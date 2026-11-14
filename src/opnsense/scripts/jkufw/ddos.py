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

    jk-ufw attack protection helper (configd: "jkufw_ddos <command>").

    stats                       everything the page shows, as JSON: pf counters, state table, blocked
                                addresses, history of the last 24 hours, recent events, IoC table sizes
    tick                        every minute from cron: take a sample, let blocked addresses expire, keep
                                allowed addresses out of the block list, write events (also to syslog,
                                program "jkufw-ddos", so a SIEM gets them)
    block <address>             put an address on the automatic block list now (expires like the others)
    unblock <address|ALL>       take an address (or all) off the automatic block list
    siemtest <host> <port> <transport> <format>
                                send one test event to a log collector
"""

import datetime
import ipaddress
import json
import os
import re
import socket
import subprocess
import sys
import syslog
import time
import xml.etree.ElementTree as ET

CONFIG = os.environ.get('JKUFW_CONFIG', '/conf/config.xml')
PFCTL = os.environ.get('JKUFW_PFCTL', '/sbin/pfctl')
STATE_DIR = os.environ.get('JKUFW_STATE', '/var/db/jkufw')
HISTORY = os.path.join(STATE_DIR, 'ddos_history.json')
EVENTS = os.path.join(STATE_DIR, 'ddos_events.json')
TABLE = 'jkufw_ddos_block'
KEEP_SAMPLES = 1440       # one a minute: 24 hours
KEEP_EVENTS = 200


def pfctl(*args):
    try:
        return subprocess.run([PFCTL] + list(args), capture_output=True, text=True, timeout=30).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ''


def load_json(path, default):
    try:
        with open(path) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return default


def save_json(path, data):
    os.makedirs(os.path.dirname(path), mode=0o750, exist_ok=True)
    tmp = path + '.tmp'
    with open(tmp, 'w') as fh:
        json.dump(data, fh, separators=(',', ':'))
    os.replace(tmp, path)


def settings():
    """ our part of config.xml: {enabled, blocktime (minutes), allow [...], interfaces [...]} """
    result = {'enabled': False, 'blocktime': 60, 'allow': [], 'interfaces': [], 'devices': {}}
    try:
        root = ET.parse(CONFIG).getroot()
    except (OSError, ET.ParseError):
        return result
    node = root.find('./OPNsense/JkUfw/ddos')
    if node is not None:
        result['enabled'] = node.findtext('general/enabled', '0') == '1'
        try:
            result['blocktime'] = max(1, int(node.findtext('general/blocktime', '60')))
        except ValueError:
            pass
        result['allow'] = [a for a in node.findtext('general/allow', '').split(',') if a]
        for item in node.findall('interfaces/interface'):
            if item.findtext('enabled', '1') == '1' and item.findtext('interface'):
                result['interfaces'].append(item.findtext('interface'))
    for name in result['interfaces']:
        dev = root.findtext('./interfaces/%s/if' % name)
        if dev:
            result['devices'][name] = dev
    return result


def pf_info():
    """ pfctl -vsi as {section: {counter: [total, rate]}} plus the syncookie mode """
    result = {}
    section = None
    for line in pfctl('-vsi').split('\n'):
        if not line.strip():
            continue
        if not line[0].isspace():
            section = line.split('  ')[0].strip().lower().replace(' ', '-')
            continue
        m = re.match(r'^\s+(.+?)\s{2,}(\S+)(?:\s+([0-9.]+)/s)?\s*$', line)
        if m and section:
            value = m.group(2)
            result.setdefault(section, {})[m.group(1).strip().lower()] = [
                int(value) if value.isdigit() else value,
                float(m.group(3)) if m.group(3) else None
            ]
    return result


def counter(info, section, name):
    value = info.get(section, {}).get(name, [0])[0]
    return value if isinstance(value, int) else 0


def state_limit():
    m = re.search(r'^states\s+hard limit\s+(\d+)', pfctl('-sm'), re.M)
    return int(m.group(1)) if m else 0


def interface_packets(devices):
    """ {device: {in_pass, in_block}} packets (IPv4 + IPv6) from pfctl -vvsI """
    result = {}
    current = None
    for line in pfctl('-vvsI').split('\n'):
        if line and not line[0].isspace():
            current = line.strip()
            continue
        m = re.match(r'^\s+(In|Out)(4|6)/(Pass|Block):\s+\[\s*Packets:\s*(\d+)', line)
        if current in devices and m and m.group(1) == 'In':
            key = 'in_' + m.group(3).lower()
            result.setdefault(current, {'in_pass': 0, 'in_block': 0})[key] += int(m.group(4))
    return result


def table_entries():
    """ automatic block list: [{address, since (epoch), packets}], negated (allowed) entries left out """
    entries = []
    current = None
    for line in pfctl('-t', TABLE, '-T', 'show', '-v').split('\n'):
        if line.startswith('  ') and not line.startswith('\t'):
            addr = line.strip()
            current = None
            if addr.startswith('!'):
                continue
            current = {'address': addr, 'since': None, 'packets': 0}
            entries.append(current)
        elif current is not None:
            text = line.strip()
            if text.startswith('Cleared:'):
                try:
                    current['since'] = int(time.mktime(time.strptime(text[8:].strip(), '%a %b %d %H:%M:%S %Y')))
                except ValueError:
                    pass
            else:
                m = re.match(r'^In/Block:\s+\[\s*Packets:\s*(\d+)', text)
                if m:
                    current['packets'] += int(m.group(1))
    return entries


def table_counts(prefixes):
    """ number of addresses per pf table whose name starts with one of the prefixes """
    result = {}
    current = None
    for line in pfctl('-vvsTables').split('\n'):
        m = re.match(r'^[-a-zA-Z]*\s+(\S+)$', line)
        if m and not line.startswith('\t'):
            current = m.group(1) if m.group(1).startswith(tuple(prefixes)) else None
            continue
        m = re.match(r'^\s+Addresses:\s+(\d+)', line)
        if current and m:
            result[current] = int(m.group(1))
    return result


def log_event(events, kind, text, **extra):
    item = {'time': int(time.time()), 'kind': kind, 'text': text}
    item.update(extra)
    events.append(item)
    syslog.openlog('jkufw-ddos', facility=syslog.LOG_LOCAL4)
    syslog.syslog(syslog.LOG_WARNING if kind in ('attack', 'block', 'syn') else syslog.LOG_NOTICE, text)


def allowed(address, allow_nets):
    try:
        net = ipaddress.ip_network(address, strict=False)
    except ValueError:
        return False
    for a in allow_nets:
        try:
            if net.version == a.version and net.subnet_of(a):
                return True
        except (TypeError, ValueError):
            continue
    return False


def cmd_tick():
    cfg = settings()
    now = int(time.time())
    history = load_json(HISTORY, [])
    events = load_json(EVENTS, [])

    allow_nets = []
    for a in cfg['allow']:
        try:
            allow_nets.append(ipaddress.ip_network(a, strict=False))
        except ValueError:
            pass

    if cfg['enabled']:
        # addresses older than the block time leave the list
        pfctl('-t', TABLE, '-T', 'expire', str(cfg['blocktime'] * 60))
        # single allowed hosts stay in the table as negated entries: pf then never adds them again
        hosts = ['!' + str(a.network_address) for a in allow_nets if a.prefixlen == a.max_prefixlen]
        if hosts:
            pfctl('-t', TABLE, '-T', 'add', *hosts)
    entries = table_entries()
    # allowed networks: their addresses are taken out again
    drop = [e['address'] for e in entries if allowed(e['address'], allow_nets)]
    if drop:
        pfctl('-t', TABLE, '-T', 'delete', *drop)
        entries = [e for e in entries if e['address'] not in drop]

    info = pf_info()
    limit = state_limit()
    packets = interface_packets(set(cfg['devices'].values()))
    sample = {
        't': now,
        'states': counter(info, 'state-table', 'current entries'),
        'limit': limit,
        'inserts': counter(info, 'state-table', 'inserts'),
        'synflood': counter(info, 'limit-counters', 'synfloods detected'),
        'cookies': counter(info, 'limit-counters', 'syncookies sent'),
        'overload': counter(info, 'limit-counters', 'overload table insertion'),
        'srclimit': counter(info, 'counters', 'src-limit') + counter(info, 'limit-counters', 'max-src-states')
        + counter(info, 'limit-counters', 'max-src-conn') + counter(info, 'limit-counters', 'max-src-conn-rate'),
        'synproxy': counter(info, 'counters', 'synproxy'),
        'in_pass': sum(p['in_pass'] for p in packets.values()),
        'in_block': sum(p['in_block'] for p in packets.values()),
        'blocked': len(entries),
    }

    prev = history[-1] if history else None
    level = 'calm'
    if prev and 0 < now - prev['t'] < 600:
        secs = now - prev['t']
        diff = lambda k: max(0, sample[k] - prev.get(k, 0))
        sample['rate_block'] = round(diff('in_block') / secs, 1)
        sample['rate_pass'] = round(diff('in_pass') / secs, 1)
        sample['rate_new'] = round(diff('inserts') / secs, 1)
        new_syn = diff('synflood') + diff('cookies')
        new_limit = diff('srclimit') + diff('overload')
        usage = sample['states'] / limit if limit else 0
        if new_syn > 0 or usage > 0.8 or sample['rate_block'] > 5000:
            level = 'attack'
        elif new_limit > 0 or usage > 0.5 or sample['rate_block'] > 500:
            level = 'elevated'
        sample['level'] = level

        if cfg['enabled']:
            if diff('synflood') > 0 or diff('cookies') > 0:
                log_event(events, 'syn', 'SYN flood: %d SYN cookies sent in the last minute' % diff('cookies'),
                          code='syn', count=diff('cookies'))
            if usage > 0.8 and prev.get('states', 0) / (prev.get('limit') or limit or 1) <= 0.8:
                log_event(events, 'attack', 'State table %d%% full (%d of %d)' % (usage * 100, sample['states'], limit),
                          code='table', count=int(usage * 100))
            if prev.get('level') == 'attack' and level != 'attack':
                log_event(events, 'ok', 'Attack is over', code='over')
            elif prev.get('level') != 'attack' and level == 'attack' and not (diff('synflood') or diff('cookies')):
                log_event(events, 'attack', 'Attack: %s blocked packets per second' % sample['rate_block'],
                          code='flood', count=sample['rate_block'])
    # addresses pf put on the list since the last run
    known = set(prev.get('addresses', [])) if prev else set()
    for e in entries:
        if e['address'] not in known and cfg['enabled']:
            log_event(events, 'block', 'Address %s blocked: crossed a connection limit' % e['address'],
                      code='limit', address=e['address'])
    sample['addresses'] = [e['address'] for e in entries][:500]
    if prev:
        prev.pop('addresses', None)

    history.append(sample)
    history = [h for h in history if h['t'] > now - 86400][-KEEP_SAMPLES:]
    save_json(HISTORY, history)
    save_json(EVENTS, events[-KEEP_EVENTS:])


def cmd_stats():
    cfg = settings()
    info = pf_info()
    history = load_json(HISTORY, [])
    for h in history:
        h.pop('addresses', None)
    devices = cfg['devices']
    packets = interface_packets(set(devices.values()))
    print(json.dumps({
        'time': int(time.time()),
        'states': counter(info, 'state-table', 'current entries'),
        'limit': state_limit(),
        'syncookies': info.get('syncookies', {}).get('mode', [''])[0],
        'counters': {k: v for s in ('counters', 'limit-counters') for k, v in info.get(s, {}).items()},
        'state_rate': info.get('state-table', {}).get('inserts', [0, None])[1],
        'interfaces': {name: packets.get(dev, {'in_pass': 0, 'in_block': 0}) for name, dev in devices.items()},
        'blocked': table_entries(),
        'tables': table_counts(['jkufw_ioc_', 'jkufw_ddos_']),
        'history': history,
        'events': list(reversed(load_json(EVENTS, [])))[:50],
    }))


def valid_address(value):
    try:
        ipaddress.ip_network(value, strict=False)
        return True
    except ValueError:
        return False


def cmd_block(address):
    if not valid_address(address):
        print(json.dumps({'status': 'failed', 'message': 'not an address'}))
        return
    pfctl('-t', TABLE, '-T', 'add', address)
    pfctl('-k', address)
    events = load_json(EVENTS, [])
    log_event(events, 'block', 'Address %s blocked by hand' % address, code='manual', address=address)
    save_json(EVENTS, events[-KEEP_EVENTS:])
    print(json.dumps({'status': 'ok'}))


def cmd_unblock(address):
    if address == 'ALL':
        keep = [l.strip() for l in pfctl('-t', TABLE, '-T', 'show').split('\n') if l.strip().startswith('!')]
        pfctl('-t', TABLE, '-T', 'flush')
        if keep:
            pfctl('-t', TABLE, '-T', 'add', *keep)
        text = 'All automatically blocked addresses released'
        code = 'release_all'
    elif valid_address(address):
        pfctl('-t', TABLE, '-T', 'delete', address)
        text = 'Address %s released by hand' % address
        code = 'release'
    else:
        print(json.dumps({'status': 'failed', 'message': 'not an address'}))
        return
    events = load_json(EVENTS, [])
    log_event(events, 'ok', text, code=code, address=address)
    save_json(EVENTS, events[-KEEP_EVENTS:])
    print(json.dumps({'status': 'ok'}))


def cmd_siemtest(host, port, transport, fmt):
    hostname = socket.gethostname()
    now = datetime.datetime.now(datetime.timezone.utc).astimezone()
    text = 'jk-ufw test event: the log collector receives messages from this firewall'
    if fmt == 'cef':
        msg = 'CEF:0|jk-ufw|firewall|1.0|test|SIEM connection test|1|rt=%d dvchost=%s msg=%s' % (
            int(now.timestamp() * 1000), hostname, text)
    elif fmt == 'json':
        msg = json.dumps({'@timestamp': now.isoformat(), 'host': hostname, 'program': 'jkufw-siem', 'message': text})
    else:
        msg = text
    line = '<133>1 %s %s jkufw-siem %d - - %s' % (now.isoformat(timespec='seconds'), hostname, os.getpid(), msg)
    family = socket.AF_INET6 if transport.endswith('6') else socket.AF_INET
    try:
        addr = socket.getaddrinfo(host, int(port), family)[0][4]
        if transport.startswith('tcp'):
            with socket.create_connection(addr[:2], timeout=5) as s:
                s.sendall((line + '\n').encode())
        else:
            with socket.socket(family, socket.SOCK_DGRAM) as s:
                s.sendto(line.encode(), addr)
        print(json.dumps({'status': 'ok'}))
    except (OSError, ValueError, IndexError) as e:
        print(json.dumps({'status': 'failed', 'message': str(e)}))


if __name__ == '__main__':
    args = sys.argv[1:]
    if args and args[0] == 'stats':
        cmd_stats()
    elif args and args[0] == 'tick':
        cmd_tick()
    elif len(args) > 1 and args[0] == 'block':
        cmd_block(args[1].strip())
    elif len(args) > 1 and args[0] == 'unblock':
        cmd_unblock(args[1].strip())
    elif len(args) > 4 and args[0] == 'siemtest':
        cmd_siemtest(args[1], args[2], args[3], args[4])
    else:
        print(__doc__)
        sys.exit(1)
