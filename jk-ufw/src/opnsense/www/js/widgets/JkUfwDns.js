/*
 * jk-ufw: DNS resolver insights (queries, blocked share, cache, top and blocked domains).
 * Needs DNS statistics enabled (Reporting > Unbound DNS page).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtNum, stackedBars, topList} from './JkUfwCommon.js';

export default class JkUfwDns extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 30;
        this.timeoutPeriod = 15000;
        this.configurable = true;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 4};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    async getWidgetOptions() {
        return {
            period: {
                title: this.t('period', 'Period'),
                type: 'select',
                options: [
                    {value: '1', label: `1 ${this.t('hour', 'h')}`},
                    {value: '12', label: `12 ${this.t('hour', 'h')}`},
                    {value: '24', label: `24 ${this.t('hour', 'h')}`}
                ],
                default: '24'
            },
            top: {
                title: this.t('rows', 'Rows in lists'),
                type: 'select',
                options: ['5', '8', '10'].map((n) => ({value: n, label: n})),
                default: '5'
            }
        };
    }

    getMarkup() {
        const id = this.id;
        const kpi = (key, label) => `
            <div class="jk-kpi"><div class="jk-tile-lbl">${label}</div>
            <div class="jk-tile-val" id="${id}-${key}">…</div><div class="jk-tile-sub" id="${id}-${key}-sub">&nbsp;</div></div>`;
        return $(`
            <div class="jk jk-pad" id="${id}-root">
                <div class="jk-kpis">
                    ${kpi('total', `<i class="fa fa-globe"></i>${this.t('queries', 'Queries')}`)}
                    ${kpi('blocked', `<span class="jk-dot bad"></span>${this.t('blocked', 'Blocked')}`)}
                    ${kpi('local', `<i class="fa fa-bolt"></i>${this.t('local', 'Cache / local')}`)}
                    ${kpi('resolved', `<i class="fa fa-cloud"></i>${this.t('resolved', 'Upstream')}`)}
                </div>
                <div class="jk-sec"><span id="${id}-chart-title">${this.t('activity', 'Activity')}</span>
                    <span class="jk-legend"><span><i style="background:#3f3f48"></i>${this.t('allowed', 'Allowed')}</span>
                    <span><i style="background:#e5202e"></i>${this.t('blocked', 'Blocked')}</span></span></div>
                <div class="jk-chart" id="${id}-chart"></div>
                <div class="jk-axis" id="${id}-axis"></div>
                <div class="jk-cols">
                    <div><div class="jk-sec"><span>${this.t('top', 'Top domains')}</span></div><div id="${id}-top"></div></div>
                    <div><div class="jk-sec"><span>${this.t('top_blocked', 'Top blocked')}</span>
                        <a href="/ui/unbound/overview">${this.t('details', 'Details')} →</a></div><div id="${id}-topb"></div></div>
                </div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
    }

    _disabled() {
        $(`#${this.id}-root`).html(`<div class="jk-empty">${esc(this.t('disabled', 'DNS statistics are disabled.'))}<br>
            <a href="/ui/unbound/overview">${esc(this.t('enable', 'Enable them on the DNS reporting page'))} →</a></div>`);
    }

    async onWidgetTick() {
        const call = (url) => this.ajaxCall(url).catch(() => null);
        const enabled = await call('/api/unbound/overview/is_enabled');
        if (!enabled || !enabled.enabled || enabled.enabled === '0') {
            this._disabled();
            return;
        }
        const config = await this.getWidgetConfig();
        const period = parseInt(config.period, 10) || 24;
        const top = parseInt(config.top, 10) || 5;
        const [totals, rolling] = await Promise.all([
            call(`/api/unbound/overview/totals/${top}`),
            call(`/api/unbound/overview/rolling/${period}`)
        ]);
        if (!totals || totals.total === undefined) {
            return;
        }

        const total = Number(totals.total) || 0;
        const blocked = (totals.blocked && Number(totals.blocked.total)) || 0;
        const local = (totals.local && Number(totals.local.total)) || 0;
        const resolved = (totals.resolved && Number(totals.resolved.total)) || 0;
        const cached = Math.max(0, total - blocked - local - resolved);
        const pct = (v) => (total ? `${(v / total * 100).toFixed(1)}%` : '0%');
        const since = totals.start_time ? new Date(Number(totals.start_time) * 1000) : null;

        $(`#${this.id}-total`).text(fmtNum(total));
        $(`#${this.id}-total-sub`).text(since ? `${this.t('since', 'since')} ${since.toLocaleDateString('ru-RU')}` : ' ');
        $(`#${this.id}-blocked`).text(pct(blocked));
        $(`#${this.id}-blocked-sub`).text(`${fmtNum(blocked)} ${this.t('queries_lc', 'queries')}`);
        $(`#${this.id}-local`).text(pct(local + cached));
        $(`#${this.id}-local-sub`).text(`${fmtNum(local + cached)} ${this.t('fast', 'answered instantly')}`);
        $(`#${this.id}-resolved`).text(pct(resolved));
        $(`#${this.id}-resolved-sub`).text(`${fmtNum(resolved)} ${this.t('queries_lc', 'queries')}`);

        const points = Object.entries(rolling || {})
            .map(([ts, v]) => [Number(ts), v || {}])
            .filter(([ts]) => Number.isFinite(ts))
            .sort((a, b) => a[0] - b[0]);
        if (points.length) {
            const blockedS = points.map(([, v]) => Number(v.blocked) || 0);
            const allowedS = points.map(([, v]) => Math.max(0, (Number(v.total) || 0) - (Number(v.blocked) || 0)));
            $(`#${this.id}-chart`).html(stackedBars([
                {values: allowedS, color: '#3f3f48'},
                {values: blockedS, color: '#e5202e'}
            ]));
            const fmt = (ts) => new Date(ts * 1000).toLocaleTimeString('ru-RU', {hour: '2-digit', minute: '2-digit'});
            $(`#${this.id}-axis`).html(`<span>${fmt(points[0][0])}</span><span>${fmt(points[Math.floor(points.length / 2)][0])}</span><span>${fmt(points[points.length - 1][0])}</span>`);
        } else {
            $(`#${this.id}-chart`).html(`<div class="jk-empty">${this.t('no_data', 'No data yet')}</div>`);
            $(`#${this.id}-axis`).empty();
        }
        $(`#${this.id}-chart-title`).text(`${this.t('activity', 'Activity')} · ${period} ${this.t('hour', 'h')}`);

        const list = (obj) => Object.entries(obj || {})
            .map(([domain, v]) => ({label: domain, value: Number(v.total) || 0, sub: v.blocklist || '', text: fmtNum(v.total)}))
            .sort((a, b) => b.value - a.value).slice(0, top);
        $(`#${this.id}-top`).html(topList(list(totals.top), '#8d8d98', this.t('no_data', 'No data yet')));
        $(`#${this.id}-topb`).html(topList(list(totals.top_blocked), '#e5202e', this.t('nothing', 'Nothing blocked')));

        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
