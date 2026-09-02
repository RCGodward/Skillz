#!/usr/bin/env bash
# Tally finding dispositions across eval/log/*.md and point at what to fix.
set -euo pipefail

log_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log"
[[ -d "$log_dir" ]] || { echo "no log directory at $log_dir" >&2; exit 1; }

shopt -s nullglob
files=("$log_dir"/*.md)
entries=()
for f in "${files[@]}"; do
  [[ "$(basename "$f")" == "TEMPLATE.md" ]] && continue
  entries+=("$f")
done

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "No log entries yet. Copy log/TEMPLATE.md to log/YYYY-MM-DD-<client>-<branch>.md after your next review."
  exit 0
fi

echo "Reviews logged: ${#entries[@]}"
echo

awk -F'|' '
  # the legend comment is pipe-separated too — never count it as a row
  /^[[:space:]]*<!--/ { next }

  # table rows look like: | 3 | should-fix | style | preference | note |
  NF >= 6 {
    sev = $3; cat = $4; disp = $5; note = $6
    gsub(/^[ \t]+|[ \t]+$/, "", sev)
    gsub(/^[ \t]+|[ \t]+$/, "", cat)
    gsub(/^[ \t]+|[ \t]+$/, "", disp)
    gsub(/^[ \t]+|[ \t]+$/, "", note)
    if (disp == "" && $2 ~ /[0-9]/) { uncoded++; next }
    if (disp !~ /^(applied|wrong|handled|preexisting|preference|not-worth-it|missed)$/) next
    # an unfilled placeholder missed row carries no note — it is not a finding
    if (disp == "missed" && note == "") next
    total++
    by_disp[disp]++
    if (cat != "") by_cat[cat]++
    if (cat != "") pair[cat "\t" disp]++
    if (sev != "" && disp == "applied") applied_sev[sev]++
    if (sev != "") sev_total[sev]++
  }
  END {
    if (total == 0) { print "No parseable finding rows found."; exit }

    printf "%-14s %6s %7s\n", "DISPOSITION", "COUNT", "SHARE"
    printf "%-14s %6s %7s\n", "----------", "-----", "-----"
    n = split("applied wrong handled preexisting preference not-worth-it missed", order, " ")
    for (i = 1; i <= n; i++) {
      d = order[i]
      c = by_disp[d] + 0
      printf "%-14s %6d %6.0f%%\n", d, c, (c * 100.0) / total
    }
    printf "%-14s %6d\n", "TOTAL", total
    if (uncoded > 0) printf "\n  (%d finding row%s still uncoded — not counted above)\n", uncoded, (uncoded == 1 ? "" : "s")

    print ""
    printf "%-13s %8s %8s %9s %11s %11s %13s %7s\n", "CATEGORY", "applied", "wrong", "handled", "preexist", "preference", "not-worth-it", "missed"
    for (c in by_cat) {
      printf "%-13s %8d %8d %9d %11d %11d %13d %7d\n", c,
        pair[c "\tapplied"] + 0, pair[c "\twrong"] + 0, pair[c "\thandled"] + 0,
        pair[c "\tpreexisting"] + 0, pair[c "\tpreference"] + 0,
        pair[c "\tnot-worth-it"] + 0, pair[c "\tmissed"] + 0
    }

    print ""
    print "ACCEPTANCE BY SEVERITY  (low acceptance on blocker/should-fix = severity inflation)"
    m = split("blocker should-fix optional", sorder, " ")
    for (i = 1; i <= m; i++) {
      s = sorder[i]
      if (sev_total[s] > 0)
        printf "  %-11s %d/%d applied (%.0f%%)\n", s, applied_sev[s] + 0, sev_total[s],
          (applied_sev[s] * 100.0) / sev_total[s]
    }

    print ""
    print "WHAT TO FIX"
    printf "  %-40s -> %s\n", "wrong / handled / preexisting: " (by_disp["wrong"] + by_disp["handled"] + by_disp["preexisting"] + 0), "<verify> is being skipped or is too weak"
    printf "  %-40s -> %s\n", "preference: " (by_disp["preference"] + 0), "<house_style> evidence rule; likely bad sibling selection"
    printf "  %-40s -> %s\n", "not-worth-it: " (by_disp["not-worth-it"] + 0), "<output> severity definitions need an anchor"
    printf "  %-40s -> %s\n", "missed: " (by_disp["missed"] + 0), "the <passes> section for that category"
    print ""
    print "  Act on a reason once it clears ~12 occurrences, or when one category is"
    print "  clearly worse than the rest. Change one section at a time, then re-run"
    print "  the replay set so you can tell which edit did what."
  }
' "${entries[@]}"

echo
echo "HARD FAILURES"
gate=$({ grep -h -E '^gate_held:[[:space:]]*no[[:space:]]*$' "${entries[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
cites=$({ grep -h -E '^style_citations_ok:[[:space:]]*no[[:space:]]*$' "${entries[@]}" 2>/dev/null || true; } | wc -l | tr -d ' ')
printf "  gate breached (edited before approval): %s\n" "$gate"
printf "  style finding with a missing or bad citation: %s\n" "$cites"
if [[ "$gate" != "0" || "$cites" != "0" ]]; then
  echo "  ^ these are hard failures, not nits — fix before tuning anything else:"
  [[ "$gate"  != "0" ]] && grep -l -E '^gate_held:[[:space:]]*no[[:space:]]*$' "${entries[@]}" | sed 's/^/      /' || true
  [[ "$cites" != "0" ]] && grep -l -E '^style_citations_ok:[[:space:]]*no[[:space:]]*$' "${entries[@]}" | sed 's/^/      /' || true
fi
