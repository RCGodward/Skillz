# branch-review -- Stage 3 Task Certification

`branch-review` is a Claude Code skill that reviews a git branch the way a careful
senior engineer would on a client codebase: correctness, a traced security audit,
conformance to *that repo's* existing style, and comment/doc-block discipline. It then
presents a numbered list of corrections and **stops**: nothing is edited until the user
picks the numbers to apply. The prompt was developed eval-first on Claude Sonnet.

## Where to look

| Artifact | File |
|---|---|
| **The Prompt** | `branch-review/SKILL.md` (+ `branch-review/references/security-checklist.md`, the catalog it consults) |
| **The Evaluations** | `branch-review/evals/` -- 15 cases, each a `case.yaml` (graders, weights) and a `scaffold.sh` (builds the fixture repo); `run.sh` runs them |
| **The Log** | `ITERATION-LOG.md` -- seven iterations, baseline to final |
| Instruction -> grader map | `TRACEABILITY.md` |
| Raw scores for every run cited in the log | `results/*.txt` |
| Version history of the prompt | `branch-review/CHANGELOG.md` |
| Scoring helpers | `tools/summarize.py`, `tools/check_log_rows.py` |

## How it meets each criterion

### The Prompt

| Criterion | Evidence |
|---|---|
| Structured prompting (RTCC) | Tagged sections map onto RTCC. **Role:** the frontmatter `description` + `<objective>` (a reviewer judging against the host codebase, not a style guide). **Task:** `<passes>`, `<output>`. **Context:** `<scope>`, `<house_style>` (what to read before judging). **Constraints:** `<verify>`, `<approval_gate>`, `<log>`, plus tool restrictions in the frontmatter (`Write` is withheld so the approval gate has tool-level enforcement). |
| Deliberate instruction design | Each rule carries its reason in one clause, so a model can apply it to cases the rule didn't anticipate (e.g. *why* the log is written before the list, *why* naming findings cite the declaring line). Several rules exist because an eval showed the plain version failing -- see the log. |
| Load-bearing >=90% | `TRACEABILITY.md`: **56 of 62 instructions (90%) fully graded, 59 (95%) at least partly**, up from 20% at the start. Three are documented exceptions (need a network or a second user turn). The ablation arm is the sensitivity check: the same cases without the skill score **66.1% vs 96.6%**. |
| No dead weight | Iteration 6 cut eight instructions the matrix couldn't justify and reworded one, then A/B-tested the result. The A/B caught a regression, which was **bisected** to the reworded sentence and fixed by restoring it; the same experiment cleared the cuts. |

### The Evaluations

| Criterion | Evidence |
|---|---|
| >=3 distinct criteria | Distinct failure classes, not variations: **approval gate** (no Edit, Write, or shell edits before approval), **correctness** (un-updated callers, dropped awaits, skipped tests), **security** (traced injection, *not* flagging an allowlisted decoy), **house-style evidence** (every style claim cites `file:line` in the repo), **false-positive suppression** (pre-existing code, formatter-config vs code), **comment/doc-block discipline** in both a repo that uses JSDoc and one that doesn't, **scope resolution** (path, auto-base, no base, uncommitted, large diff), **flags** (`--fix`, `--security-only`, `--style-only`), and the **log contract**. |
| Substantive, not window dressing | Each fixture plants a specific defect and often a decoy. Graders were checked against recorded outputs and against **mutated** copies before being trusted (`ITERATION-LOG.md`, iteration 3). One grader of my own was caught as vacuous and replaced. |
| Capable of 95%+ | Final run on the submitted files **96.8%** (+33.8 over bare Sonnet); 10 of 15 cases at 100%. Earlier, the 5-case suite reached 100%. |
| Mid-tier models | Model under test **and** judge are **Claude Sonnet** (`run.sh` pins `--judge-model sonnet`). No frontier model anywhere in the loop. |
| Pass/fail thresholds and rubrics | Every `llm` grader states explicit `PASS if ... / FAIL if ...` criteria and what doesn't matter; mechanical checks are `regex` / `tool_used` / `file_exists`. Weights per grader; a case passes at 1.0 (`--threshold` default). |

### The Log

| Criterion | Evidence |
|---|---|
| >=2 documented iterations | Seven, plus three baseline steps (0a-0c). |
| Baseline, hypothesis, change, measured result, reasoning | Every iteration has all five, with before/after tables taken from `results/`. |
| EDD Red/Green/Refactor | Red is always shown **before** the change (graders run against the unchanged prompt; in iterations 2 and 3 applied retroactively to recorded outputs). Iteration 6 is the Refactor step, with a regression check. Two hypotheses are recorded as **rejected** (3, 7), with the changes reverted. |
| Chronological, cause and effect | One change per iteration where possible; where two went in together they targeted graders in different cases so each effect stays attributable. Grader fixes and prompt fixes are never mixed in one measurement. |

## Running it

Needs Claude Code with `claude plugin eval`, and `git`. From the unzipped directory:

```sh
branch-review/evals/run.sh --model sonnet                 # full suite, both arms (~$20)
branch-review/evals/run.sh --model sonnet --ablation none \
  --case style-citation --keep-temp                       # one case, skill arm, keep traces
python3 tools/summarize.py <result.json>                  # per-case, per-grader pass rates
python3 tools/check_log_rows.py <result.json>             # log table vs findings (needs --keep-temp)
```

`branch-review/evals/README.md` explains each flag `run.sh` sets and why.

## Honest limits

- Three instructions are graded but followed unreliably by Sonnet under every phrasing
  tried: naming both sides of a style inconsistency (~50%), reading the security checklist
  (~60-80%), and not reading it under `--style-only`. The outcomes they protect hold up.
  Details in `TRACEABILITY.md`.
- 3 runs per case is a small sample; where a result mattered (iterations 6 and 7) it was
  re-run at 6.
- Next steps, not done: inline a compact security category list so no file read is
  needed; build a fixture where the style inconsistency sits inside the sibling set.
