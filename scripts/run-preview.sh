#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v quickshell >/dev/null 2>&1; then
    printf 'Quickshell is required to run the Nocturne preview.\n' >&2
    exit 127
fi

export QSG_RENDER_LOOP="${QSG_RENDER_LOOP:-threaded}"

exec quickshell --no-color --path "$project_root"
