# Sourced by each case's scaffold.sh: start the fixture repo on main.
# scaffold.sh runs as the operator, outside the sandbox, with the fixture as cwd.
git init -q -b main .
git config user.email eval@example.com
git config user.name "Eval Fixture"

# macOS: the run's sandbox can't use /usr/bin/git (see ../bin/git), and it can't read
# anything outside the fixture, so the shim has to live inside it. Under .git/ it never
# shows up in the diff being reviewed. run.sh puts .git/eval-bin on PATH.
if [[ "$(uname)" == Darwin ]]; then
  mkdir -p .git/eval-bin
  cp "$(dirname "${BASH_SOURCE[0]}")/../bin/git" .git/eval-bin/git
fi
