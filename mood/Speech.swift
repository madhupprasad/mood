//
//  Speech.swift
//  mood
//

import SwiftUI
import Speech
import AVFoundation

@MainActor
@Observable
final class SpeechTranscriber {
    enum State { case idle, recording, denied, unavailable }

    var state: State = .idle
    var transcript: String = ""

    private let recognizer = SFSpeechRecognizer()
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start() async {
        let speechAuth = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speechAuth == .authorized else { state = .denied; return }

        let micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        guard micGranted else { state = .denied; return }

        guard let recognizer, recognizer.isAvailable else { state = .unavailable; return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        let engine = AVAudioEngine()
        let format = engine.inputNode.outputFormat(forBus: 0)
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()

        do {
            try engine.start()
        } catch {
            state = .unavailable
            return
        }

        transcript = ""
        self.engine = engine
        self.request = request
        state = .recording

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        engine = nil
        request = nil
        task = nil
        state = .idle
    }
}
