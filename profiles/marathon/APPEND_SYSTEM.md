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

- Verify against artifacts, never memory: tests, command output, files on disk, PR state. Plans and prior conversation are context, not proof. Where the artifact is a code review, the audit loop below is the mechanism for this rule.
- One commit per iteration; progress goes in `RALPH_PROGRESS.md` every turn.
- Never emit the completion promise without running the acceptance commands
  fresh first.
- Blocked, budget-hit, or no-progress: report and stop (`/ralph-stop`,
  `goal_blocked` where available). Do not grind.
- Blast radius: unattended work runs in a git worktree, never the main
  checkout. Ralph `block_commands` must include `git push` / `npm publish`;
  `protected_files` must include secrets (`.env*`, `policy:secret-bearing-paths`).

## Reviewing code: the audit loop

`@plicara/pi-audit-loop` is the mechanism version of the first doctrine rule. It alternates review and behaviour-preserving simplification, and a state machine owns the phase order rather than the model.

What it enforces that prose cannot: `audit_review(verdict=clean)` is refused unless the extension has observed the loop's `test_command` run successfully since the last change.

- Start with `audit_loop_start(scope, test_command)`. `scope` is a path, a diff range, or a description.
- `test_command` is the acceptance command. Without it the gate has nothing to check, so pass it on any campaign you care about.
- A loop ends four ways: a clean review, a no-op simplification, an exhausted round budget (default 3), or a manual stop. `budget_exhausted` means it stopped with findings open — read them rather than treating the loop as passed.

What it cannot enforce: the extension sees tool executions, not file contents, so it cannot tell a simplification from an ordinary edit. Review the diff after every simplification. `review_clean` means "no findings", never "nothing changed".

## Notes

- Ralph children load only the Ralph extension (no goal/nolo inside) — the
  parent session owns goal + approvals.
- Goal continuations fire only when idle with nothing pending; they cannot
  interrupt a running iteration.
- `defaultThinkingLevel` is `medium` here (cost control over 50-iteration
  runs). Raise per-campaign with `/ralph` args or model settings when the
  task needs it.
