# Iteration log — branch-review

Evaluation-driven development of `branch-review/SKILL.md`. Each iteration follows
Red → Green → Refactor: a grader that fails for a reason we can name, one change aimed
at that reason, and a re-run of the **whole** suite to confirm the change fixed the
target without regressing anything else.

All runs: `branch-review/evals/run.sh --model sonnet` (Claude Sonnet as the model under
test, Claude Haiku as the LLM judge, 3 runs per case, `--ablation with-without` so every
case also runs without the skill). Scores are weighted grader means per case; a case
passes at 1.0. Raw results are summarized with `certification/summarize.py`.

Iterations before this log (0.1.0–0.5.0, see `branch-review/CHANGELOG.md`) were driven
by the disposition log from real use, not by eval scores, so they have no measured
baseline and are not counted here.

---

## Iteration 0a — Baseline on a mid-tier model

**Date:** 2026-10-25 · **Skill:** 0.5.0 (unchanged) · **Suite:** 3 cases

The existing suite had only been run on the default (frontier) model, where it scored
98.4%. First question: does the skill hold up on Sonnet?

| Case | With skill | Without skill |
|---|---|---|
| doc-block-discipline | 100% | 56% |
| no-preexisting-noise | 95% | 100% |
| style-citation | 80% | 60% |
| **Overall** | **91.7%** | Δ +19.9% |

**Reading the failures** (judge evidence in the result JSON):

- `style-citation / style-findings-are-evidenced` — 1/3. In both failing runs the
  tenant-scope and `NotFoundError` findings cite `orderRepository.ts:5-6`, but the
  naming finding cites only sibling *filenames* ("Siblings: `orderRepository.ts`"),
  no lines. SKILL.md requires `file.ext:lines`. **Real prompt failure on Sonnet**, but
  the grader didn't say whether a bare filename counts, so the judge split 2–1.
- `no-preexisting-noise / keeps-the-list-short` — 2/3. The failing review had exactly
  **one** finding; the judge voted FAIL FAIL PASS. **Grader failure**, not a prompt one.
- Every with-skill run says the eval log was written to `~/.branch-review-log/…`; that
  directory is empty. Carried into iteration 2.

**Decision:** fix the two graders before touching the prompt, so the next red is a
precise one. Changing grader and prompt in the same step would make it impossible to
say which one moved the score.

## Iteration 0b — Sharpen graders, add coverage, re-baseline

**Skill:** 0.5.0 (unchanged) · **Suite:** 5 cases

**Changes (evals only):**

- `keeps-the-list-short` → `regex` `not_contains` on a fourth finding heading. A count
  doesn't need a judge. Checked against all iteration-0a outputs before running: it
  agrees with a manual heading count on every with-skill run.
- `style-findings-are-evidenced` → states that a class/method/code-shape finding needs
  `path:line`, a file-*name* finding may cite the path alone, and correctness/security
  findings aren't judged.
- New case `correctness-callers` (traceability P1, P1b, P1c, P3b): changed contract with
  an un-updated caller, dropped `await`, `it.skip` on the test that covered the change,
  duplicated helper.
- New case `security-trace` (P2, U2, V1, V2, R1, R2): SQL injection that must be a
  Blocker with entry/path/impact/fix, beside an allowlisted `ORDER BY` decoy that must
  not be flagged.

**Results:**

| Case | With skill | Without skill | Failing grader (with skill) |
|---|---|---|---|
| correctness-callers | 88% | 76% | `flags-the-unawaited-save` 1/3 |
| doc-block-discipline | 93% | 56% | `flags-the-jsdoc-as-out-of-place` 2/3 |
| no-preexisting-noise | 100% | 100% | — |
| security-trace | 100% | 94% | — |
| style-citation | 70% | 50% | `style-findings-are-evidenced` **0/3** |
| **Overall** | **90.1%** | Δ +15.0% | |

**Reading the failures:**

- `style-findings-are-evidenced` 0/3 — **consistent, real.** All three naming findings
  list sibling names (`OrderRepository`, `findById`) with no line number; the
  behavioral findings in the same reviews cite lines correctly. The sharper grader
  turned a 2–1 split into an unambiguous red.
- `flags-the-unawaited-save` — **judge error.** Both "failing" reviews contain
  `### 2. [Blocker] saveOrder is no longer awaited` at `src/checkout.ts:10` with the fix.
- `flags-the-jsdoc-as-out-of-place` — **judge error.** The failing review's finding #3
  is "The JSDoc block doesn't match the codebase … Fix: remove it."
- Log mystery resolved: the eval sandbox gives each run its own `HOME`. The kept temp
  dirs (`--keep-temp`) hold correctly-formed logs under `sealed/home/.branch-review-log/`.
  Not a skill bug.

**Decision:** four false FAILs from the Haiku judge across two runs is a judge problem,
not a grader-wording problem. `run.sh` now passes `--judge-model sonnet` — still
mid-tier, and the judge for every run from here on. Re-baseline before changing the
prompt.

## Iteration 0c — Re-baseline with a Sonnet judge

**Skill:** 0.5.0 (unchanged) · **Suite:** 5 cases · **Judge:** Sonnet

**Results — this is the baseline every later iteration is measured against:**

| Case | With skill | Without skill | Failing grader (with skill) |
|---|---|---|---|
| correctness-callers | 100% | 91% | — |
| doc-block-discipline | 100% | 56% | — |
| no-preexisting-noise | 100% | 100% | — |
| security-trace | 94% | 73% | `gives-the-trace` 2/3 |
| style-citation | 70% | 50% | `style-findings-are-evidenced` 0/3 |
| **Overall** | **92.8%** | Δ +18.9% | |

The two judge errors from 0b are gone (both graders 3/3), which confirms they were the
judge. Two real failures remain:

- `style-findings-are-evidenced` 0/3 — unchanged from 0b; the naming-citation gap.
- `gives-the-trace` 2/3 — the failing injection finding names the entry point (`q`), the
  path (interpolated into SQL) and the fix, but gives the impact only as "changes the
  query" — not what an attacker gets. `references/security-checklist.md` asks for all four.

Also visible: without the skill, Sonnet never labels the injection a Blocker (0/3) and
never spots the duplicated helper (0/3). That is the skill's measurable contribution on
the two new cases.

---

## Iteration 1 — Naming findings must cite a line

**Red:** `style-citation / style-findings-are-evidenced` 0/3 (case 70%).

**Hypothesis:** the hard rule's only example (`Matches src/Services/OrderService.cs:40-58`)
is a citation of a code block. For naming findings Sonnet treats the sibling's *name* as
self-evidencing and cites `OrderRepository` rather than the line that declares it.
Behavioral findings in the same reviews cite lines correctly, so the rule is being
followed — just not generalized to naming.

**Change:** one sentence on the hard rule in `<house_style>`, with a generic example
rather than the fixture's names so the fix isn't fitted to the test.

**Prediction:** `style-findings-are-evidenced` 3/3; nothing else moves.

**Results:**

| Case | Baseline (0c) | Iteration 1 | Δ |
|---|---|---|---|
| correctness-callers | 100% | 100% | — |
| doc-block-discipline | 100% | 100% | — |
| no-preexisting-noise | 100% | 100% | — |
| security-trace | 94% | 100% | +6 |
| style-citation | 70% | 87% | +17 |
| **Overall** | **92.8%** | **97.3%** | **+4.5** |
| Δ vs. no skill | +18.9% | +26.0% | |

**Green on the target:** `style-findings-are-evidenced` 0/3 → **3/3**.

**Prediction partly wrong.** One `style-citation` run scored 0.6, failing
`cites-a-file-and-line` and `catches-the-missing-tenant-scope`, which were 3/3 at
baseline. Its final message was *only* the log line — "The evaluation log is at
`…/2026-10-25-cwd-feat-invoices-202356.md`." The review presented its findings, then
wrote the log in a separate tool call, then ended on a one-line message, so every
`last_message` grader saw nothing. Not caused by this change (it touched only
`<house_style>`); it's a latent ordering flaw in `<log>` that happened to fire here.
Carried into iteration 2.

`security-trace` reaching 100% is noise, not this change: the impact gap from 0c didn't
recur in three runs, and nothing in the edit touches security. It stays on the list.

The empty-message run also *passed* `style-findings-are-evidenced` — "every style finding
cites a line" is vacuously true with no findings. Grader fixed in iteration 2.

---

## Iteration 2 — The approval prompt must be the last thing the user sees

**Red:** 1 of 15 with-skill runs in iteration 1 (and 0 of 15 at 0c) ended on a message
containing only the log path. A new deterministic grader, `ends-with-approval-prompt`
(regex `Reply with the numbers` on `last_message`, traceability G2), applied
retroactively to the recorded outputs: 0c 15/15, iteration 1 **14/15** — it fails on
exactly that run.

**Hypothesis:** `<log>` says to write the entry "after presenting the findings — and
before you stop." That puts a tool call *between* the list and the end of the turn, and
the model sometimes closes with a fresh short message after the tool result. If the log
is written *before* the list is presented, the list, approval prompt, and log path are one
final message with nothing after it.

**Change (skill):** in `<log>`, write the entry once the findings are verified and
before presenting them; the log path stays the last line of the list message.

**Changes (evals):** `ends-with-approval-prompt` added to all five cases;
`style-findings-are-evidenced` now FAILs when the message has no numbered findings.

**Prediction:** `ends-with-approval-prompt` 15/15; no split-message runs.

**Results:**

| Case | Baseline (0c) | Iteration 1 | Iteration 2 |
|---|---|---|---|
| correctness-callers | 100% | 100% | 100% |
| doc-block-discipline | 100% | 100% | 100% |
| no-preexisting-noise | 100% | 100% | 100% |
| security-trace | 94% | 100% | 100% |
| style-citation | 70% | 87% | **100%** |
| **Overall** | **92.8%** | **97.3%** | **100%** |
| Δ vs. no skill | +18.9% | +26.0% | +31.7% |

**Green:** `ends-with-approval-prompt` 15/15. Every with-skill run's final message holds
the numbered findings, the approval prompt, and the log path, in that order — checked
directly, not just through the graders, to confirm moving the log write earlier didn't
drop it. `style-findings-are-evidenced` held at 3/3 under the stricter no-findings rule.

**Prediction correct.** The without-skill arm scores 0/15 on the new grader, as it
should — the approval prompt is the skill's own wording.

**Caveat on 100%:** the suite now passes, but it still only grades the instructions
listed ✅ in `TRACEABILITY.md`. A perfect score on a suite that ignores most of the
prompt is not the same as a load-bearing prompt; that's iteration 3.
