# Branch review — portable prompt

Self-contained version of the `branch-review` skill for tools that don't load Claude Code
skills (Cursor, Copilot, Codex, Gemini CLI, Windsurf, a chat window). Paste the whole thing,
or drop it into a client's `AGENTS.md` / `.cursor/rules/` as a review rule.

---

Review the changes on this branch. Work through it in this order and don't skip a step.

**1. Scope.** Diff the branch against its base (`main`/`master`/`develop`, or the base I
named). Use the merge-base, not a straight two-dot diff. Then read the *full current
version* of every substantially-changed file, not just the diff hunks — the surrounding
code holds the contract, the existing helpers, and the patterns I care about. If the diff
is huge, review the highest-risk files first (auth, data access, input handling, money,
migrations, config) and tell me what you deferred.

**2. Learn this codebase's style before you judge anything.** Read any committed style
rules (`.editorconfig`, linter/formatter configs, `CONTRIBUTING.md`, `AGENTS.md`), then
read 2–3 existing files that are the closest analogs of each changed file — same directory,
same layer, same kind of thing. Those files are the standard, not your defaults and not any
external style guide. Where the codebase disagrees with itself, the local neighborhood wins;
say so rather than picking a side.

**Every style comment you make must cite an existing example in this repo**
(`file.ext:lines`). If you can't cite one, it's your preference, not this project's
convention — drop it.

**3. Review in four passes.**

- *Correctness* — bugs this change introduces: boundary conditions, null paths, swallowed
  or mislabeled errors, async problems (unawaited work, races, missing cancellation),
  resource leaks, N+1 queries, broken contracts for existing consumers, and other callers
  of a changed shared function that weren't updated (search for them). Also: tests that
  assert the mock instead of the behavior, or were quietly skipped.

- *Security audit* — trace untrusted input to its sink. Injection (SQL, command, path,
  template, XXE, SSRF), XSS and unsafe rendering, missing or misplaced authorization on new
  endpoints, IDOR and missing tenant scoping, secrets in code/config/logs, weak or
  hand-rolled crypto, mass assignment, CSRF on new state-changing routes, unsafe
  deserialization, file upload handling, open redirects, missing rate limits and timeouts,
  new dependencies with floating versions or install scripts, and risky migration/IaC
  changes. Only report what you can trace end to end — name the input, the path, the impact.

- *Style conformance* — does the new code look like it belongs where it landed? Naming,
  file and class layout, error handling, logging, async style, test structure, DI. Flag a
  hand-rolled helper that duplicates an existing one (search before claiming it). Do not
  flag personal preferences, modern-idiom upgrades, or anything that would require changing
  the whole codebase.

- *Comments and docs* —
  - Inline comments exist **only** to explain non-intuitive behavior: a workaround for a
    specific bug or API quirk, a non-obvious constraint or invariant, a deliberate tradeoff,
    a business or regulatory rule the code can't convey. Flag comments that restate the
    code, narrate the obvious, act as section labels, are commented-out code, or have gone
    stale against the code they describe.
  - **Do not add XML doc blocks / JSDoc / docstrings unless that file already uses them, or
    its closest sibling files do.** Check before proposing any. If the new code added doc
    blocks that the file and its siblings don't use, flag them for removal. If the file does
    use them, match its existing tags and update any doc block whose code changed.

**4. Verify before reporting.** Re-check each finding against the full file: search for the
helper or guard you're about to call missing, confirm the "unhandled" case isn't handled by
a caller or middleware, confirm the convention you're citing is the local majority, confirm
the line is actually part of this branch's changes. Don't report pre-existing issues unless
they're security-relevant or this branch made them worse — and label them as pre-existing.
A short list of real findings beats a long list with nits in it.

**5. Present a numbered list of proposed corrections — and stop there.**

Group by severity (**Blocker**, **Should fix**, **Optional**), number continuously so I can
reply "1, 4, 7". For each: severity, `file:line`, one or two sentences on what's wrong and
why, the repo example it should match (for style items), and the proposed fix — code if
it's a line or two, a description if it's larger.

Then finish with what you reviewed (base, file count, anything deferred), one line on what
the change does well if anything, and any pre-existing issues you left alone.

**6. Then output a log entry** — one fenced markdown block I can save as
`YYYY-MM-DD-<repo>-<branch>-HHMMSS.md` (local time; replace any `/` in the branch name
with `-`). Write the file yourself if you can; paste it if you can't.
Fill in everything mechanical and leave the disposition column empty — that's my call, and
it's the whole reason the log exists.

````markdown
---
date: <today>
client: <repo owner>
repo: <repo name>
branch: <branch>
base: <base branch or merge-base sha>
language: <primary language of the diff>
files_changed: <n>
lines_changed: <n>
skill_version: portable
variant: portable-prompt
tool: <cursor | copilot | codex | gemini | other>
gate_held: yes
style_citations_ok:
---

<!-- disposition: applied | wrong | handled | preexisting | preference | not-worth-it | missed -->

| # | severity | category | disposition | note |
|---|---|---|---|---|
| 1 | blocker | security |  | missing tenant scope on order lookup |
| 2 | should-fix | correctness |  | unawaited ProcessAsync |
| - |  |  | missed |  |
````

One row per finding, same numbers as the list, with a six-to-eight word note — enough for
me to recognize it later, not the whole finding. Category is `correctness`, `security`,
`style`, or `comments`. Keep the trailing `missed` row blank for me. If I later approve
items, set those rows to `applied` and leave the rest alone.

**Do not edit any code yet.** Not even trivial fixes. Wait for me to pick the numbers I
want, then apply exactly those — nothing adjacent, no drive-by cleanups, no reformatting.
After applying, tell me what changed, run the project's tests or build if there's an obvious
command, and report the result honestly, failures included.
