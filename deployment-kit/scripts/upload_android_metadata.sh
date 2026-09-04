#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  "$KIT_DIR/play-metadata/update-metadata.sh" --help
  cat <<'EOF'

Also uploads release notes (what's new) from asc-metadata/whats-new.json.
Uses versionCode from pubspec.yaml (override with --version-code N).
Requires a draft release on the production track.

EOF
  exit 0
fi

is_dry_run=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && is_dry_run=true
done

echo "[upload_android_metadata] Store listing + contact details"
"$KIT_DIR/play-metadata/update-metadata.sh" "$@"
meta_status=$?

if [[ $meta_status -eq 2 ]]; then
  exit 2
fi
if [[ $meta_status -ne 0 ]]; then
  exit $meta_status
fi

echo
echo "[upload_android_metadata] Release notes (what's new)"
set +e
"$SCRIPT_DIR/upload_android_whats_new.sh" "$@"
whats_new_status=$?
set -e

if [[ $whats_new_status -ne 0 ]]; then
  if $is_dry_run; then
    exit $whats_new_status
  fi
  echo "[upload_android_metadata] Release notes skipped — upload AAB first:"
  echo "  $SCRIPT_DIR/upload_android_aab.sh"
fi

exit 0
