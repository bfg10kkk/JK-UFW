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
 # jk-ufw: network topology (UniFi "Topology" style). Internet, provider gateways, this firewall, its local networks
 # and every host on them, drawn as a tree. Read only: interfaces and gateways, ARP/NDP, Kea and Dnsmasq leases,
 # host discovery, plus the block alias and shaper pipes of the Devices page to show which hosts are restricted.
 #}

<style>
.jkt { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; --blue:#4c8dff; color:var(--t); font-size:13px; max-width:1480px; }
.jkt * { box-sizing:border-box; }
.jkt b, .jkt strong { font-family:inherit; font-weight:700; }
.jkt a { color:var(--a2); }
.jkt .muted { color:var(--m); }
.jkt-mono { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkt-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jkt-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:22px; color:#fff;
  background:linear-gradient(145deg,var(--a2),#a5121c); box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkt-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkt-sub { color:var(--m); margin-top:2px; max-width:720px; }
.jkt-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jkt-btn { display:inline-flex; align-items:center; justify-content:center; gap:7px; border:0; border-radius:9px; padding:9px 16px;
  font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important; text-decoration:none !important; white-space:nowrap; }
.jkt-btn:hover { background:var(--a2); }
.jkt-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jkt-btn.ghost:hover { background:var(--h); }
.jkt-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }

.jkt-kpis { display:grid; grid-template-columns:repeat(6,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 1100px) { .jkt-kpis { grid-template-columns:repeat(3,minmax(0,1fr)); } }
@media (max-width: 560px) { .jkt-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jkt-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:13px 14px; }
.jkt-kpi[data-hl] { cursor:pointer; }
.jkt-kpi[data-hl]:hover { border-color:var(--b2); }
.jkt-kpi.sel { border-color:var(--a); box-shadow:inset 0 0 0 1px var(--a); }
.jkt-kpi .l { color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; display:flex; align-items:center; gap:6px;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkt-kpi .v { font-size:23px; font-weight:700; letter-spacing:-.02em; margin-top:5px; white-space:nowrap; }
.jkt-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jkt-kpi .v.warn { color:var(--warn); }
.jkt-kpi .v.red { color:var(--a2); }
.jkt-dot { width:8px; height:8px; border-radius:50%; display:inline-block; flex:none; background:var(--m); }
.jkt-dot.on { background:var(--ok); }
.jkt-dot.blk { background:var(--a); }
.jkt-dot.lim { background:var(--warn); }

.jkt-card { background:var(--s); border:1px solid var(--b); border-radius:12px; }
.jkt-bar { display:flex; align-items:center; gap:10px; padding:12px 14px; border-bottom:1px solid var(--b); flex-wrap:wrap; }
.jkt-bar .r { margin-left:auto; display:flex; align-items:center; gap:10px; color:var(--m); font-size:12px; white-space:nowrap; }
.jkt-search { position:relative; flex:1 1 220px; max-width:340px; }
.jkt-search .fa { position:absolute; left:11px; top:50%; transform:translateY(-50%); color:var(--m); }
.jkt input.jkt-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:9px !important;
  padding:8px 10px 8px 32px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:13px; box-shadow:none !important; }
.jkt input.jkt-in:focus { border-color:var(--a) !important; outline:none; }
.jkt-seg { display:inline-flex; background:var(--s2); border:1px solid var(--b); border-radius:9px; padding:3px; gap:2px; flex-wrap:wrap; }
.jkt-seg span { padding:5px 11px; border-radius:7px; cursor:pointer; color:var(--m); font-weight:600; user-select:none; white-space:nowrap; }
.jkt-seg span:hover { color:var(--t); }
.jkt-seg span.sel { background:var(--h); color:var(--t); box-shadow:inset 0 0 0 1px var(--b2); }
.jkt-seg span .fa { margin-right:5px; }

/* map */
.jkt-view { position:relative; height:calc(100vh - 330px); min-height:460px; overflow:hidden; border-radius:0 0 12px 12px; cursor:grab;
  touch-action:none; user-select:none;
  background:radial-gradient(circle at 50% 0%, rgba(229,32,46,.07), transparent 55%),
             radial-gradient(rgba(255,255,255,.055) 1px, transparent 1.2px) 0 0/22px 22px, #0e0e11; }
.jkt-view.drag { cursor:grabbing; }
.jkt-canvas { position:absolute; left:0; top:0; transform-origin:0 0; }
.jkt-canvas svg { position:absolute; left:0; top:0; overflow:visible; pointer-events:none; }
.jkt-ln { fill:none; stroke:#34343c; stroke-width:1.6; }
.jkt-ln.on { stroke:rgba(229,32,46,.75); }
.jkt-ln.flow { stroke:var(--a2); stroke-width:1.6; stroke-dasharray:4 10; animation:jkt-flow 1.2s linear infinite; opacity:.9; }
.jkt-ln.off { stroke-dasharray:3 5; stroke:#2e2e35; }
.jkt-ln.wan { stroke:var(--a); stroke-width:2.4; }
.jkt-ln.down { stroke:#5a5a63; stroke-dasharray:6 6; }
.jkt-ln.dim { opacity:.18; }
@keyframes jkt-flow { to { stroke-dashoffset:-14; } }
@media (prefers-reduced-motion: reduce) { .jkt-ln.flow { animation:none; } }
.jkt-lbl { position:absolute; transform:translate(-50%,-50%); font-size:11px; color:var(--m); background:#0e0e11; padding:1px 7px;
  border:1px solid var(--b); border-radius:999px; white-space:nowrap; pointer-events:none; }
.jkt-node { position:absolute; display:flex; align-items:center; gap:10px; background:#16161a; border:1px solid var(--b2); border-radius:12px;
  padding:8px 10px; cursor:pointer; transition:border-color .12s, box-shadow .12s, opacity .15s; }
.jkt-node:hover { border-color:#4a4a54; }
.jkt-node.sel { border-color:var(--a); box-shadow:0 0 0 3px rgba(229,32,46,.25); }
.jkt-node.dim { opacity:.22; }
.jkt-node.hit { border-color:var(--a2); box-shadow:0 0 0 3px rgba(255,59,71,.28); }
.jkt-node .ic { position:relative; width:36px; height:36px; flex:none; border-radius:10px; display:grid; place-items:center; background:#222228; color:#c9c9d1; font-size:16px; }
.jkt-node .ic .jkt-dot { position:absolute; right:-3px; bottom:-3px; width:11px; height:11px; border:2px solid #16161a; }
.jkt-node .tx { min-width:0; flex:1; }
.jkt-node .n { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkt-node .s { color:var(--m); font-size:11.5px; line-height:1.4; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkt-node.host .s.v { font-size:11px; color:#6f6f7a; }
.jkt-node.host.off { background:#121215; }
.jkt-node.host.off .n { color:#a5a5ae; }
.jkt-node.host.off .ic { color:#6d6d76; }
.jkt-node.host.blk { border-color:rgba(229,32,46,.6); }
.jkt-node.host.blk .ic { background:var(--abg); color:var(--a2); }
.jkt-node .badge { position:absolute; top:-7px; right:8px; font-size:9.5px; font-weight:700; letter-spacing:.04em; text-transform:uppercase;
  padding:1px 6px; border-radius:5px; background:var(--a); color:#fff; }
.jkt-node .badge.lim { background:var(--warn); color:#1a1205; }
.jkt-node .badge.rnd { background:#2a2a31; color:#c9c9d1; border:1px solid var(--b2); }
.jkt-node.big { gap:12px; padding:10px 14px; }
.jkt-node.big .ic { width:44px; height:44px; border-radius:12px; font-size:20px; }
.jkt-node.big .n { font-size:14px; }
.jkt-node.fw .ic { background:linear-gradient(145deg,var(--a2),#a5121c); color:#fff; box-shadow:0 6px 22px rgba(229,32,46,.4); }
.jkt-node.fw { border-color:rgba(229,32,46,.55); background:linear-gradient(180deg,rgba(229,32,46,.1),#16161a 70%); }
.jkt-node.inet .ic { background:#1b2233; color:var(--blue); }
.jkt-node.gw .ic { background:#20202a; color:#d4d4dc; }
.jkt-node.net { border-color:#3a3a44; }
.jkt-node.net .ic { background:#2a1316; color:var(--a2); }
.jkt-node.net .cnt { margin-left:auto; text-align:right; font-size:11px; color:var(--m); line-height:1.35; }
.jkt-node.net .cnt b { color:var(--t); font-size:14px; display:block; }
.jkt-zoom { position:absolute; right:12px; bottom:12px; display:flex; flex-direction:column; gap:6px; z-index:3; }
.jkt-zoom button { width:34px; height:34px; border-radius:9px; border:1px solid var(--b2); background:#17171b; color:var(--t); cursor:pointer; }
.jkt-zoom button:hover { border-color:var(--a); color:var(--a2); }
.jkt-legend { position:absolute; left:12px; top:12px; display:flex; gap:14px; flex-wrap:wrap; z-index:3; background:rgba(14,14,17,.85);
  border:1px solid var(--b); border-radius:9px; padding:7px 11px; font-size:11.5px; color:var(--m); pointer-events:none; }
@media (max-width: 600px) { .jkt-legend { display:none; } }
.jkt-legend span { display:inline-flex; align-items:center; gap:6px; }
.jkt-legend i.l { display:inline-block; width:18px; height:0; border-top:2px solid rgba(229,32,46,.8); }
.jkt-legend i.l.off { border-top:2px dashed #4a4a52; }
.jkt-msg { position:absolute; inset:0; display:grid; place-items:center; color:var(--m); text-align:center; padding:20px; }
.jkt-msg .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }

/* table */
.jkt-tw { overflow-x:auto; }
.jkt-table { width:100%; border-collapse:collapse; }
.jkt-table th { text-align:left; font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.06em; color:var(--m);
  padding:10px 12px; border-bottom:1px solid var(--b); white-space:nowrap; cursor:pointer; user-select:none; }
.jkt-table th:hover, .jkt-table th.sorted { color:var(--t); }
.jkt-table th.sorted::after { content:" ▾"; color:var(--a2); }
.jkt-table th.sorted.asc::after { content:" ▴"; }
.jkt-table td { padding:9px 12px; border-bottom:1px solid var(--b); vertical-align:middle; }
.jkt-table tr:last-child td { border-bottom:0; }
.jkt-table tbody tr { cursor:pointer; }
.jkt-table tbody tr:hover { background:var(--h); }
.jkt-table tbody tr.off { color:var(--m); }
.jkt-table tbody tr.sel td:first-child { box-shadow:inset 3px 0 0 var(--a); }
.jkt-cell { display:flex; align-items:center; gap:10px; min-width:0; }
.jkt-cell .ic { position:relative; width:30px; height:30px; flex:none; border-radius:9px; display:grid; place-items:center; background:#202026; color:#c9c9d1; font-size:14px; }
.jkt-cell .ic .jkt-dot { position:absolute; right:-2px; bottom:-2px; border:2px solid var(--s); width:10px; height:10px; }
.jkt-cell .n { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:240px; }
.jkt-cell .s { color:var(--m); font-size:11.5px; }
@media (max-width: 1100px) { .jkt .c-oui, .jkt .c-seen { display:none; } }
@media (max-width: 820px) { .jkt .c-mtype, .jkt .c-lease { display:none; } }
@media (max-width: 620px) { .jkt .c-mac, .jkt .c-net { display:none; } }
.jkt-tag { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:6px; white-space:nowrap;
  background:var(--s2); color:var(--m); border:1px solid var(--b); }
.jkt-tag.on { color:var(--ok); }
.jkt-tag.blk { background:var(--abg); color:var(--a2); border-color:rgba(229,32,46,.35); }
.jkt-tag.lim, .jkt-tag.warn { background:rgba(245,165,36,.1); color:var(--warn); border-color:rgba(245,165,36,.3); }
.jkt-tag.info { color:#c9c9d1; }
.jkt-tags { display:flex; gap:5px; flex-wrap:wrap; }

/* analysis cards under the map */
.jkt-grid2 { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:14px; margin-top:16px; }
@media (max-width: 900px) { .jkt-grid2 { grid-template-columns:minmax(0,1fr); } }
.jkt-ch { display:flex; align-items:center; gap:8px; padding:13px 14px; border-bottom:1px solid var(--b); font-weight:700; }
.jkt-ch .fa { color:var(--a2); }
.jkt-ch .r { margin-left:auto; color:var(--m); font-weight:500; font-size:12px; }
.jkt-vend { padding:8px 14px 12px; }
.jkt-vrow { display:grid; grid-template-columns:minmax(0,1fr) 110px 34px; gap:10px; align-items:center; padding:6px 6px; border-radius:8px; cursor:pointer; }
.jkt-vrow:hover, .jkt-vrow.sel { background:var(--h); }
.jkt-vrow .nm { display:flex; align-items:center; gap:8px; min-width:0; }
.jkt-vrow .nm span { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkt-vrow .nm .fa { color:var(--m); width:14px; text-align:center; }
.jkt-vrow .bar { height:6px; border-radius:3px; background:#24242a; overflow:hidden; }
.jkt-vrow .bar i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); border-radius:3px; }
.jkt-vrow .c { text-align:right; font-variant-numeric:tabular-nums; color:var(--m); font-weight:600; }
.jkt-issues { padding:6px 14px 12px; }
.jkt-issue { display:flex; gap:11px; padding:9px 6px; border-bottom:1px solid var(--b); cursor:pointer; border-radius:8px; }
.jkt-issue:last-child { border-bottom:0; }
.jkt-issue:hover { background:var(--h); }
.jkt-issue > .fa { margin-top:2px; width:16px; text-align:center; flex:none; }
.jkt-issue .fa-exclamation-triangle { color:var(--warn); }
.jkt-issue .fa-times-circle { color:var(--a2); }
.jkt-issue .fa-info-circle { color:var(--blue); }
.jkt-issue .fa-check-circle { color:var(--ok); }
.jkt-issue .t { font-weight:600; }
.jkt-issue .d { color:var(--m); font-size:12px; margin-top:2px; line-height:1.45; }

/* side panel */
.jkt-shade { position:fixed; inset:0; background:rgba(0,0,0,.45); z-index:1040; opacity:0; pointer-events:none; transition:opacity .2s; }
.jkt-shade.open { opacity:1; pointer-events:auto; }
.jkt-panel { position:fixed; top:0; right:0; bottom:0; width:460px; max-width:100vw; z-index:1041; background:#101013; border-left:1px solid var(--b);
  transform:translateX(105%); transition:transform .22s ease; display:flex; flex-direction:column; box-shadow:-20px 0 60px rgba(0,0,0,.5); }
.jkt-panel.open { transform:none; }
.jkt-ph { display:flex; align-items:center; gap:14px; padding:20px 20px 16px; border-bottom:1px solid var(--b); }
.jkt-ph .ic { position:relative; width:48px; height:48px; border-radius:13px; display:grid; place-items:center; font-size:21px; background:#202026; color:#c9c9d1; flex:none; }
.jkt-ph .ic .jkt-dot { position:absolute; right:-3px; bottom:-3px; width:13px; height:13px; border:2px solid #101013; }
.jkt-ph .ic.fw { background:linear-gradient(145deg,var(--a2),#a5121c); color:#fff; }
.jkt-ph .ic.net { background:#2a1316; color:var(--a2); }
.jkt-ph .ic.blk { background:var(--abg); color:var(--a2); }
.jkt-ph .t { flex:1; min-width:0; }
.jkt-ph .t .n { font-size:18px; font-weight:700; letter-spacing:-.01em; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkt-ph .t .v { color:var(--m); margin-top:2px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkt-x { width:32px; height:32px; border-radius:8px; border:1px solid var(--b); background:var(--s2); color:var(--m); cursor:pointer; flex:none; }
.jkt-x:hover { color:var(--t); }
.jkt-pb { flex:1; overflow-y:auto; padding:16px 20px 24px; }
.jkt-sec { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:20px 0 8px; display:flex; align-items:center; gap:8px; }
.jkt-sec:first-child { margin-top:0; }
.jkt-kv { display:grid; grid-template-columns:140px minmax(0,1fr); }
.jkt-kv > div { padding:7px 0; border-top:1px solid var(--b); }
.jkt-kv > div:nth-child(-n+2) { border-top:0; }
.jkt-kv .k { color:var(--m); }
.jkt-kv .v { word-break:break-word; }
.jkt-kv .v .hint { display:block; color:var(--m); font-size:11.5px; margin-top:2px; }
.jkt-cp { cursor:pointer; border-bottom:1px dashed #44444c; }
.jkt-cp:hover { color:var(--a2); border-bottom-color:var(--a2); }
.jkt-find { display:flex; gap:10px; padding:9px 11px; border-radius:10px; background:var(--s); border:1px solid var(--b); margin-bottom:7px; }
.jkt-find > .fa { margin-top:2px; width:15px; text-align:center; flex:none; }
.jkt-find.warn { border-color:rgba(245,165,36,.35); }
.jkt-find.warn > .fa { color:var(--warn); }
.jkt-find.bad { border-color:rgba(229,32,46,.45); background:linear-gradient(180deg,rgba(229,32,46,.08),transparent); }
.jkt-find.bad > .fa { color:var(--a2); }
.jkt-find.info > .fa { color:var(--blue); }
.jkt-find.ok > .fa { color:var(--ok); }
.jkt-find .t { font-weight:600; }
.jkt-find .d { color:var(--m); font-size:12px; margin-top:2px; line-height:1.45; }
.jkt-links { display:flex; flex-wrap:wrap; gap:8px; margin-top:14px; }
.jkt-toast { position:fixed; left:50%; bottom:24px; transform:translate(-50%,20px); z-index:1060; opacity:0; pointer-events:none; transition:all .2s;
  background:#1b1b20; border:1px solid var(--b2); border-radius:12px; padding:10px 14px; display:flex; align-items:center; gap:10px;
  box-shadow:0 12px 40px rgba(0,0,0,.5); color:var(--t); }
.jkt-toast.open { opacity:1; transform:translate(-50%,0); }
.jkt-toast .fa { color:var(--ok); }
</style>

<div class="jkt" id="jkt">
  <div class="jkt-head">
    <div class="jkt-logo"><i class="fa fa-sitemap"></i></div>
    <div>
      <h1 class="jkt-title">Топология сети</h1>
      <div class="jkt-sub">Карта сети от интернета до каждого устройства: имя, IP, MAC и производитель. Нажмите на любой узел, чтобы увидеть подробный анализ.</div>
    </div>
    <div class="jkt-head-r">
      <a class="jkt-btn ghost" href="/ui/jkufw/devices"><i class="fa fa-laptop"></i> Устройства</a>
      <button class="jkt-btn ghost" id="jkt-csv" type="button"><i class="fa fa-download"></i> CSV</button>
      <button class="jkt-btn ghost" id="jkt-refresh" type="button"><i class="fa fa-refresh"></i> Обновить</button>
    </div>
  </div>

  <div class="jkt-kpis">
    <div class="jkt-kpi" data-hl="online"><div class="l"><span class="jkt-dot on"></span>В сети</div><div class="v" id="jkt-k-online">—</div></div>
    <div class="jkt-kpi"><div class="l"><i class="fa fa-sitemap"></i>Сети</div><div class="v" id="jkt-k-nets">—</div></div>
    <div class="jkt-kpi"><div class="l"><i class="fa fa-industry"></i>Производители</div><div class="v" id="jkt-k-vendors">—</div></div>
    <div class="jkt-kpi" data-hl="random"><div class="l"><i class="fa fa-random"></i>Случайные MAC</div><div class="v" id="jkt-k-random">—</div></div>
    <div class="jkt-kpi" data-hl="noname"><div class="l"><i class="fa fa-question-circle-o"></i>Без имени</div><div class="v" id="jkt-k-noname">—</div></div>
    <div class="jkt-kpi" data-hl="issues"><div class="l"><i class="fa fa-exclamation-triangle"></i>Замечания</div><div class="v" id="jkt-k-issues">—</div></div>
  </div>

  <div class="jkt-card">
    <div class="jkt-bar">
      <div class="jkt-search"><i class="fa fa-search"></i><input class="jkt-in" id="jkt-q" type="search" placeholder="Имя, IP, MAC или производитель" spellcheck="false"/></div>
      <div class="jkt-seg" id="jkt-show">
        <span data-show="all" class="sel">Все</span><span data-show="online">Только в сети</span>
      </div>
      <div class="jkt-seg" id="jkt-mode">
        <span data-mode="map" class="sel"><i class="fa fa-sitemap"></i>Схема</span><span data-mode="table"><i class="fa fa-list"></i>Таблица</span>
      </div>
      <div class="r"><span id="jkt-updated"></span></div>
    </div>
    <div class="jkt-view" id="jkt-view">
      <div class="jkt-canvas" id="jkt-canvas"></div>
      <div class="jkt-msg" id="jkt-msg"><div><i class="fa fa-spinner fa-pulse"></i>Строим карту сети…</div></div>
      <div class="jkt-legend">
        <span><i class="l"></i>в сети</span><span><i class="l off"></i>не в сети</span>
        <span><span class="jkt-dot blk"></span>заблокирован</span><span><span class="jkt-dot lim"></span>ограничен</span>
      </div>
      <div class="jkt-zoom">
        <button type="button" data-z="in" title="Приблизить"><i class="fa fa-plus"></i></button>
        <button type="button" data-z="out" title="Отдалить"><i class="fa fa-minus"></i></button>
        <button type="button" data-z="fit" title="Показать всю сеть"><i class="fa fa-arrows-alt"></i></button>
      </div>
    </div>
    <div class="jkt-tw" id="jkt-tablewrap" style="display:none"><table class="jkt-table">
      <thead><tr>
        <th data-sort="name">Устройство</th>
        <th data-sort="ip">IP-адрес</th>
        <th class="c-mac" data-sort="mac">MAC</th>
        <th class="c-oui" data-sort="vendor">Производитель</th>
        <th class="c-mtype" data-sort="mtype">Тип MAC</th>
        <th class="c-net" data-sort="net">Сеть</th>
        <th class="c-lease" data-sort="lease">Адрес</th>
        <th class="c-seen" data-sort="seen">Активность</th>
      </tr></thead>
      <tbody id="jkt-rows"></tbody>
    </table></div>
  </div>

  <div class="jkt-grid2">
    <div class="jkt-card">
      <div class="jkt-ch"><i class="fa fa-industry"></i>Производители устройств<span class="r" id="jkt-vend-n"></span></div>
      <div class="jkt-vend" id="jkt-vend"></div>
    </div>
    <div class="jkt-card">
      <div class="jkt-ch"><i class="fa fa-stethoscope"></i>Анализ сети<span class="r" id="jkt-iss-n"></span></div>
      <div class="jkt-issues" id="jkt-issues"></div>
    </div>
  </div>
</div>

<div class="jkt jkt-shade" id="jkt-shade"></div>
<aside class="jkt jkt-panel" id="jkt-panel" aria-hidden="true"></aside>
<div class="jkt jkt-toast" id="jkt-toast"></div>

<script>
'use strict';
$(function () {
    const ALIAS_MAC = 'jkufw_block_mac';         // shared with the Devices page
    const LIMIT_TAG = 'jk-ufw limit ';
    const LIST_EVERY = 30000;
    const RANDOM_LABEL = 'Случайный MAC';

    // layout, in canvas pixels
    const HOST_W = 236, HOST_H = 64, GAP_X = 14, GAP_Y = 12, BUS = 22, MAX_ROWS = 9, MAX_COLS = 4;
    const NET_W = 236, NET_H = 62, NET_GAP = 56, BIG_W = 250, BIG_H = 66, LVL = 46, PAD = 36;

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
    const fmtDate = (ms) => ms ? new Date(ms).toLocaleString('ru-RU', {day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'}) : '—';
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
    const plural = (n, one, few, many) => {
        const m10 = n % 10, m100 = n % 100;
        return n + ' ' + (m10 === 1 && m100 !== 11 ? one : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14) ? few : many));
    };

    // ---------- IPv4 helpers ----------
    const ip2n = (ip) => {
        const p = String(ip).split('.');
        if (p.length !== 4 || p.some((x) => !/^\d{1,3}$/.test(x) || Number(x) > 255)) {
            return null;
        }
        return ((Number(p[0]) << 24) >>> 0) + (Number(p[1]) << 16) + (Number(p[2]) << 8) + Number(p[3]);
    };
    const n2ip = (n) => [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].join('.');
    function parseCidr(cidr) {
        const m = String(cidr || '').match(/^(\d+\.\d+\.\d+\.\d+)\/(\d+)$/);
        if (!m) {
            return null;
        }
        const bits = Number(m[2]);
        const mask = bits === 0 ? 0 : (0xffffffff << (32 - bits)) >>> 0;
        const addr = ip2n(m[1]);
        if (addr === null) {
            return null;
        }
        const net = (addr & mask) >>> 0;
        return {addr: m[1], bits: bits, mask: mask, net: net, text: n2ip(net) + '/' + bits,
            size: bits >= 31 ? 0 : Math.pow(2, 32 - bits) - 2};
    }
    const inSubnet = (ip, c) => {
        const n = ip2n(ip);
        return c && n !== null && ((n & c.mask) >>> 0) === c.net;
    };

    // ---------- MAC analysis ----------
    function macInfo(mac) {
        const first = parseInt(mac.slice(0, 2), 16);
        const local = !!(first & 2);
        const multicast = !!(first & 1);
        return {
            oui: mac.slice(0, 8).toUpperCase(),
            local: local,
            multicast: multicast,
            // iOS, Android, Windows and others use a locally administered address per Wi-Fi network ("private address")
            label: multicast ? 'Групповой' : (local ? 'Локальный (случайный)' : 'Заводской (глобальный)')
        };
    }

    // Device type from vendor and name, same rules as the Devices page.
    const TYPES = [
        [/iphone|ipad|android|galaxy|pixel|redmi|poco|oneplus|realme|honor|nokia|motorola|oppo|vivo|xiaomi|huawei|samsung|zte|meizu|tecno|infinix/i, 'fa-mobile', 'Телефон или планшет'],
        [/apple|macbook|imac|mac-?mini/i, 'fa-apple', 'Устройство Apple'],
        [/printer|canon|epson|brother|kyocera|xerox|ricoh|lexmark|pantum/i, 'fa-print', 'Принтер'],
        [/tv|lg electronics|sony|philips|hisense|tcl|roku|chromecast|vizio|kivi|skyworth/i, 'fa-television', 'Телевизор или приставка'],
        [/playstation|xbox|nintendo|valve|steam/i, 'fa-gamepad', 'Игровая консоль'],
        [/amazon|echo|alexa|google|nest|sonos|yandex|station/i, 'fa-volume-up', 'Умная колонка'],
        [/ubiquiti|tp-?link|mikrotik|cisco|netgear|keenetic|zyxel|d-?link|tenda|mercusys|aruba|ruckus|routerboard|cudy|edimax/i, 'fa-wifi', 'Сетевое оборудование'],
        [/raspberry|orange ?pi|banana ?pi|hardkernel|odroid/i, 'fa-microchip', 'Одноплатный компьютер'],
        [/espressif|arduino|tuya|shelly|sonoff|aqara|lumi|ezviz|hikvision|dahua|reolink|wyze|ring/i, 'fa-microchip', 'Умный дом или камера'],
        [/vmware|virtualbox|pcs systemtechnik|oracle|parallels|qemu|xensource|proxmox|microsoft corp.*hyper|red hat/i, 'fa-cube', 'Виртуальная машина'],
        [/synology|qnap|western digital|seagate|buffalo|asustor|truenas/i, 'fa-hdd-o', 'Сетевое хранилище'],
        [/intel|realtek|dell|hewlett|hp inc|lenovo|acer|asustek|micro-star|msi|gigabyte|asrock|microsoft|azurewave|liteon|foxconn|qualcomm|broadcom|mediatek/i, 'fa-desktop', 'Компьютер']
    ];
    function typeOf(d) {
        const text = `${d.name} ${d.vendor}`;
        const hit = TYPES.find(([re]) => re.test(text));
        if (hit) {
            return {icon: hit[1], label: hit[2]};
        }
        return d.mi.local ? {icon: 'fa-mobile', label: 'Вероятно телефон или ноутбук (приватный адрес Wi-Fi)'}
            : {icon: 'fa-question-circle-o', label: 'Не определён'};
    }

    // ---------- state ----------
    let sys = {name: ''};
    let nets = [];            // local networks: {key, label, device, cidr, cidr6, vlan, up, mac, hosts:[]}
    let wans = [];            // {key, label, device, addr, gw: {name, address, status, delay, loss}}
    let hosts = [];
    let issues = [];          // network-wide findings
    let show = 'all';
    let mode = 'map';
    let query = '';
    let hl = '';              // highlight: online | random | noname | issues | vendor:<name>
    let selected = null;      // {kind, id}
    let view = {x: 0, y: 0, s: 1};
    let fitted = false;
    let layout = null;
    let tsort = {key: 'net', asc: true};
    let listTimer = null;

    async function load() {
        const [sysi, ifi, gws, ifl, arp, ndp, k4, k6, dm, hw, al, pp] = await Promise.all([
            api('/api/diagnostics/system/system_information').catch(() => null),
            api('/api/interfaces/overview/interfaces_info').catch(() => null),
            api('/api/routes/gateway/status').catch(() => null),
            api('/api/firewall/filter/get_interface_list').catch(() => null),
            api('/api/diagnostics/interface/get_arp'),
            api('/api/diagnostics/interface/get_ndp').catch(() => []),
            api('/api/kea/leases4/search', ALL).catch(() => null),
            api('/api/kea/leases6/search', ALL).catch(() => null),
            api('/api/dnsmasq/leases/search', ALL).catch(() => null),
            api('/api/hostdiscovery/service/search', ALL).catch(() => null),
            api('/api/firewall/alias/search_item', Object.assign({}, ALL, {searchPhrase: ALIAS_MAC})).catch(() => null),
            api('/api/trafficshaper/settings/search_pipes', Object.assign({}, ALL, {searchPhrase: LIMIT_TAG.trim()})).catch(() => null)
        ]);
        sys.name = (sysi && sysi.name) || 'jk-ufw';

        // interfaces: label -> key
        const labels = {};
        const byLabel = {};
        ((ifl && ifl.interfaces && ifl.interfaces.items) || []).forEach((i) => {
            labels[i.value] = i.label;
            byLabel[String(i.label).toLowerCase()] = i.value;
        });
        const keyOfLabel = (label) => byLabel[String(label || '').toLowerCase()] || '';

        // networks and WANs from the interface overview
        const gwItems = (gws && Array.isArray(gws.items)) ? gws.items : [];
        const netMap = new Map();
        wans = [];
        rows(ifi).forEach((r) => {
            if (!r.identifier || r.enabled === false) {
                return;
            }
            const key = r.identifier;
            if (/^(lo\d*|openvpn|wireguard|ipsec|enc\d*)$/.test(key) || /^(lo|enc|pflog|pfsync)\d*$/.test(r.device || '')) {
                return;
            }
            const base = {key: key, label: r.description || labels[key] || key.toUpperCase(), device: r.device || '',
                up: String(r.status || '').toLowerCase() === 'up', mac: normMac(r.macaddr), vlan: r.vlan_tag || '',
                media: r.media || '', type: r.link_type || '', addr4: r.addr4 || '', addr6: r.addr6 || ''};
            // WAN: the "wan" interface and any other one with a gateway (a second provider on optN)
            if (key === 'wan' || (key !== 'lan' && Array.isArray(r.gateways) && r.gateways.length)) {
                const gwAddrs = (r.gateways || []).map(String);
                const gw = gwItems.find((g) => gwAddrs.includes(String(g.address))) ||
                    gwItems.find((g) => String(g.name || '').toLowerCase().startsWith(key)) || null;
                wans.push(Object.assign(base, {gw: gw, gwAddr: gw ? gw.address : (gwAddrs[0] || '')}));
            } else {
                netMap.set(key, Object.assign(base, {cidr: parseCidr(r.addr4), hosts: []}));
            }
        });

        // hosts, same sources and merge rules as the Devices page
        const map = new Map();
        const own = new Set();
        const dev = (mac) => {
            mac = normMac(mac);
            if (!map.has(mac)) {
                map.set(mac, {mac: mac, ips: new Set(), names: [], vendor: '', ifkey: '', iflabel: '', online: false,
                    lease: null, first: null, last: null, src: new Set()});
            }
            return map.get(mac);
        };
        const setIf = (d, key, label) => {
            if (!d.ifkey && (key || label)) {
                d.ifkey = key || keyOfLabel(label);
                d.iflabel = label || labels[key] || key;
            }
        };
        const cleanName = (n) => {
            n = String(n || '').trim();
            return (n === '*' || n === '?') ? '' : n.replace(/\.$/, '');
        };
        const addName = (d, n, how, first) => {
            n = cleanName(n);
            if (n && !d.names.some((x) => x.n.toLowerCase() === n.toLowerCase())) {
                d.names[first ? 'unshift' : 'push']({n: n, how: how});
            }
        };

        (Array.isArray(arp) ? arp : []).forEach((e) => {
            if (!e.mac || e.mac === '(incomplete)') {
                return;
            }
            if (e.permanent) {
                own.add(normMac(e.mac));
                return;
            }
            const d = dev(e.mac);
            d.ips.add(e.ip);
            d.src.add('ARP');
            if (!e.expired) {
                d.online = true;
                d.last = Date.now();
            }
            addName(d, e.hostname, 'обратный DNS');
            d.vendor = d.vendor || e.manufacturer || '';
            setIf(d, keyOfLabel(e.intf_description), e.intf_description || e.intf);
        });
        (Array.isArray(ndp) ? ndp : []).forEach((e) => {
            const mac = normMac(e.mac);
            if (!mac || own.has(mac) || !/^[0-9a-f:]{17}$/.test(mac)) {
                return;
            }
            const d = dev(mac);
            d.src.add('NDP');
            if (isLinkLocal(e.ip)) {
                d.ll = String(e.ip).split('%')[0];
            } else {
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
            d.src.add('DHCP ' + source);
            if (r.address) {
                d.ips.add(r.address);
            }
            addName(d, r.hostname, 'запрос DHCP', true);   // the name the device asked DHCP for wins
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
            d.src.add('Host Discovery');
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

        const blocked = new Set(splitList((rows(al).find((a) => a.name === ALIAS_MAC) || {}).content).map(normMac));
        const limited = new Set(rows(pp).map((p) => String(p.description || ''))
            .filter((s) => s.startsWith(LIMIT_TAG)).map((s) => normMac(s.slice(LIMIT_TAG.length).split(' ')[0])));
        const wanKeys = new Set(wans.map((w) => w.key));

        hosts = [...map.values()].filter((d) => !wanKeys.has(d.ifkey) && d.ifkey !== 'wan').map((d) => {
            const ips = [...d.ips].filter(Boolean).sort((a, b) => ipKey(a).localeCompare(ipKey(b)));
            const h = Object.assign(d, {
                ips: ips,
                ip4s: ips.filter((ip) => !isV6(ip)),
                ip6s: ips.filter(isV6),
                name: d.names.length ? d.names[0].n : '',
                mi: macInfo(d.mac),
                blocked: blocked.has(d.mac),
                limited: limited.has(d.mac),
                src: [...d.src]
            });
            h.ip4 = h.ip4s[0] || '';
            h.type = typeOf(h);
            h.title = h.name || h.vendor || (h.mi.local ? RANDOM_LABEL : '') || h.ip4 || h.ips[0] || h.mac.toUpperCase();
            return h;
        });

        // put every host on its network; unknown interfaces get their own group
        hosts.forEach((h) => {
            let key = h.ifkey;
            if (!key || !netMap.has(key)) {
                // no interface from the tables: try the subnets
                const bySub = h.ip4 ? [...netMap.values()].find((n) => inSubnet(h.ip4, n.cidr)) : null;
                if (bySub) {
                    key = bySub.key;
                } else {
                    key = key || '_other';
                    if (!netMap.has(key)) {
                        netMap.set(key, {key: key, label: h.iflabel || 'Другие', device: '', up: true, mac: '', vlan: '', media: '',
                            type: '', addr4: '', addr6: '', cidr: null, hosts: [], synthetic: true});
                    }
                }
            }
            h.net = key;
            h.netLabel = netMap.get(key).label;
            netMap.get(key).hosts.push(h);
        });
        nets = [...netMap.values()].filter((n) => n.hosts.length || n.cidr || n.addr6)
            .sort((a, b) => (a.key === 'lan' ? -1 : b.key === 'lan' ? 1 : 0) || (a.synthetic ? 1 : 0) - (b.synthetic ? 1 : 0) ||
                String(a.label).localeCompare(String(b.label)));
        nets.forEach((n) => n.hosts.sort((a, b) => (b.online - a.online) || ipKey(a.ip4 || a.ips[0] || 'zz').localeCompare(ipKey(b.ip4 || b.ips[0] || 'zz')) ||
            a.mac.localeCompare(b.mac)));

        analyse();
        $('#jkt-updated').text('Обновлено ' + new Date().toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'}));
    }

    // ---------- analysis ----------
    function analyse() {
        const byIp = new Map();
        hosts.forEach((h) => {
            h.findings = [];
            h.ip4s.forEach((ip) => {
                if (!byIp.has(ip)) {
                    byIp.set(ip, []);
                }
                byIp.get(ip).push(h);
            });
        });
        issues = [];
        // the same IPv4 seen on several MACs
        byIp.forEach((list, ip) => {
            if (list.length > 1) {
                list.forEach((h) => h.findings.push({lvl: 'bad', icon: 'fa-times-circle', t: 'Конфликт адресов',
                    d: `IP ${ip} также у ${list.filter((x) => x !== h).map((x) => x.title + ' (' + x.mac.toUpperCase() + ')').join(', ')}. ` +
                       'Одно из устройств настроено вручную на занятый адрес или это повторитель Wi-Fi, который подменяет MAC.'}));
                issues.push({lvl: 'bad', icon: 'fa-times-circle', mac: list[0].mac, t: `Конфликт IP ${ip}`,
                    d: `${plural(list.length, 'устройство', 'устройства', 'устройств')} с одним адресом: ${list.map((x) => x.title).join(', ')}`});
            }
        });
        hosts.forEach((h) => {
            const n = nets.find((x) => x.key === h.net);
            const outside = n && n.cidr ? h.ip4s.filter((ip) => !inSubnet(ip, n.cidr)) : [];
            if (outside.length) {
                h.findings.push({lvl: 'warn', icon: 'fa-exclamation-triangle', t: 'Адрес вне подсети',
                    d: `${outside.join(', ')} не входит в ${n.cidr.text} сети ${n.label}. Устройство настроено вручную или подключено не в ту сеть.`});
                issues.push({lvl: 'warn', icon: 'fa-exclamation-triangle', mac: h.mac, t: `${h.title}: адрес вне подсети`,
                    d: `${outside.join(', ')} в сети ${n.label} (${n.cidr.text})`});
            }
            if (h.ip4s.length > 1) {
                h.findings.push({lvl: 'info', icon: 'fa-info-circle', t: 'Несколько IPv4-адресов',
                    d: `${h.ip4s.join(', ')}. Обычно это смена аренды DHCP или виртуальные машины за одним сетевым мостом.`});
            }
            if (h.mi.local) {
                h.findings.push({lvl: 'info', icon: 'fa-random', t: 'Случайный (приватный) MAC',
                    d: 'Адрес задан самим устройством, а не производителем: так делают iOS, Android и Windows для приватности в Wi-Fi. ' +
                       'Производителя по такому адресу не определить, и он может меняться, поэтому блокировка по MAC ненадёжна.'});
            } else if (!h.vendor) {
                h.findings.push({lvl: 'info', icon: 'fa-question-circle', t: 'Производитель не найден',
                    d: `Префикс ${h.mi.oui} нет в базе производителей. Это может быть редкое или очень новое устройство.`});
            }
            if (!h.name) {
                h.findings.push({lvl: 'info', icon: 'fa-tag', t: 'Нет имени',
                    d: 'Устройство не сообщило имя ни через DHCP, ни через DNS. Задайте его в постоянной аренде DHCP, чтобы узнавать в списках.'});
            }
            if (h.blocked) {
                h.findings.push({lvl: 'bad', icon: 'fa-ban', t: 'Заблокировано', d: 'Доступ в интернет и другие сети закрыт на странице «Устройства».'});
            }
            if (h.limited) {
                h.findings.push({lvl: 'warn', icon: 'fa-tachometer', t: 'Скорость ограничена', d: 'Действует ограничение шейпера со страницы «Устройства».'});
            }
            if (h.lease && h.lease.type === 'static') {
                h.findings.push({lvl: 'ok', icon: 'fa-thumb-tack', t: 'Постоянный адрес', d: `Адрес закреплён в DHCP (${h.lease.source}).`});
            }
            h.issue = h.findings.some((f) => (f.lvl === 'bad' && f.t !== 'Заблокировано') || f.t === 'Адрес вне подсети');
        });
        // network-level
        nets.forEach((n) => {
            if (n.cidr && n.cidr.size) {
                const used = n.hosts.filter((h) => h.ip4s.some((ip) => inSubnet(ip, n.cidr))).length + 1;
                const pct = Math.round(used * 100 / n.cidr.size);
                n.fill = {used: used, size: n.cidr.size, pct: pct};
                if (pct >= 80) {
                    issues.push({lvl: 'warn', icon: 'fa-exclamation-triangle', net: n.key, t: `Сеть ${n.label} почти заполнена`,
                        d: `Занято ${used} из ${n.cidr.size} адресов (${pct}%). Увеличьте подсеть или пул DHCP.`});
                }
            }
            if (!n.up && !n.synthetic) {
                issues.push({lvl: 'warn', icon: 'fa-exclamation-triangle', net: n.key, t: `Интерфейс ${n.label} не подключён`,
                    d: `${n.device || n.key}: нет линка. Проверьте кабель или виртуальный адаптер.`});
            }
        });
        wans.forEach((w) => {
            const st = String((w.gw && w.gw.status) || '').toLowerCase();
            if (w.gw && st && st !== 'none' && st !== 'online') {
                issues.push({lvl: 'bad', icon: 'fa-times-circle', net: 'wan:' + w.key, t: `Шлюз ${w.gw.name} недоступен или с потерями`,
                    d: `${w.gw.status_translated || w.gw.status}. Задержка ${w.gw.delay || '—'}, потери ${w.gw.loss || '—'}.`});
            }
        });
        const rnd = hosts.filter((h) => h.mi.local).length;
        if (rnd) {
            issues.push({lvl: 'info', icon: 'fa-random', hl: 'random', t: `${plural(rnd, 'устройство', 'устройства', 'устройств')} со случайным MAC`,
                d: 'Это телефоны и ноутбуки с приватным адресом Wi-Fi. Производитель у них неизвестен, а MAC может меняться.'});
        }
        const noname = hosts.filter((h) => !h.name).length;
        if (noname) {
            issues.push({lvl: 'info', icon: 'fa-tag', hl: 'noname', t: `${plural(noname, 'устройство', 'устройства', 'устройств')} без имени`,
                d: 'Задайте имена в постоянных арендах DHCP, чтобы узнавать устройства на карте.'});
        }
        if (!issues.some((i) => i.lvl === 'bad' || i.lvl === 'warn')) {
            issues.unshift({lvl: 'ok', icon: 'fa-check-circle', t: 'Проблем не найдено', d: 'Нет конфликтов адресов, адресов вне подсетей и недоступных шлюзов.'});
        }
        const order = {bad: 0, warn: 1, info: 2, ok: 3};
        issues.sort((a, b) => order[a.lvl] - order[b.lvl]);
    }

    // ---------- filters ----------
    function matches(h) {
        if (!query) {
            return true;
        }
        const q = query.toLowerCase();
        const hay = [h.title, h.vendor, h.mac, h.mac.replace(/:/g, '-'), h.mi.oui, ...h.ips, ...h.names.map((x) => x.n), h.netLabel]
            .join(' ').toLowerCase();
        return hay.includes(q);
    }
    function lit(h) {
        if (!hl) {
            return true;
        }
        if (hl === 'online') {
            return h.online;
        }
        if (hl === 'random') {
            return h.mi.local;
        }
        if (hl === 'noname') {
            return !h.name;
        }
        if (hl === 'issues') {
            return h.issue;
        }
        if (hl.startsWith('vendor:')) {
            return vendorKey(h) === hl.slice(7);
        }
        return true;
    }
    const shown = (h) => show === 'all' || h.online;
    const vendorKey = (h) => h.vendor || (h.mi.local ? RANDOM_LABEL : 'Неизвестен');

    // ---------- layout ----------
    function computeLayout() {
        const L = {nodes: [], lines: [], labels: [], w: 0, h: 0};
        const groups = nets.map((n) => {
            const list = n.hosts.filter(shown);
            const cols = Math.max(1, Math.min(MAX_COLS, Math.ceil(list.length / MAX_ROWS)));
            const rowsN = Math.ceil(list.length / cols);
            const hostsW = cols * (HOST_W + BUS) + (cols - 1) * GAP_X;
            return {n: n, list: list, cols: cols, rows: rowsN, w: Math.max(NET_W, hostsW)};
        });
        const totalW = groups.reduce((s, g) => s + g.w, 0) + Math.max(0, groups.length - 1) * NET_GAP;
        const width = Math.max(totalW, BIG_W * Math.max(1, wans.length) + 40 * Math.max(0, wans.length - 1));
        const cx = PAD + width / 2;
        const yInet = PAD, yGw = yInet + BIG_H + LVL, yFw = (wans.length ? yGw + BIG_H + LVL : yInet + BIG_H + LVL);
        const yNet = yFw + BIG_H + LVL + 14, yHost = yNet + NET_H + 40;

        // internet + gateways
        const inetUp = !wans.length || wans.some((w) => !w.gw || ['online', 'none', ''].includes(String(w.gw.status || '').toLowerCase()));
        L.nodes.push({kind: 'inet', id: 'inet', x: cx - BIG_W / 2, y: yInet, w: BIG_W, h: BIG_H, up: inetUp});
        const gwSpan = wans.length * BIG_W + (wans.length - 1) * 40;
        wans.forEach((w, i) => {
            const x = cx - gwSpan / 2 + i * (BIG_W + 40);
            const st = String((w.gw && w.gw.status) || '').toLowerCase();
            const up = w.up && (!w.gw || ['online', 'none', ''].includes(st));
            L.nodes.push({kind: 'gw', id: 'wan:' + w.key, x: x, y: yGw, w: BIG_W, h: BIG_H, wan: w, up: up});
            L.lines.push({d: vpath(cx, yInet + BIG_H, x + BIG_W / 2, yGw), cls: up ? 'wan' : 'down'});
            L.lines.push({d: vpath(x + BIG_W / 2, yGw + BIG_H, cx, yFw), cls: up ? 'wan' : 'down'});
            if (w.addr4) {
                L.labels.push({x: (x + BIG_W / 2 + cx) / 2, y: (yGw + BIG_H + yFw) / 2, text: `${w.label} · ${w.addr4.split('/')[0]}`});
            }
        });
        if (!wans.length) {
            L.lines.push({d: vpath(cx, yInet + BIG_H, cx, yFw), cls: 'wan'});
        }
        L.nodes.push({kind: 'fw', id: 'fw', x: cx - BIG_W / 2, y: yFw, w: BIG_W, h: BIG_H});

        // networks and hosts
        let x = PAD + (width - totalW) / 2;
        let maxY = yNet + NET_H;
        groups.forEach((g) => {
            const nx = x + (g.w - NET_W) / 2;
            const ncx = nx + NET_W / 2;
            L.nodes.push({kind: 'net', id: 'net:' + g.n.key, x: nx, y: yNet, w: NET_W, h: NET_H, net: g.n});
            L.lines.push({d: vpath(cx, yFw + BIG_H, ncx, yNet), cls: g.n.up ? 'on' : 'down'});
            if (g.n.vlan) {
                L.labels.push({x: ncx, y: yNet - 18, text: 'VLAN ' + g.n.vlan});
            }
            const left = x + (g.w - (g.cols * (HOST_W + BUS) + (g.cols - 1) * GAP_X)) / 2;
            for (let c = 0; c < g.cols; c++) {
                const colHosts = g.list.slice(c * g.rows, (c + 1) * g.rows);
                if (!colHosts.length) {
                    continue;
                }
                const bx = left + c * (HOST_W + BUS + GAP_X) + 6;
                const hx = bx + BUS - 6;
                const lastY = yHost + (colHosts.length - 1) * (HOST_H + GAP_Y) + HOST_H / 2;
                const colOn = colHosts.some((h) => h.online);
                // trunk from the network down to this column's bus
                const midY = yNet + NET_H + 22;
                L.lines.push({d: `M${ncx},${yNet + NET_H} V${midY} H${bx} V${lastY}`, cls: colOn ? 'on' : 'off', bus: true});
                colHosts.forEach((h, r) => {
                    const hy = yHost + r * (HOST_H + GAP_Y);
                    const dim = !matches(h) || !lit(h);
                    L.nodes.push({kind: 'host', id: h.mac, x: hx, y: hy, w: HOST_W, h: HOST_H, host: h, dim: dim});
                    L.lines.push({d: `M${bx},${hy + HOST_H / 2} H${hx}`, cls: h.online ? (h.blocked ? 'on' : 'flow') : 'off', dim: dim});
                    maxY = Math.max(maxY, hy + HOST_H);
                });
            }
            if (!g.list.length) {
                L.labels.push({x: ncx, y: yHost + 10, text: g.n.hosts.length ? 'все устройства не в сети' : 'нет устройств'});
            }
            x += g.w + NET_GAP;
        });
        L.w = width + PAD * 2;
        L.h = maxY + PAD + 30;
        return L;
    }
    function vpath(x1, y1, x2, y2) {
        if (Math.abs(x1 - x2) < 1) {
            return `M${x1},${y1} V${y2}`;
        }
        const my = (y1 + y2) / 2;
        const r = Math.min(14, Math.abs(x2 - x1) / 2, Math.abs(y2 - y1) / 2);
        const dir = x2 > x1 ? 1 : -1;
        return `M${x1},${y1} V${my - r} Q${x1},${my} ${x1 + dir * r},${my} H${x2 - dir * r} Q${x2},${my} ${x2},${my + r} V${y2}`;
    }

    // ---------- rendering ----------
    // second line: address, third: vendor (or the MAC when the vendor is the title already or unknown)
    function hostSub(h) {
        const ip = h.ip4 || h.ips[0] || '';
        const extra = h.ips.length > 1 ? ' +' + (h.ips.length - 1) : '';
        return ip ? ip + extra : h.mac.toUpperCase();
    }
    function hostVendor(h) {
        if (h.vendor && h.title !== h.vendor) {
            return h.vendor;
        }
        return h.ip4 || h.ips[0] ? h.mac.toUpperCase() : (h.mi.local ? RANDOM_LABEL : '');
    }
    function nodeHtml(n) {
        const style = `left:${n.x}px;top:${n.y}px;width:${n.w}px;height:${n.h}px`;
        const sel = selected && selected.id === n.id ? ' sel' : '';
        if (n.kind === 'host') {
            const h = n.host;
            const hit = query && matches(h) ? ' hit' : '';
            const badge = h.blocked ? '<span class="badge">блок</span>' : (h.limited ? '<span class="badge lim">лимит</span>' : '');
            return `<div class="jkt-node host${h.online ? '' : ' off'}${h.blocked ? ' blk' : ''}${n.dim ? ' dim' : ''}${hit}${sel}" data-id="${esc(n.id)}" style="${style}"
                title="${esc(h.title)}&#10;${esc(h.ips.join(', '))}&#10;${esc(h.mac.toUpperCase())}${h.vendor ? '&#10;' + esc(h.vendor) : ''}">${badge}
                <div class="ic"><i class="fa ${h.blocked ? 'fa-ban' : h.type.icon}"></i><span class="jkt-dot ${h.blocked ? 'blk' : (h.limited ? 'lim' : (h.online ? 'on' : ''))}"></span></div>
                <div class="tx"><div class="n">${esc(h.title)}</div><div class="s jkt-mono">${esc(hostSub(h))}</div>
                <div class="s v">${esc(hostVendor(h))}</div></div></div>`;
        }
        if (n.kind === 'net') {
            const net = n.net;
            const on = net.hosts.filter((h) => h.online).length;
            return `<div class="jkt-node net${sel}" data-id="${esc(n.id)}" style="${style}">
                <div class="ic"><i class="fa ${net.synthetic ? 'fa-question' : 'fa-sitemap'}"></i>${net.synthetic ? '' : `<span class="jkt-dot ${net.up ? 'on' : ''}"></span>`}</div>
                <div class="tx"><div class="n">${esc(net.label)}</div><div class="s jkt-mono">${esc(net.cidr ? net.cidr.text : (net.device || '—'))}</div></div>
                <div class="cnt"><b>${on}</b>из ${net.hosts.length}</div></div>`;
        }
        if (n.kind === 'fw') {
            const on = hosts.filter((h) => h.online).length;
            return `<div class="jkt-node big fw${sel}" data-id="fw" style="${style}">
                <div class="ic"><i class="fa fa-shield"></i></div>
                <div class="tx"><div class="n">${esc(sys.name)}</div><div class="s">${plural(nets.filter((x) => !x.synthetic).length, 'сеть', 'сети', 'сетей')} · ${on} в сети</div></div></div>`;
        }
        if (n.kind === 'gw') {
            const w = n.wan;
            const delay = w.gw && w.gw.delay && w.gw.delay !== '~' ? ' · ' + w.gw.delay : '';
            return `<div class="jkt-node big gw${sel}" data-id="${esc(n.id)}" style="${style}">
                <div class="ic"><i class="fa fa-server"></i><span class="jkt-dot ${n.up ? 'on' : 'blk'}"></span></div>
                <div class="tx"><div class="n">${esc(w.gw ? (w.gw.name || 'Провайдер') : 'Провайдер')}</div>
                <div class="s jkt-mono">${esc(w.gwAddr || w.addr4 || w.device || w.label)}${esc(delay)}</div></div></div>`;
        }
        return `<div class="jkt-node big inet${sel}" data-id="inet" style="${style}">
            <div class="ic"><i class="fa fa-globe"></i><span class="jkt-dot ${n.up ? 'on' : 'blk'}"></span></div>
            <div class="tx"><div class="n">Интернет</div><div class="s">${n.up ? 'доступен' : 'нет связи'}</div></div></div>`;
    }

    function renderMap() {
        layout = computeLayout();
        const svg = `<svg width="${layout.w}" height="${layout.h}" viewBox="0 0 ${layout.w} ${layout.h}">` +
            layout.lines.map((l) => `<path class="jkt-ln ${l.cls}${l.dim ? ' dim' : ''}" d="${l.d}"/>`).join('') + '</svg>';
        $('#jkt-canvas').css({width: layout.w, height: layout.h})
            .html(svg + layout.labels.map((l) => `<div class="jkt-lbl" style="left:${l.x}px;top:${l.y}px">${esc(l.text)}</div>`).join('') +
                layout.nodes.map(nodeHtml).join(''));
        $('#jkt-msg').toggle(false);
        if (!fitted) {
            fit(true);
            fitted = true;
        } else {
            applyView();
        }
    }

    function renderTable() {
        const val = (h, k) => ({
            name: h.title.toLowerCase(), ip: ipKey(h.ip4 || h.ips[0] || 'zzz'), mac: h.mac, vendor: vendorKey(h).toLowerCase(),
            mtype: h.mi.label, net: h.netLabel + ipKey(h.ip4 || h.ips[0] || 'zzz'), lease: h.lease ? h.lease.type : 'zz',
            seen: h.online ? -Date.now() * 2 : -(h.last || 0)
        })[k];
        const list = hosts.filter((h) => shown(h) && matches(h) && lit(h)).sort((a, b) => {
            const x = val(a, tsort.key), y = val(b, tsort.key);
            return (x < y ? -1 : x > y ? 1 : 0) * (tsort.asc ? 1 : -1);
        });
        $('.jkt-table th[data-sort]').each(function () {
            const k = $(this).data('sort');
            $(this).toggleClass('sorted', k === tsort.key).toggleClass('asc', k === tsort.key && tsort.asc);
        });
        if (!list.length) {
            $('#jkt-rows').html('<tr><td colspan="8"><div class="jkt-msg" style="position:static;padding:40px"><div><i class="fa fa-search"></i>Ничего не найдено</div></div></td></tr>');
            return;
        }
        $('#jkt-rows').html(list.map((h) => `<tr class="${h.online ? '' : 'off'}${selected && selected.id === h.mac ? ' sel' : ''}" data-id="${esc(h.mac)}">
            <td><div class="jkt-cell"><div class="ic"><i class="fa ${h.blocked ? 'fa-ban' : h.type.icon}"></i><span class="jkt-dot ${h.blocked ? 'blk' : (h.limited ? 'lim' : (h.online ? 'on' : ''))}"></span></div>
                <div style="min-width:0"><div class="n">${esc(h.title)}</div><div class="s">${esc(h.type.label)}</div></div></div></td>
            <td class="jkt-mono">${esc(h.ip4 || h.ips[0] || '—')}${h.ips.length > 1 ? ` <span class="muted">+${h.ips.length - 1}</span>` : ''}</td>
            <td class="c-mac jkt-mono">${esc(h.mac.toUpperCase())}</td>
            <td class="c-oui">${h.vendor ? esc(h.vendor) : `<span class="muted">${h.mi.local ? 'не определить' : 'нет в базе'}</span>`}<div class="muted jkt-mono" style="font-size:11px">${esc(h.mi.oui)}</div></td>
            <td class="c-mtype">${h.mi.local ? '<span class="jkt-tag info"><i class="fa fa-random"></i>случайный</span>' : '<span class="jkt-tag">заводской</span>'}</td>
            <td class="c-net">${esc(h.netLabel)}</td>
            <td class="c-lease">${h.lease ? (h.lease.type === 'static' ? '<span class="jkt-tag on"><i class="fa fa-thumb-tack"></i>постоянный</span>' : 'DHCP') : '<span class="muted" title="Нет аренды в DHCP этого экрана">—</span>'}</td>
            <td class="c-seen">${h.online ? '<span class="jkt-tag on"><span class="jkt-dot on"></span>в сети</span>' : esc(ago(h.last))}</td>
        </tr>`).join(''));
    }

    function renderKpis() {
        const on = hosts.filter((h) => h.online).length;
        $('#jkt-k-online').html(`${on}<small>из ${hosts.length}</small>`);
        $('#jkt-k-nets').text(nets.filter((n) => !n.synthetic).length);
        $('#jkt-k-vendors').text(new Set(hosts.filter((h) => h.vendor).map((h) => h.vendor)).size);
        $('#jkt-k-random').text(hosts.filter((h) => h.mi.local).length);
        $('#jkt-k-noname').text(hosts.filter((h) => !h.name).length);
        const nIss = issues.filter((i) => i.lvl === 'bad' || i.lvl === 'warn').length;
        $('#jkt-k-issues').text(nIss).toggleClass('warn', nIss > 0);
        $('.jkt-kpi[data-hl]').each(function () {
            $(this).toggleClass('sel', $(this).data('hl') === hl);
        });
    }

    function renderSide() {
        const counts = new Map();
        hosts.forEach((h) => counts.set(vendorKey(h), (counts.get(vendorKey(h)) || 0) + 1));
        const top = [...counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
        const max = top.length ? top[0][1] : 1;
        $('#jkt-vend-n').text(top.length ? plural(counts.size, 'группа', 'группы', 'групп') : '');
        $('#jkt-vend').html(top.length ? top.slice(0, 10).map(([v, c]) => {
            const sample = hosts.find((h) => vendorKey(h) === v);
            const icon = v === RANDOM_LABEL ? 'fa-random' : (v === 'Неизвестен' ? 'fa-question' : sample.type.icon);
            return `<div class="jkt-vrow${hl === 'vendor:' + v ? ' sel' : ''}" data-vendor="${esc(v)}" title="Подсветить на карте">
                <div class="nm"><i class="fa ${icon}"></i><span>${esc(v)}</span></div>
                <div class="bar"><i style="width:${Math.max(4, Math.round(c * 100 / max))}%"></i></div><div class="c">${c}</div></div>`;
        }).join('') + (top.length > 10 ? `<div class="muted" style="padding:6px 6px 0;font-size:12px">и ещё ${top.length - 10}…</div>` : '')
            : '<div class="muted" style="padding:16px 6px">Устройств пока нет</div>');
        const nIss = issues.filter((i) => i.lvl !== 'ok').length;
        $('#jkt-iss-n').text(nIss ? plural(nIss, 'пункт', 'пункта', 'пунктов') : '');
        $('#jkt-issues').html(issues.map((i, k) => `<div class="jkt-issue" data-issue="${k}"><i class="fa ${i.icon}"></i>
            <div><div class="t">${esc(i.t)}</div><div class="d">${esc(i.d)}</div></div></div>`).join(''));
    }

    function render() {
        renderKpis();
        renderSide();
        if (mode === 'map') {
            renderMap();
        } else {
            renderTable();
        }
        if (selected) {
            renderPanel();
        }
    }

    // ---------- pan and zoom ----------
    function applyView() {
        $('#jkt-canvas').css('transform', `translate(${view.x}px,${view.y}px) scale(${view.s})`);
    }
    // readable: on first show do not shrink below 0.8 just to fit a tall network, it can be dragged instead
    function fit(readable) {
        if (!layout) {
            return;
        }
        const $v = $('#jkt-view');
        const vw = $v.width(), vh = $v.height();
        let s = Math.max(0.25, Math.min(1.1, vw / layout.w, vh / layout.h));
        if (readable) {
            s = Math.max(s, Math.min(0.8, vw / layout.w), 0.6);
        }
        // when it does not fit, keep the firewall in the middle and let the rest be dragged into view
        const fw = layout.nodes.find((n) => n.kind === 'fw');
        const x = layout.w * s <= vw || !fw ? (vw - layout.w * s) / 2 : vw / 2 - (fw.x + fw.w / 2) * s;
        view = {s: s, x: x, y: Math.max(0, (vh - layout.h * s) / 2)};
        applyView();
    }
    function zoomAt(f, px, py) {
        const s = Math.max(0.2, Math.min(2.5, view.s * f));
        view.x = px - (px - view.x) * (s / view.s);
        view.y = py - (py - view.y) * (s / view.s);
        view.s = s;
        applyView();
    }
    function centerOn(id) {
        const n = layout && layout.nodes.find((x) => x.id === id);
        if (!n) {
            return;
        }
        const $v = $('#jkt-view');
        view.s = Math.max(view.s, 0.85);
        view.x = $v.width() / 2 - (n.x + n.w / 2) * view.s;
        view.y = $v.height() / 2 - (n.y + n.h / 2) * view.s;
        $('#jkt-canvas').css('transition', 'transform .3s ease');
        applyView();
        setTimeout(() => $('#jkt-canvas').css('transition', ''), 320);
    }
    (function () {
        const el = document.getElementById('jkt-view');
        let drag = null;
        el.addEventListener('wheel', (e) => {
            e.preventDefault();
            const r = el.getBoundingClientRect();
            zoomAt(e.deltaY < 0 ? 1.12 : 1 / 1.12, e.clientX - r.left, e.clientY - r.top);
        }, {passive: false});
        el.addEventListener('pointerdown', (e) => {
            if ($(e.target).closest('.jkt-zoom').length || e.button !== 0) {
                return;
            }
            drag = {x: e.clientX, y: e.clientY, vx: view.x, vy: view.y, moved: false, id: e.pointerId};
        });
        el.addEventListener('pointermove', (e) => {
            if (!drag || e.pointerId !== drag.id) {
                return;
            }
            const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
            if (!drag.moved && Math.abs(dx) + Math.abs(dy) > 4) {
                drag.moved = true;
                el.setPointerCapture(e.pointerId);
                el.classList.add('drag');
            }
            if (drag.moved) {
                view.x = drag.vx + dx;
                view.y = drag.vy + dy;
                applyView();
            }
        });
        const end = (e) => {
            if (!drag) {
                return;
            }
            const moved = drag.moved;
            drag = null;
            el.classList.remove('drag');
            if (!moved) {
                const node = $(document.elementFromPoint(e.clientX, e.clientY)).closest('.jkt-node');
                if (node.length) {
                    openPanel(String(node.data('id')));
                }
            }
        };
        el.addEventListener('pointerup', end);
        el.addEventListener('pointercancel', () => {
            drag = null;
            el.classList.remove('drag');
        });
    })();

    // ---------- side panel ----------
    const kvHtml = (list) => '<div class="jkt-kv">' + list.filter(Boolean).map(([k, v, mono]) =>
        `<div class="k">${k}</div><div class="v${mono ? ' jkt-mono' : ''}">${v}</div>`).join('') + '</div>';
    const cp = (v) => `<span class="jkt-cp" data-copy="${esc(v)}" title="Скопировать">${esc(v)}</span>`;

    function panelHost(h) {
        const n = nets.find((x) => x.key === h.net) || {};
        const names = h.names.length ? h.names.map((x) => `${esc(x.n)} <span class="muted">· ${esc(x.how)}</span>`).join('<br>') : '<span class="muted">не сообщило</span>';
        const v4 = h.ip4s.length ? h.ip4s.map((ip) => cp(ip) + (n.cidr ? (inSubnet(ip, n.cidr) ? '' : ' <span class="jkt-tag warn">вне подсети</span>') : '')).join('<br>') : '—';
        const lease = h.lease ? `${h.lease.type === 'static' ? 'Постоянный' : 'Динамический'} (DHCP ${esc(h.lease.source)})` +
            (h.lease.expire ? `<span class="hint">аренда до ${esc(fmtDate(h.lease.expire))}</span>` : '') : 'Задан вручную или выдан не этим экраном';
        const status = h.blocked ? '<span class="jkt-tag blk"><i class="fa fa-ban"></i>заблокировано</span>'
            : (h.online ? '<span class="jkt-tag on"><span class="jkt-dot on"></span>в сети</span>' : `не в сети · ${esc(ago(h.last))}`);
        const finds = h.findings.length ? h.findings.map((f) => `<div class="jkt-find ${f.lvl}"><i class="fa ${f.icon}"></i>
            <div><div class="t">${esc(f.t)}</div><div class="d">${esc(f.d)}</div></div></div>`).join('') : '';
        return {
            icon: `<div class="ic${h.blocked ? ' blk' : ''}"><i class="fa ${h.blocked ? 'fa-ban' : h.type.icon}"></i><span class="jkt-dot ${h.online ? 'on' : ''}"></span></div>`,
            title: h.title,
            sub: [h.vendor || (h.mi.local ? RANDOM_LABEL : ''), h.ip4].filter(Boolean).join(' · ') || h.mac.toUpperCase(),
            body: `
                <div class="jkt-sec"><i class="fa fa-id-card-o"></i> Устройство</div>
                ${kvHtml([
                    ['Состояние', status],
                    ['Имя', names],
                    ['Тип', esc(h.type.label)],
                    ['Производитель', h.vendor ? esc(h.vendor) : `<span class="muted">${h.mi.local ? 'не определить: случайный MAC' : 'нет в базе'}</span>`]
                ])}
                <div class="jkt-sec"><i class="fa fa-barcode"></i> MAC-адрес</div>
                ${kvHtml([
                    ['MAC', cp(h.mac.toUpperCase()), true],
                    ['Префикс (OUI)', esc(h.mi.oui), true],
                    ['Тип адреса', esc(h.mi.label) + (h.mi.local ? '<span class="hint">задан устройством, может меняться</span>' : '<span class="hint">выдан производителем, постоянный</span>')]
                ])}
                <div class="jkt-sec"><i class="fa fa-map-marker"></i> Адресация</div>
                ${kvHtml([
                    ['IPv4', v4, true],
                    ['IPv6', h.ip6s.length ? h.ip6s.map(cp).join('<br>') : '—', true],
                    h.ll ? ['IPv6 link-local', esc(h.ll), true] : null,
                    ['Сеть', esc(h.netLabel) + (n.cidr ? ` <span class="muted jkt-mono">${esc(n.cidr.text)}</span>` : '') + (n.vlan ? ` · VLAN ${esc(n.vlan)}` : '')],
                    ['Шлюз', n.cidr ? `<span class="jkt-mono">${esc(n.cidr.addr)}</span> <span class="muted">(${esc(sys.name)})</span>` : '—'],
                    ['Адрес выдан', lease]
                ])}
                <div class="jkt-sec"><i class="fa fa-clock-o"></i> История</div>
                ${kvHtml([
                    ['Впервые замечен', esc(fmtDate(h.first))],
                    ['Последняя активность', h.online ? 'сейчас' : esc(fmtDate(h.last))],
                    ['Источники', esc(h.src.join(', ') || '—')]
                ])}
                ${finds ? `<div class="jkt-sec"><i class="fa fa-stethoscope"></i> Анализ</div>${finds}` : ''}
                <div class="jkt-links">
                    <a class="jkt-btn sm" href="/ui/jkufw/devices#${esc(h.mac)}"><i class="fa fa-sliders"></i> Блокировка и скорость</a>
                    <a class="jkt-btn ghost sm" href="/ui/kea/dhcp/v4"><i class="fa fa-thumb-tack"></i> Закрепить IP</a>
                    <a class="jkt-btn ghost sm" href="/ui/diagnostics/interface/arp"><i class="fa fa-table"></i> ARP</a>
                </div>`
        };
    }

    function panelNet(n) {
        const on = n.hosts.filter((h) => h.online).length;
        const vendors = new Set(n.hosts.map(vendorKey)).size;
        return {
            icon: `<div class="ic net"><i class="fa fa-sitemap"></i><span class="jkt-dot ${n.up ? 'on' : ''}"></span></div>`,
            title: n.label,
            sub: [n.cidr ? n.cidr.text : '', n.device].filter(Boolean).join(' · '),
            body: `
                <div class="jkt-sec"><i class="fa fa-sitemap"></i> Сеть</div>
                ${kvHtml([
                    ['Интерфейс', esc(n.device || '—') + (n.synthetic ? ' <span class="muted">(не найден в настройках)</span>' : ''), true],
                    ['Состояние', n.synthetic ? '—' : (n.up ? '<span class="jkt-tag on"><span class="jkt-dot on"></span>подключён</span>' : '<span class="jkt-tag warn">нет линка</span>')],
                    ['Подсеть IPv4', n.cidr ? esc(n.cidr.text) : '—', true],
                    ['Адрес экрана', n.cidr ? cp(n.cidr.addr) : '—', true],
                    ['IPv6', n.addr6 ? esc(n.addr6) : '—', true],
                    ['VLAN', n.vlan ? esc(n.vlan) : 'нет'],
                    ['MAC интерфейса', n.mac ? esc(n.mac.toUpperCase()) : '—', true],
                    n.media ? ['Скорость линка', esc(n.media)] : null
                ])}
                <div class="jkt-sec"><i class="fa fa-pie-chart"></i> Устройства</div>
                ${kvHtml([
                    ['В сети', `${on} из ${n.hosts.length}`],
                    ['Производителей', String(vendors)],
                    ['Случайные MAC', String(n.hosts.filter((h) => h.mi.local).length)],
                    ['Постоянные адреса', String(n.hosts.filter((h) => h.lease && h.lease.type === 'static').length)],
                    n.fill ? ['Заполнение подсети', `${n.fill.used} из ${n.fill.size} (${n.fill.pct}%)`] : null
                ])}
                <div class="jkt-links">
                    <a class="jkt-btn ghost sm" href="/ui/interfaces/overview"><i class="fa fa-plug"></i> Интерфейсы</a>
                    <a class="jkt-btn ghost sm" href="/ui/kea/dhcp/leases4"><i class="fa fa-list"></i> Аренды DHCP</a>
                </div>`
        };
    }

    function panelWan(w) {
        const g = w.gw || {};
        return {
            icon: `<div class="ic"><i class="fa fa-server"></i></div>`,
            title: g.name || 'Провайдер',
            sub: [w.label, w.device].filter(Boolean).join(' · '),
            body: `
                <div class="jkt-sec"><i class="fa fa-globe"></i> Подключение к интернету</div>
                ${kvHtml([
                    ['Интерфейс', `${esc(w.label)} <span class="muted jkt-mono">${esc(w.device)}</span>`],
                    ['Линк', w.up ? '<span class="jkt-tag on"><span class="jkt-dot on"></span>есть</span>' : '<span class="jkt-tag blk">нет</span>'],
                    ['Тип', esc(String(w.type || '—').toUpperCase())],
                    ['Адрес WAN', w.addr4 ? cp(w.addr4) : '—', true],
                    ['IPv6', w.addr6 ? esc(w.addr6) : '—', true],
                    ['MAC', w.mac ? esc(w.mac.toUpperCase()) : '—', true],
                    ['Шлюз провайдера', w.gwAddr ? cp(w.gwAddr) : '—', true],
                    ['Состояние шлюза', esc(g.status_translated || g.status || '—')],
                    ['Задержка', esc(g.delay || '—')],
                    ['Потери', esc(g.loss || '—')]
                ])}
                <div class="jkt-links"><a class="jkt-btn ghost sm" href="/ui/routing/configuration"><i class="fa fa-road"></i> Шлюзы</a></div>`
        };
    }

    function panelFw() {
        const on = hosts.filter((h) => h.online).length;
        return {
            icon: `<div class="ic fw"><i class="fa fa-shield"></i></div>`,
            title: sys.name,
            sub: 'межсетевой экран jk-ufw',
            body: `
                <div class="jkt-sec"><i class="fa fa-shield"></i> Экран</div>
                ${kvHtml([
                    ['Имя', esc(sys.name)],
                    ['Подключения к интернету', String(wans.length)],
                    ['Локальные сети', esc(nets.filter((n) => !n.synthetic).map((n) => n.label).join(', ') || '—')],
                    ['Устройства', `${on} в сети, ${hosts.length} известно`]
                ])}
                <div class="jkt-sec"><i class="fa fa-sitemap"></i> Сети</div>
                ${kvHtml(nets.map((n) => [esc(n.label), `${n.cidr ? `<span class="jkt-mono">${esc(n.cidr.text)}</span> · ` : ''}${n.hosts.filter((h) => h.online).length} из ${n.hosts.length}`]))}`
        };
    }

    function panelInet() {
        return {
            icon: `<div class="ic"><i class="fa fa-globe"></i></div>`,
            title: 'Интернет',
            sub: plural(wans.length, 'подключение', 'подключения', 'подключений'),
            body: `<div class="jkt-sec"><i class="fa fa-globe"></i> Подключения</div>` +
                (wans.length ? kvHtml(wans.map((w) => [esc(w.label), `${esc(w.addr4 || '—')}<span class="hint">${esc((w.gw && (w.gw.status_translated || w.gw.status)) || '')}${w.gw && w.gw.delay ? ' · ' + esc(w.gw.delay) : ''}</span>`]))
                    : '<p class="muted">Интерфейсы WAN не найдены.</p>')
        };
    }

    function renderPanel() {
        if (!selected) {
            return;
        }
        let p = null;
        if (selected.kind === 'host') {
            const h = hosts.find((x) => x.mac === selected.id);
            p = h ? panelHost(h) : null;
        } else if (selected.kind === 'net') {
            const n = nets.find((x) => 'net:' + x.key === selected.id);
            p = n ? panelNet(n) : null;
        } else if (selected.kind === 'gw') {
            const w = wans.find((x) => 'wan:' + x.key === selected.id);
            p = w ? panelWan(w) : null;
        } else if (selected.kind === 'fw') {
            p = panelFw();
        } else {
            p = panelInet();
        }
        if (!p) {
            return;
        }
        $('#jkt-panel').html(`<div class="jkt-ph">${p.icon}<div class="t"><div class="n" title="${esc(p.title)}">${esc(p.title)}</div>
            <div class="v">${esc(p.sub)}</div></div><button class="jkt-x" type="button" id="jkt-close" title="Закрыть"><i class="fa fa-times"></i></button></div>
            <div class="jkt-pb">${p.body}</div>`);
    }
    function openPanel(id) {
        const kind = id === 'fw' ? 'fw' : id === 'inet' ? 'inet' : id.startsWith('net:') ? 'net' : id.startsWith('wan:') ? 'gw' : 'host';
        selected = {kind: kind, id: id};
        renderPanel();
        $('.jkt-node.sel, .jkt-table tr.sel').removeClass('sel');
        $(`.jkt-node[data-id="${id}"], .jkt-table tr[data-id="${id}"]`).addClass('sel');
        $('#jkt-panel').addClass('open').attr('aria-hidden', 'false');
        $('#jkt-shade').addClass('open');
    }
    function closePanel() {
        selected = null;
        $('.jkt-node.sel, .jkt-table tr.sel').removeClass('sel');
        $('#jkt-panel').removeClass('open').attr('aria-hidden', 'true');
        $('#jkt-shade').removeClass('open');
    }
    let toastTimer = null;
    function toast(text) {
        clearTimeout(toastTimer);
        $('#jkt-toast').html(`<i class="fa fa-check"></i>${esc(text)}`).addClass('open');
        toastTimer = setTimeout(() => $('#jkt-toast').removeClass('open'), 2200);
    }

    // ---------- CSV ----------
    function exportCsv() {
        const head = ['Имя', 'Все имена', 'IPv4', 'IPv6', 'MAC', 'OUI', 'Тип MAC', 'Производитель', 'Тип устройства', 'Сеть',
            'Адрес выдан', 'Аренда до', 'В сети', 'Впервые замечен', 'Последняя активность', 'Заблокировано', 'Ограничено', 'Замечания'];
        const q = (v) => '"' + String(v == null ? '' : v).replace(/"/g, '""') + '"';
        const lines = hosts.map((h) => [h.name, h.names.map((x) => x.n).join(' / '), h.ip4s.join(' '), h.ip6s.join(' '), h.mac.toUpperCase(),
            h.mi.oui, h.mi.label, h.vendor, h.type.label, h.netLabel,
            h.lease ? (h.lease.type === 'static' ? 'постоянный' : 'динамический') + ' ' + h.lease.source : '',
            h.lease && h.lease.expire ? fmtDate(h.lease.expire) : '', h.online ? 'да' : 'нет', h.first ? fmtDate(h.first) : '',
            h.online ? 'сейчас' : (h.last ? fmtDate(h.last) : ''), h.blocked ? 'да' : '', h.limited ? 'да' : '',
            h.findings.filter((f) => f.lvl === 'bad' || f.lvl === 'warn').map((f) => f.t).join('; ')].map(q).join(';'));
        const blob = new Blob(['﻿' + [head.map(q).join(';'), ...lines].join('\r\n')], {type: 'text/csv;charset=utf-8'});
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'jk-ufw-topology-' + new Date().toISOString().slice(0, 10) + '.csv';
        document.body.appendChild(a);
        a.click();
        setTimeout(() => {
            URL.revokeObjectURL(a.href);
            a.remove();
        }, 500);
    }

    // ---------- loading ----------
    async function refresh() {
        try {
            await load();
        } catch (e) {
            $('#jkt-msg').html(`<div><i class="fa fa-exclamation-triangle"></i>Не удалось построить карту: ${esc(e.message)}</div>`).show();
            return;
        }
        render();
    }
    async function listLoop() {
        clearTimeout(listTimer);
        if (!document.hidden) {
            await refresh();
        }
        listTimer = setTimeout(listLoop, LIST_EVERY);
    }

    // ---------- events ----------
    $('#jkt-q').on('input', function () {
        query = $(this).val().trim();
        render();
    }).on('keydown', function (e) {
        if (e.key === 'Enter') {
            const h = hosts.find((x) => shown(x) && matches(x));
            if (h) {
                if (mode === 'map') {
                    centerOn(h.mac);
                }
                openPanel(h.mac);
            }
        }
    });
    $('#jkt-show').on('click', 'span', function () {
        show = $(this).data('show');
        $('#jkt-show span').removeClass('sel');
        $(this).addClass('sel');
        fitted = false;
        render();
    });
    $('#jkt-mode').on('click', 'span', function () {
        mode = $(this).data('mode');
        $('#jkt-mode span').removeClass('sel');
        $(this).addClass('sel');
        $('#jkt-view').toggle(mode === 'map');
        $('#jkt-tablewrap').toggle(mode === 'table');
        if (mode === 'map') {
            fitted = false;
        }
        render();
    });
    $('.jkt-kpi[data-hl]').on('click', function () {
        const v = $(this).data('hl');
        hl = hl === v ? '' : v;
        render();
    });
    $('#jkt-vend').on('click', '.jkt-vrow', function () {
        const v = 'vendor:' + $(this).data('vendor');
        hl = hl === v ? '' : v;
        render();
    });
    $('#jkt-issues').on('click', '.jkt-issue', function () {
        const i = issues[Number($(this).data('issue'))];
        if (!i) {
            return;
        }
        if (i.hl) {
            hl = hl === i.hl ? '' : i.hl;
            render();
        } else if (i.mac || i.net) {
            const id = i.mac || (String(i.net).startsWith('wan:') ? i.net : 'net:' + i.net);
            if (mode === 'map') {
                centerOn(id);
            }
            openPanel(id);
        }
    });
    $('.jkt-zoom').on('click', 'button', function () {
        const z = $(this).data('z');
        const $v = $('#jkt-view');
        if (z === 'fit') {
            $('#jkt-canvas').css('transition', 'transform .3s ease');
            fit();
            setTimeout(() => $('#jkt-canvas').css('transition', ''), 320);
        } else {
            zoomAt(z === 'in' ? 1.25 : 0.8, $v.width() / 2, $v.height() / 2);
        }
    });
    $('#jkt-rows').on('click', 'tr[data-id]', function () {
        openPanel(String($(this).data('id')));
    });
    $('.jkt-table th[data-sort]').on('click', function () {
        const k = $(this).data('sort');
        tsort = tsort.key === k ? {key: k, asc: !tsort.asc} : {key: k, asc: k !== 'seen'};
        renderTable();
    });
    $('#jkt-refresh').on('click', async function () {
        $(this).find('.fa').addClass('fa-spin');
        await refresh();
        $(this).find('.fa').removeClass('fa-spin');
    });
    $('#jkt-csv').on('click', exportCsv);
    $('#jkt-shade').on('click', closePanel);
    $('#jkt-panel').on('click', '#jkt-close', closePanel).on('click', '[data-copy]', function () {
        const v = String($(this).data('copy'));
        const done = () => toast('Скопировано: ' + v);
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(v).then(done, () => null);
        } else {
            const t = $('<textarea/>').val(v).css({position: 'fixed', opacity: 0}).appendTo('body');
            t[0].select();
            try {
                document.execCommand('copy');
                done();
            } catch (e) {
                // nothing to do, the value stays visible
            }
            t.remove();
        }
    });
    $(document).on('keydown', (e) => {
        if (e.key === 'Escape' && selected) {
            closePanel();
        }
    });
    $(window).on('resize', () => {
        if (mode === 'map' && layout) {
            fit(true);
        }
    });
    document.addEventListener('visibilitychange', () => {
        if (!document.hidden) {
            listLoop();
        }
    });

    listLoop();
});
</script>
