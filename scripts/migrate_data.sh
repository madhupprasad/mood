#!/usr/bin/env bash
# Migrates mood entries from the old sandboxed container to the new
# non-sandboxed Application Support location.
#
# Run this once after upgrading to mood v1.2 or later. Safe to re-run —
# won't overwrite if the new location already has entries.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/madhupprasad/mood/main/scripts/migrate_data.sh | bash
# or:
#   bash migrate_data.sh

set -e

OLD="$HOME/Library/Containers/com.tapasya.mood/Data/Library/Application Support/com.tapasya.mood"
NEW="$HOME/Library/Application Support/com.tapasya.mood"

if [[ ! -f "$OLD/mood-entries.json" ]]; then
    echo "✓ No old data found. Nothing to migrate."
    exit 0
fi

if [[ -f "$NEW/mood-entries.json" ]] && [[ $(stat -f%z "$NEW/mood-entries.json" 2>/dev/null || stat -c%s "$NEW/mood-entries.json") -gt 50 ]]; then
    echo "⚠ The new location already has entries. Won't overwrite."
    echo "  Old: $OLD/mood-entries.json"
    echo "  New: $NEW/mood-entries.json"
    echo "If you'd rather start from the old data, delete the new file and re-run."
    exit 0
fi

mkdir -p "$NEW"
cp "$OLD/mood-entries.json" "$NEW/mood-entries.json"
[[ -f "$OLD/mood-entries.backup.json" ]] && cp "$OLD/mood-entries.backup.json" "$NEW/mood-entries.backup.json"

COUNT=$(python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "$NEW/mood-entries.json" 2>/dev/null || echo "?")
echo "✓ Migrated $COUNT entries to the new location."
echo "  Now quit and relaunch mood — your entries should appear."
