/*
 * jk-ufw: content filter and parental control at a glance: is DNS filtering on, how much it blocked,
 * which devices are without internet right now, with a one-click pause. Settings: Firewall › Content Filter.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtNum, plural} from './JkUfwCommon.js';

const STYLE = `
.jkpw-row { display:flex; align-items:center; gap:10px; padding:7px 4px; border-top:1px solid #1d1d22; }
.jkpw-row:first-child { border-top:0; }
.jkpw-ic { width:30px; height:30px; border-radius:9px; display:grid; place-items:center; background:#202026; color:#8d8d98; flex:none; }
.jkpw-row.blocked .jkpw-ic, .jkpw-row.paused .jkpw-ic { background:rgba(229,32,46,.12); color:#ff3b47; }
.jkpw-row.allowed .jkpw-ic { background:rgba(34,197,94,.12); color:#22c55e; }
.jkpw-m { flex:1; min-width:0; }
.jkpw-n { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkpw-s { color:#8d8d98; font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkpw-row.blocked .jkpw-s, .jkpw-row.paused .jkpw-s { color:#ffb3b8; }
.jkpw-b { border:1px solid #2e2e35; background:#18181c; color:#e8e8ec; border-radius:8px; padding:4px 10px; font-size:12px; font-weight:600; cursor:pointer; white-space:nowrap; }
.jkpw-b:hover { background:#1e1e23; }
.jkpw-b.pause { background:#e5202e; border-color:#e5202e; color:#fff; }
.jkpw-b.pause:hover { background:#ff3b47; }
.jkpw-b[disabled] { opacity:.5; cursor:default; }
`;

// the same groups as the Content Filter page, to count enabled categories of the whole-network policy
const CATEGORY_KEYS = [['hgz002', 'hgz010'], ['hgz011', 'hgz009'], ['oisd2'], ['hgz019'], ['hgz014'], ['hgz022'], ['hgz018']];

const keysOf = (node) => {
    if (node == null) {
        return [];
    }
    if (typeof node === 'string') {
        return node.split(',').filter(Boolean);
    }
    if (Array.isArray(node)) {
        return node;
    }
    return Object.keys(node).filter((k) => node[k] && (node[k].selected === undefined || String(node[k].selected) === '1'));
};

export default class JkUfwParental extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 30;
        this.busy = false;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    getMarkup() {
        const id = this.id;
        const kpi = (key, label) => `
            <div class="jk-kpi"><div class="jk-tile-lbl">${label}</div>
            <div class="jk-tile-val" id="${id}-${key}">…</div><div class="jk-tile-sub" id="${id}-${key}-sub">&nbsp;</div></div>`;
        return $(`
            <div class="jk jk-pad">
                <div class="jk-kpis">
                    ${kpi('filter', `<i class="fa fa-filter"></i>${this.t('filter', 'Filter')}`)}
                    ${kpi('blocked', `<span class="jk-dot bad"></span>${this.t('blocked', 'Blocked')}`)}
                    ${kpi('offline', `<i class="fa fa-moon-o"></i>${this.t('offline', 'Offline now')}`)}
                </div>
                <div class="jk-sec"><span>${this.t('devices', 'Devices')}</span><a href="/ui/jkufw/parental#sched">${this.t('settings', 'Settings')} →</a></div>
                <div id="${id}-list"></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        if (!document.getElementById('jkpw-style')) {
            $('head').append(`<style id="jkpw-style">${STYLE}</style>`);
        }
        $(`#${this.id}-list`).on('click', 'button[data-u]', async (e) => {
            const btn = $(e.currentTarget);
            if (this.busy) {
                return;
            }
            this.busy = true;
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-pulse"></i>');
            try {
                await this.ajaxCall(`/api/jkufw/parental/pause/${btn.data('u')}/${btn.data('p')}`, '{}', 'POST');
            } catch (err) {
                /* the next tick shows the real state */
            }
            this.busy = false;
            await this.onWidgetTick();
        });
    }

    async onWidgetTick() {
        const call = (url) => this.ajaxCall(url).catch(() => null);
        const [policies, status, enabled] = await Promise.all([
            call('/api/unbound/overview/get_policies'),
            call('/api/jkufw/parental/status'),
            call('/api/unbound/overview/is_enabled')
        ]);

        // filter: the whole-network policy (no source networks)
        const list = Object.values(policies || {}).filter((p) => p && typeof p === 'object');
        const active = list.filter((p) => String(p.enabled) === '1' && (keysOf(p.type).length || keysOf(p.wildcards).length));
        const global = active.find((p) => !keysOf(p.source_nets).length);
        const cats = global ? CATEGORY_KEYS.filter((ks) => ks.every((k) => keysOf(global.type).includes(k))).length : 0;
        $(`#${this.id}-filter`).html(active.length ? `<span style="color:#22c55e">${this.t('on', 'On')}</span>`
            : `<span style="color:#8d8d98">${this.t('off', 'Off')}</span>`);
        $(`#${this.id}-filter-sub`).html(active.length
            ? esc(`${cats} ${plural(cats, this.t('category1', 'category'), this.t('category2', 'categories'), this.t('category5', 'categories'))}`)
            : `<a href="/ui/jkufw/parental">${this.t('enable', 'Turn on')} →</a>`);

        if (enabled && enabled.enabled && String(enabled.enabled) !== '0') {
            const totals = await call('/api/unbound/overview/totals/1');
            const total = (totals && Number(totals.total)) || 0;
            const blocked = (totals && totals.blocked && Number(totals.blocked.total)) || 0;
            $(`#${this.id}-blocked`).text(fmtNum(blocked));
            $(`#${this.id}-blocked-sub`).text(total ? `${(blocked / total * 100).toFixed(1)}% ${this.t('of_queries', 'of queries')}` : ' ');
        } else {
            $(`#${this.id}-blocked`).text('—');
            $(`#${this.id}-blocked-sub`).text(this.t('no_stats', 'DNS statistics off'));
        }

        const devices = (status && Array.isArray(status.devices)) ? status.devices.filter((d) => d.state !== 'off') : [];
        const offline = devices.filter((d) => d.state === 'blocked' || d.state === 'paused').length;
        $(`#${this.id}-offline`).html(offline ? `<span style="color:#ff3b47">${offline}</span>` : '0');
        $(`#${this.id}-offline-sub`).text(`${this.t('of', 'of')} ${devices.length}`);

        if (!devices.length) {
            $(`#${this.id}-list`).html(`<div class="jk-empty">${this.t('nobody', 'No devices with a schedule')}<br/>
                <a href="/ui/jkufw/parental#sched">${this.t('add', 'Add a device')} →</a></div>`);
        } else {
            const time = (iso) => {
                const d = new Date(iso);
                const sameDay = d.toDateString() === new Date().toDateString();
                return (sameDay ? '' : d.toLocaleDateString('ru-RU', {weekday: 'short'}) + ' ') +
                    d.toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'});
            };
            $(`#${this.id}-list`).html(devices.map((d) => {
                let sub;
                if (d.state === 'paused') {
                    sub = this.t('paused', 'Paused');
                } else if (d.state === 'blocked') {
                    sub = this.t('no_internet', 'No internet') + (d.until ? ` ${this.t('until', 'until')} ${time(d.until)}` : '');
                } else {
                    sub = this.t('online', 'Internet allowed') + (d.until ? ` ${this.t('until', 'until')} ${time(d.until)}` : '');
                }
                const btn = d.state === 'paused'
                    ? `<button class="jkpw-b" data-u="${esc(d.uuid)}" data-p="0" type="button"><i class="fa fa-play"></i> ${this.t('resume', 'Resume')}</button>`
                    : `<button class="jkpw-b pause" data-u="${esc(d.uuid)}" data-p="1" type="button"><i class="fa fa-pause"></i> ${this.t('pause', 'Pause')}</button>`;
                const icon = d.state === 'paused' ? 'fa-pause' : (d.state === 'blocked' ? 'fa-moon-o' : 'fa-child');
                return `<div class="jkpw-row ${esc(d.state)}"><div class="jkpw-ic"><i class="fa ${icon}"></i></div>
                    <div class="jkpw-m"><div class="jkpw-n">${esc(d.name)}</div><div class="jkpw-s">${esc(sub)}</div></div>${btn}</div>`;
            }).join(''));
        }

        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
