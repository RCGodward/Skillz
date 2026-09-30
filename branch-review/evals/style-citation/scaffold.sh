#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/repositories
cat > src/repositories/orderRepository.ts <<'TS'
import {db} from '../db';
import {NotFoundError} from '../errors';

export class OrderRepository {
  async findById(tenantId: string, id: string) {
    const row = await db.orders.findFirst({where: {id, tenantId}});
    if (!row) {
      throw new NotFoundError(`order ${id}`);
    }
    return row;
  }
}
TS
cat > src/repositories/customerRepository.ts <<'TS'
import {db} from '../db';
import {NotFoundError} from '../errors';

export class CustomerRepository {
  async findById(tenantId: string, id: string) {
    const row = await db.customers.findFirst({where: {id, tenantId}});
    if (!row) {
      throw new NotFoundError(`customer ${id}`);
    }
    return row;
  }
}
TS
cat > src/errors.ts <<'TS'
export class NotFoundError extends Error {}
TS
cat > src/db.ts <<'TS'
export const db: any = {};
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/invoices
cat > src/repositories/invoice_repo.ts <<'TS'
import {db} from '../db';

export class InvoiceRepo {
  async get_invoice(id: string) {
    const row = await db.invoices.findFirst({where: {id}});
    if (!row) {
      return null;
    }
    return row;
  }
}
TS
git add -A
git commit -qm "add invoice repo"
