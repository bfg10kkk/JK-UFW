/*
 * jk-ufw: internet / gateway health (latency, jitter, loss, availability history).
 * History is sampled while the dashboard is open and kept in the browser (localStorage).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, num, history, sparkPath} from './JkUfwCommon.js';

const HIST_LEN = 120; /* samples per gateway, one per tick (10 s) => 20 minutes */

export default class JkUfwInternet extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 10;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    getMarkup() {
        return $(`<div class="jk jk-pad"><div id="${this.id}-list"><div class="jk-empty">${this.t('loading', 'Loading…')}</div></div></div>`);
    }

    async onMarkupRendered() {
        injectStyles();
    }

    /* label_class is language independent, status is a translated text */
    _state(gw) {
        const lc = String(gw.label_class || '');
        const label = gw.status || '?';
        if (lc.includes('text-danger')) {
            return ['bad', label];
        }
        if (lc.includes('text-warning')) {
            return ['warn', label];
        }
        if (lc.includes('text-success')) {
            return ['ok', label];
        }
        const s = String(gw.status || '').toLowerCase();
        if (s === 'online' || s === 'none') {
            return ['ok', label];
        }
        if (s.includes('offline') || s.includes('down')) {
            return ['bad', label];
        }
        return ['', label];
    }

    async onWidgetTick() {
        let data = null;
        try {
            data = await this.ajaxCall('/api/routing/settings/search_gateway');
        } catch (e) {
            data = null;
        }
        const rows = ((data && data.rows) || []).filter((r) => !r.disabled || r.disabled === '0' || r.disabled === false);
        const $list = $(`#${this.id}-list`);
        if (!rows.length) {
            $list.html(`<div class="jk-empty"><a href="/ui/routing/configuration">${this.t('none', 'No gateways configured')}</a></div>`);
            return;
        }
        rows.sort((a, b) => (b.defaultgw ? 1 : 0) - (a.defaultgw ? 1 : 0) || String(a.name).localeCompare(String(b.name)));

        const now = Math.floor(Date.now() / 1000);
        const cards = rows.map((gw) => {
            const [cls, label] = this._state(gw);
            const delay = num(gw.delay);
            const jitter = num(gw.stddev);
            const loss = num(gw.loss);
            const hist = history(`jkufw-gw-${gw.uuid || gw.name}`, {t: now, d: delay, l: loss, s: cls}, HIST_LEN);
            const recent = hist.filter((h) => now - h.t < HIST_LEN * this.tickTimeout * 1.5);

            const okCount = recent.filter((h) => h.s === 'ok').length;
            const avail = recent.length ? (okCount / recent.length * 100) : null;
            const delays = recent.map((h) => (h.d === null || h.d === undefined ? 0 : h.d));
            const maxDelay = Math.max(...delays, 1) * 1.15;
            const line = sparkPath(delays, maxDelay);
            const strip = Array.from({length: 40}, (_, i) => {
                const h = recent[recent.length - 40 + i];
                return `<i class="${h ? h.s : ''}"></i>`;
            }).join('');
            const minutes = Math.max(1, Math.round(recent.length * this.tickTimeout / 60));

            const stat = (title, value, unit) => `
                <div><div class="jk-tile-lbl">${title}</div>
                <div class="jk-tile-val">${value === null ? '—' : value}${value === null ? '' : `<small>${unit}</small>`}</div></div>`;

            return `
            <div class="jk-gw">
                <div class="jk-gw-top">
                    <span class="jk-dot ${cls}"></span>
                    <span class="jk-gw-name"><a href="/ui/routing/configuration#edit=${encodeURIComponent(gw.uuid || '')}">${esc(gw.name)}</a></span>
                    ${gw.defaultgw ? `<span class="jk-chip acc">${this.t('active', 'active')}</span>` : ''}
                    <span class="jk-gw-addr">${esc(gw.gateway || gw.address || '')}${gw.interface_descr ? ` · ${esc(gw.interface_descr)}` : ''}</span>
                    <span class="jk-gw-state" style="color:${{ok: '#4ade80', bad: '#ff6b74', warn: '#f5a524'}[cls] || '#8d8d98'}">${esc(label)}</span>
                </div>
                <div class="jk-gw-stats">
                    ${stat(this.t('rtt', 'Latency'), delay === null ? null : delay.toFixed(1), 'мс')}
                    ${stat(this.t('jitter', 'Jitter'), jitter === null ? null : jitter.toFixed(1), 'мс')}
                    ${stat(this.t('loss', 'Loss'), loss === null ? null : loss.toFixed(loss % 1 ? 1 : 0), '%')}
                    ${stat(this.t('availability', 'Availability'), avail === null ? null : avail.toFixed(avail === 100 ? 0 : 1), '%')}
                </div>
                <div class="jk-gw-spark">
                    <svg viewBox="0 0 100 34" preserveAspectRatio="none">
                        ${line ? `<path d="${line}L100 34L0 34Z" fill="rgba(229,32,46,.16)"/>
                        <path d="${line}" fill="none" stroke="#ff3b47" stroke-width="1.4" vector-effect="non-scaling-stroke"/>` : ''}
                    </svg>
                </div>
                <div class="jk-strip" title="${this.t('history', 'Connection history')}">${strip}</div>
                <div class="jk-axis"><span>${minutes} ${this.t('min_ago', 'min ago')}</span><span>${this.t('now', 'now')}</span></div>
            </div>`;
        }).join('');
        $list.html(cards);
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
