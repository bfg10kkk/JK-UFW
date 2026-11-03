/*
 * jk-ufw dashboard widgets: shared helpers and styles.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */

const CSS = `
.jk { --jk-accent:#e5202e; --jk-accent2:#ff3b47; --jk-surface:#18181c; --jk-border:#232329; --jk-muted:#8d8d98; --jk-text:#e8e8ec; --jk-ok:#22c55e; --jk-warn:#f5a524;
  color: var(--jk-text); font-size: 13px; text-align: left; }
.jk * { box-sizing: border-box; }
.jk-muted { color: var(--jk-muted); }
.jk-ov { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; padding: 12px; }
.jk-tile { background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 10px; padding: 12px 14px; min-height: 92px;
  display: flex; flex-direction: column; justify-content: space-between; position: relative; overflow: hidden; }
.jk-tile > * { position: relative; z-index: 1; }
.jk-tile > .jk-spark { position: absolute; z-index: 0; }
.jk-tile-lbl { color: var(--jk-muted); font-size: 11px; font-weight: 600; letter-spacing: .06em; text-transform: uppercase; display: flex; align-items: center; gap: 6px; }
.jk-tile-val { font-size: 24px; font-weight: 700; letter-spacing: -.02em; line-height: 1.15; white-space: nowrap; }
.jk-tile-val small { font-size: 13px; font-weight: 500; color: var(--jk-muted); margin-left: 3px; }
.jk-tile-sub { color: var(--jk-muted); font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.jk-tile-ring { display: flex; align-items: center; gap: 12px; }
.jk-tile-wide { grid-column: span 2; }
.jk-dot { width: 8px; height: 8px; border-radius: 50%; display: inline-block; background: var(--jk-muted); flex: none; }
.jk-dot.ok { background: var(--jk-ok); box-shadow: 0 0 0 4px rgba(34,197,94,.15); }
.jk-dot.bad { background: var(--jk-accent2); box-shadow: 0 0 0 4px rgba(229,32,46,.18); }
.jk-dot.warn { background: var(--jk-warn); box-shadow: 0 0 0 4px rgba(245,165,36,.15); }
.jk-down { color: var(--jk-accent2); }
.jk-up { color: #c9c9d1; }
.jk-bar { height: 6px; border-radius: 6px; background: #26262c; overflow: hidden; }
.jk-bar > i { display: block; height: 100%; background: var(--jk-accent); border-radius: 6px; transition: width .4s; }
.jk-spark { position: absolute; left: 0; bottom: 0; width: 100%; height: 30px; z-index: 0; opacity: .35; pointer-events: none; }

.jk-tr { padding: 12px 14px 10px; }
.jk-tr-head { display: flex; flex-wrap: wrap; gap: 22px; align-items: flex-end; margin-bottom: 8px; }
.jk-tr-stat .jk-tile-val { font-size: 20px; }
.jk-tr-chart { position: relative; height: 210px; }
.jk-tr-chart svg { position: absolute; inset: 0; width: 100%; height: 100%; overflow: visible; }
.jk-tr-ylab { position: absolute; right: 0; font-size: 10px; color: var(--jk-muted); transform: translateY(-50%); background: #131316; padding: 0 3px; }
.jk-tr-tip { position: absolute; top: 4px; background: #1d1d22; border: 1px solid #2e2e35; border-radius: 8px; padding: 6px 9px; font-size: 12px;
  pointer-events: none; white-space: nowrap; display: none; box-shadow: 0 10px 30px rgba(0,0,0,.5); z-index: 2; }
.jk-tr-x { display: flex; justify-content: space-between; color: var(--jk-muted); font-size: 10px; margin-top: 4px; }

.jk-cl { padding: 8px 6px 10px; }
.jk-cl-head { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; padding: 4px 8px 10px; }
.jk-cl-total { font-size: 22px; font-weight: 700; margin-right: 8px; }
.jk-chip { background: #222228; border: 1px solid #2e2e35; color: #c9c9d1; border-radius: 999px; padding: 2px 9px; font-size: 11px; font-weight: 600; white-space: nowrap; }
.jk-row { display: flex; align-items: center; gap: 10px; padding: 7px 8px; border-radius: 8px; }
.jk-row:hover { background: #1e1e23; }
.jk-av { width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 12px; color: #fff; flex: none; }
.jk-row-main { flex: 1; min-width: 0; }
.jk-row-name { font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.jk-row-sub { color: var(--jk-muted); font-size: 11.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.jk-row-rate { text-align: right; font-size: 11.5px; white-space: nowrap; min-width: 86px; }
.jk-row-rate .jk-bar { margin-top: 4px; height: 4px; }
.jk-empty { color: var(--jk-muted); padding: 18px; text-align: center; }

.jk-pad { padding: 12px 14px; }
.jk-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(118px, 1fr)); gap: 8px; margin-bottom: 4px; }
.jk-kpi { background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 10px; padding: 9px 11px; min-width: 0; }
.jk-kpi .jk-tile-val { font-size: 20px; }
.jk-kpi .jk-tile-sub { margin-top: 2px; }
.jk-sec { color: var(--jk-muted); font-size: 11px; font-weight: 600; letter-spacing: .06em; text-transform: uppercase; margin: 14px 0 6px;
  display: flex; justify-content: space-between; align-items: center; gap: 10px; }
.jk-sec a { color: var(--jk-muted); text-transform: none; letter-spacing: 0; font-weight: 500; }
.jk-sec a:hover { color: var(--jk-accent2); }
.jk-cols { display: grid; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); gap: 0 18px; }
.jk-top { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 3px 10px; align-items: center; padding: 6px 0 5px; border-bottom: 1px solid #1d1d22; }
.jk-top:last-child { border-bottom: 0; }
.jk-top-l { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-weight: 600; }
.jk-top-l small { color: var(--jk-muted); font-weight: 500; margin-left: 6px; }
.jk-top-v { font-variant-numeric: tabular-nums; color: #c9c9d1; font-size: 12px; }
.jk-top .jk-bar { grid-column: 1 / -1; height: 3px; }
.jk-chart { position: relative; height: 110px; margin-top: 4px; }
.jk-chart svg { width: 100%; height: 100%; display: block; overflow: visible; }
.jk-axis { display: flex; justify-content: space-between; color: var(--jk-muted); font-size: 10px; margin-top: 3px; }
.jk-legend { display: flex; gap: 14px; font-size: 11.5px; color: var(--jk-muted); flex-wrap: wrap; }
.jk-legend i { display: inline-block; width: 9px; height: 9px; border-radius: 2px; margin-right: 5px; vertical-align: -1px; }
.jk-note { color: var(--jk-muted); font-size: 11px; margin-top: 8px; }
.jk-strip { display: flex; gap: 2px; height: 18px; }
.jk-strip i { flex: 1; border-radius: 2px; background: #26262c; min-width: 2px; }
.jk-strip i.ok { background: #1f9d50; } .jk-strip i.warn { background: #f5a524; } .jk-strip i.bad { background: #ff3b47; }

.jk-gw { background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 10px; padding: 12px 14px; margin-bottom: 10px; }
.jk-gw:last-child { margin-bottom: 0; }
.jk-gw-top { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.jk-gw-name { font-weight: 700; font-size: 14px; }
.jk-gw-name a { color: inherit; }
.jk-gw-addr { color: var(--jk-muted); font-size: 12px; }
.jk-gw-state { margin-left: auto; font-weight: 600; font-size: 12px; }
.jk-gw-stats { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px; margin: 10px 0 8px; }
.jk-gw-stats .jk-tile-val { font-size: 19px; }
.jk-gw-spark { height: 46px; position: relative; margin-bottom: 8px; }
.jk-gw-spark svg { position: absolute; inset: 0; width: 100%; height: 100%; }
.jk-chip.acc { background: rgba(229,32,46,.14); border-color: rgba(229,32,46,.45); color: #ff6b74; }
.jk-chip.ok { background: rgba(34,197,94,.12); border-color: rgba(34,197,94,.4); color: #4ade80; }

.jk-ports { display: grid; grid-template-columns: repeat(auto-fill, minmax(118px, 1fr)); gap: 10px; }
.jk-port { background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 10px; padding: 10px 8px 9px; cursor: pointer; text-align: center;
  transition: border-color .15s, background .15s; min-width: 0; }
.jk-port:hover { background: #1c1c21; }
.jk-port.sel { border-color: var(--jk-accent); box-shadow: inset 0 0 0 1px var(--jk-accent); }
.jk-port.down { opacity: .55; }
.jk-port svg { display: block; margin: 0 auto 6px; }
.jk-port-name { font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.jk-port-sub { color: var(--jk-muted); font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.jk-port-rate { font-size: 11px; margin-top: 4px; white-space: nowrap; font-variant-numeric: tabular-nums; }
@keyframes jk-blink { 0%, 100% { opacity: 1; } 50% { opacity: .25; } }
.jk-led-act { animation: jk-blink .5s steps(2, end) infinite; }
.jk-detail { margin-top: 12px; background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 10px; padding: 12px 14px; }
.jk-kv { display: grid; grid-template-columns: max-content minmax(0, 1fr); gap: 5px 14px; font-size: 12.5px; }
.jk-kv dt { color: var(--jk-muted); font-weight: 500; }
.jk-kv dd { margin: 0; overflow-wrap: anywhere; }

.jk-dev { display: flex; gap: 14px; align-items: center; margin-bottom: 12px; }
.jk-dev-name { font-size: 17px; font-weight: 700; letter-spacing: -.01em; }
.jk-dev-sub { color: var(--jk-muted); font-size: 12px; }
.jk-rings { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 8px; }
.jk-rk { background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 10px; padding: 10px; display: flex; align-items: center; gap: 10px; min-width: 0; }
.jk-rk .jk-tile-val { font-size: 17px; }
.jk-rk .jk-tile-lbl, .jk-rk .jk-tile-sub { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }

.jk-svc { display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 6px; }
.jk-svc-i { display: flex; align-items: center; gap: 8px; background: var(--jk-surface); border: 1px solid var(--jk-border); border-radius: 8px; padding: 6px 6px 6px 10px; font-size: 12px; min-width: 0; }
.jk-svc-i.stopped { border-color: rgba(229,32,46,.45); }
.jk-svc-i .n { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.jk-svc-i button { background: none; border: 0; color: var(--jk-muted); padding: 2px 5px; border-radius: 6px; cursor: pointer; line-height: 1; }
.jk-svc-i button:hover { color: #fff; background: #2a2a31; }
.jk-svc-i button:disabled { opacity: .4; cursor: default; }
.jk-tabs { display: flex; gap: 4px; }
.jk-tab { background: none; border: 1px solid transparent; color: var(--jk-muted); border-radius: 999px; padding: 2px 10px; font-size: 11.5px; cursor: pointer; }
.jk-tab.on { background: #222228; border-color: #2e2e35; color: var(--jk-text); }
`;

export function injectStyles() {
    if (document.getElementById('jk-ufw-widget-css')) {
        return;
    }
    const style = document.createElement('style');
    style.id = 'jk-ufw-widget-css';
    style.textContent = CSS;
    document.head.appendChild(style);
}

export function esc(value) {
    return String(value ?? '').replace(/[&<>"']/g, (c) => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
}

/* bits per second -> [value, unit] */
export function rateParts(bps) {
    bps = Number(bps) || 0;
    const units = ['бит/с', 'Кбит/с', 'Мбит/с', 'Гбит/с', 'Тбит/с'];
    let i = 0;
    while (bps >= 1000 && i < units.length - 1) {
        bps /= 1000;
        i++;
    }
    const digits = bps >= 100 || i === 0 ? 0 : (bps >= 10 ? 1 : 2);
    return [bps.toFixed(digits), units[i]];
}

export function fmtRate(bps) {
    const [v, u] = rateParts(bps);
    return `${v} ${u}`;
}

/* round axis maximum up to a "nice" number */
export function niceMax(v) {
    if (!v || v <= 0) {
        return 1000;
    }
    const p = Math.pow(10, Math.floor(Math.log10(v)));
    for (const m of [1, 2, 2.5, 5, 10]) {
        if (v <= m * p) {
            return m * p;
        }
    }
    return 10 * p;
}

export function ring(pct, size = 46, stroke = 5, color = '#e5202e') {
    pct = Math.max(0, Math.min(100, Number(pct) || 0));
    const r = (size - stroke) / 2;
    const c = 2 * Math.PI * r;
    const off = c * (1 - pct / 100);
    const col = pct >= 90 ? '#ff3b47' : (pct >= 75 ? '#f5a524' : color);
    return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" style="flex:none">
        <circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="#26262c" stroke-width="${stroke}"/>
        <circle cx="${size / 2}" cy="${size / 2}" r="${r}" fill="none" stroke="${col}" stroke-width="${stroke}" stroke-linecap="round"
            stroke-dasharray="${c.toFixed(2)}" stroke-dashoffset="${off.toFixed(2)}" transform="rotate(-90 ${size / 2} ${size / 2})"
            style="transition: stroke-dashoffset .5s"/>
    </svg>`;
}

const AV_COLORS = ['#e5202e', '#b91c3c', '#7c3aed', '#2563eb', '#0891b2', '#059669', '#ca8a04', '#ea580c', '#64748b', '#be185d'];

export function avatar(label) {
    const s = String(label || '?');
    let h = 0;
    for (let i = 0; i < s.length; i++) {
        h = (h * 31 + s.charCodeAt(i)) >>> 0;
    }
    const words = s.replace(/[^\p{L}\p{N} ]/gu, ' ').trim().split(/\s+/);
    const initials = ((words[0] || '?')[0] + (words[1] ? words[1][0] : (words[0] || '')[1] || '')).toUpperCase();
    return `<div class="jk-av" style="background:${AV_COLORS[h % AV_COLORS.length]}">${esc(initials)}</div>`;
}

/* small sparkline path for a series, in a 100x34 box */
export function sparkPath(values, max) {
    if (values.length < 2) {
        return '';
    }
    max = max || Math.max(...values, 1);
    const step = 100 / (values.length - 1);
    let d = '';
    values.forEach((v, i) => {
        const x = (i * step).toFixed(2);
        const y = (34 - (v / max) * 30).toFixed(2);
        d += (i ? 'L' : 'M') + x + ' ' + y;
    });
    return d;
}


export function fmtNum(n) {
    return (Number(n) || 0).toLocaleString('ru-RU');
}

export function fmtBytes(bytes) {
    let v = Number(bytes) || 0;
    const units = ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ', 'ПБ'];
    let i = 0;
    while (v >= 1024 && i < units.length - 1) {
        v /= 1024;
        i++;
    }
    return `${v.toFixed(v >= 100 || i === 0 ? 0 : 1)} ${units[i]}`;
}

/* Russian plural: plural(5, 'устройство', 'устройства', 'устройств') */
export function plural(n, one, few, many) {
    const a = Math.abs(n) % 100;
    const b = a % 10;
    if (a > 10 && a < 20) {
        return many;
    }
    if (b > 1 && b < 5) {
        return few;
    }
    return b === 1 ? one : many;
}

export function ago(seconds) {
    const s = Math.max(0, Math.round(Number(seconds) || 0));
    if (s < 10) {
        return 'только что';
    }
    if (s < 60) {
        return `${s} с назад`;
    }
    if (s < 3600) {
        return `${Math.floor(s / 60)} мин назад`;
    }
    if (s < 86400) {
        return `${Math.floor(s / 3600)} ч назад`;
    }
    return `${Math.floor(s / 86400)} дн назад`;
}

/*
 * Stacked bar chart as an SVG string.
 * series: [{values: [..], color: '#..'}], all of equal length; bottom series first.
 */
export function stackedBars(series, height = 110) {
    const n = series.length ? series[0].values.length : 0;
    if (!n) {
        return '';
    }
    const W = 1000;
    const totals = Array.from({length: n}, (_, i) => series.reduce((acc, s) => acc + (Number(s.values[i]) || 0), 0));
    const max = niceMax(Math.max(...totals, 1));
    const slot = W / n;
    const gap = Math.min(slot * 0.25, 6);
    let out = '';
    for (const f of [0.5, 1]) {
        const y = (height - f * (height - 4)).toFixed(1);
        out += `<line x1="0" x2="${W}" y1="${y}" y2="${y}" stroke="#232329" stroke-width="1" vector-effect="non-scaling-stroke" stroke-dasharray="3 4"/>`;
    }
    for (let i = 0; i < n; i++) {
        let base = height;
        series.forEach((s) => {
            const v = Number(s.values[i]) || 0;
            if (v <= 0) {
                return;
            }
            const h = Math.max(1.5, v / max * (height - 4));
            base -= h;
            out += `<rect x="${(i * slot + gap / 2).toFixed(2)}" y="${base.toFixed(2)}" width="${Math.max(slot - gap, 1).toFixed(2)}" height="${h.toFixed(2)}" rx="1.5" fill="${s.color}"/>`;
        });
    }
    return `<svg viewBox="0 0 ${W} ${height}" preserveAspectRatio="none">${out}</svg>
        <span class="jk-tr-ylab" style="top:4px">${fmtNum(max)}</span>`;
}

/* horizontal "top N" list; items: [{label, sub, value, text}] */
export function topList(items, color = '#e5202e', empty = '—') {
    if (!items.length) {
        return `<div class="jk-muted" style="padding:6px 0">${esc(empty)}</div>`;
    }
    const max = Math.max(...items.map((i) => Number(i.value) || 0), 1);
    return items.map((i) => `
        <div class="jk-top" title="${esc(i.title || i.label)}">
            <div class="jk-top-l">${esc(i.label)}${i.sub ? `<small>${esc(i.sub)}</small>` : ''}</div>
            <div class="jk-top-v">${esc(i.text ?? fmtNum(i.value))}</div>
            <div class="jk-bar"><i style="width:${((Number(i.value) || 0) / max * 100).toFixed(1)}%;background:${color}"></i></div>
        </div>`).join('');
}

/* parse "1.2 ms" / "0.0 %" / "~" into a number or null */
export function num(value) {
    const v = parseFloat(String(value ?? '').replace(',', '.'));
    return Number.isFinite(v) ? v : null;
}

/* small persistent history per key in localStorage (best effort) */
export function history(key, sample, maxLen) {
    let list = [];
    try {
        list = JSON.parse(localStorage.getItem(key) || '[]');
        if (!Array.isArray(list)) {
            list = [];
        }
    } catch (e) {
        list = [];
    }
    if (sample) {
        list.push(sample);
        while (list.length > maxLen) {
            list.shift();
        }
        try {
            localStorage.setItem(key, JSON.stringify(list));
        } catch (e) { /* storage full or disabled */ }
    }
    return list;
}
