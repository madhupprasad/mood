#!/usr/bin/env bash
# Build, sign, and publish a new mood release.
#
# Usage:
#   ./scripts/release.sh <version> [release notes]
#
# Example:
#   ./scripts/release.sh 0.2 "Adds Chat tab; misc fixes."
#
# Required tools on PATH:
#   xcodebuild, ditto, gh, plus Sparkle's `sign_update` binary.
#
# Set SIGN_UPDATE to the path of Sparkle's sign_update tool, e.g.
#   export SIGN_UPDATE="$HOME/Sparkle/bin/sign_update"
#
# The script:
#   1. archives the app in Release configuration with the new version
#   2. exports the .app to a temp dir
#   3. zips it
#   4. signs the zip with the Sparkle private key
#   5. creates a GitHub release with the zip attached
#   6. prints the <item> block to paste into appcast.xml

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <version> [notes]"
    exit 1
fi

VERSION="$1"
NOTES="${2:-Release v$VERSION}"
SIGN_UPDATE_TOOL="${SIGN_UPDATE:-sign_update}"

if ! command -v "$SIGN_UPDATE_TOOL" >/dev/null 2>&1; then
    echo "Cannot find sign_update at '$SIGN_UPDATE_TOOL'."
    echo "Set SIGN_UPDATE to its full path, e.g.:"
    echo "  export SIGN_UPDATE=\"\$HOME/Sparkle/bin/sign_update\""
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "Install the GitHub CLI: brew install gh"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK="$(mktemp -d)"
ARCHIVE_PATH="$WORK/mood.xcarchive"
EXPORT_PATH="$WORK/export"
ZIP_NAME="mood-${VERSION}.zip"
ZIP_PATH="$WORK/$ZIP_NAME"

echo "▸ Archiving v$VERSION…"
xcodebuild archive \
    -project mood.xcodeproj \
    -scheme mood \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    MARKETING_VERSION="$VERSION" \
    | tail -5

echo "▸ Exporting .app…"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist scripts/ExportOptions.plist \
    | tail -5

APP_PATH="$EXPORT_PATH/mood.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "Export failed — no .app at $APP_PATH"
    exit 1
fi

echo "▸ Zipping…"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "▸ Signing update…"
SIG_LINE=$("$SIGN_UPDATE_TOOL" "$ZIP_PATH")

echo "▸ Creating GitHub release v$VERSION…"
gh release create "v$VERSION" "$ZIP_PATH" --title "v$VERSION" --notes "$NOTES"

PUBDATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
ZIP_SIZE=$(stat -f%z "$ZIP_PATH")
DOWNLOAD_URL="https://github.com/madhupprasad/mood/releases/download/v${VERSION}/${ZIP_NAME}"

cat <<EOF

==========================================================
Paste this <item> block at the TOP of appcast.xml,
then commit + push:
==========================================================

<item>
    <title>Version $VERSION</title>
    <pubDate>$PUBDATE</pubDate>
    <sparkle:version>$VERSION</sparkle:version>
    <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
    <sparkle:minimumSystemVersion>26.5</sparkle:minimumSystemVersion>
    <description><![CDATA[$NOTES]]></description>
    <enclosure
        url="$DOWNLOAD_URL"
        length="$ZIP_SIZE"
        type="application/octet-stream"
        $SIG_LINE/>
</item>

==========================================================
EOF
