#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixture.sh"
mkdir -p src
cat > src/users.ts <<'TS'
export function displayName(user: {first: string; last?: string}): string {
  return user.last ? `${user.first} ${user.last}` : user.first;
}
TS
git add -A
git commit -qm "initial"
# A remote inside .git, so origin/HEAD resolves without leaving the fixture.
git init -q --bare .git/origin.git
git remote add origin .git/origin.git
git push -q origin main
git remote set-head origin main
git checkout -qb feat/initials
cat > src/users.ts <<'TS'
export function displayName(user: {first: string; last?: string}): string {
  return user.last ? `${user.first} ${user.last}` : user.first;
}

export function initials(user: {first: string; last?: string}): string {
  return (user.first[0] + user.last[0]).toUpperCase();
}
TS
git add -A
git commit -qm "add initials"
cat > src/avatar.ts <<'TS'
import {initials} from './users';

export function avatarAlt(user: {first: string; last?: string}): string {
  return `Avatar for ${initials(user)}`;
}
TS
git add -A
git commit -qm "use initials in avatar"
