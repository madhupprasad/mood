//
//  moodApp.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox
import Speech
import AVFoundation

@main
struct moodApp: App {
    private let hotKeyManager = HotKeyManager()

    init() {
        hotKeyManager.register(keyCode: UInt32(kVK_ANSI_M),
                               modifiers: UInt32(controlKey | optionKey)) {
            QuickEntryPanel.shared.toggle()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        MenuBarExtra("Mood", systemImage: "face.smiling") {
            Button("Quick Entry  (⌃⌥M)") {
                QuickEntryPanel.shared.toggle()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

// MARK: - Global hot key (Carbon)

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private static var handler: (() -> Void)?

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        Self.handler = handler

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            HotKeyManager.handler?()
            return noErr
        }, 1, &spec, nil, nil)

        let id = EventHotKeyID(signature: OSType(0x6D6F6F64), id: 1) // "mood"
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

// MARK: - Floating quick-entry panel

final class FloatingPanel: NSPanel {
    var onResignKey: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }
}

final class QuickEntryPanel {
    static let shared = QuickEntryPanel()
    private var panel: FloatingPanel?

    func toggle() {
        if let panel, panel.isVisible {
            dismiss()
        } else {
            present()
        }
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func present() {
        let view = QuickEntryView { [weak self] in self?.dismiss() }
        let hosting = NSHostingView(rootView: view)

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 60),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
//        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.contentView = hosting
        panel.center()
        panel.onResignKey = { [weak self] in self?.dismiss() }

        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)

        self.panel = panel
    }
}

private struct QuickEntryView: View {
    let onClose: () -> Void
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("How do you feel?", text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 22, weight: .light))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .focused($focused)
            .onAppear {
                DispatchQueue.main.async { focused = true }
            }
            .onSubmit(submit)
            .onExitCommand(perform: onClose)
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        MoodStore.shared.add(trimmed)
        text = ""
        onClose()
    }
}

// MARK: - Live speech transcription

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

