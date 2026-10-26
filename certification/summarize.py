"""Summarize a `claude plugin eval --json` result: per-case, per-arm, per-grader pass rates."""
import json
import sys

result = json.load(open(sys.argv[1]))
suite = result.get("suite", {})
print(f"model: {suite.get('model', result.get('model', '?'))}  ablation: {suite.get('ablation')}")
print()
for case in result["cases"]:
    for arm, runs in case["arms"].items():
        scores = [r["score"] for r in runs]
        mean = sum(scores) / len(scores)
        print(f"{case['name']:<28} {arm:<8} mean {mean:5.0%}   runs {[round(s, 2) for s in scores]}")
        names = [g["name"] for g in runs[0].get("graders", [])]
        for name in names:
            passed = sum(
                1 for r in runs for g in r.get("graders", []) if g["name"] == name and g.get("passed")
            )
            print(f"    {passed}/{len(runs)}  {name}")
    print()
agg = result["aggregates"]
print(f"overall score {agg['overallScore']:.1%}  pass rate {agg['overallPassRate']:.1%}  "
      f"cases passed {agg['casesPassed']}/{agg['casesTotal']}  mean delta {agg.get('meanDelta', 0):+.1%}")
