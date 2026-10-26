# Iteration log — branch-review

Evaluation-driven development of `branch-review/SKILL.md`. Each iteration follows
Red → Green → Refactor: a grader that fails for a reason we can name, one change aimed
at that reason, and a re-run of the **whole** suite to confirm the change fixed the
target without regressing anything else.

All runs: `branch-review/evals/run.sh --model sonnet` — Claude Sonnet as the model under
test; the LLM judge is Haiku in 0a–0b and Sonnet from 0c on (`run.sh` pins it). 3 runs per
case unless a table says 6. Baselines and the final run use `--ablation with-without`, so
every case also runs with the skill disabled; red/green checks in between run the skill
arm only, since the bare-model arm adds nothing to a red test. Scores are weighted grader
means per case; a case passes at 1.0. Every table here comes from a file in `results/`,
produced by `summarize.py` from the run's JSON.

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

---

## Iteration 3 — Grade the rest of the prompt (Red), then fix what it finds

The suite passed, but it graded only ~25% of the instructions (`TRACEABILITY.md`). This
iteration's Red step is coverage: write graders for everything testable, run them
against the **unchanged** skill, and see which instructions Sonnet actually ignores.

**Evals added (skill unchanged):**

- Every pre-existing case: `gate-held-no-write-tool`, `gate-held-no-shell-edits`
  (`sed -i`, redirects into `src/`, `git commit`…), `findings-carry-a-severity`,
  `closes-with-reviewed-section`. `correctness-callers` also gets
  `groups-and-numbers-findings`; `style-citation` gets the log contract.
- Nine new cases: `scope-uncommitted`, `scope-path`, `scope-auto-base`, `scope-no-base`,
  `large-diff`, `doc-block-match`, `declared-rules`, `security-only`, `fix-flag`.
  Rows covered are listed in `TRACEABILITY.md`.

**Red results** (skill arm only, 14 cases × 3 runs):

| Case | Score | Failing grader |
|---|---|---|
| fix-flag | 86% | `lists-before-editing-and-reports-after` **0/3** |
| large-diff | 78% | `says-what-it-deferred` **0/3** |
| doc-block-match | 80% | `proposes-a-matching-doc-block` **0/3** |
| declared-rules | 94% | `local-neighborhood-wins` 2/3 |
| style-citation | 97% | `log-content-follows-the-template` 2/3 |
| 9 other cases | 100% | — |
| **Overall** | **95.4%** | 9/14 cases pass |

Nine of the fourteen cases — including every scope case, `security-only`, and the gate
and format graders on all five original cases — passed first time. Those instructions
were already being followed; they are now *demonstrably* load-bearing rather than
assumed to be.

**Reading the five failures:**

| Grader | Verdict | Evidence |
|---|---|---|
| `fix-flag / lists-before-editing…` | **Real.** | Ordering the trace: in 2 of 3 runs the numbered list never appears — only "I applied #1 and left #2 alone". In the third it appears *after* the first Edit. `--fix` says "still present the list first." |
| `large-diff / says-what-it-deferred` | **Real, instruction too loose.** | The Blocker is caught every time, but Reviewed says "7 files, about 2,534 lines. Nothing deferred." — no statement that the diff was over the threshold, nor how the generated locale tables were treated. |
| `doc-block-match / proposes-a-matching-doc-block` | **Grader too strict.** | Reviews flag the missing block and name the repo's `@param`/`@returns` convention but write "Add a matching block" instead of the block itself. `<output>` explicitly allows describing a fix longer than a line or two; the grader demanded more than the prompt asks for. |
| `style-citation / log-content…` | **Judge error.** | The failing run's log table matches the presented list row-for-row (numbers, severities, categories). The judge saw a trace truncated at the front. |
| `declared-rules / local-neighborhood-wins` | **Real, intermittent (1/3).** | Followed the `src/api` style correctly but never mentioned that `src/legacy` differs. Left for now; watched in the next run. |

Also observed: `<house_style>` says both "Declared rules outrank inferred ones" and
"Prefer what the code does over what a config claims." That's a contradiction for the
`.prettierrc`-vs-code case — but Sonnet resolved it correctly 3/3 (`code-beats-the-
formatter-config`, `mentions-the-config-disagreement`). No red, so it goes to Refactor as
a wording fix, not here as a behavior fix.

**Hypotheses and changes (skill):**

1. `--fix`: "still present the list first" reads as satisfied by a summary at the end.
   Make it explicit that the full numbered list is its own message *before the first
   edit*, and say why. → predicts `lists-before-editing…` 3/3.
2. Large diff: "tell the user what you deferred" is satisfiable by "nothing". Require
   Reviewed to say, by file group, what was read in full, skimmed, or deferred. →
   predicts `says-what-it-deferred` 3/3.

The two edits are in different sections (`<approval_gate>`, `<scope>`) and target graders
in different cases, so each one's effect stays attributable.

**Changes (evals):**

- `proposes-a-matching-doc-block`: accepts a described block that names the repo's
  tags; still FAILs on tags the repo never uses.
- `log-content-follows-the-template` (one judge) → three regexes for the mechanical
  parts (front matter, blank dispositions, trailing `missed` row) plus one judge for
  row-by-row agreement. Each regex was checked against the three recorded logs (all
  pass) and against mutated copies — `gate_held: no`, a self-graded
  `style_citations_ok`, a filled disposition, a dropped `missed` row, a `/` left in the
  filename — and each mutation is caught by exactly the grader meant to catch it.

**Results** (skill arm, 14 cases × 3):

| Case | Red | Iteration 3 | Grader that moved |
|---|---|---|---|
| large-diff | 78% | **100%** | `says-what-it-deferred` 0/3 → **3/3** |
| doc-block-match | 80% | **100%** | `proposes-a-matching-doc-block` 0/3 → 3/3 (grader fix) |
| fix-flag | 86% | 90% | `lists-before-editing…` 0/3 → 1/3 |
| declared-rules | 94% | 83% | `local-neighborhood-wins` 2/3 → 0/3 |
| scope-auto-base | 100% | 93% | `resolves-the-base-from-origin` 3/3 → 2/3 |
| style-citation | 97% | 93% | new `log-rows-match-the-findings` 0/3 |
| 8 other cases | 100% | 100% | — |
| **Overall** | **95.4%** | **97.2%** | |

- **Hypothesis 2 confirmed.** `large-diff` 3/3: Reviewed now says the diff is ~2,500
  lines, the auth file was read first, and the locale tables were skimmed.
- **Hypothesis 1 rejected.** Ordering the `fix-flag` traces: in all three runs there is
  no text before the first Edit — including the run the judge *passed*. Every run goes
  log → edit → "I applied item 1…". Making "before the first edit" explicit changed
  nothing. Likely interaction with iteration 2: "write the log, then present the list"
  plus `--fix` gives the model a log → apply → summarize sequence where presenting the
  list never happens.
- `resolves-the-base-from-origin` — **grader fault.** The "failing" run found the base
  with `git diff main...HEAD` and still caught the bug. The grader tested an
  implementation detail (`merge-base`), not the behavior.
- `log-rows-match-the-findings` — **judge fault, again.** A mechanical comparison shows the
  log table matches the presented list row-for-row (numbers and severities) in all three
  runs; the judge failed all three.
- `local-neighborhood-wins` — **real.** 3 misses in 6 runs across two iterations: the
  review follows the `src/api` pattern but doesn't mention `src/legacy`. Neither
  iteration-3 edit touched `<house_style>`, so this is variance in an instruction that
  was already weak, not a regression.

**Lesson recorded:** judges with `focus: trace` were wrong 4 times out of 9 on these
transcripts (20–40 KB of JSONL), in both directions. From here, anything about the trace
is a `regex` or `tool_used` grader; judges read only the final message.

---

## Iteration 4 — `--fix` ends on the full list; inconsistent conventions name both sides

**Red:** `fix-flag` list ordering 0/3 (by trace inspection); `local-neighborhood-wins` 0/3.

**Hypotheses and changes (skill):**

1. Sonnet will not hold "show the list before editing" when the flag has pre-approved
   the edits, and two phrasings have failed. What the user actually needs from that rule
   is to **see every finding, including the Optional ones still theirs to choose**. So
   `--fix` now requires the *final* message to be the full numbered list, applied items
   marked **Applied**, then the test result and the approval prompt for what's left.
   This changes the skill's intended behavior, not just its wording; flagged to the user.
   → predicts `final-message-is-the-full-list` 3/3.
2. "Say so instead of picking a side" doesn't say *where*. Now: say it in the finding
   itself, citing both sides, with an example. → predicts `local-neighborhood-wins` 3/3.

**Changes (evals):**

- `fix-flag`: the trace judge is replaced by `final-message-is-the-full-list` (judge on
  the final message) and two regexes on the log: an applied Blocker/Should-fix row, and
  no applied Optional row. Both regexes checked against all six recorded runs.
- `scope-auto-base`: `resolves-the-base` accepts any base resolution (`merge-base`,
  `origin/HEAD`, `main...`), not only `merge-base`.
- `style-citation`: `log-rows-match-the-findings` dropped. Row-for-row agreement is
  checked by `certification/check_log_rows.py` instead (see TRACEABILITY L6).

**Results** (skill arm, 14 cases × 3):

| Case | Iteration 3 | Iteration 4 | Grader that moved |
|---|---|---|---|
| fix-flag | 90% | **100%** | `final-message-is-the-full-list` **3/3** |
| declared-rules | 83% | **100%** | `local-neighborhood-wins` 0/3 → **3/3** |
| scope-auto-base | 93% | 100% | `resolves-the-base` 3/3 (grader fix) |
| style-citation | 93% | 100% | (judge removed) |
| security-trace | 100% | 93% | `gives-the-trace` 3/3 → 1/3 |
| 9 other cases | 100% | 100% | — |
| **Overall** | **97.2%** | **99.5%** | 13/14 cases pass |

- **Both hypotheses confirmed.** `check_log_rows.py` also confirms the fix-flag and
  style-citation logs match their lists.
- `gives-the-trace` 1/3 is the security-impact gap first seen at 0c, back and wider.
  This time both failing findings give impact ("read or alter arbitrary data"), path and
  fix, but name only `req.query.q` — never the endpoint, `GET /users`; the passing run
  wrote `/users?q=…`. The grader's reading of "entry point" is fair, and the prompt is
  ambiguous: SKILL.md asks for "the untrusted input", the checklist for "the entry point".
- Why the checklist's wording doesn't land: `style-citation`'s trace-capturing graders
  show `references/security-checklist.md` was opened in **1 of 6** runs across
  iterations 3–4. The read works in the sandbox (the one run that tried got the file), so
  the model is skipping it. The four-part reporting rule exists *only* in that file.

---

## Iteration 5 — Security findings carry their own trace; the checklist is always read

**Red:** `gives-the-trace` 1/3. New grader `reads-the-security-checklist`
(`tool_used: Read`, `input_match: security-checklist`, min 1) on `security-trace` and
`security-only`; predicted to fail from the 1-in-6 read rate above.

**Hypotheses and changes (skill, `<passes>` §2 only):**

1. The reporting rule lives only in a file that's usually skipped. Put it in SKILL.md and
   define the entry point as the route/handler/command *and* the parameter.
   → predicts `gives-the-trace` 3/3.
2. "Read the checklist and work through the categories that apply" lets the model decide
   none apply to it. Make the read unconditional and say why: the categories you
   wouldn't think of are the reason it exists. → predicts `reads-the-security-checklist`
   6/6.

`reads-the-security-checklist` isolates change 2; `gives-the-trace` would move from
change 1 alone even if the read still didn't happen.

**Red, measured** (pre-change skill, the two security cases × 3):

| Grader | Red |
|---|---|
| `gives-the-trace` | 1/3 |
| `reads-the-security-checklist` | **4/6** (2/3 each case) |
| `security-only / reports-no-style-or-comment-findings` | 2/3 |

The 1-in-6 read rate above was an underestimate: it came from the only case whose graders
happened to capture the full trace. Measured directly, the read happens 4 times in 6 —
still not reliable. Process note: this red ran against the skill as of commit `1157205`
(iteration 2), because the stash that removed the change also removed the uncommitted
iteration 3–4 edits. Those edits don't touch the security pass, so the red is valid for
these graders; iterations 3–4 were then committed separately (`b3126bd`).

**Results** (the two security cases × 3):

| Grader | Red | Iteration 5 |
|---|---|---|
| `gives-the-trace` | 1/3 | **3/3** |
| `reads-the-security-checklist` | 4/6 | **5/6** |
| `reports-no-style-or-comment-findings` | 2/3 | 3/3 |
| security-trace | 91% | **100%** |
| security-only | 86% | 94% |

- **Hypothesis 1 confirmed.** Every injection finding now names the endpoint and the
  parameter (`GET /users?q=…`), the path, a concrete impact, and the fix — most as four
  labelled bullets.
- **Hypothesis 2 partly confirmed.** 4/6 → 5/6. The run that skipped the checklist was a
  4-turn `--security-only` review whose finding was nonetheless complete and correct. Not
  iterated further: the outcome the read protects (a fully traced finding) is 6/6, and a
  third phrasing would be tuning wording for a step the model judged unnecessary on a
  one-file diff. Recorded as the one partial in the final traceability (P2).
- `reports-no-style-or-comment-findings` 2/3 → 3/3 is not attributed to this change; the
  red's miss was one Optional naming item, and nothing here targets it. Watched in the
  full refactor run.

---

## Iteration 6 — Refactor: cut what no grader needs, prove nothing regressed

**Change (skill, 0.6.0):** the cuts listed in `TRACEABILITY.md` ("Cut in the Refactor
step"): the flow summary, a duplicated `.editorconfig`, the file-history step, the
`<notes>` section (two restatements, one merged into declared rules), and the checklist's
reporting preamble (now in SKILL.md). The declared-rules paragraph was also reworded to
remove a contradiction ("declared rules outrank inferred ones" vs "prefer the code over
the config").

**Prediction:** no grader moves.

**Refactor run** (14 cases, with and without the skill): **97.2%** with, Δ **+36.2**.
But three graders that were 3/3 slipped:

| Grader | Iteration 4–5 | Refactor (3 runs) |
|---|---|---|
| `declared-rules / local-neighborhood-wins` | 3/3 | 1/3 |
| `declared-rules / mentions-the-config-disagreement` | 3/3 | 2/3 |
| `scope-no-base / asks-for-the-base` | 3/3 | 2/3 |

Three runs can't separate a regression from variance, so: **A/B at 6 runs each**, the
iteration-5 skill (`97e7b28`) against the refactored one, same cases.

| Grader (6 runs) | Before refactor | After refactor |
|---|---|---|
| `local-neighborhood-wins` | **5/6** | **1/6** |
| `mentions-the-config-disagreement` | 6/6 | 6/6 |
| `asks-for-the-base` | 5/6 | 6/6 |

Two of the three were variance. `local-neighborhood-wins` was a real regression. Three
of the refactor's edits touched `<house_style>`, so each was restored on its own (6 runs
each):

| Variant | `local-neighborhood-wins` |
|---|---|
| A — file-history step restored | 2/6 |
| **B — original config-vs-code sentence restored** | **4/6** |
| C — `<notes>` restored | 0/6 |

**Cause: my rewrite of the config-vs-code sentence.** The new wording ("the code wins —
don't flag code for following its neighbors") narrowed attention to the immediate
neighbors, and Sonnet stopped surveying the wider repo, so it never saw `src/legacy`.
The file-history and `<notes>` cuts are cleared by the same experiment. **Fix:** the
original sentence, verbatim; the contradiction is resolved instead in the declared-rules
step, which now scopes "a written rule outranks inference" to written documents and
says configs are weighed against the code.

Also in this step: a `style-only` case, so both scope flags are graded (P0). Its first
run was 0/3 on `reports-no-security-findings`; reading the reviews, all three flagged the
missing `tenantId` as a departure from the sibling repositories' pattern and said they
had *not* done the security analysis. That's a legitimate style finding — the grader had
assumed tenant scoping could only be a security issue. Regraded: a mechanical
`skips-the-security-pass` (the checklist is not read) plus a judge that fails only
findings argued as an exploit.

## Final run — the submitted prompt

**Skill:** 0.6.0, exactly as submitted · **Suite:** 15 cases × 3 runs × 2 arms · Sonnet
as model and judge · cost $19.65 · `results/99-final-submission.txt`

| Case | With skill | Without skill | Δ |
|---|---|---|---|
| correctness-callers | 100% | 74% | +26 |
| declared-rules | 86% | 42% | +44 |
| doc-block-discipline | 100% | 61% | +39 |
| doc-block-match | 93% | 70% | +23 |
| fix-flag | 100% | 69% | +31 |
| large-diff | 93% | 33% | +60 |
| no-preexisting-noise | 100% | 81% | +19 |
| scope-auto-base | 100% | 70% | +30 |
| scope-no-base | 100% | 67% | +33 |
| scope-path | 100% | 90% | +10 |
| scope-uncommitted | 100% | 73% | +27 |
| security-only | 89% | 58% | +31 |
| security-trace | 100% | 64% | +36 |
| style-citation | 100% | 48% | +52 |
| style-only | 88% | 91% | −3 |
| **Overall** | **96.6%** | **66.1%** | **+30.5** |

Ten cases at 100%. The failing graders, all intermittent:

| Grader | Result | Read |
|---|---|---|
| `declared-rules / local-neighborhood-wins` | 1/3 | Unstable; see iteration 7 |
| `declared-rules / mentions-the-config-disagreement` | 2/3 | 6/6 in the A/B; variance |
| `doc-block-match / proposes-a-matching-doc-block` | 2/3 | One run argued one doc block "doesn't establish a convention" — a real reasoning slip; 8/9 across three iterations |
| `large-diff / says-what-it-deferred` | 2/3 | One run said how it read each group but not that the diff was over the threshold |
| `security-only / reads-the-security-checklist` | 1/3 | Unstable; see iteration 7 |
| `style-only / skips-the-security-pass` | 1/3 | Reads the checklist anyway, reports no security findings; see iteration 7 |

`style-only` is the one case where the skill scores *below* bare Sonnet, and only on
`skips-the-security-pass` — bare Sonnet has no checklist to read. On the outcome
(`reports-no-security-findings`) both arms pass.

Log rows vs. findings (L6), checked by `check_log_rows.py` over kept traces:
`results/99-log-rows-check.txt` — 3/3 match.

## Iteration 7 — Two process instructions, two more phrasings (rejected)

**Red:** from the final run — `local-neighborhood-wins` 1/3; checklist reads 1/3 under
`--security-only`; checklist read anyway in 2/3 `--style-only` runs.

**Hypotheses and changes:**

1. The local-neighborhood rule says to name both sides of an inconsistency, but
   `<house_style>` only tells the model to read the 2–3 *closest* siblings, so whether it
   ever sees `src/legacy` is luck. Add: before calling a sibling pattern the convention,
   grep for it and its alternative across the repo.
2. "Read the checklist before this pass, every time" clashes with `--style-only`, where
   the pass doesn't run, and evidently doesn't land under `--security-only`. Reword:
   "whenever this pass runs — including under `--security-only`, where it is the whole
   job".

**Results** (6 runs each, `results/07-rejected-*.txt`):

| Grader | Before | Iteration 7 |
|---|---|---|
| `local-neighborhood-wins` | 1/3 | **1/6** |
| `security-only / reads-the-security-checklist` | 1/3 | 3/6 |
| `security-trace / reads-the-security-checklist` | 3/3 | 4/6 |
| `style-only / skips-the-security-pass` | 1/3 | 2/6 |

**Both rejected; changes reverted.** Neither moved its grader beyond the run-to-run
spread already seen. Across every run since iteration 3, `local-neighborhood-wins` passes
about half the time under four different phrasings, and the checklist is read in roughly
60–80% of security passes under three. These are process instructions Sonnet follows
unreliably whatever the wording. The outcomes they protect hold up: complete, traced
security findings 6/6 in this iteration, and no security findings under `--style-only`
5/6.

Not iterated further. The structural options — inlining a compact category list so no
read is needed, or a fixture where the inconsistency sits inside the sibling set — change
what is being tested rather than how well the prompt does it, and are listed as next
steps in the README. The submitted prompt is the one the final run measured.

## Summary

| Step | Change | Overall (with skill) | What moved |
|---|---|---|---|
| 0c | Baseline, Sonnet judge | 92.8% (5 cases) | — |
| 1 | Naming findings cite the declaring line | 97.3% | citations 0/3 → 3/3 |
| 2 | Log written before the list | 100% | split-message runs 1/15 → 0/15 |
| 3 | Grade the rest of the prompt; large-diff, `--fix` wording | 95.4% → 97.2% (14 cases) | large-diff 0/3 → 3/3; `--fix` hypothesis rejected |
| 4 | `--fix` ends on the full list; name both sides | 99.5% | fix-flag 0/3 → 3/3; neighborhood 0/3 → 3/3 |
| 5 | Security findings carry their own trace | (security cases) 97.2% | trace 1/3 → 3/3 |
| 6 | Refactor; regression found by A/B, bisected, fixed | 97.2% → **96.6%** (15 cases) | neighborhood 1/6 → 4/6 with the cause restored |
| 7 | Two process instructions reworded | — | rejected, reverted |

Instructions graded: 20% at the start → 90% fully, 95% at least partly
(`TRACEABILITY.md`). Skill vs. bare Sonnet: +18.9 points at baseline → **+30.5** on a
suite three times the size.
