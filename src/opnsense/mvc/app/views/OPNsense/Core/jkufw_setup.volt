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
 # jk-ufw: first setup in a few steps (internet, local network, access, protection).
 # It drives the stock wizard API (/api/core/initial_setup/*), so validation and the
 # way settings are written stay exactly as upstream. Threat protection is optional and
 # goes through /api/ids/*, with the same policy name as the "Threat Management" page.
 # The classic tabbed wizard is still at /ui/core/initial_setup?classic
 #}

<style>
#jkw { --a:#e5202e; --a2:#ff3b47; --abg:rgba(229,32,46,.12); --bg:#0b0b0d; --s:#131316; --s2:#18181c; --h:#1e1e23;
  --b:#232329; --b2:#2e2e35; --t:#e8e8ec; --m:#8d8d98; --ok:#22c55e; --warn:#f5a524;
  position:fixed; inset:0; z-index:2000; overflow-y:auto; background:var(--bg); color:var(--t);
  font:13.5px/1.5 Inter,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
  background-image:radial-gradient(900px 500px at 85% -10%, rgba(229,32,46,.13), transparent 60%),
    radial-gradient(700px 420px at -10% 110%, rgba(229,32,46,.07), transparent 60%); }
#jkw * { box-sizing:border-box; }
#jkw b, #jkw strong { font-family:inherit; font-weight:700; }
#jkw a { color:var(--a2); cursor:pointer; text-decoration:none; }
#jkw a:hover { text-decoration:underline; }
.jkw-top { display:flex; align-items:center; gap:12px; padding:18px 28px; }
.jkw-top .nm { font-weight:800; font-size:16px; letter-spacing:-.01em; }
.jkw-top .r { margin-left:auto; display:flex; gap:18px; align-items:center; }
#jkw .jkw-top .r a { color:var(--m); font-weight:600; font-size:12.5px; }
#jkw .jkw-top .r a:hover { color:var(--t); text-decoration:none; }
.jkw-wrap { max-width:760px; margin:0 auto; padding:10px 20px 60px; }
.jkw-prog { display:flex; gap:6px; margin:6px 0 22px; }
.jkw-prog .st { flex:1; min-width:0; cursor:default; }
.jkw-prog .st .bar { height:4px; border-radius:4px; background:var(--b); transition:background .25s; }
.jkw-prog .st .lb { font-size:11.5px; font-weight:600; color:var(--m); margin-top:8px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkw-prog .st .lb i { font-style:normal; color:#55555f; margin-right:5px; }
.jkw-prog .st.done .bar { background:#7d1219; }
.jkw-prog .st.done { cursor:pointer; }
.jkw-prog .st.done .lb { color:#c4c4cc; }
.jkw-prog .st.cur .bar { background:var(--a); box-shadow:0 0 12px rgba(229,32,46,.55); }
.jkw-prog .st.cur .lb { color:var(--t); }
@media (max-width:620px) { .jkw-prog .st .lb { display:none; } .jkw-top { padding:14px 16px; } }
.jkw-card { background:rgba(19,19,22,.94); border:1px solid var(--b); border-radius:16px; padding:28px; box-shadow:0 20px 60px rgba(0,0,0,.45); }
@media (max-width:620px) { .jkw-card { padding:20px 16px; } }
.jkw-h { display:flex; gap:16px; align-items:flex-start; margin-bottom:22px; }
.jkw-h .ic { flex:none; width:46px; height:46px; border-radius:13px; display:grid; place-items:center; font-size:20px; color:#fff;
  background:linear-gradient(145deg,var(--a2),#a5121c); box-shadow:0 6px 22px rgba(229,32,46,.33); }
.jkw-h h2 { font-size:21px; font-weight:800; letter-spacing:-.02em; margin:0; color:var(--t); }
.jkw-h p { color:var(--m); margin:3px 0 0; }
.jkw-step { display:none; }
.jkw-step.on { display:block; animation:jkwIn .25s ease; }
@keyframes jkwIn { from { opacity:0; transform:translateY(6px); } to { opacity:1; transform:none; } }
.jkw-opts { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:10px; margin-bottom:20px; }
@media (max-width:620px) { .jkw-opts { grid-template-columns:1fr; } }
.jkw-opt { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; cursor:pointer; transition:all .15s; position:relative; user-select:none; }
.jkw-opt:hover { border-color:var(--b2); background:var(--h); }
.jkw-opt.sel { border-color:var(--a); background:var(--abg); box-shadow:inset 0 0 0 1px var(--a); }
.jkw-opt .oi { font-size:18px; color:var(--m); margin-bottom:8px; }
.jkw-opt.sel .oi { color:var(--a2); }
.jkw-opt .on { font-weight:700; font-size:14px; }
.jkw-opt .od { color:var(--m); font-size:12px; margin-top:3px; line-height:1.45; }
.jkw-opt .tag { position:absolute; top:10px; right:10px; font-size:10px; font-weight:700; letter-spacing:.06em; text-transform:uppercase;
  color:var(--a2); background:var(--abg); padding:2px 7px; border-radius:6px; }
.jkw-grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:14px 16px; }
.jkw-grid .full { grid-column:1 / -1; }
@media (max-width:620px) { .jkw-grid { grid-template-columns:1fr; } }
.jkw-f label { display:block; font-size:12px; font-weight:600; color:#b8b8c2; margin:0 0 6px; }
.jkw-f .hint { color:var(--m); font-size:11.5px; margin-top:5px; line-height:1.45; }
.jkw-f .err { display:none; color:var(--a2); font-size:12px; margin-top:5px; font-weight:600; }
.jkw-f.bad .err { display:block; }
#jkw .jkw-in { display:block; width:100% !important; max-width:none !important; height:40px !important; padding:9px 12px !important;
  background:var(--s2) !important; border:1px solid var(--b) !important; border-radius:9px !important; color:var(--t) !important;
  font-size:13.5px !important; box-shadow:none !important; outline:0; transition:border-color .15s; margin:0; }
#jkw .jkw-in:focus { border-color:var(--a) !important; box-shadow:0 0 0 3px rgba(229,32,46,.18) !important; }
#jkw .jkw-f.bad .jkw-in { border-color:var(--a) !important; }
#jkw select.jkw-in { appearance:auto; }
#jkw select.jkw-in option { background:#18181c; color:#e8e8ec; }
.jkw-mono { font-family:ui-monospace,Menlo,Consolas,monospace !important; }
.jkw-ipm { display:flex; gap:8px; }
.jkw-ipm .jkw-in:first-child { flex:1; }
#jkw .jkw-ipm select.jkw-in { width:96px !important; flex:none; }
.jkw-pw { position:relative; }
.jkw-pw .eye { position:absolute; right:6px; top:6px; width:28px; height:28px; display:grid; place-items:center; color:var(--m); cursor:pointer; border-radius:6px; }
.jkw-pw .eye:hover { color:var(--t); background:var(--h); }
.jkw-meter { display:flex; gap:4px; margin-top:8px; }
.jkw-meter i { flex:1; height:4px; border-radius:4px; background:var(--b); transition:background .2s; }
.jkw-meter-l { font-size:11.5px; color:var(--m); margin-top:5px; }
.jkw-row { display:flex; align-items:center; gap:14px; padding:14px 0; border-top:1px solid var(--b); cursor:pointer; user-select:none; }
.jkw-row:first-child { border-top:0; }
.jkw-row .ri { flex:none; width:34px; height:34px; border-radius:9px; display:grid; place-items:center; background:#202026; color:var(--m); }
.jkw-row.on .ri { background:var(--abg); color:var(--a2); }
.jkw-row .rl { flex:1; min-width:0; }
.jkw-row .rn { font-weight:600; }
.jkw-row .rd { color:var(--m); font-size:12px; margin-top:1px; line-height:1.45; }
.jkw-row.sub { padding-left:48px; }
.jkw-row.dis { opacity:.4; pointer-events:none; }
.jkw-sw { flex:none; width:38px; height:22px; border-radius:999px; background:#2c2c33; position:relative; transition:background .15s; }
.jkw-sw::after { content:""; position:absolute; top:3px; left:3px; width:16px; height:16px; border-radius:50%; background:#d6d6dc; transition:left .15s; }
.jkw-row.on .jkw-sw { background:var(--a); }
.jkw-row.on .jkw-sw::after { left:19px; background:#fff; }
.jkw-sec { font-size:11.5px; font-weight:700; letter-spacing:.08em; text-transform:uppercase; color:var(--m); margin:24px 0 8px; }
.jkw-sec:first-child { margin-top:0; }
.jkw-box { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:2px 16px; }
.jkw-more { margin-top:18px; }
.jkw-more > .tg { display:inline-flex; align-items:center; gap:7px; color:var(--m); font-weight:600; font-size:12.5px; cursor:pointer; user-select:none; }
.jkw-more > .tg:hover { color:var(--t); }
.jkw-more > .tg .fa { transition:transform .2s; }
.jkw-more.open > .tg .fa { transform:rotate(90deg); }
.jkw-more > .bd { display:none; margin-top:14px; padding-top:16px; border-top:1px dashed var(--b2); }
.jkw-more.open > .bd { display:block; }
.jkw-note { border-radius:10px; padding:11px 13px; font-size:12.5px; line-height:1.5; margin-top:14px; display:flex; gap:10px; }
.jkw-note .fa { margin-top:3px; }
.jkw-note.warn { background:rgba(245,165,36,.09); border:1px solid rgba(245,165,36,.28); color:#f3d39b; }
.jkw-note.warn .fa { color:var(--warn); }
.jkw-note.info { background:var(--s2); border:1px solid var(--b); color:#a9a9b3; }
.jkw-note.info .fa { color:var(--m); }
.jkw-note.bad { background:rgba(229,32,46,.09); border:1px solid rgba(229,32,46,.35); color:#ffb3b8; }
.jkw-note.bad .fa { color:var(--a2); }
.jkw-foot { display:flex; align-items:center; gap:10px; margin-top:26px; padding-top:20px; border-top:1px solid var(--b); }
.jkw-foot .sp { flex:1; }
.jkw-foot .msg { color:var(--m); font-size:12.5px; }
.jkw-btn { border:0; border-radius:10px; padding:11px 22px; font-weight:700; font-size:13.5px; cursor:pointer; background:var(--a); color:#fff;
  display:inline-flex; align-items:center; gap:8px; transition:background .15s; }
.jkw-btn:hover { background:var(--a2); }
#jkw a.jkw-btn, #jkw a.jkw-btn:hover { color:#fff; text-decoration:none; }
.jkw-btn[disabled] { opacity:.55; cursor:default; }
.jkw-btn.ghost { background:transparent; border:1px solid var(--b2); color:var(--t); font-weight:600; }
.jkw-btn.ghost:hover { background:var(--h); }
.jkw-btn.big { padding:14px 30px; font-size:15px; border-radius:12px; box-shadow:0 10px 30px rgba(229,32,46,.35); }
/* welcome */
.jkw-hero { text-align:center; padding:36px 10px 12px; }
.jkw-hero .logo { width:84px; height:84px; margin:0 auto 22px; filter:drop-shadow(0 12px 30px rgba(229,32,46,.45)); }
.jkw-hero h1 { font-size:32px; font-weight:800; letter-spacing:-.03em; margin:0; color:#fff; }
.jkw-hero h1 span { color:var(--a2); }
.jkw-hero p.lead { color:var(--m); font-size:15px; margin:10px auto 0; max-width:480px; }
.jkw-plan { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; margin:30px 0 30px; text-align:left; }
@media (max-width:620px) { .jkw-plan { grid-template-columns:repeat(2,minmax(0,1fr)); } .jkw-hero h1 { font-size:26px; } }
.jkw-plan div { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px; }
.jkw-plan .fa { color:var(--a2); font-size:17px; }
.jkw-plan b { display:block; margin-top:8px; font-size:13px; }
.jkw-plan span { display:block; color:var(--m); font-size:11.5px; margin-top:2px; line-height:1.4; }
.jkw-hero .alt { margin-top:18px; color:var(--m); font-size:12.5px; }
.jkw-hero .alt a { color:var(--m); text-decoration:underline; }
.jkw-hero .alt a:hover { color:var(--t); }
/* summary */
.jkw-sum { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
@media (max-width:620px) { .jkw-sum { grid-template-columns:1fr; } }
.jkw-sum > div { background:var(--s2); border:1px solid var(--b); border-radius:12px; padding:14px 16px; }
.jkw-sum h4 { display:flex; align-items:center; gap:8px; font-size:11.5px; font-weight:700; letter-spacing:.08em; text-transform:uppercase; color:var(--m); margin:0 0 10px; }
.jkw-sum h4 .fa { color:var(--a2); }
.jkw-sum h4 a { margin-left:auto; text-transform:none; letter-spacing:0; font-weight:600; font-size:12px; }
.jkw-kv { display:flex; justify-content:space-between; gap:12px; padding:3px 0; font-size:12.5px; }
.jkw-kv span:first-child { color:var(--m); }
.jkw-kv span:last-child { text-align:right; font-weight:600; overflow-wrap:anywhere; }
.jkw-kv .ok { color:var(--ok); }
.jkw-kv .off { color:var(--m); font-weight:500; }
/* applying / done */
.jkw-run { list-style:none; padding:0; margin:6px 0 0; }
.jkw-run li { display:flex; gap:12px; align-items:center; padding:10px 0; color:var(--m); border-top:1px solid var(--b); }
.jkw-run li:first-child { border-top:0; }
.jkw-run li .fa { width:18px; text-align:center; }
.jkw-run li.run { color:var(--t); }
.jkw-run li.run .fa { color:var(--a2); }
.jkw-run li.done { color:#c4c4cc; }
.jkw-run li.done .fa { color:var(--ok); }
.jkw-run li.err { color:#ffb3b8; }
.jkw-run li.err .fa { color:var(--a2); }
.jkw-run li.skip { opacity:.6; }
.jkw-done { text-align:center; padding:18px 0 4px; }
.jkw-done .okc { width:72px; height:72px; border-radius:50%; margin:0 auto 18px; display:grid; place-items:center; font-size:32px; color:#fff;
  background:linear-gradient(145deg,#2fd06b,#15803d); box-shadow:0 10px 30px rgba(34,197,94,.3); }
.jkw-done h2 { font-size:24px; font-weight:800; letter-spacing:-.02em; margin:0; }
.jkw-done p { color:var(--m); margin:8px auto 0; max-width:480px; }
.jkw-done .addr { display:inline-block; margin-top:16px; padding:10px 16px; border-radius:10px; background:var(--s2); border:1px solid var(--b);
  font-family:ui-monospace,Menlo,Consolas,monospace; font-size:15px; color:#fff; }
.jkw-load { text-align:center; color:var(--m); padding:80px 0; }
</style>

<div id="jkw">
    <div class="jkw-top">
        <svg width="30" height="30" viewBox="0 0 64 64" aria-hidden="true">
            <defs><linearGradient id="jkwg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff3b47"/><stop offset="1" stop-color="#9c0f19"/></linearGradient></defs>
            <path d="M32 2 L58 17 V47 L32 62 L6 47 V17 Z" fill="url(#jkwg)"/>
            <g fill="#fff"><rect x="17" y="20" width="13" height="6" rx="1.5"/><rect x="33" y="20" width="14" height="6" rx="1.5"/>
            <rect x="17" y="29" width="6" height="6" rx="1.5"/><rect x="26" y="29" width="13" height="6" rx="1.5"/><rect x="42" y="29" width="5" height="6" rx="1.5"/>
            <rect x="17" y="38" width="13" height="6" rx="1.5"/><rect x="33" y="38" width="14" height="6" rx="1.5"/></g>
        </svg>
        <span class="nm" id="jkw-product">{{ product_name }}</span>
        <div class="r">
            <a href="/ui/core/initial_setup?classic" title="Все параметры на вкладках, как в исходном мастере">Классический мастер</a>
            <a id="jkw-skip"><i class="fa fa-times"></i>&nbsp; Пропустить</a>
        </div>
    </div>

    <div class="jkw-wrap">
        <div class="jkw-prog" id="jkw-prog" style="visibility:hidden"></div>
        <div class="jkw-card">
            <div class="jkw-load" id="jkw-loading"><i class="fa fa-spinner fa-pulse"></i>&nbsp; Загрузка текущих настроек…</div>

            <!-- 0: welcome -->
            <div class="jkw-step" data-step="welcome">
                <div class="jkw-hero">
                    <svg class="logo" viewBox="0 0 64 64" aria-hidden="true">
                        <defs><linearGradient id="jkwg2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff3b47"/><stop offset="1" stop-color="#9c0f19"/></linearGradient></defs>
                        <path d="M32 2 L58 17 V47 L32 62 L6 47 V17 Z" fill="url(#jkwg2)"/>
                        <g fill="#fff"><rect x="17" y="20" width="13" height="6" rx="1.5"/><rect x="33" y="20" width="14" height="6" rx="1.5"/>
                        <rect x="17" y="29" width="6" height="6" rx="1.5"/><rect x="26" y="29" width="13" height="6" rx="1.5"/><rect x="42" y="29" width="5" height="6" rx="1.5"/>
                        <rect x="17" y="38" width="13" height="6" rx="1.5"/><rect x="33" y="38" width="14" height="6" rx="1.5"/></g>
                    </svg>
                    <h1>Добро пожаловать в <span class="jkw-pname">{{ product_name }}</span></h1>
                    <p class="lead">Четыре коротких шага, и межсетевой экран готов к работе. Всё можно будет поменять позже в настройках.</p>
                    <div class="jkw-plan">
                        <div><i class="fa fa-globe"></i><b>Интернет</b><span>Как подключён провайдер</span></div>
                        <div><i class="fa fa-sitemap"></i><b>Локальная сеть</b><span>Адрес и раздача IP</span></div>
                        <div><i class="fa fa-key"></i><b>Доступ</b><span>Пароль и часовой пояс</span></div>
                        <div><i class="fa fa-shield"></i><b>Защита</b><span>Фильтры и защита от угроз</span></div>
                    </div>
                    <button class="jkw-btn big" id="jkw-start">Начать настройку &nbsp;<i class="fa fa-arrow-right"></i></button>
                    <div class="alt">Уже знаете, что делаете? <a id="jkw-skip2">Пропустить мастер</a> и перейти к панели.</div>
                </div>
            </div>

            <!-- 1: internet -->
            <div class="jkw-step" data-step="wan">
                <div class="jkw-h"><div class="ic"><i class="fa fa-globe"></i></div>
                    <div><h2>Подключение к интернету</h2><p>Выберите, как провайдер выдаёт адрес. Если не знаете, оставьте «Автоматически».</p></div></div>
                <div class="jkw-opts" id="jkw-wantype">
                    <div class="jkw-opt" data-v="dhcp"><span class="tag">Обычно</span><div class="oi"><i class="fa fa-magic"></i></div>
                        <div class="on">Автоматически</div><div class="od">DHCP. Адрес выдаёт провайдер или роутер перед экраном.</div></div>
                    <div class="jkw-opt" data-v="pppoe"><div class="oi"><i class="fa fa-user-circle-o"></i></div>
                        <div class="on">PPPoE</div><div class="od">Вход по логину и паролю из договора с провайдером.</div></div>
                    <div class="jkw-opt" data-v="static"><div class="oi"><i class="fa fa-thumb-tack"></i></div>
                        <div class="on">Статический IP</div><div class="od">Провайдер выдал постоянный адрес и шлюз.</div></div>
                </div>
                <div class="jkw-grid wan-pppoe">
                    <div class="jkw-f" data-k="interfaces.wan.pppoe_username"><label>Логин</label>
                        <input class="jkw-in" id="f-pppoe-user" autocomplete="off"><div class="err"></div></div>
                    <div class="jkw-f" data-k="interfaces.wan.pppoe_password"><label>Пароль</label>
                        <div class="jkw-pw"><input class="jkw-in" id="f-pppoe-pass" type="password" autocomplete="new-password"><span class="eye"><i class="fa fa-eye"></i></span></div>
                        <div class="err"></div></div>
                    <div class="jkw-f full" data-k="interfaces.wan.pppoe_provider"><label>Имя службы (необязательно)</label>
                        <input class="jkw-in" id="f-pppoe-prov" autocomplete="off"><div class="hint">Заполняется, только если провайдер его указал.</div><div class="err"></div></div>
                </div>
                <div class="jkw-grid wan-static">
                    <div class="jkw-f" data-k="interfaces.wan.ipaddr"><label>IP-адрес и маска</label>
                        <div class="jkw-ipm"><input class="jkw-in jkw-mono" id="f-wan-ip" placeholder="203.0.113.10" autocomplete="off">
                        <select class="jkw-in jkw-mono" id="f-wan-mask"></select></div><div class="err"></div></div>
                    <div class="jkw-f" data-k="interfaces.wan.gateway"><label>Шлюз</label>
                        <input class="jkw-in jkw-mono" id="f-wan-gw" placeholder="203.0.113.1" autocomplete="off"><div class="err"></div></div>
                    <div class="jkw-f full" data-k="dns_servers"><label>DNS-серверы</label>
                        <input class="jkw-in jkw-mono f-dns" placeholder="1.1.1.1, 8.8.8.8" autocomplete="off">
                        <div class="hint">Через запятую. Без них экран будет обращаться к корневым серверам напрямую.</div><div class="err"></div></div>
                </div>
                <div class="jkw-f" data-k="interfaces.wan.disable" style="margin-top:8px"><div class="err"></div></div>
                <div class="jkw-more"><span class="tg"><i class="fa fa-chevron-right"></i> Дополнительно</span>
                    <div class="bd">
                        <div class="jkw-grid">
                            <div class="jkw-f wan-dhcp-only full" data-k="dns_servers"><label>Свои DNS-серверы</label>
                                <input class="jkw-in jkw-mono f-dns" placeholder="по умолчанию от провайдера" autocomplete="off">
                                <div class="hint">Через запятую, например 1.1.1.1, 9.9.9.9.</div><div class="err"></div></div>
                            <div class="jkw-f wan-dhcp-only" data-k="interfaces.wan.dhcphostname"><label>Имя для DHCP</label>
                                <input class="jkw-in" id="f-wan-dhcphost" autocomplete="off"><div class="hint">Нужно редко, если провайдер узнаёт клиента по имени.</div><div class="err"></div></div>
                            <div class="jkw-f" data-k="interfaces.wan.spoofmac"><label>MAC-адрес (подмена)</label>
                                <input class="jkw-in jkw-mono" id="f-wan-mac" placeholder="как у сетевой карты" autocomplete="off">
                                <div class="hint">Если провайдер привязал договор к MAC старого роутера.</div><div class="err"></div></div>
                            <div class="jkw-f" data-k="interfaces.wan.mtu"><label>MTU</label>
                                <input class="jkw-in jkw-mono" id="f-wan-mtu" placeholder="1500 (PPPoE: 1492)" autocomplete="off"><div class="err"></div></div>
                            <div class="jkw-f" data-k="interfaces.wan.mss"><label>MSS</label>
                                <input class="jkw-in jkw-mono" id="f-wan-mss" placeholder="не ограничивать" autocomplete="off"><div class="err"></div></div>
                        </div>
                        <div class="jkw-box" style="margin-top:14px">
                            <div class="jkw-row" data-b="dnsallowoverride"><div class="rl"><div class="rn">Брать DNS у провайдера</div>
                                <div class="rd">DNS-серверы, полученные по DHCP или PPPoE, заменяют указанные выше.</div></div><span class="jkw-sw"></span></div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 2: lan -->
            <div class="jkw-step" data-step="lan">
                <div class="jkw-h"><div class="ic"><i class="fa fa-sitemap"></i></div>
                    <div><h2>Локальная сеть</h2><p>Адрес экрана в вашей сети. По нему вы будете открывать эту панель.</p></div></div>
                <div class="jkw-grid">
                    <div class="jkw-f" data-k="interfaces.lan.ipaddr"><label>Адрес экрана</label>
                        <div class="jkw-ipm"><input class="jkw-in jkw-mono" id="f-lan-ip" placeholder="192.168.1.1" autocomplete="off">
                        <select class="jkw-in jkw-mono" id="f-lan-mask"></select></div><div class="err"></div></div>
                    <div class="jkw-f"><label>Сеть</label>
                        <input class="jkw-in jkw-mono" id="f-lan-net" disabled><div class="hint" id="f-lan-hosts"></div></div>
                </div>
                <div class="jkw-box" style="margin-top:16px">
                    <div class="jkw-row" data-b="interfaces.lan.configure_dhcp"><div class="ri"><i class="fa fa-random"></i></div>
                        <div class="rl"><div class="rn">Раздавать адреса устройствам (DHCP)</div>
                        <div class="rd" id="f-lan-range">Компьютеры и телефоны получат адрес автоматически.</div></div><span class="jkw-sw"></span></div>
                </div>
                <div class="jkw-f" data-k="interfaces.lan.configure_dhcp"><div class="err"></div></div>
                <div class="jkw-note warn" id="jkw-lan-move" style="display:none"><i class="fa fa-exclamation-triangle"></i>
                    <div>Адрес экрана меняется. После применения панель откроется по новому адресу, а компьютеру может понадобиться
                    переподключиться к сети, чтобы получить адрес из новой сети.</div></div>
                <div class="jkw-sec" style="margin-top:24px">Имя устройства</div>
                <div class="jkw-grid">
                    <div class="jkw-f" data-k="hostname"><label>Имя</label>
                        <input class="jkw-in" id="f-hostname" placeholder="firewall" autocomplete="off"><div class="err"></div></div>
                    <div class="jkw-f" data-k="domain"><label>Домен</label>
                        <input class="jkw-in" id="f-domain" placeholder="home.arpa" autocomplete="off">
                        <div class="hint">Подойдут <span class="jkw-mono">home.arpa</span> или <span class="jkw-mono">internal</span>. Не используйте <span class="jkw-mono">local</span>.</div><div class="err"></div></div>
                </div>
                <div class="jkw-more"><span class="tg"><i class="fa fa-chevron-right"></i> Дополнительно</span>
                    <div class="bd">
                        <div class="jkw-box">
                            <div class="jkw-row" data-b="interfaces.lan.disable" data-inv="1"><div class="rl"><div class="rn">Использовать порт LAN</div>
                                <div class="rd">Выключите, только если у экрана один порт (режим «только WAN»).</div></div><span class="jkw-sw"></span></div>
                        </div>
                        <div class="jkw-f" data-k="interfaces.lan.disable"><div class="err"></div></div>
                    </div>
                </div>
            </div>

            <!-- 3: access -->
            <div class="jkw-step" data-step="access">
                <div class="jkw-h"><div class="ic"><i class="fa fa-key"></i></div>
                    <div><h2>Доступ и время</h2><p>Пароль пользователя root для входа в панель и по SSH.</p></div></div>
                <div class="jkw-grid">
                    <div class="jkw-f" data-k="password"><label>Новый пароль</label>
                        <div class="jkw-pw"><input class="jkw-in" id="f-pass" type="password" autocomplete="new-password"><span class="eye"><i class="fa fa-eye"></i></span></div>
                        <div class="jkw-meter" id="jkw-meter"><i></i><i></i><i></i><i></i></div><div class="jkw-meter-l" id="jkw-meter-l">Оставьте пустым, чтобы не менять</div>
                        <div class="err"></div></div>
                    <div class="jkw-f" data-k="password_confirm"><label>Ещё раз</label>
                        <div class="jkw-pw"><input class="jkw-in" id="f-pass2" type="password" autocomplete="new-password"><span class="eye"><i class="fa fa-eye"></i></span></div>
                        <div class="err"></div></div>
                </div>
                <div class="jkw-note warn" id="jkw-pass-note"><i class="fa fa-exclamation-triangle"></i>
                    <div>Сразу после установки у root стандартный пароль, который знают все. Задайте свой, особенно если панель видна из интернета.</div></div>
                <div class="jkw-sec" style="margin-top:24px">Регион</div>
                <div class="jkw-grid">
                    <div class="jkw-f" data-k="timezone"><label>Часовой пояс</label>
                        <select class="jkw-in" id="f-tz"></select><div class="err"></div></div>
                    <div class="jkw-f" data-k="language"><label>Язык системы</label>
                        <select class="jkw-in" id="f-lang"></select><div class="hint">Язык меню и системных сообщений.</div><div class="err"></div></div>
                </div>
            </div>

            <!-- 4: protection -->
            <div class="jkw-step" data-step="protect">
                <div class="jkw-h"><div class="ic"><i class="fa fa-shield"></i></div>
                    <div><h2>Защита</h2><p>Базовые фильтры включены по умолчанию. Защиту от угроз можно включить сейчас или позже.</p></div></div>
                <div class="jkw-sec">Защита от угроз (IDS/IPS)</div>
                <div class="jkw-opts" id="jkw-ids">
                    <div class="jkw-opt" data-v="off"><div class="oi"><i class="fa fa-power-off"></i></div>
                        <div class="on">Выключена</div><div class="od">Включить можно позже на странице «Защита от угроз».</div></div>
                    <div class="jkw-opt" data-v="ids"><span class="tag">Советуем</span><div class="oi"><i class="fa fa-eye"></i></div>
                        <div class="on">Обнаружение</div><div class="od">Атаки и вредоносный трафик записываются в журнал, связь не рвётся.</div></div>
                    <div class="jkw-opt" data-v="ips"><div class="oi"><i class="fa fa-ban"></i></div>
                        <div class="on">Блокировка</div><div class="od">Опасные соединения обрываются. Нужна поддержка netmap сетевой картой.</div></div>
                </div>
                <div class="jkw-note warn" id="jkw-ips-note" style="display:none; margin-top:-8px; margin-bottom:16px"><i class="fa fa-exclamation-triangle"></i>
                    <div>Перед блокировкой отключите аппаратную разгрузку (Interfaces › Settings: CRC, TSO, LRO) и перезагрузите экран.
                    Иначе интернет может пропасть. В VirtualBox подходят адаптеры Intel PRO/1000 и virtio-net.</div></div>
                <div class="jkw-note info" id="jkw-ids-na" style="display:none; margin-top:-8px; margin-bottom:16px"><i class="fa fa-info-circle"></i>
                    <div>Служба обнаружения вторжений недоступна на этой системе, этот пункт пропущен.</div></div>
                <div class="jkw-sec">Фильтры на входе из интернета</div>
                <div class="jkw-box">
                    <div class="jkw-row" data-b="interfaces.wan.blockbogons"><div class="ri"><i class="fa fa-filter"></i></div>
                        <div class="rl"><div class="rn">Блокировать несуществующие адреса</div>
                        <div class="rd">Трафик из диапазонов, которые не выданы ни одной сети (bogons). Почти всегда это подделка.</div></div><span class="jkw-sw"></span></div>
                    <div class="jkw-row" data-b="interfaces.wan.blockpriv"><div class="ri"><i class="fa fa-lock"></i></div>
                        <div class="rl"><div class="rn">Блокировать частные сети со стороны интернета</div>
                        <div class="rd">10/8, 172.16/12, 192.168/16 и 100.64/10. Выключите, если экран стоит за другим роутером.</div></div><span class="jkw-sw"></span></div>
                </div>
                <div class="jkw-note info" id="jkw-priv-note" style="display:none"><i class="fa fa-info-circle"></i>
                    <div>Похоже, экран получает адрес из частной сети (стоит за роутером провайдера). Блокировка частных сетей тогда может мешать, мы её выключили.</div></div>
                <div class="jkw-sec">DNS</div>
                <div class="jkw-box">
                    <div class="jkw-row" data-b="unbound.enabled"><div class="ri"><i class="fa fa-server"></i></div>
                        <div class="rl"><div class="rn">Свой DNS-резолвер</div>
                        <div class="rd">Экран сам отвечает устройствам на DNS-запросы и кэширует их (Unbound).</div></div><span class="jkw-sw"></span></div>
                    <div class="jkw-row sub" data-b="unbound.dnssec"><div class="rl"><div class="rn">Проверять подписи DNSSEC</div>
                        <div class="rd">Защищает от подмены ответов DNS.</div></div><span class="jkw-sw"></span></div>
                    <div class="jkw-row sub" data-b="unbound.dnssecstripped"><div class="rl"><div class="rn">Строгая проверка DNSSEC</div>
                        <div class="rd">Отклонять ответы подписанных зон, если подписи из них вырезаны.</div></div><span class="jkw-sw"></span></div>
                </div>
                <div class="jkw-more"><span class="tg"><i class="fa fa-chevron-right"></i> Для опытных</span>
                    <div class="bd">
                        <div class="jkw-box">
                            <div class="jkw-row" data-b="deployment_type.multiwan"><div class="rl"><div class="rn">Несколько провайдеров</div>
                                <div class="rd">Маршрутизация по источнику для двух и более подключений к интернету. С одним провайдером оставьте выключенным.</div></div><span class="jkw-sw"></span></div>
                            <div class="jkw-row" data-b="deployment_type.dhcp_dns_registration"><div class="rl"><div class="rn">Имена устройств в DNS</div>
                                <div class="rd">Устройства, получившие адрес по DHCP, доступны по имени вида <span class="jkw-mono">ноутбук.home.arpa</span>.</div></div><span class="jkw-sw"></span></div>
                            <div class="jkw-row" data-b="deployment_type.maxthreads"><div class="rl"><div class="rn">Ускорить IPsec</div>
                                <div class="rd">Обрабатывать IPsec на всех ядрах процессора. Помогает при многих одновременных VPN-потоках.</div></div><span class="jkw-sw"></span></div>
                        </div>
                        <div class="jkw-f" data-k="deployment_type.dhcp_dns_registration"><div class="err"></div></div>
                    </div>
                </div>
            </div>

            <!-- 5: review -->
            <div class="jkw-step" data-step="review">
                <div class="jkw-h"><div class="ic"><i class="fa fa-check"></i></div>
                    <div><h2>Всё готово к применению</h2><p>Проверьте настройки. После применения службы перезапустятся, это займёт около минуты.</p></div></div>
                <div class="jkw-sum" id="jkw-sum"></div>
                <div class="jkw-note warn" id="jkw-rev-move" style="display:none"><i class="fa fa-exclamation-triangle"></i><div></div></div>
            </div>

            <!-- 6: applying / done -->
            <div class="jkw-step" data-step="apply">
                <div class="jkw-h" id="jkw-apply-h"><div class="ic"><i class="fa fa-cog fa-spin"></i></div>
                    <div><h2>Применяем настройки</h2><p>Не закрывайте страницу.</p></div></div>
                <ul class="jkw-run" id="jkw-run"></ul>
                <div id="jkw-done" style="display:none"></div>
            </div>

            <div class="jkw-foot" id="jkw-foot" style="display:none">
                <button class="jkw-btn ghost" id="jkw-back"><i class="fa fa-arrow-left"></i> Назад</button>
                <span class="sp"></span>
                <span class="msg" id="jkw-msg"></span>
                <button class="jkw-btn" id="jkw-next">Далее <i class="fa fa-arrow-right"></i></button>
            </div>
        </div>
    </div>
</div>

<script>
$(function () {
    const STEPS = [
        {id: 'wan', title: 'Интернет', keys: ['interfaces.wan.', 'dns_servers', 'dnsallowoverride']},
        {id: 'lan', title: 'Локальная сеть', keys: ['interfaces.lan.', 'hostname', 'domain']},
        {id: 'access', title: 'Доступ', keys: ['password', 'password_confirm', 'timezone', 'language']},
        {id: 'protect', title: 'Защита', keys: ['unbound.', 'deployment_type.']},
        {id: 'review', title: 'Применение', keys: []}
    ];
    // Same rule sets as the "Recommended" level of the Threat Management page, and the same policy name,
    // so that page picks up what the wizard switched on.
    const IDS_FILES = ['botcc.rules', 'botcc.portgrouped.rules', 'threatview_CS_c2.rules', 'abuse.ch.feodotracker.rules',
        'abuse.ch.sslblacklist.rules', 'emerging-malware.rules', 'emerging-mobile_malware.rules', 'emerging-worm.rules',
        'emerging-coinminer.rules', 'compromised.rules', 'ciarmy.rules', 'drop.rules', 'dshield.rules',
        'emerging-exploit.rules', 'emerging-exploit_kit.rules', 'emerging-shellcode.rules', 'emerging-attack_response.rules',
        'emerging-current_events.rules', 'emerging-web_server.rules', 'emerging-web_specific_apps.rules',
        'emerging-web_client.rules', 'emerging-sql.rules', 'emerging-activex.rules', 'emerging-phishing.rules',
        'emerging-scan.rules', 'emerging-dos.rules', 'emerging-dns.rules', 'emerging-dyn_dns.rules'];
    const IDS_POLICY = 'jk-ufw: block threats';
    // server-side validation texts (gettext, English unless the system language is Russian)
    const RU = {
        'The passwords do not match.': 'Пароли не совпадают.',
        'A username is required.': 'Укажите логин.',
        'A password is required.': 'Укажите пароль.',
        'Please make sure the gateway address is reachable from the choosen subnet.': 'Шлюз должен быть в той же сети, что и адрес.',
        'Automatic DHCP server configuration is only supported for networks larger than /27.': 'Раздавать адреса можно в сети не меньше /26.',
        'When LAN is enabled, an address needs to be provided.': 'Укажите адрес экрана.',
        'To configure a DHCP server, the network interface needs to be configured.': 'Для раздачи адресов нужен включённый порт LAN.',
        'This feature requires a configured dhcp server and dns resolver configured.': 'Нужны включённые раздача адресов (шаг «Локальная сеть») и свой DNS-резолвер.',
        'Unable to enable this interface as it is not attached to a device, please assign first and run the wizard again.':
            'Этому порту не назначена сетевая карта. Назначьте её в консоли (пункт 1) и запустите мастер снова.',
        'Please specify a valid address and cidr mask to use.': 'Неверный адрес.'
    };

    const esc = (v) => $('<div/>').text(v == null ? '' : String(v)).html();
    const api = (url, data) => new Promise((resolve, reject) => {
        $.ajax({type: data === undefined ? 'GET' : 'POST', url: url, dataType: 'json', contentType: 'application/json',
            data: data === undefined ? undefined : JSON.stringify(data), timeout: 120000})
            .done((r) => resolve(r)).fail((x) => reject(new Error(x.status ? x.status + ' ' + (x.statusText || '') : 'нет связи')));
    });
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const path = (obj, p) => p.split('.').reduce((o, k) => (o == null ? undefined : o[k]), obj);
    const setPath = (obj, p, v) => {
        const ks = p.split('.');
        const last = ks.pop();
        ks.reduce((o, k) => (o[k] = o[k] || {}), obj)[last] = v;
    };
    const selKey = (node) => {
        if (node == null || typeof node !== 'object') {
            return node == null ? '' : String(node);
        }
        return Object.keys(node).find((k) => String(node[k].selected) === '1') || '';
    };
    const listVal = (node) => {
        if (node == null) {
            return '';
        }
        if (typeof node === 'object') {
            return Object.keys(node).filter((k) => k !== '' && String(node[k].selected) === '1').join(', ');
        }
        return String(node).split(',').filter(Boolean).join(', ');
    };

    /* ---------- ipv4 helpers ---------- */
    const ip2n = (ip) => {
        const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(String(ip).trim());
        if (!m || m.slice(1).some((x) => +x > 255)) {
            return null;
        }
        return ((+m[1] << 24) >>> 0) + (+m[2] << 16) + (+m[3] << 8) + (+m[4]);
    };
    const n2ip = (n) => [n >>> 24, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].join('.');
    const maskN = (bits) => (bits === 0 ? 0 : (0xffffffff << (32 - bits)) >>> 0);
    const isPrivate = (ip) => {
        const n = ip2n(ip);
        if (n === null) {
            return false;
        }
        return (n >>> 24) === 10 || (n >>> 20) === ((172 << 4) | 1) || (n >>> 16) === ((192 << 8) | 168) ||
            (n >>> 22) === ((100 << 2) | 1);
    };
    const splitCidr = (v) => {
        const p = String(v || '').split('/');
        return {ip: p[0] || '', bits: p[1] !== undefined && p[1] !== '' ? parseInt(p[1], 10) : null};
    };
    const masks = (sel, from, to, def) => {
        let h = '';
        for (let b = from; b <= to; b++) {
            h += `<option value="${b}">/${b}</option>`;
        }
        $(sel).html(h).val(String(def));
    };

    /* ---------- state ---------- */
    let W = null;             // wizard model as returned by the API
    let orig = {};            // a few values to compare against
    let ids = {mode: 'ids', available: false, rulesets: {}, policy: null, current: 'off'};
    let cur = -1;             // -1 = welcome, 0..4 = STEPS, 5 = apply
    let reached = -1;
    let busy = false;

    const b = (p) => String(path(W, p)) === '1';
    const setB = (p, on) => setPath(W, p, on ? '1' : '0');

    async function load() {
        const r = await api('/api/core/initial_setup/get');
        W = r.wizard;
        const lan = splitCidr(path(W, 'interfaces.lan.ipaddr'));
        orig.lanIp = lan.ip;
        orig.lanBits = lan.bits;
        orig.lanDisabled = b('interfaces.lan.disable');
        orig.wanType = selKey(path(W, 'interfaces.wan.ipv4_type')) || 'dhcp';
        W._wantype = orig.wanType;
        W._dns = listVal(W.dns_servers);
        W._tz = selKey(W.timezone);
        W._lang = selKey(W.language);
        try {
            const [s, rs] = await Promise.all([
                api('/api/ids/settings/get'),
                api('/api/ids/settings/list_rulesets', {current: 1, rowCount: -1, searchPhrase: ''})
            ]);
            (rs.rows || []).forEach((x) => { ids.rulesets[x.filename] = x; });
            ids.available = Object.keys(ids.rulesets).length > 0;
            const g = (s.ids || {}).general || {};
            if (String(g.enabled) === '1') {
                ids.current = selKey(g.mode) === 'netmap' ? 'ips' : 'ids';
                ids.mode = ids.current;
            }
            ids.general = g;
            try {
                const p = await api('/api/ids/settings/search_policy', {current: 1, rowCount: -1, searchPhrase: ''});
                ids.policy = (p.rows || []).find((x) => x.description === IDS_POLICY) || null;
            } catch (e) {
                ids.policy = null;
            }
        } catch (e) {
            ids.available = false;
        }
        if (!ids.available) {
            ids.mode = 'off';
        }
        fill();
    }

    /* ---------- model -> form ---------- */
    function fill() {
        const n = $('#jkw-product').text().trim();
        if (!n || n.indexOf('{') === 0 || n.indexOf('%') === 0) {
            $('#jkw-product, .jkw-pname').text('jk-ufw');
        }
        $('#f-pppoe-user').val(path(W, 'interfaces.wan.pppoe_username') || '');
        $('#f-pppoe-pass').val(path(W, 'interfaces.wan.pppoe_password') || '');
        $('#f-pppoe-prov').val(path(W, 'interfaces.wan.pppoe_provider') || '');
        const wan = splitCidr(path(W, 'interfaces.wan.ipaddr'));
        $('#f-wan-ip').val(wan.ip);
        masks('#f-wan-mask', 8, 32, wan.bits || 24);
        $('#f-wan-gw').val(path(W, 'interfaces.wan.gateway') || '');
        $('.f-dns').val(W._dns);
        $('#f-wan-dhcphost').val(path(W, 'interfaces.wan.dhcphostname') || '');
        $('#f-wan-mac').val(path(W, 'interfaces.wan.spoofmac') || '');
        $('#f-wan-mtu').val(path(W, 'interfaces.wan.mtu') || '');
        $('#f-wan-mss').val(path(W, 'interfaces.wan.mss') || '');
        $('#f-lan-ip').val(orig.lanIp || '192.168.1.1');
        masks('#f-lan-mask', 16, 30, orig.lanBits || 24);
        $('#f-hostname').val(W.hostname || '');
        $('#f-domain').val(W.domain || '');
        const opts = (node, fmt) => Object.keys(node || {}).map((k) =>
            `<option value="${esc(k)}">${esc(fmt ? fmt(k, node[k].value) : node[k].value)}</option>`).join('');
        $('#f-tz').html(opts(W.timezone, (k) => k.replace(/_/g, ' '))).val(W._tz);
        $('#f-lang').html(opts(W.language)).val(W._lang);
        renderToggles();
        renderWan();
        renderLan();
        renderIds();
    }

    /* ---------- form -> model ---------- */
    function collect() {
        setPath(W, 'interfaces.wan.pppoe_username', $('#f-pppoe-user').val().trim());
        setPath(W, 'interfaces.wan.pppoe_password', $('#f-pppoe-pass').val());
        setPath(W, 'interfaces.wan.pppoe_provider', $('#f-pppoe-prov').val().trim());
        const wip = $('#f-wan-ip').val().trim();
        setPath(W, 'interfaces.wan.ipaddr', wip ? wip + '/' + $('#f-wan-mask').val() : '');
        setPath(W, 'interfaces.wan.gateway', $('#f-wan-gw').val().trim());
        setPath(W, 'interfaces.wan.dhcphostname', $('#f-wan-dhcphost').val().trim());
        setPath(W, 'interfaces.wan.spoofmac', $('#f-wan-mac').val().trim());
        setPath(W, 'interfaces.wan.mtu', $('#f-wan-mtu').val().trim());
        setPath(W, 'interfaces.wan.mss', $('#f-wan-mss').val().trim());
        const lip = $('#f-lan-ip').val().trim();
        setPath(W, 'interfaces.lan.ipaddr', lip ? lip + '/' + $('#f-lan-mask').val() : '');
        W.hostname = $('#f-hostname').val().trim();
        W.domain = $('#f-domain').val().trim();
        W.password = $('#f-pass').val();
        W.password_confirm = $('#f-pass2').val();
        W._tz = $('#f-tz').val();
        W._lang = $('#f-lang').val();
    }

    function payload() {
        const g = (p) => { const v = path(W, p); return v == null ? '' : (typeof v === 'object' ? selKey(v) : String(v)); };
        const bool = (p) => (b(p) ? '1' : '0');
        return {wizard: {
            hostname: W.hostname, domain: W.domain, language: W._lang, timezone: W._tz,
            dns_servers: W._dns.split(/[\s,;]+/).filter(Boolean).join(','),
            dnsallowoverride: bool('dnsallowoverride'),
            unbound: {enabled: bool('unbound.enabled'), dnssec: bool('unbound.dnssec'), dnssecstripped: bool('unbound.dnssecstripped')},
            interfaces: {
                wan: {
                    disable: bool('interfaces.wan.disable'), ipv4_type: W._wantype,
                    spoofmac: g('interfaces.wan.spoofmac'), mtu: g('interfaces.wan.mtu'), mss: g('interfaces.wan.mss'),
                    ipaddr: W._wantype === 'static' ? g('interfaces.wan.ipaddr') : '',
                    gateway: W._wantype === 'static' ? g('interfaces.wan.gateway') : '',
                    dhcphostname: W._wantype === 'dhcp' ? g('interfaces.wan.dhcphostname') : '',
                    pppoe_username: g('interfaces.wan.pppoe_username'), pppoe_password: g('interfaces.wan.pppoe_password'),
                    pppoe_provider: g('interfaces.wan.pppoe_provider'),
                    blockpriv: bool('interfaces.wan.blockpriv'), blockbogons: bool('interfaces.wan.blockbogons')
                },
                lan: {ipaddr: g('interfaces.lan.ipaddr'), disable: bool('interfaces.lan.disable'),
                    configure_dhcp: bool('interfaces.lan.configure_dhcp')}
            },
            deployment_type: {multiwan: bool('deployment_type.multiwan'),
                dhcp_dns_registration: bool('deployment_type.dhcp_dns_registration'),
                maxthreads: bool('deployment_type.maxthreads')},
            password: W.password || '', password_confirm: W.password_confirm || ''
        }};
    }

    /* ---------- rendering ---------- */
    function renderToggles() {
        $('#jkw .jkw-row[data-b]').each(function () {
            const inv = $(this).data('inv') === 1;
            $(this).toggleClass('on', b($(this).data('b')) !== inv);
        });
        const unb = b('unbound.enabled');
        $('#jkw .jkw-row[data-b="unbound.dnssec"]').toggleClass('dis', !unb);
        $('#jkw .jkw-row[data-b="unbound.dnssecstripped"]').toggleClass('dis', !unb || !b('unbound.dnssec'));
    }

    function renderWan() {
        const t = W._wantype;
        $('#jkw-wantype .jkw-opt').each(function () { $(this).toggleClass('sel', $(this).data('v') === t); });
        $('.wan-pppoe').toggle(t === 'pppoe');
        $('.wan-static').toggle(t === 'static');
        $('.wan-dhcp-only').toggle(t !== 'static');
    }

    function renderLan() {
        const ipn = ip2n($('#f-lan-ip').val());
        const bits = parseInt($('#f-lan-mask').val(), 10);
        const disabled = b('interfaces.lan.disable');
        $('#f-lan-ip, #f-lan-mask').prop('disabled', disabled);
        $('#jkw .jkw-row[data-b="interfaces.lan.configure_dhcp"]').toggleClass('dis', disabled);
        if (ipn === null || isNaN(bits)) {
            $('#f-lan-net').val('');
            $('#f-lan-hosts').text('');
            $('#f-lan-range').text('Компьютеры и телефоны получат адрес автоматически.');
        } else {
            const net = (ipn & maskN(bits)) >>> 0;
            const size = Math.pow(2, 32 - bits);
            $('#f-lan-net').val(n2ip(net) + '/' + bits);
            $('#f-lan-hosts').text(`До ${(size - 2).toLocaleString('ru-RU')} устройств`);
            if (size - 2 >= 50) {
                $('#f-lan-range').html(`Устройства получат адреса <span class="jkw-mono">${n2ip(net + 41)} — ${n2ip(net + size - 11)}</span>. ` +
                    'Первые 40 адресов остаются для принтеров, серверов и других устройств с постоянным адресом.');
            } else {
                $('#f-lan-range').text('Для раздачи адресов нужна сеть /26 или больше.');
            }
        }
        const moved = !disabled && orig.lanIp && ($('#f-lan-ip').val().trim() !== orig.lanIp || bits !== orig.lanBits);
        $('#jkw-lan-move').toggle(!!moved);
    }

    function renderIds() {
        $('#jkw-ids .jkw-opt').each(function () {
            $(this).toggleClass('sel', $(this).data('v') === ids.mode);
            if (!ids.available && $(this).data('v') !== 'off') {
                $(this).css({opacity: .4, pointerEvents: 'none'});
            }
        });
        $('#jkw-ips-note').toggle(ids.mode === 'ips');
        $('#jkw-ids-na').toggle(!ids.available);
    }

    function renderProg() {
        $('#jkw-prog').css('visibility', cur >= 0 ? 'visible' : 'hidden').html(STEPS.map((s, i) => {
            const cls = i === cur ? 'cur' : (i < cur || i <= reached ? 'done' : '');
            return `<div class="st ${cls}" data-i="${i}"><div class="bar"></div><div class="lb"><i>${i + 1}</i>${esc(s.title)}</div></div>`;
        }).join(''));
    }

    function show(i) {
        cur = i;
        reached = Math.max(reached, i);
        const id = i < 0 ? 'welcome' : (i < STEPS.length ? STEPS[i].id : 'apply');
        $('#jkw-loading').hide();
        $('#jkw .jkw-step').removeClass('on').filter(`[data-step="${id}"]`).addClass('on');
        $('#jkw-foot').toggle(i >= 0 && i < STEPS.length);
        $('#jkw-back').css('visibility', 'visible');
        $('#jkw-msg').text('');
        $('#jkw-next').prop('disabled', false).html(i === STEPS.length - 1
            ? '<i class="fa fa-check"></i> Применить' : 'Далее <i class="fa fa-arrow-right"></i>');
        if (id === 'review') {
            renderSummary();
        }
        if (id === 'wan') {
            renderWan();
        }
        renderProg();
        $('#jkw').scrollTop(0);
        const first = $(`#jkw .jkw-step[data-step="${id}"] input.jkw-in:visible:enabled`).first();
        if (first.length && id !== 'welcome' && id !== 'review' && !first.val()) {
            first.trigger('focus');
        }
    }

    function clearErrors() {
        $('#jkw .jkw-f').removeClass('bad').find('.err').text('');
    }

    function showErrors(validations, step) {
        let shown = 0;
        Object.entries(validations || {}).forEach(([k, msg]) => {
            const key = k.replace(/^wizard\./, '');
            if (step && !step.keys.some((p) => key === p || (p.endsWith('.') && key.startsWith(p)))) {
                return;
            }
            const text = (Array.isArray(msg) ? msg : [msg]).map((m) => RU[m] || m).join(' ');
            let f = $(`#jkw .jkw-step[data-step="${step ? step.id : ''}"] .jkw-f[data-k="${key}"]`).filter(function () {
                return $(this).is(':visible') || $(this).closest('.jkw-more').length > 0;
            }).first();
            if (!f.length) {
                f = $(`#jkw .jkw-f[data-k="${key}"]`).first();
            }
            if (f.length) {
                f.addClass('bad').find('.err').text(text);
                f.closest('.jkw-more').addClass('open');
            }
            shown++;
        });
        return shown;
    }

    /* ---------- client checks that the API cannot give nicely ---------- */
    function localCheck(step) {
        const errs = {};
        if (step.id === 'wan' && W._wantype === 'static') {
            if (ip2n($('#f-wan-ip').val()) === null) {
                errs['interfaces.wan.ipaddr'] = 'Введите адрес вида 203.0.113.10.';
            }
            if ($('#f-wan-gw').val().trim() && ip2n($('#f-wan-gw').val()) === null) {
                errs['interfaces.wan.gateway'] = 'Введите адрес вида 203.0.113.1.';
            }
        }
        if (step.id === 'lan' && !b('interfaces.lan.disable')) {
            const n = ip2n($('#f-lan-ip').val());
            const bits = parseInt($('#f-lan-mask').val(), 10);
            if (n === null) {
                errs['interfaces.lan.ipaddr'] = 'Введите адрес вида 192.168.1.1.';
            } else if (n === ((n & maskN(bits)) >>> 0) || n === (((n & maskN(bits)) | ~maskN(bits)) >>> 0)) {
                errs['interfaces.lan.ipaddr'] = 'Это адрес сети или широковещательный, выберите другой, например ' +
                    n2ip(((n & maskN(bits)) >>> 0) + 1) + '.';
            }
            if (W._wantype === 'static' && n !== null && ip2n($('#f-wan-ip').val()) !== null) {
                const wb = parseInt($('#f-wan-mask').val(), 10);
                const m = maskN(Math.min(bits, wb));
                if (((n & m) >>> 0) === ((ip2n($('#f-wan-ip').val()) & m) >>> 0)) {
                    errs['interfaces.lan.ipaddr'] = 'Локальная сеть пересекается с сетью провайдера, выберите другую, например 192.168.10.1.';
                }
            }
        }
        if (step.id === 'access') {
            if (W.password !== W.password_confirm) {
                errs.password_confirm = 'Пароли не совпадают.';
            } else if (W.password && W.password.length < 8) {
                errs.password = 'Не меньше 8 символов.';
            }
        }
        return errs;
    }

    async function next() {
        if (busy) {
            return;
        }
        const step = STEPS[cur];
        collect();
        clearErrors();
        const local = localCheck(step);
        if (Object.keys(local).length) {
            showErrors(local, step);
            return;
        }
        if (step.id === 'review') {
            return applyAll();
        }
        busy = true;
        $('#jkw-next').prop('disabled', true);
        $('#jkw-msg').html('<i class="fa fa-spinner fa-pulse"></i> Проверка…');
        try {
            const r = await api('/api/core/initial_setup/set', payload());
            const failed = r.result !== 'saved' ? showErrors(r.validations, step) : 0;
            busy = false;
            if (failed) {
                $('#jkw-next').prop('disabled', false);
                $('#jkw-msg').text('Исправьте отмеченные поля.');
                return;
            }
            if (step.id === 'lan') {
                autoProtect();
            }
            show(cur + 1);
        } catch (e) {
            busy = false;
            $('#jkw-next').prop('disabled', false);
            $('#jkw-msg').html(`<span style="color:#ff3b47">Не удалось проверить: ${esc(e.message)}</span>`);
        }
    }

    // A WAN address in a private range means another router sits in front: blocking private nets would cut it off.
    let privAuto = false;
    function autoProtect() {
        if (privAuto) {
            return;
        }
        privAuto = true;
        // only meaningful for static and DHCP: with PPPoE the public address comes from the tunnel
        const wanIp = W._wantype === 'static' ? $('#f-wan-ip').val().trim() : (W._wantype === 'dhcp' ? (W._wanCurrentIp || '') : '');
        if (wanIp && isPrivate(wanIp) && b('interfaces.wan.blockpriv')) {
            setB('interfaces.wan.blockpriv', false);
            renderToggles();
            $('#jkw-priv-note').show();
        }
    }

    function kv(k, v, cls) {
        return `<div class="jkw-kv"><span>${esc(k)}</span><span class="${cls || ''}">${v}</span></div>`;
    }

    function renderSummary() {
        const t = W._wantype;
        const yes = (on) => (on ? '<span class="ok">включено</span>' : '<span class="off">выключено</span>');
        const lanOff = b('interfaces.lan.disable');
        const tName = {dhcp: 'Автоматически (DHCP)', pppoe: 'PPPoE', static: 'Статический IP'}[t];
        let wan = kv('Тип', esc(tName));
        if (t === 'pppoe') {
            wan += kv('Логин', esc(path(W, 'interfaces.wan.pppoe_username')));
        } else if (t === 'static') {
            wan += kv('Адрес', `<span class="jkw-mono">${esc(path(W, 'interfaces.wan.ipaddr'))}</span>`);
            wan += kv('Шлюз', `<span class="jkw-mono">${esc(path(W, 'interfaces.wan.gateway') || 'нет')}</span>`);
        }
        wan += kv('DNS', W._dns ? `<span class="jkw-mono">${esc(W._dns)}</span>` : 'от провайдера');
        let lan = lanOff ? kv('Порт LAN', '<span class="off">не используется</span>')
            : kv('Адрес экрана', `<span class="jkw-mono">${esc(path(W, 'interfaces.lan.ipaddr'))}</span>`) +
              kv('Раздача адресов', yes(b('interfaces.lan.configure_dhcp')));
        lan += kv('Имя', `<span class="jkw-mono">${esc(W.hostname + (W.domain ? '.' + W.domain : ''))}</span>`);
        const acc = kv('Пароль root', W.password ? '<span class="ok">будет изменён</span>' : '<span class="off">без изменений</span>') +
            kv('Часовой пояс', esc(String(W._tz).replace(/_/g, ' '))) +
            kv('Язык', esc(path(W, 'language.' + W._lang + '.value') || W._lang));
        const idsName = {off: '<span class="off">выключена</span>', ids: '<span class="ok">обнаружение</span>', ips: '<span class="ok">блокировка</span>'};
        const prot = kv('Защита от угроз', idsName[ids.mode]) +
            kv('Несуществующие адреса', yes(b('interfaces.wan.blockbogons'))) +
            kv('Частные сети из интернета', yes(b('interfaces.wan.blockpriv'))) +
            kv('DNS-резолвер', b('unbound.enabled') ? (b('unbound.dnssec') ? '<span class="ok">с DNSSEC</span>' : yes(true)) : yes(false));
        const box = (i, icon, title, body) => `<div><h4><i class="fa ${icon}"></i>${esc(title)}<a data-go="${i}">Изменить</a></h4>${body}</div>`;
        $('#jkw-sum').html(box(0, 'fa-globe', 'Интернет', wan) + box(1, 'fa-sitemap', 'Локальная сеть', lan) +
            box(2, 'fa-key', 'Доступ', acc) + box(3, 'fa-shield', 'Защита', prot));
        const nu = newUrl();
        $('#jkw-rev-move').toggle(!!nu).find('div').html(nu
            ? `После применения панель будет доступна по адресу <b class="jkw-mono">${esc(nu)}</b>. Если компьютер получает адрес по DHCP, переподключите его к сети.`
            : '');
    }

    // where the GUI lives after apply, when the browser talks to us over the LAN address that changes
    function newUrl() {
        if (b('interfaces.lan.disable') || !orig.lanIp) {
            return null;
        }
        const ip = splitCidr(path(W, 'interfaces.lan.ipaddr')).ip;
        if (ip === orig.lanIp || location.hostname !== orig.lanIp) {
            return null;
        }
        return location.protocol + '//' + ip + (location.port ? ':' + location.port : '') + '/';
    }

    /* ---------- apply ---------- */
    function runList(list) {
        $('#jkw-run').html(list.map((s) => {
            const ic = {done: 'fa-check', run: 'fa-spinner fa-pulse', err: 'fa-times', skip: 'fa-minus'}[s.st] || 'fa-circle-o';
            return `<li class="${s.st || ''}"><i class="fa ${ic}"></i><span>${esc(s.t)}</span></li>`;
        }).join(''));
    }

    async function idsApply() {
        const general = {enabled: ids.mode === 'off' ? '0' : '1', mode: ids.mode === 'ips' ? 'netmap' : 'pcap'};
        const ifs = selKeysOf(ids.general && ids.general.interfaces);
        if (!ifs.length) {
            general.interfaces = 'wan';
        }
        const r = await api('/api/ids/settings/set', {ids: {general: general}});
        if (r.result !== 'saved') {
            throw new Error(Object.values(r.validations || {}).join(' ') || 'настройки не сохранены');
        }
        if (ids.mode !== 'off') {
            const on = IDS_FILES.filter((f) => ids.rulesets[f] && String(ids.rulesets[f].enabled) !== '1');
            if (on.length) {
                await api('/api/ids/settings/toggle_ruleset/' + on.join(',') + '/1', {});
            }
        }
        const pol = {enabled: ids.mode === 'ips' ? '1' : '0', prio: '0', action: 'alert', rulesets: '', content: '',
            new_action: 'drop', description: IDS_POLICY};
        if (ids.policy) {
            await api('/api/ids/settings/set_policy/' + ids.policy.uuid, {policy: pol});
        } else if (ids.mode === 'ips') {
            await api('/api/ids/settings/add_policy', {policy: pol});
        }
        await api('/api/ids/service/reconfigure', {});
    }
    function selKeysOf(node) {
        if (!node) {
            return [];
        }
        if (typeof node === 'string') {
            return node.split(',').filter(Boolean);
        }
        return Object.keys(node).filter((k) => String(node[k].selected) === '1');
    }

    async function applyAll() {
        busy = true;
        const nu = newUrl();
        const idsTouch = ids.available && (ids.mode !== ids.current || ids.mode !== 'off');
        let plan = [];
        if (idsTouch) {
            plan.push({id: 'ids', t: ids.mode === 'off' ? 'Выключение защиты от угроз' : 'Настройка защиты от угроз'});
        }
        plan.push({id: 'cfg', t: 'Сохранение настроек'});
        plan.push({id: 'reload', t: 'Перезапуск сетевых служб'});
        if (idsTouch && ids.mode !== 'off' && !nu) {
            plan.push({id: 'rules', t: 'Загрузка сигнатур угроз (может занять пару минут)'});
        }
        show(STEPS.length);
        $('#jkw .jkw-top .r').css('visibility', 'hidden');
        runList(plan);
        const step = async (id, fn) => {
            const s = plan.find((x) => x.id === id);
            s.st = 'run';
            runList(plan);
            try {
                await fn();
                s.st = 'done';
            } catch (e) {
                s.st = 'err';
                s.t += ': ' + e.message;
                runList(plan);
                throw e;
            }
            runList(plan);
        };
        let idsWarn = '';
        try {
            if (idsTouch) {
                // done first: if the LAN address changes, the browser loses us right after the next call
                try {
                    await step('ids', idsApply);
                } catch (e) {
                    idsWarn = 'Защиту от угроз включить не удалось (' + e.message + '). Попробуйте на странице «Защита от угроз».';
                    plan = plan.filter((x) => x.id !== 'rules');
                }
            }
            await step('cfg', async () => {
                const r = await api('/api/core/initial_setup/configure', payload());
                if (r.result !== 'saved') {
                    const err = new Error('проверьте шаги, отмеченные красным');
                    err.validations = r.validations;
                    throw err;
                }
            });
            await step('reload', async () => {
                if (nu) {
                    await sleep(1500);
                    return;
                }
                // services reload in the background; wait until the GUI answers again
                await sleep(4000);
                for (let i = 0; i < 30; i++) {
                    try {
                        await api('/api/core/initial_setup/get');
                        return;
                    } catch (e) {
                        await sleep(2000);
                    }
                }
            });
            if (plan.find((x) => x.id === 'rules')) {
                try {
                    await step('rules', async () => { await api('/api/ids/service/update_rules', {}); });
                } catch (e) {
                    idsWarn = 'Сигнатуры не скачались (' + e.message + '). Экран попробует снова, или нажмите «Обновить» на странице «Защита от угроз».';
                }
            }
            done(nu, idsWarn);
        } catch (e) {
            busy = false;
            $('#jkw .jkw-top .r').css('visibility', 'visible');
            $('#jkw-apply-h .ic').html('<i class="fa fa-exclamation"></i>');
            $('#jkw-apply-h h2').text('Не всё получилось');
            $('#jkw-apply-h p').text('Настройки не применены. Исправьте ошибку и попробуйте ещё раз.');
            $('#jkw-done').show().html('<div class="jkw-foot" style="border:0;padding:0"><button class="jkw-btn ghost" id="jkw-retry">' +
                '<i class="fa fa-arrow-left"></i> Вернуться к настройкам</button></div>');
            $('#jkw-retry').on('click', function () {
                let first = STEPS.length - 1;
                if (e.validations) {
                    STEPS.forEach((s, i) => {
                        if (Object.keys(e.validations).some((k) => s.keys.some((p) => k.replace(/^wizard\./, '').startsWith(p)))) {
                            first = Math.min(first, i);
                        }
                    });
                }
                show(first);
                if (e.validations) {
                    showErrors(e.validations, STEPS[first]);
                }
            });
        }
    }

    function done(nu, warn) {
        busy = false;
        $('#jkw-prog').css('visibility', 'hidden');
        $('#jkw-apply-h').hide();
        const url = nu || '/ui/core/dashboard';
        $('#jkw-done').show().html(
            '<div class="jkw-done"><div class="okc"><i class="fa fa-check"></i></div>' +
            `<h2>${esc($('#jkw-product').text())} настроен</h2>` +
            (nu ? '<p>Адрес экрана изменился. Откройте панель по новому адресу. Если страница не открывается, переподключите компьютер к сети.</p>' +
                    `<div class="addr">${esc(nu)}</div>`
                : '<p>Сеть работает с новыми настройками. На панели видно трафик, устройства и угрозы.</p>') +
            (warn ? `<div class="jkw-note warn" style="text-align:left"><i class="fa fa-exclamation-triangle"></i><div>${esc(warn)}</div></div>` : '') +
            `<div style="margin-top:26px"><a class="jkw-btn big" href="${esc(url)}" style="text-decoration:none">Открыть панель &nbsp;<i class="fa fa-arrow-right"></i></a></div>` +
            '<div style="margin-top:14px;color:#8d8d98;font-size:12.5px">Обновления: <a href="/ui/core/firmware#checkupdate">System › Firmware</a></div></div>');
    }

    async function skip() {
        if (busy) {
            return;
        }
        try {
            await api('/api/core/initial_setup/abort', {});
        } catch (e) { /* nothing to undo */ }
        window.location = '/ui/core/dashboard';
    }

    /* ---------- events ---------- */
    $('#jkw-start').on('click', () => show(0));
    $('#jkw-skip, #jkw-skip2').on('click', skip);
    $('#jkw-next').on('click', next);
    $('#jkw-back').on('click', () => { if (!busy) { collect(); clearErrors(); show(cur - 1); } });
    $('#jkw-prog').on('click', '.st.done', function () { if (!busy) { collect(); clearErrors(); show(+$(this).data('i')); } });
    $('#jkw-sum').on('click', 'a[data-go]', function () { show(+$(this).data('go')); });
    $('#jkw').on('keydown', 'input.jkw-in', function (e) { if (e.key === 'Enter') { e.preventDefault(); next(); } });
    $('#jkw-wantype').on('click', '.jkw-opt', function () {
        W._wantype = $(this).data('v');
        clearErrors();
        renderWan();
    });
    $('#jkw-ids').on('click', '.jkw-opt', function () {
        ids.mode = $(this).data('v');
        renderIds();
    });
    $('#jkw').on('click', '.jkw-row[data-b]', function () {
        const p = $(this).data('b');
        setB(p, !b(p));
        if (p === 'unbound.enabled' && !b(p)) {
            setB('deployment_type.dhcp_dns_registration', false);
        }
        renderToggles();
        if (p === 'interfaces.lan.disable') {
            if (b(p)) {
                setB('interfaces.lan.configure_dhcp', false);
                renderToggles();
            }
            renderLan();
        }
    });
    $('#jkw').on('click', '.jkw-more > .tg', function () { $(this).parent().toggleClass('open'); });
    $('#jkw').on('click', '.jkw-pw .eye', function () {
        const i = $(this).siblings('input');
        const show = i.attr('type') === 'password';
        $(this).closest('.jkw-step').find('.jkw-pw input').attr('type', show ? 'text' : 'password');
        $(this).closest('.jkw-step').find('.jkw-pw .eye .fa').toggleClass('fa-eye', !show).toggleClass('fa-eye-slash', show);
    });
    $('#f-lan-ip, #f-lan-mask').on('input change', renderLan);
    $('.f-dns').on('input', function () { W._dns = $(this).val(); $('.f-dns').not(this).val(W._dns); });
    $('#f-pass').on('input', function () {
        const v = $(this).val();
        let s = 0;
        if (v.length >= 8) { s++; }
        if (v.length >= 12) { s++; }
        if (/[a-zа-я]/.test(v) && /[A-ZА-Я]/.test(v)) { s++; }
        if (/\d/.test(v) && /[^\w]/.test(v)) { s++; }
        if (v && v.length < 8) { s = 0; }
        const col = ['#e5202e', '#e5202e', '#f5a524', '#84cc16', '#22c55e'][s];
        $('#jkw-meter i').each(function (i) { $(this).css('background', v && i < Math.max(s, 1) ? col : ''); });
        $('#jkw-meter-l').text(!v ? 'Оставьте пустым, чтобы не менять'
            : ['Слишком короткий', 'Слабый', 'Средний', 'Хороший', 'Надёжный'][s]);
    });

    load().then(() => {
        // what the WAN currently has, to guess whether a router sits in front
        api('/api/interfaces/overview/interfaces_info').then((r) => {
            const w = (r.rows || []).find((x) => x.identifier === 'wan');
            const a = w && (w.addr4 || (w.ipv4 && w.ipv4[0] && w.ipv4[0].ipaddr));
            W._wanCurrentIp = a ? String(a).split('/')[0] : '';
        }).catch(() => {});
        show(-1);
    }).catch((e) => {
        $('#jkw-loading').html(`<i class="fa fa-exclamation-triangle" style="color:#ff3b47"></i>&nbsp; Не удалось загрузить настройки: ${esc(e.message)}.` +
            ' <a href="/ui/core/initial_setup?classic">Открыть классический мастер</a>');
    });
});
</script>
