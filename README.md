# Skillz

Portable Claude Code skills, kept here and copied into client repos as needed.

## Skills

| Skill | What it does |
|---|---|
| [`branch-review`](branch-review/) | Reviews a branch for correctness, security, conformance to the *existing* code's style, and comment/doc-block discipline — then presents a numbered list of corrections and waits for approval before editing. |

## Installing into a client repo

```sh
./install.sh branch-review /path/to/client-repo
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

The scripts are bash — run them from Git Bash or WSL, not PowerShell or cmd.
`.gitattributes` forces LF on `*.sh` so a Windows clone doesn't break the shebang.
`gh` and `git` are the only dependencies. The skill itself is prose and works
wherever Claude Code does; only the eval tooling is shell.

## Other AI tools

Each skill that has one ships a `REVIEW-PROMPT.md`-style portable version — a
self-contained prompt with no Claude-specific tooling in it. Paste it into Cursor,
Copilot, Codex, or Gemini CLI, or drop it into the client's `AGENTS.md` /
`.cursor/rules/` as a standing rule.
