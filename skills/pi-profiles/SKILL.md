---
name: pi-profiles
description: Install, pack, or publish shareable pi coding-agent profiles with the pi-profile wrapper. Use when the user wants to install a shared pi profile, export/pack an existing profile to share on GitHub, or set up pi-profile itself.
---

# pi profiles

Profiles are full pi config dirs under `~/.pi/profiles/<name>`, activated via
the `pi-profile` wrapper (https://github.com/AdrianTJ/pi-profiles). The wrapper
is the only installer — never hand-copy profile dirs.

## Install a shared profile

```sh
pi-profile install <owner>/<repo> [name]   # GitHub repo containing a packed profile
pi-profile install ./<packed-dir> [name]   # local dir works too
```

Then verify: `pi-profile list`, and launch `pi-profile <name>` once so the
packages declared in its settings.json fetch. Credentials are symlinked from
`~/.pi/agent/` automatically — never copy `auth.json` or `models-store.json`.

If the wrapper itself is missing, install it from the repository this skill
ships in — this file lives at `<repo>/skills/pi-profiles/SKILL.md`, so the
wrapper script is two directories up:

```sh
ln -s <this-repo>/bin/pi-profile ~/.local/bin/pi-profile
```

If that repo isn't available locally, ask the user for its URL, then
`git clone <url>` and symlink as above.

## Pack and publish a profile

```sh
pi-profile pack <name> ./<repo-name>
cd <repo-name> && git init -b main && git add -A && git commit -m "pack: <name>"
gh repo create <repo-name> --public --source=. --push
```

Always round-trip before pushing: `pi-profile install ./<repo-name> tmp-test`,
launch it once, confirm packages and skills load, then delete the test profile.

## Rules

- Packing copies real files only; symlinks (credentials, machine state) are
  skipped by design. Never work around that.
- Extension entries in settings.json pointing at absolute local paths won't
  resolve on other machines — tell the user to publish those as npm/git packages.
- Installing someone's profile runs its declared packages — same trust model
  as `npm install`. Read its settings.json first when it's not the user's own.
