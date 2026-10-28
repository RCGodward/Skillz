#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/format.ts <<'TS'
export function percent(n: number): string {
  return `${(n * 100).toFixed(1)}%`;
}
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/stats
cat > src/stats.ts <<'TS'
export function mean(xs: number[]): number {
  return xs.reduce((a, b) => a + b, 0) / xs.length;
}

export function median(xs: number[]): number {
  const sorted = [...xs].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}
TS
git add -A
git commit -qm "add mean and median"

# The log the resumed session's earlier turn wrote, where its BRANCH_REVIEW_LOG_DIR put it:
# inside .git/, so graders can read it and it never shows up in the diff under review.
mkdir -p .git/branch-review-log
cp "$(dirname "${BASH_SOURCE[0]}")/history-log.md" .git/branch-review-log/2026-10-28-cwd-feat-stats-170012.md
