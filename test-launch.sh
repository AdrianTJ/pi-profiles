#!/usr/bin/env bash
# Live launch test for pi-profile. Run: ./test-launch.sh
#
# NEVER in CI: needs pi provider auth and spends ~5 model calls.
# Extends test.sh (pack/install structure) with live `pi -p` runs proving
# profile isolation, shared sessions, skill loading, and credential hygiene.
set -euo pipefail
cd "$(dirname "$0")"
WRAP="$PWD/bin/pi-profile"
PROVIDER="${PI_TEST_PROVIDER:-opencode-go}"
MODEL="${PI_TEST_MODEL:-muse-spark-1.3-contributor}"
pi auth check --provider "$PROVIDER" >/dev/null \
  || { echo "FAIL: pi provider '$PROVIDER' not ready (pi auth check)"; exit 1; }

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
export PI_PROFILES_ROOT="$root/profiles"
export PI_PROFILE_BASE_DIR="$HOME/.pi/agent"   # read-only: auth symlinked, never copied
runs=0
PI_FLAGS=(--provider "$PROVIDER" --model "$MODEL")
launch() { # profile, prompt...  (stdout = model output)
  # NOTE: runs in a subshell under $() — caller increments $runs.
  PI_CODING_AGENT_DIR="$PI_PROFILES_ROOT/$1" pi -p --no-session "${PI_FLAGS[@]}" "${@:2}"
}

fail() { echo "FAIL: $*" >&2; exit 1; }

# --- two profiles, distinct markers
"$WRAP" create alpha >/dev/null
"$WRAP" create beta >/dev/null
echo 'Always start every reply with [ALPHA] and nothing else before it.' > "$PI_PROFILES_ROOT/alpha/APPEND_SYSTEM.md"
echo 'Always start every reply with [BETA] and nothing else before it.' > "$PI_PROFILES_ROOT/beta/APPEND_SYSTEM.md"

runs=$(( runs + 1 ))
out_alpha="$(launch alpha 'Reply with: hello')"
runs=$(( runs + 1 ))
out_beta="$(launch beta 'Reply with: hello')"
[[ "$out_alpha" == *'[ALPHA]'* ]] || fail "alpha marker missing: $out_alpha"
[[ "$out_beta" == *'[BETA]'* ]] || fail "beta marker missing: $out_beta"
[[ "$out_alpha" != *'[BETA]'* ]] || fail "beta marker leaked into alpha"
[[ "$out_beta" != *'[ALPHA]'* ]] || fail "alpha marker leaked into beta"

# --- sessions shared across profiles in one project
PI_CODING_AGENT_DIR="$PI_PROFILES_ROOT/alpha" pi -p "${PI_FLAGS[@]}" \
  --name launchtest 'Remember this codeword: CORDWAIN-7. Reply with: noted.' >/dev/null
shared="$(PI_CODING_AGENT_DIR="$PI_PROFILES_ROOT/beta" pi -p "${PI_FLAGS[@]}" \
  --continue 'What was the codeword? Reply with it and nothing else.')"
[[ "$shared" == *'CORDWAIN-7'* ]] || fail "cross-profile resume lost the thread: $shared"
runs=$(( runs + 2 ))

# --- skills load from the profile (explicit invocation: tests wiring, not trigger judgment)
"$WRAP" create skilled >/dev/null
mkdir -p "$PI_PROFILES_ROOT/skilled/skills/mine"
printf -- '---\nname: mine\ndescription: Reply with the [SKILLED] marker first. Use when the user asks for a marked greeting.\n---\n\n# Mine\n\nAlways start every reply with [SKILLED] and nothing else before it.\n' \
  > "$PI_PROFILES_ROOT/skilled/skills/mine/SKILL.md"
runs=$(( runs + 1 ))
out_skilled="$(launch skilled 'Using the mine skill, reply with: hello')"
[[ "$out_skilled" == *'[SKILLED]'* ]] || fail "profile skill not loaded: $out_skilled"

echo "all launch checks passed ($runs model calls)"
