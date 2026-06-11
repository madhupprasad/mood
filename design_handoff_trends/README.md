# Handoff: Trends screen (mood app)

## Overview
This is the **Trends / insights view** for `mood`, a macOS journaling + mood-tracking app.
It is the analytics surface reachable from the sidebar (`Library → Trends`). It summarizes the
user's logged entries over a selected time range with a set of charts and stat tiles.

The app is a **native macOS app** (SwiftUI / AppKit). The files in this bundle are an **HTML
design reference** — a working prototype that shows the intended look, layout, data, and
interactions. **Do not ship the HTML.** The task is to **recreate this screen natively in the
existing app using its current patterns** (SwiftUI views, the app's theme system, Swift Charts
or custom `Path` drawing). Match the visuals precisely; reimplement the behavior idiomatically.

## Fidelity
**High-fidelity.** Colors, typography, spacing, and interactions below are final. Recreate
pixel-closely, but use the app's existing components/tokens where they already exist (e.g. the
sidebar, the "Slate" theme palette, tag colors) rather than duplicating them.

---

## Layout (top level)
A standard two-pane app window:

```
┌───────────────────────────────────────────────────────────┐
│ titlebar (traffic lights + "mood")            44px tall     │
├───────────┬───────────────────────────────────────────────┤
│ sidebar   │  main (Trends)                                 │
│ 236px     │   ┌ topbar (header + range toggle + legend) ┐  │
│ fixed     │   └ content (scrollable) ───────────────────┘  │
└───────────┴───────────────────────────────────────────────┘
```

Only the **main → Trends** pane is new. The sidebar already exists in the app; it's included in
the prototype only for context. The sidebar's active item is **Trends**.

### Topbar
- Left: title `TRENDS` (uppercase, 12px, weight 700, letter-spacing 2.4px, color `--text-2`) and
  below it a meta line in monospace, e.g. `Past 30 days · 73 entries` (13px, `--text-3`).
- Right, stacked:
  - **Segmented control**: `Week | Month | Year` (Month default). Pill container with 1px border;
    active segment gets a raised `--card` background + subtle shadow.
  - **Scale legend**: the 5 mood shapes with names — `▲ Elevated  ● Good  ■ Steady  ▼ Low  ○ Flat`,
    each shape tinted with its mood color, labels 11.5px `--text-3`.

### Content (vertical stack, 24–34px padding, gap 14px, scrolls)
1. **Stat tiles** — 4-up grid (`repeat(4, 1fr)`, gap 14px). Collapses to 2-up under 1080px.
2. **Mood over time** — full-width card with an area+line chart.
3. **Row of two cards**: *Mood balance* (left) + *Rhythm of the day* (right).
4. **Row of two cards**: *By tag* (left) + *Consistency* heatmap (right).
Under 1080px the two-card rows stack to one column.

---

## The mood scale (core model)
Mood is a **5-point ordinal scale**. Each level has a shape, a name, and a color. The shapes are
the same glyphs already used in the compose bar (`● ■ ▲ ▼ ○`); this screen assigns them an order
and meaning (high → low):

| Value | Shape | Name     | Hex       |
|-------|-------|----------|-----------|
| 5     | ▲     | Elevated | `#7fbf86` |
| 4     | ●     | Good     | `#a8c779` |
| 3     | ■     | Steady   | `#cdbf76` |
| 2     | ▼     | Low      | `#d49a68` |
| 1     | ○     | Flat     | `#c87a72` |

A continuous mood value (e.g. a daily average of 3.6) is rendered by **linearly interpolating the
color between the two nearest levels**, and labeled with the **nearest** level's shape + name.
(See `moodColor(v)` and `nearestMood(v)` in `trends.js`.)

---

## Components (per card)

### Stat tiles (×4)
Card: `--card` bg, 1px `--border`, radius 13px, padding 16×18px, min-height 104px, flex column.
- **Average mood** — key `AVERAGE MOOD`; value = nearest mood shape (colored) + name (25px, weight 600);
  sub = mono delta vs previous period, e.g. `↑ 0.3 vs previous` (green if up `--accent`, `#d49a68` if down, `--text-3` if flat).
- **Entries logged** — big number; sub = a small inline sparkline (entries per day, `--accent` stroke, 1.5px).
- **Current streak** — number + `days` unit (14px `--text-3`); sub `longest this period`.
- **Most logged** — colored tag dot + `#<tag>`; sub `<n> entries`.

Tile key labels: 11px, uppercase, letter-spacing .5px, weight 600, `--text-3`. Sub line: 12px mono.

### Mood over time (area chart)
- Card title `Mood over time`, note `hover for any day` (right, 12px `--text-3`).
- SVG-style area chart, ~280px tall, full card width.
- Y axis = the 5 mood levels; draw a faint gridline at each level and the level's **shape** as the
  axis tick on the left (tinted with mood color). Gridline stroke `rgba(255,255,255,0.05)`.
- X axis = dates (Month) / dates (Week) / month names (Year), sparse labels, monospace 11px `--text-3`.
  Keep the **last** label but drop a near-colliding penultimate tick.
- Series: smooth (Catmull-Rom → bezier) line, 2px `--accent`, with a soft vertical gradient area fill
  (`--accent` at 0.28 alpha → 0 alpha). A small dot per point, filled with that point's interpolated mood color,
  1.5px `--panel` stroke ring.
- **Hover**: dashed vertical guide line at the nearest day + tooltip showing `date`, mood shape + name + value,
  and entry count.

### Mood balance (distribution)
Five rows, one per mood level (Elevated → Flat). Each row: shape (colored) · name (13px `--text-2`) ·
horizontal bar (track `rgba(255,255,255,0.05)`, fill = mood color, 8px tall, radius 5, width = count/max)
· count (mono, right). Bar widths animate width over .5s ease.

### Rhythm of the day (time-of-day)
Four vertical bars: `Morning · Afternoon · Evening · Night`. Each: header row with name (12px `--text-2`)
and the bucket's nearest mood shape (colored); a vertical bar whose **fill height = avg/5**, filled with the
bucket's mood color (radius 8 8 0 0); a `%` share caption below (mono 11px). Container ~150px tall.

### By tag
One row per tag, sorted by entry count desc. Row grid: `name · bar · mood shape · count`.
- name: colored tag dot + `#<tag>` (13px `--text-2`)
- bar: track `rgba(255,255,255,0.05)`, fill = the **tag's** color, width = count/max
- mood: nearest mood shape (colored) for that tag's average
- count: mono, right.

### Consistency (heatmap)
GitHub-style grid: **7 rows (weekdays) × 10 columns (weeks)**, `grid-auto-flow: column`, gap 5px,
cells ~18px, radius 4. Each cell colored by that day's avg mood via `moodColor`, or
`--heat-empty` (`rgba(255,255,255,0.045)`) when there were no entries. Hover scales the cell 1.18×
with a faint outline and shows a tooltip (`date`, mood shape+name, entry count, or "No entries").
Footer: `flat ▢▢▢▢▢ elevated` legend using the 5 mood colors as small swatches.

---

## Tag colors
| Tag      | Hex       |
|----------|-----------|
| work     | `#d98a6c` |
| health   | `#d9b15a` |
| personal | `#9aa6d9` |
| creative | `#c490c4` |

---

## Design tokens (Slate dark theme)
```
--bg:           #161617   (window + sidebar base)
--sidebar:      #141415
--panel:        #1a1a1c   (main content bg)
--card:         #1e1e21
--card-hover:   #232327
--border:       rgba(255,255,255,0.07)
--border-strong:rgba(255,255,255,0.12)
--text:         #ededeb   (primary)
--text-2:       #9a9a98   (secondary)
--text-3:       #66666a   (muted / labels)
--mono:         #7b7b78
--accent:       #79b07f   (Slate green)
--accent-dim:   rgba(121,176,127,0.14)   (active nav bg)
--heat-empty:   rgba(255,255,255,0.045)

radius:  tiles 13, cards 14, bars 5, heat cells 4, segmented 9/7
gap:     card grid 14px
```
> Note: `--accent` is theme-dependent. The app ships multiple themes (Slate green shown, plus
> blue / purple / amber swatches in the sidebar). Drive the accent from the **active theme token**,
> not a hardcoded green, so Trends recolors with the rest of the app.

## Typography
- UI: system font (`-apple-system` / SF Pro). On macOS native this is just the system font.
- Numerals, timestamps, axis labels, deltas, counts: **monospaced** (SF Mono / `ui-monospace`).
- Sizes: tile value 25px/600; card title 14px/600; section labels 11–12px/600–700 uppercase with
  letter-spacing; body 13–14px; captions 11–12px.

---

## Interactions & behavior
- **Range toggle (Week / Month / Year)**: switching re-queries the data for that window and
  re-renders every card. Week = 7 daily points; Month = 30 daily points; Year = 12 monthly points.
  The Consistency heatmap always shows the last ~70 days regardless of range.
- **Hover tooltips** on the line chart (nearest day) and heatmap (per cell). Single shared floating
  tooltip; dark `#2a2a2e`, 1px `--border-strong`, radius 9, soft shadow.
- **Bars animate** their width/height on data change (~.5s, `cubic-bezier(.2,.7,.2,1)`).
- No destructive actions on this screen; it's read-only analytics.

## State / data
This screen reads from the existing entry store. Each entry needs: `timestamp`, `moodValue (1–5)`,
and optional `tags: [String]`. Derived per selected range:
- per-day (or per-month) **average mood** and **entry count** → line chart + heatmap
- **distribution** = count of entries at each mood level → Mood balance
- **per-tag** count + average mood → By tag
- **per time-of-day bucket** (Morning 5–12, Afternoon 12–17, Evening 17–22, Night 22–5) avg + share → Rhythm
- summary: average mood (+ delta vs previous equal-length window), total entries, current streak, top tag.

> The prototype fills these with **seeded synthetic data** (`buildData(range)` in `trends.js`) so the
> charts look realistic. Replace with real queries against the entry store; keep the same shapes.

## Files in this bundle
- `mood — Trends.html` — the screen markup + all CSS (tokens, layout, every card style).
- `trends.js` — data model, color interpolation, and all chart/SVG generation + interactions.
  Read this for the exact chart math (`smoothPath`, `moodColor`, `nearestMood`, `buildData`).
- `Trends-screenshot.png` — rendered reference (if included).

## How to hand this to Claude in Xcode
1. Unzip this folder somewhere inside (or next to) your app's repo.
2. In Xcode's Claude/coding assistant (or Claude Code in Terminal at the repo root), say something like:
   *"Implement a new Trends screen in SwiftUI from the spec in `design_handoff_trends/README.md`.
   Match the visuals exactly, use our existing theme tokens and sidebar, and wire it to the real
   entry store. Use Swift Charts where it fits; custom Path drawing for the area chart is fine."*
3. Point it at `README.md` first, then `mood — Trends.html` / `trends.js` for exact values.
