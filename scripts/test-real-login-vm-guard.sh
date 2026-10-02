#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
python3 -m unittest discover \
    -s "$project_root/tests" \
    -p 'test_real_login_vm_guard.py' \
    -v
