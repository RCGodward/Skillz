#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/http.ts <<'TS'
/**
 * Fetches JSON, retrying on network errors.
 * @param url - Absolute URL to fetch.
 * @param attempts - How many times to try before giving up.
 * @returns The parsed response body.
 */
export async function getJson(url: string, attempts = 3): Promise<unknown> {
  // The gateway drops idle connections after 30s, so the first attempt after a
  // quiet period often fails; three tries covers that without masking an outage.
  for (let i = 1; ; i++) {
    try {
      return await (await fetch(url)).json();
    } catch (err) {
      if (i >= attempts) throw err;
    }
  }
}
TS
cat > src/urls.ts <<'TS'
/**
 * Joins a base URL and a path without doubling the slash.
 * @param base - Base URL, with or without a trailing slash.
 * @param path - Path, with or without a leading slash.
 * @returns The joined URL.
 */
export function joinUrl(base: string, path: string): string {
  return `${base.replace(/\/$/, '')}/${path.replace(/^\//, '')}`;
}
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/timeouts
cat > src/http.ts <<'TS'
/**
 * Fetches JSON, retrying on network errors.
 * @param url - Absolute URL to fetch.
 * @param attempts - How many times to try before giving up.
 * @returns The parsed response body.
 */
export async function getJson(url: string, timeoutMs: number, attempts = 5): Promise<unknown> {
  // The gateway drops idle connections after 30s, so the first attempt after a
  // quiet period often fails; three tries covers that without masking an outage.
  for (let i = 1; ; i++) {
    try {
      return await (await fetch(url, {signal: AbortSignal.timeout(timeoutMs)})).json();
    } catch (err) {
      if (i >= attempts) throw err;
    }
  }
}

export async function getText(url: string, timeoutMs: number): Promise<string> {
  return (await fetch(url, {signal: AbortSignal.timeout(timeoutMs)})).text();
}
TS
git add -A
git commit -qm "add timeouts; getText"
