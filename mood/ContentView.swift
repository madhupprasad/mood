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

private struct SidebarTag: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

private let sidebarTags: [SidebarTag] = [
    .init(name: "work", color: Color(red: 0.93, green: 0.55, blue: 0.32)),
    .init(name: "personal", color: Color(red: 0.84, green: 0.36, blue: 0.36)),
    .init(name: "health", color: Color(red: 0.48, green: 0.66, blue: 0.45)),
    .init(name: "creative", color: Color(red: 0.86, green: 0.72, blue: 0.36)),
]

// MARK: - Root

struct ContentView: View {
    private let store = MoodStore.shared
    @State private var selectedSection: SidebarSection = .allEntries
    @State private var draft: String = ""

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selected: $selectedSection, entryCount: store.entries.count)
                .frame(width: 200)

            Rectangle()
                .fill(Color.mutedLine)
                .frame(width: 1)

            VStack(spacing: 0) {
                Composer(draft: $draft, onLog: log)
                Rectangle().fill(Color.mutedLine).frame(height: 1)
                EntriesList(entries: store.entries)
            }
            .background(Color.appBackground)
        }
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(.light)
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
    @Binding var selected: SidebarSection
    let entryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "LIBRARY", trailing: nil)

            ForEach(SidebarSection.allCases, id: \.self) { section in
                SidebarRow(
                    title: section.title,
                    icon: section.icon,
                    selected: selected == section
                ) {
                    selected = section
                }
            }

            SectionHeader(title: "TAGS", trailing: "+")

            ForEach(sidebarTags) { tag in
                HStack(spacing: 10) {
                    Circle().fill(tag.color).frame(width: 7, height: 7)
                    Text(tag.name)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.primaryText)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
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
    }

    private var statusText: String {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Nothing to save" }
        let words = trimmed.split { $0.isWhitespace }.count
        return "\(words) word\(words == 1 ? "" : "s") to save"
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
                    Text("ALL ENTRIES")
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
                    Text("No entries yet. Start writing above or press ⌃⌥M from anywhere.")
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
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.secondaryText)
                Circle().fill(Color.accentDot).frame(width: 6, height: 6)
            }
            .frame(width: 44, alignment: .leading)

            Text(entry.mood)
                .font(.system(size: 13))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

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
