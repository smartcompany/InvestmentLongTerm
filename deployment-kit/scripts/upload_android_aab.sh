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

DEFAULT_AAB="$CLIENT_DIR/build/app/outputs/bundle/release/app-release.aab"
pass_args=()
has_aab=false
for arg in "$@"; do
  [[ "$arg" == "--aab" ]] && has_aab=true
done
if ! $has_aab; then
  pass_args=(--aab "$DEFAULT_AAB")
fi
pass_args+=("$@")

if [[ ! -d "$PLAY_DIR/node_modules/googleapis" ]]; then
  echo "Installing dependencies (googleapis)…"
  npm install --no-fund --no-audit
fi

exec node "$PLAY_DIR/upload-aab.mjs" "${pass_args[@]}"
