#!/usr/bin/env bash
set -euo pipefail
bash "$(dirname "${BASH_SOURCE[0]}")/../security-trace/scaffold.sh"
# On top of the injection: a restating comment and an off-pattern name, so there is
# style and comment material for a review that ignored --security-only to report.
cat >> src/routes/users.ts <<'TS'

// get the user count
users.get('/users_count', requireAuth, async (req, res) => {
  const rows = await db.query('SELECT count(*) AS n FROM users');
  res.json(rows[0]);
});
TS
git add -A
git commit -qm "add count"
