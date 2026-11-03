/*
 * jk-ufw: large live throughput chart for one interface (download / upload).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, rateParts, fmtRate, niceMax} from './JkUfwCommon.js';

const W = 1000;
const H = 200;

export default class JkUfwTraffic extends BaseWidget {
    constructor(config) {
        super(config);
        this.configurable = true;
        this.points = 180;
        this.rx = [];
        this.tx = [];
        this.lastTime = null;
        this.peak = {rx: 0, tx: 0};
        this.hoverIdx = null;
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 4};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    async getWidgetOptions() {
        let options = [{value: 'wan', label: 'WAN'}];
        try {
            const data = await this.ajaxCall('/api/diagnostics/traffic/interface');
            options = Object.entries(data.interfaces || {}).map(([key, intf]) => ({value: key, label: intf.name || key}));
        } catch (e) { /* keep default */ }
        return {
            interface: {
                title: this.t('interface', 'Interface'),
                type: 'select',
                options: options,
                default: options.some((o) => o.value === 'wan') ? 'wan' : (options[0] ? options[0].value : 'wan')
            },
            window: {
                title: this.t('window', 'Time window'),
                type: 'select',
                options: [
                    {value: '60', label: '1 min'},
                    {value: '180', label: '3 min'},
                    {value: '300', label: '5 min'},
                    {value: '600', label: '10 min'}
                ],
                default: '180'
            }
        };
    }

    getMarkup() {
        const id = this.id;
        return $(`
            <div class="jk jk-tr">
                <div class="jk-tr-head">
                    <div class="jk-tr-stat">
                        <div class="jk-tile-lbl"><i class="fa fa-arrow-down jk-down"></i>${this.t('download', 'Download')}</div>
                        <div class="jk-tile-val" id="${id}-rx">0<small>бит/с</small></div>
                    </div>
                    <div class="jk-tr-stat">
                        <div class="jk-tile-lbl"><i class="fa fa-arrow-up jk-up"></i>${this.t('upload', 'Upload')}</div>
                        <div class="jk-tile-val" id="${id}-tx">0<small>бит/с</small></div>
                    </div>
                    <div class="jk-tr-stat" style="margin-left:auto;text-align:right">
                        <div class="jk-tile-lbl" style="justify-content:flex-end">${this.t('peak', 'Peak')}</div>
                        <div class="jk-tile-sub" id="${id}-peak">—</div>
                    </div>
                </div>
                <div class="jk-tr-chart" id="${id}-chart">
                    <svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none">
                        <defs>
                            <linearGradient id="${id}-grx" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0" stop-color="#e5202e" stop-opacity=".45"/>
                                <stop offset="1" stop-color="#e5202e" stop-opacity="0"/>
                            </linearGradient>
                            <linearGradient id="${id}-gtx" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="0" stop-color="#a1a1aa" stop-opacity=".18"/>
                                <stop offset="1" stop-color="#a1a1aa" stop-opacity="0"/>
                            </linearGradient>
                        </defs>
                        <g id="${id}-grid"></g>
                        <path id="${id}-txa" fill="url(#${id}-gtx)"/>
                        <path id="${id}-txl" fill="none" stroke="#a1a1aa" stroke-width="1.5" stroke-dasharray="4 3" vector-effect="non-scaling-stroke"/>
                        <path id="${id}-rxa" fill="url(#${id}-grx)"/>
                        <path id="${id}-rxl" fill="none" stroke="#ff3b47" stroke-width="2" vector-effect="non-scaling-stroke"/>
                        <line id="${id}-cursor" y1="0" y2="${H}" stroke="#ffffff" stroke-opacity=".35" stroke-width="1" vector-effect="non-scaling-stroke" style="display:none"/>
                    </svg>
                    <div id="${id}-ylab"></div>
                    <div class="jk-tr-tip" id="${id}-tip"></div>
                </div>
                <div class="jk-tr-x"><span id="${id}-xstart"></span><span>${this.t('now', 'now')}</span></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        const config = await this.getWidgetConfig();
        this.intfKey = config.interface || 'wan';
        this.points = parseInt(config.window, 10) || 180;
        $(`#${this.id}-xstart`).text(`-${this.points >= 120 ? `${Math.round(this.points / 60)} min` : `${this.points} s`}`);
        this.rx = new Array(this.points).fill(0);
        this.tx = new Array(this.points).fill(0);
        this._bindHover();
        this._draw();
        super.openEventSource('/api/diagnostics/traffic/stream/1', this._onTraffic.bind(this));
    }

    _bindHover() {
        const $chart = $(`#${this.id}-chart`);
        $chart.on('mousemove', (ev) => {
            const rect = $chart[0].getBoundingClientRect();
            const frac = Math.min(Math.max((ev.clientX - rect.left) / rect.width, 0), 1);
            this.hoverIdx = Math.round(frac * (this.points - 1));
            this._drawHover();
        });
        $chart.on('mouseleave', () => {
            this.hoverIdx = null;
            $(`#${this.id}-cursor`).hide();
            $(`#${this.id}-tip`).hide();
        });
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
        const intf = (data.interfaces || {})[this.intfKey];
        if (!intf) {
            return;
        }
        const elapsed = this.lastTime ? Math.max(data.time - this.lastTime, 0.2) : 1;
        this.lastTime = data.time;
        const rx = (Number(intf.inbytes) || 0) * 8 / elapsed;
        const tx = (Number(intf.outbytes) || 0) * 8 / elapsed;
        this.rx.push(rx);
        this.rx.shift();
        this.tx.push(tx);
        this.tx.shift();
        this.peak.rx = Math.max(this.peak.rx, rx);
        this.peak.tx = Math.max(this.peak.tx, tx);

        let [v, u] = rateParts(rx);
        $(`#${this.id}-rx`).html(`${v}<small>${u}</small>`);
        [v, u] = rateParts(tx);
        $(`#${this.id}-tx`).html(`${v}<small>${u}</small>`);
        $(`#${this.id}-peak`).html(`<span class="jk-down">▼ ${fmtRate(this.peak.rx)}</span> &nbsp; ▲ ${fmtRate(this.peak.tx)}`);
        this._draw();
        if (this.hoverIdx !== null) {
            this._drawHover();
        }
    }

    _path(values, max, area) {
        const step = W / (values.length - 1);
        let d = '';
        values.forEach((val, i) => {
            const x = (i * step).toFixed(1);
            const y = (H - (val / max) * (H - 6)).toFixed(1);
            d += (i ? 'L' : 'M') + x + ' ' + y;
        });
        return area ? `${d}L${W} ${H}L0 ${H}Z` : d;
    }

    _draw() {
        this.max = niceMax(Math.max(...this.rx, ...this.tx));
        const id = this.id;
        $(`#${id}-rxa`).attr('d', this._path(this.rx, this.max, true));
        $(`#${id}-rxl`).attr('d', this._path(this.rx, this.max, false));
        $(`#${id}-txa`).attr('d', this._path(this.tx, this.max, true));
        $(`#${id}-txl`).attr('d', this._path(this.tx, this.max, false));

        let grid = '';
        let labels = '';
        for (const f of [0.25, 0.5, 0.75, 1]) {
            const y = H - f * (H - 6);
            grid += `<line x1="0" x2="${W}" y1="${y}" y2="${y}" stroke="#ffffff" stroke-opacity=".06" stroke-width="1" vector-effect="non-scaling-stroke"/>`;
            labels += `<span class="jk-tr-ylab" style="top:${(y / H * 100).toFixed(2)}%">${fmtRate(this.max * f)}</span>`;
        }
        grid += `<line x1="0" x2="${W}" y1="${H}" y2="${H}" stroke="#ffffff" stroke-opacity=".12" stroke-width="1" vector-effect="non-scaling-stroke"/>`;
        $(`#${id}-grid`).html(grid);
        $(`#${id}-ylab`).html(labels);
    }

    _drawHover() {
        const i = this.hoverIdx;
        const x = i * W / (this.points - 1);
        $(`#${this.id}-cursor`).attr({x1: x, x2: x}).show();
        const secs = this.points - 1 - i;
        const $tip = $(`#${this.id}-tip`);
        $tip.html(`<div class="jk-muted">-${secs} s</div>
            <div><span class="jk-down">▼</span> ${fmtRate(this.rx[i])}</div>
            <div><span class="jk-up">▲</span> ${fmtRate(this.tx[i])}</div>`).show();
        const pct = i / (this.points - 1);
        $tip.css(pct > 0.6 ? {left: 'auto', right: `${((1 - pct) * 100 + 1).toFixed(1)}%`} : {right: 'auto', left: `${(pct * 100 + 1).toFixed(1)}%`});
    }
}
