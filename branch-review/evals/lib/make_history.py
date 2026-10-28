"""Build a case's history.jsonl: a resumable session in which /branch-review already ran.

Usage: make_history.py <case-dir>...

Some instructions only apply after the user answers the review (G4, L10), and an eval case
is a single prompt. A case can resume a session instead (context.history_file), so this
writes one from <case-dir>/history.json: the /branch-review command, the CURRENT SKILL.md
as the skill load, the Bash call that wrote the log, and the review's final message. The
final message is authored, not recorded, because these cases need a specific finding in
it - a wrong one (G4), or an omission (L10). Generated rather than hand-edited so the skill
text can't drift from the prompt under test; run.sh regenerates every history before a run.
"""
import json
import pathlib
import sys
import uuid

EVALS = pathlib.Path(__file__).resolve().parent.parent
SKILL = EVALS.parent / "SKILL.md"
NS = uuid.UUID("6f1b3c2a-4d5e-4f60-8a7b-9c0d1e2f3a4b")
VERSION = "2.1.312"


def skill_body():
    text = SKILL.read_text()
    # The skill loads without its YAML frontmatter.
    _, _, body = text.partition("\n---\n")
    return "Base directory for this skill: branch-review\n\n" + body.lstrip("\n")


def build(case_dir):
    spec = json.loads((case_dir / "history.json").read_text())
    session = str(uuid.uuid5(NS, case_dir.name))
    stamp = iter(f"2026-10-28T17:00:{s:02d}.000Z" for s in range(60))
    entries, parent = [], None

    def add(kind, message, **extra):
        nonlocal parent
        entry_id = str(uuid.uuid5(NS, f"{case_dir.name}/{len(entries)}"))
        entries.append({
            "parentUuid": parent, "isSidechain": False, "type": kind, "message": message,
            "uuid": entry_id, "timestamp": next(stamp), "userType": "external",
            "entrypoint": "sdk-cli", "cwd": "/fixture", "sessionId": session,
            "version": VERSION, "gitBranch": spec["branch"], **extra,
        })
        parent = entry_id

    def assistant(content, stop):
        add("assistant", {
            "id": f"msg_{uuid.uuid5(NS, f'{case_dir.name}/m{len(entries)}').hex[:24]}",
            "type": "message", "role": "assistant", "model": "claude-sonnet-5-5",
            "content": content, "stop_reason": stop, "stop_sequence": None,
        })

    add("user", {"role": "user", "content": (
        "<command-message>branch-review</command-message>\n"
        "<command-name>/branch-review</command-name>\n"
        f"<command-args>{spec['args']}</command-args>")})
    add("user", {"role": "user", "content": [{"type": "text", "text": skill_body()}]},
        isMeta=True)
    tool_id = f"toolu_{uuid.uuid5(NS, case_dir.name + '/log').hex[:24]}"
    assistant([{"type": "tool_use", "id": tool_id, "name": "Bash",
                "input": {"command": spec["log_command"],
                          "description": "Write the evaluation log entry"}}], "tool_use")
    add("user", {"role": "user", "content": [{"type": "tool_result", "tool_use_id": tool_id,
                                               "content": spec["log_stdout"], "is_error": False}]},
        toolUseResult={"stdout": spec["log_stdout"], "stderr": "", "interrupted": False})
    assistant([{"type": "text", "text": spec["final_text"]}], "end_turn")

    out = case_dir / "history.jsonl"
    out.write_text("".join(json.dumps(e) + "\n" for e in entries))
    # The history only records the log write; nothing re-runs it. The scaffold installs
    # this copy where the history says it went, so the apply step has a log to update.
    body = spec["log_command"].split("<<'EOF'\n", 1)[1].split("\nEOF\n", 1)[0] + "\n"
    (case_dir / "history-log.md").write_text(body)
    return out


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        print(build(pathlib.Path(arg).resolve()))
