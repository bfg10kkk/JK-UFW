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
 # jk-ufw: content filter and parental control on one page.
 # Filtering drives the stock Unbound DNS blocklists (/api/unbound/*): one policy for the whole network and
 # optional policies for groups of devices (the most specific source network wins in Unbound).
 # Schedules and pauses go through /api/jkufw/parental/*, which turns them into aliases, schedules and
 # floating firewall rules.
 #}

<style>
.jkp { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1180px; }
.jkp * { box-sizing:border-box; }
.jkp b, .jkp strong { font-family:inherit; font-weight:700; }
.jkp .muted { color:var(--m); }
.jkp-head { display:flex; align-items:center; gap:16px; padding:6px 0 14px; flex-wrap:wrap; }
.jkp-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:24px; color:#fff;
  background:linear-gradient(145deg,var(--a2),#a5121c); box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkp-logo.off { background:var(--s2); border:1px solid var(--b); color:var(--m); box-shadow:none; }
.jkp-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkp-sub { color:var(--m); margin-top:2px; }
.jkp-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jkp-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jkp-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jkp-pill.bad i { background:var(--a); }
.jkp-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jkp-tabs { display:inline-flex; gap:4px; padding:4px; border-radius:12px; background:var(--s); border:1px solid var(--b); margin-bottom:16px; }
.jkp-tab { padding:8px 16px; border-radius:9px; font-weight:600; color:var(--m); cursor:pointer; user-select:none; }
.jkp-tab:hover { color:var(--t); }
.jkp-tab.sel { background:var(--abg); color:#fff; box-shadow:inset 0 0 0 1px var(--a); }
.jkp-tab .fa { margin-right:6px; }
.jkp-grid { display:grid; grid-template-columns:minmax(0,1.4fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1000px) { .jkp-grid { grid-template-columns:minmax(0,1fr); } }
.jkp-grid > div { min-width:0; }
.jkp-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jkp-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; }
.jkp-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; }
.jkp-card h3 a { color:var(--a2); }
.jkp-chips { display:flex; flex-wrap:wrap; gap:8px; }
.jkp-chip { padding:7px 13px; border-radius:999px; background:var(--s2); border:1px solid var(--b); cursor:pointer; font-weight:600; user-select:none; }
.jkp-chip:hover { border-color:var(--b2); }
.jkp-chip.sel { background:var(--abg); border-color:var(--a); color:#fff; }
.jkp-chip .fa { margin-right:6px; color:var(--m); }
.jkp-chip.sel .fa { color:var(--a2); }
.jkp-chip.add { border-style:dashed; color:var(--m); }
.jkp-chip small { color:var(--m); font-weight:500; margin-left:4px; }
.jkp-levels { display:grid; grid-template-columns:repeat(4,1fr); gap:10px; margin-bottom:14px; }
@media (max-width: 640px) { .jkp-levels { grid-template-columns:1fr 1fr; } }
.jkp-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; cursor:pointer; transition:all .15s; }
.jkp-opt:hover { border-color:var(--b2); background:var(--h); }
.jkp-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jkp-opt .nm { font-weight:700; font-size:14px; }
.jkp-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jkp-cats { display:grid; grid-template-columns:repeat(auto-fill,minmax(250px,1fr)); gap:8px; }
.jkp-cat { display:flex; align-items:flex-start; gap:12px; padding:11px 12px; border-radius:10px; background:var(--s2); border:1px solid var(--b); cursor:pointer; }
.jkp-cat:hover { background:var(--h); }
.jkp-cat .ci { width:32px; height:32px; flex:none; border-radius:8px; display:grid; place-items:center; background:#202026; color:var(--m); }
.jkp-cat.on .ci { background:var(--abg); color:var(--a2); }
.jkp-cat .cm { flex:1; min-width:0; }
.jkp-cat .cn { font-weight:600; }
.jkp-cat .cd { color:var(--m); font-size:11.5px; margin-top:2px; line-height:1.4; }
.jkp-sw { flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; margin-top:6px; cursor:pointer; }
.jkp-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.on > .jkp-sw, .jkp-sw.on { background:var(--a); }
.on > .jkp-sw::after, .jkp-sw.on::after { left:16px; background:#fff; }
.jkp-row { display:flex; align-items:center; gap:14px; padding:12px 0; border-top:1px solid var(--b); }
.jkp-row:first-of-type { border-top:0; padding-top:0; }
.jkp-row .rl { flex:1; min-width:0; }
.jkp-row .rn { font-weight:600; }
.jkp-row .rd { color:var(--m); font-size:12px; margin-top:2px; line-height:1.45; }
.jkp-lbl { display:block; font-weight:600; margin:12px 0 6px; }
.jkp-lbl:first-child { margin-top:0; }
.jkp-lbl small { color:var(--m); font-weight:500; margin-left:6px; }
.jkp input.jkp-in, .jkp textarea.jkp-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:8px 10px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:13px; box-shadow:none !important; }
.jkp textarea.jkp-in { min-height:84px; resize:vertical; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkp input.jkp-in:focus, .jkp textarea.jkp-in:focus { border-color:var(--a) !important; outline:none; }
.jkp input.jkp-in.mono { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkp input[type=time].jkp-in { width:150px !important; font-size:16px; font-weight:600; color-scheme:dark; }
.jkp-two { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
@media (max-width: 640px) { .jkp-two { grid-template-columns:1fr; } }
.jkp-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jkp-note .fa { margin-top:2px; }
.jkp-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; margin:0 0 16px; }
.jkp-note.warn .fa { color:var(--warn); }
.jkp-note.warn a { color:#fff; text-decoration:underline; }
.jkp-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jkp-bar { position:sticky; bottom:0; z-index:5; display:flex; align-items:center; gap:14px; padding:14px 18px; margin-top:4px;
  background:rgba(19,19,22,.92); backdrop-filter:blur(8px); border:1px solid var(--b); border-radius:12px; }
.jkp-bar .st { flex:1; color:var(--m); }
.jkp-bar .st b { color:var(--t); }
.jkp-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff; display:inline-flex; align-items:center; gap:7px; white-space:nowrap; }
.jkp-btn:hover { background:var(--a2); color:#fff; text-decoration:none; }
.jkp-btn[disabled] { opacity:.5; cursor:default; }
.jkp-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t); font-weight:600; }
.jkp-btn.ghost:hover { background:var(--h); }
.jkp-btn.sm { padding:6px 11px; font-size:12px; }
.jkp-btn.icon { padding:7px 9px; }
.jkp-btn.green { background:rgba(34,197,94,.14); color:#7ee2a0; border:1px solid rgba(34,197,94,.35); }
.jkp-btn.green:hover { background:rgba(34,197,94,.22); }
.jkp-kpis { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:10px; margin-bottom:14px; }
.jkp-kpi { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; min-width:0; }
.jkp-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jkp-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; }
.jkp-kpi .v.red { color:var(--a2); }
.jkp-top { display:flex; align-items:center; gap:8px; padding:6px 0; }
.jkp-top .tn { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkp-top .tn small { color:var(--m); margin-left:6px; }
.jkp-top .tv { color:var(--m); font-variant-numeric:tabular-nums; }
.jkp-top .tb { height:4px; border-radius:4px; background:var(--a); opacity:.8; }
.jkp-sec { color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; margin:4px 0; }
.jkp-empty { color:var(--m); text-align:center; padding:22px 6px; }
.jkp-empty .fa { display:block; font-size:22px; margin-bottom:8px; color:#3a3a42; }
.jkp-test { display:flex; gap:8px; }
.jkp-test .jkp-in { flex:1; }
.jkp-res { margin-top:12px; padding:12px; border-radius:10px; background:var(--s2); border:1px solid var(--b); display:none; }
.jkp-res.blk { border-color:rgba(229,32,46,.5); background:var(--abg); }
.jkp-res.ok { border-color:rgba(34,197,94,.35); background:rgba(34,197,94,.08); }
.jkp-res .big { font-weight:700; font-size:14px; }
.jkp-steps { margin:0; padding:0; list-style:none; }
.jkp-steps li { padding:3px 0; color:var(--m); }
.jkp-steps li.done { color:var(--t); }
.jkp-steps li.done .fa { color:var(--ok); }
.jkp-steps li.run .fa { color:var(--a2); }
.jkp-steps li.err { color:var(--a2); }
/* devices */
.jkp-devs { display:grid; grid-template-columns:repeat(auto-fill,minmax(340px,1fr)); gap:12px; }
@media (max-width: 640px) { .jkp-devs { grid-template-columns:1fr; } }
.jkp-dev { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:16px; display:flex; flex-direction:column; gap:12px; }
.jkp-dev.paused { border-color:rgba(229,32,46,.55); box-shadow:inset 0 0 0 1px rgba(229,32,46,.25); }
.jkp-dev.disabled { opacity:.55; }
.jkp-dev-top { display:flex; align-items:center; gap:12px; }
.jkp-av { width:40px; height:40px; border-radius:12px; display:grid; place-items:center; font-size:18px; background:#202026; color:var(--m); flex:none; }
.jkp-dev.paused .jkp-av, .jkp-dev.blocked .jkp-av { background:var(--abg); color:var(--a2); }
.jkp-dev.allowed .jkp-av { background:rgba(34,197,94,.12); color:var(--ok); }
.jkp-dev-nm { font-weight:700; font-size:15px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkp-dev-ad { color:var(--m); font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11.5px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkp-dev-main { flex:1; min-width:0; }
.jkp-badge { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 9px; border-radius:999px; background:var(--s2); border:1px solid var(--b); white-space:nowrap; }
.jkp-badge i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jkp-badge.allowed i { background:var(--ok); }
.jkp-badge.blocked, .jkp-badge.paused { color:#ffb3b8; border-color:rgba(229,32,46,.45); background:var(--abg); }
.jkp-badge.blocked i, .jkp-badge.paused i { background:var(--a2); }
.jkp-dev-sch { display:flex; align-items:center; gap:8px; color:var(--m); font-size:12.5px; flex-wrap:wrap; }
.jkp-dev-sch .jkp-badge { margin-left:auto; }
.jkp-dev-sch b { color:var(--t); }
.jkp-dev-act { display:flex; gap:8px; align-items:center; }
.jkp-dev-act .sp { flex:1; }
.jkp-week { display:grid; grid-template-columns:22px 1fr; gap:3px 8px; align-items:center; font-size:11px; color:var(--m); }
.jkp-week .bar { position:relative; height:10px; border-radius:3px; background:rgba(34,197,94,.22); overflow:hidden; }
.jkp-week .bar span { position:absolute; top:0; bottom:0; background:var(--a); }
.jkp-week .bar em { position:absolute; top:-2px; bottom:-2px; width:2px; background:#fff; border-radius:2px; }
.jkp-week .today { color:var(--t); font-weight:700; }
.jkp-axis { display:flex; justify-content:space-between; color:var(--m); font-size:10.5px; margin-left:30px; margin-top:2px; }
.jkp-mini { position:relative; height:6px; border-radius:3px; background:rgba(34,197,94,.22); overflow:hidden; }
.jkp-mini span { position:absolute; top:0; bottom:0; background:var(--a); }
.jkp-mini em { position:absolute; top:0; bottom:0; width:2px; background:#fff; }
.jkp-edit { border-color:var(--a); }
.jkp-presets { display:flex; flex-wrap:wrap; gap:6px; margin-top:8px; }
.jkp-presets a { color:var(--m); font-size:12px; cursor:pointer; padding:2px 8px; border-radius:6px; background:var(--s2); }
.jkp-presets a:hover { color:var(--t); }
.jkp-days .jkp-chip { min-width:46px; text-align:center; }
.jkp-times { display:flex; align-items:center; gap:10px; flex-wrap:wrap; }
.jkp-pick { max-height:220px; overflow:auto; border:1px solid var(--b); border-radius:10px; margin-top:8px; }
.jkp-pick-row { display:flex; align-items:center; gap:10px; padding:8px 10px; border-top:1px solid var(--b); cursor:pointer; }
.jkp-pick-row:first-child { border-top:0; }
.jkp-pick-row:hover { background:var(--h); }
.jkp-pick-row.sel { background:var(--abg); }
.jkp-pick-row .pn { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-weight:600; }
.jkp-pick-row .pa { color:var(--m); font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11.5px; }
.jkp-pick-row .fa-check { color:var(--a2); visibility:hidden; }
.jkp-pick-row.sel .fa-check { visibility:visible; }
.jkp-err { color:var(--a2); font-size:12px; margin-top:6px; }
</style>

<div class="jkp" id="jkp">
  <div class="jkp-head">
    <div class="jkp-logo" id="jkp-logo"><i class="fa fa-child"></i></div>
    <div>
      <h1 class="jkp-title">Фильтр контента <span class="jkp-pill" id="jkp-status"><i></i><span>…</span></span></h1>
      <div class="jkp-sub">Блокировка рекламы и нежелательных сайтов через DNS, расписание интернета для детских устройств</div>
    </div>
    <div class="jkp-head-r">
      <a class="jkp-btn ghost" href="/ui/unbound/overview"><i class="fa fa-bar-chart"></i> Журнал DNS</a>
      <a class="jkp-btn ghost" href="/ui/unbound/dnsbl"><i class="fa fa-sliders"></i> Расширенные</a>
    </div>
  </div>

  <div class="jkp-tabs" id="jkp-tabs">
    <div class="jkp-tab sel" data-tab="filter"><i class="fa fa-filter"></i>Фильтрация</div>
    <div class="jkp-tab" data-tab="sched"><i class="fa fa-clock-o"></i>Расписание и пауза</div>
  </div>

  <!-- ================= filtering ================= -->
  <div id="jkp-tab-filter">
    <div class="jkp-note warn" id="jkp-unbound-off" style="display:none"><i class="fa fa-exclamation-triangle"></i>
      <div>DNS-сервер Unbound выключен, поэтому фильтр не работает. Включите его в <a href="/ui/unbound/general">Services › Unbound DNS › General</a>
      и проследите, чтобы устройства получали адрес роутера как DNS-сервер (так настроено по умолчанию в DHCP).</div></div>

    <div class="jkp-grid">
      <div>
        <div class="jkp-card">
          <h3><i class="fa fa-users"></i> Для кого <span class="r muted" id="jkp-prof-hint"></span></h3>
          <div class="jkp-chips" id="jkp-profiles"></div>
          <div id="jkp-prof-edit" style="display:none;margin-top:16px">
            <div class="jkp-two">
              <div><label class="jkp-lbl">Название профиля</label><input class="jkp-in" id="jkp-prof-name" type="text" maxlength="60" placeholder="Например: Дети"/></div>
              <div><label class="jkp-lbl">IP-адреса устройств <small>через запятую</small></label><input class="jkp-in mono" id="jkp-prof-nets" type="text" spellcheck="false" placeholder="192.168.1.50, 192.168.1.51"/></div>
            </div>
            <div class="jkp-pick" id="jkp-prof-pick"></div>
            <div class="jkp-note info"><i class="fa fa-info-circle"></i><div>Профиль устройств заменяет профиль «Вся сеть» для этих адресов целиком.
              Закрепите за устройствами постоянный адрес в DHCP, иначе после смены адреса фильтр перестанет к ним относиться.</div></div>
            <div style="margin-top:12px"><button class="jkp-btn ghost sm" id="jkp-prof-del" type="button"><i class="fa fa-trash"></i> Удалить профиль</button></div>
          </div>
        </div>

        <div class="jkp-card">
          <h3><i class="fa fa-ban"></i> Что блокировать <span class="r muted" id="jkp-cat-count"></span></h3>
          <div class="jkp-levels" id="jkp-levels">
            <div class="jkp-opt" data-level="off"><div class="nm">Выключено</div><div class="ds">Ничего не блокируется.</div></div>
            <div class="jkp-opt" data-level="basic"><div class="nm">Базовый</div><div class="ds">Реклама, слежка и мошенники.</div></div>
            <div class="jkp-opt" data-level="family"><div class="nm">Семейный</div><div class="ds">Плюс сайты для взрослых, казино и обход фильтра.</div></div>
            <div class="jkp-opt" data-level="strict"><div class="nm">Строгий</div><div class="ds">Плюс соцсети и пиратские сайты.</div></div>
          </div>
          <div class="jkp-cats" id="jkp-cats"></div>
        </div>

        <div class="jkp-card">
          <h3><i class="fa fa-list"></i> Свои списки</h3>
          <div class="jkp-two">
            <div><label class="jkp-lbl">Всегда блокировать <small>по сайту в строке</small></label>
              <textarea class="jkp-in" id="jkp-block" spellcheck="false" placeholder="tiktok.com&#10;roblox.com"></textarea>
              <div class="muted" style="font-size:11.5px;margin-top:4px">Поддомены блокируются тоже.</div></div>
            <div><label class="jkp-lbl">Всегда разрешать <small>по сайту в строке</small></label>
              <textarea class="jkp-in" id="jkp-allow" spellcheck="false" placeholder="school.example.ru"></textarea>
              <div class="muted" style="font-size:11.5px;margin-top:4px">Если нужный сайт попал в список блокировки.</div></div>
          </div>
          <div class="jkp-err" id="jkp-list-err"></div>
        </div>

        <div class="jkp-card">
          <h3><i class="fa fa-cog"></i> Для всей сети</h3>
          <div class="jkp-row">
            <div class="rl"><div class="rn">Безопасный поиск</div><div class="rd">Google, Bing, DuckDuckGo, YouTube и другие показывают только безопасные результаты. Отключить в браузере нельзя.</div></div>
            <div class="jkp-sw" id="jkp-safesearch" role="switch" tabindex="0"></div>
          </div>
          <div class="jkp-row">
            <div class="rl"><div class="rn">Запретить сторонние DNS-серверы</div><div class="rd">Устройства не смогут обойти фильтр, прописав себе 8.8.8.8 или DNS over TLS:
              запросы на порты 53 и 853 разрешены только к роутеру. От DNS через HTTPS защищает переключатель ниже и категория «Обход фильтра».</div></div>
            <div class="jkp-sw" id="jkp-foreigndns" role="switch" tabindex="0"></div>
          </div>
          <div id="jkp-ac" style="display:none">
          <div class="jkp-row" style="border-top:1px solid var(--b);padding-top:12px">
            <div class="rl"><div class="rn">Проверять HTTPS по имени сайта</div><div class="rd">Категории и «Всегда блокировать» профиля «Вся сеть» проверяются ещё и в самом
              соединении (имя сервера в TLS, HTTP и QUIC). Не помогут ни свой DNS, ни DNS через HTTPS, ни файл hosts. «Всегда разрешать» тоже действует.</div></div>
            <div class="jkp-sw" id="jkp-sni" role="switch" tabindex="0"></div>
          </div>
          <div class="jkp-row">
            <div class="rl"><div class="rn">Блокировать DNS через HTTPS и TLS</div><div class="rd">Закрывает доступ к публичным DoH/DoT/DoQ-серверам (Google, Cloudflare, Quad9,
              AdGuard, Яндекс и ещё сотни из общего списка) по адресу и имени. Firefox и iCloud Private Relay сами отключают обход.</div></div>
            <div class="jkp-sw" id="jkp-doh" role="switch" tabindex="0"></div>
          </div>
          <div class="jkp-row">
            <div class="rl"><div class="rn">Блокировать QUIC (HTTP/3)</div><div class="rd">Браузеры и приложения переходят на обычный HTTPS, где фильтру лучше видно имя сайта.
              Сайты продолжают открываться.</div></div>
            <div class="jkp-sw" id="jkp-quic" role="switch" tabindex="0"></div>
          </div>
          <div class="jkp-note warn" id="jkp-ac-ips" style="display:none;margin:10px 0 0"><i class="fa fa-exclamation-triangle"></i><div>Проверка HTTPS работает в движке IPS, а он
            сейчас не включён. Включите его на странице <a href="/ui/jkufw/appcontrol">Контроль приложений</a>. Блокировка DNS через HTTPS по адресам и QUIC работает и без него.</div></div>
          </div>
        </div>
      </div>

      <div>
        <div class="jkp-card">
          <h3><i class="fa fa-bar-chart"></i> Статистика DNS <span class="r muted" id="jkp-since"></span></h3>
          <div id="jkp-stats"><div class="jkp-empty">Загрузка…</div></div>
        </div>
        <div class="jkp-card">
          <h3><i class="fa fa-search"></i> Проверить сайт</h3>
          <div class="jkp-test"><input class="jkp-in mono" id="jkp-test-domain" type="text" spellcheck="false" placeholder="vk.com"/>
            <button class="jkp-btn ghost" id="jkp-test-go" type="button">Проверить</button></div>
          <label class="jkp-lbl">С устройства <small>необязательно</small></label>
          <input class="jkp-in mono" id="jkp-test-src" type="text" spellcheck="false" placeholder="IP-адрес, например 192.168.1.50"/>
          <div class="jkp-res" id="jkp-test-res"></div>
          <div class="muted" style="font-size:11.5px;margin-top:10px">Проверяются уже применённые настройки.</div>
        </div>
      </div>
    </div>

    <div class="jkp-bar">
      <div class="st" id="jkp-bar-st">Изменений нет.</div>
      <button class="jkp-btn ghost" id="jkp-reset" type="button" disabled>Отменить</button>
      <button class="jkp-btn" id="jkp-apply" type="button" disabled>Применить</button>
    </div>
  </div>

  <!-- ================= schedules ================= -->
  <div id="jkp-tab-sched" style="display:none">
    <div class="jkp-card" style="display:flex;align-items:center;gap:14px;flex-wrap:wrap">
      <div style="flex:1;min-width:240px"><div style="font-weight:700;font-size:15px">Интернет по расписанию</div>
        <div class="muted" style="margin-top:2px">Отключайте интернет устройствам на ночь или ставьте на паузу одной кнопкой. Открытые соединения тоже обрываются.</div></div>
      <button class="jkp-btn" id="jkp-dev-add" type="button"><i class="fa fa-plus"></i> Добавить устройство</button>
    </div>

    <div class="jkp-card jkp-edit" id="jkp-dev-edit" style="display:none">
      <h3><i class="fa fa-pencil"></i> <span id="jkp-dev-edit-title">Новое устройство</span></h3>
      <div class="jkp-two">
        <div>
          <label class="jkp-lbl">Название</label>
          <input class="jkp-in" id="jkp-d-name" type="text" maxlength="64" placeholder="Например: Планшет Маши"/>
          <label class="jkp-lbl">Устройства <small>MAC или IP через запятую</small></label>
          <input class="jkp-in mono" id="jkp-d-addr" type="text" spellcheck="false" placeholder="aa:bb:cc:dd:ee:ff"/>
          <input class="jkp-in" id="jkp-d-find" type="text" placeholder="Поиск в сети: имя, IP, MAC" style="margin-top:8px"/>
          <div class="jkp-pick" id="jkp-d-pick"></div>
          <div class="muted" style="font-size:11.5px;margin-top:6px">Лучше выбирать по MAC: он не меняется, когда устройство получает новый IP.
            Телефоны с «частным MAC-адресом» для каждой сети держат его постоянным, пока сеть не забыта.</div>
        </div>
        <div>
          <label class="jkp-lbl">Без интернета</label>
          <div class="jkp-times">
            <span class="muted">с</span><input class="jkp-in" id="jkp-d-from" type="time" step="900" value="23:00"/>
            <span class="muted">до</span><input class="jkp-in" id="jkp-d-to" type="time" step="900" value="07:00"/>
          </div>
          <label class="jkp-lbl">По дням <small>день, когда начинается запрет</small></label>
          <div class="jkp-chips jkp-days" id="jkp-d-days"></div>
          <div class="jkp-presets">
            <a data-days="7,1,2,3,4">Перед школой (Вс–Чт)</a><a data-days="1,2,3,4,5">Будни</a><a data-days="1,2,3,4,5,6,7">Каждый день</a><a data-days="">Без расписания</a>
          </div>
          <label class="jkp-lbl">Неделя</label>
          <div class="jkp-week" id="jkp-d-week"></div>
          <div class="jkp-axis"><span>0:00</span><span>6:00</span><span>12:00</span><span>18:00</span><span>24:00</span></div>
        </div>
      </div>
      <div class="jkp-err" id="jkp-d-err"></div>
      <div style="display:flex;gap:8px;margin-top:16px;justify-content:flex-end">
        <button class="jkp-btn ghost" id="jkp-d-cancel" type="button">Отмена</button>
        <button class="jkp-btn" id="jkp-d-save" type="button">Сохранить и применить</button>
      </div>
    </div>

    <div class="jkp-devs" id="jkp-devs"><div class="jkp-empty">Загрузка…</div></div>

    <div class="jkp-note info"><i class="fa fa-info-circle"></i><div>Расписание проверяется каждые 15 минут, поэтому запрет начинается в пределах
      15 минут от заданного времени. «Пауза» действует сразу. Правила видны в <a href="/ui/firewall/filter">Firewall › Rules</a> с пометкой [jk-ufw]
      и пересоздаются при каждом сохранении здесь, поэтому меняйте их на этой странице.</div></div>
  </div>
</div>

<script>
'use strict';
$(function () {
    // Unbound blocklist keys (Services › Unbound DNS › Blocklists) grouped into UniFi-like content categories.
    const CATEGORIES = [
        {id: 'ads', name: 'Реклама и слежка', icon: 'fa-bullhorn', desc: 'Баннеры, всплывающие окна, счётчики и трекеры в приложениях.', keys: ['hgz002', 'hgz010']},
        {id: 'threats', name: 'Мошенники и вирусы', icon: 'fa-bug', desc: 'Фишинг, поддельные магазины, вредоносные и заражённые сайты.', keys: ['hgz011', 'hgz009']},
        {id: 'adult', name: 'Для взрослых', icon: 'fa-eye-slash', desc: 'Порнография и другие сайты 18+.', keys: ['oisd2']},
        {id: 'gambling', name: 'Азартные игры', icon: 'fa-money', desc: 'Онлайн-казино, ставки, лотереи.', keys: ['hgz019']},
        {id: 'bypass', name: 'Обход фильтра', icon: 'fa-user-secret', desc: 'VPN, Tor, прокси и DNS через HTTPS, которыми обходят блокировки.', keys: ['hgz014']},
        {id: 'social', name: 'Соцсети', icon: 'fa-users', desc: 'ВКонтакте, TikTok, Instagram, Facebook и другие.', keys: ['hgz022']},
        {id: 'piracy', name: 'Пиратство', icon: 'fa-film', desc: 'Торрент-трекеры и сайты с пиратскими фильмами и играми.', keys: ['hgz018']}
    ];
    const LEVELS = {off: [], basic: ['ads', 'threats'], family: ['ads', 'threats', 'adult', 'gambling', 'bypass'],
        strict: ['ads', 'threats', 'adult', 'gambling', 'bypass', 'social', 'piracy']};
    const PREFIX = 'jk-ufw: ';
    const DAYS = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const DOMAIN_RE = /^((?:[a-z0-9]|[a-z0-9][a-z0-9-]*[a-z0-9])\.)+(?:[a-z0-9]|[a-z0-9][a-z0-9-]*[a-z0-9])$/i;
    const IP4_RE = /^\d{1,3}(\.\d{1,3}){3}$/;
    const MAC_RE = /^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i;

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
    const lines = (text) => String(text || '').split(/[\s,]+/).map((s) => s.trim().toLowerCase().replace(/\.$/, '')).filter(Boolean);
    const validationText = (r) => Object.values((r && r.validations) || {}).join(' ');
    const saveOk = (r, what) => {
        if (!r || r.result !== 'saved') {
            throw new Error((what ? what + ': ' : '') + (validationText(r) || 'не сохранено'));
        }
        return r;
    };

    let clients = [];   // from the ARP table: {ip, mac, hostname, intf, vendor}
    const clientName = (c) => c.hostname || c.vendor || c.ip || c.mac;
    function loadClients() {
        return api('/api/diagnostics/interface/get_arp').then((rows) => {
            const seen = {};
            (Array.isArray(rows) ? rows : []).forEach((r) => {
                if (!r.mac || r.mac === '(incomplete)' || r.permanent === true || String(r.permanent) === '1') { return; }
                const key = r.mac.toLowerCase();
                if (!seen[key]) {
                    seen[key] = {ip: r.ip, mac: key, hostname: (r.hostname && r.hostname !== '?') ? r.hostname.split('.')[0] : '',
                        intf: r.intf_description || r.intf || '', vendor: r.manufacturer || ''};
                }
            });
            clients = Object.values(seen).sort((a, b) => clientName(a).localeCompare(clientName(b)));
        }).catch(() => { clients = []; });
    }
    const nameForAddr = (addr) => {
        const a = String(addr).toLowerCase();
        const c = clients.find((x) => x.mac === a || x.ip === a);
        return c ? clientName(c) : '';
    };

    /* ------------------------------------------------------------------ tabs */
    function showTab(tab) {
        $('#jkp-tabs .jkp-tab').each(function () { $(this).toggleClass('sel', $(this).data('tab') === tab); });
        $('#jkp-tab-filter').toggle(tab === 'filter');
        $('#jkp-tab-sched').toggle(tab === 'sched');
        try { history.replaceState(null, '', '#' + tab); } catch (e) { /* ignore */ }
    }
    $('#jkp-tabs').on('click', '.jkp-tab', function () { showTab($(this).data('tab')); });

    /* ================================================================== filtering */
    let saved = null;
    let state = null;
    let sel = 0;
    let busy = false;

    const catOn = (p, c) => c.keys.every((k) => p.keys.includes(k));
    function detectLevel(p) {
        if (!p.enabled) { return 'off'; }
        for (const lvl of ['off', 'basic', 'family', 'strict']) {
            if (CATEGORIES.every((c) => catOn(p, c) === LEVELS[lvl].includes(c.id))) {
                return lvl;
            }
        }
        return 'custom';
    }
    const profileName = (p) => p.global ? 'Вся сеть' : (p.name || 'Без названия');

    async function loadFilter() {
        const [list, ub, pc, acg, acs] = await Promise.all([
            api('/api/unbound/settings/search_dnsbl'),
            api('/api/unbound/settings/get'),
            api('/api/jkufw/parental/get').catch(() => null),
            api('/api/jkufw/appcontrol/get').catch(() => null),
            api('/api/jkufw/appcontrol/status').catch(() => null)
        ]);
        const rows = (list && list.rows) || [];
        const profiles = [];
        for (const row of rows) {
            const g = await api('/api/unbound/settings/get_dnsbl/' + row.uuid);
            const b = (g && g.blocklist) || {};
            const nets = selectedKeys(b.source_nets);
            const desc = String(b.description || '');
            profiles.push({
                uuid: row.uuid, enabled: String(b.enabled) === '1', global: nets.length === 0,
                name: desc.startsWith(PREFIX) ? desc.substring(PREFIX.length) : desc, desc: desc,
                keys: selectedKeys(b.type), nets: nets,
                block: selectedKeys(b.wildcards), allow: selectedKeys(b.allowlists), deleted: false
            });
        }
        // one policy without source networks applies to everybody; show it first, create it when missing
        profiles.sort((a, b) => (b.global - a.global) || (b.enabled - a.enabled));
        const globals = profiles.filter((p) => p.global);
        globals.slice(1).forEach((p) => { p.global = false; p.extraGlobal = true; });
        if (!globals.length) {
            profiles.unshift({uuid: null, enabled: false, global: true, name: 'Вся сеть', desc: '', keys: [], nets: [], block: [], allow: [], deleted: false});
        }
        const general = (ub && ub.unbound && ub.unbound.general) || {};
        const pg = (pc && pc.parental && pc.parental.general) || {};
        saved = {
            profiles: profiles,
            safesearch: String(general.safesearch) === '1',
            foreignDns: String(pg.block_foreign_dns) === '1',
            // HTTPS (SNI) check and DoH/QUIC blocking live in the application control feature (/api/jkufw/appcontrol)
            ac: !!(acg && acg.appcontrol),
            sni: !!(acg && acg.appcontrol && String(acg.appcontrol.sni_filter) === '1'),
            doh: !!(acg && acg.appcontrol && String(acg.appcontrol.block_doh) === '1'),
            quic: !!(acg && acg.appcontrol && String(acg.appcontrol.block_quic) === '1'),
            ipsOn: !!(acs && acs.ids && acs.ids.enabled && acs.ids.ips),
            unboundOn: String(general.enabled) === '1'
        };
        state = clone(saved);
        sel = Math.min(sel, state.profiles.length - 1);
    }

    const diffable = (s) => ({
        p: s.profiles.map((p) => [p.uuid, p.deleted, p.enabled, p.name, [...p.keys].sort(), p.nets, p.block, p.allow]),
        s: s.safesearch, f: s.foreignDns, ac: [s.sni, s.doh, s.quic]
    });
    const isDirty = () => state && saved && JSON.stringify(diffable(state)) !== JSON.stringify(diffable(saved));

    function renderFilter() {
        const visible = state.profiles.map((p, i) => [p, i]).filter(([p]) => !p.deleted);
        if (!visible.some(([, i]) => i === sel)) { sel = visible[0][1]; }
        const p = state.profiles[sel];

        $('#jkp-profiles').html(visible.map(([x, i]) => {
            const lvl = detectLevel(x);
            const note = lvl === 'off' ? 'выкл' : (x.global ? '' : (x.nets.length + ' устр.'));
            return `<span class="jkp-chip ${i === sel ? 'sel' : ''}" data-i="${i}"><i class="fa ${x.global ? 'fa-globe' : 'fa-child'}"></i>${esc(profileName(x))}${note ? `<small>${esc(note)}</small>` : ''}</span>`;
        }).join('') + '<span class="jkp-chip add" id="jkp-prof-add"><i class="fa fa-plus"></i>Профиль для устройств</span>');
        $('#jkp-prof-hint').text(p.global ? 'Действует на все устройства без своего профиля' : 'Только для выбранных устройств');

        $('#jkp-prof-edit').toggle(!p.global);
        if (!p.global) {
            if (!$('#jkp-prof-name').is(':focus')) { $('#jkp-prof-name').val(p.name); }
            if (!$('#jkp-prof-nets').is(':focus')) { $('#jkp-prof-nets').val(p.nets.join(', ')); }
            renderPicker('#jkp-prof-pick', p.nets, '', true);
        }

        const lvl = detectLevel(p);
        $('#jkp-levels .jkp-opt').each(function () { $(this).toggleClass('sel', $(this).data('level') === lvl); });
        let n = 0;
        $('#jkp-cats').html(CATEGORIES.map((c) => {
            const on = p.enabled && catOn(p, c);
            n += on ? 1 : 0;
            return `<div class="jkp-cat ${on ? 'on' : ''}" data-cat="${c.id}">
                <div class="ci"><i class="fa ${c.icon}"></i></div>
                <div class="cm"><div class="cn">${esc(c.name)}</div><div class="cd">${esc(c.desc)}</div></div>
                <div class="jkp-sw"></div></div>`;
        }).join(''));
        const other = p.keys.filter((k) => !CATEGORIES.some((c) => c.keys.includes(k)));
        $('#jkp-cat-count').text(lvl === 'custom' ? 'Свой набор' + (other.length ? ` · ещё ${other.length} списк. из «Расширенных»` : '')
            : (other.length ? `ещё ${other.length} списк. из «Расширенных»` : ''));

        if (!$('#jkp-block').is(':focus')) { $('#jkp-block').val(p.block.join('\n')); }
        if (!$('#jkp-allow').is(':focus')) { $('#jkp-allow').val(p.allow.join('\n')); }
        $('#jkp-safesearch').toggleClass('on', state.safesearch);
        $('#jkp-foreigndns').toggleClass('on', state.foreignDns);
        $('#jkp-ac').toggle(state.ac);
        $('#jkp-sni').toggleClass('on', state.sni);
        $('#jkp-doh').toggleClass('on', state.doh);
        $('#jkp-quic').toggleClass('on', state.quic);
        $('#jkp-ac-ips').toggle(state.sni && !state.ipsOn);
        $('#jkp-unbound-off').toggle(!state.unboundOn);
        const anyOn = state.profiles.some((x) => !x.deleted && x.enabled && x.keys.length);
        $('#jkp-logo').toggleClass('off', !anyOn);

        const bad = validateFilter();
        $('#jkp-list-err').text(bad);
        const dirty = isDirty();
        $('#jkp-apply').prop('disabled', !dirty || busy || !!bad);
        $('#jkp-reset').prop('disabled', !dirty || busy);
        if (!busy) {
            $('#jkp-bar-st').html(dirty ? '<b>Есть несохранённые изменения.</b> Нажмите «Применить», чтобы включить их.' : 'Изменений нет.');
        }
    }

    function validateFilter() {
        for (const p of state.profiles) {
            if (p.deleted) { continue; }
            const badDom = [...p.block, ...p.allow].find((d) => !DOMAIN_RE.test(d));
            if (badDom) { return `«${badDom}» не похоже на адрес сайта (${profileName(p)}).`; }
            if (!p.global) {
                if (!p.name.trim()) { return 'Укажите название профиля.'; }
                if (!p.nets.length) { return `Добавьте устройства в профиль «${profileName(p)}».`; }
                const badIp = p.nets.find((x) => !IP4_RE.test(x));
                if (badIp) { return `«${badIp}»: для фильтра нужен IPv4-адрес устройства.`; }
            }
        }
        return '';
    }

    // device picker shared by filter profiles (IP) and schedules (MAC)
    function renderPicker(target, selected, query, byIp) {
        const q = String(query || '').toLowerCase();
        const rows = clients.filter((c) => !q || [c.hostname, c.ip, c.mac, c.vendor].join(' ').toLowerCase().includes(q));
        if (!rows.length) {
            $(target).html(`<div class="jkp-empty" style="padding:14px">${clients.length ? 'Ничего не найдено' : 'Устройства в сети не найдены. Введите адрес вручную.'}</div>`);
            return;
        }
        const set = new Set(selected.map((s) => s.toLowerCase()));
        $(target).html(rows.slice(0, 80).map((c) => {
            const val = byIp ? c.ip : c.mac;
            return `<div class="jkp-pick-row ${set.has(val) ? 'sel' : ''}" data-v="${esc(val)}">
                <i class="fa fa-${/phone|android|iphone/i.test(clientName(c)) ? 'mobile' : 'laptop'} muted"></i>
                <div class="pn">${esc(clientName(c))}<div class="pa">${esc(c.ip)} · ${esc(c.mac)}${c.intf ? ' · ' + esc(c.intf) : ''}</div></div>
                <i class="fa fa-check"></i></div>`;
        }).join(''));
    }

    $('#jkp-profiles').on('click', '.jkp-chip', function () {
        if (busy) { return; }
        if (this.id === 'jkp-prof-add') {
            state.profiles.push({uuid: null, enabled: true, global: false, name: 'Дети', desc: '', keys: [].concat(...LEVELS.family.map((id) => CATEGORIES.find((c) => c.id === id).keys)),
                nets: [], block: [], allow: [], deleted: false});
            sel = state.profiles.length - 1;
        } else {
            sel = Number($(this).data('i'));
        }
        renderFilter();
    });
    $('#jkp-prof-name').on('input', function () { state.profiles[sel].name = String($(this).val()); renderFilter(); });
    $('#jkp-prof-nets').on('input', function () { state.profiles[sel].nets = lines($(this).val()); renderFilter(); });
    $('#jkp-prof-pick').on('click', '.jkp-pick-row', function () {
        const p = state.profiles[sel];
        const v = String($(this).data('v'));
        p.nets = p.nets.includes(v) ? p.nets.filter((x) => x !== v) : [...p.nets, v];
        if ((!p.name || p.name === 'Дети') && p.nets.length === 1 && !p.uuid) { /* keep the default name */ }
        renderFilter();
    });
    $('#jkp-prof-del').on('click', () => {
        const p = state.profiles[sel];
        if (p.uuid) { p.deleted = true; } else { state.profiles.splice(sel, 1); }
        sel = 0;
        renderFilter();
    });
    $('#jkp-levels').on('click', '.jkp-opt', function () {
        if (busy) { return; }
        const p = state.profiles[sel];
        const lvl = $(this).data('level');
        const managed = [].concat(...CATEGORIES.map((c) => c.keys));
        p.keys = p.keys.filter((k) => !managed.includes(k));
        LEVELS[lvl].forEach((id) => { p.keys.push(...CATEGORIES.find((c) => c.id === id).keys); });
        p.enabled = lvl !== 'off' || p.keys.length > 0 || p.block.length > 0;
        renderFilter();
    });
    $('#jkp-cats').on('click', '.jkp-cat', function () {
        if (busy) { return; }
        const p = state.profiles[sel];
        const c = CATEGORIES.find((x) => x.id === $(this).data('cat'));
        if (p.enabled && catOn(p, c)) {
            p.keys = p.keys.filter((k) => !c.keys.includes(k));
        } else {
            if (!p.enabled) {
                p.enabled = true;
                p.keys = p.keys.filter((k) => !CATEGORIES.some((x) => x.keys.includes(k)));
            }
            c.keys.forEach((k) => { if (!p.keys.includes(k)) { p.keys.push(k); } });
        }
        renderFilter();
    });
    $('#jkp-block').on('input', function () {
        const p = state.profiles[sel];
        p.block = lines($(this).val());
        if (p.block.length) { p.enabled = true; }
        renderFilter();
    });
    $('#jkp-allow').on('input', function () { state.profiles[sel].allow = lines($(this).val()); renderFilter(); });
    $('#jkp-safesearch, #jkp-foreigndns, #jkp-sni, #jkp-doh, #jkp-quic').on('click keydown', function (e) {
        if (busy || (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter')) { return; }
        e.preventDefault();
        const key = {'jkp-safesearch': 'safesearch', 'jkp-foreigndns': 'foreignDns', 'jkp-sni': 'sni', 'jkp-doh': 'doh', 'jkp-quic': 'quic'}[this.id];
        state[key] = !state[key];
        renderFilter();
    });
    $('#jkp-reset').on('click', () => { state = clone(saved); sel = 0; renderFilter(); });

    function steps(list) {
        $('#jkp-bar-st').html('<ul class="jkp-steps">' + list.map((s) =>
            `<li class="${s.st}"><i class="fa fa-fw ${s.st === 'done' ? 'fa-check' : (s.st === 'run' ? 'fa-spinner fa-pulse' : (s.st === 'err' ? 'fa-times' : 'fa-circle-o'))}"></i> ${esc(s.t)}</li>`
        ).join('') + '</ul>');
    }

    async function applyFilter() {
        busy = true;
        renderFilter();
        const before = {};
        saved.profiles.forEach((p) => { before[p.uuid] = JSON.stringify(diffable({profiles: [p], safesearch: 0, foreignDns: 0})); });
        const changedProfiles = state.profiles.filter((p) => p.deleted || !p.uuid ||
            before[p.uuid] !== JSON.stringify(diffable({profiles: [p], safesearch: 0, foreignDns: 0})));
        const plan = [];
        if (changedProfiles.length) {
            plan.push({t: 'Сохранение профилей', st: '', fn: async () => {
                for (const p of changedProfiles) {
                    if (p.deleted) {
                        if (p.uuid) { await api('/api/unbound/settings/del_dnsbl/' + p.uuid, {}); }
                        continue;
                    }
                    if (!p.uuid && !p.enabled && !p.keys.length && !p.block.length && !p.allow.length) {
                        continue; // untouched placeholder for the whole network
                    }
                    const desc = p.global && !p.desc ? PREFIX + 'Вся сеть' : (p.global ? p.desc : PREFIX + p.name.trim());
                    const payload = {blocklist: {enabled: p.enabled ? '1' : '0', type: p.keys.join(','), source_nets: p.nets.join(','),
                        wildcards: p.block.join(','), allowlists: p.allow.join(','), description: desc}};
                    if (p.uuid) {
                        saveOk(await api('/api/unbound/settings/set_dnsbl/' + p.uuid, payload), profileName(p));
                    } else {
                        saveOk(await api('/api/unbound/settings/add_dnsbl', payload), profileName(p));
                    }
                }
            }});
        }
        if (state.safesearch !== saved.safesearch) {
            plan.push({t: 'Безопасный поиск', st: '', fn: async () => {
                saveOk(await api('/api/unbound/settings/set', {unbound: {general: {safesearch: state.safesearch ? '1' : '0'}}}));
            }});
        }
        if (changedProfiles.length || state.safesearch !== saved.safesearch) {
            plan.push({t: 'Загрузка списков и перезапуск DNS (может занять минуту)', st: '', fn: async () => {
                if (state.safesearch !== saved.safesearch) {
                    await api('/api/unbound/service/reconfigure', {});
                }
                await api('/api/unbound/service/dnsbl', {});
            }});
        }
        if (state.foreignDns !== saved.foreignDns) {
            plan.push({t: 'Правила для сторонних DNS', st: '', fn: async () => {
                saveOk(await api('/api/jkufw/parental/set', {parental: {general: {block_foreign_dns: state.foreignDns ? '1' : '0'}}}));
                await api('/api/jkufw/parental/apply', {});
            }});
        }
        const acChanged = state.sni !== saved.sni || state.doh !== saved.doh || state.quic !== saved.quic;
        if (acChanged || (state.sni && changedProfiles.length)) {
            plan.push({t: 'Проверка HTTPS и защита от обхода', st: '', fn: async () => {
                if (acChanged) {
                    saveOk(await api('/api/jkufw/appcontrol/set', {appcontrol: {sni_filter: state.sni ? '1' : '0',
                        block_doh: state.doh ? '1' : '0', block_quic: state.quic ? '1' : '0'}}));
                }
                // rules are rebuilt in the background (category lists may be downloaded first)
                await api('/api/jkufw/appcontrol/apply', {});
            }});
        }
        let cur = 0;
        try {
            for (cur = 0; cur < plan.length; cur++) {
                plan[cur].st = 'run';
                steps(plan);
                await plan[cur].fn();
                plan[cur].st = 'done';
                steps(plan);
            }
            await loadFilter();
            busy = false;
            renderFilter();
            $('#jkp-bar-st').html('<b style="color:#22c55e"><i class="fa fa-check"></i> Готово.</b> Новые правила действуют для новых запросов; на устройствах может понадобиться пара минут, пока истечёт их DNS-кеш.');
        } catch (e) {
            plan[cur].st = 'err';
            plan[cur].t += ': ' + e.message;
            busy = false;
            steps(plan);
            $('#jkp-apply').prop('disabled', false);
        }
        loadStats();
    }
    $('#jkp-apply').on('click', applyFilter);

    async function loadStats() {
        try {
            const st = await api('/api/unbound/service/status');
            const running = st && st.status === 'running';
            $('#jkp-status').attr('class', 'jkp-pill ' + (running ? 'ok' : 'bad')).find('span').text(running ? 'DNS работает' : 'DNS остановлен');
        } catch (e) {
            $('#jkp-status').attr('class', 'jkp-pill').find('span').text('нет данных');
        }
        let en = null;
        try { en = await api('/api/unbound/overview/is_enabled'); } catch (e) { en = null; }
        if (!en || !en.enabled || String(en.enabled) === '0') {
            $('#jkp-since').text('');
            $('#jkp-stats').html('<div class="jkp-empty"><i class="fa fa-bar-chart"></i>Статистика DNS выключена.<br/>' +
                'Включите «Enable Statistics» в <a href="/ui/unbound/advanced">Unbound › Advanced</a>, чтобы видеть, что блокируется.</div>');
            return;
        }
        try {
            const t = await api('/api/unbound/overview/totals/8');
            const total = Number(t.total) || 0;
            const blocked = (t.blocked && Number(t.blocked.total)) || 0;
            const since = t.start_time ? new Date(Number(t.start_time) * 1000) : null;
            $('#jkp-since').text(since ? 'с ' + since.toLocaleDateString('ru-RU') : '');
            const top = Object.entries(t.top_blocked || {}).map(([d, v]) => [d, Number(v.total) || 0, v.blocklist || ''])
                .sort((a, b) => b[1] - a[1]).slice(0, 8);
            const tmax = top.length ? top[0][1] : 1;
            $('#jkp-stats').html(`<div class="jkp-kpis">
                <div class="jkp-kpi"><div class="l">Запросов</div><div class="v">${num(total)}</div></div>
                <div class="jkp-kpi"><div class="l">Заблокировано</div><div class="v red">${num(blocked)}</div></div>
                <div class="jkp-kpi"><div class="l">Доля</div><div class="v">${total ? (blocked / total * 100).toFixed(1) : '0'}%</div></div></div>` +
                (top.length ? '<div class="jkp-sec">Чаще всего блокируется</div>' + top.map(([d, v]) =>
                    `<div class="jkp-top"><div class="tn" title="${esc(d)}">${esc(d)}</div><div class="tb" style="width:${Math.round(v / tmax * 60) + 6}px"></div><div class="tv">${num(v)}</div></div>`).join('')
                    : '<div class="jkp-empty"><i class="fa fa-check-circle"></i>Пока ничего не заблокировано.</div>'));
        } catch (e) {
            $('#jkp-stats').html(`<div class="jkp-empty">Не удалось загрузить: ${esc(e.message)}</div>`);
        }
    }

    const blockReason = (pol) => {
        const where = String(pol.policy || '').replace(PREFIX, '');
        const list = pol.bl ? (pol.category ? pol.category + ': ' : '') + pol.bl : 'свой список';
        return (where ? 'Профиль «' + where + '» · ' : '') + list;
    };
    $('#jkp-test-go').on('click', async () => {
        const domain = String($('#jkp-test-domain').val()).trim().toLowerCase();
        if (!domain) { return; }
        const box = $('#jkp-test-res').attr('class', 'jkp-res').show().html('<i class="fa fa-spinner fa-pulse"></i> Проверяем…');
        try {
            const r = await api('/api/unbound/diagnostics/test_blocklist', {domain: domain, src: String($('#jkp-test-src').val()).trim()});
            const action = String(r.action || r.status || '').toLowerCase();
            if (action === 'block' || action === 'drop' || action === 'blocked') {
                box.addClass('blk').html(`<div class="big"><i class="fa fa-ban"></i> ${esc(domain)} блокируется</div>` +
                    `<div class="muted" style="margin-top:4px">${esc(blockReason(r.policy || {}))}</div>`);
            } else if (action === 'pass' || action === 'allow' || action === 'allowed' || action === 'ok' || action === '') {
                box.addClass('ok').html(`<div class="big"><i class="fa fa-check"></i> ${esc(domain)} открывается</div>` +
                    `<div class="muted" style="margin-top:4px">Ни один список его не блокирует.</div>`);
            } else {
                box.html(`<pre style="white-space:pre-wrap;margin:0;background:none;border:0;color:inherit">${esc(JSON.stringify(r, null, 2))}</pre>`);
            }
        } catch (e) {
            box.html('Не удалось проверить: ' + esc(e.message));
        }
    });
    $('#jkp-test-domain').on('keydown', (e) => { if (e.key === 'Enter') { $('#jkp-test-go').click(); } });

    /* ================================================================== schedules */
    let devices = [];   // {uuid, enabled, name, addresses[], paused, days[], from, to}
    let status = {};    // uuid -> {state, until}
    let editing = null; // device being edited (copy) or null

    const toMin = (hhmm) => { const [h, m] = String(hhmm || '0:0').split(':').map(Number); return h * 60 + (m || 0); };
    const hhmm = (m) => `${Math.floor(m / 60)}:${String(m % 60).padStart(2, '0')}`;
    // same as Parental::allowedRanges(): blocked minutes per weekday 1..7
    function blockedRanges(days, from, to) {
        const f = toMin(from);
        const t = toMin(to);
        const res = {1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: []};
        days.map(Number).forEach((d) => {
            if (d < 1 || d > 7) { return; }
            if (f < t) {
                res[d].push([f, t]);
            } else {
                res[d].push([f, 1440]);
                if (t > 0) { res[d % 7 + 1].push([0, t]); }
            }
        });
        return res;
    }
    function daysSummary(days) {
        const ds = days.map(Number).filter((d) => d >= 1 && d <= 7).sort();
        if (ds.length === 7) { return 'каждый день'; }
        if (!ds.length) { return ''; }
        // join runs, also across Sunday -> Monday
        const set = new Set(ds);
        let start = ds.find((d) => !set.has(d === 1 ? 7 : d - 1)) || ds[0];
        const out = [];
        for (let i = 0, d = start; i < 7; i++, d = d % 7 + 1) {
            if (!set.has(d)) { continue; }
            const prev = d === 1 ? 7 : d - 1;
            if (set.has(prev) && out.length && d !== start) {
                out[out.length - 1][1] = d;
            } else {
                out.push([d, d]);
            }
        }
        return out.map(([a, b]) => a === b ? DAYS[a - 1] : (b === a % 7 + 1 ? DAYS[a - 1] + ', ' + DAYS[b - 1] : DAYS[a - 1] + '–' + DAYS[b - 1])).join(', ');
    }
    const todayIso = () => { const d = new Date().getDay(); return d === 0 ? 7 : d; };
    const nowMin = () => { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); };

    function weekHtml(dev) {
        const br = blockedRanges(dev.days, dev.from, dev.to);
        const today = todayIso();
        return DAYS.map((name, i) => {
            const d = i + 1;
            const spans = (dev.paused ? [[0, 1440]] : br[d]).map(([a, b]) => `<span style="left:${a / 14.4}%;width:${(b - a) / 14.4}%"></span>`).join('');
            const marker = d === today ? `<em style="left:calc(${nowMin() / 14.4}% - 1px)"></em>` : '';
            return `<div class="${d === today ? 'today' : ''}">${name}</div><div class="bar">${spans}${marker}</div>`;
        }).join('');
    }

    async function loadDevices() {
        const [m, st] = await Promise.all([api('/api/jkufw/parental/get'), api('/api/jkufw/parental/status').catch(() => null)]);
        const items = (m && m.parental && m.parental.devices && m.parental.devices.device) || {};
        devices = Object.entries(items).map(([uuid, d]) => ({
            uuid: uuid, enabled: String(d.enabled) === '1', name: String(d.name || ''),
            addresses: selectedKeys(d.addresses), paused: String(d.paused) === '1',
            days: selectedKeys(d.days), from: String(d.block_from || '23:00'), to: String(d.block_to || '07:00')
        }));
        status = {};
        ((st && st.devices) || []).forEach((s) => { status[s.uuid] = s; });
    }

    function stateText(dev) {
        const s = status[dev.uuid] || {};
        const until = s.until ? new Date(s.until) : null;
        const when = until ? (until.toDateString() === new Date().toDateString() ? 'до ' : 'до ' + DAYS[(until.getDay() + 6) % 7] + ' ') +
            until.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'}) : '';
        if (!dev.enabled) { return ['off', 'Выключено']; }
        if (dev.paused) { return ['paused', 'Пауза']; }
        if (s.state === 'blocked') { return ['blocked', 'Без интернета ' + when]; }
        if (!dev.days.length) { return ['allowed', 'Интернет есть']; }
        return ['allowed', 'Интернет есть ' + when];
    }

    function renderDevices() {
        if (!devices.length) {
            $('#jkp-devs').html(`<div class="jkp-card jkp-empty" style="grid-column:1/-1"><i class="fa fa-child"></i>
                Пока нет устройств с расписанием.<br/>Нажмите «Добавить устройство», выберите, например, планшет ребёнка и время без интернета.</div>`);
            return;
        }
        $('#jkp-devs').html(devices.map((dev) => {
            const [cls, txt] = stateText(dev);
            const names = dev.addresses.map((a) => nameForAddr(a) || a);
            const sched = dev.days.length ? `<i class="fa fa-moon-o"></i> <span><b>${esc(dev.from)}–${esc(dev.to)}</b> · ${esc(daysSummary(dev.days))}</span>`
                : '<i class="fa fa-moon-o"></i> <span>Без расписания, только пауза</span>';
            return `<div class="jkp-dev ${cls} ${dev.enabled ? '' : 'disabled'}" data-u="${esc(dev.uuid)}">
                <div class="jkp-dev-top">
                    <div class="jkp-av"><i class="fa ${cls === 'paused' ? 'fa-pause' : (cls === 'blocked' ? 'fa-moon-o' : 'fa-child')}"></i></div>
                    <div class="jkp-dev-main"><div class="jkp-dev-nm">${esc(dev.name)}</div>
                        <div class="jkp-dev-ad" title="${esc(dev.addresses.join(', '))}">${esc(names.join(', '))}</div></div>
                </div>
                <div class="jkp-dev-sch">${sched}<span class="jkp-badge ${cls}"><i></i>${esc(txt)}</span></div>
                <div class="jkp-week">${weekHtml(dev)}</div>
                <div class="jkp-dev-act">
                    ${dev.paused ? '<button class="jkp-btn green sm" data-act="resume" type="button"><i class="fa fa-play"></i> Вернуть интернет</button>'
                        : '<button class="jkp-btn sm" data-act="pause" type="button"><i class="fa fa-pause"></i> Пауза</button>'}
                    <span class="sp"></span>
                    <button class="jkp-btn ghost icon" data-act="edit" type="button" title="Изменить"><i class="fa fa-pencil"></i></button>
                    <button class="jkp-btn ghost icon" data-act="del" type="button" title="Удалить"><i class="fa fa-trash"></i></button>
                    <div class="jkp-sw ${dev.enabled ? 'on' : ''}" data-act="toggle" role="switch" tabindex="0" title="Включить или выключить расписание" style="margin-top:0"></div>
                </div></div>`;
        }).join(''));
    }

    function renderEditor() {
        if (!editing) { $('#jkp-dev-edit').hide(); return; }
        $('#jkp-dev-edit').show();
        $('#jkp-dev-edit-title').text(editing.uuid ? 'Изменить: ' + editing.name : 'Новое устройство');
        if (!$('#jkp-d-name').is(':focus')) { $('#jkp-d-name').val(editing.name); }
        if (!$('#jkp-d-addr').is(':focus')) { $('#jkp-d-addr').val(editing.addresses.join(', ')); }
        $('#jkp-d-from').val(editing.from);
        $('#jkp-d-to').val(editing.to);
        $('#jkp-d-days').html(DAYS.map((n, i) => `<span class="jkp-chip ${editing.days.includes(String(i + 1)) ? 'sel' : ''}" data-d="${i + 1}">${n}</span>`).join(''));
        $('#jkp-d-week').html(weekHtml(Object.assign({}, editing, {paused: false})));
        renderPicker('#jkp-d-pick', editing.addresses, $('#jkp-d-find').val(), false);
        $('#jkp-d-err').text('');
    }
    function openEditor(dev) {
        editing = dev ? clone(dev) : {uuid: null, enabled: true, name: '', addresses: [], paused: false, days: ['7', '1', '2', '3', '4'], from: '23:00', to: '07:00'};
        $('#jkp-d-find').val('');
        renderEditor();
        $('html, body').animate({scrollTop: $('#jkp-dev-edit').offset().top - 80}, 200);
    }

    function deviceError(d) {
        if (!d.name.trim()) { return 'Укажите название.'; }
        if (!d.addresses.length) { return 'Выберите устройство из списка или введите его MAC или IP.'; }
        const bad = d.addresses.find((a) => !MAC_RE.test(a) && !IP4_RE.test(a) && !/:/.test(a));
        if (bad) { return `«${bad}» не похоже на MAC или IP-адрес.`; }
        const macs = d.addresses.filter((a) => MAC_RE.test(a)).length;
        if (macs && macs !== d.addresses.length) { return 'Укажите для одного устройства либо MAC-адреса, либо IP-адреса, не вперемешку.'; }
        return '';
    }

    async function devApply(promise, btn) {
        const $b = $(btn);
        const html = $b.html();
        $b.prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>');
        try {
            await promise();
            await loadDevices();
            renderDevices();
            return true;
        } catch (e) {
            $b.prop('disabled', false).html(html);
            alert('Не удалось: ' + e.message);
            return false;
        }
    }

    const devicePayload = (d) => ({device: {enabled: d.enabled ? '1' : '0', name: d.name.trim(), addresses: d.addresses.join(','),
        paused: d.paused ? '1' : '0', days: d.days.join(','), block_from: d.from, block_to: d.to}});

    $('#jkp-dev-add').on('click', () => openEditor(null));
    $('#jkp-d-cancel').on('click', () => { editing = null; renderEditor(); });
    $('#jkp-d-name').on('input', function () { editing.name = String($(this).val()); });
    $('#jkp-d-addr').on('input', function () { editing.addresses = lines($(this).val()); renderPicker('#jkp-d-pick', editing.addresses, $('#jkp-d-find').val(), false); });
    $('#jkp-d-find').on('input', function () { renderPicker('#jkp-d-pick', editing.addresses, $(this).val(), false); });
    $('#jkp-d-pick').on('click', '.jkp-pick-row', function () {
        const v = String($(this).data('v'));
        editing.addresses = editing.addresses.includes(v) ? editing.addresses.filter((x) => x !== v) : [...editing.addresses.filter((x) => MAC_RE.test(x)), v];
        if (!editing.name.trim() && editing.addresses.length === 1) {
            editing.name = nameForAddr(v);
        }
        renderEditor();
    });
    $('#jkp-d-days').on('click', '.jkp-chip', function () {
        const d = String($(this).data('d'));
        editing.days = editing.days.includes(d) ? editing.days.filter((x) => x !== d) : [...editing.days, d];
        renderEditor();
    });
    $('.jkp-presets').on('click', 'a', function () { editing.days = String($(this).data('days') || '').split(',').filter(Boolean); renderEditor(); });
    $('#jkp-d-from, #jkp-d-to').on('change input', function () {
        const v = String($(this).val() || '');
        if (/^\d{2}:\d{2}$/.test(v)) {
            editing[this.id === 'jkp-d-from' ? 'from' : 'to'] = v;
            $('#jkp-d-week').html(weekHtml(Object.assign({}, editing, {paused: false})));
        }
    });
    $('#jkp-d-save').on('click', async function () {
        const err = deviceError(editing);
        if (err) { $('#jkp-d-err').text(err); return; }
        const d = editing;
        const ok = await devApply(async () => {
            const r = d.uuid ? await api('/api/jkufw/parental/set_device/' + d.uuid, devicePayload(d))
                : await api('/api/jkufw/parental/add_device', devicePayload(d));
            saveOk(r);
            await api('/api/jkufw/parental/apply', {});
        }, this);
        $(this).prop('disabled', false).html('Сохранить и применить');
        if (ok) { editing = null; renderEditor(); }
    });
    $('#jkp-devs').on('click keydown', '[data-act]', async function (e) {
        if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; }
        e.preventDefault();
        const dev = devices.find((x) => x.uuid === $(this).closest('.jkp-dev').data('u'));
        if (!dev) { return; }
        const act = $(this).data('act');
        if (act === 'edit') { openEditor(dev); return; }
        if (act === 'del' && !confirm(`Удалить «${dev.name}»? Ограничения для устройства снимутся.`)) { return; }
        await devApply(async () => {
            if (act === 'pause' || act === 'resume') {
                await api(`/api/jkufw/parental/pause/${dev.uuid}/${act === 'pause' ? 1 : 0}`, {});
                return;
            }
            if (act === 'del') {
                await api('/api/jkufw/parental/del_device/' + dev.uuid, {});
            } else if (act === 'toggle') {
                saveOk(await api('/api/jkufw/parental/set_device/' + dev.uuid, devicePayload(Object.assign({}, dev, {enabled: !dev.enabled}))));
            }
            await api('/api/jkufw/parental/apply', {});
        }, this);
    });

    /* ------------------------------------------------------------------ start */
    showTab(window.location.hash === '#sched' ? 'sched' : 'filter');
    loadClients().then(() => {
        if (state) { renderFilter(); }
        if (devices.length) { renderDevices(); }
    });
    loadFilter().then(renderFilter).catch((e) => {
        $('#jkp-bar-st').html('<b style="color:#ff3b47">Не удалось загрузить настройки:</b> ' + esc(e.message));
    });
    loadStats();
    loadDevices().then(renderDevices).catch((e) => {
        $('#jkp-devs').html(`<div class="jkp-card jkp-empty" style="grid-column:1/-1">Не удалось загрузить: ${esc(e.message)}</div>`);
    });
    setInterval(() => {
        if (!busy && !editing) { loadDevices().then(renderDevices).catch(() => null); }
    }, 60000);
});
</script>
