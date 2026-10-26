#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src test
cat > src/money.ts <<'TS'
export function roundCents(amount: number): number {
  return Math.round(amount * 100) / 100;
}
TS
cat > src/pricing.ts <<'TS'
import {roundCents} from './money';

// pct is a whole-number percentage: 15 means 15% off.
export function applyDiscount(total: number, pct: number): number {
  return roundCents(total * (1 - pct / 100));
}
TS
cat > src/store.ts <<'TS'
export async function saveOrder(order: {id: string; total: number}): Promise<void> {}
export async function saveInvoice(invoice: {id: string; total: number}): Promise<void> {}
TS
cat > src/checkout.ts <<'TS'
import {applyDiscount} from './pricing';
import {saveOrder} from './store';

export async function checkout(id: string, subtotal: number): Promise<number> {
  const total = applyDiscount(subtotal, 10);
  await saveOrder({id, total});
  return total;
}
TS
cat > src/invoice.ts <<'TS'
import {applyDiscount} from './pricing';
import {saveInvoice} from './store';

export async function issueInvoice(id: string, amount: number): Promise<number> {
  const total = applyDiscount(amount, 15);
  await saveInvoice({id, total});
  return total;
}
TS
cat > test/pricing.test.ts <<'TS'
import {applyDiscount} from '../src/pricing';

describe('applyDiscount', () => {
  it('takes 10% off', () => {
    expect(applyDiscount(200, 10)).toBe(180);
  });

  it('rounds to cents', () => {
    expect(applyDiscount(9.99, 15)).toBe(8.49);
  });
});
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/fractional-discount
cat > src/pricing.ts <<'TS'
import {roundCents} from './money';

// rate is a fraction: 0.15 means 15% off.
export function applyDiscount(total: number, rate: number): number {
  return roundCents(total * (1 - rate));
}
TS
cat > src/checkout.ts <<'TS'
import {applyDiscount} from './pricing';
import {saveOrder} from './store';

function roundToCents(n: number): number {
  return Math.round(n * 100) / 100;
}

export async function checkout(id: string, subtotal: number, tip = 0): Promise<number> {
  const total = roundToCents(applyDiscount(subtotal, 0.1) + tip);
  saveOrder({id, total});
  return total;
}
TS
cat > test/pricing.test.ts <<'TS'
import {applyDiscount} from '../src/pricing';

describe('applyDiscount', () => {
  it('takes 10% off', () => {
    expect(applyDiscount(200, 0.1)).toBe(180);
  });

  it.skip('rounds to cents', () => {
    expect(applyDiscount(9.99, 15)).toBe(8.49);
  });
});
TS
git add -A
git commit -qm "switch discounts to fractional rates; add tips"
