/*
 * jk-ufw: attack protection at a glance: is an attack going on, how many addresses are blocked,
 * how many packets are dropped, how full the connection table is. Settings: Firewall › Attack Protection.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc} from './JkUfwCommon.js';

const STYLE = `
.jkdd-head { display:flex; align-items:center; gap:10px; margin-bottom:10px; }
.jkdd-ic { width:34px; height:34px; border-radius:10px; display:grid; place-items:center; background:#202026; color:#8d8d98; flex:none; font-size:15px; }
.jkdd-ic.ok { background:rgba(34,197,94,.12); color:#22c55e; }
.jkdd-ic.warn { background:rgba(245,165,36,.12); color:#f5a524; }
.jkdd-ic.bad { background:rgba(229,32,46,.16); color:#ff3b47; box-shadow:0 0 0 3px rgba(229,32,46,.12); }
.jkdd-m { flex:1; min-width:0; }
.jkdd-t { font-weight:700; font-size:14px; }
.jkdd-s { color:#8d8d98; font-size:11.5px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkdd-kp { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:8px; }
.jkdd-kp > div { background:#18181c; border:1px solid #232329; border-radius:9px; padding:8px 9px; min-width:0; }
.jkdd-kp .l { color:#8d8d98; font-size:10px; font-weight:600; text-transform:uppercase; letter-spacing:.05em; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.jkdd-kp .v { font-weight:700; font-size:17px; margin-top:2px; white-space:nowrap; }
.jkdd-kp .v small { font-size:10.5px; color:#8d8d98; margin-left:2px; font-weight:600; }
.jkdd-sp { height:38px; margin-top:10px; }
.jkdd-sp svg { width:100%; height:100%; display:block; }
.jkdd-ev { margin-top:8px; padding:8px 10px; border-radius:8px; background:#18181c; border:1px solid #232329; color:#8d8d98; font-size:11.5px; }
.jkdd-ev b { color:#e8e8ec; font-weight:600; }
`;

const fmt = (n) => {
    if (n == null || !isFinite(n)) { return '—'; }
    if (n >= 1e6) { return (n / 1e6).toFixed(1) + 'M'; }
    if (n >= 1e4) { return Math.round(n / 1e3) + 'k'; }
    return String(Math.round(n));
};

export default class JkUfwDdos extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
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
        if (!document.getElementById('jkdd-style')) {
            $('head').append(`<style id="jkdd-style">${STYLE}</style>`);
        }
    }

    async onWidgetTick() {
        let st = null;
        try {
            st = await this.ajaxCall('/api/jkufw/ddos/status');
        } catch (e) {
            st = null;
        }
        const $b = $(`#${this.id}-body`);
        if (!st || !st.stats) {
            $b.html(`<div class="jk-empty">${this.t('error', 'No data')}</div>`);
            return;
        }
        const s = st.stats;
        const hist = (s.history || []).slice(-60);
        const last = hist.length ? hist[hist.length - 1] : {};
        const level = st.enabled ? (last.level || 'calm') : 'off';
        const look = {
            off: ['', 'fa-shield', this.t('off', 'Protection is off')],
            calm: ['ok', 'fa-shield', this.t('calm', 'Calm')],
            elevated: ['warn', 'fa-exclamation-triangle', this.t('elevated', 'Elevated activity')],
            attack: ['bad', 'fa-bolt', this.t('attack', 'Attack in progress')]
        }[level] || ['', 'fa-shield', ''];
        const ifs = (st.interfaces || []).filter((i) => i.protected).map((i) => i.descr);
        const sub = st.enabled ? `${this.t('protected', 'Protected')}: ${esc(ifs.join(', ') || '—')}` : this.t('hint', 'DDoS limits, threat feeds, SIEM');
        const head = `<div class="jkdd-head"><div class="jkdd-ic ${look[0]}"><i class="fa ${look[1]}"></i></div>
            <div class="jkdd-m"><div class="jkdd-t">${esc(look[2])}</div><div class="jkdd-s">${sub}</div></div>
            ${st.enabled ? '' : `<a class="jk-chip acc" href="/ui/jkufw/ddos">${this.t('enable', 'Turn on')}</a>`}</div>`;
        const usage = s.limit ? Math.round(s.states / s.limit * 100) : null;
        const kp = `<div class="jkdd-kp">
            <div><div class="l">${this.t('blocked', 'Blocked')}</div><div class="v">${fmt((s.blocked || []).length)}<small>${this.t('ips', 'IPs')}</small></div></div>
            <div><div class="l">${this.t('dropped', 'Dropped')}</div><div class="v">${fmt(last.rate_block)}<small>${this.t('pps', 'pkt/s')}</small></div></div>
            <div><div class="l">${this.t('states', 'Connections')}</div><div class="v">${usage == null ? '—' : usage}<small>%</small></div></div></div>`;

        let spark = '';
        const vals = hist.map((h) => h.rate_block || 0);
        if (vals.length > 1) {
            const max = Math.max(10, ...vals);
            const pts = vals.map((v, i) => `${(i / (vals.length - 1) * 100).toFixed(2)},${(36 - v / max * 32).toFixed(2)}`);
            spark = `<div class="jkdd-sp"><svg viewBox="0 0 100 38" preserveAspectRatio="none">
                <polygon points="0,38 ${pts.join(' ')} 100,38" fill="rgba(229,32,46,.16)"/>
                <polyline points="${pts.join(' ')}" fill="none" stroke="#ff3b47" stroke-width="1.4" vector-effect="non-scaling-stroke"/></svg></div>`;
        }

        let ev = '';
        const e = (s.events || [])[0];
        if (e) {
            const when = new Date(e.time * 1000).toLocaleString('ru-RU', {day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit'});
            const txt = {
                limit: `${this.t('ev_limit', 'blocked')}: <b>${esc(e.address)}</b>`,
                manual: `${this.t('ev_manual', 'blocked by hand')}: <b>${esc(e.address)}</b>`,
                syn: `<b>${this.t('ev_syn', 'SYN flood')}</b>`,
                flood: `<b>${this.t('ev_flood', 'Flood')}</b> · ${fmt(e.count)} ${this.t('pps', 'pkt/s')}`,
                table: `<b>${this.t('ev_table', 'Connection table')}</b> ${e.count}%`,
                over: `<b>${this.t('ev_over', 'Attack is over')}</b>`
            }[e.code] || esc(e.text);
            ev = `<div class="jkdd-ev"><i class="fa fa-history"></i> ${txt} · ${esc(when)}</div>`;
        }
        $b.html(head + kp + spark + ev);
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
