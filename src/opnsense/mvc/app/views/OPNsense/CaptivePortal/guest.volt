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
 # jk-ufw: guest network in one page. A VLAN (or a free port), DHCP, isolation from the
 # local network, a per-device speed limit and a styled login page. Everything goes through
 # stock APIs: interfaces, dnsmasq, firewall, traffic shaper and captive portal.
 #}

<style>
.jkt { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1180px; }
.jkt * { box-sizing:border-box; }
.jkt b, .jkt strong { font-family:inherit; font-weight:700; }
.jkt-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jkt-shield { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:24px;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jkt-shield.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkt-shield.ids { color:var(--warn); }
.jkt-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkt-sub { color:var(--m); margin-top:2px; }
.jkt-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jkt-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jkt-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jkt-pill.bad i { background:var(--a); }
.jkt-head-r { margin-left:auto; display:flex; gap:8px; }
.jkt-grid { display:grid; grid-template-columns:minmax(0,1.35fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1000px) { .jkt-grid { grid-template-columns:minmax(0,1fr); } }
.jkt-grid > div { min-width:0; }
.jkt-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jkt-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; }
.jkt-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; }
.jkt-card h3 a { color:var(--a2); }
.jkt-seg { display:grid; grid-template-columns:repeat(3,1fr); gap:10px; }
@media (max-width: 640px) { .jkt-seg { grid-template-columns:1fr !important; } }
.jkt-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:14px; cursor:pointer; transition:all .15s; position:relative; }
.jkt-opt:hover { border-color:var(--b2); background:var(--h); }
.jkt-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jkt-opt .ic { font-size:18px; color:var(--m); margin-bottom:8px; }
.jkt-opt.sel .ic { color:var(--a2); }
.jkt-opt .nm { font-weight:700; font-size:14px; }
.jkt-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jkt-opt .tag { position:absolute; top:10px; right:10px; font-size:10px; font-weight:700; letter-spacing:.06em; text-transform:uppercase;
  color:var(--a2); background:var(--abg); padding:2px 7px; border-radius:6px; }
.jkt-sw { flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; margin-top:6px; }
.jkt-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.on > .jkt-sw, .jkt-sw.on { background:var(--a); }
.on > .jkt-sw::after, .jkt-sw.on::after { left:16px; background:#fff; }
.jkt-chips { display:flex; flex-wrap:wrap; gap:8px; }
.jkt-chip { padding:7px 13px; border-radius:999px; background:var(--s2); border:1px solid var(--b); cursor:pointer; font-weight:600; user-select:none; }
.jkt-chip:hover { border-color:var(--b2); }
.jkt-chip.sel { background:var(--abg); border-color:var(--a); color:#fff; }
.jkt-chip .fa { margin-right:6px; color:var(--m); }
.jkt-chip.sel .fa { color:var(--a2); }
.jkt-row { display:flex; align-items:center; gap:14px; padding:12px 0; border-top:1px solid var(--b); }
.jkt-row:first-of-type { border-top:0; padding-top:0; }
.jkt-row .rl { flex:1; }
.jkt-row .rn { font-weight:600; }
.jkt-row .rd { color:var(--m); font-size:12px; margin-top:2px; }
.jkt input.jkt-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:8px 10px !important; width:100% !important; max-width:none !important; height:auto !important; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkt-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jkt-note .fa { margin-top:2px; }
.jkt-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jkt-note.warn .fa { color:var(--warn); }
.jkt-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jkt-bar { position:sticky; bottom:0; z-index:5; display:flex; align-items:center; gap:14px; padding:14px 18px; margin-top:4px;
  background:rgba(19,19,22,.92); backdrop-filter:blur(8px); border:1px solid var(--b); border-radius:12px; }
.jkt-bar .st { flex:1; color:var(--m); }
.jkt-bar .st b { color:var(--t); }
.jkt-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff; }
.jkt-btn:hover { background:var(--a2); }
.jkt-btn[disabled] { opacity:.5; cursor:default; }
.jkt-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t); font-weight:600; }
.jkt-btn.ghost:hover { background:var(--h); }
.jkt-kpis { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:10px; margin-bottom:14px; }
.jkt-kpi { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:12px; }
.jkt-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jkt-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; }
.jkt-kpi .v.red { color:var(--a2); }
  background:rgba(245,165,36,.12); color:var(--warn); min-width:74px; text-align:center; }
.jkt-empty { color:var(--m); text-align:center; padding:22px 6px; }
.jkt-empty .fa { display:block; font-size:22px; margin-bottom:8px; color:#3a3a42; }
.jkt-steps { margin:0; padding:0; list-style:none; }
.jkt-steps li { padding:4px 0; color:var(--m); }
.jkt-steps li.done { color:var(--t); }
.jkt-steps li.done .fa { color:var(--ok); }
.jkt-steps li.run .fa { color:var(--a2); }
.jkt-steps li.err { color:var(--a2); }
.jkt .muted { color:var(--m); }
.jkt-sw.dis { opacity:.4; cursor:not-allowed; }
.jkt-head .jkt-sw { margin:0; width:42px; height:24px; cursor:pointer; }
.jkt-head .jkt-sw::after { width:20px; height:20px; }
.jkt-head .jkt-sw.on::after { left:20px; }
.jkt-fields { display:grid; grid-template-columns:repeat(auto-fit,minmax(170px,1fr)); gap:12px; margin-top:14px; }
.jkt-f label { display:block; font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; color:var(--m); margin-bottom:6px; }
.jkt-f .hint { color:var(--m); font-size:11.5px; margin-top:5px; }
.jkt-f .hint.bad { color:var(--a2); }
.jkt textarea.jkt-in, .jkt input.jkt-in.txt { font-family:inherit !important; font-size:13px !important; }
.jkt textarea.jkt-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:8px 10px !important; width:100% !important; max-width:none !important; min-height:64px; resize:vertical; }
.jkt .jkt-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px rgba(229,32,46,.15); }
.jkt-sub2 { font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; color:var(--m); margin:16px 0 8px; }
.jkt-sum { display:grid; grid-template-columns:auto 1fr; gap:8px 18px; font-size:13px; }
.jkt-sum .k { color:var(--m); }
.jkt-sum .v { font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12.5px; }
.jkt-speed { display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:12px; }
.jkt-unit { position:relative; }
.jkt-unit span { position:absolute; right:10px; top:50%; transform:translateY(-50%); color:var(--m); font-size:12px; pointer-events:none; }
.jkt-btn.danger { background:transparent; border:1px solid rgba(229,32,46,.45); color:var(--a2); font-weight:600; }
.jkt-btn.danger:hover { background:var(--abg); }
.jkt-phone { margin:0 auto; max-width:330px; border-radius:26px; padding:10px; background:#060607; border:1px solid var(--b2); box-shadow:0 18px 40px rgba(0,0,0,.45); }
.jkt-screen { position:relative; overflow:hidden; border-radius:18px; padding:26px 18px 18px; text-align:center;
  background:radial-gradient(320px 200px at 50% -40px, rgba(229,32,46,.30), transparent 70%), #0b0b0d; }
.jkt-screen .lg img { height:22px; }
.jkt-screen .wf { width:46px; height:46px; margin:16px auto 10px; border-radius:14px; display:grid; place-items:center; color:#fff; font-size:20px;
  background:linear-gradient(145deg,var(--a2),#a5121c); box-shadow:0 6px 20px rgba(229,32,46,.4); }
.jkt-screen .tt { font-size:17px; font-weight:700; letter-spacing:-.02em; overflow-wrap:anywhere; }
.jkt-screen .tx { color:var(--m); font-size:12px; margin:4px 0 14px; white-space:pre-line; overflow-wrap:anywhere; }
.jkt-screen .in { text-align:left; font-size:10.5px; color:var(--m); font-weight:600; margin-bottom:8px; }
.jkt-screen .in div { height:34px; border-radius:8px; background:var(--s2); border:1px solid var(--b); margin-top:4px; }
.jkt-screen .ck { display:flex; gap:8px; align-items:center; text-align:left; font-size:11.5px; margin:4px 0 10px; }
.jkt-screen .ck i { width:15px; height:15px; border-radius:4px; border:1px solid #3a3a44; flex:none; }
.jkt-screen .ck b { color:var(--a2); font-weight:500; }
.jkt-screen .bt { height:38px; border-radius:10px; background:var(--a); color:#fff; font-weight:700; font-size:13px; display:grid; place-items:center; }
.jkt-screen .ft { color:#5d5d68; font-size:10.5px; margin-top:12px; }
.jkt-guest { display:flex; align-items:center; gap:10px; padding:9px 0; border-top:1px solid var(--b); }
.jkt-guest:first-child { border-top:0; }
.jkt-guest .av { width:32px; height:32px; flex:none; border-radius:9px; display:grid; place-items:center; background:var(--abg); color:var(--a2); }
.jkt-guest .gm { flex:1; min-width:0; }
.jkt-guest .gn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkt-guest .gs { color:var(--m); font-size:11.5px; font-family:ui-monospace,Menlo,Consolas,monospace; }
.jkt-guest .gr { text-align:right; color:var(--m); font-size:11.5px; white-space:nowrap; }
.jkt-guest .gx { border:0; background:none; color:var(--m); padding:4px 6px; border-radius:6px; cursor:pointer; }
.jkt-guest .gx:hover { color:var(--a2); background:var(--abg); }
.jkt-modal { position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.6); display:none; align-items:center; justify-content:center; padding:16px; }
.jkt-modal.open { display:flex; }
.jkt-modal .box { max-width:440px; width:100%; }
</style>

<div class="jkt" id="jkt">
  <div class="jkt-head">
    <div class="jkt-shield" id="jkt-shield"><i class="fa fa-wifi"></i></div>
    <div>
      <h1 class="jkt-title">Гостевая сеть <span class="jkt-pill" id="jkt-status"><i></i><span>…</span></span></h1>
      <div class="jkt-sub">Отдельная сеть для гостей: вход через свою страницу, без доступа к вашим устройствам и с ограничением скорости</div>
    </div>
    <div class="jkt-head-r">
      <a class="jkt-btn ghost" href="/ui/captiveportal/voucher"><i class="fa fa-ticket"></i>&nbsp; Ваучеры</a>
      <a class="jkt-btn ghost" href="/ui/captiveportal"><i class="fa fa-sliders"></i>&nbsp; Расширенные</a>
    </div>
  </div>

  <div class="jkt-grid">
    <div>
      <div class="jkt-card" id="jkt-net-card">
        <h3><i class="fa fa-sitemap"></i> Сеть <span class="r" id="jkt-enabled-wrap" style="display:none">
          <span class="muted" style="margin-right:8px" id="jkt-enabled-lbl">Включена</span>
          <span class="jkt-sw" id="jkt-enabled" role="switch" tabindex="0" style="display:inline-block;margin:0;vertical-align:middle"></span></span></h3>
        <div id="jkt-net-new">
          <div class="jkt-seg" id="jkt-mode">
            <div class="jkt-opt" data-mode="vlan">
              <span class="tag">Рекомендуется</span>
              <div class="ic"><i class="fa fa-tags"></i></div>
              <div class="nm">Новая VLAN</div>
              <div class="ds">Через тот же порт, что и LAN. Точка доступа раздаёт гостевой SSID с этим номером VLAN.</div>
            </div>
            <div class="jkt-opt" data-mode="port">
              <div class="ic"><i class="fa fa-plug"></i></div>
              <div class="nm">Свободный порт</div>
              <div class="ds">Отдельный сетевой порт, к которому подключена гостевая точка доступа.</div>
            </div>
            <div class="jkt-opt" data-mode="iface">
              <div class="ic"><i class="fa fa-random"></i></div>
              <div class="nm">Готовый интерфейс</div>
              <div class="ds">Интерфейс, который уже настроен со статическим адресом.</div>
            </div>
          </div>
          <div id="jkt-pick-vlan">
            <div class="jkt-sub2">Порт, на котором будет VLAN</div>
            <div class="jkt-chips" id="jkt-parents"><span class="muted">Загрузка…</span></div>
          </div>
          <div id="jkt-pick-port">
            <div class="jkt-sub2">Свободный порт</div>
            <div class="jkt-chips" id="jkt-ports"></div>
          </div>
          <div id="jkt-pick-iface">
            <div class="jkt-sub2">Интерфейс</div>
            <div class="jkt-chips" id="jkt-ifaces"></div>
          </div>
          <div class="jkt-fields">
            <div class="jkt-f" id="jkt-f-tag"><label for="jkt-tag">Номер VLAN</label>
              <input class="jkt-in" id="jkt-tag" type="number" min="1" max="4094"/><div class="hint" id="jkt-tag-hint">от 1 до 4094</div></div>
            <div class="jkt-f" id="jkt-f-cidr"><label for="jkt-cidr">Адрес шлюза и маска</label>
              <input class="jkt-in" id="jkt-cidr" type="text" spellcheck="false"/><div class="hint" id="jkt-cidr-hint"></div></div>
          </div>
        </div>
        <div id="jkt-net-sum" style="display:none">
          <div class="jkt-sum" id="jkt-sum"></div>
        </div>
        <div class="jkt-row" style="margin-top:14px;border-top:1px solid var(--b);padding-top:12px">
          <div class="rl"><div class="rn">Раздавать адреса (DHCP)</div><div class="rd" id="jkt-dhcp-d">Гости получают адрес автоматически.</div></div>
          <div class="jkt-sw" id="jkt-dhcp" role="switch" tabindex="0"></div>
        </div>
        <div class="jkt-row">
          <div class="rl"><div class="rn">Изоляция от локальной сети</div><div class="rd">Гости видят только интернет: ни ваших устройств, ни настроек межсетевого экрана.</div></div>
          <div class="jkt-sw" id="jkt-isolate" role="switch" tabindex="0"></div>
        </div>
        <div class="jkt-note warn" id="jkt-vlan-note"><i class="fa fa-info-circle"></i>
          <div>Коммутатор и точка доступа должны пропускать этот номер VLAN с тегом. На точке доступа создайте гостевую сеть Wi-Fi
          и укажите в ней этот номер VLAN.</div></div>
      </div>

      <div class="jkt-card">
        <h3><i class="fa fa-sign-in"></i> Вход для гостей</h3>
        <div class="jkt-seg" id="jkt-auth" style="grid-template-columns:repeat(2,1fr)">
          <div class="jkt-opt" data-auth="open">
            <div class="ic"><i class="fa fa-hand-pointer-o"></i></div>
            <div class="nm">Без пароля</div>
            <div class="ds">Гость нажимает «Подключиться» и, если нужно, соглашается с правилами.</div>
          </div>
          <div class="jkt-opt" data-auth="login">
            <div class="ic"><i class="fa fa-key"></i></div>
            <div class="nm">Ваучер или учётная запись</div>
            <div class="ds">Одноразовые коды на время или пользователи межсетевого экрана.</div>
          </div>
        </div>
        <div id="jkt-servers-wrap">
          <div class="jkt-sub2">Где проверять логин</div>
          <div class="jkt-chips" id="jkt-servers"></div>
          <div class="jkt-note info"><i class="fa fa-ticket"></i><div>Для ваучеров создайте сервер типа <b>Voucher</b> в
            <a href="/system_authservers.php?act=new">System › Access › Servers</a>, затем выпустите коды на странице
            <a href="/ui/captiveportal/voucher">Ваучеры</a>.</div></div>
        </div>
        <div class="jkt-sub2">Страница входа</div>
        <div class="jkt-fields" style="margin-top:0">
          <div class="jkt-f"><label for="jkt-p-title">Заголовок</label><input class="jkt-in txt" id="jkt-p-title" type="text" maxlength="60"/></div>
          <div class="jkt-f"><label for="jkt-p-button">Текст кнопки</label><input class="jkt-in txt" id="jkt-p-button" type="text" maxlength="30"/></div>
        </div>
        <div class="jkt-f" style="margin-top:12px"><label for="jkt-p-text">Приветствие</label><textarea class="jkt-in" id="jkt-p-text" maxlength="600"></textarea></div>
        <div class="jkt-row" style="margin-top:12px;border-top:1px solid var(--b);padding-top:12px">
          <div class="rl"><div class="rn">Согласие с правилами</div><div class="rd">Кнопка входа станет активной только после галочки.</div></div>
          <div class="jkt-sw" id="jkt-p-accept" role="switch" tabindex="0"></div>
        </div>
        <div class="jkt-f" id="jkt-terms-wrap"><label for="jkt-p-terms">Правила пользования</label><textarea class="jkt-in" id="jkt-p-terms" maxlength="4000" style="min-height:90px"></textarea></div>
        <div class="jkt-fields">
          <div class="jkt-f"><label for="jkt-p-redirect">После входа открыть</label><input class="jkt-in" id="jkt-p-redirect" type="text" spellcheck="false" placeholder="https://… (необязательно)"/></div>
        </div>
      </div>

      <div class="jkt-card">
        <h3><i class="fa fa-tachometer"></i> Ограничения</h3>
        <div class="jkt-sub2" style="margin-top:0">Скорость на одно устройство</div>
        <div class="jkt-chips" id="jkt-speeds"></div>
        <div class="jkt-speed">
          <div class="jkt-f"><label for="jkt-down"><span style="color:var(--a2)">▼</span> Загрузка</label>
            <div class="jkt-unit"><input class="jkt-in" id="jkt-down" type="number" min="0" max="10000"/><span>Мбит/с</span></div></div>
          <div class="jkt-f"><label for="jkt-up">▲ Отдача</label>
            <div class="jkt-unit"><input class="jkt-in" id="jkt-up" type="number" min="0" max="10000"/><span>Мбит/с</span></div></div>
        </div>
        <div class="hint muted" style="font-size:11.5px;margin-top:6px">0 означает без ограничения.</div>
        <div class="jkt-sub2">Длительность сеанса</div>
        <div class="jkt-chips" id="jkt-hard"></div>
        <div class="jkt-sub2">Отключать при бездействии</div>
        <div class="jkt-chips" id="jkt-idle"></div>
      </div>
    </div>

    <div>
      <div class="jkt-card">
        <h3><i class="fa fa-mobile"></i> Так увидит гость</h3>
        <div class="jkt-phone"><div class="jkt-screen" id="jkt-preview"></div></div>
      </div>
      <div class="jkt-card">
        <h3><i class="fa fa-users"></i> Гости сейчас <span class="r"><a href="/ui/captiveportal/session">Все сеансы →</a></span></h3>
        <div class="jkt-kpis">
          <div class="jkt-kpi"><div class="l">В сети</div><div class="v red" id="jkt-k-online">—</div></div>
          <div class="jkt-kpi"><div class="l">Загружено</div><div class="v" id="jkt-k-down">—</div></div>
          <div class="jkt-kpi"><div class="l">Отдано</div><div class="v" id="jkt-k-up">—</div></div>
        </div>
        <div id="jkt-guests"><div class="jkt-empty">Загрузка…</div></div>
      </div>
      <div class="jkt-card" id="jkt-danger" style="display:none">
        <h3><i class="fa fa-trash-o"></i> Удаление</h3>
        <div class="muted" style="margin-bottom:12px">Убрать гостевую сеть целиком: портал, правила, ограничения скорости, DHCP,
          интерфейс и VLAN, если их создала эта страница.</div>
        <button class="jkt-btn danger" id="jkt-remove" type="button"><i class="fa fa-trash-o"></i>&nbsp; Удалить гостевую сеть</button>
      </div>
    </div>
  </div>

  <div class="jkt-bar">
    <div class="st" id="jkt-bar-st">Загрузка…</div>
    <button class="jkt-btn ghost" id="jkt-reset" type="button" disabled>Отменить</button>
    <button class="jkt-btn" id="jkt-apply" type="button" disabled>Применить</button>
  </div>

  <div class="jkt-modal" id="jkt-confirm"><div class="jkt-card box">
    <h3><i class="fa fa-exclamation-triangle"></i> Удалить гостевую сеть?</h3>
    <div style="margin-bottom:16px">Гости будут отключены, а их сеть перестанет работать. Отменить это нельзя, но сеть можно создать заново.</div>
    <div style="display:flex;gap:8px;justify-content:flex-end">
      <button class="jkt-btn ghost" type="button" data-close>Отмена</button>
      <button class="jkt-btn" type="button" id="jkt-remove-go">Удалить</button>
    </div>
  </div></div>
</div>

<script>
'use strict';
$(function () {
    // Every object this page creates carries one of these names, so the page can find (and remove) them again.
    const DESC = 'jk-ufw guest';
    const IFDESCR = 'GUEST';
    const ALIAS = 'jkufw_private';
    const TEMPLATE = 'jkufw_guest';
    const RULES = {self: DESC + ': block firewall', priv: DESC + ': block local networks', pass: DESC + ': allow internet'};
    const PIPES = {down: DESC + ': download', up: DESC + ': upload'};
    const SPEEDS = [[0, 0, 'Без ограничения'], [5, 1, '5 / 1'], [10, 2, '10 / 2'], [25, 5, '25 / 5'], [50, 10, '50 / 10'], [100, 20, '100 / 20']];
    const HARD = [[60, '1 час'], [240, '4 часа'], [480, '8 часов'], [1440, 'Сутки'], [0, 'Без ограничения']];
    const IDLE = [[15, '15 минут'], [30, '30 минут'], [60, 'Час'], [0, 'Никогда']];
    const PORTAL_DEFAULTS = {
        title: 'Гостевой Wi-Fi',
        text: 'Добро пожаловать! Подключитесь, чтобы пользоваться интернетом.',
        button: 'Подключиться',
        accept: true,
        terms: 'Сеть предоставляется бесплатно и без гарантий.\n\nЗапрещено нарушать закон, рассылать спам и мешать работе сети. ' +
            'Сеанс может быть прерван в любой момент.',
        redirect: ''
    };

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
    });
    const SEARCH = {current: 1, rowCount: -1, searchPhrase: ''};
    const rows = async (url, extra) => ((await api(url, Object.assign({}, SEARCH, extra || {}))).rows || []);
    // add/set calls answer {result: "saved", uuid} or {result: "failed", validations: {...}}
    const saved_ = (r, what) => {
        if (!r || r.result !== 'saved') {
            const v = Object.values((r && r.validations) || {}).join(' ');
            throw new Error(what + (v ? ': ' + v : ''));
        }
        return r;
    };
    const okStatus = (r, what) => {
        const s = String((r && (r.status || r.result)) || '').trim();
        if (s && !/^ok/i.test(s) && s !== 'saved' && s !== 'deleted') {
            throw new Error(what + ': ' + s);
        }
        return r;
    };
    const selected = (node) => {
        if (typeof node === 'string') {
            return node.split(',').filter(Boolean);
        }
        return Object.keys(node || {}).filter((k) => String(node[k].selected) === '1');
    };
    const optLabel = (o) => (o && typeof o === 'object' ? (o.value ?? o.description ?? '') : String(o ?? ''));
    const fmtBytes = (b) => {
        b = Number(b) || 0;
        const u = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'];
        let i = 0;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (i ? b.toFixed(b < 10 ? 1 : 0) : b) + ' ' + u[i];
    };

    /* --- IPv4 helpers --- */
    const ip2n = (ip) => {
        const p = String(ip).split('.');
        if (p.length !== 4 || p.some((x) => !/^\d{1,3}$/.test(x) || Number(x) > 255)) { return null; }
        return ((Number(p[0]) << 24) >>> 0) + (Number(p[1]) << 16) + (Number(p[2]) << 8) + Number(p[3]);
    };
    const n2ip = (n) => [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].join('.');
    function parseCidr(v) {
        const m = String(v || '').trim().match(/^([\d.]+)\/(\d{1,2})$/);
        if (!m) { return null; }
        const ip = ip2n(m[1]);
        const len = Number(m[2]);
        if (ip === null || len < 8 || len > 30) { return null; }
        const mask = len === 0 ? 0 : (0xffffffff << (32 - len)) >>> 0;
        const net = (ip & mask) >>> 0;
        const bc = (net | (~mask >>> 0)) >>> 0;
        if (ip === net || ip === bc) { return null; }
        const size = bc - net - 1;
        let start = net + Math.max(2, Math.floor(size * 0.4));
        let end = bc - Math.max(1, Math.min(5, Math.floor(size * 0.02)));
        if (size < 16) { start = net + 1; end = bc - 1; }
        if (ip >= start && ip <= end) { start = ip + 1 <= end ? ip + 1 : start; }
        return {ip: n2ip(ip), len: len, net: n2ip(net) + '/' + len, start: n2ip(start), end: n2ip(end), netN: net, bcN: bc};
    }
    const overlaps = (a, b) => a && b && a.netN <= b.bcN && b.netN <= a.bcN;

    /* --- minimal zip support for the login page template --- */
    const CRC = (() => {
        const t = new Uint32Array(256);
        for (let n = 0; n < 256; n++) {
            let c = n;
            for (let k = 0; k < 8; k++) { c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; }
            t[n] = c >>> 0;
        }
        return t;
    })();
    const crc32 = (u8) => {
        let c = 0xffffffff;
        for (let i = 0; i < u8.length; i++) { c = CRC[(c ^ u8[i]) & 255] ^ (c >>> 8); }
        return (c ^ 0xffffffff) >>> 0;
    };
    function zipEntries(u8) {
        const dv = new DataView(u8.buffer, u8.byteOffset, u8.byteLength);
        let eocd = -1;
        for (let i = u8.length - 22; i >= Math.max(0, u8.length - 65557); i--) {
            if (dv.getUint32(i, true) === 0x06054b50) { eocd = i; break; }
        }
        if (eocd < 0) { throw new Error('zip'); }
        const count = dv.getUint16(eocd + 10, true);
        let p = dv.getUint32(eocd + 16, true);
        const out = {};
        for (let n = 0; n < count && dv.getUint32(p, true) === 0x02014b50; n++) {
            const nlen = dv.getUint16(p + 28, true);
            const name = new TextDecoder().decode(u8.subarray(p + 46, p + 46 + nlen));
            const lho = dv.getUint32(p + 42, true);
            const csize = dv.getUint32(p + 20, true);
            const data = lho + 30 + dv.getUint16(lho + 26, true) + dv.getUint16(lho + 28, true);
            out[name] = {name: name, method: dv.getUint16(p + 10, true), crc: dv.getUint32(p + 16, true), csize: csize,
                usize: dv.getUint32(p + 24, true), data: u8.subarray(data, data + csize)};
            p += 46 + nlen + dv.getUint16(p + 30, true) + dv.getUint16(p + 32, true);
        }
        return out;
    }
    async function zipRead(entry) {
        if (entry.method === 0) { return entry.data; }
        if (entry.method !== 8 || typeof DecompressionStream === 'undefined') { throw new Error('zip method'); }
        const s = new Blob([entry.data]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
        return new Uint8Array(await new Response(s).arrayBuffer());
    }
    function zipBuild(entries) {
        const enc = new TextEncoder();
        const parts = [];
        const central = [];
        let off = 0;
        const hdr = (size) => { const b = new Uint8Array(size); return [b, new DataView(b.buffer)]; };
        entries.forEach((e) => {
            const name = enc.encode(e.name);
            const [l, lv] = hdr(30);
            lv.setUint32(0, 0x04034b50, true); lv.setUint16(4, 20, true); lv.setUint16(8, e.method, true);
            lv.setUint16(12, 33, true); lv.setUint32(14, e.crc, true); lv.setUint32(18, e.csize, true);
            lv.setUint32(22, e.usize, true); lv.setUint16(26, name.length, true);
            const [c, cv] = hdr(46);
            cv.setUint32(0, 0x02014b50, true); cv.setUint16(4, 20, true); cv.setUint16(6, 20, true); cv.setUint16(10, e.method, true);
            cv.setUint16(14, 33, true); cv.setUint32(16, e.crc, true); cv.setUint32(20, e.csize, true); cv.setUint32(24, e.usize, true);
            cv.setUint16(28, name.length, true); cv.setUint32(42, off, true);
            parts.push(l, name, e.data);
            central.push(c, name);
            off += 30 + name.length + e.data.length;
        });
        const csize = central.reduce((s, b) => s + b.length, 0);
        const [z, zv] = hdr(22);
        zv.setUint32(0, 0x06054b50, true); zv.setUint16(8, entries.length, true); zv.setUint16(10, entries.length, true);
        zv.setUint32(12, csize, true); zv.setUint32(16, off, true);
        const all = [...parts, ...central, z];
        const res = new Uint8Array(all.reduce((s, b) => s + b.length, 0));
        let p = 0;
        all.forEach((b) => { res.set(b, p); p += b.length; });
        return res;
    }
    const b64 = (u8) => {
        let s = '';
        for (let i = 0; i < u8.length; i += 0x8000) { s += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000)); }
        return btoa(s);
    };
    const unb64 = (s) => Uint8Array.from(atob(String(s || '')), (ch) => ch.charCodeAt(0));

    /* --- state --- */
    let found = {};      // objects of the guest network found on the firewall
    let saved = null;    // settings as found
    let state = null;    // settings being edited
    let env = {};        // choices offered: parents, ports, ifaces, servers, dnsmasq
    let busy = false;
    let cidrTouched = false;

    async function load() {
        const [zones, assigns, vlans, vlanItem, dns, ranges, fwRules, pipes, shRules, aliases, tplModel, zoneDefaults] = await Promise.all([
            rows('/api/captiveportal/settings/search_zones'),
            rows('/api/interfaces/assignment/search_item'),
            rows('/api/interfaces/vlan_settings/search_item'),
            api('/api/interfaces/vlan_settings/get_item').catch(() => ({})),
            api('/api/dnsmasq/settings/get').catch(() => ({})),
            rows('/api/dnsmasq/settings/search_range').catch(() => []),
            rows('/api/firewall/filter/search_rule', {searchPhrase: DESC}).catch(() => []),
            rows('/api/trafficshaper/settings/search_pipes').catch(() => []),
            rows('/api/trafficshaper/settings/search_rules').catch(() => []),
            rows('/api/firewall/alias/search_item', {searchPhrase: ALIAS}).catch(() => []),
            api('/api/captiveportal/template/get').catch(() => ({})),
            api('/api/captiveportal/settings/get_zone')
        ]);
        const f = {};
        f.zone = zones.find((z) => z.description === DESC) || null;
        f.zoneData = f.zone ? ((await api('/api/captiveportal/settings/get_zone/' + f.zone.uuid)).zone || {}) : null;
        f.vlan = vlans.find((v) => v.descr === DESC) || null;
        const ifId = (a) => a.identifier || a.uuid;
        const zoneIf = f.zoneData ? selected(f.zoneData.interfaces)[0] : null;
        f.assign = assigns.find((a) => zoneIf && ifId(a) === zoneIf) ||
            assigns.find((a) => f.vlan && a.if === f.vlan.vlanif) ||
            assigns.find((a) => a.descr === IFDESCR) || null;
        f.ifname = f.assign ? ifId(f.assign) : zoneIf;
        f.range = ranges.find((r) => r.description === DESC) || null;
        f.rules = {};
        Object.entries(RULES).forEach(([k, d]) => { f.rules[k] = fwRules.find((r) => r.description === d) || null; });
        f.pipes = {};
        f.shRules = {};
        Object.entries(PIPES).forEach(([k, d]) => {
            f.pipes[k] = pipes.find((p) => p.description === d) || null;
            f.shRules[k] = shRules.find((r) => r.description === d) || null;
        });
        f.alias = aliases.find((a) => a.name === ALIAS) || null;
        const tpls = (((tplModel.template || {}).templates || {}).template) || {};
        const tplUuid = Object.keys(tpls).find((u) => tpls[u].name === TEMPLATE) || null;
        f.template = tplUuid ? Object.assign({uuid: tplUuid}, tpls[tplUuid]) : null;
        found = f;

        // what the "new network" part can offer
        const parentOpts = ((vlanItem.vlan || {}).if) || {};
        const assignedDevs = new Set(assigns.map((a) => a.if));
        env.parents = Object.entries(parentOpts).map(([k, o]) => ({id: k, label: optLabel(o)}))
            .filter((p) => !/^(vlan|qinq|lo|enc|pflog|pfsync|wg|ovpn|tun|tap)/.test(p.id));
        env.ports = env.parents.filter((p) => !assignedDevs.has(p.id));
        env.ifaces = assigns.filter((a) => ifId(a) !== 'wan' && parseCidr(a.ipaddr) && a.descr !== IFDESCR)
            .map((a) => ({id: ifId(a), label: (a.descr || ifId(a).toUpperCase()), cidr: a.ipaddr, dev: a.if}));
        env.nets = assigns.map((a) => ({id: ifId(a), label: a.descr || ifId(a), net: parseCidr(a.ipaddr)})).filter((x) => x.net);
        env.usedTags = new Set(vlans.filter((v) => !f.vlan || v.uuid !== f.vlan.uuid).map((v) => v.if + '/' + v.tag));
        const zd = f.zoneData || zoneDefaults.zone || {};
        env.servers = Object.entries(zd.authservers || {}).map(([k, o]) => ({id: k, label: optLabel(o) || k}));
        const dm = dns.dnsmasq || {};
        env.dnsmasq = {enabled: String(dm.enable) === '1', ifaces: selected(dm.interface)};

        // portal texts are stored as jkufw.json inside the zone template
        let portal = Object.assign({}, PORTAL_DEFAULTS);
        if (f.template && f.template.content) {
            try {
                const e = zipEntries(unb64(f.template.content))['jkufw.json'];
                if (e) {
                    portal = Object.assign(portal, JSON.parse(new TextDecoder().decode(await zipRead(e))));
                }
            } catch (err) {
                // unreadable template: keep defaults, saving writes a fresh one
            }
        }

        const pipeMbit = (p) => {
            if (!p) { return 0; }
            const bw = Number(p.bandwidth) || 0;
            const m = String(p.bandwidthMetric || 'Mbit');
            return Math.round(bw * ({bit: 1e-6, Kbit: 1e-3, Mbit: 1, Gbit: 1000}[m] || 1) * 100) / 100;
        };
        const assignCidr = f.assign && parseCidr(f.assign.ipaddr) ? f.assign.ipaddr : null;
        const firstParent = env.parents.find((p) => /\[/.test(p.label)) || env.parents[0];
        const tag = f.vlan ? Number(f.vlan.tag) : 50;
        saved = {
            enabled: f.zone ? String(f.zoneData.enabled) === '1' : true,
            mode: f.vlan ? 'vlan' : (f.assign && f.assign.descr === IFDESCR ? 'port' : (f.zone ? 'iface' : 'vlan')),
            parent: f.vlan ? f.vlan.if : (firstParent ? firstParent.id : ''),
            port: f.assign ? f.assign.if : (env.ports[0] ? env.ports[0].id : ''),
            iface: f.ifname || (env.ifaces[0] ? env.ifaces[0].id : ''),
            tag: tag,
            cidr: assignCidr || `192.168.${tag % 256}.1/24`,
            dhcp: f.zone || f.assign ? !!f.range : env.dnsmasq.enabled,
            isolate: f.rules.priv ? String(f.rules.priv.enabled) === '1' : true,
            auth: f.zoneData && selected(f.zoneData.authservers).length ? 'login' : 'open',
            servers: f.zoneData ? selected(f.zoneData.authservers) : [],
            down: pipeMbit(f.pipes.down),
            up: pipeMbit(f.pipes.up),
            hard: f.zoneData ? Number(f.zoneData.hardtimeout) || 0 : 1440,
            idle: f.zoneData ? Number(f.zoneData.idletimeout) || 0 : 30,
            portal: portal
        };
        if (!f.zone && !f.pipes.down) {
            saved.down = 25;
            saved.up = 5;
        }
        state = JSON.parse(JSON.stringify(saved));
        cidrTouched = !!assignCidr;
        render();
    }

    const configured = () => !!found.zone;
    const anyFound = () => !!(found.zone || found.vlan || (found.assign && found.assign.descr === IFDESCR) || found.range ||
        Object.values(found.rules).some(Boolean) || Object.values(found.pipes).some(Boolean) || found.template);
    const diffable = (s) => JSON.stringify(Object.assign({}, s, {servers: [...s.servers].sort()}));

    function validate() {
        const errs = {};
        if (configured()) {
            // network part is fixed once created
        } else if (state.mode === 'vlan') {
            if (!state.parent) { errs.net = 'Выберите порт.'; }
            if (!(state.tag >= 1 && state.tag <= 4094)) { errs.tag = 'Номер VLAN от 1 до 4094.'; }
            else if (env.usedTags.has(state.parent + '/' + state.tag)) { errs.tag = 'Такая VLAN на этом порту уже есть.'; }
        } else if (state.mode === 'port') {
            if (!state.port) { errs.net = 'Свободных портов нет. Выберите VLAN.'; }
        } else if (!state.iface) {
            errs.net = 'Нет подходящих интерфейсов.';
        }
        if (!configured() && state.mode !== 'iface') {
            const c = parseCidr(state.cidr);
            if (!c) {
                errs.cidr = 'Например 192.168.50.1/24';
            } else {
                const clash = env.nets.find((n) => n.id !== found.ifname && overlaps(n.net, c));
                if (clash) { errs.cidr = `Пересекается с сетью ${clash.label} (${clash.net.net}).`; }
            }
        }
        if (state.auth === 'login' && !state.servers.length) { errs.auth = 'Выберите, где проверять логин.'; }
        if (state.portal.redirect && !/^https?:\/\/\S+$/i.test(state.portal.redirect)) { errs.redirect = 'Адрес должен начинаться с http:// или https://'; }
        [state.down, state.up].forEach((v) => { if (!(v >= 0 && v <= 10000)) { errs.speed = 'Скорость от 0 до 10000 Мбит/с.'; } });
        return errs;
    }

    function guestCidr() {
        if (configured() || state.mode === 'iface') {
            const a = found.assign || {};
            const i = env.ifaces.find((x) => x.id === state.iface);
            return parseCidr(a.ipaddr || (i && i.cidr));
        }
        return parseCidr(state.cidr);
    }

    function renderPreview() {
        const p = state.portal;
        const login = state.auth === 'login';
        $('#jkt-preview').html(`<div class="lg"><img src="/ui/themes/jkufw/build/images/default-logo.svg" alt="" onerror="this.style.display='none'"/></div>
            <div class="wf"><i class="fa fa-wifi"></i></div>
            <div class="tt">${esc(p.title || PORTAL_DEFAULTS.title)}</div>
            <div class="tx">${esc(p.text)}</div>
            ${login ? '<div class="in">Логин или код ваучера<div></div></div><div class="in">Пароль<div></div></div>' : ''}
            ${p.accept ? '<div class="ck"><i></i><span>Я принимаю <b>правила пользования</b></span></div>' : ''}
            <div class="bt">${esc(p.button || PORTAL_DEFAULTS.button)}</div>
            <div class="ft">Защищено <b>jk-ufw</b></div>`);
    }

    function render() {
        const isCfg = configured();
        const errs = validate();
        const chip = (sel, attr, id, label, icon) =>
            `<span class="jkt-chip ${sel ? 'sel' : ''}" ${attr}="${esc(id)}"><i class="fa ${icon}"></i>${esc(label)}</span>`;

        // status
        const pill = $('#jkt-status').removeClass('ok bad');
        $('#jkt-shield').toggleClass('on', isCfg && saved.enabled);
        if (isCfg) {
            pill.addClass(saved.enabled ? 'ok' : '').find('span').text(saved.enabled ? 'Работает' : 'Выключена');
        } else if (anyFound()) {
            pill.addClass('bad').find('span').text('Настроена не до конца');
        } else {
            pill.find('span').text('Не настроена');
        }

        // network
        $('#jkt-net-new').toggle(!isCfg);
        $('#jkt-net-sum').toggle(isCfg);
        $('#jkt-enabled-wrap').toggle(isCfg);
        $('#jkt-enabled').toggleClass('on', state.enabled);
        $('#jkt-enabled-lbl').text(state.enabled ? 'Включена' : 'Выключена');
        $('#jkt-danger').toggle(anyFound());
        if (isCfg) {
            const c = guestCidr();
            const sum = [
                ['Интерфейс', `${found.assign ? (found.assign.descr || found.ifname) : found.ifname} (${found.ifname})`],
                ['Устройство', found.vlan ? `${found.vlan.vlanif}, VLAN ${found.vlan.tag} на ${found.vlan.if}` : (found.assign ? found.assign.if : '—')],
                ['Адрес шлюза', c ? `${c.ip}/${c.len}` : '—'],
                ['Сеть гостей', c ? c.net : '—'],
                ['Адреса DHCP', found.range ? `${found.range.start_addr} – ${found.range.end_addr}` : 'не раздаются'],
                ['Портал', found.zone ? `зона ${found.zone.zoneid}` : '—']
            ];
            $('#jkt-sum').html(sum.map(([k, v]) => `<div class="k">${esc(k)}</div><div class="v">${esc(v)}</div>`).join(''));
        } else {
            $('#jkt-mode .jkt-opt').each(function () { $(this).toggleClass('sel', $(this).data('mode') === state.mode); });
            $('#jkt-pick-vlan').toggle(state.mode === 'vlan');
            $('#jkt-pick-port').toggle(state.mode === 'port');
            $('#jkt-pick-iface').toggle(state.mode === 'iface');
            $('#jkt-f-tag').toggle(state.mode === 'vlan');
            $('#jkt-f-cidr').toggle(state.mode !== 'iface');
            $('#jkt-parents').html(env.parents.map((p) => chip(p.id === state.parent, 'data-parent', p.id, p.label, 'fa-plug')).join('') ||
                '<span class="muted">Нет портов</span>');
            $('#jkt-ports').html(env.ports.map((p) => chip(p.id === state.port, 'data-port', p.id, p.label, 'fa-plug')).join('') ||
                '<span class="muted">Все порты уже заняты. Используйте VLAN.</span>');
            $('#jkt-ifaces').html(env.ifaces.map((i) => chip(i.id === state.iface, 'data-iface', i.id, `${i.label} · ${i.cidr}`, 'fa-random')).join('') ||
                '<span class="muted">Нет интерфейсов со статическим адресом, кроме WAN.</span>');
            if (document.activeElement !== $('#jkt-tag')[0]) { $('#jkt-tag').val(state.tag); }
            if (document.activeElement !== $('#jkt-cidr')[0]) { $('#jkt-cidr').val(state.cidr); }
            $('#jkt-tag-hint').text(errs.tag || errs.net || 'от 1 до 4094').toggleClass('bad', !!(errs.tag || errs.net));
            const c = parseCidr(state.cidr);
            $('#jkt-cidr-hint').text(errs.cidr || (c ? `Сеть ${c.net}, гостям ${c.start} – ${c.end}` : ''))
                .toggleClass('bad', !!errs.cidr);
        }
        $('#jkt-vlan-note').toggle(!isCfg ? state.mode === 'vlan' : !!found.vlan);
        const dhcpOk = env.dnsmasq.enabled;
        $('#jkt-dhcp').toggleClass('on', state.dhcp && dhcpOk).toggleClass('dis', !dhcpOk);
        $('#jkt-dhcp-d').html(dhcpOk ? 'Гости получают адрес автоматически (Dnsmasq).'
            : 'Служба Dnsmasq выключена. Включите её в <a href="/ui/dnsmasq/settings">Services › Dnsmasq</a> или настройте DHCP вручную.');
        $('#jkt-isolate').toggleClass('on', state.isolate);

        // login
        $('#jkt-auth .jkt-opt').each(function () { $(this).toggleClass('sel', $(this).data('auth') === state.auth); });
        $('#jkt-servers-wrap').toggle(state.auth === 'login');
        $('#jkt-servers').html(env.servers.map((s) => chip(state.servers.includes(s.id), 'data-server', s.id, s.label,
            /voucher/i.test(s.label) ? 'fa-ticket' : 'fa-user')).join('') || '<span class="muted">Нет серверов</span>');
        const p = state.portal;
        [['title', '#jkt-p-title'], ['button', '#jkt-p-button'], ['text', '#jkt-p-text'], ['terms', '#jkt-p-terms'], ['redirect', '#jkt-p-redirect']]
            .forEach(([k, sel]) => { if (document.activeElement !== $(sel)[0]) { $(sel).val(p[k]); } });
        $('#jkt-p-accept').toggleClass('on', !!p.accept);
        $('#jkt-terms-wrap').toggle(!!p.accept);

        // limits
        $('#jkt-speeds').html(SPEEDS.map(([d, u, l]) => chip(state.down === d && state.up === u, 'data-speed', d + '/' + u, l + (d ? ' Мбит/с' : ''), 'fa-tachometer')).join(''));
        if (document.activeElement !== $('#jkt-down')[0]) { $('#jkt-down').val(state.down); }
        if (document.activeElement !== $('#jkt-up')[0]) { $('#jkt-up').val(state.up); }
        $('#jkt-hard').html(HARD.map(([v, l]) => chip(state.hard === v, 'data-hard', v, l, 'fa-clock-o')).join(''));
        $('#jkt-idle').html(IDLE.map(([v, l]) => chip(state.idle === v, 'data-idle', v, l, 'fa-moon-o')).join(''));

        renderPreview();
        renderBar(errs);
    }

    function renderBar(errs) {
        errs = errs || validate();
        const dirty = diffable(state) !== diffable(saved) || !configured();
        const bad = Object.values(errs);
        $('#jkt-apply').prop('disabled', busy || !dirty || bad.length > 0)
            .html(configured() ? 'Применить' : (anyFound() ? 'Продолжить настройку' : 'Создать гостевую сеть'));
        $('#jkt-reset').prop('disabled', busy || diffable(state) === diffable(saved));
        if (busy) { return; }
        if (bad.length) {
            $('#jkt-bar-st').html('<b style="color:#ff3b47">Проверьте:</b> ' + esc(bad[0]));
        } else if (!configured()) {
            $('#jkt-bar-st').html(anyFound() ? '<b>Настройка прервалась.</b> Нажмите «Продолжить», чтобы создать недостающее, или удалите всё.'
                : 'Выберите сеть и нажмите «Создать гостевую сеть». Это займёт около минуты.');
        } else {
            $('#jkt-bar-st').html(dirty ? '<b>Есть несохранённые изменения.</b> Нажмите «Применить», чтобы включить их.' : 'Изменений нет.');
        }
    }

    function steps(list) {
        $('#jkt-bar-st').html('<ul class="jkt-steps">' + list.map((s) =>
            `<li class="${s.st}"><i class="fa fa-fw ${s.st === 'done' ? 'fa-check' : (s.st === 'run' ? 'fa-spinner fa-pulse' : (s.st === 'err' ? 'fa-times' : 'fa-circle-o'))}"></i> ${esc(s.t)}</li>`
        ).join('') + '</ul>');
    }

    async function run(plan) {
        busy = true;
        renderBar();
        let cur = 0;
        try {
            for (cur = 0; cur < plan.length; cur++) {
                plan[cur].st = 'run';
                steps(plan);
                const note = await plan[cur].fn();
                plan[cur].st = 'done';
                if (note) { plan[cur].t += ' (' + note + ')'; }
                steps(plan);
            }
            return true;
        } catch (e) {
            plan[cur].st = 'err';
            plan[cur].t += ': ' + e.message;
            steps(plan);
            return false;
        } finally {
            busy = false;
        }
    }

    /* --- apply: create whatever is missing, then update the rest --- */
    async function apply() {
        const ctx = {ifname: found.ifname, device: null};
        const plan = [];
        if (!configured() || !ctx.ifname) {
            plan.push({t: 'Сеть и интерфейс', fn: async () => {
                if (state.mode === 'iface') {
                    ctx.ifname = state.iface;
                    return;
                }
                if (found.assign && found.assign.descr === IFDESCR) {
                    ctx.ifname = found.assign.identifier || found.assign.uuid;
                    return;
                }
                let device = state.port;
                if (state.mode === 'vlan') {
                    let vlan = found.vlan;
                    if (!vlan) {
                        const r = saved_(await api('/api/interfaces/vlan_settings/add_item',
                            {vlan: {if: state.parent, tag: String(state.tag), pcp: '0', proto: '', descr: DESC, vlanif: ''}}), 'VLAN');
                        vlan = (await rows('/api/interfaces/vlan_settings/search_item')).find((v) => v.uuid === r.uuid);
                        if (!vlan) { throw new Error('VLAN не найдена после создания'); }
                    }
                    okStatus(await api('/api/interfaces/vlan_settings/reconfigure', {}), 'VLAN');
                    device = vlan.vlanif;
                }
                const r = saved_(await api('/api/interfaces/assignment/add_item', {interface: {
                    if: device, descr: IFDESCR, enable: '1', lock: '0', type4: 'staticv4', ipaddr: state.cidr, type6: ''}}), 'Интерфейс');
                ctx.ifname = r.uuid;
                okStatus(await api('/api/interfaces/assignment/reconfigure', {}), 'Интерфейс');
            }});
        }
        plan.push({t: 'Раздача адресов (DHCP)', fn: async () => {
            const want = state.dhcp && env.dnsmasq.enabled;
            if (want && !found.range) {
                const c = guestCidr();
                if (!c) { throw new Error('у интерфейса нет статического адреса'); }
                saved_(await api('/api/dnsmasq/settings/add_range', {range: {interface: ctx.ifname, start_addr: c.start, end_addr: c.end,
                    description: DESC}}), 'DHCP');
                if (env.dnsmasq.ifaces.length && !env.dnsmasq.ifaces.includes(ctx.ifname)) {
                    saved_(await api('/api/dnsmasq/settings/set', {dnsmasq: {interface: [...env.dnsmasq.ifaces, ctx.ifname].join(',')}}), 'Dnsmasq');
                }
            } else if (!want && found.range) {
                await api('/api/dnsmasq/settings/del_range/' + found.range.uuid, {});
            } else {
                return want ? 'без изменений' : (env.dnsmasq.enabled ? 'выключено' : 'Dnsmasq выключен, пропущено');
            }
            okStatus(await api('/api/dnsmasq/service/reconfigure', {}), 'Dnsmasq');
        }});
        plan.push({t: 'Изоляция и доступ в интернет', fn: async () => {
            if (!found.alias) {
                saved_(await api('/api/firewall/alias/add_item', {alias: {enabled: '1', name: ALIAS, type: 'network',
                    content: '10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16\n169.254.0.0/16', description: 'jk-ufw: private networks (guest isolation)'}}), 'Псевдоним');
                await api('/api/firewall/alias/reconfigure', {});
            }
            const want = {
                self: {action: 'block', destination_net: '(self)', on: state.isolate},
                priv: {action: 'block', destination_net: ALIAS, on: state.isolate},
                pass: {action: 'pass', destination_net: 'any', on: state.enabled}
            };
            for (const k of ['self', 'priv', 'pass']) {
                const rule = found.rules[k];
                if (rule && rule.interface && rule.interface !== ctx.ifname) {
                    await api('/api/firewall/filter/del_rule/' + rule.uuid, {});
                    found.rules[k] = null;
                }
                if (!found.rules[k]) {
                    saved_(await api('/api/firewall/filter/add_rule', {rule: {enabled: want[k].on ? '1' : '0', action: want[k].action,
                        quick: '1', interface: ctx.ifname, direction: 'in', ipprotocol: 'inet', protocol: 'any', source_net: 'any',
                        destination_net: want[k].destination_net, description: RULES[k]}}), 'Правило');
                } else if ((String(rule.enabled) === '1') !== want[k].on) {
                    await api(`/api/firewall/filter/toggle_rule/${rule.uuid}/${want[k].on ? 1 : 0}`, {});
                }
            }
            okStatus(await api('/api/firewall/filter/apply', {}), 'Правила');
        }});
        plan.push({t: 'Ограничение скорости', fn: async () => {
            const c = guestCidr();
            let changed = false;
            for (const dir of ['down', 'up']) {
                const mbit = dir === 'down' ? state.down : state.up;
                const pipe = found.pipes[dir];
                const rule = found.shRules[dir];
                if (mbit > 0) {
                    const pipeData = {pipe: {enabled: '1', bandwidth: String(mbit), bandwidthMetric: 'Mbit',
                        mask: dir === 'down' ? 'dst-ip' : 'src-ip', description: PIPES[dir]}};
                    let pipeUuid = pipe && pipe.uuid;
                    if (!pipe) {
                        pipeUuid = saved_(await api('/api/trafficshaper/settings/add_pipe', pipeData), 'Канал').uuid;
                        changed = true;
                    } else if (Number(pipe.bandwidth) !== mbit || pipe.bandwidthMetric !== 'Mbit') {
                        saved_(await api('/api/trafficshaper/settings/set_pipe/' + pipe.uuid, pipeData), 'Канал');
                        changed = true;
                    }
                    if (!rule || rule.interface !== ctx.ifname) {
                        if (rule) { await api('/api/trafficshaper/settings/del_rule/' + rule.uuid, {}); }
                        if (!c) { throw new Error('у интерфейса нет статического адреса'); }
                        saved_(await api('/api/trafficshaper/settings/add_rule', {rule: {enabled: '1', sequence: dir === 'down' ? '901' : '902',
                            interface: ctx.ifname, proto: 'ip', source: dir === 'down' ? 'any' : c.net, destination: dir === 'down' ? c.net : 'any',
                            target: pipeUuid, description: PIPES[dir]}}), 'Правило скорости');
                        changed = true;
                    }
                } else {
                    if (rule) { await api('/api/trafficshaper/settings/del_rule/' + rule.uuid, {}); changed = true; }
                    if (pipe) { await api('/api/trafficshaper/settings/del_pipe/' + pipe.uuid, {}); changed = true; }
                }
            }
            if (!changed) { return 'без изменений'; }
            okStatus(await api('/api/trafficshaper/service/reconfigure', {}), 'Шейпер');
        }});
        plan.push({t: 'Страница входа', fn: async () => {
            ctx.template = await saveTemplate();
        }});
        plan.push({t: 'Портал и вход для гостей', fn: async () => {
            const zone = {enabled: state.enabled ? '1' : '0', interfaces: ctx.ifname, description: DESC,
                authservers: state.auth === 'login' ? state.servers.join(',') : '', template: ctx.template || '',
                hardtimeout: String(state.hard), idletimeout: String(state.idle), concurrentlogins: '1', roaming: '1'};
            if (found.zone) {
                saved_(await api('/api/captiveportal/settings/set_zone/' + found.zone.uuid, {zone: zone}), 'Портал');
            } else {
                saved_(await api('/api/captiveportal/settings/add_zone', {zone: zone}), 'Портал');
            }
            okStatus(await api('/api/captiveportal/service/reconfigure', {}), 'Портал');
        }});
        const ok = await run(plan);
        const shown = $('#jkt-bar-st').html();
        await load().catch(() => null);
        $('#jkt-bar-st').html(shown + (ok ? '<div style="margin-top:6px"><b style="color:#22c55e"><i class="fa fa-check"></i> Готово.</b> ' +
            (state.enabled ? 'Гости могут подключаться.' : 'Гостевая сеть выключена.') + '</div>' : ''));
        refreshGuests();
    }

    // The login page reads its texts from jkufw.json in the zone template. The stock index.html goes in too:
    // it is identical to the default one, so the firewall strips it and keeps only jkufw.json.
    async function saveTemplate() {
        const p = state.portal;
        const json = new TextEncoder().encode(JSON.stringify({title: p.title, text: p.text, button: p.button, accept: !!p.accept,
            terms: p.accept ? p.terms : '', redirect: p.redirect,
            user_label: 'Логин или код ваучера'}, null, 1));
        const def = await new Promise((resolve, reject) => {
            const x = new XMLHttpRequest();
            x.open('GET', '/api/captiveportal/template/get_template');
            x.responseType = 'arraybuffer';
            x.onload = () => (x.status === 200 ? resolve(new Uint8Array(x.response)) : reject(new Error('шаблон ' + x.status)));
            x.onerror = () => reject(new Error('шаблон недоступен'));
            x.send();
        });
        const index = zipEntries(def)['index.html'];
        if (!index) { throw new Error('в шаблоне нет index.html'); }
        const zip = zipBuild([
            index,
            {name: 'jkufw.json', method: 0, crc: crc32(json), csize: json.length, usize: json.length, data: json}
        ]);
        const payload = {name: TEMPLATE, content: b64(zip)};
        if (found.template) { payload.uuid = found.template.uuid; }
        const r = await new Promise((resolve, reject) => {
            $.ajax({type: 'POST', url: '/api/captiveportal/template/save_template', data: payload, dataType: 'json'})
                .done(resolve).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
        });
        if (!r || r.error) { throw new Error((r && r.error) || 'не сохранено'); }
        const t = (await rows('/api/captiveportal/template/search_templates')).find((x) => x.name === TEMPLATE);
        if (!t) { throw new Error('шаблон не найден после сохранения'); }
        return t.uuid;
    }

    async function removeAll() {
        const f = found;
        const tolerant = async (url) => { try { await api(url, {}); } catch (e) { /* already gone */ } };
        const plan = [];
        if (f.zone || f.template) {
            plan.push({t: 'Портал и страница входа', fn: async () => {
                if (f.zone) {
                    await api('/api/captiveportal/settings/del_zone/' + f.zone.uuid, {});
                    await api('/api/captiveportal/service/reconfigure', {});
                }
                if (f.template) { await tolerant('/api/captiveportal/template/del_template/' + f.template.uuid); }
            }});
        }
        if (Object.values(f.pipes).some(Boolean) || Object.values(f.shRules).some(Boolean)) {
            plan.push({t: 'Ограничение скорости', fn: async () => {
                for (const r of Object.values(f.shRules).filter(Boolean)) { await tolerant('/api/trafficshaper/settings/del_rule/' + r.uuid); }
                for (const p of Object.values(f.pipes).filter(Boolean)) { await tolerant('/api/trafficshaper/settings/del_pipe/' + p.uuid); }
                await api('/api/trafficshaper/service/reconfigure', {});
            }});
        }
        if (Object.values(f.rules).some(Boolean)) {
            plan.push({t: 'Правила межсетевого экрана', fn: async () => {
                for (const r of Object.values(f.rules).filter(Boolean)) { await tolerant('/api/firewall/filter/del_rule/' + r.uuid); }
                await api('/api/firewall/filter/apply', {});
            }});
        }
        if (f.range) {
            plan.push({t: 'DHCP', fn: async () => {
                await tolerant('/api/dnsmasq/settings/del_range/' + f.range.uuid);
                await api('/api/dnsmasq/service/reconfigure', {});
            }});
        }
        if (f.assign && f.assign.descr === IFDESCR) {
            plan.push({t: 'Интерфейс', fn: async () => {
                const id = f.assign.identifier || f.assign.uuid;
                const r = await api('/api/interfaces/assignment/del_item/' + id, {});
                if (r && r.result && r.result !== 'deleted') { throw new Error(r.result); }
                okStatus(await api('/api/interfaces/assignment/reconfigure', {}), 'Интерфейс');
            }});
        }
        if (f.vlan) {
            plan.push({t: 'VLAN', fn: async () => {
                await api('/api/interfaces/vlan_settings/del_item/' + f.vlan.uuid, {});
                await api('/api/interfaces/vlan_settings/reconfigure', {});
            }});
        }
        const ok = await run(plan);
        const shown = $('#jkt-bar-st').html();
        await load().catch(() => null);
        $('#jkt-bar-st').html(shown + (ok ? '<div style="margin-top:6px"><b style="color:#22c55e"><i class="fa fa-check"></i> Гостевая сеть удалена.</b></div>' : ''));
        refreshGuests();
    }

    async function refreshGuests() {
        if (!found.zone) {
            $('#jkt-k-online, #jkt-k-down, #jkt-k-up').text('—');
            $('#jkt-guests').html('<div class="jkt-empty"><i class="fa fa-wifi"></i>Гости появятся здесь, когда сеть будет создана.</div>');
            return;
        }
        let list = [];
        try {
            const zid = String(found.zone.zoneid);
            list = (await rows('/api/captiveportal/session/search', {selected_zones: [zid]})).filter((s) => String(s.zoneid) === zid);
        } catch (e) {
            list = [];
        }
        const sum = (k) => list.reduce((s, x) => s + (Number(x[k]) || 0), 0);
        $('#jkt-k-online').text(list.length);
        // portal accounting: bytes_in are sent by the guest, bytes_out are received by it
        $('#jkt-k-down').text(fmtBytes(sum('bytes_out')));
        $('#jkt-k-up').text(fmtBytes(sum('bytes_in')));
        if (!list.length) {
            $('#jkt-guests').html('<div class="jkt-empty"><i class="fa fa-user-o"></i>Сейчас никто не подключён.</div>');
            return;
        }
        const since = (t) => {
            const d = new Date(Number(t) * 1000);
            return Number.isFinite(d.getTime()) ? d.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'}) : '';
        };
        $('#jkt-guests').html(list.slice(0, 30).map((s) => `<div class="jkt-guest">
            <div class="av"><i class="fa ${s.userName ? 'fa-user' : 'fa-mobile'}"></i></div>
            <div class="gm"><div class="gn">${esc(s.userName || s.ipAddress)}</div>
              <div class="gs">${esc(s.ipAddress)} · ${esc(s.macAddress || '')}</div></div>
            <div class="gr">с ${esc(since(s.startTime))}<br><span style="color:var(--a2)">▼</span> ${esc(fmtBytes(s.bytes_out))} ▲ ${esc(fmtBytes(s.bytes_in))}</div>
            <button class="gx" type="button" title="Отключить" data-session="${esc(s.sessionId)}"><i class="fa fa-times"></i></button>
          </div>`).join(''));
    }

    /* --- events --- */
    const edit = (fn) => function (e) {
        if (busy) { return; }
        fn.call(this, e);
        render();
    };
    const swKey = (fn) => function (e) {
        if (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter') { return; }
        e.preventDefault();
        fn.call(this, e);
    };
    $('#jkt-mode').on('click', '.jkt-opt', edit(function () { state.mode = $(this).data('mode'); }));
    $('#jkt-parents').on('click', '.jkt-chip', edit(function () { state.parent = String($(this).data('parent')); }));
    $('#jkt-ports').on('click', '.jkt-chip', edit(function () { state.port = String($(this).data('port')); }));
    $('#jkt-ifaces').on('click', '.jkt-chip', edit(function () { state.iface = String($(this).data('iface')); }));
    $('#jkt-tag').on('input', edit(function () {
        state.tag = Number($(this).val());
        if (!cidrTouched && state.tag >= 1 && state.tag <= 4094) { state.cidr = `192.168.${state.tag % 256}.1/24`; }
    }));
    $('#jkt-cidr').on('input', edit(function () { state.cidr = String($(this).val()).trim(); cidrTouched = true; }));
    $('#jkt-dhcp').on('click keydown', swKey(edit(function () { if (env.dnsmasq.enabled) { state.dhcp = !state.dhcp; } })));
    $('#jkt-isolate').on('click keydown', swKey(edit(function () { state.isolate = !state.isolate; })));
    $('#jkt-enabled').on('click keydown', swKey(edit(function () { state.enabled = !state.enabled; })));
    $('#jkt-auth').on('click', '.jkt-opt', edit(function () {
        state.auth = $(this).data('auth');
        if (state.auth === 'login' && !state.servers.length && env.servers.length) {
            const v = env.servers.find((s) => /voucher/i.test(s.label)) || env.servers[0];
            state.servers = [v.id];
        }
    }));
    $('#jkt-servers').on('click', '.jkt-chip', edit(function () {
        const id = String($(this).data('server'));
        state.servers = state.servers.includes(id) ? state.servers.filter((x) => x !== id) : [...state.servers, id];
    }));
    [['title', '#jkt-p-title'], ['button', '#jkt-p-button'], ['text', '#jkt-p-text'], ['terms', '#jkt-p-terms'], ['redirect', '#jkt-p-redirect']]
        .forEach(([k, sel]) => $(sel).on('input', edit(function () { state.portal[k] = String($(this).val()); })));
    $('#jkt-p-accept').on('click keydown', swKey(edit(function () { state.portal.accept = !state.portal.accept; })));
    $('#jkt-speeds').on('click', '.jkt-chip', edit(function () {
        const [d, u] = String($(this).data('speed')).split('/').map(Number);
        state.down = d;
        state.up = u;
    }));
    $('#jkt-down').on('input', edit(function () { state.down = Number($(this).val()) || 0; }));
    $('#jkt-up').on('input', edit(function () { state.up = Number($(this).val()) || 0; }));
    $('#jkt-hard').on('click', '.jkt-chip', edit(function () { state.hard = Number($(this).data('hard')); }));
    $('#jkt-idle').on('click', '.jkt-chip', edit(function () { state.idle = Number($(this).data('idle')); }));
    $('#jkt-reset').on('click', edit(function () { state = JSON.parse(JSON.stringify(saved)); }));
    $('#jkt-apply').on('click', () => { if (!busy) { apply(); } });
    $('#jkt-remove').on('click', () => { if (!busy) { $('#jkt-confirm').addClass('open'); } });
    $('#jkt-confirm').on('click', '[data-close]', () => $('#jkt-confirm').removeClass('open'));
    $('#jkt-remove-go').on('click', () => { $('#jkt-confirm').removeClass('open'); removeAll(); });
    $('#jkt-guests').on('click', '.gx', async function () {
        $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>');
        await api('/api/captiveportal/session/disconnect', {sessionId: String($(this).data('session'))}).catch(() => null);
        refreshGuests();
    });

    load().then(refreshGuests).catch((e) => {
        $('#jkt-bar-st').html('<b style="color:#ff3b47">Не удалось загрузить настройки:</b> ' + esc(e.message));
    });
    setInterval(() => { if (!busy) { refreshGuests(); } }, 20000);
});
</script>
