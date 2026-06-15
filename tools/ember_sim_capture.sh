#!/usr/bin/env bash
# ember_sim_capture.sh — boot an iPhone simulator, run Ember's standalone entry
# (lib/ember/main_ember.dart), optionally with the EMBER_TOUR self-drive, then
# burst-screenshot the sim to an output dir and quit. Reusable across every
# review-loop stage. simctl can screenshot but NOT tap, so reliable multi-state
# capture relies on the app self-driving (EMBER_TOUR) while we snap frames.
#
# Usage: tools/ember_sim_capture.sh <out_dir> [tour=1|0] [seconds=36]
set -uo pipefail

ROOT="/Users/Sahu/Desktop/Work/GlutaFam"
OUT="${1:?usage: ember_sim_capture.sh <out_dir> [tour] [seconds]}"
TOUR="${2:-1}"
SECS="${3:-36}"
mkdir -p "$OUT"
cd "$ROOT" || exit 3
LOG="$OUT/run.log"

# --- pick + boot an iPhone simulator -----------------------------------------
UDID=$(xcrun simctl list devices available | grep -m1 -E "iPhone 1[5-7] Pro \(" | grep -oiE "[0-9A-F-]{36}" | head -1)
[ -z "${UDID:-}" ] && UDID=$(xcrun simctl list devices available | grep -m1 -E "iPhone" | grep -oiE "[0-9A-F-]{36}" | head -1)
if [ -z "${UDID:-}" ]; then echo "FATAL: no iPhone simulator available"; exit 4; fi
echo "UDID=$UDID"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
open -a Simulator >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" >/dev/null 2>&1 || true

# --- launch the app (incremental build; caches are warm) ----------------------
DEFINE=""; [ "$TOUR" = "1" ] && DEFINE="--dart-define=EMBER_TOUR=1"
echo "Launching main_ember (tour=$TOUR) on $UDID ..."
( fvm flutter run -t lib/ember/main_ember.dart $DEFINE -d "$UDID" --debug >"$LOG" 2>&1 ) &
RUNPID=$!

# --- wait until the app is up -------------------------------------------------
UP=0
for _ in $(seq 1 240); do
  if grep -qiE "Dart VM Service|Syncing files|Flutter run key|EMBER_TOUR_STATE|Observatory" "$LOG"; then UP=1; break; fi
  if ! kill -0 "$RUNPID" 2>/dev/null; then break; fi   # process died
  sleep 1
done
if [ "$UP" != "1" ]; then
  echo "APP_RAN=0"; echo "---- run.log tail ----"; tail -40 "$LOG"
  kill "$RUNPID" 2>/dev/null || true
  exit 5
fi
sleep 5  # let first frame + initial tour state settle

# --- burst screenshots --------------------------------------------------------
N=$(( SECS / 2 )); [ "$N" -lt 1 ] && N=1
for i in $(seq 1 "$N"); do
  xcrun simctl io "$UDID" screenshot "$OUT/shot_$(printf '%02d' "$i").png" >/dev/null 2>&1 || true
  sleep 2
done
grep "EMBER_TOUR_STATE" "$LOG" > "$OUT/tour_markers.txt" 2>/dev/null || true

# --- tear down ----------------------------------------------------------------
BUNDLE=$(defaults read "$ROOT/build/ios/iphonesimulator/Runner.app/Info" CFBundleIdentifier 2>/dev/null || echo "")
[ -n "$BUNDLE" ] && xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
kill "$RUNPID" 2>/dev/null || true
pkill -f "flutter.*main_ember.dart" 2>/dev/null || true

SHOTS=$(ls "$OUT"/shot_*.png 2>/dev/null | wc -l | tr -d ' ')
echo "APP_RAN=1"
echo "SHOTS=$SHOTS in $OUT"
echo "TOUR_MARKERS:"; cat "$OUT/tour_markers.txt" 2>/dev/null || true
echo "---- run.log tail ----"; tail -8 "$LOG"
