---
name: branch-review
description: "Review the changes on a branch in one pass — correctness, security audit, conformance to the surrounding code's existing style, and comment/doc-block discipline — then present a numbered list of proposed corrections and wait for approval before editing anything. Use when asked to review a branch, diff, or PR; to security-audit pending changes; or to check that new code matches the house style of the codebase it landed in."
argument-hint: "[base-branch | PR# | path] [--fix] [--security-only] [--style-only]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
---

<objective>
Review the changes on this branch against **the standards of the codebase they were added to**,
not against any external style guide. Produce a numbered, reviewable list of proposed
corrections. Edit nothing until the user approves specific items.

Flow: resolve scope → learn the house style → four review passes → verify findings →
present list → **STOP** → apply only what was approved.
</objective>

<scope>
Resolve what to review, in this order:

1. `$ARGUMENTS` names a base branch (`main`, `develop`, `origin/release/2.1`) → diff against it.
2. `$ARGUMENTS` is a PR number → `gh pr diff <n>`; fall back to fetching the branch if `gh` is absent.
3. `$ARGUMENTS` is a path → restrict to files under it, still diffed against the base.
4. No arguments → find the base automatically:
   `git merge-base HEAD $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)`
   Try `origin/main`, `origin/master`, `origin/develop`, `origin/trunk` in order. If none
   resolve, ask which base to use — do not guess a base that produces a 400-file diff.
5. If the branch has no commits ahead of base, review uncommitted work instead
   (`git diff HEAD` plus `git status --porcelain` for untracked files) and say that's what you did.

Then get the review surface:
- `git diff --stat <base>...HEAD` — size check.
- `git diff <base>...HEAD` — the changes themselves.
- Read the **full current version** of every substantially-changed file. A diff hunk hides
  the surrounding contract: the helper that already exists, the validation two functions up,
  the disposal pattern the rest of the class uses. Most false findings come from reviewing
  hunks instead of files.

If the diff exceeds ~2000 changed lines, say so, review the highest-risk files first
(auth, data access, input handling, money, migrations, config), and tell the user what
you deferred.
</scope>

<house_style>
**Do this before judging anything.** The whole point of this review is that the code should
look like it belongs where it is. You cannot assess that until you know what "there" looks like.

Gather evidence, cheapest first:

1. **Declared rules** — read whatever exists: `.editorconfig`, `.eslintrc*`, `biome.json`,
   `.prettierrc`, `.stylecop.json`, `.editorconfig`, `ruff.toml`/`pyproject.toml`,
   `.rubocop.yml`, `checkstyle.xml`, `Directory.Build.props`, `CONTRIBUTING.md`,
   `CLAUDE.md`/`AGENTS.md`, `docs/style*`. Declared rules outrank inferred ones.
2. **Sibling files** — for each changed file, read 2–3 existing files that are its closest
   analogs (same directory, same layer, same suffix: another controller, another repository,
   another reducer, another test). These are your ground truth.
3. **The file's own history** — `git log --oneline -5 -- <file>` and the pre-change version
   of the file. Code the branch *touched* should stay consistent with code it *didn't*.

From that evidence, note the conventions that actually apply here — naming, file/class layout,
error handling, logging, async style, null/optional handling, test structure, DI patterns,
string formatting, import ordering. Prefer what the code does over what a config claims,
where they disagree, and mention the disagreement.

**Hard rule:** every style finding must point at an existing example in this repo —
`Matches src/Services/OrderService.cs:40-58` — or it does not get reported. If you cannot
cite one, the convention is your preference, not theirs, and it is out of scope.

Corollary: where the codebase is internally inconsistent, the local neighborhood wins.
Say so instead of picking a side: "This directory uses X; the older modules use Y."
</house_style>

<passes>
Run all four over the diff. Skip security/style only if `--security-only` / `--style-only` was passed.

### 1. Correctness
Bugs the change introduces or fails to handle. Look for: off-by-one and boundary conditions;
null/undefined paths the new code opens; error paths that swallow, mislabel, or leak;
async issues (unawaited work, races, missing cancellation, sync-over-async); resource leaks
(connections, handles, subscriptions, timers); state mutated where the surrounding code
treats it as immutable; N+1 queries and unbounded loops over external calls; changed behavior
of a shared function whose *other* callers weren't updated — grep for them; contracts broken
for existing consumers (signature, serialization shape, DB schema, config keys);
tests that assert the mock rather than the behavior, or that were deleted/skipped quietly.

### 2. Security
Read `references/security-checklist.md` and work through the categories that apply to the
languages and surfaces in this diff. Report a finding only where you can name the untrusted
input and trace its path to the sink. Include severity and concrete impact.

### 3. Style conformance
Only against conventions evidenced in `<house_style>`. Typical real findings: a new class
that doesn't follow the layering/naming of its siblings; error handling invented here when
the codebase has an established pattern; a hand-rolled helper duplicating one that exists
(grep before claiming this); logging that skips the project's logger or structure;
tests shaped unlike the neighboring tests; formatting that a committed linter config
would reject.

Not findings: personal preferences, modern-idiom upgrades, patterns the whole codebase
would need to adopt, or reformatting untouched lines.

### 4. Comments and documentation
Two rules, applied strictly:

**Inline comments exist only to explain non-intuitive behavior.** Keep or add a comment
when it explains *why* — a workaround for a specific bug or API quirk, a non-obvious
constraint or invariant, a deliberate deviation, a chosen tradeoff, a regulatory or
business rule that isn't inferable from the code. Flag comments that restate what the
code plainly says, narrate the obvious (`// loop through items`), label sections that
naming should carry, are commented-out code, or have drifted out of sync with the code —
a stale comment is a bug report, not a nit.

**Doc-block comments follow the file's existing convention.** Before proposing or keeping
any XML doc block / JSDoc / docstring / KDoc, check prevalence:
- Does the file already use them? → match that, including which tags it actually uses.
- If not, do its closest siblings? → check 2–3, and note the ratio.
- Neither? → flag the new doc blocks as out of place and propose removing them.
Never add doc blocks to a file or area that doesn't have them, even on public APIs, and
even if a linter *could* be configured to want them. Existing doc blocks on code the
branch changed must be updated to match the new behavior — a doc block describing the old
signature is a finding.
</passes>

<verify>
Before writing the list, re-check each finding against the full file and the wider repo.
Drop anything you cannot defend. Specifically:
- Grep for the helper/validation/guard you're about to say is missing — it may exist upstream.
- Confirm the "unhandled" case isn't handled by a caller, a middleware, a filter, or an attribute.
- Confirm a "wrong" convention isn't the local majority.
- Re-read the hunk: is the line you're flagging actually part of this branch's changes?

Report nothing that already existed on the base branch unless it is a security issue or the
branch materially worsened it — say explicitly when a finding is pre-existing.

A short list of real findings is the deliverable. Padding it with nits costs the user more
than missing a nit does.
</verify>

<output>
Present findings as a numbered list, grouped by severity, most severe first. Number
continuously across groups so the user can reply "1, 4, 7".

Severity:
- **Blocker** — will break, corrupt data, or expose something. Merge shouldn't happen.
- **Should fix** — real bug in an edge case, contract drift, security hardening, or a
  clear break from house style.
- **Optional** — small consistency and comment items. Fine to skip.

Each finding, kept tight:

```
### 3. [Should fix] Unawaited save leaves the transaction open
`src/Services/OrderService.cs:112`
`ProcessAsync` is called without await, so the scope disposes before the write lands.
Every other method in this class awaits its repository call (see line 58).
Fix: `await _repo.ProcessAsync(order, ct);`
```

Show the proposed code when it's a line or two; describe it when it's larger. Cite the repo
example for every style finding. Do not paste the full corrected file.

Close with a short section:
- **Reviewed** — base, commit range, file count, and anything you deferred.
- **Looks good** — one line on what the change does well, if it does. Not filler; skip if empty.
- **Not changed** — pre-existing issues you noticed but left alone.
</output>

<approval_gate>
**Stop after presenting the list. Do not edit any file until the user replies.**

This is the point of the skill. No Edit, no Write, no `sed -i`, no "I went ahead and fixed
the trivial ones." Even a one-character fix waits.

End with: *"Reply with the numbers to apply (or 'all'), and I'll make just those changes."*

When the user replies:
- Apply exactly the approved items — nothing adjacent, no drive-by cleanups, no reformatting.
- If applying one reveals a second issue, fix only what was approved and mention the new one.
- If an approved fix turns out to be wrong on closer reading, say so instead of applying it.
- After applying: list what changed, run the project's existing test/build command if there
  is an obvious one, and report the result honestly — including failures.
- Leave rejected findings alone. Don't re-litigate them.

`--fix` in the arguments means the user pre-approved Blocker and Should-fix items: still
present the list first, then apply those, and leave Optional items for them to choose.
</approval_gate>

<notes>
- Client codebases differ hard. When this repo's convention conflicts with your instinct,
  the repo wins, silently — don't editorialize about the house style.
- If the repo has a `CLAUDE.md`/`AGENTS.md` with review or style rules, those outrank
  anything inferred here; follow them and say which rule you applied.
- Non-git directories: fall back to reviewing what the user points you at, and say the
  scope was manual.
</notes>
