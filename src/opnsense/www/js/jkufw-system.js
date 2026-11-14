/*
 * Copyright (c) 2026 jk8s and jk-ufw contributors
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * jk-ufw: shared look for the pages of the "System" menu (see css/jkufw-system.css).
 *
 * jkufwSystemMark() runs right after the menu is printed (default.volt, fbegin.inc) and adds
 * class "jks" to <html> when the selected menu entry lives under System, so the styles
 * apply before the page is painted. On DOM ready the page header becomes the same hero as
 * on the jk-ufw feature pages (icon, title, one line of explanation) and the sibling pages
 * of the current group get a segmented switcher. Only presentation: no ids, forms, buttons
 * or handlers of the page are touched, and the original English title stays visible in small
 * print so documentation and forum answers still match.
 */
(function () {
    'use strict';

    /* pages that already have their own jk-ufw design */
    var SKIP = ['/ui/jkufw/notify', '/ui/core/initial_setup'];

    var GROUPS = {
        Access: ['Доступ', 'fa-users'],
        Configuration: ['Конфигурация', 'fa-history'],
        Firmware: ['Обновления', 'fa-cloud-download'],
        Gateways: ['Шлюзы', 'fa-location-arrow'],
        HighAvailability: ['Отказоустойчивость', 'fa-refresh'],
        Routes: ['Маршруты', 'fa-map-signs'],
        Settings: ['Настройки', 'fa-sliders'],
        Snapshots: ['Снимки', 'fa-hdd-o'],
        Trust: ['Сертификаты', 'fa-certificate'],
        LogFiles: ['Журналы', 'fa-file-text-o'],
        Diagnostics: ['Диагностика', 'fa-stethoscope']
    };

    /* [path (prefix match, longest wins), icon, title, one-line description] */
    var PAGES = [
        ['/ui/auth/user', 'fa-user', 'Пользователи', 'Учётные записи для входа в веб-интерфейс, SSH и VPN, их группы и ключи API.'],
        ['/ui/auth/group', 'fa-users', 'Группы', 'Группы объединяют пользователей и выдают им права разом.'],
        ['/ui/auth/priv', 'fa-key', 'Права доступа', 'Какие страницы и действия доступны каждому пользователю и группе.'],
        ['/system_authservers.php', 'fa-server', 'Серверы входа', 'Проверка логина через LDAP, RADIUS или локальную базу пользователей.'],
        ['/diag_authentication.php', 'fa-check-circle', 'Проверка входа', 'Проверьте логин и пароль на выбранном сервере аутентификации.'],
        ['/diag_backup.php', 'fa-download', 'Резервные копии', 'Скачайте всю конфигурацию в файл или восстановите её из файла.'],
        ['/ui/core/defaults', 'fa-undo', 'Сброс к заводским', 'Возврат всех настроек к исходным. Перед сбросом сделайте резервную копию.'],
        ['/ui/core/backup/history', 'fa-history', 'История изменений', 'Каждое сохранение настроек: когда и кто менял. Можно сравнить версии и откатиться.'],
        ['/ui/core/firmware', 'fa-cloud-download', 'Обновления системы', 'Версия, обновления, журнал изменений, плагины и пакеты.'],
        ['/crash_reporter.php', 'fa-bug', 'Отчёты о сбоях', 'Сведения об ошибках PHP и аварийных завершениях программ.'],
        ['/ui/diagnostics/log/core/pkg', 'fa-file-text-o', 'Журнал обновлений', 'Что и когда устанавливал менеджер пакетов.'],
        ['/ui/routing/configuration', 'fa-location-arrow', 'Шлюзы', 'Выходы в интернет и их мониторинг: задержка, потери, состояние.'],
        ['/ui/routing/gateway_groups', 'fa-random', 'Группы шлюзов', 'Резервирование и балансировка между несколькими провайдерами.'],
        ['/ui/diagnostics/log/core/gateways', 'fa-file-text-o', 'Журнал шлюзов', 'Пропадания связи и восстановления каждого шлюза.'],
        ['/ui/core/hasync_status', 'fa-heartbeat', 'Состояние кластера', 'Связь с резервным межсетевым экраном и синхронизация служб.'],
        ['/ui/core/hasync', 'fa-refresh', 'Отказоустойчивость', 'Синхронизация настроек и состояний со вторым межсетевым экраном.'],
        ['/ui/routes', 'fa-map-signs', 'Статические маршруты', 'Через какой шлюз отправлять трафик к отдельным сетям.'],
        ['/ui/diagnostics/interface/routes', 'fa-sitemap', 'Таблица маршрутов', 'Маршруты, которые сейчас использует система.'],
        ['/ui/diagnostics/log/core/routing', 'fa-file-text-o', 'Журнал маршрутизации', 'События демонов маршрутизации.'],
        ['/system_advanced_admin.php', 'fa-shield', 'Администрирование', 'Веб-интерфейс, SSH, консоль и защита входа.'],
        ['/system_general.php', 'fa-sliders', 'Общие настройки', 'Имя устройства, домен, часовой пояс, язык и DNS-серверы.'],
        ['/system_advanced_misc.php', 'fa-wrench', 'Дополнительно', 'Энергосбережение, криптография, временные файлы и прочие тонкие настройки.'],
        ['/ui/core/tunables', 'fa-microchip', 'Параметры ядра', 'Значения sysctl и загрузчика для тонкой настройки системы.'],
        ['/ui/cron', 'fa-clock-o', 'Планировщик', 'Задачи по расписанию: обновления, перезагрузки, отчёты.'],
        ['/ui/syslog', 'fa-file-text', 'Журналирование', 'Сколько хранить журналы и куда их отправлять.'],
        ['/ui/core/snapshots', 'fa-hdd-o', 'Снимки системы', 'Загрузочные снимки ZFS: откат всей системы за одну перезагрузку.'],
        ['/ui/trust/ca', 'fa-university', 'Центры сертификации', 'Корневые и промежуточные центры, которыми подписаны сертификаты.'],
        ['/ui/trust/cert', 'fa-id-card-o', 'Сертификаты', 'Сертификаты для веб-интерфейса, VPN и пользователей.'],
        ['/ui/trust/crl', 'fa-ban', 'Отзыв сертификатов', 'Списки отозванных сертификатов, которым больше нельзя доверять.'],
        ['/ui/trust/settings', 'fa-cog', 'Настройки доверия', 'Хранилище доверенных центров системы и ограничения OpenSSL.'],
        ['/ui/diagnostics/log/core/audit', 'fa-user-secret', 'Журнал аудита', 'Входы, изменения настроек и действия администраторов.'],
        ['/ui/diagnostics/log/core/configd', 'fa-file-text-o', 'Журнал службы настроек', 'Команды, которые выполняла служба configd.'],
        ['/ui/diagnostics/log/core/boot', 'fa-power-off', 'Журнал загрузки', 'Сообщения ядра и служб при последнем запуске.'],
        ['/ui/diagnostics/log/core/system', 'fa-file-text-o', 'Системный журнал', 'Общие сообщения системы и служб.'],
        ['/ui/diagnostics/log/core/lighttpd', 'fa-globe', 'Журнал веб-сервера', 'Запросы и ошибки веб-интерфейса.'],
        ['/ui/core/service', 'fa-cubes', 'Службы', 'Запуск, остановка и перезапуск системных служб.'],
        ['/ui/diagnostics/activity', 'fa-tasks', 'Активность', 'Процессы и загрузка процессора в реальном времени.'],
        ['/ui/diagnostics/system', 'fa-bar-chart', 'Статистика', 'Память, буферы сети и другие показатели ядра.']
    ];

    function lookup(path) {
        var best = null;
        PAGES.forEach(function (p) {
            if (path.indexOf(p[0]) === 0 && (best === null || p[0].length > best[0].length)) {
                best = p;
            }
        });
        return best;
    }

    window.jkufwSystemMark = function () {
        try {
            var path = window.location.pathname;
            if (SKIP.some(function (s) { return path.indexOf(s) === 0; })) {
                return;
            }
            if (document.querySelector('#System.active-menu') !== null) {
                document.documentElement.classList.add('jks');
            }
        } catch (e) { /* styling only */ }
    };

    function esc(s) {
        return $('<div/>').text(s).html();
    }

    function hero() {
        var $head = $('.page-content-head .list-inline > li:first-child');
        var $h1 = $head.find('h1').first();
        if ($h1.length === 0 || $h1.hasClass('jks-title')) {
            return;
        }
        var path = window.location.pathname;
        var page = lookup(path);
        /* group from the menu: #System_<Group> holds the selected entry */
        var $grp = $('#System > .collapse.active-menu').first();
        var gid = ($grp.attr('id') || '').replace(/^System_/, '');
        var $active = $('#System a.list-group-item.active').first();
        var group = gid ? (GROUPS[gid] || [$('[href="#System_' + gid + '"]').text().trim(), 'fa-server']) : ['', 'fa-server'];
        var orig = $.trim($h1.clone().children().remove().end().text());
        var title = page ? page[2] : ($active.text().trim() || orig);
        var icon = page ? page[1] : group[1];
        var sub = page ? page[3] : '';

        var $star = $h1.find('.menu-favorite-star').detach();
        $h1.addClass('jks-title').empty()
            .append($('<span/>').text(title))
            .append('<span class="jks-pill"><i></i>Система' + (group[0] ? ' · ' + esc(group[0]) : '') + '</span>')
            .append($star);
        var $txt = $('<div class="jks-hero-txt"/>').append($h1);
        if (sub) {
            $txt.append($('<div class="jks-sub"/>').text(sub));
        }
        if (orig && orig !== title) {
            $txt.append($('<div class="jks-orig"/>').text(orig));
        }
        $head.empty().append(
            $('<div class="jks-hero"/>').append('<div class="jks-logo"><i class="fa ' + icon + '"></i></div>').append($txt)
        );
        document.title = title + ' | ' + document.title.split(' | ').slice(1).join(' | ');
    }

    function siblings() {
        var $grp = $('#System > .collapse.active-menu').first();
        if ($grp.length === 0) {
            return;
        }
        var here = window.location.pathname;
        var links = $grp.children('a.list-group-item[href]').filter(function () {
            var h = $(this).attr('href') || '';
            return h.charAt(0) !== '#' && $(this).attr('target') !== '_blank';
        });
        if (links.length < 2) {
            return;
        }
        /* firmware & co: the siblings are tabs of this very page, the page shows them already */
        var same = links.filter(function () { return this.pathname === here; }).length;
        if (same > 1) {
            return;
        }
        var $seg = $('<div class="jks-seg" role="navigation"/>');
        links.each(function () {
            var $a = $('<a/>').attr('href', $(this).attr('href')).text($(this).text().trim());
            if ($(this).hasClass('active') || this.pathname === here) {
                $a.addClass('sel');
            }
            $seg.append($a);
        });
        $('.page-content-head > .container-fluid').append($('<div class="jks-nav"/>').append($seg));
    }

    function cards() {
        /* the "advanced mode / full help" switches of base_form live in a header-less first section */
        $('.page-content-main form > .table-responsive').each(function () {
            var $t = $(this).children('table');
            if ($t.children('thead').length === 0 && $t.find('tbody > tr').length === 1 &&
                    $t.find('[id^="show_all_help_"], [id^="show_advanced_"]').length) {
                $(this).addClass('jks-tools');
            }
        });
        /* boxes with several titled form sections: every section becomes its own card */
        $('.page-content-main .content-box, .page-content-main .tab-pane').each(function () {
            var $box = $(this);
            var n = 0;
            $box.find('form').each(function () {
                n = Math.max(n, $(this).children('.table-responsive').not('.jks-tools').length);
            });
            var legacy = $box.children('table.opnsense_standard_table_form').length +
                $box.children('form').children('table.opnsense_standard_table_form').length;
            if ((n > 1 || legacy > 1) && $box.find('.content-box, .tab-pane').length === 0) {
                $box.addClass('jks-split');
                $box.parents('.content-box, .tab-content').addClass('jks-bare');
            }
        });
        /* legacy pages open each table with a row holding only a <strong> title: make it the card heading */
        $('.page-content-main table.table').each(function () {
            var $tr = $(this).children('tbody').first().children('tr').first();
            if ($tr.length === 0) {
                $tr = $(this).children('tr').first();
            }
            var $first = $tr.children('td').first();
            if ($first.children().length === 1 && $first.children('strong, b').length === 1 &&
                    $.trim($first.text()) === $.trim($first.children().first().text()) &&
                    $tr.find('input, select, textarea, button').length === 0) {
                $tr.addClass('jks-head');
            }
        });
        /* MVC pages that end with a plain save button row: show it as the sticky action bar */
        $('.page-content-main section.col-xs-12 > .col-md-12, .page-content-main .tab-pane > .col-md-12').each(function () {
            var $c = $(this);
            if ($c.children('.btn-primary').length && $c.children(':not(.btn):not(i):not(span):not(br)').length === 0) {
                $c.addClass('jks-bar');
            }
        });
    }

    $(function () {
        if (!document.documentElement.classList.contains('jks')) {
            return;
        }
        try { hero(); } catch (e) { /* presentation only */ }
        try { siblings(); } catch (e) { /* presentation only */ }
        try { cards(); } catch (e) { /* presentation only */ }
    });
})();
