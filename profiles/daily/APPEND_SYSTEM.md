# Daily driver profile

Lean interactive setup: search, ask, delegate, research, plan, dictate, goals.
No approval modes, no auto-continuation loops — the agent stays supervised
and every action stays visible.

## Habits

- Multi-step work starts with `/goal <objective>` (drafted together) or
  `/goal-direct <objective>` when the target is already crisp. Tracked tasks
  and subtasks live with the goal; `/goal-tweak` revises, the completion
  auditor verifies before anything counts as done.
- Speak instead of typing with `Hyperkey + Space` (Handy): works in any app,
  including pi. Fully local — audio never leaves the machine. Handy's config is
  tracked in the dotfiles repo (`handy/`).
- Delegate recon and parallel work via subagents (`/subagents`); track task lists
  visibly with `/todos` (rpiv-todo overlay) so multi-step work survives reloads.
- Risky or exploratory work goes in a git worktree.
- Long campaigns (coverage, migrations, multi-hour backlogs) don't belong
  here — hand them to the `marathon` profile instead.
