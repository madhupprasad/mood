//
//  moodApp.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

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
