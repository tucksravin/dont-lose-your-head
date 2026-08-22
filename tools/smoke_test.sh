#!/usr/bin/env bash
# Smoke tests — prove the game still loads, lints, chains, and can be PLAYED
# end to end, headless. Run before claiming anything works, and before a PR:
#     tools/smoke_test.sh            # everything except the web export
#     tools/smoke_test.sh --web      # also runs tools/export_web.sh and checks the output
#     tools/smoke_test.sh load_all   # one suite by name (see tools/smoke/)
# Exit code: 0 = all green. Any FAIL, or any engine ERROR / Parse Error in the
# output, is red. "warn" lines never fail the run — read them anyway.
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [[ ! -x "$GODOT" ]]; then
  echo "Godot not found at $GODOT — set GODOT=/path/to/godot" >&2
  exit 2
fi

SUITES=(load_all day_lint day_chain day_sunset play_through)
WEB=0
ONLY=()
for arg in "$@"; do
  case "$arg" in
    --web) WEB=1 ;;
    *) ONLY+=("$arg") ;;
  esac
done
if [[ ${#ONLY[@]} -gt 0 ]]; then SUITES=("${ONLY[@]}"); fi

red=0
engine_errors() {   # stdin: godot output. prints matching lines; returns 0 if any
  grep -E '^(ERROR|SCRIPT ERROR|USER ERROR)|Parse Error|SCRIPT ERROR' | grep -v 'known:' | head -20
}

echo "== import"
out="$("$GODOT" --headless --path . --import 2>&1)"
errs="$(printf '%s\n' "$out" | engine_errors)"
if [[ -n "$errs" ]]; then echo "$errs"; echo "  FAIL  import printed engine errors"; red=1; else echo "  ok    import clean"; fi

for s in "${SUITES[@]}"; do
  echo "== $s"
  out="$("$GODOT" --headless --path . -s "tools/smoke/$s.gd" 2>&1)"
  code=$?
  printf '%s\n' "$out" | grep -E '^(  ok|  FAIL|  warn|-- |SMOKE)' || true
  errs="$(printf '%s\n' "$out" | engine_errors)"
  if [[ -n "$errs" ]]; then
    echo "  (engine errors during $s)"; echo "$errs" | sed 's/^/    /'
    code=1
  fi
  if ! printf '%s\n' "$out" | grep -q '^SMOKE PASS'; then code=1; fi
  if [[ $code -ne 0 ]]; then red=1; fi
done

if [[ $WEB -eq 1 ]]; then
  echo "== web export"
  if tools/export_web.sh >/tmp/smoke_web.log 2>&1 && [[ -f build/web/index.html && -f build/web/index.wasm ]]; then
    echo "  ok    build/web/index.html + index.wasm + web.zip ($(du -h build/web.zip | cut -f1))"
  else
    echo "  FAIL  web export — see /tmp/smoke_web.log"; tail -5 /tmp/smoke_web.log; red=1
  fi
fi

echo
if [[ $red -eq 0 ]]; then echo "SMOKE: ALL GREEN"; else echo "SMOKE: RED — see FAIL lines above"; fi
exit $red
