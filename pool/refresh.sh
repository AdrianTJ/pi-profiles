#!/usr/bin/env bash
# Move pool/ to the newest published version of every package and re-lock.
# Run weekly by .github/workflows/pool-refresh.yml; safe to run by hand.
#
# Each dependency range becomes ^<latest>; `overrides` are deliberate pins and
# are left alone. Only package.json and package-lock.json change, and no
# package code runs (--package-lock-only, --ignore-scripts). Prints one line
# per changed range.
set -euo pipefail
cd "$(dirname "$0")"

node - <<'EOF'
const fs = require("fs");
const { execFileSync } = require("child_process");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
const changes = [];
for (const [name, range] of Object.entries(pkg.dependencies || {})) {
  const latest = execFileSync("npm", ["view", name, "version"], { encoding: "utf8" }).trim();
  const next = "^" + latest;
  if (range !== next) {
    changes.push(`${name}: ${range} -> ${next}`);
    pkg.dependencies[name] = next;
  }
}
fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
console.log(changes.length ? changes.join("\n") : "every range already at latest");
EOF

# update, not install: transitive dependencies move to their newest in-range
# versions too, not just the direct ones.
npm update --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null
