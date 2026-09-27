#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
runner="$(command -v qmltestrunner || true)"

if [[ -z "$runner" && -x /usr/lib/qt6/bin/qmltestrunner ]]; then
    runner=/usr/lib/qt6/bin/qmltestrunner
fi

if [[ -z "$runner" ]]; then
    printf 'Qt QML Test Runner (qmltestrunner) is required to run the state tests.\n' >&2
    exit 127
fi

cd "$project_root"
QML_IMPORT_PATH="${QML_IMPORT_PATH:-/usr/lib/qt6/qml}" \
    QT_QPA_PLATFORM=offscreen \
    "$runner" -input tests -platform offscreen
