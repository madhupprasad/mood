# mood

> a tiny journal. cream-colored, mostly text, hard to feel bad in. macOS today — iOS and Android on the way.

[**Website**](https://madhupprasad.github.io/mood/) · [**Download for macOS**](https://github.com/madhupprasad/mood/releases/latest) · macOS 26.5 (Tahoe) or later

I wanted somewhere small to type into about how I was feeling. Not a tracker. Not a daily prompt. Not a calendar with a streak that yells at me. A blinking cursor and a Return key. So I built one. mood is what I made.

## Platforms

mood started on macOS and is growing into your pocket. The macOS app is the released one; the mobile apps are in development and build from source today. All three share the same idea and the same plain-JSON storage, but each fits its platform.

| Platform | Status | How to get it |
|---|---|---|
| **macOS** 26.5+ | Released | [Download](https://github.com/madhupprasad/mood/releases/latest) |
| **iOS** 26.5+ | In development | Build from source (Xcode) |
| **Android** 8.0+ (API 26) | In development | Build from source (Android Studio) |

- **macOS** has the full kit — the `⌃⌥M` global quick-entry bar, menu-bar extra, and Sparkle in-app updates.
- **iOS** keeps the writing, mood, trends, voice, and on-device Chat, in a Daylio-style mood-first composer. No global hotkey (the OS has none); updates come from the App Store.
- **Android** (Kotlin + Jetpack Compose) has the mood-first composer, entries, and trends, with voice and tags landing next. **Chat is omitted for now** — Android's on-device LLM story isn't there yet, and mood won't ship your journal to a cloud model.

## What it does

- **Just types.** Write something, hit Return. Date and time get attached. That's an entry. No required fields, no scoring.
- **`⌃⌥M` from anywhere.** Spotlight-style bar pops up. Type, hit Return, it disappears. The thought is logged before you've broken stride.
- **`#hashtags` are filters.** Mention `#work` somewhere in an entry → the sidebar grows a `#work` row that filters to those entries. No tag UI. No fuss.
- **Trends, gently.** Line chart of mood over time. Rhythm of the day. Consistency heatmap. Read like the weather — no diagnoses, no "you're trending sad."
- **Voice in.** Click the mic, or hold `⌥Space` and talk. Apple's on-device Speech framework. Nothing leaves your Mac.
- **Chat with your past.** Ask the on-device LLM things like *"what's been bothering me at work?"* It reads your recent entries and answers. Apple Intelligence, all on-device.
- **In-app updates.** New version? You get a prompt next time you launch. Click Install. Done.
- **A vent pad.** A small "burn it" sheet next to the composer for things you don't want to keep. The words rise off the screen as flames and disappear. Nothing is saved.

## What it isn't

- A **streak app**. No flame counter. No "you broke your streak" guilt.
- A **mood-as-a-number app**. Rate entries 1–5 if it helps you; ignore it if it doesn't.
- A **vault**. Your entries live as plaintext JSON. Encrypt your Mac; don't store sensitive secrets here.
- A **note-taking app**. Use Notes or Bear for plans. mood is for the moment.

## Install

1. Download `mood.zip` from the [latest release](https://github.com/madhupprasad/mood/releases/latest).
2. Unzip, drag `mood.app` into `/Applications`.
3. **Double-click `mood.app`.** macOS will block it with *"Apple could not verify mood is free of malware that may harm your Mac"* — click **Done** to dismiss.
4. Open **System Settings → Privacy & Security** → scroll to the **Security** section.
5. You'll see a line about *"mood was blocked to protect your Mac."* Click **Open Anyway**.
6. A new dialog asks you to confirm; enter your Mac password if prompted, then click **Open Anyway** again.
7. mood launches. From now on, double-clicking the app just opens it normally — the warning is one-time.

macOS does this dance because mood isn't signed with an Apple Developer ID (I haven't sent Apple their $99/yr). Apple removed the older right-click → Open shortcut in macOS Sequoia, so the System Settings route is the only path. macOS will also ask for Microphone + Speech Recognition the first time you use dictation.

## Keyboard (macOS)

| Shortcut | What it does |
|---|---|
| `Return` | Log the entry |
| `⌃⌥M`   | Toggle the floating quick-entry panel from anywhere on your Mac |
| `Esc`    | Close the quick-entry panel without saving |
| `⌥Space` | Hold to dictate (push-to-talk) |

## Privacy

Everything is local. Your entries live as plain JSON at:

```
~/Library/Application Support/com.tapasya.mood/
```

You can read them with `cat`. They don't sync to a server because there's no server. The **Chat** feature reads your recent entries and replies via Apple Intelligence — running on your Mac, not in the cloud. The model never sees a network.

Want to stop? Your data doesn't disappear with the app — it just sits where it is. To wipe: in-app **Settings → Clear all entries**, or `rm -rf` the folder above.

## Updates

Sparkle. The app checks GitHub for new releases when you launch it. If there's one, you get a small in-app dialog: "A new version is available." Install or skip. That's the whole loop. No background telemetry, no analytics. The feed it checks is [`appcast.xml`](https://raw.githubusercontent.com/madhupprasad/mood/main/appcast.xml) — block it if you'd rather not check. (iOS and Android get updates through their own app stores; no Sparkle there.)

## Building from source

- **Apple (macOS + iOS):** open `mood.xcodeproj` in Xcode. It's a single multiplatform target — pick a Mac or an iPhone/Simulator destination and run. Building for a physical iPhone needs an Apple Developer account for signing.
- **Android:** open the `android/` folder in Android Studio, let it Gradle-sync, create an emulator in **Device Manager**, then **Run**. Min SDK 26 (Android 8.0); the project uses Jetpack Compose and has no external charting dependencies.

---

Built with care by [Madhupprasad](https://github.com/madhupprasad), mostly at night. Issues, PRs, and "hey I added a theme" forks all welcome.
