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
    jk-ufw: stream antivirus and sandbox (Firewall > Antivirus).

    Two ways files are checked:
      * web downloads go through the proxy (Squid -> c-icap -> clamd) and are blocked on the fly;
        this script only reads the clamd/squid logs for the page (see "events");
      * files in HTTP / SMTP / FTP / SMB / NFS traffic are cut out by Suricata (file-store, rules in
        jkufw-av.rules) and analysed here: ClamAV, hash reputation (MalwareBazaar, VirusTotal) and,
        if set up, dynamic analysis in a sandbox (CAPEv2 / Cuckoo on your own server, or VirusTotal).
    Hashes judged malicious go on a block list used by ClamAV (proxy) and by Suricata (filesha256 rule).

    av.py worker            cron, every minute: take new files, analyse, poll sandboxes, clean up
    av.py status            JSON: engines, counters
    av.py events [n]        JSON: latest detections (files + proxy log)
    av.py files [n]         JSON: analysed files
    av.py file <sha256>     JSON: one file with full report
    av.py upload <path> [name]   analyse a file uploaded on the page (file is moved into quarantine)
    av.py lookup <hash>     hash-only check (reputation), adds a record
    av.py rescan <sha256>   analyse again;  av.py submit <sha256>  send to the sandbox now
    av.py block <sha256> [name] / unblock <sha256> / delete <sha256>
    av.py sync              rewrite Suricata rules, hash lists and reload engines

    Paths can be moved for tests with JKUFW_AV_ROOT (prefix for every absolute path) and
    JKUFW_CONFIG (config.xml); JKUFW_MB_API / JKUFW_VT_API point the reputation services elsewhere.
"""

import datetime
import fcntl
import glob
import hashlib
import ipaddress
import json
import os
import re
import shutil
import socket
import sqlite3
import ssl
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
import xml.etree.ElementTree as ET

ROOT = os.environ.get('JKUFW_AV_ROOT', '')


def p(path):
    return ROOT + path


CONFIG = os.environ.get('JKUFW_CONFIG', '/conf/config.xml')
WORK = p('/var/db/jkufw/av')
STORE = WORK + '/files'
DB = WORK + '/av.db'
LOCK = WORK + '/worker.lock'
BADLIST = WORK + '/bad-sha256.txt'
FILESTORE = p('/var/log/suricata/filestore')
RULES = p('/usr/local/etc/suricata/rules/jkufw-av.rules')
HSB = p('/var/db/clamav/jkufw-blocked.hsb')
CLAMD_SOCK = p('/var/run/clamav/clamd.sock')
CLAMD_LOGS = p('/var/log/clamd')
SQUID_LOG = p('/var/log/squid/access.log')
SURICATA_PID = p('/var/run/suricata.pid')

UA = 'jk-ufw-antivirus/1.0'
MB_API = os.environ.get('JKUFW_MB_API', 'https://mb-api.abuse.ch/api/v1/')
VT_API = os.environ.get('JKUFW_VT_API', 'https://www.virustotal.com/api/v3')

# Suricata "file.magic" substrings per file kind (libmagic descriptions)
MAGIC = {
    'exe': ['PE32', 'MS-DOS executable', 'ELF ', 'Mach-O', 'MSI Installer'],
    'office': ['Microsoft Word', 'Microsoft Excel', 'Microsoft PowerPoint', 'Microsoft OOXML',
               'Composite Document File', 'Rich Text Format', 'OpenDocument'],
    'pdf': ['PDF document'],
    'archive': ['Zip archive', 'RAR archive', '7-zip archive', 'gzip compressed', 'bzip2 compressed',
                'XZ compressed', 'Microsoft Cabinet', 'POSIX tar'],
    'script': ['script text', 'batch file', 'PowerShell', 'HTML Application', 'JavaScript'],
    'android': ['Java archive', 'Android', 'Dalvik'],
    'disk': ['ISO 9660', 'Microsoft Disk Image', 'DOS/MBR boot sector', 'VHD', 'UDF filesystem'],
}
KIND_ORDER = ['exe', 'office', 'pdf', 'archive', 'script', 'android', 'disk']
PROTOS = ['http', 'smtp', 'ftp-data', 'smb', 'nfs']
QUARANTINE_MAX = 2 << 30
SID_BASE = 9170000      # 9170001.. extraction rules, 9170900.. hash block rules


# ---------------------------------------------------------------------------------------------
# settings

def settings():
    s = {
        'web': {'enabled': False, 'maxsize': 25},
        'files': {'enabled': False, 'types': ['exe', 'office', 'pdf', 'archive', 'script'],
                  'maxsize': 32, 'keep_days': 14, 'keep_clean': False},
        'intel': {'mb_key': '', 'vt_key': ''},
        'sandbox': {'provider': 'none', 'url': '', 'token': '', 'verify': True, 'submit': 'unknown'},
        'action': {'autoblock': True, 'suspicious': False},
    }
    try:
        root = ET.parse(CONFIG).getroot()
    except (OSError, ET.ParseError):
        return s
    node = root.find('./OPNsense/JkUfw/antivirus')
    if node is None:
        return s

    def txt(path, default=''):
        e = node.find(path)
        return (e.text or '').strip() if e is not None and e.text is not None else default

    def flag(path, default):
        v = txt(path, None)
        return default if v is None else v == '1'

    def num(path, default):
        try:
            return int(txt(path, str(default)))
        except ValueError:
            return default

    s['web'] = {'enabled': flag('web/enabled', False), 'maxsize': num('web/maxsize', 25)}
    types = [t for t in txt('files/types', ','.join(s['files']['types'])).split(',') if t in MAGIC]
    s['files'] = {'enabled': flag('files/enabled', False), 'types': types, 'maxsize': num('files/maxsize', 32),
                  'keep_days': num('files/keep_days', 14), 'keep_clean': flag('files/keep_clean', False)}
    s['intel'] = {'mb_key': txt('intel/mb_key'), 'vt_key': txt('intel/vt_key')}
    s['sandbox'] = {'provider': txt('sandbox/provider', 'none') or 'none', 'url': txt('sandbox/url').rstrip('/'),
                    'token': txt('sandbox/token'), 'verify': flag('sandbox/verify', True),
                    'submit': txt('sandbox/submit', 'unknown') or 'unknown'}
    s['action'] = {'autoblock': flag('action/autoblock', True), 'suspicious': flag('action/suspicious', False)}
    return s


# ---------------------------------------------------------------------------------------------
# database

SCHEMA = """
create table if not exists files (
    sha256 text primary key, md5 text, sha1 text,
    first_seen real, last_seen real, seen integer default 1,
    name text, size integer, magic text, kind text,
    source text, proto text, client text, server text, host text, url text,
    stored text,
    clamav text, clamav_at real,
    intel text, intel_at real,
    sb_provider text, sb_task text, sb_state text, sb_at real, sb_score real, sb_report text,
    verdict text, reason text, updated real
);
create table if not exists blocklist (sha256 text primary key, name text, reason text, added real, auto integer);
create table if not exists meta (key text primary key, value text);
"""


def db():
    os.makedirs(STORE, mode=0o700, exist_ok=True)
    con = sqlite3.connect(DB, timeout=30)
    con.row_factory = sqlite3.Row
    con.executescript(SCHEMA)
    return con


def meta_get(con, key, default=None):
    r = con.execute('select value from meta where key=?', (key,)).fetchone()
    return r['value'] if r else default


def meta_set(con, key, value):
    con.execute('insert or replace into meta(key, value) values (?, ?)', (key, str(value)))


def row_dict(r, full=False):
    d = dict(r)
    for k in ('intel', 'sb_report'):
        try:
            d[k] = json.loads(d[k]) if d.get(k) else None
        except ValueError:
            d[k] = None
    if not full and d.get('sb_report'):
        rep = d['sb_report']
        d['sb_report'] = {k: rep.get(k) for k in ('score', 'family', 'url') if k in rep}
        d['sb_report']['signatures'] = len(rep.get('signatures') or [])
    d['quarantined'] = bool(d.get('stored')) and os.path.exists(d['stored'])
    d.pop('stored', None)
    return d


# ---------------------------------------------------------------------------------------------
# helpers

def is_sha256(v):
    return bool(re.fullmatch(r'[0-9a-f]{64}', v or ''))


def hashes(path):
    h = {'md5': hashlib.md5(), 'sha1': hashlib.sha1(), 'sha256': hashlib.sha256()}
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            for x in h.values():
                x.update(chunk)
    return {k: v.hexdigest() for k, v in h.items()}


def file_magic(path):
    try:
        out = subprocess.run(['/usr/bin/file', '-b', path], capture_output=True, text=True, timeout=20)
        return out.stdout.strip()[:200]
    except (OSError, subprocess.SubprocessError):
        return ''


def kind_of(magic, name=''):
    m = (magic or '').lower()
    for k in KIND_ORDER:
        for needle in MAGIC[k]:
            if needle.lower() in m:
                if k == 'archive' and (name or '').lower().endswith('.apk'):
                    return 'android'
                return k
    ext = os.path.splitext(name or '')[1].lower()
    for k, exts in (('exe', '.exe .dll .msi .scr .com'), ('office', '.doc .docx .docm .xls .xlsx .xlsm .ppt .pptx .rtf'),
                    ('pdf', '.pdf'), ('archive', '.zip .rar .7z .gz .tgz .cab'), ('script', '.js .vbs .ps1 .bat .cmd .hta .sh'),
                    ('android', '.apk'), ('disk', '.iso .img .vhd .vhdx')):
        if ext and ext in exts.split():
            return k
    return 'other'


def private(ip):
    try:
        a = ipaddress.ip_address(ip)
        return a.is_private or a.is_link_local
    except ValueError:
        return False


def http(url, data=None, headers=None, verify=True, timeout=30, method=None):
    """small urllib wrapper; returns (status, parsed JSON or text)"""
    hdr = {'User-Agent': UA}
    hdr.update(headers or {})
    req = urllib.request.Request(url, data=data, headers=hdr, method=method)
    ctx = ssl.create_default_context()
    if not verify:
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
            body = resp.read()
            status = resp.status
    except urllib.error.HTTPError as e:
        body = e.read()
        status = e.code
    try:
        return status, json.loads(body.decode('utf-8', 'replace'))
    except ValueError:
        return status, body.decode('utf-8', 'replace')[:500]


def multipart(path, name, field='file', extra=None):
    boundary = uuid.uuid4().hex
    parts = []
    for k, v in (extra or {}).items():
        parts.append(('--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n' % (boundary, k, v)).encode())
    with open(path, 'rb') as f:
        content = f.read()
    safe = re.sub(r'[^A-Za-z0-9._-]', '_', name or 'sample') or 'sample'
    parts.append(('--%s\r\nContent-Disposition: form-data; name="%s"; filename="%s"\r\n'
                  'Content-Type: application/octet-stream\r\n\r\n' % (boundary, field, safe)).encode() + content + b'\r\n')
    parts.append(('--%s--\r\n' % boundary).encode())
    return b''.join(parts), 'multipart/form-data; boundary=%s' % boundary


# ---------------------------------------------------------------------------------------------
# ClamAV (clamd INSTREAM, so clamd needs no access to our files)

def clamd_cmd(cmd, payload_path=None, timeout=120):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(timeout)
    s.connect(CLAMD_SOCK)
    try:
        s.sendall(b'z' + cmd.encode() + b'\0')
        if payload_path:
            with open(payload_path, 'rb') as f:
                for chunk in iter(lambda: f.read(1 << 16), b''):
                    s.sendall(struct.pack('!L', len(chunk)) + chunk)
            s.sendall(struct.pack('!L', 0))
        out = b''
        while not out.endswith(b'\0'):
            buf = s.recv(4096)
            if not buf:
                break
            out += buf
        return out.rstrip(b'\0').decode('utf-8', 'replace').strip()
    finally:
        s.close()


def clamd_alive():
    try:
        return clamd_cmd('PING', timeout=3) == 'PONG'
    except OSError:
        return False


def clamav_scan(path):
    """'' = clean, signature name = found, None = scanner unavailable / error"""
    try:
        out = clamd_cmd('INSTREAM', path)
    except OSError:
        return None
    m = re.match(r'^stream: (.+) FOUND$', out)
    if m:
        return m.group(1)
    if out.endswith('OK'):
        return ''
    return None


# ---------------------------------------------------------------------------------------------
# hash reputation

def intel_lookup(sha256, cfg):
    """returns dict {source: {...}}; never raises"""
    res = {}
    key = cfg['intel']['mb_key']
    if key:
        try:
            st, js = http(MB_API, urllib.parse.urlencode(
                {'query': 'get_info', 'hash': sha256}).encode(), {'Auth-Key': key}, timeout=20)
            if isinstance(js, dict) and js.get('query_status') == 'ok' and js.get('data'):
                d = js['data'][0]
                res['malwarebazaar'] = {'found': True, 'signature': d.get('signature') or '',
                                        'tags': (d.get('tags') or [])[:8], 'first_seen': d.get('first_seen'),
                                        'url': 'https://bazaar.abuse.ch/sample/%s/' % sha256}
            elif isinstance(js, dict) and js.get('query_status') in ('hash_not_found', 'no_results'):
                res['malwarebazaar'] = {'found': False}
            else:
                res['malwarebazaar'] = {'error': (js.get('query_status') if isinstance(js, dict) else None) or 'HTTP %d' % st}
        except (OSError, ValueError) as e:
            res['malwarebazaar'] = {'error': str(e)[:120]}
    key = cfg['intel']['vt_key']
    if key:
        try:
            st, js = http('%s/files/%s' % (VT_API, sha256), headers={'x-apikey': key}, timeout=20)
            if st == 200 and isinstance(js, dict):
                a = js.get('data', {}).get('attributes', {})
                stats = a.get('last_analysis_stats') or {}
                label = (a.get('popular_threat_classification') or {}).get('suggested_threat_label') or ''
                res['virustotal'] = {'found': True, 'sha256': js.get('data', {}).get('id', ''),
                                     'name': a.get('meaningful_name') or '', 'malicious': stats.get('malicious', 0),
                                     'suspicious': stats.get('suspicious', 0),
                                     'total': sum(v for v in stats.values() if isinstance(v, int)),
                                     'label': label, 'url': 'https://www.virustotal.com/gui/file/%s' % sha256}
            elif st == 404:
                res['virustotal'] = {'found': False}
            else:
                msg = js.get('error', {}).get('code') if isinstance(js, dict) else ''
                res['virustotal'] = {'error': msg or 'HTTP %d' % st}
        except (OSError, ValueError) as e:
            res['virustotal'] = {'error': str(e)[:120]}
    return res


# ---------------------------------------------------------------------------------------------
# sandboxes

def sb_headers(cfg):
    tok = cfg['sandbox']['token']
    prov = cfg['sandbox']['provider']
    if prov == 'virustotal':
        return {'x-apikey': cfg['intel']['vt_key']}
    if not tok:
        return {}
    if prov == 'cuckoo':
        return {'Authorization': 'Bearer %s' % tok}
    return {'Authorization': tok if ' ' in tok else 'Token %s' % tok}


def sb_submit(path, name, cfg):
    """returns task id (str); raises RuntimeError with a readable message"""
    prov = cfg['sandbox']['provider']
    url = cfg['sandbox']['url']
    verify = cfg['sandbox']['verify']
    if prov == 'cape':
        body, ctype = multipart(path, name)
        st, js = http(url + '/apiv2/tasks/create/file/', body, dict(sb_headers(cfg), **{'Content-Type': ctype}),
                      verify=verify, timeout=120)
        if isinstance(js, dict) and not js.get('error') and (js.get('data') or {}).get('task_ids'):
            return str(js['data']['task_ids'][0])
        raise RuntimeError(sb_error(st, js))
    if prov == 'cuckoo':
        body, ctype = multipart(path, name)
        st, js = http(url + '/tasks/create/file', body, dict(sb_headers(cfg), **{'Content-Type': ctype}),
                      verify=verify, timeout=120)
        if isinstance(js, dict) and js.get('task_id'):
            return str(js['task_id'])
        raise RuntimeError(sb_error(st, js))
    if prov == 'virustotal':
        body, ctype = multipart(path, name)
        st, js = http(VT_API + '/files', body,
                      dict(sb_headers(cfg), **{'Content-Type': ctype}), timeout=300)
        if isinstance(js, dict) and (js.get('data') or {}).get('id'):
            return js['data']['id']
        raise RuntimeError(sb_error(st, js))
    raise RuntimeError('песочница не настроена')


def sb_error(st, js):
    if isinstance(js, dict):
        for k in ('error_value', 'message', 'detail'):
            if js.get(k):
                return str(js[k])[:160]
        if isinstance(js.get('error'), dict):
            return str(js['error'].get('message') or js['error'].get('code'))[:160]
    return 'HTTP %s' % st


def sb_poll(task, sha256, cfg):
    """returns (state, report) where state in running/done/error"""
    prov = cfg['sandbox']['provider']
    url = cfg['sandbox']['url']
    verify = cfg['sandbox']['verify']
    hdr = sb_headers(cfg)
    if prov == 'cape':
        st, js = http('%s/apiv2/tasks/status/%s/' % (url, task), headers=hdr, verify=verify)
        state = js.get('data') if isinstance(js, dict) else None
        if state in ('failed_analysis', 'failed_processing', 'failed_reporting'):
            return 'error', {'error': state}
        if state != 'reported':
            return 'running', None
        st, rep = http('%s/apiv2/tasks/get/report/%s/json/' % (url, task), headers=hdr, verify=verify, timeout=120)
        if not isinstance(rep, dict):
            return 'error', {'error': 'отчёт не получен (HTTP %s)' % st}
        sigs = [{'name': x.get('name'), 'description': x.get('description'), 'severity': x.get('severity')}
                for x in (rep.get('signatures') or [])][:40]
        fam = rep.get('malfamily') or ''
        if not fam and isinstance(rep.get('detections'), list) and rep['detections']:
            fam = rep['detections'][0].get('family', '') if isinstance(rep['detections'][0], dict) else str(rep['detections'][0])
        return 'done', {'score': float(rep.get('malscore') or 0), 'family': fam, 'signatures': sigs,
                        'url': '%s/analysis/%s/' % (url, task)}
    if prov == 'cuckoo':
        st, js = http('%s/tasks/view/%s' % (url, task), headers=hdr, verify=verify)
        state = (js.get('task') or {}).get('status') if isinstance(js, dict) else None
        if state in ('failed_analysis', 'failed_processing', 'failed_reporting'):
            return 'error', {'error': state}
        if state != 'reported':
            return 'running', None
        st, rep = http('%s/tasks/report/%s' % (url, task), headers=hdr, verify=verify, timeout=120)
        if not isinstance(rep, dict):
            return 'error', {'error': 'отчёт не получен (HTTP %s)' % st}
        sigs = [{'name': x.get('name'), 'description': x.get('description'), 'severity': x.get('severity')}
                for x in (rep.get('signatures') or [])][:40]
        return 'done', {'score': float((rep.get('info') or {}).get('score') or 0), 'family': '', 'signatures': sigs,
                        'url': '%s/analysis/%s/' % (url.rsplit(':', 1)[0] if url.count(':') > 1 else url, task)}
    if prov == 'virustotal':
        st, js = http('%s/analyses/%s' % (VT_API, task), headers=hdr)
        a = (js.get('data') or {}).get('attributes') if isinstance(js, dict) else None
        if not a:
            return 'error', {'error': sb_error(st, js)}
        if a.get('status') != 'completed':
            return 'running', None
        stats = a.get('stats') or {}
        mal, sus = stats.get('malicious', 0), stats.get('suspicious', 0)
        total = sum(v for v in stats.values() if isinstance(v, int)) or 1
        names = sorted({r.get('result') for r in (a.get('results') or {}).values()
                        if r.get('category') == 'malicious' and r.get('result')})
        sigs = [{'name': n, 'description': '', 'severity': 3} for n in names[:20]]
        # 0..10 like a sandbox score: 3+ engines = malicious
        score = 10.0 if mal >= 10 else (7.0 if mal >= 3 else (4.0 if mal or sus >= 2 else 0.0))
        return 'done', {'score': score, 'family': names[0] if names else '', 'signatures': sigs,
                        'engines': '%d/%d' % (mal, total), 'url': 'https://www.virustotal.com/gui/file/%s' % sha256}
    return 'error', {'error': 'песочница не настроена'}


# ---------------------------------------------------------------------------------------------
# verdict

def judge(r):
    """returns (verdict, reason) from a files row (dict)"""
    reasons_bad, reasons_sus = [], []
    if r.get('clamav'):
        reasons_bad.append('ClamAV: %s' % r['clamav'])
    intel = r.get('intel') or {}
    mb = intel.get('malwarebazaar') or {}
    if mb.get('found'):
        reasons_bad.append('MalwareBazaar: %s' % (mb.get('signature') or 'известный вредонос'))
    vt = intel.get('virustotal') or {}
    if vt.get('found'):
        if vt.get('malicious', 0) >= 3:
            reasons_bad.append('VirusTotal: %d/%d %s' % (vt['malicious'], vt.get('total', 0), vt.get('label') or ''))
        elif vt.get('malicious', 0) >= 1 or vt.get('suspicious', 0) >= 2:
            reasons_sus.append('VirusTotal: %d/%d' % (vt.get('malicious', 0), vt.get('total', 0)))
    rep = r.get('sb_report') or {}
    if r.get('sb_state') == 'done' and rep:
        score = float(rep.get('score') or 0)
        txt = 'Песочница: %.1f/10%s' % (score, (' ' + rep['family']) if rep.get('family') else '')
        if score >= 6.5:
            reasons_bad.append(txt)
        elif score >= 3.5:
            reasons_sus.append(txt)
    if reasons_bad:
        return 'malicious', '; '.join(reasons_bad)
    if reasons_sus:
        return 'suspicious', '; '.join(reasons_sus)
    if r.get('sb_state') in ('queued', 'running'):
        return 'pending', 'в песочнице'
    # known to ~70 engines and none flags it, or run in the sandbox without findings: clean
    if (vt.get('found') and not vt.get('malicious')) or r.get('sb_state') == 'done':
        return 'clean', 'чисто: ' + ', '.join(x for x, ok in (
            ('ClamAV', r.get('clamav') == ''), ('VirusTotal', vt.get('found')), ('песочница', r.get('sb_state') == 'done')) if ok)
    checked = [x for x, ok in (('ClamAV', r.get('clamav') == ''), ('MalwareBazaar', mb.get('found') is False),
                                ('VirusTotal', vt.get('found') is False)) if ok]
    if not checked:
        return 'unknown', 'проверка не выполнена'
    return 'unknown', 'ничего не найдено: ' + ', '.join(checked)


def save_row(con, r):
    r['verdict'], r['reason'] = judge(r)
    r['updated'] = time.time()
    cols = [c for c in r.keys() if c in FILE_COLS]
    vals = [json.dumps(r[c], ensure_ascii=False) if c in ('intel', 'sb_report') and r[c] is not None else r[c] for c in cols]
    con.execute('insert or replace into files(%s) values (%s)' % (','.join(cols), ','.join('?' * len(cols))), vals)
    return r


FILE_COLS = ['sha256', 'md5', 'sha1', 'first_seen', 'last_seen', 'seen', 'name', 'size', 'magic', 'kind', 'source',
             'proto', 'client', 'server', 'host', 'url', 'stored', 'clamav', 'clamav_at', 'intel', 'intel_at',
             'sb_provider', 'sb_task', 'sb_state', 'sb_at', 'sb_score', 'sb_report', 'verdict', 'reason', 'updated']


def load_row(con, sha256):
    r = con.execute('select * from files where sha256=?', (sha256,)).fetchone()
    if not r:
        return None
    d = dict(r)
    for k in ('intel', 'sb_report'):
        try:
            d[k] = json.loads(d[k]) if d.get(k) else None
        except ValueError:
            d[k] = None
    return d


def want_sandbox(r, cfg, force=False):
    if cfg['sandbox']['provider'] == 'none' or not r.get('stored') or not os.path.exists(r['stored']):
        return False
    if r.get('sb_state') in ('queued', 'running', 'done') and not force:
        return False
    if force:
        return True
    mode = cfg['sandbox']['submit']
    if mode == 'manual':
        return False
    if mode == 'all':
        return True
    # unknown: only what nobody has judged yet
    verdict, _ = judge(r)
    return verdict in ('unknown', 'suspicious')


def analyse(con, r, cfg, force_sandbox=False):
    """ClamAV + reputation for a row with a stored file (or hash only); queue for the sandbox"""
    now = time.time()
    if r.get('stored') and os.path.exists(r['stored']):
        r['clamav'] = clamav_scan(r['stored'])
        r['clamav_at'] = now
    if (cfg['intel']['mb_key'] or cfg['intel']['vt_key']) and is_sha256(r['sha256']):
        cached = r.get('intel') or {}
        fresh = r.get('intel_at') and now - r['intel_at'] < 6 * 3600 and not any('error' in v for v in cached.values())
        if not fresh or force_sandbox:
            r['intel'] = intel_lookup(r['sha256'], cfg)
            r['intel_at'] = now
    if want_sandbox(r, cfg, force_sandbox):
        r['sb_provider'] = cfg['sandbox']['provider']
        r['sb_state'] = 'queued'
        r['sb_task'] = None
        r['sb_report'] = None
        r['sb_at'] = now
    save_row(con, r)
    act_on_verdict(con, r, cfg)
    return r


def act_on_verdict(con, r, cfg):
    if not cfg['action']['autoblock']:
        return
    if r['verdict'] == 'malicious' or (r['verdict'] == 'suspicious' and cfg['action']['suspicious']):
        if not con.execute('select 1 from blocklist where sha256=?', (r['sha256'],)).fetchone():
            con.execute('insert into blocklist(sha256, name, reason, added, auto) values (?,?,?,?,1)',
                        (r['sha256'], r.get('name') or '', r.get('reason') or '', time.time()))
            meta_set(con, 'blocklist_dirty', 1)


# ---------------------------------------------------------------------------------------------
# intake: Suricata file-store v2 (<dir>/<xx>/<sha256> + <sha256>.<ts>.<n>.json written with write-fileinfo)

def intake_filestore(con, cfg):
    taken = 0
    if not os.path.isdir(FILESTORE):
        return 0
    maxsize = cfg['files']['maxsize'] << 20
    for meta in sorted(glob.glob(FILESTORE + '/[0-9a-f][0-9a-f]/*.json'))[:500]:
        try:
            with open(meta) as f:
                ev = json.loads(f.readline() or '{}')
        except (OSError, ValueError):
            ev = {}
        fi = ev.get('fileinfo') or {}
        sha = (fi.get('sha256') or os.path.basename(meta).split('.')[0]).lower()
        data = os.path.join(os.path.dirname(meta), sha)
        try:
            os.unlink(meta)
        except OSError:
            pass
        if not is_sha256(sha):
            continue
        src, dst = ev.get('src_ip', ''), ev.get('dest_ip', '')
        client, server = (src, dst) if private(src) and not private(dst) else (dst, src)
        httpd = ev.get('http') or {}
        smtp = ev.get('email') or {}
        name = os.path.basename(fi.get('filename') or '') or sha[:12]
        r = load_row(con, sha)
        now = time.time()
        if r:
            r['last_seen'] = now
            r['seen'] = (r.get('seen') or 1) + 1
            r['client'] = client or r.get('client')
            if not os.path.exists(data) or (r.get('stored') and os.path.exists(r['stored'])):
                # seen before and already analysed: count it, keep the old verdict
                if os.path.exists(data):
                    os.unlink(data)
                save_row(con, r)
                act_on_verdict(con, r, cfg)
                continue
        else:
            r = {'sha256': sha, 'first_seen': now, 'last_seen': now, 'seen': 1, 'name': name[:200],
                 'size': fi.get('size') or 0, 'magic': (fi.get('magic') or '')[:200],
                 'source': 'traffic', 'proto': ev.get('app_proto') or ev.get('proto') or '',
                 'client': client, 'server': server, 'host': httpd.get('hostname') or smtp.get('from') or '',
                 'url': (httpd.get('url') or '')[:500], 'sb_state': ''}
            r['kind'] = kind_of(r['magic'], name)
        if os.path.exists(data):
            size = os.path.getsize(data)
            if size > maxsize:
                os.unlink(data)
                r['size'] = size
                r['stored'] = None
            else:
                dest = os.path.join(STORE, sha)
                shutil.move(data, dest)
                os.chmod(dest, 0o600)
                r['stored'] = dest
                r['size'] = size
                h = hashes(dest)
                r['md5'], r['sha1'] = h['md5'], h['sha1']
        analyse(con, r, cfg)
        taken += 1
    # data files whose json was lost (suricata restart): take them as well
    for data in glob.glob(FILESTORE + '/[0-9a-f][0-9a-f]/' + '[0-9a-f]' * 64)[:200]:
        if os.path.getmtime(data) > time.time() - 120:
            continue
        sha = os.path.basename(data)
        if load_row(con, sha):
            os.unlink(data)
            continue
        dest = os.path.join(STORE, sha)
        shutil.move(data, dest)
        os.chmod(dest, 0o600)
        h = hashes(dest)
        mg = file_magic(dest)
        r = {'sha256': sha, 'md5': h['md5'], 'sha1': h['sha1'], 'first_seen': time.time(), 'last_seen': time.time(),
             'seen': 1, 'name': sha[:12], 'size': os.path.getsize(dest), 'magic': mg, 'kind': kind_of(mg),
             'source': 'traffic', 'stored': dest, 'sb_state': ''}
        analyse(con, r, cfg)
        taken += 1
    return taken


def sandbox_work(con, cfg):
    if cfg['sandbox']['provider'] == 'none':
        return
    now = time.time()
    rows = con.execute("select sha256 from files where sb_state in ('queued','running') order by sb_at limit 20").fetchall()
    for (sha,) in rows:
        r = load_row(con, sha)
        try:
            if r['sb_state'] == 'queued':
                if not r.get('stored') or not os.path.exists(r['stored']):
                    r['sb_state'], r['sb_report'] = 'error', {'error': 'файл уже удалён'}
                else:
                    r['sb_task'] = sb_submit(r['stored'], r.get('name'), cfg)
                    r['sb_provider'] = cfg['sandbox']['provider']
                    r['sb_state'], r['sb_at'] = 'running', now
            elif r['sb_state'] == 'running':
                if r.get('sb_provider') != cfg['sandbox']['provider']:
                    r['sb_state'], r['sb_report'] = 'error', {'error': 'песочница сменилась'}
                else:
                    state, rep = sb_poll(r['sb_task'], sha, cfg)
                    if state != 'running':
                        r['sb_state'], r['sb_report'] = state, rep
                        r['sb_score'] = rep.get('score') if state == 'done' else None
                    elif now - (r.get('sb_at') or now) > 3 * 3600:
                        r['sb_state'], r['sb_report'] = 'error', {'error': 'нет ответа 3 часа'}
        except (OSError, ValueError, RuntimeError) as e:
            if r['sb_state'] == 'queued' and now - (r.get('sb_at') or now) < 1800:
                continue        # sandbox down: retry for half an hour
            r['sb_state'], r['sb_report'] = 'error', {'error': str(e)[:160]}
        save_row(con, r)
        act_on_verdict(con, r, cfg)


def cleanup(con, cfg):
    now = time.time()
    keep = cfg['files']['keep_days'] * 86400
    for r in con.execute('select sha256, stored, verdict, sb_state, last_seen from files where stored is not null').fetchall():
        if r['sb_state'] in ('queued', 'running'):
            continue
        if (r['verdict'] == 'clean' and not cfg['files']['keep_clean']) or now - (r['last_seen'] or now) > keep:
            if r['stored'] and os.path.exists(r['stored']):
                os.unlink(r['stored'])
            con.execute('update files set stored=null where sha256=?', (r['sha256'],))
    # quarantine cap: 2 GB, oldest not-malicious files go first
    total = 0
    rows = con.execute("select sha256, stored, verdict from files where stored is not null "
                       "order by (verdict in ('malicious','suspicious')) desc, last_seen desc").fetchall()
    for r in rows:
        try:
            total += os.path.getsize(r['stored'])
        except OSError:
            continue
        if total > QUARANTINE_MAX and r['verdict'] not in ('malicious', 'suspicious'):
            os.unlink(r['stored'])
            con.execute('update files set stored=null where sha256=?', (r['sha256'],))
    # records themselves: 90 days, block list keeps its own copy
    con.execute('delete from files where last_seen < ?', (now - 90 * 86400,))
    # Suricata's own temp files of interrupted transfers
    for t in glob.glob(FILESTORE + '/tmp/*'):
        try:
            if os.path.getmtime(t) < now - 6 * 3600:
                os.unlink(t)
        except OSError:
            pass


# ---------------------------------------------------------------------------------------------
# block list -> ClamAV + Suricata

def write_if_changed(path, content):
    try:
        with open(path) as f:
            if f.read() == content:
                return False
    except OSError:
        pass
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + '.tmp'
    with open(tmp, 'w') as f:
        f.write(content)
    os.chmod(tmp, 0o644)
    os.replace(tmp, path)
    return True


def suricata_rules(cfg, have_hashes):
    lines = ['# jk-ufw antivirus: generated by /usr/local/opnsense/scripts/jkufw/av.py, do not edit', '']
    sid = SID_BASE
    if cfg['files']['enabled']:
        for kind in cfg['files']['types']:
            for proto in PROTOS:
                for needle in MAGIC.get(kind, []):
                    sid += 1
                    lines.append('alert %s any any -> any any (msg:"jk-ufw AV: extract %s (%s)"; file.magic; content:"%s"; '
                                 'nocase; filestore; noalert; classtype:misc-activity; sid:%d; rev:1;)'
                                 % (proto, kind, needle.strip(), needle.strip(), sid))
    if have_hashes:
        for i, proto in enumerate(PROTOS):
            lines.append('drop %s any any -> any any (msg:"jk-ufw AV: blocked malicious file (hash list)"; '
                         'filesha256:%s; classtype:trojan-activity; priority:1; sid:%d; rev:1;)'
                         % (proto, BADLIST[len(ROOT):] if ROOT else BADLIST, SID_BASE + 900 + i))
    return '\n'.join(lines) + '\n'


def sync(con=None, cfg=None):
    own = con is None
    con = con or db()
    cfg = cfg or settings()
    rows = con.execute('select sha256, name from blocklist order by added').fetchall()
    changed_rules = False
    write_if_changed(BADLIST, ''.join('%s\n' % r['sha256'] for r in rows))
    hsb = ''.join('%s:*:JkUfw.Blocked.%s:73\n' % (r['sha256'], r['sha256'][:12]) for r in rows)
    reload_clam = False
    if os.path.isdir(os.path.dirname(HSB)):
        if rows:
            reload_clam = write_if_changed(HSB, hsb)
        elif os.path.exists(HSB):
            os.unlink(HSB)
            reload_clam = True
    if reload_clam and clamd_alive():
        try:
            clamd_cmd('RELOAD', timeout=10)
        except OSError:
            pass
    if os.path.isdir(os.path.dirname(RULES)):
        changed_rules = write_if_changed(RULES, suricata_rules(cfg, bool(rows)))
    meta_set(con, 'blocklist_dirty', 0)
    meta_set(con, 'synced', time.time())
    con.commit()
    if own:
        con.close()
    if changed_rules and suricata_running():
        subprocess.run(['/usr/local/sbin/configctl', 'ids', 'reload'], capture_output=True, timeout=300)
    return {'blocked': len(rows), 'rules_changed': changed_rules, 'clamav_reloaded': reload_clam}


def suricata_running():
    try:
        with open(SURICATA_PID) as f:
            os.kill(int(f.read().strip()), 0)
        return True
    except (OSError, ValueError):
        return False


# ---------------------------------------------------------------------------------------------
# proxy detections from logs (clamd FOUND lines from c-icap, matched with squid 403 entries)

LOG_RE = re.compile(r'(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:?\d\d)?)\s.*?\b(instream|stream)\(([^)]*)\):\s+(.+?)\s+FOUND')


def parse_ts(v):
    v = v.replace('Z', '+00:00')
    try:
        if re.search(r'[+-]\d\d:?\d\d$', v):
            return datetime.datetime.fromisoformat(re.sub(r'([+-]\d\d)(\d\d)$', r'\1:\2', v)).timestamp()
        return time.mktime(time.strptime(v[:19], '%Y-%m-%dT%H:%M:%S'))
    except ValueError:
        return 0.0


def web_events(limit=50):
    files = sorted(glob.glob(CLAMD_LOGS + '/clamd_*.log'))[-3:]
    hits = []
    for fn in files:
        try:
            with open(fn, errors='replace') as f:
                for line in f:
                    if 'FOUND' not in line:
                        continue
                    m = LOG_RE.search(line)
                    # c-icap talks to clamd over TCP (127.0.0.1@port); our own scans use the socket
                    if not m or '@' not in m.group(3):
                        continue
                    ts = parse_ts(m.group(1))
                    hits.append({'time': ts, 'signature': m.group(4)})
        except OSError:
            continue
    hits = hits[-limit:]
    # squid native log: "time elapsed client code/status bytes method URL ..."
    blocked = []
    try:
        with open(SQUID_LOG, 'rb') as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - (4 << 20)))
            for line in f.read().decode('utf-8', 'replace').splitlines():
                parts = line.split()
                if len(parts) > 6 and parts[3].endswith('/403'):
                    try:
                        blocked.append((float(parts[0]), parts[2], parts[6]))
                    except ValueError:
                        pass
    except OSError:
        pass
    used = set()
    for h in hits:
        best = None
        for i, (t, client, url) in enumerate(blocked):
            if i in used or abs(t - h['time']) > 6:
                continue
            if best is None or abs(t - h['time']) < abs(blocked[best][0] - h['time']):
                best = i
        if best is not None:
            used.add(best)
            h['client'], h['url'] = blocked[best][1], blocked[best][2][:300]
    return list(reversed(hits))


# ---------------------------------------------------------------------------------------------
# commands

def cmd_status():
    cfg = settings()
    con = db()
    day = time.time() - 86400
    q = lambda sql, *a: con.execute(sql, a).fetchone()[0]
    out = {
        'clamd': {'socket': os.path.exists(CLAMD_SOCK), 'running': clamd_alive()},
        'suricata': {'running': suricata_running(), 'rules': os.path.exists(RULES),
                     'filestore': os.path.isdir(FILESTORE)},
        'files_24h': q('select count(*) from files where last_seen > ?', day),
        'malicious_24h': q("select count(*) from files where last_seen > ? and verdict='malicious'", day),
        'suspicious_24h': q("select count(*) from files where last_seen > ? and verdict='suspicious'", day),
        'files_total': q('select count(*) from files'),
        'sandbox_queue': q("select count(*) from files where sb_state in ('queued','running')"),
        'quarantine': q('select count(*) from files where stored is not null'),
        'blocked_hashes': q('select count(*) from blocklist'),
        'worker_at': float(meta_get(con, 'worker_at', 0) or 0),
        'worker_error': meta_get(con, 'worker_error', ''),
        'settings': {'files': cfg['files']['enabled'], 'sandbox': cfg['sandbox']['provider']},
    }
    if out['clamd']['running']:
        try:
            v = clamd_cmd('VERSION', timeout=5)       # ClamAV 1.4.1/27456/Sat Nov 14 09:21:02 2026
            parts = v.split('/')
            out['clamd'].update({'version': parts[0].replace('ClamAV ', ''),
                                 'db_version': parts[1] if len(parts) > 1 else '',
                                 'db_date': parts[2] if len(parts) > 2 else ''})
        except OSError:
            pass
    web = web_events(500)
    out['web_blocked_24h'] = len([h for h in web if h['time'] > day])
    con.close()
    return out


def cmd_events(limit):
    con = db()
    files = [row_dict(r) for r in con.execute(
        "select * from files where verdict in ('malicious','suspicious') order by last_seen desc limit ?", (limit,))]
    con.close()
    ev = [{'type': 'file', 'time': f['last_seen'], 'verdict': f['verdict'], 'name': f['name'], 'sha256': f['sha256'],
           'client': f['client'], 'host': f['host'], 'reason': f['reason'], 'source': f['source']} for f in files]
    ev += [{'type': 'web', 'time': h['time'], 'verdict': 'malicious', 'name': (h.get('url') or '').rsplit('/', 1)[-1][:80],
            'url': h.get('url'), 'client': h.get('client'), 'reason': 'ClamAV: %s' % h['signature'], 'source': 'web'}
           for h in web_events(limit)]
    ev.sort(key=lambda e: e['time'] or 0, reverse=True)
    return {'events': ev[:limit]}


def cmd_files(limit):
    con = db()
    rows = [row_dict(r) for r in con.execute('select * from files order by last_seen desc limit ?', (limit,))]
    blocked = {r['sha256'] for r in con.execute('select sha256 from blocklist')}
    for r in rows:
        r['blocked'] = r['sha256'] in blocked
    bl = [dict(r) for r in con.execute('select * from blocklist order by added desc limit 500')]
    con.close()
    return {'files': rows, 'blocklist': bl}


def cmd_file(sha):
    con = db()
    r = con.execute('select * from files where sha256=? or md5=? or sha1=?', (sha, sha, sha)).fetchone()
    if not r:
        return {'error': 'not found'}
    d = row_dict(r, full=True)
    d['blocked'] = bool(con.execute('select 1 from blocklist where sha256=?', (d['sha256'],)).fetchone())
    con.close()
    return d


def cmd_upload(path, name):
    cfg = settings()
    if not os.path.isfile(path):
        return {'error': 'файл не найден'}
    con = db()
    h = hashes(path)
    dest = os.path.join(STORE, h['sha256'])
    shutil.move(path, dest)
    os.chmod(dest, 0o600)
    mg = file_magic(dest)
    now = time.time()
    r = load_row(con, h['sha256']) or {'sha256': h['sha256'], 'first_seen': now, 'seen': 0, 'sb_state': ''}
    r.update({'md5': h['md5'], 'sha1': h['sha1'], 'last_seen': now, 'seen': (r.get('seen') or 0) + 1,
              'name': os.path.basename(name or '')[:200] or h['sha256'][:12], 'size': os.path.getsize(dest), 'magic': mg,
              'kind': kind_of(mg, name), 'source': r.get('source') or 'upload', 'stored': dest})
    r = analyse(con, r, cfg)
    con.commit()
    if meta_get(con, 'blocklist_dirty') == '1':
        sync(con, cfg)
    out = row_dict(con.execute('select * from files where sha256=?', (r['sha256'],)).fetchone(), full=True)
    con.close()
    return out


def cmd_lookup(value):
    cfg = settings()
    value = value.strip().lower()
    if not re.fullmatch(r'[0-9a-f]{32}|[0-9a-f]{40}|[0-9a-f]{64}', value):
        return {'error': 'нужен MD5, SHA-1 или SHA-256'}
    con = db()
    known = con.execute('select sha256 from files where sha256=? or md5=? or sha1=?', (value,) * 3).fetchone()
    if not known and not (cfg['intel']['mb_key'] or cfg['intel']['vt_key']):
        con.close()
        return {'error': 'для проверки хеша укажите ключ MalwareBazaar или VirusTotal'}
    if known:
        r = load_row(con, known['sha256'])
        r['intel_at'] = None
    else:
        sha = value
        intel = None
        if len(value) != 64:
            # MD5 / SHA-1 of a file never seen here: VirusTotal knows the SHA-256
            intel = intel_lookup(value, {'intel': {'mb_key': cfg['intel']['mb_key'], 'vt_key': cfg['intel']['vt_key']}})
            sha = ((intel.get('virustotal') or {}).get('sha256') or '').lower()
            if not is_sha256(sha):
                con.close()
                mb = intel.get('malwarebazaar') or {}
                return {'error': 'хеш не найден' + (' (MalwareBazaar: %s)' % mb['signature'] if mb.get('found') else ''),
                        'intel': intel}
        now = time.time()
        r = load_row(con, sha) or {'sha256': sha, 'first_seen': now, 'last_seen': now, 'seen': 1,
                                   'name': ((intel or {}).get('virustotal') or {}).get('name', ''), 'kind': 'other',
                                   'source': 'hash', 'sb_state': ''}
        if intel:
            r['intel'], r['intel_at'] = intel, now
        if len(value) == 32:
            r['md5'] = value
        elif len(value) == 40:
            r['sha1'] = value
    r = analyse(con, r, cfg)
    con.commit()
    if meta_get(con, 'blocklist_dirty') == '1':
        sync(con, cfg)
    out = row_dict(con.execute('select * from files where sha256=?', (r['sha256'],)).fetchone(), full=True)
    out['blocked'] = bool(con.execute('select 1 from blocklist where sha256=?', (r['sha256'],)).fetchone())
    con.close()
    return out


def cmd_rescan(sha, submit=False):
    cfg = settings()
    con = db()
    r = load_row(con, sha)
    if not r:
        return {'error': 'not found'}
    if submit:
        if cfg['sandbox']['provider'] == 'none':
            return {'error': 'песочница не настроена'}
        if not r.get('stored') or not os.path.exists(r['stored']):
            return {'error': 'файла уже нет в карантине, отправить нечего'}
    r['intel_at'] = None
    r = analyse(con, r, cfg, force_sandbox=submit)
    con.commit()
    if meta_get(con, 'blocklist_dirty') == '1':
        sync(con, cfg)
    out = row_dict(con.execute('select * from files where sha256=?', (sha,)).fetchone(), full=True)
    con.close()
    return out


def cmd_block(sha, name='', block=True):
    if not is_sha256(sha):
        return {'error': 'нужен SHA-256'}
    con = db()
    if block:
        r = load_row(con, sha) or {}
        con.execute('insert or replace into blocklist(sha256, name, reason, added, auto) values (?,?,?,?,0)',
                    (sha, name or r.get('name') or '', r.get('reason') or 'вручную', time.time()))
    else:
        con.execute('delete from blocklist where sha256=?', (sha,))
    con.commit()
    res = sync(con)
    con.close()
    return {'result': 'ok', 'blocked': res['blocked']}


def cmd_delete(sha):
    con = db()
    r = load_row(con, sha)
    if r and r.get('stored') and os.path.exists(r['stored']):
        os.unlink(r['stored'])
    con.execute('delete from files where sha256=?', (sha,))
    con.commit()
    con.close()
    return {'result': 'ok'}


def cmd_worker():
    os.makedirs(WORK, mode=0o700, exist_ok=True)
    lock = open(LOCK, 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return {'result': 'busy'}
    cfg = settings()
    con = db()
    err = ''
    taken = 0
    try:
        taken = intake_filestore(con, cfg)
        con.commit()
        sandbox_work(con, cfg)
        con.commit()
        cleanup(con, cfg)
        if meta_get(con, 'blocklist_dirty') == '1' or not os.path.exists(RULES) and cfg['files']['enabled']:
            sync(con, cfg)
    except Exception as e:      # keep the cron quiet, show the error on the page
        err = '%s: %s' % (type(e).__name__, e)
    meta_set(con, 'worker_at', time.time())
    meta_set(con, 'worker_error', err)
    con.commit()
    con.close()
    return {'result': 'ok' if not err else 'error', 'taken': taken, 'error': err}


def main(argv):
    cmd = argv[1] if len(argv) > 1 else 'status'
    arg = argv[2] if len(argv) > 2 else ''
    num = lambda v, d: max(1, min(1000, int(v))) if str(v).isdigit() else d
    sha_ok = lambda v: is_sha256(v.lower())
    if cmd == 'worker':
        out = cmd_worker()
    elif cmd == 'status':
        out = cmd_status()
    elif cmd == 'events':
        out = cmd_events(num(arg, 50))
    elif cmd == 'files':
        out = cmd_files(num(arg, 200))
    elif cmd == 'file':
        out = cmd_file(arg.lower())
    elif cmd == 'upload':
        out = cmd_upload(arg, argv[3] if len(argv) > 3 else '')
    elif cmd == 'lookup':
        out = cmd_lookup(arg)
    elif cmd in ('rescan', 'submit') and sha_ok(arg):
        out = cmd_rescan(arg.lower(), submit=cmd == 'submit')
    elif cmd in ('block', 'unblock'):
        out = cmd_block(arg.lower(), argv[3] if len(argv) > 3 else '', cmd == 'block')
    elif cmd == 'delete' and sha_ok(arg):
        out = cmd_delete(arg.lower())
    elif cmd == 'sync':
        out = sync()
    else:
        out = {'error': 'usage: av.py worker|status|events|files|file|upload|lookup|rescan|submit|block|unblock|delete|sync'}
    print(json.dumps(out, ensure_ascii=False))


if __name__ == '__main__':
    main(sys.argv)
