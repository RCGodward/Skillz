"""Check that each run's log table matches the findings it presented.

Usage: check_log_rows.py <eval-result.json> [case-name]

No eval grader can compare two places in one transcript, and the trace-reading judge got
this wrong 3 times in 3 runs, so this is checked here instead, from the grader evidence
the run recorded.
"""
import json
import re
import sys

SEVERITY = {"Blocker": "blocker", "Should fix": "should-fix", "Optional": "optional"}

result = json.load(open(sys.argv[1]))
case_filter = sys.argv[2] if len(sys.argv) > 2 else None
failures = 0
for case in result["cases"]:
    if case_filter and case["name"] != case_filter:
        continue
    for i, run in enumerate(case["arms"].get("with", [])):
        evidence = [g.get("evidence", "") for g in run["graders"]]
        trace = max(evidence, key=len)
        rows = re.findall(r"\| (\d+) \| ([a-z-]+) \| [a-z]+ \|", trace)
        final = next((e for e in evidence if "Reply with the numbers" in e and len(e) < len(trace)), "")
        listed = [(n, SEVERITY.get(s, s)) for n, s in
                  re.findall(r"^(?:#{2,4}\s*|\*\*)(\d+)\.\s*\[([^\]]+)\]", final, re.M)]
        if not rows or not listed:
            print(f"{case['name']} run {i}: skipped (no log table or no list in evidence)")
            continue
        ok = rows == listed
        failures += not ok
        print(f"{case['name']} run {i}: {'match' if ok else 'MISMATCH'}  log={rows}  list={listed}")
sys.exit(1 if failures else 0)
