# Eval cases for branch-review

Run with `run.sh`, which supplies the flags every run needs:

```sh
branch-review/evals/run.sh                                  # full suite, with and without the skill
branch-review/evals/run.sh --smoke                          # one run per case, skill arm only (~$0.60)
branch-review/evals/run.sh --smoke doc-block-discipline     # one case
branch-review/evals/run.sh --case style-\* --runs 5         # anything else passes through
```

The first run in this directory asks you to confirm you trust the plugin; pass
`--trust-plugin` to skip that (CI). Results and the HTML report land in
`evals/results/<timestamp>/`, which is gitignored -- the report embeds full transcripts.
A full run is about 160 agent runs (27 cases x 3 runs, most with both arms) and costs
roughly $40-60; add `-j 6` to run six at once and `--max-cost-usd` to cap it. A run that
hits an account usage limit scores those runs 0 without grading -- the CLI says so at the
end; re-run rather than reading the scores.

## What run.sh sets, and why

**`--scaffold`.** Each case builds its fixture repo with the `scaffold.sh` beside its
`case.yaml`, which sources `lib/fixture.sh` for the common setup. The CLI only runs
scaffold scripts when you pass this flag; without it every case runs in an empty
directory and the review has nothing to review.

**`--no-publish`.** The HTML report publishes to claude.ai by default. Every fixture here
is synthetic, so it's safe as it stands -- but the moment a case is derived from client
work, `--no-publish` is not optional.

**`--allow-tools Bash Edit`.** The skill's own `allowed-tools` does not apply inside an
eval run; the case's `execution.allowed_tools` governs, and gated tools additionally need
this operator grant. Bash is needed for git. **Edit is granted on purpose**: every case
asserts `tool_used: Edit, min: 0, max: 0`, and that assertion is worthless if the run
couldn't have edited anything in the first place. Granting Edit is what turns the
approval gate from an untested claim into a tested one. (`min: 0` is required -- `min`
defaults to 1, and without it the gate fails on every run that correctly edits nothing.)

**`PATH`, on macOS.** `/usr/bin/git` is an xcrun shim that fails inside the eval sandbox
(it can't write its cache under `/var/folders`), and the sandbox won't let the run read
anything outside its own fixture -- not this repo, not `/tmp`. So `lib/fixture.sh` copies
`bin/git`, which execs the real Xcode/CLT git by full path, into each fixture's
`.git/eval-bin/`, and `run.sh` puts that relative path on `PATH`. `case.yaml` can't do
this itself: `execution.env` only accepts `EVAL_*` keys. Without it the review still
runs, but it reconstructs the diff by decoding `.git/objects` by hand -- which is not the
behavior under test.

## Ablation

With a plugin target, `--ablation with-without` is the default: each case also runs with
the skill disabled and reports the delta. That answers "does the skill beat bare Claude
on this case", which the disposition log can't -- you only ever see the with-skill arm in
real use.

It does **not** tell you which section of SKILL.md is carrying the result. For that,
copy the skill, delete one section, and run the same cases against both targets.

## The cases

| Case | Asserts | Failure it guards |
|---|---|---|
| `doc-block-discipline` | Flags JSDoc in a repo that uses none; flags a restating comment; leaves the basis-points comment alone; proposes adding no doc blocks | The rule most likely to rot, and the one with a crisp right answer |
| `style-citation` | Every style finding cites a file in the fixture; catches the dropped tenant scope | `preference` rows -- findings asserted from general convention rather than this repo |
| `no-preexisting-noise` | Doesn't report untouched pre-existing code as a finding; keeps the list short | `preexisting` and `wrong` rows -- the false positives that cost trust |
| `correctness-callers` | Catches an un-updated caller of a changed function, a dropped `await`, a test switched to `it.skip`, and a helper that duplicates one in `src/money.ts` | `missed` rows in the correctness pass |
| `security-trace` | Reports SQL injection as a Blocker with entry point, path, impact and fix; leaves an allowlisted `ORDER BY` alone | `missed` security findings, and `wrong` ones from not checking the guard upstream |
| `scope-*` (6) | Base branch, path, auto base, no base (ask), uncommitted work, PR number via a stand-in `gh` | Reviewing the wrong diff |
| `large-diff` | Says the diff is large and how each file group was handled; still finds the one-character auth bug | Attention lost in generated code |
| `full-file-read` | Finds a defect that lives outside every diff hunk | Reviewing hunks instead of files |
| `test-asserts-mock` | Flags a test that mocks the function it tests | `missed` test-quality findings |
| `doc-block-match` | In a repo that *uses* JSDoc: matching tags, stale doc block, stale comment | The opposite doc-block regime |
| `declared-rules` | Cites `CONTRIBUTING.md`; code beats a formatter config; names both sides of an inconsistent directory | `preference` rows |
| `security-only`, `style-only` | Each flag suppresses the other passes | Flags ignored |
| `fix-flag` | `--fix` applies only Blocker/Should fix, runs the tests, ends on the full list, marks the log | Over-applying |
| `apply-wrong-fix`, `apply-discovery` | Resumed sessions: refuses an approved-but-wrong fix; notices and logs a second instance of a fixed flaw | The apply step |
| `sec-*` (7) | One planted defect per bullet of the 0.7.0 security checklist (graders `c02-...` to `c45-...`), reviewed with `--security-only`; since 0.8.0 cut the checklist, regression tests for the security pass | `missed` security categories |

The original five cases also carry the gate, severity and Reviewed-section graders.
`lib/security_cases.py` generates the `sec-*/case.yaml` files from one table; edit that,
not the YAML.

## Resumed-session cases

`apply-wrong-fix` and `apply-discovery` test what happens *after* the user replies to a
review, which a single-prompt case can't reach. Each sets `context.history_file:
history.jsonl` -- a session in which `/branch-review` already ran -- and its prompt is the
user's reply ("1, 2"). `lib/make_history.py` builds that session from the case's
`history.json` (the authored review list, and the log it wrote) plus the **current**
SKILL.md, and `run.sh` regenerates it before every run, so the skill text in the history
can't drift from the prompt under test. The scaffold installs the log where the history
says it went (`.review-logs/`, git-ignored), so graders can read the real file.

The CLI writes the live session back next to the case as `<session-id>.jsonl`. Those files
record the full request context, account details included; `.gitignore` keeps them out.

## Writing llm graders that don't misfire

`run.sh` sets `--judge-model sonnet`. The CLI's default judge, Haiku, failed reviews that
plainly contained the finding four times across the first two Sonnet baselines, and a
count (`keeps-the-list-short`) is now a `regex` grader for the same reason. Any judge
reads criteria literally, and in this suite's first scored runs every false FAIL came
from criteria phrased as prohibitions: "must NOT flag the basis-points comment" failed a review that cited it as
the example to follow; "does not propose adding doc blocks" failed a review whose only
doc-block proposal was to remove one. What fixed them:

- Write an explicit `PASS if ...` and `FAIL if ...`, rather than "the review does not ...".
- Say what is *allowed* near the line you're drawing -- citing the comment as a good
  example, proposing removal, a finding labelled Optional.
- Say what doesn't matter (severity label, wording).
- Set `focus: last_message` when the criterion is about the review itself rather than
  the tool calls that produced it.

Smoke a new grader with `run.sh --smoke <case> --runs 2` and read the review in the
report before trusting a FAIL.

## Writing a new case from your log data

The disposition column tells you which grader you need:

- **`missed` row** -> an `llm` grader asserting the review *does* report it. Build a
  fixture with the same defect shape.
- **`wrong` / `handled` / `preexisting` row** -> an `llm` grader asserting it does *not*,
  or a `regex` grader with `match: not_contains`. These are the valuable ones; a corpus
  of things a reviewer wrongly flagged is not something you can synthesize.
- **`preference` row** -> extend `style-citation` rather than adding a case.
- **`gate_held: no`** -> already covered by the gate grader everywhere.

Do not copy client code into a fixture. Reconstruct the *shape* of the defect -- same
language, same layering, same doc-block regime -- in a neutral repo built by
`scaffold_script`. It is more work than copying and it is not negotiable.

## Case schema

Enforced by the CLI (`schema_version: "1.0"`):

```
schema_version, name, description?, tags[], plugins[]?, runs (default 3),
expected_outcome?
context:   scaffold_script? (a path, relative to the case dir -- not inline bash), history_file?, add_dirs[]
execution: prompt?, max_turns (<=200, default 10), timeout_seconds (<=3600, default 300),
           model?, allowed_tools[], append_system_prompt?, env{} (EVAL_* keys only)
graders:   at least one, unique names
```

Grader `type` is one of `regex` | `tool_order` | `tool_used` | `file_exists` | `llm` |
`baseline`. All take `name` and `weight`. `regex` takes `target` (`trace` |
`last_message` | `files` | `mock_calls` | `{source: file, path}`), `pattern`, `flags`,
and `match` (`contains` | `not_contains` | `count:N`). `tool_used` takes `tool`,
`input_match?`, `min?` (default 1), `max?`. `llm` takes `criteria` and `focus`.
