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
  || { echo "uncommitted changes under branch-review/ or certification/ -- commit first" >&2; exit 1; }
"$repo/check-versions.sh" >/dev/null

# Everything comes out of HEAD, not the working tree. The skill keeps the repo's layout so
# branch-review/evals/run.sh works from the unzipped directory as-is.
mkdir -p "$root/tools"
git -C "$repo" archive HEAD branch-review | tar -x -C "$root"
# The portable prompt is a separate, unevaluated variant that hasn't been brought up to
# 0.6.0; leaving it in would hand the examiner a second, stale "prompt".
rm "$root/branch-review/REVIEW-PROMPT.md"
git -C "$repo" archive HEAD certification | tar -x -C "$stage"
c="$stage/certification"
cp "$c/README.md" "$c/ITERATION-LOG.md" "$c/TRACEABILITY.md" "$root/"
cp -R "$c/results" "$root/results"
cp "$c/summarize.py" "$c/check_log_rows.py" "$c/calibrate_judge.py" "$root/tools/"
cp -R "$c/calibration" "$root/calibration"

# The full history of main, so every commit hash the log cites can be checked:
#   git clone repo.bundle skillz && git -C skillz show <hash>
git -C "$repo" bundle create "$root/repo.bundle" main 2>/dev/null

# ASCII only: an examiner's viewer may not be UTF-8, and a mangled em dash or check
# mark reads as corruption.
# Text files only (-I): the git bundle is binary by design.
if LC_ALL=C grep -rnI '[^ -~[:space:]]' "$root" >&2; then
  echo "non-ASCII characters in the files above -- replace them before packaging" >&2
  exit 1
fi

mkdir -p "$out"
rm -f "$out/$name.zip"
(cd "$stage" && zip -qr "$out/$name.zip" "$name")
echo "$out/$name.zip"
unzip -l "$out/$name.zip" | tail -1
