#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-$project_root/docs/screenshots/final}"
mkdir -p -- "$output_dir"
output_dir="$(cd -- "$output_dir" && pwd)"
# One process / one capture avoids stale glyph batches on repeated Qt 6.11 grabs.
for size in 1280x720 1920x1080 2560x1440 3440x1440; do
    states=(idle auth)
    if [[ "$size" == 1920x1080 ]]; then
        states+=(wake wake-middle return-middle typing typing-long authenticating failure collapse black power session)
    fi
    for state in "${states[@]}"; do
        NOCTURNE_WINDOWED=0 NOCTURNE_WIDTH="${size%x*}" NOCTURNE_HEIGHT="${size#*x}" \
            NOCTURNE_CAPTURE_DIR="$output_dir" NOCTURNE_CAPTURE_STATE="$state" \
            "$project_root/scripts/run-preview.sh"
    done
done
