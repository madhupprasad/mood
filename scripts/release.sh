#!/usr/bin/env bash
# Build, sign, publish, and announce a new mood release in one shot.
#
# Usage:
#   ./scripts/release.sh <version> [release notes]
#
# Example:
#   ./scripts/release.sh 1.3 "Bug fixes"
#
# What it does:
#   1. archive + export the .app in Release configuration
#   2. zip it
#   3. sign the zip with the Sparkle private key (from Keychain)
#   4. create a GitHub release with the zip attached
#   5. insert a new <item> at the top of appcast.xml
#   6. commit appcast.xml and push
#
# Required tools on PATH:
#   xcodebuild, ditto, gh (GitHub CLI), python3
# Required env var:
#   SIGN_UPDATE  → path to Sparkle's sign_update binary
#                  (e.g. $HOME/.../SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update)

set -euo pipefail

# -------- Args --------
if [[ $# -lt 1 ]]; then
    echo "usage: $0 <version> [notes]"
    exit 1
fi

VERSION="$1"
NOTES="${2:-Release v$VERSION}"
SIGN_UPDATE_TOOL="${SIGN_UPDATE:-sign_update}"

# Pull these from constants you can tweak if needed
REPO="madhupprasad/mood"
MIN_MACOS="26.5"
APPCAST_PATH="appcast.xml"

# Use a homebrew gh if not on PATH
export PATH="/opt/homebrew/bin:$PATH"

# -------- Sanity checks --------
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -n $(git status --porcelain | grep -v '^\?\?') ]]; then
    echo "✗ Working tree has uncommitted changes. Commit or stash first."
    git status --porcelain
    exit 1
fi

if grep -q "<title>Version ${VERSION}</title>" "$APPCAST_PATH" 2>/dev/null; then
    echo "✗ Version ${VERSION} already exists in $APPCAST_PATH"
    exit 1
fi

if ! command -v "$SIGN_UPDATE_TOOL" >/dev/null 2>&1; then
    echo "✗ Cannot find sign_update at '$SIGN_UPDATE_TOOL'"
    echo "  Set SIGN_UPDATE env var, e.g.:"
    echo "    export SIGN_UPDATE=\"\$HOME/Library/Developer/Xcode/DerivedData/mood-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update\""
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "✗ Install the GitHub CLI: brew install gh"
    exit 1
fi

# -------- Build --------
WORK="$(mktemp -d)"
ARCHIVE_PATH="$WORK/mood.xcarchive"
EXPORT_PATH="$WORK/export"
ZIP_NAME="mood-${VERSION}.zip"
ZIP_PATH="$WORK/$ZIP_NAME"

echo "▸ Archiving v${VERSION}…"
xcodebuild archive \
    -project mood.xcodeproj \
    -scheme mood \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$ARCHIVE_PATH" \
    MARKETING_VERSION="$VERSION" \
    >/dev/null

echo "▸ Exporting .app…"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist scripts/ExportOptions.plist \
    >/dev/null

APP_PATH="$EXPORT_PATH/mood.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "✗ Export failed — no .app at $APP_PATH"
    exit 1
fi

echo "▸ Zipping…"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "▸ Signing update…"
SIG_LINE=$("$SIGN_UPDATE_TOOL" "$ZIP_PATH")

# -------- Release --------
echo "▸ Creating GitHub release v${VERSION}…"
gh release create "v$VERSION" "$ZIP_PATH" \
    --repo "$REPO" \
    --title "v$VERSION" \
    --notes "$NOTES"

# -------- Patch appcast.xml --------
PUBDATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ZIP_NAME}"

NEW_ITEM_FILE="$(mktemp)"
cat > "$NEW_ITEM_FILE" <<EOF
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUBDATE}</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>${MIN_MACOS}</sparkle:minimumSystemVersion>
      <description><![CDATA[${NOTES}]]></description>
      <enclosure url="${DOWNLOAD_URL}" type="application/octet-stream" ${SIG_LINE}/>
    </item>
EOF

echo "▸ Updating ${APPCAST_PATH}…"
python3 - "$APPCAST_PATH" "$NEW_ITEM_FILE" <<'PYEOF'
import sys

appcast_path, new_item_path = sys.argv[1], sys.argv[2]
with open(appcast_path) as f:
    content = f.read()
with open(new_item_path) as f:
    new_item = f.read().rstrip()

# Insert before the first existing <item>; if none, before </channel>
anchor = content.find("<item>")
if anchor == -1:
    anchor = content.find("</channel>")
    if anchor == -1:
        raise SystemExit("appcast.xml has no <item> or </channel> anchor")

# Walk back to the start of the anchor's line for matching indent
line_start = content.rfind("\n", 0, anchor) + 1
indent = content[line_start:anchor]

# Re-indent every line of the new item to match
indented_new = "\n".join(indent + line.lstrip() if line.strip() else "" for line in new_item.splitlines())

content = content[:line_start] + indented_new + "\n" + content[line_start:]

with open(appcast_path, "w") as f:
    f.write(content)
PYEOF

rm -f "$NEW_ITEM_FILE"

# -------- Commit + push --------
echo "▸ Committing and pushing…"
git add "$APPCAST_PATH"
git commit -m "appcast: v${VERSION}"
git push

echo ""
echo "✓ Released v${VERSION}"
echo "  GitHub: https://github.com/${REPO}/releases/tag/v${VERSION}"
echo "  Friends will be prompted next time they launch (or click Check for Updates…)."
