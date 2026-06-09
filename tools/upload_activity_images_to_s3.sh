#!/usr/bin/env bash
# Upload the 10 Satellite Engineer activity image folders to the public
# howwow S3 bucket, mirroring the local layout under an `activities/`
# prefix so the Flutter client can build URLs as
#
#   https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities/<id>/<relative path>
#
# Usage:
#   tools/upload_activity_images_to_s3.sh             # upload all 10 activities
#   tools/upload_activity_images_to_s3.sh <id> [...]  # upload only the listed activities
#   DRY_RUN=1 tools/upload_activity_images_to_s3.sh   # show what would happen
#
# Requirements:
#   • AWS CLI v2 (`aws --version`)
#   • Credentials configured (`aws configure` or env vars) with PutObject +
#     PutObjectAcl on s3://the-how-wow-prod/activities/*
#
# Behaviour:
#   • Uses `aws s3 sync` so reruns are incremental — only changed/new files
#     transfer. Existing untouched files are NOT re-uploaded.
#   • Skips `asset_meta.json` and any other JSON metadata files (the client
#     doesn't load them at runtime).
#   • Sets `--acl public-read` so the URLs are anonymously fetchable, and
#     a 1-year Cache-Control so devices cache aggressively (file paths are
#     stable; if a file changes meaningfully, rename it).
#   • Picks Content-Type by extension where the AWS CLI's default guess is
#     wrong (it guesses fine for png/jpg, but webp can land as
#     application/octet-stream on older CLIs).

set -euo pipefail

BUCKET="the-how-wow-prod"
REGION="ap-south-1"
PREFIX="activities"
SOURCE_ROOT="assets/images"

# All 10 Satellite Engineer activities (ids match the activityId values the
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

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not configured. Run 'aws configure' or set AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY." >&2
  exit 1
fi

# Resolve script's own directory so the script can be invoked from anywhere
# but still finds the assets/ tree at the repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -d "$SOURCE_ROOT" ]]; then
  echo "ERROR: $SOURCE_ROOT not found — run this from the GlutaFam repo root or via tools/upload_activity_images_to_s3.sh" >&2
  exit 1
fi

DRY_RUN_FLAG=""
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  DRY_RUN_FLAG="--dryrun"
  echo "── DRY RUN MODE — no files will be uploaded ──"
fi

# ── upload ──────────────────────────────────────────────────────────────

echo
echo "Uploading ${#ACTIVITIES[@]} activity folder(s) to s3://$BUCKET/$PREFIX/"
echo

total_files=0
total_bytes=0
start_ts=$(date +%s)

for activity in "${ACTIVITIES[@]}"; do
  src="$SOURCE_ROOT/$activity"
  dest="s3://$BUCKET/$PREFIX/$activity"

  if [[ ! -d "$src" ]]; then
    echo "  ⚠️  $activity — local folder $src not found, skipping"
    continue
  fi

  # Per-folder file count + size so the run prints meaningful progress.
  count=$(find "$src" -type f \! -name "*.json" | wc -l | tr -d ' ')
  size=$(find "$src" -type f \! -name "*.json" -print0 \
          | xargs -0 stat -f "%z" 2>/dev/null \
          | awk '{s+=$1} END {printf "%.1f MB", s/1048576}')

  echo "▶ $activity  →  $dest  ($count files, $size)"

  aws s3 sync "$src/" "$dest/" \
    --region "$REGION" \
    --acl public-read \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "*.json" \
    --exclude ".DS_Store" \
    --exclude "*/.DS_Store" \
    $DRY_RUN_FLAG \
    --only-show-errors

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
  sample=$(find "$SOURCE_ROOT/$first" -type f \! -name "*.json" 2>/dev/null | head -1)
  if [[ -n "$sample" ]]; then
    relpath="${sample#$SOURCE_ROOT/$first/}"
    # AWS CLI sync URL-encodes spaces etc. for us, but our paths are
    # snake_case so a plain concat round-trips fine. If you ever add files
    # with spaces, encode the path before sticking it in this URL.
    url="https://$BUCKET.s3.$REGION.amazonaws.com/$PREFIX/$first/$relpath"
    echo "Verification — fetching one uploaded file:"
    echo "  $url"
    if curl -fsI -m 10 "$url" >/dev/null 2>&1; then
      echo "  ✓ HTTP 200 — bucket is serving uploaded files publicly"
    else
      echo "  ✗ verification fetch failed — check bucket policy / Block Public Access settings" >&2
      exit 1
    fi
  fi
fi
