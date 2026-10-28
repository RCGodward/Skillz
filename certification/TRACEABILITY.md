# Instruction -> criterion traceability

Every instruction in `branch-review/SKILL.md` **0.7.0** (the resubmitted prompt),
including the 45 security-checklist bullets now inline in its security pass, and the eval
grader that fails if the instruction is ignored. Graders are named `case / grader` and
live in `branch-review/evals/<case>/case.yaml`.

An instruction is **load-bearing** when at least one grader fails without it. Counted the
way the Stage 3 review counted: the SKILL.md units below plus every checklist bullet.

Status: **graded**; **partial** -- graded, but part of the instruction isn't.

## Summary

| | 0.5.0 (start) | 0.6.0 (as reviewed) | **0.7.0 (resubmitted)** |
|---|---|---|---|
| SKILL.md instructions | 66 | 62 | 64 |
| Checklist bullets the prompt makes the model use | 45 | 45 | 45 (inline) |
| **Total** | 111 | 107 | **109** |
| Graded | 14 (13 + C16) | 59 (56 + 3 checklist) | **108** |
| Partial | 10 | 3 | **1** (L6) |
| No criterion | 87 | 45 (3 + 42 checklist) | **0** |
| **Load-bearing** | 22% | 58% (review's figure) | **100%** (99% fully graded) |

Counted mechanically from the tables below. 0.7.0 has two more SKILL.md instructions than
0.6.0 (H8b, G7, added in iteration 8) and none of 0.6.0's three exceptions: S2, G4 and
L10 now have criteria.

Graded is not the same as reliably followed: "Graded but unstable" below lists the
instructions that pass only part of the time, and the iteration log reports what the
checklist bullets add over bare Sonnet (most planted defects are found without them).

## Objective

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| O1 | Judge against this codebase's standards, not an external guide | graded | `style-citation / style-findings-are-evidenced`; `declared-rules / code-beats-the-formatter-config` |
| O2 | Produce a numbered list | graded | `correctness-callers / groups-and-numbers-findings`; `no-preexisting-noise / keeps-the-list-short` |
| O3 | Edit nothing until approved | graded | `gate-held-nothing-edited` (all 15 cases) |

## Scope

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| S1 | Base-branch argument -> diff against it | graded | Every finding grader in the 12 cases run as `/branch-review main` |
| S2 | PR number -> that PR's diff | graded | `scope-pr-number / asks-gh-for-the-pr`, `reviews-the-pr-change`, `does-not-review-mains-commit` (a stand-in `gh` in the fixture serves PR #42) |
| S3 | Path argument -> only files under it | graded | `scope-path / stays-inside-the-path`, `finds-the-billing-bug` |
| S4 | No args -> find the base from `origin/*` | graded | `scope-auto-base / resolves-the-base`, `finds-the-bug-in-the-first-commit`, `reports-the-base-it-used` |
| S4b | ...and ask if none resolves; don't guess | graded | `scope-no-base / asks-for-the-base` |
| S5 | No commits ahead -> review uncommitted work, say so | graded | `scope-uncommitted / says-it-reviewed-uncommitted-work`, `flags-the-committed-secret`, `covers-the-untracked-file` |
| S6 | Three-dot diff against the merge-base | graded | `scope-auto-base / finds-the-bug-in-the-first-commit` (bug is in the branch's first commit) |
| S7 | Read the full current file, not just hunks | graded | `full-file-read / finds-the-logout-gap` (the defect is in `logout()`, outside every diff hunk) |
| S8 | >2000 lines -> say so, risk-first, say how each group was handled | graded | `large-diff / says-what-it-deferred`, `catches-the-inverted-expiry` |

## House style

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| H1 | Learn the style before judging | graded | Every citation grader -- a cited sibling can't exist without it |
| H2 | Read declared rules; written rules outrank inference; cite the file | graded | `declared-rules / applies-the-declared-logging-rule` (must cite `CONTRIBUTING.md`) |
| H3 | Read 2-3 closest siblings per changed file | graded | `style-citation / style-findings-are-evidenced`, `cites-a-file-and-line` |
| H4 | Note the conventions that apply | graded | `style-citation` (naming, error handling), `declared-rules` (logging, async) |
| H5 | Code beats a config it disagrees with; mention it | graded | `declared-rules / code-beats-the-formatter-config`, `mentions-the-config-disagreement` |
| H6 | **Every style finding cites `file:line`** | graded | `style-citation / cites-a-file-and-line`, `style-findings-are-evidenced` |
| H7 | Naming findings cite the declaring line | graded | `style-citation / style-findings-are-evidenced` (iteration 1) |
| H8 | Inconsistent codebase -> local wins; name both sides in the finding | graded | `declared-rules / local-neighborhood-wins` (iterations 4, 6, 8) |
| H8b | Grep a pattern across the changed file's directory before calling it the convention | graded | `declared-rules / local-neighborhood-wins` (the inconsistent file is the third sibling; iteration 8) |

## Passes

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| P0 | Run all four; honor `--security-only` / `--style-only` | graded | `security-only / reports-no-style-or-comment-findings`; `style-only / skips-the-security-pass`, `reports-no-security-findings` |
| P1 | Correctness: boundaries, nulls, async, contracts... | graded | `correctness-callers / flags-the-unawaited-save`; `scope-path / finds-the-billing-bug`; `scope-auto-base / finds-the-bug-in-the-first-commit`; `large-diff / catches-the-inverted-expiry` |
| P1b | Grep for other callers of a changed shared function | graded | `correctness-callers / flags-the-unupdated-caller` (caller is in an untouched file) |
| P1c | Tests that assert the mock, or were skipped | graded | `correctness-callers / flags-the-skipped-test` (skipped); `test-asserts-mock / flags-the-test-asserting-its-mock` (asserts the mock) |
| P2 | Work through the categories that match the diff, even when it looks safe | graded | The 45 checklist rows below: each category is graded on whether a planted defect of that kind is reported |
| P2b | Security finding states entry point, path, impact, fix | graded | `security-trace / gives-the-trace` (iteration 5) |
| P2c | Report only what you can trace end to end; "could be unsafe" is noise | graded | `security-trace / does-not-flag-the-allowlisted-sort` |
| P3 | Style conformance against evidenced conventions | graded | `style-citation / style-findings-are-evidenced`; `declared-rules / local-neighborhood-wins` |
| P3b | Hand-rolled helper duplicating an existing one | graded | `correctness-callers / flags-the-duplicate-helper` |
| P3c | Not findings: preferences, idiom upgrades, untouched lines | graded | `no-preexisting-noise / keeps-the-list-short`; `declared-rules / code-beats-the-formatter-config` |
| P4a | Inline comments explain *why*; flag restating ones | graded | `doc-block-discipline / flags-the-restating-comment` (and must keep the basis-points *why* comment) |
| P4b | A stale comment is a finding | graded | `doc-block-match / flags-the-stale-inline-comment` |
| P4c | No doc blocks in file or siblings -> flag new ones for removal | graded | `doc-block-discipline / flags-the-jsdoc-as-out-of-place` |
| P4d | File uses doc blocks -> match its tags | graded | `doc-block-match / proposes-a-matching-doc-block` |
| P4e | Never add doc blocks where the area has none | graded | `doc-block-discipline / does-not-propose-adding-doc-blocks` |
| P4f | Doc block on changed code must be updated | graded | `doc-block-match / flags-the-stale-doc-block` |

## Verify

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| V1 | Grep for the guard before calling it missing | graded | `security-trace / does-not-flag-the-allowlisted-sort` (guard is in another file) |
| V2 | Check callers/middleware before calling a case unhandled | graded | Same grader |
| V3 | Confirm a "wrong" convention isn't the local majority | graded | `declared-rules / code-beats-the-formatter-config` |
| V4 | Only flag lines this branch changed | graded | `no-preexisting-noise / does-not-report-untouched-retry-as-a-finding` |
| V5 | Pre-existing -> only if security/worsened, and labelled | graded | Same grader (allows a labelled pre-existing note) |
| V6 | A short real list beats a padded one | graded | `no-preexisting-noise / keeps-the-list-short` |

## Output

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| U1 | Grouped by severity, numbered continuously | graded | `correctness-callers / groups-and-numbers-findings`; `findings-carry-a-severity` (5 cases) |
| U2 | Severity definitions | graded | `security-trace / reports-the-injection-as-a-blocker`; `large-diff / catches-the-inverted-expiry` (must be Blocker) |
| U3 | Each finding: `file:line`, what/why, fix; describe larger fixes | graded | `correctness-callers / groups-and-numbers-findings`; `doc-block-match / proposes-a-matching-doc-block` |
| U4 | Close with Reviewed / Looks good / Not changed | graded | `closes-with-reviewed-section` (5 cases); `large-diff / says-what-it-deferred` |

## Approval gate

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| G1 | Stop: no Edit, no Write, no `sed -i` | graded | `gate-held-nothing-edited`, `gate-held-no-write-tool`, `gate-held-no-shell-edits` |
| G2 | End with the "Reply with the numbers..." prompt, then the log line | graded | `ends-with-approval-prompt` (14 cases); `style-citation / tells-the-user-where-the-log-is` |
| G3 | Apply exactly what was approved; leave the rest alone | graded | `fix-flag / applies-the-await-fix`, `leaves-the-optional-comment` |
| G4 | A fix that's wrong on closer reading -> say so, don't apply | graded | `apply-wrong-fix / says-why-2-was-not-applied`, `keeps-the-fallback-the-wrong-fix-would-remove`, `makes-no-adjacent-change` (resumed session; the list holds a planted wrong finding) |
| G7 | After each fix, check the branch's other new code for the same flaw | graded | `apply-discovery / mentions-the-median-miss` (iteration 8) |
| G5 | After applying: list changes, run tests, report honestly | graded | `fix-flag / runs-the-project-tests`, `final-message-is-the-full-list` |
| G6 | `--fix`: apply Blocker/Should fix; end on the full list, applied marked | graded | `fix-flag / final-message-is-the-full-list` (iteration 4), `no-write-tool` |

## Log

| ID | Instruction | St. | Grader(s) |
|---|---|---|---|
| L1 | Write the log before presenting the list | graded | `ends-with-approval-prompt` (iteration 2) |
| L2 | Bash heredoc, never `Write` | graded | `style-citation / gate-held-no-write-tool`; `fix-flag / no-write-tool` |
| L3 | `$BRANCH_REVIEW_LOG_DIR` or `~/.branch-review-log`; never in the repo | graded | `style-citation / log-written-with-a-timestamped-name`, `log-not-written-into-the-repo` |
| L4 | `YYYY-MM-DD-<repo>-<branch>-HHMMSS.md`, `/` -> `-`, never overwrite | graded | `style-citation / log-written-with-a-timestamped-name` |
| L5 | Front matter, mechanical fields filled, `gate_held: yes` | graded | `style-citation / log-front-matter-is-complete` |
| L6 | One row per finding, same numbers and order | partial | Row shape graded (`style-citation / log-dispositions-left-blank`); exact rows graded in the resumed-session cases, whose findings are known (`apply-*/marks-1-applied`, `does-not-mark-2-applied`); for a fresh review, row-for-row agreement is checked by `tools/check_log_rows.py`, since no grader can compare two places in one transcript |
| L7 | Dispositions blank, `style_citations_ok` blank, trailing `missed` row | graded | `style-citation / log-dispositions-left-blank`, `log-front-matter-is-complete`, `log-keeps-the-missed-row` |
| L8 | Tell the user where it landed | graded | `style-citation / tells-the-user-where-the-log-is` |
| L9 | After apply, set `applied` on approved rows only | graded | `fix-flag / marks-applied-in-the-log`, `leaves-optional-row-blank-in-the-log` |
| L10 | Discoveries during apply: one question (did the branch add or change the code?) decides `[apply]` row vs comment | graded | `apply-discovery / logs-an-apply-miss` (iteration 9) |

## Security checklist (SKILL.md, security pass)

Inline in SKILL.md since 0.7.0, numbered in order. Each bullet has a planted defect and a
grader that passes only if the review reports it; C01, C16 and C20 reuse earlier cases.

| ID | Bullet | St. | Grader(s) |
|---|---|---|---|
| C01 | SQL / ORM raw fragments built with string concatenation or interpolation.... | graded | `security-trace / reports-the-injection-as-a-blocker`, `gives-the-trace`, `does-not-flag-the-allowlisted-sort` |
| C02 | Command execution built from input (`exec`, `spawn` with shell, `Process.Start`,... | graded | `sec-node-input / c02-command-execution` |
| C03 | Path traversal: user-controlled segments reaching file APIs. Canonicalize, then... | graded | `sec-node-input / c03-path-traversal` |
| C04 | Deserialization of untrusted data into polymorphic types (`BinaryFormatter`,... | graded | `sec-python-data / c04-unsafe-deserialization` |
| C05 | Template/expression injection (SSTI, SpEL, EL) from user strings. | graded | `sec-python-data / c05-template-injection` |
| C06 | LDAP, XPath, NoSQL operator injection (`$where`, `$ne` from a JSON body). | graded | `sec-python-data / c06-nosql-injection` |
| C07 | XXE: XML parsers with external entities or DTDs enabled. | graded | `sec-dotnet-java / c07-xxe` |
| C08 | SSRF: a URL from input fetched server-side. Allowlist host and scheme; block redirects... | graded | `sec-node-input / c08-ssrf` |
| C09 | XSS: `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `Html.Raw`, `/safe`, unescaped... | graded | `sec-node-web / c09-xss` |
| C10 | Untrusted data into a URL, an `href`/`src` (`javascript:`), a CSS value, or an inline... | graded | `sec-node-web / c10-untrusted-href` |
| C11 | Response headers or log lines built from input (header/log injection, CRLF). | graded | `sec-node-web / c11-header-injection` |
| C12 | CSV/formula injection in exported data. | graded | `sec-python-data / c12-csv-injection` |
| C13 | A new endpoint, route, handler, or GraphQL resolver with no auth attribute/middleware... | graded | `sec-node-web / c13-route-without-auth` |
| C14 | Authorization checked in the UI, the caller, or the gateway but not at the resource. | graded | `sec-node-auth / c14-ui-only-authz` |
| C15 | IDOR: an object id from input loaded without an ownership/tenant scope check. | graded | `sec-node-auth / c15-idor` |
| C16 | Multi-tenant queries missing the tenant predicate. | graded | `style-citation / catches-the-missing-tenant-scope` |
| C17 | Role checks by string comparison, negation chains, or client-supplied claims. | graded | `sec-node-auth / c17-client-supplied-role` |
| C18 | Token/session handling: expiry, revocation, rotation on privilege change, fixation. | graded | `sec-node-auth / c18-session-fixation` |
| C19 | JWTs: algorithm not pinned, signature unverified, `none` accepted, `kid` used as a path. | graded | `sec-node-auth / c19-jwt-unverified` |
| C20 | Keys, tokens, passwords, connection strings, private keys committed in code, config,... | graded | `scope-uncommitted / flags-the-committed-secret` |
| C21 | Secrets logged, echoed in errors, or included in telemetry/analytics payloads. | graded | `sec-python-privacy / c21-secret-logged` |
| C22 | Debug flags, verbose errors, permissive CORS (`*` with credentials), or disabled TLS... | graded | `sec-dotnet-java / c22-tls-validation-disabled` |
| C23 | Dependencies added: unfamiliar or typo-squattable package names, `latest`/floating... | graded | `sec-go-infra / c23-risky-dependency` |
| C24 | Hand-rolled crypto, ECB mode, static/reused IVs, `Math.random` for anything... | graded | `sec-node-auth / c24-weak-random-token` |
| C25 | Passwords stored with a fast hash or no salt; use the platform's password hash. | graded | `sec-python-privacy / c25-fast-password-hash` |
| C26 | MD5/SHA-1 for signatures or integrity (fine for a cache key -- say which case it is). | graded | `sec-python-privacy / c26-md5-signature` |
| C27 | PII/PHI/card data newly written to logs, added to a response body, sent to a third... | graded | `sec-python-privacy / c27-pii-in-logs` |
| C28 | Data-retention or deletion paths that miss a new store. | graded | `sec-python-privacy / c28-retention-missed` |
| C29 | CSRF protection missing on a new state-changing form/endpoint that uses cookie auth. | graded | `sec-node-web / c29-csrf` |
| C30 | Mass assignment: request body bound straight to an entity, letting `isAdmin`/`role`... | graded | `sec-node-web / c30-mass-assignment` |
| C31 | Missing rate limiting on auth, reset, invite, or expensive endpoints. | graded | `sec-node-web / c31-rate-limit` |
| C32 | File upload: type/size unchecked, original filename trusted, stored inside the web root. | graded | `sec-dotnet-java / c32-unsafe-upload` |
| C33 | Redirects to a user-supplied URL (open redirect). | graded | `sec-node-input / c33-open-redirect` |
| C34 | Error responses leaking stack traces, SQL, or internal hostnames. | graded | `sec-node-web / c34-error-leakage` |
| C35 | Secret/token comparison not constant-time. | graded | `sec-node-auth / c35-non-constant-time-compare` |
| C36 | TOCTOU between a check and its use (permission checks, file existence, balance checks). | graded | `sec-node-auth / c36-toctou-balance` |
| C37 | Unbounded allocation, decompression, or regex on user input (ReDoS, zip bombs). | graded | `sec-node-input / c37-redos` |
| C38 | Missing timeouts on outbound calls. | graded | `sec-node-input / c38-missing-timeout` |
| C39 | **C#/.NET** -- `BinaryFormatter`; `JsonSerializerSettings.TypeNameHandling`; SQL via... | graded | `sec-dotnet-java / c39-dotnet-typenamehandling` |
| C40 | **JS/TS** -- prototype pollution in deep merges; `eval`/`new... | graded | `sec-node-input / c40-prototype-pollution` |
| C41 | **Python** -- `pickle`, `yaml.load` without `SafeLoader`, `subprocess(...,... | graded | `sec-python-data / c41-python-unsafe-yaml` |
| C42 | **Java** -- native deserialization, `Runtime.exec` with a string, XXE defaults in... | graded | `sec-dotnet-java / c42-java-runtime-exec` |
| C43 | **Go** -- `fmt.Sprintf` into SQL, ignored errors on security-relevant calls,... | graded | `sec-go-infra / c43-go-insecureskipverify` |
| C44 | **SQL/migrations** -- a migration that widens a permission, drops a constraint,... | graded | `sec-go-infra / c44-migration-widens-permission` |
| C45 | **IaC/CI** -- public buckets, `0.0.0.0/0` ingress, wildcard IAM, secrets in workflow... | graded | `sec-go-infra / c45-iac-open-ingress` |

## Graded but unstable on Sonnet

Graded means a grader fails when the instruction is ignored -- not that it always passes.
In the final 0.7.0 run (`results/20-final-0.7.0.txt`) every instruction's graders pass in
at least 2 of 3 runs; these are the ones below 3/3, or historically unreliable:

| ID | Final run | History | What the outcome shows |
|---|---|---|---|
| H8 / H8b name both sides of an inconsistency | 2/3 | ~50% in iterations 3-7, 2/3 since the directory grep (iteration 8) | The local style is always applied; what's sometimes missing is naming the odd file out |
| P0 honor `--security-only` | 2/3 | 3/3 in the red step | One run added an Optional comment finding |
| H6/H7 cite `file:line` for every style finding | 2/3 | 3/3 in most runs | One naming finding without a line number |
| L6 log rows match the list | 71/72 runs | -- | One finding dropped after the log was written |
| C38 outbound timeouts | 2/3 | 3/3 in the red step | The bullet the ablation shows the checklist is actually needed for |

The two process instructions the review flagged as unreliable -- reading the checklist
(P2) and not reading it under `--style-only` (P0) -- no longer exist: the checklist is
inline (iteration 8).

## Exceptions

None. The three instructions listed here at 0.6.0 (S2, G4, L10) are now graded: S2 by a
stand-in `gh`, G4 and L10 by resuming a session whose review list was authored for the
test (`branch-review/evals/lib/make_history.py`).

## Cut in the Refactor step (iteration 6)

| Was | Why cut |
|---|---|
| Flow summary line in `<objective>` | Restated the section order. |
| Duplicated `.editorconfig` in the declared-rules list | Typo. |
| `gh pr diff` detail | Shortened to one clause (S2). |
| "Read the file's own history" step | No observable effect; bisected in iteration 6 and not implicated in any grader change. |
| `<notes>`: "repo wins silently" | Restated H6. |
| `<notes>`: `CLAUDE.md`/`AGENTS.md` outrank inference | Merged into H2, which now also says to cite the file. |
| `<notes>`: non-git directories | Model default; untestable and unneeded. |
| Checklist preamble: reporting rule | Moved into SKILL.md (P2b) in iteration 5; the checklist now defers to it. |

`references/security-checklist.md` itself is a catalog the security pass consults, not
a list of instructions: grading each of its ~60 categories would need ~60 fixtures. Its
use is graded (P2), and so is the reporting rule (P2b) and the trace-only rule (P2c).
