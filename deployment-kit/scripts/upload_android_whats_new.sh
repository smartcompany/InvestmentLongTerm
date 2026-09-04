#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAY_DIR="$(cd "$SCRIPT_DIR/../play-metadata" && pwd)"
CLIENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PLAY_DIR"

if [[ -f "$PLAY_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$PLAY_DIR/.env"
  set +a
fi

export PLAY_PACKAGE_NAME="${PLAY_PACKAGE_NAME:-com.smartcompany.longterminvestment}"
DEFAULT_PLAY_KEY="/Users/smart/Projects/auth/play-publisher/play-publisher-504708-798db1ae50fd.json"
export PLAY_SERVICE_ACCOUNT_JSON="${PLAY_SERVICE_ACCOUNT_JSON:-$DEFAULT_PLAY_KEY}"

VERSION_CODE=""
pass_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version-code)
      VERSION_CODE="$2"
      pass_args+=("$1" "$2")
      shift 2
      ;;
    *)
      pass_args+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$VERSION_CODE" ]]; then
  VERSION_CODE="$(grep '^version:' "$CLIENT_DIR/pubspec.yaml" | sed 's/.*+//')"
  pass_args=(--version-code "$VERSION_CODE" "${pass_args[@]}")
fi

if [[ ! -d "$PLAY_DIR/node_modules/googleapis" ]]; then
  npm install --no-fund --no-audit
fi

echo "Release notes for versionCode $VERSION_CODE"
exec node "$PLAY_DIR/update-whats-new.mjs" "${pass_args[@]}"
