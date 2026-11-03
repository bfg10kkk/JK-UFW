/*
 * jk-ufw: device health card (CPU, memory, disk, temperature, swap, disks, versions).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, ring, fmtBytes} from './JkUfwCommon.js';

/* original drawing of a small 1U appliance in the jk-ufw style */
const DEVICE_SVG = `
<svg width="92" height="56" viewBox="0 0 92 56" style="flex:none" aria-hidden="true">
  <rect x="1" y="9" width="90" height="38" rx="7" fill="#1a1a1f" stroke="#2e2e35"/>
  <rect x="1" y="9" width="90" height="5" rx="2.5" fill="#e5202e" opacity=".85"/>
  <path d="M15 22 l6 -3.5 6 3.5 v7 l-6 3.5 -6 -3.5z" fill="#e5202e"/>
  <rect x="17.5" y="24" width="7" height="1.6" fill="#fff"/><rect x="17.5" y="27" width="7" height="1.6" fill="#fff"/>
  ${[0, 1, 2, 3].map((i) => `<rect x="${40 + i * 12}" y="24" width="9" height="8" rx="1.5" fill="#0b0b0d" stroke="#3a3a42"/>
  <circle cx="${42 + i * 12}" cy="36.5" r="1.3" fill="${i < 2 ? '#22c55e' : '#3a3a42'}"/>
  <circle cx="${47 + i * 12}" cy="36.5" r="1.3" fill="${i === 0 ? '#f5a524' : '#3a3a42'}"/>`).join('')}
</svg>`;

export default class JkUfwSystem extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
        this.cpuSource = null;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    getMarkup() {
        const id = this.id;
        const rk = (key, label) => `
            <div class="jk-rk"><span id="${id}-${key}-ring">${ring(0, 40, 5)}</span>
            <div style="min-width:0"><div class="jk-tile-lbl">${label}</div><div class="jk-tile-val" id="${id}-${key}">…</div>
            <div class="jk-tile-sub" id="${id}-${key}-sub"></div></div></div>`;
        return $(`
            <div class="jk jk-pad">
                <div class="jk-dev">
                    ${DEVICE_SVG}
                    <div style="min-width:0">
                        <div class="jk-dev-name" id="${id}-name">…</div>
                        <div class="jk-dev-sub" id="${id}-ver"></div>
                        <div class="jk-dev-sub" id="${id}-up"></div>
                    </div>
                </div>
                <div class="jk-rings">
                    ${rk('cpu', 'CPU')}
                    ${rk('ram', this.t('memory', 'Memory'))}
                    ${rk('disk', this.t('disk', 'Disk'))}
                    ${rk('temp', this.t('temperature', 'Temperature'))}
                </div>
                <div class="jk-sec"><span>${this.t('storage', 'Storage')}</span><span id="${id}-swap"></span></div>
                <div id="${id}-disks"></div>
                <div class="jk-sec"><span>${this.t('details', 'Details')}</span>
                    <a href="/ui/core/firmware#checkupdate">${this.t('updates', 'Check for updates')} →</a></div>
                <dl class="jk-kv" id="${id}-kv"></dl>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        this._openCpu();
    }

    _openCpu() {
        this._closeCpu();
        try {
            this.cpuSource = new EventSource('/api/diagnostics/cpu_usage/stream');
            this.cpuSource.onmessage = (event) => {
                try {
                    const pct = Math.round(Number(JSON.parse(event.data).total) || 0);
                    $(`#${this.id}-cpu-ring`).html(ring(pct, 40, 5));
                    $(`#${this.id}-cpu`).html(`${pct}<small>%</small>`);
                } catch (e) { /* ignore malformed event */ }
            };
        } catch (e) {
            this.cpuSource = null;
        }
    }

    _closeCpu() {
        if (this.cpuSource) {
            this.cpuSource.close();
            this.cpuSource = null;
        }
    }

    async onWidgetTick() {
        const call = (url) => this.ajaxCall(url).catch(() => null);
        const [info, time, res, disk, temp, swap, cpuType] = await Promise.all([
            call('/api/diagnostics/system/system_information'),
            call('/api/diagnostics/system/system_time'),
            call('/api/diagnostics/system/system_resources'),
            call('/api/diagnostics/system/system_disk'),
            call('/api/diagnostics/system/system_temperature'),
            call('/api/diagnostics/system/system_swap'),
            this.cpuType ? Promise.resolve(this.cpuType) : call('/api/diagnostics/cpu_usage/getcputype')
        ]);
        const id = this.id;

        if (info) {
            $(`#${id}-name`).text(info.name || '');
            $(`#${id}-ver`).text((info.versions || [])[0] || '');
        }
        if (time) {
            $(`#${id}-up`).text(`${this.t('uptime', 'Uptime')}: ${time.uptime || '—'}`);
        }

        const m = res && res.memory;
        if (m && m.total) {
            const pct = Math.round(Number(m.used) / Number(m.total) * 100);
            $(`#${id}-ram-ring`).html(ring(pct, 40, 5));
            $(`#${id}-ram`).html(`${pct}<small>%</small>`);
            $(`#${id}-ram-sub`).text(`${fmtBytes(m.used)} / ${fmtBytes(m.total)}`);
        }

        const devices = (disk && disk.devices) || [];
        const root = devices.find((d) => d.mountpoint === '/') || devices[0];
        if (root) {
            const pct = parseInt(root.used_pct, 10) || 0;
            $(`#${id}-disk-ring`).html(ring(pct, 40, 5));
            $(`#${id}-disk`).html(`${pct}<small>%</small>`);
            $(`#${id}-disk-sub`).text(`${root.used} / ${root.total || root.blocks}`);
        }
        const shown = devices.filter((d) => d.type !== 'tmpfs' && d.type !== 'cd9660');
        $(`#${id}-disks`).html(shown.length ? shown.map((d) => {
            const pct = parseInt(d.used_pct, 10) || 0;
            const col = pct >= 90 ? '#ff3b47' : (pct >= 75 ? '#f5a524' : '#e5202e');
            return `<div class="jk-top" title="${esc(d.device)}">
                <div class="jk-top-l">${esc(d.mountpoint)}<small>${esc(d.type)}</small></div>
                <div class="jk-top-v">${esc(d.used)} / ${esc(d.total || d.blocks)} · ${pct}%</div>
                <div class="jk-bar"><i style="width:${pct}%;background:${col}"></i></div></div>`;
        }).join('') : `<div class="jk-muted">—</div>`);

        const temps = Array.isArray(temp) ? temp.map((x) => parseFloat(x.temperature)).filter(Number.isFinite) : [];
        if (temps.length) {
            const max = Math.max(...temps);
            $(`#${id}-temp-ring`).html(ring(Math.min(100, max), 40, 5));
            $(`#${id}-temp`).html(`${max.toFixed(0)}<small>°C</small>`);
            $(`#${id}-temp-sub`).text(`${temps.length} ${this.t('sensors', 'sensors')}`);
        } else {
            $(`#${id}-temp`).text('—');
            $(`#${id}-temp-sub`).text(this.t('no_sensors', 'no sensors'));
        }

        const sw = swap && Array.isArray(swap.swap) ? swap.swap : [];
        if (sw.length) {
            const total = sw.reduce((a, s) => a + (Number(s.total) || 0), 0);
            const used = sw.reduce((a, s) => a + (Number(s.used) || 0), 0);
            $(`#${id}-swap`).text(`swap ${fmtBytes(used * 1024)} / ${fmtBytes(total * 1024)}`);
        }

        if (cpuType) {
            this.cpuType = cpuType;
        }
        const kv = [];
        const cpuName = Array.isArray(cpuType) ? cpuType[0] : cpuType;
        if (cpuName) {
            kv.push([this.t('cpu', 'Processor'), cpuName]);
        }
        if (time && time.loadavg) {
            kv.push([this.t('load', 'Load average'), time.loadavg]);
        }
        if (info && info.versions) {
            info.versions.slice(1).forEach((v) => kv.push([this.t('component', 'Component'), v]));
        }
        if (time && time.config) {
            kv.push([this.t('config', 'Config changed'), time.config]);
        }
        $(`#${id}-kv`).html(kv.map(([k, v]) => `<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join(''));

        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }

    onVisibilityChanged(visible) {
        super.onVisibilityChanged(visible);
        if (visible) {
            this._openCpu();
        } else {
            this._closeCpu();
        }
    }

    onWidgetClose() {
        super.onWidgetClose();
        this._closeCpu();
    }
}
