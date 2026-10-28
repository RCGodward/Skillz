"""Calibrate the LLM judge against blind labels.

  calibrate_judge.py sample <result.json> <evals-dir> <out-dir> [n_pass]
      Writes items.json (criterion + the text the judge saw, no verdict) for a blind
      labeler, and key.json (the judge's verdicts). Takes every judge FAIL in the
      with-skill arm plus n_pass randomly chosen PASSes (fixed seed).
  calibrate_judge.py score <out-dir>
      Compares labels.json ({"id": "PASS"|"FAIL", ...}) with key.json and reports
      agreement, false FAILs and false PASSes.
"""
import json
import pathlib
import random
import re
import sys


def criteria_by_grader(evals_dir):
    found = {}
    for case_yaml in pathlib.Path(evals_dir).glob("*/case.yaml"):
        text = case_yaml.read_text()
        for m in re.finditer(r"name: (\S+)\n(?:    focus: \S+\n)?    criteria: \|\n((?:      .*\n|\n)+)", text):
            found[(case_yaml.parent.name, m.group(1))] = re.sub(r"(?m)^      ", "", m.group(2)).strip()
    return found


def sample(result_path, evals_dir, out_dir, n_pass=30):
    result = json.loads(pathlib.Path(result_path).read_text())
    crit = criteria_by_grader(evals_dir)
    fails, passes = [], []
    for case in result["cases"]:
        for run_i, run in enumerate(case["arms"]["with"]):
            for g in run["graders"]:
                if "judge votes" not in str(g.get("explanation", "")):
                    continue
                item = {"id": f"{case['name']}/{g['name']}/run{run_i}",
                        "criterion": crit.get((case["name"], g["name"]), "?"),
                        "output": g.get("evidence", "")}
                (passes if g.get("passed") else fails).append((item, "PASS" if g.get("passed") else "FAIL"))
    random.Random(7).shuffle(passes)
    chosen = fails + passes[:n_pass]
    random.Random(11).shuffle(chosen)
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    (out / "items.json").write_text(json.dumps([i for i, _ in chosen], indent=1))
    (out / "key.json").write_text(json.dumps({i["id"]: v for i, v in chosen}, indent=1))
    print(f"{len(chosen)} items: {len(fails)} judge FAILs, {min(n_pass, len(passes))} PASSes")


def score(out_dir):
    out = pathlib.Path(out_dir)
    key = json.loads((out / "key.json").read_text())
    labels = json.loads((out / "labels.json").read_text())
    agree = [k for k in key if labels.get(k, {}).get("label") == key[k]]
    false_fail = [k for k in key if key[k] == "FAIL" and labels[k]["label"] == "PASS"]
    false_pass = [k for k in key if key[k] == "PASS" and labels[k]["label"] == "FAIL"]
    lines = [f"items: {len(key)}  agreement: {len(agree)}/{len(key)} ({100 * len(agree) / len(key):.0f}%)",
             f"judge FAIL, label PASS (false FAIL): {len(false_fail)}",
             f"judge PASS, label FAIL (false PASS): {len(false_pass)}"]
    for k in false_fail + false_pass:
        lines.append(f"  {k}: judge {key[k]}, label {labels[k]['label']} -- {labels[k].get('reason', '')}")
    report = "\n".join(lines)
    (out / "report.txt").write_text(report + "\n")
    print(report)


if __name__ == "__main__":
    if sys.argv[1] == "sample":
        sample(sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]) if len(sys.argv) > 5 else 30)
    else:
        score(sys.argv[2])
