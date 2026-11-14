# Сборка и сопровождение jk-ufw

Этот репозиторий уже переименован: название, логотипы, тема `jkufw` и виджеты дашборда лежат в исходниках.
Ниже: как собрать установочный образ, как ставить изменения на работающую систему и как забирать исправления
из основного проекта.

## 1. Установочный образ

Нужна машина или виртуалка на FreeBSD 15.1 (amd64): от 4 ядер, 8 ГБ памяти и 60 ГБ диска.

```sh
pkg install -y git
git clone -b stable/26.7 https://github.com/bfg10kkk/JK-UFW.git /usr/core   # этот репозиторий
git -C /usr/core fetch https://github.com/opnsense/core.git 'refs/tags/26.7*:refs/tags/26.7*'   # метки версий
git clone https://github.com/opnsense/tools /usr/tools                       # сборочные инструменты
cd /usr/tools
make update                         # скачает src, ports, plugins; /usr/core уже ваш и останется вашим
make prefetch-base,kernel,packages  # готовые наборы с зеркала, иначе сборка всего займёт сутки
make core-opnsense                  # пересобрать пакет core из этого репозитория
make dvd                            # или vm / serial / vga
make print-IMAGESDIR                # где лежит готовый образ
```

- Метки версий (`26.7.x`) нужны, чтобы сборка вычислила номер версии; без них `make` остановится с ошибкой
  «Did not find appropriate tag». Если метки уже есть в этом репозитории, вторая строка просто ничего не скачает.
- `make core-opnsense` обязателен: в скачанном наборе пакетов core уже помечен как собранный, и без этой
  команды в образ попадёт не переименованный core. Имя цели менять нельзя, это внутреннее имя пакета.
- Не передавайте `NAME=jk-ufw`: от него зависит имя главного пакета, и сборка его не найдёт.
  Готовый файл образа просто переименуйте.
- Если `make` пишет, что версия pkg не совпадает, выполните команду, которую он подсказывает
  (`make -C /usr/ports/opnsense/pkg clean all reinstall`), и повторите.

## 2. Изменения на работающей системе

На установленной системе (по SSH, пункт 8 «Shell»):

```sh
pkg install -y git
git clone -b stable/26.7 https://github.com/bfg10kkk/JK-UFW.git /root/jk-ufw
git -C /root/jk-ufw fetch https://github.com/opnsense/core.git 'refs/tags/26.7*:refs/tags/26.7*'
cd /root/jk-ufw && make upgrade     # собрать пакет из репозитория и сразу установить
```

Если нужно поменять только внешний вид на уже установленной системе, хватит пакета темы:
`sh jk-ufw/install.sh` (подробности в [jk-ufw/README.md](../README.md)).

## 3. Исправления из основного проекта

```sh
git remote add upstream https://github.com/opnsense/core.git   # один раз
git fetch upstream stable/26.7
git merge upstream/stable/26.7
sh jk-ufw/fork/rebrand-core.sh .      # заново применить название к новым и изменённым файлам
git add -A && git commit -m "Merge upstream, reapply jk-ufw branding" && git push
```

Если при слиянии конфликт в файле, который трогает скрипт (например `Mk/version.mk` или `README.md`),
возьмите версию основного проекта (`git checkout --theirs <файл>`), запустите скрипт и закоммитьте.

## 4. Скрипт переименования

`jk-ufw/fork/rebrand-core.sh` можно запускать сколько угодно раз. Настройки в начале скрипта:
`PRODUCT` (название), `WWW` (сайт проекта), `HOLDER` (имя в подвале), `PKGSITE` (свой сервер пакетов),
`CRASHURL` (свой сервер отчётов о сбоях; пока он пуст, отчёты никуда не отправляются, а показываются на странице
System › Firmware › Reporter, чтобы их можно было приложить к issue).
Тему и виджеты он берёт из `jk-ufw/src`, логотипы из `jk-ufw/assets`, документы репозитория из `jk-ufw/fork/repo`.

Что он не трогает и почему:
- **LICENSE, шапки с копирайтом в исходниках и страница Lobby › License.** Лицензия BSD-2-Clause разрешает
  форк, изменения и продажу, но требует сохранять уведомления об авторских правах в исходниках и в документации
  к сборкам. Если их убрать, распространять сборки будет нельзя.
- **Внутренние имена:** пространства имён PHP, каталог `/usr/local/opnsense`, разделы конфигурации, имя пакета,
  адреса зеркал. В интерфейсе их не видно, а переименование сломает систему и слияние с основным проектом.

## 5. Обновления

Пока нет своего сервера пакетов, система берёт обновления с зеркала основного проекта, и обновление пакета
core вернёт старое название в интерфейсе. Поэтому обновляйтесь пересборкой (раздел 1 или 2) или поднимите
свой сервер пакетов со своим ключом подписи и укажите его в `PKGSITE`.

## 6. Все новые функции сразу

Семь страниц, мастер настройки и виджеты из разделов 7–14 ставятся на работающий экран одной командой (под root),
без пересборки образа:

```sh
fetch -o /tmp/try-all.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-all.sh
sh /tmp/try-all.sh                 # или: sh /tmp/try-all.sh <ветка>
sh /tmp/try-all.sh --remove        # убрать всё
```

Скрипт по очереди запускает `try-*.sh` из `jk-ufw/features/`, каждый можно запускать и отдельно.
Обновление core (System › Firmware) перезапишет эти файлы, после него запустите скрипт ещё раз.

## 7. Защита от угроз (IDS/IPS)

Страница **Services › Intrusion Detection › Threat Management** (`/ui/ids/threats`) и виджет дашборда
«jk-ufw: Защита от угроз (IPS)». Это надстройка над встроенным Suricata: режим (выкл / IDS / IPS), интерфейсы,
уровень защиты и категории правил ET open и abuse.ch на одном экране. Режим IPS включает netmap и одну политику
`jk-ufw: block threats`, которая переводит все сработавшие правила включённых наборов из «alert» в «drop».
Старая страница с полными настройками осталась на месте, кнопка «Расширенные».

Файлы: `src/opnsense/mvc/app/controllers/OPNsense/IDS/ThreatsController.php`,
`src/opnsense/mvc/app/views/OPNsense/IDS/threats.volt`, `src/opnsense/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml`
(пункт меню в отдельном файле, чтобы не конфликтовать с основным проектом), `src/opnsense/www/js/widgets/JkUfwThreats.js`.

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-ids.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-ids.sh
sh /tmp/try-ids.sh                 # или: sh /tmp/try-ids.sh <ветка>
sh /tmp/try-ids.sh --remove        # убрать
```

Для IPS отключите аппаратную разгрузку (Interfaces › Settings: CRC, TSO, LRO) и перезагрузитесь. В VirtualBox
подходят адаптеры Intel PRO/1000 и virtio-net.

## 8. Устройства в сети

Страница **Lobby › Devices** (`/ui/jkufw/devices`), в стиле раздела Clients из UniFi. Список собирается из таблиц
ARP и NDP, аренд Kea и Dnsmasq и Host Discovery (если включён): имя, производитель по MAC, адреса, сеть, аренда,
когда устройство впервые и последний раз замечено. Скорость скачивания и отдачи по каждому устройству берётся из
iftop на локальных интерфейсах раз в 10 секунд. Виджет дашборда «jk-ufw: Устройства» ведёт на эту страницу.

В один клик:
- **Заблокировать.** MAC и текущие IP устройства попадают в псевдонимы `jkufw_block_mac` и `jkufw_block_ip`,
  одно плавающее правило `jk-ufw: blocked devices` (создаётся при первой блокировке) закрывает им всё, кроме
  обращений к самому экрану (DNS, DHCP, веб-интерфейс). Открытые соединения устройства сбрасываются.
- **Ограничить скорость.** Для устройства создаются два канала шейпера `jk-ufw limit <MAC> down|up` и два правила
  на его локальном интерфейсе. Если устройство потом получит другой IP, нажмите «Изменить», чтобы обновить правила.

Файлы: `src/opnsense/mvc/app/controllers/OPNsense/JkUfw/DevicesController.php`,
`src/opnsense/mvc/app/views/OPNsense/JkUfw/devices.volt`, `src/opnsense/mvc/app/models/OPNsense/JkUfw/ACL/ACL.xml`,
`src/opnsense/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml`.

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-devices.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-devices.sh
sh /tmp/try-devices.sh                 # или: sh /tmp/try-devices.sh <ветка>
sh /tmp/try-devices.sh --remove        # убрать
```

## 9. VPN для удалённого доступа (WireGuard + QR-код)

Страница **VPN › WireGuard › Remote Access** (`/ui/wireguard/remote`). Надстройка над встроенным WireGuard:
кнопка «Включить VPN» создаёт сервер `jkufw_vpn` (сеть 10.66.0.0/24, UDP 51820), открывает порт на WAN,
разрешает трафик клиентов (правила `jk-ufw VPN: …` на группе WireGuard) и добавляет исходящий NAT для выхода
в интернет. Если исходящий NAT был в режиме «автоматический», он переключается на «гибридный»: автоматические
правила остаются, к ним добавляется одно наше. Дальше «Добавить устройство» создаёт ключи и показывает QR-код
для приложения WireGuard и файл `.conf` для компьютера. Устройства можно отключать и удалять, у каждого видно,
в сети ли оно и сколько трафика прошло. Сервер и устройства обычные, их видно и на старой странице
(кнопка «Расширенные»).

QR-код рисует `qrcode.js` (MIT, Kazuhiko Arase), он уже входит в core, отдельная библиотека не нужна.

Если экран стоит за другим роутером (WAN с адресом 192.168.x.x, как в VirtualBox), страница об этом
предупредит: на том роутере нужно пробросить UDP 51820 на экран и указать внешний IP или имя DDNS.

Файлы: `src/opnsense/mvc/app/controllers/OPNsense/Wireguard/RemoteController.php`,
`src/opnsense/mvc/app/views/OPNsense/Wireguard/remote.volt`, пункт меню в
`src/opnsense/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml`.

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-vpn.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-vpn.sh
sh /tmp/try-vpn.sh                 # или: sh /tmp/try-vpn.sh <ветка>
sh /tmp/try-vpn.sh --remove        # убрать страницу (сервер и правила остаются)
```

## 10. Блокировка стран (карта)

Страница **Firewall › Country Blocking** (`/ui/firewall/geoblock`) и виджет дашборда «jk-ufw: Блокировка стран».
Страны выбираются кликом по карте мира или в списке по регионам, направление: входящие, исходящие или в обе стороны.
Под капотом это обычные средства: GeoIP-алиас `jkufw_geoblock` и два плавающих правила блокировки
`jk-ufw: geoblock in` / `jk-ufw: geoblock out` (видны в Firewall › Rules, пишут в журнал).

Нужна база MaxMind GeoLite2: бесплатная регистрация на maxmind.com, ключ вставляется прямо на странице,
база скачивается сразу и дальше обновляется сама. Свой адрес базы тоже можно вставить вместо ключа.

Файлы: `src/opnsense/mvc/app/controllers/OPNsense/Firewall/GeoblockController.php`,
`src/opnsense/mvc/app/views/OPNsense/Firewall/geoblock.volt`, `src/opnsense/www/js/jkufw-worldmap.js`
(контуры стран Natural Earth 1:110m, общественное достояние), `src/opnsense/www/js/widgets/JkUfwGeoblock.js`,
`src/opnsense/mvc/app/models/OPNsense/JkUfw/{Menu/Menu.xml,ACL/ACL.xml}`.

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-geoblock.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-geoblock.sh
sh /tmp/try-geoblock.sh                 # или: sh /tmp/try-geoblock.sh <ветка>
sh /tmp/try-geoblock.sh --remove        # убрать
```

## 11. Фильтр контента и родительский контроль

Страница **Firewall › Content Filter** (`/ui/jkufw/parental`) и виджет дашборда «jk-ufw: Родительский контроль».

- **Фильтрация** — надстройка над списками блокировки Unbound DNS: уровни «Базовый / Семейный / Строгий» и категории
  (реклама, мошенники, 18+, казино, обход фильтра, соцсети, пиратство), свои списки «всегда блокировать / разрешать»,
  профили для групп устройств по IP (в Unbound побеждает самый точный профиль), безопасный поиск,
  запрет сторонних DNS (порты 53 и 853 только к роутеру), статистика и проверка сайта.
- **Расписание и пауза** — модель `OPNsense/JkUfw/Parental`. При сохранении для каждого устройства создаются
  псевдоним `jkufw_<id>` (MAC или IP), расписание `jkufw_<id>` (часы, когда интернет разрешён) и два плавающих правила
  с пометкой `[jk-ufw]`: pass по расписанию и reject после него. Когда расписание заканчивается, OPNsense убирает pass
  и сбрасывает его соединения; при паузе соединения устройства сбрасываются сразу. Расписание проверяется кроном
  каждые 15 минут. Эти объекты пересоздаются при каждом сохранении, руками их не меняйте.

Файлы: `controllers/OPNsense/JkUfw/{ParentalController.php,Api/ParentalController.php}`,
`models/OPNsense/JkUfw/{Parental.xml,Parental.php,ACL/ACL.xml,Menu/Menu.xml}`, `views/OPNsense/JkUfw/parental.volt`,
`www/js/widgets/JkUfwParental.js`.

Попробовать на работающем экране (под root):

```sh
fetch -o /tmp/try-parental.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-parental.sh
sh /tmp/try-parental.sh            # или: sh /tmp/try-parental.sh <ветка>
sh /tmp/try-parental.sh --remove   # убрать (сначала удалите устройства на странице)
```

Фильтр работает, только если включён Unbound и устройства используют роутер как DNS (по умолчанию так и есть).

## 12. Уведомления в Telegram

Страница **System › Settings › Notifications** (`/ui/jkufw/notify`): угрозы из IDS/IPS, пропадание и
возврат интернета, входы в веб-интерфейс и неудачные попытки. Как получить токен бота, настроить и проверить:
[jk-ufw/features/notify.md](../features/notify.md).

## 13. Гостевая сеть

Страница **Services › Captive Portal › Guest Network** (`/ui/captiveportal/guest`) и виджет дашборда
«jk-ufw: Гостевая сеть». Один экран вместо пяти разделов: новая VLAN на существующем порту (или свободный порт,
или готовый интерфейс), адрес шлюза, DHCP через Dnsmasq, изоляция от локальной сети, страница входа (без пароля,
по ваучеру или по учётной записи, с правилами пользования), скорость на одно устройство, длительность сеанса и
список подключённых гостей с кнопкой «Отключить».

Что создаётся (всё через штатные API, найти можно по имени `jk-ufw guest`):
- VLAN и интерфейс `GUEST` со статическим адресом;
- диапазон DHCP в Dnsmasq (если служба включена; иначе DHCP настраивается вручную);
- псевдоним `jkufw_private` (частные сети) и три правила на интерфейсе: запрет к самому экрану, запрет к частным
  сетям, разрешение в интернет. DNS и сама страница входа разрешены автоматически правилами портала;
- два канала шейпера с маской по адресу (у каждого устройства своя полоса) и два правила к ним;
- зона Captive Portal с шаблоном `jkufw_guest`. В шаблоне лежит только `jkufw.json` с текстами страницы, а сама
  страница входа (`src/opnsense/scripts/captiveportal/htdocs_default`) общая для всех зон и обновляется вместе с core.

Выключатель «Включена» отключает зону и правило доступа в интернет: гости остаются в своей сети, но без интернета.
Кнопка «Удалить гостевую сеть» убирает всё перечисленное, кроме псевдонима.

Файлы: `src/opnsense/mvc/app/controllers/OPNsense/CaptivePortal/GuestController.php`,
`src/opnsense/mvc/app/views/OPNsense/CaptivePortal/guest.volt`, `src/opnsense/mvc/app/models/OPNsense/JkUfw/Menu/Menu.xml`,
`src/opnsense/www/js/widgets/JkUfwGuest.js`, страница входа в `jk-ufw/src/opnsense/scripts/captiveportal/htdocs_default`
(скрипт переименования копирует её в core).

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-guest.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-guest.sh
sh /tmp/try-guest.sh                 # или: sh /tmp/try-guest.sh <ветка>
sh /tmp/try-guest.sh --remove        # убрать
```

В VirtualBox для проверки удобнее «Свободный порт»: добавьте виртуальной машине третий адаптер (Internal Network)
и подключите к той же внутренней сети вторую машину-гостя. Для VLAN нужен коммутатор или точка доступа с тегами.

## 14. Мастер первой настройки

При первом входе (и в меню **System › Wizard**, `/ui/core/initial_setup`) открывается мастер jk-ufw: приветствие
и четыре шага: «Интернет» (DHCP, PPPoE или статический адрес), «Локальная сеть» (адрес экрана, раздача адресов, имя),
«Доступ» (пароль root, часовой пояс, язык) и «Защита» (защита от угроз IDS/IPS, фильтры bogons и частных сетей,
DNS-резолвер и DNSSEC), затем сводка и применение. Мастер работает через тот же API, что и исходный
(`/api/core/initial_setup/*`), поэтому проверки и запись настроек не изменились. Защита от угроз включается через
`/api/ids/*` с теми же наборами правил («Рекомендуемый» уровень) и той же политикой `jk-ufw: block threats`, что и
страница Threat Management. Если меняется адрес LAN, мастер в конце показывает новый адрес панели.
Исходный мастер с вкладками остался: `/ui/core/initial_setup?classic`.

Файлы: `src/opnsense/mvc/app/views/OPNsense/Core/jkufw_setup.volt` (новый) и одна правка в
`src/opnsense/mvc/app/controllers/OPNsense/Core/InitialSetupController.php` (выбор шаблона). Если при слиянии
с основным проектом в контроллере будет конфликт, возьмите их версию и верните условие с `classic`.

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-setup.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-setup.sh
sh /tmp/try-setup.sh                 # или: sh /tmp/try-setup.sh <ветка>
sh /tmp/try-setup.sh --remove        # вернуть исходный мастер
```

## 21. Защита сайтов (WAF)

Страница **Firewall › Web Protection (WAF)** (`/ui/jkufw/waf`). Межсетевой экран веб-приложений для сайтов внутри
сети, открытых в интернет: экран отвечает на их имена на портах 80/443 (обратный прокси) и проверяет каждый запрос
до того, как он дойдёт до сервера. Проверки: SQL-инъекции и XSS (сигнатуры + libinjection), обход каталогов,
подключение чужих файлов (RFI), приёмы обхода защиты, опасные загрузки, известные сканеры уязвимостей. Для каждого
сайта режим «Только наблюдать» (атаки пишутся в журнал, но проходят; удобно первые дни) или «Блокировать».
На странице: атаки за сутки по типам и часам, самые активные адреса, последние запросы с причиной.

Движок не новый: модуль nginx (`os-nginx`) с NAXSI и базовыми правилами `naxsi_core.rules`, страница ставит его
и загружает правила сама. Применение пишет обычные объекты nginx с описанием `jk-ufw waf: <сайт>` (upstream, location
с NAXSI, HTTP-сервер) и правила `[jk-ufw waf]` на выбранных интерфейсах. Объекты nginx, созданные вручную, не трогаются.

Панель управления экрана по умолчанию занимает 443 и 80. Шаг «Перенести панель на 8443» меняет порт панели
(System › Settings › Administration) и отключает её редирект с 80; страница сама откроется по новому адресу.
Проброс портов 80/443 на внутренний сервер (если был) нужно удалить, иначе запросы идут мимо WAF: страница
предупреждает об этом.

Файлы: `src/opnsense/mvc/app/models/OPNsense/JkUfw/{Waf.xml,Waf.php,Publish.php}`,
`src/opnsense/mvc/app/controllers/OPNsense/JkUfw/{WafController.php,Api/WafController.php}`,
`src/opnsense/mvc/app/views/OPNsense/JkUfw/waf.volt`, меню и ACL в `models/OPNsense/JkUfw/{Menu,ACL}`.

```sh
fetch -o /tmp/try-waf.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-waf.sh
sh /tmp/try-waf.sh                 # или: sh /tmp/try-waf.sh <ветка>
sh /tmp/try-waf.sh --remove        # убрать (сначала выключите WAF на странице и нажмите «Применить»)
```

## 22. Защита почты

Страница **Services › Mail Protection** (`/ui/jkufw/mail`). Почтовый шлюз перед почтовым сервером внутри сети:
почта из интернета приходит на экран (порт 25), проверяется и только потом передаётся серверу. Проверки: спам
(SPF, DKIM, DMARC, списки блокировки, Bayes), вирусы во вложениях (ClamAV, базы обновляются сами), опасные вложения
(.exe, .js, .vbs, .lnk, .iso, макросы Office и др.), фишинговые ссылки (OpenPhish), отложенная доставка
(greylisting), строгие проверки SMTP. Пороги «пометить как спам» и «отклонить» задаются ползунками. Можно пускать
через шлюз и исходящую почту (в сервере указать экран как smart host). На странице: счётчики, последние письма с
вердиктом и причинами, состояние служб, очередь, версия антивирусных баз.

Работа делается стандартными модулями: `os-postfix` (приём и пересылка по доменам), `os-rspamd` (антиспам, milter),
`os-clamav` (антивирус), `os-redis` (для greylisting); страница ставит недостающие. Применение пишет их настройки
и правило `[jk-ufw mail]` для порта 25. Домены, добавленные в Postfix вручную, не трогаются. Пока rspamd недоступен,
Postfix временно отказывает (tempfail), так что непроверенная почта не проходит, а отправители повторят позже.

В DNS MX-запись домена должна указывать на внешний адрес экрана, имя шлюза совпадать с MX и PTR. Проброс порта 25
на внутренний сервер нужно удалить (страница предупреждает).

Файлы: `src/opnsense/mvc/app/models/OPNsense/JkUfw/{Mail.xml,Mail.php,Publish.php}`,
`src/opnsense/mvc/app/controllers/OPNsense/JkUfw/{MailController.php,Api/MailController.php}`,
`src/opnsense/mvc/app/views/OPNsense/JkUfw/mail.volt`, меню и ACL в `models/OPNsense/JkUfw/{Menu,ACL}`.

```sh
fetch -o /tmp/try-mail.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-mail.sh
sh /tmp/try-mail.sh                 # или: sh /tmp/try-mail.sh <ветка>
sh /tmp/try-mail.sh --remove        # убрать (сначала выключите защиту на странице и нажмите «Применить»)
```
