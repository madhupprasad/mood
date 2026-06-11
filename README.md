# mood

## A minimal macOS journaling app for tracking how you feel throughout the day. Built with SwiftUI.

## Main screen
<img width="1437" height="900" alt="Screenshot 2026-06-12 at 1 24 14 AM" src="https://github.com/user-attachments/assets/9bc9c757-22ad-406d-bbd6-2e2a84b8727c" />

## Spotlight like pop-up - make an entry from anywhere.
<img width="1440" height="747" alt="Screenshot 2026-06-12 at 1 26 22 AM" src="https://github.com/user-attachments/assets/cf8cca50-0cc0-4e4c-a2ce-c058b62130ec" />

## Themes
<img width="220" height="126" alt="Screenshot 2026-06-12 at 1 25 08 AM" src="https://github.com/user-attachments/assets/428a1057-826a-4275-ab54-0ecfeb3aaaad" />

## Talk with your past self - with AI
<img width="1440" height="388" alt="Screenshot 2026-06-12 at 1 24 58 AM" src="https://github.com/user-attachments/assets/ebc0a75a-28c4-4a3e-a9ad-85209909e84d" />

## TRENDS - Graphical analysis on your mood
<img width="1440" height="900" alt="Screenshot 2026-06-12 at 1 24 24 AM" src="https://github.com/user-attachments/assets/01b8351a-07fb-4dc4-9ec0-82023cc79d03" />


## Features

- **Quick logging** — type a thought, hit Return, it's saved with a timestamp.
- **Global hotkey** — press `⌃⌥M` anywhere on your Mac to open a floating quick-entry bar. No need to switch apps.
- **Menu bar access** — a smiley icon lives in the menu bar for quick entry without the hotkey.
- **Inline tags** — type `#anything` in your entries. Tags appear as colored chips, get listed in the sidebar automatically, and act as filters.
- **Sidebar filters** — All Entries, Today, Calendar (with a custom mini month picker), and any tag you've used.
- **Voice dictation** — click the mic icon to dictate entries using Apple's on-device Speech framework.
- **Chat with your past** — an on-device AI companion (Apple Intelligence) you can ask about how you've been feeling.
- **Trends** — graphical analysis of your mood over time: line chart, mood balance, rhythm of the day, by tag, consistency heatmap.
- **In-app updates** — the app prompts you when a new version is available and installs it itself.
- **Local-only storage** — entries stay on your Mac as plain JSON. Nothing is uploaded.

## Install

1. Download `mood.zip` from the [latest release](https://github.com/madhupprasad/mood/releases/latest).
2. Unzip it and drag `mood.app` into `/Applications`.
3. **First launch**: right-click the app → **Open** → click **Open** in the dialog.

Since the app is unsigned, you'll see *"Apple could not verify…"* the first time. Open it once via **right-click → Open → Open**, or **System Settings → Privacy & Security → Open Anyway**. After that it launches normally.

Requires **macOS 26.5 (Tahoe)** or later.

When you first use the mic button, macOS will ask for Microphone and Speech Recognition permission.

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `Return` | Log current entry |
| `⌃⌥M`   | Toggle global quick-entry panel |
| `Esc`    | Close quick-entry panel without saving |
| `⌥Space` | Hold to dictate (push-to-talk) |

## Updates

The app checks for new versions in the background and shows an in-app prompt when one's available. Click **Install Update** and it handles the rest. You can also check on demand via **Mood → Check for Updates…** or the smiley menu bar icon.

## Privacy

Your entries live only on your Mac, as plain JSON, here:

```
~/Library/Application Support/com.tapasya.mood/mood-entries.json
```

The **Chat with your past** feature runs entirely on-device via Apple Intelligence — your journal text is never sent to a server.
