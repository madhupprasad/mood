//
//  Models.swift
//  mood
//

import SwiftUI

struct MoodEntry: Identifiable, Codable {
    var id: UUID = UUID()
    let mood: String
    let date: Date
    var moodValue: Int?
    var moodInferred: Bool = false

    init(id: UUID = UUID(), mood: String, date: Date, moodValue: Int? = nil, moodInferred: Bool = false) {
        self.id = id
        self.mood = mood
        self.date = date
        self.moodValue = moodValue
        self.moodInferred = moodInferred
    }

    private enum CodingKeys: String, CodingKey {
        case id, mood, date, moodValue, moodInferred
    }

    // Custom decoder so additions of new fields never break older entries on disk.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.mood = try c.decode(String.self, forKey: .mood)
        self.date = try c.decode(Date.self, forKey: .date)
        self.moodValue = try c.decodeIfPresent(Int.self, forKey: .moodValue)
        self.moodInferred = try c.decodeIfPresent(Bool.self, forKey: .moodInferred) ?? false
    }
}

@Observable
final class MoodStore {
    static let shared = MoodStore()

    private(set) var entries: [MoodEntry] = []

    private let fileURL: URL
    private let backupURL: URL

    private init() {
        let directory = URL.applicationSupportDirectory
            .appending(path: Bundle.main.bundleIdentifier ?? "mood")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appending(path: "mood-entries.json")
        self.backupURL = directory.appending(path: "mood-entries.backup.json")
        load()
    }

    func add(_ mood: String, moodValue: Int? = nil) {
        let entry = MoodEntry(mood: mood, date: Date(), moodValue: moodValue, moodInferred: false)
        entries.insert(entry, at: 0)
        save()
    }

    func clearAll() {
        entries = []
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            entries = try JSONDecoder().decode([MoodEntry].self, from: data)
        } catch {
            // Decoder failed: preserve the on-disk file rather than clobber it on the next save.
            let salvageURL = fileURL.appendingPathExtension("unreadable.\(Int(Date().timeIntervalSince1970))")
            try? FileManager.default.moveItem(at: fileURL, to: salvageURL)
            entries = []
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        // Keep a one-deep rolling backup before each write so the previous version is recoverable.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }
        try? data.write(to: fileURL, options: .atomic)
    }
}
