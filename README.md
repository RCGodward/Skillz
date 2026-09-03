# Skillz

Portable Claude Code skills, kept here and copied into client repos as needed.

## Skills

| Skill | What it does |
|---|---|
| [`branch-review`](branch-review/) | Reviews a branch for correctness, security, conformance to the *existing* code's style, and comment/doc-block discipline — then presents a numbered list of corrections and waits for approval before editing. ([changelog](branch-review/CHANGELOG.md)) |

## Installing into a client repo

```sh
./install.sh branch-review /path/to/client-repo
```

On Windows, `install.bat` does the same from cmd.exe or PowerShell:

```bat
install.bat branch-review C:\path\to\client-repo
```

That copies the skill to `<client-repo>/.claude/skills/branch-review/`. Use
`--user` to install to `~/.claude/skills/` instead when you don't want a footprint
in the client's tree:

```sh
./install.sh branch-review --user
```

Then invoke it as `/branch-review`, optionally with a base branch, PR number, or path:

```
/branch-review
/branch-review develop
/branch-review 4821
/branch-review src/Billing --fix
```

Each skill keeps its own `CHANGELOG.md` next to its `SKILL.md`. One version number
covers the skill, stated in three places that must agree — the marker at the top of
`SKILL.md`, `version` in `.claude-plugin/plugin.json`, and the newest changelog heading.
`./check-versions.sh` fails if they drift; the marker is what lands in every log's
`skill_version`, so a mismatch means logs citing the wrong changelog section. It installs along with the skill, so a copy
sitting in a client repo says what it is. Changes to the repo's own tooling — `install.sh`,
`install.bat`, `eval/` — live in git history rather than a changelog.

## Evaluating and improving a skill

[`eval/`](eval/) holds two loops: a disposition log the skill writes for you after
every review (`eval/collect.sh` files them, `eval/tally.sh` counts them), and a replay harness
(`eval/replay.sh`) that pulls merged PRs from a repo and sets each one up beside
the human review that already happened, so you can score findings against ground
truth.

See [eval/README.md](eval/README.md).

`branch-review` also carries a `claude plugin eval` suite in
[`branch-review/evals/`](branch-review/evals/) — three cases covering doc-block
discipline, style citation, and false positives on untouched code, each asserting the
approval gate held. `plugin eval` is in early access and the cases have not been scored
yet. `install.sh` strips `evals/` when installing into a client repo.

## Windows

`install.bat` is the installer for cmd.exe and PowerShell. The **eval** scripts
(`eval/*.sh`) are bash — run those from Git Bash or WSL, not PowerShell or cmd.
`.gitattributes` forces LF on `*.sh` so a Windows clone doesn't break the shebang.
`gh` and `git` are the only dependencies. The skill itself is prose and works
wherever Claude Code does; only the eval tooling is shell.

## Other AI tools

Each skill that has one ships a `REVIEW-PROMPT.md`-style portable version — a
self-contained prompt with no Claude-specific tooling in it. Paste it into Cursor,
Copilot, Codex, or Gemini CLI, or drop it into the client's `AGENTS.md` /
`.cursor/rules/` as a standing rule.
