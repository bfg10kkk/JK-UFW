/*
 * jk-ufw: firewall activity from the live filter log (blocked vs passed, top sources and ports).
 * Only rules with logging enabled appear in the log (the default deny rule logs by default).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtNum, plural, stackedBars, topList} from './JkUfwCommon.js';

const SERVICES = {
    20: 'FTP-data', 21: 'FTP', 22: 'SSH', 23: 'Telnet', 25: 'SMTP', 53: 'DNS', 67: 'DHCP', 69: 'TFTP', 80: 'HTTP',
    110: 'POP3', 123: 'NTP', 135: 'MS-RPC', 137: 'NetBIOS', 138: 'NetBIOS', 139: 'NetBIOS', 143: 'IMAP', 161: 'SNMP',
    389: 'LDAP', 443: 'HTTPS', 445: 'SMB', 465: 'SMTPS', 500: 'IKE', 514: 'Syslog', 587: 'SMTP', 853: 'DoT', 993: 'IMAPS',
    995: 'POP3S', 1194: 'OpenVPN', 1433: 'MSSQL', 1723: 'PPTP', 1900: 'SSDP', 2323: 'Telnet', 3306: 'MySQL',
    3389: 'RDP', 4500: 'IPsec', 5060: 'SIP', 5353: 'mDNS', 5432: 'PostgreSQL', 5900: 'VNC', 6379: 'Redis',
    8080: 'HTTP-alt', 8443: 'HTTPS-alt', 8888: 'HTTP-alt', 9200: 'Elastic', 27017: 'MongoDB', 51820: 'WireGuard'
};

export default class JkUfwSecurity extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
        this.timeoutPeriod = 15000;
        this.configurable = true;
        this.ifNames = {};
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 4};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    async getWidgetOptions() {
        return {
            window: {
                title: this.t('window', 'Time window'),
                type: 'select',
                options: [
                    {value: '15', label: `15 ${this.t('minutes', 'min')}`},
                    {value: '30', label: `30 ${this.t('minutes', 'min')}`},
                    {value: '60', label: `60 ${this.t('minutes', 'min')}`},
                    {value: '180', label: `3 ${this.t('hours', 'h')}`}
                ],
                default: '30'
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
                    ${kpi('blocked', `<span class="jk-dot bad"></span>${this.t('blocked', 'Blocked')}`)}
                    ${kpi('passed', `<span class="jk-dot ok"></span>${this.t('passed', 'Passed')}`)}
                    ${kpi('sources', `<i class="fa fa-user-secret"></i>${this.t('sources', 'Sources')}`)}
                    ${kpi('port', `<i class="fa fa-crosshairs"></i>${this.t('top_port', 'Top target')}`)}
                </div>
                <div class="jk-sec"><span>${this.t('per_minute', 'Events per minute')}</span>
                    <span class="jk-legend"><span><i style="background:#e5202e"></i>${this.t('blocked', 'Blocked')}</span>
                    <span><i style="background:#3f3f48"></i>${this.t('passed', 'Passed')}</span></span></div>
                <div class="jk-chart" id="${id}-chart"></div>
                <div class="jk-axis" id="${id}-axis"></div>
                <div class="jk-cols">
                    <div><div class="jk-sec"><span>${this.t('top_sources', 'Top blocked sources')}</span></div><div id="${id}-src"></div></div>
                    <div><div class="jk-sec"><span>${this.t('top_ports', 'Top blocked ports')}</span>
                        <a href="/ui/diagnostics/firewall/log">${this.t('open_log', 'Open log')} →</a></div><div id="${id}-ports"></div></div>
                </div>
                <div class="jk-note">${this.t('note', 'Only rules with logging enabled are counted.')}</div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        try {
            this.ifNames = await this.ajaxCall('/api/diagnostics/interface/get_interface_names') || {};
        } catch (e) {
            this.ifNames = {};
        }
    }

    async onWidgetTick() {
        const config = await this.getWidgetConfig();
        const windowMin = parseInt(config.window, 10) || 30;
        let log = null;
        try {
            log = await this.ajaxCall('/api/diagnostics/firewall/log', {limit: 2500});
        } catch (e) {
            log = null;
        }
        if (!Array.isArray(log)) {
            $(`#${this.id}-chart`).html(`<div class="jk-empty">${this.t('unavailable', 'Data unavailable')}</div>`);
            return;
        }

        const now = Date.now();
        const from = now - windowMin * 60000;
        const buckets = Math.min(windowMin, 60);
        const bucketMs = windowMin * 60000 / buckets;
        const blockedSeries = new Array(buckets).fill(0);
        const passedSeries = new Array(buckets).fill(0);
        const srcCount = {};
        const portCount = {};
        let blocked = 0;
        let passed = 0;
        let oldest = now;

        log.forEach((r) => {
            const ts = Date.parse(String(r.__timestamp__ || '').replace(' ', 'T'));
            if (!Number.isFinite(ts) || ts < from || ts > now + 60000) {
                return;
            }
            oldest = Math.min(oldest, ts);
            const idx = Math.min(buckets - 1, Math.max(0, Math.floor((ts - from) / bucketMs)));
            if (r.action === 'block') {
                blocked++;
                blockedSeries[idx]++;
                if (r.src) {
                    const k = r.src;
                    srcCount[k] = srcCount[k] || {n: 0, intf: r.interface};
                    srcCount[k].n++;
                }
                if (r.dstport) {
                    const k = `${r.dstport}/${String(r.protoname || '').toLowerCase()}`;
                    portCount[k] = (portCount[k] || 0) + 1;
                }
            } else if (r.action === 'pass') {
                passed++;
                passedSeries[idx]++;
            }
        });

        const total = blocked + passed;
        const sources = Object.keys(srcCount).length;
        const topPorts = Object.entries(portCount).sort((a, b) => b[1] - a[1]).slice(0, 5);
        const portLabel = (key) => {
            const [port, proto] = key.split('/');
            return {label: SERVICES[port] ? `${SERVICES[port]}` : `${this.t('port', 'Port')} ${port}`, sub: `${port}/${proto}`};
        };

        $(`#${this.id}-blocked`).text(fmtNum(blocked));
        $(`#${this.id}-blocked-sub`).text(total ? `${(blocked / total * 100).toFixed(0)}% ${this.t('of_events', 'of events')}` : ' ');
        $(`#${this.id}-passed`).text(fmtNum(passed));
        $(`#${this.id}-passed-sub`).text(`${this.t('for', 'in')} ${windowMin} ${this.t('minutes', 'min')}`);
        $(`#${this.id}-sources`).text(fmtNum(sources));
        $(`#${this.id}-sources-sub`).text(`${plural(sources, 'адрес', 'адреса', 'адресов')} ${this.t('blocked_lc', 'blocked')}`);
        if (topPorts.length) {
            const p = portLabel(topPorts[0][0]);
            $(`#${this.id}-port`).text(p.label);
            $(`#${this.id}-port-sub`).text(`${p.sub} · ${fmtNum(topPorts[0][1])}`);
        } else {
            $(`#${this.id}-port`).text('—');
            $(`#${this.id}-port-sub`).html('&nbsp;');
        }

        $(`#${this.id}-chart`).html(stackedBars([
            {values: blockedSeries, color: '#e5202e'},
            {values: passedSeries, color: '#3f3f48'}
        ]));
        $(`#${this.id}-axis`).html(`<span>−${windowMin} ${this.t('minutes', 'min')}</span><span>−${Math.round(windowMin / 2)} ${this.t('minutes', 'min')}</span><span>${this.t('now', 'now')}</span>`);

        const srcItems = Object.entries(srcCount).sort((a, b) => b[1].n - a[1].n).slice(0, 5)
            .map(([ip, v]) => ({label: ip, sub: this.ifNames[v.intf] || v.intf || '', value: v.n}));
        $(`#${this.id}-src`).html(topList(srcItems, '#e5202e', this.t('nothing', 'Nothing blocked')));
        $(`#${this.id}-ports`).html(topList(topPorts.map(([k, n]) => ({...portLabel(k), value: n})), '#ff3b47',
            this.t('nothing', 'Nothing blocked')));

        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
