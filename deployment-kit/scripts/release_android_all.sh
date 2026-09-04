#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "[release-android-all] Android build"
"$SCRIPT_DIR/build_android.sh"

echo
echo "[release-android-all] Android AAB upload"
set +e
"$SCRIPT_DIR/upload_android_aab.sh" "$@"
aab_status=$?
set -e

if [[ $aab_status -eq 2 ]]; then
  echo "[release-android-all] AAB upload skipped — Play Console app not found yet."
  echo "Create the app in Play Console and upload the first AAB manually, then rerun."
  exit 0
fi

if [[ $aab_status -ne 0 ]]; then
  exit $aab_status
fi

echo
echo "[release-android-all] Android metadata (listings + contact + release notes)"
set +e
"$SCRIPT_DIR/upload_android_metadata.sh" --verify "$@"
android_meta_status=$?
set -e

if [[ $android_meta_status -eq 2 ]]; then
  echo "[release-android-all] Android metadata skipped — Play Console app not found yet."
  echo "Create the app in Play Console once, then rerun this script."
  exit 0
fi

if [[ $android_meta_status -ne 0 ]]; then
  exit $android_meta_status
fi

echo
echo "[release-android-all] Android screenshots"
"$SCRIPT_DIR/upload_android_screenshots.sh" "$@"

exit 0
