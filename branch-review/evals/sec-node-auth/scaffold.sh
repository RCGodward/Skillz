#!/usr/bin/env bash
# Checklist bullets planted here: C14 C15 C17 C18 C19 C24 C35 C36 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/routes src/ui
printf 'export const db: any = {};\n' > src/db.ts
cat > src/auth.ts <<'TS'
export function requireAuth(req: any, res: any, next: () => void) {
  if (!req.session?.userId) return res.status(401).end();
  next();
}
TS
cat > src/routes/documents.ts <<'TS'
import {Router} from 'express';
import {db} from '../db';
import {requireAuth} from '../auth';

export const documents = Router();

documents.get('/api/documents/:id', requireAuth, async (req, res) => {
  const doc = await db.documents.get(req.params.id);
  if (!doc || doc.ownerId !== req.session.userId) return res.status(404).end();
  res.json(doc);
});
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/billing-portal
cat > src/routes/billing.ts <<'TS'
import {Router} from 'express';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import {db} from '../db';
import {requireAuth} from '../auth';

export const billing = Router();

billing.post('/login', async (req, res) => {
  const user = await db.auth.check(req.body.email, req.body.password);
  if (!user) return res.status(401).end();
  req.session.userId = user.id;
  req.session.role = user.role;
  res.json({ok: true});
});

billing.get('/api/invoices/:id', requireAuth, async (req, res) => {
  res.json(await db.invoices.get(req.params.id));
});

billing.delete('/api/projects/:id', requireAuth, async (req, res) => {
  await db.projects.remove(req.params.id);
  res.status(204).end();
});

billing.post('/api/refunds', requireAuth, async (req, res) => {
  if (req.headers['x-user-role'] !== 'finance') return res.status(403).end();
  await db.refunds.create(req.body);
  res.status(201).end();
});

billing.get('/api/partner/statement', async (req, res) => {
  const claims: any = jwt.decode(String(req.headers.authorization).replace('Bearer ', ''));
  res.json(await db.statements.forPartner(claims.partnerId));
});

billing.post('/api/password-reset', async (req, res) => {
  const token = Math.random().toString(36).slice(2);
  await db.resets.create({email: req.body.email, token});
  res.status(202).end();
});

billing.post('/webhooks/payments', async (req, res) => {
  const expected = crypto.createHmac('sha256', process.env.WEBHOOK_SECRET!).update(req.rawBody).digest('hex');
  if (req.headers['x-signature'] !== expected) return res.status(401).end();
  await db.payments.record(req.body);
  res.status(204).end();
});

billing.post('/api/wallet/withdraw', requireAuth, async (req, res) => {
  const wallet = await db.wallets.get(req.session.userId);
  const amount = Number(req.body.amount);
  if (wallet.balance >= amount) {
    await db.payouts.send(req.session.userId, amount);
    await db.wallets.update(req.session.userId, {balance: wallet.balance - amount});
  }
  res.json({ok: true});
});
TS
cat > src/ui/projects.tsx <<'TSX'
export function ProjectRow({project, user}: {project: any; user: any}) {
  return (
    <tr>
      <td>{project.name}</td>
      {/* Only admins may delete projects. */}
      {user.role === 'admin' && <td><button data-delete={project.id}>Delete</button></td>}
    </tr>
  );
}
TSX
git add -A
git commit -qm "billing portal"
