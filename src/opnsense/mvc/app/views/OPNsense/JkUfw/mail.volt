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
 # jk-ufw: mail protection. A mail gateway in front of the mail servers inside the network: mail from the
 # internet lands on the firewall, is checked for spam (SPF, DKIM, DMARC, blocklists, Bayes, phishing),
 # viruses (ClamAV) and dangerous attachments, and only clean mail reaches the inside server.
 # Data comes from /api/jkufw/mail/*, which writes the settings of the stock Postfix, rspamd, ClamAV and
 # Redis plugins and the port 25 pass rule (see models/OPNsense/JkUfw/Mail.php).
 #}

<style>
.jml { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1240px; }
.jml * { box-sizing:border-box; }
.jml b, .jml strong { font-family:inherit; font-weight:700; }
.jml .mono { font-family:ui-monospace,Menlo,Consolas,monospace; }
.jml .muted { color:var(--m); }
.jml a.lnk { color:var(--a2); }
.jml-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jml-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:23px; flex:none;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jml-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jml-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jml-sub { color:var(--m); margin-top:2px; }
.jml-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jml-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jml-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jml-pill.warn i { background:var(--warn); }
.jml-pill.bad i { background:var(--a); }
.jml-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jml-grid { display:grid; grid-template-columns:minmax(0,1.5fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1050px) { .jml-grid { grid-template-columns:minmax(0,1fr); } }
.jml-grid > div { min-width:0; }
.jml-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jml-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.jml-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; display:flex; gap:8px; align-items:center; }
.jml-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 760px) { .jml-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jml-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; min-width:0; }
.jml-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jml-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jml-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jml-kpi .v.ok { color:var(--ok); } .jml-kpi .v.bad { color:var(--a2); } .jml-kpi .v.warn { color:var(--warn); }
/* flow diagram */
.jml-flow { padding:10px 18px 6px; background:radial-gradient(ellipse at 40% 0%,rgba(229,32,46,.10),rgba(229,32,46,0) 60%), var(--s); }
.jml-flow svg { display:block; width:100%; height:auto; }
.jml-flow text { font-family:inherit; }
@keyframes jmlflow { to { stroke-dashoffset:-24; } }
.jml-flow .live { stroke-dasharray:7 5; animation:jmlflow .9s linear infinite; }
@media (prefers-reduced-motion: reduce) { .jml-flow .live { animation:none; } }
/* link cards */
.jml-links { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:12px; }
@media (max-width: 640px) { .jml-links { grid-template-columns:minmax(0,1fr); } }
.jml-link { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; position:relative; min-width:0; }
.jml-link.carry { border-color:rgba(229,32,46,.55); box-shadow:inset 0 0 0 1px rgba(229,32,46,.25); }
.jml-link.off { opacity:.6; }
.jml-link-top { display:flex; align-items:center; gap:10px; }
.jml-link-ic { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:16px; flex:none; position:relative; }
.jml-link.carry .jml-link-ic { background:var(--abg); color:var(--a2); }
.jml-link-ic .dot { position:absolute; right:-2px; bottom:-2px; width:11px; height:11px; border-radius:50%; background:#3a3a42; border:2px solid var(--s2); }
.dot.ok { background:var(--ok) !important; } .dot.warn { background:var(--warn) !important; } .dot.bad { background:var(--a) !important; }
.jml-link-n { font-weight:700; font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jml-link-s { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jml-link-m { flex:1; min-width:0; }
.jml-chip { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; background:#232329; color:var(--m); white-space:nowrap; }
.jml-chip.acc { background:var(--abg); color:var(--a2); }
.jml-chip.ok { background:rgba(34,197,94,.12); color:#4ade80; }
.jml-chip.warn { background:rgba(245,165,36,.12); color:var(--warn); }
.jml-chip.bad { background:var(--abg); color:#ff6b74; }
.jml-stats { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; margin:14px 0 8px; }
.jml-stats .l { color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jml-stats .v { font-size:18px; font-weight:700; letter-spacing:-.02em; }
.jml-stats .v small { font-size:11px; color:var(--m); margin-left:2px; font-weight:600; }
.jml-spark { height:44px; }
.jml-spark svg { width:100%; height:100%; display:block; }
.jml-strip { display:flex; gap:2px; margin-top:6px; }
.jml-strip i { flex:1; height:6px; border-radius:2px; background:#26262c; }
.jml-strip i.ok { background:rgba(34,197,94,.75); } .jml-strip i.warn { background:var(--warn); } .jml-strip i.bad { background:var(--a); }
.jml-tr { display:flex; gap:14px; margin-top:10px; color:var(--m); font-size:12px; align-items:center; }
.jml-tr b { color:var(--t); font-weight:600; }
.jml-util { height:4px; border-radius:2px; background:#26262c; margin-top:8px; overflow:hidden; }
.jml-util i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); }
/* buttons, fields */
.jml-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important;
  display:inline-flex; align-items:center; gap:7px; text-decoration:none !important; white-space:nowrap; }
.jml-btn:hover { background:var(--a2); }
.jml-btn[disabled] { opacity:.5; cursor:default; }
.jml-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jml-btn.ghost:hover { background:var(--h); }
.jml-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jml-btn.icon { padding:6px 9px; }
.jml-btn.danger:hover { color:var(--a2) !important; border-color:rgba(229,32,46,.5); }
.jml-sw { display:inline-block; vertical-align:middle; flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jml-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jml-sw.on { background:var(--a); }
.jml-sw.on::after { left:16px; background:#fff; }
.jml-seg { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
.jml-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; cursor:pointer; transition:all .15s; min-width:0; }
.jml-opt:hover { border-color:var(--b2); background:var(--h); }
.jml-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jml-opt .nm { font-weight:700; font-size:13.5px; }
.jml-opt .nm .fa { color:var(--m); margin-right:6px; }
.jml-opt.sel .nm .fa { color:var(--a2); }
.jml-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jml-field { margin-bottom:14px; }
.jml-field > label { display:block; font-weight:600; margin-bottom:6px; }
.jml-field .hint { color:var(--m); font-size:12px; margin-top:5px; line-height:1.45; }
.jml input.jml-in, .jml select.jml-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:9px 11px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:12.5px; box-shadow:none !important; }
.jml input.jml-in:focus, .jml select.jml-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg) !important; }
.jml input.jml-in.bad { border-color:var(--a) !important; }
.jml-row2 { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:12px; }
@media (max-width: 560px) { .jml-row2, .jml-seg { grid-template-columns:minmax(0,1fr); } }
.jml-tg { display:flex; gap:12px; align-items:flex-start; padding:11px 0; border-top:1px solid var(--b); }
.jml-tg:first-of-type { border-top:0; }
.jml-tg .tx { flex:1; min-width:0; }
.jml-tg .tx b { display:block; }
.jml-tg .tx span { color:var(--m); font-size:12px; line-height:1.45; }
.jml-order { margin:0; padding:0; list-style:none; }
.jml-order li { display:flex; align-items:center; gap:10px; padding:9px 10px; border:1px solid var(--b); background:var(--s2); border-radius:10px; margin-bottom:8px; }
.jml-order li.out { opacity:.55; }
.jml-order .num { width:24px; height:24px; border-radius:7px; display:grid; place-items:center; font-weight:700; font-size:12px; background:var(--abg); color:var(--a2); flex:none; }
.jml-order li.out .num { background:#232329; color:var(--m); }
.jml-order .nm { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jml-order .nm small { color:var(--m); font-weight:500; margin-left:6px; }
.jml-order .ctl { display:flex; gap:4px; align-items:center; flex:none; }
.jml-order .wt { min-width:46px; text-align:center; font-weight:700; }
.jml-chips { display:flex; gap:8px; flex-wrap:wrap; }
.jml-cb { display:inline-flex; align-items:center; gap:7px; padding:7px 11px; border:1px solid var(--b); background:var(--s2); border-radius:9px; cursor:pointer; font-weight:600; font-size:12.5px; }
.jml-cb .fa { color:var(--m); }
.jml-cb.sel { border-color:var(--a); background:var(--abg); }
.jml-cb.sel .fa { color:var(--a2); }
.jml-cb small { color:var(--m); font-weight:500; }
.jml-pol { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jml-pol:first-child { border-top:0; padding-top:0; }
.jml-pol .ic { width:38px; height:38px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jml-pol.off .ic { background:#202026; color:var(--m); }
.jml-pol.off .pm { opacity:.6; }
.jml-pol .pm { flex:1; min-width:0; }
.jml-pol .pn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jml-pol .ps { color:var(--m); font-size:11.5px; margin-top:2px; overflow-wrap:anywhere; }
.jml-pol .arrow { display:flex; align-items:center; gap:6px; flex:none; font-weight:600; }
.jml-pol .pa { display:flex; gap:6px; align-items:center; flex:none; }
@media (max-width: 560px) { .jml-pol { flex-wrap:wrap; } .jml-pol .arrow { order:3; width:100%; padding-left:50px; } }
.jml-ev { display:flex; gap:11px; padding:9px 0; border-top:1px solid var(--b); }
.jml-ev:first-child { border-top:0; padding-top:0; }
.jml-ev .ei { width:28px; height:28px; border-radius:8px; display:grid; place-items:center; flex:none; background:#202026; color:var(--m); font-size:12.5px; }
.jml-ev.bad .ei { background:var(--abg); color:var(--a2); }
.jml-ev.ok .ei { background:rgba(34,197,94,.12); color:var(--ok); }
.jml-ev.warn .ei { background:rgba(245,165,36,.12); color:var(--warn); }
.jml-ev .et { flex:1; min-width:0; line-height:1.4; }
.jml-ev .ew { color:var(--m); font-size:11.5px; }
.jml-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jml-note .fa { margin-top:2px; }
.jml-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jml-note.warn .fa { color:var(--warn); }
.jml-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jml-note.err { background:var(--abg); border:1px solid rgba(229,32,46,.4); color:#ffb3b8; }
.jml-empty { color:var(--m); text-align:center; padding:24px 6px; }
.jml-empty .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }
.jml-hero { display:flex; gap:18px; align-items:center; padding:22px; background:linear-gradient(120deg,rgba(229,32,46,.14),rgba(229,32,46,0) 60%), var(--s); }
.jml-hero .big { font-size:17px; font-weight:700; }
.jml-hero .ds { color:var(--m); margin-top:4px; line-height:1.5; }
.jml-applybar { position:sticky; bottom:12px; z-index:5; display:none; align-items:center; gap:12px; padding:12px 14px; margin-bottom:16px;
  background:#1b1114; border:1px solid rgba(229,32,46,.45); border-radius:12px; box-shadow:0 10px 30px rgba(0,0,0,.5); }
.jml-applybar.show { display:flex; }
.jml-applybar .tx { flex:1; min-width:0; }
/* modal */
.jml-ov { max-width:none; font-size:13px; position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.72); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; padding:16px; }
.jml-ov.open { display:flex; }
.jml-modal { width:100%; max-width:560px; max-height:calc(100vh - 32px); overflow:auto; background:var(--s); border:1px solid var(--b2); border-radius:14px;
  padding:22px; box-shadow:0 20px 60px rgba(0,0,0,.6); color:var(--t); }
.jml-modal h4 { margin:0 0 4px; font-size:17px; font-weight:700; }
.jml-modal .sub { color:var(--m); margin-bottom:16px; line-height:1.5; }
.jml-modal .ft { display:flex; gap:8px; justify-content:flex-end; margin-top:18px; flex-wrap:wrap; }
.jml-apps { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; }
@media (max-width: 480px) { .jml-apps { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jml-app { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 4px; text-align:center; cursor:pointer; font-size:11.5px; font-weight:600; line-height:1.25; }
.jml-app .fa { display:block; font-size:18px; margin-bottom:6px; color:var(--m); }
.jml-app.sel { border-color:var(--a); background:var(--abg); }
.jml-app.sel .fa { color:var(--a2); }
.jml-err { color:#ff8a92; font-size:12px; margin-top:10px; }
.jml-dom { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jml-dom:first-child { border-top:0; padding-top:0; }
.jml-dom .ic { width:40px; height:40px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jml-dom.off .ic { background:#202026; color:var(--m); }
.jml-dom.off .pm { opacity:.6; }
.jml-dom .pm { flex:1; min-width:0; }
.jml-dom .pn { font-weight:700; font-size:14px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jml-dom .ps { color:var(--m); font-size:11.5px; margin-top:3px; }
.jml-dom .pa { display:flex; gap:6px; align-items:center; flex:none; }
.jml-msg { display:flex; gap:11px; padding:10px 0; border-top:1px solid var(--b); }
.jml-msg:first-child { border-top:0; padding-top:0; }
.jml-msg .ei { width:30px; height:30px; border-radius:8px; display:grid; place-items:center; flex:none; background:#202026; color:var(--m); font-size:13px; }
.jml-msg.bad .ei { background:var(--abg); color:var(--a2); }
.jml-msg.ok .ei { background:rgba(34,197,94,.12); color:var(--ok); }
.jml-msg.warn .ei { background:rgba(245,165,36,.12); color:var(--warn); }
.jml-msg .et { flex:1; min-width:0; line-height:1.4; }
.jml-msg .sj { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jml-msg .ew { color:var(--m); font-size:11.5px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jml-msg .sc { flex:none; text-align:right; display:flex; flex-direction:column; gap:4px; align-items:flex-end; }
.jml-msg .sc b { font-size:13px; }
.jml-svc { display:flex; align-items:center; gap:10px; padding:8px 0; border-top:1px solid var(--b); }
.jml-svc:first-child { border-top:0; padding-top:0; }
.jml-svc .dot { width:9px; height:9px; border-radius:50%; background:#3a3a42; flex:none; }
.jml-svc .n { flex:1; min-width:0; }
.jml-svc .n small { display:block; color:var(--m); font-size:11.5px; }
.jml-range { display:flex; align-items:center; gap:10px; }
.jml-range input { flex:1; accent-color:#e5202e; }
.jml-range b { min-width:28px; text-align:right; }
.jml-steps { margin:0; padding:0; list-style:none; }
.jml-steps li { display:flex; gap:12px; align-items:center; padding:9px 0; border-top:1px solid var(--b); }
.jml-steps li:first-child { border-top:0; }
.jml-steps .num { width:26px; height:26px; border-radius:8px; display:grid; place-items:center; font-weight:700; font-size:12px; background:#232329; color:var(--m); flex:none; }
.jml-steps li.done .num { background:rgba(34,197,94,.14); color:var(--ok); }
.jml-steps .tx { flex:1; min-width:0; }
.jml-steps .tx span { display:block; color:var(--m); font-size:12px; }
.jml-log { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11px; color:var(--m); background:#0f0f12; border:1px solid var(--b); border-radius:8px; padding:8px 10px;
  max-height:120px; overflow:auto; white-space:pre-wrap; margin-top:10px; display:none; }
.jml-flow { display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-top:12px; font-size:12px; color:var(--m); }
.jml-flow span.s { background:var(--s2); border:1px solid var(--b); border-radius:8px; padding:5px 9px; color:var(--t); font-weight:600; }
.jml-flow span.s.acc { border-color:rgba(229,32,46,.5); background:var(--abg); }
</style>

<div class="jml" id="jml">
  <div class="jml-head">
    <div class="jml-logo" id="jml-logo"><i class="fa fa-envelope"></i></div>
    <div>
      <h1 class="jml-title">Защита почты <span class="jml-pill" id="jml-pill"><i></i><span>…</span></span></h1>
      <div class="jml-sub">Почтовый шлюз: спам, вирусы и опасные вложения отсекаются до того, как письмо попадёт на ваш сервер</div>
    </div>
    <div class="jml-head-r">
      <a class="jml-btn ghost" href="/ui/rspamd"><i class="fa fa-filter"></i> Антиспам</a>
      <a class="jml-btn ghost" href="/ui/postfix/general"><i class="fa fa-sliders"></i> Расширенно</a>
    </div>
  </div>

  <div id="jml-loading" class="jml-card"><div class="jml-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></div>
  <div id="jml-error" class="jml-note err" style="display:none; margin:0 0 16px"><i class="fa fa-exclamation-circle"></i><div></div></div>

  <div id="jml-main" style="display:none">
    <div class="jml-card jml-hero" id="jml-setup" style="display:none">
      <div class="jml-logo on"><i class="fa fa-envelope"></i></div>
      <div style="flex:1; min-width:0">
        <div class="big">Нужно установить компоненты</div>
        <div class="ds">Шлюз собран из проверенных модулей: почтовый сервер Postfix, антиспам rspamd, антивирус ClamAV и Redis для отложенной доставки.</div>
        <ul class="jml-steps" id="jml-steps" style="margin-top:12px"></ul>
        <button class="jml-btn" id="jml-install" style="margin-top:10px"><i class="fa fa-download"></i> Установить</button>
        <div class="jml-log" id="jml-setup-log"></div>
      </div>
    </div>

    <div id="jml-notes"></div>

    <div class="jml-kpis">
      <div class="jml-kpi"><div class="l">Проверено писем</div><div class="v" id="k-scanned">—</div></div>
      <div class="jml-kpi"><div class="l">Отклонено</div><div class="v bad" id="k-rejected">—</div></div>
      <div class="jml-kpi"><div class="l">Помечено как спам</div><div class="v warn" id="k-spam">—</div></div>
      <div class="jml-kpi"><div class="l">Вирусов</div><div class="v" id="k-virus">—</div></div>
    </div>

    <div class="jml-applybar" id="jml-applybar">
      <i class="fa fa-pencil" style="color:var(--a2)"></i>
      <div class="tx"><b>Есть несохранённые изменения.</b> <span class="muted" id="jml-apply-t">Они вступят в силу после применения.</span></div>
      <button class="jml-btn ghost sm" id="jml-revert">Отменить</button>
      <button class="jml-btn sm" id="jml-apply"><i class="fa fa-check"></i> Применить</button>
    </div>

    <div class="jml-grid">
      <div>
        <div class="jml-card">
          <h3><i class="fa fa-at"></i> Почтовые домены
            <span class="r"><button class="jml-btn sm" id="jml-add"><i class="fa fa-plus"></i> Добавить домен</button></span></h3>
          <div id="jml-domains"></div>
          <div class="jml-flow"><span class="s">Интернет</span><i class="fa fa-long-arrow-right"></i><span class="s acc"><i class="fa fa-shield"></i> jk-ufw: проверка</span>
            <i class="fa fa-long-arrow-right"></i><span class="s">Ваш почтовый сервер</span></div>
        </div>
        <div class="jml-card">
          <h3><i class="fa fa-inbox"></i> Последние письма <span class="r muted" id="jml-poll"></span></h3>
          <div id="jml-events"></div>
        </div>
      </div>
      <div>
        <div class="jml-card">
          <h3><i class="fa fa-cogs"></i> Проверки
            <span class="r"><span class="muted" id="jml-en-t">Выключено</span><span class="jml-sw" id="jml-en" role="switch" tabindex="0" aria-label="Защита почты"></span></span></h3>
          <div class="jml-tg"><div class="tx"><b>Антивирус</b><span>Каждое вложение проверяет ClamAV, письма с вирусами отклоняются.</span></div><span class="jml-sw" data-sw="antivirus" role="switch" tabindex="0"></span></div>
          <div class="jml-tg"><div class="tx"><b>Опасные вложения</b><span>Отклонять .exe, .js, .vbs, .lnk, .iso, макросы Office и другие исполняемые файлы.</span></div><span class="jml-sw" data-sw="attachments" role="switch" tabindex="0"></span></div>
          <div class="jml-tg"><div class="tx"><b>Защита от фишинга</b><span>Ссылки сверяются с базой OpenPhish.</span></div><span class="jml-sw" data-sw="phishing" role="switch" tabindex="0"></span></div>
          <div class="jml-tg"><div class="tx"><b>Отложенная доставка (greylisting)</b><span>Подозрительное письмо от незнакомого сервера сначала просим повторить: спам-боты не повторяют. Нужен Redis.</span></div><span class="jml-sw" data-sw="greylist" role="switch" tabindex="0"></span></div>
          <div class="jml-tg"><div class="tx"><b>Строгие проверки SMTP</b><span>Отказ серверам с неверным именем и письмам с несуществующих доменов.</span></div><span class="jml-sw" data-sw="strict" role="switch" tabindex="0"></span></div>
          <div class="jml-tg"><div class="tx"><b>Проверять исходящую почту</b><span>Ваши серверы отправляют почту через шлюз. В сервере укажите адрес экрана как smart host.</span></div><span class="jml-sw" data-sw="outbound" role="switch" tabindex="0"></span></div>
          <div class="jml-field" style="margin-top:12px"><label>Помечать как спам от <b id="jml-spam-v"></b> баллов</label>
            <div class="jml-range"><input type="range" min="2" max="20" step="1" id="jml-spam"/></div>
            <div class="hint">Письмо доходит, но с пометкой в заголовке. С середины до порога отказа в теме появляется [SPAM].</div></div>
          <div class="jml-field"><label>Отклонять от <b id="jml-rej-v"></b> баллов</label>
            <div class="jml-range"><input type="range" min="5" max="40" step="1" id="jml-rej"/></div>
            <div class="hint">Чем ниже, тем строже. Обычное письмо набирает 0–3 балла.</div></div>
        </div>
        <div class="jml-card">
          <h3><i class="fa fa-server"></i> Шлюз</h3>
          <div class="jml-field"><label for="jml-host">Имя шлюза</label>
            <input class="jml-in mono" id="jml-host" type="text" placeholder="mx.example.com"/>
            <div class="hint">Должно совпадать с MX-записью и обратной зоной (PTR) внешнего адреса, иначе часть почты будет считать вас спамером.</div></div>
          <div class="jml-field"><label>Принимать почту на</label><div class="jml-chips" id="jml-ifs"></div></div>
          <div class="jml-row2">
            <div class="jml-field"><label for="jml-size">Размер письма до, МБ</label><input class="jml-in" id="jml-size" type="text" inputmode="numeric"/></div>
            <div class="jml-field"><label for="jml-allow">Доверенные отправители</label><input class="jml-in mono" id="jml-allow" type="text" placeholder="partner.ru, boss@mail.ru"/></div>
          </div>
        </div>
        <div class="jml-card">
          <h3><i class="fa fa-heartbeat"></i> Состояние</h3>
          <div id="jml-svcs"></div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- domain editor -->
<div class="jml jml-ov" id="jml-ov-dom" role="dialog" aria-modal="true">
  <div class="jml-modal">
    <h4 id="jd-title">Новый домен</h4>
    <div class="sub">Почта для этого домена принимается шлюзом, проверяется и передаётся на ваш сервер.</div>
    <div class="jml-field"><label for="jd-domain">Домен</label><input class="jml-in mono" id="jd-domain" type="text" placeholder="example.com"/></div>
    <div class="jml-row2">
      <div class="jml-field"><label for="jd-server">Почтовый сервер внутри сети</label><input class="jml-in mono" id="jd-server" type="text" placeholder="192.168.1.25"/></div>
      <div class="jml-field"><label for="jd-port">Порт SMTP</label><input class="jml-in" id="jd-port" type="text" inputmode="numeric" placeholder="25"/></div>
    </div>
    <div class="jml-field"><label for="jd-descr">Описание</label><input class="jml-in" id="jd-descr" type="text" placeholder="Exchange, Zimbra, Mailcow…"/></div>
    <div class="jml-note info"><i class="fa fa-info-circle"></i><div>В DNS направьте MX-запись домена на внешний адрес экрана. Принимать почту в обход шлюза серверу больше не нужно.</div></div>
    <div class="jml-err" id="jd-err"></div>
    <div class="ft">
      <button class="jml-btn ghost danger" id="jd-del" style="margin-right:auto"><i class="fa fa-trash"></i> Удалить</button>
      <button class="jml-btn ghost" data-close>Отмена</button>
      <button class="jml-btn" id="jd-save"><i class="fa fa-check"></i> Сохранить</button>
    </div>
  </div>
</div>

<script>
'use strict';
$(function () {
    const POLL_MS = 15000;
    const SVC = {postfix: ['Postfix', 'принимает и передаёт почту'], rspamd: ['rspamd', 'антиспам и проверка вложений'],
        clamav: ['ClamAV', 'антивирус'], redis: ['Redis', 'память для отложенной доставки']};
    const FLAGS = ['antivirus', 'attachments', 'phishing', 'greylist', 'strict', 'outbound'];

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
    const num = (n) => n == null ? '—' : Number(n).toLocaleString('ru-RU');
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const swKey = (h) => function (e) { if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; } e.preventDefault(); h.call(this, e); };

    let st = null, model = null, draft = null, base = null, busy = false, pendingDomains = false;

    const fromModel = () => {
        const g = model.mail.general;
        const d = {enabled: String(g.enabled) === '1', hostname: pick(g.hostname), interfaces: list(g.interfaces),
            spam_score: pick(g.spam_score) || '6', reject_score: pick(g.reject_score) || '15', max_size: pick(g.max_size) || '50',
            allow_senders: list(g.allow_senders).join(', ')};
        FLAGS.forEach((f) => { d[f] = String(g[f]) === '1'; });
        return d;
    };
    const domains = () => Object.entries((model.mail.domains && model.mail.domains.domain) || {}).map(([uuid, d]) => ({
        uuid, enabled: String(d.enabled) === '1', domain: pick(d.domain), server: pick(d.server), port: pick(d.port) || '25', description: pick(d.description)
    }));
    const dirty = () => JSON.stringify(draft) !== JSON.stringify(base) || pendingDomains;
    const markDirty = () => { $('#jml-applybar').toggleClass('show', dirty()); renderSettings(); renderSetup(); renderHead(); };
    const needed = () => Object.entries(st.components).filter(([k, c]) => !c.installed &&
        (k === 'postfix' || k === 'rspamd' || (k === 'clamav' && draft.antivirus) || (k === 'redis' && draft.greylist)));

    function renderHead() {
        const c = st.components;
        const on = base.enabled && st.applied > 0 && c.postfix.running && c.rspamd.running;
        const p = $('#jml-pill').removeClass('ok warn bad');
        if (!c.postfix.installed || !c.rspamd.installed) { p.addClass('warn').find('span').text('Не установлено'); }
        else if (!base.enabled) { p.find('span').text('Выключено'); }
        else if (on) { p.addClass('ok').find('span').text('Проверяет почту ' + domains().filter((d) => d.enabled).length + ' домен(ов)'); }
        else if (!c.postfix.running || !c.rspamd.running) { p.addClass('bad').find('span').text('Служба не запущена'); }
        else { p.addClass('warn').find('span').text('Не применено'); }
        $('#jml-logo').toggleClass('on', on);
    }

    function renderSetup() {
        const all = Object.entries(st.components).filter(([k, c]) => k === 'postfix' || k === 'rspamd' || (k === 'clamav' && draft.antivirus) || (k === 'redis' && draft.greylist));
        $('#jml-setup').toggle(needed().length > 0);
        $('#jml-steps').html(all.map(([k, c], i) => `<li class="${c.installed ? 'done' : ''}"><span class="num">${c.installed ? '<i class="fa fa-check"></i>' : i + 1}</span>
            <div class="tx"><b>${esc(SVC[k][0])}</b><span>${esc(c.package)} · ${esc(SVC[k][1])}</span></div></li>`).join(''));
    }

    function renderNotes() {
        const notes = [];
        (st.forwards || []).forEach((f) => notes.push(['warn', 'fa-exclamation-triangle',
            `Порт 25 пробрасывается на ${esc(f.target)}${f.descr ? ' («' + esc(f.descr) + '»)' : ''}: почта идёт на сервер напрямую, без проверки. Удалите проброс в <a class="lnk" href="/ui/firewall/d_nat">Firewall › NAT</a> после включения шлюза.`]));
        if (base.enabled && draft.antivirus && st.components.clamav.installed && !st.signatures) {
            notes.push(['info', 'fa-info-circle', 'ClamAV загружает антивирусные базы (около 300 МБ). Пока они не скачаны, антивирус не работает.']);
        }
        $('#jml-notes').html(notes.map((n) => `<div class="jml-note ${n[0]}" style="margin:0 0 16px"><i class="fa ${n[1]}"></i><div>${n[2]}</div></div>`).join(''));
    }

    function renderKpis() {
        const s = st.stats;
        $('#k-scanned').text(s ? num(s.scanned) : '—'); $('#k-rejected').text(s ? num(s.rejected) : '—');
        $('#k-spam').text(s ? num(s.spam) : '—'); $('#k-virus').text(s ? num(s.viruses) : '—').toggleClass('bad', !!(s && s.viruses));
    }

    function renderDomains() {
        const ls = domains();
        if (!ls.length) {
            $('#jml-domains').html('<div class="jml-empty"><i class="fa fa-at"></i>Добавьте домен, почту которого принимает ваш сервер внутри сети.</div>');
            return;
        }
        $('#jml-domains').html(ls.map((d) => `<div class="jml-dom ${d.enabled ? '' : 'off'}"><div class="ic"><i class="fa fa-at"></i></div>
            <div class="pm"><div class="pn">${esc(d.domain)}</div><div class="ps">→ <span class="mono">${esc(d.server)}:${esc(d.port)}</span>${d.description ? ' · ' + esc(d.description) : ''}</div></div>
            <div class="pa"><span class="jml-sw ${d.enabled ? 'on' : ''}" data-toggle="${d.uuid}" role="switch" tabindex="0"></span>
            <button class="jml-btn ghost sm icon" data-edit="${d.uuid}" title="Изменить"><i class="fa fa-pencil"></i></button></div></div>`).join(''));
    }

    const verdict = (e) => {
        if (e.virus) { return ['bad', 'fa-bug', 'Вирус: ' + e.virus]; }
        switch (e.action) {
            case 'reject': return ['bad', 'fa-ban', e.attachment ? 'Опасное вложение' : 'Отклонено'];
            case 'add header': case 'rewrite subject': return ['warn', 'fa-exclamation-triangle', 'Спам'];
            case 'greylist': case 'soft reject': return ['warn', 'fa-clock-o', 'Отложено'];
            default: return ['ok', 'fa-check', 'Чистое'];
        }
    };
    function renderEvents() {
        const ev = st.events || [];
        if (!ev.length) {
            $('#jml-events').html(`<div class="jml-empty"><i class="fa fa-inbox"></i>${st.components.rspamd.running ? 'Писем пока не было.' : 'Появятся здесь, когда шлюз заработает.'}</div>`);
            return;
        }
        $('#jml-events').html(ev.slice(0, 10).map((e) => {
            const v = verdict(e);
            return `<div class="jml-msg ${v[0]}"><div class="ei"><i class="fa ${v[1]}"></i></div>
              <div class="et"><div class="sj">${esc(e.subject || '(без темы)')}</div>
                <div class="ew">${esc(e.from || '<>')} → ${esc(e.to)} · ${ago(e.time)}${e.reasons.length ? ' · ' + esc(e.reasons.join(', ')) : ''}</div></div>
              <div class="sc"><span class="jml-chip ${v[0]}">${esc(v[2])}</span><b class="${e.score >= +base.spam_score ? 'muted' : 'muted'}">${e.score.toFixed(1)}</b></div></div>`;
        }).join(''));
    }

    function renderSvcs() {
        const rows = Object.entries(st.components).filter(([k, c]) => c.installed || c.needed).map(([k, c]) => {
            const cls = !c.installed ? 'warn' : (c.running ? 'ok' : (base.enabled && c.needed ? 'bad' : ''));
            const txt = !c.installed ? 'не установлен' : (c.running ? 'работает' : 'остановлен');
            let extra = SVC[k][1];
            if (k === 'clamav' && st.signatures) { extra = 'база ' + esc(st.signatures.daily || '') + (st.signatures.total ? ', сигнатур ' + num(st.signatures.total) : ''); }
            if (k === 'postfix' && st.queue != null) { extra = 'в очереди писем: ' + st.queue; }
            return `<div class="jml-svc"><span class="dot ${cls}"></span><div class="n"><b>${esc(SVC[k][0])}</b><small>${extra}</small></div><span class="jml-chip ${cls}">${txt}</span></div>`;
        });
        $('#jml-svcs').html(rows.join(''));
    }

    function renderSettings() {
        $('#jml-en').toggleClass('on', draft.enabled);
        $('#jml-en-t').text(draft.enabled ? 'Включено' : 'Выключено');
        FLAGS.forEach((f) => $(`[data-sw="${f}"]`).toggleClass('on', draft[f]));
        $('#jml-spam').val(draft.spam_score); $('#jml-spam-v').text(draft.spam_score);
        $('#jml-rej').val(draft.reject_score); $('#jml-rej-v').text(draft.reject_score);
        $('#jml-ifs').html(st.interfaces.map((i) => `<span class="jml-cb ${draft.interfaces.includes(i.name) ? 'sel' : ''}" data-if="${esc(i.name)}">
            <i class="fa ${i.wan ? 'fa-globe' : 'fa-sitemap'}"></i>${esc(i.descr)}</span>`).join(''));
        [['#jml-host', 'hostname'], ['#jml-size', 'max_size'], ['#jml-allow', 'allow_senders']].forEach(([id, k]) => { if (!$(id).is(':focus')) { $(id).val(draft[k]); } });
        $('#jml-host').attr('placeholder', st.hostname || 'mx.example.com');
    }

    function renderAll() { renderHead(); renderSetup(); renderNotes(); renderKpis(); renderDomains(); renderEvents(); renderSvcs(); renderSettings(); }

    async function loadAll(keepDraft) {
        [st, model] = await Promise.all([api('/api/jkufw/mail/status'), api('/api/jkufw/mail/get')]);
        base = fromModel();
        if (!keepDraft || !draft) { draft = JSON.parse(JSON.stringify(base)); }
    }
    async function refresh() {
        try {
            st = await api('/api/jkufw/mail/status');
            $('#jml-error').hide();
            renderHead(); renderNotes(); renderKpis(); renderEvents(); renderSvcs();
            $('#jml-poll').text('обновлено ' + new Date().toLocaleTimeString('ru-RU'));
        } catch (e) { showErr('Нет ответа от экрана: ' + e.message); }
    }
    const showErr = (m) => $('#jml-error').show().find('div').text(m);
    const log = (t) => $('#jml-setup-log').show().text(t);

    async function install(pkg) {
        await api('/api/core/firmware/install/' + pkg, {});
        for (let i = 0; i < 300; i++) {
            await sleep(2000);
            const r = await api('/api/core/firmware/upgradestatus');
            log(pkg + '\n' + (r.log || '').split('\n').slice(-6).join('\n'));
            if (r.status === 'done') { return; }
            if (r.status === 'error') { throw new Error(pkg + ': установка не удалась, см. Система › Прошивка › Журнал'); }
        }
        throw new Error(pkg + ': установка идёт слишком долго');
    }
    $('#jml-install').on('click', async function () {
        const $b = $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i> Устанавливаю…');
        try {
            for (const [, c] of needed()) { await install(c.package); }
            await loadAll(true); renderAll();
        } catch (e) { showErr(e.message); }
        finally { $b.prop('disabled', false).html('<i class="fa fa-download"></i> Установить'); }
    });

    async function freshclam() {
        let r = await api('/api/clamav/service/freshclam', {action: 'go'});
        for (let i = 0; i < 180 && r.status !== 'done'; i++) {
            $('#jml-apply-t').text('ClamAV скачивает антивирусные базы…');
            await sleep(5000);
            r = await api('/api/clamav/service/freshclam', {});
        }
    }
    async function applyAll() {
        if (busy) { return; }
        busy = true;
        const html = $('#jml-apply').html();
        $('#jml-apply').prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i> Применяю…');
        try {
            const g = {enabled: draft.enabled ? '1' : '0', hostname: draft.hostname, interfaces: draft.interfaces.join(','), spam_score: draft.spam_score,
                reject_score: draft.reject_score, max_size: draft.max_size, allow_senders: draft.allow_senders.split(/[\s,;]+/).filter(Boolean).join(',')};
            FLAGS.forEach((f) => { g[f] = draft[f] ? '1' : '0'; });
            saved(await api('/api/jkufw/mail/set', {mail: {general: g}}), 'Настройки');
            const r = await api('/api/jkufw/mail/apply', {});
            if (r.errorMessage) { throw new Error(r.errorMessage); }
            for (const s of r.reconfigure || []) {
                $('#jml-apply-t').text('Перезапускаю ' + s.name + '…');
                if (s.freshclam) { await freshclam(); } else { await api(s.url, {}); }
            }
            pendingDomains = false;
            await loadAll(false);
            $('#jml-applybar').removeClass('show');
            renderAll();
        } catch (e) { showErr('Не удалось применить: ' + e.message); }
        finally { busy = false; $('#jml-apply').prop('disabled', false).html(html); $('#jml-apply-t').text('Они вступят в силу после применения.'); }
    }
    $('#jml-apply').on('click', applyAll);
    $('#jml-revert').on('click', async () => { pendingDomains = false; await loadAll(false); $('#jml-applybar').removeClass('show'); renderAll(); });

    $('#jml-en').on('click keydown', swKey(() => { draft.enabled = !draft.enabled; markDirty(); }));
    $('[data-sw]').on('click keydown', swKey(function () { const f = $(this).data('sw'); draft[f] = !draft[f]; markDirty(); }));
    $('#jml-spam').on('input', function () { draft.spam_score = this.value; if (+draft.reject_score < +this.value + 2) { draft.reject_score = String(+this.value + 2); } markDirty(); });
    $('#jml-rej').on('input', function () { draft.reject_score = this.value; if (+draft.spam_score > +this.value - 2) { draft.spam_score = String(Math.max(2, +this.value - 2)); } markDirty(); });
    $('#jml-ifs').on('click', '.jml-cb', function () {
        const n = String($(this).data('if'));
        draft.interfaces = draft.interfaces.includes(n) ? draft.interfaces.filter((x) => x !== n) : draft.interfaces.concat([n]);
        markDirty();
    });
    $('#jml-host').on('input', function () { draft.hostname = this.value.trim(); markDirty(); });
    $('#jml-size').on('input', function () { draft.max_size = this.value.trim(); markDirty(); });
    $('#jml-allow').on('input', function () { draft.allow_senders = this.value; markDirty(); });

    let editing = null;
    function openDom(uuid) {
        const d = uuid ? domains().find((x) => x.uuid === uuid) : null;
        editing = uuid || null;
        $('#jd-title').text(d ? d.domain : 'Новый домен');
        $('#jd-domain').val(d ? d.domain : ''); $('#jd-server').val(d ? d.server : ''); $('#jd-port').val(d ? d.port : '25'); $('#jd-descr').val(d ? d.description : '');
        $('#jd-del').toggle(!!d); $('#jd-err').text('');
        $('#jml-ov-dom').addClass('open');
        setTimeout(() => $('#jd-domain').trigger('focus'), 50);
    }
    async function reloadModel() { model = await api('/api/jkufw/mail/get'); pendingDomains = true; renderDomains(); markDirty(); }
    $('#jml-add').on('click', () => openDom(null));
    $('#jml-domains').on('click', '[data-edit]', function () { openDom($(this).data('edit')); })
        .on('click keydown', '[data-toggle]', swKey(async function () {
            try { await api('/api/jkufw/mail/toggleDomain/' + $(this).data('toggle'), {}); await reloadModel(); } catch (e) { showErr(e.message); }
        }));
    $('#jd-save').on('click', async () => {
        const dom = {enabled: '1', domain: $('#jd-domain').val().trim().toLowerCase(), server: $('#jd-server').val().trim(),
            port: $('#jd-port').val().trim() || '25', description: $('#jd-descr').val().trim()};
        if (editing) { dom.enabled = domains().find((x) => x.uuid === editing).enabled ? '1' : '0'; }
        try {
            saved(await api(editing ? '/api/jkufw/mail/setDomain/' + editing : '/api/jkufw/mail/addDomain', {domain: dom}));
            $('#jml-ov-dom').removeClass('open');
            if (!editing && !draft.enabled) { draft.enabled = true; }
            await reloadModel();
        } catch (e) { $('#jd-err').text(e.message); }
    });
    $('#jd-del').on('click', async () => {
        try { await api('/api/jkufw/mail/delDomain/' + editing, {}); $('#jml-ov-dom').removeClass('open'); await reloadModel(); } catch (e) { $('#jd-err').text(e.message); }
    });
    $('.jml-ov').on('click', function (e) { if (e.target === this) { $(this).removeClass('open'); } })
        .on('click', '[data-close]', function () { $(this).closest('.jml-ov').removeClass('open'); });
    $(document).on('keydown', (e) => { if (e.key === 'Escape') { $('.jml-ov').removeClass('open'); } });

    (async () => {
        try {
            await loadAll(false);
            $('#jml-loading').hide(); $('#jml-main').show();
            renderAll();
            setInterval(() => { if (!busy && !document.hidden) { refresh(); } }, POLL_MS);
        } catch (e) { $('#jml-loading').hide(); showErr('Не удалось загрузить: ' + e.message); }
    })();
});
</script>
