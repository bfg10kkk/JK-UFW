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
 # jk-ufw: devices in the network (UniFi "Clients" style). Everything goes through existing core APIs:
 # ARP/NDP, Kea and Dnsmasq leases, host discovery, iftop for live traffic; blocking uses two firewall aliases
 # and one floating rule, speed limits use traffic shaper pipes and rules.
 #}

<style>
.jkd { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; --blue:#4c8dff; color:var(--t); font-size:13px; max-width:1320px; }
.jkd * { box-sizing:border-box; }
.jkd b, .jkd strong { font-family:inherit; font-weight:700; }
.jkd a { color:var(--a2); }
.jkd-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jkd-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:22px; color:#fff;
  background:linear-gradient(145deg,var(--a2),#a5121c); box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkd-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkd-sub { color:var(--m); margin-top:2px; }
.jkd-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jkd-pill i { width:7px; height:7px; border-radius:50%; background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jkd-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jkd-btn { display:inline-flex; align-items:center; justify-content:center; gap:7px; border:0; border-radius:9px; padding:9px 16px;
  font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important; text-decoration:none !important; white-space:nowrap; }
.jkd-btn:hover { background:var(--a2); }
.jkd-btn[disabled] { opacity:.5; cursor:default; }
.jkd-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jkd-btn.ghost:hover { background:var(--h); }
.jkd-btn.ok { background:#15803d; }
.jkd-btn.ok:hover { background:var(--ok); }
.jkd-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jkd-kpis { display:grid; grid-template-columns:repeat(6,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 1100px) { .jkd-kpis { grid-template-columns:repeat(3,minmax(0,1fr)); } }
@media (max-width: 560px) { .jkd-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jkd-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:13px 14px; cursor:default; }
.jkd-kpi[data-f] { cursor:pointer; }
.jkd-kpi[data-f]:hover { border-color:var(--b2); }
.jkd-kpi .l { color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; display:flex; align-items:center; gap:6px;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkd-kpi .v { font-size:23px; font-weight:700; letter-spacing:-.02em; margin-top:5px; white-space:nowrap; }
.jkd-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jkd-kpi .v.red { color:var(--a2); }
.jkd-kpi .v.warn { color:var(--warn); }
.jkd-dot { width:8px; height:8px; border-radius:50%; display:inline-block; flex:none; background:var(--m); }
.jkd-dot.on { background:var(--ok); }
.jkd-dot.blk { background:var(--a); }
.jkd-dot.lim { background:var(--warn); }
.jkd-card { background:var(--s); border:1px solid var(--b); border-radius:12px; }
.jkd-bar { display:flex; align-items:center; gap:10px; padding:14px; border-bottom:1px solid var(--b); flex-wrap:wrap; }
.jkd-search { position:relative; flex:1 1 220px; max-width:340px; }
.jkd-search .fa { position:absolute; left:11px; top:50%; transform:translateY(-50%); color:var(--m); }
.jkd input.jkd-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:9px !important;
  padding:8px 10px 8px 32px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:13px; box-shadow:none !important; }
.jkd input.jkd-in:focus { border-color:var(--a) !important; outline:none; }
.jkd input.jkd-num { padding-left:10px !important; font-variant-numeric:tabular-nums; }
.jkd-seg { display:inline-flex; background:var(--s2); border:1px solid var(--b); border-radius:9px; padding:3px; gap:2px; flex-wrap:wrap; }
.jkd-seg span { padding:5px 11px; border-radius:7px; cursor:pointer; color:var(--m); font-weight:600; user-select:none; white-space:nowrap; }
.jkd-seg span:hover { color:var(--t); }
.jkd-seg span.sel { background:var(--h); color:var(--t); box-shadow:inset 0 0 0 1px var(--b2); }
.jkd-seg span em { font-style:normal; color:var(--m); font-weight:500; margin-left:4px; }
.jkd-chips { display:flex; gap:6px; flex-wrap:wrap; }
.jkd-chip { padding:5px 11px; border-radius:999px; background:var(--s2); border:1px solid var(--b); cursor:pointer; font-weight:600; user-select:none; font-size:12px; }
.jkd-chip:hover { border-color:var(--b2); }
.jkd-chip.sel { background:var(--abg); border-color:var(--a); color:#fff; }
.jkd-bar .r { margin-left:auto; color:var(--m); font-size:12px; white-space:nowrap; }
.jkd-table { width:100%; border-collapse:collapse; }
.jkd-table th { text-align:left; font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.06em; color:var(--m);
  padding:10px 12px; border-bottom:1px solid var(--b); white-space:nowrap; cursor:pointer; user-select:none; }
.jkd-table th:hover { color:var(--t); }
.jkd-table th.sorted { color:var(--t); }
.jkd-table th.sorted::after { content:" ▾"; color:var(--a2); }
.jkd-table th.sorted.asc::after { content:" ▴"; }
.jkd-table th.nosort { cursor:default; }
.jkd-table td { padding:9px 12px; border-bottom:1px solid var(--b); vertical-align:middle; }
.jkd-table tr:last-child td { border-bottom:0; }
.jkd-table tbody tr { cursor:pointer; transition:background .1s; }
.jkd-table tbody tr:hover { background:var(--h); }
.jkd-table tbody tr.off { color:var(--m); }
.jkd-table tbody tr.blk td:first-child { box-shadow:inset 3px 0 0 var(--a); }
.jkd-table .num { text-align:right; font-variant-numeric:tabular-nums; white-space:nowrap; }
.jkd-table th.num { text-align:right; }
.jkd-mono { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkd-dev { display:flex; align-items:center; gap:11px; min-width:0; }
.jkd-av { position:relative; width:34px; height:34px; flex:none; border-radius:10px; display:grid; place-items:center; background:#202026; color:#c9c9d1; font-size:15px; }
.jkd-av .jkd-dot { position:absolute; right:-2px; bottom:-2px; border:2px solid var(--s); width:11px; height:11px; }
tr:hover .jkd-av .jkd-dot { border-color:var(--h); }
.jkd-av.blk { background:var(--abg); color:var(--a2); }
.jkd-dn { min-width:0; }
.jkd-dn .n { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:260px; }
.jkd-dn .v { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:260px; }
.jkd-down { color:var(--blue); }
.jkd-up { color:var(--a2); }
.jkd-spark { display:block; }
.jkd-tag { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:6px; white-space:nowrap;
  background:var(--s2); color:var(--m); border:1px solid var(--b); }
.jkd-tag.blk { background:var(--abg); color:var(--a2); border-color:rgba(229,32,46,.35); }
.jkd-tag.lim { background:rgba(245,165,36,.1); color:var(--warn); border-color:rgba(245,165,36,.3); }
.jkd-tag.on { color:var(--ok); }
.jkd-tags { display:flex; gap:5px; flex-wrap:wrap; }
.jkd-act { width:30px; height:30px; border-radius:8px; border:1px solid var(--b); background:var(--s2); color:var(--m); display:grid; place-items:center; cursor:pointer; }
.jkd-act:hover { color:var(--a2); border-color:var(--a); }
.jkd-act.on { color:#fff; background:var(--a); border-color:var(--a); }
.jkd-act.on:hover { background:var(--a2); }
.jkd-act[disabled] { opacity:.35; cursor:default; }
.jkd-empty { color:var(--m); text-align:center; padding:40px 6px; }
.jkd-empty .fa { display:block; font-size:24px; margin-bottom:10px; color:#3a3a42; }
@media (max-width: 1200px) { .jkd .c-mac { display:none; } }
@media (max-width: 980px) { .jkd .c-net, .jkd .c-spark { display:none; } }
@media (max-width: 720px) { .jkd .c-ip, .jkd .c-up, .jkd .c-st { display:none; } .jkd-dn .n, .jkd-dn .v { max-width:150px; }
  .jkd-table th, .jkd-table td { padding-left:8px; padding-right:8px; } }
.jkd-tw { overflow-x:auto; }

/* side panel */
.jkd-shade { position:fixed; inset:0; background:rgba(0,0,0,.45); z-index:1040; opacity:0; pointer-events:none; transition:opacity .2s; }
.jkd-shade.open { opacity:1; pointer-events:auto; }
.jkd-panel { position:fixed; top:0; right:0; bottom:0; width:440px; max-width:100vw; z-index:1041; background:#101013; border-left:1px solid var(--b);
  transform:translateX(105%); transition:transform .22s ease; display:flex; flex-direction:column; box-shadow:-20px 0 60px rgba(0,0,0,.5); }
.jkd-panel.open { transform:none; }
.jkd-ph { display:flex; align-items:center; gap:14px; padding:20px 20px 16px; border-bottom:1px solid var(--b); }
.jkd-ph .jkd-av { width:48px; height:48px; border-radius:13px; font-size:21px; }
.jkd-ph .t { flex:1; min-width:0; }
.jkd-ph .t .n { font-size:18px; font-weight:700; letter-spacing:-.01em; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkd-ph .t .v { color:var(--m); margin-top:2px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkd-x { width:32px; height:32px; border-radius:8px; border:1px solid var(--b); background:var(--s2); color:var(--m); cursor:pointer; flex:none; }
.jkd-x:hover { color:var(--t); }
.jkd-pb { flex:1; overflow-y:auto; padding:16px 20px 24px; }
.jkd-sec { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:18px 0 10px; display:flex; align-items:center; gap:8px; }
.jkd-sec:first-child { margin-top:0; }
.jkd-live { display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:8px; }
.jkd-live > div { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 12px; }
.jkd-live .l { color:var(--m); font-size:11px; font-weight:600; }
.jkd-live .v { font-size:18px; font-weight:700; margin-top:3px; font-variant-numeric:tabular-nums; }
.jkd-chart { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 8px 4px; }
.jkd-kv { display:grid; grid-template-columns:130px minmax(0,1fr); gap:0; }
.jkd-kv > div { padding:7px 0; border-top:1px solid var(--b); }
.jkd-kv > div:nth-child(-n+2) { border-top:0; }
.jkd-kv .k { color:var(--m); }
.jkd-kv .v { word-break:break-all; }
.jkd-box { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; }
.jkd-box.blk { border-color:rgba(229,32,46,.45); background:linear-gradient(180deg,rgba(229,32,46,.09),transparent); }
.jkd-box p { color:var(--m); margin:0 0 12px; line-height:1.5; font-size:12.5px; }
.jkd-box .row { display:flex; gap:8px; align-items:center; flex-wrap:wrap; }
.jkd-speeds { display:flex; flex-wrap:wrap; gap:6px; margin-bottom:12px; }
.jkd-lim { display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:12px; }
.jkd-lim label { display:block; color:var(--m); font-size:11.5px; font-weight:600; margin-bottom:5px; }
.jkd-lim .u { position:relative; }
.jkd-lim .u span { position:absolute; right:10px; top:50%; transform:translateY(-50%); color:var(--m); font-size:12px; pointer-events:none; }
.jkd-links { display:flex; flex-wrap:wrap; gap:8px; margin-top:4px; }

.jkd-toast { position:fixed; left:50%; bottom:24px; transform:translate(-50%,20px); z-index:1060; opacity:0; pointer-events:none; transition:all .2s;
  background:#1b1b20; border:1px solid var(--b2); border-radius:12px; padding:11px 14px; display:flex; align-items:center; gap:12px;
  box-shadow:0 12px 40px rgba(0,0,0,.5); max-width:calc(100vw - 32px); color:var(--t); }
.jkd-toast.open { opacity:1; transform:translate(-50%,0); pointer-events:auto; }
.jkd-toast .fa-check { color:var(--ok); }
.jkd-toast .fa-times-circle { color:var(--a2); }
.jkd-toast .fa-spinner { color:var(--a2); }
.jkd-toast a { font-weight:700; cursor:pointer; white-space:nowrap; }
.jkd .muted { color:var(--m); }
</style>

<div class="jkd" id="jkd">
  <div class="jkd-head">
    <div class="jkd-logo"><i class="fa fa-laptop"></i></div>
    <div>
      <h1 class="jkd-title">Устройства в сети <span class="jkd-pill" id="jkd-online-pill"><i></i><span>…</span></span></h1>
      <div class="jkd-sub">Все клиенты локальных сетей: имена, производители, адреса и трафик. Нажмите на устройство, чтобы заблокировать его или ограничить скорость.</div>
    </div>
    <div class="jkd-head-r">
      <a class="jkd-btn ghost" href="/ui/kea/dhcp/leases4"><i class="fa fa-list"></i> Аренды DHCP</a>
      <button class="jkd-btn ghost" id="jkd-refresh" type="button"><i class="fa fa-refresh"></i> Обновить</button>
    </div>
  </div>

  <div class="jkd-kpis">
    <div class="jkd-kpi" data-f="online"><div class="l"><span class="jkd-dot on"></span>В сети</div><div class="v" id="jkd-k-online">—</div></div>
    <div class="jkd-kpi" data-f="all"><div class="l"><i class="fa fa-database"></i>Известно</div><div class="v" id="jkd-k-all">—</div></div>
    <div class="jkd-kpi"><div class="l"><span class="jkd-down">▼</span>Скачивают</div><div class="v" id="jkd-k-down">—</div></div>
    <div class="jkd-kpi"><div class="l"><span class="jkd-up">▲</span>Отдают</div><div class="v" id="jkd-k-up">—</div></div>
    <div class="jkd-kpi" data-f="blocked"><div class="l"><span class="jkd-dot blk"></span>Заблокировано</div><div class="v red" id="jkd-k-blocked">—</div></div>
    <div class="jkd-kpi" data-f="limited"><div class="l"><span class="jkd-dot lim"></span>Ограничено</div><div class="v warn" id="jkd-k-limited">—</div></div>
  </div>

  <div class="jkd-card">
    <div class="jkd-bar">
      <div class="jkd-search"><i class="fa fa-search"></i><input class="jkd-in" id="jkd-q" type="search" placeholder="Имя, IP, MAC или производитель" spellcheck="false"/></div>
      <div class="jkd-seg" id="jkd-filter">
        <span data-f="all" class="sel">Все</span><span data-f="online">В сети</span><span data-f="offline">Не в сети</span>
        <span data-f="blocked">Заблокированы</span><span data-f="limited">Ограничены</span>
      </div>
      <div class="jkd-chips" id="jkd-nets"></div>
      <div class="r" id="jkd-updated"></div>
    </div>
    <div class="jkd-tw"><table class="jkd-table">
      <thead><tr>
        <th data-sort="name">Устройство</th>
        <th class="c-ip" data-sort="ip">IP-адрес</th>
        <th class="c-mac" data-sort="mac">MAC</th>
        <th class="c-net" data-sort="net">Сеть</th>
        <th class="num" data-sort="down">Скачивание</th>
        <th class="num c-up" data-sort="up">Отдача</th>
        <th class="c-spark nosort">Активность</th>
        <th class="c-st" data-sort="status">Статус</th>
        <th class="nosort"></th>
      </tr></thead>
      <tbody id="jkd-rows"><tr><td colspan="9"><div class="jkd-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></td></tr></tbody>
    </table></div>
  </div>
</div>

<div class="jkd jkd-shade" id="jkd-shade"></div>
<aside class="jkd jkd-panel" id="jkd-panel" aria-hidden="true"></aside>
<div class="jkd jkd-toast" id="jkd-toast"></div>

<script>
'use strict';
$(function () {
    const ALIAS_MAC = 'jkufw_block_mac';
    const ALIAS_IP = 'jkufw_block_ip';
    const RULE_DESC = 'jk-ufw: blocked devices';
    const LIMIT_TAG = 'jk-ufw limit ';           // + "<mac> down|up" on shaper pipes and rules
    const TRAFFIC_EVERY = 10000;                 // iftop samples for 2 s, so keep this well above that
    const LIST_EVERY = 30000;
    const HISTORY = 30;

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
    });
    const ALL = {current: 1, rowCount: -1, searchPhrase: ''};
    const rows = (r) => (r && Array.isArray(r.rows)) ? r.rows : [];
    const splitList = (v) => String(v || '').split(/[\s,]+/).map((s) => s.trim()).filter(Boolean);
    const normMac = (m) => String(m || '').trim().toLowerCase();
    const isV6 = (ip) => String(ip).includes(':');
    const isLinkLocal = (ip) => /^fe80:/i.test(String(ip));
    const ipKey = (ip) => isV6(ip) ? 'z' + ip : String(ip).split('.').map((p) => p.padStart(3, '0')).join('.');
    const parseTime = (v) => {
        if (v === undefined || v === null || v === '') {
            return null;
        }
        if (typeof v === 'number' || /^\d+$/.test(String(v))) {
            const n = Number(v);
            return n > 1e12 ? n : n * 1000;
        }
        const t = Date.parse(String(v).replace(' ', 'T'));
        return isNaN(t) ? null : t;
    };

    function fmtRate(bits) {
        bits = Number(bits) || 0;
        if (bits <= 0) {
            return '—';
        }
        const u = [['бит/с', 1], ['кбит/с', 1e3], ['Мбит/с', 1e6], ['Гбит/с', 1e9]];
        let i = 0;
        while (i < u.length - 1 && bits >= u[i + 1][1] * 0.9995) {
            i++;
        }
        const v = bits / u[i][1];
        return (v >= 100 || i === 0 ? v.toFixed(0) : v.toFixed(1)).replace('.', ',') + ' ' + u[i][0];
    }
    function fmtRateHtml(bits) {
        const s = fmtRate(bits);
        const i = s.lastIndexOf(' ');
        return i < 0 ? s : `${s.slice(0, i)}<small>${s.slice(i + 1)}</small>`;
    }
    function ago(ms) {
        if (!ms) {
            return '—';
        }
        const s = Math.max(0, Math.round((Date.now() - ms) / 1000));
        if (s < 60) {
            return 'только что';
        }
        if (s < 3600) {
            return Math.round(s / 60) + ' мин назад';
        }
        if (s < 86400) {
            return Math.round(s / 3600) + ' ч назад';
        }
        return Math.round(s / 86400) + ' дн назад';
    }
    const fmtDate = (ms) => ms ? new Date(ms).toLocaleString('ru-RU', {day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'}) : '—';

    // Device type icon from vendor and name, the way UniFi shows a device glyph next to the client.
    const ICONS = [
        [/iphone|ipad|android|galaxy|pixel|redmi|poco|oneplus|realme|honor|nokia|motorola|oppo|vivo|xiaomi|huawei|samsung|zte|meizu|tecno|infinix/i, 'fa-mobile'],
        [/apple|macbook|imac|mac-?mini/i, 'fa-apple'],
        [/printer|canon|epson|brother|kyocera|xerox|ricoh|lexmark|pantum/i, 'fa-print'],
        [/tv|lg electronics|sony|philips|hisense|tcl|roku|chromecast|vizio|kivi|skyworth/i, 'fa-television'],
        [/playstation|xbox|nintendo|valve|steam/i, 'fa-gamepad'],
        [/amazon|echo|alexa|google|nest|sonos|yandex|station/i, 'fa-volume-up'],
        [/ubiquiti|tp-?link|mikrotik|cisco|netgear|keenetic|zyxel|d-?link|tenda|mercusys|aruba|ruckus|routerboard|cudy|edimax/i, 'fa-wifi'],
        [/raspberry|espressif|arduino|tuya|shelly|sonoff|aqara|lumi|ezviz|hikvision|dahua|reolink|wyze|ring/i, 'fa-microchip'],
        [/vmware|virtualbox|pcs systemtechnik|oracle|parallels|qemu|xensource|proxmox|microsoft corp.*hyper|red hat/i, 'fa-cube'],
        [/synology|qnap|western digital|seagate|buffalo|asustor|truenas/i, 'fa-hdd-o'],
        [/intel|realtek|dell|hewlett|hp inc|lenovo|acer|asustek|micro-star|msi|gigabyte|asrock|microsoft|azurewave|liteon|foxconn|qualcomm|broadcom|mediatek/i, 'fa-desktop']
    ];
    const iconFor = (d) => {
        const text = `${d.name} ${d.vendor}`;
        const hit = ICONS.find(([re]) => re.test(text));
        return hit ? hit[1] : 'fa-question-circle-o';
    };

    let ifaces = {};          // key -> label (LAN, GUEST, ...)
    let ifaceByLabel = {};    // lowercased label -> key
    let devices = [];
    let hist = {};            // mac -> {down:[], up:[]}
    let rates = {};           // ip -> {down, up}
    let trafficOk = null;
    let cfg = {macAlias: null, ipAlias: null, rule: null, pipes: [], srules: []};
    let filter = 'all';
    let net = '';
    let query = '';
    let sort = {key: 'down', asc: false};
    let current = null;       // mac shown in the side panel
    let busy = false;
    let listTimer = null;
    let trafficTimer = null;

    function aliasEntries(alias) {
        return alias ? splitList(alias.content) : [];
    }

    async function loadConfig() {
        const [al, fr, pp, sr] = await Promise.all([
            api('/api/firewall/alias/search_item', Object.assign({}, ALL, {searchPhrase: 'jkufw_'})).catch(() => null),
            api('/api/firewall/filter/search_rule', Object.assign({}, ALL, {searchPhrase: RULE_DESC})).catch(() => null),
            api('/api/trafficshaper/settings/search_pipes', Object.assign({}, ALL, {searchPhrase: LIMIT_TAG.trim()})).catch(() => null),
            api('/api/trafficshaper/settings/search_rules', Object.assign({}, ALL, {searchPhrase: LIMIT_TAG.trim()})).catch(() => null)
        ]);
        cfg = {
            macAlias: rows(al).find((a) => a.name === ALIAS_MAC) || null,
            ipAlias: rows(al).find((a) => a.name === ALIAS_IP) || null,
            rule: rows(fr).find((r) => r.description === RULE_DESC) || null,
            pipes: rows(pp).filter((p) => String(p.description || '').startsWith(LIMIT_TAG)),
            srules: rows(sr).filter((p) => String(p.description || '').startsWith(LIMIT_TAG))
        };
    }

    function limitOf(mac) {
        const res = {};
        ['down', 'up'].forEach((dir) => {
            const p = cfg.pipes.find((x) => x.description === `${LIMIT_TAG}${mac} ${dir}`);
            if (p) {
                // search results carry the option label ("kbit/s"), get_pipe the key ("Kbit")
                const metric = String(p.bandwidthMetric || 'Mbit').toLowerCase().replace('/s', '');
                const mult = {bit: 1e-6, kbit: 1e-3, mbit: 1, gbit: 1e3}[metric] || 1;
                res[dir] = {uuid: p.uuid, mbit: Number(p.bandwidth) * mult, enabled: String(p.enabled) !== '0'};
            }
        });
        return (res.down || res.up) ? res : null;
    }

    async function loadDevices() {
        const [ifl, arp, ndp, k4, k6, dm, hw] = await Promise.all([
            api('/api/firewall/filter/get_interface_list').catch(() => null),
            api('/api/diagnostics/interface/get_arp'),
            api('/api/diagnostics/interface/get_ndp').catch(() => []),
            api('/api/kea/leases4/search', ALL).catch(() => null),
            api('/api/kea/leases6/search', ALL).catch(() => null),
            api('/api/dnsmasq/leases/search', ALL).catch(() => null),
            api('/api/hostdiscovery/service/search', ALL).catch(() => null),
            loadConfig()
        ]);

        ifaces = {};
        ifaceByLabel = {};
        ((ifl && ifl.interfaces && ifl.interfaces.items) || []).forEach((i) => {
            ifaces[i.value] = i.label;
            ifaceByLabel[String(i.label).toLowerCase()] = i.value;
        });
        const keyOfLabel = (label) => ifaceByLabel[String(label || '').toLowerCase()] || '';

        const map = new Map();
        const own = new Set();
        const dev = (mac) => {
            mac = normMac(mac);
            if (!map.has(mac)) {
                map.set(mac, {mac: mac, ips: new Set(), names: [], vendor: '', ifkey: '', iflabel: '', online: false,
                    lease: null, first: null, last: null});
            }
            return map.get(mac);
        };
        const setIf = (d, key, label) => {
            if (!d.ifkey && (key || label)) {
                d.ifkey = key || keyOfLabel(label);
                d.iflabel = label || ifaces[key] || key;
            }
        };
        const cleanName = (n) => {
            n = String(n || '').trim();
            return (n === '*' || n === '?') ? '' : n.replace(/\.$/, '');
        };

        (Array.isArray(arp) ? arp : []).forEach((e) => {
            if (!e.mac || e.mac === '(incomplete)') {
                return;
            }
            if (e.permanent) {
                own.add(normMac(e.mac));   // the firewall's own interfaces
                return;
            }
            const d = dev(e.mac);
            d.ips.add(e.ip);
            if (!e.expired) {
                d.online = true;
                d.last = Date.now();
            }
            if (cleanName(e.hostname)) {
                d.names.push(cleanName(e.hostname));
            }
            d.vendor = d.vendor || e.manufacturer || '';
            setIf(d, keyOfLabel(e.intf_description), e.intf_description || e.intf);
        });
        (Array.isArray(ndp) ? ndp : []).forEach((e) => {
            const mac = normMac(e.mac);
            if (!mac || own.has(mac) || !/^[0-9a-f:]{17}$/.test(mac)) {
                return;
            }
            const d = dev(mac);
            if (!isLinkLocal(e.ip)) {
                d.ips.add(String(e.ip).split('%')[0]);
            }
            d.vendor = d.vendor || e.manufacturer || '';
            setIf(d, keyOfLabel(e.intf_description), e.intf_description || e.intf);
        });
        const addLease = (r, source) => {
            const mac = normMac(r.hwaddr);
            if (!mac || own.has(mac)) {
                return;
            }
            const d = dev(mac);
            if (r.address) {
                d.ips.add(r.address);
            }
            if (cleanName(r.hostname)) {
                d.names.unshift(cleanName(r.hostname));   // the name the device asked DHCP for wins
            }
            d.vendor = d.vendor || r.mac_info || '';
            setIf(d, r.if_name, r.if_descr);
            if (!d.lease || isV6(d.lease.address)) {
                d.lease = {source: source, address: r.address, type: r.lease_type || '', expire: parseTime(r.expire)};
            }
        };
        rows(k4).forEach((r) => addLease(r, 'Kea'));
        rows(k6).forEach((r) => addLease(r, 'Kea'));
        rows(dm).forEach((r) => addLease(r, 'Dnsmasq'));
        rows(hw).forEach((r) => {
            const mac = normMac(r.ether_address);
            if (!mac || own.has(mac)) {
                return;
            }
            const d = dev(mac);
            if (r.ip_address && !isLinkLocal(r.ip_address)) {
                d.ips.add(r.ip_address);
            }
            d.vendor = d.vendor || r.organization_name || '';
            setIf(d, keyOfLabel(r.interface_name), r.interface_name);
            const f = parseTime(r.first_seen);
            const l = parseTime(r.last_seen);
            if (f && (!d.first || f < d.first)) {
                d.first = f;
            }
            if (l && (!d.last || l > d.last)) {
                d.last = l;
            }
            if (l && Date.now() - l < 5 * 60 * 1000) {
                d.online = true;
            }
        });

        const blockedMacs = new Set(aliasEntries(cfg.macAlias).map(normMac));
        devices = [...map.values()]
            .filter((d) => d.ifkey !== 'wan')
            .map((d) => {
                const ips = [...d.ips].filter(Boolean).sort((a, b) => ipKey(a).localeCompare(ipKey(b)));
                return Object.assign(d, {
                    ips: ips,
                    ip4: ips.find((ip) => !isV6(ip)) || '',
                    name: d.names[0] || '',
                    blocked: blockedMacs.has(d.mac),
                    limit: limitOf(d.mac)
                });
            });
        // keep blocked devices visible even when they are gone from every table
        blockedMacs.forEach((mac) => {
            if (!map.has(mac)) {
                devices.push({mac: mac, ips: [], ip4: '', name: '', names: [], vendor: '', ifkey: '', iflabel: '', online: false,
                    lease: null, first: null, last: null, blocked: true, limit: limitOf(mac)});
            }
        });
        devices.forEach((d) => {
            d.title = d.name || d.vendor || d.ip4 || d.ips[0] || d.mac.toUpperCase();
            d.icon = iconFor(d);
        });
        $('#jkd-updated').text('Обновлено ' + new Date().toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'}));
    }

    async function loadTraffic() {
        const keys = Object.keys(ifaces).filter((k) => k !== 'wan' && !/^(lo|openvpn|wireguard|ipsec|enc)/.test(k));
        if (!keys.length) {
            return;
        }
        try {
            const top = await api('/api/diagnostics/traffic/top/' + keys.join(','));
            const next = {};
            const add = (ip, down, up) => {
                const cur = next[ip] || (next[ip] = {down: 0, up: 0});
                cur.down += down;
                cur.up += up;
            };
            // iftop pairs: each record is one end of the conversations (its "in" is what it receives), the
            // details are the other ends with what they send. Which end is the LAN device depends on iftop,
            // so count both; a partner's share of the record's sending is split by how much it sends back.
            Object.values(top || {}).forEach((intf) => {
                (intf.records || []).forEach((r) => {
                    const rin = Number(r.rate_bits_in) || 0;
                    const rout = Number(r.rate_bits_out) || 0;
                    add(r.address, rin, rout);
                    const details = r.details || [];
                    const sent = details.reduce((s, x) => s + (Number(x.rate_bits) || 0), 0);
                    details.forEach((x) => {
                        const up = Number(x.rate_bits) || 0;
                        const share = details.length === 1 ? 1 : (sent ? up / sent : 1 / details.length);
                        add(x.address, rout * share, up);
                    });
                });
            });
            rates = next;
            trafficOk = true;
        } catch (e) {
            trafficOk = false;
            rates = {};
        }
        devices.forEach((d) => {
            const h = hist[d.mac] || (hist[d.mac] = {down: [], up: []});
            let down = 0;
            let up = 0;
            d.ips.forEach((ip) => {
                if (rates[ip]) {
                    down += rates[ip].down;
                    up += rates[ip].up;
                }
            });
            d.down = down;
            d.up = up;
            h.down.push(down);
            h.up.push(up);
            if (h.down.length > HISTORY) {
                h.down.shift();
                h.up.shift();
            }
        });
    }

    function spark(h, w, hgt, big) {
        const down = (h && h.down) || [];
        const up = (h && h.up) || [];
        const n = Math.max(down.length, 2);
        const max = Math.max(1, ...down, ...up);
        const pts = (arr) => {
            const pad = arr.length < 2 ? [0, 0].concat(arr).slice(-2) : arr;
            return pad.map((v, i) => `${(i / (pad.length - 1) * w).toFixed(1)},${(hgt - 1 - v / max * (hgt - 3)).toFixed(1)}`).join(' ');
        };
        if (n < 2 && !big) {
            return '';
        }
        return `<svg class="jkd-spark" width="${big ? '100%' : w}" height="${hgt}" viewBox="0 0 ${w} ${hgt}" preserveAspectRatio="none">
            <polygon points="0,${hgt} ${pts(down)} ${w},${hgt}" fill="rgba(76,141,255,.16)"/>
            <polyline points="${pts(down)}" fill="none" stroke="#4c8dff" stroke-width="1.5" vector-effect="non-scaling-stroke"/>
            <polyline points="${pts(up)}" fill="none" stroke="#ff3b47" stroke-width="1.2" vector-effect="non-scaling-stroke"/></svg>`;
    }

    const avatar = (d) => `<div class="jkd-av ${d.blocked ? 'blk' : ''}"><i class="fa ${d.blocked ? 'fa-ban' : d.icon}"></i>
        <span class="jkd-dot ${d.online ? 'on' : ''}"></span></div>`;

    function statusTags(d) {
        const t = [];
        if (d.blocked) {
            t.push('<span class="jkd-tag blk"><i class="fa fa-ban"></i>Заблокировано</span>');
        }
        if (d.limit) {
            const l = d.limit;
            const s = [l.down ? `▼${fmtMbit(l.down.mbit)}` : '', l.up ? `▲${fmtMbit(l.up.mbit)}` : ''].filter(Boolean).join(' ');
            t.push(`<span class="jkd-tag lim"><i class="fa fa-tachometer"></i>${esc(s)}</span>`);
        }
        if (!t.length) {
            t.push(d.online ? '<span class="jkd-tag on"><span class="jkd-dot on"></span>В сети</span>'
                : `<span class="jkd-tag">${d.last ? esc(ago(d.last)) : 'Не в сети'}</span>`);
        }
        return `<div class="jkd-tags">${t.join('')}</div>`;
    }
    const fmtMbit = (v) => (v >= 1 ? String(+v.toFixed(1)) : String(+v.toFixed(2))).replace('.', ',');

    function visible() {
        const q = query.toLowerCase();
        return devices.filter((d) => {
            if (filter === 'online' && !d.online) {
                return false;
            }
            if (filter === 'offline' && d.online) {
                return false;
            }
            if (filter === 'blocked' && !d.blocked) {
                return false;
            }
            if (filter === 'limited' && !d.limit) {
                return false;
            }
            if (net && d.ifkey !== net) {
                return false;
            }
            if (q) {
                const hay = [d.title, d.vendor, d.mac, d.mac.replace(/:/g, '-'), ...d.ips, ...d.names].join(' ').toLowerCase();
                return hay.includes(q);
            }
            return true;
        });
    }

    function sorter(a, b) {
        const k = sort.key;
        let r = 0;
        if (k === 'down' || k === 'up') {
            r = (a[k] || 0) - (b[k] || 0);
            if (!r) {
                r = (a.online - b.online) || -a.title.localeCompare(b.title, 'ru');
            }
        } else if (k === 'ip') {
            r = ipKey(a.ip4 || a.ips[0] || 'zz').localeCompare(ipKey(b.ip4 || b.ips[0] || 'zz'));
        } else if (k === 'mac') {
            r = a.mac.localeCompare(b.mac);
        } else if (k === 'net') {
            r = String(a.iflabel).localeCompare(String(b.iflabel), 'ru');
        } else if (k === 'status') {
            const w = (d) => (d.blocked ? 4 : 0) + (d.limit ? 2 : 0) + (d.online ? 1 : 0);
            r = w(a) - w(b);
        } else {
            r = a.title.localeCompare(b.title, 'ru', {numeric: true});
        }
        return sort.asc ? r : -r;
    }

    function render() {
        const online = devices.filter((d) => d.online).length;
        $('#jkd-online-pill span').text(`${online} в сети`);
        $('#jkd-k-online').text(online);
        $('#jkd-k-all').text(devices.length);
        const sum = (k) => devices.reduce((s, d) => s + (d[k] || 0), 0);
        $('#jkd-k-down').html(trafficOk === false ? '<span class="muted">н/д</span>' : fmtRateHtml(sum('down')));
        $('#jkd-k-up').html(trafficOk === false ? '<span class="muted">н/д</span>' : fmtRateHtml(sum('up')));
        $('#jkd-k-blocked').text(devices.filter((d) => d.blocked).length);
        $('#jkd-k-limited').text(devices.filter((d) => d.limit).length);

        const nets = {};
        devices.forEach((d) => {
            if (d.ifkey) {
                nets[d.ifkey] = (nets[d.ifkey] || 0) + 1;
            }
        });
        const netKeys = Object.keys(nets).sort((a, b) => nets[b] - nets[a]);
        $('#jkd-nets').html(netKeys.length > 1 ? [`<span class="jkd-chip ${net ? '' : 'sel'}" data-net="">Все сети</span>`]
            .concat(netKeys.map((k) => `<span class="jkd-chip ${net === k ? 'sel' : ''}" data-net="${esc(k)}">${esc(ifaces[k] || k)} · ${nets[k]}</span>`)).join('') : '');
        $('#jkd-filter span').each(function () {
            $(this).toggleClass('sel', $(this).data('f') === filter);
        });
        $('.jkd-table th[data-sort]').each(function () {
            $(this).toggleClass('sorted', $(this).data('sort') === sort.key).toggleClass('asc', sort.asc);
        });

        const list = visible().sort(sorter);
        if (!list.length) {
            const msg = devices.length ? 'Под фильтр ничего не попало' : 'Устройства пока не найдены';
            $('#jkd-rows').html(`<tr><td colspan="9"><div class="jkd-empty"><i class="fa fa-laptop"></i>${msg}</div></td></tr>`);
        } else {
            $('#jkd-rows').html(list.map((d) => {
                const extra = d.ips.length > 1 ? ` <span class="muted">+${d.ips.length - 1}</span>` : '';
                const sub = d.name && d.vendor ? d.vendor : (d.name ? '' : (d.vendor ? d.mac.toUpperCase() : ''));
                return `<tr class="${d.online ? '' : 'off'} ${d.blocked ? 'blk' : ''}" data-mac="${esc(d.mac)}">
                    <td><div class="jkd-dev">${avatar(d)}<div class="jkd-dn"><div class="n" title="${esc(d.title)}">${esc(d.title)}</div>
                        <div class="v">${esc(sub) || '&nbsp;'}</div></div></div></td>
                    <td class="c-ip jkd-mono">${esc(d.ip4 || d.ips[0] || '—')}${extra}</td>
                    <td class="c-mac jkd-mono muted">${esc(d.mac.toUpperCase())}</td>
                    <td class="c-net">${esc(d.iflabel || '—')}</td>
                    <td class="num"><span class="jkd-down">${d.down ? '▼' : ''}</span> ${fmtRate(d.down)}</td>
                    <td class="num c-up"><span class="jkd-up">${d.up ? '▲' : ''}</span> ${fmtRate(d.up)}</td>
                    <td class="c-spark">${spark(hist[d.mac], 90, 24)}</td>
                    <td class="c-st">${statusTags(d)}</td>
                    <td><button type="button" class="jkd-act ${d.blocked ? 'on' : ''}" data-act="block" ${busy ? 'disabled' : ''}
                        title="${d.blocked ? 'Разблокировать' : 'Заблокировать доступ'}"><i class="fa ${d.blocked ? 'fa-unlock' : 'fa-ban'}"></i></button></td>
                </tr>`;
            }).join(''));
        }
        if (current) {
            renderPanel();
        }
    }

    // ---------- side panel ----------
    let draft = null;   // speed limit being edited: {down, up} in Mbit/s

    function renderPanel() {
        const d = devices.find((x) => x.mac === current);
        if (!d) {
            return;
        }
        if (!draft || draft.mac !== d.mac) {
            draft = {mac: d.mac, down: d.limit && d.limit.down ? d.limit.down.mbit : '', up: d.limit && d.limit.up ? d.limit.up.mbit : ''};
        }
        const v4 = d.ips.filter((ip) => !isV6(ip));
        const v6 = d.ips.filter(isV6);
        const lease = d.lease ? `${d.lease.type === 'static' ? 'Постоянный' : 'Динамический'} (${esc(d.lease.source)})` : 'Не через DHCP этого экрана';
        const kv = [
            ['Состояние', d.online ? '<span class="jkd-tag on"><span class="jkd-dot on"></span>В сети</span>' : 'Не в сети'],
            ['IPv4', v4.length ? v4.map(esc).join('<br>') : '—'],
            ['IPv6', v6.length ? v6.map(esc).join('<br>') : '—'],
            ['MAC', esc(d.mac.toUpperCase())],
            ['Производитель', esc(d.vendor || 'неизвестен')],
            ['Сеть', esc(d.iflabel || '—')],
            ['Адрес выдан', lease],
            ['Аренда до', d.lease && d.lease.expire ? esc(fmtDate(d.lease.expire)) : '—'],
            ['Впервые замечен', esc(fmtDate(d.first))],
            ['Активность', d.online ? 'сейчас' : esc(ago(d.last))]
        ].map(([k, v]) => `<div class="k">${k}</div><div class="v ${/MAC|IPv/.test(k) ? 'jkd-mono' : ''}">${v}</div>`).join('');

        const canLimit = d.ips.length > 0 && !!d.ifkey;
        const presets = [1, 5, 10, 25, 50, 100];
        const sel = (v) => Number(draft.down) === v && Number(draft.up) === v;
        const h = hist[d.mac];

        $('#jkd-panel').html(`
            <div class="jkd-ph">${avatar(d)}
                <div class="t"><div class="n" title="${esc(d.title)}">${esc(d.title)}</div>
                <div class="v">${esc([d.vendor, d.ip4].filter(Boolean).join(' · ') || d.mac.toUpperCase())}</div></div>
                <button class="jkd-x" type="button" id="jkd-close" title="Закрыть"><i class="fa fa-times"></i></button></div>
            <div class="jkd-pb">
                <div class="jkd-sec"><i class="fa fa-line-chart"></i> Трафик сейчас</div>
                <div class="jkd-live">
                    <div><div class="l"><span class="jkd-down">▼</span> Скачивание</div><div class="v">${fmtRate(d.down)}</div></div>
                    <div><div class="l"><span class="jkd-up">▲</span> Отдача</div><div class="v">${fmtRate(d.up)}</div></div>
                </div>
                <div class="jkd-chart">${spark(h, 400, 70, true) || '<div class="muted" style="padding:20px 6px;text-align:center">Собираем данные…</div>'}</div>

                <div class="jkd-sec"><i class="fa fa-ban"></i> Доступ</div>
                <div class="jkd-box ${d.blocked ? 'blk' : ''}">
                    ${d.blocked
                        ? `<p><b style="color:var(--a2)">Устройство заблокировано.</b> Оно не выходит в интернет и в другие сети, но может обращаться к этому экрану (DNS, DHCP, веб-интерфейс).</p>
                           <button class="jkd-btn ok" type="button" data-act="block" ${busy ? 'disabled' : ''}><i class="fa fa-unlock"></i> Разблокировать</button>`
                        : `<p>Блокировка закрывает устройству интернет и другие сети по MAC-адресу, даже если оно сменит IP. Доступ к самому экрану (DNS, DHCP, веб-интерфейс) останется.</p>
                           <button class="jkd-btn" type="button" data-act="block" ${busy ? 'disabled' : ''}><i class="fa fa-ban"></i> Заблокировать</button>`}
                </div>

                <div class="jkd-sec"><i class="fa fa-tachometer"></i> Ограничение скорости</div>
                <div class="jkd-box">
                    ${canLimit ? `
                    <p>${d.limit ? 'Сейчас действует ограничение. Его можно изменить или снять.' : 'Скорость для этого устройства, отдельно на скачивание и на отдачу.'}</p>
                    <div class="jkd-speeds">${presets.map((v) => `<span class="jkd-chip ${sel(v) ? 'sel' : ''}" data-preset="${v}">${v} Мбит/с</span>`).join('')}</div>
                    <div class="jkd-lim">
                        <div><label><span class="jkd-down">▼</span> Скачивание</label><div class="u"><input class="jkd-in jkd-num" id="jkd-lim-down" type="number" min="0.1" step="0.1" value="${esc(draft.down)}" placeholder="без огр."/><span>Мбит/с</span></div></div>
                        <div><label><span class="jkd-up">▲</span> Отдача</label><div class="u"><input class="jkd-in jkd-num" id="jkd-lim-up" type="number" min="0.1" step="0.1" value="${esc(draft.up)}" placeholder="без огр."/><span>Мбит/с</span></div></div>
                    </div>
                    <div class="row">
                        <button class="jkd-btn" type="button" data-act="limit" ${busy ? 'disabled' : ''}><i class="fa fa-check"></i> ${d.limit ? 'Изменить' : 'Ограничить'}</button>
                        ${d.limit ? `<button class="jkd-btn ghost" type="button" data-act="unlimit" ${busy ? 'disabled' : ''}><i class="fa fa-times"></i> Снять ограничение</button>` : ''}
                    </div>` : '<p style="margin:0">Ограничить скорость можно, когда у устройства известны IP-адрес и сеть. Подождите, пока оно появится в сети.</p>'}
                </div>

                <div class="jkd-sec"><i class="fa fa-info-circle"></i> Подробности</div>
                <div class="jkd-kv">${kv}</div>
                <div class="jkd-links" style="margin-top:14px">
                    <a class="jkd-btn ghost sm" href="/ui/kea/dhcp/v4"><i class="fa fa-thumb-tack"></i> Закрепить IP</a>
                    <a class="jkd-btn ghost sm" href="/ui/firewall/filter"><i class="fa fa-shield"></i> Правила</a>
                    <a class="jkd-btn ghost sm" href="/ui/trafficshaper"><i class="fa fa-filter"></i> Шейпер</a>
                </div>
            </div>`);
    }

    function openPanel(mac) {
        current = mac;
        draft = null;
        renderPanel();
        $('#jkd-panel').addClass('open').attr('aria-hidden', 'false');
        $('#jkd-shade').addClass('open');
    }
    function closePanel() {
        current = null;
        $('#jkd-panel').removeClass('open').attr('aria-hidden', 'true');
        $('#jkd-shade').removeClass('open');
    }

    let toastTimer = null;
    function toast(kind, html, undo) {
        clearTimeout(toastTimer);
        const icon = {ok: 'fa-check', err: 'fa-times-circle', run: 'fa-spinner fa-pulse'}[kind] || 'fa-info-circle';
        $('#jkd-toast').html(`<i class="fa ${icon}"></i><div>${html}</div>${undo ? '<a id="jkd-undo">Отменить</a>' : ''}`).addClass('open');
        $('#jkd-undo').on('click', () => {
            $('#jkd-toast').removeClass('open');
            undo();
        });
        if (kind !== 'run') {
            toastTimer = setTimeout(() => $('#jkd-toast').removeClass('open'), kind === 'err' ? 9000 : 6000);
        }
    }

    // ---------- actions ----------
    function checkSaved(r, what) {
        if (!r || r.result !== 'saved') {
            const msg = Object.values((r && r.validations) || {}).join(' ');
            throw new Error(`${what}: ${msg || 'не сохранено'}`);
        }
        return r;
    }

    async function setAlias(name, type, existing, entries, descr) {
        const content = [...new Set(entries)].join('\n');
        if (existing) {
            return checkSaved(await api('/api/firewall/alias/set_item/' + existing.uuid, {alias: {content: content, enabled: '1'}}), name);
        }
        return checkSaved(await api('/api/firewall/alias/add_item', {alias: {enabled: '1', name: name, type: type, content: content,
            description: descr}}), name);
    }

    async function withBusy(fn) {
        if (busy) {
            return;
        }
        busy = true;
        render();
        try {
            await fn();
        } catch (e) {
            toast('err', `<b>Не получилось.</b> ${esc(e.message)}`);
        }
        busy = false;
        await refresh();
    }

    async function setBlocked(d, block) {
        const name = esc(d.title);
        toast('run', block ? `Блокируем <b>${name}</b>…` : `Разблокируем <b>${name}</b>…`);
        await loadConfig();
        let macs = aliasEntries(cfg.macAlias).map(normMac);
        let ips = aliasEntries(cfg.ipAlias);
        if (block) {
            macs.push(d.mac);
            ips = ips.concat(d.ips);   // takes effect at once; the MAC alias follows IP changes
        } else {
            macs = macs.filter((m) => m !== d.mac);
            ips = ips.filter((ip) => !d.ips.includes(ip));
        }
        await setAlias(ALIAS_MAC, 'mac', cfg.macAlias, macs, 'jk-ufw: заблокированные устройства (MAC)');
        await setAlias(ALIAS_IP, 'host', cfg.ipAlias, ips, 'jk-ufw: заблокированные устройства (IP)');
        if (!cfg.rule) {
            // floating, quick, first: block everything from these devices except traffic to the firewall itself
            checkSaved(await api('/api/firewall/filter/add_rule', {rule: {
                enabled: '1', action: 'block', quick: '1', interface: '', direction: 'in', ipprotocol: 'inet46',
                protocol: 'any', source_net: `${ALIAS_MAC},${ALIAS_IP}`, destination_net: '(self)', destination_not: '1',
                log: '1', sequence: '1', description: RULE_DESC}}), 'правило');
        } else if (String(cfg.rule.enabled) === '0') {
            await api('/api/firewall/filter/toggle_rule/' + cfg.rule.uuid + '/1', {});
        }
        await api('/api/firewall/filter/apply', {});
        await api('/api/firewall/alias/reconfigure', {});
        if (block) {
            // drop connections that are already open, otherwise they keep working until they time out
            await Promise.all(d.ips.map((ip) => api('/api/diagnostics/firewall/kill_states', {filter: ip}).catch(() => null)));
        }
        toast('ok', block ? `<b>${name}</b> заблокировано.` : `<b>${name}</b> снова в интернете.`,
            () => withBusy(() => setBlocked(d, !block)));
    }

    async function setLimit(d, down, up) {
        const name = esc(d.title);
        const removing = !down && !up;
        toast('run', removing ? `Снимаем ограничение для <b>${name}</b>…` : `Ограничиваем <b>${name}</b>…`);
        await loadConfig();
        const ips = d.ips.join(',');
        const want = {down: down, up: up};
        // rules go first on delete, the shaper refuses to drop a pipe that is still in use
        for (const dir of ['down', 'up']) {
            const desc = `${LIMIT_TAG}${d.mac} ${dir}`;
            const rule = cfg.srules.find((r) => r.description === desc);
            const pipe = cfg.pipes.find((p) => p.description === desc);
            if (!want[dir]) {
                if (rule) {
                    await api('/api/trafficshaper/settings/del_rule/' + rule.uuid, {});
                }
                if (pipe) {
                    await api('/api/trafficshaper/settings/del_pipe/' + pipe.uuid, {});
                }
                continue;
            }
            const pipeData = {pipe: {enabled: '1', bandwidth: String(Math.round(want[dir] * 1000)), bandwidthMetric: 'Kbit',
                mask: 'none', description: desc}};
            let pipeUuid = pipe && pipe.uuid;
            if (pipe) {
                checkSaved(await api('/api/trafficshaper/settings/set_pipe/' + pipe.uuid, pipeData), 'канал');
            } else {
                pipeUuid = checkSaved(await api('/api/trafficshaper/settings/add_pipe', pipeData), 'канал').uuid;
            }
            // on the LAN port the device's downloads leave the firewall towards it, uploads arrive from it
            const ruleData = {rule: {enabled: '1', sequence: '1', interface: d.ifkey, proto: 'ip',
                source: dir === 'up' ? ips : 'any', destination: dir === 'down' ? ips : 'any',
                src_port: 'any', dst_port: 'any', direction: dir === 'down' ? 'out' : 'in', target: pipeUuid, description: desc}};
            if (rule) {
                checkSaved(await api('/api/trafficshaper/settings/set_rule/' + rule.uuid, ruleData), 'правило шейпера');
            } else {
                checkSaved(await api('/api/trafficshaper/settings/add_rule', ruleData), 'правило шейпера');
            }
        }
        await api('/api/trafficshaper/service/reconfigure', {});
        draft = null;
        const txt = [down ? `▼ ${fmtMbit(down)}` : '', up ? `▲ ${fmtMbit(up)}` : ''].filter(Boolean).join(', ');
        toast('ok', removing ? `Ограничение для <b>${name}</b> снято.` : `<b>${name}</b>: ${esc(txt)} Мбит/с.`);
    }

    // ---------- loading ----------
    async function refresh() {
        try {
            await loadDevices();
        } catch (e) {
            $('#jkd-rows').html(`<tr><td colspan="9"><div class="jkd-empty"><i class="fa fa-exclamation-triangle"></i>
                Не удалось получить список устройств: ${esc(e.message)}</div></td></tr>`);
            return;
        }
        devices.forEach((d) => {
            const h = hist[d.mac];
            d.down = h && h.down.length ? h.down[h.down.length - 1] : 0;
            d.up = h && h.up.length ? h.up[h.up.length - 1] : 0;
        });
        render();
    }

    async function listLoop() {
        clearTimeout(listTimer);
        if (!busy && !document.hidden) {
            await refresh();
        }
        listTimer = setTimeout(listLoop, LIST_EVERY);
    }
    async function trafficLoop() {
        clearTimeout(trafficTimer);
        if (!document.hidden && devices.length) {
            await loadTraffic();
            if (!busy) {
                render();
            }
        }
        trafficTimer = setTimeout(trafficLoop, TRAFFIC_EVERY);
    }

    // ---------- events ----------
    $('#jkd-q').on('input', function () {
        query = $(this).val().trim();
        render();
    });
    $('#jkd-filter').on('click', 'span', function () {
        filter = $(this).data('f');
        render();
    });
    $('.jkd-kpi[data-f]').on('click', function () {
        filter = $(this).data('f');
        render();
    });
    $('#jkd-nets').on('click', '.jkd-chip', function () {
        net = String($(this).data('net') || '');
        render();
    });
    $('.jkd-table th[data-sort]').on('click', function () {
        const k = $(this).data('sort');
        sort = sort.key === k ? {key: k, asc: !sort.asc} : {key: k, asc: ['name', 'ip', 'mac', 'net'].includes(k)};
        render();
    });
    $('#jkd-rows').on('click', 'tr[data-mac]', function (e) {
        const mac = $(this).data('mac');
        if ($(e.target).closest('[data-act]').length) {
            const d = devices.find((x) => x.mac === mac);
            if (d) {
                withBusy(() => setBlocked(d, !d.blocked));
            }
            return;
        }
        openPanel(mac);
    });
    $('#jkd-refresh').on('click', async function () {
        $(this).find('.fa').addClass('fa-spin');
        await refresh();
        await loadTraffic();
        render();
        $(this).find('.fa').removeClass('fa-spin');
    });
    $('#jkd-shade').on('click', closePanel);
    $(document).on('keydown', (e) => {
        if (e.key === 'Escape' && current) {
            closePanel();
        }
    });
    $('#jkd-panel')
        .on('click', '#jkd-close', closePanel)
        .on('click', '[data-preset]', function () {
            const v = Number($(this).data('preset'));
            draft.down = v;
            draft.up = v;
            renderPanel();
        })
        .on('input', '#jkd-lim-down, #jkd-lim-up', function () {
            draft[this.id === 'jkd-lim-down' ? 'down' : 'up'] = $(this).val();
            $('#jkd-panel [data-preset]').removeClass('sel');
        })
        .on('click', '[data-act]', function () {
            const d = devices.find((x) => x.mac === current);
            if (!d) {
                return;
            }
            const act = $(this).data('act');
            if (act === 'block') {
                withBusy(() => setBlocked(d, !d.blocked));
            } else if (act === 'unlimit') {
                withBusy(() => setLimit(d, 0, 0));
            } else if (act === 'limit') {
                const down = parseFloat(String(draft.down).replace(',', '.')) || 0;
                const up = parseFloat(String(draft.up).replace(',', '.')) || 0;
                if (!down && !up) {
                    toast('err', 'Укажите скорость хотя бы в одну сторону.');
                    return;
                }
                withBusy(() => setLimit(d, down, up));
            }
        });
    document.addEventListener('visibilitychange', () => {
        if (!document.hidden) {
            listLoop();
            trafficLoop();
        }
    });

    listLoop().then(trafficLoop);
});
</script>
