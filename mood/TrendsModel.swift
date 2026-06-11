//
//  TrendsModel.swift
//  mood
//
//  Mood scale, color interpolation, range definitions, and the
//  derived TrendsData computed from real entries.
//

import SwiftUI

// MARK: - Mood scale (5-point ordinal)

struct MoodLevel: Identifiable {
    let value: Int           // 1...5
    let shape: String        // unicode glyph
    let name: String
    private let rgb: (Double, Double, Double)

    var id: Int { value }
    var color: Color { Color(red: rgb.0, green: rgb.1, blue: rgb.2) }
    fileprivate var rgbTuple: (Double, Double, Double) { rgb }

    static let all: [MoodLevel] = [
        MoodLevel(value: 5, shape: "▲", name: "Elevated", rgb: (0x7f / 255, 0xbf / 255, 0x86 / 255)),
        MoodLevel(value: 4, shape: "●", name: "Good",     rgb: (0xa8 / 255, 0xc7 / 255, 0x79 / 255)),
        MoodLevel(value: 3, shape: "■", name: "Steady",   rgb: (0xcd / 255, 0xbf / 255, 0x76 / 255)),
        MoodLevel(value: 2, shape: "▼", name: "Low",      rgb: (0xd4 / 255, 0x9a / 255, 0x68 / 255)),
        MoodLevel(value: 1, shape: "○", name: "Flat",     rgb: (0xc8 / 255, 0x7a / 255, 0x72 / 255)),
    ]

    static func nearest(to value: Double) -> MoodLevel {
        all.min(by: { abs(Double($0.value) - value) < abs(Double($1.value) - value) }) ?? all[2]
    }

    /// Interpolated color along the 5-stop scale (5 -> 1 maps to top -> bottom).
    static func color(for value: Double) -> Color {
        let v = max(1.0, min(5.0, value))
        let idx = 5.0 - v
        let lo = max(0, min(4, Int(idx.rounded(.down))))
        let hi = min(4, lo + 1)
        let f = idx - Double(lo)
        let a = all[lo].rgbTuple
        let b = all[hi].rgbTuple
        return Color(
            red: a.0 + (b.0 - a.0) * f,
            green: a.1 + (b.1 - a.1) * f,
            blue: a.2 + (b.2 - a.2) * f
        )
    }
}

// MARK: - Range

enum TrendsRange: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var bucketCount: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .year: 12
        }
    }

    var windowLabel: String {
        switch self {
        case .week: "Past 7 days"
        case .month: "Past 30 days"
        case .year: "Past 12 months"
        }
    }
}

// MARK: - Derived data

struct TrendsData {
    struct Point: Identifiable {
        let id: Int
        let date: Date
        let value: Double       // average mood for this bucket (3.0 when no data)
        let entries: Int
        let label: String
        let hasData: Bool
    }

    struct TagSummary: Identifiable {
        let name: String
        let color: Color
        let count: Int
        let avg: Double
        var id: String { name }
    }

    struct Bucket: Identifiable {
        let name: String
        let avg: Double?       // nil when no rated entries fell in the bucket
        let share: Double
        let count: Int
        var id: String { name }
    }

    struct HeatCell: Identifiable {
        let id: Int
        let date: Date
        let value: Double?      // nil = no entries that day
        let entries: Int
    }

    struct DistributionRow: Identifiable {
        let level: MoodLevel
        let count: Int
        var id: Int { level.value }
    }

    let range: TrendsRange
    let points: [Point]
    let totalEntries: Int
    let avg: Double            // overall avg mood for window (3.0 fallback when no data)
    let prevAvg: Double
    let hasAvg: Bool           // did the window have any moodValue at all?
    let tags: [TagSummary]
    let buckets: [Bucket]
    let dist: [DistributionRow]
    let streak: Int
    let heat: [HeatCell]
}

extension TrendsData {
    static func compute(from allEntries: [MoodEntry], range: TrendsRange, now: Date = Date()) -> TrendsData {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let bucketCount = range.bucketCount

        // Window start
        let windowStart: Date
        switch range {
        case .week:
            windowStart = cal.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        case .month:
            windowStart = cal.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
        case .year:
            windowStart = cal.date(byAdding: .month, value: -11, to: startOfMonth(of: now, cal: cal)) ?? startOfToday
        }

        let windowEntries = allEntries.filter { $0.date >= windowStart && $0.date <= now }

        // Build per-bucket points
        var points: [Point] = []
        for i in 0..<bucketCount {
            let bucketDate: Date
            let label: String
            let inBucket: [MoodEntry]

            switch range {
            case .week, .month:
                let offset = -(bucketCount - 1 - i)
                bucketDate = cal.date(byAdding: .day, value: offset, to: startOfToday) ?? startOfToday
                inBucket = windowEntries.filter { cal.isDate($0.date, inSameDayAs: bucketDate) }
                label = "\(cal.component(.day, from: bucketDate)) \(monthAbbrev(bucketDate))"
            case .year:
                let offset = -(bucketCount - 1 - i)
                let base = startOfMonth(of: now, cal: cal)
                bucketDate = cal.date(byAdding: .month, value: offset, to: base) ?? base
                inBucket = windowEntries.filter { cal.isDate($0.date, equalTo: bucketDate, toGranularity: .month) }
                label = monthAbbrev(bucketDate)
            }

            let values = inBucket.compactMap { $0.moodValue }
            let hasData = !values.isEmpty
            let avg = hasData ? Double(values.reduce(0, +)) / Double(values.count) : 3.0
            points.append(Point(id: i, date: bucketDate, value: avg, entries: inBucket.count, label: label, hasData: hasData))
        }

        // Totals
        let totalEntries = points.reduce(0) { $0 + $1.entries }
        let windowValues = windowEntries.compactMap { $0.moodValue }
        let hasAvg = !windowValues.isEmpty
        let windowAvg = hasAvg ? Double(windowValues.reduce(0, +)) / Double(windowValues.count) : 3.0

        // Previous window of same length
        let prevWindowDays: Int
        switch range {
        case .week: prevWindowDays = 7
        case .month: prevWindowDays = 30
        case .year: prevWindowDays = 365
        }
        let prevStart = cal.date(byAdding: .day, value: -prevWindowDays, to: windowStart) ?? windowStart
        let prevEntries = allEntries.filter { $0.date >= prevStart && $0.date < windowStart }
        let prevValues = prevEntries.compactMap { $0.moodValue }
        let prevAvg = prevValues.isEmpty ? windowAvg : Double(prevValues.reduce(0, +)) / Double(prevValues.count)

        // Tags
        var tagCounts: [String: (count: Int, values: [Int])] = [:]
        for entry in windowEntries {
            for tag in extractTags(from: entry.mood) {
                var existing = tagCounts[tag] ?? (0, [])
                existing.count += 1
                if let v = entry.moodValue { existing.values.append(v) }
                tagCounts[tag] = existing
            }
        }
        let tags: [TagSummary] = tagCounts.map { (name, data) in
            let avg = data.values.isEmpty ? 3.0 : Double(data.values.reduce(0, +)) / Double(data.values.count)
            return TagSummary(name: name, color: colorForTag(name), count: data.count, avg: avg)
        }.sorted { $0.count > $1.count }

        // Time-of-day buckets
        let bucketNames = ["Morning", "Afternoon", "Evening", "Night"]
        var bucketData: [String: (count: Int, values: [Int])] = [:]
        bucketNames.forEach { bucketData[$0] = (0, []) }
        for entry in windowEntries {
            let h = cal.component(.hour, from: entry.date)
            let name: String
            switch h {
            case 5...11: name = "Morning"
            case 12...16: name = "Afternoon"
            case 17...21: name = "Evening"
            default: name = "Night"
            }
            var d = bucketData[name] ?? (0, [])
            d.count += 1
            if let v = entry.moodValue { d.values.append(v) }
            bucketData[name] = d
        }
        let bucketTotal = max(1, bucketData.values.reduce(0) { $0 + $1.count })
        let buckets: [Bucket] = bucketNames.map { name in
            let d = bucketData[name] ?? (0, [])
            let avg: Double? = d.values.isEmpty ? nil : Double(d.values.reduce(0, +)) / Double(d.values.count)
            return Bucket(name: name, avg: avg, share: Double(d.count) / Double(bucketTotal), count: d.count)
        }

        // Mood distribution
        let dist: [DistributionRow] = MoodLevel.all.map { level in
            let count = windowEntries.filter { $0.moodValue == level.value }.count
            return DistributionRow(level: level, count: count)
        }

        // Current streak: consecutive days back from today that have at least one entry
        var streak = 0
        var dayCursor = startOfToday
        while allEntries.contains(where: { cal.isDate($0.date, inSameDayAs: dayCursor) }) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: dayCursor) else { break }
            dayCursor = prev
        }

        // Heatmap: last 70 days
        let heat: [HeatCell] = (0..<70).map { i in
            let d = cal.date(byAdding: .day, value: -(69 - i), to: startOfToday) ?? startOfToday
            let same = allEntries.filter { cal.isDate($0.date, inSameDayAs: d) }
            let values = same.compactMap { $0.moodValue }
            let v: Double? = values.isEmpty ? nil : Double(values.reduce(0, +)) / Double(values.count)
            return HeatCell(id: i, date: d, value: v, entries: same.count)
        }

        return TrendsData(
            range: range,
            points: points,
            totalEntries: totalEntries,
            avg: windowAvg,
            prevAvg: prevAvg,
            hasAvg: hasAvg,
            tags: tags,
            buckets: buckets,
            dist: dist,
            streak: streak,
            heat: heat
        )
    }
}

// MARK: - Helpers

private let monthAbbrevs = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

private func monthAbbrev(_ date: Date) -> String {
    let m = Calendar.current.component(.month, from: date)
    return monthAbbrevs[m - 1]
}

private func startOfMonth(of date: Date, cal: Calendar) -> Date {
    cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
}
