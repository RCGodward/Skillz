#!/usr/bin/env bash
# Copy a skill from this repo into a client repo (or into ~/.claude/skills).
#   ./install.sh <skill> <target-repo>
#   ./install.sh <skill> --user
set -euo pipefail

src_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill="${1:-}"
target="${2:-}"

if [[ -z "$skill" || -z "$target" ]]; then
  echo "usage: $0 <skill> <target-repo|--user>" >&2
  echo "skills: $(cd "$src_root" && find . -maxdepth 2 -name SKILL.md -exec dirname {} \; | sed 's|^\./||' | tr '\n' ' ')" >&2
  exit 1
fi

[[ -f "$src_root/$skill/SKILL.md" ]] || { echo "no such skill: $skill" >&2; exit 1; }

if [[ "$target" == "--user" ]]; then
  dest="$HOME/.claude/skills/$skill"
else
  [[ -d "$target" ]] || { echo "no such directory: $target" >&2; exit 1; }
  dest="$target/.claude/skills/$skill"
fi

mkdir -p "$(dirname "$dest")"
rm -rf "$dest"
cp -R "$src_root/$skill" "$dest"
# Eval fixtures are for developing the skill, not for the repo it gets installed into.
rm -rf "$dest/evals"
echo "installed $skill -> $dest"
