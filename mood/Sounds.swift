//
//  Sounds.swift
//  mood
//
//  Plays a small affirmation when the user burns something in the vent pad.
//  Tries an audio file in this order:
//    1. Bundled resource named slay-queen.{m4a,mp3,caf,wav,aiff}
//    2. File at ~/Library/Application Support/com.tapasya.mood/slay-queen.{...}
//  Falls back to AVSpeechSynthesizer speaking "Slay, queen" so the feature
//  is functional out of the box even before a real recording is dropped in.
//

import Foundation
import AVFoundation

@MainActor
final class BurnSoundPlayer {
    static let shared = BurnSoundPlayer()

    private var player: AVAudioPlayer?
    private let synth = AVSpeechSynthesizer()

    private static let baseNames = ["slay-queen", "slay_queen", "burn"]
    private static let extensions = ["m4a", "mp3", "caf", "wav", "aiff"]

    private init() {}

    func play() {
        if let bundled = findBundledClip() {
            playFile(bundled)
            return
        }
        if let userFile = findUserClip() {
            playFile(userFile)
            return
        }
        speakFallback()
    }

    // MARK: - Locate

    private func findBundledClip() -> URL? {
        for name in Self.baseNames {
            for ext in Self.extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    return url
                }
            }
        }
        return nil
    }

    private func findUserClip() -> URL? {
        let dir = URL.applicationSupportDirectory
            .appending(path: Bundle.main.bundleIdentifier ?? "mood")
        for name in Self.baseNames {
            for ext in Self.extensions {
                let url = dir.appending(path: "\(name).\(ext)")
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
        }
        return nil
    }

    // MARK: - Play

    private func playFile(_ url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.9
            player?.prepareToPlay()
            player?.play()
        } catch {
            speakFallback()
        }
    }

    private func speakFallback() {
        let utterance = AVSpeechUtterance(string: "Slay, queen.")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.15
        utterance.voice = preferredVoice()
        synth.speak(utterance)
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let englishFemale = voices.filter {
            $0.language.hasPrefix("en") && $0.gender == .female
        }
        // Prefer premium > enhanced > default
        if let premium = englishFemale.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = englishFemale.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return englishFemale.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
