# mood

A minimal macOS journaling app for tracking how you feel throughout the day. Built with SwiftUI.

## Features

- **Quick logging** — type a thought, hit Return, it's saved with a timestamp.
- **Global hotkey** — press `⌃⌥M` anywhere on your Mac to open a floating quick-entry bar. No need to switch apps.
- **Menu bar access** — a smiley icon lives in the menu bar for quick entry without the hotkey.
- **Inline tags** — type `#anything` in your entries. Tags appear as colored chips, get listed in the sidebar automatically, and act as filters.
- **Sidebar filters** — All Entries, Today, Calendar (with a custom mini month picker), and any tag you've used.
- **Voice dictation** — click the mic icon to dictate entries using Apple's on-device Speech framework.
- **Persistent storage** — entries are saved as JSON in the app's Application Support directory and load on launch.

## Requirements

- macOS 14 or later
- Xcode 16+ to build

## Running

1. Open `mood.xcodeproj` in Xcode.
2. Select the `mood` scheme and your Mac as the run destination.
3. ⌘R to build and run.

On first launch the app will request Microphone and Speech Recognition permissions when you use the mic button.

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Return` | Log current entry |
| `⌃⌥M`   | Toggle global quick-entry panel |
| `Esc`    | Close quick-entry panel without saving |

## Storage

Entries are stored at:

```
~/Library/Containers/com.tapasya.mood/Data/Library/Application Support/com.tapasya.mood/mood-entries.json
```

It's plain JSON — easy to back up, easy to migrate.

## Project structure

```
mood/
├── ContentView.swift    Main window: sidebar + composer + entry list
├── moodApp.swift        App entry, global hotkey, quick-entry panel, speech transcription
├── mood.entitlements    Sandbox + microphone + network entitlements
└── Assets.xcassets      App icon and asset catalog
```
