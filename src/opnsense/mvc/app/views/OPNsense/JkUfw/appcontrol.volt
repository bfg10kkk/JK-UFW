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
 # jk-ufw: application control. Settings via /api/jkufw/appcontrol/{get,set,apply}, usage via .../status.
 # Recognition runs in the stock Suricata (IPS); the engine can be switched on from here through /api/ids/*.
 #}

<style>
.jka { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1240px; }
.jka * { box-sizing:border-box; }
.jka b, .jka strong { font-family:inherit; font-weight:700; }
.jka .muted { color:var(--m); }
.jka-head { display:flex; align-items:center; gap:16px; padding:6px 0 14px; flex-wrap:wrap; }
.jka-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:24px; color:#fff;
  background:linear-gradient(145deg,var(--a2),#a5121c); box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jka-logo.off { background:var(--s2); border:1px solid var(--b); color:var(--m); box-shadow:none; }
.jka-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jka-sub { color:var(--m); margin-top:2px; }
.jka-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jka-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jka-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jka-pill.warn i { background:var(--warn); }
.jka-pill.bad i { background:var(--a); }
.jka-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jka-grid { display:grid; grid-template-columns:minmax(0,1.65fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1050px) { .jka-grid { grid-template-columns:minmax(0,1fr); } }
.jka-grid > div { min-width:0; }
.jka-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jka-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; }
.jka-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; }
.jka-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 760px) { .jka-kpis { grid-template-columns:1fr 1fr; } }
.jka-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px 16px; min-width:0; }
.jka-kpi .l { color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jka-kpi .v { font-size:26px; font-weight:700; letter-spacing:-.02em; margin-top:4px; }
.jka-kpi .v.red { color:var(--a2); }
.jka-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:4px; }
.jka-tools { display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-bottom:12px; }
.jka input.jka-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:8px 10px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:13px; box-shadow:none !important; }
.jka input.jka-in:focus { border-color:var(--a) !important; outline:none; }
.jka input.jka-in.mono { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jka-search { position:relative; flex:1; min-width:200px; }
.jka-search .fa { position:absolute; left:11px; top:11px; color:var(--m); }
.jka-search input.jka-in { padding-left:32px !important; }
.jka-chips { display:flex; flex-wrap:wrap; gap:6px; margin-bottom:14px; }
.jka-chip { padding:6px 12px; border-radius:999px; background:var(--s2); border:1px solid var(--b); cursor:pointer; font-weight:600; user-select:none; font-size:12.5px; }
.jka-chip:hover { border-color:var(--b2); }
.jka-chip.sel { background:var(--abg); border-color:var(--a); color:#fff; }
.jka-chip .fa { margin-right:6px; color:var(--m); }
.jka-chip.sel .fa { color:var(--a2); }
.jka-chip small { color:var(--m); font-weight:500; margin-left:5px; }
.jka-sec { color:var(--m); font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; margin:16px 0 8px; display:flex; align-items:center; gap:8px; }
.jka-sec:first-child { margin-top:0; }
.jka-sec .fa { color:var(--a2); }
.jka-apps { display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr)); gap:8px; }
.jka-app { display:flex; align-items:center; gap:11px; padding:10px 11px; border-radius:10px; background:var(--s2); border:1px solid var(--b); cursor:pointer; min-width:0; }
.jka-app:hover { background:var(--h); }
.jka-app.cur { border-color:var(--b2); box-shadow:inset 0 0 0 1px var(--b2); }
.jka-app.blk { border-color:rgba(229,32,46,.5); background:linear-gradient(0deg,var(--abg),var(--abg)),var(--s2); }
.jka-av { width:34px; height:34px; flex:none; border-radius:9px; display:grid; place-items:center; font-weight:800; font-size:15px; color:#fff; position:relative; }
.jka-app.blk .jka-av::after { content:"\f05e"; font-family:FontAwesome; position:absolute; right:-5px; bottom:-5px; font-size:13px; color:var(--a2);
  background:var(--s); border-radius:50%; width:17px; height:17px; display:grid; place-items:center; font-weight:400; }
.jka-am { flex:1; min-width:0; }
.jka-an { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jka-au { color:var(--m); font-size:11.5px; margin-top:1px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jka-au b { color:var(--t); font-weight:600; }
.jka-au .red { color:#ff8a91; }
.jka-sw { flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jka-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jka-sw.on { background:var(--a); }
.jka-sw.on::after { left:16px; background:#fff; }
.jka-sw.dis { opacity:.4; cursor:default; }
.jka-row { display:flex; align-items:center; gap:14px; padding:12px 0; border-top:1px solid var(--b); }
.jka-row:first-of-type { border-top:0; padding-top:0; }
.jka-row .rl { flex:1; min-width:0; }
.jka-row .rn { font-weight:600; }
.jka-row .rd { color:var(--m); font-size:12px; margin-top:2px; line-height:1.45; }
.jka-lbl { display:block; font-weight:600; margin:12px 0 6px; }
.jka-lbl small { color:var(--m); font-weight:500; margin-left:6px; }
.jka-note { border-radius:10px; padding:12px 14px; font-size:12.5px; line-height:1.5; display:flex; gap:12px; align-items:flex-start; }
.jka-note > .fa { margin-top:2px; font-size:15px; }
.jka-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; margin:0 0 16px; }
.jka-note.warn > .fa { color:var(--warn); }
.jka-note.warn a { color:#fff; text-decoration:underline; }
.jka-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); margin-top:12px; }
.jka-note .nt { flex:1; }
.jka-note .nt b { color:#fff; }
.jka-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff; display:inline-flex; align-items:center; gap:7px; white-space:nowrap; }
.jka-btn:hover { background:var(--a2); color:#fff; text-decoration:none; }
.jka-btn[disabled] { opacity:.5; cursor:default; }
.jka-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t); font-weight:600; }
.jka-btn.ghost:hover { background:var(--h); }
.jka-btn.sm { padding:6px 11px; font-size:12px; }
.jka-bar { position:sticky; bottom:0; z-index:5; display:flex; align-items:center; gap:14px; padding:14px 18px; margin-top:4px;
  background:rgba(19,19,22,.92); backdrop-filter:blur(8px); border:1px solid var(--b); border-radius:12px; }
.jka-bar .st { flex:1; color:var(--m); }
.jka-bar .st b { color:var(--t); }
.jka-top { display:flex; align-items:center; gap:10px; padding:6px 0; cursor:pointer; }
.jka-top .jka-av { width:26px; height:26px; font-size:12px; border-radius:7px; }
.jka-top .tn { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jka-top .tn small { color:var(--m); font-weight:500; margin-left:6px; }
.jka-top .tb { height:5px; border-radius:4px; background:var(--a); opacity:.85; }
.jka-top .tb.ok { background:#5a5a66; }
.jka-top .tv { color:var(--m); font-variant-numeric:tabular-nums; min-width:34px; text-align:right; }
.jka-ev { display:flex; gap:10px; align-items:flex-start; padding:8px 0; border-top:1px solid var(--b); }
.jka-ev:first-child { border-top:0; }
.jka-ev .jka-av { width:26px; height:26px; font-size:12px; border-radius:7px; }
.jka-ev .em { flex:1; min-width:0; }
.jka-ev .e1 { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jka-ev .e2 { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; font-family:ui-monospace,Menlo,Consolas,monospace; }
.jka-ev .et { color:var(--m); font-size:11.5px; white-space:nowrap; }
.jka-badge { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; background:var(--s2); border:1px solid var(--b); color:var(--m); white-space:nowrap; }
.jka-badge.blk { color:#ffb3b8; border-color:rgba(229,32,46,.45); background:var(--abg); }
.jka-empty { color:var(--m); text-align:center; padding:22px 6px; }
.jka-empty .fa { display:block; font-size:22px; margin-bottom:8px; color:#3a3a42; }
.jka-det-top { display:flex; align-items:center; gap:12px; margin-bottom:14px; }
.jka-det-top .jka-av { width:46px; height:46px; font-size:20px; border-radius:12px; }
.jka-det-nm { font-size:17px; font-weight:700; }
.jka-how { margin-top:10px; }
.jka-how .hk { color:var(--m); font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.06em; margin:10px 0 5px; }
.jka-how code { display:inline-block; background:var(--s2); border:1px solid var(--b); color:var(--t); border-radius:6px; padding:2px 7px; margin:0 4px 4px 0; font-size:11.5px; }
.jka-steps { margin:0; padding:0; list-style:none; }
.jka-steps li { padding:2px 0; color:var(--m); }
.jka-steps li.done { color:var(--t); }
.jka-steps li.done .fa { color:var(--ok); }
.jka-steps li.run .fa { color:var(--a2); }
.jka-steps li.err { color:var(--a2); }
.jka-err { color:var(--a2); font-size:12px; margin-top:6px; }
@media (max-width: 640px) {
  .jka-chips { flex-wrap:nowrap; overflow-x:auto; padding-bottom:4px; scrollbar-width:none; }
  .jka-chip { white-space:nowrap; }
  .jka-bar { padding:10px 12px; gap:8px; }
  .jka-bar .st { font-size:12px; }
  .jka-bar .jka-btn { padding:9px 12px; }
  .jka-head-r { margin-left:0; }
}
</style>

<div class="jka" id="jka">
  <div class="jka-head">
    <div class="jka-logo off" id="jka-logo"><i class="fa fa-th-large"></i></div>
    <div>
      <h1 class="jka-title">Контроль приложений <span class="jka-pill" id="jka-status"><i></i><span>…</span></span></h1>
      <div class="jka-sub">Узнаёт приложения в трафике по имени сервера, протоколу и сигнатурам и блокирует ненужные</div>
    </div>
    <div class="jka-head-r">
      <a class="jka-btn ghost" href="/ui/jkufw/parental"><i class="fa fa-child"></i> Фильтр контента</a>
      <a class="jka-btn ghost" href="/ui/ids/threats"><i class="fa fa-shield"></i> Угрозы</a>
    </div>
  </div>

  <div class="jka-note warn" id="jka-engine" style="display:none"><i class="fa fa-exclamation-triangle"></i>
    <div class="nt" id="jka-engine-text"></div>
    <button class="jka-btn sm" id="jka-engine-go" type="button" style="display:none"></button>
  </div>

  <div class="jka-kpis">
    <div class="jka-kpi"><div class="l">Приложений за сутки</div><div class="v" id="jka-k-apps">–</div></div>
    <div class="jka-kpi"><div class="l">Заблокировано</div><div class="v red" id="jka-k-blocked">–</div></div>
    <div class="jka-kpi"><div class="l">Устройств</div><div class="v" id="jka-k-clients">–</div></div>
    <div class="jka-kpi"><div class="l">Под запретом</div><div class="v" id="jka-k-rules">–</div></div>
  </div>

  <div class="jka-grid">
    <div>
      <div class="jka-card">
        <div class="jka-tools">
          <div class="jka-search"><i class="fa fa-search"></i><input class="jka-in" id="jka-q" type="text" placeholder="Найти приложение"/></div>
          <button class="jka-btn ghost sm" id="jka-cat-block" type="button"><i class="fa fa-ban"></i> Блокировать категорию</button>
        </div>
        <div class="jka-chips" id="jka-cats"></div>
        <div id="jka-list"><div class="jka-empty">Загрузка…</div></div>
      </div>
    </div>

    <div>
      <div class="jka-card" id="jka-det" style="display:none"></div>
      <div class="jka-card">
        <h3><i class="fa fa-bar-chart"></i> Чаще всего <span class="r muted">за 24 часа</span></h3>
        <div id="jka-top"><div class="jka-empty">Загрузка…</div></div>
      </div>
      <div class="jka-card">
        <h3><i class="fa fa-history"></i> Последние события</h3>
        <div id="jka-events"><div class="jka-empty">Загрузка…</div></div>
      </div>
      <div class="jka-card">
        <h3><i class="fa fa-cog"></i> Настройки</h3>
        <div class="jka-row">
          <div class="rl"><div class="rn">Контроль приложений</div><div class="rd">Распознавать приложения и применять запреты.</div></div>
          <div class="jka-sw" id="jka-enabled" role="switch" tabindex="0"></div>
        </div>
        <div class="jka-row">
          <div class="rl"><div class="rn">Статистика по всем приложениям</div><div class="rd">Записывать и разрешённые приложения, чтобы видеть, кто чем пользуется.
            Одна запись на устройство и приложение раз в 5 минут.</div></div>
          <div class="jka-sw" id="jka-visibility" role="switch" tabindex="0"></div>
        </div>
        <label class="jka-lbl">Не проверять <small>IP или сети через запятую</small></label>
        <input class="jka-in mono" id="jka-exempt" type="text" spellcheck="false" placeholder="192.168.1.10, 192.168.50.0/24"/>
        <div class="jka-err" id="jka-exempt-err"></div>
        <div class="jka-note info"><i class="fa fa-info-circle"></i><div class="nt">HTTPS-фильтр по категориям, блокировка DNS через HTTPS и QUIC
          настраиваются в <a href="/ui/jkufw/parental">Фильтре контента</a> и используют тот же движок.</div></div>
      </div>
    </div>
  </div>

  <div class="jka-bar">
    <div class="st" id="jka-bar-st">Изменений нет.</div>
    <button class="jka-btn ghost" id="jka-reset" type="button" disabled>Отменить</button>
    <button class="jka-btn" id="jka-apply" type="button" disabled>Применить</button>
  </div>
</div>

<script>
'use strict';
$(function () {
    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const num = (n) => Number(n || 0).toLocaleString('ru-RU');
    const clone = (o) => JSON.parse(JSON.stringify(o));
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => {
                let msg = x.status + ' ' + (x.statusText || '');
                try { msg = (JSON.parse(x.responseText).message || msg); } catch (e) { /* not json */ }
                reject(new Error(msg));
            });
    });
    const selectedKeys = (node) => {
        if (node == null) { return []; }
        if (typeof node === 'string') { return node.split(',').map((s) => s.trim()).filter(Boolean); }
        return Object.keys(node).filter((k) => k !== '' && (node[k].selected === undefined || String(node[k].selected) === '1'));
    };
    const NET_RE = /^(\d{1,3}(\.\d{1,3}){3}(\/\d{1,2})?|[0-9a-f:]*:[0-9a-f:.]+(\/\d{1,3})?)$/i;
    const HOW = {sni: 'Имена серверов (HTTPS, HTTP, QUIC)', ip: 'Сети адресов', proto: 'Протокол', ports: 'Порты', sig: 'Сигнатуры пакетов'};
    const PROTO = {'bittorrent-dht': 'BitTorrent DHT', rdp: 'RDP', ssh: 'SSH', rfb: 'VNC (RFB)', telnet: 'Telnet', ike: 'IKE / IPsec'};
    const ago = (ts) => {
        const s = Math.max(0, Math.round(Date.now() / 1000 - ts));
        if (s < 60) { return 'только что'; }
        if (s < 3600) { return Math.round(s / 60) + ' мин назад'; }
        if (s < 86400) { return Math.round(s / 3600) + ' ч назад'; }
        return new Date(ts * 1000).toLocaleString('ru-RU');
    };

    let catalog = {categories: [], apps: [], web: []};
    let byId = {};
    let saved = null;
    let state = null;
    let status = {stats: {apps: {}, web: {}, clients: {}, recent: []}, ids: {}, state: {}, hostnames: {}};
    let clients = {};   // ip -> name (ARP + DHCP)
    let filterCat = 'all';
    let current = null;
    let busy = false;

    const initials = (name) => {
        const w = String(name).replace(/[()]/g, '').split(/\s+/).filter(Boolean);
        return (w.length > 1 && /^[A-ZА-Я]/.test(w[1]) ? w[0][0] + w[1][0] : w[0].substring(0, 2)).toUpperCase();
    };
    const avatar = (app) => {
        const light = ['#fffc00', '#ffcc00', '#53fc18'].includes(app.color);
        return `<div class="jka-av" style="background:${esc(app.color)};${light ? 'color:#111' : ''}">${esc(initials(app.name))}</div>`;
    };
    const devName = (ip) => clients[ip] || status.hostnames[ip] || ip;
    const usage = (id) => (status.stats.apps || {})[id] || null;

    async function load() {
        const [cat, cfg] = await Promise.all([api('/api/jkufw/appcontrol/catalog'), api('/api/jkufw/appcontrol/get')]);
        catalog = cat;
        byId = {};
        catalog.apps.forEach((a) => { byId[a.id] = a; });
        const c = (cfg && cfg.appcontrol) || {};
        saved = {
            enabled: String(c.enabled) === '1',
            visibility: String(c.visibility) !== '0',
            blocked: selectedKeys(c.blocked).filter((id) => byId[id]).sort(),
            exempt: selectedKeys(c.exempt)
        };
        state = clone(saved);
    }

    async function loadStatus() {
        try {
            status = await api('/api/jkufw/appcontrol/status');
            status.stats = status.stats || {apps: {}, web: {}, clients: {}, recent: []};
            status.hostnames = status.hostnames || {};
        } catch (e) {
            /* keep the last one */
        }
    }

    function loadClients() {
        return api('/api/diagnostics/interface/get_arp').then((rows) => {
            (Array.isArray(rows) ? rows : []).forEach((r) => {
                if (r.ip && r.hostname && r.hostname !== '?') { clients[r.ip] = r.hostname.split('.')[0]; }
            });
        }).catch(() => null);
    }

    const diffable = (s) => JSON.stringify([s.enabled, s.visibility, [...s.blocked].sort(), s.exempt]);
    const isDirty = () => state && saved && diffable(state) !== diffable(saved);
    const validate = () => {
        const bad = state.exempt.find((x) => !NET_RE.test(x));
        return bad ? `«${bad}» не похоже на IP-адрес или сеть.` : '';
    };

    /* ------------------------------------------------------------------ render */
    function renderEngine() {
        const ids = status.ids || {};
        const box = $('#jka-engine');
        const go = $('#jka-engine-go').hide();
        let text = '';
        if (!state.enabled) {
            box.hide();
        } else if (!ids.enabled) {
            text = '<b>Движок распознавания (IPS) выключен.</b> Без него приложения не распознаются и не блокируются. ' +
                'Включите его на внутренней сети: так запреты видят настоящий адрес каждого устройства.';
            go.show().html(`<i class="fa fa-power-off"></i> Включить IPS${ids.lan && ids.lan.length ? ' на ' + esc(ids.lan[0].name) : ''}`);
        } else if (!ids.ips) {
            text = '<b>Движок работает в режиме наблюдения (IDS).</b> Приложения видны в статистике, но запреты не действуют — переключите его в режим IPS.';
            go.show().html('<i class="fa fa-shield"></i> Перевести в IPS');
        } else if (!ids.on_lan && ids.lan && ids.lan.length) {
            text = `<b>IPS следит только за ${esc((ids.interfaces || []).map((x) => x.name).join(', ') || 'WAN')}.</b> За NAT все устройства выглядят одним адресом,
                поэтому статистика по устройствам и исключения не работают. Добавьте внутреннюю сеть.`;
            go.show().html(`<i class="fa fa-plus"></i> Добавить ${esc(ids.lan[0].name)}`);
        } else if (!ids.running) {
            text = '<b>Служба IPS не запущена.</b> Посмотрите журнал в <a href="/ui/ids#alerts">Services › Intrusion Detection</a> или нажмите «Применить».';
        }
        box.toggle(!!text);
        $('#jka-engine-text').html(text +
            (go.is(':visible') ? ' <span class="muted">Для IPS отключите аппаратную разгрузку в <a href="/ui/interfaces/settings">Interfaces › Settings</a>.</span>' : ''));

        const pill = $('#jka-status').attr('class', 'jka-pill');
        if (!saved.enabled) {
            pill.find('span').text('выключено');
        } else if (ids.enabled && ids.running && ids.ips) {
            pill.addClass('ok').find('span').text('работает');
        } else if (ids.enabled && ids.running) {
            pill.addClass('warn').find('span').text('только наблюдает');
        } else {
            pill.addClass('bad').find('span').text('IPS не работает');
        }
        $('#jka-logo').toggleClass('off', !saved.enabled);
    }

    function renderKpis() {
        const apps = status.stats.apps || {};
        const ids = Object.keys(apps);
        $('#jka-k-apps').text(num(ids.length));
        $('#jka-k-blocked').text(num(ids.reduce((s, k) => s + (apps[k].blocked || 0), 0) +
            Object.values(status.stats.web || {}).reduce((s, v) => s + (v.blocked || 0), 0)));
        $('#jka-k-clients').text(num(Object.keys(status.stats.clients || {}).length));
        $('#jka-k-rules').html(`${num(saved.blocked.length)}<small>прил.</small>`);
    }

    function renderList() {
        const q = String($('#jka-q').val() || '').trim().toLowerCase();
        const blocked = new Set(state.blocked);
        const counts = {all: catalog.apps.length, blocked: blocked.size, used: catalog.apps.filter((a) => usage(a.id)).length};
        catalog.categories.forEach((c) => { counts[c.id] = catalog.apps.filter((a) => a.cat === c.id).length; });
        const chips = [{id: 'all', name: 'Все', icon: 'fa-th'}, {id: 'used', name: 'Замечены', icon: 'fa-eye'},
            {id: 'blocked', name: 'Заблокированы', icon: 'fa-ban'}].concat(catalog.categories);
        $('#jka-cats').html(chips.map((c) => `<span class="jka-chip ${filterCat === c.id ? 'sel' : ''}" data-cat="${c.id}">
            <i class="fa ${c.icon}"></i>${esc(c.name)}<small>${counts[c.id] || 0}</small></span>`).join(''));
        const inCat = catalog.categories.find((c) => c.id === filterCat);
        $('#jka-cat-block').toggle(!!inCat).html(inCat && catalog.apps.filter((a) => a.cat === inCat.id).every((a) => blocked.has(a.id))
            ? '<i class="fa fa-check"></i> Разрешить категорию' : '<i class="fa fa-ban"></i> Блокировать категорию');

        const show = catalog.apps.filter((a) => (!q || a.name.toLowerCase().includes(q) || a.id.includes(q)) &&
            (filterCat === 'all' || a.cat === filterCat || (filterCat === 'blocked' && blocked.has(a.id)) || (filterCat === 'used' && usage(a.id))));
        if (!show.length) {
            $('#jka-list').html('<div class="jka-empty"><i class="fa fa-search"></i>Ничего не найдено</div>');
            return;
        }
        if (filterCat === 'used') {
            show.sort((a, b) => usage(b.id).hits - usage(a.id).hits);
        }
        let html = '';
        const groups = filterCat === 'all' || filterCat === 'blocked' ? catalog.categories : [{id: null}];
        groups.forEach((g) => {
            const items = show.filter((a) => g.id === null || a.cat === g.id);
            if (!items.length) { return; }
            if (g.id) { html += `<div class="jka-sec"><i class="fa ${g.icon}"></i>${esc(g.name)}</div>`; }
            html += '<div class="jka-apps">' + items.map((a) => {
                const u = usage(a.id);
                const on = blocked.has(a.id);
                const devs = u ? Object.keys(u.clients || {}).length : 0;
                const line = u ? (u.blocked ? `<span class="red">${num(u.blocked)} заблок.</span> · ${devs} устр.` : `<b>${devs}</b> устр. · ${ago(u.last)}`)
                    : (on ? 'запрещено' : 'не замечено');
                return `<div class="jka-app ${on ? 'blk' : ''} ${current === a.id ? 'cur' : ''}" data-id="${a.id}">${avatar(a)}
                    <div class="jka-am"><div class="jka-an">${esc(a.name)}</div><div class="jka-au">${line}</div></div>
                    <div class="jka-sw ${on ? 'on' : ''} ${state.enabled ? '' : 'dis'}" title="Блокировать"></div></div>`;
            }).join('') + '</div>';
        });
        $('#jka-list').html(html);
    }

    function renderDetail() {
        const a = byId[current];
        if (!a) { $('#jka-det').hide(); return; }
        const u = usage(a.id);
        const on = state.blocked.includes(a.id);
        const cat = catalog.categories.find((c) => c.id === a.cat) || {name: ''};
        const devs = u ? Object.entries(u.clients || {}).sort((x, y) => y[1] - x[1]).slice(0, 8) : [];
        const how = (a.how || []).map((h) => `<div class="hk">${esc(HOW[h.kind] || h.kind)}</div>` +
            (h.kind === 'sig' ? `<code>${h.items[0]} собств. сигнатур</code>` :
                h.items.slice(0, 12).map((x) => `<code>${esc(PROTO[x] || x)}</code>`).join('') + (h.items.length > 12 ? `<code>ещё ${h.items.length - 12}</code>` : ''))).join('');
        $('#jka-det').show().html(`<div class="jka-det-top">${avatar(a)}<div style="flex:1;min-width:0"><div class="jka-det-nm">${esc(a.name)}</div>
              <div class="muted">${esc(cat.name)}</div></div>
              <button class="jka-btn ghost sm" id="jka-det-close" type="button"><i class="fa fa-times"></i></button></div>
            <div class="jka-row" style="padding-top:0"><div class="rl"><div class="rn">${on ? 'Заблокировано' : 'Разрешено'}</div>
              <div class="rd">${on ? 'Соединения этого приложения обрываются у всех устройств, кроме исключений.' : 'Приложение работает как обычно.'}</div></div>
              <div class="jka-sw ${on ? 'on' : ''} ${state.enabled ? '' : 'dis'}" id="jka-det-sw"></div></div>
            <div class="jka-sec" style="margin-top:6px">Кто пользовался за сутки</div>
            ${devs.length ? devs.map(([ip, n]) => `<div class="jka-top" style="cursor:default"><div class="tn">${esc(devName(ip))}${devName(ip) !== ip ? `<small>${esc(ip)}</small>` : ''}</div>
              <div class="tv">${num(n)}</div></div>`).join('') : '<div class="muted" style="padding:4px 0 8px">Никто.</div>'}
            <div class="jka-how">${how}</div>`);
    }

    function renderTop() {
        const apps = Object.entries(status.stats.apps || {}).filter(([id]) => byId[id]).sort((x, y) => y[1].hits - x[1].hits).slice(0, 8);
        if (!apps.length) {
            $('#jka-top').html(`<div class="jka-empty"><i class="fa fa-bar-chart"></i>${saved.enabled ? 'Пока ничего не распознано.' : 'Контроль приложений выключен.'}</div>`);
            return;
        }
        const max = apps[0][1].hits || 1;
        $('#jka-top').html(apps.map(([id, u]) => `<div class="jka-top" data-id="${id}">${avatar(byId[id])}
            <div class="tn">${esc(byId[id].name)}<small>${Object.keys(u.clients || {}).length} устр.</small></div>
            <div class="tb ${u.blocked ? '' : 'ok'}" style="width:${Math.round(u.hits / max * 70) + 6}px"></div><div class="tv">${num(u.hits)}</div></div>`).join(''));
    }

    function renderEvents() {
        const rows = (status.stats.recent || []).slice(0, 10);
        if (!rows.length) {
            $('#jka-events').html('<div class="jka-empty"><i class="fa fa-history"></i>Событий нет.</div>');
            return;
        }
        const webName = (id) => id === 'doh' ? 'DNS через HTTPS' : ((catalog.web.find((c) => c.id === id) || {}).name || id);
        $('#jka-events').html(rows.map((r) => {
            const app = r.kind === 'app' ? byId[r.id] : null;
            const av = app ? avatar(app) : '<div class="jka-av" style="background:#2a2a31;color:#ff8a91"><i class="fa fa-globe"></i></div>';
            const title = app ? app.name : webName(r.id);
            return `<div class="jka-ev">${av}<div class="em"><div class="e1">${esc(title)} ${r.blocked ? '<span class="jka-badge blk">заблокировано</span>' : ''}</div>
                <div class="e2">${esc(devName(r.src))} → ${esc(r.host || r.dst)}</div></div><div class="et">${ago(r.ts)}</div></div>`;
        }).join(''));
    }

    function render() {
        renderEngine();
        renderKpis();
        renderList();
        renderDetail();
        renderTop();
        renderEvents();
        $('#jka-enabled').toggleClass('on', state.enabled);
        $('#jka-visibility').toggleClass('on', state.visibility).toggleClass('dis', !state.enabled);
        if (!$('#jka-exempt').is(':focus')) { $('#jka-exempt').val(state.exempt.join(', ')); }
        const bad = validate();
        $('#jka-exempt-err').text(bad);
        const dirty = isDirty();
        $('#jka-apply').prop('disabled', !dirty || busy || !!bad);
        $('#jka-reset').prop('disabled', !dirty || busy);
        if (!busy) {
            const n = state.blocked.length - saved.blocked.length;
            $('#jka-bar-st').html(dirty ? '<b>Есть несохранённые изменения.</b> ' + (n > 0 ? `Будет заблокировано ещё ${n} прил. ` : '') + 'Нажмите «Применить».'
                : progressText());
        }
    }

    function progressText() {
        const st = status.state || {};
        if (st.phase && st.phase !== 'done' && st.phase !== 'error' && Date.now() / 1000 - (st.updated || 0) < 600) {
            return `<i class="fa fa-spinner fa-pulse"></i> ${esc(st.message || 'Применение')}…`;
        }
        if (st.error) {
            return `<b style="color:#ff3b47">Последнее применение с ошибкой:</b> ${esc(st.error)}`;
        }
        if (st.result && st.applied) {
            return `Правил: <b>${num(st.result.rules)}</b> · применено ${ago(st.applied)}.`;
        }
        return 'Изменений нет.';
    }

    /* ------------------------------------------------------------------ events */
    const toggleApp = (id) => {
        if (!state.enabled || busy) { return; }
        state.blocked = state.blocked.includes(id) ? state.blocked.filter((x) => x !== id) : [...state.blocked, id];
        render();
    };
    $('#jka-list').on('click', '.jka-app', function (e) {
        const id = String($(this).data('id'));
        if ($(e.target).hasClass('jka-sw')) {
            toggleApp(id);
            return;
        }
        current = current === id ? null : id;
        render();
        if (current && window.innerWidth < 1050) { $('#jka-det')[0].scrollIntoView({behavior: 'smooth'}); }
    });
    $('#jka-det').on('click', '#jka-det-sw', () => toggleApp(current));
    $('#jka-det').on('click', '#jka-det-close', () => { current = null; render(); });
    $('#jka-top').on('click', '.jka-top', function () { current = String($(this).data('id')); render(); });
    $('#jka-cats').on('click', '.jka-chip', function () { filterCat = String($(this).data('cat')); render(); });
    $('#jka-q').on('input', renderList);
    $('#jka-cat-block').on('click', () => {
        if (!state.enabled || busy) { return; }
        const ids = catalog.apps.filter((a) => a.cat === filterCat).map((a) => a.id);
        const all = ids.every((id) => state.blocked.includes(id));
        state.blocked = all ? state.blocked.filter((x) => !ids.includes(x)) : [...new Set([...state.blocked, ...ids])];
        render();
    });
    $('#jka-enabled, #jka-visibility').on('click keydown', function (e) {
        if (busy || (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter')) { return; }
        e.preventDefault();
        if (this.id === 'jka-enabled') { state.enabled = !state.enabled; } else if (state.enabled) { state.visibility = !state.visibility; }
        render();
    });
    $('#jka-exempt').on('input', function () {
        state.exempt = String($(this).val()).split(/[\s,]+/).map((s) => s.trim()).filter(Boolean);
        render();
    });
    $('#jka-reset').on('click', () => { state = clone(saved); render(); });

    function steps(list) {
        $('#jka-bar-st').html('<ul class="jka-steps">' + list.map((s) =>
            `<li class="${s.st}"><i class="fa fa-fw ${s.st === 'done' ? 'fa-check' : (s.st === 'run' ? 'fa-spinner fa-pulse' : (s.st === 'err' ? 'fa-times' : 'fa-circle-o'))}"></i> ${esc(s.t)}</li>`
        ).join('') + '</ul>');
    }

    // wait for the background rule generator (scripts/jkufw/appcontrol.py) to finish
    async function waitApplied(since) {
        for (let i = 0; i < 90; i++) {
            await new Promise((r) => setTimeout(r, 2000));
            await loadStatus();
            const st = status.state || {};
            if ((st.updated || 0) >= since && (st.phase === 'done' || st.phase === 'error')) {
                if (st.phase === 'error') { throw new Error(st.error || 'ошибка'); }
                return st;
            }
        }
        throw new Error('нет ответа, проверьте позже');
    }

    async function runPlan(plan, done) {
        busy = true;
        render();
        let cur = 0;
        try {
            for (cur = 0; cur < plan.length; cur++) {
                plan[cur].st = 'run';
                steps(plan);
                await plan[cur].fn();
                plan[cur].st = 'done';
                steps(plan);
            }
            await load();
            await loadStatus();
            busy = false;
            render();
            $('#jka-bar-st').html(done());
        } catch (e) {
            plan[cur].st = 'err';
            plan[cur].t += ': ' + e.message;
            busy = false;
            steps(plan);
            $('#jka-apply').prop('disabled', false);
        }
    }

    const applySteps = () => [
        {t: 'Сохранение', st: '', fn: async () => {
            const r = await api('/api/jkufw/appcontrol/set', {appcontrol: {enabled: state.enabled ? '1' : '0', visibility: state.visibility ? '1' : '0',
                blocked: [...state.blocked].sort().join(','), exempt: state.exempt.join(',')}});
            if (!r || r.result !== 'saved') {
                throw new Error(Object.values((r && r.validations) || {}).join(' ') || 'не сохранено');
            }
        }},
        {t: 'Правила и перезагрузка IPS', st: '', fn: async () => {
            const since = Math.floor(Date.now() / 1000) - 5;
            await api('/api/jkufw/appcontrol/apply', {});
            await waitApplied(since);
        }}
    ];
    $('#jka-apply').on('click', () => runPlan(applySteps(), () => {
        const r = (status.state || {}).result || {};
        return `<b style="color:#22c55e"><i class="fa fa-check"></i> Готово.</b> Заблокировано приложений: ${num(r.apps_blocked)}, правил: ${num(r.rules)}.
            Уже открытые соединения могут жить до переподключения приложения.`;
    }));

    // switch the stock Suricata on (IPS, netmap) and make it watch the first LAN interface
    $('#jka-engine-go').on('click', async () => {
        const ids = status.ids || {};
        const lan = (ids.lan || [])[0];
        const plan = [
            {t: 'Настройка IPS', st: '', fn: async () => {
                const g = ((await api('/api/ids/settings/get')).ids || {}).general || {};
                const ifaces = selectedKeys(g.interfaces);
                if (lan && !ifaces.includes(lan.id)) { ifaces.push(lan.id); }
                const r = await api('/api/ids/settings/set', {ids: {general: {enabled: '1', mode: (selectedKeys(g.mode)[0] || 'pcap') === 'pcap' ? 'netmap' : selectedKeys(g.mode)[0],
                    interfaces: ifaces.join(',')}}});
                if (!r || r.result !== 'saved') {
                    throw new Error(Object.values((r && r.validations) || {}).join(' ') || 'не сохранено');
                }
            }},
            {t: 'Запуск службы', st: '', fn: async () => { await api('/api/ids/service/reconfigure', {}); }}
        ];
        if (isDirty() || !saved.enabled) {
            if (!saved.enabled) { state.enabled = true; }
            plan.push(...applySteps());
        } else {
            plan.push({t: 'Правила приложений', st: '', fn: async () => {
                const since = Math.floor(Date.now() / 1000) - 5;
                await api('/api/jkufw/appcontrol/apply', {});
                await waitApplied(since);
            }});
        }
        runPlan(plan, () => '<b style="color:#22c55e"><i class="fa fa-check"></i> IPS работает.</b> Статистика появится по мере работы устройств.');
    });

    /* ------------------------------------------------------------------ start */
    Promise.all([load(), loadStatus(), loadClients()]).then(render).catch((e) => {
        $('#jka-list').html(`<div class="jka-empty">Не удалось загрузить: ${esc(e.message)}</div>`);
    });
    setInterval(() => { if (!busy) { loadStatus().then(render); } }, 30000);
});
</script>
