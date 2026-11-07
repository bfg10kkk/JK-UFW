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
 # jk-ufw: threat management (IDS/IPS) in one page. It drives the stock Suricata
 # integration through /api/ids/*: general settings, rule sets, one drop policy.
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
@media (max-width: 640px) { .jkt-seg, .jkt-levels { grid-template-columns:1fr !important; } }
.jkt-opt { background:var(--s2); border:1px solid var(--b); border-radius:10px; padding:14px; cursor:pointer; transition:all .15s; position:relative; }
.jkt-opt:hover { border-color:var(--b2); background:var(--h); }
.jkt-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jkt-opt .ic { font-size:18px; color:var(--m); margin-bottom:8px; }
.jkt-opt.sel .ic { color:var(--a2); }
.jkt-opt .nm { font-weight:700; font-size:14px; }
.jkt-opt .ds { color:var(--m); font-size:12px; margin-top:4px; line-height:1.45; }
.jkt-opt .tag { position:absolute; top:10px; right:10px; font-size:10px; font-weight:700; letter-spacing:.06em; text-transform:uppercase;
  color:var(--a2); background:var(--abg); padding:2px 7px; border-radius:6px; }
.jkt-levels { display:grid; grid-template-columns:repeat(4,1fr); gap:10px; margin-bottom:16px; }
.jkt-cats { display:grid; grid-template-columns:repeat(auto-fill,minmax(250px,1fr)); gap:8px; }
.jkt-cat { display:flex; align-items:flex-start; gap:12px; padding:11px 12px; border-radius:10px; background:var(--s2); border:1px solid var(--b); cursor:pointer; }
.jkt-cat:hover { background:var(--h); }
.jkt-cat .ci { width:32px; height:32px; flex:none; border-radius:8px; display:grid; place-items:center; background:#202026; color:var(--m); }
.jkt-cat.on .ci { background:var(--abg); color:var(--a2); }
.jkt-cat .cm { flex:1; min-width:0; }
.jkt-cat .cn { font-weight:600; }
.jkt-cat .cd { color:var(--m); font-size:11.5px; margin-top:2px; line-height:1.4; }
.jkt-cat.na { opacity:.45; cursor:not-allowed; }
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
.jkt-chart { display:flex; align-items:flex-end; gap:2px; height:70px; margin-bottom:4px; }
.jkt-chart div { flex:1; display:flex; flex-direction:column-reverse; min-height:2px; background:#1c1c21; border-radius:2px; overflow:hidden; }
.jkt-chart span { display:block; }
.jkt-axis { display:flex; justify-content:space-between; color:var(--m); font-size:11px; margin-bottom:14px; }
.jkt-ev { display:flex; gap:10px; padding:9px 0; border-top:1px solid var(--b); align-items:flex-start; }
.jkt-ev:first-child { border-top:0; }
.jkt-ev .bd { flex:none; font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:.05em; padding:2px 7px; border-radius:6px; margin-top:1px;
  background:rgba(245,165,36,.12); color:var(--warn); min-width:74px; text-align:center; }
.jkt-ev .bd.blk { background:var(--abg); color:var(--a2); }
.jkt-ev .em { flex:1; min-width:0; }
.jkt-ev .en { font-weight:600; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkt-ev .es { color:var(--m); font-size:11.5px; font-family:ui-monospace,Menlo,Consolas,monospace; margin-top:2px; }
.jkt-ev .et { color:var(--m); font-size:11.5px; white-space:nowrap; }
.jkt-top { display:flex; align-items:center; gap:8px; padding:6px 0; }
.jkt-top .tn { flex:1; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.jkt-top .tv { color:var(--m); font-variant-numeric:tabular-nums; }
.jkt-top .tb { height:4px; border-radius:4px; background:var(--a); opacity:.8; }
.jkt-empty { color:var(--m); text-align:center; padding:22px 6px; }
.jkt-empty .fa { display:block; font-size:22px; margin-bottom:8px; color:#3a3a42; }
.jkt-steps { margin:0; padding:0; list-style:none; }
.jkt-steps li { padding:4px 0; color:var(--m); }
.jkt-steps li.done { color:var(--t); }
.jkt-steps li.done .fa { color:var(--ok); }
.jkt-steps li.run .fa { color:var(--a2); }
.jkt-steps li.err { color:var(--a2); }
.jkt .muted { color:var(--m); }
</style>

<div class="jkt" id="jkt">
  <div class="jkt-head">
    <div class="jkt-shield" id="jkt-shield"><i class="fa fa-shield"></i></div>
    <div>
      <h1 class="jkt-title">Защита от угроз <span class="jkt-pill" id="jkt-status"><i></i><span>…</span></span></h1>
      <div class="jkt-sub" id="jkt-subtitle">Система обнаружения и предотвращения вторжений на базе Suricata</div>
    </div>
    <div class="jkt-head-r">
      <a class="jkt-btn ghost" href="/ui/ids#alerts"><i class="fa fa-list"></i>&nbsp; Журнал угроз</a>
      <a class="jkt-btn ghost" href="/ui/ids"><i class="fa fa-sliders"></i>&nbsp; Расширенные</a>
    </div>
  </div>

  <div class="jkt-grid">
    <div>
      <div class="jkt-card">
        <h3><i class="fa fa-power-off"></i> Режим</h3>
        <div class="jkt-seg" id="jkt-mode">
          <div class="jkt-opt" data-mode="off">
            <div class="ic"><i class="fa fa-ban"></i></div>
            <div class="nm">Выключено</div>
            <div class="ds">Трафик не проверяется. Межсетевой экран работает как обычно.</div>
          </div>
          <div class="jkt-opt" data-mode="ids">
            <div class="ic"><i class="fa fa-eye"></i></div>
            <div class="nm">Обнаружение (IDS)</div>
            <div class="ds">Подозрительный трафик записывается в журнал, но не блокируется.</div>
          </div>
          <div class="jkt-opt" data-mode="ips">
            <span class="tag">Рекомендуется</span>
            <div class="ic"><i class="fa fa-shield"></i></div>
            <div class="nm">Предотвращение (IPS)</div>
            <div class="ds">Угрозы блокируются сразу, до того как дойдут до устройств в сети.</div>
          </div>
        </div>
        <div class="jkt-note warn" id="jkt-ips-note" style="display:none">
          <i class="fa fa-exclamation-triangle"></i>
          <div>Для IPS отключите аппаратную разгрузку на сетевых картах: <a href="/ui/interfaces/settings">Interfaces › Settings</a>,
          галочки <b>CRC</b>, <b>TSO</b> и <b>LRO</b> (Disable…), затем перезагрузка. Иначе пакеты могут теряться. В VirtualBox лучше
          ставить тип адаптера <b>Intel PRO/1000</b> или <b>virtio-net</b>.</div>
        </div>
      </div>

      <div class="jkt-card">
        <h3><i class="fa fa-sitemap"></i> Какие сети проверять</h3>
        <div class="jkt-chips" id="jkt-ifaces"><span class="muted">Загрузка…</span></div>
        <div class="jkt-note info"><i class="fa fa-info-circle"></i>
          <div>Обычно достаточно WAN: так проверяется весь трафик из интернета и обратно. LAN добавляйте, если нужно видеть угрозы между устройствами внутри сети.</div></div>
      </div>

      <div class="jkt-card">
        <h3><i class="fa fa-tachometer"></i> Уровень защиты <span class="r muted" id="jkt-rule-count"></span></h3>
        <div class="jkt-levels" id="jkt-levels">
          <div class="jkt-opt" data-level="basic"><div class="nm">Базовый</div><div class="ds">Ботнеты, вирусы и адреса с плохой репутацией. Почти без ложных срабатываний.</div></div>
          <div class="jkt-opt" data-level="recommended"><div class="nm">Рекомендуемый</div><div class="ds">Плюс эксплойты, фишинг, сканирование и атаки на веб.</div></div>
          <div class="jkt-opt" data-level="max"><div class="nm">Максимальный</div><div class="ds">Все категории. Больше нагрузка на процессор и ложных срабатываний.</div></div>
          <div class="jkt-opt" data-level="custom"><div class="nm">Свой</div><div class="ds">Категории выбраны вручную ниже.</div></div>
        </div>
        <div class="jkt-cats" id="jkt-cats"></div>
      </div>

      <div class="jkt-card">
        <h3><i class="fa fa-cog"></i> Дополнительно</h3>
        <div class="jkt-row">
          <div class="rl"><div class="rn">Домашние сети</div><div class="rd">Адреса вашей сети. Правила отличают «своих» от «чужих» по этому списку.</div>
            <div style="margin-top:8px"><input class="jkt-in" id="jkt-homenet" type="text" spellcheck="false"/></div></div>
        </div>
        <div class="jkt-row">
          <div class="rl"><div class="rn">Неразборчивый режим</div><div class="rd">Нужен, если проверяются VLAN на одном физическом интерфейсе.</div></div>
          <div class="jkt-sw" id="jkt-promisc" role="switch" tabindex="0"></div>
        </div>
        <div class="jkt-row">
          <div class="rl"><div class="rn">Обновление сигнатур</div><div class="rd" id="jkt-upd">Сигнатуры скачиваются при применении и затем раз в сутки автоматически.</div></div>
          <button class="jkt-btn ghost" id="jkt-update" type="button"><i class="fa fa-refresh"></i>&nbsp; Обновить сейчас</button>
        </div>
      </div>
    </div>

    <div>
      <div class="jkt-card">
        <h3><i class="fa fa-bolt"></i> Угрозы за 24 часа <span class="r"><a href="/ui/ids#alerts">Все события →</a></span></h3>
        <div class="jkt-kpis">
          <div class="jkt-kpi"><div class="l">Обнаружено</div><div class="v" id="jkt-k-total">—</div></div>
          <div class="jkt-kpi"><div class="l">Заблокировано</div><div class="v red" id="jkt-k-blocked">—</div></div>
          <div class="jkt-kpi"><div class="l">Источников</div><div class="v" id="jkt-k-src">—</div></div>
        </div>
        <div class="jkt-chart" id="jkt-chart"></div>
        <div class="jkt-axis"><span>−24 ч</span><span>−12 ч</span><span>сейчас</span></div>
        <div id="jkt-top"></div>
      </div>
      <div class="jkt-card">
        <h3><i class="fa fa-history"></i> Последние события</h3>
        <div id="jkt-events"><div class="jkt-empty">Загрузка…</div></div>
      </div>
    </div>
  </div>

  <div class="jkt-bar">
    <div class="st" id="jkt-bar-st">Изменений нет.</div>
    <button class="jkt-btn ghost" id="jkt-reset" type="button" disabled>Отменить</button>
    <button class="jkt-btn" id="jkt-apply" type="button" disabled>Применить</button>
  </div>
</div>

<script>
'use strict';
$(function () {
    // Rule set files of the stock "ET open" and abuse.ch feeds, grouped the way UniFi shows threat categories.
    const CATEGORIES = [
        {id: 'botnet', name: 'Ботнеты и C&C', icon: 'fa-sitemap', level: 'basic',
            desc: 'Связь заражённых устройств с серверами управления.',
            files: ['botcc.rules', 'botcc.portgrouped.rules', 'threatview_CS_c2.rules', 'abuse.ch.feodotracker.rules', 'abuse.ch.sslblacklist.rules']},
        {id: 'malware', name: 'Вирусы и трояны', icon: 'fa-bug', level: 'basic',
            desc: 'Загрузка и работа вредоносных программ, черви, майнеры.',
            files: ['emerging-malware.rules', 'emerging-mobile_malware.rules', 'emerging-worm.rules', 'emerging-coinminer.rules']},
        {id: 'reputation', name: 'Плохая репутация IP', icon: 'fa-user-secret', level: 'basic',
            desc: 'Известные атакующие и взломанные хосты (DShield, CI Army, Spamhaus DROP).',
            files: ['compromised.rules', 'ciarmy.rules', 'drop.rules', 'dshield.rules']},
        {id: 'exploit', name: 'Эксплойты', icon: 'fa-crosshairs', level: 'recommended',
            desc: 'Попытки воспользоваться уязвимостями, шелл-код, наборы эксплойтов.',
            files: ['emerging-exploit.rules', 'emerging-exploit_kit.rules', 'emerging-shellcode.rules', 'emerging-attack_response.rules', 'emerging-current_events.rules']},
        {id: 'web', name: 'Атаки на веб', icon: 'fa-globe', level: 'recommended',
            desc: 'SQL-инъекции, атаки на веб-серверы, браузеры и CMS.',
            files: ['emerging-web_server.rules', 'emerging-web_specific_apps.rules', 'emerging-web_client.rules', 'emerging-sql.rules', 'emerging-activex.rules']},
        {id: 'phishing', name: 'Фишинг', icon: 'fa-envelope-o', level: 'recommended',
            desc: 'Поддельные страницы входа и кража учётных данных.',
            files: ['emerging-phishing.rules']},
        {id: 'scan', name: 'Сканирование и DoS', icon: 'fa-search', level: 'recommended',
            desc: 'Сканеры портов, перебор паролей, отказ в обслуживании.',
            files: ['emerging-scan.rules', 'emerging-dos.rules']},
        {id: 'dns', name: 'DNS', icon: 'fa-random', level: 'recommended',
            desc: 'Туннели через DNS, подозрительные динамические домены.',
            files: ['emerging-dns.rules', 'emerging-dyn_dns.rules']},
        {id: 'adware', name: 'Реклама и нежелательное ПО', icon: 'fa-eye-slash', level: 'max',
            desc: 'Рекламные модули, PUP, подозрительные user-agent.',
            files: ['emerging-adware_pup.rules', 'emerging-user_agents.rules']},
        {id: 'services', name: 'Сетевые службы', icon: 'fa-server', level: 'max',
            desc: 'Почта, FTP, Telnet, SNMP, RPC, NetBIOS, VoIP, SCADA, ICMP.',
            files: ['emerging-smtp.rules', 'emerging-imap.rules', 'emerging-pop3.rules', 'emerging-ftp.rules', 'emerging-tftp.rules',
                'emerging-telnet.rules', 'emerging-snmp.rules', 'emerging-rpc.rules', 'emerging-netbios.rules', 'emerging-voip.rules',
                'emerging-scada.rules', 'emerging-icmp.rules']},
        {id: 'remote', name: 'Удалённый доступ', icon: 'fa-desktop', level: 'max',
            desc: 'TeamViewer, AnyDesk, VNC и подобные программы.',
            files: ['emerging-remote_access.rules']},
        {id: 'p2p', name: 'P2P, игры и чаты', icon: 'fa-users', level: 'max',
            desc: 'Торренты, файлообменники, игры и мессенджеры.',
            files: ['emerging-p2p.rules', 'emerging-file_sharing.rules', 'emerging-games.rules', 'emerging-chat.rules']},
        {id: 'tor', name: 'Tor', icon: 'fa-low-vision', level: 'max',
            desc: 'Подключения к узлам сети Tor.',
            files: ['tor.rules']},
        {id: 'policy', name: 'Политики и аномалии', icon: 'fa-flag', level: 'max',
            desc: 'Нарушения политик и общие подозрительные события. Много шума.',
            files: ['emerging-policy.rules', 'emerging-info.rules', 'emerging-hunting.rules', 'emerging-misc.rules', 'emerging-ja3.rules']}
    ];
    const LEVELS = {basic: ['basic'], recommended: ['basic', 'recommended'], max: ['basic', 'recommended', 'max']};
    const POLICY_NAME = 'jk-ufw: block threats';

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    // suricata writes 2026-11-05T15:00:00.123456+0000; normalise so every browser can parse it
    const parseTs = (v) => Date.parse(String(v || '').replace(/(\.\d{3})\d+/, '$1').replace(/([+-]\d\d)(\d\d)$/, '$1:$2'));
    const num = (n) => Number(n || 0).toLocaleString('ru-RU');
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data)})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status + ' ' + (x.statusText || ''))));
    });
    const selectedKeys = (node) => {
        if (typeof node === 'string') {
            return node.split(',').filter(Boolean);
        }
        return Object.keys(node || {}).filter((k) => String(node[k].selected) === '1');
    };

    let saved = null;   // state as loaded from the firewall
    let state = null;   // state being edited
    let rulesets = {};  // filename -> {enabled, modified_local}
    let ifaceNames = {};
    let busy = false;

    const catState = (cat, enabledSet) => cat.files.some((f) => enabledSet.has(f));
    const availableFiles = (cat) => cat.files.filter((f) => rulesets[f] !== undefined);

    function detectLevel(cats) {
        for (const lvl of ['basic', 'recommended', 'max']) {
            if (CATEGORIES.every((c) => !availableFiles(c).length || cats[c.id] === LEVELS[lvl].includes(c.level))) {
                return lvl;
            }
        }
        return 'custom';
    }

    async function load() {
        const [settings, rs] = await Promise.all([
            api('/api/ids/settings/get'),
            api('/api/ids/settings/list_rulesets', {current: 1, rowCount: -1, searchPhrase: ''})
        ]);
        const g = (settings.ids || {}).general || {};
        rulesets = {};
        (rs.rows || []).forEach((r) => { rulesets[r.filename] = r; });
        const enabledSet = new Set(Object.values(rulesets).filter((r) => String(r.enabled) === '1').map((r) => r.filename));
        ifaceNames = {};
        Object.entries(g.interfaces || {}).forEach(([k, v]) => { ifaceNames[k] = v.value; });

        const enabled = String(g.enabled) === '1';
        const modeVal = selectedKeys(g.mode)[0] || 'pcap';
        let policy = null;
        try {
            const p = await api('/api/ids/settings/search_policy', {current: 1, rowCount: -1, searchPhrase: ''});
            policy = (p.rows || []).find((r) => r.description === POLICY_NAME) || null;
        } catch (e) {
            policy = null;
        }
        const ips = enabled && modeVal !== 'pcap' && policy && String(policy.enabled) === '1';
        const cats = {};
        CATEGORIES.forEach((c) => { cats[c.id] = catState(c, enabledSet); });

        saved = {
            mode: !enabled ? 'off' : (ips ? 'ips' : 'ids'),
            ifaces: selectedKeys(g.interfaces),
            homenet: selectedKeys(g.homenet).join(','),
            promisc: String(g.promisc) === '1',
            cats: cats,
            policy: policy,
            rawMode: modeVal
        };
        if (!enabled && !Object.values(cats).some(Boolean)) {
            // first visit: suggest the recommended level so "Apply" is one click away
            CATEGORIES.forEach((c) => { cats[c.id] = LEVELS.recommended.includes(c.level); });
        }
        state = JSON.parse(JSON.stringify(saved));
        state.level = detectLevel(state.cats);
        const newest = Object.values(rulesets).map((r) => r.modified_local).filter(Boolean).sort().pop();
        $('#jkt-upd').text(newest ? `Последнее обновление: ${newest}. Дальше раз в сутки автоматически.`
            : 'Сигнатуры ещё не скачивались. Они скачаются при нажатии «Применить».');
        render();
    }

    function render() {
        $('#jkt-mode .jkt-opt').each(function () { $(this).toggleClass('sel', $(this).data('mode') === state.mode); });
        $('#jkt-ips-note').toggle(state.mode === 'ips');

        const chips = Object.entries(ifaceNames).map(([k, v]) =>
            `<span class="jkt-chip ${state.ifaces.includes(k) ? 'sel' : ''}" data-if="${esc(k)}"><i class="fa fa-plug"></i>${esc(v)}</span>`);
        $('#jkt-ifaces').html(chips.join('') || '<span class="muted">Нет интерфейсов</span>');

        $('#jkt-levels .jkt-opt').each(function () { $(this).toggleClass('sel', $(this).data('level') === state.level); });
        let files = 0;
        $('#jkt-cats').html(CATEGORIES.map((c) => {
            const avail = availableFiles(c).length > 0;
            const on = avail && state.cats[c.id];
            if (on) {
                files += availableFiles(c).length;
            }
            return `<div class="jkt-cat ${on ? 'on' : ''} ${avail ? '' : 'na'}" data-cat="${c.id}" title="${esc(c.files.join(', '))}">
                <div class="ci"><i class="fa ${c.icon}"></i></div>
                <div class="cm"><div class="cn">${esc(c.name)}</div><div class="cd">${esc(avail ? c.desc : 'Набор правил недоступен в этой версии.')}</div></div>
                <div class="jkt-sw"></div></div>`;
        }).join(''));
        $('#jkt-rule-count').text(`${files} ${files % 10 === 1 && files % 100 !== 11 ? 'набор' : (files % 10 >= 2 && files % 10 <= 4 && (files % 100 < 10 || files % 100 >= 20) ? 'набора' : 'наборов')} правил`);
        $('#jkt-homenet').val(state.homenet);
        $('#jkt-promisc').toggleClass('on', state.promisc);
        $('#jkt-mode, #jkt-ifaces, #jkt-levels, #jkt-cats').css('opacity', 1);

        const dirty = JSON.stringify(diffable(state)) !== JSON.stringify(diffable(saved));
        $('#jkt-apply, #jkt-reset').prop('disabled', !dirty || busy);
        if (!busy) {
            $('#jkt-bar-st').html(dirty ? '<b>Есть несохранённые изменения.</b> Нажмите «Применить», чтобы включить их.' : 'Изменений нет.');
        }
    }

    const diffable = (s) => ({mode: s.mode, ifaces: [...s.ifaces].sort(), homenet: s.homenet, promisc: s.promisc,
        cats: CATEGORIES.filter((c) => availableFiles(c).length).map((c) => !!s.cats[c.id])});

    async function refreshStatus() {
        let st = 'disabled';
        try {
            st = (await api('/api/ids/service/status')).status || 'unknown';
        } catch (e) {
            st = 'unknown';
        }
        const mode = saved ? saved.mode : 'off';
        const pill = $('#jkt-status').removeClass('ok bad');
        const shield = $('#jkt-shield').removeClass('on ids');
        if (st === 'running') {
            pill.addClass('ok').find('span').text(mode === 'ips' ? 'Блокирует угрозы' : 'Только наблюдает');
            shield.addClass(mode === 'ips' ? 'on' : 'ids');
        } else if (mode !== 'off') {
            pill.addClass('bad').find('span').text('Не запущена');
        } else {
            pill.find('span').text('Выключена');
        }
    }

    async function loadAlerts() {
        let res = null;
        try {
            res = await api('/api/ids/service/query_alerts', {current: 1, rowCount: 1000, searchPhrase: ''});
        } catch (e) {
            res = null;
        }
        const rows = (res && res.rows) || [];
        const now = Date.now();
        const from = now - 24 * 3600 * 1000;
        const buckets = Array.from({length: 24}, () => ({b: 0, a: 0}));
        const sig = {};
        const srcs = new Set();
        let total = 0;
        let blocked = 0;
        const recent = [];
        rows.forEach((r) => {
            const ts = parseTs(r.timestamp);
            if (!Number.isFinite(ts) || ts < from) {
                return;
            }
            total++;
            const isBlk = r.alert_action === 'blocked';
            if (isBlk) {
                blocked++;
            }
            const i = Math.min(23, Math.max(0, Math.floor((ts - from) / 3600000)));
            buckets[i][isBlk ? 'b' : 'a']++;
            sig[r.alert] = (sig[r.alert] || 0) + 1;
            if (r.src_ip) {
                srcs.add(r.src_ip);
            }
            if (recent.length < 12) {
                recent.push(r);
            }
        });
        $('#jkt-k-total').text(num(total));
        $('#jkt-k-blocked').text(num(blocked));
        $('#jkt-k-src').text(num(srcs.size));
        const max = Math.max(1, ...buckets.map((x) => x.a + x.b));
        $('#jkt-chart').html(buckets.map((x) => {
            const h = (x.a + x.b) / max * 100;
            const hb = x.a + x.b ? x.b / (x.a + x.b) * 100 : 0;
            return `<div style="height:${Math.max(3, h)}%" title="${x.b} заблок. / ${x.a} обнар.">
                <span style="height:${hb}%;background:#e5202e"></span><span style="height:${x.a + x.b ? 100 - hb : 0}%;background:#f5a524;opacity:.7"></span></div>`;
        }).join(''));
        const top = Object.entries(sig).sort((a, b) => b[1] - a[1]).slice(0, 5);
        const tmax = top.length ? top[0][1] : 1;
        $('#jkt-top').html(top.length ? '<div class="muted" style="font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;margin-bottom:4px">Частые сигнатуры</div>' +
            top.map(([n, v]) => `<div class="jkt-top"><div class="tn" title="${esc(n)}">${esc(n)}</div>
                <div class="tb" style="width:${Math.round(v / tmax * 60) + 6}px"></div><div class="tv">${num(v)}</div></div>`).join('') : '');

        if (!recent.length) {
            const why = saved && saved.mode === 'off' ? 'Защита выключена. Выберите режим и нажмите «Применить».' : 'За последние сутки угроз не найдено.';
            $('#jkt-events').html(`<div class="jkt-empty"><i class="fa fa-check-circle"></i>${why}</div>`);
            return;
        }
        $('#jkt-events').html(recent.map((r) => {
            const blk = r.alert_action === 'blocked';
            const t = new Date(parseTs(r.timestamp));
            const sp = r.src_port ? ':' + r.src_port : '';
            const dp = r.dest_port ? ':' + r.dest_port : '';
            return `<div class="jkt-ev"><span class="bd ${blk ? 'blk' : ''}">${blk ? 'Блок' : 'Замечено'}</span>
                <div class="em"><div class="en" title="${esc(r.alert)}">${esc(r.alert)}</div>
                <div class="es">${esc(r.src_ip)}${esc(sp)} → ${esc(r.dest_ip)}${esc(dp)} · ${esc(r.proto || '')}${r.in_iface ? ' · ' + esc(r.in_iface) : ''}</div></div>
                <div class="et">${t.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'})}</div></div>`;
        }).join(''));
    }

    function steps(list) {
        $('#jkt-bar-st').html('<ul class="jkt-steps">' + list.map((s) =>
            `<li class="${s.st}"><i class="fa fa-fw ${s.st === 'done' ? 'fa-check' : (s.st === 'run' ? 'fa-spinner fa-pulse' : (s.st === 'err' ? 'fa-times' : 'fa-circle-o'))}"></i> ${esc(s.t)}</li>`
        ).join('') + '</ul>');
    }

    async function apply(forceUpdate) {
        busy = true;
        render();
        const enabledFiles = new Set(Object.values(rulesets).filter((r) => String(r.enabled) === '1').map((r) => r.filename));
        const wantOn = [];
        const wantOff = [];
        CATEGORIES.forEach((c) => {
            availableFiles(c).forEach((f) => {
                if (state.cats[c.id] && !enabledFiles.has(f)) {
                    wantOn.push(f);
                } else if (!state.cats[c.id] && enabledFiles.has(f)) {
                    wantOff.push(f);
                }
            });
        });
        const activeFiles = new Set([...enabledFiles, ...wantOn].filter((f) => !wantOff.includes(f)));
        const needDownload = forceUpdate || wantOn.length > 0 ||
            [...activeFiles].some((f) => rulesets[f] && !rulesets[f].modified_local);
        const plan = [
            {t: 'Сохранение настроек', st: ''},
            {t: 'Наборы правил и политика блокировки', st: ''},
            {t: state.mode === 'off' ? 'Остановка службы' : 'Запуск службы', st: ''}
        ];
        if (needDownload && state.mode !== 'off') {
            plan.push({t: 'Загрузка сигнатур (может занять пару минут)', st: ''});
        }
        const step = async (i, fn) => {
            plan[i].st = 'run';
            steps(plan);
            await fn();
            plan[i].st = 'done';
            steps(plan);
        };
        let cur = 0;
        try {
            await step(cur = 0, async () => {
                const general = {
                    enabled: state.mode === 'off' ? '0' : '1',
                    interfaces: state.ifaces.join(','),
                    homenet: state.homenet,
                    promisc: state.promisc ? '1' : '0'
                };
                if (state.mode === 'ips') {
                    general.mode = 'netmap';
                } else if (state.mode === 'ids') {
                    general.mode = 'pcap';
                }
                const r = await api('/api/ids/settings/set', {ids: {general: general}});
                if (r.result !== 'saved') {
                    const msg = Object.values(r.validations || {}).join(' ');
                    throw new Error(msg || 'настройки не сохранены');
                }
            });
            await step(cur = 1, async () => {
                if (wantOn.length) {
                    await api('/api/ids/settings/toggle_ruleset/' + wantOn.join(',') + '/1', {});
                }
                if (wantOff.length) {
                    await api('/api/ids/settings/toggle_ruleset/' + wantOff.join(',') + '/0', {});
                }
                // IPS = every alerting rule of the enabled sets is turned into "drop" by one policy.
                const pol = {enabled: state.mode === 'ips' ? '1' : '0', prio: '0', action: 'alert', rulesets: '', content: '',
                    new_action: 'drop', description: POLICY_NAME};
                if (saved.policy) {
                    await api('/api/ids/settings/set_policy/' + saved.policy.uuid, {policy: pol});
                } else if (state.mode === 'ips') {
                    await api('/api/ids/settings/add_policy', {policy: pol});
                }
            });
            await step(cur = 2, async () => {
                const r = await api('/api/ids/service/reconfigure', {});
                if (r.status && !/^ok/i.test(String(r.status).trim())) {
                    throw new Error(r.status);
                }
            });
            if (plan[3]) {
                await step(cur = 3, async () => { await api('/api/ids/service/update_rules', {}); });
            }
            await load();
            busy = false;
            render();
            $('#jkt-bar-st').html('<b style="color:#22c55e"><i class="fa fa-check"></i> Готово.</b> ' +
                (state.mode === 'off' ? 'Защита выключена.' : (state.mode === 'ips' ? 'Угрозы блокируются.' : 'Угрозы записываются в журнал.')));
        } catch (e) {
            plan[cur].st = 'err';
            plan[cur].t += ': ' + e.message;
            busy = false;
            steps(plan);
            $('#jkt-apply').prop('disabled', false);
        }
        refreshStatus();
        loadAlerts();
    }

    $('#jkt-mode').on('click', '.jkt-opt', function () {
        if (busy) { return; }
        state.mode = $(this).data('mode');
        render();
    });
    $('#jkt-ifaces').on('click', '.jkt-chip', function () {
        if (busy) { return; }
        const k = String($(this).data('if'));
        state.ifaces = state.ifaces.includes(k) ? state.ifaces.filter((x) => x !== k) : [...state.ifaces, k];
        render();
    });
    $('#jkt-levels').on('click', '.jkt-opt', function () {
        if (busy) { return; }
        const lvl = $(this).data('level');
        state.level = lvl;
        if (LEVELS[lvl]) {
            CATEGORIES.forEach((c) => { state.cats[c.id] = LEVELS[lvl].includes(c.level); });
        }
        render();
    });
    $('#jkt-cats').on('click', '.jkt-cat:not(.na)', function () {
        if (busy) { return; }
        const id = $(this).data('cat');
        state.cats[id] = !state.cats[id];
        state.level = detectLevel(state.cats);
        render();
    });
    $('#jkt-promisc').on('click keydown', function (e) {
        if (busy || (e.type === 'keydown' && e.key !== ' ' && e.key !== 'Enter')) { return; }
        e.preventDefault();
        state.promisc = !state.promisc;
        render();
    });
    $('#jkt-homenet').on('input', function () {
        state.homenet = String($(this).val()).replace(/\s+/g, '');
        const dirty = JSON.stringify(diffable(state)) !== JSON.stringify(diffable(saved));
        $('#jkt-apply, #jkt-reset').prop('disabled', !dirty || busy);
    });
    $('#jkt-reset').on('click', () => {
        state = JSON.parse(JSON.stringify(saved));
        state.level = detectLevel(state.cats);
        render();
    });
    $('#jkt-apply').on('click', () => apply(false));
    $('#jkt-update').on('click', async function () {
        const btn = $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>&nbsp; Обновляем…');
        try {
            await api('/api/ids/service/update_rules', {});
            await load();
        } catch (e) {
            $('#jkt-upd').text('Не удалось обновить: ' + e.message);
        }
        btn.prop('disabled', false).html('<i class="fa fa-refresh"></i>&nbsp; Обновить сейчас');
    });

    load().then(() => { refreshStatus(); loadAlerts(); }).catch((e) => {
        $('#jkt-bar-st').html('<b style="color:#ff3b47">Не удалось загрузить настройки:</b> ' + esc(e.message));
    });
    setInterval(() => { if (!busy) { refreshStatus(); loadAlerts(); } }, 30000);
});
</script>
