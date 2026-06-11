//
//  moodApp.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

#if canImport(Sparkle)
import Sparkle
#endif

@main
struct moodApp: App {
    private let hotKeyManager = HotKeyManager()

    #if canImport(Sparkle)
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    #endif

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
        .commands {
            #if canImport(Sparkle)
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.updater.checkForUpdates()
                }
            }
            #endif
        }

        MenuBarExtra("Mood", systemImage: "face.smiling") {
            Button("Quick Entry  (⌃⌥M)") {
                QuickEntryPanel.shared.toggle()
            }
            #if canImport(Sparkle)
            Button("Check for Updates…") {
                updaterController.updater.checkForUpdates()
            }
            #endif
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
