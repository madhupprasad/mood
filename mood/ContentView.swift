//
//  ContentView.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI
import FoundationModels

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

// MARK: - Weekly summary (FoundationModels)

@Generable
struct WeeklySummary {
    @Guide(description: "One short sentence capturing the overall emotional tone of the week.")
    let mood: String

    @Guide(description: "Three to four short phrases (2-4 words each) describing recurring themes from the entries.")
    let themes: [String]

    @Guide(description: "A single notable moment, shift, or pattern from the week, described in one sentence.")
    let highlight: String

    @Guide(description: "A gentle, supportive observation or suggestion for the coming week. One to two sentences.")
    let suggestion: String
}

@MainActor
@Observable
final class WeeklySummarizer {
    enum State {
        case idle
        case loading
        case ready(WeeklySummary)
        case empty
        case unavailable(String)
        case failed(String)
    }

    var state: State = .idle

    func generateIfNeeded(from entries: [MoodEntry]) async {
        if case .idle = state {
            await generate(from: entries)
        }
    }

    func generate(from entries: [MoodEntry]) async {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = entries.filter { $0.date >= weekAgo }

        guard !recent.isEmpty else {
            state = .empty
            return
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.appleIntelligenceNotEnabled):
            state = .unavailable("Enable Apple Intelligence in System Settings to see weekly summaries.")
            return
        case .unavailable(.modelNotReady):
            state = .unavailable("The on-device model is still downloading. Try again shortly.")
            return
        case .unavailable(.deviceNotEligible):
            state = .unavailable("This Mac doesn't support Apple Intelligence.")
            return
        case .unavailable:
            state = .unavailable("Foundation Models is unavailable on this device.")
            return
        }

        state = .loading

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d 'at' h:mm a"
        let entriesText = recent
            .sorted { $0.date < $1.date }
            .map { entry in "• [\(formatter.string(from: entry.date))] \(entry.mood)" }
            .joined(separator: "\n")

        let instructions = """
            You are a thoughtful journaling companion who helps someone reflect on their week. \
            You read their short mood-tracker entries and produce a brief, warm, perceptive weekly summary. \
            Be specific and grounded in what they actually wrote — don't invent details or feelings they did not express. \
            Be encouraging but not saccharine. Keep responses concise.
            """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
            Here are this week's mood entries, in chronological order:

            \(entriesText)

            Reflect on this week.
            """

        do {
            let response = try await session.respond(to: prompt, generating: WeeklySummary.self)
            state = .ready(response.content)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Theme

struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let background: Color
    let sidebar: Color
    let selection: Color
    let primary: Color
    let secondary: Color
    let line: Color
    let accent: Color
    let logButtonText: Color
    let isDark: Bool
}

enum ThemeCatalog {
    static let cream = Theme(
        id: "cream",
        name: "Cream",
        background: Color(red: 0.97, green: 0.96, blue: 0.93),
        sidebar: Color(red: 0.94, green: 0.93, blue: 0.89),
        selection: Color(red: 0.90, green: 0.88, blue: 0.83),
        primary: Color(red: 0.18, green: 0.17, blue: 0.16),
        secondary: Color(red: 0.55, green: 0.53, blue: 0.49),
        line: Color(red: 0.87, green: 0.85, blue: 0.81),
        accent: Color(red: 0.48, green: 0.66, blue: 0.45),
        logButtonText: .white,
        isDark: false
    )

    static let slate = Theme(
        id: "slate",
        name: "Slate",
        background: Color(red: 0.11, green: 0.12, blue: 0.13),
        sidebar: Color(red: 0.14, green: 0.15, blue: 0.17),
        selection: Color(red: 0.20, green: 0.22, blue: 0.25),
        primary: Color(red: 0.91, green: 0.90, blue: 0.87),
        secondary: Color(red: 0.55, green: 0.55, blue: 0.53),
        line: Color(red: 0.19, green: 0.20, blue: 0.22),
        accent: Color(red: 0.58, green: 0.78, blue: 0.55),
        logButtonText: Color(red: 0.11, green: 0.12, blue: 0.13),
        isDark: true
    )

    static let sky = Theme(
        id: "sky",
        name: "Sky",
        background: Color(red: 0.96, green: 0.97, blue: 0.99),
        sidebar: Color(red: 0.90, green: 0.93, blue: 0.96),
        selection: Color(red: 0.82, green: 0.87, blue: 0.93),
        primary: Color(red: 0.12, green: 0.17, blue: 0.23),
        secondary: Color(red: 0.42, green: 0.49, blue: 0.57),
        line: Color(red: 0.80, green: 0.85, blue: 0.90),
        accent: Color(red: 0.34, green: 0.55, blue: 0.85),
        logButtonText: .white,
        isDark: false
    )

    static let lavender = Theme(
        id: "lavender",
        name: "Lavender",
        background: Color(red: 0.96, green: 0.95, blue: 0.97),
        sidebar: Color(red: 0.92, green: 0.90, blue: 0.94),
        selection: Color(red: 0.85, green: 0.82, blue: 0.89),
        primary: Color(red: 0.20, green: 0.16, blue: 0.26),
        secondary: Color(red: 0.50, green: 0.45, blue: 0.55),
        line: Color(red: 0.84, green: 0.81, blue: 0.87),
        accent: Color(red: 0.59, green: 0.42, blue: 0.78),
        logButtonText: .white,
        isDark: false
    )

    static let solar = Theme(
        id: "solar",
        name: "Solar",
        background: Color(red: 0.98, green: 0.95, blue: 0.91),
        sidebar: Color(red: 0.95, green: 0.91, blue: 0.83),
        selection: Color(red: 0.91, green: 0.85, blue: 0.73),
        primary: Color(red: 0.18, green: 0.14, blue: 0.09),
        secondary: Color(red: 0.58, green: 0.52, blue: 0.41),
        line: Color(red: 0.86, green: 0.78, blue: 0.62),
        accent: Color(red: 0.89, green: 0.52, blue: 0.29),
        logButtonText: .white,
        isDark: false
    )

    static let all: [Theme] = [cream, slate, sky, lavender, solar]

    static func theme(forID id: String) -> Theme {
        all.first(where: { $0.id == id }) ?? cream
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = ThemeCatalog.cream
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
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
    @AppStorage("themeID") private var themeID: String = ThemeCatalog.cream.id
    @State private var filter: SidebarFilter = .section(.allEntries)
    @State private var calendarDate: Date = Date()
    @State private var draft: String = ""
    @State private var summarizer = WeeklySummarizer()

    private var theme: Theme { ThemeCatalog.theme(forID: themeID) }

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(
                filter: $filter,
                calendarDate: $calendarDate,
                themeID: $themeID,
                allTags: allTags
            )
            .frame(width: 220)

            Rectangle()
                .fill(theme.line)
                .frame(width: 1)

            VStack(spacing: 0) {
                Composer(draft: $draft, onLog: log)
                Rectangle().fill(theme.line).frame(height: 1)
                if case .section(.trends) = filter {
                    TrendsView(entries: store.entries, summarizer: summarizer)
                } else {
                    EntriesList(
                        entries: filteredEntries,
                        filter: filter,
                        calendarDate: calendarDate
                    )
                }
            }
            .background(theme.background)
        }
        .environment(\.theme, theme)
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(theme.isDark ? .dark : .light)
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
    @Environment(\.theme) private var theme
    @Binding var filter: SidebarFilter
    @Binding var calendarDate: Date
    @Binding var themeID: String
    let allTags: [String]

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
                    .foregroundStyle(theme.secondary)
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
                                .foregroundStyle(theme.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                        .background(filter == .tag(tag) ? theme.selection : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            ThemePicker(themeID: $themeID)
        }
        .background(theme.sidebar)
    }
}

private struct SectionHeader: View {
    @Environment(\.theme) private var theme
    let title: String
    let trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

private struct SidebarRow: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.primary)
                    .frame(width: 12)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(selected ? theme.selection : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct MiniCalendar: View {
    @Environment(\.theme) private var theme
    @Binding var selected: Date
    @State private var month: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.primary)
                Spacer()
                navButton(systemImage: "chevron.left") { shiftMonth(-1) }
                navButton(systemImage: "chevron.right") { shiftMonth(1) }
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.secondary)
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
                .foregroundStyle(theme.secondary)
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
        let weekday = calendar.component(.weekday, from: monthStart)
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
                    .foregroundStyle(isSelected ? theme.logButtonText : theme.primary)
                    .frame(maxWidth: .infinity, minHeight: 20)
                    .background(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 4).fill(theme.primary)
                            } else if isToday {
                                RoundedRectangle(cornerRadius: 4).stroke(theme.primary.opacity(0.35), lineWidth: 1)
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

// MARK: - Theme picker

private struct ThemePicker: View {
    @Environment(\.theme) private var theme
    @Binding var themeID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("THEME")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(theme.secondary)
                Spacer()
                Text(theme.name)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondary)
            }
            HStack(spacing: 10) {
                ForEach(ThemeCatalog.all) { candidate in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            themeID = candidate.id
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(theme.primary, lineWidth: 1.5)
                                .padding(-3)
                                .opacity(themeID == candidate.id ? 1 : 0)

                            Circle()
                                .fill(candidate.background)
                                .overlay(
                                    Circle()
                                        .trim(from: 0.5, to: 1.0)
                                        .fill(candidate.accent)
                                        .rotationEffect(.degrees(-90))
                                )
                                .overlay(Circle().stroke(candidate.primary.opacity(0.3), lineWidth: 0.8))
                                .frame(width: 22, height: 22)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(candidate.name)
                }
                Spacer()
            }
        }
        .padding(16)
        .overlay(
            Rectangle().fill(theme.line).frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Composer

private struct Composer: View {
    @Environment(\.theme) private var theme
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
                        .foregroundStyle(theme.secondary)
                    Text(now, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(theme.secondary)
                }
                .frame(width: 60, alignment: .leading)

                TextField("What's on your mind right now…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primary)
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
                    .foregroundStyle(theme.secondary)
                HStack(spacing: 14) {
                    Circle().fill(theme.primary).frame(width: 7, height: 7)
                    Rectangle().fill(theme.primary).frame(width: 7, height: 7)
                    Triangle().fill(theme.primary).frame(width: 8, height: 7)
                    Triangle().fill(theme.primary).frame(width: 8, height: 7).rotationEffect(.degrees(180))
                    Circle().stroke(theme.primary, lineWidth: 1).frame(width: 7, height: 7)
                }
                Spacer()
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.secondary)
                Button(action: onLog) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up").font(.system(size: 10, weight: .medium))
                        Text("Log").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.primary)
                    .foregroundStyle(theme.logButtonText)
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
        case .denied, .unavailable: theme.secondary.opacity(0.5)
        case .idle: theme.secondary
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
                Circle().fill(theme.accent).frame(width: 6, height: 6)
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
}

// MARK: - Trends (weekly summary)

private struct TrendsView: View {
    @Environment(\.theme) private var theme
    let entries: [MoodEntry]
    let summarizer: WeeklySummarizer

    private var entriesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.date >= weekAgo }.count
    }

    private var isLoading: Bool {
        if case .loading = summarizer.state { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                content
                Spacer(minLength: 24)
            }
        }
        .task {
            await summarizer.generateIfNeeded(from: entries)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("WEEKLY SUMMARY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            Text("·").foregroundStyle(theme.secondary)
            Text("\(entriesThisWeek) \(entriesThisWeek == 1 ? "entry" : "entries") this week")
                .font(.system(size: 10))
                .foregroundStyle(theme.secondary)
            Spacer()
            Button {
                Task { await summarizer.generate(from: entries) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .help("Regenerate summary")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(
            Rectangle().fill(theme.line).frame(height: 1),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var content: some View {
        switch summarizer.state {
        case .idle:
            placeholder("Generating a reflection on your week…")
        case .loading:
            loadingState
        case .ready(let summary):
            summaryCard(summary)
        case .empty:
            placeholder("Log some entries this week to see a summary here.")
        case .unavailable(let msg):
            placeholder(msg)
        case .failed(let msg):
            placeholder("Couldn't generate a summary. \(msg)")
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Reflecting on your week…")
                .font(.system(size: 12))
                .foregroundStyle(theme.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(theme.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
    }

    private func summaryCard(_ summary: WeeklySummary) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            summarySection(label: "MOOD") {
                Text(summary.mood)
                    .font(.system(size: 16))
                    .lineSpacing(4)
            }

            if !summary.themes.isEmpty {
                summarySection(label: "THEMES") {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(summary.themes, id: \.self) { themeName in
                            Text(themeName)
                                .font(.system(size: 12))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(theme.selection)
                                )
                                .foregroundStyle(theme.primary)
                        }
                    }
                }
            }

            summarySection(label: "HIGHLIGHT") {
                Text(summary.highlight)
                    .font(.system(size: 13))
                    .lineSpacing(3)
            }

            summarySection(label: "FOR NEXT WEEK") {
                Text(summary.suggestion)
                    .font(.system(size: 13))
                    .italic()
                    .lineSpacing(3)
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func summarySection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(theme.secondary)
            content()
                .foregroundStyle(theme.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Simple flow layout for theme chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    ContentView()
}
