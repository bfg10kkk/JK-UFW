/*
 * jk-ufw: services at a glance, stopped ones first, with one-click restart / start.
 * BSD-2-Clause, see LICENSE in the jk-ufw-theme package.
 */
import {injectStyles, esc, plural} from './JkUfwCommon.js';

export default class JkUfwServices extends BaseWidget {
    constructor(config) {
        super(config);
        this.tickTimeout = 15;
        this.busy = false;
        this.filter = 'all';
    }

    getGridOptions() {
        return {sizeToContent: true, minW: 3};
    }

    t(key, fallback) {
        return this.translations[key] ?? fallback;
    }

    getMarkup() {
        return $(`
            <div class="jk jk-pad">
                <div class="jk-gw-top" style="margin-bottom:10px">
                    <span class="jk-cl-total" id="${this.id}-run">…</span>
                    <span class="jk-muted" id="${this.id}-sum"></span>
                    <span class="jk-tabs" style="margin-left:auto">
                        <button class="jk-tab on" data-f="all">${this.t('all', 'All')}</button>
                        <button class="jk-tab" data-f="stopped">${this.t('stopped', 'Stopped')}</button>
                    </span>
                </div>
                <div class="jk-svc" id="${this.id}-list"></div>
            </div>`);
    }

    async onMarkupRendered() {
        injectStyles();
        const $root = $(`#${this.id}-list`).closest('.jk');
        $root.on('click', '.jk-tab', (e) => {
            this.filter = $(e.currentTarget).data('f');
            $root.find('.jk-tab').removeClass('on');
            $(e.currentTarget).addClass('on');
            this._render();
        });
        $root.on('click', '.jk-svc-i button', async (e) => {
            const $b = $(e.currentTarget);
            const action = $b.data('action');
            /* id is "name" or "name/instance" */
            const sid = String($b.data('sid')).split('/').map(encodeURIComponent).join('/');
            this.busy = true;
            $b.prop('disabled', true).find('i').addClass('fa-spin');
            try {
                await this.ajaxCall(`/api/core/service/${action}/${sid}`, {}, 'POST');
            } catch (err) { /* status refresh below shows the result */ }
            this.busy = false;
            await this.onWidgetTick();
        });
    }

    async onWidgetTick() {
        if (this.busy) {
            return;
        }
        let data = null;
        try {
            data = await this.ajaxCall('/api/core/service/search');
        } catch (e) {
            data = null;
        }
        this.rows = (data && data.rows) || [];
        this._render();
    }

    _render() {
        const rows = (this.rows || []).slice();
        const stopped = rows.filter((r) => !r.running);
        $(`#${this.id}-run`).text(`${rows.length - stopped.length}/${rows.length}`);
        $(`#${this.id}-sum`).html(stopped.length
            ? `<span style="color:#ff6b74">${stopped.length} ${plural(stopped.length, 'остановлена', 'остановлены', 'остановлено')}</span>`
            : this.t('all_running', 'all running'));

        rows.sort((a, b) => (a.running ? 1 : 0) - (b.running ? 1 : 0) || String(a.description).localeCompare(String(b.description)));
        const shown = this.filter === 'stopped' ? rows.filter((r) => !r.running) : rows;
        if (!shown.length) {
            $(`#${this.id}-list`).html(`<div class="jk-empty" style="grid-column:1/-1">${this.t('none_stopped', 'Nothing is stopped')}</div>`);
        } else {
            $(`#${this.id}-list`).html(shown.map((r) => {
                const action = r.running ? 'restart' : 'start';
                const btn = `<button data-action="${action}" data-sid="${esc(r.id || r.name)}"
                        title="${esc(r.running ? this.t('restart', 'Restart') : this.t('start', 'Start'))}">
                        <i class="fa ${r.running ? 'fa-refresh' : 'fa-play'}"></i></button>`;
                return `<div class="jk-svc-i${r.running ? '' : ' stopped'}" title="${esc(r.description)} (${esc(r.name)})">
                    <span class="jk-dot ${r.running ? 'ok' : 'bad'}"></span><span class="n">${esc(r.description)}</span>${btn}</div>`;
            }).join(''));
        }
        if (this.config && this.config.callbacks && this.config.callbacks.updateGrid) {
            this.config.callbacks.updateGrid();
        }
    }
}
