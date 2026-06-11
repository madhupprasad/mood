# mood

<img width="1440" height="900" alt="Screenshot 2026-06-08 at 8 04 40 PM" src="https://github.com/user-attachments/assets/68d0f8c6-8011-48f0-b934-dcd1c11a1129" />

A minimal macOS journaling app for tracking how you feel throughout the day. Built with SwiftUI.

## Features

- **Quick logging** — type a thought, hit Return, it's saved with a timestamp.
- **Global hotkey** — press `⌃⌥M` anywhere on your Mac to open a floating quick-entry bar. No need to switch apps.
- **Menu bar access** — a smiley icon lives in the menu bar for quick entry without the hotkey.
- **Inline tags** — type `#anything` in your entries. Tags appear as colored chips, get listed in the sidebar automatically, and act as filters.
- **Sidebar filters** — All Entries, Today, Calendar (with a custom mini month picker), and any tag you've used.
- **Voice dictation** — click the mic icon to dictate entries using Apple's on-device Speech framework.
- **Persistent storage** — entries are saved as JSON in the app's Application Support directory and load on launch.

## Install

1. Download `mood.zip` from the [latest release](https://github.com/madhupprasad/mood/releases/latest).
2. Unzip it and drag `mood.app` into `/Applications`.
3. **First launch**: right-click the app → **Open** → click **Open** in the dialog.
   The app isn't notarized, so macOS will warn the first time. This bypass is a one-time step — subsequent launches open normally.

Requires **macOS 26.5 (Tahoe)** or later.

When you first use the mic button, macOS will ask for Microphone and Speech Recognition permission.

## Build from source

If you'd rather build it yourself or hack on the app:

- macOS 26.5 or later
- Xcode 16+ (or whatever ships with Tahoe)

1. Clone the repo.
2. Open `mood.xcodeproj` in Xcode.
3. Select the `mood` scheme and your Mac as the run destination.
4. ⌘R to build and run.

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
