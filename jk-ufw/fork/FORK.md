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

## 18. Защита от атак: DDoS, списки угроз, экспорт в SIEM

Страница **Firewall › Attack Protection** (`/ui/jkufw/ddos`) и виджет дашборда «jk-ufw: защита от атак».
Закрывает пункты требований к NGFW «защита от DDoS-атак», «импорт индикаторов компрометации» и «передача событий
в SIEM». Три вкладки:

**DDoS.** Для выбранных внешних интерфейсов (по умолчанию все интерфейсы со шлюзом) правила пропуска, открытые для
всего интернета (источник «any»), получают лимиты на один адрес: число соединений (`max-src-states`), для TCP ещё
открытые соединения (`max-src-conn`) и скорость новых (`max-src-conn-rate … overload <jkufw_ddos_block>`), на
строгом уровне SYN-прокси. Кто превысил лимит, попадает в таблицу `jkufw_ddos_block`, правило
`[jk-ufw ddos] blocked attackers` первым на интерфейсе отбрасывает его пакеты. Уровни: «Лёгкий», «Обычный»,
«Строгий» и «Свой» (числа вручную), отдельно для каждого интерфейса. Поля, которые пользователь заполнил в правиле
сам, не трогаются; правила с ограниченным источником (офис, партнёры) не трогаются. Общие настройки: pf SYN cookies
(при нагрузке / всегда), адаптивные тайм-ауты (60–120 % размера таблицы), агрессивная очистка, лимит ответов
ICMP/RST (`net.inet.icmp.icmplim`), блокировка bogons, время блокировки, списки «никогда не блокировать» и «всегда
блокировать». Раз в минуту `scripts/jkufw/ddos.py tick` (cron) снимает счётчики pf, снимает блокировку по истечении
времени, держит разрешённые адреса вне таблицы и пишет события («адрес заблокирован», «SYN-флуд», «таблица
заполнена на N %», «атака закончилась») в журнал `/var/log/jkufw/ddos/` (программа `jkufw-ddos`). Страница
показывает состояние (спокойно / повышенная активность / атака), график за 1–24 часа, чёрный список с ручной
блокировкой и освобождением.

**Списки угроз (IoC).** Готовые бесплатные списки (FireHOL Level 1, abuse.ch Feodo Tracker, Emerging Threats,
CINS Army, blocklist.de) или свой по HTTPS, плюс свои индикаторы вручную. Каждый список это алиас URL Table
`jkufw_ioc_<id>` с обновлением по расписанию; правила `[jk-ufw ioc]` (плавающие, все интерфейсы) блокируют трафик
с этих адресов и к ним, с записью в журнал.

**Экспорт в SIEM.** Получатели по syslog UDP/TCP в формате CEF (KUMA, MaxPatrol SIEM, QRadar, ArcSight), JSON
(Elastic, Graylog, Wazuh) или RFC 5424. Шаблон `service/templates/OPNsense/JkUfw/Siem` пишет
`/usr/local/etc/syslog-ng.conf.d/jkufw-siem.conf`: записи filterlog разбираются на поля (действие, направление,
интерфейс, адреса, порты, протокол, правило), срабатывания Suricata на сигнатуру, класс и приоритет. Выбор
потоков: межсетевой экран, IPS, защита от DDoS, входы и изменения настроек, остальное. Кнопка «Проверить»
шлёт тестовое событие.

Всё, что меняет «Применить», записано в модели (`applied`): исходные значения полей правил, системных настроек,
флагов интерфейсов и параметра ядра. Следующее применение сначала возвращает их, затем применяет текущие настройки,
поэтому выключение защиты возвращает конфигурацию в исходный вид (значение, изменённое после этого вручную,
остаётся как есть).

Ограничения: проброс портов с «Pass» / «Register rule» не имеет своего правила, лимиты на него не ставятся (страница
показывает, сколько таких). Защита работает в пределах ширины канала: от атаки, забивающей канал провайдера, спасает
только фильтрация у провайдера.

Файлы: `src/opnsense/mvc/app/{models,controllers,views}/OPNsense/JkUfw/` (`Ddos.*`, `DdosController.php`,
`Api/DdosController.php`, `ddos.volt`), `src/opnsense/scripts/jkufw/ddos.py`,
`src/opnsense/service/conf/actions.d/actions_jkufw_ddos.conf`, `src/etc/inc/plugins.inc.d/jkufw_ddos.inc`,
`src/opnsense/service/templates/OPNsense/JkUfw/Siem/`, `src/opnsense/service/templates/OPNsense/Syslog/local/jkufw_ddos.conf`,
`src/opnsense/www/js/widgets/JkUfwDdos.js`.

Попробовать на работающем экране без пересборки образа (под root):

```sh
fetch -o /tmp/try-ddos.sh https://raw.githubusercontent.com/bfg10kkk/JK-UFW/stable/26.7/jk-ufw/features/try-ddos.sh
sh /tmp/try-ddos.sh                 # или: sh /tmp/try-ddos.sh <ветка или коммит>
sh /tmp/try-ddos.sh --remove        # убрать (сначала выключите защиту на странице и нажмите «Применить»)
```

Если панель открыта через внешний интерфейс (как в VirtualBox за домашним роутером), при включении страница сама
добавит ваш адрес в «Никогда не блокировать». Блокировку bogons на таком интерфейсе не включайте.
