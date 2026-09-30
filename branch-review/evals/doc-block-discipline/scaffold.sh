#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/orders.ts <<'TS'
import {Money} from './money';

export function orderTotal(lines: Line[]): Money {
  return lines.reduce((sum, l) => sum.plus(l.amount), Money.zero());
}

export function applyTax(total: Money, rate: number): Money {
  // Rates arrive as basis points from the tax service, not percent.
  return total.times(1 + rate / 10000);
}
TS
cat > src/money.ts <<'TS'
export class Money {
  private constructor(private readonly cents: number) {}
  static zero(): Money { return new Money(0); }
  plus(other: Money): Money { return new Money(this.cents + other.cents); }
  times(factor: number): Money { return new Money(Math.round(this.cents * factor)); }
}
TS
cat > src/lines.ts <<'TS'
import {Money} from './money';

export interface Line {
  sku: string;
  amount: Money;
}
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/discounts
cat > src/discounts.ts <<'TS'
import {Money} from './money';
import {Line} from './lines';

/**
 * Applies a percentage discount to a set of order lines.
 *
 * @param lines - The order lines to discount.
 * @param percent - The discount percentage to apply.
 * @returns The discounted total as a Money value.
 */
export function discountedTotal(lines: Line[], percent: number): Money {
  // Loop through the lines and add them up
  let total = Money.zero();
  for (const line of lines) {
    total = total.plus(line.amount);
  }
  return total.times(1 - percent / 100);
}
TS
git add -A
git commit -qm "add discounted total"
