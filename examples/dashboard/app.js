/* ==============================================
   NexaRail RC1 Devnet Dashboard — Application Logic
   Vanilla JS — No Dependencies
   ============================================== */

(function () {
  'use strict';

  // ──────────────────────────────────────────────
  // Configuration
  // ──────────────────────────────────────────────

  let API = 'http://localhost:1317';
  const RPC = 'http://localhost:26657';
  let autoRefreshInterval = null;
  let autoRefreshEnabled = false;
  let errorLog = [];

  // DOM references (populated on init)
  let $els = {};

  // ──────────────────────────────────────────────
  // Utilities
  // ──────────────────────────────────────────────

  function $(sel, ctx) { return (ctx || document).querySelector(sel); }

  function $$(sel, ctx) { return Array.from((ctx || document).querySelectorAll(sel)); }

  function escHtml(s) {
    if (s === null || s === undefined) return '';
    const d = document.createElement('div');
    d.textContent = String(s);
    return d.innerHTML;
  }

  function now() {
    return new Date().toLocaleTimeString();
  }

  function timestamp() {
    const d = new Date();
    return d.toLocaleDateString() + ' ' + d.toLocaleTimeString();
  }

  // ──────────────────────────────────────────────
  // Safe Fetch
  // ──────────────────────────────────────────────

  async function safeFetch(url, timeoutMs) {
    timeoutMs = timeoutMs || 5000;

    const controller = new AbortController();
    const timer = setTimeout(function () {
      controller.abort();
    }, timeoutMs);

    try {
      const res = await fetch(url, {
        signal: controller.signal,
        headers: { 'Accept': 'application/json' }
      });

      clearTimeout(timer);

      if (!res.ok) {
        let body = '';
        try {
          body = await res.text();
        } catch (_) { /* ignore */ }
        // Cosmos SDK sometimes returns 501 with "Not Implemented"
        if (body && body.length < 500) {
          return { ok: false, data: null, error: 'HTTP ' + res.status + ': ' + body.trim().substring(0, 200) };
        }
        return { ok: false, data: null, error: 'HTTP ' + res.status + ' ' + res.statusText };
      }

      let data;
      try {
        data = await res.json();
      } catch (parseErr) {
        return { ok: false, data: null, error: 'Invalid JSON response' };
      }

      return { ok: true, data: data, error: null };

    } catch (err) {
      clearTimeout(timer);

      if (err.name === 'AbortError') {
        return { ok: false, data: null, error: 'Request timed out (' + timeoutMs + 'ms)' };
      }
      if (err instanceof TypeError && err.message === 'Failed to fetch') {
        return { ok: false, data: null, error: 'Cannot connect — is the daemon running?' };
      }
      return { ok: false, data: null, error: err.message || 'Unknown network error' };
    }
  }

  // ──────────────────────────────────────────────
  // Error Logging
  // ──────────────────────────────────────────────

  function logError(section, error) {
    errorLog.push({
      time: now(),
      section: section,
      message: error
    });
    if (errorLog.length > 50) errorLog.shift();
    renderErrorLog();
  }

  // ──────────────────────────────────────────────
  // Helpers for Section Renderers
  // ──────────────────────────────────────────────

  function setCardStatus(cardId, status) {
    var el = $('#' + cardId + ' .card-status');
    if (!el) return;
    el.className = 'card-status ' + status;
    el.textContent = status;
  }

  function setCardBody(cardId, html) {
    var el = $('#' + cardId + ' .card-body');
    if (!el) return;
    el.innerHTML = html;
    el.className = 'card-body';
  }

  function showLoading(cardId) {
    var el = $('#' + cardId + ' .card-body');
    if (!el) return;
    el.className = 'card-body loading';
    el.innerHTML =
      '<div class="loading-pulse">' +
        '<span class="pulse-dot"></span>' +
        '<span class="pulse-dot"></span>' +
        '<span class="pulse-dot"></span>' +
        '<span>Loading…</span>' +
      '</div>';
    setCardStatus(cardId, 'loading');
  }

  function showEmpty(cardId, msg) {
    msg = msg || 'No data available';
    setCardBody(cardId,
      '<div class="empty-state">' +
        '<div class="empty-icon">📭</div>' +
        '<div>' + escHtml(msg) + '</div>' +
      '</div>'
    );
    setCardStatus(cardId, 'empty');
  }

  function showError(cardId, err, sectionName) {
    var msg = typeof err === 'string' ? err : (err.error || err.message || 'Unknown error');
    setCardBody(cardId,
      '<div class="error-message">⚠️ ' + escHtml(msg) + '</div>'
    );
    setCardStatus(cardId, 'error');
    logError(sectionName || cardId, msg);
  }

  function isUnimplemented(result) {
    if (!result.ok) {
      var m = result.error || '';
      return m.indexOf('501') !== -1 ||
             m.indexOf('Not Implemented') !== -1 ||
             m.indexOf('not implemented') !== -1 ||
             m.indexOf('404') !== -1;
    }
    return false;
  }

  function isEmptyResult(data) {
    if (data === null || data === undefined) return true;
    if (Array.isArray(data) && data.length === 0) return true;
    if (typeof data === 'object' && Object.keys(data).length === 0) return true;
    return false;
  }

  function isNullArray(data) {
    // e.g. merchants: null
    if (data === null) return true;
    // nested field check: data.merchants === null
    return false;
  }

  function kvRows(obj, keys) {
    if (!obj || typeof obj !== 'object') return '<div class="empty-state">No data</div>';
    return keys.map(function (k) {
      var val = obj[k];
      var display = (val === null || val === undefined)
        ? '<span style="color:#6a6a80;font-style:italic;">null</span>'
        : escHtml(String(val));
      var label = k.replace(/_/g, ' ').replace(/\b\w/g, function (c) { return c.toUpperCase(); });
      return '<div class="kv-row"><span class="kv-label">' + escHtml(label) + '</span><span class="kv-value">' + display + '</span></div>';
    }).join('');
  }

  function safeJsonStringify(data) {
    try {
      return JSON.stringify(data, null, 2);
    } catch (_) {
      return '[Circular or unstringifiable]';
    }
  }

  function highlightJson(obj) {
    var str = safeJsonStringify(obj);
    if (!str) return escHtml(str);
    // Simple colourising — wrap known patterns
    return escHtml(str)
      .replace(/"([^"]+)":/g, '<span class="json-key">"$1"</span>:')
      .replace(/"([^"]+)"/g, '<span class="json-string">"$1"</span>')
      .replace(/\b(true|false)\b/g, '<span class="json-bool">$1</span>')
      .replace(/\bnull\b/g, '<span class="json-null">null</span>')
      .replace(/\b(\d+\.?\d*)\b/g, '<span class="json-number">$1</span>');
  }

  function dataTable(headers, rows) {
    if (!rows || rows.length === 0) return '';
    var h = headers.map(function (hdr) { return '<th>' + escHtml(hdr) + '</th>'; }).join('');
    var r = rows.map(function (row) {
      return '<tr>' + row.map(function (cell) {
        return '<td>' + (cell === null || cell === undefined ? '<span style="color:#6a6a80;">—</span>' : escHtml(String(cell))) + '</td>';
      }).join('') + '</tr>';
    }).join('');
    return '<table class="data-table"><thead><tr>' + h + '</tr></thead><tbody>' + r + '</tbody></table>';
  }

  // ──────────────────────────────────────────────
  // Section Renderers
  // ──────────────────────────────────────────────

  async function renderNodeStatus() {
    showLoading('card-node-status');

    // Try both /cosmos/base/tendermint/v1beta1/node_info and /node_info
    var result = await safeFetch(API + '/cosmos/base/tendermint/v1beta1/node_info');
    if (!result.ok) {
      result = await safeFetch(API + '/node_info');
    }
    if (!result.ok) {
      // Try RPC health
      var rpcResult = await safeFetch(RPC + '/status');
      if (rpcResult.ok && rpcResult.data && rpcResult.data.result) {
        var s = rpcResult.data.result;
        var syncInfo = s.sync_info || {};
        var nodeInfo = s.node_info || {};
        var isSynced = syncInfo.catching_up === false;
        setCardBody('card-node-status',
          kvRows({
            'node_id': nodeInfo.id || nodeInfo.default_node_id || '—',
            'moniker': nodeInfo.moniker || '—',
            'network': nodeInfo.network || '—',
            'block_height': syncInfo.latest_block_height || '—',
            'catching_up': isSynced ? 'No ✓' : 'Yes ⚠️',
            'earliest_block': syncInfo.earliest_block_height || '—'
          }, ['node_id', 'moniker', 'network', 'block_height', 'catching_up', 'earliest_block'])
        );
        setCardStatus('card-node-status', 'ok');
        return;
      }
      showError('card-node-status', result, 'Node Status');
      return;
    }

    var d = result.data;
    var ni = d.node_info || d;
    var sync = d.sync_info || d;
    var isSynced = sync.catching_up === false;

    setCardBody('card-node-status',
      kvRows({
        'node_id': ni.id || ni.default_node_id || '—',
        'moniker': ni.moniker || '—',
        'network': ni.network || '—',
        'version': ni.version || '—',
        'block_height': sync.latest_block_height || sync.last_block_height || '—',
        'catching_up': isSynced ? 'No ✓' : 'Yes ⚠️',
        'earliest_block': sync.earliest_block_height || '—'
      }, ['node_id', 'moniker', 'network', 'version', 'block_height', 'catching_up', 'earliest_block'])
    );
    setCardStatus('card-node-status', 'ok');
  }

  async function renderLiveFlags() {
    showLoading('card-live-flags');

    var modules = [
      { name: 'settlement', path: '/nexa/settlement/v1/params', flagKeys: ['live_enabled', 'treasury_routing_enabled', 'burn_routing_enabled'] },
      { name: 'escrow',     path: '/nexa/escrow/v1/params',     flagKeys: ['live_enabled'] },
      { name: 'treasury',   path: '/nexa/treasury/v1/params',    flagKeys: ['live_enabled'] },
      { name: 'payout',     path: '/nexa/payout/v1/params',      flagKeys: ['live_enabled'] }
    ];

    var results = await Promise.all(modules.map(function (mod) {
      return safeFetch(API + mod.path).then(function (r) {
        return { mod: mod, result: r };
      });
    }));

    var flagHtml = '';

    results.forEach(function (item) {
      var mod = item.mod;
      var result = item.result;

      flagHtml += '<div style="margin-bottom: 4px; font-size:0.82rem; font-weight:600; color:var(--text-secondary); padding: 4px 0;">' + escHtml(mod.name.charAt(0).toUpperCase() + mod.name.slice(1)) + '</div>';

      if (!result.ok) {
        if (isUnimplemented(result)) {
          mod.flagKeys.forEach(function (k) {
            flagHtml +=
              '<div class="flag-item">' +
                '<span class="flag-name">' + escHtml(k) + '</span>' +
                '<span class="flag-indicator unknown"><span class="flag-dot amber"></span> N/A</span>' +
              '</div>';
          });
        } else {
          mod.flagKeys.forEach(function (k) {
            flagHtml +=
              '<div class="flag-item">' +
                '<span class="flag-name">' + escHtml(k) + '</span>' +
                '<span class="flag-indicator unknown"><span class="flag-dot amber"></span> ' + escHtml(result.error.substring(0, 60)) + '</span>' +
              '</div>';
          });
          logError('Live Flags', mod.name + ': ' + result.error);
        }
        return;
      }

      var params = result.data.params || result.data;
      mod.flagKeys.forEach(function (k) {
        // Walk nested path — e.g. params may wrap settlement params
        var val = resolveNestedFlag(params, k);
        var isTrue = val === true || val === 'true' || val === 1 || String(val) === 'true';

        flagHtml +=
          '<div class="flag-item">' +
            '<span class="flag-name">' + escHtml(k) + '</span>' +
            '<span class="flag-indicator ' + (isTrue ? 'pass' : 'fail') + '">' +
              '<span class="flag-dot ' + (isTrue ? 'green' : 'red') + '"></span> ' +
              (isTrue ? 'PASS' : 'FAIL') +
            '</span>' +
          '</div>';
      });
    });

    setCardBody('card-live-flags',
      '<div class="flags-grid">' + flagHtml + '</div>'
    );
    setCardStatus('card-live-flags', 'ok');
  }

  function resolveNestedFlag(params, key) {
    if (params[key] !== undefined) return params[key];
    // Walk object keys recursively
    for (var k in params) {
      if (params.hasOwnProperty(k) && typeof params[k] === 'object' && params[k] !== null) {
        var v = resolveNestedFlag(params[k], key);
        if (v !== undefined) return v;
      }
    }
    return undefined;
  }

  async function renderModuleParams() {
    showLoading('card-module-params');

    var paramEndpoints = [
      { name: 'nexarail', path: '/nexa/nexarail/v1/params' },
      { name: 'settlement', path: '/nexa/settlement/v1/params' },
      { name: 'escrow', path: '/nexa/escrow/v1/params' },
      { name: 'treasury', path: '/nexa/treasury/v1/params' },
      { name: 'payout', path: '/nexa/payout/v1/params' },
      { name: 'bank', path: '/cosmos/bank/v1beta1/params' },
      { name: 'staking', path: '/cosmos/staking/v1beta1/params' },
      { name: 'distribution', path: '/cosmos/distribution/v1beta1/params' }
    ];

    var results = await Promise.all(paramEndpoints.map(function (ep) {
      return safeFetch(API + ep.path).then(function (r) {
        return { ep: ep, result: r };
      });
    }));

    var html = '';
    var anyOk = false;

    results.forEach(function (item) {
      var ep = item.ep;
      var result = item.result;

      if (!result.ok) {
        if (isUnimplemented(result)) {
          html +=
            '<div style="margin-bottom:8px;padding-bottom:6px;border-bottom:1px solid var(--border);">' +
              '<strong style="color:var(--text-secondary);">' + escHtml(ep.name) + '</strong>' +
              ' <span style="color:var(--text-muted);font-size:0.75rem;">— not available (single-node mode)</span>' +
            '</div>';
        }
        return;
      }

      anyOk = true;
      var params = result.data.params || result.data;
      var rows = [];
      for (var k in params) {
        if (params.hasOwnProperty(k)) {
          var v = params[k];
          var display = (v === null)
            ? '<span style="color:#6a6a80;font-style:italic;">null</span>'
            : (typeof v === 'object')
              ? '<span class="json-display" style="display:inline;padding:0;background:none;border:none;max-height:none;">' + highlightJson(v) + '</span>'
              : escHtml(String(v));
          rows.push('<div class="kv-row"><span class="kv-label">' + escHtml(k) + '</span><span class="kv-value">' + display + '</span></div>');
        }
      }

      html +=
        '<div style="margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid var(--border);">' +
          '<div style="font-weight:600;color:var(--accent);font-size:0.82rem;margin-bottom:4px;">' + escHtml(ep.name) + '</div>' +
          rows.join('') +
        '</div>';
    });

    if (!anyOk) {
      showEmpty('card-module-params', 'No module params available (all endpoints unimplemented)');
      return;
    }

    setCardBody('card-module-params', html);
    setCardStatus('card-module-params', 'ok');
  }

  async function renderTreasurySummary() {
    showLoading('card-treasury-summary');

    var endpoints = [
      { name: 'total_accounts', path: '/nexa/treasury/v1/accounts' },
      { name: 'total_budgets', path: '/nexa/treasury/v1/budgets' },
      { name: 'total_grants', path: '/nexa/treasury/v1/grants' },
      { name: 'total_spend_requests', path: '/nexa/treasury/v1/spend_requests' }
    ];

    var results = await Promise.all(endpoints.map(function (ep) {
      return safeFetch(API + ep.path).then(function (r) {
        return { ep: ep, result: r };
      });
    }));

    var summary = {};
    var anyOk = false;

    results.forEach(function (item) {
      var ep = item.ep;
      var result = item.result;

      if (!result.ok) {
        summary[ep.name] = isUnimplemented(result) ? 'N/A' : 'Error: ' + result.error.substring(0, 50);
        if (!isUnimplemented(result)) {
          logError('Treasury Summary', ep.name + ': ' + result.error);
        }
        return;
      }

      anyOk = true;
      var data = result.data;
      // Count arrays
      if (Array.isArray(data)) {
        summary[ep.name] = data.length;
      } else if (data.accounts && Array.isArray(data.accounts)) {
        summary[ep.name] = data.accounts.length;
      } else if (data.budgets && Array.isArray(data.budgets)) {
        summary[ep.name] = data.budgets.length;
      } else if (data.grants && Array.isArray(data.grants)) {
        summary[ep.name] = data.grants.length;
      } else if (data.spend_requests && Array.isArray(data.spend_requests)) {
        summary[ep.name] = data.spend_requests.length;
      } else if (data.pagination) {
        // Some endpoints return pagination with total
        summary[ep.name] = data.pagination.total || 0;
      } else {
        // Count object keys
        var keys = Object.keys(data).filter(function (k) { return k !== 'pagination'; });
        summary[ep.name] = keys.length;
      }
    });

    var rows = [
      { label: 'Total Accounts', key: 'total_accounts' },
      { label: 'Total Budgets', key: 'total_budgets' },
      { label: 'Total Grants', key: 'total_grants' },
      { label: 'Total Spend Requests', key: 'total_spend_requests' }
    ];

    var html = rows.map(function (r) {
      var v = summary[r.key];
      var display = (v === undefined || v === null || v === 'N/A')
        ? '<span style="color:#6a6a80;font-style:italic;">N/A</span>'
        : (typeof v === 'string' && v.indexOf('Error') === 0)
          ? '<span style="color:var(--color-red);">' + escHtml(v) + '</span>'
          : '<strong>' + escHtml(String(v)) + '</strong>';
      return '<div class="kv-row"><span class="kv-label">' + escHtml(r.label) + '</span><span class="kv-value">' + display + '</span></div>';
    }).join('');

    setCardBody('card-treasury-summary', html);
    setCardStatus('card-treasury-summary', anyOk ? 'ok' : 'empty');
  }

  async function renderMerchantList() {
    showLoading('card-merchant-list');

    var result = await safeFetch(API + '/nexa/nexarail/v1/merchants');
    if (!result.ok) {
      if (isUnimplemented(result)) {
        showEmpty('card-merchant-list', 'Not available in single-node mode');
      } else {
        showError('card-merchant-list', result, 'Merchant List');
      }
      return;
    }

    var data = result.data;
    var merchants = data.merchants || data;

    if (merchants === null) {
      showEmpty('card-merchant-list', 'None');
      return;
    }

    if (Array.isArray(merchants) && merchants.length === 0) {
      showEmpty('card-merchant-list', 'No merchants registered');
      return;
    }

    if (Array.isArray(merchants)) {
      var headers = Object.keys(merchants[0] || {});
      var rows = merchants.map(function (m) {
        return headers.map(function (h) { return safeCell(m[h]); });
      });
      var countHtml = '<div style="margin-bottom:8px;font-size:0.78rem;color:var(--text-secondary);">Count: <strong>' + merchants.length + '</strong></div>';
      setCardBody('card-merchant-list', countHtml + dataTable(headers, rows));
      setCardStatus('card-merchant-list', 'ok');
      return;
    }

    // Object response
    setCardBody('card-merchant-list',
      '<div class="json-display">' + highlightJson(data) + '</div>'
    );
    setCardStatus('card-merchant-list', 'ok');
  }

  async function renderSettlementList() {
    showLoading('card-settlement-list');

    var result = await safeFetch(API + '/nexa/settlement/v1/settlements');
    if (!result.ok) {
      if (isUnimplemented(result)) {
        showEmpty('card-settlement-list', 'Not available in single-node mode');
      } else {
        showError('card-settlement-list', result, 'Settlement List');
      }
      return;
    }

    var data = result.data;
    var settlements = data.settlements || data;

    if (settlements === null) {
      showEmpty('card-settlement-list', 'None');
      return;
    }

    if (Array.isArray(settlements)) {
      if (settlements.length === 0) {
        showEmpty('card-settlement-list', 'No settlements recorded');
        return;
      }
      var headers = Object.keys(settlements[0] || {});
      var rows = settlements.map(function (s) {
        return headers.map(function (h) { return safeCell(s[h]); });
      });
      var countHtml = '<div style="margin-bottom:8px;font-size:0.78rem;color:var(--text-secondary);">Count: <strong>' + settlements.length + '</strong></div>';
      setCardBody('card-settlement-list', countHtml + dataTable(headers, rows));
      setCardStatus('card-settlement-list', 'ok');
      return;
    }

    setCardBody('card-settlement-list',
      '<div class="json-display">' + highlightJson(data) + '</div>'
    );
    setCardStatus('card-settlement-list', 'ok');
  }

  async function renderEscrowList() {
    showLoading('card-escrow-list');

    var result = await safeFetch(API + '/nexa/escrow/v1/escrows');
    if (!result.ok) {
      if (isUnimplemented(result)) {
        showEmpty('card-escrow-list', 'Not available in single-node mode');
      } else {
        showError('card-escrow-list', result, 'Escrow List');
      }
      return;
    }

    var data = result.data;
    var escrows = data.escrows || data;

    if (escrows === null) {
      showEmpty('card-escrow-list', 'None');
      return;
    }

    if (Array.isArray(escrows)) {
      if (escrows.length === 0) {
        showEmpty('card-escrow-list', 'No escrows active');
        return;
      }
      var headers = Object.keys(escrows[0] || {});
      var rows = escrows.map(function (e) {
        return headers.map(function (h) { return safeCell(e[h]); });
      });
      var countHtml = '<div style="margin-bottom:8px;font-size:0.78rem;color:var(--text-secondary);">Count: <strong>' + escrows.length + '</strong></div>';
      setCardBody('card-escrow-list', countHtml + dataTable(headers, rows));
      setCardStatus('card-escrow-list', 'ok');
      return;
    }

    setCardBody('card-escrow-list',
      '<div class="json-display">' + highlightJson(data) + '</div>'
    );
    setCardStatus('card-escrow-list', 'ok');
  }

  async function renderPayoutList() {
    showLoading('card-payout-list');

    var result = await safeFetch(API + '/nexa/payout/v1/payouts');
    if (!result.ok) {
      if (isUnimplemented(result)) {
        showEmpty('card-payout-list', 'Not available in single-node mode');
      } else {
        showError('card-payout-list', result, 'Payout List');
      }
      return;
    }

    var data = result.data;
    var payouts = data.payouts || data;

    if (payouts === null) {
      showEmpty('card-payout-list', 'None');
      return;
    }

    if (Array.isArray(payouts)) {
      if (payouts.length === 0) {
        showEmpty('card-payout-list', 'No payouts recorded');
        return;
      }
      var headers = Object.keys(payouts[0] || {});
      var rows = payouts.map(function (p) {
        return headers.map(function (h) { return safeCell(p[h]); });
      });
      var countHtml = '<div style="margin-bottom:8px;font-size:0.78rem;color:var(--text-secondary);">Count: <strong>' + payouts.length + '</strong></div>';
      setCardBody('card-payout-list', countHtml + dataTable(headers, rows));
      setCardStatus('card-payout-list', 'ok');
      return;
    }

    setCardBody('card-payout-list',
      '<div class="json-display">' + highlightJson(data) + '</div>'
    );
    setCardStatus('card-payout-list', 'ok');
  }

  function safeCell(v) {
    if (v === null || v === undefined) return '<span style="color:#6a6a80;font-style:italic;">null</span>';
    if (typeof v === 'object') return '<span class="json-display" style="display:inline;padding:0;background:none;border:none;max-height:none;font-size:0.7rem;">' + highlightJson(v) + '</span>';
    return escHtml(String(v));
  }

  // ──────────────────────────────────────────────
  // Error Log Renderer
  // ──────────────────────────────────────────────

  function renderErrorLog() {
    var el = $('#error-log-content');
    if (!el) return;

    if (errorLog.length === 0) {
      el.innerHTML = '<div class="error-log-empty">No errors recorded</div>';
      return;
    }

    var lines = errorLog.map(function (e) {
      return '[' + escHtml(e.time) + '] [' + escHtml(e.section) + '] ' + escHtml(e.message);
    }).join('\n');

    el.innerHTML = '<pre>' + lines + '</pre>';
  }

  // ──────────────────────────────────────────────
  // Main Render
  // ──────────────────────────────────────────────

  async function renderDashboard() {
    var refreshBtn = $('#refresh-btn');
    if (refreshBtn) refreshBtn.disabled = true;

    // Update API URL from input
    var apiInput = $('#api-url');
    if (apiInput && apiInput.value.trim()) {
      API = apiInput.value.trim().replace(/\/+$/, '');
    }

    // Run all sections in parallel
    await Promise.all([
      renderNodeStatus().catch(function (e) {
        showError('card-node-status', e.message || 'Render error', 'Node Status');
      }),
      renderLiveFlags().catch(function (e) {
        showError('card-live-flags', e.message || 'Render error', 'Live Flags');
      }),
      renderModuleParams().catch(function (e) {
        showError('card-module-params', e.message || 'Render error', 'Module Params');
      }),
      renderTreasurySummary().catch(function (e) {
        showError('card-treasury-summary', e.message || 'Render error', 'Treasury Summary');
      }),
      renderMerchantList().catch(function (e) {
        showError('card-merchant-list', e.message || 'Render error', 'Merchant List');
      }),
      renderSettlementList().catch(function (e) {
        showError('card-settlement-list', e.message || 'Render error', 'Settlement List');
      }),
      renderEscrowList().catch(function (e) {
        showError('card-escrow-list', e.message || 'Render error', 'Escrow List');
      }),
      renderPayoutList().catch(function (e) {
        showError('card-payout-list', e.message || 'Render error', 'Payout List');
      })
    ]);

    // Update timestamp
    var ts = $('#last-updated');
    if (ts) ts.textContent = 'Last updated: ' + timestamp();

    if (refreshBtn) refreshBtn.disabled = false;
  }

  // ──────────────────────────────────────────────
  // Auto-Refresh
  // ──────────────────────────────────────────────

  function toggleAutoRefresh() {
    autoRefreshEnabled = !autoRefreshEnabled;
    var track = $('.toggle-track');
    var label = $('.toggle-label-text');

    if (autoRefreshEnabled) {
      track.classList.add('active');
      if (label) label.textContent = 'Auto-refresh ON';
      autoRefreshInterval = setInterval(function () {
        renderDashboard();
      }, 15000); // every 15 seconds
    } else {
      track.classList.remove('active');
      if (label) label.textContent = 'Auto-refresh OFF';
      if (autoRefreshInterval) {
        clearInterval(autoRefreshInterval);
        autoRefreshInterval = null;
      }
    }
  }

  // ──────────────────────────────────────────────
  // Error Log Toggle
  // ──────────────────────────────────────────────

  function toggleErrorLog() {
    var content = $('#error-log-content');
    var arrow = $('#error-log-toggle .arrow');
    if (!content) return;

    var isOpen = content.classList.toggle('open');
    if (arrow) arrow.classList.toggle('open', isOpen);
  }

  // ──────────────────────────────────────────────
  // Init
  // ──────────────────────────────────────────────

  function init() {
    // Wire up refresh button
    var refreshBtn = $('#refresh-btn');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', function () {
        renderDashboard();
      });
    }

    // Wire up auto-refresh toggle
    var toggleEl = $('#auto-refresh-toggle');
    if (toggleEl) {
      toggleEl.addEventListener('click', toggleAutoRefresh);
    }

    // Wire up error log toggle
    var errToggle = $('#error-log-toggle');
    if (errToggle) {
      errToggle.addEventListener('click', toggleErrorLog);
    }

    // Wire up API URL input: save on Enter
    var apiInput = $('#api-url');
    if (apiInput) {
      apiInput.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') {
          renderDashboard();
        }
      });
    }

    // Initial render
    renderDashboard();
  }

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
