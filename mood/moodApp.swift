//
//  moodApp.swift
//  mood
//
//  Created by Madhupprasad S on 08/06/26.
//

import SwiftUI

#if os(macOS)
import AppKit
import Carbon.HIToolbox
#endif

#if canImport(Sparkle) && os(macOS)
import Sparkle
#endif

@main
struct moodApp: App {
    #if os(macOS)
    private let hotKeyManager = HotKeyManager()
    #endif

    #if canImport(Sparkle) && os(macOS)
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    #endif

    init() {
        #if os(macOS)
        hotKeyManager.register(keyCode: UInt32(kVK_ANSI_M),
                               modifiers: UInt32(controlKey | optionKey)) {
            QuickEntryPanel.shared.toggle()
        }
        #endif
    }

    var body: some Scene {
        #if os(macOS)
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
        #else
        WindowGroup {
            MoodRootView_iOS()
        }
        #endif
    }
}
