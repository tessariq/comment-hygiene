#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scanner="$script_dir/check-push-messages.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$tmp_dir/repo"
git init -q "$repo"
cd "$repo"
git config core.hooksPath .git/hooks
git config user.email fixture@example.com
git config user.name Fixture
git config commit.gpgsign false

commit() {
  printf '%s\n' "$2" >>file.txt
  git add file.txt
  git commit -q --no-verify -m "$1"
}

commit $'feat: add the first fact\n\nExplain the change.' one
clean_head="$(git rev-parse HEAD)"
if ! output="$(bash "$scanner" "$clean_head" 2>&1)"; then
  fail "a clean commit was rejected: $output"
fi

commit $'feat: add a second fact\n\nExplain it.\n\nAmp-Thread:\nhttps://ampcode.com/threads/T-1' two
if output="$(bash "$scanner" "$clean_head..HEAD" 2>&1)"; then
  fail "a session link was accepted"
fi
[[ "$output" == *"automated attribution"* ]] \
  || fail "the scanner did not name the policy: $output"

if printf 'refs/heads/main %s refs/heads/main %s\n' \
  "$(git rev-parse HEAD)" "$clean_head" | bash "$scanner" >/dev/null 2>&1; then
  fail "the stdin range accepted a session link"
fi
if ! printf 'refs/heads/main %s refs/heads/main %s\n' \
  "$clean_head" "$clean_head" | bash "$scanner" >/dev/null 2>&1; then
  fail "the stdin range rejected an empty push"
fi

commit $'feat: add the third fact\n\nExplain the change.' three
agent_parent="$(git rev-parse HEAD~1)"
git commit -q --amend --no-verify --no-edit --author='Amp <amp@ampcode.com>'
if output="$(bash "$scanner" "$agent_parent..HEAD" 2>&1)"; then
  fail "an agent author was accepted"
fi
[[ "$output" == *"agent identity"* ]] \
  || fail "the scanner did not name the author policy: $output"

bounded_base="$(git rev-parse HEAD)"
commit $'feat: add hidden attribution\n\nAmp-Thread: https://ampcode.com/threads/T-hidden' hidden
for number in $(seq 1 200); do
  commit "chore: add history fixture $number

Exercise complete outgoing-range scanning." "$number"
done
if output="$(bash "$scanner" "$bounded_base..HEAD" 2>&1)"; then
  fail "an offending commit older than 200 outgoing commits was accepted"
fi
[[ "$output" == *"automated attribution"* ]] \
  || fail "the complete-range scan did not report the policy: $output"

printf 'push message checks passed\n'
