# branch-review -- Stage 3 Task Certification (resubmission)

`branch-review` is a Claude Code skill that reviews a git branch the way a careful
senior engineer would on a client codebase: correctness, a traced security audit,
conformance to *that repo's* existing style, and comment/doc-block discipline. It then
presents a numbered list of corrections and **stops**: nothing is edited until the user
picks the numbers to apply. The prompt was developed eval-first on Claude Sonnet.

## What changed since the first submission

The first submission failed on load-bearing share: **58%** (62 of 107), because the
security checklist's 45 bullets counted as instructions and 42 had no criterion, and
three SKILL.md instructions had none either. In response (`ITERATION-LOG.md`, "After the
Stage 3 review"):

| Review finding | What was done |
|---|---|
| 42 checklist bullets ungraded | Seven `sec-*` fixtures plant one defect per bullet; all 45 got a named grader (`c01`..`c45`). Then an ablation showed the skill without the checklist still finds 40 of the 42, so the checklist was **cut to the two checks it measurably adds** (iteration 10). The 45 graders stay as regression tests and all pass 3/3. |
| S2, G4, L10 had no criterion | S2: a stand-in `gh` serves a PR. G4 and L10: cases that resume a session after the review, so the user's reply ("1, 2") can be tested. |
| S7, P1c partly graded | A defect outside every diff hunk; a test that asserts its own mock. |
| `--model` not pinned | `run.sh` pins `--model sonnet` and `--judge-model sonnet`. |
| Sonnet judging Sonnet | A different-family judge isn't available in `claude plugin eval`, so the judge was **calibrated** against blind labels: 92% agreement, **0 false PASSes**. |
| Weak regexes | Citation regex is language-agnostic; the Reviewed check is anchored to a heading. |
| README overclaim; iteration 4 delta | Corrected; iteration 4 now notes it was measured on a replacement grader. |
| Commit hashes unverifiable | `repo.bundle` is in this ZIP: `git clone repo.bundle skillz`. |

Result: **load-bearing 58% -> 100%** (64 of 65 fully graded, 1 partial), and the prompt
is 109 -> 65 instructions; final run **99.6%**.

## Where to look

| Artifact | File |
|---|---|
| **The Prompt** | `branch-review/SKILL.md` (0.8.0) |
| **The Evaluations** | `branch-review/evals/` -- 27 cases, each a `case.yaml` (graders, weights) and a `scaffold.sh` (builds the fixture repo); `run.sh` runs them. `branch-review/evals/README.md` describes every case |
| **The Log** | `ITERATION-LOG.md` -- iterations 1-10, baseline to final, including the post-review section |
| Instruction -> grader map | `TRACEABILITY.md` |
| Raw scores for every run cited in the log | `results/*.txt` |
| Judge calibration | `calibration/` (items, blind labels, key, report) |
| Version history of the prompt | `branch-review/CHANGELOG.md` |
| Full repository history | `repo.bundle` |
| Scoring helpers | `tools/summarize.py`, `tools/check_log_rows.py`, `tools/calibrate_judge.py` |

## How it meets each criterion

### The Prompt

| Criterion | Evidence |
|---|---|
| Structured prompting (RTCC) | Tagged sections map onto RTCC. **Role:** the frontmatter `description` + `<objective>` (a reviewer judging against the host codebase, not a style guide). **Task:** `<passes>`, `<output>`. **Context:** `<scope>`, `<house_style>` (what to read before judging). **Constraints:** `<verify>`, `<approval_gate>`, `<log>`, plus tool restrictions in the frontmatter (`Write` is withheld so the approval gate has tool-level enforcement). |
| Deliberate instruction design | Each rule carries its reason in one clause, so a model can apply it to cases the rule didn't anticipate (e.g. *why* the log is written before the list, *why* naming findings cite the declaring line). Several rules exist because an eval showed the plain version failing -- see the log. |
| Load-bearing >=90% | `TRACEABILITY.md`, counted the way the review counted: **65 instructions, 64 fully graded, 1 partial (L6), 0 without a criterion -- 100%**. Beyond coverage, sensitivity: the same cases without the skill score **74.7% vs 99.9%**, and the checklist, which had a grader per bullet but measurably did little, was cut. |
| No dead weight | Two Refactor steps. Iteration 6 cut eight instructions and A/B-tested the result; a regression was bisected to one reworded sentence and fixed. Iteration 10 cut the 45-bullet security checklist (a quarter of the prompt) to two checks after an ablation showed the skill found 40 of its 42 planted defects without it; all 45 graders still pass. |

### The Evaluations

| Criterion | Evidence |
|---|---|
| >=3 distinct criteria | Distinct failure classes, not variations: **approval gate** (no Edit, Write, or shell edits before approval), **correctness** (un-updated callers, dropped awaits, skipped and mock-asserting tests, a defect outside the hunk), **security** (one planted defect per checklist category, a traced injection, *not* flagging an allowlisted decoy), **house-style evidence** (every style claim cites `file:line`), **false-positive suppression**, **comment/doc-block discipline** in both doc-block regimes, **scope resolution** (base, path, auto-base, no base, uncommitted, PR number, large diff), **flags**, the **apply step** (refusing an approved-but-wrong fix, catching a second instance of a fixed flaw), and the **log contract**. |
| Substantive, not window dressing | Each fixture plants a specific defect and often a decoy. Graders were checked against recorded outputs and **mutated** copies before being trusted; resumed-session logs are graded on the real file. Retired graders are named and explained in the log. |
| Capable of 95%+ | Final run on 0.8.0: **99.6%**, 25 of 27 cases at 100%, 0 API errors (`results/21-final-0.8.0.txt`). |
| Mid-tier models | Model under test **and** judge are **Claude Sonnet**, both pinned in `run.sh`. No frontier model in the loop. (The blind calibration labels came from a larger model, used only to check the judge.) |
| Pass/fail thresholds and rubrics | Every `llm` grader states explicit `PASS if ... / FAIL if ...` criteria and what doesn't matter; mechanical checks are `regex` / `tool_used` / `file_exists`. Weights per grader; a case passes at 1.0. Judge calibration: 34/37 agreement with blind labels, all three disagreements false FAILs. |

### The Log

| Criterion | Evidence |
|---|---|
| >=2 documented iterations | Ten, plus baselines (0a-0c), a red step, and fixture fixes measured separately. |
| Baseline, hypothesis, change, measured result, reasoning | Every iteration has all five, with before/after tables from `results/`. |
| EDD Red/Green/Refactor | Red is shown **before** each change, on the unchanged prompt. Iterations 6 and 10 are Refactor steps, each with a full regression run. Two hypotheses are recorded as **rejected** (iteration 3's `--fix` phrasing, iteration 7), with the changes reverted. |
| Chronological, cause and effect | One prompt change per iteration where possible; where several went in together they targeted graders in different cases. Grader and fixture fixes are labelled where they occur and, after the review, measured on the unchanged prompt before any prompt edit. A run that hit a usage limit was discarded and re-run, and says so. |

## Running it

Needs Claude Code with `claude plugin eval`, `git` and `python3`. From the unzipped
directory:

```sh
branch-review/evals/run.sh --keep-temp -j 6 --max-cost-usd 90   # full suite, both arms (~$35-55)
branch-review/evals/run.sh --ablation none --case style-citation  # one case, skill arm
python3 tools/summarize.py <result.json>                          # per-case, per-grader pass rates
python3 tools/check_log_rows.py <result.json>                     # log rows vs findings (needs --keep-temp)
python3 tools/calibrate_judge.py score calibration                # re-score the judge calibration
```

## Honest limits

- **The checklist cut rests on textbook fixtures.** Each `sec-*` defect is a clear-cut
  instance Sonnet recognizes unprompted. The cut is safe on these; whether a category
  list helps on subtler real-world variants is something these fixtures can't measure
  either way.
- Some graded instructions pass in 2 of 3 runs in one of the last two full runs rather
  than always 3 (looking again after a fix, naming both sides of an inconsistency,
  `--security-only` discipline, one citation slip, one log row per ~70 runs). Listed in
  `TRACEABILITY.md`.
- 3 runs per case is a small sample; where a result mattered it was re-run at 6.
- The judge was calibrated, not replaced: the blind labeller is a larger model from the
  same family.
