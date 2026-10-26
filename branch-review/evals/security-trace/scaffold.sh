#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/routes src/middleware
cat > src/db.ts <<'TS'
export const db: {query(sql: string, params?: unknown[]): Promise<any[]>} = {} as any;
TS
cat > src/middleware/auth.ts <<'TS'
export function requireAuth(req: any, res: any, next: () => void) {
  if (!req.user) {
    return res.status(401).end();
  }
  next();
}
TS
cat > src/sorting.ts <<'TS'
const SORTABLE = ['name', 'email', 'created_at'] as const;

// Identifiers can't be bound as parameters, so sort columns are allowlisted instead.
export function sortColumn(input: unknown): string {
  return SORTABLE.includes(input as any) ? (input as string) : 'name';
}
TS
cat > src/routes/users.ts <<'TS'
import {Router} from 'express';
import {db} from '../db';
import {requireAuth} from '../middleware/auth';

export const users = Router();

users.get('/users/:id', requireAuth, async (req, res) => {
  const rows = await db.query('SELECT id, name, email FROM users WHERE id = $1', [req.params.id]);
  res.json(rows[0] ?? null);
});
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/user-search
cat > src/routes/users.ts <<'TS'
import {Router} from 'express';
import {db} from '../db';
import {requireAuth} from '../middleware/auth';
import {sortColumn} from '../sorting';

export const users = Router();

users.get('/users/:id', requireAuth, async (req, res) => {
  const rows = await db.query('SELECT id, name, email FROM users WHERE id = $1', [req.params.id]);
  res.json(rows[0] ?? null);
});

users.get('/users', requireAuth, async (req, res) => {
  const sort = sortColumn(req.query.sort);
  const rows = await db.query(
    `SELECT id, name, email FROM users WHERE name ILIKE '%${req.query.q}%' ORDER BY ${sort}`,
  );
  res.json(rows);
});
TS
git add -A
git commit -qm "add user search"
