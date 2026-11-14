/*
 * jk-ufw: SD-WAN at a glance: which internet link carries the traffic now, health of every link
 * (latency, loss, state) and the last failover. Settings: Lobby › SD-WAN.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc} from './JkUfwCommon.js';

const STYLE = `
.jksw-head { display:flex; align-items:center; gap:10px; margin-bottom:10px; }
.jksw-mode { font-weight:700; font-size:14px; }
.jksw-sub { color:#8d8d98; font-size:11.5px; }
.jksw-row { display:flex; align-items:center; gap:10px; padding:8px 4px; border-top:1px solid #1d1d22; }
.jksw-row:first-child { border-top:0; }
.jksw-ic { width:30px; height:30px; border-radius:9px; display:grid; place-items:center; background:#202026; color:#8d8d98; flex:none; position:relative; }
.jksw-row.carry .jksw-ic { background:rgba(229,32,46,.12); color:#ff3b47; }
.jksw-ic .d { position:absolute; right:-2px; bottom:-2px; width:10px; height:10px; border-radius:50%; background:#3a3a42; border:2px solid #131316; }
.jksw-ic .d.ok { background:#22c55e; } .jksw-ic .d.warn { background:#f5a524; } .jksw-ic .d.bad { background:#e5202e; }
.jksw-m { flex:1; min-width:0; }
.jksw-n { font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jksw-s { color:#8d8d98; font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jksw-v { text-align:right; font-weight:700; white-space:nowrap; }
.jksw-v small { color:#8d8d98; font-weight:500; margin-left:2px; }
.jksw-tag { font-size:10.5px; font-weight:700; padding:1px 7px; border-radius:999px; background:rgba(229,32,46,.12); color:#ff3b47; margin-left:6px; }
.jksw-ev { margin-top:8px; padding:8px 10px; border-radius:8px; background:#18181c; border:1px solid #232329; color:#8d8d98; font-size:11.5px; }
.jksw-ev b { color:#e8e8ec; font-weight:600; }
`;

const STATE = {none: 'ok', loss: 'warn', delay: 'warn', 'delay+loss': 'warn', down: 'bad', force_down: 'bad'};

export default class JkUfwSdwan extends BaseWidget {
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
        return $(`<div class="jk jk-pad"><div id="${this.id}-body"><div class="jk-empty">${this.t('loading', 'Loading…')}</div></div></div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        if (!document.getElementById('jksw-style')) {
            $('head').append(`<style id="jksw-style">${STYLE}</style>`);
        }
    }

    async onWidgetTick() {
        let st = null;
        try {
            st = await this.ajaxCall('/api/jkufw/sdwan/status');
        } catch (e) {
            st = null;
        }
        const $b = $(`#${this.id}-body`);
        if (!st || !Array.isArray(st.links)) {
            $b.html(`<div class="jk-empty">${this.t('error', 'No data')}</div>`);
            return;
        }
        const name = (l) => l.label || l.descr || l.name;
        const members = st.links.filter((l) => st.members.includes(l.name));
        const shown = st.enabled && members.length ? members : st.links.filter((l) => !l.disabled);
        const pos = (l) => { const i = st.members.indexOf(l.name); return i < 0 ? 99 : i; };
        shown.sort((a, b) => pos(a) - pos(b));
        const up = members.filter((l) => STATE[l.status] === 'ok' || STATE[l.status] === 'warn').length;

        let head;
        if (!st.enabled) {
            head = `<div class="jksw-head"><div class="jksw-m"><div class="jksw-mode">${this.t('off', 'SD-WAN is off')}</div>
                <div class="jksw-sub">${this.t('links', 'Links')}: ${shown.length}</div></div>
                <a class="jk-chip acc" href="/ui/jkufw/sdwan">${this.t('enable', 'Turn on')}</a></div>`;
        } else {
            const mode = st.mode === 'balance' ? this.t('balance', 'Load balancing') : this.t('failover', 'Failover');
            head = `<div class="jksw-head"><div class="jksw-m"><div class="jksw-mode">${esc(mode)}</div>
                <div class="jksw-sub">${this.t('online', 'Online')}: ${up} ${this.t('of', 'of')} ${members.length}</div></div>
                <span class="jk-dot ${up === members.length ? 'ok' : up ? 'warn' : 'bad'}"></span></div>`;
        }

        const rows = shown.map((l) => {
            const cls = l.disabled ? '' : l.monitoring ? (STATE[l.status] || '') : 'ok';
            const carry = st.enabled && l.carrying;
            const val = cls === 'bad' ? `<span style="color:#ff6b74">${this.t('down', 'down')}</span>`
                : l.delay == null ? '—' : `${l.delay.toFixed(0)}<small>${this.t('ms', 'ms')}</small>`;
            const loss = l.loss ? ` · ${this.t('loss', 'loss')} ${l.loss.toFixed(0)}%` : '';
            return `<div class="jksw-row ${carry ? 'carry' : ''}">
                <div class="jksw-ic"><i class="fa fa-globe"></i><span class="d ${cls}"></span></div>
                <div class="jksw-m"><div class="jksw-n">${esc(name(l))}${carry ? `<span class="jksw-tag">${this.t('active', 'active')}</span>` : ''}</div>
                <div class="jksw-s">${esc(l.interface_descr)}${loss}</div></div>
                <div class="jksw-v">${val}</div></div>`;
        }).join('');

        let ev = '';
        const last = (st.events || []).find((e) => e.to === 'down' || e.from === 'down');
        if (last) {
            const l = st.links.find((x) => x.name === last.gateway);
            const when = last.time ? new Date(last.time).toLocaleString('ru-RU', {day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit'}) : '';
            ev = `<div class="jksw-ev"><i class="fa fa-history"></i> <b>${esc(l ? name(l) : last.gateway)}</b>
                ${last.to === 'down' ? this.t('went_down', 'went down') : this.t('came_back', 'came back')} · ${esc(when)}</div>`;
        }
        $b.html(head + `<div>${rows || `<div class="jk-empty">${this.t('none', 'No internet links')}</div>`}</div>` + ev);
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
