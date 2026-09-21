#!/usr/bin/env bash
# Enforce Conventional Commit subjects, descriptive bodies, and clean attribution.
set -euo pipefail

msg_file="${1:-}"
if [[ -z "$msg_file" || ! -f "$msg_file" ]]; then
  echo "check-commit-msg: missing commit message file argument" >&2
  exit 1
fi

subject="$(grep -vE '^[[:space:]]*#' "$msg_file" | sed '/^[[:space:]]*$/d' | head -n 1)"
require_body=true

case "$subject" in
  "Merge "* | "Revert "* | "fixup! "* | "squash! "*)
    require_body=false
    ;;
  *)
    if ! printf '%s' "$subject" | grep -qE '^(feat|fix|refactor|docs|test|chore|perf|ci)(\([a-z0-9._-]+\))?!?: .+'; then
      echo "check-commit-msg: subject must be a Conventional Commit:" >&2
      echo "  <type>: <description>   (types: feat fix refactor docs test chore perf ci)" >&2
      echo "got: ${subject:-<empty>}" >&2
      exit 1
    fi
    subject_without_task_suffix="$(printf '%s' "$subject" | sed -E 's/ \(T-[0-9]+\)$//')"
    if printf '%s' "$subject_without_task_suffix" | grep -qE 'T-[0-9]+'; then
      echo "check-commit-msg: task references must use a short-key subject suffix:" >&2
      echo "  feat: add a focused capability (T-012)" >&2
      exit 1
    fi
    ;;
esac

if [[ "$require_body" == true ]]; then
  if ! awk '
    /^[[:space:]]*#/ { next }
    !subject && /^[[:space:]]*$/ { next }
    !subject { subject = 1; next }
    !separator && /^[[:space:]]*$/ { separator = 1; next }
    !separator { invalid = 1; next }
    !/^[[:space:]]*$/ { body = 1 }
    END { exit !(separator && body && !invalid) }
  ' "$msg_file"; then
    echo "check-commit-msg: add a descriptive body after the subject" >&2
    echo "  Explain intent, context, and non-obvious decisions after a blank line." >&2
    exit 1
  fi

  if ! awk '
    /^[[:space:]]*#/ { next }
    !subject && /^[[:space:]]*$/ { next }
    !subject { subject = 1; next }
    !separator && /^[[:space:]]*$/ { separator = 1; next }
    separator && length($0) > 72 { exit 1 }
  ' "$msg_file"; then
    echo "check-commit-msg: wrap body lines at 72 characters" >&2
    exit 1
  fi
fi

if ! bash "$(dirname "${BASH_SOURCE[0]}")/check-attribution.sh" "$msg_file"; then
  echo "check-commit-msg: remove automated-attribution lines" >&2
  exit 1
fi
