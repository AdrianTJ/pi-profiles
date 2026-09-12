# Daily driver profile

Lean interactive setup: search, ask, delegate, research, plan, dictate, goals.
No approval modes, no auto-continuation loops — the agent stays supervised
and every action stays visible.

## Habits

- Multi-step work starts with `/goal <objective>` (drafted together) or
  `/goal-direct <objective>` when the target is already crisp. Tracked tasks
  and subtasks live with the goal; `/goal-tweak` revises, the completion
  auditor verifies before anything counts as done.
- Speak instead of typing with `Hyperkey + Space` (pi-transcribe): toggle, talk,
  transcript lands in the editor for review before sending. Fully local — audio
  never leaves the machine; models and settings live in the profile's
  `pi-transcribe.json`.
- Delegate recon and parallel work via subagents (`/agents`); track task lists
  visibly with `/todos` (rpiv-todo overlay) so multi-step work survives reloads.
- Risky or exploratory work goes in a git worktree.
- Long campaigns (coverage, migrations, multi-hour backlogs) don't belong
  here — hand them to the `marathon` profile instead.
