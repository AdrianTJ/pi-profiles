# pi-profile

Per-profile config directories for the [pi coding agent](https://pi.dev), with shared session history.

A profile is a complete pi config dir (`~/.pi/profiles/<name>`) activated with
`PI_CODING_AGENT_DIR`. Skills, extensions, packages, `settings.json`,
`APPEND_SYSTEM.md` — everything is isolated per profile. Sessions stay shared via
`PI_CODING_AGENT_SESSION_DIR`, so `/resume` sees all history from any profile.

## Install

```sh
ln -s "$PWD/bin/pi-profile" ~/.local/bin/pi-profile
```

## Usage

```sh
pi-profile list                 # show profiles
pi-profile create work          # new empty profile (shares auth + global AGENTS.md)
pi-profile create web --from work   # clone an existing profile's settings
pi-profile create min --from base   # copy your main ~/.pi/agent/settings.json
pi-profile                      # pick a profile (fzf if installed)
pi-profile work                 # launch pi in the 'work' profile
alias piwork='pi-profile work'  # optional per-profile aliases
```

## What's in a profile

Shared at creation (symlinked, never copied — secrets stay in one place):
`auth.json`, `models-store.json`, `AGENTS.md`, `trust.json`.

Per-profile: `settings.json` (packages/extensions live here), `skills/`,
`extensions/`, and any other pi config file. To share more, symlink it yourself:

```sh
ln -s ~/.pi/agent/skills/deslop ~/.pi/profiles/work/skills/deslop
```

## Notes

- Session files are keyed by working directory, so "shared" history means
  shared *per project* — resume a project's thread from any profile.
- Project-local `.pi/` still loads on top, as usual.
- If pi grows built-in profile support (see earendil-works/pi#3966), migrate by
  moving `~/.pi/profiles/*` contents accordingly.

Environment overrides: `PI_PROFILES_ROOT`, `PI_PROFILE_BASE_DIR`, `PI_PROFILE_SESSIONS`.
