#!/usr/bin/env bash
# Smoke test for pi-profile pack/install. Run: ./test.sh
set -euo pipefail
cd "$(dirname "$0")"
WRAP="$PWD/bin/pi-profile"

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
export PI_PROFILES_ROOT="$root/profiles"
export PI_PROFILE_BASE_DIR="$root/base"
mkdir -p "$PI_PROFILE_BASE_DIR/skills"
echo '{"packages":[]}' > "$PI_PROFILE_BASE_DIR/settings.json"
echo 'secret' > "$PI_PROFILE_BASE_DIR/auth.json"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert() { [ -e "$1" ] || fail "missing: $1"; }
assert_not() { [ ! -e "$1" ] || fail "should not exist: $1"; }

# --- create a profile with content, including a symlinked credential
"$WRAP" create web
echo 'custom' > "$PI_PROFILES_ROOT/web/APPEND_SYSTEM.md"
mkdir -p "$PI_PROFILES_ROOT/web/skills/mine"
echo 'skill' > "$PI_PROFILES_ROOT/web/skills/mine/SKILL.md"
# (create already symlinked auth.json from base)

# --- pack: portable files in, secrets out
"$WRAP" pack web "$root/packed" >/dev/null
assert    "$root/packed/settings.json"
assert    "$root/packed/APPEND_SYSTEM.md"
assert    "$root/packed/skills/mine/SKILL.md"
assert    "$root/packed/README.md"
assert_not "$root/packed/auth.json"
[ -z "$(find "$root/packed" -type l)" ] || fail "packed bundle contains a symlink"

# --- install from local dir: fresh profile, credentials re-symlinked
"$WRAP" install "$root/packed" clone >/dev/null
assert "$PI_PROFILES_ROOT/clone/settings.json"
assert "$PI_PROFILES_ROOT/clone/skills/mine/SKILL.md"
[ -L "$PI_PROFILES_ROOT/clone/auth.json" ] || fail "auth.json not re-symlinked at install"
diff "$PI_PROFILES_ROOT/clone/settings.json" "$root/packed/settings.json" || fail "settings.json altered in transit"

# --- install from a GitHub-style spec fails cleanly offline (name validation)
if "$WRAP" install 'not a spec' >/dev/null 2>&1; then fail "bad spec accepted"; fi
if "$WRAP" install "$root/packed" 'bad name!' >/dev/null 2>&1; then fail "bad name accepted"; fi
if "$WRAP" install "$root/packed" clone >/dev/null 2>&1; then fail "existing profile overwritten"; fi

echo "all pack/install checks passed"
