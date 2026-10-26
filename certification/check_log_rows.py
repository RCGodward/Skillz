"""Check that each run's log table matches the findings it presented.

Usage: check_log_rows.py <eval-result.json> [case-name]

No eval grader can compare two places in one transcript, and a trace-reading judge got
this wrong 3 times in 3 runs, so it is checked here instead. Reads each run's trace.jsonl
(run the suite with --keep-temp so the traces survive), takes the table from the Bash
heredoc that wrote the log, and compares it with the numbered findings in the final
message: same numbers, same order, same severities.
"""
import json
import os
import re
import sys

SEVERITY = {"Blocker": "blocker", "Should fix": "should-fix", "Optional": "optional"}
ROW = re.compile(r"^\| (\d+) \| ([a-z-]+) \| [a-z]+ \|", re.M)
FINDING = re.compile(r"^(?:#{2,4}\s*|\*\*)(\d+)\.\s*\[([^\]]+)\]", re.M)


def read_trace(path):
    log_tables, final = [], ""
    for line in open(path):
        event = json.loads(line)
        if event.get("type") == "result":
            final = event.get("result") or final
        for block in (event.get("message") or {}).get("content") or []:
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            command = (block.get("input") or {}).get("command", "")
            if "branch-review-log" in command and ROW.search(command):
                log_tables.append(command)
    return log_tables, final


result = json.load(open(sys.argv[1]))
case_filter = sys.argv[2] if len(sys.argv) > 2 else None
checked = failures = 0
for case in result["cases"]:
    if case_filter and case["name"] != case_filter:
        continue
    for i, run in enumerate(case["arms"].get("with", [])):
        path = run.get("tracePath")
        if not path or not os.path.exists(path):
            print(f"{case['name']} run {i}: no trace (run with --keep-temp)")
            continue
        tables, final = read_trace(path)
        listed = [(n, SEVERITY.get(s, s)) for n, s in FINDING.findall(final)]
        if not tables or not listed:
            print(f"{case['name']} run {i}: skipped (no log heredoc or no findings)")
            continue
        # The first heredoc is the review's log; a later one is the apply-step update.
        rows = ROW.findall(tables[0])
        ok = rows == listed
        checked += 1
        failures += not ok
        print(f"{case['name']} run {i}: {'match' if ok else 'MISMATCH'}  log={rows}  list={listed}")
print(f"{checked} runs checked, {failures} mismatched")
sys.exit(1 if failures else 0)
