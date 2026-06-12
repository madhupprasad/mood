# mood

> a tiny macOS journal. cream-colored, mostly text, hard to feel bad in.

[**Website**](https://madhupprasad.github.io/mood/) · [**Download for macOS**](https://github.com/madhupprasad/mood/releases/latest) · macOS 26.5 (Tahoe) or later

I wanted somewhere small to type into about how I was feeling. Not a tracker. Not a daily prompt. Not a calendar with a streak that yells at me. A blinking cursor and a Return key. So I built one. mood is what I made.

## Screens

### Main
<img width="1437" height="900" alt="mood main screen" src="https://github.com/user-attachments/assets/9bc9c757-22ad-406d-bbd6-2e2a84b8727c" />

### Spotlight-style quick entry, from anywhere
<img width="1440" height="747" alt="floating quick-entry panel" src="https://github.com/user-attachments/assets/cf8cca50-0cc0-4e4c-a2ce-c058b62130ec" />

### Five themes that recolor everything
<img width="220" height="126" alt="theme picker with five swatches" src="https://github.com/user-attachments/assets/428a1057-826a-4275-ab54-0ecfeb3aaaad" />

### Chat with your past — on-device AI
<img width="1440" height="388" alt="AI chat that reads your recent entries" src="https://github.com/user-attachments/assets/ebc0a75a-28c4-4a3e-a9ad-85209909e84d" />

### Trends — read it like the weather
<img width="1440" height="900" alt="trends dashboard with line chart and stat tiles" src="https://github.com/user-attachments/assets/01b8351a-07fb-4dc4-9ec0-82023cc79d03" />

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
3. **First launch**: right-click the app → **Open** → click **Open** in the dialog.

macOS warns the first time because mood isn't signed (I haven't sent Apple their $99/yr yet). One-time right-click → Open and you're set; every launch after is normal. macOS will also ask for Microphone + Speech Recognition the first time you use dictation.

## Keyboard

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

Sparkle. The app checks GitHub for new releases when you launch it. If there's one, you get a small in-app dialog: "A new version is available." Install or skip. That's the whole loop. No background telemetry, no analytics. The feed it checks is [`appcast.xml`](https://raw.githubusercontent.com/madhupprasad/mood/main/appcast.xml) — block it if you'd rather not check.

---

Built with care by [Madhupprasad](https://github.com/madhupprasad), mostly at night. Issues, PRs, and "hey I added a theme" forks all welcome.
