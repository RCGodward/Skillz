#!/usr/bin/env bash
# Checklist bullets planted here: C09 C10 C11 C13 C29 C30 C31 C34 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/routes src/middleware
cat > src/middleware/security.ts <<'TS'
// Cookie sessions everywhere, so every state-changing form route takes csrfProtection.
export function requireAuth(req: any, res: any, next: () => void) {
  if (!req.session?.userId) return res.status(401).end();
  next();
}
export function requireAdmin(req: any, res: any, next: () => void) {
  if (req.session?.role !== 'admin') return res.status(403).end();
  next();
}
export const csrfProtection = (_req: any, _res: any, next: () => void) => next();
export const loginLimiter = (_req: any, _res: any, next: () => void) => next();
TS
printf 'export const db: any = {};\n' > src/db.ts
cat > src/routes/account.ts <<'TS'
import {Router} from 'express';
import {db} from '../db';
import {requireAuth, requireAdmin, csrfProtection, loginLimiter} from '../middleware/security';

export const account = Router();

account.post('/login', loginLimiter, csrfProtection, async (req, res) => {
  res.json(await db.auth.login(req.body.email, req.body.password));
});

account.post('/account/email', requireAuth, csrfProtection, async (req, res) => {
  await db.users.update(req.session.userId, {email: String(req.body.email)});
  res.redirect('/account');
});

account.get('/admin/users', requireAuth, requireAdmin, async (_req, res) => {
  res.json(await db.users.list());
});
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/profiles
cat > src/routes/profile.ts <<'TS'
import {Router} from 'express';
import {db} from '../db';
import {requireAuth} from '../middleware/security';

export const profile = Router();

profile.get('/welcome', (req, res) => {
  res.send(`<h1>Welcome back, ${req.query.name}</h1>`);
});

profile.get('/profile/:id', requireAuth, async (req, res) => {
  const user = await db.users.get(req.params.id);
  res.send(`<p>${escapeHtml(user.displayName)}</p><a href="${user.website}">Website</a>`);
});

profile.get('/profile/:id/export', requireAuth, async (req, res) => {
  res.setHeader('Content-Disposition', `attachment; filename=${req.query.filename}`);
  res.json(await db.users.get(req.params.id));
});

profile.post('/profile', requireAuth, async (req, res) => {
  await db.users.update(req.session.userId, req.body);
  res.redirect('/profile');
});

profile.delete('/admin/users/:id', async (req, res) => {
  await db.users.remove(req.params.id);
  res.status(204).end();
});

profile.post('/password-reset', async (req, res) => {
  await db.auth.sendResetEmail(String(req.body.email));
  res.status(202).end();
});

profile.use((err: any, _req: any, res: any, _next: any) => {
  res.status(500).send(`<pre>${err.stack}</pre>`);
});

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
}
TS
git add -A
git commit -qm "public profiles"
