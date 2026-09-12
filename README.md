# pi-profile

Per-profile config directories for the [pi coding agent](https://github.com/earendil-works/pi), with shared session history.

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
pack copies real files only. Extension entries pointing at absolute local
paths (e.g. profile-badge) won't resolve on other machines — publish those as
packages instead. Installing a profile runs its declared packages, same trust
model as `npm install`.

## What's in a profile

Shared at creation (symlinked, never copied — secrets stay in one place):
`auth.json`, `models-store.json`, `AGENTS.md`, `trust.json`, `extensions/`.

`extensions/` is shared because tools install their own files into the base agent
dir (Orca's managed status extension, for example) and Pi only discovers
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
