# marathon

Unattended campaigns: goal plus Ralph loop, durable plans, approval gating, and a machine-enforced code-review gate.

Use it when: work should run for hours without you, one task per iteration, one commit per iteration.

Note: `pi-nolo` gates `edit` and `bash` behind confirmation and re-registers both tools, which strips any parameters other extensions add to them. Do not add `NVlabs/SoL-Pi` style extensions that extend `edit` to this profile. The audit loop only adds its own `audit_*` tools and observes tool-execution events, so it does not collide with that re-registration. Run guide: `profiles/README.md`.
