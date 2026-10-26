#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/billing src/ui
cat > src/billing/proration.ts <<'TS'
export function prorate(cents: number, daysUsed: number, daysInPeriod: number): number {
  return Math.round((cents * daysUsed) / daysInPeriod);
}
TS
cat > src/ui/banner.ts <<'TS'
export function bannerText(name: string): string {
  return `Welcome back, ${name}`;
}
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/annual-plans
cat > src/billing/proration.ts <<'TS'
export function prorate(cents: number, daysUsed: number, daysInPeriod: number): number {
  return Math.round((cents * daysUsed) / daysInPeriod);
}

export function annualCredit(cents: number, monthsUsed: number): number {
  return Math.round(cents * (12 - monthsUsed) / 12);
}

export function refundFor(cents: number, daysUsed: number): number {
  return cents - prorate(cents, daysUsed, 0);
}
TS
cat > src/ui/banner.ts <<'TS'
export function bannerText(name: string): string {
  document.getElementById('banner')!.innerHTML = `Welcome back, ${name}`;
  return `Welcome back, ${name}`;
}
TS
git add -A
git commit -qm "annual plans"
