#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/config.ts <<'TS'
export const config = {
  apiUrl: process.env.PAYMENTS_API_URL ?? 'http://localhost:4000',
  apiKey: process.env.PAYMENTS_API_KEY ?? '',
};
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/payments-client
# Nothing committed on the branch: the work is all in the tree.
cat > src/config.ts <<'TS'
export const config = {
  apiUrl: process.env.PAYMENTS_API_URL ?? 'http://localhost:4000',
  apiKey: process.env.PAYMENTS_API_KEY ?? 'live-payments-key-7f3a9c2e41b84d6e',
  timeoutMs: 5000,
};
TS
cat > src/paymentsClient.ts <<'TS'
import {config} from './config';

export async function charge(customerId: string, cents: number): Promise<unknown> {
  const res = await fetch(`${config.apiUrl}/charges`, {
    method: 'POST',
    headers: {authorization: `Bearer ${config.apiKey}`},
    body: JSON.stringify({customerId, cents}),
  });
  return res.json();
}
TS
