#!/usr/bin/env bash
# Generate per-activity asset manifests.
#
# For each activity folder under `assets/images/<activity_id>/`, this script
# writes a JSON file at `assets/manifests/<activity_id>.json` containing the
# list of file paths *relative to the activity folder*. The runtime
# (`precacheActivityImages` in lib/utils/s3_assets.dart) reads that list,
# resolves each path to its S3 URL, and warms `precacheImage` for them all
# before the activity screen mounts.
#
# The manifest also carries an `audio` array listing every sound file under
# `assets/sounds/<activity_id>/` (relative to that folder). The runtime
# (`precacheActivityAudio` in lib/utils/s3_audio.dart) downloads those from
# `activities/<id>/audio/<path>` on S3 into the app cache dir so voice/SFX
# play with file-local latency.
#
# Why ship a manifest rather than listing assets at runtime:
#   • `rootBundle.loadString('AssetManifest.json')` only knows about files
#     actually declared in pubspec.yaml — once we stop bundling the
#     activity images (so the APK stays small), the AssetManifest no
#     longer contains them.
#   • Hand-written precache lists drift the moment anyone adds a sprite.
#   • Generating the list at build time is precise, version-controlled,
#     and re-runnable in 1 second.
#
# Usage:
#   tools/generate_activity_manifests.sh             # all 10 activities
#   tools/generate_activity_manifests.sh <id> [...]  # only the listed ones
#
# The manifests are committed to git so CI / Flutter builds don't need to
# run this. Re-run any time someone adds/removes/renames an image.

set -euo pipefail

SOURCE_ROOT="assets/images"
SOUNDS_ROOT="assets/sounds"
DEST_DIR="assets/manifests"

ALL_ACTIVITIES=(
  build_satellite
  choose_right_satellite
  code_satellite
  earth_detective
  how_much_can_you_see
  orbit_launcher
  power_balance
  restore_earth
  satellite_doctor
  signal_rescue
  save_coastal_city
)

if [[ $# -gt 0 ]]; then
  ACTIVITIES=("$@")
else
  ACTIVITIES=("${ALL_ACTIVITIES[@]}")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p "$DEST_DIR"

echo "Generating manifests for ${#ACTIVITIES[@]} activity folder(s) → $DEST_DIR/"
echo

for activity in "${ACTIVITIES[@]}"; do
  src="$SOURCE_ROOT/$activity"
  dest="$DEST_DIR/$activity.json"

  if [[ ! -d "$src" ]]; then
    echo "  ⚠️  $activity — local folder $src not found, skipping"
    continue
  fi

  # List every image-like file, sorted, relative to the activity folder.
  # Excludes the asset_meta.json metadata + .DS_Store. Sort order matters
  # so the diff is stable across machines.
  files=$(cd "$src" && find . -type f \
            \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
            ! -name ".DS_Store" \
          | sed 's|^\./||' \
          | LC_ALL=C sort)

  count=$(echo "$files" | grep -c . || true)

  # Same listing for audio files under assets/sounds/<id>/ (may be absent).
  sounds_src="$SOUNDS_ROOT/$activity"
  audio_files=""
  if [[ -d "$sounds_src" ]]; then
    audio_files=$(cd "$sounds_src" && find . -type f \
            \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) \
            ! -name ".DS_Store" \
          | sed 's|^\./||' \
          | LC_ALL=C sort)
  fi
  audio_count=$(echo "$audio_files" | grep -c . || true)

  # Hand-build the JSON so we don't depend on jq. Paths are snake_case and
  # have no quotes/backslashes — JSON-safe as-is.
  {
    echo "{"
    echo "  \"activityId\": \"$activity\","
    echo "  \"count\": $count,"
    echo "  \"paths\": ["
    first=1
    while IFS= read -r p; do
      [[ -z "$p" ]] && continue
      if [[ $first -eq 1 ]]; then
        printf '    "%s"' "$p"
        first=0
      else
        printf ',\n    "%s"' "$p"
      fi
    done <<< "$files"
    echo
    echo "  ],"
    echo "  \"audioCount\": $audio_count,"
    echo "  \"audio\": ["
    first=1
    while IFS= read -r p; do
      [[ -z "$p" ]] && continue
      if [[ $first -eq 1 ]]; then
        printf '    "%s"' "$p"
        first=0
      else
        printf ',\n    "%s"' "$p"
      fi
    done <<< "$audio_files"
    echo
    echo "  ]"
    echo "}"
  } > "$dest"

  printf "  ✓ %-30s %3s images, %3s audio → %s\n" "$activity" "$count" "$audio_count" "$dest"
done

echo
echo "Done. Don't forget to:"
echo "  1. include 'assets/manifests/' in pubspec.yaml"
echo "  2. commit the generated JSON files"
