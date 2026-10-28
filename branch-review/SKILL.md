---
name: branch-review
description: "Review the changes on a branch in one pass -- correctness, security audit, conformance to the surrounding code's existing style, and comment/doc-block discipline -- then present a numbered list of proposed corrections and wait for approval before editing anything. Use when asked to review a branch, diff, or PR; to security-audit pending changes; or to check that new code matches the house style of the codebase it landed in."
argument-hint: "[base-branch | PR# | path] [--fix] [--security-only] [--style-only]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
---

<!-- branch-review 0.6.0 -->

<objective>
Review the changes on this branch against **the standards of the codebase they were added to**,
not against any external style guide. Produce a numbered, reviewable list of proposed
corrections. Edit nothing until the user approves specific items.
</objective>

<scope>
Resolve what to review, in this order:

1. `$ARGUMENTS` names a base branch (`main`, `develop`, `origin/release/2.1`) -> diff against it.
2. `$ARGUMENTS` is a PR number -> that PR's diff (`gh pr diff`, or fetch its branch without `gh`).
3. `$ARGUMENTS` is a path -> restrict to files under it, still diffed against the base.
4. No arguments -> find the base automatically:
   `git merge-base HEAD $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)`
   Try `origin/main`, `origin/master`, `origin/develop`, `origin/trunk` in order. If none
   resolve, ask which base to use -- do not guess a base that produces a 400-file diff.
5. If the branch has no commits ahead of base, review uncommitted work instead
   (`git diff HEAD` plus `git status --porcelain` for untracked files) and say that's what you did.

Then get the review surface:
- `git diff --stat <base>...HEAD` -- size check.
- `git diff <base>...HEAD` -- the changes themselves.
- Read the **full current version** of every substantially-changed file. A diff hunk hides
  the surrounding contract: the helper that already exists, the validation two functions up,
  the disposal pattern the rest of the class uses. Most false findings come from reviewing
  hunks instead of files.

If the diff exceeds ~2000 changed lines, say so, review the highest-risk files first
(auth, data access, input handling, money, migrations, config), and say in **Reviewed**
how you handled the rest, by group: read in full, skimmed (e.g. generated tables), or
deferred. "Nothing deferred" alone doesn't tell the user where your attention went.
</scope>

<house_style>
**Do this before judging anything.** The whole point of this review is that the code should
look like it belongs where it is. You cannot assess that until you know what "there" looks like.

Gather evidence, cheapest first:

1. **Declared rules** -- read whatever exists: `CONTRIBUTING.md`, `CLAUDE.md`/`AGENTS.md`,
   `docs/style*`, and linter/formatter configs (`.editorconfig`, `.eslintrc*`, `biome.json`,
   `.prettierrc`, `.stylecop.json`, `ruff.toml`/`pyproject.toml`, `.rubocop.yml`,
   `checkstyle.xml`, `Directory.Build.props`). A rule written in those documents outranks
   anything you infer; cite the file it comes from in the finding. Configs are weighed
   against the code, below.
2. **Sibling files** -- for each changed file, read 2-3 existing files that are its closest
   analogs (same directory, same layer, same suffix: another controller, another repository,
   another reducer, another test). These are your ground truth. Before citing a pattern
   as the convention, grep for it and its obvious alternative across the changed file's
   directory: two siblings agreeing doesn't mean the third does.

From that evidence, note the conventions that actually apply here -- naming, file/class layout,
error handling, logging, async style, null/optional handling, test structure, DI patterns,
string formatting, import ordering. Prefer what the code does over what a config claims,
where they disagree, and mention the disagreement.

**Hard rule:** every style finding must point at an existing example in this repo --
`Matches src/Services/OrderService.cs:40-58` -- or it does not get reported. If you cannot
cite one, the convention is your preference, not theirs, and it is out of scope.
Naming findings too: cite the line where a sibling declares the name
(`src/Services/CustomerService.cs:12`), not just the name. Only a finding about a file's
own name may cite the sibling's path alone.

Corollary: where the codebase is internally inconsistent, the local neighborhood wins.
Say so in the finding itself, citing both sides, so it doesn't read as a repo-wide rule:
"This directory uses X (`a.ts:4`); the older modules use Y (`legacy/b.ts:9`)."
</house_style>

<passes>
Run all four over the diff. Skip security/style only if `--security-only` / `--style-only` was passed.

### 1. Correctness
Bugs the change introduces or fails to handle. Look for: off-by-one and boundary conditions;
null/undefined paths the new code opens; error paths that swallow, mislabel, or leak;
async issues (unawaited work, races, missing cancellation, sync-over-async); resource leaks
(connections, handles, subscriptions, timers); state mutated where the surrounding code
treats it as immutable; N+1 queries and unbounded loops over external calls; changed behavior
of a shared function whose *other* callers weren't updated -- grep for them; contracts broken
for existing consumers (signature, serialization shape, DB schema, config keys);
tests that assert the mock rather than the behavior, or that were deleted/skipped quietly.

### 2. Security
Work through the categories below that match the languages and surfaces in this diff,
even when it looks safe: the ones you wouldn't think of unprompted are the reason the list
exists. "Could be unsafe" without a traced path is noise; skip it.

Report a finding only where you can trace it end to end, and state all four:
- **Entry point** -- the route, handler, job, or command, *and* the parameter
  (`POST /orders`, body `couponCode`), not just the variable name.
- **Path** -- how the value reaches the sink.
- **Impact** -- what an attacker concretely gets: whose data, read or write, what scope.
- **Fix** -- the specific change.

#### Input and injection
- SQL / ORM raw fragments built with string concatenation or interpolation. Parameterize.
  Check dynamic `ORDER BY`/table names -- parameters don't cover identifiers; use an allowlist.
- Command execution built from input (`exec`, `spawn` with shell, `Process.Start`,
  backticks, `os.system`). Prefer argv arrays over shell strings.
- Path traversal: user-controlled segments reaching file APIs. Canonicalize, then confirm
  the resolved path stays under the intended root.
- Deserialization of untrusted data into polymorphic types (`BinaryFormatter`,
  `TypeNameHandling.All`, `pickle`, unsafe YAML, Java native). Type-restricted or don't.
- Template/expression injection (SSTI, SpEL, EL) from user strings.
- LDAP, XPath, NoSQL operator injection (`$where`, `$ne` from a JSON body).
- XXE: XML parsers with external entities or DTDs enabled.
- SSRF: a URL from input fetched server-side. Allowlist host and scheme; block redirects to
  internal ranges and cloud metadata endpoints.

#### Output and rendering
- XSS: `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `Html.Raw`, `|safe`, unescaped
  interpolation into markup. Confirm sanitization is on the untrusted value, not just nearby.
- Untrusted data into a URL, an `href`/`src` (`javascript:`), a CSS value, or an inline event.
- Response headers or log lines built from input (header/log injection, CRLF).
- CSV/formula injection in exported data.

#### AuthN / AuthZ
- A new endpoint, route, handler, or GraphQL resolver with no auth attribute/middleware --
  compare against how its siblings are protected; the gap is usually the tell.
- Authorization checked in the UI, the caller, or the gateway but not at the resource.
- IDOR: an object id from input loaded without an ownership/tenant scope check.
- Multi-tenant queries missing the tenant predicate.
- Role checks by string comparison, negation chains, or client-supplied claims.
- Token/session handling: expiry, revocation, rotation on privilege change, fixation.
- JWTs: algorithm not pinned, signature unverified, `none` accepted, `kid` used as a path.

#### Secrets and configuration
- Keys, tokens, passwords, connection strings, private keys committed in code, config,
  tests, fixtures, or comments. Check new config and `.env*` files specifically.
- Secrets logged, echoed in errors, or included in telemetry/analytics payloads.
- Debug flags, verbose errors, permissive CORS (`*` with credentials), or disabled TLS
  verification introduced for local work and left in.
- Dependencies added: unfamiliar or typo-squattable package names, `latest`/floating
  versions, install scripts, or a lockfile edited by hand.

#### Crypto and data
- Hand-rolled crypto, ECB mode, static/reused IVs, `Math.random` for anything security-bearing.
- Passwords stored with a fast hash or no salt; use the platform's password hash.
- MD5/SHA-1 for signatures or integrity (fine for a cache key -- say which case it is).
- PII/PHI/card data newly written to logs, added to a response body, sent to a third party,
  or stored without the encryption the surrounding code applies.
- Data-retention or deletion paths that miss a new store.

#### Web and API surface
- CSRF protection missing on a new state-changing form/endpoint that uses cookie auth.
- Mass assignment: request body bound straight to an entity, letting `isAdmin`/`role` through.
- Missing rate limiting on auth, reset, invite, or expensive endpoints.
- File upload: type/size unchecked, original filename trusted, stored inside the web root.
- Redirects to a user-supplied URL (open redirect).
- Error responses leaking stack traces, SQL, or internal hostnames.

#### Timing, concurrency, and resource use
- Secret/token comparison not constant-time.
- TOCTOU between a check and its use (permission checks, file existence, balance checks).
- Unbounded allocation, decompression, or regex on user input (ReDoS, zip bombs).
- Missing timeouts on outbound calls.

#### Language-specific quick hits
- **C#/.NET** -- `BinaryFormatter`; `JsonSerializerSettings.TypeNameHandling`; SQL via
  `FromSqlRaw`/`ExecuteSqlRaw` with interpolation; `[AllowAnonymous]` added; `Html.Raw`;
  `ServerCertificateCustomValidationCallback` returning true; `Process.Start` with a shell.
- **JS/TS** -- prototype pollution in deep merges; `eval`/`new Function`/`setTimeout(string)`;
  `child_process.exec` vs `execFile`; Express routes missing auth middleware; `postMessage`
  handlers without an origin check; secrets in `NEXT_PUBLIC_*`/bundled client config.
- **Python** -- `pickle`, `yaml.load` without `SafeLoader`, `subprocess(..., shell=True)`,
  f-strings in SQL, Jinja `|safe`, `assert` used for a runtime security check.
- **Java** -- native deserialization, `Runtime.exec` with a string, XXE defaults in
  `DocumentBuilderFactory`, Spring endpoints missing `@PreAuthorize` where siblings have it.
- **Go** -- `fmt.Sprintf` into SQL, ignored errors on security-relevant calls, `InsecureSkipVerify`.
- **SQL/migrations** -- a migration that widens a permission, drops a constraint, backfills
  with a default that breaks a tenant scope, or is not reversible.
- **IaC/CI** -- public buckets, `0.0.0.0/0` ingress, wildcard IAM, secrets in workflow env,
  a workflow triggered by `pull_request_target` that checks out untrusted code.

### 3. Style conformance
Only against conventions evidenced in `<house_style>`. Typical real findings: a new class
that doesn't follow the layering/naming of its siblings; error handling invented here when
the codebase has an established pattern; a hand-rolled helper duplicating one that exists
(grep before claiming this); logging that skips the project's logger or structure;
tests shaped unlike the neighboring tests; formatting that a committed linter config
would reject.

Not findings: personal preferences, modern-idiom upgrades, patterns the whole codebase
would need to adopt, or reformatting untouched lines.

### 4. Comments and documentation
Two rules, applied strictly:

**Inline comments exist only to explain non-intuitive behavior.** Keep or add a comment
when it explains *why* -- a workaround for a specific bug or API quirk, a non-obvious
constraint or invariant, a deliberate deviation, a chosen tradeoff, a regulatory or
business rule that isn't inferable from the code. Flag comments that restate what the
code plainly says, narrate the obvious (`// loop through items`), label sections that
naming should carry, are commented-out code, or have drifted out of sync with the code --
a stale comment is a bug report, not a nit.

**Doc-block comments follow the file's existing convention.** Before proposing or keeping
any XML doc block / JSDoc / docstring / KDoc, check prevalence:
- Does the file already use them? -> match that, including which tags it actually uses.
- If not, do its closest siblings? -> check 2-3, and note the ratio.
- Neither? -> flag the new doc blocks as out of place and propose removing them.
Never add doc blocks to a file or area that doesn't have them, even on public APIs, and
even if a linter *could* be configured to want them. Existing doc blocks on code the
branch changed must be updated to match the new behavior -- a doc block describing the old
signature is a finding.
</passes>

<verify>
Before writing the list, re-check each finding against the full file and the wider repo.
Drop anything you cannot defend. Specifically:
- Grep for the helper/validation/guard you're about to say is missing -- it may exist upstream.
- Confirm the "unhandled" case isn't handled by a caller, a middleware, a filter, or an attribute.
- Confirm a "wrong" convention isn't the local majority.
- Re-read the hunk: is the line you're flagging actually part of this branch's changes?

Report nothing that already existed on the base branch unless it is a security issue or the
branch materially worsened it -- say explicitly when a finding is pre-existing.

A short list of real findings is the deliverable. Padding it with nits costs the user more
than missing a nit does.
</verify>

<output>
Present findings as a numbered list, grouped by severity, most severe first. Number
continuously across groups so the user can reply "1, 4, 7".

Severity:
- **Blocker** -- will break, corrupt data, or expose something. Merge shouldn't happen.
- **Should fix** -- real bug in an edge case, contract drift, security hardening, or a
  clear break from house style.
- **Optional** -- small consistency and comment items. Fine to skip.

Each finding, kept tight:

```
### 3. [Should fix] Unawaited save leaves the transaction open
`src/Services/OrderService.cs:112`
`ProcessAsync` is called without await, so the scope disposes before the write lands.
Every other method in this class awaits its repository call (see line 58).
Fix: `await _repo.ProcessAsync(order, ct);`
```

Show the proposed code when it's a line or two; describe it when it's larger. Cite the repo
example for every style finding. Do not paste the full corrected file.

Close with a short section:
- **Reviewed** -- base, commit range, file count, and anything you deferred.
- **Looks good** -- one line on what the change does well, if it does. Not filler; skip if empty.
- **Not changed** -- pre-existing issues you noticed but left alone.
</output>

<approval_gate>
**Stop after presenting the list. Do not edit any file until the user replies.**

This is the point of the skill. No Edit, no Write, no `sed -i`, no "I went ahead and fixed
the trivial ones." Even a one-character fix waits.

End with: *"Reply with the numbers to apply (or 'all'), and I'll make just those changes."*
Then the one-line note about where the log entry landed (see `<log>`).

When the user replies:
- Apply exactly the approved items -- nothing adjacent, no drive-by cleanups, no reformatting.
- If applying one reveals a second issue, fix only what was approved and mention the new
  one. Record it in the log too -- see "Discoveries during apply" in `<log>`.
- If an approved fix turns out to be wrong on closer reading, say so instead of applying it.
- After applying: list what changed, run the project's existing test/build command if there
  is an obvious one, and report the result honestly -- including failures.
- After each fix, check the rest of the branch's new code for the same flaw: a missing
  guard or check rarely occurs once. Fix only what was approved; report what you find and
  log it (see "Discoveries during apply" in `<log>`).
- Leave rejected findings alone. Don't re-litigate them.

`--fix` in the arguments means the user pre-approved Blocker and Should-fix items: apply
those, run the tests, and leave Optional items for them to choose. Your final message is
then the **full numbered list** in the usual format, every item still in it, each applied
one marked **Applied**, followed by the test result and the approval prompt for what's
left. A summary of only what you changed hides the Optional items the user still has to
decide on.
</approval_gate>

<log>
Once the findings are verified, and **before** you present them, write an evaluation log
entry. It exists so the user can score the review later without reconstructing it from
memory. Writing it first keeps the list, the approval prompt, and the log path in one final
message; a tool call after the list tends to end the turn on a stray one-line reply.

Write it with a Bash heredoc, not the Write tool. This skill is deliberately not granted
`Write`, so that the approval gate can't be breached through it. That constraint holds here too.

Destination: `${BRANCH_REVIEW_LOG_DIR:-$HOME/.branch-review-log}/`, created if absent.
Filename: `YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`, local time, zero-padded. Replace any
`/` in the branch name with `-` -- `feat/billing` in a filename would otherwise create a
directory. The time is what keeps a second review of the same branch on the same day from
landing on the first one; never write over an existing file.
Never write the log into the repo under review -- it isn't yours to add files to.

Fill in everything mechanical. Leave every judgment call blank: the disposition column is
the whole point of the log, and it's the user's to make, not yours.

```markdown
---
date: <today>
client: <repo owner, as a starting point -- the user may recode it>
repo: <repo name>
branch: <branch reviewed>
base: <base branch or merge-base sha>
language: <primary language of the diff>
files_changed: <n>
lines_changed: <n>
skill_version: <the version from the marker at the top of this SKILL.md>
variant: skill
tool: claude-code
gate_held: yes
style_citations_ok:
---

<!-- disposition: applied | wrong | handled | preexisting | preference | not-worth-it | missed -->

| # | severity | category | disposition | note |
|---|---|---|---|---|
| 1 | blocker | security |  | missing tenant scope on order lookup |
| 2 | should-fix | correctness |  | unawaited ProcessAsync |
| - |  |  | missed |  |
```

- One row per finding, in the order you presented them, with the same numbers.
- `note` is a short label -- six or eight words, enough to recognize the finding later.
  Not the full finding; the user has that in the transcript.
- Keep the trailing `missed` row blank for the user to fill in with anything you didn't catch.
- `gate_held: yes` is true at the moment you write the file. If you later edit anything
  that wasn't approved, come back and change it to `no`. Do not quietly leave it at `yes`.
- Leave `style_citations_ok` empty. Whether a citation actually supports the finding is the
  user's call, and self-grading it is worthless.

Then present the list, and put where the log landed on one line after the approval prompt.

**After the apply step**, go back and set `disposition: applied` on the rows the user
approved. Leave every other row blank -- you know what they declined, not why, and the
reason is the part worth recording.

### Discoveries during apply

Applying a fix means reading the code far more closely than reviewing it did, so it is
normal to find something the review pass missed. When that happens, add a row to the log
in the same pass you mention it to the user.

**Only if it was in scope for the review** -- introduced by this branch, or code the diff
touched that the branch made worse. That is a genuine miss and the log should say so.

An issue in code the branch never touched is **not** a miss. The review is instructed not
to report pre-existing problems, so logging one as `missed` would penalise the skill for
following its own rule and inflate the number you steer by. Mention it to the user, and
record it as an HTML comment under the table rather than a row.

A qualifying row looks like:

```
| - | should-fix | correctness | missed | [apply] Cols==0 guard covers only one path |
```

- Number stays `-`; it was never in the numbered list.
- Severity and category as you would have reported them.
- **Prefix the note with `[apply]`.** It marks the row as self-found rather than caught by
  the user, which `tally.sh` reports separately -- the two mean different things about where
  the review pass is weak.
- Fill the blank placeholder `missed` row if it is still empty; otherwise append after it.
- Disposition stays `missed` even if the user then approves a fix for it. The fact being
  recorded is that the review didn't report it, not what happened afterwards.
</log>
