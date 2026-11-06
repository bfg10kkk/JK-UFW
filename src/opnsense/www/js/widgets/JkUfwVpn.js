/*
 * jk-ufw: remote access at a glance (WireGuard peers and OpenVPN client sessions).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, avatar, ago, fmtBytes} from './JkUfwCommon.js';

export default class JkUfwVpn extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
        this.configurable = true;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    async getWidgetOptions() {
        return {
            offline: {
                title: this.t('show_offline', 'Show offline peers'),
                type: 'checkbox',
                default: true
            }
        };
    }

    getMarkup() {
        return $(`
            <div class="jk jk-cl">
                <div class="jk-cl-head" id="${this.id}-head"><span class="jk-cl-total">…</span></div>
                <div id="${this.id}-list"></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
    }

    async onWidgetTick() {
        const config = await this.getWidgetConfig();
        const [wg, ovpn] = await Promise.all([
            this.ajaxCall('/api/wireguard/service/show').catch(() => null),
            this.ajaxCall('/api/openvpn/service/search_sessions', JSON.stringify({type: ['server']}), 'POST').catch(() => null)
        ]);

        const items = [];
        ((wg && wg.rows) || []).filter((r) => r.type === 'peer').forEach((r) => {
            const age = r['latest-handshake-age'];
            const state = r['peer-status'] === 'online' ? 'ok' : (r['peer-status'] === 'stale' ? 'warn' : 'bad');
            items.push({
                kind: 'WireGuard',
                name: r.name || (r['public-key'] || '').slice(0, 10) + '…',
                tunnel: r.ifname || r.if || '',
                addr: r['allowed-ips'] || '',
                endpoint: r.endpoint && r.endpoint !== '(none)' ? r.endpoint : '',
                state: state,
                when: age === null || age === undefined ? this.t('never', 'never') : ago(age),
                rx: Number(r['transfer-rx']) || 0,
                tx: Number(r['transfer-tx']) || 0
            });
        });
        ((ovpn && ovpn.rows) || []).filter((r) => r.is_client).forEach((r) => {
            items.push({
                kind: 'OpenVPN',
                name: r.common_name || r.username || '?',
                tunnel: r.description || '',
                addr: r.virtual_address || '',
                endpoint: r.real_address || '',
                state: r.status === 'failed' ? 'bad' : 'ok',
                when: r.connected_since || '',
                rx: Number(r.bytes_received) || 0,
                tx: Number(r.bytes_sent) || 0
            });
        });

        const online = items.filter((i) => i.state === 'ok').length;
        const kinds = [...new Set(items.map((i) => i.kind))];
        $(`#${this.id}-head`).html(`<span class="jk-cl-total">${online}</span>
            <span class="jk-muted" style="margin-right:6px">${this.t('online_of', 'online of')} ${items.length}</span>
            ${kinds.map((k) => `<span class="jk-chip">${esc(k)} · ${items.filter((i) => i.kind === k).length}</span>`).join('')}`);

        const order = {ok: 0, warn: 1, bad: 2};
        const shown = items.filter((i) => config.offline || i.state !== 'bad')
            .sort((a, b) => order[a.state] - order[b.state] || (b.rx + b.tx) - (a.rx + a.tx));
        if (!items.length) {
            $(`#${this.id}-list`).html(`<div class="jk-empty">${this.t('none', 'No VPN tunnels configured')}<br>
                <a href="/ui/wireguard/remote">WireGuard + QR</a> · <a href="/ui/openvpn/instances">OpenVPN</a></div>`);
        } else if (!shown.length) {
            $(`#${this.id}-list`).html(`<div class="jk-empty">${this.t('nobody', 'Nobody is connected')}</div>`);
        } else {
            $(`#${this.id}-list`).html(shown.map((i) => `
                <div class="jk-row" title="${esc(i.endpoint)}">
                    <div style="position:relative">${avatar(i.name)}
                        <span class="jk-dot ${i.state}" style="position:absolute;right:-1px;bottom:-1px;border:2px solid #131316;width:11px;height:11px;box-shadow:none"></span></div>
                    <div class="jk-row-main">
                        <div class="jk-row-name">${esc(i.name)}</div>
                        <div class="jk-row-sub">${[i.kind + (i.tunnel ? ` · ${i.tunnel}` : ''), i.addr].filter(Boolean).map(esc).join(' · ')}</div>
                    </div>
                    <div class="jk-row-rate">
                        <div>${esc(i.when)}</div>
                        <div class="jk-muted"><span class="jk-down">▼</span> ${fmtBytes(i.rx)} ▲ ${fmtBytes(i.tx)}</div>
                    </div>
                </div>`).join(''));
        }
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
