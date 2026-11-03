/* jk-ufw: product branding. Shows NAME instead of the upstream product name everywhere in the UI. */
(function () {
  var NAME = 'jk-ufw';
  var FOOTER = 'jk-ufw';
  var UPSTREAM = /OPNsense/g;
  /* never touch form values, code/log output or the user@hostname label (real host name) */
  var SKIP = { SCRIPT: 1, STYLE: 1, TEXTAREA: 1, INPUT: 1, PRE: 1, CODE: 1, NOSCRIPT: 1 };
  /* the license page carries the legally required copyright notices: keep its text exactly as written */
  var LEGAL = location.pathname.indexOf('/ui/core/license') === 0;

  function skipped(el) {
    for (; el && el !== document.body; el = el.parentNode) {
      if (el.nodeType === 1 && (SKIP[el.tagName] || el.id === 'menu_messages' || el.isContentEditable)) return true;
      if (LEGAL && el.nodeType === 1 && el.classList && el.classList.contains('page-content-main')) return true;
    }
    return false;
  }
  function fixText(node) {
    if (node.nodeValue && node.nodeValue.indexOf('OPNsense') !== -1 && !skipped(node.parentNode)) {
      node.nodeValue = node.nodeValue.replace(UPSTREAM, NAME);
    }
  }
  function fixAttrs(el) {
    if (el.nodeType !== 1 || skipped(el)) return;
    ['title', 'placeholder', 'alt', 'data-original-title', 'aria-label'].forEach(function (a) {
      var v = el.getAttribute(a);
      if (v && v.indexOf('OPNsense') !== -1) el.setAttribute(a, v.replace(UPSTREAM, NAME));
    });
  }
  function walk(root) {
    if (!root) return;
    if (root.nodeType === 3) { fixText(root); return; }
    if (root.nodeType !== 1 || SKIP[root.tagName]) return;
    fixAttrs(root);
    var tw = document.createTreeWalker(root, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT, null);
    var n;
    while ((n = tw.nextNode())) {
      if (n.nodeType === 3) fixText(n); else fixAttrs(n);
    }
  }
  function fixTitle() {
    if (document.title.indexOf('OPNsense') !== -1) document.title = document.title.replace(UPSTREAM, NAME);
  }
  function fixFooter() {
    var foots = document.querySelectorAll('.page-foot .container-fluid, .login-foot');
    for (var i = 0; i < foots.length; i++) {
      if (foots[i].getAttribute('data-jk') === '1') continue;
      foots[i].setAttribute('data-jk', '1');
      foots[i].textContent = FOOTER;
    }
  }
  function run() {
    fixTitle();
    fixFooter();
    walk(document.body);
    if (window.MutationObserver) {
      new MutationObserver(function (muts) {
        for (var i = 0; i < muts.length; i++) {
          var m = muts[i];
          if (m.type === 'characterData') fixText(m.target);
          else if (m.type === 'attributes') fixAttrs(m.target);
          else for (var j = 0; j < m.addedNodes.length; j++) walk(m.addedNodes[j]);
        }
        fixTitle();
      }).observe(document.body, { childList: true, subtree: true, characterData: true,
        attributes: true, attributeFilter: ['title', 'placeholder', 'data-original-title'] });
      var t = document.querySelector('title');
      if (t) new MutationObserver(fixTitle).observe(t, { childList: true, characterData: true, subtree: true });
    }
  }
  fixTitle();
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run);
  else run();
})();

/* jk-ufw: recolor stock dashboard charts (Chart.js / smoothie) to the red-on-black palette */
(function () {
  var MAP = { '#d94f00': '#e5202e', '#e5e5e5': '#2a2a31', '#ffffff': '#e8e8ec' };
  var PALETTE = ['#e5202e', '#a1a1aa', '#ff8a8f', '#f5a524', '#22c55e', '#7c3aed', '#0891b2', '#be185d', '#64748b', '#ca8a04'];

  function swap(c) {
    if (typeof c !== 'string' || c.charAt(0) !== '#' || c.length < 7) return c;
    var base = c.substr(0, 7).toLowerCase();
    return MAP[base] ? MAP[base] + c.substr(7) : c;
  }
  function swapAll(v) { return Array.isArray(v) ? v.map(swap) : swap(v); }

  function patchCharts() {
    if (typeof Chart === 'undefined' || Chart.__jkufw) return;
    Chart.__jkufw = true;
    Chart.defaults.color = '#8d8d98';
    Chart.defaults.borderColor = 'rgba(255,255,255,0.06)';
    Chart.defaults.font.family = '"Inter", "Segoe UI", system-ui, -apple-system, Roboto, Arial, sans-serif';
    if (Chart.colorschemes && Chart.colorschemes.tableau && Chart.colorschemes.tableau.Classic10) {
      var arr = Chart.colorschemes.tableau.Classic10;
      for (var i = 0; i < arr.length; i++) arr[i] = PALETTE[i % PALETTE.length];
    }
    Chart.register({
      id: 'jkufwRecolor',
      beforeUpdate: function (chart) {
        (chart.data.datasets || []).forEach(function (ds) {
          ['backgroundColor', 'borderColor', 'hoverBackgroundColor', 'pointBackgroundColor'].forEach(function (k) {
            if (ds[k] !== undefined && typeof ds[k] !== 'function') ds[k] = swapAll(ds[k]);
          });
          if (chart.config.type === 'doughnut') ds.borderColor = '#131316';
        });
      }
    });
  }

  function patchSmoothie() {
    if (typeof SmoothieChart === 'undefined' || SmoothieChart.__jkufw) return;
    SmoothieChart.__jkufw = true;
    var orig = SmoothieChart.prototype.addTimeSeries;
    SmoothieChart.prototype.addTimeSeries = function (ts, opts) {
      opts = opts || {};
      if (opts.strokeStyle) opts.strokeStyle = swap(opts.strokeStyle);
      if (!opts.fillStyle || opts.fillStyle === 'transparent') opts.fillStyle = 'rgba(229,32,46,0.12)';
      return orig.call(this, ts, opts);
    };
  }

  function run() { patchCharts(); patchSmoothie(); }
  run();
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run);
})();

/* jk-ufw: icon rail navigation by default + labels for rail fly-outs */
(function () {
  try {
    if (window.localStorage && localStorage.getItem('toggle_sidebar_preset') === null) {
      localStorage.setItem('toggle_sidebar_preset', '1');
    }
  } catch (e) { /* storage unavailable */ }

  function decorateMenu() {
    var links = document.querySelectorAll('#mainmenu > div > a.list-group-item');
    for (var i = 0; i < links.length; i++) {
      var label = (links[i].textContent || '').trim();
      if (!label) continue;
      links[i].setAttribute('title', label);
      var next = links[i].nextElementSibling;
      if (next && next.tagName === 'DIV') next.setAttribute('data-jk-title', label);
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', decorateMenu);
  else decorateMenu();
})();
