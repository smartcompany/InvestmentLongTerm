#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "[release-android-all] Android build"
"$SCRIPT_DIR/build_android.sh"

echo
echo "[release-android-all] Android metadata"
set +e
"$SCRIPT_DIR/upload_android_metadata.sh" "$@"
android_meta_status=$?
set -e

if [[ $android_meta_status -eq 2 ]]; then
  echo "[release-android-all] Android metadata skipped — Play Console app not found yet."
  echo "Upload the generated AAB in Play Console once, then rerun metadata upload."
  exit 0
fi

exit $android_meta_status
