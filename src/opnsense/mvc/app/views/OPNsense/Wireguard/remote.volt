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
 # jk-ufw: WireGuard remote access in one page. One click creates a WireGuard instance,
 # opens its port on WAN, lets clients through and adds outbound NAT; every device then
 # gets its own keys and a QR code for the WireGuard app. Everything goes through the
 # stock /api/wireguard/* and /api/firewall/* endpoints; the instance and peers are
 # ordinary ones and stay editable on VPN > WireGuard.
 #}

<style>
.jkw { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --s:#131316; --s2:#18181c; --h:#1e1e23; --b:#232329; --b2:#2e2e35;
  --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524; color:var(--t); font-size:13px; max-width:1180px; }
.jkw * { box-sizing:border-box; }
.jkw b, .jkw strong { font-family:inherit; font-weight:700; }
.jkw-head { display:flex; align-items:center; gap:16px; padding:6px 0 18px; flex-wrap:wrap; }
.jkw-logo { width:52px; height:52px; border-radius:14px; display:grid; place-items:center; font-size:24px;
  background:var(--s2); border:1px solid var(--b); color:var(--m); transition:all .2s; }
.jkw-logo.on { color:#fff; background:linear-gradient(145deg,var(--a2),#a5121c); border-color:transparent; box-shadow:0 6px 24px rgba(229,32,46,.35); }
.jkw-title { font-size:22px; font-weight:700; letter-spacing:-.02em; margin:0; }
.jkw-sub { color:var(--m); margin-top:2px; }
.jkw-pill { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:600; padding:3px 10px; border-radius:999px;
  background:var(--s2); border:1px solid var(--b); margin-left:8px; vertical-align:middle; }
.jkw-pill i { width:7px; height:7px; border-radius:50%; background:var(--m); }
.jkw-pill.ok i { background:var(--ok); box-shadow:0 0 0 3px rgba(34,197,94,.18); }
.jkw-pill.bad i { background:var(--a); }
.jkw-head-r { margin-left:auto; display:flex; gap:8px; flex-wrap:wrap; }
.jkw-grid { display:grid; grid-template-columns:minmax(0,1.45fr) minmax(0,1fr); gap:16px; align-items:start; }
@media (max-width: 1000px) { .jkw-grid { grid-template-columns:minmax(0,1fr); } }
.jkw-grid > div { min-width:0; }
.jkw-card { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:18px; margin-bottom:16px; }
.jkw-card h3 { font-size:13px; font-weight:700; text-transform:uppercase; letter-spacing:.07em; color:var(--m); margin:0 0 14px;
  display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.jkw-card h3 .r { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:500; }
.jkw-hero { display:flex; gap:18px; align-items:center; padding:22px; background:linear-gradient(120deg,rgba(229,32,46,.14),rgba(229,32,46,0) 60%), var(--s); }
.jkw-hero .big { font-size:17px; font-weight:700; }
.jkw-hero .ds { color:var(--m); margin-top:4px; line-height:1.5; }
.jkw-field { margin-bottom:14px; }
.jkw-field label { display:block; font-weight:600; margin-bottom:6px; }
.jkw-field .hint { color:var(--m); font-size:12px; margin-top:5px; line-height:1.45; }
.jkw-row2 { display:grid; grid-template-columns:minmax(0,2fr) minmax(0,1fr); gap:12px; }
.jkw-row2.eq { grid-template-columns:minmax(0,1fr) minmax(0,1fr); }
@media (max-width: 640px) { .jkw-row2, .jkw-row2.eq, .jkw-seg { grid-template-columns:minmax(0,1fr) !important; } }
.jkw input.jkw-in { background:var(--s2) !important; border:1px solid var(--b) !important; color:var(--t) !important; border-radius:8px !important;
  padding:9px 11px !important; width:100% !important; max-width:none !important; height:auto !important; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12.5px; }
.jkw input.jkw-in:focus { border-color:var(--a) !important; outline:none; box-shadow:0 0 0 3px var(--abg); }
.jkw input.jkw-in.bad { border-color:var(--a) !important; }
.jkw-seg { display:grid; grid-template-columns:repeat(2,1fr); gap:10px; }
.jkw-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:13px; cursor:pointer; transition:all .15s; position:relative; }
.jkw-opt:hover { border-color:var(--b2); background:var(--h); }
.jkw-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jkw-opt .nm { font-weight:700; font-size:13.5px; }
.jkw-opt .nm .fa { color:var(--m); margin-right:6px; }
.jkw-opt.sel .nm .fa { color:var(--a2); }
.jkw-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jkw-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:12px; display:flex; gap:10px; }
.jkw-note .fa { margin-top:2px; }
.jkw-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jkw-note.warn .fa { color:var(--warn); }
.jkw-note.info { background:var(--s2); border:1px solid var(--b); color:var(--m); }
.jkw-note.err { background:var(--abg); border:1px solid rgba(229,32,46,.4); color:#ffb3b8; }
.jkw-btn { border:0; border-radius:9px; padding:10px 18px; font-weight:700; font-size:13px; cursor:pointer; background:var(--a); color:#fff !important;
  display:inline-flex; align-items:center; gap:7px; text-decoration:none !important; white-space:nowrap; }
.jkw-btn:hover { background:var(--a2); }
.jkw-btn[disabled] { opacity:.5; cursor:default; }
.jkw-btn.ghost { background:var(--s2); border:1px solid var(--b); color:var(--t) !important; font-weight:600; }
.jkw-btn.ghost:hover { background:var(--h); }
.jkw-btn.sm { padding:6px 11px; font-size:12px; border-radius:8px; }
.jkw-btn.icon { padding:7px 9px; }
.jkw-btn.danger:hover { color:var(--a2) !important; border-color:rgba(229,32,46,.5); }
.jkw-steps { margin:14px 0 0; padding:0; list-style:none; }
.jkw-steps li { padding:4px 0; color:var(--m); }
.jkw-steps li.done { color:var(--t); }
.jkw-steps li.done .fa { color:var(--ok); }
.jkw-steps li.run .fa { color:var(--a2); }
.jkw-steps li.err { color:var(--a2); }
.jkw-how { margin:0; padding:0; list-style:none; counter-reset:s; }
.jkw-how li { position:relative; padding:0 0 16px 40px; line-height:1.5; color:var(--m); }
.jkw-how li b { color:var(--t); display:block; }
.jkw-how li::before { counter-increment:s; content:counter(s); position:absolute; left:0; top:0; width:26px; height:26px; border-radius:8px;
  display:grid; place-items:center; font-weight:700; background:var(--abg); color:var(--a2); }
.jkw-kpis { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin-bottom:16px; }
@media (max-width: 640px) { .jkw-kpis { grid-template-columns:repeat(2,minmax(0,1fr)); } }
.jkw-kpi { background:var(--s); border:1px solid var(--b); border-radius:12px; padding:14px; }
.jkw-kpi .l { overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--m); font-size:11px; font-weight:600; text-transform:uppercase; letter-spacing:.06em; }
.jkw-kpi .v { font-size:24px; font-weight:700; letter-spacing:-.02em; margin-top:4px; }
.jkw-kpi .v.ok { color:var(--ok); }
.jkw-dev { display:flex; align-items:center; gap:12px; padding:12px 0; border-top:1px solid var(--b); }
.jkw-dev:first-child { border-top:0; padding-top:0; }
.jkw-dev .di { width:38px; height:38px; flex:none; border-radius:10px; display:grid; place-items:center; background:#202026; color:var(--m); font-size:17px; position:relative; }
.jkw-dev .di .dot { position:absolute; right:-2px; bottom:-2px; width:11px; height:11px; border-radius:50%; background:#3a3a42; border:2px solid var(--s); }
.jkw-dev.online .di { background:var(--abg); color:var(--a2); }
.jkw-dev.online .di .dot { background:var(--ok); }
.jkw-dev.off { opacity:.55; }
.jkw-dev .dm { flex:1; min-width:0; }
.jkw-dev .dn { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkw-dev .ds { color:var(--m); font-size:11.5px; margin-top:2px; }
.jkw-dev .ds .mono { font-family:ui-monospace,Menlo,Consolas,monospace; }
.jkw-dev .da { display:flex; gap:6px; flex:none; }
.jkw-kv { display:flex; gap:12px; padding:9px 0; border-top:1px solid var(--b); align-items:baseline; }
.jkw-kv:first-of-type { border-top:0; padding-top:0; }
.jkw-kv .k { color:var(--m); flex:none; width:118px; }
.jkw-kv .v { flex:1; min-width:0; overflow-wrap:anywhere; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:12px; }
.jkw-sw { display:inline-block; vertical-align:middle; flex:none; width:34px; height:20px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; cursor:pointer; }
.jkw-sw::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jkw-sw.on { background:var(--a); }
.jkw-sw.on::after { left:16px; background:#fff; }
.jkw-empty { color:var(--m); text-align:center; padding:26px 6px; }
.jkw-empty .fa { display:block; font-size:26px; margin-bottom:10px; color:#3a3a42; }
.jkw .muted { color:var(--m); }
.jkw a.lnk { color:var(--a2); }
/* modal */
.jkw-ov { max-width:none; font-size:13px; position:fixed; inset:0; z-index:1050; background:rgba(0,0,0,.72); backdrop-filter:blur(3px); display:none; align-items:center; justify-content:center; padding:16px; }
.jkw-ov.open { display:flex; }
.jkw-modal { width:100%; max-width:520px; max-height:calc(100vh - 32px); overflow:auto; background:var(--s); border:1px solid var(--b2); border-radius:14px;
  padding:22px; box-shadow:0 20px 60px rgba(0,0,0,.6); color:var(--t); }
.jkw-modal h4 { margin:0 0 4px; font-size:17px; font-weight:700; }
.jkw-modal .sub { color:var(--m); margin-bottom:16px; line-height:1.5; }
.jkw-modal .ft { display:flex; gap:8px; justify-content:flex-end; margin-top:18px; flex-wrap:wrap; }
.jkw-types { display:grid; grid-template-columns:repeat(4,1fr); gap:8px; }
.jkw-type { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:10px 4px; text-align:center; cursor:pointer; font-size:12px; font-weight:600; }
.jkw-type .fa { display:block; font-size:19px; margin-bottom:6px; color:var(--m); }
.jkw-type.sel { border-color:var(--a); background:var(--abg); }
.jkw-type.sel .fa { color:var(--a2); }
.jkw-qr { background:#fff; border-radius:12px; padding:14px; width:fit-content; max-width:100%; margin:0 auto; }
.jkw-qr svg, .jkw-qr img { display:block; width:280px; max-width:100%; height:auto; }
.jkw-conf { margin-top:14px; }
.jkw-conf summary { cursor:pointer; color:var(--m); font-weight:600; }
.jkw-conf pre { margin-top:8px; background:var(--s2); border:1px solid var(--b); color:var(--t); border-radius:8px; padding:10px; font-size:11.5px; white-space:pre-wrap; word-break:break-all; }
</style>

<div class="jkw" id="jkw">
  <div class="jkw-head">
    <div class="jkw-logo" id="jkw-logo"><i class="fa fa-lock"></i></div>
    <div>
      <h1 class="jkw-title">Удалённый доступ <span class="jkw-pill" id="jkw-status"><i></i><span>…</span></span></h1>
      <div class="jkw-sub">VPN WireGuard: телефон и ноутбук подключаются к домашней сети из любого места</div>
    </div>
    <div class="jkw-head-r">
      <a class="jkw-btn ghost" href="/ui/wireguard/diagnostics/"><i class="fa fa-heartbeat"></i> Статус</a>
      <a class="jkw-btn ghost" href="/ui/wireguard/general"><i class="fa fa-sliders"></i> Расширенные</a>
    </div>
  </div>

  <div id="jkw-loading" class="jkw-card"><div class="jkw-empty"><i class="fa fa-spinner fa-pulse"></i>Загрузка…</div></div>

  <!-- first run: nothing configured yet -->
  <div id="jkw-setup" style="display:none">
    <div class="jkw-grid">
      <div>
        <div class="jkw-card jkw-hero">
          <div class="jkw-logo on" style="flex:none"><i class="fa fa-mobile"></i></div>
          <div><div class="big">VPN в один клик</div>
            <div class="ds">Проверьте адрес и нажмите «Включить VPN». Сервер, ключи, правила межсетевого экрана и выход в интернет
              настроятся сами. Потом добавьте устройство и отсканируйте QR-код.</div></div>
        </div>
        <div class="jkw-card">
          <h3><i class="fa fa-globe"></i> Подключение</h3>
          <div class="jkw-row2">
            <div class="jkw-field"><label for="jkw-host">Адрес для подключения</label>
              <input class="jkw-in" id="jkw-host" type="text" spellcheck="false" placeholder="vpn.example.com или внешний IP"/>
              <div class="hint">Внешний IP или имя DDNS, по которому устройства найдут этот экран из интернета.</div></div>
            <div class="jkw-field"><label for="jkw-port">Порт UDP</label>
              <input class="jkw-in" id="jkw-port" type="text" inputmode="numeric" value="51820"/></div>
          </div>
          <div class="jkw-note warn" id="jkw-nat-note" style="display:none; margin-top:0">
            <i class="fa fa-exclamation-triangle"></i>
            <div>Адрес <b id="jkw-nat-ip"></b> внутренний: экран стоит за другим роутером. На том роутере пробросьте <b>UDP <span class="jkw-pport">51820</span></b>
              на этот экран, а сюда впишите внешний IP роутера или имя DDNS.</div>
          </div>
        </div>
        <div class="jkw-card">
          <h3><i class="fa fa-random"></i> Какой трафик пускать через VPN</h3>
          <div class="jkw-seg" id="jkw-route">
            <div class="jkw-opt sel" data-route="full"><div class="nm"><i class="fa fa-shield"></i>Весь трафик</div>
              <div class="ds">Интернет идёт через дом. Защищает в публичном Wi-Fi, работает фильтрация и блокировка рекламы.</div></div>
            <div class="jkw-opt" data-route="split"><div class="nm"><i class="fa fa-home"></i>Только домашняя сеть</div>
              <div class="ds">Через VPN идут только адреса дома: <span id="jkw-lan-list" class="muted">…</span>. Остальное напрямую.</div></div>
          </div>
        </div>
        <div class="jkw-card">
          <h3><i class="fa fa-cog"></i> Дополнительно</h3>
          <div class="jkw-row2 eq">
            <div class="jkw-field"><label for="jkw-net">Сеть VPN</label>
              <input class="jkw-in" id="jkw-net" type="text" spellcheck="false" value="10.66.0.0/24"/>
              <div class="hint">Из неё устройства получают адреса. Не должна совпадать с домашней сетью.</div></div>
            <div class="jkw-field"><label for="jkw-dns">DNS для устройств</label>
              <input class="jkw-in" id="jkw-dns" type="text" spellcheck="false" value="10.66.0.1"/>
              <div class="hint">По умолчанию DNS этого экрана (Unbound). Можно указать, например, 1.1.1.1.</div></div>
          </div>
          <div class="jkw-note err" id="jkw-setup-err" style="display:none"></div>
          <div style="display:flex; align-items:center; gap:14px; flex-wrap:wrap">
            <button class="jkw-btn" id="jkw-enable" type="button"><i class="fa fa-power-off"></i> Включить VPN</button>
            <span class="muted">Ничего из существующих настроек не удаляется.</span>
          </div>
          <ul class="jkw-steps" id="jkw-steps"></ul>
        </div>
      </div>
      <div>
        <div class="jkw-card">
          <h3><i class="fa fa-question-circle"></i> Как это работает</h3>
          <ol class="jkw-how">
            <li><b>Включите VPN</b>Создаётся сервер WireGuard, на WAN открывается порт, клиентам разрешается доступ в сеть и в интернет.</li>
            <li><b>Добавьте устройство</b>Для каждого телефона или ноутбука создаются свои ключи. Потерянное устройство отключается одной кнопкой.</li>
            <li><b>Отсканируйте QR-код</b>В приложении WireGuard: «+» › «Сканировать QR-код». На компьютере импортируйте файл .conf.</li>
          </ol>
          <div class="jkw-note info" style="margin-top:0"><i class="fa fa-download"></i>
            <div>Приложение WireGuard бесплатное: App Store, Google Play, Windows, macOS и Linux. Ссылки на
              <a class="lnk" href="https://www.wireguard.com/install/" target="_blank" rel="noopener">wireguard.com/install</a>.</div></div>
        </div>
      </div>
    </div>
  </div>

  <!-- VPN configured -->
  <div id="jkw-main" style="display:none">
    <div class="jkw-kpis">
      <div class="jkw-kpi"><div class="l">Устройств</div><div class="v" id="jkw-k-dev">0</div></div>
      <div class="jkw-kpi"><div class="l">Сейчас в сети</div><div class="v ok" id="jkw-k-on">0</div></div>
      <div class="jkw-kpi"><div class="l">Скачано устройствами</div><div class="v" id="jkw-k-rx">0</div></div>
      <div class="jkw-kpi"><div class="l">Отправлено устройствами</div><div class="v" id="jkw-k-tx">0</div></div>
    </div>
    <div class="jkw-grid">
      <div>
        <div class="jkw-card">
          <h3><i class="fa fa-mobile"></i> Устройства <span class="r"><button class="jkw-btn sm" id="jkw-add" type="button"><i class="fa fa-plus"></i> Добавить устройство</button></span></h3>
          <div id="jkw-devs"></div>
        </div>
      </div>
      <div>
        <div class="jkw-card">
          <h3><i class="fa fa-server"></i> Сервер <span class="r"><span class="jkw-sw" id="jkw-srv-sw" role="switch" tabindex="0" title="Включить или выключить VPN"></span></span></h3>
          <div id="jkw-srv"></div>
          <div class="jkw-note err" id="jkw-main-err" style="display:none"></div>
        </div>
        <div class="jkw-card">
          <h3><i class="fa fa-pencil"></i> Для новых QR-кодов</h3>
          <div class="jkw-field"><label for="jkw-e-host">Адрес для подключения</label>
            <input class="jkw-in" id="jkw-e-host" type="text" spellcheck="false"/></div>
          <div class="jkw-field"><label for="jkw-e-dns">DNS</label>
            <input class="jkw-in" id="jkw-e-dns" type="text" spellcheck="false"/></div>
          <div class="jkw-field"><label for="jkw-e-ips">Через VPN</label>
            <input class="jkw-in" id="jkw-e-ips" type="text" spellcheck="false"/>
            <div class="hint">0.0.0.0/0, ::/0 значит весь трафик. Уже выданные QR-коды не меняются: после правки покажите код устройству заново.</div></div>
          <button class="jkw-btn ghost sm" id="jkw-e-save" type="button" disabled><i class="fa fa-check"></i> Сохранить</button>
          <span class="muted" id="jkw-e-st" style="margin-left:8px"></span>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="jkw jkw-ov" id="jkw-ov" role="dialog" aria-modal="true">
  <div class="jkw-modal">
    <div id="jkw-m-add">
      <h4>Новое устройство</h4>
      <div class="sub">Ключи создадутся на экране. QR-код появится сразу после добавления.</div>
      <div class="jkw-field"><label>Тип</label>
        <div class="jkw-types" id="jkw-types">
          <div class="jkw-type sel" data-type="phone" data-icon="fa-mobile"><i class="fa fa-mobile"></i>Телефон</div>
          <div class="jkw-type" data-type="tablet" data-icon="fa-tablet"><i class="fa fa-tablet"></i>Планшет</div>
          <div class="jkw-type" data-type="laptop" data-icon="fa-laptop"><i class="fa fa-laptop"></i>Ноутбук</div>
          <div class="jkw-type" data-type="pc" data-icon="fa-desktop"><i class="fa fa-desktop"></i>Компьютер</div>
        </div></div>
      <div class="jkw-field"><label for="jkw-d-name">Название</label>
        <input class="jkw-in" id="jkw-d-name" type="text" spellcheck="false" maxlength="48" placeholder="phone-ivan"/>
        <div class="hint">Латиница, цифры, точка, дефис и подчёркивание.</div></div>
      <label style="display:flex; gap:8px; align-items:flex-start; font-weight:400; cursor:pointer">
        <input type="checkbox" id="jkw-d-keep" checked style="margin-top:2px"/>
        <span>Хранить ключ устройства на экране, чтобы QR-код можно было показать ещё раз.
          <span class="muted">Без этого код показывается только сейчас.</span></span></label>
      <div class="jkw-note err" id="jkw-d-err" style="display:none"></div>
      <div class="ft">
        <button class="jkw-btn ghost" type="button" data-close>Отмена</button>
        <button class="jkw-btn" id="jkw-d-create" type="button"><i class="fa fa-qrcode"></i> Создать</button>
      </div>
    </div>
    <div id="jkw-m-qr" style="display:none">
      <h4 id="jkw-q-title"></h4>
      <div class="sub">Откройте WireGuard на устройстве: «+» › «Сканировать QR-код». На компьютере скачайте файл и импортируйте его.</div>
      <div class="jkw-qr" id="jkw-q-img"></div>
      <div class="jkw-note warn" id="jkw-q-warn" style="display:none"><i class="fa fa-key"></i>
        <div>Ключ этого устройства не хранится на экране, код больше не покажется. Отсканируйте его сейчас или скачайте файл.</div></div>
      <details class="jkw-conf"><summary>Показать настройки текстом</summary><pre id="jkw-q-text"></pre></details>
      <div class="ft">
        <button class="jkw-btn ghost" id="jkw-q-dl" type="button"><i class="fa fa-download"></i> Скачать .conf</button>
        <button class="jkw-btn" type="button" data-close>Готово</button>
      </div>
    </div>
  </div>
</div>

<script>
'use strict';
$(function () {
    const SERVER_NAME = 'jkufw_vpn';
    const RULE_TAG = 'jk-ufw VPN';
    const TYPE_ICON = {phone: 'fa-mobile', tablet: 'fa-tablet', laptop: 'fa-laptop', pc: 'fa-desktop'};

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
    });
    const grid = (url, extra) => api(url, Object.assign({current: 1, rowCount: -1, searchPhrase: ''}, extra || {}));
    // MVC answers {result: 'saved'} or {result: 'failed', validations: {...}}
    const saved = (r, what) => {
        if (!r || r.result !== 'saved') {
            const msg = Object.values((r && r.validations) || {}).join(' ');
            throw new Error((what ? what + ': ' : '') + (msg || 'не сохранено'));
        }
        return r;
    };
    const bytes = (n) => {
        n = Number(n || 0);
        const u = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'];
        let i = 0;
        while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
        return (i ? n.toFixed(n < 10 ? 1 : 0) : n) + ' ' + u[i];
    };
    const ago = (s) => {
        if (s == null) { return 'ещё не подключалось'; }
        if (s < 60) { return 'только что'; }
        if (s < 3600) { return Math.floor(s / 60) + ' мин назад'; }
        if (s < 86400) { return Math.floor(s / 3600) + ' ч назад'; }
        return Math.floor(s / 86400) + ' дн назад';
    };

    // --- IPv4 helpers ---------------------------------------------------------------------------
    const ip2n = (ip) => {
        const p = String(ip).split('.');
        if (p.length !== 4 || p.some((x) => !/^\d{1,3}$/.test(x) || +x > 255)) { return null; }
        return ((+p[0] << 24) >>> 0) + (+p[1] << 16) + (+p[2] << 8) + (+p[3]);
    };
    const n2ip = (n) => [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].join('.');
    const parseCidr = (c) => {
        const m = String(c || '').trim().match(/^([\d.]+)\/(\d{1,2})$/);
        if (!m || +m[2] > 32) { return null; }
        const ip = ip2n(m[1]);
        if (ip === null) { return null; }
        const bits = +m[2];
        const mask = bits ? (0xffffffff << (32 - bits)) >>> 0 : 0;
        return {ip: ip, bits: bits, net: (ip & mask) >>> 0, mask: mask};
    };
    const overlaps = (a, b) => {
        const mask = a.bits < b.bits ? a.mask : b.mask;
        return ((a.net & mask) >>> 0) === ((b.net & mask) >>> 0);
    };
    const isPrivate = (ip) => {
        const n = ip2n(ip);
        if (n === null) { return false; }
        return [['10.0.0.0', 8], ['172.16.0.0', 12], ['192.168.0.0', 16], ['100.64.0.0', 10], ['169.254.0.0', 16]]
            .some(([b, bits]) => overlaps(parseCidr(b + '/' + bits), {net: n, bits: 32, mask: 0xffffffff}));
    };
    const hostPort = (ep) => {
        const m = String(ep || '').match(/^\[?(.*?)\]?(?::(\d+))?$/);
        return {host: m ? m[1] : '', port: m && m[2] ? m[2] : ''};
    };

    // --- state ----------------------------------------------------------------------------------
    let server = null;   // our WireGuard instance (search row) or null
    let info = null;     // get_server_info of that instance: endpoint, peer_dns, allowed_ips, pubkey, mtu, address
    let wgEnabled = false;
    let devices = [];
    let live = {};       // pubkey -> wg show record
    let ifaceNets = [];  // [{name, cidr}] of non-WAN interfaces
    let wanIp = '';
    let busy = false;
    let lastConf = null;

    async function loadIfaces() {
        try {
            const r = await grid('/api/interfaces/overview/interfaces_info');
            ifaceNets = [];
            (r.rows || []).forEach((row) => {
                const c = parseCidr(row.addr4);
                if (!c || !row.identifier) { return; }
                if (row.identifier === 'wan') {
                    wanIp = n2ip(c.ip);
                } else if (!/^(lo|wg|ovpn|ipsec)/.test(row.device || '')) {
                    ifaceNets.push({name: row.description || row.identifier, cidr: n2ip(c.net) + '/' + c.bits});
                }
            });
        } catch (e) {
            ifaceNets = [];
        }
    }

    async function load() {
        const [general, servers] = await Promise.all([api('/api/wireguard/general/get'), grid('/api/wireguard/server/search_server')]);
        wgEnabled = String(((general || {}).general || {}).enabled) === '1';
        server = (servers.rows || []).find((r) => r.name === SERVER_NAME) || null;
        info = null;
        devices = [];
        if (server) {
            const [si, cl] = await Promise.all([
                api('/api/wireguard/client/get_server_info/' + server.uuid),
                grid('/api/wireguard/client/search_client', {servers: [server.uuid]})
            ]);
            info = si && si.status === 'ok' ? si : null;
            devices = cl.rows || [];
        }
        await loadLive();
        render();
    }

    async function loadLive() {
        live = {};
        try {
            const r = await grid('/api/wireguard/service/show');
            (r.rows || []).forEach((x) => {
                if (x.type === 'peer' && x['public-key']) {
                    live[x['public-key']] = x;
                } else if (x.type === 'interface' && server && x.ifname === server.name) {
                    live.__if = x;
                }
            });
        } catch (e) {
            live = {};
        }
    }

    function render() {
        $('#jkw-loading').hide();
        const on = !!server && wgEnabled && String(server.enabled) === '1';
        const pill = $('#jkw-status').removeClass('ok bad');
        $('#jkw-logo').toggleClass('on', on && !!live.__if);
        if (!server) {
            pill.find('span').text('Не настроен');
        } else if (on && live.__if) {
            pill.addClass('ok').find('span').text('Работает');
        } else if (on) {
            pill.addClass('bad').find('span').text('Не запущен');
        } else {
            pill.find('span').text('Выключен');
        }
        $('#jkw-setup').toggle(!server);
        $('#jkw-main').toggle(!!server);
        if (!server) {
            renderSetup();
            return;
        }
        renderMain(on);
    }

    // --- setup ----------------------------------------------------------------------------------
    let route = 'full';

    function renderSetup() {
        if (!$('#jkw-host').val()) {
            $('#jkw-host').val(wanIp);
        }
        $('#jkw-lan-list').text(ifaceNets.map((x) => x.cidr).join(', ') || 'сети интерфейсов');
        $('#jkw-route .jkw-opt').each(function () { $(this).toggleClass('sel', $(this).data('route') === route); });
        checkSetup();
    }

    function checkSetup() {
        const host = String($('#jkw-host').val()).trim();
        const port = String($('#jkw-port').val()).trim();
        const net = parseCidr($('#jkw-net').val());
        $('.jkw-pport').text(port || '51820');
        $('#jkw-nat-ip').text(host);
        $('#jkw-nat-note').toggle(isPrivate(host));
        const errors = [];
        if (!host) {
            errors.push('Укажите адрес для подключения.');
        }
        if (!/^\d+$/.test(port) || +port < 1 || +port > 65535) {
            errors.push('Порт должен быть числом от 1 до 65535.');
        }
        if (!net || net.bits > 30 || net.bits < 16) {
            errors.push('Сеть VPN укажите как 10.66.0.0/24 (маска от /16 до /30).');
        } else {
            const clash = ifaceNets.find((x) => overlaps(net, parseCidr(x.cidr)));
            if (clash) {
                errors.push(`Сеть VPN пересекается с сетью ${clash.name} (${clash.cidr}). Выберите другую, например 10.66.0.0/24.`);
            }
        }
        $('#jkw-host').toggleClass('bad', !host);
        $('#jkw-net').toggleClass('bad', !net);
        return errors;
    }

    function steps(list) {
        $('#jkw-steps').html(list.map((s) =>
            `<li class="${s.st}"><i class="fa fa-fw ${s.st === 'done' ? 'fa-check' : (s.st === 'run' ? 'fa-spinner fa-pulse' : (s.st === 'err' ? 'fa-times' : 'fa-circle-o'))}"></i> ${esc(s.t)}</li>`
        ).join(''));
    }

    async function ruleExists(url, descr) {
        const r = await grid(url, {searchPhrase: descr});
        return (r.rows || []).some((x) => x.description === descr);
    }

    async function setup() {
        const errors = checkSetup();
        if (errors.length) {
            $('#jkw-setup-err').html('<i class="fa fa-exclamation-circle"></i><div>' + errors.map(esc).join('<br/>') + '</div>').show();
            return;
        }
        $('#jkw-setup-err').hide();
        busy = true;
        $('#jkw-enable').prop('disabled', true);
        const host = String($('#jkw-host').val()).trim();
        const port = String($('#jkw-port').val()).trim();
        const net = parseCidr($('#jkw-net').val());
        const srvAddr = n2ip(net.net + 1) + '/' + net.bits;
        const netCidr = n2ip(net.net) + '/' + net.bits;
        const allowed = route === 'full' ? '0.0.0.0/0,::/0' : [...ifaceNets.map((x) => x.cidr), netCidr].join(',');
        const dns = String($('#jkw-dns').val()).trim();
        const endpoint = (host.includes(':') && !host.startsWith('[') ? '[' + host + ']' : host) + ':' + port;

        const plan = [
            {t: 'Ключи сервера', st: ''},
            {t: 'Сервер WireGuard ' + srvAddr, st: ''},
            {t: 'Запуск службы', st: ''},
            {t: 'Правила: порт UDP ' + port + ' на WAN и доступ для клиентов', st: ''},
            {t: 'Выход в интернет (исходящий NAT)', st: ''},
            {t: 'Применение правил', st: ''}
        ];
        let cur = 0;
        const step = async (i, fn) => {
            cur = i;
            plan[i].st = 'run';
            steps(plan);
            const note = await fn();
            if (note) {
                plan[i].t += ' · ' + note;
            }
            plan[i].st = 'done';
            steps(plan);
        };
        let keys = null;
        let uuid = null;
        try {
            await step(0, async () => {
                keys = await api('/api/wireguard/server/key_pair');
                if (!keys || !keys.pubkey || !keys.privkey) {
                    throw new Error('не удалось создать ключи');
                }
            });
            await step(1, async () => {
                const r = saved(await api('/api/wireguard/server/add_server', {server: {
                    enabled: '1', name: SERVER_NAME, pubkey: keys.pubkey, privkey: keys.privkey, port: port,
                    tunneladdress: srvAddr, dns: '', mtu: '', disableroutes: '0', gateway: '', peers: '', debug: '0',
                    endpoint: endpoint, peer_dns: dns, allowed_ips: allowed
                }}));
                uuid = r.uuid;
            });
            await step(2, async () => {
                if (!wgEnabled) {
                    saved(await api('/api/wireguard/general/set', {general: {enabled: '1'}}), 'WireGuard');
                }
                await api('/api/wireguard/service/reconfigure', {});
            });
            await step(3, async () => {
                const rules = [
                    {descr: RULE_TAG + ': вход WireGuard', rule: {interface: 'wan', ipprotocol: 'inet', protocol: 'UDP',
                        source_net: 'any', destination_net: 'wanip', destination_port: port}},
                    {descr: RULE_TAG + ': трафик клиентов', rule: {interface: 'wireguard', ipprotocol: 'inet46', protocol: 'any',
                        source_net: 'any', destination_net: 'any', destination_port: ''}}
                ];
                for (const x of rules) {
                    if (await ruleExists('/api/firewall/filter/search_rule', x.descr)) {
                        continue;
                    }
                    saved(await api('/api/firewall/filter/add_rule', {rule: Object.assign({
                        enabled: '1', action: 'pass', quick: '1', direction: 'in', source_port: '', description: x.descr
                    }, x.rule)}), 'правило');
                }
            });
            await step(4, async () => {
                const g = await api('/api/firewall/source_nat/get');
                const modes = (((g || {}).filter || {}).general || {}).snat_mode || {};
                const mode = typeof modes === 'string' ? modes : (Object.keys(modes).find((k) => String(modes[k].selected) === '1') || 'automatic');
                if (mode === 'disabled') {
                    return 'NAT выключен в настройках, пропущено';
                }
                let note = '';
                if (mode === 'automatic') {
                    // hybrid = the automatic rules plus ours, nothing existing changes
                    saved(await api('/api/firewall/source_nat/set', {filter: {general: {snat_mode: 'hybrid'}}}), 'режим NAT');
                    note = 'режим NAT: гибридный';
                }
                const descr = RULE_TAG + ': выход в интернет';
                if (!(await ruleExists('/api/firewall/source_nat/search_rule', descr))) {
                    saved(await api('/api/firewall/source_nat/add_rule', {rule: {
                        enabled: '1', nonat: '0', interface: 'wan', ipprotocol: 'inet', protocol: 'any',
                        source_net: netCidr, source_port: '', destination_net: 'any', destination_port: '',
                        target: '', target_port: '', description: descr
                    }}), 'NAT');
                }
                return note;
            });
            await step(5, async () => {
                await api('/api/firewall/filter/apply', {});
                await api('/api/firewall/source_nat/apply', {});
            });
            busy = false;
            await load();
            openAdd();
        } catch (e) {
            plan[cur].st = 'err';
            plan[cur].t += ': ' + e.message;
            steps(plan);
            busy = false;
            $('#jkw-enable').prop('disabled', false);
            if (uuid) {
                // the instance exists now; reload so the page switches over and the rest can be retried from there
                setTimeout(() => load().catch(() => null), 2500);
            }
        }
    }

    // --- main -----------------------------------------------------------------------------------
    const devType = (d) => {
        const m = String(d.name || '').match(/^(phone|tablet|laptop|pc)[-_.]/);
        return m ? m[1] : (/(iphone|android|pixel|galaxy|phone|tel)/i.test(d.name) ? 'phone' : 'laptop');
    };

    function renderMain(on) {
        let online = 0;
        let rx = 0;
        let tx = 0;
        const rows = devices.map((d) => {
            const l = live[d.pubkey] || {};
            const isOn = l['peer-status'] === 'online';
            if (isOn) { online++; }
            rx += Number(l['transfer-rx'] || 0);
            tx += Number(l['transfer-tx'] || 0);
            const enabled = String(d.enabled) === '1';
            const addr = String(d.tunneladdress || '').split(',')[0].replace(/\/32$/, '');
            const status = !enabled ? 'выключено' : (isOn ? 'в сети' : ago(l['latest-handshake-age']));
            const traffic = l['transfer-rx'] || l['transfer-tx'] ? ` · ↓ ${bytes(l['transfer-tx'])} ↑ ${bytes(l['transfer-rx'])}` : '';
            return `<div class="jkw-dev ${isOn ? 'online' : ''} ${enabled ? '' : 'off'}" data-uuid="${esc(d.uuid)}">
                <div class="di"><i class="fa ${TYPE_ICON[devType(d)]}"></i><span class="dot"></span></div>
                <div class="dm"><div class="dn">${esc(d.name)}</div>
                  <div class="ds"><span class="mono">${esc(addr)}</span> · ${esc(status)}${esc(traffic)}</div></div>
                <div class="da">
                  <button class="jkw-btn ghost sm icon" data-act="qr" type="button" title="QR-код и файл"><i class="fa fa-qrcode"></i></button>
                  <button class="jkw-btn ghost sm icon" data-act="toggle" type="button" title="${enabled ? 'Отключить' : 'Включить'}"><i class="fa ${enabled ? 'fa-pause' : 'fa-play'}"></i></button>
                  <button class="jkw-btn ghost sm icon danger" data-act="del" type="button" title="Удалить"><i class="fa fa-trash"></i></button>
                </div></div>`;
        });
        $('#jkw-devs').html(rows.join('') || `<div class="jkw-empty"><i class="fa fa-mobile"></i>Устройств пока нет.<br/>Нажмите «Добавить устройство», чтобы получить QR-код.</div>`);
        $('#jkw-k-dev').text(devices.length);
        $('#jkw-k-on').text(online);
        // wg counts on the server side: what the server sent was downloaded by the devices
        $('#jkw-k-rx').text(bytes(tx));
        $('#jkw-k-tx').text(bytes(rx));

        const i = info || {};
        const ep = hostPort(i.endpoint);
        const full = /(^|,)\s*0\.0\.0\.0\/0/.test(i.allowed_ips || '');
        $('#jkw-srv-sw').toggleClass('on', on);
        $('#jkw-srv').html([
            ['Адрес', i.endpoint || '—'],
            ['Порт UDP', server.port || ep.port || '—'],
            ['Сеть VPN', server.tunneladdress || '—'],
            ['DNS', i.peer_dns || '—'],
            ['Через VPN', full ? 'весь трафик' : (i.allowed_ips || '—')],
            ['Открытый ключ', i.pubkey || '—']
        ].map(([k, v]) => `<div class="jkw-kv"><div class="k">${esc(k)}</div><div class="v">${esc(v)}</div></div>`).join(''));
        if (isPrivate(ep.host)) {
            $('#jkw-main-err').removeClass('err').addClass('warn').html('<i class="fa fa-exclamation-triangle"></i><div>Адрес подключения внутренний. ' +
                'Из интернета устройства его не найдут: укажите внешний IP или DDNS ниже и пробросьте UDP ' + esc(server.port || ep.port) + ' на внешнем роутере.</div>').show();
        } else {
            $('#jkw-main-err').hide();
        }
        if (!$('#jkw-e-save').data('dirty')) {
            $('#jkw-e-host').val(i.endpoint || '');
            $('#jkw-e-dns').val(i.peer_dns || '');
            $('#jkw-e-ips').val(String(i.allowed_ips || '').split(',').map((s) => s.trim()).join(', '));
        }
    }

    function showErr(msg) {
        $('#jkw-main-err').removeClass('warn').addClass('err').html('<i class="fa fa-exclamation-circle"></i><div>' + esc(msg) + '</div>').show();
    }

    // --- config / QR ----------------------------------------------------------------------------
    function buildConf(d) {
        const i = info || {};
        const rows = ['[Interface]', 'PrivateKey = ' + d.privkey, 'Address = ' + String(d.tunneladdress).split(',').map((s) => s.trim()).join(', ')];
        if (i.peer_dns) { rows.push('DNS = ' + i.peer_dns); }
        if (i.mtu) { rows.push('MTU = ' + i.mtu); }
        rows.push('', '[Peer]', 'PublicKey = ' + i.pubkey);
        if (d.psk) { rows.push('PresharedKey = ' + d.psk); }
        rows.push('Endpoint = ' + i.endpoint, 'AllowedIPs = ' + String(i.allowed_ips || '0.0.0.0/0,::/0').split(',').map((s) => s.trim()).join(', '));
        rows.push('PersistentKeepalive = ' + (d.keepalive || 25));
        return rows.join('\n') + '\n';
    }

    function showQr(name, conf, stored) {
        const qr = qrcode(0, 'M');
        qr.addData(conf);
        qr.make();
        $('#jkw-q-img').html(qr.createSvgTag({cellSize: 5, margin: 2, scalable: true}));
        $('#jkw-q-title').text('Подключить «' + name + '»');
        $('#jkw-q-text').text(conf);
        $('#jkw-q-warn').toggle(!stored);
        lastConf = {name: name, conf: conf};
        $('#jkw-m-add').hide();
        $('#jkw-m-qr').show();
        $('#jkw-ov').addClass('open');
    }

    async function qrFor(uuid) {
        const d = devices.find((x) => x.uuid === uuid);
        const r = await api('/api/wireguard/client/get_client/' + uuid);
        const c = (r && r.client) || {};
        if (!c.privkey) {
            showErr(`Ключ устройства «${d ? d.name : ''}» не хранится на экране, поэтому QR-код показать нельзя. Удалите устройство и добавьте его заново.`);
            return;
        }
        const plain = (v) => (typeof v === 'object' && v !== null) ? Object.keys(v).filter((k) => String(v[k].selected) === '1').join(',') : String(v || '');
        showQr(c.name || (d && d.name), buildConf({privkey: c.privkey, psk: c.psk, keepalive: c.keepalive,
            tunneladdress: plain(c.tunneladdress) || (d && d.tunneladdress)}), true);
    }

    // --- add device -----------------------------------------------------------------------------
    let devTypeSel = 'phone';

    function openAdd() {
        $('#jkw-d-err').hide();
        const used = new Set(devices.map((x) => x.name));
        let n = 1;
        while (used.has(devTypeSel + '-' + n)) { n++; }
        $('#jkw-d-name').val(devTypeSel + '-' + n).removeClass('bad');
        $('#jkw-types .jkw-type').each(function () { $(this).toggleClass('sel', $(this).data('type') === devTypeSel); });
        $('#jkw-d-create').prop('disabled', false).html('<i class="fa fa-qrcode"></i> Создать');
        $('#jkw-m-qr').hide();
        $('#jkw-m-add').show();
        $('#jkw-ov').addClass('open');
        setTimeout(() => $('#jkw-d-name').trigger('focus').trigger('select'), 30);
    }

    async function createDevice() {
        const name = String($('#jkw-d-name').val()).trim();
        const err = (m) => $('#jkw-d-err').html('<i class="fa fa-exclamation-circle"></i><div>' + esc(m) + '</div>').show();
        if (!/^[0-9a-zA-Z._-]{1,64}$/.test(name)) {
            $('#jkw-d-name').addClass('bad');
            return err('Название: латиница, цифры, точка, дефис или подчёркивание, без пробелов.');
        }
        if (devices.some((x) => x.name === name)) {
            $('#jkw-d-name').addClass('bad');
            return err('Устройство с таким названием уже есть.');
        }
        const keep = $('#jkw-d-keep').prop('checked');
        $('#jkw-d-create').prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i> Создаём…');
        try {
            const [keys, psk, si] = await Promise.all([
                api('/api/wireguard/server/key_pair'),
                api('/api/wireguard/client/psk'),
                api('/api/wireguard/client/get_server_info/' + server.uuid)
            ]);
            if (!keys || !keys.pubkey || !keys.privkey) {
                throw new Error('не удалось создать ключи');
            }
            if (!si || si.status !== 'ok' || !si.address) {
                throw new Error('в сети VPN не осталось свободных адресов');
            }
            info = si;
            const address = si.address.split(',').filter((a) => !a.includes(':')).join(',') || si.address;
            saved(await api('/api/wireguard/client/add_client_builder', {configbuilder: {
                enabled: '1', name: name, pubkey: keys.pubkey, privkey: keep ? keys.privkey : '', psk: psk.psk || '',
                tunneladdress: address, keepalive: '25', server: server.uuid
            }}));
            await api('/api/wireguard/service/reconfigure', {});
            const conf = buildConf({privkey: keys.privkey, psk: psk.psk, tunneladdress: address, keepalive: 25});
            showQr(name, conf, keep);
            load().catch(() => null);
        } catch (e) {
            err('Не получилось: ' + e.message);
            $('#jkw-d-create').prop('disabled', false).html('<i class="fa fa-qrcode"></i> Создать');
        }
    }

    // --- events ---------------------------------------------------------------------------------
    $('#jkw-host, #jkw-port, #jkw-net').on('input', () => {
        checkSetup();
        const net = parseCidr($('#jkw-net').val());
        const dns = $('#jkw-dns');
        if (net && (!dns.data('touched'))) {
            dns.val(n2ip(net.net + 1));
        }
    });
    $('#jkw-dns').on('input', function () { $(this).data('touched', true); });
    $('#jkw-route').on('click', '.jkw-opt', function () {
        route = $(this).data('route');
        renderSetup();
    });
    $('#jkw-enable').on('click', () => { if (!busy) { setup(); } });
    $('#jkw-add').on('click', openAdd);
    $('#jkw-types').on('click', '.jkw-type', function () {
        const prev = devTypeSel;
        devTypeSel = $(this).data('type');
        $('#jkw-types .jkw-type').removeClass('sel');
        $(this).addClass('sel');
        const nm = $('#jkw-d-name');
        if (new RegExp('^' + prev + '-\\d+$').test(nm.val())) {
            const used = new Set(devices.map((x) => x.name));
            let n = 1;
            while (used.has(devTypeSel + '-' + n)) { n++; }
            nm.val(devTypeSel + '-' + n);
        }
    });
    $('#jkw-d-name').on('input', function () { $(this).removeClass('bad'); $('#jkw-d-err').hide(); })
        .on('keydown', (e) => { if (e.key === 'Enter') { createDevice(); } });
    $('#jkw-d-create').on('click', createDevice);
    $('#jkw-ov').on('click', '[data-close]', () => $('#jkw-ov').removeClass('open'));
    $('#jkw-ov').on('mousedown', function (e) { if (e.target === this) { $(this).removeClass('open'); } });
    $(document).on('keydown', (e) => { if (e.key === 'Escape') { $('#jkw-ov').removeClass('open'); } });
    $('#jkw-q-dl').on('click', () => {
        if (!lastConf) { return; }
        const a = document.createElement('a');
        a.href = URL.createObjectURL(new Blob([lastConf.conf], {type: 'text/plain'}));
        a.download = lastConf.name + '.conf';
        document.body.appendChild(a);
        a.click();
        setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 500);
    });

    $('#jkw-devs').on('click', 'button[data-act]', async function () {
        const uuid = String($(this).closest('.jkw-dev').data('uuid'));
        const d = devices.find((x) => x.uuid === uuid);
        const act = $(this).data('act');
        $('#jkw-main-err').hide();
        try {
            if (act === 'qr') {
                await qrFor(uuid);
                return;
            }
            if (act === 'del' && !window.confirm(`Удалить «${d ? d.name : ''}»? Устройство больше не сможет подключиться.`)) {
                return;
            }
            $(this).prop('disabled', true).find('.fa').attr('class', 'fa fa-spinner fa-pulse');
            if (act === 'del') {
                await api('/api/wireguard/client/del_client/' + uuid, {});
            } else {
                await api('/api/wireguard/client/toggle_client/' + uuid, {});
            }
            await api('/api/wireguard/service/reconfigure', {});
            await load();
        } catch (e) {
            showErr('Не получилось: ' + e.message);
            load().catch(() => null);
        }
    });

    $('#jkw-srv-sw').on('click keydown', async function (e) {
        if (busy || !server || (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter')) { return; }
        e.preventDefault();
        busy = true;
        const on = $(this).hasClass('on');
        try {
            if (!wgEnabled) {
                saved(await api('/api/wireguard/general/set', {general: {enabled: '1'}}), 'WireGuard');
            }
            if (on || String(server.enabled) !== '1') {
                await api('/api/wireguard/server/toggle_server/' + server.uuid, {});
            }
            await api('/api/wireguard/service/reconfigure', {});
            await load();
        } catch (err) {
            showErr('Не получилось: ' + err.message);
        }
        busy = false;
    });

    $('#jkw-e-host, #jkw-e-dns, #jkw-e-ips').on('input', () => {
        $('#jkw-e-save').prop('disabled', false).data('dirty', true);
        $('#jkw-e-st').text('');
    });
    $('#jkw-e-save').on('click', async function () {
        const btn = $(this).prop('disabled', true);
        try {
            saved(await api('/api/wireguard/server/set_server/' + server.uuid, {server: {
                endpoint: String($('#jkw-e-host').val()).trim(),
                peer_dns: String($('#jkw-e-dns').val()).replace(/\s+/g, ''),
                allowed_ips: String($('#jkw-e-ips').val()).replace(/\s+/g, '')
            }}));
            btn.data('dirty', false);
            $('#jkw-e-st').text('Сохранено.');
            await load();
        } catch (e) {
            btn.prop('disabled', false);
            $('#jkw-e-st').text(e.message);
        }
    });

    loadIfaces().then(load).catch((e) => {
        $('#jkw-loading').html('<div class="jkw-empty"><i class="fa fa-exclamation-circle"></i>Не удалось загрузить настройки: ' + esc(e.message) + '</div>');
    });
    setInterval(() => {
        if (!busy && server && !$('#jkw-ov').hasClass('open')) {
            loadLive().then(render).catch(() => null);
        }
    }, 15000);
});
</script>
