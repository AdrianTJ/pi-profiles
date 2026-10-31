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
echo '{"version":1}' > "$PI_PROFILES_ROOT/web/sol-pi.json"
echo 'decoy' > "$PI_PROFILES_ROOT/web/custom.json"
# (create already symlinked auth.json from base)

# --- pack: portable files in, secrets out
"$WRAP" pack web "$root/packed" >/dev/null
assert    "$root/packed/settings.json"
assert    "$root/packed/APPEND_SYSTEM.md"
assert    "$root/packed/skills/mine/SKILL.md"
assert    "$root/packed/README.md"
assert    "$root/packed/sol-pi.json"
assert_not "$root/packed/auth.json"
assert_not "$root/packed/custom.json"
[ -z "$(find "$root/packed" -type l)" ] || fail "packed bundle contains a symlink"

# --- install from local dir: fresh profile, credentials re-symlinked
"$WRAP" install "$root/packed" clone >/dev/null
assert "$PI_PROFILES_ROOT/clone/settings.json"
assert "$PI_PROFILES_ROOT/clone/skills/mine/SKILL.md"
assert "$PI_PROFILES_ROOT/clone/sol-pi.json"
[ -L "$PI_PROFILES_ROOT/clone/auth.json" ] || fail "auth.json not re-symlinked at install"
diff "$PI_PROFILES_ROOT/clone/settings.json" "$root/packed/settings.json" || fail "settings.json altered in transit"

# --- install from a GitHub-style spec fails cleanly offline (name validation)
if "$WRAP" install 'not a spec' >/dev/null 2>&1; then fail "bad spec accepted"; fi
if "$WRAP" install "$root/packed" 'bad name!' >/dev/null 2>&1; then fail "bad name accepted"; fi
if "$WRAP" install "$root/packed" clone >/dev/null 2>&1; then fail "existing profile overwritten"; fi

# --- clean-lock: repair the ../ ghost entries npm writes for a symlinked --prefix
lock="$PI_PROFILES_ROOT/.shared/npm/package-lock.json"
mkdir -p "$(dirname "$lock")"
cat > "$lock" <<'EOF'
{
  "name": "pi-extensions",
  "version": "file:../escape/root",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": { "name": "pi-extensions", "dependencies": { "pi-tasks": "^0.2.7" } },
    "../../profiles/.shared/npm/node_modules/undici": { "version": "8.10.0" },
    "../../profiles/profiles/.shared/npm/node_modules/undici": { "version": "8.10.0" },
    "node_modules/pi-tasks": { "version": "0.2.7" }
  }
}
EOF

# --check must fail on ghosts without touching the file
if "$WRAP" clean-lock --check >/dev/null 2>&1; then fail "--check passed on a poisoned lockfile"; fi
if ! grep -q '\.\./' "$lock"; then fail "--check modified the lockfile"; fi

clean_out="$("$WRAP" clean-lock)"
case "$clean_out" in
  *"recovered 0, dropped 2 ghost entries"*) ;;
  *) fail "unexpected clean-lock output: $clean_out" ;;
esac
if grep -q '\.\./' "$lock"; then fail "ghost entries survived clean-lock"; fi
grep -q '"node_modules/pi-tasks"' "$lock" || fail "clean-lock dropped a real entry"
grep -q '""' "$lock" || fail "clean-lock dropped the root entry"
if grep -q '"version": "file:' "$lock"; then fail "relative root version survived"; fi

# idempotent, and --check passes once clean
if ! "$WRAP" clean-lock --check; then fail "--check failed on a clean lockfile"; fi
clean_out="$("$WRAP" clean-lock)"
case "$clean_out" in
  *"lockfile clean"*) ;;
  *) fail "clean-lock is not idempotent: $clean_out" ;;
esac

# --- conversion: npm rewrote the only real key as a ghost; recover it from disk
cat > "$lock" <<'EOF'
{
  "name": "pi-extensions",
  "version": "file:../elsewhere/npm",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": { "name": "pi-extensions" },
    "../../elsewhere/npm/node_modules/pi-tasks": { "version": "9.9.9" },
    "../../elsewhere/npm/node_modules/@some/bin-win32": { "version": "1.0.0", "optional": true }
  }
}
EOF
mkdir -p "$PI_PROFILES_ROOT/.shared/npm/node_modules/pi-tasks"
touch "$PI_PROFILES_ROOT/.shared/npm/node_modules/pi-tasks/package.json"
if "$WRAP" clean-lock --check >/dev/null 2>&1; then fail "--check passed on a converted lockfile"; fi
clean_out="$("$WRAP" clean-lock)"
case "$clean_out" in
  *"recovered 2, dropped 0 ghost entries"*) ;;
  *) fail "conversion not repaired: $clean_out" ;;
esac
grep -q '"node_modules/pi-tasks": {' "$lock" || fail "ghost was not recovered to its canonical key"
grep -q '"version": "9.9.9"' "$lock" || fail "recovered entry lost its contents"
grep -q '"node_modules/@some/bin-win32": {' "$lock" || fail "optional off-disk entry not recovered"

# --- gutted lockfile: detectable, and repair says how to regenerate
cat > "$lock" <<'EOF'
{
  "name": "pi-extensions",
  "lockfileVersion": 3,
  "requires": true,
  "packages": { "": { "name": "pi-extensions" } }
}
EOF
if "$WRAP" clean-lock --check >/dev/null 2>&1; then fail "--check passed on a gutted lockfile"; fi
if "$WRAP" clean-lock >/dev/null 2>&1; then fail "repair claimed to fix a gutted lockfile"; fi

# a lockfile npm could not have written must be refused, not rewritten
printf 'not json\n' > "$lock"
if "$WRAP" clean-lock >/dev/null 2>&1; then fail "unparsable lockfile accepted"; fi
grep -q 'not json' "$lock" || fail "unparsable lockfile was rewritten"

# no lockfile yet: both modes pass quietly
rm "$lock"
"$WRAP" clean-lock --check
"$WRAP" clean-lock >/dev/null

# --- update: stub pi and brew record each call as "<agent dir> <args>"
stubs="$root/stubs"; calls="$root/calls.log"
mkdir -p "$stubs" "$root/Cellar/pi-coding-agent/9.9.9/bin"
cat > "$stubs/pi" <<'EOF'
#!/usr/bin/env bash
echo "${PI_CODING_AGENT_DIR:-default} $*" >> "$CALLS"
[ -z "${PI_FAIL_DIR:-}" ] || [ "$PI_FAIL_DIR" != "${PI_CODING_AGENT_DIR:-}" ]
EOF
cat > "$stubs/brew" <<'EOF'
#!/usr/bin/env bash
echo "brew $*" >> "$CALLS"
EOF
chmod +x "$stubs/pi" "$stubs/brew"
export CALLS="$calls"
plain_path="$stubs:$PATH"
run_update() { : > "$calls"; PATH="$plain_path" "$WRAP" update "$@" >"$root/update.out" 2>&1; }
has() { grep -qxF "$1" "$calls" || fail "update did not call: $1 (got: $(tr '\n' ';' < "$calls"))"; }
lacks() { if grep -q -- "$1" "$calls"; then fail "update should not call: $1"; fi; }

run_update || fail "default update failed: $(cat "$root/update.out")"
has "default update --self"
has "$PI_PROFILE_BASE_DIR update --extensions"
has "$PI_PROFILES_ROOT/web update --extensions"
has "$PI_PROFILES_ROOT/clone update --extensions"
lacks "--models"

run_update --models || fail "--models update failed"
has "default update --models"
lacks "--self"; lacks "--extensions"

run_update --extensions -na || fail "--extensions update failed"
has "$PI_PROFILES_ROOT/web update --extensions -na"
lacks "--self"

if run_update --bogus; then fail "unknown flag accepted"; fi

# a failing agent dir fails the run without skipping the others
if PI_FAIL_DIR="$PI_PROFILES_ROOT/clone" run_update --extensions; then fail "extension failure not reported"; fi
has "$PI_PROFILES_ROOT/web update --extensions"

# ghost keys written by the per-dir runs are repaired before update returns
mkdir -p "$(dirname "$lock")" "$(dirname "$lock")/node_modules/pi-tasks"
printf '{"lockfileVersion":3,"packages":{"":{},"../x/node_modules/pi-tasks":{"version":"1.0.0"}}}\n' > "$lock"
run_update --extensions || fail "update with a ghost lockfile failed"
"$WRAP" clean-lock --check >/dev/null 2>&1 || fail "update left ghost entries in the pool lockfile"
rm -rf "$(dirname "$lock")"

# a Homebrew pi is upgraded through brew, never pi's own self-update
mv "$stubs/pi" "$root/Cellar/pi-coding-agent/9.9.9/bin/pi"
ln -s "../Cellar/pi-coding-agent/9.9.9/bin/pi" "$stubs/pi"
run_update --self || fail "brew self update failed"
has "brew upgrade pi-coding-agent"
lacks "update --self"

echo "all pack/install, clean-lock and update checks passed"
