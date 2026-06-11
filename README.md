# mood

## A minimal macOS journaling app for tracking how you feel throughout the day. Built with SwiftUI.

## Main screen
<img width="1437" height="900" alt="Screenshot 2026-06-12 at 1 24 14 AM" src="https://github.com/user-attachments/assets/9bc9c757-22ad-406d-bbd6-2e2a84b8727c" />

## Spotlight like pop-up - make an entry from anywhere.
<img width="1440" height="747" alt="Screenshot 2026-06-12 at 1 26 22 AM" src="https://github.com/user-attachments/assets/cf8cca50-0cc0-4e4c-a2ce-c058b62130ec" />

## Themes
<img width="220" height="126" alt="Screenshot 2026-06-12 at 1 25 08 AM" src="https://github.com/user-attachments/assets/428a1057-826a-4275-ab54-0ecfeb3aaaad" />

## Talk with your past self - with AI
<img width="1440" height="388" alt="Screenshot 2026-06-12 at 1 24 58 AM" src="https://github.com/user-attachments/assets/ebc0a75a-28c4-4a3e-a9ad-85209909e84d" />

## TRENDS - Graphical analysis on your mood
<img width="1440" height="900" alt="Screenshot 2026-06-12 at 1 24 24 AM" src="https://github.com/user-attachments/assets/01b8351a-07fb-4dc4-9ec0-82023cc79d03" />


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

Since the app is unsigned, friends will see *"Apple could not verify…"* the first time. Open it once via **right-click → Open → Open**, or **System Settings → Privacy & Security → Open Anyway**. After that it launches normally. Annoying but free.

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

## Auto-updates (Sparkle)

The app uses [Sparkle](https://sparkle-project.org) so users get update prompts inside the app — no more manual re-downloads. There's a "Check for Updates…" item in the **Mood** menu and the menu bar dropdown; Sparkle also checks silently once a day.

### One-time setup

1. **Add the Sparkle Swift Package**
   In Xcode → **File → Add Package Dependencies…** → paste `https://github.com/sparkle-project/Sparkle` → choose the latest 2.x release → add to the `mood` target.

2. **Generate update-signing keys** (one time, per developer)
   From the cloned Sparkle repo or your local DerivedData, run:
   ```bash
   ./Sparkle/bin/generate_keys
   ```
   - Save the **private key** somewhere safe — it lives in your Keychain by default and is never committed to the repo.
   - Copy the printed **public key** (`SUPublicEDKey`) for the next step.

3. **Add Info.plist entries**
   In Xcode → select the project → **mood** target → **Info** tab → "Custom macOS Application Target Properties" → click `+` and add:
   - `SUFeedURL` (String) → `https://raw.githubusercontent.com/madhupprasad/mood/main/appcast.xml`
   - `SUPublicEDKey` (String) → the public key from step 2.

4. **Set the `SIGN_UPDATE` env var** so the release script can find Sparkle's signing tool:
   ```bash
   export SIGN_UPDATE="$HOME/Library/Developer/Xcode/DerivedData/mood-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
   ```
   (Or grab it from the Sparkle release archive and put it on `$PATH`.)

5. **Push the initial `appcast.xml`** (it's already in the repo) so users' apps can fetch it.

### Cutting a release

```bash
./scripts/release.sh 1.3 "Notes here"
```

The script refuses to run unless `main` is clean and synced with `origin/main`, so the released binary is built from the same commit on GitHub. It archives + exports + zips the `.app`, signs with your Sparkle key, creates the GitHub release, inserts a new `<item>` at the top of `appcast.xml`, commits and pushes.

Friends with a previous version get an in-app update prompt automatically next time they launch (or instantly via **Check for Updates…**).

## Project structure

```
mood/
├── ContentView.swift    Main window: sidebar + composer + entry list
├── moodApp.swift        App entry, global hotkey, quick-entry panel, speech transcription
├── mood.entitlements    Sandbox + microphone + network entitlements
└── Assets.xcassets      App icon and asset catalog
```
