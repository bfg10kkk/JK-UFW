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
 # jk-ufw: WAF. Web servers inside the network that are open to the internet get a guard in front:
 # the firewall answers for their names on 80/443 and checks every request (SQL injection, XSS,
 # path traversal, file inclusion, evasion tricks, dangerous uploads, bad bots) before passing it on.
 # Data comes from /api/jkufw/waf/*, which writes ordinary nginx plugin objects (NAXSI module) and two
 # pass rules (see models/OPNsense/JkUfw/Waf.php).
 #}

<style>
.jwf { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1240px; }
.jwf * { box-sizing:border-box; }
.jwf b, .jwf strong { font-family:inherit; font-weight:700; }
.jwf .mono { font-family:ui-monospace,Menlo,Consolas,monospace; }
.jwf .muted { color:var(--m); }
.jwf a.lnk { color:var(--a2); }
.jwf-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jwf-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:23px; flex:none;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jwf-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jwf-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jwf-sub { color:var(--m); margin-top:2px; }
.jwf-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jwf-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jwf-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jwf-pill.warn i { background:var(--warn); }
.jwf-pill.bad i { background:var(--a); }
.jwf-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jwf-grid { display:grid; grid-template-columns:minmax(0,1.5fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1050px) { .jwf-grid { grid-template-columns:minmax(0,1fr); } }
.jwf-grid > div { min-width:0; }
.jwf-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jwf-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.jwf-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; display:flex; gap:8px; align-items:center; }
.jwf-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 760px) { .jwf-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jwf-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; min-width:0; }
.jwf-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jwf-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jwf-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jwf-kpi .v.ok { color:var(--ok); } .jwf-kpi .v.bad { color:var(--a2); } .jwf-kpi .v.warn { color:var(--warn); }
/* flow diagram */
.jwf-flow { padding:10px 18px 6px; background:radial-gradient(ellipse at 40% 0%,rgba(229,32,46,.10),rgba(229,32,46,0) 60%), var(--s); }
.jwf-flow svg { display:block; width:100%; height:auto; }
.jwf-flow text { font-family:inherit; }
@keyframes jwfflow { to { stroke-dashoffset:-24; } }
.jwf-flow .live { stroke-dasharray:7 5; animation:jwfflow .9s linear infinite; }
@media (prefers-reduced-motion: reduce) { .jwf-flow .live { animation:none; } }
/* link cards */
.jwf-links { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:12px; }
@media (max-width: 640px) { .jwf-links { grid-template-columns:minmax(0,1fr); } }
.jwf-link { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; position:relative; min-width:0; }
.jwf-link.carry { border-color:rgba(229,32,46,.55); box-shadow:inset 0 0 0 1px rgba(229,32,46,.25); }
.jwf-link.off { opacity:.6; }
.jwf-link-top { display:flex; align-items:center; gap:10px; }
.jwf-link-ic { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:16px; flex:none; position:relative; }
.jwf-link.carry .jwf-link-ic { background:var(--abg); color:var(--a2); }
.jwf-link-ic .dot { position:absolute; right:-2px; bottom:-2px; width:11px; height:11px; border-radius:50%; background:#3a3a42; border:2px solid var(--s2); }
.dot.ok { background:var(--ok) !important; } .dot.warn { background:var(--warn) !important; } .dot.bad { background:var(--a) !important; }
.jwf-link-n { font-weight:700; font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jwf-link-s { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jwf-link-m { flex:1; min-width:0; }
.jwf-chip { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; background:#232329; color:var(--m); white-space:nowrap; }
.jwf-chip.acc { background:var(--abg); color:var(--a2); }
.jwf-chip.ok { background:rgba(34,197,94,.12); color:#4ade80; }
.jwf-chip.warn { background:rgba(245,165,36,.12); color:var(--warn); }
.jwf-chip.bad { background:var(--abg); color:#ff6b74; }
.jwf-stats { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; margin:14px 0 8px; }
.jwf-stats .l { color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jwf-stats .v { font-size:18px; font-weight:700; letter-spacing:-.02em; }
.jwf-stats .v small { font-size:11px; color:var(--m); margin-left:2px; font-weight:600; }
.jwf-spark { height:44px; }
.jwf-spark svg { width:100%; height:100%; display:block; }
.jwf-strip { display:flex; gap:2px; margin-top:6px; }
.jwf-strip i { flex:1; height:6px; border-radius:2px; background:#26262c; }
.jwf-strip i.ok { background:rgba(34,197,94,.75); } .jwf-strip i.warn { background:var(--warn); } .jwf-strip i.bad { background:var(--a); }
.jwf-tr { display:flex; gap:14px; margin-top:10px; color:var(--m); font-size:12px; align-items:center; }
.jwf-tr b { color:var(--t); font-weight:600; }
.jwf-util { height:4px; border-radius:2px; background:#26262c; margin-top:8px; overflow:hidden; }
.jwf-util i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); }
/* buttons, fields */
.jwf-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important;
  display:inline-flex; align-items:center; gap:7px; text-decoration:none !important; white-space:nowrap; }
.jwf-btn:hover { background:var(--a2); }
.jwf-btn[disabled] { opacity:.5; cursor:default; }
.jwf-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jwf-btn.ghost:hover { background:var(--h); }
.jwf-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jwf-btn.icon { padding:6px 9px; }
.jwf-btn.danger:hover { color:var(--a2) !important; border-color:rgba(229,32,46,.5); }
.jwf-sw { display:inline-block; vertical-align:middle; flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jwf-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jwf-sw.on { background:var(--a); }
.jwf-sw.on::after { left:16px; background:#fff; }
.jwf-seg { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
.jwf-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; cursor:pointer; transition:all .15s; min-width:0; }
.jwf-opt:hover { border-color:var(--b2); background:var(--h); }
.jwf-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jwf-opt .nm { font-weight:700; font-size:13.5px; }
.jwf-opt .nm .fa { color:var(--m); margin-right:6px; }
.jwf-opt.sel .nm .fa { color:var(--a2); }
.jwf-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jwf-field { margin-bottom:14px; }
.jwf-field > label { display:block; font-weight:600; margin-bottom:6px; }
.jwf-field .hint { color:var(--m); font-size:12px; margin-top:5px; line-height:1.45; }
.jwf input.jwf-in, .jwf select.jwf-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:9px 11px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:12.5px; box-shadow:none !important; }
.jwf input.jwf-in:focus, .jwf select.jwf-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg) !important; }
.jwf input.jwf-in.bad { border-color:var(--a) !important; }
.jwf-row2 { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:12px; }
@media (max-width: 560px) { .jwf-row2, .jwf-seg { grid-template-columns:minmax(0,1fr); } }
.jwf-tg { display:flex; gap:12px; align-items:flex-start; padding:11px 0; border-top:1px solid var(--b); }
.jwf-tg:first-of-type { border-top:0; }
.jwf-tg .tx { flex:1; min-width:0; }
.jwf-tg .tx b { display:block; }
.jwf-tg .tx span { color:var(--m); font-size:12px; line-height:1.45; }
.jwf-order { margin:0; padding:0; list-style:none; }
.jwf-order li { display:flex; align-items:center; gap:10px; padding:9px 10px; border:1px solid var(--b); background:var(--s2); border-radius:10px; margin-bottom:8px; }
.jwf-order li.out { opacity:.55; }
.jwf-order .num { width:24px; height:24px; border-radius:7px; display:grid; place-items:center; font-weight:700; font-size:12px; background:var(--abg); color:var(--a2); flex:none; }
.jwf-order li.out .num { background:#232329; color:var(--m); }
.jwf-order .nm { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jwf-order .nm small { color:var(--m); font-weight:500; margin-left:6px; }
.jwf-order .ctl { display:flex; gap:4px; align-items:center; flex:none; }
.jwf-order .wt { min-width:46px; text-align:center; font-weight:700; }
.jwf-chips { display:flex; gap:8px; flex-wrap:wrap; }
.jwf-cb { display:inline-flex; align-items:center; gap:7px; padding:7px 11px; border:1px solid var(--b); background:var(--s2); border-radius:9px; cursor:pointer; font-weight:600; font-size:12.5px; }
.jwf-cb .fa { color:var(--m); }
.jwf-cb.sel { border-color:var(--a); background:var(--abg); }
.jwf-cb.sel .fa { color:var(--a2); }
.jwf-cb small { color:var(--m); font-weight:500; }
.jwf-pol { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jwf-pol:first-child { border-top:0; padding-top:0; }
.jwf-pol .ic { width:38px; height:38px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jwf-pol.off .ic { background:#202026; color:var(--m); }
.jwf-pol.off .pm { opacity:.6; }
.jwf-pol .pm { flex:1; min-width:0; }
.jwf-pol .pn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jwf-pol .ps { color:var(--m); font-size:11.5px; margin-top:2px; overflow-wrap:anywhere; }
.jwf-pol .arrow { display:flex; align-items:center; gap:6px; flex:none; font-weight:600; }
.jwf-pol .pa { display:flex; gap:6px; align-items:center; flex:none; }
@media (max-width: 560px) { .jwf-pol { flex-wrap:wrap; } .jwf-pol .arrow { order:3; width:100%; padding-left:50px; } }
.jwf-ev { display:flex; gap:11px; padding:9px 0; border-top:1px solid var(--b); }
.jwf-ev:first-child { border-top:0; padding-top:0; }
.jwf-ev .ei { width:28px; height:28px; border-radius:8px; display:grid; place-items:center; flex:none; background:#202026; color:var(--m); font-size:12.5px; }
.jwf-ev.bad .ei { background:var(--abg); color:var(--a2); }
.jwf-ev.ok .ei { background:rgba(34,197,94,.12); color:var(--ok); }
.jwf-ev.warn .ei { background:rgba(245,165,36,.12); color:var(--warn); }
.jwf-ev .et { flex:1; min-width:0; line-height:1.4; }
.jwf-ev .ew { color:var(--m); font-size:11.5px; }
.jwf-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jwf-note .fa { margin-top:2px; }
.jwf-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jwf-note.warn .fa { color:var(--warn); }
.jwf-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jwf-note.err { background:var(--abg); border:1px solid rgba(229,32,46,.4); color:#ffb3b8; }
.jwf-empty { color:var(--m); text-align:center; padding:24px 6px; }
.jwf-empty .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }
.jwf-hero { display:flex; gap:18px; align-items:center; padding:22px; background:linear-gradient(120deg,rgba(229,32,46,.14),rgba(229,32,46,0) 60%), var(--s); }
.jwf-hero .big { font-size:17px; font-weight:700; }
.jwf-hero .ds { color:var(--m); margin-top:4px; line-height:1.5; }
.jwf-applybar { position:sticky; bottom:12px; z-index:5; display:none; align-items:center; gap:12px; padding:12px 14px; margin-bottom:16px;
  background:#1b1114; border:1px solid rgba(229,32,46,.45); border-radius:12px; box-shadow:0 10px 30px rgba(0,0,0,.5); }
.jwf-applybar.show { display:flex; }
.jwf-applybar .tx { flex:1; min-width:0; }
/* modal */
.jwf-ov { max-width:none; font-size:13px; position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.72); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; padding:16px; }
.jwf-ov.open { display:flex; }
.jwf-modal { width:100%; max-width:560px; max-height:calc(100vh - 32px); overflow:auto; background:var(--s); border:1px solid var(--b2); border-radius:14px;
  padding:22px; box-shadow:0 20px 60px rgba(0,0,0,.6); color:var(--t); }
.jwf-modal h4 { margin:0 0 4px; font-size:17px; font-weight:700; }
.jwf-modal .sub { color:var(--m); margin-bottom:16px; line-height:1.5; }
.jwf-modal .ft { display:flex; gap:8px; justify-content:flex-end; margin-top:18px; flex-wrap:wrap; }
.jwf-apps { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; }
@media (max-width: 480px) { .jwf-apps { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jwf-app { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 4px; text-align:center; cursor:pointer; font-size:11.5px; font-weight:600; line-height:1.25; }
.jwf-app .fa { display:block; font-size:18px; margin-bottom:6px; color:var(--m); }
.jwf-app.sel { border-color:var(--a); background:var(--abg); }
.jwf-app.sel .fa { color:var(--a2); }
.jwf-err { color:#ff8a92; font-size:12px; margin-top:10px; }
.jwf-site { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jwf-site:first-child { border-top:0; padding-top:0; }
.jwf-site .ic { width:40px; height:40px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:17px; flex:none; position:relative; }
.jwf-site.off .ic { background:#202026; color:var(--m); }
.jwf-site.off .pm { opacity:.6; }
.jwf-site .pm { flex:1; min-width:0; }
.jwf-site .pn { font-weight:700; font-size:14px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jwf-site .ps { color:var(--m); font-size:11.5px; margin-top:3px; display:flex; gap:6px; flex-wrap:wrap; align-items:center; }
.jwf-site .cnt { text-align:right; flex:none; min-width:64px; }
.jwf-site .cnt b { font-size:18px; display:block; letter-spacing:-.02em; }
.jwf-site .cnt span { color:var(--m); font-size:11px; }
.jwf-site .pa { display:flex; gap:6px; align-items:center; flex:none; }
@media (max-width: 560px) { .jwf-site { flex-wrap:wrap; } .jwf-site .pm { flex:1 1 calc(100% - 52px); }
  .jwf-site .cnt { flex:1; text-align:left; padding-left:52px; display:flex; gap:6px; align-items:baseline; } .jwf-site .cnt b { display:inline; } }
.jwf-bars { display:flex; flex-direction:column; gap:9px; }
.jwf-bar { display:grid; grid-template-columns:130px minmax(0,1fr) 36px; gap:10px; align-items:center; font-size:12.5px; }
.jwf-bar .t { height:8px; border-radius:4px; background:#232329; overflow:hidden; }
.jwf-bar .t i { display:block; height:100%; border-radius:4px; background:linear-gradient(90deg,#a5121c,var(--a2)); }
.jwf-bar .n { text-align:right; font-weight:700; }
.jwf-hours { display:flex; align-items:flex-end; gap:3px; height:64px; margin-top:4px; }
.jwf-hours i { flex:1; background:#26262c; border-radius:3px 3px 0 0; min-height:3px; }
.jwf-hours i.on { background:linear-gradient(180deg,var(--a2),#a5121c); }
.jwf-hl { display:flex; justify-content:space-between; color:var(--m); font-size:10.5px; margin-top:5px; }
.jwf-ip { display:flex; align-items:center; gap:10px; padding:7px 0; border-top:1px solid var(--b); }
.jwf-ip:first-child { border-top:0; }
.jwf-ip .mono { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; }
.jwf-req { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11.5px; color:#c9c9d1; background:#0f0f12; border:1px solid var(--b); border-radius:6px;
  padding:3px 7px; margin-top:4px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jwf-steps { counter-reset:s; margin:0; padding:0; list-style:none; }
.jwf-steps li { display:flex; gap:12px; align-items:center; padding:10px 0; border-top:1px solid var(--b); }
.jwf-steps li:first-child { border-top:0; }
.jwf-steps .num { width:26px; height:26px; border-radius:8px; display:grid; place-items:center; font-weight:700; font-size:12px; background:#232329; color:var(--m); flex:none; }
.jwf-steps li.done .num { background:rgba(34,197,94,.14); color:var(--ok); }
.jwf-steps li.cur .num { background:var(--abg); color:var(--a2); }
.jwf-steps .tx { flex:1; min-width:0; }
.jwf-steps .tx span { display:block; color:var(--m); font-size:12px; }
.jwf-log { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11px; color:var(--m); background:#0f0f12; border:1px solid var(--b); border-radius:8px; padding:8px 10px;
  max-height:120px; overflow:auto; white-space:pre-wrap; margin-top:10px; display:none; }
</style>

<div class="jwf" id="jwf">
  <div class="jwf-head">
    <div class="jwf-logo" id="jwf-logo"><i class="fa fa-shield"></i></div>
    <div>
      <h1 class="jwf-title">Защита сайтов (WAF) <span class="jwf-pill" id="jwf-pill"><i></i><span>…</span></span></h1>
      <div class="jwf-sub">Межсетевой экран веб-приложений: проверяет каждый запрос к вашим сайтам до того, как он дойдёт до сервера</div>
    </div>
    <div class="jwf-head-r">
      <a class="jwf-btn ghost" href="/ui/trust/cert"><i class="fa fa-certificate"></i> Сертификаты</a>
      <a class="jwf-btn ghost" href="/ui/nginx"><i class="fa fa-sliders"></i> Расширенно</a>
    </div>
  </div>

  <div id="jwf-loading" class="jwf-card"><div class="jwf-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></div>
  <div id="jwf-error" class="jwf-note err" style="display:none; margin:0 0 16px"><i class="fa fa-exclamation-circle"></i><div></div></div>

  <div id="jwf-main" style="display:none">
    <div class="jwf-card jwf-hero" id="jwf-setup" style="display:none">
      <div class="jwf-logo on"><i class="fa fa-shield"></i></div>
      <div style="flex:1; min-width:0">
        <div class="big">Подготовка WAF</div>
        <div class="ds">Защита работает на модуле nginx с движком NAXSI и базовыми правилами. Всё ставится и настраивается отсюда.</div>
        <ul class="jwf-steps" id="jwf-steps" style="margin-top:12px"></ul>
        <div class="jwf-log" id="jwf-setup-log"></div>
      </div>
    </div>

    <div id="jwf-notes"></div>

    <div class="jwf-kpis">
      <div class="jwf-kpi"><div class="l">Атак за 24 часа</div><div class="v" id="k-total">—</div></div>
      <div class="jwf-kpi"><div class="l">Заблокировано</div><div class="v bad" id="k-blocked">—</div></div>
      <div class="jwf-kpi"><div class="l">Только замечено</div><div class="v warn" id="k-detected">—</div></div>
      <div class="jwf-kpi"><div class="l">Атакующих адресов</div><div class="v" id="k-ips">—</div></div>
    </div>

    <div class="jwf-applybar" id="jwf-applybar">
      <i class="fa fa-pencil" style="color:var(--a2)"></i>
      <div class="tx"><b>Есть несохранённые изменения.</b> <span class="muted">Они вступят в силу после применения.</span></div>
      <button class="jwf-btn ghost sm" id="jwf-revert">Отменить</button>
      <button class="jwf-btn sm" id="jwf-apply"><i class="fa fa-check"></i> Применить</button>
    </div>

    <div class="jwf-grid">
      <div>
        <div class="jwf-card">
          <h3><i class="fa fa-globe"></i> Защищаемые сайты
            <span class="r"><button class="jwf-btn sm" id="jwf-add"><i class="fa fa-plus"></i> Добавить сайт</button></span></h3>
          <div id="jwf-sites"></div>
        </div>
        <div class="jwf-card">
          <h3><i class="fa fa-bolt"></i> Последние атаки <span class="r muted" id="jwf-poll"></span></h3>
          <div id="jwf-events"></div>
        </div>
      </div>
      <div>
        <div class="jwf-card">
          <h3><i class="fa fa-cogs"></i> Настройки
            <span class="r"><span class="muted" id="jwf-en-t">Выключено</span><span class="jwf-sw" id="jwf-en" role="switch" tabindex="0" aria-label="WAF"></span></span></h3>
          <div class="jwf-field">
            <label>Где сайты доступны снаружи</label>
            <div class="jwf-chips" id="jwf-ifs"></div>
            <div class="hint">На этих интерфейсах откроются порты ниже, только к адресу самого экрана.</div>
          </div>
          <div class="jwf-row2">
            <div class="jwf-field"><label for="jwf-http">Порт HTTP</label><input class="jwf-in" id="jwf-http" type="text" inputmode="numeric"/></div>
            <div class="jwf-field"><label for="jwf-https">Порт HTTPS</label><input class="jwf-in" id="jwf-https" type="text" inputmode="numeric"/></div>
          </div>
          <div class="jwf-field"><label for="jwf-trusted">Доверенные адреса</label>
            <input class="jwf-in mono" id="jwf-trusted" type="text" placeholder="203.0.113.7, 10.0.0.0/8"/>
            <div class="hint">Запросы с них не проверяются: офис, мониторинг, свой сканер уязвимостей.</div></div>
        </div>
        <div class="jwf-card">
          <h3><i class="fa fa-bar-chart"></i> Типы атак за 24 часа</h3>
          <div class="jwf-bars" id="jwf-cats"></div>
          <div class="jwf-hours" id="jwf-hours"></div>
          <div class="jwf-hl"><span>24 ч назад</span><span>12 ч</span><span>сейчас</span></div>
        </div>
        <div class="jwf-card">
          <h3><i class="fa fa-user-secret"></i> Самые активные атакующие</h3>
          <div id="jwf-ips"></div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- site editor -->
<div class="jwf jwf-ov" id="jwf-ov-site" role="dialog" aria-modal="true">
  <div class="jwf-modal">
    <h4 id="js-title">Новый сайт</h4>
    <div class="sub">Экран будет отвечать на эти имена и передавать проверенные запросы на внутренний сервер. В DNS имена должны указывать на внешний адрес экрана.</div>
    <div class="jwf-field"><label for="js-domains">Адреса сайта</label>
      <input class="jwf-in mono" id="js-domains" type="text" placeholder="shop.example.com, www.example.com"/></div>
    <div class="jwf-field"><label for="js-backend">Внутренний сервер</label>
      <input class="jwf-in mono" id="js-backend" type="text" placeholder="http://192.168.1.20:8080"/>
      <div class="hint">Адрес, по которому сайт открывается внутри сети.</div></div>
    <div class="jwf-field"><label for="js-cert">Сертификат HTTPS</label>
      <select class="jwf-in" id="js-cert"></select>
      <div class="hint">Без сертификата сайт работает только по HTTP. Бесплатный сертификат Let's Encrypt можно выпустить в модуле ACME.</div></div>
    <div class="jwf-field"><label>Что делать с атаками</label>
      <div class="jwf-seg" id="js-mode">
        <div class="jwf-opt" data-mode="detect"><div class="nm"><i class="fa fa-eye"></i>Только наблюдать</div>
          <div class="ds">Атаки записываются, но проходят. Хорошо для первых дней: видно, не мешают ли правила самому сайту.</div></div>
        <div class="jwf-opt" data-mode="block"><div class="nm"><i class="fa fa-ban"></i>Блокировать</div>
          <div class="ds">Опасный запрос не доходит до сервера, атакующий получает страницу «Доступ запрещён».</div></div>
      </div></div>
    <div class="jwf-field"><label>Проверки</label>
      <div class="jwf-chips" id="js-rules">
        <span class="jwf-cb" data-v="sqli"><i class="fa fa-database"></i>SQL-инъекции</span>
        <span class="jwf-cb" data-v="xss"><i class="fa fa-code"></i>XSS</span>
        <span class="jwf-cb" data-v="traversal"><i class="fa fa-folder-open"></i>Обход каталогов</span>
        <span class="jwf-cb" data-v="rfi"><i class="fa fa-external-link"></i>Подключение чужих файлов</span>
        <span class="jwf-cb" data-v="evade"><i class="fa fa-user-secret"></i>Обход защиты</span>
        <span class="jwf-cb" data-v="uploads"><i class="fa fa-upload"></i>Опасные загрузки</span>
      </div></div>
    <div class="jwf-tg"><div class="tx"><b>Только HTTPS</b><span>Перенаправлять HTTP на HTTPS. Нужен сертификат.</span></div><span class="jwf-sw" id="js-https" role="switch" tabindex="0"></span></div>
    <div class="jwf-tg"><div class="tx"><b>Отсекать ботов-сканеров</b><span>sqlmap, nikto, masscan и другие известные сканеры уязвимостей.</span></div><span class="jwf-sw" id="js-bots" role="switch" tabindex="0"></span></div>
    <div class="jwf-tg"><div class="tx"><b>WebSocket</b><span>Для чатов, панелей и приложений с живым обновлением.</span></div><span class="jwf-sw" id="js-ws" role="switch" tabindex="0"></span></div>
    <div class="jwf-field" style="margin-top:10px"><label for="js-body">Максимальный размер загрузки, МБ</label>
      <input class="jwf-in" id="js-body" type="text" inputmode="numeric" style="max-width:140px !important"/></div>
    <div class="jwf-err" id="js-err"></div>
    <div class="ft">
      <button class="jwf-btn ghost danger" id="js-del" style="margin-right:auto"><i class="fa fa-trash"></i> Удалить</button>
      <button class="jwf-btn ghost" data-close>Отмена</button>
      <button class="jwf-btn" id="js-save"><i class="fa fa-check"></i> Сохранить</button>
    </div>
  </div>
</div>

<script>
'use strict';
$(function () {
    const POLL_MS = 15000;
    const CATS = {
        sqli: ['fa-database', 'SQL-инъекция'], xss: ['fa-code', 'XSS'], traversal: ['fa-folder-open', 'Обход каталогов'],
        rfi: ['fa-external-link', 'Чужой файл (RFI)'], evade: ['fa-user-secret', 'Обход защиты'], uploads: ['fa-upload', 'Опасная загрузка'],
        protocol: ['fa-exclamation-triangle', 'Битый запрос'], custom: ['fa-filter', 'Своё правило']
    };
    const ALL_RULES = ['sqli', 'xss', 'traversal', 'rfi', 'evade', 'uploads'];

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error((x.responseJSON && x.responseJSON.errorMessage) || (x.status + ' ' + (x.statusText || '')))));
    });
    const saved = (r, what) => {
        if (!r || r.result !== 'saved') {
            const msg = Object.values((r && r.validations) || {}).join(' ');
            throw new Error((what ? what + ': ' : '') + (msg || 'не сохранено'));
        }
        return r;
    };
    const pick = (v) => {
        if (v == null) { return ''; }
        if (typeof v !== 'object') { return String(v); }
        return Object.keys(v).filter((k) => String(v[k].selected) === '1').join(',');
    };
    const list = (v) => pick(v).split(',').filter(Boolean);
    const ago = (t) => {
        const s = Math.max(0, Math.round(Date.now() / 1000 - t));
        if (s < 60) { return 'только что'; }
        if (s < 3600) { return Math.floor(s / 60) + ' мин назад'; }
        if (s < 86400) { return Math.floor(s / 3600) + ' ч назад'; }
        return new Date(t * 1000).toLocaleDateString('ru-RU');
    };
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const swKey = (h) => function (e) { if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; } e.preventDefault(); h.call(this, e); };

    let st = null, model = null, draft = null, base = null, busy = false, pendingSites = false;

    const fromModel = () => {
        const g = model.waf.general;
        return {enabled: String(g.enabled) === '1', interfaces: list(g.interfaces), http_port: pick(g.http_port), https_port: pick(g.https_port),
            trusted: list(g.trusted).join(', ')};
    };
    const dirty = () => JSON.stringify(draft) !== JSON.stringify(base) || pendingSites;
    const markDirty = () => { $('#jwf-applybar').toggleClass('show', dirty()); renderSettings(); renderHead(); };
    const sites = () => Object.entries((model.waf.sites && model.waf.sites.site) || {}).map(([uuid, s]) => ({
        uuid, enabled: String(s.enabled) === '1', domains: list(s.domains), backend: pick(s.backend), certificate: pick(s.certificate),
        https_only: String(s.https_only) === '1', mode: pick(s.mode) || 'detect', rules: list(s.rules), bots: String(s.bots) === '1',
        websocket: String(s.websocket) === '1', max_body: pick(s.max_body) || '20'
    }));
    const certName = (ref) => { const c = (st.certificates || []).find((x) => x.refid === ref); return c ? (c.descr || c.cn) : ''; };
    const nginx = () => st.components[0];

    // ---- rendering ------------------------------------------------------------------------------
    function renderHead() {
        const on = base.enabled && st.applied > 0 && nginx().running;
        const p = $('#jwf-pill').removeClass('ok warn bad');
        if (!nginx().installed) { p.addClass('warn').find('span').text('Не установлено'); }
        else if (!base.enabled) { p.find('span').text('Выключено'); }
        else if (!nginx().running) { p.addClass('bad').find('span').text('nginx не запущен'); }
        else if (on) { p.addClass('ok').find('span').text('Защищает ' + sites().filter((s) => s.enabled).length + ' сайт(а)'); }
        else { p.addClass('warn').find('span').text('Не применено'); }
        $('#jwf-logo').toggleClass('on', on);
    }

    function renderSetup() {
        const n = nginx();
        const steps = [
            [n.installed, 'Модуль nginx', 'Пакет os-nginx из официального репозитория', 'install', 'Установить'],
            [st.rules_loaded, 'Базовые правила NAXSI', 'Около 45 сигнатур атак, загрузка с GitHub', 'rules', 'Загрузить'],
            [!st.gui.conflict.length, 'Свободные порты ' + draft.http_port + ' и ' + draft.https_port,
                st.gui.conflict.length ? 'Сейчас их занимает панель управления экрана' : 'Панель управления на порту ' + st.gui.port, 'gui', 'Перенести панель на 8443']
        ];
        const cur = steps.findIndex((s) => !s[0]);
        $('#jwf-setup').toggle(cur !== -1);
        $('#jwf-steps').html(steps.map((s, i) => `<li class="${s[0] ? 'done' : (i === cur ? 'cur' : '')}">
            <span class="num">${s[0] ? '<i class="fa fa-check"></i>' : i + 1}</span>
            <div class="tx"><b>${esc(s[1])}</b><span>${esc(s[2])}</span></div>
            ${!s[0] && i === cur ? `<button class="jwf-btn sm" data-step="${s[3]}">${esc(s[4])}</button>` : ''}</li>`).join(''));
    }

    function renderNotes() {
        const notes = [];
        (st.forwards || []).forEach((f) => notes.push(['warn', 'fa-exclamation-triangle',
            `Проброс порта ${f.port} на ${esc(f.target)}${f.descr ? ' («' + esc(f.descr) + '»)' : ''} отправляет запросы мимо WAF. Удалите его в <a class="lnk" href="/ui/firewall/d_nat">Firewall › NAT</a>, когда сайт будет добавлен здесь.`]));
        if (st.other_sites) {
            notes.push(['info', 'fa-info-circle', `В модуле nginx есть ещё ${st.other_sites} сервер(а), настроенных вручную. Страница их не трогает.`]);
        }
        $('#jwf-notes').html(notes.map((n) => `<div class="jwf-note ${n[0]}" style="margin:0 0 16px"><i class="fa ${n[1]}"></i><div>${n[2]}</div></div>`).join(''));
    }

    function renderKpis() {
        const s = st.stats;
        $('#k-total').text(s.total); $('#k-blocked').text(s.blocked); $('#k-detected').text(s.detected); $('#k-ips').text(s.attackers);
    }

    function renderSites() {
        const ls = sites();
        if (!ls.length) {
            $('#jwf-sites').html('<div class="jwf-empty"><i class="fa fa-globe"></i>Сайтов пока нет. Добавьте веб-сервер, который открыт в интернет: интернет-магазин, почту в браузере, CRM.</div>');
            return;
        }
        $('#jwf-sites').html(ls.map((s) => {
            const c = st.sites[s.uuid] || {blocked: 0, detected: 0};
            const n = c.blocked + c.detected;
            const tls = s.certificate ? `<span class="jwf-chip ok"><i class="fa fa-lock"></i>HTTPS</span>` : `<span class="jwf-chip warn"><i class="fa fa-unlock"></i>только HTTP</span>`;
            const mode = s.mode === 'block' ? `<span class="jwf-chip acc"><i class="fa fa-ban"></i>блокирует</span>` : `<span class="jwf-chip"><i class="fa fa-eye"></i>наблюдает</span>`;
            return `<div class="jwf-site ${s.enabled ? '' : 'off'}">
              <div class="ic"><i class="fa fa-globe"></i></div>
              <div class="pm"><div class="pn">${esc(s.domains.join(', '))}</div>
                <div class="ps">${mode}${tls}<span class="mono">→ ${esc(s.backend)}</span><span>${s.rules.length} из 6 проверок</span></div></div>
              <div class="cnt"><b class="${n ? 'bad' : ''}" style="${n ? 'color:var(--a2)' : ''}">${n}</b><span>атак за 24 ч</span></div>
              <div class="pa"><span class="jwf-sw ${s.enabled ? 'on' : ''}" data-toggle="${s.uuid}" role="switch" tabindex="0"></span>
                <button class="jwf-btn ghost sm icon" data-edit="${s.uuid}" title="Изменить"><i class="fa fa-pencil"></i></button></div></div>`;
        }).join(''));
    }

    function renderEvents() {
        const ev = st.events || [];
        if (!ev.length) {
            $('#jwf-events').html('<div class="jwf-empty"><i class="fa fa-check-circle"></i>За последние сутки атак не было.</div>');
            return;
        }
        $('#jwf-events').html(ev.slice(0, 10).map((e) => {
            const c = CATS[e.category] || CATS.custom;
            return `<div class="jwf-ev ${e.blocked ? 'bad' : 'warn'}"><div class="ei"><i class="fa ${c[0]}"></i></div>
              <div class="et"><b>${esc(c[1])}</b> ${e.blocked ? '<span class="jwf-chip bad">заблокировано</span>' : '<span class="jwf-chip warn">пропущено, режим наблюдения</span>'}
                <div class="ew"><span class="mono">${esc(e.ip)}</span> → ${esc(e.server)} · ${esc(e.where.join(', ') || e.uri)} · ${ago(e.time)}</div>
                <div class="jwf-req" title="${esc(e.request)}">${esc(e.request || e.uri)}</div></div></div>`;
        }).join(''));
    }

    function renderStats() {
        const by = st.stats.by_category || {};
        const keys = Object.keys(by).sort((a, b) => by[b] - by[a]);
        const max = Math.max(1, ...Object.values(by));
        $('#jwf-cats').html(keys.length ? keys.map((k) => `<div class="jwf-bar"><span>${esc((CATS[k] || CATS.custom)[1])}</span>
            <div class="t"><i style="width:${Math.max(3, by[k] / max * 100)}%"></i></div><span class="n">${by[k]}</span></div>`).join('')
            : '<div class="muted">Нет данных за сутки.</div>');
        const h = st.stats.hourly || [];
        const hm = Math.max(1, ...h);
        $('#jwf-hours').html(h.map((v, i) => `<i class="${v ? 'on' : ''}" style="height:${v ? Math.max(8, v / hm * 100) : 4}%" title="${24 - i} ч назад: ${v}"></i>`).join(''));
        const ips = st.stats.top_ips || [];
        $('#jwf-ips').html(ips.length ? ips.map((x) => `<div class="jwf-ip"><span class="mono">${esc(x.ip)}</span><span class="jwf-chip bad">${x.count}</span>
            <a class="jwf-btn ghost sm" href="/ui/diagnostics/firewall/states#${encodeURIComponent(x.ip)}" title="Соединения"><i class="fa fa-search"></i></a></div>`).join('')
            : '<div class="muted">Никто не атаковал.</div>');
    }

    function renderSettings() {
        $('#jwf-en').toggleClass('on', draft.enabled);
        $('#jwf-en-t').text(draft.enabled ? 'Включено' : 'Выключено');
        $('#jwf-ifs').html(st.interfaces.map((i) => `<span class="jwf-cb ${draft.interfaces.includes(i.name) ? 'sel' : ''}" data-if="${esc(i.name)}">
            <i class="fa ${i.wan ? 'fa-globe' : 'fa-sitemap'}"></i>${esc(i.descr)}</span>`).join(''));
        ['http_port', 'https_port'].forEach((k) => { const $i = $(k === 'http_port' ? '#jwf-http' : '#jwf-https'); if (!$i.is(':focus')) { $i.val(draft[k]); } });
        if (!$('#jwf-trusted').is(':focus')) { $('#jwf-trusted').val(draft.trusted); }
    }

    function renderAll() {
        renderHead(); renderSetup(); renderNotes(); renderKpis(); renderSites(); renderEvents(); renderStats(); renderSettings();
    }

    async function loadAll(keepDraft) {
        [st, model] = await Promise.all([api('/api/jkufw/waf/status'), api('/api/jkufw/waf/get')]);
        base = fromModel();
        if (!keepDraft || !draft) { draft = JSON.parse(JSON.stringify(base)); }
    }

    async function refresh() {
        try {
            st = await api('/api/jkufw/waf/status');
            $('#jwf-error').hide();
            renderHead(); renderSetup(); renderNotes(); renderKpis(); renderSites(); renderEvents(); renderStats();
            $('#jwf-poll').text('обновлено ' + new Date().toLocaleTimeString('ru-RU'));
        } catch (e) { showErr('Нет ответа от экрана: ' + e.message); }
    }
    const showErr = (m) => $('#jwf-error').show().find('div').text(m);
    const log = (t) => $('#jwf-setup-log').show().text(t);

    // ---- setup steps ----------------------------------------------------------------------------
    async function install(pkg) {
        await api('/api/core/firmware/install/' + pkg, {});
        for (let i = 0; i < 300; i++) {
            await sleep(2000);
            const r = await api('/api/core/firmware/upgradestatus');
            log((r.log || '').split('\n').slice(-6).join('\n'));
            if (r.status === 'done') { return; }
            if (r.status === 'error') { throw new Error('установка не удалась, см. Система › Прошивка › Журнал'); }
        }
        throw new Error('установка идёт слишком долго');
    }
    $('#jwf-steps').on('click', '[data-step]', async function () {
        const $b = $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i> Подождите…');
        try {
            const step = $(this).data('step');
            if (step === 'install') { await install('os-nginx'); }
            if (step === 'rules') {
                const r = await api('/api/jkufw/waf/rules', {});
                if (r.status !== 'ok') { throw new Error('правила не загрузились: нет доступа к GitHub?'); }
            }
            if (step === 'gui') {
                const r = await api('/api/jkufw/waf/movegui', {port: 8443});
                if (r.status !== 'ok') { throw new Error('порт не изменён'); }
                log('Панель переезжает на порт ' + r.port + '. Через несколько секунд откроется новый адрес…');
                setTimeout(() => { location.href = r.protocol + '://' + location.hostname + ':' + r.port + location.pathname; }, 6000);
                return;
            }
            await loadAll(true); renderAll();
        } catch (e) { showErr(e.message); await loadAll(true); renderAll(); }
    });

    // ---- apply ----------------------------------------------------------------------------------
    async function applyAll() {
        if (busy) { return; }
        busy = true;
        const html = $('#jwf-apply').html();
        $('#jwf-apply').prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i> Применяю…');
        try {
            if (draft.enabled && !st.rules_loaded && nginx().installed) { await api('/api/jkufw/waf/rules', {}); }
            const g = {enabled: draft.enabled ? '1' : '0', interfaces: draft.interfaces.join(','), http_port: draft.http_port, https_port: draft.https_port,
                trusted: draft.trusted.split(/[\s,;]+/).filter(Boolean).join(',')};
            saved(await api('/api/jkufw/waf/set', {waf: {general: g}}), 'Настройки');
            const r = await api('/api/jkufw/waf/apply', {});
            if (r.errorMessage) { throw new Error(r.errorMessage); }
            for (const url of r.reconfigure || []) { await api(url, {}); }
            pendingSites = false;
            await loadAll(false);
            $('#jwf-applybar').removeClass('show');
            renderAll();
        } catch (e) { showErr('Не удалось применить: ' + e.message); }
        finally { busy = false; $('#jwf-apply').prop('disabled', false).html(html); }
    }
    $('#jwf-apply').on('click', applyAll);
    $('#jwf-revert').on('click', async () => { pendingSites = false; await loadAll(false); $('#jwf-applybar').removeClass('show'); renderAll(); });

    // ---- settings events ------------------------------------------------------------------------
    $('#jwf-en').on('click keydown', swKey(() => { draft.enabled = !draft.enabled; markDirty(); }));
    $('#jwf-ifs').on('click', '.jwf-cb', function () {
        const n = String($(this).data('if'));
        draft.interfaces = draft.interfaces.includes(n) ? draft.interfaces.filter((x) => x !== n) : draft.interfaces.concat([n]);
        markDirty();
    });
    $('#jwf-http').on('input', function () { draft.http_port = this.value.trim(); markDirty(); });
    $('#jwf-https').on('input', function () { draft.https_port = this.value.trim(); markDirty(); });
    $('#jwf-trusted').on('input', function () { draft.trusted = this.value; markDirty(); });

    // ---- site editor ----------------------------------------------------------------------------
    let editing = null, form = null;
    function renderForm() {
        $('#js-mode .jwf-opt').each(function () { $(this).toggleClass('sel', $(this).data('mode') === form.mode); });
        $('#js-rules .jwf-cb').each(function () { $(this).toggleClass('sel', form.rules.includes($(this).data('v'))); });
        $('#js-https').toggleClass('on', form.https_only); $('#js-bots').toggleClass('on', form.bots); $('#js-ws').toggleClass('on', form.websocket);
    }
    function openSite(uuid) {
        const s = uuid ? sites().find((x) => x.uuid === uuid) : null;
        editing = uuid || null;
        form = s ? JSON.parse(JSON.stringify(s)) : {enabled: true, domains: [], backend: '', certificate: '', https_only: false, mode: 'detect',
            rules: ALL_RULES.slice(), bots: true, websocket: false, max_body: '20'};
        $('#js-title').text(s ? s.domains[0] : 'Новый сайт');
        $('#js-domains').val(form.domains.join(', ')); $('#js-backend').val(form.backend); $('#js-body').val(form.max_body);
        $('#js-cert').html('<option value="">Без сертификата (только HTTP)</option>' + (st.certificates || []).map((c) =>
            `<option value="${esc(c.refid)}">${esc(c.descr || c.cn)}${c.cn && c.descr !== c.cn ? ' — ' + esc(c.cn) : ''}</option>`).join('')).val(form.certificate);
        $('#js-del').toggle(!!s); $('#js-err').text('');
        renderForm();
        $('#jwf-ov-site').addClass('open');
        setTimeout(() => $('#js-domains').trigger('focus'), 50);
    }
    $('#jwf-add').on('click', () => openSite(null));
    $('#jwf-sites').on('click', '[data-edit]', function () { openSite($(this).data('edit')); })
        .on('click keydown', '[data-toggle]', swKey(async function () {
            try { await api('/api/jkufw/waf/toggleSite/' + $(this).data('toggle'), {}); pendingSites = true; model = await api('/api/jkufw/waf/get'); renderSites(); markDirty(); }
            catch (e) { showErr(e.message); }
        }));
    $('#js-mode').on('click', '.jwf-opt', function () { form.mode = $(this).data('mode'); renderForm(); });
    $('#js-rules').on('click', '.jwf-cb', function () {
        const v = $(this).data('v');
        form.rules = form.rules.includes(v) ? form.rules.filter((x) => x !== v) : form.rules.concat([v]);
        renderForm();
    });
    $('#js-https').on('click keydown', swKey(() => { form.https_only = !form.https_only; renderForm(); }));
    $('#js-bots').on('click keydown', swKey(() => { form.bots = !form.bots; renderForm(); }));
    $('#js-ws').on('click keydown', swKey(() => { form.websocket = !form.websocket; renderForm(); }));
    $('#js-save').on('click', async () => {
        let backend = $('#js-backend').val().trim();
        if (backend && !/^https?:\/\//i.test(backend)) { backend = 'http://' + backend; }
        const site = {enabled: form.enabled ? '1' : '0', domains: $('#js-domains').val().split(/[\s,;]+/).filter(Boolean).join(','), backend: backend,
            certificate: $('#js-cert').val() || '', https_only: form.https_only ? '1' : '0', mode: form.mode, rules: form.rules.join(','),
            bots: form.bots ? '1' : '0', websocket: form.websocket ? '1' : '0', max_body: $('#js-body').val().trim() || '20'};
        try {
            saved(await api(editing ? '/api/jkufw/waf/setSite/' + editing : '/api/jkufw/waf/addSite', {site: site}));
            $('#jwf-ov-site').removeClass('open');
            pendingSites = true;
            if (!editing && !draft.enabled) { draft.enabled = true; }
            model = await api('/api/jkufw/waf/get');
            renderSites(); markDirty();
        } catch (e) { $('#js-err').text(e.message); }
    });
    $('#js-del').on('click', async () => {
        if (!editing) { return; }
        try { await api('/api/jkufw/waf/delSite/' + editing, {}); $('#jwf-ov-site').removeClass('open'); pendingSites = true; model = await api('/api/jkufw/waf/get'); renderSites(); markDirty(); }
        catch (e) { $('#js-err').text(e.message); }
    });
    $('.jwf-ov').on('click', function (e) { if (e.target === this) { $(this).removeClass('open'); } })
        .on('click', '[data-close]', function () { $(this).closest('.jwf-ov').removeClass('open'); });
    $(document).on('keydown', (e) => { if (e.key === 'Escape') { $('.jwf-ov').removeClass('open'); } });

    (async () => {
        try {
            await loadAll(false);
            $('#jwf-loading').hide(); $('#jwf-main').show();
            renderAll();
            setInterval(() => { if (!busy && !document.hidden) { refresh(); } }, POLL_MS);
        } catch (e) { $('#jwf-loading').hide(); showErr('Не удалось загрузить: ' + e.message); }
    })();
});
</script>
