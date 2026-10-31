# Profiles

Every profile definition lives here, so a machine can be rebuilt from this repo
plus credentials. `pi-profile list` shows what is installed locally and what each
one installs, read from the profile itself.

| Profile | What it is for | Packages |
| --- | --- | --- |
| `daily` | Lean interactive daily driver: search, ask, delegate, plan, dictate. | 7 |
| `basic` | Plain pi plus two extensions: web search and subagents. | 2 |
| `marathon` | Unattended campaigns: goal, Ralph loop, durable plans, approval gating, review gate. | 5 |
| `SoL-Pi` | SoL-Pi trial: Action Fusion and ObservationPack, nothing else. | 2 |
| `pi-starter` | Baseline starter set for a fresh machine. | 7 |
| `alterwiki` | AlterWiki extension development against a local checkout. | 1 |
| `research` | Research and reading sessions, base tools only. | 0 |
| `work` | Separate working context, base tools only. | 0 |
| `pi-profiles` | Working on the `pi-profile` wrapper itself. | 0 |

The zero-package profiles still load `profile-badge` from `extensions/`, which
shows the active profile in the footer.

## Install a profile

Profiles are directories here, not repos of their own, so install from a local
checkout:

```sh
pi-profile install ./profiles/marathon marathon    # campaign profile
pi-profile install ./profiles/daily daily          # interactive driver
pi-profile create work                            # nothing saved yet: empty
```

`install` copies the portable whitelist (`settings.json`, `DESCRIPTION.md`,
`APPEND_SYSTEM.md`, `sol-pi.json`, `skills/`, `prompts/`, `extensions/`). Anything
beside it must be placed by hand. Packages re-fetch from npm/git on first launch
using `pool/` as the version reference. After installing, verify with a trivial
headless run before trusting a campaign to it.

The GitHub form needs the profile packed and pushed as its own repo first, which
is what `pack` prepares:

```sh
pi-profile pack marathon ./pi-marathon
cd ./pi-marathon && git init -b main && git add -A && git commit -m 'pack: marathon'
pi-profile install you/pi-marathon marathon
```

## Placeholders

No profile here contains a personal path. Three placeholders stand in for
machine-specific locations, documented with dummy values in `.env.example`:

| Placeholder | Used by | Meaning |
| --- | --- | --- |
| `${AGENTS_SKILLS_DIR}` | `marathon` | Your `~/.agents/skills` store, as an exclude pattern |
| `${PI_PROFILES_DIR}` | `research`, `work`, `pi-profiles`, `SoL-Pi` | A checkout of this repo, for `profile-badge.ts` |
| `${ALTERWIKI_DIR}` | `alterwiki` | A checkout of the AlterWiki extension |

Pi does not expand environment variables in settings, so replace each one with
the absolute path in `~/.pi/profiles/<name>/settings.json` after installing. Pi
does expand `~`, and the exclude pattern needs an absolute path, so
`!~/...` will not match.

## pool/ — package versions

`pool/package.json` and `pool/package-lock.json` record the versions the profiles
were last run against, including the `overrides` that pin
`@modelcontextprotocol/sdk` and `undici` past known advisories. A fresh pool
starts clean with:

```sh
mkdir -p ~/.pi/profiles/.shared/npm
cp pool/package.json pool/package-lock.json ~/.pi/profiles/.shared/npm/
cd ~/.pi/profiles/.shared/npm && npm install
```

That reproduces the tested versions instead of whatever npm resolves today. Then `pi-profile clean-lock --check` confirms the lockfile has no ghost entries.

A weekly workflow (`pool-refresh.yml`) proposes the newest versions as a PR, built by `pool/refresh.sh`; merge it once `pi-profile update` has run them. pi rewrites the live pool's `package.json` on every update and drops `overrides`, so those pins hold only for a pool built from these files.

## marathon — unattended campaigns

Stack: `/goal` (intent) + Ralph loop (execution) + `pi-tasks` (durable plans)
+ `pi-nolo` (approvals) + `@plicara/pi-audit-loop` (review gate). Doctrine in
`APPEND_SYSTEM.md`.

Interactive run (use tmux if you want to detach):

```
/goal --tokens 200k <objective with acceptance criteria>
/yolo full
/ralph --path ./task-dir
```

Headless:

```sh
pi-profile marathon -p "/ralph --path ./task-dir"
pi-profile marathon -p "/goal --tokens 50k <objective>"
```

Task dir anatomy (`/ralph-scaffold --preset fix-tests my-task` starts one):

```
task-dir/
├── RALPH.md            # YAML frontmatter (config) + Markdown body (prompt)
└── OPEN_QUESTIONS.md   # REQUIRED — must exist with no P0/P1 items, or the
                        # completion gate blocks forever
```

Frontmatter essentials: `max_iterations`, `timeout` (seconds per iteration),
`completion_promise` (done marker), `required_outputs` (files that must exist),
`guardrails.block_commands` (always `git push`), `guardrails.protected_files`
(always secrets). One task per iteration, one commit per iteration.

Monitor with `/ralph-status --summary`, stop gracefully with `/ralph-stop`,
kill with `/ralph-cancel`. Morning routine: run the suite yourself, read
`RALPH_PROGRESS.md` + `BUGS_FOUND.md` first, review commit-by-commit, revert
ruthlessly, squash-merge survivors.

Safety contract: worktrees only (never the main checkout), token budgets on
goals, `max_iterations` on loops, blocked/budget-hit/no-progress means
report-and-stop. Proven: 12→26 tests, 87%→100% coverage, ~15 min, zero
interventions, zero scope violations.

## SoL-Pi — efficiency evaluation (standalone)

NVIDIA's [SoL-Pi](https://github.com/NVlabs/SoL-Pi) (`0.1.0`) and nothing else,
with conservative `sol-pi.json`: Action Fusion + ObservationPack on, reducer +
context compact off. Use it for long **single sessions** (no loops needed) — that
is what SoL-Pi is built for.

This profile used to be the marathon stack plus SoL-Pi. That was a mistake, and
it invalidated the first trial: the extra packages changed what was being
measured. `pi-nolo` re-registers the builtin `edit` tool, holds the `edit` slot
ahead of SoL-Pi, and drops Action Fusion's `then_run` parameter, so fusion never
fired on `edit` calls for the entire trial. That profile is deleted, and this one
declares only SoL-Pi.

Never load `pi-nolo` next to SoL-Pi: both register `edit` and the first one loaded
keeps the slot, on 0.84.2 and 0.85.1 alike. The same goes for any extension that
re-registers `edit`, `write` or `bash` from Pi's builtin definitions.

Re-measured 2026-09-12 against stock Pi 0.85.1: with a natural prompt the model
never opts into `then_run` (0 of 6 runs), so the profile is ObservationPack plus
about 14% extra prompt overhead on small tasks. When the prompt asks for the
fusion it fires every time and saves a turn (4 to 3 turns, -21.6% and -12.7%
tokens). Large-context results were too noisy at 3 pairs to call.

`sol-pi.json` is inside `pi-profile pack`'s whitelist, so installing the profile
ships it automatically — no manual copy step.

Config resolution is profile-scoped (verified in SoL-Pi source: it resolves
via `getAgentDir()`), so nothing leaks into base. Provenance and trial notes
live in `harness-configs` `SOURCES.md` under "sol-pi".

## Rebuilding on a new machine

What git restores: this repo (launcher, every profile definition, `pool/`
versions), `harness-configs` (base agent settings, shared skills, `profile-badge`
source), and `dotfiles` (Brewfile, shell config).

What git cannot restore, and must be redone:

1. **Credentials.** `auth.json` and `models-store.json` are symlinks to the base
   agent dir and are never committed. Log in to each provider again. API keys
   that live in profile files instead (`basic/web-search.json` holds an Exa key)
   have to be re-entered.
2. **Skills outside git.** 9 of 20 store skills live in `harness-configs`. The
   rest come from upstream sources recorded in `~/.agents/.skill-lock.json`
   (`mattpocock/skills`, `anthropics/skills`, `openai/skills`,
   `obra/superpowers`, `vercel-labs/agent-skills`); reinstall them from there.
3. **App-managed extensions.** Orca, herdr and cmux install their own extensions
   into `~/.pi/agent/extensions/`. Reinstalling the app re-adds them.
4. **Placeholders.** Fill in `AGENTS_SKILLS_DIR`, `PI_PROFILES_DIR` and
   `ALTERWIKI_DIR` per `## Placeholders` above.

Suggested order:

```sh
# 1. tools and dotfiles
brew bundle --file ~/Documents/Projects/dotfiles/Brewfile

# 2. base agent config (settings, shared skills, profile-badge)
cd ~/Documents/Projects/harness-configs && ./install.sh

# 3. the launcher and the package pool
cd ~/Documents/Projects/pi-profiles
ln -s "$PWD/bin/pi-profile" ~/.local/bin/pi-profile
git config core.hooksPath .githooks
mkdir -p ~/.pi/profiles/.shared/npm
cp pool/package.json pool/package-lock.json ~/.pi/profiles/.shared/npm/
(cd ~/.pi/profiles/.shared/npm && npm install)

# 4. profiles, then credentials
pi-profile install ./profiles/daily daily
pi-profile install ./profiles/marathon marathon
# ... repeat for the profiles you use, then log in to each provider once
pi-profile daily                 # verify: one trivial prompt per profile
```
