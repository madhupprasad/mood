//
//  ContentView.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI

struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    let mood: String
    let date: Date
}

@Observable
final class MoodStore {
    private(set) var entries: [MoodEntry] = []
    private let fileURL: URL

    init() {
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

struct ContentView: View {
    @State private var store = MoodStore()
    @State private var mood: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("How do you feel now?")
                .font(.title)
                .bold()
                .foregroundColor(.yellow)

            TextField("Enter your mood", text: $mood)
                .textFieldStyle(.roundedBorder)
                .onSubmit(logMood)

            Button("Log Mood") {
                logMood()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(mood.trimmingCharacters(in: .whitespaces).isEmpty)

            List(store.entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(entry.date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(entry.mood)
                    Spacer()
                }
            }
        }
        .padding()
    }

    private func logMood() {
        let trimmed = mood.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed)
        mood = ""
    }
}

#Preview {
    ContentView()
}
