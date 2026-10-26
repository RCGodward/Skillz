#!/usr/bin/env bash
# Build the Stage 3 certification ZIP from tracked files only, so real review logs
# (eval/log/) and eval result transcripts (*/evals/results/) can never end up in it.
set -euo pipefail

cert="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(dirname "$cert")"
out="$cert/dist"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

name="branch-review-stage3"
root="$stage/$name"

git -C "$repo" diff --quiet HEAD -- branch-review certification \
  || { echo "uncommitted changes under branch-review/ or certification/ — commit first" >&2; exit 1; }
"$repo/check-versions.sh" >/dev/null

# Everything comes out of HEAD, not the working tree. The skill keeps the repo's layout so
# branch-review/evals/run.sh works from the unzipped directory as-is.
mkdir -p "$root/tools"
git -C "$repo" archive HEAD branch-review | tar -x -C "$root"
git -C "$repo" archive HEAD certification | tar -x -C "$stage"
c="$stage/certification"
cp "$c/README.md" "$c/ITERATION-LOG.md" "$c/TRACEABILITY.md" "$root/"
cp -R "$c/results" "$root/results"
cp "$c/summarize.py" "$c/check_log_rows.py" "$root/tools/"

mkdir -p "$out"
rm -f "$out/$name.zip"
(cd "$stage" && zip -qr "$out/$name.zip" "$name")
echo "$out/$name.zip"
unzip -l "$out/$name.zip" | tail -1
