#!/usr/bin/env bash
# Export a release Web build and zip it for itch.io.
# Usage: tools/export_web.sh            (uses /Applications/Godot.app)
#        GODOT=/path/to/godot tools/export_web.sh
set -euo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/web"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot not found at $GODOT — set GODOT=/path/to/godot" >&2
  exit 1
fi

rm -rf "$OUT" "$ROOT/build/web.zip"
mkdir -p "$OUT"
# .gdignore makes Godot skip build/ entirely — otherwise the previous build gets imported and packed into the next one.
: > "$ROOT/build/.gdignore"

# Headless import first so a fresh clone exports cleanly.
"$GODOT" --headless --path "$ROOT" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"

( cd "$OUT" && zip -qr ../web.zip . -x ".DS_Store" )
echo
echo "Built: $ROOT/build/web.zip  ← upload this to itch.io (kind: HTML)"
echo "Local test: python3 -m http.server -d \"$OUT\" 8000   then open http://localhost:8000"
