#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

exec "$KIT_DIR/asc-metadata/update-metadata.sh" "$@"
