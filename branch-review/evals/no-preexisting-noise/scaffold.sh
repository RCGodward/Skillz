#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/report.ts <<'TS'
export function formatRow(values: string[]): string {
  return values.join(',');
}

// Pre-existing, untouched by the branch: a hand-rolled retry with no backoff.
export async function fetchWithRetry(url: string): Promise<string> {
  for (let i = 0; i < 5; i++) {
    try {
      const res = await fetch(url);
      return await res.text();
    } catch {}
  }
  throw new Error('failed');
}
TS
git add -A
git commit -qm "initial"
git checkout -qb fix/escaping
cat > src/report.ts <<'TS'
export function formatRow(values: string[]): string {
  return values.map(escapeField).join(',');
}

function escapeField(value: string): string {
  if (!/[",\n]/.test(value)) {
    return value;
  }
  return `"${value.replace(/"/g, '""')}"`;
}

// Pre-existing, untouched by the branch: a hand-rolled retry with no backoff.
export async function fetchWithRetry(url: string): Promise<string> {
  for (let i = 0; i < 5; i++) {
    try {
      const res = await fetch(url);
      return await res.text();
    } catch {}
  }
  throw new Error('failed');
}
TS
git add -A
git commit -qm "escape csv fields"
