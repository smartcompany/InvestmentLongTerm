#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_IOS_META=false
RUN_ANDROID_META=false
RUN_IOS_BUILD=false
RUN_ANDROID_BUILD=false
DRY_RUN=false
IOS_BUILD_BUMP=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --ios-meta        Upload App Store metadata
  --android-meta    Upload Google Play metadata
  --ios-build       Build iOS release
  --android-build   Build Android release
  --ios-bump        Bump iOS build number before build
  --dry-run         Pass dry-run to metadata uploads
  -h, --help        Show help

Example:
  ./deployment-kit/scripts/release_all.sh --ios-meta --android-meta --dry-run
  ./deployment-kit/scripts/release_all.sh --ios-build --android-build --ios-bump
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ios-meta) RUN_IOS_META=true ;;
    --android-meta) RUN_ANDROID_META=true ;;
    --ios-build) RUN_IOS_BUILD=true ;;
    --android-build) RUN_ANDROID_BUILD=true ;;
    --ios-bump) IOS_BUILD_BUMP=true ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if ! $RUN_IOS_META && ! $RUN_ANDROID_META && ! $RUN_IOS_BUILD && ! $RUN_ANDROID_BUILD; then
  usage
  exit 1
fi

if $RUN_IOS_META; then
  echo
  echo "[release-all] iOS metadata"
  if $DRY_RUN; then
    "$SCRIPT_DIR/upload_ios_metadata.sh" --dry-run
  else
    "$SCRIPT_DIR/upload_ios_metadata.sh"
  fi
fi

if $RUN_ANDROID_META; then
  echo
  echo "[release-all] Android metadata"
  set +e
  if $DRY_RUN; then
    "$SCRIPT_DIR/upload_android_metadata.sh" --dry-run
  else
    "$SCRIPT_DIR/upload_android_metadata.sh"
  fi
  android_meta_status=$?
  set -e
  if [[ $android_meta_status -eq 2 ]]; then
    echo "[release-all] Android metadata skipped — Play Console app not found yet."
  elif [[ $android_meta_status -ne 0 ]]; then
    exit $android_meta_status
  fi
fi

if $RUN_IOS_BUILD; then
  echo
  echo "[release-all] iOS build"
  if $IOS_BUILD_BUMP; then
    "$SCRIPT_DIR/build_ios.sh" --bump
  else
    "$SCRIPT_DIR/build_ios.sh"
  fi
fi

if $RUN_ANDROID_BUILD; then
  echo
  echo "[release-all] Android build"
  "$SCRIPT_DIR/build_android.sh"
fi
