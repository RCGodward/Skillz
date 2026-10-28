#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/pricing.ts <<'TS'
export function lineTotal(qty: number, unitCents: number, discountCents: number): number {
  return qty * unitCents - discountCents;
}
TS
cat > src/store.ts <<'TS'
export async function saveOrder(order: {id: string; total: number}): Promise<void> {}
TS
cat > src/cart.ts <<'TS'
import {lineTotal} from './pricing';
import {saveOrder} from './store';

export async function checkout(id: string, qty: number, unitCents: number): Promise<number> {
  const total = lineTotal(qty, unitCents, 0);
  await saveOrder({id, total});
  return total;
}
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/bulk-orders
cat > src/bulk.ts <<'TS'
import {lineTotal} from './pricing';
import {saveOrder} from './store';

type Line = {qty: number; unitCents: number; discountCents?: number};

export async function bulkOrder(id: string, lines: Line[]): Promise<number> {
  const total = lines.reduce(
    (sum, l) => sum + lineTotal(l.qty, l.unitCents, l.discountCents ?? 0),
    0,
  );
  saveOrder({id, total});
  return total;
}
TS
git add -A
git commit -qm "add bulk orders"

# The log the resumed session's earlier turn wrote, where its BRANCH_REVIEW_LOG_DIR put
# it: a git-ignored folder inside the checkout, so graders can read it and it never
# shows up in the diff. (Not .git/: Claude Code denies Bash writes there.)
echo ".review-logs/" >> .git/info/exclude
mkdir -p .review-logs
cp "$(dirname "${BASH_SOURCE[0]}")/history-log.md" .review-logs/2026-10-28-cwd-feat-bulk-orders-170012.md
