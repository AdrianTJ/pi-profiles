# Profile run guide

Two long-run profiles live here. Both install the same way:

```sh
pi-profile install <this-repo> marathon    # campaign profile
pi-profile install <this-repo> sol-trial   # efficiency trial profile
```

`install` copies the portable whitelist (`settings.json`, `APPEND_SYSTEM.md`).
Anything beside it must be placed by hand — see per-profile notes. Packages
re-fetch from npm/git on first launch. After installing, verify with a
trivial headless run before trusting a campaign to it.

## marathon — unattended campaigns

Stack: `/goal` (intent) + Ralph loop (execution) + `pi-tasks` (durable plans)
+ `pi-nolo` (approvals). Doctrine in `APPEND_SYSTEM.md`.

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

## sol-trial — SoL-Pi efficiency evaluation (standalone)

Same stack as marathon plus NVIDIA's
[SoL-Pi](https://github.com/NVlabs/SoL-Pi) (`0.1.0`), with conservative
`sol-pi.json`: Action Fusion + ObservationPack on, reducer + context compact
off. Use it for long **single sessions** (no loops needed) — that is what
SoL-Pi is built for.

Extra install step — `sol-pi.json` is outside `pi-profile pack`'s whitelist,
so copy it by hand after installing:

```sh
cp profiles/sol-trial/sol-pi.json ~/.pi/profiles/sol-trial/sol-pi.json
```

Config resolution is profile-scoped (verified in SoL-Pi source: it resolves
via `getAgentDir()`), so nothing leaks into base. Provenance and trial notes
live in `harness-configs` `SOURCES.md` under "sol-pi".

Known issue (diagnosed 2026-09-11, Pi 0.84.4): Action Fusion's `then_run`
follow-up does not execute — the model passes it, the edit applies, but the
fused command never runs and no `[then_run:*]` marker appears; the agent
re-runs the check itself. Pi's registry code shows extension tools overwrite
builtins by name, so registration is not the cause; the `then_run` argument
appears to be dropped between the model call and execution. Re-test after
upstream clarifies 0.84.2-vs-0.84.4 behavior before relying on Fusion.
