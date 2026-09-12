# marathon

Unattended campaigns: goal plus Ralph loop, durable plans, approval gating.

Use it when: work should run for hours without you, one task per iteration, one commit per iteration.

Installed: `@bacnh85/pi-fff`, `@jqwn/pi-ask-user-question`, `@narumitw/pi-btw`, `@dietrichgebert/ponytail`, `pi-subagents-lite`, `pi-tasks`, `pi-web-lite`, `@lnilluv/pi-ralph-loop`, `@xbear/pi-goal`, `pi-nolo`. Doctrine in `APPEND_SYSTEM.md`.

Note: `pi-nolo` gates `edit` and `bash` behind confirmation and re-registers both tools, which strips any parameters other extensions add to them. Do not add `NVlabs/SoL-Pi` style extensions that extend `edit` to this profile. Run guide: `profiles/README.md`.
