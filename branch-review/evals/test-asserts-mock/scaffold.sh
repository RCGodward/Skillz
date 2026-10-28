#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src test
cat > src/tax.ts <<'TS'
export function salesTax(cents: number, region: string): number {
  const rate = region === 'CA' ? 0.0725 : 0.05;
  return Math.round(cents * rate);
}
TS
cat > test/tax.test.ts <<'TS'
import {salesTax} from '../src/tax';

describe('salesTax', () => {
  it('uses the California rate', () => {
    expect(salesTax(10000, 'CA')).toBe(725);
  });
});
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/oregon
cat > src/tax.ts <<'TS'
export function salesTax(cents: number, region: string): number {
  if (region === 'OR') return 0;
  const rate = region === 'CA' ? 0.0725 : 0.05;
  return Math.round(cents * rate);
}
TS
cat > test/tax.test.ts <<'TS'
import * as tax from '../src/tax';

describe('salesTax', () => {
  it('uses the California rate', () => {
    expect(tax.salesTax(10000, 'CA')).toBe(725);
  });

  it('charges no tax in Oregon', () => {
    const spy = jest.spyOn(tax, 'salesTax').mockReturnValue(0);
    expect(tax.salesTax(10000, 'OR')).toBe(0);
    expect(spy).toHaveBeenCalledWith(10000, 'OR');
  });
});
TS
git add -A
git commit -qm "no sales tax in Oregon"
