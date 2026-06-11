//
//  Entries.swift
//  mood
//

import SwiftUI

// MARK: - Tag helpers

private let tagRegex = /#([A-Za-z0-9_]+)/

func extractTags(from text: String) -> [String] {
    text.matches(of: tagRegex).map { String($0.output.1).lowercased() }
}

func bodyWithoutTags(_ text: String) -> String {
    text.replacing(tagRegex, with: "")
        .replacing(/\s+/, with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private let tagPalette: [Color] = [
    Color(red: 0.93, green: 0.55, blue: 0.32), // orange
    Color(red: 0.84, green: 0.36, blue: 0.36), // red
    Color(red: 0.48, green: 0.66, blue: 0.45), // green
    Color(red: 0.86, green: 0.72, blue: 0.36), // yellow
    Color(red: 0.45, green: 0.55, blue: 0.78), // blue
    Color(red: 0.70, green: 0.48, blue: 0.72), // purple
]

func colorForTag(_ name: String) -> Color {
    let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    return tagPalette[sum % tagPalette.count]
}

// MARK: - Entries list

struct EntriesList: View {
    @Environment(\.theme) private var theme
    let entries: [MoodEntry]
    let filter: SidebarFilter
    let calendarDate: Date

    private var groups: [(label: String, items: [MoodEntry])] {
        let cal = Calendar.current
        let now = Date()
        let dict = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return dict
            .sorted { $0.key > $1.key }
            .map { day, items in
                (dayLabel(for: day, now: now), items.sorted { $0.date > $1.date })
            }
    }

    private var headerTitle: String {
        switch filter {
        case .section(.calendar):
            return calendarDate.formatted(.dateTime.month(.wide).day().year()).uppercased()
        case .section(let s):
            return s.title.uppercased()
        case .tag(let name):
            return "#\(name.uppercased())"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .section(.today): "Nothing logged today yet."
        case .section(.allEntries): "No entries yet. Start writing above or press ⌃⌥M from anywhere."
        case .section(.calendar): "Nothing logged on this day."
        case .section(.trends): "Nothing here yet."
        case .section(.chat): "Nothing here yet."
        case .tag(let name): "No entries tagged #\(name)."
        }
    }

    private func dayLabel(for date: Date, now: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "TODAY" }
        if cal.isDateInYesterday(date) { return "YESTERDAY" }
        if let days = cal.dateComponents([.day], from: date, to: now).day, days < 7 {
            return date.formatted(.dateTime.weekday(.wide)).uppercased()
        }
        return date.formatted(.dateTime.month().day()).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(headerTitle)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(theme.secondary)
                    Text("·").foregroundStyle(theme.secondary)
                    Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.secondary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .overlay(
                    Rectangle().fill(theme.line).frame(height: 1),
                    alignment: .bottom
                )

                if entries.isEmpty {
                    Text(emptyMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                }

                ForEach(groups, id: \.label) { group in
                    Text(group.label)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(theme.secondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 6)

                    ForEach(group.items) { entry in
                        EntryRow(entry: entry)
                    }
                }

                Spacer(minLength: 24)
            }
        }
    }
}

// MARK: - Entry row

private struct EntryRow: View {
    @Environment(\.theme) private var theme
    let entry: MoodEntry

    var body: some View {
        let tags = extractTags(from: entry.mood)
        let body = bodyWithoutTags(entry.mood)

        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(theme.secondary)
                moodIndicator
            }
            .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if !body.isEmpty {
                    Text(body)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !tags.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .overlay(
            Rectangle().fill(theme.line.opacity(0.6)).frame(height: 1),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var moodIndicator: some View {
        if let v = entry.moodValue, let level = MoodLevel.all.first(where: { $0.value == v }) {
            Text(level.shape)
                .font(.system(size: 11))
                .foregroundStyle(level.color)
                .opacity(entry.moodInferred ? 0.6 : 1.0)
                .help(entry.moodInferred ? "\(level.name) (inferred)" : level.name)
        } else {
            Circle().fill(theme.accent).frame(width: 6, height: 6)
        }
    }
}
