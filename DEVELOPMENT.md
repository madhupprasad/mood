# Development

Internal docs for building, releasing, and maintaining mood.

## Build from source

- macOS 26.5 or later
- Xcode 16+ (or whatever ships with Tahoe)

1. Clone the repo.
2. Open `mood.xcodeproj` in Xcode.
3. Select the `mood` scheme and your Mac as the run destination.
4. ⌘R to build and run.

## Project structure

```
mood/mood/
├── moodApp.swift          App entry, hotkey wiring, menu bar extra
├── ContentView.swift      Root window: sidebar + composer + main pane
├── Models.swift           MoodEntry + MoodStore (JSON persistence)
├── Theme.swift            Theme struct + ThemeCatalog + environment key
├── Sidebar.swift          Sidebar + tag list + theme picker + settings popover
├── MiniCalendar.swift     Custom calendar grid for the Calendar tab
├── Composer.swift         Compose bar (text + mood chips + mic + log button)
├── Entries.swift          EntriesList + EntryRow + tag helpers
├── TrendsModel.swift      MoodLevel + TrendsRange + TrendsData computation
├── Trends.swift           Trends screen (stat tiles + cards + heatmap)
├── Chat.swift             Chat with your past (FoundationModels)
├── Speech.swift           SpeechTranscriber (on-device dictation)
├── QuickEntryPanel.swift  HotKeyManager + FloatingPanel + QuickEntryView
├── Info.plist             SUFeedURL + SUPublicEDKey
└── mood.entitlements      (currently unused; Xcode auto-generates entitlements)

appcast.xml                Sparkle update feed
scripts/release.sh         Build + sign + publish + appcast + push (local)
scripts/migrate_data.sh    One-shot data migration for friends upgrading from
                           the sandboxed (pre-v1.2) build
scripts/ExportOptions.plist  xcodebuild -exportArchive options
```

## Auto-updates (Sparkle)

The app uses [Sparkle](https://sparkle-project.org) so users get update prompts inside the app — no manual re-downloads. There's a "Check for Updates…" item in the **Mood** menu and the menu bar dropdown; Sparkle also checks silently once a day.

### One-time setup

1. **Add the Sparkle Swift Package**
   In Xcode → **File → Add Package Dependencies…** → paste `https://github.com/sparkle-project/Sparkle` → choose the latest 2.x release → add to the `mood` target.

2. **Generate update-signing keys** (one time, per developer)
   From your local DerivedData:
   ```bash
   ~/Library/Developer/Xcode/DerivedData/mood-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
   ```
   - The **private key** lives in your Keychain — never committed.
   - Copy the printed **public key** (`SUPublicEDKey`) for the next step.

3. **Add Info.plist entries**
   In Xcode → select the project → **mood** target → **Info** tab → "Custom macOS Application Target Properties" → click `+` and add:
   - `SUFeedURL` (String) → `https://raw.githubusercontent.com/madhupprasad/mood/main/appcast.xml`
   - `SUPublicEDKey` (String) → the public key from step 2.

4. **Set the `SIGN_UPDATE` env var** so the release script can find Sparkle's signing tool (add to `~/.zshrc`):
   ```bash
   export SIGN_UPDATE="$HOME/Library/Developer/Xcode/DerivedData/mood-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
   ```
   The release script auto-resolves the glob and falls back to searching DerivedData if the path is missing.

5. **App Sandbox is disabled.** Sparkle 2 needs significant extra plumbing (app groups, multiple XPC entitlements, plist keys) to work inside a sandbox. We removed the sandbox capability via Xcode → Signing & Capabilities. Without sandbox, the Sparkle installer XPC service can authorize and replace the running app cleanly.

### Cutting a release

```bash
./scripts/release.sh 1.3 "Release notes here"
```

The script refuses to run unless:
- The working tree is clean (no uncommitted edits).
- You're on `main`.
- Local `main` matches `origin/main` byte-for-byte (no unpushed commits, not behind).

That guarantee means the released binary is provably built from the same commit that's on GitHub.

What the script does, in order:
1. archive + export the `.app` in Release configuration
2. zip it with `ditto`
3. sign the zip with your Sparkle Keychain private key
4. `gh release create` with the zip attached
5. insert a new `<item>` at the top of `appcast.xml` (preserves indentation)
6. commit `appcast.xml` and `git push`

Friends running a previous version get the in-app prompt within 24h of next launch (or instantly via **Check for Updates…**).

### Public key history

Don't change `SUPublicEDKey` in `Info.plist` casually. If you rotate the key, existing users can't validate signatures from new releases — they're locked out of auto-update and have to manually re-download the next version once.

Current key: `m34xAi5Pv4GGM2Y+beG2zPCQU3CY4fgeyvG8NpPGwqk=`

## Data migration script (for users)

Pre-v1.2 builds were sandboxed; v1.2+ are not. The data location changed:

- Pre-v1.2: `~/Library/Containers/com.tapasya.mood/Data/Library/Application Support/com.tapasya.mood/`
- v1.2+:    `~/Library/Application Support/com.tapasya.mood/`

`scripts/migrate_data.sh` copies the data over safely (refuses to overwrite if the new location already has data). Share with friends as a one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/madhupprasad/mood/main/scripts/migrate_data.sh | bash
```

## Backup safety net

`MoodStore.save()` writes `mood-entries.backup.json` next to `mood-entries.json` before each save. If the JSON ever fails to decode on load, the unreadable file is moved aside with an `.unreadable.<timestamp>` suffix instead of being overwritten on the next save — so disk corruption never silently wipes data.

## Future work

- **GitHub Actions release workflow** — already designed; blocked on GitHub `macos-latest` getting an Xcode with the macOS 26 SDK. Once available, we can ship via tag push instead of laptop builds. Until then, `release.sh` is the only path.
- **Lower deployment target to macOS 15** to widen the friend pool — would require gating `Chat.swift` (FoundationModels is macOS 26-only) behind `#if canImport(FoundationModels)`.
