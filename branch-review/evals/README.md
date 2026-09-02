# Eval cases for branch-review

Run with `claude plugin eval` from the repo root:

```sh
claude plugin eval ./branch-review --allow-tools Bash Edit --no-publish
claude plugin eval ./branch-review --case doc-block-\* --no-publish   # one case
```

**`plugin eval` is in early access.** On an account without it the command exits with
`\`plugin eval\` is currently in early access` and does nothing. Nothing below has been
executed yet — the cases are written against the schema the CLI enforces and their
scaffold scripts are verified to build the fixtures they claim, but no case has ever
been scored.

## Two flags that matter

**`--no-publish`.** The HTML report publishes to claude.ai by default. Every fixture here
is synthetic, so it's safe as it stands — but the moment a case is derived from client
work, `--no-publish` is not optional.

**`--allow-tools Bash Edit`.** The skill's own `allowed-tools` does not apply inside an
eval run; the case's `execution.allowed_tools` governs, and gated tools additionally need
this operator grant. Bash is needed for git. **Edit is granted on purpose**: every case
asserts `tool_used: Edit, max: 0`, and that assertion is worthless if the run couldn't
have edited anything in the first place. Granting Edit is what turns the approval gate
from an untested claim into a tested one.

## Ablation

With a plugin target, `--ablation with-without` is the default: each case also runs with
the skill disabled and reports the delta. That answers "does the skill beat bare Claude
on this case", which the disposition log can't — you only ever see the with-skill arm in
real use.

It does **not** tell you which section of SKILL.md is carrying the result. For that,
copy the skill, delete one section, and run the same cases against both targets.

## The cases

| Case | Asserts | Failure it guards |
|---|---|---|
| `doc-block-discipline` | Flags JSDoc in a repo that uses none; flags a restating comment; leaves the basis-points comment alone; proposes adding no doc blocks | The rule most likely to rot, and the one with a crisp right answer |
| `style-citation` | Every style finding cites a file in the fixture; catches the dropped tenant scope | `preference` rows — findings asserted from general convention rather than this repo |
| `no-preexisting-noise` | Doesn't report untouched pre-existing code as a finding; keeps the list short | `preexisting` and `wrong` rows — the false positives that cost trust |

Every case also carries the gate grader.

## Writing a new case from your log data

The disposition column tells you which grader you need:

- **`missed` row** → an `llm` grader asserting the review *does* report it. Build a
  fixture with the same defect shape.
- **`wrong` / `handled` / `preexisting` row** → an `llm` grader asserting it does *not*,
  or a `regex` grader with `match: not_contains`. These are the valuable ones; a corpus
  of things a reviewer wrongly flagged is not something you can synthesize.
- **`preference` row** → extend `style-citation` rather than adding a case.
- **`gate_held: no`** → already covered by the gate grader everywhere.

Do not copy client code into a fixture. Reconstruct the *shape* of the defect — same
language, same layering, same doc-block regime — in a neutral repo built by
`scaffold_script`. It is more work than copying and it is not negotiable.

## Case schema

Enforced by the CLI (`schema_version: "1.0"`):

```
schema_version, name, description?, tags[], plugins[]?, runs (default 3),
expected_outcome?
context:   scaffold_script?, history_file?, add_dirs[]
execution: prompt?, max_turns (≤200, default 10), timeout_seconds (≤3600, default 300),
           model?, allowed_tools[], append_system_prompt?, env{}
graders:   at least one, unique names
```

Grader `type` is one of `regex` | `tool_order` | `tool_used` | `file_exists` | `llm` |
`baseline`. All take `name` and `weight`. `regex` takes `target` (`trace` |
`last_message` | `files` | `mock_calls` | `{source: file, path}`), `pattern`, `flags`,
and `match` (`contains` | `not_contains` | `count:N`). `tool_used` takes `tool`,
`input_match?`, `min?`, `max?`. `llm` takes `criteria` and `focus`.
