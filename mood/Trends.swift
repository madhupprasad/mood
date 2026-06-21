//
//  Trends.swift
//  mood
//
//  The Trends screen. Topbar (title + range toggle + legend) + a scrolling
//  stack of cards: stat tiles, mood-over-time chart, mood balance, rhythm of
//  the day, by tag, and a consistency heatmap.
//

import SwiftUI
import Charts

// MARK: - Root

struct TrendsView: View {
    @Environment(\.theme) private var theme
    let entries: [MoodEntry]

    @State private var range: TrendsRange = .month
    @State private var cache = TrendsCache()
    @State private var isScrolling = false

    // `TrendsData.compute` is heavy (many Calendar calls + a 70-day heatmap).
    // Memoize it so it only recomputes when the entries or range actually
    // change — not on every body pass or scroll-driven re-layout, and not
    // once per reference (body reads `data` 7×). This keeps scrolling smooth.
    private var data: TrendsData {
        let key = "\(range.rawValue)|\(entries.count)|"
            + (entries.first.map { "\($0.id.uuidString):\($0.date.timeIntervalSince1970)" } ?? "-")
        if cache.key != key {
            cache.value = TrendsData.compute(from: entries, range: range)
            cache.key = key
        }
        return cache.value ?? TrendsData.compute(from: entries, range: range)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                TopBar(range: $range, data: data)

                StatTilesRow(data: data, range: range)

                TrendsCard {
                    MoodOverTimeCard(data: data, isScrolling: isScrolling)
                }

                CardGrid {
                    TrendsCard { MoodBalanceCard(data: data) }
                    TrendsCard { RhythmOfDayCard(data: data) }
                }

                CardGrid {
                    TrendsCard { ByTagCard(data: data) }
                    TrendsCard { ConsistencyCard(data: data, isScrolling: isScrolling) }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .padding(.bottom, 34)
        }
        .background(theme.background)
        // While scrolling, turn off the hover hit-testing in the chart and the
        // heatmap. Otherwise content sliding under a stationary cursor fires a
        // storm of hover callbacks that re-render those heavy views per frame.
        .onScrollPhaseChange { _, phase in
            let scrolling = phase != .idle
            if scrolling != isScrolling { isScrolling = scrolling }
        }
    }
}

/// Reference-type cache so the memoized `data` survives across body passes
/// without re-triggering SwiftUI state invalidation.
private final class TrendsCache {
    var key: String = ""
    var value: TrendsData?
}

// MARK: - Card wrapper + grid

private struct TrendsCard<Content: View>: View {
    @Environment(\.theme) private var theme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(theme.line, lineWidth: 1)
            )
    }
}

private struct CardGrid<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) { content() }
            VStack(alignment: .leading, spacing: 14) { content() }
        }
    }
}

private struct CardTitle: View {
    @Environment(\.theme) private var theme
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.primary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondary)
            }
        }
    }
}

// MARK: - Top bar

private struct TopBar: View {
    @Environment(\.theme) private var theme
    @Binding var range: TrendsRange
    let data: TrendsData

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TRENDS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(theme.secondary)
                Text("\(range.windowLabel) · \(data.totalEntries) \(data.totalEntries == 1 ? "entry" : "entries")")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(theme.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 10) {
                RangeToggle(range: $range)
                MoodLegend()
            }
        }
        .padding(.bottom, 4)
    }
}

private struct RangeToggle: View {
    @Environment(\.theme) private var theme
    @Binding var range: TrendsRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TrendsRange.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { range = option }
                } label: {
                    Text(option.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(option == range ? theme.card : Color.clear)
                                .shadow(color: option == range ? Color.black.opacity(theme.isDark ? 0.25 : 0.05) : .clear,
                                        radius: 3, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(theme.line, lineWidth: 1)
        )
    }
}

private struct MoodLegend: View {
    @Environment(\.theme) private var theme
    var body: some View {
        HStack(spacing: 14) {
            ForEach(MoodLevel.all) { level in
                HStack(spacing: 5) {
                    Text(level.shape).foregroundStyle(level.color)
                    Text(level.name).foregroundStyle(theme.secondary)
                }
                .font(.system(size: 11.5))
            }
        }
    }
}

// MARK: - Stat tiles

private struct StatTilesRow: View {
    let data: TrendsData
    let range: TrendsRange

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) { tiles }
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) { tilesFirstTwo }
                HStack(alignment: .top, spacing: 14) { tilesLastTwo }
            }
        }
    }

    @ViewBuilder private var tiles: some View {
        StatTile.averageMood(data: data)
        StatTile.entriesLogged(data: data)
        StatTile.currentStreak(data: data, range: range)
        StatTile.mostLogged(data: data)
    }
    @ViewBuilder private var tilesFirstTwo: some View {
        StatTile.averageMood(data: data)
        StatTile.entriesLogged(data: data)
    }
    @ViewBuilder private var tilesLastTwo: some View {
        StatTile.currentStreak(data: data, range: range)
        StatTile.mostLogged(data: data)
    }
}

private struct StatTile<Value: View, Sub: View>: View {
    @Environment(\.theme) private var theme
    let key: String
    @ViewBuilder var value: () -> Value
    @ViewBuilder var sub: () -> Sub

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(key)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(theme.secondary)
            value()
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(theme.primary)
            Spacer(minLength: 0)
            sub()
        }
        .frame(minHeight: 104, alignment: .topLeading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(theme.line, lineWidth: 1)
        )
    }
}

extension StatTile where Value == AnyView, Sub == AnyView {
    static func averageMood(data: TrendsData) -> StatTile<AnyView, AnyView> {
        let m = MoodLevel.nearest(to: data.avg)
        let delta = data.avg - data.prevAvg
        return StatTile(
            key: "Average mood",
            value: {
                AnyView(
                    HStack(spacing: 8) {
                        Text(m.shape).foregroundStyle(m.color).font(.system(size: 22))
                        Text(data.hasAvg ? m.name : "—")
                    }
                )
            },
            sub: { AnyView(DeltaLine(delta: delta, hasAvg: data.hasAvg)) }
        )
    }

    static func entriesLogged(data: TrendsData) -> StatTile<AnyView, AnyView> {
        StatTile(
            key: "Entries logged",
            value: { AnyView(Text("\(data.totalEntries)")) },
            sub: { AnyView(InlineSparkline(values: data.points.map { Double($0.entries) })) }
        )
    }

    static func currentStreak(data: TrendsData, range: TrendsRange) -> StatTile<AnyView, AnyView> {
        StatTile(
            key: "Current streak",
            value: {
                AnyView(
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(data.streak)")
                        StreakUnit()
                    }
                )
            },
            sub: { AnyView(SubMuted(text: "longest this period")) }
        )
    }

    static func mostLogged(data: TrendsData) -> StatTile<AnyView, AnyView> {
        let top = data.tags.first
        return StatTile(
            key: "Most logged",
            value: {
                AnyView(
                    HStack(spacing: 8) {
                        if let top {
                            Circle().fill(top.color).frame(width: 9, height: 9)
                            Text("#\(top.name)")
                        } else {
                            Text("—")
                        }
                    }
                )
            },
            sub: {
                AnyView(SubMuted(text: top.map { "\($0.count) \($0.count == 1 ? "entry" : "entries")" } ?? "No tags yet"))
            }
        )
    }
}

private struct StreakUnit: View {
    @Environment(\.theme) private var theme
    var body: some View {
        Text("days")
            .font(.system(size: 14))
            .foregroundStyle(theme.secondary)
    }
}

private struct SubMuted: View {
    @Environment(\.theme) private var theme
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(theme.secondary)
    }
}

private struct DeltaLine: View {
    @Environment(\.theme) private var theme
    let delta: Double
    let hasAvg: Bool

    private var arrow: String {
        if !hasAvg { return "→" }
        if delta >= 0.05 { return "↑" }
        if delta <= -0.05 { return "↓" }
        return "→"
    }
    private var color: Color {
        if !hasAvg { return theme.secondary }
        if delta >= 0.05 { return theme.accent }
        if delta <= -0.05 { return Color(red: 0xd4 / 255, green: 0x9a / 255, blue: 0x68 / 255) }
        return theme.secondary
    }

    var body: some View {
        Text("\(arrow) \(String(format: "%.1f", abs(delta))) vs previous")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(color)
    }
}

private struct InlineSparkline: View {
    @Environment(\.theme) private var theme
    let values: [Double]

    var body: some View {
        Canvas { ctx, size in
            guard values.count > 1, let mx = values.max(), mx > 0 else { return }
            let step = size.width / CGFloat(values.count - 1)
            var path = Path()
            for (i, v) in values.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - 2 - CGFloat(v / mx) * (size.height - 4)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(theme.accent), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 120, height: 26)
    }
}

// MARK: - Mood over time

private struct MoodOverTimeCard: View {
    @Environment(\.theme) private var theme
    let data: TrendsData
    var isScrolling: Bool = false

    @State private var hoverIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardTitle(title: "Mood over time", trailing: "hover for any day")

            Chart {
                ForEach(MoodLevel.all) { level in
                    RuleMark(y: .value("Level", level.value))
                        .foregroundStyle(theme.line.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                }

                ForEach(data.points) { p in
                    AreaMark(
                        x: .value("i", p.id),
                        y: .value("v", p.value)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [theme.accent.opacity(0.28), theme.accent.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                ForEach(data.points) { p in
                    LineMark(
                        x: .value("i", p.id),
                        y: .value("v", p.value)
                    )
                    .foregroundStyle(theme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

                ForEach(data.points) { p in
                    PointMark(
                        x: .value("i", p.id),
                        y: .value("v", p.value)
                    )
                    .symbolSize(28)
                    .foregroundStyle(MoodLevel.color(for: p.value))
                }

                if let i = hoverIndex, i < data.points.count {
                    RuleMark(x: .value("i", data.points[i].id))
                        .foregroundStyle(theme.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .chartXScale(domain: 0...Swift.max(1, data.points.count - 1))
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self), let level = MoodLevel.all.first(where: { $0.value == v }) {
                            Text(level.shape)
                                .font(.system(size: 12))
                                .foregroundStyle(level.color)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: xTickIndices) { value in
                    AxisValueLabel {
                        if let i = value.as(Int.self), i >= 0, i < data.points.count {
                            Text(data.points[i].label)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(theme.secondary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let pt):
                                let plotFrame = geo[proxy.plotAreaFrame]
                                let xInPlot = pt.x - plotFrame.origin.x
                                if let raw: Double = proxy.value(atX: xInPlot) {
                                    let i = Int(raw.rounded())
                                    hoverIndex = Swift.max(0, Swift.min(data.points.count - 1, i))
                                }
                            case .ended:
                                hoverIndex = nil
                            }
                        }
                        .allowsHitTesting(!isScrolling)
                }
            }
            .frame(height: 260)
            .onChange(of: isScrolling) { _, nowScrolling in
                if nowScrolling { hoverIndex = nil }
            }

            if let i = hoverIndex {
                HoverReadout(point: data.points[i])
            }
        }
    }

    private var xTickIndices: [Int] {
        let n = data.points.count
        guard n > 1 else { return [0] }
        let step = Swift.max(1, Int(ceil(Double(n) / 8.0)))
        var out: [Int] = []
        var i = 0
        while i < n {
            out.append(i)
            i += step
        }
        if let last = out.last, n - 1 - last < Int(Double(step) * 0.6) { out.removeLast() }
        out.append(n - 1)
        return Array(Set(out)).sorted()
    }
}

private struct HoverReadout: View {
    @Environment(\.theme) private var theme
    let point: TrendsData.Point

    var body: some View {
        let m = MoodLevel.nearest(to: point.value)
        HStack(spacing: 10) {
            Text(point.label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.primary)
            Text("·").foregroundStyle(theme.secondary)
            HStack(spacing: 5) {
                Text(m.shape).foregroundStyle(m.color)
                Text(m.name).foregroundStyle(theme.primary)
                Text("· \(String(format: "%.1f", point.value))").foregroundStyle(theme.secondary)
            }
            .font(.system(size: 12))
            Text("·").foregroundStyle(theme.secondary)
            Text("\(point.entries) \(point.entries == 1 ? "entry" : "entries")")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(theme.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 9).fill(theme.background))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(theme.line, lineWidth: 1))
    }
}

// MARK: - Mood balance

private struct MoodBalanceCard: View {
    @Environment(\.theme) private var theme
    let data: TrendsData

    private var maxCount: Int { Swift.max(1, data.dist.map(\.count).max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardTitle(title: "Mood balance", trailing: "how the period split")

            VStack(spacing: 10) {
                ForEach(data.dist) { row in
                    HStack(spacing: 10) {
                        Text(row.level.shape)
                            .font(.system(size: 13))
                            .foregroundStyle(row.level.color)
                            .frame(width: 16)
                        Text(row.level.name)
                            .font(.system(size: 13))
                            .foregroundStyle(theme.primary)
                            .frame(width: 70, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(theme.line.opacity(0.5))
                                Capsule()
                                    .fill(row.level.color)
                                    .frame(width: geo.size.width * CGFloat(row.count) / CGFloat(maxCount))
                                    .animation(.easeOut(duration: 0.5), value: row.count)
                            }
                        }
                        .frame(height: 8)
                        Text("\(row.count)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(theme.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// MARK: - Rhythm of the day

private struct RhythmOfDayCard: View {
    @Environment(\.theme) private var theme
    let data: TrendsData

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardTitle(title: "Rhythm of the day", trailing: "avg mood by time")

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(data.buckets) { bucket in
                    BucketColumn(bucket: bucket)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 170)
        }
    }
}

private struct BucketColumn: View {
    @Environment(\.theme) private var theme
    let bucket: TrendsData.Bucket

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(bucket.name)
                    .font(.system(size: 12))
                    .foregroundStyle(bucket.count > 0 ? theme.primary : theme.secondary)
                Spacer()
                if let avg = bucket.avg {
                    Text(MoodLevel.nearest(to: avg).shape)
                        .foregroundStyle(MoodLevel.nearest(to: avg).color)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.line.opacity(0.45))
                    if let avg = bucket.avg {
                        let h = geo.size.height * CGFloat(avg / 5.0)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(MoodLevel.color(for: avg))
                            .frame(height: Swift.max(4, h))
                            .animation(.easeOut(duration: 0.5), value: avg)
                    }
                }
            }

            Text(captionText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.secondary)
        }
    }

    private var captionText: String {
        guard bucket.count > 0 else { return "—" }
        let share = Int(round(bucket.share * 100))
        let n = bucket.count
        return "\(share)% · \(n) \(n == 1 ? "entry" : "entries")"
    }
}

// MARK: - By tag

private struct ByTagCard: View {
    @Environment(\.theme) private var theme
    let data: TrendsData

    private var maxCount: Int { Swift.max(1, data.tags.map(\.count).max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardTitle(title: "By tag", trailing: "what came up")

            if data.tags.isEmpty {
                Text("Tag entries with #hashtags to see them here.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(data.tags) { tag in
                        let mood = MoodLevel.nearest(to: tag.avg)
                        HStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Circle().fill(tag.color).frame(width: 8, height: 8)
                                Text("#\(tag.name)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(theme.primary)
                            }
                            .frame(width: 110, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(theme.line.opacity(0.5))
                                    Capsule()
                                        .fill(tag.color)
                                        .frame(width: geo.size.width * CGFloat(tag.count) / CGFloat(maxCount))
                                        .animation(.easeOut(duration: 0.5), value: tag.count)
                                }
                            }
                            .frame(height: 8)

                            Text(mood.shape)
                                .font(.system(size: 13))
                                .foregroundStyle(mood.color)
                                .frame(width: 16)
                            Text("\(tag.count)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(theme.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Consistency heatmap

private struct ConsistencyCard: View {
    @Environment(\.theme) private var theme
    let data: TrendsData
    var isScrolling: Bool = false

    @State private var hoveredCellID: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardTitle(title: "Consistency", trailing: "last 70 days")

            HStack(alignment: .top, spacing: 5) {
                ForEach(0..<10, id: \.self) { col in
                    VStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { row in
                            let idx = col * 7 + row
                            if idx < data.heat.count {
                                heatCell(for: data.heat[idx])
                            } else {
                                Color.clear.frame(width: 18, height: 18)
                            }
                        }
                    }
                }
            }
            .allowsHitTesting(!isScrolling)
            .onChange(of: isScrolling) { _, nowScrolling in
                if nowScrolling { hoveredCellID = nil }
            }

            if let id = hoveredCellID, let cell = data.heat.first(where: { $0.id == id }) {
                HeatReadout(cell: cell)
            }

            HeatLegend()
        }
    }

    @ViewBuilder
    private func heatCell(for cell: TrendsData.HeatCell) -> some View {
        let fill: Color = {
            if let v = cell.value {
                return MoodLevel.color(for: v)
            }
            if cell.entries > 0 {
                // Logged but no mood rating — visible neutral so the activity shows.
                return theme.accent.opacity(0.35)
            }
            return theme.isDark ? Color.white.opacity(0.045) : Color.black.opacity(0.06)
        }()
        let hovered = hoveredCellID == cell.id
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fill)
            .frame(width: 18, height: 18)
            .scaleEffect(hovered ? 1.18 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(theme.primary.opacity(hovered ? 0.4 : 0), lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.12), value: hovered)
            .onHover { isOn in
                if isOn {
                    hoveredCellID = cell.id
                } else if hoveredCellID == cell.id {
                    hoveredCellID = nil
                }
            }
    }
}

private struct HeatReadout: View {
    @Environment(\.theme) private var theme
    let cell: TrendsData.HeatCell

    var body: some View {
        let dateLabel = cell.date.formatted(.dateTime.day().month(.abbreviated).weekday(.abbreviated))
        HStack(spacing: 10) {
            Text(dateLabel)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.primary)
            if let v = cell.value {
                let m = MoodLevel.nearest(to: v)
                Text("·").foregroundStyle(theme.secondary)
                HStack(spacing: 5) {
                    Text(m.shape).foregroundStyle(m.color)
                    Text(m.name).foregroundStyle(theme.primary)
                }
                .font(.system(size: 12))
                Text("·").foregroundStyle(theme.secondary)
                Text("\(cell.entries) \(cell.entries == 1 ? "entry" : "entries")")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.secondary)
            } else if cell.entries > 0 {
                Text("·").foregroundStyle(theme.secondary)
                Text("\(cell.entries) \(cell.entries == 1 ? "entry" : "entries"), no mood rating")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.secondary)
            } else {
                Text("·").foregroundStyle(theme.secondary)
                Text("No entries")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 9).fill(theme.background))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(theme.line, lineWidth: 1))
    }
}

private struct HeatLegend: View {
    @Environment(\.theme) private var theme
    var body: some View {
        HStack(spacing: 8) {
            Text("flat")
                .font(.system(size: 11))
                .foregroundStyle(theme.secondary)
            HStack(spacing: 4) {
                ForEach(MoodLevel.all.reversed()) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(level.color)
                        .frame(width: 12, height: 12)
                }
            }
            Text("elevated")
                .font(.system(size: 11))
                .foregroundStyle(theme.secondary)
        }
    }
}
