#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checker="$script_dir/check-commit-msg.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_accepts() {
  local name="$1"
  local message="$2"
  local message_file="$tmp_dir/$name"
  local output
  printf '%s\n' "$message" >"$message_file"
  if ! output="$(bash "$checker" "$message_file" 2>&1)"; then
    fail "$name was rejected: $output"
  fi
}

assert_rejects() {
  local name="$1"
  local message="$2"
  local expected="$3"
  local message_file="$tmp_dir/$name"
  local output
  printf '%s\n' "$message" >"$message_file"
  if output="$(bash "$checker" "$message_file" 2>&1)"; then
    fail "$name was accepted"
  fi
  [[ "$output" == *"$expected"* ]] \
    || fail "$name did not report '$expected': $output"
}

body_72="$(printf '%072d' 0)"
body_73="$(printf '%073d' 0)"

assert_accepts conventional $'docs: clarify contributor workflow\n\nExplain why contributors need the clarified path.'
assert_accepts task-suffix $'feat(domain): add scope (T-001)\n\nKeep matching in the domain layer.'
assert_accepts generated-merge "Merge branch 'feature'"
assert_accepts body-at-72 "test: accept bounded body lines

$body_72"
assert_rejects unknown-type $'build: configure tooling\n\nExplain the change.' 'Conventional Commit'
assert_rejects missing-body 'docs: reject missing body' 'descriptive body'
assert_rejects unseparated-body $'docs: reject body\nExplain why.' 'descriptive body'
assert_rejects body-over-72 "test: reject long body lines

$body_73" '72 characters'
assert_rejects slugged-task $'feat: add scope (T-001-scope)\n\nExplain the change.' 'task references'
assert_rejects attribution $'feat: add scope\n\nExplain it.\n\nCo-Authored-By: Bot <bot@example.com>' 'automated-attribution'
assert_rejects session-link $'feat: add scope\n\nExplain it.\n\nAmp-Thread: https://ampcode.com/threads/T-1' 'automated-attribution'

printf 'commit message checks passed\n'
