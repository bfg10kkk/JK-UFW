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
 # jk-ufw: SD-WAN. Several internet links behave like one: every link is checked all the time
 # (latency, jitter, loss), traffic moves to a healthy link by itself (failover) or is spread over
 # all of them (load balancing), and traffic routes send chosen devices or apps over a chosen link.
 # Data comes from /api/jkufw/sdwan/*, which turns the settings into ordinary gateways, gateway groups,
 # aliases and floating rules (see models/OPNsense/JkUfw/Sdwan.php).
 #}

<style>
.jsd { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1240px; }
.jsd * { box-sizing:border-box; }
.jsd b, .jsd strong { font-family:inherit; font-weight:700; }
.jsd .mono { font-family:ui-monospace,Menlo,Consolas,monospace; }
.jsd .muted { color:var(--m); }
.jsd a.lnk { color:var(--a2); }
.jsd-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jsd-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:23px; flex:none;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jsd-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jsd-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jsd-sub { color:var(--m); margin-top:2px; }
.jsd-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jsd-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jsd-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jsd-pill.warn i { background:var(--warn); }
.jsd-pill.bad i { background:var(--a); }
.jsd-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jsd-grid { display:grid; grid-template-columns:minmax(0,1.5fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1050px) { .jsd-grid { grid-template-columns:minmax(0,1fr); } }
.jsd-grid > div { min-width:0; }
.jsd-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jsd-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.jsd-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; display:flex; gap:8px; align-items:center; }
.jsd-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 760px) { .jsd-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jsd-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; min-width:0; }
.jsd-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jsd-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jsd-kpi .v small { font-size:13px; color:var(--m); font-weight:600; margin-left:3px; }
.jsd-kpi .v.ok { color:var(--ok); } .jsd-kpi .v.bad { color:var(--a2); } .jsd-kpi .v.warn { color:var(--warn); }
/* flow diagram */
.jsd-flow { padding:10px 18px 6px; background:radial-gradient(ellipse at 40% 0%,rgba(229,32,46,.10),rgba(229,32,46,0) 60%), var(--s); }
.jsd-flow svg { display:block; width:100%; height:auto; }
.jsd-flow text { font-family:inherit; }
@keyframes jsdflow { to { stroke-dashoffset:-24; } }
.jsd-flow .live { stroke-dasharray:7 5; animation:jsdflow .9s linear infinite; }
@media (prefers-reduced-motion: reduce) { .jsd-flow .live { animation:none; } }
/* link cards */
.jsd-links { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:12px; }
@media (max-width: 640px) { .jsd-links { grid-template-columns:minmax(0,1fr); } }
.jsd-link { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; position:relative; min-width:0; }
.jsd-link.carry { border-color:rgba(229,32,46,.55); box-shadow:inset 0 0 0 1px rgba(229,32,46,.25); }
.jsd-link.off { opacity:.6; }
.jsd-link-top { display:flex; align-items:center; gap:10px; }
.jsd-link-ic { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:16px; flex:none; position:relative; }
.jsd-link.carry .jsd-link-ic { background:var(--abg); color:var(--a2); }
.jsd-link-ic .dot { position:absolute; right:-2px; bottom:-2px; width:11px; height:11px; border-radius:50%; background:#3a3a42; border:2px solid var(--s2); }
.dot.ok { background:var(--ok) !important; } .dot.warn { background:var(--warn) !important; } .dot.bad { background:var(--a) !important; }
.jsd-link-n { font-weight:700; font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jsd-link-s { color:var(--m); font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jsd-link-m { flex:1; min-width:0; }
.jsd-chip { display:inline-flex; align-items:center; gap:5px; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; background:#232329; color:var(--m); white-space:nowrap; }
.jsd-chip.acc { background:var(--abg); color:var(--a2); }
.jsd-chip.ok { background:rgba(34,197,94,.12); color:#4ade80; }
.jsd-chip.warn { background:rgba(245,165,36,.12); color:var(--warn); }
.jsd-chip.bad { background:var(--abg); color:#ff6b74; }
.jsd-stats { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; margin:14px 0 8px; }
.jsd-stats .l { color:var(--m); font-size:10.5px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jsd-stats .v { font-size:18px; font-weight:700; letter-spacing:-.02em; }
.jsd-stats .v small { font-size:11px; color:var(--m); margin-left:2px; font-weight:600; }
.jsd-spark { height:44px; }
.jsd-spark svg { width:100%; height:100%; display:block; }
.jsd-strip { display:flex; gap:2px; margin-top:6px; }
.jsd-strip i { flex:1; height:6px; border-radius:2px; background:#26262c; }
.jsd-strip i.ok { background:rgba(34,197,94,.75); } .jsd-strip i.warn { background:var(--warn); } .jsd-strip i.bad { background:var(--a); }
.jsd-tr { display:flex; gap:14px; margin-top:10px; color:var(--m); font-size:12px; align-items:center; }
.jsd-tr b { color:var(--t); font-weight:600; }
.jsd-util { height:4px; border-radius:2px; background:#26262c; margin-top:8px; overflow:hidden; }
.jsd-util i { display:block; height:100%; background:linear-gradient(90deg,#a5121c,var(--a2)); }
/* buttons, fields */
.jsd-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important;
  display:inline-flex; align-items:center; gap:7px; text-decoration:none !important; white-space:nowrap; }
.jsd-btn:hover { background:var(--a2); }
.jsd-btn[disabled] { opacity:.5; cursor:default; }
.jsd-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jsd-btn.ghost:hover { background:var(--h); }
.jsd-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jsd-btn.icon { padding:6px 9px; }
.jsd-btn.danger:hover { color:var(--a2) !important; border-color:rgba(229,32,46,.5); }
.jsd-sw { display:inline-block; vertical-align:middle; flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jsd-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jsd-sw.on { background:var(--a); }
.jsd-sw.on::after { left:16px; background:#fff; }
.jsd-seg { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
.jsd-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; cursor:pointer; transition:all .15s; min-width:0; }
.jsd-opt:hover { border-color:var(--b2); background:var(--h); }
.jsd-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jsd-opt .nm { font-weight:700; font-size:13.5px; }
.jsd-opt .nm .fa { color:var(--m); margin-right:6px; }
.jsd-opt.sel .nm .fa { color:var(--a2); }
.jsd-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jsd-field { margin-bottom:14px; }
.jsd-field > label { display:block; font-weight:600; margin-bottom:6px; }
.jsd-field .hint { color:var(--m); font-size:12px; margin-top:5px; line-height:1.45; }
.jsd input.jsd-in, .jsd select.jsd-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:9px 11px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:12.5px; box-shadow:none !important; }
.jsd input.jsd-in:focus, .jsd select.jsd-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg) !important; }
.jsd input.jsd-in.bad { border-color:var(--a) !important; }
.jsd-row2 { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:12px; }
@media (max-width: 560px) { .jsd-row2, .jsd-seg { grid-template-columns:minmax(0,1fr); } }
.jsd-tg { display:flex; gap:12px; align-items:flex-start; padding:11px 0; border-top:1px solid var(--b); }
.jsd-tg:first-of-type { border-top:0; }
.jsd-tg .tx { flex:1; min-width:0; }
.jsd-tg .tx b { display:block; }
.jsd-tg .tx span { color:var(--m); font-size:12px; line-height:1.45; }
.jsd-order { margin:0; padding:0; list-style:none; }
.jsd-order li { display:flex; align-items:center; gap:10px; padding:9px 10px; border:1px solid var(--b); background:var(--s2); border-radius:10px; margin-bottom:8px; }
.jsd-order li.out { opacity:.55; }
.jsd-order .num { width:24px; height:24px; border-radius:7px; display:grid; place-items:center; font-weight:700; font-size:12px; background:var(--abg); color:var(--a2); flex:none; }
.jsd-order li.out .num { background:#232329; color:var(--m); }
.jsd-order .nm { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jsd-order .nm small { color:var(--m); font-weight:500; margin-left:6px; }
.jsd-order .ctl { display:flex; gap:4px; align-items:center; flex:none; }
.jsd-order .wt { min-width:46px; text-align:center; font-weight:700; }
.jsd-chips { display:flex; gap:8px; flex-wrap:wrap; }
.jsd-cb { display:inline-flex; align-items:center; gap:7px; padding:7px 11px; border:1px solid var(--b); background:var(--s2); border-radius:9px; cursor:pointer; font-weight:600; font-size:12.5px; }
.jsd-cb .fa { color:var(--m); }
.jsd-cb.sel { border-color:var(--a); background:var(--abg); }
.jsd-cb.sel .fa { color:var(--a2); }
.jsd-cb small { color:var(--m); font-weight:500; }
.jsd-pol { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jsd-pol:first-child { border-top:0; padding-top:0; }
.jsd-pol .ic { width:38px; height:38px; border-radius:10px; display:grid; place-items:center; background:var(--abg); color:var(--a2); font-size:16px; flex:none; }
.jsd-pol.off .ic { background:#202026; color:var(--m); }
.jsd-pol.off .pm { opacity:.6; }
.jsd-pol .pm { flex:1; min-width:0; }
.jsd-pol .pn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jsd-pol .ps { color:var(--m); font-size:11.5px; margin-top:2px; overflow-wrap:anywhere; }
.jsd-pol .arrow { display:flex; align-items:center; gap:6px; flex:none; font-weight:600; }
.jsd-pol .pa { display:flex; gap:6px; align-items:center; flex:none; }
@media (max-width: 560px) { .jsd-pol { flex-wrap:wrap; } .jsd-pol .arrow { order:3; width:100%; padding-left:50px; } }
.jsd-ev { display:flex; gap:11px; padding:9px 0; border-top:1px solid var(--b); }
.jsd-ev:first-child { border-top:0; padding-top:0; }
.jsd-ev .ei { width:28px; height:28px; border-radius:8px; display:grid; place-items:center; flex:none; background:#202026; color:var(--m); font-size:12.5px; }
.jsd-ev.bad .ei { background:var(--abg); color:var(--a2); }
.jsd-ev.ok .ei { background:rgba(34,197,94,.12); color:var(--ok); }
.jsd-ev.warn .ei { background:rgba(245,165,36,.12); color:var(--warn); }
.jsd-ev .et { flex:1; min-width:0; line-height:1.4; }
.jsd-ev .ew { color:var(--m); font-size:11.5px; }
.jsd-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jsd-note .fa { margin-top:2px; }
.jsd-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jsd-note.warn .fa { color:var(--warn); }
.jsd-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jsd-note.err { background:var(--abg); border:1px solid rgba(229,32,46,.4); color:#ffb3b8; }
.jsd-empty { color:var(--m); text-align:center; padding:24px 6px; }
.jsd-empty .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }
.jsd-hero { display:flex; gap:18px; align-items:center; padding:22px; background:linear-gradient(120deg,rgba(229,32,46,.14),rgba(229,32,46,0) 60%), var(--s); }
.jsd-hero .big { font-size:17px; font-weight:700; }
.jsd-hero .ds { color:var(--m); margin-top:4px; line-height:1.5; }
.jsd-applybar { position:sticky; bottom:12px; z-index:5; display:none; align-items:center; gap:12px; padding:12px 14px; margin-bottom:16px;
  background:#1b1114; border:1px solid rgba(229,32,46,.45); border-radius:12px; box-shadow:0 10px 30px rgba(0,0,0,.5); }
.jsd-applybar.show { display:flex; }
.jsd-applybar .tx { flex:1; min-width:0; }
/* modal */
.jsd-ov { max-width:none; font-size:13px; position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.72); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; padding:16px; }
.jsd-ov.open { display:flex; }
.jsd-modal { width:100%; max-width:560px; max-height:calc(100vh - 32px); overflow:auto; background:var(--s); border:1px solid var(--b2); border-radius:14px;
  padding:22px; box-shadow:0 20px 60px rgba(0,0,0,.6); color:var(--t); }
.jsd-modal h4 { margin:0 0 4px; font-size:17px; font-weight:700; }
.jsd-modal .sub { color:var(--m); margin-bottom:16px; line-height:1.5; }
.jsd-modal .ft { display:flex; gap:8px; justify-content:flex-end; margin-top:18px; flex-wrap:wrap; }
.jsd-apps { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; }
@media (max-width: 480px) { .jsd-apps { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jsd-app { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 4px; text-align:center; cursor:pointer; font-size:11.5px; font-weight:600; line-height:1.25; }
.jsd-app .fa { display:block; font-size:18px; margin-bottom:6px; color:var(--m); }
.jsd-app.sel { border-color:var(--a); background:var(--abg); }
.jsd-app.sel .fa { color:var(--a2); }
.jsd-err { color:#ff8a92; font-size:12px; margin-top:10px; }
</style>

<div class="jsd" id="jsd">
  <div class="jsd-head">
    <div class="jsd-logo" id="jsd-logo"><i class="fa fa-random"></i></div>
    <div>
      <h1 class="jsd-title">SD-WAN <span class="jsd-pill" id="jsd-pill"><i></i><span>…</span></span></h1>
      <div class="jsd-sub">Несколько интернет-каналов как один: проверка связи, резерв, балансировка и маршруты для приложений</div>
    </div>
    <div class="jsd-head-r">
      <a class="jsd-btn ghost" href="/ui/diagnostics/log/core/gateways"><i class="fa fa-list-alt"></i> Журнал</a>
      <a class="jsd-btn ghost" href="/ui/routing/configuration"><i class="fa fa-sliders"></i> Шлюзы</a>
    </div>
  </div>

  <div id="jsd-loading" class="jsd-card"><div class="jsd-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></div>
  <div id="jsd-error" class="jsd-note err" style="display:none; margin:0 0 16px"><i class="fa fa-exclamation-circle"></i><div></div></div>

  <div id="jsd-main" style="display:none">
    <div class="jsd-card jsd-hero" id="jsd-intro" style="display:none">
      <div class="jsd-logo on"><i class="fa fa-random"></i></div>
      <div style="flex:1; min-width:0">
        <div class="big" id="jsd-intro-t">Два провайдера лучше одного</div>
        <div class="ds" id="jsd-intro-d"></div>
      </div>
      <button class="jsd-btn" id="jsd-intro-go" style="display:none"><i class="fa fa-power-off"></i> Включить SD-WAN</button>
    </div>

    <div class="jsd-kpis">
      <div class="jsd-kpi"><div class="l">Каналы в сети</div><div class="v" id="k-up">—</div></div>
      <div class="jsd-kpi"><div class="l">Режим</div><div class="v" id="k-mode">—</div></div>
      <div class="jsd-kpi"><div class="l">Скорость сейчас</div><div class="v" id="k-rate">—</div></div>
      <div class="jsd-kpi"><div class="l">Сбоев за 24 часа</div><div class="v" id="k-fail">—</div></div>
    </div>

    <div class="jsd-card jsd-flow"><div id="jsd-flow"></div></div>

    <div class="jsd-applybar" id="jsd-applybar">
      <i class="fa fa-pencil" style="color:var(--a2)"></i>
      <div class="tx"><b>Есть несохранённые изменения.</b> <span class="muted">Они вступят в силу после применения.</span></div>
      <button class="jsd-btn ghost sm" id="jsd-revert">Отменить</button>
      <button class="jsd-btn sm" id="jsd-apply"><i class="fa fa-check"></i> Применить</button>
    </div>

    <div class="jsd-grid">
      <div>
        <div class="jsd-card">
          <h3><i class="fa fa-plug"></i> Интернет-каналы <span class="r muted" id="jsd-poll"></span></h3>
          <div class="jsd-links" id="jsd-links"></div>
        </div>
        <div class="jsd-card">
          <h3><i class="fa fa-code-fork"></i> Маршруты трафика
            <span class="r"><button class="jsd-btn sm" id="jsd-pol-add"><i class="fa fa-plus"></i> Добавить маршрут</button></span></h3>
          <div id="jsd-pols"></div>
        </div>
      </div>
      <div>
        <div class="jsd-card">
          <h3><i class="fa fa-cogs"></i> Как использовать каналы
            <span class="r"><span class="muted" id="jsd-en-t">Выключено</span><span class="jsd-sw" id="jsd-en" role="switch" tabindex="0" aria-label="SD-WAN"></span></span></h3>
          <div class="jsd-seg" id="jsd-mode">
            <div class="jsd-opt" data-mode="failover"><div class="nm"><i class="fa fa-life-ring"></i>Резерв</div>
              <div class="ds">Работает первый канал. Пропал — через секунды всё идёт по следующему, вернулся — обратно.</div></div>
            <div class="jsd-opt" data-mode="balance"><div class="nm"><i class="fa fa-balance-scale"></i>Балансировка</div>
              <div class="ds">Все исправные каналы работают вместе, нагрузка делится по весам. Сломанный канал выпадает сам.</div></div>
          </div>
          <div class="jsd-field" style="margin-top:16px">
            <label id="jsd-order-l">Порядок каналов</label>
            <ul class="jsd-order" id="jsd-order"></ul>
            <div class="hint" id="jsd-order-h"></div>
          </div>
          <div class="jsd-field">
            <label>Канал считается сломанным, если</label>
            <div class="jsd-chips" id="jsd-trigger">
              <span class="jsd-cb" data-v="down"><i class="fa fa-unlink"></i>нет связи</span>
              <span class="jsd-cb" data-v="downloss"><i class="fa fa-tint"></i>или потери пакетов</span>
              <span class="jsd-cb" data-v="downlosslatency"><i class="fa fa-hourglass-half"></i>или потери и задержка</span>
            </div>
            <div class="hint">Пороги: потери от 10–20 %, задержка от 200–500 мс. Их можно поменять у шлюза.</div>
          </div>
          <div class="jsd-field">
            <label>Какие сети ходят в интернет через SD-WAN</label>
            <div class="jsd-chips" id="jsd-lans"></div>
            <div class="hint">Гостевую сеть с порталом авторизации лучше не отмечать: правила SD-WAN срабатывают раньше портала.</div>
          </div>
          <div class="jsd-tg"><div class="tx"><b>Один клиент — один канал</b><span>При балансировке устройство держится одного канала: банки и сайты с входом не разлогинивают.</span></div>
            <span class="jsd-sw" id="jsd-sticky" role="switch" tabindex="0"></span></div>
          <div class="jsd-tg"><div class="tx"><b>Быстрое переключение</b><span>При сбое канала оборвать его соединения, чтобы звонки и игры сразу переподключились по другому.</span></div>
            <span class="jsd-sw" id="jsd-kill" role="switch" tabindex="0"></span></div>
        </div>
        <div class="jsd-card">
          <h3><i class="fa fa-history"></i> События каналов</h3>
          <div id="jsd-events"></div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- link settings -->
<div class="jsd jsd-ov" id="jsd-ov-link" role="dialog" aria-modal="true">
  <div class="jsd-modal">
    <h4 id="jl-title">Канал</h4>
    <div class="sub" id="jl-sub"></div>
    <div class="jsd-field"><label for="jl-label">Название</label>
      <input class="jsd-in" id="jl-label" type="text" maxlength="40" placeholder="Например: Оптика, LTE-модем"/></div>
    <div class="jsd-row2">
      <div class="jsd-field"><label for="jl-monitor">Адрес для проверки</label>
        <input class="jsd-in mono" id="jl-monitor" type="text" placeholder="1.1.1.1"/>
        <div class="hint">Пингуется через этот канал раз в секунду. У каждого канала свой.</div></div>
      <div class="jsd-field"><label for="jl-speed">Скорость тарифа, Мбит/с</label>
        <input class="jsd-in" id="jl-speed" type="text" inputmode="numeric" placeholder="100"/>
        <div class="hint">Для полосы загрузки на карточке. Можно не указывать.</div></div>
    </div>
    <div class="jsd-field" id="jl-weight-f"><label>Вес при балансировке: <b id="jl-weight-v">1</b></label>
      <input id="jl-weight" type="range" min="1" max="10" step="1" value="1" style="width:100%; accent-color:#e5202e"/>
      <div class="hint">Канал с весом 3 получает втрое больше новых соединений, чем канал с весом 1.</div></div>
    <div class="jsd-err" id="jl-err"></div>
    <div class="ft">
      <button class="jsd-btn ghost" data-close>Отмена</button>
      <button class="jsd-btn" id="jl-save"><i class="fa fa-check"></i> Сохранить</button>
    </div>
  </div>
</div>

<!-- traffic route -->
<div class="jsd jsd-ov" id="jsd-ov-pol" role="dialog" aria-modal="true">
  <div class="jsd-modal">
    <h4 id="jp-title">Новый маршрут</h4>
    <div class="sub">Пустите выбранный трафик через нужный канал: игры через оптику, камеры через LTE, работу через стабильного провайдера.</div>
    <div class="jsd-field"><label for="jp-name">Название</label>
      <input class="jsd-in" id="jp-name" type="text" maxlength="48" placeholder="Например: Игры через оптику"/></div>
    <div class="jsd-field"><label>Какой трафик</label>
      <div class="jsd-apps" id="jp-apps"></div></div>
    <div class="jsd-row2" id="jp-custom" style="display:none">
      <div class="jsd-field"><label for="jp-ports">Порты</label>
        <input class="jsd-in mono" id="jp-ports" type="text" placeholder="5060, 10000-20000"/></div>
      <div class="jsd-field"><label for="jp-proto">Протокол</label>
        <select class="jsd-in" id="jp-proto"><option value="TCP/UDP">TCP и UDP</option><option value="TCP">TCP</option><option value="UDP">UDP</option></select></div>
    </div>
    <div class="jsd-field"><label for="jp-src">Устройства</label>
      <input class="jsd-in mono" id="jp-src" type="text" placeholder="все устройства"/>
      <div class="hint">IP-адреса или подсети через запятую, например 192.168.1.20, 192.168.1.64/28. Пусто — все устройства.
        Удобно закрепить адреса на странице <a class="lnk" href="/ui/jkufw/devices">Устройства</a>.</div></div>
    <div class="jsd-field"><label for="jp-dst">Куда</label>
      <input class="jsd-in mono" id="jp-dst" type="text" placeholder="любые адреса в интернете"/>
      <div class="hint">Необязательно: адреса или подсети сервиса, например офисного VPN-сервера.</div></div>
    <div class="jsd-field"><label>Через канал</label>
      <div class="jsd-chips" id="jp-wan"></div></div>
    <div class="jsd-tg" style="border-top:0; padding-top:0"><div class="tx"><b>Если канал недоступен — через другие</b>
      <span>Выключите, если этот трафик не должен уходить через другой канал ни при каких условиях.</span></div>
      <span class="jsd-sw on" id="jp-fb" role="switch" tabindex="0"></span></div>
    <div class="jsd-err" id="jp-err"></div>
    <div class="ft">
      <button class="jsd-btn ghost" data-close>Отмена</button>
      <button class="jsd-btn" id="jp-save"><i class="fa fa-check"></i> Сохранить</button>
    </div>
  </div>
</div>

<script>
'use strict';
$(function () {
    const POLL_MS = 5000;
    const HIST = 72;       // samples kept per link (6 minutes at 5 s)
    const APPS = {
        any: ['fa-globe', 'Весь трафик', ''],
        web: ['fa-window-maximize', 'Сайты', 'порты 80, 443'],
        calls: ['fa-phone', 'Звонки и видеосвязь', 'Zoom, Meet, Teams, SIP'],
        gaming: ['fa-gamepad', 'Игры', 'Xbox, PlayStation, Steam'],
        mail: ['fa-envelope', 'Почта', 'SMTP, IMAP, POP3'],
        remote: ['fa-desktop', 'Удалённый доступ', 'RDP, SSH, VNC, TeamViewer'],
        vpn: ['fa-lock', 'VPN', 'IPsec, OpenVPN, WireGuard'],
        custom: ['fa-sliders', 'Свои порты', '']
    };
    const MODE = {failover: 'Резерв', balance: 'Балансировка'};

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
    // option and list fields come back as {key: {value, selected}}
    const pick = (v) => {
        if (v == null) { return ''; }
        if (typeof v !== 'object') { return String(v); }
        return Object.keys(v).filter((k) => String(v[k].selected) === '1').join(',');
    };
    const list = (v) => pick(v).split(',').filter(Boolean);
    const rate = (bps) => {
        if (bps == null || !isFinite(bps)) { return ['—', '']; }
        const u = ['бит/с', 'Кбит/с', 'Мбит/с', 'Гбит/с'];
        let i = 0;
        while (bps >= 1000 && i < u.length - 1) { bps /= 1000; i++; }
        return [bps.toFixed(bps < 10 && i ? 1 : 0), u[i]];
    };
    const store = {
        get(k, d) { try { const v = JSON.parse(localStorage.getItem(k)); return v == null ? d : v; } catch (e) { return d; } },
        set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* private mode */ } }
    };

    let st = null;          // last /status
    let model = null;       // last /get
    let draft = null;       // general settings being edited
    let busy = false;
    const prev = {};        // previous byte counters per link, for rates
    const rates = {};

    const health = (l) => {
        if (l.disabled) { return ['', 'Выключен']; }
        if (!l.monitoring) { return ['', 'Без проверки']; }
        switch (l.status) {
            case 'none': return ['ok', 'В сети'];
            case 'loss': return ['warn', 'Потери'];
            case 'delay': return ['warn', 'Задержка'];
            case 'delay+loss': return ['warn', 'Потери и задержка'];
            case 'down': return ['bad', 'Нет связи'];
            case 'force_down': return ['bad', 'Отключён вручную'];
            default: return ['', 'Проверка…'];
        }
    };
    const linkName = (l) => l.label || l.descr || l.name;
    const linkByName = (n) => (st ? st.links.find((l) => l.name === n) : null);
    const linkIcon = (l) => /lte|4g|5g|modem|mobile|мтс|билайн|мегафон|теле2|yota/i.test(l.label + ' ' + l.descr + ' ' + l.interface_descr) ? 'fa-signal' : 'fa-globe';

    // ---- settings draft -------------------------------------------------------------------------
    const fromModel = () => {
        const g = model.sdwan.general;
        const members = list(g.members).length ? pick(g.members).split(',') : [];
        return {
            enabled: String(g.enabled) === '1',
            mode: pick(g.mode) || 'failover',
            members: members,
            trigger: pick(g.trigger) || 'downloss',
            sticky: String(g.sticky) === '1',
            killstates: String(g.killstates) === '1',
            lans: list(g.lans)
        };
    };
    let saved_draft = null;
    const dirty = () => JSON.stringify(draft) !== JSON.stringify(saved_draft);
    const markDirty = () => { $('#jsd-applybar').toggleClass('show', dirty() || pendingPolicies); renderSettings(); renderFlow(); renderKpis(); };
    let pendingPolicies = false;

    // members list as edited: CSVListField keeps the posted order
    const orderedLinks = () => {
        const ls = (st ? st.links : []).filter((l) => !l.disabled);
        const inList = draft.members.map((n) => ls.find((l) => l.name === n)).filter(Boolean);
        return inList.concat(ls.filter((l) => !draft.members.includes(l.name)));
    };

    // ---- rendering ------------------------------------------------------------------------------
    function renderHead() {
        const en = saved_draft.enabled && st.applied_rules > 0;
        const members = st.links.filter((l) => saved_draft.members.includes(l.name));
        const up = members.filter((l) => ['ok', 'warn'].includes(health(l)[0])).length;
        const clean = members.filter((l) => health(l)[0] === 'ok').length;
        let cls = '', txt = 'Выключено';
        if (en) {
            if (clean === members.length) { cls = 'ok'; txt = 'Работает'; }
            else if (up === members.length) { cls = 'warn'; txt = 'Работает, есть помехи'; }
            else if (up > 0) { cls = 'warn'; txt = 'Работает на ' + up + ' из ' + members.length; }
            else { cls = 'bad'; txt = 'Нет интернета'; }
        }
        $('#jsd-pill').attr('class', 'jsd-pill ' + cls).find('span').text(txt);
        $('#jsd-logo').toggleClass('on', en);

        const wans = st.links.filter((l) => !l.disabled);
        const $i = $('#jsd-intro');
        if (wans.length < 2) {
            $('#jsd-intro-t').text('Подключите второй канал');
            $('#jsd-intro-d').html('Сейчас у экрана ' + (wans.length ? 'один выход в интернет' : 'нет выхода в интернет') +
                '. Подключите второго провайдера или LTE-модем к свободному порту, назначьте его на странице ' +
                '<a class="lnk" href="/interfaces_assign.php">Интерфейсы › Назначения</a> и включите получение адреса по DHCP. ' +
                'Канал сразу появится здесь.');
            $('#jsd-intro-go').hide();
            $i.show();
        } else if (!saved_draft.enabled) {
            $('#jsd-intro-t').text('Два провайдера лучше одного');
            $('#jsd-intro-d').text('Найдено каналов: ' + wans.length + '. Включите SD-WAN — экран начнёт проверять каждый канал и сам ' +
                'переключит интернет, если провайдер пропадёт. Порядок, режим и маршруты можно настроить ниже.');
            $('#jsd-intro-go').show();
            $i.show();
        } else {
            $i.hide();
        }
    }

    function renderKpis() {
        const members = st.links.filter((l) => saved_draft.members.includes(l.name));
        const up = members.filter((l) => ['ok', 'warn'].includes(health(l)[0])).length;
        $('#k-up').attr('class', 'v ' + (!members.length ? '' : up === members.length ? 'ok' : up ? 'warn' : 'bad'))
            .html(members.length ? up + '<small>из ' + members.length + '</small>' : '—');
        $('#k-mode').text(saved_draft.enabled ? MODE[saved_draft.mode] : 'Выключен');
        let total = 0, any = false;
        st.links.forEach((l) => { if (rates[l.name]) { total += rates[l.name].down + rates[l.name].up; any = true; } });
        const r = rate(any ? total : null);
        $('#k-rate').html(esc(r[0]) + (r[1] ? '<small>' + r[1] + '</small>' : ''));
        const day = Date.now() - 86400000;
        const fails = (st.events || []).filter((e) => e.to === 'down' && e.time && Date.parse(e.time) > day).length;
        $('#k-fail').attr('class', 'v ' + (fails ? 'warn' : 'ok')).text(fails);
    }

    function renderFlow() {
        const links = orderedLinks();
        if (!links.length) { $('#jsd-flow').html('<div class="jsd-empty"><i class="fa fa-plug"></i>Нет интернет-каналов</div>'); return; }
        if ($('#jsd-flow').width() < 640) { renderFlowNarrow(links); return; }
        const n = links.length;
        const H = Math.max(170, 64 * n + 40), W = 960, cy = H / 2;
        const lanX = 110, fwX = 380, lkX = 640, netX = 880;
        const lanNames = (st.lans || []).filter((l) => draft.lans.includes(l.name)).map((l) => l.descr);
        const lanText = lanNames.length ? lanNames.join(', ') : 'Нет сетей';
        let svg = '';
        // LAN -> firewall
        svg += `<path d="M${lanX + 46} ${cy} L${fwX - 52} ${cy}" stroke="#e5202e" stroke-width="2.5" fill="none" class="${saved_draft.enabled ? 'live' : ''}" opacity="${saved_draft.enabled ? 1 : .35}"/>`;
        links.forEach((l, i) => {
            const y = n === 1 ? cy : 20 + (H - 40) * (i + .5) / n;
            const [cls] = health(l);
            const member = draft.members.includes(l.name);
            const carry = saved_draft.enabled && l.carrying;
            const col = carry ? '#e5202e' : cls === 'bad' ? '#7a1a20' : '#3a3a42';
            const dash = carry ? 'class="live"' : member ? 'stroke-dasharray="4 6"' : 'stroke-dasharray="2 8"';
            const c1 = fwX + 120, c2 = lkX - 140;
            svg += `<path d="M${fwX + 52} ${cy} C${c1} ${cy} ${c2} ${y} ${lkX - 92} ${y}" stroke="${col}" stroke-width="${carry ? 2.5 : 1.6}" fill="none" ${dash}/>`;
            svg += `<path d="M${lkX + 92} ${y} C${lkX + 150} ${y} ${netX - 100} ${cy} ${netX - 40} ${cy}" stroke="${col}" stroke-width="${carry ? 2.5 : 1.6}" fill="none" ${dash}/>`;
            const dot = {ok: '#22c55e', warn: '#f5a524', bad: '#e5202e'}[cls] || '#55555f';
            const lat = l.delay != null && cls !== 'bad' ? l.delay.toFixed(0) + ' мс' : health(l)[1];
            const tag = !member ? 'не используется' : !saved_draft.enabled ? 'готов' : carry ? (saved_draft.mode === 'balance' ? 'в работе' : 'основной сейчас') :
                (saved_draft.mode === 'failover' ? 'резерв' : (cls === 'bad' ? 'выпал' : 'ожидает'));
            svg += `<g>
                <rect x="${lkX - 92}" y="${y - 24}" width="184" height="48" rx="11" fill="${carry ? 'rgba(229,32,46,.12)' : '#18181c'}" stroke="${carry ? '#e5202e' : '#2e2e35'}"/>
                <circle cx="${lkX - 72}" cy="${y - 6}" r="4.5" fill="${dot}"/>
                <text x="${lkX - 60}" y="${y - 2}" fill="#e8e8ec" font-size="13.5" font-weight="700">${esc(linkName(l).length > 19 ? linkName(l).slice(0, 18) + '…' : linkName(l))}</text>
                <text x="${lkX - 78}" y="${y + 15}" fill="#8d8d98" font-size="11.5">${esc(tag)} · ${esc(lat)}</text>
            </g>`;
        });
        // nodes
        svg += `<g><rect x="${lanX - 70}" y="${cy - 30}" width="140" height="60" rx="14" fill="#18181c" stroke="#2e2e35"/>
            <text x="${lanX}" y="${cy - 4}" text-anchor="middle" fill="#e8e8ec" font-size="13.5" font-weight="700">Локальная сеть</text>
            <text x="${lanX}" y="${cy + 15}" text-anchor="middle" fill="#8d8d98" font-size="11.5">${esc(lanText.slice(0, 22))}</text></g>`;
        svg += `<g><rect x="${fwX - 52}" y="${cy - 40}" width="104" height="80" rx="18" fill="url(#jsdg)" stroke="none"/>
            <text x="${fwX}" y="${cy - 2}" text-anchor="middle" fill="#fff" font-size="15" font-weight="800">jk-ufw</text>
            <text x="${fwX}" y="${cy + 17}" text-anchor="middle" fill="rgba(255,255,255,.8)" font-size="11.5">${saved_draft.enabled ? esc(MODE[saved_draft.mode].toLowerCase()) : 'SD-WAN выкл.'}</text></g>`;
        svg += `<g><circle cx="${netX}" cy="${cy}" r="40" fill="#18181c" stroke="#2e2e35"/>
            <text x="${netX}" y="${cy + 5}" text-anchor="middle" fill="#e8e8ec" font-size="13" font-weight="700">Интернет</text></g>`;
        $('#jsd-flow').html(`<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Схема каналов">
            <defs><linearGradient id="jsdg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff3b47"/><stop offset="1" stop-color="#a5121c"/></linearGradient></defs>${svg}</svg>`);
    }

    // phones: top to bottom, links side by side
    function renderFlowNarrow(links) {
        const n = links.length, W = 360, bw = Math.min(150, (W - 20) / n - 8);
        const lanY = 34, fwY = 120, lkY = 228, netY = 326, H = 366;
        const lanNames = (st.lans || []).filter((l) => draft.lans.includes(l.name)).map((l) => l.descr);
        let svg = `<path d="M180 ${lanY + 24} L180 ${fwY - 32}" stroke="#e5202e" stroke-width="2.5" fill="none" class="${saved_draft.enabled ? 'live' : ''}" opacity="${saved_draft.enabled ? 1 : .35}"/>`;
        links.forEach((l, i) => {
            const x = W / 2 + (i - (n - 1) / 2) * (bw + 8);
            const [cls] = health(l);
            const member = draft.members.includes(l.name);
            const carry = saved_draft.enabled && l.carrying;
            const col = carry ? '#e5202e' : cls === 'bad' ? '#7a1a20' : '#3a3a42';
            const dash = carry ? 'class="live"' : member ? 'stroke-dasharray="4 6"' : 'stroke-dasharray="2 8"';
            svg += `<path d="M180 ${fwY + 32} C180 ${fwY + 70} ${x} ${lkY - 70} ${x} ${lkY - 26}" stroke="${col}" stroke-width="${carry ? 2.5 : 1.6}" fill="none" ${dash}/>`;
            svg += `<path d="M${x} ${lkY + 26} C${x} ${lkY + 60} 180 ${netY - 60} 180 ${netY - 26}" stroke="${col}" stroke-width="${carry ? 2.5 : 1.6}" fill="none" ${dash}/>`;
            const dot = {ok: '#22c55e', warn: '#f5a524', bad: '#e5202e'}[cls] || '#55555f';
            const lat = l.delay != null && cls !== 'bad' ? l.delay.toFixed(0) + ' мс' : health(l)[1];
            const maxc = Math.max(5, Math.floor((bw - 26) / 7.6));
            const short = (t) => (t.length > maxc ? t.slice(0, maxc - 1) + '…' : t);
            svg += `<g><rect x="${x - bw / 2}" y="${lkY - 26}" width="${bw}" height="52" rx="10" fill="${carry ? 'rgba(229,32,46,.12)' : '#18181c'}" stroke="${carry ? '#e5202e' : '#2e2e35'}"/>
                <circle cx="${x - bw / 2 + 12}" cy="${lkY - 6}" r="4" fill="${dot}"/>
                <text x="${x - bw / 2 + 21}" y="${lkY - 2}" fill="#e8e8ec" font-size="12" font-weight="700">${esc(short(linkName(l)))}</text>
                <text x="${x - bw / 2 + 10}" y="${lkY + 15}" fill="#8d8d98" font-size="11">${esc(lat)}</text></g>`;
        });
        svg += `<g><rect x="90" y="${lanY - 24}" width="180" height="48" rx="12" fill="#18181c" stroke="#2e2e35"/>
            <text x="180" y="${lanY - 3}" text-anchor="middle" fill="#e8e8ec" font-size="13" font-weight="700">Локальная сеть</text>
            <text x="180" y="${lanY + 14}" text-anchor="middle" fill="#8d8d98" font-size="11">${esc((lanNames.join(', ') || 'Нет сетей').slice(0, 26))}</text></g>`;
        svg += `<g><rect x="130" y="${fwY - 32}" width="100" height="64" rx="16" fill="url(#jsdg2)"/>
            <text x="180" y="${fwY - 2}" text-anchor="middle" fill="#fff" font-size="15" font-weight="800">jk-ufw</text>
            <text x="180" y="${fwY + 16}" text-anchor="middle" fill="rgba(255,255,255,.8)" font-size="11">${saved_draft.enabled ? esc(MODE[saved_draft.mode].toLowerCase()) : 'SD-WAN выкл.'}</text></g>`;
        svg += `<g><rect x="120" y="${netY - 24}" width="120" height="48" rx="24" fill="#18181c" stroke="#2e2e35"/>
            <text x="180" y="${netY + 5}" text-anchor="middle" fill="#e8e8ec" font-size="13" font-weight="700">Интернет</text></g>`;
        $('#jsd-flow').html(`<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Схема каналов">
            <defs><linearGradient id="jsdg2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff3b47"/><stop offset="1" stop-color="#a5121c"/></linearGradient></defs>${svg}</svg>`);
    }

    function spark(hist) {
        const vals = hist.map((h) => (h.d == null ? 0 : h.d));
        if (vals.length < 2) { return ''; }
        const max = Math.max(...vals, 10) * 1.2;
        const pts = vals.map((v, i) => `${(i / (HIST - 1) * 100 + (HIST - vals.length) / (HIST - 1) * 100).toFixed(2)} ${(40 - v / max * 36).toFixed(2)}`);
        const line = 'M' + pts.join(' L');
        const x0 = pts[0].split(' ')[0];
        return `<svg viewBox="0 0 100 40" preserveAspectRatio="none">
            <path d="${line} L100 40 L${x0} 40 Z" fill="rgba(229,32,46,.14)"/>
            <path d="${line}" fill="none" stroke="#ff3b47" stroke-width="1.5" vector-effect="non-scaling-stroke"/></svg>`;
    }

    function renderLinks() {
        const links = orderedLinks().concat(st.links.filter((l) => l.disabled));
        if (!links.length) {
            $('#jsd-links').html('<div class="jsd-empty" style="grid-column:1/-1"><i class="fa fa-plug"></i>Шлюзы не найдены</div>');
            return;
        }
        $('#jsd-links').html(links.map((l) => {
            const [cls, label] = health(l);
            const member = draft.members.includes(l.name);
            const carry = saved_draft.enabled && l.carrying;
            const hist = store.get('jksd-h-' + l.name, []);
            const strip = Array.from({length: 36}, (_, i) => { const h = hist[hist.length - 36 + i]; return `<i class="${h ? h.s : ''}"></i>`; }).join('');
            const r = rates[l.name];
            const down = rate(r ? r.down : null), up = rate(r ? r.up : null);
            const util = r && l.speed ? Math.min(100, r.down / (l.speed * 1e6) * 100) : null;
            const pos = saved_draft.members.indexOf(l.name);
            let role = '';
            if (carry) { role = `<span class="jsd-chip acc"><i class="fa fa-bolt"></i>${saved_draft.mode === 'balance' ? 'в работе' : 'основной сейчас'}</span>`; }
            else if (saved_draft.enabled && pos >= 0) { role = `<span class="jsd-chip">${saved_draft.mode === 'failover' ? 'резерв ' + pos : 'ожидает'}</span>`; }
            const v = (x, d) => (x == null ? '—' : x.toFixed(d));
            return `<div class="jsd-link ${carry ? 'carry' : ''} ${!member || l.disabled ? 'off' : ''}">
                <div class="jsd-link-top">
                  <div class="jsd-link-ic"><i class="fa ${linkIcon(l)}"></i><span class="dot ${cls}"></span></div>
                  <div class="jsd-link-m"><div class="jsd-link-n">${esc(linkName(l))}</div>
                    <div class="jsd-link-s">${esc(l.interface_descr)} · <span class="mono">${esc(l.address && l.address !== '~' ? l.address : 'dhcp')}</span></div></div>
                  <button class="jsd-btn ghost icon sm" data-edit-link="${esc(l.name)}" title="Настроить"><i class="fa fa-pencil"></i></button>
                </div>
                <div style="margin-top:10px; display:flex; gap:6px; flex-wrap:wrap"><span class="jsd-chip ${cls}">${esc(label)}</span>${role}
                  ${saved_draft.mode === 'balance' && member ? `<span class="jsd-chip">вес ${l.weight}</span>` : ''}</div>
                <div class="jsd-stats">
                  <div><div class="l">Задержка</div><div class="v">${v(l.delay, 1)}<small>мс</small></div></div>
                  <div><div class="l">Джиттер</div><div class="v">${v(l.stddev, 1)}<small>мс</small></div></div>
                  <div><div class="l">Потери</div><div class="v">${v(l.loss, 0)}<small>%</small></div></div>
                </div>
                <div class="jsd-spark">${spark(hist)}</div>
                <div class="jsd-strip" title="История проверок">${strip}</div>
                <div class="jsd-tr"><span><i class="fa fa-arrow-down"></i> <b>${down[0]}</b> ${down[1]}</span>
                  <span><i class="fa fa-arrow-up"></i> <b>${up[0]}</b> ${up[1]}</span>
                  <span style="margin-left:auto" class="mono" title="Адрес проверки">${esc(l.monitoring ? (l.monitor || '') : 'проверка выкл.')}</span></div>
                ${util != null ? `<div class="jsd-util" title="Загрузка канала ${util.toFixed(0)}%"><i style="width:${util.toFixed(1)}%"></i></div>` : ''}
              </div>`;
        }).join(''));
    }

    function renderSettings() {
        $('#jsd-en').toggleClass('on', draft.enabled).attr('aria-checked', draft.enabled);
        $('#jsd-en-t').text(draft.enabled ? 'Включено' : 'Выключено');
        $('#jsd-mode .jsd-opt').each(function () { $(this).toggleClass('sel', $(this).data('mode') === draft.mode); });
        $('#jsd-trigger .jsd-cb').each(function () { $(this).toggleClass('sel', $(this).data('v') === draft.trigger); });
        $('#jsd-sticky').toggleClass('on', draft.sticky).closest('.jsd-tg').toggle(draft.mode === 'balance');
        $('#jsd-kill').toggleClass('on', draft.killstates);
        const bal = draft.mode === 'balance';
        $('#jsd-order-l').text(bal ? 'Каналы и их веса' : 'Порядок каналов');
        $('#jsd-order-h').text(bal ? 'Вес 1–10: чем больше, тем больше соединений получает канал. Выключенный канал не используется.'
            : 'Первый — основной, остальные ждут в резерве по порядку. Выключенный канал не используется.');
        const links = orderedLinks();
        $('#jsd-order').html(links.map((l) => {
            const idx = draft.members.indexOf(l.name);
            const on = idx >= 0;
            const [cls] = health(l);
            const ctl = !on ? '' : bal
                ? `<button class="jsd-btn ghost icon sm" data-w="-1" data-n="${esc(l.name)}" aria-label="меньше"><i class="fa fa-minus"></i></button>
                   <span class="wt">${l.weight}</span>
                   <button class="jsd-btn ghost icon sm" data-w="1" data-n="${esc(l.name)}" aria-label="больше"><i class="fa fa-plus"></i></button>`
                : `<button class="jsd-btn ghost icon sm" data-mv="-1" data-n="${esc(l.name)}" ${idx === 0 ? 'disabled' : ''} aria-label="выше"><i class="fa fa-arrow-up"></i></button>
                   <button class="jsd-btn ghost icon sm" data-mv="1" data-n="${esc(l.name)}" ${idx === draft.members.length - 1 ? 'disabled' : ''} aria-label="ниже"><i class="fa fa-arrow-down"></i></button>`;
            return `<li class="${on ? '' : 'out'}"><span class="num">${on ? (bal ? '<i class="fa fa-check"></i>' : idx + 1) : '–'}</span>
                <span class="dot ${cls}" style="width:8px;height:8px;border-radius:50%;background:#3a3a42;flex:none"></span>
                <span class="nm">${esc(linkName(l))}<small>${esc(l.interface_descr)}</small></span>
                <span class="ctl">${ctl}<span class="jsd-sw ${on ? 'on' : ''}" data-member="${esc(l.name)}" role="switch" tabindex="0" style="margin-left:6px"></span></span></li>`;
        }).join(''));
        $('#jsd-lans').html((st.lans || []).map((l) => `<span class="jsd-cb ${draft.lans.includes(l.name) ? 'sel' : ''}" data-lan="${esc(l.name)}">
            <i class="fa ${draft.lans.includes(l.name) ? 'fa-check-square' : 'fa-square-o'}"></i>${esc(l.descr)} <small class="mono">${esc(l.net)}</small></span>`).join('')
            || '<span class="muted">Внутренние сети не найдены</span>');
    }

    function polDescr(p) {
        const app = p.app;
        const parts = [];
        const src = list(p.source);
        parts.push(src.length ? 'Устройства: ' + src.join(', ') : 'Все устройства');
        if (app === 'custom') { parts.push(pick(p.protocol) + ' ' + list(p.ports).join(', ')); }
        else if (app !== 'any') { parts.push(APPS[app][1] + (APPS[app][2] ? ' (' + APPS[app][2] + ')' : '')); }
        const dst = list(p.destination);
        if (dst.length) { parts.push('куда: ' + dst.join(', ')); }
        return parts.join(' · ');
    }

    function renderPolicies() {
        const pols = Object.entries((model.sdwan.policies && model.sdwan.policies.policy) || {});
        if (!pols.length) {
            $('#jsd-pols').html('<div class="jsd-empty"><i class="fa fa-code-fork"></i>Маршрутов нет: весь трафик идёт по общим правилам.<br>' +
                'Добавьте маршрут, чтобы, например, игры шли через оптику, а камеры — через LTE.</div>');
            return;
        }
        $('#jsd-pols').html(pols.map(([uuid, p]) => {
            const app = pick(p.app) || 'any';
            const on = String(p.enabled) === '1';
            const l = linkByName(p.wan);
            const [cls] = l ? health(l) : ['bad'];
            const fb = String(p.fallback) === '1';
            return `<div class="jsd-pol ${on ? '' : 'off'}">
                <div class="ic"><i class="fa ${APPS[app][0]}"></i></div>
                <div class="pm"><div class="pn">${esc(p.name)}</div><div class="ps">${esc(polDescr(Object.assign({}, p, {app: app})))}</div></div>
                <div class="arrow"><i class="fa fa-long-arrow-right muted"></i><span class="dot ${cls}" style="width:8px;height:8px;border-radius:50%;background:#3a3a42"></span>
                  ${esc(l ? linkName(l) : p.wan)}${fb ? '' : ' <span class="jsd-chip warn" title="Без резерва">строго</span>'}</div>
                <div class="pa"><span class="jsd-sw ${on ? 'on' : ''}" data-pol-toggle="${uuid}" role="switch" tabindex="0"></span>
                  <button class="jsd-btn ghost icon sm" data-pol-edit="${uuid}" title="Изменить"><i class="fa fa-pencil"></i></button>
                  <button class="jsd-btn ghost icon sm danger" data-pol-del="${uuid}" title="Удалить"><i class="fa fa-trash"></i></button></div>
              </div>`;
        }).join(''));
    }

    function fmtTime(t) {
        const d = new Date(t);
        if (isNaN(d)) { return ''; }
        const now = new Date();
        const hm = d.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'});
        if (d.toDateString() === now.toDateString()) { return 'сегодня, ' + hm; }
        const y = new Date(now - 86400000);
        if (d.toDateString() === y.toDateString()) { return 'вчера, ' + hm; }
        return d.toLocaleDateString('ru-RU', {day: 'numeric', month: 'short'}) + ', ' + hm;
    }

    function renderEvents() {
        const ev = (st.events || []).slice(0, 8);
        if (!ev.length) {
            $('#jsd-events').html('<div class="jsd-empty"><i class="fa fa-check-circle"></i>Сбоев не было</div>');
            return;
        }
        $('#jsd-events').html(ev.map((e) => {
            const l = linkByName(e.gateway);
            const nm = '«' + (l ? linkName(l) : e.gateway) + '»';
            let cls = 'ok', ic = 'fa-check', text = nm + ' снова в норме';
            if (e.to === 'down' || e.to === 'force_down') { cls = 'bad'; ic = 'fa-unlink'; text = nm + ' пропал' + (e.alert ? ', трафик переключён' : ''); }
            else if (e.to === 'loss') { cls = 'warn'; ic = 'fa-tint'; text = nm + ': потери пакетов' + (e.loss != null ? ' ' + e.loss.toFixed(0) + ' %' : ''); }
            else if (e.to === 'delay') { cls = 'warn'; ic = 'fa-hourglass-half'; text = nm + ': высокая задержка' + (e.delay != null ? ' ' + e.delay.toFixed(0) + ' мс' : ''); }
            else if (e.to === 'delay+loss') { cls = 'warn'; ic = 'fa-exclamation-triangle'; text = nm + ': потери и задержка'; }
            else if (e.from === 'down') { text = nm + ' восстановлен' + (e.alert ? ', трафик возвращён' : ''); }
            return `<div class="jsd-ev ${cls}"><div class="ei"><i class="fa ${ic}"></i></div>
                <div class="et">${esc(text)}<div class="ew">${esc(fmtTime(e.time))}</div></div></div>`;
        }).join(''));
    }

    function renderAll() {
        renderHead(); renderKpis(); renderFlow(); renderLinks(); renderSettings(); renderPolicies(); renderEvents();
    }

    // ---- data -----------------------------------------------------------------------------------
    function sample() {
        const t = st.time;
        st.links.forEach((l) => {
            const p = prev[l.name];
            if (p && l.inbytes != null && t > p.t) {
                rates[l.name] = {down: Math.max(0, (l.inbytes - p.in) * 8 / (t - p.t)), up: Math.max(0, (l.outbytes - p.out) * 8 / (t - p.t))};
            }
            prev[l.name] = {t: t, in: l.inbytes, out: l.outbytes};
            if (l.monitoring && !l.disabled) {
                const h = store.get('jksd-h-' + l.name, []);
                h.push({d: l.delay, s: health(l)[0]});
                while (h.length > HIST) { h.shift(); }
                store.set('jksd-h-' + l.name, h);
            }
        });
    }

    async function loadStatus() {
        st = await api('/api/jkufw/sdwan/status');
        sample();
    }
    async function loadModel() {
        model = await api('/api/jkufw/sdwan/get');
        saved_draft = fromModel();
        if (!saved_draft.members.length && !saved_draft.enabled) {
            // first visit: offer every healthy link, the current default first
            saved_draft.members = st.links.filter((l) => !l.disabled).map((l) => l.name);
        }
        if (!saved_draft.lans.length && st.lans.length) { saved_draft.lans = [st.lans[0].name]; }
        draft = JSON.parse(JSON.stringify(saved_draft));
    }

    async function refresh() {
        try {
            await loadStatus();
            $('#jsd-error').hide();
            renderHead(); renderKpis(); renderFlow(); renderLinks(); renderEvents();
            $('#jsd-poll').text('обновлено ' + new Date().toLocaleTimeString('ru-RU'));
        } catch (e) {
            $('#jsd-error').show().find('div').text('Нет ответа от экрана: ' + e.message);
        }
    }

    function showErr(msg) { $('#jsd-error').show().find('div').text(msg); }

    async function applyAll() {
        if (busy) { return; }
        busy = true;
        const $b = $('#jsd-apply, #jsd-intro-go').prop('disabled', true);
        const html = $('#jsd-apply').html();
        $('#jsd-apply').html('<i class="fa fa-spinner fa-pulse"></i> Применяю…');
        try {
            const g = Object.assign({}, draft, {
                enabled: draft.enabled ? '1' : '0', sticky: draft.sticky ? '1' : '0', killstates: draft.killstates ? '1' : '0',
                members: draft.members.join(','), lans: draft.lans.join(',')
            });
            saved(await api('/api/jkufw/sdwan/set', {sdwan: {general: g}}), 'Настройки');
            const r = await api('/api/jkufw/sdwan/apply', {});
            if (r && r.errorMessage) { throw new Error(r.errorMessage); }
            if (!r || r.status === 'failed') { throw new Error('экран не применил изменения'); }
            pendingPolicies = false;
            await loadStatus();
            await loadModel();
            $('#jsd-applybar').removeClass('show');
            renderAll();
        } catch (e) {
            showErr('Не удалось применить: ' + e.message);
        } finally {
            busy = false;
            $b.prop('disabled', false);
            $('#jsd-apply').html(html);
        }
    }

    // ---- settings events ------------------------------------------------------------------------
    const swKey = (h) => function (e) { if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; } e.preventDefault(); h.call(this, e); };
    $('#jsd-en').on('click keydown', swKey(() => {
        draft.enabled = !draft.enabled;
        if (draft.enabled && !draft.members.length) { draft.members = st.links.filter((l) => !l.disabled).map((l) => l.name); }
        markDirty();
    }));
    $('#jsd-intro-go').on('click', () => { draft.enabled = true; markDirty(); applyAll(); });
    $('#jsd-mode').on('click', '.jsd-opt', function () { draft.mode = $(this).data('mode'); markDirty(); renderLinks(); });
    $('#jsd-trigger').on('click', '.jsd-cb', function () { draft.trigger = $(this).data('v'); markDirty(); });
    $('#jsd-sticky').on('click keydown', swKey(() => { draft.sticky = !draft.sticky; markDirty(); }));
    $('#jsd-kill').on('click keydown', swKey(() => { draft.killstates = !draft.killstates; markDirty(); }));
    $('#jsd-lans').on('click', '.jsd-cb', function () {
        const n = String($(this).data('lan'));
        draft.lans = draft.lans.includes(n) ? draft.lans.filter((x) => x !== n) : draft.lans.concat([n]);
        markDirty();
    });
    $('#jsd-order').on('click keydown', '[data-member]', swKey(function () {
        const n = String($(this).data('member'));
        draft.members = draft.members.includes(n) ? draft.members.filter((x) => x !== n) : draft.members.concat([n]);
        markDirty();
    })).on('click', '[data-mv]', function () {
        const n = String($(this).data('n')), d = Number($(this).data('mv'));
        const i = draft.members.indexOf(n), j = i + d;
        if (i < 0 || j < 0 || j >= draft.members.length) { return; }
        [draft.members[i], draft.members[j]] = [draft.members[j], draft.members[i]];
        markDirty();
    }).on('click', '[data-w]', async function () {
        const l = linkByName(String($(this).data('n')));
        const w = Math.max(1, Math.min(10, l.weight + Number($(this).data('w'))));
        if (w === l.weight) { return; }
        try {
            saved(await api('/api/jkufw/sdwan/link', {link: {gateway: l.name, label: l.label, monitor: l.monitor === '~' ? '' : (l.monitor || ''), weight: w, speed: l.speed || ''}}), 'Вес');
            l.weight = w;
            pendingPolicies = true;
            markDirty();
            renderLinks();
        } catch (e) { showErr(e.message); }
    });
    $('#jsd-apply').on('click', applyAll);
    $('#jsd-revert').on('click', () => { draft = JSON.parse(JSON.stringify(saved_draft)); pendingPolicies = false; $('#jsd-applybar').removeClass('show'); renderAll(); });

    // ---- link modal -----------------------------------------------------------------------------
    let editLink = null;
    $('#jsd-links').on('click', '[data-edit-link]', function () {
        editLink = linkByName(String($(this).data('edit-link')));
        if (!editLink) { return; }
        $('#jl-title').text(linkName(editLink));
        $('#jl-sub').html(esc(editLink.interface_descr) + ' · шлюз <span class="mono">' + esc(editLink.name) + '</span>');
        $('#jl-label').val(editLink.label);
        $('#jl-monitor').val(editLink.monitor && editLink.monitor !== '~' && editLink.monitor !== editLink.address ? editLink.monitor : '').removeClass('bad');
        $('#jl-speed').val(editLink.speed || '');
        $('#jl-weight').val(editLink.weight || 1);
        $('#jl-weight-v').text(editLink.weight || 1);
        $('#jl-weight-f').toggle(draft.mode === 'balance');
        $('#jl-err').text('');
        $('#jsd-ov-link').addClass('open');
        setTimeout(() => $('#jl-label').trigger('focus'), 50);
    });
    $('#jl-weight').on('input', function () { $('#jl-weight-v').text(this.value); });
    $('#jl-save').on('click', async () => {
        const mon = $('#jl-monitor').val().trim();
        if (mon && !/^\d{1,3}(\.\d{1,3}){3}$/.test(mon)) { $('#jl-monitor').addClass('bad'); $('#jl-err').text('Адрес проверки — IPv4, например 1.1.1.1'); return; }
        try {
            saved(await api('/api/jkufw/sdwan/link', {link: {gateway: editLink.name, label: $('#jl-label').val().trim(), monitor: mon,
                weight: $('#jl-weight').val(), speed: $('#jl-speed').val().replace(/\D/g, '')}}), 'Канал');
            $('#jsd-ov-link').removeClass('open');
            pendingPolicies = true;
            await loadStatus();
            markDirty();
            renderLinks();
            renderPolicies();
        } catch (e) { $('#jl-err').text(e.message); }
    });

    // ---- policy modal ---------------------------------------------------------------------------
    let editPol = null, polApp = 'gaming', polWan = null, polFb = true;
    const renderPolForm = () => {
        $('#jp-apps').html(Object.entries(APPS).map(([k, a]) => `<div class="jsd-app ${k === polApp ? 'sel' : ''}" data-app="${k}" title="${esc(a[2])}"><i class="fa ${a[0]}"></i>${esc(a[1])}</div>`).join(''));
        $('#jp-custom').toggle(polApp === 'custom');
        $('#jp-wan').html(st.links.filter((l) => !l.disabled).map((l) => `<span class="jsd-cb ${l.name === polWan ? 'sel' : ''}" data-wan="${esc(l.name)}">
            <i class="fa ${linkIcon(l)}"></i>${esc(linkName(l))}</span>`).join(''));
        $('#jp-fb').toggleClass('on', polFb);
    };
    const openPol = (uuid) => {
        const p = uuid ? model.sdwan.policies.policy[uuid] : null;
        editPol = uuid || null;
        $('#jp-title').text(p ? 'Маршрут' : 'Новый маршрут');
        $('#jp-name').val(p ? p.name : '');
        $('#jp-src').val(p ? list(p.source).join(', ') : '');
        $('#jp-dst').val(p ? list(p.destination).join(', ') : '');
        $('#jp-ports').val(p ? list(p.ports).join(', ') : '');
        $('#jp-proto').val(p ? pick(p.protocol) || 'TCP/UDP' : 'TCP/UDP');
        polApp = p ? pick(p.app) || 'any' : 'gaming';
        const wans = st.links.filter((l) => !l.disabled);
        polWan = p ? p.wan : (draft.members[0] || (wans[0] && wans[0].name));
        polFb = p ? String(p.fallback) === '1' : true;
        $('#jp-err').text('');
        renderPolForm();
        $('#jsd-ov-pol').addClass('open');
        setTimeout(() => $('#jp-name').trigger('focus'), 50);
    };
    $('#jsd-pol-add').on('click', () => openPol(null));
    $('#jp-apps').on('click', '.jsd-app', function () {
        polApp = $(this).data('app');
        if (!$('#jp-name').val().trim() || $('#jp-name').data('auto')) {
            const l = linkByName(polWan);
            $('#jp-name').val(APPS[polApp][1] + (l ? ' через ' + linkName(l) : '')).data('auto', true);
        }
        renderPolForm();
    });
    $('#jp-name').on('input', function () { $(this).data('auto', false); });
    $('#jp-wan').on('click', '.jsd-cb', function () { polWan = String($(this).data('wan')); renderPolForm(); });
    $('#jp-fb').on('click keydown', swKey(() => { polFb = !polFb; renderPolForm(); }));
    const csv = (s) => s.split(/[\s,;]+/).filter(Boolean).join(',');
    $('#jp-save').on('click', async () => {
        const name = $('#jp-name').val().trim();
        if (!name) { $('#jp-err').text('Дайте маршруту название'); return; }
        if (!polWan) { $('#jp-err').text('Выберите канал'); return; }
        const body = {policy: {enabled: editPol ? String(model.sdwan.policies.policy[editPol].enabled) : '1', name: name,
            source: csv($('#jp-src').val()), app: polApp, protocol: $('#jp-proto').val(), ports: polApp === 'custom' ? csv($('#jp-ports').val()) : '',
            destination: csv($('#jp-dst').val()), wan: polWan, fallback: polFb ? '1' : '0'}};
        try {
            saved(await api(editPol ? '/api/jkufw/sdwan/set_policy/' + editPol : '/api/jkufw/sdwan/add_policy', body), 'Маршрут');
            $('#jsd-ov-pol').removeClass('open');
            await reloadPolicies();
        } catch (e) { $('#jp-err').text(e.message); }
    });
    async function reloadPolicies() {
        const keep = draft;
        model = await api('/api/jkufw/sdwan/get');
        draft = keep;
        pendingPolicies = true;
        markDirty();
        renderPolicies();
    }
    $('#jsd-pols').on('click', '[data-pol-edit]', function () { openPol($(this).data('pol-edit')); })
        .on('click', '[data-pol-del]', async function () {
            const uuid = $(this).data('pol-del');
            const $row = $(this).closest('.jsd-pol');
            if ($row.data('confirm') !== true) {
                $row.data('confirm', true);
                $(this).html('<i class="fa fa-trash"></i> Удалить?').css('color', 'var(--a2)');
                setTimeout(() => { $row.data('confirm', false); renderPolicies(); }, 3500);
                return;
            }
            try { await api('/api/jkufw/sdwan/del_policy/' + uuid, {}); await reloadPolicies(); } catch (e) { showErr(e.message); }
        })
        .on('click keydown', '[data-pol-toggle]', swKey(async function () {
            try { await api('/api/jkufw/sdwan/toggle_policy/' + $(this).data('pol-toggle'), {}); await reloadPolicies(); } catch (e) { showErr(e.message); }
        }));

    $('.jsd-ov').on('click', function (e) { if (e.target === this) { $(this).removeClass('open'); } })
        .on('click', '[data-close]', function () { $(this).closest('.jsd-ov').removeClass('open'); });
    $(document).on('keydown', (e) => { if (e.key === 'Escape') { $('.jsd-ov').removeClass('open'); } });
    $('#jl-label, #jl-monitor, #jl-speed').on('keydown', (e) => { if (e.key === 'Enter') { $('#jl-save').trigger('click'); } });

    // ---- start ----------------------------------------------------------------------------------
    (async () => {
        try {
            await loadStatus();
            await loadModel();
            $('#jsd-loading').hide();
            $('#jsd-main').show();
            renderAll();
            $('#jsd-poll').text('обновлено ' + new Date().toLocaleTimeString('ru-RU'));
            setInterval(() => { if (!document.hidden) { refresh(); } }, POLL_MS);
            let rz = null;
            $(window).on('resize', () => { clearTimeout(rz); rz = setTimeout(renderFlow, 150); });
        } catch (e) {
            $('#jsd-loading').hide();
            showErr('Не удалось загрузить SD-WAN: ' + e.message);
        }
    })();
});
</script>
