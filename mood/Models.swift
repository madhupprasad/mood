//
//  Models.swift
//  mood
//

import SwiftUI

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
