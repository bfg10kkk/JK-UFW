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
 #
 # jk-ufw: stream antivirus and sandbox. Web downloads are scanned on the fly by ClamAV through the
 # web proxy (Squid -> c-icap); files in HTTP / SMTP / FTP / SMB / NFS traffic are cut out by Suricata
 # and analysed (ClamAV, hash reputation, sandbox). Hashes found malicious are blocked in both paths.
 # Data comes from /api/jkufw/antivirus/* (scripts/jkufw/av.py does the analysis).
 #}

<style>
.jav { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1240px; }
.jav * { box-sizing:border-box; }
.jav b, .jav strong { font-family:inherit; font-weight:700; }
.jav .mono { font-family:ui-monospace,Menlo,Consolas,monospace; }
.jav .muted { color:var(--m); }
.jav a.lnk { color:var(--a2); }
.jav-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jav-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:23px; flex:none;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jav-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jav-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jav-sub { color:var(--m); margin-top:2px; }
.jav-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jav-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jav-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jav-pill.warn i { background:var(--warn); }
.jav-pill.bad i { background:var(--a); }
.jav-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jav-grid { display:grid; grid-template-columns:minmax(0,1.5fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1050px) { .jav-grid { grid-template-columns:minmax(0,1fr); } }
.jav-grid > div { min-width:0; }
.jav-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jav-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.jav-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; display:flex; gap:8px; align-items:center; }
.jav-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 760px) { .jav-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jav-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; min-width:0; }
.jav-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jav-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jav-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jav-kpi .v.ok { color:var(--ok); } .jav-kpi .v.bad { color:var(--a2); } .jav-kpi .v.warn { color:var(--warn); }
/* flow diagram */
.jav-flow { padding:10px 18px 6px; background:radial-gradient(ellipse at 40% 0%,rgba(229,32,46,.10),rgba(229,32,46,0) 60%), var(--s); }
.jav-flow svg { display:block; width:100%; height:auto; }
.jav-flow text { font-family:inherit; }
@keyframes javflow { to { stroke-dashoffset:-24; } }
.jav-flow .live { stroke-dasharray:7 5; animation:javflow .9s linear infinite; }
@media (prefers-reduced-motion: reduce) { .jav-flow .live { animation:none; } }
/* link cards */
.jav-links { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:12px; }
@media (max-width: 640px) { .jav-links { grid-template-columns:minmax(0,1fr); } }
.jav-link { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; position:relative; min-width:0; }
.jav-link.carry { border-color:rgba(229,32,46,.55); box-shadow:inset 0 0 0 1px rgba(229,32,46,.25); }
.jav-link.off { opacity:.6; }
.jav-link-top { display:flex; align-items:center; gap:10px; }
.jav-link-ic { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:16px; flex:none; position:relative; }
.jav-link.carry .jav-link-ic { background:var(--abg); color:var(--a2); }
.jav-link-ic .dot { position:absolute; right:-2px; bottom:-2px; width:11px; height:11px; border-radius:50%; background:#3a3a42; border:2px solid var(--s2); }
.dot.ok { background:var(--ok) !important; } .dot.warn { background:var(--warn) !important; } .dot.bad { background:var(--a) !important; }
.jav-link-n { font-weight:700; font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jav-link-s { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jav-link-m { flex:1; min-width:0; }
.jav-chip { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; background:#232329; color:var(--m); white-space:nowrap; }
.jav-chip.acc { background:var(--abg); color:var(--a2); }
.jav-chip.ok { background:rgba(34,197,94,.12); color:#4ade80; }
.jav-chip.warn { background:rgba(245,165,36,.12); color:var(--warn); }
.jav-chip.bad { background:var(--abg); color:#ff6b74; }
.jav-stats { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; margin:14px 0 8px; }
.jav-stats .l { color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jav-stats .v { font-size:18px; font-weight:700; letter-spacing:-.02em; }
.jav-stats .v small { font-size:11px; color:var(--m); margin-left:2px; font-weight:600; }
.jav-spark { height:44px; }
.jav-spark svg { width:100%; height:100%; display:block; }
.jav-strip { display:flex; gap:2px; margin-top:6px; }
.jav-strip i { flex:1; height:6px; border-radius:2px; background:#26262c; }
.jav-strip i.ok { background:rgba(34,197,94,.75); } .jav-strip i.warn { background:var(--warn); } .jav-strip i.bad { background:var(--a); }
.jav-tr { display:flex; gap:14px; margin-top:10px; color:var(--m); font-size:12px; align-items:center; }
.jav-tr b { color:var(--t); font-weight:600; }
.jav-util { height:4px; border-radius:2px; background:#26262c; margin-top:8px; overflow:hidden; }
.jav-util i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); }
/* buttons, fields */
.jav-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important;
  display:inline-flex; align-items:center; gap:7px; text-decoration:none !important; white-space:nowrap; }
.jav-btn:hover { background:var(--a2); }
.jav-btn[disabled] { opacity:.5; cursor:default; }
.jav-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jav-btn.ghost:hover { background:var(--h); }
.jav-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jav-btn.icon { padding:6px 9px; }
.jav-btn.danger:hover { color:var(--a2) !important; border-color:rgba(229,32,46,.5); }
.jav-sw { display:inline-block; vertical-align:middle; flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jav-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jav-sw.on { background:var(--a); }
.jav-sw.on::after { left:16px; background:#fff; }
.jav-seg { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
.jav-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; cursor:pointer; transition:all .15s; min-width:0; }
.jav-opt:hover { border-color:var(--b2); background:var(--h); }
.jav-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jav-opt .nm { font-weight:700; font-size:13.5px; }
.jav-opt .nm .fa { color:var(--m); margin-right:6px; }
.jav-opt.sel .nm .fa { color:var(--a2); }
.jav-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jav-field { margin-bottom:14px; }
.jav-field > label { display:block; font-weight:600; margin-bottom:6px; }
.jav-field .hint { color:var(--m); font-size:12px; margin-top:5px; line-height:1.45; }
.jav input.jav-in, .jav select.jav-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:9px 11px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:12.5px; box-shadow:none !important; }
.jav input.jav-in:focus, .jav select.jav-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg) !important; }
.jav input.jav-in.bad { border-color:var(--a) !important; }
.jav-row2 { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:12px; }
@media (max-width: 560px) { .jav-row2, .jav-seg { grid-template-columns:minmax(0,1fr); } }
.jav-tg { display:flex; gap:12px; align-items:flex-start; padding:11px 0; border-top:1px solid var(--b); }
.jav-tg:first-of-type { border-top:0; }
.jav-tg .tx { flex:1; min-width:0; }
.jav-tg .tx b { display:block; }
.jav-tg .tx span { color:var(--m); font-size:12px; line-height:1.45; }
.jav-order { margin:0; padding:0; list-style:none; }
.jav-order li { display:flex; align-items:center; gap:10px; padding:9px 10px; border:1px solid var(--b); background:var(--s2); border-radius:10px; margin-bottom:8px; }
.jav-order li.out { opacity:.55; }
.jav-order .num { width:24px; height:24px; border-radius:7px; display:grid; place-items:center; font-weight:700; font-size:12px; background:var(--abg); color:var(--a2); flex:none; }
.jav-order li.out .num { background:#232329; color:var(--m); }
.jav-order .nm { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jav-order .nm small { color:var(--m); font-weight:500; margin-left:6px; }
.jav-order .ctl { display:flex; gap:4px; align-items:center; flex:none; }
.jav-order .wt { min-width:46px; text-align:center; font-weight:700; }
.jav-chips { display:flex; gap:8px; flex-wrap:wrap; }
.jav-cb { display:inline-flex; align-items:center; gap:7px; padding:7px 11px; border:1px solid var(--b); background:var(--s2); border-radius:9px; cursor:pointer; font-weight:600; font-size:12.5px; }
.jav-cb .fa { color:var(--m); }
.jav-cb.sel { border-color:var(--a); background:var(--abg); }
.jav-cb.sel .fa { color:var(--a2); }
.jav-cb small { color:var(--m); font-weight:500; }
.jav-pol { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jav-pol:first-child { border-top:0; padding-top:0; }
.jav-pol .ic { width:38px; height:38px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jav-pol.off .ic { background:#202026; color:var(--m); }
.jav-pol.off .pm { opacity:.6; }
.jav-pol .pm { flex:1; min-width:0; }
.jav-pol .pn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jav-pol .ps { color:var(--m); font-size:11.5px; margin-top:2px; overflow-wrap:anywhere; }
.jav-pol .arrow { display:flex; align-items:center; gap:6px; flex:none; font-weight:600; }
.jav-pol .pa { display:flex; gap:6px; align-items:center; flex:none; }
@media (max-width: 560px) { .jav-pol { flex-wrap:wrap; } .jav-pol .arrow { order:3; width:100%; padding-left:50px; } }
.jav-ev { display:flex; gap:11px; padding:9px 0; border-top:1px solid var(--b); }
.jav-ev:first-child { border-top:0; padding-top:0; }
.jav-ev .ei { width:28px; height:28px; border-radius:8px; display:grid; place-items:center; flex:none; background:#202026; color:var(--m); font-size:12.5px; }
.jav-ev.bad .ei { background:var(--abg); color:var(--a2); }
.jav-ev.ok .ei { background:rgba(34,197,94,.12); color:var(--ok); }
.jav-ev.warn .ei { background:rgba(245,165,36,.12); color:var(--warn); }
.jav-ev .et { flex:1; min-width:0; line-height:1.4; }
.jav-ev .ew { color:var(--m); font-size:11.5px; }
.jav-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jav-note .fa { margin-top:2px; }
.jav-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jav-note.warn .fa { color:var(--warn); }
.jav-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jav-note.err { background:var(--abg); border:1px solid rgba(229,32,46,.4); color:#ffb3b8; }
.jav-empty { color:var(--m); text-align:center; padding:24px 6px; }
.jav-empty .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }
.jav-hero { display:flex; gap:18px; align-items:center; padding:22px; background:linear-gradient(120deg,rgba(229,32,46,.14),rgba(229,32,46,0) 60%), var(--s); }
.jav-hero .big { font-size:17px; font-weight:700; }
.jav-hero .ds { color:var(--m); margin-top:4px; line-height:1.5; }
.jav-applybar { position:sticky; bottom:12px; z-index:5; display:none; align-items:center; gap:12px; padding:12px 14px; margin-bottom:16px;
  background:#1b1114; border:1px solid rgba(229,32,46,.45); border-radius:12px; box-shadow:0 10px 30px rgba(0,0,0,.5); }
.jav-applybar.show { display:flex; }
.jav-applybar .tx { flex:1; min-width:0; }
/* modal */
.jav-ov { max-width:none; font-size:13px; position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.72); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; padding:16px; }
.jav-ov.open { display:flex; }
.jav-modal { width:100%; max-width:560px; max-height:calc(100vh - 32px); overflow:auto; background:var(--s); border:1px solid var(--b2); border-radius:14px;
  padding:22px; box-shadow:0 20px 60px rgba(0,0,0,.6); color:var(--t); }
.jav-modal h4 { margin:0 0 4px; font-size:17px; font-weight:700; }
.jav-modal .sub { color:var(--m); margin-bottom:16px; line-height:1.5; }
.jav-modal .ft { display:flex; gap:8px; justify-content:flex-end; margin-top:18px; flex-wrap:wrap; }
.jav-apps { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; }
@media (max-width: 480px) { .jav-apps { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jav-app { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 4px; text-align:center; cursor:pointer; font-size:11.5px; font-weight:600; line-height:1.25; }
.jav-app .fa { display:block; font-size:18px; margin-bottom:6px; color:var(--m); }
.jav-app.sel { border-color:var(--a); background:var(--abg); }
.jav-app.sel .fa { color:var(--a2); }
.jav-err { color:#ff8a92; font-size:12px; margin-top:10px; }
/* antivirus additions */
.jav-pipe { display:flex; align-items:stretch; gap:0; padding:16px 18px; overflow-x:auto; }
.jav-st { flex:1; min-width:120px; background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:12px; position:relative; }
.jav-st.on { border-color:rgba(229,32,46,.5); background:linear-gradient(160deg,rgba(229,32,46,.13),rgba(229,32,46,0) 70%), var(--s2); }
.jav-st .ic { width:30px; height:30px; border-radius:9px; display:grid; place-items:center; background:#202026; color:var(--m); margin-bottom:8px; }
.jav-st.on .ic { background:var(--abg); color:var(--a2); }
.jav-st .nm { font-weight:700; font-size:12.5px; }
.jav-st .ds { color:var(--m); font-size:11.5px; margin-top:3px; line-height:1.35; }
.jav-arrow { display:grid; place-items:center; color:#3a3a42; padding:0 6px; flex:none; }
.jav-arrow.on { color:var(--a2); }
.jav-drop { border:1.5px dashed var(--b2); border-radius:12px; padding:22px 14px; text-align:center; cursor:pointer; transition:all .15s; background:var(--s2); }
.jav-drop:hover, .jav-drop.over { border-color:var(--a); background:var(--abg); }
.jav-drop .fa { font-size:26px; color:var(--a2); display:block; margin-bottom:8px; }
.jav-drop b { display:block; font-size:14px; }
.jav-or { display:flex; gap:8px; margin-top:12px; }
.jav-or input { flex:1; }
.jav-tbl { width:100%; border-collapse:collapse; }
.jav-tbl th { color:var(--m); font-size:10.5px; font-weight:700; text-transform:uppercase; letter-spacing:.06em; text-align:left; padding:0 8px 8px; white-space:nowrap; }
.jav-tbl td { padding:9px 8px; border-top:1px solid var(--b); vertical-align:middle; }
.jav-tbl tr.row { cursor:pointer; }
.jav-tbl tr.row:hover td { background:var(--h); }
.jav-tbl .fn { font-weight:600; max-width:260px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jav-tbl .fs { color:var(--m); font-size:11.5px; max-width:260px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jav-ki { width:30px; height:30px; border-radius:8px; display:grid; place-items:center; background:#202026; color:var(--m); flex:none; }
.jav-fcell { display:flex; gap:10px; align-items:center; min-width:0; }
@media (max-width: 760px) { .jav-tbl .hide-s { display:none; } }
.jav-filter { display:flex; gap:6px; flex-wrap:wrap; }
.jav-filter span { font-size:11.5px; font-weight:600; padding:4px 10px; border-radius:999px; border:1px solid var(--b); cursor:pointer; color:var(--m); background:var(--s2); }
.jav-filter span.sel { color:var(--t); border-color:var(--a); background:var(--abg); }
.jav-plug { display:flex; gap:8px; flex-wrap:wrap; margin:2px 0 14px; }
.jav-verdict { display:flex; gap:14px; align-items:center; padding:14px; border-radius:12px; background:var(--s2); border:1px solid var(--b); margin-bottom:14px; }
.jav-verdict .big { width:46px; height:46px; border-radius:12px; display:grid; place-items:center; font-size:20px; flex:none; background:#202026; color:var(--m); }
.jav-verdict.malicious { border-color:rgba(229,32,46,.55); background:linear-gradient(120deg,rgba(229,32,46,.16),rgba(229,32,46,0) 70%), var(--s2); }
.jav-verdict.malicious .big { background:var(--a); color:#fff; }
.jav-verdict.suspicious .big { background:rgba(245,165,36,.18); color:var(--warn); }
.jav-verdict.clean .big { background:rgba(34,197,94,.14); color:var(--ok); }
.jav-verdict .t { font-size:16px; font-weight:700; }
.jav-verdict .r { color:var(--m); margin-top:3px; line-height:1.4; overflow-wrap:anywhere; }
.jav-kv { display:grid; grid-template-columns:120px minmax(0,1fr); gap:6px 12px; font-size:12.5px; }
.jav-kv .k { color:var(--m); }
.jav-kv .v { overflow-wrap:anywhere; }
.jav-checks { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px; margin:14px 0; }
@media (max-width: 520px) { .jav-checks { grid-template-columns:minmax(0,1fr); } }
.jav-check { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 12px; min-width:0; }
.jav-check .h { display:flex; align-items:center; gap:7px; font-weight:700; font-size:12.5px; }
.jav-check .d { color:var(--m); font-size:11.5px; margin-top:4px; line-height:1.4; overflow-wrap:anywhere; }
.jav-sig { display:flex; gap:8px; padding:6px 0; border-top:1px solid var(--b); font-size:12px; }
.jav-sig:first-child { border-top:0; }
.jav-sig .sv { flex:none; width:8px; height:8px; border-radius:50%; margin-top:5px; background:var(--m); }
.jav-sig .sv.s3 { background:var(--a); } .jav-sig .sv.s2 { background:var(--warn); }
.jav-log { background:#0d0d0f; border:1px solid var(--b); border-radius:8px; padding:10px; font-size:11.5px; max-height:180px; overflow:auto; white-space:pre-wrap; color:var(--m); }
.jav-sec { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:16px 0 8px; }
</style>

<div class="jav" id="jav">
  <div class="jav-head">
    <div class="jav-logo" id="jav-logo"><i class="fa fa-shield"></i></div>
    <div>
      <h1 class="jav-title">Антивирус и песочница <span class="jav-pill" id="jav-pill"><i></i><span>…</span></span></h1>
      <div class="jav-sub">Проверка загрузок на лету, файлы из трафика, репутация хешей и запуск подозрительного в песочнице</div>
    </div>
    <div class="jav-head-r">
      <a class="jav-btn ghost" href="/ui/ids/threats"><i class="fa fa-crosshairs"></i> Угрозы IDS</a>
      <a class="jav-btn ghost" href="/ui/diagnostics/log/core/clamd"><i class="fa fa-list-alt"></i> Журнал ClamAV</a>
    </div>
  </div>

  <div id="jav-loading" class="jav-card"><div class="jav-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></div>
  <div id="jav-error" class="jav-note err" style="display:none; margin:0 0 16px"><i class="fa fa-exclamation-circle"></i><div></div></div>

  <div id="jav-main" style="display:none">
    <div class="jav-card jav-hero" id="jav-intro" style="display:none">
      <div class="jav-logo on"><i class="fa fa-shield"></i></div>
      <div style="flex:1; min-width:0">
        <div class="big">Вредонос не должен дойти до компьютера</div>
        <div class="ds">Включите проверку веб-загрузок: каждый скачанный файл проходит через ClamAV, заражённый заменяется страницей-предупреждением.
          Файлы из почты, FTP и общих папок вырезаются из трафика системой обнаружения вторжений и проверяются по базам и в песочнице.</div>
      </div>
      <button class="jav-btn" id="jav-intro-go"><i class="fa fa-power-off"></i> Включить защиту</button>
    </div>

    <div class="jav-kpis">
      <div class="jav-kpi"><div class="l">Файлов за 24 ч</div><div class="v" id="k-files">—</div></div>
      <div class="jav-kpi"><div class="l">Угроз за 24 ч</div><div class="v" id="k-bad">—</div></div>
      <div class="jav-kpi"><div class="l">В песочнице</div><div class="v" id="k-sb">—</div></div>
      <div class="jav-kpi"><div class="l">Хешей в блок-листе</div><div class="v" id="k-bl">—</div></div>
    </div>

    <div class="jav-card" style="padding:0"><div class="jav-pipe" id="jav-pipe"></div></div>

    <div class="jav-applybar" id="jav-applybar">
      <i class="fa fa-pencil" style="color:var(--a2)"></i>
      <div class="tx"><b>Есть несохранённые изменения.</b> <span class="muted">Они вступят в силу после применения.</span></div>
      <button class="jav-btn ghost sm" id="jav-revert">Отменить</button>
      <button class="jav-btn sm" id="jav-apply"><i class="fa fa-check"></i> Применить</button>
    </div>
    <div id="jav-warn"></div>

    <div class="jav-grid">
      <div>
        <div class="jav-card">
          <h3><i class="fa fa-flask"></i> Проверить файл</h3>
          <div class="jav-drop" id="jav-drop" tabindex="0" role="button">
            <i class="fa fa-cloud-upload"></i><b>Перетащите файл сюда</b><span class="muted">или нажмите, чтобы выбрать. До 64 МБ: ClamAV, базы угроз и песочница.</span>
          </div>
          <input type="file" id="jav-file" style="display:none"/>
          <div class="jav-or">
            <input class="jav-in mono" id="jav-hash" type="text" placeholder="или вставьте MD5, SHA-1, SHA-256" spellcheck="false"/>
            <button class="jav-btn ghost" id="jav-hash-go"><i class="fa fa-search"></i> Проверить</button>
          </div>
          <div id="jav-check-res"></div>
        </div>
        <div class="jav-card">
          <h3><i class="fa fa-file-o"></i> Проверенные файлы
            <span class="r"><span class="jav-filter" id="jav-filter">
              <span data-f="all" class="sel">Все</span><span data-f="bad">Угрозы</span><span data-f="pending">В работе</span><span data-f="blocked">Заблокированы</span>
            </span></span></h3>
          <div style="overflow-x:auto"><table class="jav-tbl"><thead><tr><th>Файл</th><th>Вердикт</th><th class="hide-s">Устройство</th><th class="hide-s">Когда</th></tr></thead>
            <tbody id="jav-files"></tbody></table></div>
        </div>
      </div>
      <div>
        <div class="jav-card">
          <h3><i class="fa fa-globe"></i> Веб-загрузки на лету
            <span class="r"><span class="muted" id="w-en-t">Выключено</span><span class="jav-sw" id="w-en" role="switch" tabindex="0" aria-label="Проверка веб-загрузок"></span></span></h3>
          <div class="jav-plug" id="w-plug"></div>
          <div class="jav-field"><label>Какие сети проверять</label><div class="jav-chips" id="w-ifs"></div></div>
          <div class="jav-tg"><div class="tx"><b>Проверять и HTTPS</b><span>Почти всё скачивается по HTTPS. Прокси вскрывает соединение своим сертификатом: его нужно установить на компьютеры как доверенный.</span></div>
            <span class="jav-sw" id="w-https" role="switch" tabindex="0"></span></div>
          <div id="w-https-box" style="display:none">
            <div class="jav-field"><label for="w-ca">Центр сертификации</label>
              <select class="jav-in" id="w-ca"></select>
              <div class="hint" id="w-ca-h">Создайте его в <a class="lnk" href="/ui/trust/ca">Система › Доверие › Центры сертификации</a>, затем раздайте .crt на устройства.</div></div>
            <div class="jav-field"><label for="w-nobump">Не вскрывать</label>
              <input class="jav-in mono" id="w-nobump" type="text" placeholder=".kaspi.kz, .egov.kz, .apple.com"/>
              <div class="hint">Банки, госуслуги и приложения с закреплённым сертификатом. Домены через запятую, точка в начале — с поддоменами.</div></div>
          </div>
          <div class="jav-row2">
            <div class="jav-field"><label for="w-max">Проверять файлы до, МБ</label><input class="jav-in" id="w-max" type="text" inputmode="numeric"/>
              <div class="hint">Крупнее пропускаются без проверки.</div></div>
            <div class="jav-field"><label>Если сканер недоступен</label>
              <div class="jav-chips" id="w-onerr"><span class="jav-cb" data-v="pass"><i class="fa fa-unlock"></i>пропускать</span><span class="jav-cb" data-v="block"><i class="fa fa-ban"></i>блокировать</span></div></div>
          </div>
        </div>

        <div class="jav-card">
          <h3><i class="fa fa-scissors"></i> Файлы из трафика
            <span class="r"><span class="muted" id="f-en-t">Выключено</span><span class="jav-sw" id="f-en" role="switch" tabindex="0" aria-label="Извлечение файлов"></span></span></h3>
          <div class="muted" style="margin:-4px 0 12px; line-height:1.5">Система обнаружения вторжений вырезает файлы из HTTP, почты (SMTP), FTP, SMB и NFS — без прокси и настроек на устройствах. Зашифрованный трафик (HTTPS, IMAPS) так не виден.</div>
          <div id="f-ids"></div>
          <div class="jav-field"><label>Какие файлы</label><div class="jav-chips" id="f-types"></div></div>
          <div class="jav-row2">
            <div class="jav-field"><label for="f-max">Размер до, МБ</label><input class="jav-in" id="f-max" type="text" inputmode="numeric"/></div>
            <div class="jav-field"><label for="f-keep">Карантин, дней</label><input class="jav-in" id="f-keep" type="text" inputmode="numeric"/>
              <div class="hint">Подозрительные и вредоносные файлы. Чистые удаляются сразу.</div></div>
          </div>
        </div>

        <div class="jav-card">
          <h3><i class="fa fa-cubes"></i> Песочница и базы угроз</h3>
          <div class="jav-field"><label>Где запускать файлы</label>
            <div class="jav-seg" id="s-prov" style="grid-template-columns:repeat(2,minmax(0,1fr))">
              <div class="jav-opt" data-v="none"><div class="nm"><i class="fa fa-ban"></i>Не запускать</div><div class="ds">Только ClamAV и проверка хешей по базам.</div></div>
              <div class="jav-opt" data-v="cape"><div class="nm"><i class="fa fa-server"></i>CAPEv2</div><div class="ds">Своя песочница в вашей сети. Файлы никуда не уходят.</div></div>
              <div class="jav-opt" data-v="cuckoo"><div class="nm"><i class="fa fa-server"></i>Cuckoo</div><div class="ds">Своя песочница Cuckoo 2.x с REST API.</div></div>
              <div class="jav-opt" data-v="virustotal"><div class="nm"><i class="fa fa-cloud"></i>VirusTotal</div><div class="ds">Облако, ~70 антивирусов. Файл уходит за рубеж.</div></div>
            </div></div>
          <div id="s-own">
            <div class="jav-row2">
              <div class="jav-field"><label for="s-url">Адрес песочницы</label><input class="jav-in mono" id="s-url" type="text" placeholder="http://10.0.50.10:8000"/></div>
              <div class="jav-field"><label for="s-token">API-токен</label><input class="jav-in mono" id="s-token" type="password" autocomplete="off" placeholder="если включена авторизация"/></div>
            </div>
            <div class="jav-tg" style="border-top:0; padding-top:0"><div class="tx"><b>Проверять сертификат</b><span>Выключите для песочницы с самоподписанным HTTPS.</span></div>
              <span class="jav-sw" id="s-verify" role="switch" tabindex="0"></span></div>
          </div>
          <div class="jav-note warn" id="s-vt-warn" style="display:none; margin:0 0 12px"><i class="fa fa-exclamation-triangle"></i>
            <div>Файлы уходят в VirusTotal (Google) и становятся доступны подписчикам сервиса. Для документов компании и требований к хранению данных в РК лучше своя песочница CAPEv2.</div></div>
          <div class="jav-field" id="s-submit-f"><label>Что отправлять само</label>
            <div class="jav-chips" id="s-submit"><span class="jav-cb" data-v="unknown"><i class="fa fa-question-circle"></i>неизвестные</span><span class="jav-cb" data-v="all"><i class="fa fa-files-o"></i>все</span><span class="jav-cb" data-v="manual"><i class="fa fa-hand-pointer-o"></i>только вручную</span></div>
            <div class="hint">«Неизвестные» — то, что не нашли ClamAV и базы угроз.</div></div>
          <div class="jav-sec">Репутация хешей — сам файл не отправляется</div>
          <div class="jav-row2">
            <div class="jav-field"><label for="i-mb">Ключ MalwareBazaar</label><input class="jav-in mono" id="i-mb" type="password" autocomplete="off" placeholder="бесплатно на auth.abuse.ch"/></div>
            <div class="jav-field"><label for="i-vt">Ключ VirusTotal</label><input class="jav-in mono" id="i-vt" type="password" autocomplete="off" placeholder="бесплатный: 4 запроса в минуту"/></div>
          </div>
        </div>

        <div class="jav-card">
          <h3><i class="fa fa-ban"></i> Реакция</h3>
          <div class="jav-tg"><div class="tx"><b>Блокировать найденное</b><span>Хеш вредоносного файла попадает в блок-лист: прокси и система предотвращения вторжений больше не пропустят этот файл никому.</span></div>
            <span class="jav-sw" id="a-auto" role="switch" tabindex="0"></span></div>
          <div class="jav-tg"><div class="tx"><b>И подозрительное тоже</b><span>Строже, но иногда задевает редкие легальные программы.</span></div>
            <span class="jav-sw" id="a-sus" role="switch" tabindex="0"></span></div>
          <div class="jav-sec">Последние угрозы</div>
          <div id="jav-events"></div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- file report -->
<div class="jav jav-ov" id="jav-ov-file" role="dialog" aria-modal="true">
  <div class="jav-modal" style="max-width:680px">
    <div id="jr-body"></div>
    <div class="jav-err" id="jr-err"></div>
    <div class="ft" id="jr-ft"></div>
  </div>
</div>

<!-- plugin install -->
<div class="jav jav-ov" id="jav-ov-inst" role="dialog" aria-modal="true">
  <div class="jav-modal">
    <h4>Нужны компоненты</h4>
    <div class="sub" id="ji-sub"></div>
    <div class="jav-log" id="ji-log" style="display:none"></div>
    <div class="jav-err" id="ji-err"></div>
    <div class="ft">
      <button class="jav-btn ghost" data-close id="ji-cancel">Отмена</button>
      <button class="jav-btn" id="ji-go"><i class="fa fa-download"></i> Установить</button>
    </div>
  </div>
</div>

<script>
'use strict';
$(function () {
    const POLL_MS = 10000;
    const KINDS = {
        exe: ['fa-cog', 'Программы', 'exe, dll, msi, ELF'],
        office: ['fa-file-word-o', 'Документы Office', 'doc, xls, ppt, rtf'],
        pdf: ['fa-file-pdf-o', 'PDF', ''],
        archive: ['fa-file-archive-o', 'Архивы', 'zip, rar, 7z, cab'],
        script: ['fa-file-code-o', 'Скрипты', 'js, vbs, ps1, hta'],
        android: ['fa-android', 'Android', 'apk'],
        disk: ['fa-hdd-o', 'Образы дисков', 'iso, img, vhd'],
        other: ['fa-file-o', 'Файл', '']
    };
    const VERDICT = {
        malicious: ['bad', 'fa-bug', 'Вредоносный'],
        suspicious: ['warn', 'fa-exclamation-triangle', 'Подозрительный'],
        clean: ['ok', 'fa-check', 'Чистый'],
        unknown: ['', 'fa-question', 'Не найден в базах'],
        pending: ['acc', 'fa-flask', 'В песочнице']
    };
    const SOURCE = {traffic: 'из трафика', upload: 'загружен вручную', hash: 'проверка хеша', web: 'веб-загрузка'};
    const PROVIDER = {none: '', cape: 'CAPEv2', cuckoo: 'Cuckoo', virustotal: 'VirusTotal'};

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
    const ago = (t) => {
        if (!t) { return '—'; }
        const s = Math.max(0, Date.now() / 1000 - t);
        if (s < 60) { return 'только что'; }
        if (s < 3600) { return Math.round(s / 60) + ' мин назад'; }
        if (s < 86400) { return Math.round(s / 3600) + ' ч назад'; }
        return new Date(t * 1000).toLocaleDateString('ru-RU', {day: 'numeric', month: 'short'});
    };
    const size = (b) => {
        if (b == null || b === '') { return ''; }
        const u = ['Б', 'КБ', 'МБ', 'ГБ'];
        let i = 0;
        b = Number(b);
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (b < 10 && i ? b.toFixed(1) : Math.round(b)) + ' ' + u[i];
    };
    const swKey = (fn) => function (e) {
        if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; }
        e.preventDefault();
        fn.call(this, e);
    };
    const showErr = (m) => { $('#jav-error').toggle(!!m).find('div').text(m || ''); };

    let st = null, model = null, draft = null, saved = null, files = [], blocklist = [], events = [];
    let filter = 'all';
    let busy = false;

    const fromModel = () => {
        const a = model.antivirus;
        return {
            web: {enabled: a.web.enabled === '1', interfaces: list(a.web.interfaces), https: a.web.https === '1',
                ca: a.web.ca || '', nobump: list(a.web.nobump).join(', '), maxsize: a.web.maxsize, onerror: pick(a.web.onerror) || 'pass'},
            files: {enabled: a.files.enabled === '1', types: list(a.files.types), maxsize: a.files.maxsize, keep_days: a.files.keep_days},
            intel: {mb_key: a.intel.mb_key, vt_key: a.intel.vt_key},
            sandbox: {provider: pick(a.sandbox.provider) || 'none', url: a.sandbox.url, token: a.sandbox.token,
                verify: a.sandbox.verify === '1', submit: pick(a.sandbox.submit) || 'unknown'},
            action: {autoblock: a.action.autoblock === '1', suspicious: a.action.suspicious === '1'}
        };
    };
    const toModel = (d) => ({antivirus: {
        web: {enabled: d.web.enabled ? '1' : '0', interfaces: d.web.interfaces.join(','), https: d.web.https ? '1' : '0', ca: d.web.ca,
            nobump: d.web.nobump.split(/[\s,]+/).filter(Boolean).join(','), maxsize: String(d.web.maxsize).trim(), onerror: d.web.onerror},
        files: {enabled: d.files.enabled ? '1' : '0', types: d.files.types.join(','), maxsize: String(d.files.maxsize).trim(),
            keep_days: String(d.files.keep_days).trim()},
        intel: {mb_key: d.intel.mb_key.trim(), vt_key: d.intel.vt_key.trim()},
        sandbox: {provider: d.sandbox.provider, url: d.sandbox.url.trim(), token: d.sandbox.token, verify: d.sandbox.verify ? '1' : '0',
            submit: d.sandbox.submit},
        action: {autoblock: d.action.autoblock ? '1' : '0', suspicious: d.action.suspicious ? '1' : '0'}
    }});
    const dirty = () => JSON.stringify(draft) !== JSON.stringify(saved);
    const markDirty = () => { $('#jav-applybar').toggleClass('show', dirty()); renderSettings(); renderPipe(); };

    // ---- rendering ------------------------------------------------------------------------------
    function renderHead() {
        const web = saved.web.enabled && st.proxy.icap;
        const fl = saved.files.enabled && st.ids.enabled;
        const on = web || fl;
        $('#jav-logo').toggleClass('on', on);
        let cls = '', txt = 'Выключено';
        if (on && st.clamd && !st.clamd.running && st.plugins.clamav.installed) { cls = 'warn'; txt = 'ClamAV не запущен'; }
        else if (on && st.worker_error) { cls = 'warn'; txt = 'Ошибка обработки'; }
        else if (web && fl) { cls = 'ok'; txt = 'Полная защита'; }
        else if (on) { cls = 'ok'; txt = web ? 'Веб-загрузки' : 'Файлы из трафика'; }
        $('#jav-pill').attr('class', 'jav-pill ' + cls).find('span').text(txt);
        $('#jav-intro').toggle(!saved.web.enabled && !saved.files.enabled);
        const bad = (st.malicious_24h || 0) + (st.web_blocked_24h || 0);
        $('#k-files').text(st.files_24h ?? '—');
        $('#k-bad').text(bad).attr('class', 'v ' + (bad ? 'bad' : 'ok'));
        $('#k-sb').html(saved.sandbox.provider === 'none' ? '<span class="muted" style="font-size:15px">не подключена</span>' : esc(st.sandbox_queue));
        $('#k-bl').text(st.blocked_hashes ?? 0);
        const w = [];
        if (st.worker_error) { w.push(['err', 'Обработчик файлов: ' + st.worker_error]); }
        if (saved.files.enabled && !st.ids.enabled) {
            w.push(['warn', 'Система обнаружения вторжений выключена, поэтому файлы из трафика не вырезаются. Включите её на странице <a class="lnk" href="/ui/ids/threats">Угрозы</a>.']);
        }
        if (saved.web.enabled && st.plugins.clamav.installed && st.clamd && !st.clamd.running) {
            w.push(['warn', 'ClamAV не отвечает. Первая загрузка баз сигнатур занимает несколько минут; если не помогло — <a class="lnk" href="/ui/clamav/general/index">настройки ClamAV</a>.']);
        }
        $('#jav-warn').html(w.map(([c, t]) => `<div class="jav-note ${c}" style="margin:0 0 16px"><i class="fa fa-exclamation-triangle"></i><div>${t}</div></div>`).join(''));
    }

    function renderPipe() {
        const d = draft;
        const clam = st.clamd && st.clamd.running;
        const stages = [
            [d.web.enabled, 'fa-globe', 'Веб-прокси', d.web.enabled ? (d.web.https ? 'HTTP и HTTPS' : 'только HTTP') : 'выключен'],
            [clam, 'fa-shield', 'ClamAV', clam ? ('базы ' + (st.clamd.db_version || '') ) : (st.plugins.clamav.installed ? 'не запущен' : 'не установлен')],
            [d.files.enabled && st.ids.enabled, 'fa-scissors', 'Файлы из трафика', d.files.enabled ? (st.ids.enabled ? (st.ids.ips ? 'IPS, с блокировкой' : 'IDS, только анализ') : 'IDS выключена') : 'выключено'],
            [!!(d.intel.mb_key || d.intel.vt_key), 'fa-database', 'Базы угроз', [d.intel.mb_key ? 'MalwareBazaar' : '', d.intel.vt_key ? 'VirusTotal' : ''].filter(Boolean).join(', ') || 'нет ключей'],
            [d.sandbox.provider !== 'none', 'fa-flask', 'Песочница', PROVIDER[d.sandbox.provider] || 'не подключена'],
            [d.action.autoblock, 'fa-ban', 'Блок-лист', d.action.autoblock ? (st.blocked_hashes || 0) + ' хешей' : 'вручную']
        ];
        $('#jav-pipe').html(stages.map(([on, ic, nm, ds], i) =>
            (i ? `<div class="jav-arrow ${on ? 'on' : ''}"><i class="fa fa-angle-right"></i></div>` : '') +
            `<div class="jav-st ${on ? 'on' : ''}"><div class="ic"><i class="fa ${ic}"></i></div><div class="nm">${nm}</div><div class="ds">${esc(ds)}</div></div>`).join(''));
    }

    function plugChip(name, label) {
        const p = st.plugins[name];
        if (!p.installed) { return `<span class="jav-chip">${label}: не установлен</span>`; }
        const run = {clamav: st.clamd && st.clamd.running, cicap: st.cicap, proxy: st.proxy.enabled && st.proxy.icap}[name];
        return `<span class="jav-chip ${run ? 'ok' : ''}">${label}${run ? ' работает' : ''}</span>`;
    }

    function renderSettings() {
        const d = draft;
        const sw = (id, on) => $(id).toggleClass('on', !!on).attr('aria-checked', on ? 'true' : 'false');
        sw('#w-en', d.web.enabled); $('#w-en-t').text(d.web.enabled ? 'Включено' : 'Выключено');
        $('#w-plug').html(plugChip('proxy', 'Прокси') + plugChip('cicap', 'ICAP') + plugChip('clamav', 'ClamAV') +
            (st.nat_rules ? `<span class="jav-chip acc">перенаправлений: ${st.nat_rules}</span>` : ''));
        $('#w-ifs').html((st.interfaces.length ? st.interfaces : [{id: 'lan', descr: 'LAN'}]).map((i) =>
            `<span class="jav-cb ${d.web.interfaces.includes(i.id) ? 'sel' : ''}" data-if="${esc(i.id)}"><i class="fa fa-sitemap"></i>${esc(i.descr)}</span>`).join(''));
        sw('#w-https', d.web.https);
        $('#w-https-box').toggle(d.web.https);
        const cas = st.cas || [];
        $('#w-ca').html('<option value="">— выберите —</option>' + cas.map((c) => `<option value="${esc(c.refid)}" ${c.refid === d.web.ca ? 'selected' : ''}>${esc(c.descr)}</option>`).join(''));
        if (!$('#w-nobump').is(':focus')) { $('#w-nobump').val(d.web.nobump); }
        if (!$('#w-max').is(':focus')) { $('#w-max').val(d.web.maxsize); }
        $('#w-onerr .jav-cb').each(function () { $(this).toggleClass('sel', $(this).data('v') === d.web.onerror); });

        sw('#f-en', d.files.enabled); $('#f-en-t').text(d.files.enabled ? 'Включено' : 'Выключено');
        $('#f-ids').html(st.ids.enabled ? (st.ids.ips ? '' :
            '<div class="jav-note info" style="margin:0 0 12px"><i class="fa fa-info-circle"></i><div>Система работает в режиме обнаружения: файлы анализируются, но заблокировать известный вредонос на лету она сможет только в режиме IPS.</div></div>') :
            '<div class="jav-note warn" style="margin:0 0 12px"><i class="fa fa-exclamation-triangle"></i><div>Нужна включённая система обнаружения вторжений. <a class="lnk" href="/ui/ids/threats">Включить</a></div></div>');
        $('#f-types').html(Object.keys(KINDS).filter((k) => k !== 'other').map((k) =>
            `<span class="jav-cb ${d.files.types.includes(k) ? 'sel' : ''}" data-kind="${k}"><i class="fa ${KINDS[k][0]}"></i>${KINDS[k][1]}${KINDS[k][2] ? ' <small>' + KINDS[k][2] + '</small>' : ''}</span>`).join(''));
        if (!$('#f-max').is(':focus')) { $('#f-max').val(d.files.maxsize); }
        if (!$('#f-keep').is(':focus')) { $('#f-keep').val(d.files.keep_days); }

        $('#s-prov .jav-opt').each(function () { $(this).toggleClass('sel', $(this).data('v') === d.sandbox.provider); });
        $('#s-own').toggle(['cape', 'cuckoo'].includes(d.sandbox.provider));
        $('#s-vt-warn').toggle(d.sandbox.provider === 'virustotal');
        $('#s-submit-f').toggle(d.sandbox.provider !== 'none');
        $('#s-url').attr('placeholder', d.sandbox.provider === 'cuckoo' ? 'http://10.0.50.10:8090' : 'http://10.0.50.10:8000');
        ['s-url', 's-token', 'i-mb', 'i-vt'].forEach((id) => {
            const v = {'s-url': d.sandbox.url, 's-token': d.sandbox.token, 'i-mb': d.intel.mb_key, 'i-vt': d.intel.vt_key}[id];
            if (!$('#' + id).is(':focus')) { $('#' + id).val(v); }
        });
        sw('#s-verify', d.sandbox.verify);
        $('#s-submit .jav-cb').each(function () { $(this).toggleClass('sel', $(this).data('v') === d.sandbox.submit); });
        sw('#a-auto', d.action.autoblock);
        sw('#a-sus', d.action.suspicious);
        $('#a-sus').closest('.jav-tg').css('opacity', d.action.autoblock ? 1 : 0.5);
    }

    function verdictChip(v) {
        const x = VERDICT[v] || VERDICT.unknown;
        return `<span class="jav-chip ${x[0]}"><i class="fa ${x[1]}"></i>${x[2]}</span>`;
    }

    function renderFiles() {
        const bl = new Set(blocklist.map((b) => b.sha256));
        const rows = files.filter((f) => filter === 'all' || (filter === 'bad' && ['malicious', 'suspicious'].includes(f.verdict)) ||
            (filter === 'pending' && ['queued', 'running'].includes(f.sb_state)) || (filter === 'blocked' && bl.has(f.sha256)));
        if (!rows.length) {
            const why = files.length ? 'Ничего под этот фильтр' : (saved.files.enabled ? 'Пока не было файлов нужных типов' : 'Включите «Файлы из трафика» или проверьте файл вручную');
            $('#jav-files').html(`<tr><td colspan="4"><div class="jav-empty"><i class="fa fa-folder-open-o"></i>${why}</div></td></tr>`);
            return;
        }
        $('#jav-files').html(rows.slice(0, 150).map((f) => {
            const k = KINDS[f.kind] || KINDS.other;
            const v = ['queued', 'running'].includes(f.sb_state) && !['malicious', 'suspicious'].includes(f.verdict) ? 'pending' : f.verdict;
            const sub = [size(f.size), SOURCE[f.source] || '', f.host || ''].filter(Boolean).join(' · ');
            return `<tr class="row" data-sha="${esc(f.sha256)}">
                <td><div class="jav-fcell"><div class="jav-ki" style="${v === 'malicious' ? 'background:var(--abg);color:var(--a2)' : ''}"><i class="fa ${k[0]}"></i></div>
                  <div style="min-width:0"><div class="fn">${esc(f.name || f.sha256.slice(0, 16))}${bl.has(f.sha256) ? ' <i class="fa fa-ban" style="color:var(--a2)" title="в блок-листе"></i>' : ''}</div>
                  <div class="fs">${esc(sub)}</div></div></div></td>
                <td>${verdictChip(v)}<div class="fs" style="margin-top:3px">${esc(f.reason || '')}</div></td>
                <td class="hide-s mono">${esc(f.client || '—')}</td>
                <td class="hide-s muted" style="white-space:nowrap">${ago(f.last_seen)}${f.seen > 1 ? ' <small>×' + f.seen + '</small>' : ''}</td></tr>`;
        }).join(''));
    }

    function renderEvents() {
        if (!events.length) {
            $('#jav-events').html('<div class="jav-empty" style="padding:12px 6px"><i class="fa fa-check-circle-o"></i>Угроз не было</div>');
            return;
        }
        $('#jav-events').html(events.slice(0, 8).map((e) => `<div class="jav-ev ${e.verdict === 'malicious' ? 'bad' : 'warn'}" ${e.sha256 ? `data-sha="${esc(e.sha256)}" style="cursor:pointer"` : ''}>
            <div class="ei"><i class="fa ${e.type === 'web' ? 'fa-globe' : 'fa-bug'}"></i></div>
            <div class="et"><b>${esc(e.name || 'файл')}</b> ${e.type === 'web' ? '<span class="muted">остановлен прокси</span>' : ''}
              <div class="ew">${esc(e.reason || '')}</div>
              <div class="ew">${esc([e.client, e.url || e.host].filter(Boolean).join(' · '))} · ${ago(e.time)}</div></div></div>`).join(''));
    }

    // ---- report ---------------------------------------------------------------------------------
    function reportHtml(f) {
        const v = ['queued', 'running'].includes(f.sb_state) && !['malicious', 'suspicious'].includes(f.verdict) ? 'pending' : (f.verdict || 'unknown');
        const x = VERDICT[v] || VERDICT.unknown;
        const k = KINDS[f.kind] || KINDS.other;
        const intel = f.intel || {};
        const mb = intel.malwarebazaar, vt = intel.virustotal;
        const check = (title, ic, cls, text) => `<div class="jav-check"><div class="h"><i class="fa ${ic}" style="color:${cls}"></i>${title}</div><div class="d">${text}</div></div>`;
        const red = 'var(--a2)', green = 'var(--ok)', grey = 'var(--m)', amber = 'var(--warn)';
        const checks = [];
        checks.push(f.clamav ? check('ClamAV', 'fa-bug', red, esc(f.clamav)) :
            f.clamav === '' ? check('ClamAV', 'fa-check', green, 'сигнатур не найдено') :
            check('ClamAV', 'fa-minus', grey, f.quarantined || f.source !== 'hash' ? 'сканер недоступен' : 'только хеш, файла нет'));
        if (mb) {
            checks.push(mb.found ? check('MalwareBazaar', 'fa-bug', red, esc(mb.signature || 'известный образец') + (mb.tags && mb.tags.length ? ' · ' + esc(mb.tags.join(', ')) : '') + (mb.url ? ` · <a class="lnk" target="_blank" rel="noopener" href="${esc(mb.url)}">открыть</a>` : '')) :
                mb.error ? check('MalwareBazaar', 'fa-exclamation', amber, esc(mb.error)) : check('MalwareBazaar', 'fa-check', green, 'хеш неизвестен'));
        }
        if (vt) {
            checks.push(vt.found ? check('VirusTotal', vt.malicious ? 'fa-bug' : 'fa-check', vt.malicious >= 3 ? red : (vt.malicious ? amber : green),
                `${vt.malicious}/${vt.total} антивирусов${vt.label ? ' · ' + esc(vt.label) : ''} · <a class="lnk" target="_blank" rel="noopener" href="${esc(vt.url)}">открыть</a>`) :
                vt.error ? check('VirusTotal', 'fa-exclamation', amber, esc(vt.error)) : check('VirusTotal', 'fa-question', grey, 'файл там ещё не встречался'));
        }
        const rep = f.sb_report || {};
        let sb = '';
        if (f.sb_state === 'queued' || f.sb_state === 'running') {
            checks.push(check('Песочница', 'fa-spinner fa-pulse', amber, f.sb_state === 'queued' ? 'в очереди на отправку' : `${esc(PROVIDER[f.sb_provider] || '')}: идёт анализ, обычно 3–10 минут`));
        } else if (f.sb_state === 'done') {
            const s = Number(rep.score || 0);
            checks.push(check('Песочница', s >= 6.5 ? 'fa-bug' : (s >= 3.5 ? 'fa-exclamation-triangle' : 'fa-check'), s >= 6.5 ? red : (s >= 3.5 ? amber : green),
                `${esc(PROVIDER[f.sb_provider] || '')}: оценка ${s.toFixed(1)} из 10${rep.family ? ' · ' + esc(rep.family) : ''}${rep.engines ? ' · ' + esc(rep.engines) : ''}${rep.url ? ` · <a class="lnk" target="_blank" rel="noopener" href="${esc(rep.url)}">отчёт</a>` : ''}`));
            const sigs = rep.signatures || [];
            if (sigs.length) {
                sb = `<div class="jav-sec">Что делал файл</div>` + sigs.slice(0, 12).map((g) =>
                    `<div class="jav-sig"><span class="sv s${Math.min(3, Number(g.severity) || 1)}"></span><div><b>${esc(g.description || g.name)}</b>${g.description ? ` <span class="muted mono">${esc(g.name)}</span>` : ''}</div></div>`).join('');
            }
        } else if (f.sb_state === 'error') {
            checks.push(check('Песочница', 'fa-exclamation', amber, esc(rep.error || 'ошибка')));
        }
        const kv = [['SHA-256', f.sha256], ['MD5', f.md5], ['SHA-1', f.sha1], ['Тип', f.magic], ['Размер', size(f.size)],
            ['Источник', [SOURCE[f.source], f.proto].filter(Boolean).join(', ')], ['Устройство', f.client], ['Сервер', [f.host, f.server].filter(Boolean).join(' · ')],
            ['Адрес', f.url], ['Впервые', f.first_seen ? new Date(f.first_seen * 1000).toLocaleString('ru-RU') : ''], ['Встречался', f.seen > 1 ? f.seen + ' раз' : '']]
            .filter(([, val]) => val).map(([kk, val]) => `<div class="k">${kk}</div><div class="v ${/SHA|MD5/.test(kk) ? 'mono' : ''}">${esc(val)}</div>`).join('');
        return `<div class="jav-verdict ${v}"><div class="big"><i class="fa ${x[1]}"></i></div>
            <div style="min-width:0"><div class="t">${x[2]}${f.blocked ? ' <span class="jav-chip bad"><i class="fa fa-ban"></i>заблокирован</span>' : ''}</div>
            <div class="r"><i class="fa ${k[0]}"></i> ${esc(f.name || 'без имени')} · ${esc(f.reason || '')}</div></div></div>
            <div class="jav-checks">${checks.join('')}</div>${sb}
            <div class="jav-sec">Подробности</div><div class="jav-kv">${kv}</div>`;
    }
    let curFile = null;
    function openReport(f) {
        curFile = f;
        $('#jr-err').text('');
        $('#jr-body').html(reportHtml(f));
        const canSb = saved.sandbox.provider !== 'none' && f.quarantined && !['queued', 'running'].includes(f.sb_state);
        $('#jr-ft').html(`<button class="jav-btn ghost danger" data-act="delete"><i class="fa fa-trash"></i> Удалить запись</button>
            <span style="flex:1"></span>
            <button class="jav-btn ghost" data-act="rescan"><i class="fa fa-refresh"></i> Проверить заново</button>
            ${canSb ? '<button class="jav-btn ghost" data-act="submit"><i class="fa fa-flask"></i> В песочницу</button>' : ''}
            ${f.blocked ? '<button class="jav-btn ghost" data-act="unblock"><i class="fa fa-unlock"></i> Разблокировать</button>' :
                '<button class="jav-btn" data-act="block"><i class="fa fa-ban"></i> Заблокировать хеш</button>'}
            <button class="jav-btn ghost" data-close>Закрыть</button>`);
        $('#jav-ov-file').addClass('open');
    }
    async function showFile(sha) {
        try {
            const f = await api('/api/jkufw/antivirus/file/' + sha);
            if (f.error) { throw new Error(f.error); }
            openReport(f);
        } catch (e) { showErr('Отчёт не загружен: ' + e.message); }
    }
    $('#jr-ft').on('click', '[data-act]', async function () {
        const act = $(this).data('act');
        if (act === 'delete' && $(this).data('confirm') !== true) {
            $(this).data('confirm', true).html('<i class="fa fa-trash"></i> Точно удалить?');
            return;
        }
        $('#jr-ft button').prop('disabled', true);
        try {
            const r = await api('/api/jkufw/antivirus/' + act + '/' + curFile.sha256, {});
            if (r.error) { throw new Error(r.error); }
            if (act === 'delete') { $('#jav-ov-file').removeClass('open'); } else { await showFile(curFile.sha256); }
            await refresh();
        } catch (e) { $('#jr-err').text(e.message); }
        $('#jr-ft button').prop('disabled', false);
    });

    // ---- manual check ---------------------------------------------------------------------------
    function checking(text) {
        $('#jav-check-res').html(`<div class="jav-note info"><i class="fa fa-spinner fa-pulse"></i><div>${text}</div></div>`);
    }
    function checked(f) {
        if (f.error) {
            $('#jav-check-res').html(`<div class="jav-note err"><i class="fa fa-exclamation-circle"></i><div>${esc(f.error)}</div></div>`);
            return;
        }
        const v = VERDICT[['queued', 'running'].includes(f.sb_state) && f.verdict !== 'malicious' ? 'pending' : f.verdict] || VERDICT.unknown;
        $('#jav-check-res').html(`<div class="jav-ev ${v[0]}" style="margin-top:14px; cursor:pointer" data-sha="${esc(f.sha256)}"><div class="ei"><i class="fa ${v[1]}"></i></div>
            <div class="et"><b>${esc(f.name || f.sha256.slice(0, 16))}</b> — ${v[2].toLowerCase()}<div class="ew">${esc(f.reason || '')}</div>
            <div class="ew"><a class="lnk">Открыть отчёт</a></div></div></div>`);
        refresh();
    }
    function upload(file) {
        if (!file) { return; }
        if (file.size > 64 * 1024 * 1024) { checked({error: 'Файл больше 64 МБ.'}); return; }
        checking('Проверяю ' + esc(file.name) + ' (' + size(file.size) + ')…');
        const fd = new FormData();
        fd.append('file', file, file.name);
        $.ajax({type: 'POST', url: '/api/jkufw/antivirus/upload', data: fd, processData: false, contentType: false, dataType: 'json', timeout: 300000})
            .done(checked).fail((x) => checked({error: 'Ошибка загрузки: ' + x.status}));
    }
    $('#jav-drop').on('click keydown', swKey(() => $('#jav-file').trigger('click')))
        .on('dragover dragenter', (e) => { e.preventDefault(); $('#jav-drop').addClass('over'); })
        .on('dragleave drop', (e) => { e.preventDefault(); $('#jav-drop').removeClass('over'); })
        .on('drop', (e) => upload(e.originalEvent.dataTransfer.files[0]));
    $('#jav-file').on('change', function () { upload(this.files[0]); this.value = ''; });
    $('#jav-hash-go').on('click', async () => {
        const h = $('#jav-hash').val().trim();
        if (!/^([0-9a-f]{32}|[0-9a-f]{40}|[0-9a-f]{64})$/i.test(h)) { checked({error: 'Нужен MD5 (32 символа), SHA-1 (40) или SHA-256 (64).'}); return; }
        checking('Ищу хеш в базах угроз…');
        $.ajax({type: 'POST', url: '/api/jkufw/antivirus/lookup', data: {hash: h}, dataType: 'json'})
            .done(checked).fail((x) => checked({error: 'Ошибка: ' + x.status}));
    });
    $('#jav-hash').on('keydown', (e) => { if (e.key === 'Enter') { $('#jav-hash-go').trigger('click'); } });
    $('#jav-check-res, #jav-events').on('click', '[data-sha]', function () { showFile($(this).data('sha')); });
    $('#jav-files').on('click', 'tr.row', function () { showFile($(this).data('sha')); });
    $('#jav-filter').on('click', 'span', function () {
        filter = $(this).data('f');
        $('#jav-filter span').removeClass('sel');
        $(this).addClass('sel');
        renderFiles();
    });

    // ---- settings events ------------------------------------------------------------------------
    const toggle = (id, fn) => $(id).on('click keydown', swKey(() => { fn(); markDirty(); }));
    toggle('#w-en', () => { draft.web.enabled = !draft.web.enabled; });
    toggle('#w-https', () => { draft.web.https = !draft.web.https; });
    toggle('#f-en', () => { draft.files.enabled = !draft.files.enabled; });
    toggle('#s-verify', () => { draft.sandbox.verify = !draft.sandbox.verify; });
    toggle('#a-auto', () => { draft.action.autoblock = !draft.action.autoblock; });
    toggle('#a-sus', () => { if (draft.action.autoblock) { draft.action.suspicious = !draft.action.suspicious; } });
    $('#w-ifs').on('click', '[data-if]', function () {
        const id = $(this).data('if');
        draft.web.interfaces = draft.web.interfaces.includes(id) ? draft.web.interfaces.filter((x) => x !== id) : draft.web.interfaces.concat([id]);
        markDirty();
    });
    $('#f-types').on('click', '[data-kind]', function () {
        const k = $(this).data('kind');
        draft.files.types = draft.files.types.includes(k) ? draft.files.types.filter((x) => x !== k) : draft.files.types.concat([k]);
        markDirty();
    });
    $('#w-onerr').on('click', '.jav-cb', function () { draft.web.onerror = $(this).data('v'); markDirty(); });
    $('#s-submit').on('click', '.jav-cb', function () { draft.sandbox.submit = $(this).data('v'); markDirty(); });
    $('#s-prov').on('click', '.jav-opt', function () { draft.sandbox.provider = $(this).data('v'); markDirty(); });
    $('#w-ca').on('change', function () { draft.web.ca = $(this).val(); markDirty(); });
    const bind = (id, set) => $(id).on('input', function () { set($(this).val()); $('#jav-applybar').toggleClass('show', dirty()); renderPipe(); })
        .on('blur', markDirty);
    bind('#w-nobump', (v) => { draft.web.nobump = v; });
    bind('#w-max', (v) => { draft.web.maxsize = v; });
    bind('#f-max', (v) => { draft.files.maxsize = v; });
    bind('#f-keep', (v) => { draft.files.keep_days = v; });
    bind('#s-url', (v) => { draft.sandbox.url = v; });
    bind('#s-token', (v) => { draft.sandbox.token = v; });
    bind('#i-mb', (v) => { draft.intel.mb_key = v; });
    bind('#i-vt', (v) => { draft.intel.vt_key = v; });
    $('#jav-revert').on('click', () => { draft = JSON.parse(JSON.stringify(saved)); markDirty(); });
    $('#jav-intro-go').on('click', () => {
        draft.web.enabled = true;
        if (!draft.web.interfaces.length && st.interfaces.length) { draft.web.interfaces = [st.interfaces[0].id]; }
        if (st.ids.enabled) { draft.files.enabled = true; }
        markDirty();
        $('#jav-apply').trigger('click');
    });

    // ---- apply ----------------------------------------------------------------------------------
    async function installPackages(pkgs) {
        $('#ji-sub').html(`Для проверки веб-загрузок нужны стандартные плагины: <b>${pkgs.map(esc).join(', ')}</b>. Они скачаются с сервера обновлений (несколько минут), затем настройки применятся сами.`);
        $('#ji-log').hide().text('');
        $('#ji-err').text('');
        $('#ji-go').prop('disabled', false).show();
        $('#jav-ov-inst').addClass('open');
        return new Promise((resolve) => {
            $('#ji-cancel').off('click.i').on('click.i', () => resolve(false));
            $('#ji-go').off('click').on('click', async () => {
                $('#ji-go').prop('disabled', true);
                $('#ji-log').show();
                try {
                    for (const pkg of pkgs) {
                        $('#ji-log').append('>>> ' + pkg + '\n');
                        const r = await api('/api/core/firmware/install/' + pkg, {});
                        if (r.status && r.status !== 'ok') { throw new Error(r.status_msg || r.status); }
                        for (let i = 0; i < 400; i++) {
                            await new Promise((ok) => setTimeout(ok, 2500));
                            const s = await api('/api/core/firmware/upgradestatus');
                            $('#ji-log').text(s.log || '').scrollTop(1e9);
                            if (s.status === 'done') { break; }
                            if (s.status === 'error') { throw new Error('установка ' + pkg + ' не удалась, смотрите журнал выше'); }
                        }
                    }
                    $('#jav-ov-inst').removeClass('open');
                    resolve(true);
                } catch (e) {
                    $('#ji-err').text(e.message);
                    $('#ji-go').prop('disabled', false).html('<i class="fa fa-refresh"></i> Повторить');
                }
            });
        });
    }

    $('#jav-apply').on('click', async () => {
        if (busy) { return; }
        busy = true;
        const $b = $('#jav-apply').prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i> Применяю…');
        showErr('');
        try {
            const r = await api('/api/jkufw/antivirus/set', toModel(draft));
            if (r.result !== 'saved') { throw new Error(Object.values(r.validations || {}).join(' ') || 'не сохранено'); }
            let res = await api('/api/jkufw/antivirus/apply', {});
            if (res.status === 'missing') {
                const ok = await installPackages(res.packages);
                if (!ok) { throw new Error('Без плагинов веб-загрузки проверять нечем. Остальные настройки сохранены.'); }
                location.reload();
                return;
            }
            if (res.status !== 'ok') { throw new Error('не применено'); }
            for (const svc of res.services || []) {
                $b.html('<i class="fa fa-spinner fa-pulse"></i> ' + {clamav: 'ClamAV', cicap: 'ICAP', proxy: 'Прокси'}[svc] + '…');
                await api('/api/' + svc + '/service/reconfigure', {}).catch(() => null);
            }
            if ((res.services || []).includes('clamav')) {
                await api('/api/clamav/service/freshclam', {action: '1'}).catch(() => null);
            }
            await loadModel();
            await refresh();
            if ((res.warnings || []).length) { showErr(res.warnings.join(' ')); }
        } catch (e) {
            showErr(e.message);
        }
        busy = false;
        $b.prop('disabled', false).html('<i class="fa fa-check"></i> Применить');
    });

    $('.jav-ov').on('click', function (e) { if (e.target === this) { $(this).removeClass('open'); } })
        .on('click', '[data-close]', function () { $(this).closest('.jav-ov').removeClass('open'); });
    $(document).on('keydown', (e) => { if (e.key === 'Escape') { $('.jav-ov').removeClass('open'); } });

    // ---- data -----------------------------------------------------------------------------------
    async function loadModel() {
        model = await api('/api/jkufw/antivirus/get');
        saved = fromModel();
        draft = JSON.parse(JSON.stringify(saved));
        $('#jav-applybar').removeClass('show');
    }
    async function refresh() {
        const [s, f, e] = await Promise.all([api('/api/jkufw/antivirus/status'), api('/api/jkufw/antivirus/files'), api('/api/jkufw/antivirus/events')]);
        st = s;
        files = f.files || [];
        blocklist = f.blocklist || [];
        events = e.events || [];
        if (!dirty()) { draft = JSON.parse(JSON.stringify(saved)); }
        renderHead();
        renderSettings();
        renderPipe();
        renderFiles();
        renderEvents();
    }

    (async () => {
        try {
            await loadModel();
            await refresh();
            $('#jav-loading').hide();
            $('#jav-main').show();
            setInterval(() => { if (!document.hidden && !busy) { refresh().catch(() => null); } }, POLL_MS);
        } catch (e) {
            $('#jav-loading').hide();
            showErr('Не удалось загрузить страницу: ' + e.message);
        }
    })();
});
</script>
