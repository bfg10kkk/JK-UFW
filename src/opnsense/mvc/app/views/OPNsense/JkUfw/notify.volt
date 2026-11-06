{#
 # Copyright (c) 2026 jk8s and jk-ufw contributors
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without modification,
 # are permitted provided that the following conditions are met:
 #
 # 1. Redistributions of source code must retain the above copyright notice,
 #    this list of conditions and the following disclaimer.
 #
 # 2. Redistributions in binary form must reproduce the above copyright notice,
 #    this list of conditions and the following disclaimer in the documentation
 #    and/or other materials provided with the distribution.
 #
 # THIS SOFTWARE IS PROVIDED “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,
 # INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 # AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 # AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 # OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 #
 # jk-ufw: Telegram notifications. Settings go through /api/jkufw/notify/*,
 # the watcher (scripts/jkufw/notify.py) runs from cron every minute while enabled.
 #}

<style>
.jkn { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; --tg:#2aabee; color:var(--t); font-size:13px; max-width:1180px; }
.jkn * { box-sizing:border-box; }
.jkn b, .jkn strong { font-family:inherit; font-weight:700; }
.jkn-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jkn-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:22px;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jkn-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkn-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkn-sub { color:var(--m); margin-top:2px; }
.jkn-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jkn-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jkn-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jkn-pill.bad i { background:var(--a); }
.jkn-pill.warn i { background:var(--warn); }
.jkn-head-r { margin-left:auto; display:flex; align-items:center; gap:12px; }
.jkn-master { display:flex; align-items:center; gap:10px; padding:10px 14px; border-radius:12px; background:var(--s); border:1px solid var(--b);
  cursor:pointer; user-select:none; font-weight:600; }
.jkn-grid { display:grid; grid-template-columns:minmax(0,1.3fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1000px) { .jkn-grid { grid-template-columns:minmax(0,1fr); } }
.jkn-grid > div { min-width:0; }
.jkn-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jkn-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; }
.jkn-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; }
.jkn-step { display:flex; gap:14px; padding:12px 0; border-top:1px solid var(--b); }
.jkn-step:first-of-type { border-top:0; padding-top:0; }
.jkn-num { flex:none; width:26px; height:26px; border-radius:50%; display:grid; place-items:center; font-weight:700; font-size:12px;
  background:var(--s2); border:1px solid var(--b2); color:var(--m); }
.jkn-step.done .jkn-num { background:var(--abg); border-color:var(--a); color:var(--a2); }
.jkn-step .sb { flex:1; min-width:0; }
.jkn-step .sn { font-weight:600; }
.jkn-step .sd { color:var(--m); font-size:12px; margin-top:2px; line-height:1.5; }
.jkn-step .sd a { color:var(--a2); }
.jkn-field { display:flex; gap:8px; margin-top:9px; }
.jkn input.jkn-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:8px 10px !important; width:100% !important; max-width:none !important; height:auto !important; margin:0 !important;
  font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkn input.jkn-in::placeholder { color:#5b5b66 !important; opacity:1; }
.jkn input.jkn-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg) !important; }
.jkn input.jkn-in.err { border-color:var(--a) !important; }
.jkn-errmsg { color:var(--a2); font-size:12px; margin-top:6px; }
.jkn-chats { display:flex; flex-wrap:wrap; gap:8px; margin-top:10px; }
.jkn-chip { display:inline-flex; align-items:center; gap:8px; padding:7px 13px; border-radius:999px; background:var(--s2); border:1px solid var(--b);
  cursor:pointer; font-weight:600; user-select:none; }
.jkn-chip:hover { border-color:var(--b2); }
.jkn-chip.sel { background:var(--abg); border-color:var(--a); color:#fff; }
.jkn-chip .fa { color:var(--m); }
.jkn-chip.sel .fa { color:var(--a2); }
.jkn-chip small { color:var(--m); font-weight:500; }
.jkn-row { display:flex; align-items:center; gap:14px; padding:12px 0; border-top:1px solid var(--b); cursor:pointer; }
.jkn-row:first-of-type { border-top:0; padding-top:0; }
.jkn-row .ri { flex:none; width:34px; height:34px; border-radius:9px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:15px; }
.jkn-row.on .ri { background:var(--abg); color:var(--a2); }
.jkn-row .rl { flex:1; min-width:0; }
.jkn-row .rn { font-weight:600; }
.jkn-row .rd { color:var(--m); font-size:12px; margin-top:2px; }
.jkn-sub-row { padding:0 0 12px 48px; }
.jkn-seg { display:inline-flex; background:var(--s2); border:1px solid var(--b); border-radius:9px; padding:3px; gap:2px; flex-wrap:wrap; }
.jkn-seg span { padding:5px 12px; border-radius:7px; cursor:pointer; color:var(--m); font-weight:600; font-size:12px; }
.jkn-seg span.sel { background:var(--a); color:#fff; }
.jkn-sw { flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; }
.jkn-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.on > .jkn-sw, .jkn-sw.on { background:var(--a); }
.on > .jkn-sw::after, .jkn-sw.on::after { left:16px; background:#fff; }
.jkn-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jkn-note .fa { margin-top:2px; }
.jkn-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jkn-note.warn .fa { color:var(--warn); }
.jkn-note.bad { background:var(--abg); border:1px solid rgba(229,32,46,.35); color:#ffc4c8; }
.jkn-note.bad .fa { color:var(--a2); }
.jkn-note.ok { background:rgba(34,197,94,.08); border:1px solid rgba(34,197,94,.28); color:#b6ecc9; }
.jkn-note.ok .fa { color:var(--ok); }
.jkn-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jkn-note a { color:var(--a2); }
.jkn-btn { border:0; border-radius:9px; padding:9px 16px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff; white-space:nowrap; }
.jkn-btn:hover { background:var(--a2); }
.jkn-btn[disabled] { opacity:.5; cursor:default; }
.jkn-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t); font-weight:600; }
.jkn-btn.ghost:hover { background:var(--h); }
.jkn-btn.icon { padding:8px 11px; }
.jkn-kpis { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:10px; margin-bottom:6px; }
.jkn-kpi { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; min-width:0; }
.jkn-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jkn-kpi .v { font-size:22px; font-weight:700; letter-spacing:-.02em; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkn-kpi .v.sm { font-size:15px; padding-top:6px; }
@media (max-width: 640px) { .jkn-kpi { padding:10px; } .jkn-kpi .l { white-space:normal; letter-spacing:.02em; font-size:10px; } .jkn-kpi .v.sm { font-size:13px; white-space:normal; } }
.jkn-phone { background:#0e1621; border-radius:14px; padding:14px; border:1px solid #1c2733; }
.jkn-phone-top { display:flex; align-items:center; gap:10px; padding-bottom:12px; margin-bottom:12px; border-bottom:1px solid #1c2733; }
.jkn-phone-top .av { width:34px; height:34px; border-radius:50%; display:grid; place-items:center; color:#fff;
  background:linear-gradient(145deg,var(--a2),#a5121c); font-size:14px; }
.jkn-phone-top .nm { font-weight:700; }
.jkn-phone-top .st { color:#6d8296; font-size:11.5px; }
.jkn-msg { background:#182533; border-radius:12px 12px 12px 4px; padding:9px 12px 7px; margin-bottom:8px; max-width:94%; line-height:1.45;
  font-size:12.5px; white-space:pre-wrap; word-break:break-word; color:#e9eef3; }
.jkn .jkn-msg code { background:none; border:0; color:#7fb8e8; padding:0; font-size:11.5px; }
.jkn-msg b { color:#fff; }
.jkn-msg .tm { display:block; text-align:right; color:#6d8296; font-size:10.5px; margin-top:2px; }
.jkn-msg.off { opacity:.35; }
.jkn-hist { margin-top:12px; }
.jkn-ev { display:flex; gap:10px; padding:8px 0; border-top:1px solid var(--b); align-items:center; }
.jkn-ev:first-child { border-top:0; }
.jkn-ev .fa { width:16px; text-align:center; color:var(--a2); }
.jkn-ev .en { flex:1; }
.jkn-ev .et { color:var(--m); font-size:11.5px; white-space:nowrap; }
.jkn-empty { color:var(--m); text-align:center; padding:16px 6px; }
.jkn-bar { position:sticky; bottom:0; z-index:5; display:flex; align-items:center; gap:14px; padding:14px 18px; margin-top:4px; flex-wrap:wrap;
  background:rgba(19,19,22,.92); backdrop-filter:blur(8px); border:1px solid var(--b); border-radius:12px; }
.jkn-bar .st { flex:1; color:var(--m); min-width:180px; }
.jkn-bar .st b { color:var(--t); }
.jkn .muted { color:var(--m); }
</style>

<div class="jkn" id="jkn">
  <div class="jkn-head">
    <div class="jkn-logo" id="jkn-logo"><i class="fa fa-paper-plane"></i></div>
    <div>
      <h1 class="jkn-title">Уведомления в Telegram <span class="jkn-pill" id="jkn-status"><i></i><span>…</span></span></h1>
      <div class="jkn-sub">Угрозы, пропадание интернета и входы в веб-интерфейс приходят вам в Telegram.</div>
    </div>
    <div class="jkn-head-r">
      <div class="jkn-master" id="jkn-enabled" role="switch" tabindex="0"><span>Уведомления</span><div class="jkn-sw"></div></div>
    </div>
  </div>

  <div class="jkn-grid">
    <div>
      <div class="jkn-card">
        <h3><i class="fa fa-plug"></i> Подключение бота</h3>
        <div class="jkn-step" id="jkn-s1">
          <div class="jkn-num">1</div>
          <div class="sb"><div class="sn">Создайте бота</div>
            <div class="sd">Откройте <a href="https://t.me/BotFather" target="_blank" rel="noopener">@BotFather</a> в Telegram,
              отправьте <code>/newbot</code>, придумайте имя. В ответ придёт токен вида <code>123456789:AAE…</code></div></div>
        </div>
        <div class="jkn-step" id="jkn-s2">
          <div class="jkn-num">2</div>
          <div class="sb"><div class="sn">Вставьте токен</div>
            <div class="jkn-field">
              <input class="jkn-in" id="jkn-token" type="password" autocomplete="off" spellcheck="false" placeholder="123456789:AAE…"/>
              <button class="jkn-btn ghost icon" id="jkn-eye" type="button" title="Показать"><i class="fa fa-eye"></i></button>
            </div>
            <div class="jkn-errmsg" id="jkn-token-err" style="display:none"></div></div>
        </div>
        <div class="jkn-step" id="jkn-s3">
          <div class="jkn-num">3</div>
          <div class="sb"><div class="sn">Выберите чат</div>
            <div class="sd">Напишите своему боту любое сообщение (или добавьте его в группу) и нажмите «Найти чат».</div>
            <div class="jkn-field">
              <input class="jkn-in" id="jkn-chat" type="text" autocomplete="off" spellcheck="false" placeholder="ID чата, например 987654321"/>
              <button class="jkn-btn ghost" id="jkn-find" type="button"><i class="fa fa-search"></i>&nbsp; Найти чат</button>
            </div>
            <div class="jkn-errmsg" id="jkn-chat-err" style="display:none"></div>
            <div class="jkn-chats" id="jkn-chats"></div></div>
        </div>
        <div class="jkn-step" id="jkn-s4">
          <div class="jkn-num">4</div>
          <div class="sb"><div class="sn">Проверьте</div>
            <div class="sd">Настройки сохранятся, и бот пришлёт тестовое сообщение.</div>
            <div class="jkn-field"><button class="jkn-btn" id="jkn-test" type="button"><i class="fa fa-paper-plane"></i>&nbsp; Отправить тест</button></div>
            <div id="jkn-test-res"></div></div>
        </div>
      </div>

      <div class="jkn-card">
        <h3><i class="fa fa-bell"></i> О чём сообщать</h3>
        <div id="jkn-events">
          <div class="jkn-row" data-k="threats"><div class="ri"><i class="fa fa-shield"></i></div>
            <div class="rl"><div class="rn">Угрозы (IDS/IPS)</div><div class="rd">Сработавшие правила Suricata. Одна и та же угроза от одного адреса не чаще раза в 30 минут.</div></div>
            <div class="jkn-sw"></div></div>
          <div class="jkn-sub-row" id="jkn-sev-row">
            <div class="jkn-seg" id="jkn-sev"><span data-v="1">Только высокая важность</span><span data-v="2">Высокая и средняя</span><span data-v="3">Все</span></div>
            <div class="jkn-note warn" id="jkn-ids-off" style="display:none"><i class="fa fa-exclamation-triangle"></i>
              <div>Защита от угроз сейчас выключена, сообщать будет не о чем. Включите её на странице
              <a href="/ui/ids/threats">Защита от угроз</a>.</div></div>
          </div>
          <div class="jkn-row" data-k="wan"><div class="ri"><i class="fa fa-globe"></i></div>
            <div class="rl"><div class="rn">Пропал и появился интернет</div><div class="rd">Шлюз WAN перестал отвечать и снова на связи. Пока интернета нет, сообщение ждёт и придёт сразу после восстановления.</div></div>
            <div class="jkn-sw"></div></div>
          <div class="jkn-row" data-k="login_ok"><div class="ri"><i class="fa fa-key"></i></div>
            <div class="rl"><div class="rn">Вход в веб-интерфейс</div><div class="rd">Кто и с какого адреса вошёл.</div></div>
            <div class="jkn-sw"></div></div>
          <div class="jkn-row" data-k="login_fail"><div class="ri"><i class="fa fa-user-times"></i></div>
            <div class="rl"><div class="rn">Неудачные попытки входа</div><div class="rd">Неверный логин или пароль. Попытки с одного адреса собираются в одно сообщение.</div></div>
            <div class="jkn-sw"></div></div>
          <div class="jkn-row" data-k="silent"><div class="ri"><i class="fa fa-bell-slash"></i></div>
            <div class="rl"><div class="rn">Без звука</div><div class="rd">Сообщения приходят беззвучно.</div></div>
            <div class="jkn-sw"></div></div>
        </div>
      </div>
    </div>

    <div>
      <div class="jkn-card">
        <h3><i class="fa fa-heartbeat"></i> Состояние</h3>
        <div class="jkn-kpis">
          <div class="jkn-kpi"><div class="l">Отправлено</div><div class="v" id="jkn-k-sent">—</div></div>
          <div class="jkn-kpi"><div class="l">В очереди</div><div class="v" id="jkn-k-pend">—</div></div>
          <div class="jkn-kpi"><div class="l">Проверка</div><div class="v sm" id="jkn-k-run">—</div></div>
        </div>
        <div id="jkn-health"></div>
        <div class="jkn-hist" id="jkn-hist"></div>
      </div>
      <div class="jkn-card">
        <h3><i class="fa fa-mobile"></i> Как это выглядит</h3>
        <div class="jkn-phone">
          <div class="jkn-phone-top"><div class="av"><i class="fa fa-shield"></i></div>
            <div><div class="nm" id="jkn-bot-name">jk-ufw бот</div><div class="st">бот</div></div></div>
          <div id="jkn-preview"></div>
        </div>
      </div>
    </div>
  </div>

  <div class="jkn-bar">
    <div class="st" id="jkn-bar-st">Изменений нет.</div>
    <button class="jkn-btn ghost" id="jkn-reset" type="button" disabled>Отменить</button>
    <button class="jkn-btn" id="jkn-apply" type="button" disabled>Сохранить</button>
  </div>
</div>

<script>
'use strict';
$(function () {
    const FLAGS = ['enabled', 'threats', 'wan', 'login_ok', 'login_fail', 'silent'];
    const HIST = {threat: ['fa-shield', 'Угроза'], wan: ['fa-globe', 'Интернет'], login: ['fa-key', 'Вход'], login_fail: ['fa-user-times', 'Неудачный вход']};
    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
    });
    const ago = (ts, now) => {
        if (!ts) { return 'никогда'; }
        const s = Math.max(0, (now || Date.now() / 1000) - ts);
        if (s < 90) { return 'только что'; }
        if (s < 3600) { return Math.round(s / 60) + ' мин назад'; }
        if (s < 86400) { return Math.round(s / 3600) + ' ч назад'; }
        return new Date(ts * 1000).toLocaleDateString('ru-RU');
    };
    const hhmm = (d) => d.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'});

    let saved = null;
    let state = null;
    let status = null;
    let busy = false;
    let idsEnabled = null;

    function fromApi(n) {
        const s = {};
        FLAGS.forEach((k) => { s[k] = String(n[k]) === '1'; });
        s.token = n.token || '';
        s.chat_id = n.chat_id || '';
        const sev = n.threat_severity || {};
        s.threat_severity = typeof sev === 'object' ? (Object.keys(sev).find((k) => String(sev[k].selected) === '1') || '2') : String(sev);
        return s;
    }
    function toApi(s) {
        const n = {};
        FLAGS.forEach((k) => { n[k] = s[k] ? '1' : '0'; });
        n.token = s.token.trim();
        n.chat_id = s.chat_id.trim();
        n.threat_severity = s.threat_severity;
        return {notify: n};
    }
    const dirty = () => JSON.stringify(state) !== JSON.stringify(saved);

    function preview() {
        const host = 'jk-ufw';
        const now = new Date();
        const items = [
            ['threats', '🛡 <b>Угроза заблокирована</b>\n<code>' + host + '</code>\n\n<b>ET SCAN Nmap Scripting Engine</b>\n45.155.205.12:51544 → 192.168.1.20:22 (TCP)\n⛔ заблокировано · важность: средняя'],
            ['wan', '🔴 <b>Пропал интернет: WAN</b>\n<code>' + host + '</code>\nШлюз 10.0.2.2 не отвечает.'],
            ['wan', '🟢 <b>Интернет восстановлен: WAN</b>\n<code>' + host + '</code>\nНе было связи: 4 мин.'],
            ['login_ok', '🔑 <b>Вход в веб-интерфейс</b>\n<code>' + host + '</code>\nПользователь <b>root</b> с адреса <code>192.168.1.5</code>'],
            ['login_fail', '🚫 <b>Неудачный вход в веб-интерфейс</b>\n<code>' + host + '</code>\nПопыток: 3 с адреса <code>203.0.113.9</code>\nЛогин: <b>admin</b>']
        ];
        $('#jkn-preview').html(items.map(([k, text], i) =>
            '<div class="jkn-msg' + (state.enabled && state[k] ? '' : ' off') + '">' + text +
            '<span class="tm">' + hhmm(new Date(now - (items.length - i) * 7 * 60000)) + '</span></div>').join(''));
    }

    function renderStatus() {
        const pill = $('#jkn-status').removeClass('ok bad warn');
        let text = 'Выключено';
        if (saved && saved.enabled) {
            if (status && status.last_error && status.pending) {
                pill.addClass('bad'); text = 'Ошибка доставки';
            } else if (status && (!status.last_run || status.now - status.last_run > 300)) {
                pill.addClass('warn'); text = 'Ожидает запуска';
            } else {
                pill.addClass('ok'); text = 'Работает';
            }
        }
        pill.find('span').text(text);
        $('#jkn-logo').toggleClass('on', !!(saved && saved.enabled));
        if (!status) { return; }
        $('#jkn-k-sent').text(Number(status.sent || 0).toLocaleString('ru-RU'));
        $('#jkn-k-pend').text(status.pending || 0);
        $('#jkn-k-run').text(saved && saved.enabled ? ago(status.last_run, status.now) : '—');
        const notes = [];
        if (status.last_error) {
            notes.push('<div class="jkn-note bad"><i class="fa fa-exclamation-circle"></i><div><b>Не удалось отправить</b> (' +
                esc(ago(status.last_error.ts, status.now)) + '): ' + esc(status.last_error.message) +
                (status.pending ? '<br/>Сообщений в очереди: ' + status.pending + '. Они уйдут, как только связь появится.' : '') + '</div></div>');
        }
        const gws = Object.entries(status.gateways || {});
        if (gws.length) {
            notes.push('<div class="jkn-note info"><i class="fa fa-globe"></i><div>Шлюзы: ' + gws.map(([n, s]) =>
                esc(n) + ' <b style="color:' + (s === 'down' ? 'var(--a2)' : 'var(--ok)') + '">' + (s === 'down' ? 'нет связи' : 'на связи') + '</b>').join(', ') + '</div></div>');
        }
        $('#jkn-health').html(notes.join(''));
        const hist = status.history || [];
        $('#jkn-hist').html(hist.length ? hist.map((h) => {
            const [icon, name] = HIST[h.type] || ['fa-bell', h.type];
            return '<div class="jkn-ev"><i class="fa ' + icon + '"></i><div class="en">' + esc(name) + '</div><div class="et">' + esc(ago(h.ts, status.now)) + '</div></div>';
        }).join('') : '<div class="jkn-empty">Сообщений пока не было.</div>');
    }

    function render() {
        $('#jkn-enabled').toggleClass('on', state.enabled);
        $('#jkn-events .jkn-row').each(function () { $(this).toggleClass('on', !!state[$(this).data('k')]); });
        $('#jkn-sev span').each(function () { $(this).toggleClass('sel', String($(this).data('v')) === state.threat_severity); });
        $('#jkn-sev-row').toggle(state.threats);
        $('#jkn-ids-off').toggle(state.threats && idsEnabled === false);
        if ($('#jkn-token').val() !== state.token) { $('#jkn-token').val(state.token); }
        if ($('#jkn-chat').val() !== state.chat_id) { $('#jkn-chat').val(state.chat_id); }
        $('#jkn-s1, #jkn-s2').toggleClass('done', /^\d+:.{30,}$/.test(state.token.trim()));
        $('#jkn-s3').toggleClass('done', state.chat_id.trim() !== '');
        $('#jkn-s4').toggleClass('done', !!(status && status.sent));
        $('#jkn-chats .jkn-chip').each(function () { $(this).toggleClass('sel', String($(this).data('id')) === state.chat_id.trim()); });
        const d = dirty();
        $('#jkn-apply, #jkn-reset').prop('disabled', !d || busy);
        $('#jkn-test, #jkn-find').prop('disabled', busy);
        if (!busy) {
            $('#jkn-bar-st').html(d ? '<b>Есть несохранённые изменения.</b>' :
                (saved.enabled ? 'Проверка событий раз в минуту.' : 'Уведомления выключены.'));
        }
        renderStatus();
        preview();
    }

    function showErrors(validations) {
        $('#jkn-token, #jkn-chat').removeClass('err');
        $('#jkn-token-err, #jkn-chat-err').hide();
        const map = {'notify.token': 'token', 'notify.chat_id': 'chat'};
        Object.entries(validations || {}).forEach(([k, msg]) => {
            const id = map[k];
            if (id) {
                $('#jkn-' + id).addClass('err');
                $('#jkn-' + id + '-err').text(Array.isArray(msg) ? msg.join(' ') : msg).show();
            }
        });
    }

    async function save() {
        busy = true;
        render();
        $('#jkn-bar-st').html('<i class="fa fa-spinner fa-pulse"></i>&nbsp; Сохраняем…');
        try {
            const r = await api('/api/jkufw/notify/set', toApi(state));
            if (r.result !== 'saved') {
                showErrors(r.validations);
                throw new Error('проверьте выделенные поля');
            }
            showErrors({});
            await api('/api/jkufw/notify/reconfigure', {});
            saved = JSON.parse(JSON.stringify(state));
            return true;
        } catch (e) {
            busy = false;
            render();
            $('#jkn-bar-st').html('<b style="color:var(--a2)">Не сохранено:</b> ' + esc(e.message));
            return false;
        } finally {
            busy = false;
        }
    }

    async function refreshStatus() {
        try {
            status = await api('/api/jkufw/notify/status');
        } catch (e) {
            status = null;
        }
        renderStatus();
        $('#jkn-s4').toggleClass('done', !!(status && status.sent));
    }

    async function load() {
        const r = await api('/api/jkufw/notify/get');
        saved = fromApi(r.notify || {});
        state = JSON.parse(JSON.stringify(saved));
        render();
        api('/api/ids/settings/get').then((ids) => {
            idsEnabled = String((((ids || {}).ids || {}).general || {}).enabled) === '1';
            render();
        }).catch(() => {});
    }

    $('#jkn-enabled').on('click keydown', function (e) {
        if (busy || (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter')) { return; }
        e.preventDefault();
        state.enabled = !state.enabled;
        render();
    });
    $('#jkn-events').on('click', '.jkn-row', function () {
        if (busy) { return; }
        const k = $(this).data('k');
        state[k] = !state[k];
        render();
    });
    $('#jkn-sev').on('click', 'span', function () {
        if (busy) { return; }
        state.threat_severity = String($(this).data('v'));
        render();
    });
    $('#jkn-token').on('input', function () { state.token = String($(this).val()).trim(); render(); });
    $('#jkn-chat').on('input', function () { state.chat_id = String($(this).val()).trim(); render(); });
    $('#jkn-eye').on('click', function () {
        const inp = $('#jkn-token');
        const show = inp.attr('type') === 'password';
        inp.attr('type', show ? 'text' : 'password');
        $(this).find('.fa').toggleClass('fa-eye', !show).toggleClass('fa-eye-slash', show);
    });
    $('#jkn-chats').on('click', '.jkn-chip', function () {
        state.chat_id = String($(this).data('id'));
        render();
    });
    $('#jkn-find').on('click', async function () {
        if (!state.token) {
            showErrors({'notify.token': 'Сначала вставьте токен бота.'});
            return;
        }
        if (dirty() && !(await save())) { return; }
        const btn = $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>&nbsp; Ищем…');
        try {
            const r = await api('/api/jkufw/notify/chats', {});
            if (r.status !== 'ok') { throw new Error(r.message || 'ошибка'); }
            if (r.bot) { $('#jkn-bot-name').text('@' + r.bot); }
            const chats = r.chats || [];
            $('#jkn-chats').html(chats.length ? chats.map((c) =>
                '<span class="jkn-chip" data-id="' + esc(c.id) + '"><i class="fa ' + (c.type === 'private' ? 'fa-user' : 'fa-users') + '"></i>' +
                esc(c.name || c.username || c.id) + (c.username ? ' <small>@' + esc(c.username) + '</small>' : '') + '</span>').join('') :
                '<div class="jkn-note warn" style="margin-top:0"><i class="fa fa-info-circle"></i><div>Чатов пока нет. Напишите боту ' +
                (r.bot ? '<a href="https://t.me/' + esc(r.bot) + '" target="_blank" rel="noopener">@' + esc(r.bot) + '</a> ' : '') +
                'любое сообщение и нажмите «Найти чат» ещё раз.</div></div>');
            if (chats.length === 1 && !state.chat_id) { state.chat_id = chats[0].id; }
        } catch (e) {
            $('#jkn-chats').html('<div class="jkn-note bad" style="margin-top:0"><i class="fa fa-exclamation-circle"></i><div>' + esc(e.message) + '</div></div>');
        }
        btn.html('<i class="fa fa-search"></i>&nbsp; Найти чат');
        render();
    });
    $('#jkn-test').on('click', async function () {
        $('#jkn-test-res').empty();
        if (dirty() && !(await save())) { return; }
        render();
        const btn = $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>&nbsp; Отправляем…');
        try {
            const r = await api('/api/jkufw/notify/test', {});
            if (r.status !== 'ok') { throw new Error(r.message || 'ошибка'); }
            $('#jkn-test-res').html('<div class="jkn-note ok"><i class="fa fa-check-circle"></i><div>Отправлено. Проверьте Telegram.</div></div>');
            $('#jkn-s4').addClass('done');
        } catch (e) {
            $('#jkn-test-res').html('<div class="jkn-note bad"><i class="fa fa-exclamation-circle"></i><div><b>Не отправлено:</b> ' + esc(e.message) + '</div></div>');
        }
        btn.prop('disabled', false).html('<i class="fa fa-paper-plane"></i>&nbsp; Отправить тест');
    });
    $('#jkn-reset').on('click', () => {
        state = JSON.parse(JSON.stringify(saved));
        showErrors({});
        render();
    });
    $('#jkn-apply').on('click', async () => {
        if (await save()) {
            render();
            $('#jkn-bar-st').html('<i class="fa fa-check" style="color:var(--ok)"></i>&nbsp; Сохранено.');
            refreshStatus();
        }
    });

    load().then(refreshStatus).catch((e) => {
        $('#jkn-bar-st').html('<b style="color:var(--a2)">Не удалось загрузить настройки:</b> ' + esc(e.message));
    });
    setInterval(() => { if (!busy) { refreshStatus(); } }, 30000);
});
</script>
