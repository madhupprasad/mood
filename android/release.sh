#!/usr/bin/env bash
# Bump the version and build a signed release AAB for Google Play.
#
# Usage:
#   ./release.sh            # bump versionCode only, keep versionName
#   ./release.sh 1.1        # bump versionCode AND set versionName to 1.1
#
# What it does:
#   1. increments versionCode in app/build.gradle.kts (Play requires it to rise)
#   2. optionally sets versionName
#   3. builds a signed release .aab with Android Studio's bundled JDK
#   4. copies it to ~/Desktop/mood-<versionName>.aab and prints the path
#
# It does NOT upload — that's the manual step in Play Console:
#   Testing → Internal testing → Create new release → upload the .aab → roll out.

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
GRADLE_FILE="app/build.gradle.kts"

# -------- Sanity --------
if [[ ! -f keystore.properties ]]; then
    echo "✗ keystore.properties not found — the AAB would be unsigned and Play would reject it."
    echo "  Copy keystore.properties.template → keystore.properties and fill in your passwords."
    exit 1
fi

# Prefer Android Studio's bundled JDK (system java is often too old for AGP).
if [[ -z "${JAVA_HOME:-}" || ! -x "${JAVA_HOME:-}/bin/java" ]]; then
    STUDIO_JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    if [[ -x "$STUDIO_JBR/bin/java" ]]; then
        export JAVA_HOME="$STUDIO_JBR"
    else
        echo "✗ No usable JDK. Set JAVA_HOME or install Android Studio."
        exit 1
    fi
fi

# -------- Bump versionCode --------
CURRENT=$(perl -ne 'if (/versionCode\s*=\s*(\d+)/){print $1; exit}' "$GRADLE_FILE")
if [[ -z "$CURRENT" ]]; then
    echo "✗ Couldn't find versionCode in $GRADLE_FILE"
    exit 1
fi
NEXT=$((CURRENT + 1))
perl -i -pe 's/versionCode\s*=\s*\d+/versionCode = '"$NEXT"'/' "$GRADLE_FILE"
echo "▸ versionCode $CURRENT → $NEXT"

# -------- Optional versionName --------
if [[ $# -ge 1 ]]; then
    VNAME="$1"
    perl -i -pe 's/versionName\s*=\s*"[^"]*"/versionName = "'"$VNAME"'"/' "$GRADLE_FILE"
    echo "▸ versionName → $VNAME"
else
    VNAME=$(perl -ne 'if (/versionName\s*=\s*"([^"]*)"/){print $1; exit}' "$GRADLE_FILE")
fi

# -------- Build --------
echo "▸ Building signed release AAB (JAVA_HOME=$JAVA_HOME)…"
./gradlew bundleRelease --no-daemon

AAB="app/build/outputs/bundle/release/app-release.aab"
if [[ ! -f "$AAB" ]]; then
    echo "✗ Build did not produce $AAB"
    exit 1
fi

OUT="$HOME/Desktop/mood-${VNAME}.aab"
cp "$AAB" "$OUT"

echo ""
echo "✓ Built mood ${VNAME}  (versionCode ${NEXT})"
echo "  AAB: $OUT"
echo "  Next: Play Console → Internal testing → Create new release → upload that .aab → roll out."
echo "  Your phone auto-updates within minutes (or force it in Play Store → Manage apps & device)."
