#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
# No main, master, develop or trunk anywhere, and no remote.
git checkout -qb release-2024
mkdir -p src
printf 'export const version = "1.0.0";\n' > src/version.ts
git add -A
git commit -qm "release 1.0"
git checkout -qb hotfix-login
printf 'export const version = "1.0.1";\n' > src/version.ts
printf 'export const loginTimeoutMs = 0;\n' > src/login.ts
git add -A
git commit -qm "hotfix"
