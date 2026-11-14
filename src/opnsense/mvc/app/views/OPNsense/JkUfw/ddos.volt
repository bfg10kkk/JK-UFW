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
 #
 # jk-ufw: attack protection. Three parts on one page:
 #  - DDoS: per-address limits on the pass rules that are open to the internet, an automatic block list
 #    (pf overload table), SYN cookies, adaptive timeouts, live attack statistics;
 #  - threat feeds (IoC): downloaded lists of known bad addresses, blocked in both directions;
 #  - SIEM: copies of the firewall, IDS and security logs for a log collector in CEF, JSON or RFC 5424.
 # Data comes from /api/jkufw/ddos/* (see controllers/OPNsense/JkUfw/Api/DdosController.php).
 #}

<style>
.jdd { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1240px; }
.jdd * { box-sizing:border-box; }
.jdd b, .jdd strong { font-family:inherit; font-weight:700; }
.jdd .mono { font-family:ui-monospace,Menlo,Consolas,monospace; }
.jdd .muted { color:var(--m); }
.jdd a.lnk { color:var(--a2); }
.jdd-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jdd-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:23px; flex:none;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jdd-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jdd-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jdd-sub { color:var(--m); margin-top:2px; }
.jdd-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jdd-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jdd-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jdd-pill.warn i { background:var(--warn); }
.jdd-pill.bad i { background:var(--a); }
.jdd-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jdd-grid { display:grid; grid-template-columns:minmax(0,1.5fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1050px) { .jdd-grid { grid-template-columns:minmax(0,1fr); } }
.jdd-grid > div { min-width:0; }
.jdd-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jdd-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.jdd-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; display:flex; gap:8px; align-items:center; }
.jdd-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 760px) { .jdd-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jdd-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; min-width:0; }
.jdd-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jdd-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jdd-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jdd-kpi .v.ok { color:var(--ok); } .jdd-kpi .v.bad { color:var(--a2); } .jdd-kpi .v.warn { color:var(--warn); }
/* flow diagram */
.jdd-flow { padding:10px 18px 6px; background:radial-gradient(ellipse at 40% 0%,rgba(229,32,46,.10),rgba(229,32,46,0) 60%), var(--s); }
.jdd-flow svg { display:block; width:100%; height:auto; }
.jdd-flow text { font-family:inherit; }
@keyframes jddflow { to { stroke-dashoffset:-24; } }
.jdd-flow .live { stroke-dasharray:7 5; animation:jddflow .9s linear infinite; }
@media (prefers-reduced-motion: reduce) { .jdd-flow .live { animation:none; } }
/* link cards */
.jdd-links { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:12px; }
@media (max-width: 640px) { .jdd-links { grid-template-columns:minmax(0,1fr); } }
.jdd-link { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; position:relative; min-width:0; }
.jdd-link.carry { border-color:rgba(229,32,46,.55); box-shadow:inset 0 0 0 1px rgba(229,32,46,.25); }
.jdd-link.off { opacity:.6; }
.jdd-link-top { display:flex; align-items:center; gap:10px; }
.jdd-link-ic { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:16px; flex:none; position:relative; }
.jdd-link.carry .jdd-link-ic { background:var(--abg); color:var(--a2); }
.jdd-link-ic .dot { position:absolute; right:-2px; bottom:-2px; width:11px; height:11px; border-radius:50%; background:#3a3a42; border:2px solid var(--s2); }
.dot.ok { background:var(--ok) !important; } .dot.warn { background:var(--warn) !important; } .dot.bad { background:var(--a) !important; }
.jdd-link-n { font-weight:700; font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jdd-link-s { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jdd-link-m { flex:1; min-width:0; }
.jdd-chip { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; background:#232329; color:var(--m); white-space:nowrap; }
.jdd-chip.acc { background:var(--abg); color:var(--a2); }
.jdd-chip.ok { background:rgba(34,197,94,.12); color:#4ade80; }
.jdd-chip.warn { background:rgba(245,165,36,.12); color:var(--warn); }
.jdd-chip.bad { background:var(--abg); color:#ff6b74; }
.jdd-stats { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; margin:14px 0 8px; }
.jdd-stats .l { color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jdd-stats .v { font-size:18px; font-weight:700; letter-spacing:-.02em; }
.jdd-stats .v small { font-size:11px; color:var(--m); margin-left:2px; font-weight:600; }
.jdd-spark { height:44px; }
.jdd-spark svg { width:100%; height:100%; display:block; }
.jdd-strip { display:flex; gap:2px; margin-top:6px; }
.jdd-strip i { flex:1; height:6px; border-radius:2px; background:#26262c; }
.jdd-strip i.ok { background:rgba(34,197,94,.75); } .jdd-strip i.warn { background:var(--warn); } .jdd-strip i.bad { background:var(--a); }
.jdd-tr { display:flex; gap:14px; margin-top:10px; color:var(--m); font-size:12px; align-items:center; }
.jdd-tr b { color:var(--t); font-weight:600; }
.jdd-util { height:4px; border-radius:2px; background:#26262c; margin-top:8px; overflow:hidden; }
.jdd-util i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); }
/* buttons, fields */
.jdd-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important;
  display:inline-flex; align-items:center; gap:7px; text-decoration:none !important; white-space:nowrap; }
.jdd-btn:hover { background:var(--a2); }
.jdd-btn[disabled] { opacity:.5; cursor:default; }
.jdd-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jdd-btn.ghost:hover { background:var(--h); }
.jdd-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jdd-btn.icon { padding:6px 9px; }
.jdd-btn.danger:hover { color:var(--a2) !important; border-color:rgba(229,32,46,.5); }
.jdd-sw { display:inline-block; vertical-align:middle; flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jdd-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jdd-sw.on { background:var(--a); }
.jdd-sw.on::after { left:16px; background:#fff; }
.jdd-seg { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
.jdd-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; cursor:pointer; transition:all .15s; min-width:0; }
.jdd-opt:hover { border-color:var(--b2); background:var(--h); }
.jdd-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jdd-opt .nm { font-weight:700; font-size:13.5px; }
.jdd-opt .nm .fa { color:var(--m); margin-right:6px; }
.jdd-opt.sel .nm .fa { color:var(--a2); }
.jdd-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jdd-field { margin-bottom:14px; }
.jdd-field > label { display:block; font-weight:600; margin-bottom:6px; }
.jdd-field .hint { color:var(--m); font-size:12px; margin-top:5px; line-height:1.45; }
.jdd input.jdd-in, .jdd select.jdd-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:9px 11px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:12.5px; box-shadow:none !important; }
.jdd input.jdd-in:focus, .jdd select.jdd-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg) !important; }
.jdd input.jdd-in.bad { border-color:var(--a) !important; }
.jdd-row2 { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:12px; }
@media (max-width: 560px) { .jdd-row2, .jdd-seg { grid-template-columns:minmax(0,1fr); } }
.jdd-tg { display:flex; gap:12px; align-items:flex-start; padding:11px 0; border-top:1px solid var(--b); }
.jdd-tg:first-of-type { border-top:0; }
.jdd-tg .tx { flex:1; min-width:0; }
.jdd-tg .tx b { display:block; }
.jdd-tg .tx span { color:var(--m); font-size:12px; line-height:1.45; }
.jdd-order { margin:0; padding:0; list-style:none; }
.jdd-order li { display:flex; align-items:center; gap:10px; padding:9px 10px; border:1px solid var(--b); background:var(--s2); border-radius:10px; margin-bottom:8px; }
.jdd-order li.out { opacity:.55; }
.jdd-order .num { width:24px; height:24px; border-radius:7px; display:grid; place-items:center; font-weight:700; font-size:12px; background:var(--abg); color:var(--a2); flex:none; }
.jdd-order li.out .num { background:#232329; color:var(--m); }
.jdd-order .nm { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jdd-order .nm small { color:var(--m); font-weight:500; margin-left:6px; }
.jdd-order .ctl { display:flex; gap:4px; align-items:center; flex:none; }
.jdd-order .wt { min-width:46px; text-align:center; font-weight:700; }
.jdd-chips { display:flex; gap:8px; flex-wrap:wrap; }
.jdd-cb { display:inline-flex; align-items:center; gap:7px; padding:7px 11px; border:1px solid var(--b); background:var(--s2); border-radius:9px; cursor:pointer; font-weight:600; font-size:12.5px; }
.jdd-cb .fa { color:var(--m); }
.jdd-cb.sel { border-color:var(--a); background:var(--abg); }
.jdd-cb.sel .fa { color:var(--a2); }
.jdd-cb small { color:var(--m); font-weight:500; }
.jdd-pol { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jdd-pol:first-child { border-top:0; padding-top:0; }
.jdd-pol .ic { width:38px; height:38px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jdd-pol.off .ic { background:#202026; color:var(--m); }
.jdd-pol.off .pm { opacity:.6; }
.jdd-pol .pm { flex:1; min-width:0; }
.jdd-pol .pn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jdd-pol .ps { color:var(--m); font-size:11.5px; margin-top:2px; overflow-wrap:anywhere; }
.jdd-pol .arrow { display:flex; align-items:center; gap:6px; flex:none; font-weight:600; }
.jdd-pol .pa { display:flex; gap:6px; align-items:center; flex:none; }
@media (max-width: 560px) { .jdd-pol { flex-wrap:wrap; } .jdd-pol .arrow { order:3; width:100%; padding-left:50px; } }
.jdd-ev { display:flex; gap:11px; padding:9px 0; border-top:1px solid var(--b); }
.jdd-ev:first-child { border-top:0; padding-top:0; }
.jdd-ev .ei { width:28px; height:28px; border-radius:8px; display:grid; place-items:center; flex:none; background:#202026; color:var(--m); font-size:12.5px; }
.jdd-ev.bad .ei { background:var(--abg); color:var(--a2); }
.jdd-ev.ok .ei { background:rgba(34,197,94,.12); color:var(--ok); }
.jdd-ev.warn .ei { background:rgba(245,165,36,.12); color:var(--warn); }
.jdd-ev .et { flex:1; min-width:0; line-height:1.4; }
.jdd-ev .ew { color:var(--m); font-size:11.5px; }
.jdd-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jdd-note .fa { margin-top:2px; }
.jdd-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jdd-note.warn .fa { color:var(--warn); }
.jdd-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jdd-note.err { background:var(--abg); border:1px solid rgba(229,32,46,.4); color:#ffb3b8; }
.jdd-empty { color:var(--m); text-align:center; padding:24px 6px; }
.jdd-empty .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }
.jdd-hero { display:flex; gap:18px; align-items:center; padding:22px; background:linear-gradient(120deg,rgba(229,32,46,.14),rgba(229,32,46,0) 60%), var(--s); }
.jdd-hero .big { font-size:17px; font-weight:700; }
.jdd-hero .ds { color:var(--m); margin-top:4px; line-height:1.5; }
.jdd-applybar { position:sticky; bottom:12px; z-index:5; display:none; align-items:center; gap:12px; padding:12px 14px; margin-bottom:16px;
  background:#1b1114; border:1px solid rgba(229,32,46,.45); border-radius:12px; box-shadow:0 10px 30px rgba(0,0,0,.5); }
.jdd-applybar.show { display:flex; }
.jdd-applybar .tx { flex:1; min-width:0; }
/* modal */
.jdd-ov { max-width:none; font-size:13px; position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.72); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; padding:16px; }
.jdd-ov.open { display:flex; }
.jdd-modal { width:100%; max-width:560px; max-height:calc(100vh - 32px); overflow:auto; background:var(--s); border:1px solid var(--b2); border-radius:14px;
  padding:22px; box-shadow:0 20px 60px rgba(0,0,0,.6); color:var(--t); }
.jdd-modal h4 { margin:0 0 4px; font-size:17px; font-weight:700; }
.jdd-modal .sub { color:var(--m); margin-bottom:16px; line-height:1.5; }
.jdd-modal .ft { display:flex; gap:8px; justify-content:flex-end; margin-top:18px; flex-wrap:wrap; }
.jdd-apps { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; }
@media (max-width: 480px) { .jdd-apps { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jdd-app { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 4px; text-align:center; cursor:pointer; font-size:11.5px; font-weight:600; line-height:1.25; }
.jdd-app .fa { display:block; font-size:18px; margin-bottom:6px; color:var(--m); }
.jdd-app.sel { border-color:var(--a); background:var(--abg); }
.jdd-app.sel .fa { color:var(--a2); }
.jdd-err { color:#ff8a92; font-size:12px; margin-top:10px; }
/* page specific */
.jdd-tabs { display:flex; gap:6px; margin:0 0 16px; border-bottom:1px solid var(--b); flex-wrap:wrap; }
.jdd-tab { padding:10px 14px; font-weight:600; color:var(--m); cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-1px; display:flex; gap:8px; align-items:center; }
.jdd-tab:hover { color:var(--t); }
.jdd-tab.sel { color:var(--t); border-bottom-color:var(--a); }
.jdd-tab .n { font-size:11px; font-weight:700; padding:1px 7px; border-radius:999px; background:#232329; color:var(--m); }
.jdd-tab.sel .n { background:var(--abg); color:var(--a2); }
.jdd-pane { display:none; }
.jdd-pane.sel { display:block; }
.jdd-logo.attack { color:#fff; background:linear-gradient(145deg,#ff6b3d,#c0151f); animation:jddpulse 1.6s ease-in-out infinite; }
@keyframes jddpulse { 0%,100% { box-shadow:0 0 0 0 rgba(229,32,46,.55); } 50% { box-shadow:0 0 0 10px rgba(229,32,46,0); } }
@media (prefers-reduced-motion: reduce) { .jdd-logo.attack { animation:none; } }
.jdd-bar { height:6px; border-radius:3px; background:#26262c; margin-top:9px; overflow:hidden; }
.jdd-bar i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); border-radius:3px; }
.jdd-bar.ok i { background:linear-gradient(90deg,#15803d,var(--ok)); }
.jdd-chart { position:relative; height:190px; }
.jdd-chart svg { display:block; width:100%; height:100%; overflow:visible; }
.jdd-chart text { font-family:inherit; font-size:10.5px; fill:var(--m); }
.jdd-legend { display:flex; gap:16px; flex-wrap:wrap; color:var(--m); font-size:12px; margin-top:10px; }
.jdd-legend i { display:inline-block; width:10px; height:10px; border-radius:3px; margin-right:6px; vertical-align:-1px; }
.jdd-range { display:inline-flex; background:var(--s2); border:1px solid var(--b); border-radius:8px; padding:2px; }
.jdd-range span { padding:3px 10px; border-radius:6px; cursor:pointer; font-size:12px; font-weight:600; color:var(--m); }
.jdd-range span.sel { background:var(--h); color:var(--t); }
.jdd-if { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; margin-bottom:12px; }
.jdd-if.on { border-color:rgba(229,32,46,.45); }
.jdd-if-top { display:flex; align-items:center; gap:10px; }
.jdd-if-ic { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:16px; flex:none; }
.jdd-if.on .jdd-if-ic { background:var(--abg); color:var(--a2); }
.jdd-if-m { flex:1; min-width:0; }
.jdd-if-n { font-weight:700; font-size:14px; }
.jdd-if-s { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jdd-if-body { margin-top:12px; }
.jdd-lv { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:6px; }
@media (max-width: 560px) { .jdd-lv { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jdd-lv span { text-align:center; padding:7px 4px; border-radius:8px; border:1px solid var(--b); background:var(--s); cursor:pointer; font-weight:600; font-size:12px; }
.jdd-lv span.sel { border-color:var(--a); background:var(--abg); color:#fff; }
.jdd-lim { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; margin-top:10px; }
@media (max-width: 560px) { .jdd-lim { grid-template-columns:minmax(0,1fr); } }
.jdd-lim > div { background:var(--s); border:1px solid var(--b); border-radius:9px; padding:8px 10px; min-width:0; }
.jdd-lim .l { color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.05em; }
.jdd-lim .v { font-weight:700; font-size:16px; margin-top:2px; }
.jdd-lim .v small { color:var(--m); font-size:11px; font-weight:600; margin-left:3px; }
.jdd-lim input.jdd-in { padding:5px 8px !important; margin-top:4px; font-weight:700; font-size:14px !important; }
.jdd-rules { margin-top:12px; border-top:1px solid var(--b); padding-top:10px; }
.jdd-rule { display:flex; gap:10px; align-items:center; padding:5px 0; font-size:12.5px; }
.jdd-rule .fa { width:16px; text-align:center; color:var(--m); }
.jdd-rule.lim .fa { color:var(--ok); }
.jdd-rule .rn { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jdd-rule .rs { color:var(--m); font-size:11.5px; white-space:nowrap; }
@media (max-width: 560px) { .jdd-rule { flex-wrap:wrap; } .jdd-rule .rn { flex:1 1 calc(100% - 30px); white-space:normal; } .jdd-rule .rs { padding-left:26px; white-space:normal; } }
.jdd-tbl { width:100%; border-collapse:collapse; }
.jdd-tbl th { text-align:left; color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; padding:0 8px 8px 0; }
.jdd-tbl td { padding:8px 8px 8px 0; border-top:1px solid var(--b); vertical-align:middle; }
.jdd-tbl td:last-child, .jdd-tbl th:last-child { text-align:right; padding-right:0; }
.jdd-addr { display:flex; gap:8px; margin-top:12px; }
.jdd-addr .jdd-in { flex:1; }
.jdd-ta { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important; width:100% !important; max-width:none !important;
  min-height:110px; padding:9px 11px !important; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; resize:vertical; }
.jdd-ta:focus { border-color:var(--a) !important; outline:none; }
.jdd-feed { display:flex; gap:12px; align-items:center; padding:12px 0; border-top:1px solid var(--b); }
.jdd-feed:first-child { border-top:0; padding-top:0; }
.jdd-feed .ic { width:38px; height:38px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jdd-feed.off .ic { background:#202026; color:var(--m); }
.jdd-feed.off .fm { opacity:.6; }
.jdd-feed .fm { flex:1; min-width:0; }
.jdd-feed .fn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jdd-feed .fs { color:var(--m); font-size:11.5px; margin-top:2px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jdd-feed .fc { text-align:right; flex:none; font-weight:700; }
.jdd-feed .fc small { display:block; color:var(--m); font-weight:500; font-size:11px; }
.jdd-feed .fa-ctl { display:flex; gap:6px; align-items:center; flex:none; }
.jdd-cat { display:grid; grid-template-columns:repeat(auto-fill,minmax(210px,1fr)); gap:8px; }
.jdd-cat .jdd-opt .nm { font-size:12.5px; }
.jdd-cat .jdd-opt.added { opacity:.45; cursor:default; }
.jdd-pre { background:#0d0d10; border:1px solid var(--b); border-radius:8px; padding:10px 12px; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11.5px;
  color:#c9c9d1; white-space:pre-wrap; word-break:break-all; line-height:1.5; }
.jdd-pre b { color:var(--a2); font-weight:600; }
.jdd-fmt { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; }
@media (max-width: 560px) { .jdd-fmt { grid-template-columns:minmax(0,1fr); } }
</style>

<div class="jdd" id="jdd">
  <div class="jdd-head">
    <div class="jdd-logo" id="jdd-logo"><i class="fa fa-shield"></i></div>
    <div>
      <h1 class="jdd-title">Защита от атак <span class="jdd-pill" id="jdd-pill"><i></i><span>…</span></span></h1>
      <div class="jdd-sub">DDoS, списки угроз и выгрузка журналов в SIEM</div>
    </div>
    <div class="jdd-head-r">
      <a class="jdd-btn ghost" href="/ui/diagnostics/log/jkufw/ddos"><i class="fa fa-list-alt"></i> Журнал</a>
      <a class="jdd-btn ghost" href="/ui/firewall/filter"><i class="fa fa-sliders"></i> Правила</a>
    </div>
  </div>

  <div id="jdd-loading" class="jdd-card"><div class="jdd-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></div>
  <div id="jdd-error" class="jdd-note err" style="display:none; margin:0 0 16px"><i class="fa fa-exclamation-circle"></i><div></div></div>

  <div id="jdd-main" style="display:none">
    <div class="jdd-tabs" id="jdd-tabs">
      <div class="jdd-tab sel" data-tab="ddos"><i class="fa fa-bolt"></i> DDoS</div>
      <div class="jdd-tab" data-tab="ioc"><i class="fa fa-crosshairs"></i> Списки угроз <span class="n" id="jdd-n-ioc">0</span></div>
      <div class="jdd-tab" data-tab="siem"><i class="fa fa-share-square-o"></i> Экспорт в SIEM <span class="n" id="jdd-n-siem">0</span></div>
    </div>

    <div class="jdd-applybar" id="jdd-applybar">
      <i class="fa fa-pencil" style="color:var(--a2)"></i>
      <div class="tx"><b>Есть неприменённые изменения.</b> <span class="muted">Они вступят в силу после применения.</span></div>
      <button class="jdd-btn ghost sm" id="jdd-revert">Отменить</button>
      <button class="jdd-btn sm" id="jdd-apply"><i class="fa fa-check"></i> Применить</button>
    </div>

    <!-- ===================== DDoS ===================== -->
    <div class="jdd-pane sel" data-pane="ddos">
      <div class="jdd-card jdd-hero" id="jdd-intro" style="display:none">
        <div class="jdd-logo on"><i class="fa fa-shield"></i></div>
        <div style="flex:1; min-width:0">
          <div class="big">Защита от DDoS выключена</div>
          <div class="ds">Включите — и у каждого адреса из интернета появится лимит соединений. Кто его превысит, попадёт
            в чёрный список на заданное время. SYN-флуд отражается SYN cookies, а таблица соединений не переполнится.</div>
        </div>
        <button class="jdd-btn" id="jdd-intro-go"><i class="fa fa-power-off"></i> Включить защиту</button>
      </div>

      <div class="jdd-kpis">
        <div class="jdd-kpi"><div class="l">Состояние</div><div class="v" id="k-state">—</div></div>
        <div class="jdd-kpi"><div class="l">Отброшено сейчас</div><div class="v" id="k-drop">—</div></div>
        <div class="jdd-kpi"><div class="l">Заблокировано адресов</div><div class="v" id="k-blocked">—</div></div>
        <div class="jdd-kpi"><div class="l">Таблица соединений</div><div class="v" id="k-states">—</div><div class="jdd-bar ok" id="k-states-bar"><i style="width:0"></i></div></div>
      </div>

      <div class="jdd-card">
        <h3><i class="fa fa-area-chart"></i> Нагрузка на внешние интерфейсы
          <span class="r"><span class="jdd-range" id="jdd-range"><span data-h="1">1 ч</span><span data-h="6" class="sel">6 ч</span><span data-h="24">24 ч</span></span></span></h3>
        <div class="jdd-chart" id="jdd-chart"></div>
        <div class="jdd-legend">
          <span><i style="background:var(--a2)"></i>Отброшено пакетов/с</span>
          <span><i style="background:#d6d6dc"></i>Новых соединений/с</span>
          <span><i style="background:rgba(229,32,46,.22)"></i>Атака</span>
          <span><i style="background:rgba(245,165,36,.18)"></i>Повышенная активность</span>
        </div>
      </div>

      <div class="jdd-grid">
        <div>
          <div class="jdd-card">
            <h3><i class="fa fa-plug"></i> Что защищаем <span class="r muted" id="jdd-poll"></span></h3>
            <div id="jdd-ifs"></div>
          </div>
          <div class="jdd-card">
            <h3><i class="fa fa-ban"></i> Чёрный список
              <span class="r"><button class="jdd-btn ghost sm danger" id="jdd-unblock-all"><i class="fa fa-eraser"></i> Освободить все</button></span></h3>
            <div id="jdd-blocked"></div>
            <div class="jdd-addr">
              <input class="jdd-in mono" id="jdd-block-ip" type="text" placeholder="Адрес, например 203.0.113.7"/>
              <button class="jdd-btn sm" id="jdd-block"><i class="fa fa-ban"></i> Заблокировать</button>
            </div>
            <div class="hint muted" style="font-size:12px; margin-top:6px" id="jdd-block-h"></div>
          </div>
        </div>
        <div>
          <div class="jdd-card">
            <h3><i class="fa fa-tachometer"></i> Уровень защиты
              <span class="r"><span class="muted" id="jdd-en-t">Выключено</span><span class="jdd-sw" id="jdd-en" role="switch" tabindex="0" aria-label="Защита от DDoS"></span></span></h3>
            <div class="jdd-seg" id="jdd-preset" style="grid-template-columns:repeat(3,minmax(0,1fr))">
              <div class="jdd-opt" data-p="light"><div class="nm"><i class="fa fa-leaf"></i>Лёгкий</div><div class="ds">Для игр, торрентов и больших офисов за одним адресом.</div></div>
              <div class="jdd-opt" data-p="standard"><div class="nm"><i class="fa fa-shield"></i>Обычный</div><div class="ds">Подходит почти всем. Не мешает сайтам и VPN.</div></div>
              <div class="jdd-opt" data-p="strict"><div class="nm"><i class="fa fa-bolt"></i>Строгий</div><div class="ds">Во время атаки. SYN-прокси и жёсткие лимиты.</div></div>
            </div>
            <div class="jdd-tg" style="margin-top:8px"><div class="tx"><b>SYN cookies</b><span>Отвечать на SYN-флуд, не занимая таблицу соединений.</span></div>
              <select class="jdd-in" id="jdd-cookies" style="width:auto !important"><option value="off">выкл</option><option value="adaptive">при нагрузке</option><option value="always">всегда</option></select></div>
            <div class="jdd-tg"><div class="tx"><b>Адаптивные тайм-ауты</b><span>Когда таблица заполняется на 60 %, простаивающие соединения закрываются быстрее.</span></div>
              <span class="jdd-sw" id="jdd-adaptive" role="switch" tabindex="0"></span></div>
            <div class="jdd-tg"><div class="tx"><b>Агрессивная очистка</b><span>Короткие тайм-ауты для всех соединений. Может рвать долгие простаивающие сессии.</span></div>
              <span class="jdd-sw" id="jdd-aggr" role="switch" tabindex="0"></span></div>
            <div class="jdd-tg"><div class="tx"><b>Лимит ответов ICMP/RST в секунду</b><span>Сколько ошибок и сбросов шлёт сам межсетевой экран. Не даёт использовать его как отражатель.</span></div>
              <input class="jdd-in" id="jdd-icmp" type="text" inputmode="numeric" style="width:90px !important"/></div>
            <div class="jdd-tg"><div class="tx"><b>Блокировать несуществующие адреса</b><span id="jdd-bogons-h">Пакеты из зарезервированных диапазонов (bogons), которые бывают только у подделанных отправителей.</span></div>
              <span class="jdd-sw" id="jdd-bogons" role="switch" tabindex="0"></span></div>
            <div class="jdd-field" style="margin-top:12px"><label for="jdd-blocktime">На сколько блокировать нарушителя</label>
              <select class="jdd-in" id="jdd-blocktime">
                <option value="10">10 минут</option><option value="60">1 час</option><option value="360">6 часов</option>
                <option value="1440">сутки</option><option value="10080">неделя</option></select></div>
            <div class="jdd-field"><label for="jdd-allow">Никогда не блокировать</label>
              <textarea class="jdd-ta" id="jdd-allow" style="min-height:64px" placeholder="адрес или сеть на строку"></textarea>
              <div class="hint" id="jdd-allow-h"></div></div>
            <div class="jdd-field" style="margin-bottom:0"><label for="jdd-deny">Всегда блокировать</label>
              <textarea class="jdd-ta" id="jdd-deny" style="min-height:64px" placeholder="адрес или сеть на строку"></textarea></div>
          </div>
          <div class="jdd-card">
            <h3><i class="fa fa-history"></i> События</h3>
            <div id="jdd-events"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- ===================== IoC ===================== -->
    <div class="jdd-pane" data-pane="ioc">
      <div class="jdd-kpis">
        <div class="jdd-kpi"><div class="l">Списков включено</div><div class="v" id="k-feeds">—</div></div>
        <div class="jdd-kpi"><div class="l">Опасных адресов</div><div class="v" id="k-iocs">—</div></div>
        <div class="jdd-kpi"><div class="l">Своих индикаторов</div><div class="v" id="k-own">—</div></div>
        <div class="jdd-kpi"><div class="l">Направление</div><div class="v" style="font-size:17px; padding-top:5px">вход и выход</div></div>
      </div>
      <div class="jdd-grid">
        <div>
          <div class="jdd-card">
            <h3><i class="fa fa-crosshairs"></i> Подключённые списки угроз</h3>
            <div id="jdd-feeds"></div>
          </div>
          <div class="jdd-card">
            <h3><i class="fa fa-plus-circle"></i> Добавить список</h3>
            <div class="jdd-cat" id="jdd-cat"></div>
            <div class="jdd-row2" style="margin-top:14px">
              <div class="jdd-field"><label for="jdd-feed-name">Свой список: название</label>
                <input class="jdd-in" id="jdd-feed-name" type="text" maxlength="48" placeholder="Например: ГосСОПКА"/></div>
              <div class="jdd-field"><label for="jdd-feed-url">Адрес файла (HTTPS)</label>
                <input class="jdd-in mono" id="jdd-feed-url" type="text" placeholder="https://…/blocklist.txt"/></div>
            </div>
            <button class="jdd-btn ghost sm" id="jdd-feed-add"><i class="fa fa-plus"></i> Добавить</button>
            <div class="jdd-note info"><i class="fa fa-info-circle"></i><div>Файл — по адресу или сети на строку (комментарии с # пропускаются).
              Списки скачиваются по расписанию, трафик с этими адресами блокируется в обе стороны: атаки снаружи и
              обращения заражённых устройств к серверам управления.</div></div>
          </div>
        </div>
        <div>
          <div class="jdd-card">
            <h3><i class="fa fa-pencil-square-o"></i> Свои индикаторы (IoC)</h3>
            <textarea class="jdd-ta" id="jdd-custom" style="min-height:180px" placeholder="198.51.100.23&#10;203.0.113.0/24&#10;2001:db8:bad::/48"></textarea>
            <div class="hint muted" style="font-size:12px; margin-top:6px">IP-адреса и сети из бюллетеней CERT, отчётов SOC и расследований. По одному на строку.</div>
            <div class="jdd-tg" style="margin-top:8px"><div class="tx"><b>Записывать срабатывания в журнал</b><span>Попадут в журнал межсетевого экрана и в SIEM.</span></div>
              <span class="jdd-sw" id="jdd-ioclog" role="switch" tabindex="0"></span></div>
          </div>
        </div>
      </div>
    </div>

    <!-- ===================== SIEM ===================== -->
    <div class="jdd-pane" data-pane="siem">
      <div class="jdd-grid">
        <div>
          <div class="jdd-card">
            <h3><i class="fa fa-share-square-o"></i> Куда отправлять журналы
              <span class="r"><button class="jdd-btn sm" id="jdd-siem-add"><i class="fa fa-plus"></i> Добавить получателя</button></span></h3>
            <div id="jdd-targets"></div>
          </div>
        </div>
        <div>
          <div class="jdd-card">
            <h3><i class="fa fa-code"></i> Как выглядят события</h3>
            <div class="jdd-chips" id="jdd-sample-fmt" style="margin-bottom:10px">
              <span class="jdd-cb sel" data-f="cef">CEF</span><span class="jdd-cb" data-f="json">JSON</span><span class="jdd-cb" data-f="rfc5424">RFC 5424</span></div>
            <div class="jdd-pre" id="jdd-sample"></div>
            <div class="jdd-note info"><i class="fa fa-info-circle"></i><div>Записи межсетевого экрана разбираются на поля: источник, назначение,
              порты, действие, интерфейс. Срабатывания IPS — на сигнатуру, класс и приоритет. Остальное уходит текстом с именем программы.
              Время — по часам межсетевого экрана, доставка — syslog по UDP или TCP.</div></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- SIEM target -->
<div class="jdd jdd-ov" id="jdd-ov-siem" role="dialog" aria-modal="true">
  <div class="jdd-modal">
    <h4 id="js-title">Получатель журналов</h4>
    <div class="sub">SIEM или сборщик журналов: KUMA, MaxPatrol SIEM, QRadar, ArcSight, Splunk, Elastic, Graylog, Wazuh.</div>
    <div class="jdd-field"><label for="js-name">Название</label>
      <input class="jdd-in" id="js-name" type="text" maxlength="48" placeholder="Например: SOC KUMA"/></div>
    <div class="jdd-row2">
      <div class="jdd-field"><label for="js-host">Адрес</label>
        <input class="jdd-in mono" id="js-host" type="text" placeholder="10.0.0.50 или siem.example.kz"/></div>
      <div class="jdd-row2">
        <div class="jdd-field"><label for="js-port">Порт</label>
          <input class="jdd-in mono" id="js-port" type="text" inputmode="numeric" placeholder="514"/></div>
        <div class="jdd-field"><label for="js-tr">Протокол</label>
          <select class="jdd-in" id="js-tr"><option value="udp4">UDP</option><option value="tcp4">TCP</option><option value="udp6">UDP (IPv6)</option><option value="tcp6">TCP (IPv6)</option></select></div>
      </div>
    </div>
    <div class="jdd-field"><label>Формат</label>
      <div class="jdd-fmt" id="js-fmt">
        <div class="jdd-opt" data-f="cef"><div class="nm">CEF</div><div class="ds">KUMA, MaxPatrol, QRadar, ArcSight</div></div>
        <div class="jdd-opt" data-f="json"><div class="nm">JSON</div><div class="ds">Elastic, Graylog, Wazuh, Splunk</div></div>
        <div class="jdd-opt" data-f="rfc5424"><div class="nm">Syslog</div><div class="ds">RFC 5424, как есть</div></div>
      </div></div>
    <div class="jdd-field"><label>Что отправлять</label>
      <div class="jdd-chips" id="js-logs">
        <span class="jdd-cb" data-v="firewall"><i class="fa fa-fire"></i>Межсетевой экран</span>
        <span class="jdd-cb" data-v="ids"><i class="fa fa-eye"></i>Атаки (IPS)</span>
        <span class="jdd-cb" data-v="security"><i class="fa fa-shield"></i>Защита от DDoS</span>
        <span class="jdd-cb" data-v="auth"><i class="fa fa-user-secret"></i>Входы и изменения настроек</span>
        <span class="jdd-cb" data-v="system"><i class="fa fa-server"></i>Остальное</span>
      </div></div>
    <div class="jdd-err" id="js-err"></div>
    <div class="ft">
      <button class="jdd-btn ghost" data-close>Отмена</button>
      <button class="jdd-btn" id="js-save"><i class="fa fa-check"></i> Готово</button>
    </div>
  </div>
</div>

<script>
'use strict';
$(function () {
    const POLL_MS = 10000;
    const LEVEL_NAMES = {light: 'Лёгкий', standard: 'Обычный', strict: 'Строгий', custom: 'Свой'};
    const FMT_NAMES = {cef: 'CEF', json: 'JSON', rfc5424: 'Syslog RFC 5424'};
    const LOG_NAMES = {firewall: 'межсетевой экран', ids: 'IPS', security: 'DDoS', auth: 'входы и настройки', system: 'остальное'};

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error((x.responseJSON && x.responseJSON.errorMessage) || (x.status + ' ' + (x.statusText || '')))));
    });
    const pick = (v) => {
        if (v == null) { return ''; }
        if (typeof v !== 'object') { return String(v); }
        return Object.keys(v).filter((k) => String(v[k].selected) === '1').join(',');
    };
    const list = (v) => pick(v).split(',').filter(Boolean);
    const num = (n) => (n == null || !isFinite(n)) ? '—' : Math.round(n).toLocaleString('ru-RU');
    const short = (n) => {
        if (n == null || !isFinite(n)) { return '—'; }
        if (n >= 1e6) { return (n / 1e6).toFixed(1).replace('.', ',') + ' млн'; }
        if (n >= 1e4) { return Math.round(n / 1e3) + ' тыс'; }
        return Math.round(n).toLocaleString('ru-RU');
    };
    const ago = (t) => {
        const s = Math.max(0, Date.now() / 1000 - t);
        if (s < 60) { return 'только что'; }
        if (s < 3600) { return Math.round(s / 60) + ' мин назад'; }
        if (s < 86400) { return Math.round(s / 3600) + ' ч назад'; }
        return Math.round(s / 86400) + ' дн назад';
    };
    const when = (t) => {
        const d = new Date(t * 1000), now = new Date();
        const hm = d.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'});
        if (d.toDateString() === now.toDateString()) { return 'сегодня, ' + hm; }
        const y = new Date(now); y.setDate(now.getDate() - 1);
        if (d.toDateString() === y.toDateString()) { return 'вчера, ' + hm; }
        return d.toLocaleDateString('ru-RU', {day: 'numeric', month: 'short'}) + ', ' + hm;
    };
    const lines = (v) => String(v || '').split(/[\s,;]+/).map((s) => s.trim()).filter(Boolean);
    const store = {
        get(k, d) { try { const v = JSON.parse(localStorage.getItem(k)); return v == null ? d : v; } catch (e) { return d; } },
        set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* private mode */ } }
    };

    let st = null;          // last /status
    let draft = null;       // settings being edited
    let saved = null;       // settings as saved (JSON)
    let busy = false;
    let range = store.get('jdd-range', 6);

    // ---- settings ---------------------------------------------------------------------------------
    function fromModel(m) {
        const g = m.ddos.general;
        const items = (o) => Object.keys(o || {}).map((uuid) => Object.assign({uuid: uuid}, o[uuid]));
        return {
            general: {
                enabled: String(g.enabled) === '1', preset: pick(g.preset) || 'standard', syncookies: pick(g.syncookies) || 'adaptive',
                adaptive: String(g.adaptive) === '1', optimization: pick(g.optimization) || 'normal', icmplimit: String(g.icmplimit || ''),
                bogons: String(g.bogons) === '1', blocktime: String(g.blocktime || '60'), allow: list(g.allow), deny: list(g.deny)
            },
            interfaces: items(m.ddos.interfaces.interface).map((i) => ({
                uuid: i.uuid, interface: String(i.interface), enabled: String(i.enabled) === '1', level: pick(i.level) || 'standard',
                states: String(i.states || ''), conns: String(i.conns || ''), rate: String(i.rate || ''), per: String(i.per || ''),
                synproxy: String(i.synproxy) === '1'
            })),
            ioc: {
                custom: list(m.ddos.ioc.custom), log: String(m.ddos.ioc.log) === '1',
                feeds: items(m.ddos.ioc.feed).map((f) => ({uuid: f.uuid, enabled: String(f.enabled) === '1', name: String(f.name), url: String(f.url), refresh: String(f.refresh || '12')}))
            },
            siem: items(m.ddos.siem.target).map((t) => ({uuid: t.uuid, enabled: String(t.enabled) === '1', name: String(t.name), host: String(t.host),
                port: String(t.port || '514'), transport: pick(t.transport) || 'udp4', format: pick(t.format) || 'cef', logs: list(t.logs)}))
        };
    }
    const b = (v) => v ? '1' : '0';
    function toPost(d) {
        const g = d.general;
        return {ddos: {
            general: {enabled: b(g.enabled), preset: g.preset, syncookies: g.syncookies, adaptive: b(g.adaptive), optimization: g.optimization,
                icmplimit: g.icmplimit, bogons: b(g.bogons), blocktime: g.blocktime, allow: g.allow.join(','), deny: g.deny.join(',')},
            interfaces: d.interfaces.map((i) => ({uuid: i.uuid || '', interface: i.interface, enabled: b(i.enabled), level: i.level,
                states: i.states, conns: i.conns, rate: i.rate, per: i.per, synproxy: b(i.synproxy)})),
            ioc: {custom: d.ioc.custom.join(','), log: b(d.ioc.log),
                feeds: d.ioc.feeds.map((f) => ({uuid: f.uuid || '', enabled: b(f.enabled), name: f.name, url: f.url, refresh: f.refresh}))},
            siem: d.siem.map((t) => ({uuid: t.uuid || '', enabled: b(t.enabled), name: t.name, host: t.host, port: t.port,
                transport: t.transport, format: t.format, logs: t.logs.join(',')}))
        }};
    }
    const dirty = () => JSON.stringify(draft) !== saved;
    function changed() {
        $('#jdd-applybar').toggleClass('show', dirty() || (st && st.pending));
        renderAll();
    }

    const ifDraft = (name) => draft.interfaces.find((i) => i.interface === name);
    const levelLimits = (i) => {
        if (i.level !== 'custom' && st.levels[i.level]) { return st.levels[i.level]; }
        const s = st.levels.standard;
        const v = (k) => i[k] !== '' && i[k] != null ? parseInt(i[k], 10) : s[k];
        return {states: v('states'), conns: v('conns'), rate: v('rate'), per: v('per'), synproxy: i.synproxy ? '1' : '0'};
    };
    function applyPreset(p) {
        const g = draft.general;
        g.preset = p;
        const ps = st.presets[p];
        if (ps) {
            g.syncookies = ps.syncookies; g.adaptive = ps.adaptive === '1'; g.optimization = ps.optimization; g.icmplimit = ps.icmplimit;
            draft.interfaces.forEach((i) => { if (i.level !== 'custom') { i.level = p; } });
        }
    }
    function enable(on) {
        draft.general.enabled = on;
        if (on && !draft.interfaces.some((i) => i.enabled)) {
            st.interfaces.filter((i) => i.wan).forEach((i) => {
                const d = ifDraft(i.name);
                if (d) { d.enabled = true; } else { draft.interfaces.push({interface: i.name, enabled: true, level: draft.general.preset === 'custom' ? 'standard' : draft.general.preset, states: '', conns: '', rate: '', per: '', synproxy: false}); }
            });
        }
        if (on && st.admin_address && !draft.general.allow.length) {
            draft.general.allow.push(st.admin_address);
        }
    }

    // ---- state of the attack ----------------------------------------------------------------------
    function current() {
        const h = (st.stats.history || []);
        return h.length ? h[h.length - 1] : {};
    }
    function level() {
        if (!st.enabled || !st.applied) { return 'off'; }
        return current().level || 'calm';
    }
    const LOOK = {
        off: ['', 'Выключено', 'muted'],
        calm: ['ok', 'Спокойно', 'ok'],
        elevated: ['warn', 'Повышенная активность', 'warn'],
        attack: ['bad', 'Идёт атака', 'bad']
    };

    // ---- rendering --------------------------------------------------------------------------------
    function renderHead() {
        const lv = level(), look = LOOK[lv];
        $('#jdd-pill').attr('class', 'jdd-pill ' + look[0]).find('span').text(look[1]);
        $('#jdd-logo').toggleClass('on', lv !== 'off' && lv !== 'attack').toggleClass('attack', lv === 'attack');
        $('#jdd-intro').toggle(!draft.general.enabled && !st.enabled);
    }

    function renderKpis() {
        const s = st.stats, c = current(), lv = level();
        $('#k-state').attr('class', 'v ' + LOOK[lv][2]).text(LOOK[lv][1]);
        $('#k-drop').html(c.rate_block == null ? '—' : `${short(c.rate_block)}<small>пак/с</small>`);
        const blocked = (s.blocked || []).length;
        $('#k-blocked').attr('class', 'v' + (blocked ? ' bad' : '')).text(num(blocked));
        const pct = s.limit ? s.states / s.limit * 100 : 0;
        $('#k-states').html(`${short(s.states)}<small>из ${short(s.limit)}</small>`);
        $('#k-states-bar').toggleClass('ok', pct < 50).find('i').css('width', Math.min(100, Math.max(pct, s.states ? 1 : 0)).toFixed(1) + '%');
        $('#jdd-poll').text('обновлено ' + new Date(s.time * 1000).toLocaleTimeString('ru-RU'));

        const feeds = draft.ioc.feeds.filter((f) => f.enabled);
        $('#k-feeds').html(`${feeds.length}<small>из ${draft.ioc.feeds.length}</small>`);
        let total = 0;
        (st.feeds || []).forEach((f) => { total += f.entries || 0; });
        $('#k-iocs').text(short(total + (st.custom_entries || 0)));
        $('#k-own').text(num(draft.ioc.custom.length));
        $('#jdd-n-ioc').text(feeds.length + (draft.ioc.custom.length ? 1 : 0));
        $('#jdd-n-siem').text(draft.siem.filter((t) => t.enabled).length);
    }

    function renderChart() {
        const el = $('#jdd-chart');
        const W = Math.max(300, el.width() || 600), H = 190, L = 44, R = 8, T = 10, B = 22;
        const now = st.stats.time || Date.now() / 1000;
        const from = now - range * 3600;
        const hist = (st.stats.history || []).filter((h) => h.t >= from);
        if (hist.length < 2) {
            el.html('<div class="jdd-empty" style="padding-top:60px"><i class="fa fa-area-chart"></i>Данные появятся через пару минут после включения защиты</div>');
            return;
        }
        const peak = Math.max(10, ...hist.map((h) => Math.max(h.rate_block || 0, h.rate_new || 0)));
        const step = Math.pow(10, Math.floor(Math.log10(peak / 3)));
        const unit = [1, 2, 2.5, 5, 10].map((m) => m * step).find((u) => u * 3 >= peak) || step * 10;
        const max = unit * 3 * 1.08;
        const x = (t) => L + (t - from) / (now - from) * (W - L - R);
        const y = (v) => T + (1 - v / max) * (H - T - B);
        let svg = `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none">`;
        // attack / elevated bands
        hist.forEach((h, i) => {
            if (h.level === 'attack' || h.level === 'elevated') {
                const x0 = x(i ? hist[i - 1].t : h.t - 60), x1 = x(h.t);
                svg += `<rect x="${x0.toFixed(1)}" y="${T}" width="${Math.max(1, x1 - x0).toFixed(1)}" height="${H - T - B}" fill="${h.level === 'attack' ? 'rgba(229,32,46,.20)' : 'rgba(245,165,36,.14)'}"/>`;
            }
        });
        for (let k = 0; k <= 3; k++) {
            const v = unit * k, yy = y(v);
            svg += `<line x1="${L}" x2="${W - R}" y1="${yy.toFixed(1)}" y2="${yy.toFixed(1)}" stroke="#232329"/>`;
            svg += `<text x="${L - 6}" y="${(yy + 3.5).toFixed(1)}" text-anchor="end">${short(v)}</text>`;
        }
        const ticks = W < 520 ? 3 : 6;
        for (let k = 0; k <= ticks; k++) {
            const t = from + (now - from) * k / ticks;
            svg += `<text x="${x(t).toFixed(1)}" y="${H - 5}" text-anchor="${k === 0 ? 'start' : k === ticks ? 'end' : 'middle'}">${new Date(t * 1000).toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'})}</text>`;
        }
        const path = (k) => hist.map((h, i) => `${i ? 'L' : 'M'}${x(h.t).toFixed(1)},${y(h[k] || 0).toFixed(1)}`).join('');
        svg += `<path d="${path('rate_block')} L${x(hist[hist.length - 1].t).toFixed(1)},${y(0).toFixed(1)} L${x(hist[0].t).toFixed(1)},${y(0).toFixed(1)}Z" fill="rgba(255,59,71,.16)"/>`;
        svg += `<path d="${path('rate_block')}" fill="none" stroke="#ff3b47" stroke-width="1.8" stroke-linejoin="round"/>`;
        svg += `<path d="${path('rate_new')}" fill="none" stroke="#d6d6dc" stroke-width="1.3" stroke-dasharray="3 3" opacity=".8"/>`;
        svg += '</svg>';
        el.html(svg);
        $('#jdd-range span').each(function () { $(this).toggleClass('sel', Number($(this).data('h')) === range); });
    }

    function renderIfs() {
        const ifs = st.interfaces.slice().sort((a, b) => (b.wan - a.wan) || a.descr.localeCompare(b.descr));
        const html = ifs.map((i) => {
            const d = ifDraft(i.name);
            const on = !!(d && d.enabled);
            const lim = d ? levelLimits(d) : null;
            const sub = [i.address, i.device, i.wan ? 'внешний' : 'внутренний'].filter(Boolean).join(' · ');
            let body = '';
            if (on) {
                const custom = d.level === 'custom';
                const cell = (k, label, unit) => custom
                    ? `<div><div class="l">${label}</div><input class="jdd-in" data-lim="${k}" data-if="${esc(i.name)}" value="${esc(d[k] || lim[k])}" inputmode="numeric"/></div>`
                    : `<div><div class="l">${label}</div><div class="v">${num(lim[k])}<small>${unit}</small></div></div>`;
                const tcp = i.rules.filter((r) => r.tcp).length;
                const rules = i.rules.length ? i.rules.map((r) => `<div class="jdd-rule ${r.limited ? 'lim' : ''}">
                        <i class="fa ${r.limited ? 'fa-check-circle' : 'fa-circle-o'}"></i>
                        <span class="rn">${esc(r.description || 'Правило без описания')}</span>
                        <span class="rs">${esc(r.protocol)}${r.port ? ' · ' + esc(r.port) : ''}${r.tcp ? '' : ' · только лимит соединений'}</span></div>`).join('')
                    : '<div class="muted" style="font-size:12px">На этом интерфейсе нет правил, открытых для всего интернета. Защиту дают чёрный список, SYN cookies и тайм-ауты.</div>';
                body = `<div class="jdd-if-body">
                    <div class="jdd-lv">${['light', 'standard', 'strict', 'custom'].map((l) => `<span data-lv="${l}" data-if="${esc(i.name)}" class="${d.level === l ? 'sel' : ''}">${LEVEL_NAMES[l]}</span>`).join('')}</div>
                    <div class="jdd-lim">
                      ${cell('states', 'Соединений с адреса', 'макс')}
                      ${cell('rate', 'Новых TCP за ' + (custom ? 'период' : lim.per + ' с'), 'шт')}
                      ${cell('conns', 'Открытых TCP с адреса', 'макс')}
                    </div>
                    ${custom ? `<div class="jdd-tg" style="padding-bottom:0"><div class="tx"><b>SYN-прокси</b><span>Межсетевой экран сам завершает TCP-рукопожатие и только потом пропускает соединение.</span></div>
                        <span class="jdd-sw ${d.synproxy ? 'on' : ''}" data-syn="${esc(i.name)}" role="switch" tabindex="0"></span></div>` : ''}
                    <div class="jdd-rules"><div class="muted" style="font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; margin-bottom:4px">
                      Открытые правила: ${i.rules.length}${tcp ? ` · TCP: ${tcp}` : ''}</div>${rules}
                      ${i.rdrpass ? `<div class="jdd-note warn" style="margin-top:8px"><i class="fa fa-exclamation-triangle"></i><div>Проброс портов без своего правила: ${i.rdrpass}.
                        Лимиты на них не ставятся: в пробросе выберите связанное правило «Manual» и добавьте обычное правило пропуска.</div></div>` : ''}
                    </div></div>`;
            }
            return `<div class="jdd-if ${on ? 'on' : ''}">
                <div class="jdd-if-top">
                  <div class="jdd-if-ic"><i class="fa ${i.wan ? 'fa-globe' : 'fa-sitemap'}"></i></div>
                  <div class="jdd-if-m"><div class="jdd-if-n">${esc(i.descr)}${on && i.limited ? ` <span class="jdd-chip ok">защищено правил: ${i.limited}</span>` : ''}</div>
                    <div class="jdd-if-s mono">${esc(sub)}</div></div>
                  <span class="jdd-sw ${on ? 'on' : ''}" data-ifon="${esc(i.name)}" role="switch" tabindex="0" aria-label="${esc(i.descr)}"></span>
                </div>${body}</div>`;
        }).join('');
        $('#jdd-ifs').html(html || '<div class="jdd-empty">Нет интерфейсов</div>');
    }

    function renderBlocked() {
        const items = (st.stats.blocked || []).slice().sort((a, b) => (b.since || 0) - (a.since || 0));
        const bt = parseInt(draft.general.blocktime, 10) * 60;
        if (!items.length) {
            $('#jdd-blocked').html('<div class="jdd-empty"><i class="fa fa-check-circle"></i>Сейчас никто не заблокирован</div>');
        } else {
            const left = (e) => {
                if (!e.since) { return '—'; }
                const s = e.since + bt - Date.now() / 1000;
                if (s <= 60) { return '&lt; 1 мин'; }
                return s < 3600 ? Math.round(s / 60) + ' мин' : (s / 3600).toFixed(1).replace('.', ',') + ' ч';
            };
            $('#jdd-blocked').html(`<table class="jdd-tbl"><thead><tr><th>Адрес</th><th>С</th><th>Отброшено</th><th>Осталось</th><th></th></tr></thead><tbody>
                ${items.slice(0, 50).map((e) => `<tr><td class="mono"><b>${esc(e.address)}</b></td><td class="muted">${e.since ? esc(ago(e.since)) : '—'}</td>
                  <td>${num(e.packets)}</td><td class="muted">${left(e)}</td>
                  <td><button class="jdd-btn ghost sm" data-unblock="${esc(e.address)}" title="Освободить"><i class="fa fa-unlock"></i></button></td></tr>`).join('')}
                </tbody></table>${items.length > 50 ? `<div class="muted" style="margin-top:8px">и ещё ${items.length - 50}</div>` : ''}`);
        }
        $('#jdd-unblock-all').toggle(items.length > 0);
        const BT = {'10': '10 минут', '60': 'час', '360': '6 часов', '1440': 'сутки', '10080': 'неделю'};
        $('#jdd-block-h').text(`Ручная блокировка действует ${BT[draft.general.blocktime] || draft.general.blocktime + ' мин'}, как и автоматическая. Навсегда — в поле «Всегда блокировать».`);
    }

    function eventText(e) {
        const a = `<b class="mono">${esc(e.address || '')}</b>`;
        switch (e.code) {
            case 'limit': return [`${a} превысил лимит соединений и заблокирован`, 'bad', 'fa-ban'];
            case 'manual': return [`${a} заблокирован вручную`, 'bad', 'fa-ban'];
            case 'syn': return [`Отражён SYN-флуд: ${num(e.count)} SYN cookies за минуту`, 'bad', 'fa-bolt'];
            case 'flood': return [`Атака: отброшено ${short(e.count)} пакетов в секунду`, 'bad', 'fa-bolt'];
            case 'table': return [`Таблица соединений заполнена на ${e.count} %`, 'warn', 'fa-database'];
            case 'over': return ['Атака закончилась', 'ok', 'fa-check'];
            case 'release': return [`${a} освобождён вручную`, 'ok', 'fa-unlock'];
            case 'release_all': return ['Чёрный список очищен', 'ok', 'fa-eraser'];
            default: return [esc(e.text), '', 'fa-info'];
        }
    }
    function renderEvents() {
        const ev = (st.stats.events || []).slice(0, 12);
        $('#jdd-events').html(ev.length ? ev.map((e) => {
            const [t, cls, ic] = eventText(e);
            return `<div class="jdd-ev ${cls}"><div class="ei"><i class="fa ${ic}"></i></div><div class="et">${t}<div class="ew">${esc(when(e.time))}</div></div></div>`;
        }).join('') : '<div class="jdd-empty"><i class="fa fa-moon-o"></i>Событий пока нет</div>');
    }

    function renderSettings() {
        const g = draft.general;
        $('#jdd-en').toggleClass('on', g.enabled);
        $('#jdd-en-t').text(g.enabled ? 'Включено' : 'Выключено');
        $('#jdd-preset .jdd-opt').each(function () { $(this).toggleClass('sel', $(this).data('p') === g.preset); });
        if (!$('#jdd-cookies').is(':focus')) { $('#jdd-cookies').val(g.syncookies); }
        $('#jdd-adaptive').toggleClass('on', g.adaptive);
        $('#jdd-aggr').toggleClass('on', g.optimization === 'aggressive');
        if (!$('#jdd-icmp').is(':focus')) { $('#jdd-icmp').val(g.icmplimit); }
        $('#jdd-bogons').toggleClass('on', g.bogons);
        const priv = st.interfaces.some((i) => ifDraft(i.name) && ifDraft(i.name).enabled && i.private);
        $('#jdd-bogons-h').html(priv
            ? '<span style="color:var(--warn)">Внешний интерфейс в частной сети (за роутером): включайте, только если провайдер даёт белый адрес напрямую.</span>'
            : 'Пакеты из зарезервированных диапазонов (bogons), которые бывают только у подделанных отправителей.');
        const bt = String(g.blocktime);
        if (!$('#jdd-blocktime option[value="' + bt + '"]').length) {
            $('#jdd-blocktime').append(`<option value="${esc(bt)}">${esc(bt)} мин</option>`);
        }
        $('#jdd-blocktime').val(bt);
        if (!$('#jdd-allow').is(':focus')) { $('#jdd-allow').val(g.allow.join('\n')); }
        if (!$('#jdd-deny').is(':focus')) { $('#jdd-deny').val(g.deny.join('\n')); }
        const me = st.admin_address;
        $('#jdd-allow-h').html(me && !g.allow.includes(me)
            ? `Ваш адрес сейчас <span class="mono">${esc(me)}</span> — <a class="lnk" href="#" id="jdd-add-me">добавить</a>, чтобы не заблокировать себя.`
            : 'Офис, мониторинг, партнёры. Отдельные адреса не попадут в список; сети освобождаются в течение минуты.');
    }

    function renderFeeds() {
        const feeds = draft.ioc.feeds;
        const counts = {};
        (st.feeds || []).forEach((f) => { counts[f.uuid] = f.entries; });
        $('#jdd-feeds').html(feeds.length ? feeds.map((f, idx) => {
            const n = f.uuid != null ? counts[f.uuid] : undefined;
            const host = (f.url.match(/^https?:\/\/([^/]+)/) || [])[1] || f.url;
            return `<div class="jdd-feed ${f.enabled ? '' : 'off'}">
                <div class="ic"><i class="fa fa-crosshairs"></i></div>
                <div class="fm"><div class="fn">${esc(f.name)}</div><div class="fs mono">${esc(host)} · раз в ${esc(f.refresh)} ч</div></div>
                <div class="fc">${n == null ? '<span class="muted">—</span>' : short(n)}<small>${n == null ? (!f.enabled ? 'выключен' : f.uuid ? 'загрузка' : 'после применения') : 'адресов'}</small></div>
                <div class="fa-ctl"><span class="jdd-sw ${f.enabled ? 'on' : ''}" data-feed="${idx}" role="switch" tabindex="0"></span>
                  <button class="jdd-btn ghost sm icon danger" data-feeddel="${idx}" title="Удалить"><i class="fa fa-trash"></i></button></div></div>`;
        }).join('') : '<div class="jdd-empty"><i class="fa fa-crosshairs"></i>Списки не подключены. Выберите готовый ниже или добавьте свой.</div>');
        const have = feeds.map((f) => f.url);
        $('#jdd-cat').html(Object.keys(st.catalog).map((k) => {
            const [name, url, h] = st.catalog[k];
            const added = have.includes(url);
            return `<div class="jdd-opt ${added ? 'added' : ''}" data-cat="${k}"><div class="nm"><i class="fa ${added ? 'fa-check' : 'fa-plus'}"></i>${esc(name)}</div>
                <div class="ds mono">${esc((url.match(/^https?:\/\/([^/]+)/) || [])[1])} · ${h} ч</div></div>`;
        }).join(''));
        if (!$('#jdd-custom').is(':focus')) { $('#jdd-custom').val(draft.ioc.custom.join('\n')); }
        $('#jdd-ioclog').toggleClass('on', draft.ioc.log);
    }

    function renderTargets() {
        $('#jdd-targets').html(draft.siem.length ? draft.siem.map((t, idx) => `<div class="jdd-feed ${t.enabled ? '' : 'off'}">
                <div class="ic"><i class="fa fa-server"></i></div>
                <div class="fm"><div class="fn">${esc(t.name)} <span class="jdd-chip">${FMT_NAMES[t.format]}</span></div>
                  <div class="fs"><span class="mono">${esc(t.host)}:${esc(t.port)}/${t.transport.slice(0, 3).toUpperCase()}</span> · ${t.logs.map((l) => LOG_NAMES[l]).join(', ')}</div></div>
                <div class="fa-ctl">
                  <button class="jdd-btn ghost sm" data-siemtest="${idx}" ${t.uuid ? '' : 'disabled title="Сначала примените"'}><i class="fa fa-paper-plane"></i> Проверить</button>
                  <span class="jdd-sw ${t.enabled ? 'on' : ''}" data-siem="${idx}" role="switch" tabindex="0"></span>
                  <button class="jdd-btn ghost sm icon" data-siemedit="${idx}" title="Изменить"><i class="fa fa-pencil"></i></button>
                  <button class="jdd-btn ghost sm icon danger" data-siemdel="${idx}" title="Удалить"><i class="fa fa-trash"></i></button></div></div>`).join('')
            : '<div class="jdd-empty"><i class="fa fa-share-square-o"></i>Журналы пока никуда не отправляются.<br>Добавьте SIEM или сборщик журналов вашего SOC.</div>');
    }

    let sampleFmt = 'cef';
    function renderSample() {
        const host = 'jk-ufw';
        const s = {
            cef: `<b>&lt;134&gt;Nov 14 18:00:01 ${host}</b> CEF:0|jk-ufw|firewall|1.0|fw-block|Firewall block in|5|act=block deviceDirection=0 deviceInboundInterface=vtnet0 src=203.0.113.9 dst=192.168.31.85 spt=51515 dpt=443 proto=tcp cs1Label=ruleLabel cs1=02f4bab0… cn1Label=ruleNumber cn1=96 rt=1794679201000 dvchost=${host}

<b>&lt;129&gt;Nov 14 18:00:04 ${host}</b> CEF:0|jk-ufw|ids|1.0|1:2010935:3|ET SCAN Suspicious inbound to MSSQL port 1433|7|cat=Potentially Bad Traffic proto=TCP cs2Label=source cs2=198.51.100.4:4444 cs3Label=destination cs3=192.168.31.85:1433 …`,
            json: `<b>&lt;134&gt;Nov 14 18:00:01 ${host} filterlog:</b> {"timestamp":"2026-11-14T18:00:01+05:00","host":"${host}","program":"filterlog","severity":"info","fw":{"action":"block","dir":"in","iface":"vtnet0","proto":"tcp","src":"203.0.113.9","sport":"51515","dst":"192.168.31.85","dport":"443","rule":"96","label":"02f4bab0…"},"message":"96,,,02f4…"}`,
            rfc5424: `<b>&lt;164&gt;1 2026-11-14T18:00:05+05:00 ${host} jkufw-ddos 4242 - -</b> Address 198.51.100.7 blocked: crossed a connection limit`
        };
        $('#jdd-sample').html(s[sampleFmt]);
        $('#jdd-sample-fmt .jdd-cb').each(function () { $(this).toggleClass('sel', $(this).data('f') === sampleFmt); });
    }

    function renderAll() {
        renderHead();
        renderKpis();
        if (!$('#jdd-ifs').find(':focus').length) { renderIfs(); }
        renderBlocked();
        renderEvents();
        renderSettings();
        renderFeeds();
        renderTargets();
        renderSample();
        $('#jdd-apply').prop('disabled', busy);
    }

    // ---- data ---------------------------------------------------------------------------------------
    function showError(msg) {
        $('#jdd-error').toggle(!!msg).find('div').text(msg || '');
    }
    async function load(full) {
        try {
            const tasks = [api('/api/jkufw/ddos/status')];
            if (full) { tasks.push(api('/api/jkufw/ddos/get')); }
            const [s, m] = await Promise.all(tasks);
            st = s;
            if (full) {
                const fresh = fromModel(m);
                if (!draft || !dirty()) { draft = fresh; }
                saved = JSON.stringify(fresh);
            }
            $('#jdd-loading').hide();
            $('#jdd-main').show();
            changed();
            renderChart();
        } catch (e) {
            $('#jdd-loading').hide();
            showError('Не удалось загрузить данные: ' + e.message);
        }
    }

    async function applyAll() {
        if (busy) { return; }
        busy = true;
        showError('');
        $('#jdd-apply').html('<i class="fa fa-spinner fa-pulse"></i> Применяю…').prop('disabled', true);
        try {
            const r = await api('/api/jkufw/ddos/save', toPost(draft));
            if (!r || r.result !== 'saved') {
                const msgs = Object.values((r && r.validations) || {}).map((v) => Array.isArray(v) ? v.join(' ') : v);
                throw new Error(msgs.join(' ') || 'настройки не сохранены');
            }
            const a = await api('/api/jkufw/ddos/apply', {});
            if (!a || a.status !== 'ok') { throw new Error((a && a.status) || 'ошибка применения'); }
            draft = null;
            await load(true);
        } catch (e) {
            showError('Не применено: ' + e.message);
        } finally {
            busy = false;
            $('#jdd-apply').html('<i class="fa fa-check"></i> Применить');
            if (draft) { changed(); }
        }
    }

    // ---- events -------------------------------------------------------------------------------------
    const toggle = (sel, fn) => $(document).on('click keydown', sel, function (e) {
        if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; }
        e.preventDefault();
        fn.call(this, $(this));
        changed();
    });
    $('#jdd-tabs').on('click', '.jdd-tab', function () {
        const t = $(this).data('tab');
        $('.jdd-tab').removeClass('sel'); $(this).addClass('sel');
        $('.jdd-pane').removeClass('sel'); $(`.jdd-pane[data-pane="${t}"]`).addClass('sel');
        store.set('jdd-tab', t);
        if (t === 'ddos') { renderChart(); }
    });
    $('#jdd-range').on('click', 'span', function () { range = Number($(this).data('h')); store.set('jdd-range', range); renderChart(); });
    $('#jdd-intro-go').on('click', () => { enable(true); changed(); applyAll(); });
    toggle('#jdd-en', () => enable(!draft.general.enabled));
    $('#jdd-preset').on('click', '.jdd-opt', function () { applyPreset($(this).data('p')); changed(); });
    $('#jdd-cookies').on('change', function () { draft.general.syncookies = $(this).val(); draft.general.preset = 'custom'; changed(); });
    toggle('#jdd-adaptive', () => { draft.general.adaptive = !draft.general.adaptive; draft.general.preset = 'custom'; });
    toggle('#jdd-aggr', () => { draft.general.optimization = draft.general.optimization === 'aggressive' ? 'normal' : 'aggressive'; draft.general.preset = 'custom'; });
    toggle('#jdd-bogons', () => { draft.general.bogons = !draft.general.bogons; });
    $('#jdd-icmp').on('input', function () { draft.general.icmplimit = $(this).val().replace(/\D/g, ''); draft.general.preset = 'custom'; $('#jdd-applybar').toggleClass('show', dirty()); })
        .on('blur', changed);
    $('#jdd-blocktime').on('change', function () { draft.general.blocktime = $(this).val(); changed(); });
    $('#jdd-allow').on('input', function () { draft.general.allow = lines($(this).val()); $('#jdd-applybar').toggleClass('show', dirty()); }).on('blur', changed);
    $('#jdd-deny').on('input', function () { draft.general.deny = lines($(this).val()); $('#jdd-applybar').toggleClass('show', dirty()); }).on('blur', changed);
    $(document).on('click', '#jdd-add-me', (e) => { e.preventDefault(); draft.general.allow.push(st.admin_address); changed(); });

    toggle('[data-ifon]', ($el) => {
        const name = $el.data('ifon');
        const d = ifDraft(name);
        if (d) { d.enabled = !d.enabled; } else {
            draft.interfaces.push({interface: name, enabled: true, level: draft.general.preset === 'custom' ? 'standard' : draft.general.preset, states: '', conns: '', rate: '', per: '', synproxy: false});
        }
    });
    $(document).on('click', '[data-lv]', function () {
        const d = ifDraft($(this).data('if'));
        const lv = $(this).data('lv');
        if (lv === 'custom' && d.level !== 'custom') {
            const lim = levelLimits(d);
            Object.assign(d, {states: String(lim.states), conns: String(lim.conns), rate: String(lim.rate), per: String(lim.per), synproxy: lim.synproxy === '1'});
        }
        d.level = lv;
        changed();
    });
    $(document).on('input', '[data-lim]', function () {
        const d = ifDraft($(this).data('if'));
        d[$(this).data('lim')] = $(this).val().replace(/\D/g, '');
        $('#jdd-applybar').toggleClass('show', dirty());
    }).on('blur', '[data-lim]', changed);
    toggle('[data-syn]', ($el) => { const d = ifDraft($el.data('syn')); d.synproxy = !d.synproxy; });

    $(document).on('click', '[data-unblock]', async function () {
        const a = $(this).data('unblock');
        try { await api('/api/jkufw/ddos/unblock', {address: String(a)}); await load(false); } catch (e) { showError(e.message); }
    });
    $('#jdd-unblock-all').on('click', async () => {
        try { await api('/api/jkufw/ddos/unblock', {address: 'ALL'}); await load(false); } catch (e) { showError(e.message); }
    });
    $('#jdd-block').on('click', async () => {
        const a = $('#jdd-block-ip').val().trim();
        if (!a) { return; }
        try {
            const r = await api('/api/jkufw/ddos/block', {address: a});
            if (r.status !== 'ok') { throw new Error(r.message || 'не получилось'); }
            $('#jdd-block-ip').val('');
            await load(false);
        } catch (e) { showError('Не заблокировано: ' + e.message); }
    });

    // threat feeds
    $('#jdd-cat').on('click', '.jdd-opt:not(.added)', function () {
        const [name, url, h] = st.catalog[$(this).data('cat')];
        draft.ioc.feeds.push({enabled: true, name: name, url: url, refresh: String(h)});
        changed();
    });
    $('#jdd-feed-add').on('click', () => {
        const name = $('#jdd-feed-name').val().trim(), url = $('#jdd-feed-url').val().trim();
        if (!name || !/^https?:\/\/\S+$/.test(url)) { showError('Укажите название и адрес списка (https://…).'); return; }
        showError('');
        draft.ioc.feeds.push({enabled: true, name: name, url: url, refresh: '12'});
        $('#jdd-feed-name, #jdd-feed-url').val('');
        changed();
    });
    toggle('[data-feed]', ($el) => { const f = draft.ioc.feeds[$el.data('feed')]; f.enabled = !f.enabled; });
    $(document).on('click', '[data-feeddel]', function () { draft.ioc.feeds.splice($(this).data('feeddel'), 1); changed(); });
    $('#jdd-custom').on('input', function () { draft.ioc.custom = lines($(this).val()); $('#jdd-applybar').toggleClass('show', dirty()); }).on('blur', changed);
    toggle('#jdd-ioclog', () => { draft.ioc.log = !draft.ioc.log; });

    // SIEM
    let editing = null;
    let form = null;
    function openSiem(idx) {
        editing = idx;
        const t = idx == null ? {name: '', host: '', port: '514', transport: 'udp4', format: 'cef', logs: ['firewall', 'ids', 'security', 'auth']} : draft.siem[idx];
        form = {format: t.format, logs: t.logs.slice()};
        $('#js-title').text(idx == null ? 'Новый получатель' : t.name);
        $('#js-name').val(t.name); $('#js-host').val(t.host); $('#js-port').val(t.port); $('#js-tr').val(t.transport);
        $('#js-err').text('');
        renderForm();
        $('#jdd-ov-siem').addClass('open');
        setTimeout(() => $('#js-name').trigger('focus'), 50);
    }
    function renderForm() {
        $('#js-fmt .jdd-opt').each(function () { $(this).toggleClass('sel', $(this).data('f') === form.format); });
        $('#js-logs .jdd-cb').each(function () { $(this).toggleClass('sel', form.logs.includes($(this).data('v'))); });
    }
    $('#js-fmt').on('click', '.jdd-opt', function () { form.format = $(this).data('f'); renderForm(); });
    $('#js-logs').on('click', '.jdd-cb', function () {
        const v = $(this).data('v');
        form.logs = form.logs.includes(v) ? form.logs.filter((x) => x !== v) : form.logs.concat([v]);
        renderForm();
    });
    $('#js-save').on('click', () => {
        const t = {name: $('#js-name').val().trim(), host: $('#js-host').val().trim(), port: $('#js-port').val().trim() || '514',
            transport: $('#js-tr').val(), format: form.format, logs: form.logs};
        if (!t.name) { $('#js-err').text('Укажите название.'); return; }
        if (!/^[A-Za-z0-9.:\-]+$/.test(t.host)) { $('#js-err').text('Укажите IP-адрес или имя сервера.'); return; }
        if (!/^\d+$/.test(t.port) || +t.port < 1 || +t.port > 65535) { $('#js-err').text('Порт — число от 1 до 65535.'); return; }
        if (!t.logs.length) { $('#js-err').text('Выберите, что отправлять.'); return; }
        if (editing == null) { draft.siem.push(Object.assign({enabled: true}, t)); } else { Object.assign(draft.siem[editing], t); }
        $('#jdd-ov-siem').removeClass('open');
        changed();
    });
    $('#jdd-siem-add').on('click', () => openSiem(null));
    $(document).on('click', '[data-siemedit]', function () { openSiem($(this).data('siemedit')); });
    $(document).on('click', '[data-siemdel]', function () { draft.siem.splice($(this).data('siemdel'), 1); changed(); });
    toggle('[data-siem]', ($el) => { const t = draft.siem[$el.data('siem')]; t.enabled = !t.enabled; });
    $(document).on('click', '[data-siemtest]', async function () {
        const t = draft.siem[$(this).data('siemtest')];
        const $b = $(this);
        $b.html('<i class="fa fa-spinner fa-pulse"></i> Отправляю');
        try {
            const r = await api('/api/jkufw/ddos/siemtest', {uuid: t.uuid});
            $b.html(r.status === 'ok' ? '<i class="fa fa-check" style="color:var(--ok)"></i> Отправлено' : '<i class="fa fa-times" style="color:var(--a2)"></i> Ошибка')
                .attr('title', r.message || 'Тестовое событие отправлено, проверьте SIEM');
        } catch (e) {
            $b.html('<i class="fa fa-times"></i> Ошибка').attr('title', e.message);
        }
    });
    $('#jdd-sample-fmt').on('click', '.jdd-cb', function () { sampleFmt = $(this).data('f'); renderSample(); });

    $('#jdd-apply').on('click', applyAll);
    $('#jdd-revert').on('click', () => { draft = JSON.parse(saved); changed(); });
    $('.jdd-ov').on('click', function (e) { if (e.target === this) { $(this).removeClass('open'); } })
        .on('click', '[data-close]', function () { $(this).closest('.jdd-ov').removeClass('open'); });
    $(document).on('keydown', (e) => { if (e.key === 'Escape') { $('.jdd-ov').removeClass('open'); } });
    $(window).on('resize', () => { if (st) { renderChart(); } });

    const tab = store.get('jdd-tab', 'ddos');
    if (tab !== 'ddos') { $(`.jdd-tab[data-tab="${tab}"]`).trigger('click'); }
    load(true);
    setInterval(() => { if (!busy && !document.hidden) { load(false).then(() => renderChart()); } }, POLL_MS);
});
</script>
