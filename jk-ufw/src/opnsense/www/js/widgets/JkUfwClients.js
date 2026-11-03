/*
 * jk-ufw: connected devices (ARP table + DHCP hostnames), sorted by live traffic.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtRate, avatar} from './JkUfwCommon.js';

export default class JkUfwClients extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
        this.timeoutPeriod = 15000; /* traffic/top samples for a few seconds */
        this.configurable = true;
        this.intfMap = {};
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    async getWidgetOptions() {
        return {
            limit: {
                title: this.t('limit', 'Rows'),
                type: 'select',
                options: [5, 10, 15, 25, 50].map((n) => ({value: String(n), label: String(n)})),
                default: '10'
            },
            live: {
                title: this.t('live', 'Show live traffic per device'),
                type: 'checkbox',
                default: true
            }
        };
    }

    getMarkup() {
        return $(`
            <div class="jk jk-cl">
                <div class="jk-cl-head" id="${this.id}-head"><span class="jk-cl-total">…</span></div>
                <div id="${this.id}-list"><div class="jk-empty">${this.t('loading', 'Loading…')}</div></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        try {
            const data = await this.ajaxCall('/api/diagnostics/traffic/interface');
            Object.entries(data.interfaces || {}).forEach(([key, intf]) => {
                this.intfMap[key] = intf.name || key;
            });
        } catch (e) { /* traffic per device will be unavailable */ }
    }

    async onWidgetTick() {
        const config = await this.getWidgetConfig();
        const limit = parseInt(config.limit, 10) || 10;
        const lanKeys = Object.keys(this.intfMap).filter((k) => k !== 'wan');

        const [arp, top] = await Promise.all([
            this.ajaxCall('/api/diagnostics/interface/get_arp').catch(() => null),
            (config.live && lanKeys.length)
                ? this.ajaxCall(`/api/diagnostics/traffic/top/${lanKeys.join(',')}`).catch(() => null)
                : Promise.resolve(null)
        ]);

        if (!Array.isArray(arp)) {
            $(`#${this.id}-list`).html(`<div class="jk-empty">${this.t('unavailable', 'Data unavailable')}</div>`);
            return;
        }

        const rates = {};
        if (top) {
            Object.values(top).forEach((intf) => {
                (intf.records || []).forEach((r) => {
                    rates[r.address] = {
                        rin: Number(r.rate_bits_in) || 0,
                        rout: Number(r.rate_bits_out) || 0
                    };
                });
            });
        }

        const wanName = this.intfMap.wan;
        const seen = new Set();
        const devices = [];
        const byIntf = {};
        arp.forEach((e) => {
            if (e.permanent || e.expired || !e.mac || seen.has(e.mac)) {
                return;
            }
            if (wanName && e.intf_description === wanName) {
                return;
            }
            seen.add(e.mac);
            const intfName = e.intf_description || e.intf || '';
            byIntf[intfName] = (byIntf[intfName] || 0) + 1;
            const r = rates[e.ip] || {rin: 0, rout: 0};
            devices.push({
                name: e.hostname || e.manufacturer || e.ip,
                ip: e.ip,
                mac: e.mac,
                vendor: e.manufacturer || '',
                intf: intfName,
                down: r.rin,
                up: r.rout,
                total: r.rin + r.rout
            });
        });

        devices.sort((a, b) => (b.total - a.total) || a.name.localeCompare(b.name));
        const maxTotal = Math.max(...devices.map((d) => d.total), 1);

        const chips = Object.entries(byIntf).sort((a, b) => b[1] - a[1])
            .map(([k, v]) => `<span class="jk-chip">${esc(k)} · ${v}</span>`).join('');
        $(`#${this.id}-head`).html(`<span class="jk-cl-total">${devices.length}</span>
            <span class="jk-muted" style="margin-right:6px">${this.t('devices', 'devices')}</span>${chips}`);

        if (!devices.length) {
            $(`#${this.id}-list`).html(`<div class="jk-empty">${this.t('none', 'No devices found')}</div>`);
            return;
        }

        const rows = devices.slice(0, limit).map((d) => {
            const sub = [d.ip, d.vendor && d.vendor !== d.name ? d.vendor : ''].filter(Boolean).map(esc).join(' · ');
            const rate = (config.live && top)
                ? `<div class="jk-row-rate">
                        <div><span class="jk-down">▼</span> ${d.down ? fmtRate(d.down) : '—'}</div>
                        <div class="jk-muted">▲ ${d.up ? fmtRate(d.up) : '—'}</div>
                        <div class="jk-bar"><i style="width:${(d.total / maxTotal * 100).toFixed(1)}%"></i></div>
                   </div>`
                : `<span class="jk-chip">${esc(d.intf)}</span>`;
            return `<div class="jk-row" title="${esc(d.mac)}">
                    ${avatar(d.name)}
                    <div class="jk-row-main">
                        <div class="jk-row-name">${esc(d.name)}</div>
                        <div class="jk-row-sub">${sub}${config.live && top && d.intf ? ` · ${esc(d.intf)}` : ''}</div>
                    </div>
                    ${rate}
                </div>`;
        }).join('');
        $(`#${this.id}-list`).html(rows);
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
