# Evaluating branch-review

Two loops, both cheap. The log is the one that matters day to day; the replay
harness is for when you want ground truth or are testing a change to the skill.

## 1. Disposition log — from real use

The skill writes the entry itself. When it reports findings it drops a pre-filled log to
`~/.branch-review-log/` (override with `BRANCH_REVIEW_LOG_DIR`) — metadata, one row per
finding, and `applied` already set on whatever you approved. It never writes into the
client repo.

Pull the entries over when you're back here:

```sh
./collect.sh --list   # what's waiting, and how many rows are still uncoded
./collect.sh          # move them into log/
```

Then fill in the disposition column. That's the part no tool can do for you, and it's
the only part that matters. One minute per review.

`log/TEMPLATE.md` is the manual fallback for the portable prompt or another tool; name
it the same way the skill does, `YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`, so that reviewing
the same branch twice in a day gives you two entries rather than one.

The point is not the count of findings, it's **why you rejected the ones you rejected**.
That column is the improvement backlog, ranked by frequency.

Entries stay local — `.gitignore` keeps `eval/log/*.md` out of the repo, since a log
names a real repository, a branch, and defects in code that may not be yours to publish.
Only `TEMPLATE.md` is tracked. If you want them versioned, put them somewhere private
rather than loosening this.

### Disposition codes

| Code | Means | Usually points at |
|---|---|---|
| `applied` | You took the fix | — |
| `wrong` | The code doesn't do what the finding claims | verify step |
| `handled` | Real concern, but already covered by a caller, middleware, guard, or framework | verify step |
| `preexisting` | True, but not introduced by this branch, and not flagged as such | verify step |
| `preference` | A convention this repo doesn't actually hold — cited nothing, or cited wrong | house_style / sibling selection |
| `not-worth-it` | True and this repo's convention, but not worth the churn | severity calibration |
| `missed` | Anything the review didn't report — caught by you, by a human reviewer, or by the skill itself while applying a fix (those are prefixed `[apply]`) | the relevant review pass |

Use `missed` rows freely — record them with `-` in the number column. A skill that
produces a clean, short, *incomplete* list is failing quietly, and nothing else surfaces it.

The skill fills in some of these itself: when applying an approved fix turns up something
the review should have caught, it adds a `missed` row noted `[apply]`. `tally.sh` splits
those out, because they say something different — a miss it found on a closer read is the
`<verify>` step not looking, while a miss you had to catch is the review pass not covering
the ground at all. Issues in code the branch never touched are deliberately excluded; the
review is told not to report pre-existing problems, so counting them as misses would
penalise it for obeying that rule.

Then:

```sh
./tally.sh
```

Counts dispositions by category across every log entry and names the section of
`SKILL.md` each pattern implicates. Don't act on a single review — act when a
reason clears roughly a dozen occurrences, or when one category is visibly worse
than the others.

## 2. Replay harness — ground truth from history

Merged PRs are labeled data: a human already reviewed them, and later commits
already told you which bugs got through.

```sh
./replay.sh --repo ~/clients/acme/api --limit 10
```

For each merged PR this collects the diff, the merge-base the skill should review
against, and every human review comment on it, into `replay/<repo>/pr-<n>/`. It
prints the command to run the review yourself, or use `--run` to invoke Claude Code
headlessly and capture the findings automatically.

Then compare `skill-findings.md` against `human-review.md` per PR. You're looking
for three things: what the human caught that the skill didn't (`missed`), what the
skill flagged that the human didn't care about (a false-positive candidate — check
before believing it, humans miss plenty), and whether style findings cite real
examples from that repo.

`--clean` removes the worktrees it created in the target repo when you're done.

Needs `gh` and `git` only — JSON is parsed with gh's built-in `--jq`, so a standalone
`jq` isn't required (it isn't on most Windows boxes).

### Testing a change to the skill

Change **one section**, re-run the same PR set, diff the findings. Otherwise you
won't know which edit did what. Keep a stable set of 8–10 PRs across two or three
client repos with different style regimes — that mix is what makes the results
mean something, since conformance to the host codebase is the part that's hard.

### Doc-block regression

The doc-block rule is the one with a crisp right answer, so it's worth a fixture:
the same change applied to a file in a repo that uses doc blocks everywhere, one
that uses none, and one that's inconsistent. Correct behavior differs in each and
is binary — add, match, or flag for removal. Any client repo of each kind will do;
you don't need to build one.
