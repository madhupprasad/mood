# Security Policy

mood is a hobby app maintained by one person in their spare time. Security reports are taken seriously, but the resources to respond are modest. This document sets honest expectations.

## Supported Versions

Only the **latest released version** gets security fixes. Older versions are unsupported the moment a new release lands. If you're not on the latest, the answer to almost any issue is "please update."

| Version          | Supported                |
| ---------------- | ------------------------ |
| latest release   | ✅                        |
| anything older   | ❌  please update         |

In-app updates make this easy: open mood → **Mood menu → Check for Updates…** → Install.

## Threat model

mood's threat model is narrow on purpose:

| In scope                                              | Out of scope                                                                 |
| ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| A flaw that lets a remote/non-user read your entries  | An attacker who already has physical access to your unlocked Mac             |
| A flaw in the Sparkle update verification path        | macOS-level vulnerabilities (those belong to Apple)                          |
| An XSS or RCE in the landing page                     | Social engineering of a friend you sent the app to                           |
| Misuse of microphone or speech permissions            | Risks from running the unsigned `.app` (it's documented; choose to trust it) |

Your journal entries live as **plain JSON** at `~/Library/Application Support/com.tapasya.mood/`. If your Mac is compromised, your journal is compromised — that's a property of every local-only journal, not a bug. Encrypt your disk (FileVault), don't store sensitive secrets you wouldn't want a future you reading.

## Reporting a Vulnerability

If you've found a security issue, please **don't** open a public GitHub Issue. Two private channels:

1. **GitHub Security Advisory** (preferred) — go to <https://github.com/madhupprasad/mood/security/advisories/new>. Encrypted, only the maintainer sees it.
2. **Email** — `madhupprasad7@gmail.com`. Mention "mood security" in the subject so it isn't lost.

Please include:

- What the issue is, in one paragraph.
- How to reproduce it.
- The version of mood and macOS you're on.
- Any proof-of-concept code, screenshots, or logs.

You'll get a reply within **7 days** acknowledging the report. A fix (or an honest "I can't fix this") usually follows within **30 days** for high-severity issues, longer for low-severity ones. You'll be credited in the release notes unless you ask to stay anonymous.

## Update channel

mood checks <https://raw.githubusercontent.com/madhupprasad/mood/main/appcast.xml> for new versions via [Sparkle](https://sparkle-project.org). Each release zip is signed with the maintainer's **EdDSA private key**; the **public key** is embedded in every shipped build of mood. The Sparkle framework refuses to install an update whose signature doesn't verify against that embedded key.

If you'd rather not have the app contact GitHub at all: block the feed URL above in `/etc/hosts` or your firewall. Updates stop; everything else keeps working.

## What mood does **not** do

- Send your entries anywhere. There's no server.
- Run analytics or telemetry.
- Track you across sessions.
- Embed third-party SDKs other than [Sparkle](https://sparkle-project.org) (for in-app updates).
- Bundle ad networks, beacons, or marketing pixels.

If you find evidence to the contrary, that's a vulnerability — please report it via the channels above.

## Acknowledgements

No public reports yet. If you're the first, you'll be listed here.

— [Madhupprasad](https://github.com/madhupprasad)
