/* mood — Trends view logic
   Seeded synthetic data + SVG charts + interactions.
   Pure vanilla JS, no deps. */
(function () {
  'use strict';

  // ---- Mood scale (5-point). high -> low ----
  const MOODS = [
    { v: 5, shape: '▲', name: 'Elevated', color: '#7fbf86' },
    { v: 4, shape: '●', name: 'Good',     color: '#a8c779' },
    { v: 3, shape: '■', name: 'Steady',   color: '#cdbf76' },
    { v: 2, shape: '▼', name: 'Low',      color: '#d49a68' },
    { v: 1, shape: '○', name: 'Flat',     color: '#c87a72' },
  ];
  const TAGS = [
    { name: 'work',     color: '#d98a6c' },
    { name: 'health',   color: '#d9b15a' },
    { name: 'personal', color: '#9aa6d9' },
    { name: 'creative', color: '#c490c4' },
  ];
  const DAYS_SHORT = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const MON_SHORT = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // ---- seeded RNG ----
  function mulberry32(a) {
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  // value (1..5) -> interpolated color along MOODS
  function moodColor(v) {
    v = Math.max(1, Math.min(5, v));
    const idx = 5 - v; // 0..4 from top
    const lo = Math.floor(idx), hi = Math.min(4, lo + 1), f = idx - lo;
    const a = hexToRgb(MOODS[lo].color), b = hexToRgb(MOODS[hi].color);
    return `rgb(${Math.round(a[0] + (b[0] - a[0]) * f)},${Math.round(a[1] + (b[1] - a[1]) * f)},${Math.round(a[2] + (b[2] - a[2]) * f)})`;
  }
  function hexToRgb(h) {
    const n = parseInt(h.slice(1), 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function nearestMood(v) {
    return MOODS.reduce((best, m) => Math.abs(m.v - v) < Math.abs(best.v - v) ? m : best, MOODS[0]);
  }

  const TODAY = new Date(2026, 5, 11); // Jun 11 2026
  function dateMinus(n) { const d = new Date(TODAY); d.setDate(d.getDate() - n); return d; }

  // ---- data model per range ----
  function buildData(range) {
    const seed = range === 'week' ? 71 : range === 'year' ? 4012 : 2026;
    const rnd = mulberry32(seed);
    const n = range === 'week' ? 7 : range === 'year' ? 12 : 30;

    let base = 3.3;
    const points = [];
    for (let i = 0; i < n; i++) {
      base += (rnd() - 0.48) * 0.7;
      base = Math.max(1.6, Math.min(4.7, base));
      const wave = Math.sin(i / (range === 'year' ? 2.4 : 4.2)) * 0.45;
      const v = Math.max(1, Math.min(5, base + wave + (rnd() - 0.5) * 0.45));
      const entries = 1 + Math.floor(rnd() * (range === 'year' ? 40 : 4));
      let label;
      if (range === 'year') {
        const m = (TODAY.getMonth() - (n - 1 - i) + 1200) % 12;
        label = MON_SHORT[m];
      } else {
        const d = dateMinus(n - 1 - i);
        label = d.getDate() + ' ' + MON_SHORT[d.getMonth()];
      }
      points.push({ i, v, entries, label });
    }

    const totalEntries = points.reduce((s, p) => s + p.entries, 0);
    const avg = points.reduce((s, p) => s + p.v, 0) / points.length;
    const prevAvg = avg - (rnd() - 0.42) * 0.6;

    // tags
    const tags = TAGS.map((t, k) => {
      const r = mulberry32(seed * 7 + k * 13);
      const count = Math.round(totalEntries * (0.12 + r() * 0.3));
      const tavg = 2.2 + r() * 2.4;
      return { ...t, count, avg: tavg };
    }).sort((a, b) => b.count - a.count);

    // time of day
    const buckets = ['Morning', 'Afternoon', 'Evening', 'Night'].map((name, k) => {
      const r = mulberry32(seed * 11 + k * 5);
      return { name, avg: 2 + r() * 2.8, share: 0.15 + r() * 0.35 };
    });
    const bsum = buckets.reduce((s, b) => s + b.share, 0);
    buckets.forEach(b => b.share = b.share / bsum);

    // distribution across 5 moods
    const dist = MOODS.map((m, k) => {
      const r = mulberry32(seed * 17 + k * 3);
      // weight toward middle-high
      const w = [0.16, 0.30, 0.27, 0.18, 0.09][k] * (0.7 + r() * 0.6);
      return { ...m, w };
    });
    const dsum = dist.reduce((s, d) => s + d.w, 0);
    dist.forEach(d => d.count = Math.round(d.w / dsum * totalEntries));

    // streak (synthetic)
    const streak = range === 'week' ? 6 : range === 'year' ? 41 : 12;

    // heatmap: last 70 days
    const hr = mulberry32(seed + 999);
    const heat = [];
    for (let i = 0; i < 70; i++) {
      const has = hr() > 0.18;
      heat.push({
        i,
        date: dateMinus(69 - i),
        v: has ? Math.max(1, Math.min(5, 2.4 + Math.sin(i / 6) * 1 + (hr() - 0.5) * 1.6)) : null,
        entries: has ? 1 + Math.floor(hr() * 4) : 0,
      });
    }

    return { range, points, totalEntries, avg, prevAvg, tags, buckets, dist, streak, heat };
  }

  // ================= rendering =================
  const $ = (s, r = document) => r.querySelector(s);

  let tip;
  function ensureTip() {
    if (!tip) { tip = document.createElement('div'); tip.className = 'tip'; document.body.appendChild(tip); }
    return tip;
  }
  function showTip(html, x, y) {
    const t = ensureTip();
    t.innerHTML = html;
    t.style.opacity = '1';
    const r = t.getBoundingClientRect();
    t.style.left = Math.max(8, Math.min(window.innerWidth - r.width - 8, x - r.width / 2)) + 'px';
    t.style.top = (y - r.height - 14) + 'px';
  }
  function hideTip() { if (tip) tip.style.opacity = '0'; }

  // ---- stat tiles ----
  function renderStats(d) {
    const m = nearestMood(d.avg);
    const delta = d.avg - d.prevAvg;
    const arrow = delta >= 0.05 ? '↑' : delta <= -0.05 ? '↓' : '→';
    const dcls = delta >= 0.05 ? 'up' : delta <= -0.05 ? 'down' : 'flat';
    const topTag = d.tags[0];
    // mini sparkline for entries tile
    const spark = sparkline(d.points.map(p => p.entries));
    $('#stats').innerHTML = `
      <div class="tile">
        <div class="tile-k">Average mood</div>
        <div class="tile-v"><span class="shape" style="color:${m.color}">${m.shape}</span> ${m.name}</div>
        <div class="tile-sub ${dcls}">${arrow} ${Math.abs(delta).toFixed(1)} vs previous</div>
      </div>
      <div class="tile">
        <div class="tile-k">Entries logged</div>
        <div class="tile-v">${d.totalEntries}</div>
        <div class="tile-spark">${spark}</div>
      </div>
      <div class="tile">
        <div class="tile-k">Current streak</div>
        <div class="tile-v">${d.streak}<span class="tile-unit">days</span></div>
        <div class="tile-sub flat">longest this period</div>
      </div>
      <div class="tile">
        <div class="tile-k">Most logged</div>
        <div class="tile-v"><span class="tdot" style="background:${topTag.color}"></span>#${topTag.name}</div>
        <div class="tile-sub flat">${topTag.count} entries</div>
      </div>`;
  }

  function sparkline(vals) {
    const W = 120, H = 26, max = Math.max(...vals, 1);
    const step = W / (vals.length - 1);
    const pts = vals.map((v, i) => [i * step, H - 2 - (v / max) * (H - 4)]);
    const d = 'M' + pts.map(p => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join(' L');
    return `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" width="${W}" height="${H}">
      <path d="${d}" fill="none" stroke="var(--accent)" stroke-width="1.5" vector-effect="non-scaling-stroke" stroke-linejoin="round"/>
    </svg>`;
  }

  // ---- mood over time (area) ----
  function renderLine(d) {
    const W = 1000, H = 280, padL = 44, padR = 16, padT = 18, padB = 30;
    const iw = W - padL - padR, ih = H - padT - padB;
    const n = d.points.length;
    const x = i => padL + (n === 1 ? iw / 2 : (i / (n - 1)) * iw);
    const y = v => padT + (1 - (v - 1) / 4) * ih;

    // gridlines + shape labels
    let grid = '';
    MOODS.forEach(m => {
      const yy = y(m.v);
      grid += `<line x1="${padL}" y1="${yy}" x2="${W - padR}" y2="${yy}" class="grid"/>`;
      grid += `<text x="${padL - 12}" y="${yy + 4}" class="axis-shape" style="fill:${m.color}">${m.shape}</text>`;
    });

    const pts = d.points.map(p => [x(p.i), y(p.v)]);
    const line = smoothPath(pts);
    const area = line + ` L${pts[pts.length - 1][0].toFixed(1)},${(H - padB).toFixed(1)} L${pts[0][0].toFixed(1)},${(H - padB).toFixed(1)} Z`;

    // x labels (sparse, no collision at the end)
    const everyX = Math.ceil(n / 8);
    const ticks = [];
    for (let i = 0; i < n; i += everyX) ticks.push(i);
    if (ticks[ticks.length - 1] !== n - 1) {
      if ((n - 1) - ticks[ticks.length - 1] < everyX * 0.6) ticks.pop();
      ticks.push(n - 1);
    }
    let xl = '';
    ticks.forEach(i => {
      xl += `<text x="${x(i)}" y="${H - 8}" class="axis-x">${d.points[i].label}</text>`;
    });

    // dots
    const dots = d.points.map(p => `<circle cx="${x(p.i).toFixed(1)}" cy="${y(p.v).toFixed(1)}" r="3" class="lpt" fill="${moodColor(p.v)}"/>`).join('');

    $('#linechart').innerHTML = `
      <svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" class="linesvg">
        <defs>
          <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="var(--accent)" stop-opacity="0.28"/>
            <stop offset="100%" stop-color="var(--accent)" stop-opacity="0"/>
          </linearGradient>
        </defs>
        ${grid}
        <path d="${area}" fill="url(#areaGrad)"/>
        <path d="${line}" fill="none" stroke="var(--accent)" stroke-width="2" vector-effect="non-scaling-stroke" stroke-linejoin="round" stroke-linecap="round"/>
        ${dots}
        <line id="guide" class="guide" x1="0" y1="${padT}" x2="0" y2="${H - padB}" style="opacity:0"/>
        ${xl}
      </svg>`;

    // hover: invisible hit columns over the real svg
    const host = $('#linechart');
    const svg = host.querySelector('svg');
    const guide = svg.querySelector('#guide');
    host.onmousemove = e => {
      const r = svg.getBoundingClientRect();
      const rel = (e.clientX - r.left) / r.width * W;
      // nearest point
      let best = 0, bd = Infinity;
      d.points.forEach(p => { const dx = Math.abs(x(p.i) - rel); if (dx < bd) { bd = dx; best = p.i; } });
      const p = d.points[best];
      const px = x(p.i), py = y(p.v);
      guide.setAttribute('x1', px); guide.setAttribute('x2', px); guide.style.opacity = '1';
      const m = nearestMood(p.v);
      const sx = r.left + (px / W) * r.width;
      const sy = r.top + (py / H) * r.height;
      showTip(`<b>${p.label}</b><span class="tip-row"><span class="shape" style="color:${m.color}">${m.shape}</span> ${m.name} · ${p.v.toFixed(1)}</span><span class="tip-sub">${p.entries} ${p.entries === 1 ? 'entry' : 'entries'}</span>`, sx, sy);
    };
    host.onmouseleave = () => { guide.style.opacity = '0'; hideTip(); };
  }

  function smoothPath(pts) {
    if (pts.length < 2) return '';
    let d = `M${pts[0][0].toFixed(1)},${pts[0][1].toFixed(1)}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2;
      const c1x = p1[0] + (p2[0] - p0[0]) / 6, c1y = p1[1] + (p2[1] - p0[1]) / 6;
      const c2x = p2[0] - (p3[0] - p1[0]) / 6, c2y = p2[1] - (p3[1] - p1[1]) / 6;
      d += ` C${c1x.toFixed(1)},${c1y.toFixed(1)} ${c2x.toFixed(1)},${c2y.toFixed(1)} ${p2[0].toFixed(1)},${p2[1].toFixed(1)}`;
    }
    return d;
  }

  // ---- mood distribution (horizontal bars) ----
  function renderDist(d) {
    const max = Math.max(...d.dist.map(x => x.count), 1);
    $('#dist').innerHTML = d.dist.map(m => `
      <div class="distrow">
        <span class="shape dist-shape" style="color:${m.color}">${m.shape}</span>
        <span class="dist-name">${m.name}</span>
        <span class="dist-bar"><span class="dist-fill" style="width:${(m.count / max * 100).toFixed(0)}%;background:${m.color}"></span></span>
        <span class="dist-count">${m.count}</span>
      </div>`).join('');
  }

  // ---- by tag ----
  function renderTags(d) {
    const max = Math.max(...d.tags.map(t => t.count), 1);
    $('#bytag').innerHTML = d.tags.map(t => {
      const m = nearestMood(t.avg);
      return `<div class="tagrow">
        <span class="tagrow-name"><span class="tdot" style="background:${t.color}"></span>#${t.name}</span>
        <span class="tagrow-bar"><span class="tagrow-fill" style="width:${(t.count / max * 100).toFixed(0)}%;background:${t.color}"></span></span>
        <span class="tagrow-mood"><span class="shape" style="color:${m.color}">${m.shape}</span></span>
        <span class="tagrow-count">${t.count}</span>
      </div>`;
    }).join('');
  }

  // ---- time of day ----
  function renderClock(d) {
    $('#clock').innerHTML = d.buckets.map(b => {
      const m = nearestMood(b.avg);
      return `<div class="bucket">
        <div class="bucket-top"><span class="bucket-name">${b.name}</span><span class="shape" style="color:${m.color}">${m.shape}</span></div>
        <div class="bucket-bar"><span class="bucket-fill" style="height:${(b.avg / 5 * 100).toFixed(0)}%;background:${m.color}"></span></div>
        <div class="bucket-share">${Math.round(b.share * 100)}%</div>
      </div>`;
    }).join('');
  }

  // ---- consistency heatmap ----
  function renderHeat(d) {
    const cells = d.heat.map(c => {
      const bg = c.v == null ? 'var(--heat-empty)' : moodColor(c.v);
      return `<div class="hcell" data-i="${c.i}" style="background:${bg}"></div>`;
    }).join('');
    $('#heat').innerHTML = cells;
    const host = $('#heat');
    host.onmouseover = e => {
      const cell = e.target.closest('.hcell'); if (!cell) return;
      const c = d.heat[+cell.dataset.i];
      const r = cell.getBoundingClientRect();
      const dl = c.date.getDate() + ' ' + MON_SHORT[c.date.getMonth()] + ', ' + DAYS_SHORT[c.date.getDay()];
      if (c.v == null) { showTip(`<b>${dl}</b><span class="tip-sub">No entries</span>`, r.left + r.width / 2, r.top); }
      else { const m = nearestMood(c.v); showTip(`<b>${dl}</b><span class="tip-row"><span class="shape" style="color:${m.color}">${m.shape}</span> ${m.name}</span><span class="tip-sub">${c.entries} ${c.entries === 1 ? 'entry' : 'entries'}</span>`, r.left + r.width / 2, r.top); }
    };
    host.onmouseleave = hideTip;
  }

  // ---- legend ----
  function renderLegend() {
    $('#scale-legend').innerHTML = MOODS.map(m =>
      `<span class="leg"><span class="shape" style="color:${m.color}">${m.shape}</span>${m.name}</span>`).join('');
  }

  function renderAll(range) {
    const d = buildData(range);
    $('#range-meta').textContent =
      (range === 'week' ? 'Past 7 days' : range === 'year' ? 'Past 12 months' : 'Past 30 days') +
      ' · ' + d.totalEntries + ' entries';
    renderStats(d);
    renderLine(d);
    renderDist(d);
    renderTags(d);
    renderClock(d);
    renderHeat(d);
  }

  function init() {
    renderLegend();
    let range = 'month';
    renderAll(range);
    document.querySelectorAll('.seg').forEach(btn => {
      btn.addEventListener('click', () => {
        if (btn.dataset.range === range) return;
        range = btn.dataset.range;
        document.querySelectorAll('.seg').forEach(b => b.classList.toggle('on', b === btn));
        renderAll(range);
      });
    });
    // sidebar tag hover affordance only; nav active is Trends
    document.addEventListener('scroll', hideTip, true);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
