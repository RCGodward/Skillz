# Instruction → criterion traceability

Every instruction in `branch-review/SKILL.md` (v0.5.0 at the start of this work), and the
eval grader that would fail if the instruction were deleted or ignored. An instruction
with no grader is either given one or cut — that is the load-bearing test.

Status: **✅ graded** · **◐ partial** (exercised by a fixture, but no grader fails if it's
ignored) · **❌ none**. `Action` is what this certification pass does about it.

Line numbers refer to SKILL.md as of 0.5.0.

## Objective (15–22)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| O1 | Judge against this codebase's standards, not an external guide | ✅ | `style-citation/style-findings-are-evidenced` |
| O2 | Produce a numbered list of corrections | ◐ | Graders refer to "numbered findings" but none checks numbering → **add output-format grader** |
| O3 | Edit nothing until the user approves | ✅ | `gate-held-nothing-edited` (every case) |
| O4 | Flow summary line | — | Restates the sections below; **cut** |

## Scope (24–48)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| S1 | Base-branch argument → diff against it | ✅ | Every case runs `/branch-review main` |
| S2 | PR number → `gh pr diff` | ❌ | Needs network + `gh`; untestable in the sandbox. Model does this unprompted → **cut to one clause** |
| S3 | Path argument → restrict to files under it | ❌ | **New case** `scope-path` |
| S4 | No args → find base via `origin/*`; ask if none resolve | ❌ | **New case** `scope-auto-base` (fixture has no remote) |
| S5 | No commits ahead → review uncommitted work, say so | ❌ | **New case** `scope-uncommitted` |
| S6 | Three-dot diff against merge-base | ◐ | `no-preexisting-noise` depends on it but doesn't assert it |
| S7 | Read full files, not just hunks | ◐ | Implied by `doc-block-discipline` sibling check |
| S8 | >2000 changed lines → say so, risk-first, list deferrals | ❌ | **New case** `large-diff-deferral` |

## House style (50–77)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| H1 | Learn style before judging | ◐ | Covered in effect by H3/H7 |
| H2 | Read declared rules (`.editorconfig`, linters…); they outrank inferred ones | ❌ | List has `.editorconfig` twice → **dedupe**; **add a lint config to a fixture** |
| H3 | Read 2–3 sibling files per changed file | ✅ | `style-citation` (citations must name siblings) |
| H4 | Read the file's own history | ❌ | **Cut** — no observable effect separate from S6/S7 |
| H5 | Note the conventions that apply (naming, errors, logging…) | ✅ | `style-citation` fixture diverges on naming + error handling |
| H6 | Code beats config when they disagree; mention it | ❌ | **Grader on the lint-config fixture** (H2) |
| H7 | **Every style finding cites `file:line` in this repo** | ✅ | `cites-a-file-and-line`, `style-findings-are-evidenced` |
| H8 | Inconsistent codebase → local neighborhood wins, say so | ❌ | **Grader on the lint-config fixture** or cut |

## Passes (79–128)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| P0 | Run all four passes; `--security-only` / `--style-only` | ❌ | **Grader**: `--security-only` run reports no style items |
| P1 | Correctness: boundaries, nulls, errors, async, leaks, N+1… | ❌ | **New case** `correctness-callers` (iteration 1) |
| P1b | Grep for other callers of a changed shared function | ❌ | Same case |
| P1c | Tests that assert the mock / quietly skipped | ❌ | Same case (skipped test) or cut |
| P2 | Security: work the checklist, trace input → sink | ◐ | Tenant scope in `style-citation`; **new case** `security-trace` (iteration 1) |
| P3 | Style conformance against evidenced conventions | ✅ | `style-citation` |
| P3b | Hand-rolled helper duplicating an existing one | ❌ | Add to `correctness-callers` fixture or cut |
| P3c | Not findings: preferences, idiom upgrades, untouched lines | ◐ | `keeps-the-list-short` |
| P4a | Inline comments only explain *why*; flag restating ones | ✅ | `flags-the-restating-comment` (and keeps the *why* comment) |
| P4b | Stale comment is a finding | ❌ | **Add to a fixture** |
| P4c | Doc blocks: no file/sibling uses them → flag for removal | ✅ | `flags-the-jsdoc-as-out-of-place` |
| P4d | Doc blocks: file uses them → match its tags | ❌ | **Second doc-block fixture** (repo that uses JSDoc) |
| P4e | Never add doc blocks where the area has none | ✅ | `does-not-propose-adding-doc-blocks` |
| P4f | Doc block on changed code must be updated | ❌ | Same fixture as P4d |

## Verify (130–143)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| V1 | Grep for the guard before calling it missing | ❌ | `security-trace` decoy: input already validated upstream |
| V2 | Check callers / middleware before calling a case unhandled | ❌ | Same decoy |
| V3 | Confirm "wrong" convention isn't the local majority | ◐ | `style-citation` |
| V4 | Only flag lines this branch changed | ✅ | `does-not-report-untouched-retry-as-a-finding` |
| V5 | Pre-existing → only if security/worsened, and label it | ✅ | Same grader |
| V6 | Short list beats padded list | ✅ | `keeps-the-list-short` |

## Output (145–172)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| U1 | Group by severity, number continuously | ❌ | **Regex grader** on every case |
| U2 | Severity definitions (Blocker / Should fix / Optional) | ❌ | `security-trace`: injection must be **Blocker** |
| U3 | Each finding: `file:line`, what/why, fix | ◐ | `cites-a-file-and-line` (style case only) → **extend** |
| U4 | Close with Reviewed / Looks good / Not changed | ❌ | **Regex grader** for `Reviewed` |

## Approval gate (174–194)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| G1 | Stop — no Edit, Write, `sed -i` | ◐ | Grader catches `Edit` only → **add file-unchanged + Bash write guards** |
| G2 | End with the "Reply with the numbers…" prompt | ❌ | **Regex grader** |
| G3 | Apply exactly the approved items | ❌ | Needs a second turn; tested via `--fix` (G4) |
| G4 | `--fix` → apply Blocker/Should-fix, leave Optional | ❌ | **New case** `fix-flag` (file-content regex) |
| G5 | After apply: list changes, run tests, report honestly | ❌ | Same case |
| G6 | Wrong-on-closer-reading fix → say so, don't apply | ❌ | Hard to fixture → candidate to cut |

## Log (196–282)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| L1 | Write a log entry after the findings | ❌ | **New case** `log-contract` (iteration 2) |
| L2 | Use a Bash heredoc, never `Write` | ❌ | `tool_used: Write, max: 0` |
| L3 | `$BRANCH_REVIEW_LOG_DIR` or `~/.branch-review-log`; never in the repo | ❌ | Same case — **sandbox constraint, see iteration 2** |
| L4 | Filename `YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`, `/` → `-` | ❌ | Regex on the heredoc command |
| L5 | Front matter template, mechanical fields filled | ❌ | Same case |
| L6 | One row per finding, same numbers; short notes | ❌ | Same case |
| L7 | Blank dispositions; blank `missed` row; `style_citations_ok` empty | ❌ | Same case |
| L8 | `gate_held: yes`, flip to `no` if breached | ◐ | Value checked in L5 |
| L9 | Tell the user where it landed | ❌ | Regex on last message |
| L10 | After apply, set `applied` on approved rows | ❌ | `fix-flag` case |
| L11 | Discoveries during apply → `[apply]` missed row, scoped | ❌ | Needs a fixture where the fix exposes a second bug; candidate to keep untested and say so |

## Notes (284–291)

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| N1 | Repo convention wins silently | — | Duplicate of H7/H8 → **cut** |
| N2 | `CLAUDE.md`/`AGENTS.md` rules outrank inferred | — | Duplicate of H2 → **merge into H2** |
| N3 | Non-git directory → manual scope | ❌ | **Cut** — model default |

## `references/security-checklist.md`

Treated as a reference catalog the security pass consults, not as instructions: its
~60 bullets are categories to look in, and grading every one would need ~60 fixtures.
Its two actual instructions are graded:

| ID | Instruction | Status | Grader / action |
|---|---|---|---|
| R1 | Report only what you can trace input → sink | ❌ | `security-trace` decoy must not be flagged |
| R2 | Give entry point, path, impact, fix | ❌ | `security-trace` grader |

## Tally

| | Count |
|---|---|
| Instructions | 66 |
| ✅ graded at start | 13 (20%) |
| ◐ partial at start | 10 |
| ❌ none at start | 40 |
| — restatements of other rows | 3 |
| Marked for cut / merge | 7 |

Target after iterations: every instruction that survives the cut is ✅ (≥90%), with any
exception listed here by ID and the reason it can't be fixtured.
