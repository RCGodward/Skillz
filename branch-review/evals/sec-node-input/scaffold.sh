#!/usr/bin/env bash
# Checklist bullets planted here: C02 C03 C08 C33 C37 C38 C40 (see the graders).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src/routes src/middleware src/util
cat > src/middleware/auth.ts <<'TS'
export function requireAuth(req: any, res: any, next: () => void) {
  if (!req.user) return res.status(401).end();
  next();
}
TS
cat > src/routes/health.ts <<'TS'
import {Router} from 'express';
import {requireAuth} from '../middleware/auth';

export const health = Router();

health.get('/health', requireAuth, (_req, res) => {
  res.json({ok: true});
});
TS
git add -A
git commit -qm "initial"
git checkout -qb feat/media-tools
cat > src/routes/media.ts <<'TS'
import {Router} from 'express';
import {exec} from 'child_process';
import path from 'path';
import {requireAuth} from '../middleware/auth';

const UPLOAD_DIR = '/srv/app/uploads';

export const media = Router();

// Thumbnails are made by ImageMagick on the host.
media.post('/media/thumbnail', requireAuth, (req, res) => {
  exec(`convert ${req.body.file} -resize 200x200 /tmp/thumb.png`, (err) => {
    if (err) return res.status(500).end();
    res.sendFile('/tmp/thumb.png');
  });
});

media.get('/media/files/:name', requireAuth, (req, res) => {
  res.sendFile(path.join(UPLOAD_DIR, req.params.name));
});

media.get('/media/preview', requireAuth, async (req, res) => {
  const upstream = await fetch(String(req.query.url));
  res.type(upstream.headers.get('content-type') ?? 'text/plain').send(await upstream.text());
});

media.get('/media/done', requireAuth, (req, res) => {
  res.redirect(String(req.query.next));
});

media.get('/media/search', requireAuth, (req, res) => {
  const pattern = new RegExp(String(req.query.q));
  res.json(CATALOG.filter((title) => pattern.test(title)));
});

media.get('/media/licenses', requireAuth, async (_req, res) => {
  const partner = await fetch('https://licensing.partner.example/v1/licenses');
  res.json(await partner.json());
});

const CATALOG = ['sunrise.jpg', 'harbor.png', 'forest.webp'];
TS
cat > src/util/settings.ts <<'TS'
export function deepMerge(target: any, source: any): any {
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object') {
      target[key] = deepMerge(target[key] ?? {}, source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
}
TS
cat > src/routes/prefs.ts <<'TS'
import {Router} from 'express';
import {requireAuth} from '../middleware/auth';
import {deepMerge} from '../util/settings';

export const prefs = Router();
const defaults = {theme: 'light', notifications: {email: true}};

prefs.post('/prefs', requireAuth, (req, res) => {
  res.json(deepMerge(defaults, JSON.parse(req.body.raw)));
});
TS
git add -A
git commit -qm "media tools and preferences"
