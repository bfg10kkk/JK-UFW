/*
 * jk-ufw: interfaces shown as a port panel with link / activity LEDs and live traffic.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtRate} from './JkUfwCommon.js';

function speedOf(media) {
    const m = /(\d+(?:\.\d+)?)\s*(G)?base/i.exec(String(media || ''));
    if (!m) {
        return '';
    }
    const mbps = Number(m[1]) * (m[2] ? 1000 : 1);
    return mbps >= 1000 ? `${+(mbps / 1000).toFixed(1)} Гбит/с` : `${mbps} Мбит/с`;
}

function portSvg(up, active) {
    const pins = Array.from({length: 8}, (_, i) =>
        `<rect x="${11.2 + i * 3.1}" y="9.5" width="1.6" height="5" rx=".5" fill="${up ? '#c9a227' : '#4a4a52'}"/>`).join('');
    return `<svg width="46" height="38" viewBox="0 0 46 38" aria-hidden="true">
        <rect x="1" y="1" width="44" height="36" rx="6" fill="#0d0d10" stroke="${up ? '#3a3a42' : '#2a2a31'}"/>
        <path d="M8 8h30v16h-8v5h-14v-5h-8z" fill="#050506" stroke="#26262c"/>
        ${pins}
        <rect x="4" y="3.5" width="6" height="2.6" rx="1" fill="${up ? '#22c55e' : '#2a2a31'}"/>
        <rect x="36" y="3.5" width="6" height="2.6" rx="1" fill="${active ? '#f5a524' : '#2a2a31'}" class="${active ? 'jk-led-act' : ''}"/>
    </svg>`;
}

export default class JkUfwPorts extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
        this.ports = [];
        this.rates = {};
        this.lastTime = null;
        this.selected = null;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    getMarkup() {
        return $(`
            <div class="jk jk-pad">
                <div class="jk-ports" id="${this.id}-ports"><div class="jk-empty">${this.t('loading', 'Loading…')}</div></div>
                <div class="jk-detail" id="${this.id}-detail" style="display:none"></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        $(`#${this.id}-ports`).on('click', '.jk-port', (e) => {
            this.selected = $(e.currentTarget).data('if');
            this._render();
        });
        super.openEventSource('/api/diagnostics/traffic/stream/1', this._onTraffic.bind(this));
    }

    _onTraffic(event) {
        if (!event || !event.data) {
            return;
        }
        let data;
        try {
            data = JSON.parse(event.data);
        } catch (e) {
            return;
        }
        const elapsed = this.lastTime ? Math.max(data.time - this.lastTime, 0.2) : 1;
        this.lastTime = data.time;
        Object.entries(data.interfaces || {}).forEach(([key, intf]) => {
            this.rates[key] = {
                rx: (Number(intf.inbytes) || 0) * 8 / elapsed,
                tx: (Number(intf.outbytes) || 0) * 8 / elapsed
            };
        });
        this._renderRates();
    }

    async onWidgetTick() {
        let data = null;
        try {
            data = await this.ajaxCall('/api/interfaces/overview/interfaces_info');
        } catch (e) {
            data = null;
        }
        const rows = ((data && data.rows) || []).filter((r) =>
            r.config && r.identifier && r.enabled !== false && !(r.config.virtual === '1'));
        this.ports = rows.map((r) => ({
            id: r.identifier,
            name: r.description || r.identifier.toUpperCase(),
            device: r.device || r.config.if || '',
            up: String(r.status || '').toLowerCase() === 'up',
            status: r.status || '',
            media: r.media || r.cell_mode || '',
            mac: r.macaddr || '',
            ipv4: r.addr4 || '',
            ipv6: r.addr6 || '',
            type: r.link_type || '',
            vlan: r.vlan_tag,
            mtu: r.mtu || ''
        }));
        if (!this.selected || !this.ports.some((p) => p.id === this.selected)) {
            this.selected = (this.ports.find((p) => p.id === 'wan') || this.ports[0] || {}).id || null;
        }
        this._render();
    }

    _render() {
        const $ports = $(`#${this.id}-ports`);
        if (!this.ports.length) {
            $ports.html(`<div class="jk-empty">${this.t('none', 'No interfaces')}</div>`);
            $(`#${this.id}-detail`).hide();
            return;
        }
        $ports.html(this.ports.map((p) => {
            const r = this.rates[p.id] || {rx: 0, tx: 0};
            const active = p.up && (r.rx + r.tx) > 2000;
            return `<div class="jk-port${p.up ? '' : ' down'}${p.id === this.selected ? ' sel' : ''}" data-if="${esc(p.id)}" title="${esc(p.device)}">
                <span id="${this.id}-svg-${esc(p.id)}">${portSvg(p.up, active)}</span>
                <div class="jk-port-name">${esc(p.name)}</div>
                <div class="jk-port-sub">${p.up ? (esc(speedOf(p.media)) || esc(p.device)) : esc(this.t('no_link', 'no link'))}</div>
                <div class="jk-port-rate" id="${this.id}-rate-${esc(p.id)}"></div>
            </div>`;
        }).join(''));
        this._renderRates();
        this._renderDetail();
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }

    _renderRates() {
        this.ports.forEach((p) => {
            const r = this.rates[p.id];
            const $rate = $(`#${this.id}-rate-${p.id}`);
            if (!$rate.length) {
                return;
            }
            $rate.html(p.up && r ? `<span class="jk-down">▼</span> ${fmtRate(r.rx)}<br><span class="jk-muted">▲ ${fmtRate(r.tx)}</span>` : '&nbsp;<br>&nbsp;');
            const active = p.up && r && (r.rx + r.tx) > 2000;
            const $svg = $(`#${this.id}-svg-${p.id}`);
            if ($svg.data('act') !== active) {
                $svg.data('act', active).html(portSvg(p.up, active));
            }
        });
        const sel = this.ports.find((p) => p.id === this.selected);
        if (sel) {
            const r = this.rates[sel.id] || {rx: 0, tx: 0};
            $(`#${this.id}-d-rx`).text(fmtRate(r.rx));
            $(`#${this.id}-d-tx`).text(fmtRate(r.tx));
        }
    }

    _renderDetail() {
        const p = this.ports.find((x) => x.id === this.selected);
        const $d = $(`#${this.id}-detail`);
        if (!p) {
            $d.hide();
            return;
        }
        const types = {dhcp: 'DHCP', static: this.t('static', 'Static'), pppoe: 'PPPoE', none: '—'};
        const kv = [
            [this.t('device', 'Device'), p.device],
            [this.t('status', 'Status'), p.up ? this.t('up', 'connected') : (p.status || this.t('down', 'down'))],
            [this.t('media', 'Media'), p.media || '—'],
            ['IPv4', p.ipv4 || '—'],
            ['IPv6', p.ipv6 || '—'],
            [this.t('addressing', 'Addressing'), types[p.type] || p.type || '—'],
            ['MAC', p.mac || '—']
        ];
        if (p.vlan) {
            kv.push(['VLAN', p.vlan]);
        }
        if (p.mtu) {
            kv.push(['MTU', p.mtu]);
        }
        $d.show().html(`
            <div class="jk-gw-top" style="margin-bottom:10px">
                <span class="jk-dot ${p.up ? 'ok' : 'bad'}"></span>
                <span class="jk-gw-name"><a href="/interfaces.php?if=${encodeURIComponent(p.id)}">${esc(p.name)}</a></span>
                <span class="jk-gw-addr">${esc(speedOf(p.media))}</span>
                <span class="jk-gw-state"><span class="jk-down">▼</span> <span id="${this.id}-d-rx">—</span>
                    &nbsp; <span class="jk-muted">▲</span> <span id="${this.id}-d-tx">—</span></span>
            </div>
            <dl class="jk-kv">${kv.map(([k, v]) => `<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join('')}</dl>`);
        this._renderRates();
    }
}
