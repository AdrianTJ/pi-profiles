# pi-profile

Per-profile config directories for the [pi coding agent](https://github.com/earendil-works/pi), with shared session history and a shared package pool.

A profile is a complete pi config dir (`~/.pi/profiles/<name>`) activated with
`PI_CODING_AGENT_DIR`. Packages, `skills/`, `settings.json` and
`APPEND_SYSTEM.md` are isolated per profile, while `extensions/` is shared with
the base agent dir (see [What's in a profile](#whats-in-a-profile)). Sessions stay
shared via `PI_CODING_AGENT_SESSION_DIR`, so `/resume` sees all history from any
profile.

## Install

```sh
ln -s "$PWD/bin/pi-profile" ~/.local/bin/pi-profile
```

## Usage

```sh
pi-profile list                 # profiles: purpose, packages, skills, config
pi-profile show work            # a profile's full description
pi-profile create work          # new empty profile (shares auth + global AGENTS.md)
pi-profile create web --from work   # clone an existing profile's settings
pi-profile create min --from base   # copy your main ~/.pi/agent/settings.json
pi-profile pack web ./pi-web        # export a shareable profile folder
pi-profile install you/pi-web       # install a shared profile (GitHub or local dir)
pi-profile update               # update pi and every profile's extensions
pi-profile                      # pick a profile (fzf if installed)
pi-profile work                 # launch pi in the 'work' profile
alias piwork='pi-profile work'  # optional per-profile aliases
```

## Describing a profile

Every profile carries a `DESCRIPTION.md`: what it is for and when to reach for
it instead of another one. Its first non-heading line is the summary shown by
`pi-profile list` and by the picker, so keep that line short and put the detail
underneath.

```md
# web

Web scraping and crawling work: playwright plus the fetch tools.

Use it when: the task is mostly reading pages you cannot reach with curl.
```

`list` prints that prose and then the profile's real contents, read from the
profile itself at list time: declared packages, skills, and config files it
carries. Nothing to keep in sync by hand, so a description never claims a package
the profile does not install. `list -1` gives the one-line-per-profile form.

`create` and `install` leave a starter file when there is none, `show` prints the
description plus the same inventory, and `pack` carries the file into the bundle,
so an installed profile keeps its description. Profiles without one show up as
`no description yet`.

## Sharing profiles

A profile's portable content is small — settings.json (which declares its
packages), DESCRIPTION.md, APPEND_SYSTEM.md, sol-pi.json, and the skills/,
prompts/, and extensions/ directories. `pack` copies exactly that whitelist into
a folder you
push to GitHub; `install` clones any such repo into
a new local profile and re-symlinks your credentials. Packages re-fetch from
npm/git on first launch, so nothing is vendored.

```sh
pi-profile pack web ./pi-web     # → push ./pi-web to a new GitHub repo
cd pi-web && git init -b main && git add -A && git commit -m 'pack: web'

pi-profile install someone/pi-web   # anyone can install it
pi-profile install ./pi-web mine    # local dirs work too — test before pushing
```

Secrets can't leak into a bundle: profiles hold credentials as symlinks and
pack copies real files only. Extension entries that point at a local checkout use
`${PLACEHOLDER}` names instead of a real path (see `profiles/README.md` and
`.env.example`), so nothing personal is committed and each machine fills in its
own path. Installing a profile runs its declared packages, same trust
model as `npm install`.

## What this repo carries

- `bin/pi-profile` — the launcher.
- `profiles/<name>/` — every profile definition (settings, description,
  `APPEND_SYSTEM.md`, `sol-pi.json`, and any owned skills). Nine profiles live
  here; see `profiles/README.md` for what each one is for and how to rebuild a
  machine from scratch.
- `pool/package.json`, `pool/package-lock.json` — the package versions and
  overrides the profiles were last run against, so a fresh pool reproduces them.
- `extensions/profile-badge.ts` — the footer badge, loaded by profiles that
  reference it.

## What's in a profile

Shared at creation (symlinked, never copied — secrets stay in one place):
`auth.json`, `models-store.json`, `AGENTS.md`, `trust.json`, `extensions/`.

Packages are shared too: every profile's `npm/` and `git/` entries are symlinks into one pool at `~/.pi/profiles/.shared/` (override with `PI_PROFILE_PACKAGES_DIR`), and the base agent dir links to the same pool. So all profiles and plain `pi` run the same package versions. Existing installs are migrated with:

```sh
pi-profile migrate-packages
```

One caveat: pi passes the pool's symlinked `npm/` to npm as `--prefix` without resolving it, so each `pi update --extensions` rewrites the pool lockfile with `../`-relative ghost keys and a relative root version field, which `npm audit` counts as phantom vulnerabilities. `check.sh` fails on them (and on a lockfile gutted by that rewrite); `pi-profile clean-lock` repairs the lockfile from the on-disk tree.

## Updating

`pi update --extensions` only reads the active agent dir's `settings.json`, so a package only one profile declares is never updated from another. `pi-profile update` covers everything in one go:

```sh
pi-profile update               # pi itself, then extensions in base + every profile
pi-profile update --extensions  # extensions only (also --self, --models; they add up)
```

pi itself is updated once, through `brew upgrade` when the `pi` on PATH lives in a Homebrew Cellar (pi cannot self-update those), otherwise through `pi update --self`. Extensions then update once per agent dir, after which the pool lockfile is repaired with `clean-lock`. `--models` refreshes the model catalogs once, since `models-store.json` is shared. A failure in any step is reported at the end and the command exits non-zero, but the remaining steps still run.

### Weekly updates

`.github/workflows/pool-refresh.yml` runs `pool/refresh.sh` every Monday and opens (or updates) a PR moving `pool/` to the newest published versions. It checks the new lockfile installs, that `overrides` still apply, and puts the `npm audit` count in the PR body. Nothing merges on its own. Installed extensions on a machine still update only when `pi-profile update` runs there.

`extensions/` is shared because tools install their own files into the base agent
dir (a status-reporting extension, for example) and Pi only discovers
extensions under the active agent dir. A private `extensions/` directory means a
profile silently loads none of them, which is how profile sessions end up missing
status reporting.

Per-profile: `settings.json` (packages and absolute-path extensions live here),
`skills/`, and any other pi config file. To share more, symlink it yourself:

```sh
ln -s ~/.pi/agent/skills/deslop ~/.pi/profiles/work/skills/deslop
```

To give one profile extensions of its own, replace its `extensions` symlink with a
real directory and symlink the base files you want back in. `pack` skips symlinks,
so the shared directory never ends up in a published bundle.

New profiles automatically get the `profile-badge` extension (shows the active
profile name, e.g. `[work]`, in the footer). It reads `PI_CODING_AGENT_DIR`, so
it stays silent when pi runs without the wrapper.

## Notes

- `~/.agents/skills/` is discovered globally by pi in every profile (by design —
  it's the cross-harness skill location). Profile isolation covers pi-specific
  config: `~/.pi/profiles/<name>/{settings.json,skills,extensions,...}`.

- Session files are keyed by working directory, so "shared" history means
  shared *per project* — resume a project's thread from any profile.
- Project-local `.pi/` still loads on top, as usual.
- `pack` copies real files only, so anything you symlinked into a profile
  (skills, extensions) is left out of the bundle — copy the files in instead.
- If pi grows built-in profile support (see earendil-works/pi#3966), migrate by
  moving `~/.pi/profiles/*` contents accordingly.

Environment overrides: `PI_PROFILES_ROOT`, `PI_PROFILE_BASE_DIR`, `PI_PROFILE_SESSIONS`.

## Checks

`./check.sh` runs everything CI runs: shellcheck on `bin/pi-profile` and the
pack/install smoke test. Point the hook at it once per clone and a broken check
never reaches CI:

```sh
git config core.hooksPath .githooks
```
