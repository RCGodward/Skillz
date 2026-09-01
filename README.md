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

## Other AI tools

Each skill that has one ships a `REVIEW-PROMPT.md`-style portable version — a
self-contained prompt with no Claude-specific tooling in it. Paste it into Cursor,
Copilot, Codex, or Gemini CLI, or drop it into the client's `AGENTS.md` /
`.cursor/rules/` as a standing rule.
