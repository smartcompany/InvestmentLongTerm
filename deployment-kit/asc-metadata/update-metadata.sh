#!/usr/bin/env bash
# Upload App Store listing + What's New metadata via App Store Connect API.
#
# Usage:
#   ./update-metadata.sh --dry-run
#   ./update-metadata.sh
#   ./update-metadata.sh --only whatsNew
#   ./update-metadata.sh --only reviewNotes
#   ./update-metadata.sh --bundle-id com.smartcompany.longterminvestment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DEFAULT_KEY="/Users/smart/Projects/auth/fastlaneAuthKeys/AuthKey_7FN57R567Z.p8"
DEFAULT_KEY_ID="7FN57R567Z"
DEFAULT_BUNDLE_ID="com.smartcompany.longterminvestment"
DEFAULT_APP_NAME="My Assets AI"
DEFAULT_PRIMARY_LANGUAGE="en-US"
DEFAULT_SUPPORT_URL="https://smartcompany.github.io"
DEFAULT_MARKETING_URL="https://smartcompany.github.io"
DEFAULT_COPYRIGHT="2026 Yong Geon Kim. All rights reserved."
FALLBACK_ENV="/Users/smart/Projects/Tabata/client/tools/asc-metadata/.env"
PRESET_ASC_BUNDLE_ID="${ASC_BUNDLE_ID:-}"
PRESET_ASC_APP_ID="${ASC_APP_ID:-}"
PRESET_ASC_SKU="${ASC_SKU:-}"
PRESET_ASC_APP_NAME="${ASC_APP_NAME:-}"
PRESET_PRODUCE_USERNAME="${PRODUCE_USERNAME:-}"
DEFAULT_PRODUCE_USERNAME="gunnylove@gmail.com"
DEFAULT_PRODUCE_TEAM_ID="NTCK5U8AWD"
DEFAULT_PRODUCE_ITC_TEAM_ID="117828562"

load_dotenv() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  set -a
  # shellcheck disable=SC1090
  source "$file"
  set +a
}

if [[ -f "$FALLBACK_ENV" ]]; then
  load_dotenv "$FALLBACK_ENV"
fi
load_dotenv "$SCRIPT_DIR/.env"

export ASC_KEY_ID="${ASC_KEY_ID:-$DEFAULT_KEY_ID}"
export ASC_PRIVATE_KEY_PATH="${ASC_PRIVATE_KEY_PATH:-$DEFAULT_KEY}"
export ASC_BUNDLE_ID="${PRESET_ASC_BUNDLE_ID:-$DEFAULT_BUNDLE_ID}"
export ASC_APP_ID="${PRESET_ASC_APP_ID:-}"
export ASC_SKU="${PRESET_ASC_SKU:-$ASC_BUNDLE_ID}"
export ASC_APP_NAME="${PRESET_ASC_APP_NAME:-$DEFAULT_APP_NAME}"
export PRODUCE_USERNAME="${PRESET_PRODUCE_USERNAME:-$DEFAULT_PRODUCE_USERNAME}"
export ASC_SUPPORT_URL="${ASC_SUPPORT_URL:-$DEFAULT_SUPPORT_URL}"
export ASC_MARKETING_URL="${ASC_MARKETING_URL:-$DEFAULT_MARKETING_URL}"
export ASC_COPYRIGHT="${ASC_COPYRIGHT:-$DEFAULT_COPYRIGHT}"

pass_args=()
SKU_EXPLICIT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle-id)
      export ASC_BUNDLE_ID="$2"
      shift 2
      ;;
    --app-id)
      export ASC_APP_ID="$2"
      shift 2
      ;;
    --sku)
      export ASC_SKU="$2"
      SKU_EXPLICIT=true
      shift 2
      ;;
    --app-name)
      export ASC_APP_NAME="$2"
      shift 2
      ;;
    --help|-h)
      exec node "$SCRIPT_DIR/update-metadata.mjs" --help
      ;;
    *)
      pass_args+=("$1")
      shift
      ;;
  esac
done

if [[ "$SKU_EXPLICIT" != true && -z "${PRESET_ASC_SKU}" ]]; then
  export ASC_SKU="$ASC_BUNDLE_ID"
fi

if [[ -z "${ASC_ISSUER_ID:-}" ]]; then
  echo "ASC_ISSUER_ID is required."
  echo "App Store Connect → Users and Access → Keys → Issuer ID 를 복사한 뒤:"
  echo "  1) cp .env.example .env 후 ASC_ISSUER_ID=... 입력, 또는"
  echo "  2) ASC_ISSUER_ID=... ./update-metadata.sh"
  exit 1
fi

if [[ ! -f "$ASC_PRIVATE_KEY_PATH" ]]; then
  echo "Auth key not found: $ASC_PRIVATE_KEY_PATH"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node is required (Node 18+)."
  exit 1
fi

echo "Key ID:  $ASC_KEY_ID"
echo "Key:     $ASC_PRIVATE_KEY_PATH"
echo "Bundle:  $ASC_BUNDLE_ID"
if [[ -n "${ASC_APP_ID:-}" ]]; then
  echo "App ID:  $ASC_APP_ID"
fi
echo

run_metadata() {
  node "$SCRIPT_DIR/update-metadata.mjs" "${pass_args[@]}"
}

create_app_if_missing() {
  if ! command -v fastlane >/dev/null 2>&1; then
    echo "fastlane is required to auto-create the app when it is missing."
    return 1
  fi

  echo "App missing in App Store Connect. Creating it with fastlane produce..."
  fastlane produce create \
    -u "$PRODUCE_USERNAME" \
    -a "$ASC_BUNDLE_ID" \
    -q "$ASC_APP_NAME" \
    -y "$ASC_SKU" \
    -m "$DEFAULT_PRIMARY_LANGUAGE" \
    -j ios \
    -b "$DEFAULT_PRODUCE_TEAM_ID" \
    -k "$DEFAULT_PRODUCE_ITC_TEAM_ID"
}

tmp_log="$(mktemp)"
set +e
run_metadata >"$tmp_log" 2>&1
status=$?
set -e

if [[ $status -eq 0 ]]; then
  cat "$tmp_log"
  rm -f "$tmp_log"
  exit 0
fi

if grep -q "App not found for bundleId=" "$tmp_log"; then
  cat "$tmp_log"
  create_app_if_missing
  rm -f "$tmp_log"
  exec node "$SCRIPT_DIR/update-metadata.mjs" "${pass_args[@]}"
fi

cat "$tmp_log"
rm -f "$tmp_log"
exit $status
