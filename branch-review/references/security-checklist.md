# Security checklist

Work the categories that match the surfaces this diff actually touches. Report a finding
only when you can name the untrusted input and trace it to the sink. "Could be unsafe"
without a path is noise; skip it.

For each real finding give: the entry point, the path, the impact, and the fix.

## Input and injection
- SQL / ORM raw fragments built with string concatenation or interpolation. Parameterize.
  Check dynamic `ORDER BY`/table names — parameters don't cover identifiers; use an allowlist.
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

## Output and rendering
- XSS: `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `Html.Raw`, `|safe`, unescaped
  interpolation into markup. Confirm sanitization is on the untrusted value, not just nearby.
- Untrusted data into a URL, an `href`/`src` (`javascript:`), a CSS value, or an inline event.
- Response headers or log lines built from input (header/log injection, CRLF).
- CSV/formula injection in exported data.

## AuthN / AuthZ
- A new endpoint, route, handler, or GraphQL resolver with no auth attribute/middleware —
  compare against how its siblings are protected; the gap is usually the tell.
- Authorization checked in the UI, the caller, or the gateway but not at the resource.
- IDOR: an object id from input loaded without an ownership/tenant scope check.
- Multi-tenant queries missing the tenant predicate.
- Role checks by string comparison, negation chains, or client-supplied claims.
- Token/session handling: expiry, revocation, rotation on privilege change, fixation.
- JWTs: algorithm not pinned, signature unverified, `none` accepted, `kid` used as a path.

## Secrets and configuration
- Keys, tokens, passwords, connection strings, private keys committed in code, config,
  tests, fixtures, or comments. Check new config and `.env*` files specifically.
- Secrets logged, echoed in errors, or included in telemetry/analytics payloads.
- Debug flags, verbose errors, permissive CORS (`*` with credentials), or disabled TLS
  verification introduced for local work and left in.
- Dependencies added: unfamiliar or typo-squattable package names, `latest`/floating
  versions, install scripts, or a lockfile edited by hand.

## Crypto and data
- Hand-rolled crypto, ECB mode, static/reused IVs, `Math.random` for anything security-bearing.
- Passwords stored with a fast hash or no salt; use the platform's password hash.
- MD5/SHA-1 for signatures or integrity (fine for a cache key — say which case it is).
- PII/PHI/card data newly written to logs, added to a response body, sent to a third party,
  or stored without the encryption the surrounding code applies.
- Data-retention or deletion paths that miss a new store.

## Web and API surface
- CSRF protection missing on a new state-changing form/endpoint that uses cookie auth.
- Mass assignment: request body bound straight to an entity, letting `isAdmin`/`role` through.
- Missing rate limiting on auth, reset, invite, or expensive endpoints.
- File upload: type/size unchecked, original filename trusted, stored inside the web root.
- Redirects to a user-supplied URL (open redirect).
- Error responses leaking stack traces, SQL, or internal hostnames.

## Timing, concurrency, and resource use
- Secret/token comparison not constant-time.
- TOCTOU between a check and its use (permission checks, file existence, balance checks).
- Unbounded allocation, decompression, or regex on user input (ReDoS, zip bombs).
- Missing timeouts on outbound calls.

## Language-specific quick hits
- **C#/.NET** — `BinaryFormatter`; `JsonSerializerSettings.TypeNameHandling`; SQL via
  `FromSqlRaw`/`ExecuteSqlRaw` with interpolation; `[AllowAnonymous]` added; `Html.Raw`;
  `ServerCertificateCustomValidationCallback` returning true; `Process.Start` with a shell.
- **JS/TS** — prototype pollution in deep merges; `eval`/`new Function`/`setTimeout(string)`;
  `child_process.exec` vs `execFile`; Express routes missing auth middleware; `postMessage`
  handlers without an origin check; secrets in `NEXT_PUBLIC_*`/bundled client config.
- **Python** — `pickle`, `yaml.load` without `SafeLoader`, `subprocess(..., shell=True)`,
  f-strings in SQL, Jinja `|safe`, `assert` used for a runtime security check.
- **Java** — native deserialization, `Runtime.exec` with a string, XXE defaults in
  `DocumentBuilderFactory`, Spring endpoints missing `@PreAuthorize` where siblings have it.
- **Go** — `fmt.Sprintf` into SQL, ignored errors on security-relevant calls, `InsecureSkipVerify`.
- **SQL/migrations** — a migration that widens a permission, drops a constraint, backfills
  with a default that breaks a tenant scope, or is not reversible.
- **IaC/CI** — public buckets, `0.0.0.0/0` ingress, wildcard IAM, secrets in workflow env,
  a workflow triggered by `pull_request_target` that checks out untrusted code.
