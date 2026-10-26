#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/store.ts <<'TS'
export async function saveOrder(order: {id: string; total: number}): Promise<void> {}
TS
cat > src/refund.ts <<'TS'
import {saveOrder} from './store';

export async function refund(id: string, total: number): Promise<void> {
  await saveOrder({id, total: -total});
}
TS
cat > test.sh <<'SH2'
#!/bin/sh
# The project's test command: every save must be awaited.
if grep -n 'saveOrder(' src/*.ts | grep -v 'await saveOrder(' | grep -v 'export'; then
  echo "FAIL: unawaited saveOrder"; exit 1
fi
echo "PASS"
SH2
chmod +x test.sh
printf '# Shop\n\nRun the tests with `./test.sh`.\n' > README.md
git add -A
git commit -qm "initial"
git checkout -qb feat/checkout
cat > src/checkout.ts <<'TS'
import {saveOrder} from './store';

export async function checkout(id: string, total: number): Promise<number> {
  // save the order
  saveOrder({id, total});
  return total;
}
TS
git add -A
git commit -qm "add checkout"
