#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
skill_file="$project_root/skills/comment-hygiene/SKILL.md"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

grep -Fq '## Installed-skill runtime' "$skill_file" \
  || fail "the canonical skill does not document the installed runtime"
grep -Fq 'uncomment 3.7.0' "$skill_file" \
  || fail "the installed runtime prerequisite is not pinned"
grep -Fq 'command -v uncomment' "$skill_file" \
  || fail "the installed runtime failure check is not documented"
grep -Fq 'NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff -- "path/to/changed-file.py"' "$skill_file" \
  || fail "the location-independent audit command is not documented"
grep -Fq 'NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff --remove-doc --remove-todo --remove-fixme -- "path/to/changed-file.py"' "$skill_file" \
  || fail "the location-independent broad-audit command does not quote its path"
grep -Fq 'mise exec -- task audit -- "path/to/changed-file.py"' "$skill_file" \
  || fail "the source audit example does not quote its path"
grep -Fq 'mise exec -- task audit-all -- "path/to/changed-file.py"' "$skill_file" \
  || fail "the source broad-audit example does not quote its path"
grep -Fq 'mise exec -- task strip -- "path/to/changed-file.py"' "$skill_file" \
  || fail "the source strip example does not quote its path"

prerequisite_script="$workdir/prerequisite.sh"
awk '
  /^## Installed-skill runtime$/ { in_section = 1; next }
  /^## Source-repository workflow$/ { exit }
  in_section && /^```sh$/ && !in_block { in_block = 1; next }
  in_block && /^```$/ { exit }
  in_block { print }
' "$skill_file" >"$prerequisite_script"
[[ -s "$prerequisite_script" ]] \
  || fail "could not extract the installed runtime prerequisite"

expect_prerequisite_failure() {
  local label="$1"
  local expected="$2"
  local bin_dir="$3"
  local output
  local status

  if output="$(PATH="$bin_dir" /bin/sh "$prerequisite_script" 2>&1)"; then
    fail "$label prerequisite unexpectedly passed"
  else
    status=$?
  fi
  [[ "$status" -eq 2 ]] || fail "$label prerequisite exited with $status instead of 2"
  grep -Fq "$expected" <<<"$output" \
    || fail "$label prerequisite did not explain the failure: $output"
}

missing_bin="$workdir/missing-bin"
mkdir -p "$missing_bin"
expect_prerequisite_failure "missing binary" "required as an executable" "$missing_bin"

non_executable_bin="$workdir/non-executable-bin"
mkdir -p "$non_executable_bin"
cat >"$non_executable_bin/uncomment" <<'EOF'
#!/bin/sh
printf '%s\n' 'uncomment 3.7.0'
EOF
expect_prerequisite_failure "non-executable binary" "required as an executable" "$non_executable_bin"
if output="$(
  cd "$workdir"
  PATH="$non_executable_bin" /bin/bash -c \
    'hash -p "$1/uncomment" uncomment; . "$2"' \
    bash "$non_executable_bin" "$prerequisite_script" 2>&1
)"; then
  fail "hashed non-executable prerequisite unexpectedly passed"
else
  status=$?
fi
[[ "$status" -eq 2 ]] \
  || fail "hashed non-executable prerequisite exited with $status instead of 2"
grep -Fq 'required as an executable' <<<"$output" \
  || fail "hashed non-executable prerequisite did not reject the file: $output"

wrong_version_bin="$workdir/wrong-version-bin"
mkdir -p "$wrong_version_bin"
cat >"$wrong_version_bin/uncomment" <<'EOF'
#!/bin/sh
printf '%s\n' 'uncomment 3.6.0'
EOF
chmod +x "$wrong_version_bin/uncomment"
expect_prerequisite_failure "wrong version" "expected uncomment 3.7.0" "$wrong_version_bin"

failing_version_bin="$workdir/failing-version-bin"
mkdir -p "$failing_version_bin"
cat >"$failing_version_bin/uncomment" <<'EOF'
#!/bin/sh
printf '%s\n' 'uncomment 3.7.0'
exit 7
EOF
chmod +x "$failing_version_bin/uncomment"
expect_prerequisite_failure "failing version probe" "could not run" "$failing_version_bin"

cat >"$workdir/uncomment" <<'EOF'
#!/bin/sh
printf '%s\n' 'uncomment 3.7.0'
EOF
chmod +x "$workdir/uncomment"
if output="$(
  cd "$workdir"
  PATH="$missing_bin" /bin/bash -c \
    'uncomment() { printf "%s\\n" "uncomment 3.7.0"; }; . "$1"' \
    bash "$prerequisite_script" 2>&1
)"; then
  fail "shell-function shadow prerequisite unexpectedly passed"
else
  status=$?
fi
[[ "$status" -eq 2 ]] \
  || fail "shell-function shadow prerequisite exited with $status instead of 2"
grep -Fq 'required as an executable' <<<"$output" \
  || fail "shell-function shadow prerequisite did not reject the shadow: $output"

command -v uncomment >/dev/null 2>&1 \
  || fail "uncomment is unavailable; run this test through the pinned Mise environment"
[[ "$(uncomment --version)" == 'uncomment 3.7.0' ]] \
  || fail "the test requires uncomment 3.7.0"

target="$workdir/target"
mkdir -p "$target/.agents/skills/comment-hygiene"
cp "$skill_file" "$target/.agents/skills/comment-hygiene/SKILL.md"

cat >"$target/runtime.py" <<'EOF'
"""Documentation remains in ordinary mode."""

# Ordinary narration.
URL = "https://example.test/docs/#fragment"

# ruff: noqa: F401
# ~keep
# This protected comment remains.
protected = True

# TODO: Keep this follow-up in ordinary mode.
value = 1
EOF

[[ ! -e "$target/Taskfile.yml" ]] || fail "target unexpectedly has a Taskfile"
[[ ! -e "$target/mise.toml" ]] || fail "target unexpectedly has Mise configuration"
[[ ! -e "$target/scripts/comment-hygiene" ]] \
  || fail "target unexpectedly has the source wrapper"
[[ "$(find "$target" -type f -name SKILL.md | wc -l)" -eq 1 ]] \
  || fail "target does not contain exactly one installed SKILL.md"

before_hash="$(sha256sum "$target/runtime.py")"
ordinary_output="$(cd "$target" && /bin/sh -c '
  . "$1"
  NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff -- runtime.py
' sh "$prerequisite_script")"
grep -Fq 'would remove 1' <<<"$ordinary_output" \
  || fail "installed ordinary audit did not identify one comment"
[[ "$before_hash" == "$(sha256sum "$target/runtime.py")" ]] \
  || fail "ordinary installed audit changed its input"

broad_output="$(cd "$target" && /bin/sh -c '
  . "$1"
  NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff \
    --remove-doc --remove-todo --remove-fixme -- runtime.py
' sh "$prerequisite_script")"
grep -Fq 'would remove 3' <<<"$broad_output" \
  || fail "installed broad audit did not identify docs, ordinary, and TODO comments"
[[ "$before_hash" == "$(sha256sum "$target/runtime.py")" ]] \
  || fail "broad installed audit changed its input"

grep -Fq 'https://example.test/docs/#fragment' "$target/runtime.py" \
  || fail "installed audit changed URL-like string data"
grep -Fq '# ruff: noqa: F401' "$target/runtime.py" \
  || fail "installed audit removed a tool directive"
grep -Fq '# ~keep' "$target/runtime.py" \
  || fail "installed audit removed the protection marker"
grep -Fq '# This protected comment remains.' "$target/runtime.py" \
  || fail "installed audit removed a protected comment"

printf 'installed runtime checks passed\n'
