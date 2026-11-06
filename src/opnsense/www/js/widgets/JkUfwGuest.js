/*
 * jk-ufw: guest network at a glance (captive portal zone created by Services > Captive Portal > Guest Network).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, avatar, fmtBytes} from './JkUfwCommon.js';

const DESC = 'jk-ufw guest';

export default class JkUfwGuest extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 20;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
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
        const zones = await this.ajaxCall('/api/captiveportal/settings/search_zones',
            JSON.stringify({current: 1, rowCount: -1, searchPhrase: ''}), 'POST').catch(() => null);
        const zone = ((zones && zones.rows) || []).find((z) => z.description === DESC);
        const head = $(`#${this.id}-head`);
        const list = $(`#${this.id}-list`);
        if (!zone) {
            head.html(`<span class="jk-muted">${this.t('none', 'Guest network is not set up')}</span>`);
            list.html(`<div class="jk-empty"><a href="/ui/captiveportal/guest">${this.t('setup', 'Set up')} →</a></div>`);
        } else {
            const res = await this.ajaxCall('/api/captiveportal/session/search',
                JSON.stringify({current: 1, rowCount: -1, searchPhrase: '', selected_zones: [String(zone.zoneid)]}), 'POST').catch(() => null);
            const rows = ((res && res.rows) || []).filter((s) => String(s.zoneid) === String(zone.zoneid));
            // portal accounting: bytes_in are sent by the guest, bytes_out are received by it
            const down = rows.reduce((s, r) => s + (Number(r.bytes_out) || 0), 0);
            const up = rows.reduce((s, r) => s + (Number(r.bytes_in) || 0), 0);
            const on = String(zone.enabled) === '1';
            head.html(`<span class="jk-cl-total">${rows.length}</span>
                <span class="jk-muted" style="margin-right:6px">${this.t('online', 'guests online')}</span>
                <span class="jk-chip">${on ? this.t('on', 'On') : this.t('off', 'Off')}</span>
                <span class="jk-chip"><span class="jk-down">▼</span> ${fmtBytes(down)} ▲ ${fmtBytes(up)}</span>`);
            if (!rows.length) {
                list.html(`<div class="jk-empty">${this.t('nobody', 'Nobody is connected')}</div>`);
            } else {
                list.html(rows.sort((a, b) => (Number(b.bytes_out) || 0) - (Number(a.bytes_out) || 0)).slice(0, 8).map((r) => `
                    <div class="jk-row">
                        ${avatar(r.userName || r.macAddress || r.ipAddress)}
                        <div class="jk-row-main">
                            <div class="jk-row-name">${esc(r.userName || r.ipAddress)}</div>
                            <div class="jk-row-sub">${esc([r.ipAddress, r.macAddress].filter(Boolean).join(' · '))}</div>
                        </div>
                        <div class="jk-row-rate"><div><span class="jk-down">▼</span> ${fmtBytes(r.bytes_out)}</div>
                            <div class="jk-muted">▲ ${fmtBytes(r.bytes_in)}</div></div>
                    </div>`).join(''));
            }
        }
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
