#!/usr/bin/env bash
# Upload the Satellite Engineer activity audio folders (Orbit voice-over,
# BGM, SFX) to the public howwow S3 bucket. Audio lives INSIDE each
# activity's existing image prefix, under an `audio/` segment:
#
#   local:  assets/sounds/<activity_id>/<relative path>
#   S3:     https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities/<activity_id>/audio/<relative path>
#
# (Images occupy activities/<id>/<subfolders> directly; `audio/` is a
# reserved segment — no activity has an image folder by that name.)
#
# Usage:
#   tools/upload_activity_audio_to_s3.sh             # upload all 11 activities
#   tools/upload_activity_audio_to_s3.sh <id> [...]  # upload only the listed activities
#   DRY_RUN=1 tools/upload_activity_audio_to_s3.sh   # show what would happen
#
# Requirements:
#   • AWS CLI v2 (`aws --version`)
#   • Credentials configured (`aws configure` or env vars) with PutObject +
#     PutObjectAcl on s3://the-how-wow-prod/activities/*
#
# Behaviour:
#   • Uses `aws s3 sync` so reruns are incremental — only changed/new files
#     transfer. Existing untouched files are NOT re-uploaded.
#   • Sets `--acl public-read` so the URLs are anonymously fetchable, and
#     a 1-year Cache-Control so devices cache aggressively (file paths are
#     stable; if a clip changes meaningfully, rename it).
#   • Forces correct audio Content-Types per extension — the AWS CLI's
#     guesser is unreliable for wav (audio/x-wav vs audio/wav) and can land
#     octet-stream on some systems, which breaks some platform players.

set -euo pipefail

BUCKET="the-how-wow-prod"
REGION="ap-south-1"
PREFIX="activities"
SOURCE_ROOT="assets/sounds"
# The bucket lives in the howwow AWS account (793422184522) — the local
# `default` profile is a different account and gets AccessDenied. Override
# with AWS_PROFILE=<name> if your profile is named differently.
PROFILE="${AWS_PROFILE:-new}"

# All 11 Satellite Engineer activities (ids match the activityId values the
# backend seeds + the registry in lib/screens/missions/activityRegistry.dart).
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

# ── arg handling ────────────────────────────────────────────────────────

if [[ $# -gt 0 ]]; then
  ACTIVITIES=("$@")
else
  ACTIVITIES=("${ALL_ACTIVITIES[@]}")
fi

# ── preflight ───────────────────────────────────────────────────────────

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI not found. Install via 'brew install awscli' or see https://aws.amazon.com/cli/" >&2
  exit 1
fi

if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not configured for profile '$PROFILE'. Run 'aws configure --profile $PROFILE' or set AWS_PROFILE." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -d "$SOURCE_ROOT" ]]; then
  echo "ERROR: $SOURCE_ROOT not found — run this from the GlutaFam repo root or via tools/upload_activity_audio_to_s3.sh" >&2
  exit 1
fi

DRY_RUN_FLAG=""
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  DRY_RUN_FLAG="--dryrun"
  echo "── DRY RUN MODE — no files will be uploaded ──"
fi

# ── upload ──────────────────────────────────────────────────────────────

echo
echo "Uploading ${#ACTIVITIES[@]} activity audio folder(s) to s3://$BUCKET/$PREFIX/<id>/audio/"
echo

total_files=0
start_ts=$(date +%s)

# One sync pass per (extension → content-type) pair. `aws s3 sync` only
# takes a single --content-type, so we filter by extension per pass.
# Pairs are "ext:content-type" — bash 3.2 (macOS default) has no assoc arrays.
TYPE_PAIRS=(
  "mp3:audio/mpeg"
  "wav:audio/wav"
  "ogg:audio/ogg"
  "m4a:audio/mp4"
)

for activity in "${ACTIVITIES[@]}"; do
  src="$SOURCE_ROOT/$activity"
  dest="s3://$BUCKET/$PREFIX/$activity/audio"

  if [[ ! -d "$src" ]]; then
    echo "  ⚠️  $activity — local folder $src not found, skipping"
    continue
  fi

  count=$(find "$src" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) | wc -l | tr -d ' ')
  size=$(find "$src" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.m4a" \) -print0 \
          | xargs -0 stat -f "%z" 2>/dev/null \
          | awk '{s+=$1} END {printf "%.1f MB", s/1048576}')

  echo "▶ $activity  →  $dest/  ($count files, $size)"

  for pair in "${TYPE_PAIRS[@]}"; do
    ext="${pair%%:*}"
    ctype="${pair#*:}"
    # Skip the pass entirely if the activity has no files of this type.
    if ! find "$src" -type f -iname "*.$ext" | grep -q .; then
      continue
    fi
    aws s3 sync "$src/" "$dest/" \
      --profile "$PROFILE" \
      --region "$REGION" \
      --acl public-read \
      --cache-control "public, max-age=31536000, immutable" \
      --content-type "$ctype" \
      --exclude "*" \
      --include "*.$ext" \
      --exclude ".DS_Store" \
      --exclude "*/.DS_Store" \
      $DRY_RUN_FLAG \
      --only-show-errors
  done

  total_files=$((total_files + count))
  echo "  ✓ done"
  echo
done

elapsed=$(( $(date +%s) - start_ts ))
echo "Uploaded $total_files file(s) across ${#ACTIVITIES[@]} activity folder(s) in ${elapsed}s."
echo

# ── verification ────────────────────────────────────────────────────────

if [[ "${DRY_RUN:-0}" != "1" ]] && [[ ${#ACTIVITIES[@]} -gt 0 ]]; then
  first="${ACTIVITIES[0]}"
  sample=$(find "$SOURCE_ROOT/$first" -type f \( -iname "*.mp3" -o -iname "*.wav" \) 2>/dev/null | head -1)
  if [[ -n "$sample" ]]; then
    relpath="${sample#$SOURCE_ROOT/$first/}"
    url="https://$BUCKET.s3.$REGION.amazonaws.com/$PREFIX/$first/audio/$relpath"
    echo "Verification — fetching one uploaded file:"
    echo "  $url"
    if curl -fsI -m 10 "$url" >/dev/null 2>&1; then
      echo "  ✓ HTTP 200 — bucket is serving uploaded audio publicly"
    else
      echo "  ✗ verification fetch failed — check bucket policy / Block Public Access settings" >&2
      exit 1
    fi
  fi
fi
