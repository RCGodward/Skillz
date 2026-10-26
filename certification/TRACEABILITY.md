# Instruction → criterion traceability

Every instruction in `branch-review/SKILL.md` **0.6.0** (the submitted prompt), and the
eval grader that fails if the instruction is ignored. Graders are named
`case / grader` and live in `branch-review/evals/<case>/case.yaml`.

An instruction is **load-bearing** when at least one grader would fail without it. The
ablation arm (same cases, skill disabled) is the evidence that the graders are sensitive
to the prompt: see the final run in `ITERATION-LOG.md`.

Status: **✅ graded** · **◐ partial** — graded, but part of the instruction isn't ·
**⚠ exception** — kept, not fixturable, reason given.

## Summary

| | At start (0.5.0) | Final (0.6.0) |
|---|---|---|
| Instructions | 66 | 62 |
| ✅ graded | 13 (20%) | **56 (90%)** |
| ◐ partial | 10 | 3 |
| ⚠ exception / ❌ none | 40 | 3 |
| Cut or merged as dead weight | — | 8 |

Load-bearing (✅ + ◐) = **59 / 62 = 95%**; fully graded = 56 / 62 = 90%. The final count
is higher than "66 minus cuts" because grading forced some compound instructions apart
(S4/S4b, P2/P2b/P2c, H6/H7) — each now has its own grader. Counted mechanically from the
tables below. The three exceptions are listed at the end with reasons.

## Objective

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| O1 | Judge against this codebase's standards, not an external guide | ✅ | `style-citation / style-findings-are-evidenced`; `declared-rules / code-beats-the-formatter-config` |
| O2 | Produce a numbered list | ✅ | `correctness-callers / groups-and-numbers-findings`; `no-preexisting-noise / keeps-the-list-short` |
| O3 | Edit nothing until approved | ✅ | `gate-held-nothing-edited` (all 15 cases) |

## Scope

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| S1 | Base-branch argument → diff against it | ✅ | Every finding grader in the 12 cases run as `/branch-review main` |
| S2 | PR number → that PR's diff | ⚠ | Needs `gh` and a network; see exceptions |
| S3 | Path argument → only files under it | ✅ | `scope-path / stays-inside-the-path`, `finds-the-billing-bug` |
| S4 | No args → find the base from `origin/*` | ✅ | `scope-auto-base / resolves-the-base`, `finds-the-bug-in-the-first-commit`, `reports-the-base-it-used` |
| S4b | …and ask if none resolves; don't guess | ✅ | `scope-no-base / asks-for-the-base` |
| S5 | No commits ahead → review uncommitted work, say so | ✅ | `scope-uncommitted / says-it-reviewed-uncommitted-work`, `flags-the-committed-secret`, `covers-the-untracked-file` |
| S6 | Three-dot diff against the merge-base | ✅ | `scope-auto-base / finds-the-bug-in-the-first-commit` (bug is in the branch's first commit) |
| S7 | Read the full current file, not just hunks | ◐ | Exercised by `doc-block-match / flags-the-stale-doc-block` (doc block sits outside the hunk), but no grader isolates it |
| S8 | >2000 lines → say so, risk-first, say how each group was handled | ✅ | `large-diff / says-what-it-deferred`, `catches-the-inverted-expiry` |

## House style

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| H1 | Learn the style before judging | ✅ | Every citation grader — a cited sibling can't exist without it |
| H2 | Read declared rules; written rules outrank inference; cite the file | ✅ | `declared-rules / applies-the-declared-logging-rule` (must cite `CONTRIBUTING.md`) |
| H3 | Read 2–3 closest siblings per changed file | ✅ | `style-citation / style-findings-are-evidenced`, `cites-a-file-and-line` |
| H4 | Note the conventions that apply | ✅ | `style-citation` (naming, error handling), `declared-rules` (logging, async) |
| H5 | Code beats a config it disagrees with; mention it | ✅ | `declared-rules / code-beats-the-formatter-config`, `mentions-the-config-disagreement` |
| H6 | **Every style finding cites `file:line`** | ✅ | `style-citation / cites-a-file-and-line`, `style-findings-are-evidenced` |
| H7 | Naming findings cite the declaring line | ✅ | `style-citation / style-findings-are-evidenced` (iteration 1) |
| H8 | Inconsistent codebase → local wins; name both sides in the finding | ✅ | `declared-rules / local-neighborhood-wins` (iterations 4, 6) |

## Passes

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| P0 | Run all four; honor `--security-only` / `--style-only` | ✅ | `security-only / reports-no-style-or-comment-findings`; `style-only / skips-the-security-pass`, `reports-no-security-findings` |
| P1 | Correctness: boundaries, nulls, async, contracts… | ✅ | `correctness-callers / flags-the-unawaited-save`; `scope-path / finds-the-billing-bug`; `scope-auto-base / finds-the-bug-in-the-first-commit`; `large-diff / catches-the-inverted-expiry` |
| P1b | Grep for other callers of a changed shared function | ✅ | `correctness-callers / flags-the-unupdated-caller` (caller is in an untouched file) |
| P1c | Tests that assert the mock, or were skipped | ◐ | `correctness-callers / flags-the-skipped-test` covers *skipped*; *asserts the mock* has no fixture |
| P2 | Read the security checklist every time | ✅ | `security-trace`, `security-only / reads-the-security-checklist` |
| P2b | Security finding states entry point, path, impact, fix | ✅ | `security-trace / gives-the-trace` (iteration 5) |
| P2c | Report only what you can trace end to end | ✅ | `security-trace / does-not-flag-the-allowlisted-sort` |
| P3 | Style conformance against evidenced conventions | ✅ | `style-citation / style-findings-are-evidenced`; `declared-rules / local-neighborhood-wins` |
| P3b | Hand-rolled helper duplicating an existing one | ✅ | `correctness-callers / flags-the-duplicate-helper` |
| P3c | Not findings: preferences, idiom upgrades, untouched lines | ✅ | `no-preexisting-noise / keeps-the-list-short`; `declared-rules / code-beats-the-formatter-config` |
| P4a | Inline comments explain *why*; flag restating ones | ✅ | `doc-block-discipline / flags-the-restating-comment` (and must keep the basis-points *why* comment) |
| P4b | A stale comment is a finding | ✅ | `doc-block-match / flags-the-stale-inline-comment` |
| P4c | No doc blocks in file or siblings → flag new ones for removal | ✅ | `doc-block-discipline / flags-the-jsdoc-as-out-of-place` |
| P4d | File uses doc blocks → match its tags | ✅ | `doc-block-match / proposes-a-matching-doc-block` |
| P4e | Never add doc blocks where the area has none | ✅ | `doc-block-discipline / does-not-propose-adding-doc-blocks` |
| P4f | Doc block on changed code must be updated | ✅ | `doc-block-match / flags-the-stale-doc-block` |

## Verify

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| V1 | Grep for the guard before calling it missing | ✅ | `security-trace / does-not-flag-the-allowlisted-sort` (guard is in another file) |
| V2 | Check callers/middleware before calling a case unhandled | ✅ | Same grader |
| V3 | Confirm a "wrong" convention isn't the local majority | ✅ | `declared-rules / code-beats-the-formatter-config` |
| V4 | Only flag lines this branch changed | ✅ | `no-preexisting-noise / does-not-report-untouched-retry-as-a-finding` |
| V5 | Pre-existing → only if security/worsened, and labelled | ✅ | Same grader (allows a labelled pre-existing note) |
| V6 | A short real list beats a padded one | ✅ | `no-preexisting-noise / keeps-the-list-short` |

## Output

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| U1 | Grouped by severity, numbered continuously | ✅ | `correctness-callers / groups-and-numbers-findings`; `findings-carry-a-severity` (5 cases) |
| U2 | Severity definitions | ✅ | `security-trace / reports-the-injection-as-a-blocker`; `large-diff / catches-the-inverted-expiry` (must be Blocker) |
| U3 | Each finding: `file:line`, what/why, fix; describe larger fixes | ✅ | `correctness-callers / groups-and-numbers-findings`; `doc-block-match / proposes-a-matching-doc-block` |
| U4 | Close with Reviewed / Looks good / Not changed | ✅ | `closes-with-reviewed-section` (5 cases); `large-diff / says-what-it-deferred` |

## Approval gate

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| G1 | Stop: no Edit, no Write, no `sed -i` | ✅ | `gate-held-nothing-edited`, `gate-held-no-write-tool`, `gate-held-no-shell-edits` |
| G2 | End with the "Reply with the numbers…" prompt, then the log line | ✅ | `ends-with-approval-prompt` (14 cases); `style-citation / tells-the-user-where-the-log-is` |
| G3 | Apply exactly what was approved; leave the rest alone | ✅ | `fix-flag / applies-the-await-fix`, `leaves-the-optional-comment` |
| G4 | A fix that's wrong on closer reading → say so, don't apply | ⚠ | See exceptions |
| G5 | After applying: list changes, run tests, report honestly | ✅ | `fix-flag / runs-the-project-tests`, `final-message-is-the-full-list` |
| G6 | `--fix`: apply Blocker/Should fix; end on the full list, applied marked | ✅ | `fix-flag / final-message-is-the-full-list` (iteration 4), `no-write-tool` |

## Log

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| L1 | Write the log before presenting the list | ✅ | `ends-with-approval-prompt` (iteration 2) |
| L2 | Bash heredoc, never `Write` | ✅ | `style-citation / gate-held-no-write-tool`; `fix-flag / no-write-tool` |
| L3 | `$BRANCH_REVIEW_LOG_DIR` or `~/.branch-review-log`; never in the repo | ✅ | `style-citation / log-written-with-a-timestamped-name`, `log-not-written-into-the-repo` |
| L4 | `YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`, `/` → `-`, never overwrite | ✅ | `style-citation / log-written-with-a-timestamped-name` |
| L5 | Front matter, mechanical fields filled, `gate_held: yes` | ✅ | `style-citation / log-front-matter-is-complete` |
| L6 | One row per finding, same numbers and order | ◐ | Row shape graded (`log-dispositions-left-blank`); row-for-row agreement checked by `certification/check_log_rows.py` over the result JSON, since no grader can compare two places in one transcript |
| L7 | Dispositions blank, `style_citations_ok` blank, trailing `missed` row | ✅ | `style-citation / log-dispositions-left-blank`, `log-front-matter-is-complete`, `log-keeps-the-missed-row` |
| L8 | Tell the user where it landed | ✅ | `style-citation / tells-the-user-where-the-log-is` |
| L9 | After apply, set `applied` on approved rows only | ✅ | `fix-flag / marks-applied-in-the-log`, `leaves-optional-row-blank-in-the-log` |
| L10 | Discoveries during apply → scoped `[apply]` missed row | ⚠ | See exceptions |

## Graded but unstable on Sonnet

Graded means a grader fails when the instruction is ignored — not that it always passes.
Three instructions are followed only part of the time, under every phrasing tried
(`ITERATION-LOG.md`, iterations 4–7):

| ID | Pass rate since iteration 3 | What the outcome graders show |
|---|---|---|
| H8 name both sides of an inconsistency | ~50% | The local style is always applied correctly; what's missing is the mention of `src/legacy` |
| P2 read the security checklist | ~60–80% of security passes | Security findings are complete and correctly traced 6/6 |
| P0 skip security under `--style-only` | checklist still read ~50% | No security findings reported, 5/6 |

## Exceptions — kept, not fixturable

| ID | Instruction | Why it can't be graded here | Why it stays |
|---|---|---|---|
| S2 | PR number → that PR's diff | Needs `gh`, credentials and a network; the eval sandbox has none. | Real entry point for the skill; the one non-obvious part (falling back when `gh` is missing) is a single clause. |
| G4 | An approved fix that's wrong → say so | Needs a second user turn approving a fix the review itself proposed wrongly; an eval case is a single prompt, and planting a wrong finding means the review didn't make it. | Cheap insurance against applying a bad fix because it was approved. |
| L10 | Discoveries during apply → `[apply]` row | Needs an apply step that *exposes* a second, in-scope bug; whether a given fix does that is nondeterministic. | Feeds `eval/tally.sh`'s split between self-found and human-found misses — the 0.4.0 feature. Kept by the author's decision. |

## Cut in the Refactor step (iteration 6)

| Was | Why cut |
|---|---|
| Flow summary line in `<objective>` | Restated the section order. |
| Duplicated `.editorconfig` in the declared-rules list | Typo. |
| `gh pr diff` detail | Shortened to one clause (S2). |
| "Read the file's own history" step | No observable effect; bisected in iteration 6 and not implicated in any grader change. |
| `<notes>`: "repo wins silently" | Restated H6. |
| `<notes>`: `CLAUDE.md`/`AGENTS.md` outrank inference | Merged into H2, which now also says to cite the file. |
| `<notes>`: non-git directories | Model default; untestable and unneeded. |
| Checklist preamble: reporting rule | Moved into SKILL.md (P2b) in iteration 5; the checklist now defers to it. |

`references/security-checklist.md` itself is a catalog the security pass consults, not
a list of instructions: grading each of its ~60 categories would need ~60 fixtures. Its
use is graded (P2), and so is the reporting rule (P2b) and the trace-only rule (P2c).
