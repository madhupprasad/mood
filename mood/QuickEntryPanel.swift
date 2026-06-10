//
//  QuickEntryPanel.swift
//  mood
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

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

// MARK: - Floating panel

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
