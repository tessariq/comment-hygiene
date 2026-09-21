#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$project_root/fixtures/comment-slop.py"
runner="$project_root/scripts/comment-hygiene"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

target="$workdir/comment-slop.py"
cp "$fixture" "$target"

audit_output="$($runner audit "$target")"
grep -Fq "would be modified" <<<"$audit_output"
grep -Fq "Explains an obvious assignment." <<<"$audit_output"
cmp --silent "$fixture" "$target"

$runner strip --apply "$target"

if grep -Fq "Explains an obvious assignment." "$target"; then
  echo "ordinary comment was not removed" >&2
  exit 1
fi
if grep -Fq "The following URL is data, not a comment" "$target"; then
  echo "inline narration was not removed" >&2
  exit 1
fi
grep -Fq 'https://example.test/docs/#fragment' "$target"
grep -Fq "TODO: Replace the compatibility fallback after v2 adoption." "$target"

echo "comment-hygiene fixture: ordinary comments removed; string and TODO preserved"
