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
 # jk-ufw: country blocking on a clickable world map. Under the hood it is one GeoIP
 # alias (jkufw_geoblock) and two floating block rules, all through the stock APIs:
 # /api/firewall/alias/* and /api/firewall/filter/*.
 #}

<script src="/ui/js/jkufw-worldmap.js"></script>
<style>
.jkg { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; --land:#26262d; color:var(--t); font-size:13px; max-width:1280px; }
.jkg * { box-sizing:border-box; }
.jkg b, .jkg strong { font-family:inherit; font-weight:700; }
.jkg-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jkg-icon { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:24px;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jkg-icon.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkg-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkg-sub { color:var(--m); margin-top:2px; }
.jkg-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jkg-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jkg-pill.ok i { background:var(--a); box-shadow:0 0 0 3px rgba(229,32,46,.2); }
.jkg-pill.warn i { background:var(--warn); }
.jkg-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jkg-grid { display:grid; grid-template-columns:minmax(0,1fr) 340px; gap:16px; align-items:start; }
@media (max-width: 1100px) { .jkg-grid { grid-template-columns:minmax(0,1fr); } }
.jkg-grid > div { min-width:0; }
.jkg-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jkg-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; }
.jkg-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; }
.jkg-card h3 a { color:var(--a2); }

.jkg-mapwrap { position:relative; background:radial-gradient(ellipse at 50% 40%, #15151a 0%, #0e0e11 70%); border:1px solid var(--b);
  border-radius:10px; overflow:hidden; touch-action:none; user-select:none; }
.jkg-map { display:block; width:100%; height:auto; cursor:grab; }
.jkg-map.drag { cursor:grabbing; }
.jkg-map path, .jkg-map circle { fill:var(--land); stroke:#0e0e11; stroke-width:.6; vector-effect:non-scaling-stroke; cursor:pointer; transition:fill .12s; }
.jkg-map circle { stroke:#3a3a44; }
.jkg-map .on { fill:var(--a); stroke:#5a0c12; }
.jkg-map circle.on { stroke:#ff8a92; }
.jkg-map .hov { fill:#3a3a45; }
.jkg-map .on.hov { fill:var(--a2); }
.jkg-map .nodata { fill:#1b1b20; cursor:not-allowed; }
.jkg-zoom { position:absolute; right:10px; top:10px; display:flex; flex-direction:column; gap:4px; }
.jkg-zoom button { width:30px; height:30px; border-radius:8px; border:1px solid var(--b2); background:rgba(24,24,28,.9); color:var(--t); font-size:14px; cursor:pointer; }
.jkg-zoom button:hover { background:var(--h); }
.jkg-tip { position:absolute; pointer-events:none; background:rgba(12,12,15,.95); border:1px solid var(--b2); border-radius:8px; padding:6px 10px;
  font-size:12px; white-space:nowrap; display:none; z-index:3; box-shadow:0 6px 18px rgba(0,0,0,.4); }
.jkg-tip .c { color:var(--m); margin-left:6px; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11px; }
.jkg-tip .s { display:block; color:var(--m); font-size:11px; margin-top:2px; }
.jkg-tip .s.on { color:var(--a2); }
.jkg-legend { display:flex; gap:16px; align-items:center; color:var(--m); font-size:12px; margin-top:10px; flex-wrap:wrap; }
.jkg-legend i { display:inline-block; width:10px; height:10px; border-radius:3px; margin-right:6px; vertical-align:-1px; }
.jkg-legend .hint { margin-left:auto; }

.jkg-seg { display:grid; grid-template-columns:repeat(3,1fr); gap:10px; }
@media (max-width: 700px) { .jkg-seg { grid-template-columns:1fr; } }
.jkg-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px 14px; cursor:pointer; transition:all .15s; }
.jkg-opt:hover { border-color:var(--b2); background:var(--h); }
.jkg-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jkg-opt .nm { font-weight:700; font-size:14px; display:flex; align-items:center; gap:8px; }
.jkg-opt .nm .fa { color:var(--m); }
.jkg-opt.sel .nm .fa { color:var(--a2); }
.jkg-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jkg-row { display:flex; align-items:center; gap:14px; padding:0 0 14px; margin-bottom:14px; border-bottom:1px solid var(--b); }
.jkg-row .rl { flex:1; }
.jkg-row .rn { font-weight:600; font-size:14px; }
.jkg-row .rd { color:var(--m); font-size:12px; margin-top:2px; }
.jkg-sw { flex:none; width:40px; height:22px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jkg-sw::after { content:""; position:absolute; top:2px; left:2px; width:18px; height:18px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jkg-sw.on { background:var(--a); }
.jkg-sw.on::after { left:20px; background:#fff; }

.jkg input.jkg-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:8px 10px !important; width:100% !important; max-width:none !important; height:auto !important; font-size:13px; box-shadow:none !important; }
.jkg input.jkg-in:focus { border-color:var(--b2) !important; outline:none; }
.jkg input.mono { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkg-chips { display:flex; flex-wrap:wrap; gap:6px; margin:12px 0 4px; min-height:24px; max-height:150px; overflow:auto; }
.jkg-chip { display:inline-flex; align-items:center; gap:6px; padding:4px 6px 4px 10px; border-radius:999px; background:var(--abg);
  border:1px solid rgba(229,32,46,.45); font-weight:600; font-size:12px; }
.jkg-chip .cc { color:var(--a2); font-family:ui-monospace,Menlo,Consolas,monospace; font-size:10.5px; }
.jkg-chip .x { width:18px; height:18px; display:grid; place-items:center; border-radius:50%; cursor:pointer; color:var(--m); }
.jkg-chip .x:hover { background:rgba(255,255,255,.08); color:#fff; }
.jkg-list { max-height:520px; overflow:auto; margin:8px -6px 0 0; padding-right:6px; }
.jkg-list::-webkit-scrollbar { width:6px; }
.jkg-list::-webkit-scrollbar-thumb { background:#2c2c33; border-radius:6px; }
.jkg-reg { display:flex; align-items:center; gap:8px; padding:10px 2px 6px; position:sticky; top:0; background:var(--s); z-index:1;
  font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); cursor:pointer; }
.jkg-reg .n { color:var(--a2); text-transform:none; letter-spacing:0; }
.jkg-reg .act { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:600; color:var(--m); }
.jkg-reg .act:hover { color:var(--t); }
.jkg-reg .fa-caret-right { transition:transform .15s; }
.jkg-reg.open .fa-caret-right { transform:rotate(90deg); }
.jkg-c { display:flex; align-items:center; gap:10px; padding:7px 8px; border-radius:8px; cursor:pointer; }
.jkg-c:hover, .jkg-c.hov { background:var(--h); }
.jkg-c .cc { width:26px; flex:none; color:var(--m); font-family:ui-monospace,Menlo,Consolas,monospace; font-size:11px; }
.jkg-c .cn { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkg-c .ck { width:18px; height:18px; flex:none; border-radius:5px; border:1.5px solid #3a3a44; display:grid; place-items:center; font-size:11px; color:transparent; }
.jkg-c.on .ck { background:var(--a); border-color:var(--a); color:#fff; }
.jkg-c.on .cn { color:#fff; }

.jkg-kpis { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:10px; margin-bottom:14px; }
@media (max-width: 640px) { .jkg-kpis { grid-template-columns:1fr; } }
.jkg-kpi { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; }
.jkg-kpi .l { color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jkg-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; }
.jkg-kpi .v.red { color:var(--a2); }
.jkg-kpi .d { color:var(--m); font-size:11.5px; margin-top:2px; }
.jkg-ev { display:flex; gap:10px; padding:8px 0; border-top:1px solid var(--b); align-items:center; }
.jkg-ev:first-child { border-top:0; }
.jkg-ev .bd { flex:none; font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:.05em; padding:2px 7px; border-radius:6px;
  background:var(--abg); color:var(--a2); min-width:62px; text-align:center; }
.jkg-ev .bd.out { background:rgba(245,165,36,.12); color:var(--warn); }
.jkg-ev .em { flex:1; min-width:0; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkg-ev .et { color:var(--m); font-size:11.5px; white-space:nowrap; }
.jkg-empty { color:var(--m); text-align:center; padding:22px 6px; }
.jkg-empty .fa { display:block; font-size:22px; margin-bottom:8px; color:#3a3a42; }

.jkg-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; display:flex; gap:10px; }
.jkg-note .fa { margin-top:2px; }
.jkg-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jkg-note.warn .fa { color:var(--warn); }
.jkg-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jkg-note a { color:var(--a2); }
.jkg-geo { display:flex; align-items:center; gap:14px; flex-wrap:wrap; }
.jkg-geo .gi { width:36px; height:36px; border-radius:10px; display:grid; place-items:center; background:var(--s2); border:1px solid var(--b); color:var(--ok); flex:none; }
.jkg-geo.bad .gi { color:var(--warn); }
.jkg-geo .gt { flex:1; min-width:220px; }
.jkg-geo .gt b { display:block; font-size:14px; }
.jkg-geo .gt span { color:var(--m); font-size:12px; }
.jkg-setup { display:none; margin-top:14px; }
.jkg-setup ol { margin:0 0 12px 18px; padding:0; color:var(--m); line-height:1.7; }
.jkg-setup ol b { color:var(--t); }
.jkg-setup .ln { display:flex; gap:8px; }
.jkg-setup .ln input { flex:1; }
.jkg-setup .res { margin-top:8px; font-size:12.5px; }

.jkg-bar { position:sticky; bottom:0; z-index:5; display:flex; align-items:center; gap:14px; padding:14px 18px; margin-top:4px;
  background:rgba(19,19,22,.92); backdrop-filter:blur(8px); border:1px solid var(--b); border-radius:12px; }
.jkg-bar .st { flex:1; color:var(--m); }
.jkg-bar .st b { color:var(--t); }
.jkg-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff; white-space:nowrap; }
.jkg-btn:hover { background:var(--a2); color:#fff; text-decoration:none; }
.jkg-btn[disabled] { opacity:.5; cursor:default; }
.jkg-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t); font-weight:600; }
.jkg-btn.ghost:hover { background:var(--h); }
.jkg-btn.sm { padding:7px 12px; font-size:12px; }
.jkg-steps { margin:0; padding:0; list-style:none; }
.jkg-steps li { padding:3px 0; color:var(--m); }
.jkg-steps li.done { color:var(--t); }
.jkg-steps li.done .fa { color:var(--ok); }
.jkg-steps li.run .fa { color:var(--a2); }
.jkg-steps li.err { color:var(--a2); }
.jkg .muted { color:var(--m); }
</style>

<div class="jkg" id="jkg">
  <div class="jkg-head">
    <div class="jkg-icon" id="jkg-icon"><i class="fa fa-globe"></i></div>
    <div>
      <h1 class="jkg-title">Блокировка стран <span class="jkg-pill" id="jkg-status"><i></i><span>…</span></span></h1>
      <div class="jkg-sub">Соединения с выбранными странами отбрасываются межсетевым экраном по базе адресов GeoIP</div>
    </div>
    <div class="jkg-head-r">
      <a class="jkg-btn ghost" href="/ui/diagnostics/firewall/log"><i class="fa fa-list"></i>&nbsp; Журнал</a>
      <a class="jkg-btn ghost" href="/ui/firewall/filter"><i class="fa fa-check"></i>&nbsp; Правила</a>
      <a class="jkg-btn ghost" href="/ui/firewall/alias"><i class="fa fa-list-alt"></i>&nbsp; Алиасы</a>
    </div>
  </div>

  <div class="jkg-card" id="jkg-geocard">
    <div class="jkg-geo" id="jkg-geo">
      <div class="gi"><i class="fa fa-database"></i></div>
      <div class="gt"><b id="jkg-geo-t">База GeoIP…</b><span id="jkg-geo-s">&nbsp;</span></div>
      <button class="jkg-btn ghost sm" id="jkg-geo-upd" type="button" style="display:none"><i class="fa fa-refresh"></i>&nbsp; Обновить</button>
      <button class="jkg-btn ghost sm" id="jkg-geo-key" type="button" style="display:none"><i class="fa fa-key"></i>&nbsp; Сменить ключ</button>
    </div>
    <div class="jkg-setup" id="jkg-setup">
      <ol>
        <li>Зарегистрируйтесь бесплатно на <a href="https://www.maxmind.com/en/geolite2/signup" target="_blank" rel="noopener">maxmind.com (GeoLite2)</a>.</li>
        <li>В личном кабинете откройте <b>Manage License Keys</b> и создайте ключ.</li>
        <li>Вставьте ключ ниже. База скачается сразу и дальше будет обновляться сама.</li>
      </ol>
      <div class="ln">
        <input class="jkg-in mono" id="jkg-key" type="text" spellcheck="false" autocomplete="off" placeholder="Лицензионный ключ MaxMind или полный адрес базы"/>
        <button class="jkg-btn" id="jkg-key-save" type="button">Сохранить и скачать</button>
      </div>
      <div class="res" id="jkg-key-res"></div>
    </div>
  </div>

  <div class="jkg-grid">
    <div>
      <div class="jkg-card">
        <h3><i class="fa fa-map-o"></i> Карта <span class="r muted" id="jkg-count"></span></h3>
        <div class="jkg-mapwrap" id="jkg-mapwrap">
          <svg class="jkg-map" id="jkg-map" xmlns="http://www.w3.org/2000/svg"></svg>
          <div class="jkg-zoom">
            <button type="button" data-z="in" title="Приблизить">+</button>
            <button type="button" data-z="out" title="Отдалить">−</button>
            <button type="button" data-z="reset" title="Весь мир"><i class="fa fa-globe"></i></button>
          </div>
          <div class="jkg-tip" id="jkg-tip"></div>
        </div>
        <div class="jkg-legend">
          <span><i style="background:#e5202e"></i>Заблокирована</span>
          <span><i style="background:#26262d"></i>Разрешена</span>
          <span class="hint">Нажмите на страну, чтобы заблокировать. Колесо мыши или +/− приближают.</span>
        </div>
      </div>

      <div class="jkg-card">
        <h3><i class="fa fa-sliders"></i> Настройки</h3>
        <div class="jkg-row">
          <div class="rl"><div class="rn">Блокировка включена</div>
            <div class="rd">Когда выключено, список стран сохраняется, но трафик не блокируется.</div></div>
          <div class="jkg-sw" id="jkg-enabled" role="switch" tabindex="0"></div>
        </div>
        <div class="jkg-seg" id="jkg-dir">
          <div class="jkg-opt" data-dir="in">
            <div class="nm"><i class="fa fa-sign-in"></i> Входящие</div>
            <div class="ds">Из этих стран нельзя подключиться к вам: к сервисам за пробросом портов, VPN и т.п.</div>
          </div>
          <div class="jkg-opt" data-dir="out">
            <div class="nm"><i class="fa fa-sign-out"></i> Исходящие</div>
            <div class="ds">Устройства вашей сети не смогут открыть сайты и серверы в этих странах.</div>
          </div>
          <div class="jkg-opt" data-dir="both">
            <div class="nm"><i class="fa fa-exchange"></i> В обе стороны</div>
            <div class="ds">Полная изоляция: ни туда, ни оттуда. Так делает UniFi Region Blocking.</div>
          </div>
        </div>
        <div class="jkg-note info" style="margin-top:12px"><i class="fa fa-info-circle"></i>
          <div>Локальная сеть не пострадает: частные адреса не относятся ни к одной стране. Но если вы управляете
          межсетевым экраном через интернет, не блокируйте страну, из которой подключаетесь.</div></div>
      </div>

      <div class="jkg-card">
        <h3><i class="fa fa-bolt"></i> Работа правил <span class="r"><a href="/ui/diagnostics/firewall/log">Весь журнал →</a></span></h3>
        <div class="jkg-kpis">
          <div class="jkg-kpi"><div class="l">Стран заблокировано</div><div class="v" id="jkg-k-c">—</div><div class="d" id="jkg-k-c-d">&nbsp;</div></div>
          <div class="jkg-kpi"><div class="l">Отброшено входящих</div><div class="v red" id="jkg-k-in">—</div><div class="d" id="jkg-k-in-d">&nbsp;</div></div>
          <div class="jkg-kpi"><div class="l">Отброшено исходящих</div><div class="v red" id="jkg-k-out">—</div><div class="d" id="jkg-k-out-d">&nbsp;</div></div>
        </div>
        <div class="muted" style="font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;margin-bottom:4px">Последние блокировки</div>
        <div id="jkg-events"><div class="jkg-empty">Загрузка…</div></div>
      </div>
    </div>

    <div>
      <div class="jkg-card">
        <h3><i class="fa fa-flag"></i> Страны <span class="r"><a href="#" id="jkg-clear">Снять все</a></span></h3>
        <input class="jkg-in" id="jkg-search" type="text" spellcheck="false" autocomplete="off" placeholder="Поиск: название или код (CN, KP…)"/>
        <div class="jkg-chips" id="jkg-chips"></div>
        <div class="jkg-list" id="jkg-list"><div class="jkg-empty">Загрузка…</div></div>
      </div>
    </div>
  </div>

  <div class="jkg-bar">
    <div class="st" id="jkg-bar-st">Изменений нет.</div>
    <button class="jkg-btn ghost" id="jkg-reset" type="button" disabled>Отменить</button>
    <button class="jkg-btn" id="jkg-apply" type="button" disabled>Применить</button>
  </div>
</div>

<script>
'use strict';
$(function () {
    const ALIAS = 'jkufw_geoblock';
    const RULE_IN = 'jk-ufw: geoblock in';
    const RULE_OUT = 'jk-ufw: geoblock out';
    const MAXMIND = 'https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&suffix=zip&license_key=';
    const REGIONS = [
        ['Europe', 'Европа'], ['Asia', 'Азия'], ['America', 'Америка'], ['Africa', 'Африка'], ['Australia', 'Австралия'],
        ['Pacific', 'Океания'], ['Indian', 'Индийский океан'], ['Atlantic', 'Атлантика'], ['Arctic', 'Арктика'],
        ['Antarctica', 'Антарктида'], ['', 'Прочее']
    ];
    const MAP = window.JKUFW_WORLDMAP || {w: 1000, h: 470, paths: {}, dots: {}};

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const num = (n) => Number(n || 0).toLocaleString('ru-RU');
    const plural = (n, one, few, many) => {
        const a = Math.abs(n) % 100;
        const b = a % 10;
        return (a > 10 && a < 20) ? many : (b > 1 && b < 5 ? few : (b === 1 ? one : many));
    };
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
    });
    const selectedKeys = (node) => {
        if (typeof node === 'string') {
            return node.split(/[\n,]/).map((s) => s.trim()).filter(Boolean);
        }
        return Object.keys(node || {}).filter((k) => k && String(node[k].selected) === '1');
    };
    let ruNames = null;
    try {
        ruNames = new Intl.DisplayNames(['ru'], {type: 'region'});
    } catch (e) {
        ruNames = null;
    }

    let countries = {};     // code -> {name, region}
    let saved = null;       // {enabled, dir, codes: []}
    let state = null;
    let aliasUuid = null;
    let rules = {in: null, out: null};
    let geo = {};
    let busy = false;
    let search = '';
    const openRegions = new Set();

    const nameOf = (code) => {
        if (code === 'EU') {
            return 'Европа (без страны)';
        }
        let n = null;
        try {
            n = ruNames ? ruNames.of(code) : null;
        } catch (e) {
            n = null;
        }
        return (n && n !== code) ? n : ((countries[code] || {}).name || code);
    };
    const geoReady = () => Number(geo.address_count || 0) > 0;

    /* ---------- map ---------- */
    const svg = document.getElementById('jkg-map');
    const NS = 'http://www.w3.org/2000/svg';
    let vb = {x: 0, y: 0, w: MAP.w, h: MAP.h};
    const shapes = {};  // code -> [elements]

    function buildMap() {
        svg.setAttribute('viewBox', `0 0 ${MAP.w} ${MAP.h}`);
        const add = (code, el) => {
            el.setAttribute('data-c', code);
            svg.appendChild(el);
            (shapes[code] = shapes[code] || []).push(el);
        };
        Object.entries(MAP.paths).forEach(([code, d]) => {
            const p = document.createElementNS(NS, 'path');
            p.setAttribute('d', d);
            add(code, p);
        });
        Object.entries(MAP.dots || {}).forEach(([code, xy]) => {
            const c = document.createElementNS(NS, 'circle');
            c.setAttribute('cx', xy[0]);
            c.setAttribute('cy', xy[1]);
            add(code, c);
        });
        setViewBox(vb);
    }

    function setViewBox(v) {
        const minW = MAP.w / 10;
        v.w = Math.min(MAP.w, Math.max(minW, v.w));
        v.h = v.w * MAP.h / MAP.w;
        v.x = Math.min(MAP.w - v.w, Math.max(0, v.x));
        v.y = Math.min(MAP.h - v.h, Math.max(0, v.y));
        vb = v;
        svg.setAttribute('viewBox', `${v.x} ${v.y} ${v.w} ${v.h}`);
        const r = Math.max(1.2, 3.2 * v.w / MAP.w);
        svg.querySelectorAll('circle').forEach((c) => c.setAttribute('r', r));
    }

    function zoomAt(factor, cx, cy) {
        const w = vb.w / factor;
        const h = w * MAP.h / MAP.w;
        setViewBox({x: cx - (cx - vb.x) * (w / vb.w), y: cy - (cy - vb.y) * (h / vb.h), w: w, h: h});
    }

    const toMap = (ev) => {
        const r = svg.getBoundingClientRect();
        return [vb.x + (ev.clientX - r.left) / r.width * vb.w, vb.y + (ev.clientY - r.top) / r.height * vb.h];
    };

    function paintMap() {
        const on = new Set(state ? state.codes : []);
        Object.entries(shapes).forEach(([code, els]) => {
            els.forEach((el) => el.classList.toggle('on', on.has(code)));
        });
    }

    function hover(code, on) {
        (shapes[code] || []).forEach((el) => el.classList.toggle('hov', on));
        $(`#jkg-list .jkg-c[data-c="${code}"]`).toggleClass('hov', on);
    }

    let drag = null;
    svg.addEventListener('wheel', (ev) => {
        ev.preventDefault();
        const [mx, my] = toMap(ev);
        zoomAt(ev.deltaY < 0 ? 1.25 : 0.8, mx, my);
    }, {passive: false});
    svg.addEventListener('pointerdown', (ev) => {
        drag = {x: ev.clientX, y: ev.clientY, vx: vb.x, vy: vb.y, moved: false};
    });
    window.addEventListener('pointermove', (ev) => {
        if (!drag) {
            return;
        }
        const dx = ev.clientX - drag.x;
        const dy = ev.clientY - drag.y;
        if (!drag.moved && Math.abs(dx) + Math.abs(dy) > 4) {
            drag.moved = true;
            svg.classList.add('drag');
            $('#jkg-tip').hide();
        }
        if (drag.moved) {
            const r = svg.getBoundingClientRect();
            setViewBox({x: drag.vx - dx / r.width * vb.w, y: drag.vy - dy / r.height * vb.h, w: vb.w, h: vb.h});
        }
    });
    window.addEventListener('pointerup', () => {
        svg.classList.remove('drag');
        setTimeout(() => { drag = null; }, 0);
    });
    let hovered = null;
    svg.addEventListener('mousemove', (ev) => {
        const code = ev.target.getAttribute && ev.target.getAttribute('data-c');
        if (hovered && hovered !== code) {
            hover(hovered, false);
        }
        hovered = code || null;
        const tip = $('#jkg-tip');
        if (!code || (drag && drag.moved)) {
            tip.hide();
            return;
        }
        hover(code, true);
        const on = state && state.codes.includes(code);
        tip.html(`<b>${esc(nameOf(code))}</b><span class="c">${esc(code)}</span>
            <span class="s ${on ? 'on' : ''}">${on ? 'Заблокирована · нажмите, чтобы разрешить' : 'Нажмите, чтобы заблокировать'}</span>`);
        const wr = document.getElementById('jkg-mapwrap').getBoundingClientRect();
        let x = ev.clientX - wr.left + 14;
        const y = ev.clientY - wr.top + 14;
        tip.show();
        if (x + tip.outerWidth() > wr.width - 8) {
            x = ev.clientX - wr.left - tip.outerWidth() - 14;
        }
        tip.css({left: x, top: y});
    });
    svg.addEventListener('mouseleave', () => {
        if (hovered) {
            hover(hovered, false);
            hovered = null;
        }
        $('#jkg-tip').hide();
    });
    svg.addEventListener('click', (ev) => {
        if (drag && drag.moved) {
            return;
        }
        const code = ev.target.getAttribute && ev.target.getAttribute('data-c');
        if (code) {
            toggle(code);
            svg.dispatchEvent(new MouseEvent('mousemove', {clientX: ev.clientX, clientY: ev.clientY}));
        }
    });
    $('.jkg-zoom').on('click', 'button', function () {
        const z = $(this).data('z');
        if (z === 'reset') {
            setViewBox({x: 0, y: 0, w: MAP.w, h: MAP.h});
        } else {
            zoomAt(z === 'in' ? 1.5 : 1 / 1.5, vb.x + vb.w / 2, vb.y + vb.h / 2);
        }
    });

    /* ---------- country list ---------- */
    function toggle(code, force) {
        if (busy || !state) {
            return;
        }
        const has = state.codes.includes(code);
        const want = force === undefined ? !has : force;
        if (want && !has) {
            state.codes.push(code);
        } else if (!want && has) {
            state.codes = state.codes.filter((c) => c !== code);
        }
        autoEnable();
        render();
    }

    function autoEnable() {
        // first countries picked on a fresh setup: switch the feature on, so "Apply" really blocks them
        if (!saved.codes.length && !saved.enabled && state.codes.length && !state.enabledTouched) {
            state.enabled = true;
        }
    }

    function renderList() {
        const q = search.trim().toLowerCase();
        const on = new Set(state.codes);
        const byRegion = {};
        Object.keys(countries).forEach((code) => {
            const name = nameOf(code);
            if (q && !(name.toLowerCase().includes(q) || code.toLowerCase() === q || (countries[code].name || '').toLowerCase().includes(q))) {
                return;
            }
            const reg = REGIONS.some((r) => r[0] === countries[code].region) ? countries[code].region : '';
            (byRegion[reg] = byRegion[reg] || []).push({code: code, name: name});
        });
        const html = REGIONS.filter(([key]) => byRegion[key]).map(([key, label]) => {
            const items = byRegion[key].sort((a, b) => a.name.localeCompare(b.name, 'ru'));
            const sel = items.filter((i) => on.has(i.code)).length;
            const open = q || openRegions.has(key);
            const all = sel === items.length;
            return `<div class="jkg-reg ${open ? 'open' : ''}" data-reg="${esc(key)}">
                    <i class="fa fa-caret-right"></i>${esc(label)} <span class="n">${sel ? sel + ' / ' + items.length : ''}</span>
                    <span class="act" data-all="${all ? 0 : 1}">${all ? 'снять все' : 'выбрать все'}</span></div>` +
                (open ? items.map((i) => `<div class="jkg-c ${on.has(i.code) ? 'on' : ''}" data-c="${i.code}">
                    <span class="cc">${i.code}</span><span class="cn">${esc(i.name)}</span><span class="ck"><i class="fa fa-check"></i></span></div>`).join('') : '');
        }).join('');
        $('#jkg-list').html(html || '<div class="jkg-empty">Ничего не найдено</div>');
    }

    function renderChips() {
        const codes = [...state.codes].sort((a, b) => nameOf(a).localeCompare(nameOf(b), 'ru'));
        $('#jkg-chips').html(codes.length ? codes.map((c) =>
            `<span class="jkg-chip" data-c="${c}"><span class="cc">${c}</span>${esc(nameOf(c))}<span class="x" title="Разрешить"><i class="fa fa-times"></i></span></span>`).join('')
            : '<span class="muted">Ни одна страна не выбрана. Нажмите на карту или отметьте в списке.</span>');
        $('#jkg-clear').toggle(codes.length > 0);
    }

    /* ---------- state ---------- */
    const diffable = (s) => ({enabled: s.enabled, dir: s.dir, codes: [...s.codes].sort()});
    const isDirty = () => JSON.stringify(diffable(state)) !== JSON.stringify(diffable(saved));

    function render() {
        paintMap();
        renderList();
        renderChips();
        $('#jkg-enabled').toggleClass('on', state.enabled);
        $('#jkg-dir .jkg-opt').each(function () { $(this).toggleClass('sel', $(this).data('dir') === state.dir); });
        $('#jkg-dir').css('opacity', state.enabled ? 1 : .55);
        const n = state.codes.length;
        $('#jkg-count').text(n ? `${n} ${plural(n, 'страна', 'страны', 'стран')} в списке` : '');

        const dirty = isDirty();
        let blocker = '';
        if (state.enabled && !state.codes.length) {
            blocker = 'Выберите хотя бы одну страну или выключите блокировку.';
        } else if (state.enabled && !geoReady()) {
            blocker = 'Сначала подключите базу GeoIP (вверху страницы): без неё правила ничего не заблокируют.';
        }
        $('#jkg-apply').prop('disabled', !dirty || busy || !!blocker);
        $('#jkg-reset').prop('disabled', !dirty || busy);
        if (!busy) {
            $('#jkg-bar-st').html(dirty ? (blocker ? `<b style="color:#f5a524">${esc(blocker)}</b>`
                : '<b>Есть несохранённые изменения.</b> Нажмите «Применить», чтобы включить их.') : 'Изменений нет.');
        }
        renderStatus();
    }

    function renderStatus() {
        const pill = $('#jkg-status').removeClass('ok warn');
        const icon = $('#jkg-icon').removeClass('on');
        if (!saved) {
            return;
        }
        const n = saved.codes.length;
        if (saved.enabled && n && geoReady()) {
            pill.addClass('ok').find('span').text(`Активна · ${n} ${plural(n, 'страна', 'страны', 'стран')}`);
            icon.addClass('on');
        } else if (saved.enabled && n) {
            pill.addClass('warn').find('span').text('Нет базы GeoIP');
        } else {
            pill.find('span').text('Выключена');
        }
    }

    function renderGeo() {
        const ok = geoReady();
        const hasUrl = !!String(geo.url || '').trim();
        $('#jkg-geo').toggleClass('bad', !ok);
        if (ok) {
            const ts = geo.timestamp ? new Date(geo.timestamp) : null;
            $('#jkg-geo-t').text('База GeoIP подключена');
            $('#jkg-geo-s').text(`${num(geo.address_count)} диапазонов адресов` +
                (ts && !isNaN(ts) ? ` · версия от ${ts.toLocaleDateString('ru-RU')}` : '') + ' · обновляется автоматически');
        } else {
            $('#jkg-geo-t').text(hasUrl ? 'База GeoIP ещё не скачана' : 'Нужна база GeoIP');
            $('#jkg-geo-s').text(hasUrl ? 'Источник указан, но данных нет. Нажмите «Обновить» или проверьте ключ.'
                : 'Страны определяются по базе адресов MaxMind GeoLite2. Она бесплатная, нужен только ключ.');
        }
        $('#jkg-geo-upd').toggle(hasUrl);
        $('#jkg-geo-key').toggle(hasUrl);
        $('#jkg-setup').toggle(!hasUrl);
    }

    async function loadGeo() {
        const g = await api('/api/firewall/alias/get_geo_ip');
        geo = ((g || {}).alias || {}).geoip || {};
        renderGeo();
    }

    async function loadRules() {
        const res = await api('/api/firewall/filter/search_rule?show_all=1', {current: 1, rowCount: -1, searchPhrase: 'jk-ufw: geoblock'});
        const rows = (res && res.rows) || [];
        rules = {in: rows.find((r) => r.description === RULE_IN) || null, out: rows.find((r) => r.description === RULE_OUT) || null};
    }

    async function load() {
        const [list] = await Promise.all([api('/api/firewall/alias/list_countries'), loadGeo()]);
        countries = list || {};
        let codes = [];
        aliasUuid = null;
        const u = await api('/api/firewall/alias/get_alias_uuid/' + ALIAS);
        if (u && u.uuid) {
            aliasUuid = u.uuid;
            const item = await api('/api/firewall/alias/get_item/' + aliasUuid);
            codes = selectedKeys(((item || {}).alias || {}).content).filter((c) => /^[A-Z]{2}$/.test(c));
        }
        await loadRules();
        const inOn = !!rules.in && String(rules.in.enabled) === '1';
        const outOn = !!rules.out && String(rules.out.enabled) === '1';
        saved = {
            enabled: inOn || outOn,
            dir: inOn && outOn ? 'both' : (outOn ? 'out' : (inOn ? 'in' : 'both')),
            codes: codes
        };
        state = JSON.parse(JSON.stringify(saved));
        if (!openRegions.size) {
            const regs = new Set(codes.map((c) => (countries[c] || {}).region));
            REGIONS.forEach(([k]) => { if (regs.has(k)) { openRegions.add(k); } });
            if (!openRegions.size) {
                openRegions.add('Asia');
            }
        }
        render();
    }

    async function loadStats() {
        try {
            await loadRules();
        } catch (e) {
            /* keep the previous numbers */
        }
        const n = saved ? saved.codes.length : 0;
        $('#jkg-k-c').text(num(n));
        $('#jkg-k-c-d').text(saved && saved.enabled ? ({in: 'только входящие', out: 'только исходящие', both: 'в обе стороны'})[saved.dir] : 'блокировка выключена');
        [['in', rules.in], ['out', rules.out]].forEach(([k, r]) => {
            const active = r && String(r.enabled) === '1';
            $(`#jkg-k-${k}`).text(active ? num(r.packets) : '—');
            $(`#jkg-k-${k}-d`).text(active ? `пакетов · ${num(r.evaluations)} проверок` : 'правило выключено');
        });

        const ids = {};
        if (rules.in) { ids[rules.in.uuid] = 'in'; }
        if (rules.out) { ids[rules.out.uuid] = 'out'; }
        let log = [];
        if (Object.keys(ids).length) {
            try {
                log = await api('/api/diagnostics/firewall/log?limit=2000');
            } catch (e) {
                log = [];
            }
        }
        const rows = (Array.isArray(log) ? log : []).filter((r) => ids[r.rid]).slice(0, 10);
        if (!rows.length) {
            const why = !(saved && saved.enabled) ? 'Блокировка выключена.' : 'Пока ничего не заблокировано, или записи уже ушли из журнала.';
            $('#jkg-events').html(`<div class="jkg-empty"><i class="fa fa-check-circle"></i>${why}</div>`);
            return;
        }
        $('#jkg-events').html(rows.map((r) => {
            const dir = ids[r.rid];
            const port = r.dstport ? ':' + r.dstport : '';
            const t = String(r.__timestamp__ || '').replace('T', ' ').slice(11, 16);
            return `<div class="jkg-ev"><span class="bd ${dir}">${dir === 'in' ? 'Вход' : 'Выход'}</span>
                <div class="em" title="${esc(r.src)} → ${esc(r.dst)}${esc(port)}">${esc(r.src)} → ${esc(r.dst)}${esc(port)} <span class="muted">${esc(r.protoname || '')}</span></div>
                <div class="et">${esc(t)}</div></div>`;
        }).join(''));
    }

    function steps(list) {
        $('#jkg-bar-st').html('<ul class="jkg-steps">' + list.map((s) =>
            `<li class="${s.st}"><i class="fa fa-fw ${s.st === 'done' ? 'fa-check' : (s.st === 'run' ? 'fa-spinner fa-pulse' : (s.st === 'err' ? 'fa-times' : 'fa-circle-o'))}"></i> ${esc(s.t)}</li>`
        ).join('') + '</ul>');
    }

    const checkSaved = (r, what) => {
        if (!r || r.result !== 'saved') {
            const msg = Object.values((r && r.validations) || {}).join(' ');
            throw new Error(msg || what + ' не сохранено');
        }
        return r;
    };

    async function apply() {
        busy = true;
        render();
        const plan = [
            {t: 'Список стран (алиас ' + ALIAS + ')', st: ''},
            {t: 'Правила межсетевого экрана', st: ''},
            {t: 'Применение', st: ''}
        ];
        let cur = 0;
        const step = async (i, fn) => {
            cur = i;
            plan[i].st = 'run';
            steps(plan);
            await fn();
            plan[i].st = 'done';
            steps(plan);
        };
        try {
            await step(0, async () => {
                const codes = state.codes.length ? state.codes : saved.codes;
                const alias = {enabled: '1', name: ALIAS, type: 'geoip', proto: 'IPv4,IPv6', content: [...codes].sort().join('\n'),
                    description: 'jk-ufw: blocked countries (managed by Firewall > Country Blocking)'};
                if (aliasUuid) {
                    checkSaved(await api('/api/firewall/alias/set_item/' + aliasUuid, {alias: alias}), 'Алиас');
                } else {
                    aliasUuid = checkSaved(await api('/api/firewall/alias/add_item', {alias: alias}), 'Алиас').uuid;
                }
            });
            await step(1, async () => {
                const want = {in: state.enabled && state.dir !== 'out', out: state.enabled && state.dir !== 'in'};
                for (const k of ['in', 'out']) {
                    const rule = {enabled: want[k] ? '1' : '0', action: 'block', quick: '1', interface: '', direction: 'any',
                        ipprotocol: 'inet46', protocol: 'any', log: '1', sequence: '1',
                        source_net: k === 'in' ? ALIAS : 'any', destination_net: k === 'out' ? ALIAS : 'any',
                        description: k === 'in' ? RULE_IN : RULE_OUT};
                    if (rules[k]) {
                        checkSaved(await api('/api/firewall/filter/set_rule/' + rules[k].uuid, {rule: rule}), 'Правило');
                    } else if (want[k]) {
                        checkSaved(await api('/api/firewall/filter/add_rule', {rule: rule}), 'Правило');
                    }
                }
            });
            await step(2, async () => {
                // reloads the filter (rules) and refreshes alias tables, so the new country list is live
                const r = await api('/api/firewall/alias/reconfigure', {});
                if (r.status && r.status !== 'ok') {
                    throw new Error(r.status);
                }
            });
            await load();
            busy = false;
            render();
            $('#jkg-bar-st').html('<b style="color:#22c55e"><i class="fa fa-check"></i> Готово.</b> ' +
                (saved.enabled ? `Заблокировано ${saved.codes.length} ${plural(saved.codes.length, 'страна', 'страны', 'стран')}.` : 'Блокировка выключена.'));
        } catch (e) {
            plan[cur].st = 'err';
            plan[cur].t += ': ' + e.message;
            busy = false;
            steps(plan);
            $('#jkg-apply').prop('disabled', false);
        }
        loadStats();
    }

    async function saveKey() {
        const v = String($('#jkg-key').val() || '').trim();
        const res = $('#jkg-key-res');
        if (!v) {
            res.html('<span style="color:#f5a524">Вставьте ключ.</span>');
            return;
        }
        const url = /^https?:\/\//i.test(v) ? v : MAXMIND + encodeURIComponent(v);
        const btn = $('#jkg-key-save').prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>&nbsp; Скачиваем…');
        try {
            checkSaved(await api('/api/firewall/alias/set', {alias: {geoip: {url: url}}}), 'Ключ');
            await api('/api/firewall/alias/reconfigure', {});
            await api('/api/firewall/alias/update/geoip', {});
            await loadGeo();
            if (geoReady()) {
                res.html('');
                $('#jkg-key').val('');
            } else {
                res.html('<span style="color:#ff3b47">База не скачалась. Проверьте ключ и что у межсетевого экрана есть доступ в интернет.</span>');
                $('#jkg-setup').show();
            }
        } catch (e) {
            res.html(`<span style="color:#ff3b47">Ошибка: ${esc(e.message)}</span>`);
        }
        btn.prop('disabled', false).text('Сохранить и скачать');
        if (state) {
            render();
        }
    }

    /* ---------- events ---------- */
    $('#jkg-list').on('click', '.jkg-c', function () { toggle(String($(this).data('c'))); });
    $('#jkg-list').on('mouseenter', '.jkg-c', function () { hover(String($(this).data('c')), true); });
    $('#jkg-list').on('mouseleave', '.jkg-c', function () { hover(String($(this).data('c')), false); });
    $('#jkg-list').on('click', '.jkg-reg', function (e) {
        const key = String($(this).data('reg'));
        if ($(e.target).hasClass('act')) {
            if (busy) { return; }
            const all = String($(e.target).data('all')) === '1';
            const q = search.trim();
            Object.keys(countries).filter((c) => (REGIONS.some((r) => r[0] === countries[c].region) ? countries[c].region : '') === key)
                .filter((c) => !q || $(`#jkg-list .jkg-c[data-c="${c}"]`).length)
                .forEach((c) => {
                    const has = state.codes.includes(c);
                    if (all && !has) { state.codes.push(c); }
                    if (!all && has) { state.codes = state.codes.filter((x) => x !== c); }
                });
            autoEnable();
            render();
            return;
        }
        if (openRegions.has(key)) { openRegions.delete(key); } else { openRegions.add(key); }
        renderList();
    });
    $('#jkg-chips').on('click', '.x', function () { toggle(String($(this).closest('.jkg-chip').data('c')), false); });
    $('#jkg-chips').on('mouseenter', '.jkg-chip', function () { hover(String($(this).data('c')), true); });
    $('#jkg-chips').on('mouseleave', '.jkg-chip', function () { hover(String($(this).data('c')), false); });
    $('#jkg-clear').on('click', (e) => {
        e.preventDefault();
        if (!busy) { state.codes = []; render(); }
    });
    $('#jkg-search').on('input', function () { search = String($(this).val()); renderList(); });
    $('#jkg-enabled').on('click keydown', function (e) {
        if (busy || !state || (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter')) { return; }
        e.preventDefault();
        state.enabled = !state.enabled;
        state.enabledTouched = true;
        render();
    });
    $('#jkg-dir').on('click', '.jkg-opt', function () {
        if (busy || !state) { return; }
        state.dir = $(this).data('dir');
        render();
    });
    $('#jkg-reset').on('click', () => { state = JSON.parse(JSON.stringify(saved)); render(); });
    $('#jkg-apply').on('click', apply);
    $('#jkg-key-save').on('click', saveKey);
    $('#jkg-key').on('keydown', (e) => { if (e.key === 'Enter') { saveKey(); } });
    $('#jkg-geo-key').on('click', () => { $('#jkg-setup').toggle(); $('#jkg-key').focus(); });
    $('#jkg-geo-upd').on('click', async function () {
        const btn = $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>&nbsp; Обновляем…');
        try {
            await api('/api/firewall/alias/update/geoip', {});
            await loadGeo();
        } catch (e) {
            $('#jkg-geo-s').text('Не удалось обновить: ' + e.message);
        }
        btn.prop('disabled', false).html('<i class="fa fa-refresh"></i>&nbsp; Обновить');
        if (state) { render(); }
    });

    buildMap();
    load().then(loadStats).catch((e) => {
        $('#jkg-bar-st').html('<b style="color:#ff3b47">Не удалось загрузить настройки:</b> ' + esc(e.message));
    });
    setInterval(() => { if (!busy && saved) { loadStats(); } }, 30000);
});
</script>
