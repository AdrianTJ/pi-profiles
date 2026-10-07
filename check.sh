#!/usr/bin/env bash
# Everything CI runs for this repo, in one place so the same checks can run
# before a push instead of after. CI calls this file, and so does .githooks/pre-push.
set -euo pipefail
cd "$(dirname "$0")"

command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck is required: brew install shellcheck" >&2; exit 1; }

shellcheck bin/pi-profile
# npm update through the pool's symlinked npm/ leaves ../-prefixed ghost keys
# in the lockfile (npm audit counts them as phantom vulnerabilities). Fail
# loudly rather than let them accumulate: run 'pi-profile clean-lock' to clear.
./bin/pi-profile clean-lock --check
./test.sh

echo "pi-profiles: all checks passed"
