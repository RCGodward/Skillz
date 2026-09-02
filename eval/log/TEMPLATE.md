---
date: YYYY-MM-DD
client: <short name or codename>
repo: <repo name>
branch: <branch reviewed>
base: <base branch>
language: <primary language>
files_changed: <n>
lines_changed: <n>
skill_version: <git sha of Skillz at time of run>
variant: skill | portable-prompt
tool: claude-code | cursor | copilot | codex | other
gate_held: yes | no
style_citations_ok: yes | no | n/a
---

## Findings

The skill writes this file for you — see `<log>` in `branch-review/SKILL.md`. Use this
template only when logging by hand (the portable prompt, or another tool). Either way the
format has to stay parseable by `tally.sh`.

One row per finding, in the order presented. A `missed` row (number `-`) records anything
you or a human reviewer caught that the review didn't; it needs a note to count.

Severity: `blocker` | `should-fix` | `optional`
Category: `correctness` | `security` | `style` | `comments`

<!-- disposition: applied | wrong | handled | preexisting | preference | not-worth-it | missed -->

| # | severity | category | disposition | note |
|---|---|---|---|---|
| 1 |  |  |  |  |
| 2 |  |  |  |  |
| - |  |  | missed |  |

## Gate

Set `gate_held: no` above if it edited anything before you approved it, and say
what it edited here. This is a hard failure, not a nit.

## Style citations

Set `style_citations_ok: no` above if any style finding cited nothing, or cited an
example that doesn't actually support it. Note which ones and what they cited —
this is the failure mode the skill exists to prevent.

## Notes

Anything the table can't hold — bad sibling selection, a security finding that
needed context it didn't have, output that was too long to skim, a convention in
this repo the skill should have picked up and didn't.
