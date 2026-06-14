//
//  ContentView.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI

struct ContentView: View {
    private let store = MoodStore.shared
    @AppStorage("themeID") private var themeID: String = ThemeCatalog.cream.id
    @State private var filter: SidebarFilter = .section(.allEntries)
    @State private var calendarDate: Date = Date()
    @State private var draft: String = ""
    @State private var selectedMood: Int? = nil
    @State private var selectedEmotions: Set<String> = []
    @State private var chatService = ChatService()

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
                Composer(draft: $draft, selectedMood: $selectedMood, selectedEmotions: $selectedEmotions, onLog: log)
                Rectangle().fill(theme.line).frame(height: 1)
                switch filter {
                case .section(.trends):
                    TrendsView(entries: store.entries)
                case .section(.chat):
                    ChatView(entries: store.entries, service: chatService)
                case .section(.games):
                    GamesView()
                default:
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
        case .section(.allEntries), .section(.trends), .section(.chat), .section(.games):
            return store.entries
        case .tag(let name):
            return store.entries.filter { extractTags(from: $0.mood).contains(name) }
        }
    }

    private func log() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed, moodValue: selectedMood, emotions: Array(selectedEmotions))
        draft = ""
        selectedMood = nil
        selectedEmotions = []
    }
}

#Preview {
    ContentView()
}
