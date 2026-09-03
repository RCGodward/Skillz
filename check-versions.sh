#!/usr/bin/env bash
# Fail if a skill's three version statements disagree: the marker at the top of
# SKILL.md, "version" in .claude-plugin/plugin.json, and the newest CHANGELOG heading.
#
# The marker is the one that ends up in every eval log's skill_version field, so a
# drift here means a log pointing at the wrong changelog section.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

shopt -s nullglob
for skill_md in "$root"/*/SKILL.md; do
  dir="$(dirname "$skill_md")"
  skill="$(basename "$dir")"

  marker="$(sed -n 's/^<!-- '"$skill"' \([0-9][0-9.]*\) -->$/\1/p' "$skill_md" | head -1)"
  manifest=""
  [[ -f "$dir/.claude-plugin/plugin.json" ]] && manifest="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$dir/.claude-plugin/plugin.json" | head -1)"
  changelog=""
  [[ -f "$dir/CHANGELOG.md" ]] && changelog="$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' "$dir/CHANGELOG.md" | head -1)"

  printf "%-18s marker=%-8s manifest=%-8s changelog=%-8s " \
    "$skill" "${marker:-MISSING}" "${manifest:-MISSING}" "${changelog:-MISSING}"

  if [[ -z "$marker" || -z "$manifest" || -z "$changelog" ]]; then
    echo "FAIL (missing)"; status=1
  elif [[ "$marker" == "$manifest" && "$marker" == "$changelog" ]]; then
    echo "ok"
  else
    echo "FAIL (disagree)"; status=1
  fi
done

if [[ $status -ne 0 ]]; then
  echo
  echo "Bump all three together. The marker is what lands in a log's skill_version," >&2
  echo "so a mismatch means logs citing a changelog section that says something else." >&2
fi
exit $status
