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

**Preferred — GitHub Actions** (builds from the literal commit, signs in CI, never touches your laptop):

```bash
git tag v1.3
git push --tags
```

That triggers `.github/workflows/release.yml`, which archives + exports + zips the `.app`, signs with `SPARKLE_PRIVATE_KEY` from repo secrets, creates the GitHub release, updates `appcast.xml`, and pushes. Friends with a previous version get an in-app update prompt automatically.

You can also trigger it manually from **GitHub → Actions → Release → Run workflow** and fill in version + notes.

**One-time setup for the Action:**

1. Export your Sparkle private key:
   ```bash
   ~/Library/Developer/Xcode/DerivedData/mood-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x /tmp/sparkle.key
   ```
2. Copy the contents of `/tmp/sparkle.key`.
3. Repo → **Settings → Secrets and variables → Actions → New repository secret**:
   - Name: `SPARKLE_PRIVATE_KEY`
   - Value: paste the key
4. Securely delete the local copy: `rm -P /tmp/sparkle.key`

**Local fallback** (your laptop, useful if Actions is down):

```bash
./scripts/release.sh 1.3 "Notes here"
```

Refuses to run unless `main` is clean and synced with `origin/main`, so the released binary is provably from the same commit on GitHub.

## Project structure

```
mood/
├── ContentView.swift    Main window: sidebar + composer + entry list
├── moodApp.swift        App entry, global hotkey, quick-entry panel, speech transcription
├── mood.entitlements    Sandbox + microphone + network entitlements
└── Assets.xcassets      App icon and asset catalog
```
