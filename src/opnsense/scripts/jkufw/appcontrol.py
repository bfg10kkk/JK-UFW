#!/usr/local/bin/python3

"""
    Copyright (c) 2026 jk8s and jk-ufw contributors
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.

    --------------------------------------------------------------------------------------

    jk-ufw application control and HTTPS (SNI) web filter, on top of the stock Suricata (Services > Intrusion Detection).

    apply    write the Suricata rules, datasets and the Unbound "canary" zones from the settings in config.xml
             (OPNsense/JkUfw/appcontrol + the network-wide Content Filter policy), then reload what changed
    refresh  re-download the category lists when they are older than a day, then apply (cron, daily)
    status   JSON: last apply result + what was recognised in the last 24 hours (from eve.json)
    rules    print the generated rules (debugging)

    Rule ids (sid), so alerts can be mapped back without parsing messages:
        9700000 + n * 1000 + k   application number n from appcatalog.json
        9800000 + c * 1000 + k   web filter category c
        9890000 + k              DNS over HTTPS resolvers
        9899000 + k              allow list (pass rules)
    Monitoring rules ("alert") carry no msg on purpose: OPNsense rule policies (such as the IPS policy of the
    Threat Management page, "every alert becomes drop") only see rules that have a msg, so ours stay alerts.
"""

import argparse
import base64
import fcntl
import hashlib
import ipaddress
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime

ROOT = os.environ.get('JKUFW_ROOT', '')      # test harness only: prefix for every system path
HERE = os.path.dirname(os.path.abspath(__file__))
CATALOG = os.path.join(HERE, 'appcatalog.json')
CONFIG = ROOT + '/conf/config.xml'
RULES = ROOT + '/usr/local/etc/suricata/rules/jkufw-appcontrol.rules'
DATA_DIR = ROOT + '/usr/local/etc/suricata/jkufw'
YAML = ROOT + '/usr/local/etc/suricata/conf.d/jkufw-appcontrol.yaml'
UNBOUND = ROOT + '/usr/local/etc/unbound.opnsense.d/jkufw-appcontrol.conf'
UNBOUND_COPY = ROOT + '/var/unbound/etc/jkufw-appcontrol.conf'   # start.sh copies the file here, it is never cleaned up
CACHE = ROOT + '/var/db/jkufw/lists'
STATE = ROOT + '/var/run/jkufw-appcontrol.json'
LOCK = ROOT + '/var/run/jkufw-appcontrol.lock'
EVE = ROOT + '/var/log/suricata/eve.json'

SID_APP, SID_WEB, SID_DOH, SID_ALLOW = 9700000, 9800000, 9890000, 9899000
LIST_MAX_AGE = 86400
DOMAIN_RE = re.compile(r'^(?=.{1,253}$)((?!-)[a-z0-9_-]{1,63}(?<!-)\.)+[a-z][a-z0-9-]{0,62}$')
# suffixes of the server name looked up in the category datasets: the whole name, then its last 2, 3 and 4 labels
LABEL_DEPTHS = [0, 2, 3, 4]


def load_catalog():
    with open(CATALOG) as f:
        return json.load(f)


def write_state(**kw):
    state = {}
    try:
        with open(STATE) as f:
            state = json.load(f)
    except (OSError, ValueError):
        pass
    state.update(kw)
    state['updated'] = int(time.time())
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    tmp = STATE + '.tmp'
    with open(tmp, 'w') as f:
        json.dump(state, f)
    os.replace(tmp, STATE)


def csv(text):
    return [x.strip() for x in (text or '').replace('\n', ',').split(',') if x.strip()]


def read_settings():
    """ settings of this feature and the network-wide Content Filter policy, straight from config.xml """
    root = ET.parse(CONFIG).getroot()
    ac = root.find('OPNsense/JkUfw/appcontrol')
    get = (lambda tag: (ac.findtext(tag) or '').strip()) if ac is not None else (lambda tag: '')
    s = {
        'enabled': get('enabled') == '1',
        'visibility': get('visibility') != '0',
        'blocked': set(csv(get('blocked'))),
        'exempt': csv(get('exempt')),
        'sni_filter': get('sni_filter') == '1',
        'block_doh': get('block_doh') == '1',
        'block_quic': get('block_quic') == '1',
        'ids_enabled': (root.findtext('OPNsense/IDS/general/enabled') or '0') == '1',
        'ids_mode': root.findtext('OPNsense/IDS/general/mode') or 'pcap',
        'web_keys': set(), 'web_block': [], 'web_allow': []
    }
    # Content Filter: the enabled Unbound blocklist policy without source networks applies to the whole network
    for bl in root.findall('OPNsense/unboundplus/dnsbl/blocklist'):
        if (bl.findtext('enabled') or '0') != '1' or csv(bl.findtext('source_nets')):
            continue
        s['web_keys'].update(csv(bl.findtext('type')))
        s['web_block'] += [d.lower().lstrip('*.') for d in csv(bl.findtext('wildcards')) + csv(bl.findtext('blocklists'))]
        s['web_allow'] += [d.lower().lstrip('*.') for d in csv(bl.findtext('allowlists'))]
    s['web_block'] = sorted({d for d in s['web_block'] if DOMAIN_RE.match(d)})
    s['web_allow'] = sorted({d for d in s['web_allow'] if DOMAIN_RE.match(d)})
    return s


# ------------------------------------------------------------------------------------------------ lists

def parse_list(text):
    """ domains from a hosts file, a plain or wildcard domain list or an adblock-style list """
    out = set()
    for line in text.splitlines():
        line = line.split('#', 1)[0].strip().lower()
        if not line or line.startswith('!') or line.startswith('['):
            continue
        parts = line.split()
        if len(parts) >= 2 and parts[0] in ('0.0.0.0', '127.0.0.1', '::', '::1'):
            line = parts[1]
        elif len(parts) > 1:
            continue
        line = line.removeprefix('||').removesuffix('^').removeprefix('*.').removeprefix('.').rstrip('.')
        if DOMAIN_RE.match(line):
            out.add(line)
    return out


def fetch_list(key, url, force=False):
    """ domains of one category list; downloaded at most once a day, the last good copy is kept on errors """
    path = os.path.join(CACHE, key + '.txt')
    fresh = os.path.exists(path) and time.time() - os.path.getmtime(path) < LIST_MAX_AGE
    if not fresh or force:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'jk-ufw-appcontrol/1.0'})
            with urllib.request.urlopen(req, timeout=90) as resp:
                text = resp.read().decode('utf-8', 'replace')
            domains = parse_list(text)
            if len(domains) > 0:
                os.makedirs(CACHE, exist_ok=True)
                with open(path + '.tmp', 'w') as f:
                    f.write('\n'.join(sorted(domains)) + '\n')
                os.replace(path + '.tmp', path)
        except Exception as e:  # network or HTTP error: fall back to what we have
            if not os.path.exists(path):
                raise RuntimeError('cannot download %s: %s' % (url, e))
    with open(path) as f:
        return set(f.read().split())


# ------------------------------------------------------------------------------------------------ rules

def address_list(items):
    nets = []
    for item in items:
        try:
            nets.append(str(ipaddress.ip_network(item, strict=False)))
        except ValueError:
            continue
    return nets


class RuleSet:
    def __init__(self, exempt):
        exempt = address_list(exempt)
        # devices left out ("exempt") are never matched; everything else is, so the rules also work when the
        # sensor sits on WAN behind NAT. Destinations inside $HOME_NET are skipped for protocol/port rules so
        # that e.g. blocking SSH never locks anybody out of the firewall or local servers.
        self.src = '![%s]' % ','.join(exempt) if exempt else 'any'
        self.lines = []

    def add(self, action, proto, dst, dport, options, sid, msg=None):
        head = '%s %s %s any -> %s %s' % (action, proto, self.src, dst, dport)
        parts = ['msg:"%s";' % msg.replace('"', "'").replace(';', ',')] if msg else []
        options = options.strip()
        if options:
            parts.append(options if options.endswith(';') else options + ';')
        parts.append('sid:%d; rev:1;' % sid)
        self.lines.append('%s (%s)' % (head, ' '.join(parts)))

    def sni(self, action, domain, sid, msg, extra=''):
        """ three rules per name: TLS server name, HTTP host, QUIC server name; subdomains match too """
        d = domain.lower().strip('.')
        flow = 'flow:to_server,established; ' if action != 'pass' else 'flow:to_server; '
        self.add(action, 'tls', 'any', 'any', '%stls.sni; dotprefix; content:".%s"; nocase; endswith; %s' % (flow, d, extra),
                 sid, msg)
        self.add(action, 'http', 'any', 'any', '%shttp.host; dotprefix; content:".%s"; endswith; %s' % (flow, d, extra),
                 sid + 1, msg)
        self.add(action, 'quic', 'any', 'any', 'flow:to_server; quic.sni; dotprefix; content:".%s"; nocase; endswith; %s' % (d, extra),
                 sid + 2, msg)


def build(settings, catalog, force_download=False):
    """ -> (rules text, {dataset name: set of domains}, unbound text, info) """
    rs = RuleSet(settings['exempt'])
    datasets = {}
    info = {'apps_blocked': 0, 'apps_watched': 0, 'web_categories': [], 'web_domains': 0, 'errors': []}
    watch_limit = 'threshold:type limit, track by_src, count 1, seconds 300; '

    if settings['enabled']:
        for app in catalog['apps']:
            blocked = app['id'] in settings['blocked']
            if not blocked and not settings['visibility']:
                continue
            action = 'drop' if blocked else 'alert'
            msg = ('jk-ufw app: %s blocked' % app['name']) if blocked else None
            extra = '' if blocked else watch_limit
            info['apps_blocked' if blocked else 'apps_watched'] += 1
            sid = SID_APP + app['n'] * 1000
            k = 0
            for domain in app.get('sni', []):
                rs.sni(action, domain, sid + k, msg, extra)
                k += 3
            ips = address_list(app.get('ip', []))
            if ips:
                rs.add(action, 'ip', '[%s]' % ','.join(ips), 'any', extra, sid + k, msg)
                k += 1
            for proto in app.get('proto', []):
                rs.add(action, proto, '!$HOME_NET', 'any', 'flow:to_server; ' + extra, sid + k, msg)
                k += 1
            for port in app.get('ports', []):
                rs.add(action, port['proto'], '!$HOME_NET', port['port'], 'flow:to_server; ' + extra, sid + k, msg)
                k += 1
            for sig in app.get('sig', []):
                rs.add(action, sig['proto'], '!$HOME_NET', 'any', sig['options'] + ' ' + extra, sid + k, msg)
                k += 1

    if settings['block_doh']:
        for k, domain in enumerate(catalog['doh']['sni']):
            rs.sni('drop', domain, SID_DOH + k * 3, 'jk-ufw web: DNS over HTTPS (%s)' % domain)

    if settings['sni_filter']:
        for cat in catalog['web']['categories']:
            if cat['id'] == 'custom':
                domains = set(settings['web_block'])
            else:
                if not cat['keys'] or not all(key in settings['web_keys'] for key in cat['keys']):
                    continue
                domains = set()
                for key in cat['keys']:
                    try:
                        domains |= fetch_list(key, catalog['web']['urls'][key], force_download)
                    except RuntimeError as e:
                        info['errors'].append(str(e))
            if not domains:
                continue
            name = 'jkufw-web-' + cat['id']
            datasets[name] = domains
            info['web_categories'].append(cat['id'])
            info['web_domains'] += len(domains)
            msg = 'jk-ufw web: %s' % cat['name']
            sid = SID_WEB + cat['c'] * 1000
            for i, depth in enumerate(LABEL_DEPTHS):
                xform = 'pcrexform:"([^.]+(?:\\.[^.]+){%d})$"; ' % (depth - 1) if depth else ''
                set_kw = 'dataset:isset,%s;' % name
                rs.add('drop', 'tls', 'any', 'any', 'flow:to_server,established; tls.sni; %s%s' % (xform, set_kw), sid + i * 3, msg)
                rs.add('drop', 'http', 'any', 'any', 'flow:to_server,established; http.host; %s%s' % (xform, set_kw), sid + i * 3 + 1, msg)
                rs.add('drop', 'quic', 'any', 'any', 'flow:to_server; quic.sni; %s%s' % (xform, set_kw), sid + i * 3 + 2, msg)

    # allow list of the Content Filter wins over everything above ("pass" is evaluated first in Suricata)
    if rs.lines and settings['web_allow']:
        for k, domain in enumerate(settings['web_allow'][:300]):
            rs.sni('pass', domain, SID_ALLOW + k * 3, 'jk-ufw web: allowed %s' % domain)

    unbound = ''
    if settings['block_doh']:
        # browsers and Apple devices check these names and turn their own encrypted DNS off when they do not resolve
        unbound = 'server:\n' + ''.join('  local-zone: "%s." always_nxdomain\n' % d for d in catalog['doh']['canary'])

    header = ['# AUTO GENERATED by /usr/local/opnsense/scripts/jkufw/appcontrol.py, DO NOT EDIT.',
              '# jk-ufw application control and HTTPS web filter, see Firewall > Application Control.']
    return '\n'.join(header + rs.lines) + '\n', datasets, unbound, info


def render_yaml(datasets):
    out = ['%YAML 1.1', '---', '# AUTO GENERATED by jk-ufw appcontrol.py: category lists for the HTTPS web filter', 'datasets:']
    if not datasets:
        out[-1] = 'datasets: {}'
    for name in sorted(datasets):
        size = max(4096, 1 << (len(datasets[name]) * 2 - 1).bit_length())
        out += ['  %s:' % name, '    type: string', '    load: %s/%s.lst' % (DATA_DIR, name),
                '    hashsize: %d' % min(size, 1 << 21), '    memcap: %dmb' % max(16, len(datasets[name]) * 200 // (1 << 20) + 16)]
    return '\n'.join(out) + '\n'


def write_if_changed(path, content):
    data = content.encode() if isinstance(content, str) else content
    try:
        with open(path, 'rb') as f:
            if f.read() == data:
                return False
    except OSError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + '.tmp', 'wb') as f:
        f.write(data)
    os.replace(path + '.tmp', path)
    return True


def remove_if_exists(path):
    if os.path.exists(path):
        os.remove(path)
        return True
    return False


def run(cmd):
    if ROOT:   # test harness: never touch services
        print('would run: ' + ' '.join(cmd), file=sys.stderr)
        return ''
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def suricata_running():
    return run(['/usr/local/etc/rc.d/suricata', 'status']).find('is running') >= 0 if not ROOT else True


def apply(force_download=False):
    catalog = load_catalog()
    settings = read_settings()
    write_state(phase='build', message='Сборка правил', error='')
    rules, datasets, unbound, info = build(settings, catalog, force_download)

    data_changed = False
    for name, domains in datasets.items():
        content = ''.join(base64.b64encode(d.encode()).decode() + '\n' for d in sorted(domains))
        data_changed |= write_if_changed('%s/%s.lst' % (DATA_DIR, name), content)
    if os.path.isdir(DATA_DIR):
        for fn in os.listdir(DATA_DIR):
            if fn.endswith('.lst') and fn[:-4] not in datasets:
                os.remove(os.path.join(DATA_DIR, fn))
    yaml_new = not os.path.exists(YAML)
    yaml_changed = write_if_changed(YAML, render_yaml(datasets))
    rules_changed = write_if_changed(RULES, rules)
    unbound_changed = remove_if_exists(UNBOUND) if not unbound else write_if_changed(UNBOUND, unbound)
    if not unbound:
        unbound_changed |= remove_if_exists(UNBOUND_COPY)

    actions = []
    if yaml_new:
        # suricata.yaml includes conf.d/*.yaml at template time: render it again so our datasets are known
        run(['/usr/local/sbin/configctl', 'template', 'reload', 'OPNsense/IDS'])
        actions.append('template')
    if settings['ids_enabled']:
        if yaml_new or yaml_changed or data_changed:
            write_state(phase='restart', message='Перезапуск IPS')
            run(['/usr/local/opnsense/scripts/suricata/installRules.py'])
            run(['/usr/local/etc/rc.d/suricata', 'restart'])
            actions.append('restart')
        elif rules_changed:
            write_state(phase='reload', message='Загрузка правил в IPS')
            run(['/usr/local/opnsense/scripts/suricata/installRules.py'])
            run(['/bin/pkill', '-USR2', 'suricata'])
            actions.append('reload')
    elif rules_changed:
        run(['/usr/local/opnsense/scripts/suricata/installRules.py'])
    if unbound_changed:
        write_state(phase='dns', message='Перезапуск DNS')
        run(['/usr/local/sbin/configctl', 'unbound', 'restart'])
        actions.append('unbound')

    info['rules'] = rules.count('\n') - 2
    info['actions'] = actions
    write_state(phase='done', message='', error='; '.join(info['errors']), result=info, applied=int(time.time()))
    return info


# ------------------------------------------------------------------------------------------------ status

def parse_ts(value):
    try:
        return datetime.strptime(value[:26] + value[-5:], '%Y-%m-%dT%H:%M:%S.%f%z').timestamp()
    except (ValueError, TypeError):
        return 0


def sid_owner(sid, apps_by_n, web_by_c):
    if SID_APP <= sid < SID_WEB:
        app = apps_by_n.get((sid - SID_APP) // 1000)
        return ('app', app['id']) if app else None
    if SID_WEB <= sid < SID_DOH:
        cat = web_by_c.get((sid - SID_WEB) // 1000)
        return ('web', cat['id']) if cat else None
    if SID_DOH <= sid < SID_ALLOW:
        return ('web', 'doh')
    return None


def stats(window=86400, max_bytes=48 << 20):
    catalog = load_catalog()
    apps_by_n = {a['n']: a for a in catalog['apps']}
    web_by_c = {c['c']: c for c in catalog['web']['categories']}
    since = time.time() - window
    result = {'window': window, 'apps': {}, 'web': {}, 'clients': {}, 'recent': [], 'events': 0}
    paths = [EVE] if os.path.exists(EVE) else []
    for path in paths:
        with open(path, 'rb') as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - max_bytes))
            if size > max_bytes:
                f.readline()
            for raw in f:
                if b'"signature_id":98' not in raw and b'"signature_id":97' not in raw:
                    continue
                try:
                    ev = json.loads(raw)
                except ValueError:
                    continue
                alert = ev.get('alert') or {}
                owner = sid_owner(int(alert.get('signature_id', 0)), apps_by_n, web_by_c)
                if owner is None:
                    continue
                ts = parse_ts(ev.get('timestamp'))
                if ts < since:
                    continue
                kind, key = owner
                blocked = alert.get('action') == 'blocked' or str(alert.get('signature', '')).endswith('blocked') \
                    or kind == 'web'
                src = ev.get('src_ip', '')
                bucket = result['apps' if kind == 'app' else 'web'].setdefault(key, {'hits': 0, 'blocked': 0, 'last': 0, 'clients': {}})
                bucket['hits'] += 1
                bucket['blocked'] += 1 if blocked else 0
                bucket['last'] = max(bucket['last'], ts)
                bucket['clients'][src] = bucket['clients'].get(src, 0) + 1
                result['clients'][src] = result['clients'].get(src, 0) + 1
                result['events'] += 1
                host = (ev.get('tls') or {}).get('sni') or (ev.get('http') or {}).get('hostname') or (ev.get('quic') or {}).get('sni') or ''
                result['recent'].append({'ts': int(ts), 'kind': kind, 'id': key, 'src': src, 'dst': ev.get('dest_ip', ''),
                                         'host': host, 'blocked': blocked})
    result['recent'] = sorted(result['recent'], key=lambda r: -r['ts'])[:60]
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['apply', 'refresh', 'status', 'rules'])
    args = parser.parse_args()

    if args.command == 'status':
        state = {}
        try:
            with open(STATE) as f:
                state = json.load(f)
        except (OSError, ValueError):
            pass
        out = {'state': state, 'stats': stats()}
        out['rules_installed'] = os.path.exists(RULES)
        print(json.dumps(out))
        return
    if args.command == 'rules':
        print(build(read_settings(), load_catalog())[0])
        return

    os.makedirs(os.path.dirname(LOCK), exist_ok=True)
    with open(LOCK, 'w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            print(json.dumps({'status': 'busy'}))
            return
        try:
            info = apply(force_download=False)
            print(json.dumps({'status': 'ok', 'result': info}))
        except Exception as e:
            write_state(phase='error', message='', error=str(e))
            print(json.dumps({'status': 'failed', 'message': str(e)}))
            sys.exit(1)


if __name__ == '__main__':
    main()
