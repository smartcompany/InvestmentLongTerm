#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAY_DIR="$SCRIPT_DIR"
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

if [[ ! -d "$PLAY_DIR/node_modules/googleapis" ]]; then
  npm install --no-fund --no-audit
fi

exec node "$PLAY_DIR/update-whats-new.mjs" "$@"
