//
//  ContentView.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI

// MARK: - Model

struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    let mood: String
    let date: Date
}

@Observable
final class MoodStore {
    static let shared = MoodStore()

    private(set) var entries: [MoodEntry] = []
    private let fileURL: URL

    private init() {
        let directory = URL.applicationSupportDirectory
            .appending(path: Bundle.main.bundleIdentifier ?? "mood")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appending(path: "mood-entries.json")
        load()
    }

    func add(_ mood: String) {
        entries.insert(MoodEntry(mood: mood, date: Date()), at: 0)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Theme

private extension Color {
    static let appBackground = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let sidebarBackground = Color(red: 0.94, green: 0.93, blue: 0.89)
    static let selectionFill = Color(red: 0.90, green: 0.88, blue: 0.83)
    static let primaryText = Color(red: 0.18, green: 0.17, blue: 0.16)
    static let secondaryText = Color(red: 0.55, green: 0.53, blue: 0.49)
    static let mutedLine = Color(red: 0.87, green: 0.85, blue: 0.81)
    static let accentDot = Color(red: 0.48, green: 0.66, blue: 0.45)
}

// MARK: - Sidebar model

enum SidebarSection: Hashable, CaseIterable {
    case allEntries, today, calendar, trends

    var title: String {
        switch self {
        case .allEntries: "All Entries"
        case .today: "Today"
        case .calendar: "Calendar"
        case .trends: "Trends"
        }
    }

    var icon: String {
        switch self {
        case .allEntries: "circle.fill"
        case .today: "sun.max"
        case .calendar: "calendar"
        case .trends: "chart.line.uptrend.xyaxis"
        }
    }
}

enum SidebarFilter: Hashable {
    case section(SidebarSection)
    case tag(String)
}

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

// MARK: - Root

struct ContentView: View {
    private let store = MoodStore.shared
    @State private var filter: SidebarFilter = .section(.allEntries)
    @State private var calendarDate: Date = Date()
    @State private var draft: String = ""

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(
                filter: $filter,
                calendarDate: $calendarDate,
                allTags: allTags,
                entryCount: store.entries.count
            )
            .frame(width: 220)

            Rectangle()
                .fill(Color.mutedLine)
                .frame(width: 1)

            VStack(spacing: 0) {
                Composer(draft: $draft, onLog: log)
                Rectangle().fill(Color.mutedLine).frame(height: 1)
                EntriesList(
                    entries: filteredEntries,
                    filter: filter,
                    calendarDate: calendarDate
                )
            }
            .background(Color.appBackground)
        }
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(.light)
    }

    private var allTags: [String] {
        var seen: Set<String> = []
        var ordered: [String] = []
        for entry in store.entries {
            for tag in extractTags(from: entry.mood) where seen.insert(tag).inserted {
                ordered.append(tag)
            }
        }
        return ordered.sorted()
    }

    private var filteredEntries: [MoodEntry] {
        let cal = Calendar.current
        switch filter {
        case .section(.today):
            return store.entries.filter { cal.isDateInToday($0.date) }
        case .section(.calendar):
            return store.entries.filter { cal.isDate($0.date, inSameDayAs: calendarDate) }
        case .section(.allEntries), .section(.trends):
            return store.entries
        case .tag(let name):
            return store.entries.filter { extractTags(from: $0.mood).contains(name) }
        }
    }

    private func log() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed)
        draft = ""
    }
}

// MARK: - Sidebar

private struct Sidebar: View {
    @Binding var filter: SidebarFilter
    @Binding var calendarDate: Date
    let allTags: [String]
    let entryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "LIBRARY", trailing: nil)

            ForEach(SidebarSection.allCases, id: \.self) { section in
                SidebarRow(
                    title: section.title,
                    icon: section.icon,
                    selected: filter == .section(section)
                ) {
                    filter = .section(section)
                }

                if section == .calendar && filter == .section(.calendar) {
                    MiniCalendar(selected: $calendarDate)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                }
            }

            SectionHeader(title: "TAGS", trailing: allTags.isEmpty ? nil : "\(allTags.count)")

            if allTags.isEmpty {
                Text("Type #tags in your entries")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            } else {
                ForEach(allTags, id: \.self) { tag in
                    Button {
                        filter = .tag(tag)
                    } label: {
                        HStack(spacing: 10) {
                            Circle().fill(colorForTag(tag)).frame(width: 7, height: 7)
                            Text(tag)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                        .background(filter == .tag(tag) ? Color.selectionFill : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            UserCard(name: "Alex Chen", subtitle: "\(entryCount) entries")
        }
        .background(Color.sidebarBackground)
    }
}

private struct SectionHeader: View {
    let title: String
    let trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.secondaryText)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

private struct SidebarRow: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 12)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.primaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(selected ? Color.selectionFill : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct MiniCalendar: View {
    @Binding var selected: Date
    @State private var month: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                Spacer()
                navButton(systemImage: "chevron.left") { shiftMonth(-1) }
                navButton(systemImage: "chevron.right") { shiftMonth(1) }
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 2) {
                ForEach(0..<numberOfRows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            cell(at: index)
                        }
                    }
                }
            }
        }
    }

    private func navButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.secondaryText)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
    }

    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols.map { String($0.prefix(2)) }
    }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart) // 1 = Sun
        return weekday - calendar.firstWeekday
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    private var numberOfRows: Int {
        Int(ceil(Double(leadingBlanks + daysInMonth) / 7.0))
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        let dayIndex = index - leadingBlanks
        if dayIndex < 0 || dayIndex >= daysInMonth {
            Text("")
                .frame(maxWidth: .infinity, minHeight: 20)
        } else {
            let date = calendar.date(byAdding: .day, value: dayIndex, to: monthStart) ?? monthStart
            let isSelected = calendar.isDate(date, inSameDayAs: selected)
            let isToday = calendar.isDateInToday(date)

            Button {
                selected = date
            } label: {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(isSelected ? .white : Color.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 20)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 4).fill(Color.primaryText)
                            } else if isToday {
                                RoundedRectangle(cornerRadius: 4).stroke(Color.primaryText.opacity(0.35), lineWidth: 1)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func shiftMonth(_ delta: Int) {
        month = calendar.date(byAdding: .month, value: delta, to: month) ?? month
    }
}

private struct UserCard: View {
    let name: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(red: 0.93, green: 0.55, blue: 0.32))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .overlay(
            Rectangle().fill(Color.mutedLine).frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Composer

private struct Composer: View {
    @Binding var draft: String
    let onLog: () -> Void

    @State private var now: Date = Date()
    @State private var transcriber = SpeechTranscriber()
    @State private var draftBeforeRecording: String = ""
    @State private var pttHolding: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(now, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute().second())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.secondaryText)
                    Text(now, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.secondaryText)
                }
                .frame(width: 60, alignment: .leading)

                TextField("What's on your mind right now…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1...5)
                    .onSubmit(onLog)
                    .onKeyPress(.space, phases: .all) { press in
                        handlePushToTalk(press)
                    }

                Button(action: toggleRecording) {
                    Image(systemName: micIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(micColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle().fill(transcriber.state == .recording ? Color.red.opacity(0.12) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help(micHelp)
            }

            HStack(spacing: 8) {
                Text("MOOD")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.secondaryText)
                HStack(spacing: 14) {
                    Circle().fill(Color.primaryText).frame(width: 7, height: 7)
                    Rectangle().fill(Color.primaryText).frame(width: 7, height: 7)
                    Triangle().fill(Color.primaryText).frame(width: 8, height: 7)
                    Triangle().fill(Color.primaryText).frame(width: 8, height: 7).rotationEffect(.degrees(180))
                    Circle().stroke(Color.primaryText, lineWidth: 1).frame(width: 7, height: 7)
                }
                Spacer()
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondaryText)
                Button(action: onLog) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up").font(.system(size: 10, weight: .medium))
                        Text("Log").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryText)
                    .foregroundStyle(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.leading, 76)
        }
        .padding(24)
        .task {
            while !Task.isCancelled {
                now = Date()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onChange(of: transcriber.transcript) { _, newValue in
            guard transcriber.state == .recording else { return }
            let separator = draftBeforeRecording.isEmpty ? "" : " "
            draft = draftBeforeRecording + separator + newValue
        }
    }

    private var statusText: String {
        if transcriber.state == .recording { return "Listening…" }
        if transcriber.state == .denied { return "Mic permission needed" }
        if transcriber.state == .unavailable { return "Speech unavailable" }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Nothing to save" }
        let words = trimmed.split { $0.isWhitespace }.count
        return "\(words) word\(words == 1 ? "" : "s") to save"
    }

    private var micIcon: String {
        transcriber.state == .recording ? "stop.circle.fill" : "mic"
    }

    private var micColor: Color {
        switch transcriber.state {
        case .recording: .red
        case .denied, .unavailable: Color.secondaryText.opacity(0.5)
        case .idle: Color.secondaryText
        }
    }

    private var micHelp: String {
        switch transcriber.state {
        case .recording: "Stop recording"
        case .denied: "Allow microphone access in System Settings"
        case .unavailable: "Speech recognition unavailable"
        case .idle: "Dictate your entry  (or hold ⌥Space)"
        }
    }

    private func toggleRecording() {
        if transcriber.state == .recording {
            transcriber.stop()
        } else {
            draftBeforeRecording = draft
            Task { await transcriber.start() }
        }
    }

    private func handlePushToTalk(_ press: KeyPress) -> KeyPress.Result {
        if pttHolding {
            if press.phase == .up {
                pttHolding = false
                transcriber.stop()
            }
            return .handled
        }
        if press.phase == .down && press.modifiers.contains(.option) {
            pttHolding = true
            draftBeforeRecording = draft
            Task { await transcriber.start() }
            return .handled
        }
        return .ignored
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Entries list

private struct EntriesList: View {
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
                        .foregroundStyle(Color.secondaryText)
                    Text("·").foregroundStyle(Color.secondaryText)
                    Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .overlay(
                    Rectangle().fill(Color.mutedLine).frame(height: 1),
                    alignment: .bottom
                )

                if entries.isEmpty {
                    Text(emptyMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondaryText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                }

                ForEach(groups, id: \.label) { group in
                    Text(group.label)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Color.secondaryText)
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

private struct EntryRow: View {
    let entry: MoodEntry

    var body: some View {
        let tags = extractTags(from: entry.mood)
        let body = bodyWithoutTags(entry.mood)

        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.secondaryText)
                Circle().fill(Color.accentDot).frame(width: 6, height: 6)
            }
            .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if !body.isEmpty {
                    Text(body)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.primaryText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !tags.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.accentDot)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .overlay(
            Rectangle().fill(Color.mutedLine.opacity(0.6)).frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    ContentView()
}
