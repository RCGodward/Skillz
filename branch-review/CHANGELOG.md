# branch-review changelog

Versions match `.claude-plugin/plugin.json`. A log entry's `skill_version` field says
which one produced it.

## 0.6.0 -- 2026-10-25

Every change here came from an eval failure on Sonnet; `certification/ITERATION-LOG.md`
has the before/after numbers for each.

- Naming findings cite the line where a sibling declares the name, not just the name.
- The log is written before the findings are presented, so the list, the approval prompt,
  and the log path end the turn together. A tool call after the list sometimes ended the
  turn on a bare log-path message.
- `--fix` ends on the full numbered list with applied items marked **Applied**, then the
  test result. It used to say "present the list first"; Sonnet would not hold that once
  the edits were pre-approved, and its after-the-fact summary hid the Optional items.
- Large diffs: **Reviewed** says, per file group, what was read in full, skimmed, or
  deferred.
- Inconsistent conventions: name both sides in the finding itself, with citations.
- Security findings state entry point (route *and* parameter), path, impact, and fix.
  That rule lived only in the checklist, which was often not opened; the checklist read
  is now unconditional.
- Declared rules: a rule written in `CONTRIBUTING.md`/`CLAUDE.md`/`AGENTS.md`/docs
  outranks inferred conventions and gets cited; linter and formatter configs are weighed
  against the code. The old text said both "declared rules outrank inferred ones" and
  "prefer the code over the config". (A first rewording of the config sentence cut
  `local-neighborhood-wins` from 5/6 to 1/6; the original sentence is kept verbatim.)
- Removed: the flow summary, the file-history step, the `<notes>` section (restatements
  of rules elsewhere), and a duplicated `.editorconfig`.
- Eval suite: 3 cases -> 15, Sonnet as both model and judge.

## 0.5.0 -- 2026-09-03

- Version numbering collapsed to one authoritative value. The marker at the top of
  `SKILL.md` now carries the semver rather than a separate `vN` counter, and
  `check-versions.sh` at the repo root fails if the marker, `plugin.json`, and the top
  changelog heading disagree. A log's `skill_version` now names a changelog section
  directly.
- Logs written before this say `v2`, `v3`, `v4`; those correspond to 0.2.0, 0.3.0, 0.4.0.

## 0.4.0 -- 2026-09-02

- The review now records anything it finds while applying an approved fix as a `missed`
  row in the log, instead of leaving it to be reconstructed from the transcript. Scoped to
  issues the branch introduced or worsened -- a problem in untouched code is not a miss,
  because the review is told not to report pre-existing issues. Those get an HTML comment
  under the table instead.
- Self-found misses are noted `[apply]` so `tally.sh` can report them separately from the
  ones a human caught. A miss found on a closer read points at `<verify>`; a miss you had
  to catch points at the review pass itself.

## 0.3.0 -- 2026-09-02

- Log filenames carry a timestamp (`YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`). Reviewing a
  branch, applying fixes, and reviewing again the same day used to overwrite the first
  entry.
- Slashes in branch names are flattened. `feat/billing` would have been written as a path,
  silently creating a directory.
- Replaced the `-2`/`-3` collision suffix with a plain never-overwrite rule; the suffix
  scheme depended on remembering to check for a collision, which is what failed.

## 0.2.0 -- 2026-09-02

- The review writes its own pre-filled evaluation log when it reports findings, to
  `~/.branch-review-log/` (`BRANCH_REVIEW_LOG_DIR` overrides), and sets `applied` on
  whatever gets approved. Judgment columns are left blank on purpose.
- Written with a Bash heredoc rather than the Write tool, so `Write` can stay out of
  `allowed-tools` and the approval gate keeps its one piece of tool enforcement.
- Never writes into the repo under review.
- Packaged as a plugin (`.claude-plugin/plugin.json`) with a `claude plugin eval` suite
  under `evals/`, so the skill is a valid eval target. `install.sh` strips `evals/`.

## 0.1.0 -- 2026-09-01

- Initial skill. One pass over a branch covering correctness, security audit, conformance
  to the surrounding code's existing style, and comment/doc-block discipline, ending in a
  numbered list of proposed corrections and a stop before any file is edited.
- Style findings must cite an existing example in the repo, so the review holds the host
  codebase's conventions instead of importing defaults.
- Inline comments are kept only where they explain non-intuitive behavior; doc blocks
  follow the file's and its siblings' existing convention rather than being added.
- Ships a portable prompt variant for tools that don't load Claude Code skills.

<!--
0.1.0 predates the marker in SKILL.md entirely. Logs written by 0.2.0-0.4.0 record
skill_version as v2/v3/v4, which correspond to 0.2.0/0.3.0/0.4.0. From 0.5.0 the marker
and the log field carry the semver itself.
-->
