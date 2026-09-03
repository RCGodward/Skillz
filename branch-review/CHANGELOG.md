# branch-review changelog

Versions match `.claude-plugin/plugin.json`. A log entry's `skill_version` field says
which one produced it.

## 0.4.0 — 2026-09-02

- The review now records anything it finds while applying an approved fix as a `missed`
  row in the log, instead of leaving it to be reconstructed from the transcript. Scoped to
  issues the branch introduced or worsened — a problem in untouched code is not a miss,
  because the review is told not to report pre-existing issues. Those get an HTML comment
  under the table instead.
- Self-found misses are noted `[apply]` so `tally.sh` can report them separately from the
  ones a human caught. A miss found on a closer read points at `<verify>`; a miss you had
  to catch points at the review pass itself.

## 0.3.0 — 2026-09-02

- Log filenames carry a timestamp (`YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`). Reviewing a
  branch, applying fixes, and reviewing again the same day used to overwrite the first
  entry.
- Slashes in branch names are flattened. `feat/billing` would have been written as a path,
  silently creating a directory.
- Replaced the `-2`/`-3` collision suffix with a plain never-overwrite rule; the suffix
  scheme depended on remembering to check for a collision, which is what failed.

## 0.2.0 — 2026-09-02

- The review writes its own pre-filled evaluation log when it reports findings, to
  `~/.branch-review-log/` (`BRANCH_REVIEW_LOG_DIR` overrides), and sets `applied` on
  whatever gets approved. Judgment columns are left blank on purpose.
- Written with a Bash heredoc rather than the Write tool, so `Write` can stay out of
  `allowed-tools` and the approval gate keeps its one piece of tool enforcement.
- Never writes into the repo under review.
- Packaged as a plugin (`.claude-plugin/plugin.json`) with a `claude plugin eval` suite
  under `evals/`, so the skill is a valid eval target. `install.sh` strips `evals/`.

## 0.1.0 — 2026-09-01

- Initial skill. One pass over a branch covering correctness, security audit, conformance
  to the surrounding code's existing style, and comment/doc-block discipline, ending in a
  numbered list of proposed corrections and a stop before any file is edited.
- Style findings must cite an existing example in the repo, so the review holds the host
  codebase's conventions instead of importing defaults.
- Inline comments are kept only where they explain non-intuitive behavior; doc blocks
  follow the file's and its siblings' existing convention rather than being added.
- Ships a portable prompt variant for tools that don't load Claude Code skills.

<!--
Versions before 0.2.0 predate the marker in SKILL.md. Logs written by 0.2.0-0.4.0 record
skill_version as v2/v3/v4, which correspond to 0.2.0/0.3.0/0.4.0.
-->
