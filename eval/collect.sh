#!/usr/bin/env bash
# Move review logs the skill dropped in ~/.branch-review-log into eval/log/.
#
#   ./collect.sh          # move them here
#   ./collect.sh --list   # just show what's waiting
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
drop="${BRANCH_REVIEW_LOG_DIR:-$HOME/.branch-review-log}"
dest="$script_dir/log"

[[ -d "$drop" ]] || { echo "nothing dropped yet ($drop does not exist)"; exit 0; }

shopt -s nullglob
pending=("$drop"/*.md)
[[ ${#pending[@]} -gt 0 ]] || { echo "nothing waiting in $drop"; exit 0; }

if [[ "${1:-}" == "--list" ]]; then
  for f in "${pending[@]}"; do
    unfilled=$(awk -F'|' 'NF>=6 && $2 ~ /[0-9-]/ {d=$5; gsub(/[ \t]/,"",d); if (d=="") n++} END{print n+0}' "$f")
    printf "  %-45s %s row(s) still uncoded\n" "$(basename "$f")" "$unfilled"
  done
  exit 0
fi

moved=0
for f in "${pending[@]}"; do
  target="$dest/$(basename "$f")"
  if [[ -e "$target" ]]; then
    echo "  skip (already here): $(basename "$f")" >&2
    continue
  fi
  mv "$f" "$target"
  moved=$((moved + 1))
done

echo "collected $moved entr$([[ $moved -eq 1 ]] && echo y || echo ies) into eval/log/"
[[ $moved -gt 0 ]] && echo "Fill in the disposition column, then run ./tally.sh"
exit 0
