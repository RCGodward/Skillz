---
date: 2026-10-28
client: Eval Fixture
repo: cwd
branch: feat/bulk-orders
base: main
language: typescript
files_changed: 1
lines_changed: 13
skill_version: 0.6.0
variant: skill
tool: claude-code
gate_held: yes
style_citations_ok:
---

<!-- disposition: applied | wrong | handled | preexisting | preference | not-worth-it | missed -->

| # | severity | category | disposition | note |
|---|---|---|---|---|
| 1 | blocker | correctness |  | saveOrder not awaited in bulkOrder |
| 2 | should-fix | correctness |  | redundant discountCents ?? 0 fallback |
| - |  |  | missed |  |
