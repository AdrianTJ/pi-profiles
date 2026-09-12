#!/usr/bin/env bash
# Everything CI runs for this repo, in one place so the same checks can run
# before a push instead of after. CI calls this file, and so does .githooks/pre-push.
set -euo pipefail
cd "$(dirname "$0")"

command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck is required: brew install shellcheck" >&2; exit 1; }

shellcheck bin/pi-profile
./test.sh

echo "pi-profiles: all checks passed"
