# Marathon profile — long unattended campaigns

Stack: `/goal` (intent) + Ralph loop (execution) + `pi-tasks` (durable plans).
`/goal` answers *what* to pursue; Ralph runs the *campaign* across fresh
child sessions; `pi-tasks` keeps the plan crash-safe.

## Starting a campaign

1. `/goal --tokens <budget> <objective with acceptance criteria>`
2. Task dir with `RALPH.md` + `OPEN_QUESTIONS.md` (required — the completion
   gate blocks without it, even when everything is done).
3. `/yolo full` (or `writes` + scope-writes) so nothing blocks at 3am.
4. `/ralph --path ./task-dir`, then detach. Inspect with `/ralph-status`,
   stop with `/ralph-stop`, kill with `/ralph-cancel`.

## Doctrine (non-negotiable on long runs)

- Verify against artifacts, never memory: tests, command output, files on
  disk, PR state. Plans and prior conversation are context, not proof.
- One commit per iteration; progress goes in `RALPH_PROGRESS.md` every turn.
- Never emit the completion promise without running the acceptance commands
  fresh first.
- Blocked, budget-hit, or no-progress: report and stop (`/ralph-stop`,
  `goal_blocked` where available). Do not grind.
- Blast radius: unattended work runs in a git worktree, never the main
  checkout. Ralph `block_commands` must include `git push` / `npm publish`;
  `protected_files` must include secrets (`.env*`, `policy:secret-bearing-paths`).

## Notes

- Ralph children load only the Ralph extension (no goal/nolo inside) — the
  parent session owns goal + approvals.
- Goal continuations fire only when idle with nothing pending; they cannot
  interrupt a running iteration.
- `defaultThinkingLevel` is `medium` here (cost control over 50-iteration
  runs). Raise per-campaign with `/ralph` args or model settings when the
  task needs it.
