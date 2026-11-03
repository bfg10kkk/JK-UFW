/*
 * jk-ufw: network overview tiles (internet, throughput, clients, CPU, RAM, states, uptime).
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, rateParts, ring, sparkPath} from './JkUfwCommon.js';

export default class JkUfwOverview extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 10;
        this.configurable = true;
        this.lastTime = null;
        this.hist = {rx: [], tx: []};
        this.cpuSource = null;
        this.wanName = null;
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
            wan: {
                title: this.t('wan_interface', 'WAN interface'),
                type: 'select',
                options: options,
                default: options.some((o) => o.value === 'wan') ? 'wan' : (options[0] ? options[0].value : 'wan')
            }
        };
    }

    getMarkup() {
        const id = this.id;
        const tile = (key, label, body) => `
            <div class="jk-tile" id="${id}-${key}">
                <div class="jk-tile-lbl">${label}</div>
                ${body}
            </div>`;
        return $(`
            <div class="jk jk-ov">
                ${tile('inet', `<span class="jk-dot" id="${id}-inet-dot"></span>${this.t('internet', 'Internet')}`,
                    `<div class="jk-tile-val" id="${id}-inet-val">…</div><div class="jk-tile-sub" id="${id}-inet-sub">&nbsp;</div>`)}
                ${tile('rx', `<i class="fa fa-arrow-down jk-down"></i>${this.t('download', 'Download')}`,
                    `<div class="jk-tile-val" id="${id}-rx-val">0<small>бит/с</small></div>
                     <svg class="jk-spark" viewBox="0 0 100 34" preserveAspectRatio="none"><path id="${id}-rx-spark" fill="rgba(229,32,46,.18)" stroke="#ff3b47" stroke-width="1.2" vector-effect="non-scaling-stroke"/></svg>`)}
                ${tile('tx', `<i class="fa fa-arrow-up jk-up"></i>${this.t('upload', 'Upload')}`,
                    `<div class="jk-tile-val" id="${id}-tx-val">0<small>бит/с</small></div>
                     <svg class="jk-spark" viewBox="0 0 100 34" preserveAspectRatio="none"><path id="${id}-tx-spark" fill="rgba(200,200,210,.10)" stroke="#a1a1aa" stroke-width="1.2" vector-effect="non-scaling-stroke"/></svg>`)}
                ${tile('clients', `<i class="fa fa-laptop"></i>${this.t('clients', 'Clients')}`,
                    `<div class="jk-tile-val" id="${id}-clients-val">…</div><div class="jk-tile-sub" id="${id}-clients-sub">&nbsp;</div>`)}
                ${tile('cpu', 'CPU',
                    `<div class="jk-tile-ring"><span id="${id}-cpu-ring">${ring(0)}</span><div class="jk-tile-val" id="${id}-cpu-val">…</div></div>`)}
                ${tile('ram', this.t('memory', 'Memory'),
                    `<div class="jk-tile-ring"><span id="${id}-ram-ring">${ring(0)}</span><div><div class="jk-tile-val" id="${id}-ram-val">…</div><div class="jk-tile-sub" id="${id}-ram-sub"></div></div></div>`)}
                ${tile('states', `<i class="fa fa-exchange"></i>${this.t('states', 'Sessions')}`,
                    `<div class="jk-tile-val" id="${id}-states-val">…</div><div class="jk-bar"><i id="${id}-states-bar" style="width:0%"></i></div>`)}
                ${tile('uptime', `<i class="fa fa-clock-o"></i>${this.t('uptime', 'Uptime')}`,
                    `<div class="jk-tile-val" id="${id}-uptime-val" style="font-size:18px">…</div><div class="jk-tile-sub" id="${id}-uptime-sub"></div>`)}
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        const config = await this.getWidgetConfig();
        this.wanKey = config.wan || 'wan';
        super.openEventSource('/api/diagnostics/traffic/stream/1', this._onTraffic.bind(this));
        this._openCpu();
    }

    _openCpu() {
        this._closeCpu();
        try {
            this.cpuSource = new EventSource('/api/diagnostics/cpu_usage/stream');
            this.cpuSource.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    const pct = Math.round(Number(data.total) || 0);
                    $(`#${this.id}-cpu-ring`).html(ring(pct));
                    $(`#${this.id}-cpu-val`).html(`${pct}<small>%</small>`);
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
        const intf = (data.interfaces || {})[this.wanKey];
        if (!intf) {
            return;
        }
        this.wanName = intf.name || this.wanKey;
        const elapsed = this.lastTime ? Math.max(data.time - this.lastTime, 0.2) : 1;
        this.lastTime = data.time;
        const rx = (Number(intf.inbytes) || 0) * 8 / elapsed;
        const tx = (Number(intf.outbytes) || 0) * 8 / elapsed;
        for (const [k, v] of [['rx', rx], ['tx', tx]]) {
            this.hist[k].push(v);
            if (this.hist[k].length > 60) {
                this.hist[k].shift();
            }
            const [num, unit] = rateParts(v);
            $(`#${this.id}-${k}-val`).html(`${num}<small>${unit}</small>`);
        }
        const max = Math.max(...this.hist.rx, ...this.hist.tx, 1);
        for (const k of ['rx', 'tx']) {
            const line = sparkPath(this.hist[k], max);
            $(`#${this.id}-${k}-spark`).attr('d', line ? `${line}L100 34L0 34Z` : '');
        }
    }

    async onWidgetTick() {
        const call = (url) => this.ajaxCall(url).catch(() => null);
        const [gw, arp, res, time, states] = await Promise.all([
            call('/api/routing/settings/search_gateway'),
            call('/api/diagnostics/interface/get_arp'),
            call('/api/diagnostics/system/system_resources'),
            call('/api/diagnostics/system/system_time'),
            call('/api/diagnostics/firewall/pf_states')
        ]);
        this._renderGateway(gw);
        this._renderClients(arp);
        this._renderMemory(res);
        this._renderTime(time);
        this._renderStates(states);
    }

    _renderGateway(data) {
        const rows = (data && data.rows) || [];
        const gw = rows.find((r) => r.defaultgw) || rows[0];
        const $dot = $(`#${this.id}-inet-dot`).removeClass('ok bad warn');
        if (!gw) {
            $(`#${this.id}-inet-val`).text('—');
            $(`#${this.id}-inet-sub`).text(this.t('no_gateway', 'No gateway'));
            return;
        }
        /* label_class is language independent, status is a translated text */
        const lc = String(gw.label_class || '');
        const status = String(gw.status || '').toLowerCase();
        let cls = 'warn';
        let label = gw.status || '?';
        if (lc.includes('text-success') || status === 'online' || status === 'none') {
            cls = 'ok';
            label = this.t('online', 'Online');
        } else if (lc.includes('text-danger') || status.includes('offline') || status.includes('down')) {
            cls = 'bad';
            label = this.t('offline', 'Offline');
        }
        $dot.addClass(cls);
        $(`#${this.id}-inet-val`).text(label);
        const delay = gw.delay && gw.delay !== '~' ? ` · ${gw.delay}` : '';
        const loss = gw.loss && gw.loss !== '~' && parseFloat(gw.loss) > 0 ? ` · ${this.t('loss', 'loss')} ${gw.loss}` : '';
        $(`#${this.id}-inet-sub`).text(`${gw.name}${delay}${loss}`);
    }

    _renderClients(arp) {
        if (!Array.isArray(arp)) {
            return;
        }
        const seen = new Set();
        const byIntf = {};
        arp.forEach((e) => {
            if (e.permanent || e.expired || !e.mac || seen.has(e.mac)) {
                return;
            }
            if (this.wanName && e.intf_description === this.wanName) {
                return;
            }
            seen.add(e.mac);
            const name = e.intf_description || e.intf || '?';
            byIntf[name] = (byIntf[name] || 0) + 1;
        });
        $(`#${this.id}-clients-val`).text(seen.size);
        $(`#${this.id}-clients-sub`).text(Object.entries(byIntf).map(([k, v]) => `${k} ${v}`).join(' · ') || ' ');
    }

    _renderMemory(res) {
        const m = res && res.memory;
        if (!m || !m.total) {
            return;
        }
        const pct = Math.round(Number(m.used) / Number(m.total) * 100);
        $(`#${this.id}-ram-ring`).html(ring(pct));
        $(`#${this.id}-ram-val`).html(`${pct}<small>%</small>`);
        const gb = (v) => (Number(v) / 1073741824).toFixed(1);
        $(`#${this.id}-ram-sub`).text(`${gb(m.used)} / ${gb(m.total)} GB`);
    }

    _renderTime(time) {
        if (!time) {
            return;
        }
        $(`#${this.id}-uptime-val`).text(time.uptime || '—');
        $(`#${this.id}-uptime-sub`).text(time.loadavg ? `load ${time.loadavg}` : '');
    }

    _renderStates(states) {
        if (!states || states.current === undefined) {
            return;
        }
        const cur = Number(states.current) || 0;
        const lim = Number(states.limit) || 0;
        $(`#${this.id}-states-val`).html(`${cur.toLocaleString('ru-RU')}${lim ? `<small>/ ${lim.toLocaleString('ru-RU')}</small>` : ''}`);
        $(`#${this.id}-states-bar`).css('width', lim ? `${Math.min(100, cur / lim * 100).toFixed(1)}%` : '0%');
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
