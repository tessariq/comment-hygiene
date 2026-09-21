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

hyphen_target="$workdir/-comment-slop.py"
cp "$fixture" "$hyphen_target"
hyphen_audit_output="$(cd "$workdir" && "$runner" audit -- "-comment-slop.py")"
grep -Fq "would be modified" <<<"$hyphen_audit_output"
cmp --silent "$fixture" "$hyphen_target"
(cd "$workdir" && "$runner" strip --apply -- "-comment-slop.py")
if grep -Fq "Explains an obvious assignment." "$hyphen_target"; then
  echo "ordinary comment in a hyphen-prefixed path was not removed" >&2
  exit 1
fi

broad_fixture="$project_root/fixtures/comment-slop-broad.py"
broad_target="$workdir/comment-slop-broad.py"
cp "$broad_fixture" "$broad_target"

broad_ordinary_output="$($runner audit -- "$broad_target")"
grep -Fq "would remove 1 (L3)" <<<"$broad_ordinary_output"
if grep -Eq 'L1|L6|L9' <<<"$broad_ordinary_output"; then
  echo "ordinary audit included a broad-only candidate" >&2
  exit 1
fi
cmp --silent "$broad_fixture" "$broad_target"

broad_audit_output="$($runner audit --all -- "$broad_target")"
grep -Fq "would remove 4 (L1, L3, L6, L9)" <<<"$broad_audit_output"
cmp --silent "$broad_fixture" "$broad_target"

"$runner" strip --all --apply "$broad_target"
for removed_comment in \
  "Broad documentation candidate." \
  "Ordinary broad comment." \
  "Broad TODO candidate." \
  "Broad FIXME candidate."; do
  if grep -Fq "$removed_comment" "$broad_target"; then
    echo "broad strip retained: $removed_comment" >&2
    exit 1
  fi
done
grep -Fq 'broad_value = 1' "$broad_target"
grep -Fq 'broad_todo_value = 2' "$broad_target"
grep -Fq 'broad_fixme_value = 3' "$broad_target"

protected_fixture="$project_root/fixtures/comment-slop-protected.py"
protected_target="$workdir/comment-slop-protected.py"
cp "$protected_fixture" "$protected_target"

protected_ordinary_output="$($runner audit -- "$protected_target")"
grep -Fq "would remove 1 (L1)" <<<"$protected_ordinary_output"
if grep -Eq 'L4|L5|L6|L8|L9|L10' <<<"$protected_ordinary_output"; then
  echo "ordinary audit included a protected candidate" >&2
  exit 1
fi
cmp --silent "$protected_fixture" "$protected_target"

protected_broad_output="$($runner audit --all -- "$protected_target")"
grep -Fq "would remove 2 (L1, L10)" <<<"$protected_broad_output"
if grep -Eq 'L4|L5|L6|L8|L9' <<<"$protected_broad_output"; then
  echo "broad audit included a protected candidate" >&2
  exit 1
fi
cmp --silent "$protected_fixture" "$protected_target"

"$runner" strip --all --apply "$protected_target"
protected_expected="$workdir/comment-slop-protected.expected.py"
cat >"$protected_expected" <<'EOF'
PROTECTED_DOCUMENTATION_URL = "https://example.test/protected/#fragment"

# ruff: noqa: F401
# ~keep
# This protected comment remains.
protected_value = 1
trailing_protected_value = 3  # ~keep

protected_todo_value = 2
EOF
cmp --silent "$protected_expected" "$protected_target" \
  || { echo "protected strip output changed unexpectedly" >&2; diff -u "$protected_expected" "$protected_target"; exit 1; }

echo "comment-hygiene fixtures: ordinary, broad, protected, and string-data behavior passed"
