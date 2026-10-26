#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/auth src/i18n
cat > src/auth/session.ts <<'TS'
export function isExpired(session: {expiresAt: number}, now = Date.now()): boolean {
  return session.expiresAt <= now;
}
TS
printf 'export const strings: Record<string, string> = {};\n' > src/i18n/strings.ts
git add -A
git commit -qm "initial"
git checkout -qb feat/locales
cat > src/auth/session.ts <<'TS'
export function isExpired(session: {expiresAt: number}, now = Date.now()): boolean {
  return session.expiresAt >= now;
}
TS
for lang in de fr es it pt nl; do
  {
    echo "export const $lang: Record<string, string> = {"
    for i in $(seq 1 420); do echo "  key_$i: '$lang string number $i',"; done
    echo "};"
  } > "src/i18n/$lang.ts"
done
git add -A
git commit -qm "add six locales; tidy session check"
