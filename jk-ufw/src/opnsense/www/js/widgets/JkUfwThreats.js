/*
 * jk-ufw: intrusion detection / prevention (Suricata) at a glance: detected vs blocked threats for the last
 * 24 hours, top signatures and attackers. Settings live on Services › Intrusion Detection › Threat Management.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtNum, plural, stackedBars, topList} from './JkUfwCommon.js';

// suricata writes 2026-11-05T15:00:00.123456+0000; normalise so every browser can parse it
const parseTs = (v) => Date.parse(String(v || '').replace(/(\.\d{3})\d+/, '$1').replace(/([+-]\d\d)(\d\d)$/, '$1:$2'));

export default class JkUfwThreats extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 30;
        this.timeoutPeriod = 20000;
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
            hours: {
                title: this.t('window', 'Time window'),
                type: 'select',
                options: [
                    {value: '1', label: `1 ${this.t('hours', 'h')}`},
                    {value: '6', label: `6 ${this.t('hours', 'h')}`},
                    {value: '24', label: `24 ${this.t('hours', 'h')}`}
                ],
                default: '24'
            }
        };
    }

    getMarkup() {
        const id = this.id;
        const kpi = (key, label) => `
            <div class="jk-kpi"><div class="jk-tile-lbl">${label}</div>
            <div class="jk-tile-val" id="${id}-${key}">…</div><div class="jk-tile-sub" id="${id}-${key}-sub">&nbsp;</div></div>`;
        return $(`
            <div class="jk jk-pad">
                <div class="jk-kpis">
                    ${kpi('mode', `<i class="fa fa-shield"></i>${this.t('protection', 'Protection')}`)}
                    ${kpi('detected', `<span class="jk-dot warn"></span>${this.t('detected', 'Detected')}`)}
                    ${kpi('blocked', `<span class="jk-dot bad"></span>${this.t('blocked', 'Blocked')}`)}
                    ${kpi('sources', `<i class="fa fa-user-secret"></i>${this.t('sources', 'Attackers')}`)}
                </div>
                <div class="jk-sec"><span id="${id}-chart-title">${this.t('timeline', 'Threats over time')}</span>
                    <span class="jk-legend"><span><i style="background:#e5202e"></i>${this.t('blocked', 'Blocked')}</span>
                    <span><i style="background:#f5a524"></i>${this.t('detected_only', 'Logged only')}</span></span></div>
                <div class="jk-chart" id="${id}-chart"></div>
                <div class="jk-axis" id="${id}-axis"></div>
                <div class="jk-cols">
                    <div><div class="jk-sec"><span>${this.t('top_signatures', 'Top threats')}</span></div><div id="${id}-sig"></div></div>
                    <div><div class="jk-sec"><span>${this.t('top_sources', 'Top attackers')}</span>
                        <a href="/ui/ids/threats">${this.t('settings', 'Settings')} →</a></div><div id="${id}-src"></div></div>
                </div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
    }

    async onWidgetTick() {
        const config = await this.getWidgetConfig();
        const hours = parseInt(config.hours, 10) || 24;
        let status = 'unknown';
        let alerts = null;
        try {
            status = (await this.ajaxCall('/api/ids/service/status')).status || 'unknown';
        } catch (e) {
            status = 'unknown';
        }
        try {
            alerts = await this.ajaxCall('/api/ids/service/query_alerts',
                JSON.stringify({current: 1, rowCount: 2000, searchPhrase: ''}), 'POST');
        } catch (e) {
            alerts = null;
        }

        const running = status === 'running';
        $(`#${this.id}-mode`).html(running ? `<span style="color:#22c55e">${this.t('on', 'On')}</span>`
            : `<span style="color:#8d8d98">${this.t('off', 'Off')}</span>`);
        $(`#${this.id}-mode-sub`).html(running ? this.t('running', 'Suricata running')
            : `<a href="/ui/ids/threats">${this.t('enable', 'Turn on')} →</a>`);

        const rows = (alerts && Array.isArray(alerts.rows)) ? alerts.rows : [];
        const now = Date.now();
        const from = now - hours * 3600000;
        const buckets = hours === 1 ? 30 : (hours === 6 ? 36 : 48);
        const bucketMs = hours * 3600000 / buckets;
        const blockedSeries = new Array(buckets).fill(0);
        const loggedSeries = new Array(buckets).fill(0);
        const sigCount = {};
        const srcCount = {};
        let blocked = 0;
        let logged = 0;

        rows.forEach((r) => {
            const ts = parseTs(r.timestamp);
            if (!Number.isFinite(ts) || ts < from || ts > now + 60000) {
                return;
            }
            const idx = Math.min(buckets - 1, Math.max(0, Math.floor((ts - from) / bucketMs)));
            if (r.alert_action === 'blocked') {
                blocked++;
                blockedSeries[idx]++;
            } else {
                logged++;
                loggedSeries[idx]++;
            }
            if (r.alert) {
                sigCount[r.alert] = (sigCount[r.alert] || 0) + 1;
            }
            if (r.src_ip) {
                srcCount[r.src_ip] = srcCount[r.src_ip] || {n: 0, dst: r.dest_port ? `→ ${r.dest_ip}:${r.dest_port}` : ''};
                srcCount[r.src_ip].n++;
            }
        });

        const total = blocked + logged;
        const sources = Object.keys(srcCount).length;
        $(`#${this.id}-detected`).text(fmtNum(total));
        $(`#${this.id}-detected-sub`).text(`${this.t('for', 'in')} ${hours} ${this.t('hours', 'h')}`);
        $(`#${this.id}-blocked`).text(fmtNum(blocked));
        $(`#${this.id}-blocked-sub`).text(total ? `${(blocked / total * 100).toFixed(0)}% ${this.t('of_threats', 'of threats')}`
            : (running ? this.t('clean', 'all clear') : ' '));
        $(`#${this.id}-sources`).text(fmtNum(sources));
        $(`#${this.id}-sources-sub`).text(plural(sources, 'адрес', 'адреса', 'адресов'));

        if (!running && !rows.length) {
            $(`#${this.id}-chart`).html(`<div class="jk-empty">${this.t('disabled', 'Intrusion prevention is off')}</div>`);
            $(`#${this.id}-axis`).html('');
        } else {
            $(`#${this.id}-chart`).html(stackedBars([
                {values: blockedSeries, color: '#e5202e'},
                {values: loggedSeries, color: '#f5a524'}
            ]));
            $(`#${this.id}-axis`).html(`<span>−${hours} ${this.t('hours', 'h')}</span><span>−${hours / 2} ${this.t('hours', 'h')}</span><span>${this.t('now', 'now')}</span>`);
        }

        const sigItems = Object.entries(sigCount).sort((a, b) => b[1] - a[1]).slice(0, 5)
            .map(([name, n]) => {
                const m = /^(ET|GPL|SURICATA|ETPRO)\s+(\S+)\s+(.*)$/.exec(name);
                return {label: m ? m[3] : name, sub: m ? m[2] : '', value: n, title: name};
            });
        $(`#${this.id}-sig`).html(topList(sigItems, '#e5202e', this.t('nothing', 'No threats')));
        const srcItems = Object.entries(srcCount).sort((a, b) => b[1].n - a[1].n).slice(0, 5)
            .map(([ip, v]) => ({label: ip, sub: v.dst, value: v.n}));
        $(`#${this.id}-src`).html(topList(srcItems, '#ff3b47', this.t('nothing', 'No threats')));

        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
