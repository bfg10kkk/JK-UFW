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
    jk-ufw: Telegram notifications.

    notify.py run      cron, every minute while enabled: new IDS/IPS alerts, gateway (WAN) state changes,
                       Web GUI logins -> Telegram. Starts at the end of each log, so old events are never sent.
                       Messages that cannot be delivered (e.g. while the WAN is down) are queued and retried.
    notify.py test     send a test message, print JSON result
    notify.py chats    list chats that wrote to the bot (getUpdates), print JSON
    notify.py status   print watcher state as JSON

    Paths can be overridden with environment variables (used by the tests): JKUFW_CONFIG, JKUFW_STATE,
    JKUFW_EVE, JKUFW_AUDIT, JKUFW_GATEWAYS (a command printing gateway_status.php JSON), JKUFW_API.
"""

import fcntl
import html
import json
import os
import re
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

CONFIG = os.environ.get('JKUFW_CONFIG', '/conf/config.xml')
STATE = os.environ.get('JKUFW_STATE', '/var/db/jkufw/notify.json')
EVE = os.environ.get('JKUFW_EVE', '/var/log/suricata/eve.json')
AUDIT = os.environ.get('JKUFW_AUDIT', '/var/log/audit/latest.log')
GATEWAYS = os.environ.get('JKUFW_GATEWAYS', '/usr/local/opnsense/scripts/routes/gateway_status.php')
API = os.environ.get('JKUFW_API', 'https://api.telegram.org')

MAX_READ = 4 * 1024 * 1024      # per log and run; a flood is summarised anyway
THREAT_COOLDOWN = 30 * 60       # same signature from the same source: once per 30 minutes
FAIL_COOLDOWN = 15 * 60         # failed logins from the same address: once per 15 minutes
MAX_PENDING = 30
MAX_TEXT = 3900                 # Telegram limit is 4096 characters

DOWN_STATES = ('down', 'force_down')
SEVERITY = {1: 'высокая', 2: 'средняя', 3: 'низкая'}

RE_LOGIN_OK = re.compile(r"user (\S+) authenticated successfully for WebGui \[[^\]]*\] at (\S+)")
RE_LOGIN_FAIL = re.compile(r"Web GUI authentication error for '(.*)' from (\S+)")


def load_settings():
    settings = {'enabled': False, 'token': '', 'chat_id': '', 'threats': True, 'threat_severity': 2,
                'wan': True, 'login_ok': True, 'login_fail': True, 'silent': False, 'hostname': socket.gethostname()}
    try:
        root = ET.parse(CONFIG).getroot()
    except (OSError, ET.ParseError):
        return settings
    node = root.find('OPNsense/JkUfw/notify')
    if node is not None:
        def flag(name, default):
            value = node.findtext(name)
            return default if value is None else value.strip() == '1'
        settings['enabled'] = flag('enabled', False)
        settings['token'] = (node.findtext('token') or '').strip()
        settings['chat_id'] = (node.findtext('chat_id') or '').strip()
        for name in ('threats', 'wan', 'login_ok', 'login_fail', 'silent'):
            settings[name] = flag(name, settings[name])
        try:
            settings['threat_severity'] = int(node.findtext('threat_severity') or 2)
        except ValueError:
            pass
    host = (root.findtext('system/hostname') or '').strip()
    domain = (root.findtext('system/domain') or '').strip()
    if host:
        settings['hostname'] = host + ('.' + domain if domain else '')
    return settings


def load_state():
    try:
        with open(STATE) as f:
            state = json.load(f)
            if isinstance(state, dict):
                return state
    except (OSError, ValueError):
        pass
    return {}


def save_state(state):
    os.makedirs(os.path.dirname(STATE), mode=0o700, exist_ok=True)
    tmp = STATE + '.tmp'
    with open(tmp, 'w') as f:
        json.dump(state, f)
    os.chmod(tmp, 0o600)
    os.replace(tmp, STATE)


class TelegramError(Exception):
    pass


def telegram(settings, method, params=None):
    if not settings['token']:
        raise TelegramError('не указан токен бота')
    url = '%s/bot%s/%s' % (API, settings['token'], method)
    data = urllib.parse.urlencode(params or {}).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=data), timeout=15) as resp:
            answer = json.load(resp)
    except urllib.error.HTTPError as e:
        try:
            answer = json.load(e)
        except ValueError:
            raise TelegramError('HTTP %d' % e.code)
    except (urllib.error.URLError, OSError, ValueError) as e:
        raise TelegramError('нет связи с api.telegram.org (%s)' % getattr(e, 'reason', e))
    if not answer.get('ok'):
        raise TelegramError(answer.get('description') or 'ошибка Telegram')
    return answer.get('result')


def send(settings, text):
    if not settings['chat_id']:
        raise TelegramError('не указан чат')
    telegram(settings, 'sendMessage', {
        'chat_id': settings['chat_id'],
        'text': text[:MAX_TEXT],
        'parse_mode': 'HTML',
        'disable_web_page_preview': 'true',
        'disable_notification': 'true' if settings['silent'] else 'false',
    })


def header(settings, icon, title):
    return '%s <b>%s</b>\n<code>%s</code>' % (icon, html.escape(title), html.escape(settings['hostname']))


def stamp(ts=None):
    return time.strftime('%d.%m.%Y %H:%M:%S', time.localtime(ts or time.time()))


def read_new_lines(state, key, path):
    """lines appended to path since the previous run; the first run only remembers the end of the file"""
    try:
        st = os.stat(path)
    except OSError:
        return []
    files = state.setdefault('files', {})
    prev = files.get(key)
    if prev is None:
        files[key] = {'ino': st.st_ino, 'pos': st.st_size}
        return []
    pos = prev.get('pos', 0)
    if prev.get('ino') != st.st_ino or st.st_size < pos:
        pos = 0     # rotated or truncated
    if st.st_size - pos > MAX_READ:
        pos = st.st_size - MAX_READ
    lines = []
    with open(path, 'rb') as f:
        f.seek(pos)
        chunk = f.read(st.st_size - pos)
    end = chunk.rfind(b'\n')
    if end >= 0:
        lines = chunk[:end].decode('utf-8', 'replace').splitlines()
        pos += end + 1
    files[key] = {'ino': st.st_ino, 'pos': pos}
    return lines


def cooled_down(state, key, period, now):
    cool = state.setdefault('cooldown', {})
    if now - cool.get(key, 0) < period:
        return False
    cool[key] = now
    return True


def check_threats(settings, state, now):
    lines = read_new_lines(state, 'eve', EVE)
    if not settings['threats']:
        return []
    groups = {}
    total = 0
    for line in lines:
        if '"alert"' not in line:
            continue
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        alert = ev.get('alert') or {}
        if ev.get('event_type') != 'alert' or int(alert.get('severity') or 3) > settings['threat_severity']:
            continue
        total += 1
        key = (str(alert.get('signature_id', '')), ev.get('src_ip', ''))
        g = groups.get(key)
        if g is None:
            g = groups[key] = {'ev': ev, 'count': 0, 'blocked': False}
        g['count'] += 1
        g['blocked'] = g['blocked'] or alert.get('action') == 'blocked'
    fresh = [g for k, g in groups.items() if cooled_down(state, 'ids:%s:%s' % k, THREAT_COOLDOWN, now)]
    if not fresh:
        return []
    fresh.sort(key=lambda g: (int(g['ev']['alert'].get('severity') or 3), -g['count']))
    blocked = sum(g['count'] for g in fresh if g['blocked'])
    title = 'Угроза заблокирована' if blocked and len(fresh) == 1 else 'Обнаружена угроза'
    if len(fresh) > 1:
        title = 'Угрозы: %d событий' % sum(g['count'] for g in fresh)
    parts = [header(settings, '🛡' if blocked else '⚠️', title)]
    for g in fresh[:5]:
        ev, alert = g['ev'], g['ev']['alert']
        src = '%s:%s' % (ev.get('src_ip', '?'), ev.get('src_port', '')) if ev.get('src_port') else ev.get('src_ip', '?')
        dst = '%s:%s' % (ev.get('dest_ip', '?'), ev.get('dest_port', '')) if ev.get('dest_port') else ev.get('dest_ip', '?')
        parts.append('\n<b>%s</b>\n%s → %s%s\n%s · важность: %s%s' % (
            html.escape(alert.get('signature') or 'sid %s' % alert.get('signature_id')),
            html.escape(src), html.escape(dst),
            (' (%s)' % html.escape(ev['proto'])) if ev.get('proto') else '',
            '⛔ заблокировано' if g['blocked'] else '👁 только обнаружено',
            SEVERITY.get(int(alert.get('severity') or 3), '?'),
            (' · ×%d' % g['count']) if g['count'] > 1 else ''))
    if len(fresh) > 5:
        parts.append('\n…и ещё %d' % (len(fresh) - 5))
    parts.append('\n🕒 %s' % stamp(now))
    return [('threat', '\n'.join(parts))]


def gateway_status():
    cmd = GATEWAYS.split()
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout
    data = json.loads(out or '{}')
    return data if isinstance(data, dict) else {}


def check_gateways(settings, state, now):
    if not settings['wan']:
        return []
    try:
        current = gateway_status()
    except (OSError, ValueError, subprocess.SubprocessError):
        return []
    known = state.get('gateways')
    messages = []
    result = {}
    for name, gw in current.items():
        down = str(gw.get('status', 'none')) in DOWN_STATES
        prev = (known or {}).get(name)
        since = prev.get('since', now) if prev and prev.get('down') == down else now
        result[name] = {'down': down, 'since': since}
        if known is None or prev is None or prev.get('down') == down:
            continue
        address = gw.get('address') if gw.get('address') not in (None, '', '~') else ''
        if down:
            text = header(settings, '🔴', 'Пропал интернет: %s' % name)
            text += '\nШлюз %s не отвечает%s.' % (html.escape(address) or html.escape(name),
                                                 ' (принудительно выключен)' if gw.get('status') == 'force_down' else '')
            if gw.get('loss') not in (None, '', '~'):
                text += '\nПотери: %s' % html.escape(str(gw['loss']))
        else:
            text = header(settings, '🟢', 'Интернет восстановлен: %s' % name)
            text += '\nНе было связи: %s.' % duration(now - prev.get('since', now))
        messages.append(('wan', text + '\n🕒 %s' % stamp(now)))
    state['gateways'] = result
    return messages


def duration(seconds):
    seconds = int(max(seconds, 0))
    if seconds < 60:
        return '%d с' % seconds
    if seconds < 3600:
        return '%d мин' % (seconds // 60)
    if seconds < 86400:
        return '%d ч %d мин' % (seconds // 3600, seconds % 3600 // 60)
    return '%d д %d ч' % (seconds // 86400, seconds % 86400 // 3600)


def check_logins(settings, state, now):
    lines = read_new_lines(state, 'audit', AUDIT)
    if not (settings['login_ok'] or settings['login_fail']):
        return []
    messages = []
    fails = {}
    for line in lines:
        m = RE_LOGIN_OK.search(line)
        if m and settings['login_ok']:
            text = header(settings, '🔑', 'Вход в веб-интерфейс')
            text += '\nПользователь <b>%s</b> с адреса <code>%s</code>' % (html.escape(m.group(1)), html.escape(m.group(2)))
            messages.append(('login', text + '\n🕒 %s' % stamp(now)))
            continue
        m = RE_LOGIN_FAIL.search(line)
        if m and settings['login_fail']:
            f = fails.setdefault(m.group(2), {'users': [], 'count': 0})
            f['count'] += 1
            if m.group(1) not in f['users']:
                f['users'].append(m.group(1))
    for address, f in fails.items():
        if not cooled_down(state, 'fail:%s' % address, FAIL_COOLDOWN, now):
            continue
        text = header(settings, '🚫', 'Неудачный вход в веб-интерфейс')
        text += '\n%s с адреса <code>%s</code>\nЛогин: %s' % (
            'Попыток: %d' % f['count'] if f['count'] > 1 else 'Неверный логин или пароль',
            html.escape(address), ', '.join('<b>%s</b>' % html.escape(u or '(пусто)') for u in f['users'][:5]))
        messages.append(('login_fail', text + '\n🕒 %s' % stamp(now)))
    return messages


def deliver(settings, state, messages, now):
    pending = state.get('pending', []) + [{'type': t, 'text': text, 'ts': now} for t, text in messages]
    left = []
    error = None
    for item in pending:
        if error is None:
            try:
                text = item['text']
                if now - item.get('ts', now) > 120:
                    text += '\n<i>(доставлено с задержкой: %s)</i>' % duration(now - item['ts'])
                send(settings, text)
                state['sent'] = state.get('sent', 0) + 1
                state['last_sent'] = now
                history = state.setdefault('history', [])
                history.insert(0, {'type': item.get('type'), 'ts': item.get('ts', now)})
                del history[20:]
                continue
            except TelegramError as e:
                error = str(e)
        left.append(item)
    state['pending'] = left[-MAX_PENDING:]
    if error:
        state['last_error'] = {'ts': now, 'message': error}
    elif pending:
        state.pop('last_error', None)


def cmd_run(settings):
    now = int(time.time())
    state = load_state()
    if not settings['enabled']:
        return
    if now - state.get('last_run', 0) > 600:
        # first run, or the watcher was off: start from the current end of the logs instead of replaying a backlog
        state.pop('files', None)
        state.pop('gateways', None)
    messages = []
    for check in (check_gateways, check_threats, check_logins):
        try:
            messages += check(settings, state, now)
        except Exception as e:     # one broken source must not stop the others
            state['last_error'] = {'ts': now, 'message': '%s: %s' % (check.__name__, e)}
    if messages or state.get('pending'):
        deliver(settings, state, messages, now)
    state['last_run'] = now
    save_state(state)


def cmd_test(settings):
    text = header(settings, '✅', 'Тестовое сообщение')
    text += ('\nУведомления jk-ufw работают. Сюда будут приходить угрозы, пропадание интернета и входы '
             'в веб-интерфейс.\n🕒 %s' % stamp())
    try:
        send(settings, text)
    except TelegramError as e:
        return {'status': 'error', 'message': str(e)}
    return {'status': 'ok'}


def cmd_chats(settings):
    try:
        me = telegram(settings, 'getMe')
        updates = telegram(settings, 'getUpdates', {'limit': 100, 'allowed_updates': '[]'})
    except TelegramError as e:
        return {'status': 'error', 'message': str(e)}
    chats = {}
    for upd in updates or []:
        for key in ('message', 'edited_message', 'channel_post', 'my_chat_member'):
            chat = (upd.get(key) or {}).get('chat')
            if chat and 'id' in chat:
                name = chat.get('title') or ' '.join(filter(None, [chat.get('first_name'), chat.get('last_name')]))
                chats[chat['id']] = {'id': str(chat['id']), 'type': chat.get('type', ''), 'name': name,
                                     'username': chat.get('username', '')}
    return {'status': 'ok', 'bot': (me or {}).get('username', ''), 'chats': list(chats.values())}


def cmd_status(settings):
    state = load_state()
    return {
        'status': 'ok',
        'enabled': settings['enabled'],
        'configured': bool(settings['token'] and settings['chat_id']),
        'ids_log': os.path.exists(EVE),
        'last_run': state.get('last_run'),
        'last_sent': state.get('last_sent'),
        'sent': state.get('sent', 0),
        'pending': len(state.get('pending', [])),
        'last_error': state.get('last_error'),
        'history': state.get('history', [])[:10],
        'gateways': {k: ('down' if v.get('down') else 'up') for k, v in (state.get('gateways') or {}).items()},
        'now': int(time.time()),
    }


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'status'
    settings = load_settings()
    if action == 'run':
        os.makedirs(os.path.dirname(STATE), mode=0o700, exist_ok=True)
        with open(STATE + '.lock', 'w') as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except OSError:
                return      # previous run still busy (slow network)
            cmd_run(settings)
        return
    handlers = {'test': cmd_test, 'chats': cmd_chats, 'status': cmd_status}
    if action not in handlers:
        print(json.dumps({'status': 'error', 'message': 'unknown action'}))
        sys.exit(1)
    print(json.dumps(handlers[action](settings), ensure_ascii=False))


if __name__ == '__main__':
    main()
