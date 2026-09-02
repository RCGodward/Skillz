#!/usr/bin/env bash
# Replay merged PRs through branch-review and collect the human review beside it.
#
#   ./replay.sh --repo ~/clients/acme/api --limit 10
#   ./replay.sh --repo ~/clients/acme/api --pr 812,847 --run
#   ./replay.sh --repo ~/clients/acme/api --clean
#
# Output lands in eval/replay/<repo>/pr-<n>/ inside THIS repo, never in the client's tree.
# The one thing it does write to the client repo is git worktrees; --clean removes them.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skillz_root="$(dirname "$script_dir")"

repo_path="."
limit=10
prs=""
run=0
clean=0
out_root="$script_dir/replay"

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'USAGE'

  --repo <path>    Local clone of the repo to replay (default: cwd)
  --limit <n>      How many recent merged PRs (default: 10)
  --pr <a,b,c>     Specific PR numbers instead of the most recent
  --run            Invoke `claude -p /branch-review` headlessly and capture findings
  --clean          Remove worktrees this script created in the target repo, then exit
  --out <dir>      Override output root
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)  repo_path="$2"; shift 2 ;;
    --limit) limit="$2"; shift 2 ;;
    --pr)    prs="$2"; shift 2 ;;
    --out)   out_root="$2"; shift 2 ;;
    --run)   run=1; shift ;;
    --clean) clean=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

for dep in gh git; do
  command -v "$dep" >/dev/null || { echo "$dep is required" >&2; exit 1; }
done

repo_path="$(cd "$repo_path" && pwd)"
git -C "$repo_path" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "not a git repository: $repo_path" >&2; exit 1; }

if [[ $clean -eq 1 ]]; then
  git -C "$repo_path" worktree list --porcelain \
    | awk '/^worktree /{print substr($0,10)}' \
    | grep -F "$out_root" \
    | while read -r wt; do
        echo "removing worktree $wt"
        git -C "$repo_path" worktree remove --force "$wt" 2>/dev/null || true
      done
  git -C "$repo_path" worktree prune
  git -C "$repo_path" for-each-ref --format='%(refname)' 'refs/branch-review-replay/*' \
    | while read -r ref; do git -C "$repo_path" update-ref -d "$ref"; done
  echo "clean."
  exit 0
fi

slug="$(cd "$repo_path" && gh repo view --json nameWithOwner -q .nameWithOwner)"
[[ -n "$slug" ]] || { echo "could not resolve a GitHub repo for $repo_path" >&2; exit 1; }
repo_name="${slug##*/}"
out="$out_root/$repo_name"
mkdir -p "$out"

if [[ -n "$prs" ]]; then
  pr_numbers="$(echo "$prs" | tr ',' '\n' | tr -d ' ' | grep -E '^[0-9]+$')"
else
  pr_numbers="$(cd "$repo_path" && gh pr list --state merged --limit "$limit" --json number -q '.[].number')"
fi
[[ -n "$pr_numbers" ]] || { echo "no merged PRs found" >&2; exit 1; }

echo "repo:   $slug"
echo "output: $out"
echo

for n in $pr_numbers; do
  dir="$out/pr-$n"
  wt="$dir/wt"
  mkdir -p "$dir"
  echo "── PR #$n"

  fields=number,title,url,author,baseRefName,headRefName,baseRefOid,mergedAt,additions,deletions,changedFiles
  (cd "$repo_path" && gh pr view "$n" --json "$fields") > "$dir/pr.json"

  # gh's built-in --jq keeps this working without a standalone jq on PATH (Windows).
  meta_tsv="$(cd "$repo_path" && gh pr view "$n" --json "$fields" \
    -q '[.baseRefName, .url, (.changedFiles|tostring), (.additions|tostring), (.deletions|tostring), .title] | @tsv')"
  IFS=$'\t' read -r base_branch pr_url pr_files pr_add pr_del title <<< "$meta_tsv"

  # refs/pull/N/head survives branch deletion, unlike the head branch itself.
  git -C "$repo_path" fetch -q origin "refs/pull/$n/head:refs/branch-review-replay/$n" --force
  git -C "$repo_path" fetch -q origin "$base_branch" || true
  head_sha="$(git -C "$repo_path" rev-parse "refs/branch-review-replay/$n")"
  base_sha="$(git -C "$repo_path" merge-base "$head_sha" FETCH_HEAD 2>/dev/null \
              || git -C "$repo_path" merge-base "$head_sha" "origin/$base_branch")"

  git -C "$repo_path" diff "$base_sha".."$head_sha" > "$dir/diff.patch"

  # Human review: inline comments, review bodies, then PR conversation.
  {
    echo "# Human review of #$n — $title"
    echo
    echo "## Inline comments"
    echo
    (cd "$repo_path" && gh api --paginate "repos/$slug/pulls/$n/comments" \
      --jq '.[] | "- **\(.user.login)** `\(.path):\(.line // .original_line // "?")`\n\n  \(.body | gsub("\n"; "\n  "))\n"') 2>/dev/null || echo "_none_"
    echo
    echo "## Review summaries"
    echo
    (cd "$repo_path" && gh api --paginate "repos/$slug/pulls/$n/reviews" \
      --jq '.[] | select(.body != "") | "- **\(.user.login)** (\(.state))\n\n  \(.body | gsub("\n"; "\n  "))\n"') 2>/dev/null || echo "_none_"
    echo
    echo "## Conversation"
    echo
    (cd "$repo_path" && gh api --paginate "repos/$slug/issues/$n/comments" \
      --jq '.[] | "- **\(.user.login)**\n\n  \(.body | gsub("\n"; "\n  "))\n"') 2>/dev/null || echo "_none_"
  } > "$dir/human-review.md"

  comment_count=$( { (cd "$repo_path" && gh api --paginate "repos/$slug/pulls/$n/comments" --jq '.[].id') 2>/dev/null || true; } | wc -l | tr -d ' ')

  if [[ ! -d "$wt" ]]; then
    git -C "$repo_path" worktree add -q --detach "$wt" "$head_sha"
  fi
  "$skillz_root/install.sh" branch-review "$wt" >/dev/null

  cat > "$dir/RUN.md" <<RUNEOF
# Replay: $slug #$n

$title
$pr_url

- base branch: \`$base_branch\`
- merge-base:  \`$base_sha\`
- PR head:     \`$head_sha\`
- size:        $pr_files files, +$pr_add/-$pr_del
- human inline comments: $comment_count

## Run the review

\`\`\`sh
cd $wt
claude
> /branch-review $base_sha
\`\`\`

Paste the findings into \`skill-findings.md\` in this directory, then score against
\`human-review.md\` and log the result with \`eval/log/TEMPLATE.md\`.

## What to look for

- What the human caught that the skill didn't → \`missed\` rows.
- What the skill flagged that the human ignored → false-positive candidate.
  Check it before believing it; human reviewers miss plenty.
- Did every style finding cite a real example from this repo, and was it apt?
- Did it stop before editing anything?
RUNEOF

  if [[ $run -eq 1 ]]; then
    command -v claude >/dev/null || { echo "  claude CLI not found; skipping --run" >&2; continue; }
    echo "  running review…"
    (cd "$wt" && claude -p "/branch-review $base_sha") > "$dir/skill-findings.md" 2>"$dir/skill-findings.err" \
      || echo "  review failed; see $dir/skill-findings.err" >&2
  else
    : > "$dir/skill-findings.md"
  fi

  echo "  $dir  ($comment_count human comments)"
done

echo
echo "Done. Next: run each review (see RUN.md), fill skill-findings.md, then log with eval/log/TEMPLATE.md."
echo "When finished: ./replay.sh --repo $repo_path --clean"
