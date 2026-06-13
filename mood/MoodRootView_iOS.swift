//
//  MoodRootView_iOS.swift
//  mood
//
//  iOS-only root. A tab bar (Write · Entries · Trends · Chat) replaces the
//  Mac sidebar. Tag filtering moves into the Entries tab as a chip strip.
//

#if os(iOS)

import SwiftUI

struct MoodRootView_iOS: View {
    private let store = MoodStore.shared
    @AppStorage("themeID") private var themeID: String = ThemeCatalog.cream.id

    @State private var draft: String = ""
    @State private var selectedMood: Int? = nil
    @State private var tagFilter: String? = nil
    @State private var chatService = ChatService()
    @State private var selectedTab: Int = 0

    private var theme: Theme { ThemeCatalog.theme(forID: themeID) }

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

    private var entriesForList: [MoodEntry] {
        guard let tagFilter else { return store.entries }
        return store.entries.filter { extractTags(from: $0.mood).contains(tagFilter) }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MoodComposer_iOS(draft: $draft, selectedMood: $selectedMood, onLog: log)
                .tabItem { Label("Write", systemImage: "pencil") }
                .tag(0)

            EntriesTab_iOS(
                entries: entriesForList,
                allTags: allTags,
                tagFilter: $tagFilter
            )
            .tabItem { Label("Entries", systemImage: "list.bullet") }
            .tag(1)

            TrendsView(entries: store.entries)
                .background(theme.background)
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            ChatView(entries: store.entries, service: chatService)
                .background(theme.background)
                .tabItem { Label("Chat", systemImage: "bubble.left.and.text.bubble.right") }
                .tag(3)
        }
        .environment(\.theme, theme)
        .tint(theme.accent)
        .preferredColorScheme(theme.isDark ? .dark : .light)
    }

    private func log() {
        // Mood is required on iOS; the note is optional.
        guard let mood = selectedMood else { return }
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        store.add(trimmed, moodValue: mood)
        draft = ""
        selectedMood = nil
    }
}

// MARK: - Entries tab (list + tag chip strip)

private struct EntriesTab_iOS: View {
    @Environment(\.theme) private var theme
    let entries: [MoodEntry]
    let allTags: [String]
    @Binding var tagFilter: String?

    var body: some View {
        VStack(spacing: 0) {
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(label: "All", active: tagFilter == nil) { tagFilter = nil }
                        ForEach(allTags, id: \.self) { tag in
                            chip(label: "#\(tag)", active: tagFilter == tag) {
                                tagFilter = (tagFilter == tag) ? nil : tag
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                Rectangle().fill(theme.line).frame(height: 0.5)
            }

            EntriesList(
                entries: entries,
                filter: tagFilter.map { .tag($0) } ?? .section(.allEntries),
                calendarDate: Date()
            )
        }
        .background(theme.background)
    }

    private func chip(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? theme.logButtonText : theme.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(active ? theme.primary : theme.line.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }
}

#endif
