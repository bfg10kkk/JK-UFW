/*
 * jk-ufw: country blocking at a glance: a small world map with the blocked countries in red and how many packets
 * the two block rules dropped. Settings live on Firewall › Country Blocking (/ui/firewall/geoblock).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, fmtNum, plural} from './JkUfwCommon.js';

const ALIAS = 'jkufw_geoblock';
const RULE_IN = 'jk-ufw: geoblock in';
const RULE_OUT = 'jk-ufw: geoblock out';

let mapPromise = null;
function loadMap() {
    if (window.JKUFW_WORLDMAP) {
        return Promise.resolve(window.JKUFW_WORLDMAP);
    }
    if (!mapPromise) {
        mapPromise = new Promise((resolve) => {
            const s = document.createElement('script');
            s.src = '/ui/js/jkufw-worldmap.js';
            s.onload = () => resolve(window.JKUFW_WORLDMAP || null);
            s.onerror = () => resolve(null);
            document.head.appendChild(s);
        });
    }
    return mapPromise;
}

const selectedKeys = (node) => {
    if (typeof node === 'string') {
        return node.split(/[\n,]/).map((s) => s.trim()).filter(Boolean);
    }
    return Object.keys(node || {}).filter((k) => k && String(node[k].selected) === '1');
};

export default class JkUfwGeoblock extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 60;
        this.timeoutPeriod = 20000;
        this.mapDrawn = false;
        try {
            this.ru = new Intl.DisplayNames(['ru'], {type: 'region'});
        } catch (e) {
            this.ru = null;
        }
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 4};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    name(code) {
        try {
            const n = this.ru ? this.ru.of(code) : null;
            return n && n !== code ? n : code;
        } catch (e) {
            return code;
        }
    }

    getMarkup() {
        const id = this.id;
        const kpi = (key, label) => `
            <div class="jk-kpi"><div class="jk-tile-lbl">${label}</div>
            <div class="jk-tile-val" id="${id}-${key}">…</div><div class="jk-tile-sub" id="${id}-${key}-sub">&nbsp;</div></div>`;
        return $(`
            <div class="jk jk-pad">
                <style>
                    .jkgw-map { display:block; width:100%; height:auto; margin:6px 0 8px; }
                    .jkgw-map path, .jkgw-map circle { fill:#26262d; stroke:#0e0e11; stroke-width:.5; vector-effect:non-scaling-stroke; }
                    .jkgw-map .on { fill:#e5202e; stroke:#5a0c12; }
                    .jkgw-map.off .on { fill:#7a2a30; }
                    .jkgw-chips { display:flex; flex-wrap:wrap; gap:5px; }
                    .jkgw-chips span { font-size:11.5px; font-weight:600; padding:2px 8px; border-radius:999px; background:rgba(229,32,46,.12);
                        border:1px solid rgba(229,32,46,.4); white-space:nowrap; }
                </style>
                <div class="jk-kpis">
                    ${kpi('state', `<i class="fa fa-globe"></i>${this.t('blocking', 'Blocking')}`)}
                    ${kpi('in', `<span class="jk-dot bad"></span>${this.t('inbound', 'Inbound dropped')}`)}
                    ${kpi('out', `<span class="jk-dot warn"></span>${this.t('outbound', 'Outbound dropped')}`)}
                </div>
                <svg class="jkgw-map" id="${id}-map" xmlns="http://www.w3.org/2000/svg"></svg>
                <div class="jk-sec"><span>${this.t('countries', 'Blocked countries')}</span>
                    <a href="/ui/firewall/geoblock">${this.t('settings', 'Settings')} →</a></div>
                <div class="jkgw-chips" id="${id}-chips"></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        const map = await loadMap();
        const svg = document.getElementById(`${this.id}-map`);
        if (!map || !svg) {
            $(svg).hide();
            return;
        }
        const ns = 'http://www.w3.org/2000/svg';
        svg.setAttribute('viewBox', `0 0 ${map.w} ${map.h}`);
        Object.entries(map.paths).forEach(([code, d]) => {
            const p = document.createElementNS(ns, 'path');
            p.setAttribute('d', d);
            p.setAttribute('data-c', code);
            svg.appendChild(p);
        });
        Object.entries(map.dots || {}).forEach(([code, xy]) => {
            const c = document.createElementNS(ns, 'circle');
            c.setAttribute('cx', xy[0]);
            c.setAttribute('cy', xy[1]);
            c.setAttribute('r', 3.5);
            c.setAttribute('data-c', code);
            svg.appendChild(c);
        });
        this.mapDrawn = true;
    }

    async onWidgetTick() {
        let codes = [];
        let rules = [];
        try {
            const u = await this.ajaxCall(`/api/firewall/alias/get_alias_uuid/${ALIAS}`);
            if (u && u.uuid) {
                const item = await this.ajaxCall(`/api/firewall/alias/get_item/${u.uuid}`);
                codes = selectedKeys(((item || {}).alias || {}).content).filter((c) => /^[A-Z]{2}$/.test(c));
            }
        } catch (e) {
            codes = [];
        }
        try {
            const res = await this.ajaxCall('/api/firewall/filter/search_rule?show_all=1',
                JSON.stringify({current: 1, rowCount: -1, searchPhrase: 'jk-ufw: geoblock'}), 'POST');
            rules = (res && res.rows) || [];
        } catch (e) {
            rules = [];
        }
        const rIn = rules.find((r) => r.description === RULE_IN);
        const rOut = rules.find((r) => r.description === RULE_OUT);
        const inOn = !!rIn && String(rIn.enabled) === '1';
        const outOn = !!rOut && String(rOut.enabled) === '1';
        const active = (inOn || outOn) && codes.length > 0;
        const n = codes.length;

        $(`#${this.id}-state`).html(active ? `<span style="color:#ff3b47">${fmtNum(n)}</span>`
            : `<span style="color:#8d8d98">${this.t('off', 'Off')}</span>`);
        $(`#${this.id}-state-sub`).html(active ? plural(n, 'страна', 'страны', 'стран')
            : `<a href="/ui/firewall/geoblock">${this.t('enable', 'Turn on')} →</a>`);
        [['in', rIn, inOn], ['out', rOut, outOn]].forEach(([k, r, on]) => {
            $(`#${this.id}-${k}`).text(on ? fmtNum(r.packets || 0) : '—');
            $(`#${this.id}-${k}-sub`).text(on ? this.t('packets', 'packets') : this.t('rule_off', 'rule off'));
        });

        const svg = document.getElementById(`${this.id}-map`);
        if (svg && this.mapDrawn) {
            const set = new Set(codes);
            svg.classList.toggle('off', !active);
            svg.querySelectorAll('[data-c]').forEach((el) => el.classList.toggle('on', set.has(el.getAttribute('data-c'))));
        }
        const names = codes.map((c) => this.name(c)).sort((a, b) => a.localeCompare(b, 'ru'));
        const shown = names.slice(0, 12).map((x) => `<span>${esc(x)}</span>`).join('');
        $(`#${this.id}-chips`).html(n ? shown + (n > 12 ? `<span>+${n - 12}</span>` : '')
            : `<div class="jk-empty" style="padding:6px 0">${this.t('none', 'No countries blocked')}</div>`);

        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
