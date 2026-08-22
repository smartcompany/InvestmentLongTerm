#!/usr/bin/env bash
# Alias: What's New only
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/update-metadata.sh" --only whatsNew "$@"
