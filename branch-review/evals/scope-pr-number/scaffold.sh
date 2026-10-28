#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/export.ts <<'TS'
export function toCsvRow(values: string[]): string {
  return values.map((v) => (/[",\n]/.test(v) ? `"${v.replace(/"/g, '""')}"` : v)).join(',');
}
TS
git add -A
git commit -qm "initial"
# PR #42's head lives on a branch; the checkout stays on main, as it would for a reviewer
# who was handed a PR number.
git checkout -qb feat/export-totals
cat > src/totals.ts <<'TS'
export function averageOrderValue(totals: number[]): number {
  return totals.reduce((a, b) => a + b, 0) / totals.length;
}
TS
git add -A
git commit -qm "add average order value"
git checkout -q main
# Unrelated work on main that is NOT part of PR #42.
printf '\nexport const CSV_MIME = "text/csv";\n' >> src/export.ts
git commit -qam "csv mime constant"

# A stand-in for the GitHub CLI: answers for PR #42 from the local branch, and fails for
# anything else, like gh would for a PR that doesn't exist.
mkdir -p .git/eval-bin
cat > .git/eval-bin/gh <<'GH'
#!/usr/bin/env bash
case "$*" in
  "pr diff 42"*)       exec git diff main...feat/export-totals ;;
  "pr view 42"*)       echo '{"number":42,"title":"Add average order value","headRefName":"feat/export-totals","baseRefName":"main","state":"OPEN"}' ;;
  "pr checkout 42"*)   exec git checkout -q feat/export-totals ;;
  *)                   echo "gh (eval stand-in): unsupported: $*" >&2; exit 1 ;;
esac
GH
chmod +x .git/eval-bin/gh
