#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
# logout() sits far below the code the branch changes, outside any diff hunk.
cat > src/sessions.ts <<'TS'
const sessions = new Map<string, {userId: string; expiresAt: number}>();

export function login(token: string, userId: string): void {
  sessions.set(token, {userId, expiresAt: Date.now() + 3_600_000});
}

export function lookup(token: string): string | undefined {
  const s = sessions.get(token);
  return s && s.expiresAt > Date.now() ? s.userId : undefined;
}

export function sessionCount(): number {
  return sessions.size;
}

export function pruneExpired(now = Date.now()): number {
  let removed = 0;
  for (const [token, s] of sessions) {
    if (s.expiresAt <= now) {
      sessions.delete(token);
      removed++;
    }
  }
  return removed;
}

export function describe(token: string): string {
  const s = sessions.get(token);
  return s ? `${s.userId} until ${new Date(s.expiresAt).toISOString()}` : 'none';
}

// Every session store must be cleared here, or a logged-out token keeps working.
export function logout(token: string): void {
  sessions.delete(token);
}
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/remember-me
python3 - <<'PY'
p = "src/sessions.ts"
s = open(p).read()
s = s.replace('''const sessions = new Map<string, {userId: string; expiresAt: number}>();
''', '''const sessions = new Map<string, {userId: string; expiresAt: number}>();
const remembered = new Map<string, string>();
''')
s = s.replace('''export function lookup(token: string): string | undefined {
  const s = sessions.get(token);
  return s && s.expiresAt > Date.now() ? s.userId : undefined;
}''', '''export function rememberMe(token: string, userId: string): void {
  remembered.set(token, userId);
}

export function lookup(token: string): string | undefined {
  const s = sessions.get(token);
  if (s && s.expiresAt > Date.now()) return s.userId;
  return remembered.get(token);
}''')
open(p, "w").write(s)
PY
git commit -qam "remember-me sessions"
