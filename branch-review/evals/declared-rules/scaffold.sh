#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/api src/legacy
cat > CONTRIBUTING.md <<'MD'
# Contributing

- Log through `log` from `src/log.ts`. Never call `console.*` directly; the log
  pipeline redacts customer emails and `console` output bypasses it.
MD
printf '{\n  "singleQuote": true\n}\n' > .prettierrc
cat > src/log.ts <<'TS'
export const log = {error: (msg: string, meta?: object) => {}};
TS
cat > src/api/orders.ts <<'TS'
import {log} from "../log";
import {db} from "../db";

export async function getOrder(id: string) {
  try {
    return await db.orders.find(id);
  } catch (err) {
    log.error("order lookup failed", {id, err});
    throw err;
  }
}
TS
cat > src/api/customers.ts <<'TS'
import {log} from "../log";
import {db} from "../db";

export async function getCustomer(id: string) {
  try {
    return await db.customers.find(id);
  } catch (err) {
    log.error("customer lookup failed", {id, err});
    throw err;
  }
}
TS
cat > src/legacy/reports.ts <<'TS'
import {db} from "../db";

export function getReport(id: string) {
  return db.reports.find(id).then((r: any) => r ?? null);
}
TS
printf 'export const db: any = {};\n' > src/db.ts
git add -A
git commit -qm "initial"
git checkout -qb feat/refunds
cat > src/api/refunds.ts <<'TS'
import {db} from "../db";

export function getRefund(id: string, email: string) {
  return db.refunds.find(id).catch((err: unknown) => {
    console.error("refund lookup failed", {id, email, err});
    throw err;
  });
}
TS
git add -A
git commit -qm "add refunds api"
