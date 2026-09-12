# SoL-Pi

SoL-Pi trial profile: Action Fusion and ObservationPack, nothing else.

Use it when: evaluating NVIDIA's SoL-Pi on real work, or comparing token use against stock pi. Keep it free of other extensions: anything that re-registers `edit`, `write` or `bash` silently disables Action Fusion's `then_run`.

Installed: `git:github.com/NVlabs/SoL-Pi` only, plus the shared badge extension. `sol-pi.json` turns Action Fusion and ObservationPack on, leaves the reducer and context compact off.

Measured 2026-09-12: fusion fires only when the model opts in. With `deepseek-v4-flash-0731` and a natural prompt it fired 0 of 6 runs, so on this backend the profile is ObservationPack plus roughly 14% extra prompt overhead on small tasks. Notes in `harness-configs/SOURCES.md` under "sol-pi".
