#!/usr/bin/env bash
# Run the branch-review plugin eval suite with the flags every run needs.
#   branch-review/evals/run.sh                       # full suite, with and without the skill
#   branch-review/evals/run.sh --smoke [case-glob]   # one run per case, skill arm only
#   branch-review/evals/run.sh --case style-\* --runs 5   # anything else passes through
set -euo pipefail

evals="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin="$(dirname "$evals")"

args=()
if [[ "${1:-}" == "--smoke" ]]; then
  shift
  args+=(--runs 1 --ablation none)
  if [[ -n "${1:-}" && "$1" != -* ]]; then
    args+=(--case "$1")
    shift
  fi
fi

# See bin/git and lib/fixture.sh for why macOS needs this. The entries are relative
# because the shim lives inside each fixture's .git/, the only place the sandbox can read;
# the ../ variants cover the review cd'ing into a subdirectory.
# Fixtures also put stand-ins there on every OS (scope-pr-number's gh), so the PATH entry
# is unconditional; only the git shim itself is macOS-only.
export PATH=".git/eval-bin:../.git/eval-bin:../../.git/eval-bin:$PATH"

# Resumed-session cases build their history from the current SKILL.md, so it can't drift.
shopt -s nullglob
history_cases=()
for spec in "$evals"/*/history.json; do history_cases+=("$(dirname "$spec")"); done
if (( ${#history_cases[@]} )); then
  python3 "$evals/lib/make_history.py" "${history_cases[@]}" >/dev/null
fi

# Haiku, the default judge, failed reviews that plainly contained the finding four times
# in two Sonnet baselines. Sonnet keeps the whole suite on mid-tier models.
# The model under test is pinned too, so a bare run.sh reproduces the logged numbers.
# A later --model on the command line overrides it.
exec claude plugin eval "$plugin" \
  --model sonnet \
  --judge-model sonnet \
  --scaffold \
  --allow-tools Bash Edit \
  --no-publish \
  ${args[@]+"${args[@]}"} "$@"
