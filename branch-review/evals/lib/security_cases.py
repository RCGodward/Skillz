"""Writes the sec-*/case.yaml files: one grader per bullet of the 0.7.0 security checklist.

Usage: python3 lib/security_cases.py   (from branch-review/evals/)

Each sec-* fixture plants several checklist defects in one branch and is reviewed with
--security-only. Every grader below is named after the checklist bullet it exercised
(C01..C45, in the order of the checklist in 0.7.0's security pass). 0.8.0 cut the
checklist to the two checks it measurably added; these graders stay as regression tests
for the security pass. C01, C16 and C20 are covered by security-trace, style-citation and
scope-uncommitted.
"""
import pathlib

EVALS = pathlib.Path(__file__).resolve().parent.parent

CASES = {
    "sec-node-input": ("Input handling in a new Express router: command execution, path "
                       "traversal, SSRF, open redirect, ReDoS, a missing outbound timeout, and "
                       "prototype pollution.", [
        ("c02-command-execution", "src/routes/media.ts builds a shell command from req.body.file and passes it to child_process.exec (command injection)."),
        ("c03-path-traversal", "src/routes/media.ts joins req.params.name onto UPLOAD_DIR and sends the file, so ../ segments escape the upload directory (path traversal)."),
        ("c08-ssrf", "src/routes/media.ts fetches req.query.url server-side and returns the body (SSRF)."),
        ("c33-open-redirect", "src/routes/media.ts redirects to req.query.next without restricting it (open redirect)."),
        ("c37-redos", "src/routes/media.ts compiles req.query.q into a RegExp, so a crafted pattern can cause catastrophic backtracking (ReDoS) or match unintended input."),
        ("c38-missing-timeout", "an outbound fetch in src/routes/media.ts (the partner licenses call, or the preview fetch) has no timeout, so a slow upstream ties up the request."),
        ("c40-prototype-pollution", "deepMerge in src/util/settings.ts merges user JSON without guarding __proto__ / constructor, so POST /prefs allows prototype pollution (the shared defaults object is also mutated)."),
    ]),
    "sec-node-web": ("Rendering and web surface in a new profile router: reflected XSS, a "
                     "user-controlled href, header injection, a missing auth check, CSRF, mass "
                     "assignment, a missing rate limit, and stack traces in errors.", [
        ("c09-xss", "GET /welcome in src/routes/profile.ts interpolates req.query.name into HTML unescaped (reflected XSS)."),
        ("c10-untrusted-href", "the profile page puts user.website into an href without validating the scheme, so a javascript: URL runs script."),
        ("c11-header-injection", "the export route builds the Content-Disposition header from req.query.filename, allowing header / CRLF injection or a spoofed filename."),
        ("c13-route-without-auth", "DELETE /admin/users/:id has no requireAuth / requireAdmin, unlike the admin route in src/routes/account.ts."),
        ("c29-csrf", "POST /profile (a cookie-session, state-changing route) lacks csrfProtection, which the sibling form routes in src/routes/account.ts use."),
        ("c30-mass-assignment", "POST /profile passes req.body straight to db.users.update, letting a caller set fields like role (mass assignment)."),
        ("c31-rate-limit", "POST /password-reset has no rate limit, unlike /login which uses loginLimiter."),
        ("c34-error-leakage", "the error handler sends err.stack to the client."),
    ]),
    "sec-node-auth": ("Authentication and authorization in a new billing router: UI-only "
                      "authorization, IDOR, a client-supplied role, session fixation, an "
                      "unverified JWT, a weak reset token, a non-constant-time signature "
                      "check, and a check-then-act race on a balance.", [
        ("c14-ui-only-authz", "DELETE /api/projects/:id only requires login; the admin-only rule exists solely in the UI (src/ui/projects.tsx), not on the server."),
        ("c15-idor", "GET /api/invoices/:id loads an invoice by id without the ownership check that src/routes/documents.ts applies (IDOR)."),
        ("c17-client-supplied-role", "POST /api/refunds authorizes on the x-user-role request header, which the client controls."),
        ("c18-session-fixation", "POST /login sets userId/role on the existing session without regenerating it (session fixation / no rotation on privilege change)."),
        ("c19-jwt-unverified", "GET /api/partner/statement uses jwt.decode, which does not verify the signature, and trusts claims.partnerId."),
        ("c24-weak-random-token", "the password-reset token comes from Math.random, which is not cryptographically secure."),
        ("c35-non-constant-time-compare", "the payments webhook compares the HMAC signature with !==, not a constant-time comparison."),
        ("c36-toctou-balance", "POST /api/wallet/withdraw checks the balance, then pays out, then writes the new balance non-atomically, so concurrent requests can overdraw (TOCTOU / race)."),
    ]),
    "sec-python-data": ("Data handling in new Flask endpoints: pickle, unsafe YAML, template "
                        "injection, NoSQL operator injection, and CSV formula injection.", [
        ("c04-unsafe-deserialization", "POST /imports/cart calls pickle.loads on the request body, allowing code execution."),
        ("c41-python-unsafe-yaml", "POST /imports/catalog uses yaml.load with yaml.Loader (not SafeLoader / safe_load) on request data."),
        ("c05-template-injection", "GET /greeting concatenates the name parameter into render_template_string (server-side template injection)."),
        ("c06-nosql-injection", "POST /staff/login passes JSON body values straight into a Mongo query, so an operator such as {\"$ne\": \"\"} bypasses the password check."),
        ("c12-csv-injection", "the reviews CSV export writes user-entered comments without neutralizing leading = + - @ (CSV / formula injection)."),
    ]),
    "sec-python-privacy": ("Secrets, crypto, and personal data in new signup and support code: a "
                           "logged API key, a fast unsalted password hash, MD5 signature "
                           "checks, PII in logs, and a new store the erasure path misses.", [
        ("c21-secret-logged", "send_verification_sms logs SMS_API_KEY."),
        ("c25-fast-password-hash", "create_user stores passwords as unsalted SHA-256 instead of a password hash (bcrypt, scrypt, argon2, PBKDF2)."),
        ("c26-md5-signature", "the support webhook verifies its signature with MD5 over secret + body instead of an HMAC with a modern hash."),
        ("c27-pii-in-logs", "create_user logs the SSN and date of birth (and email)."),
        ("c28-retention-missed", "the new support_attachments table holds user data that delete_account in app/accounts.py (right to erasure) does not delete."),
    ]),
    "sec-dotnet-java": ("C# and Java integrations: polymorphic JSON deserialization, disabled "
                        "TLS validation, an unchecked upload into the web root, XXE, and "
                        "Runtime.exec with a string.", [
        ("c39-dotnet-typenamehandling", "PartnerController deserializes request JSON with TypeNameHandling.All, allowing attacker-chosen types."),
        ("c22-tls-validation-disabled", "the partner HttpClient's ServerCertificateCustomValidationCallback always returns true, disabling TLS certificate validation."),
        ("c32-unsafe-upload", "the documents upload trusts file.FileName and writes into wwwroot/uploads with no type or size check (path traversal / served executable content)."),
        ("c07-xxe", "FeedController parses request XML with a default DocumentBuilderFactory, leaving external entities / DTDs enabled (XXE)."),
        ("c42-java-runtime-exec", "FeedController passes the host request parameter into Runtime.getRuntime().exec as a single string (command injection)."),
    ]),
    "sec-go-infra": ("Go, SQL migration, infrastructure, and dependency changes: skipped TLS "
                     "verification, a widened database grant, a database open to the "
                     "internet, and risky new dependencies.", [
        ("c43-go-insecureskipverify", "cmd/sync/main.go sets InsecureSkipVerify: true on the HTTP client (and sends a token over that connection)."),
        ("c44-migration-widens-permission", "migrations/002_reporting.sql grants ALL PRIVILEGES on every table to the read-only role."),
        ("c45-iac-open-ingress", "infra/db.tf opens the Postgres security group to 0.0.0.0/0."),
        ("c23-risky-dependency", "web/package.json adds a typo-squat-looking package (lodahs) and/or a floating \"latest\" version."),
    ]),
}

HEADER = '''schema_version: "1.0"
name: {name}
description: >
  {description} Reviewed with --security-only. Graders are named after the
  0.7.0 checklist bullet each defect exercises (see lib/security_cases.py).
tags: [security, checklist]

context:
  scaffold_script: scaffold.sh

execution:
  prompt: /branch-review main --security-only
  allowed_tools: [Bash, Read, Grep, Glob, Edit]
  max_turns: 50
  timeout_seconds: 1200

runs: 3

graders:
  - type: tool_used
    name: gate-held-nothing-edited
    tool: Edit
    min: 0
    max: 0
    weight: 3
'''

GRADER = '''
  - type: llm
    name: {name}
    focus: last_message
    criteria: |
      PASS if a numbered finding reports this: {what}
      Severity label and wording don't matter, and it may share a finding with another
      issue. FAIL if it is not among the numbered findings.
    weight: 2
'''

FOOTER = '''
  - type: regex
    name: ends-with-approval-prompt
    target: last_message
    pattern: 'Reply with the numbers'
    match: contains
    weight: 1
'''

if __name__ == "__main__":
    import textwrap
    for name, (description, defects) in CASES.items():
        desc = "\n  ".join(textwrap.wrap(description, 84))
        body = HEADER.format(name=name, description=desc)
        for grader, what in defects:
            body += GRADER.format(name=grader, what=what)
        (EVALS / name / "case.yaml").write_text(body + FOOTER)
        print(f"{name}: {len(defects)} checklist graders")
