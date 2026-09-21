---
name: comment-hygiene
description: Review and reduce low-value code comments with AST-safe candidate detection from uncomment.
---

# Comment hygiene

Use this skill after implementing or substantially changing source code. Its goal
is to remove stale narration while retaining information that is not recoverable
from the code itself.

## Scope and safety

- Review only files changed in the current task unless the user explicitly asks
  for a wider cleanup.
- Never use a regex or text replacement to identify comments. In the source
  repository, use `uncomment` through its Taskfile; from an installed copy, use
  the prerequisite and direct command below so strings that resemble comments
  are safe.
- `uncomment` identifies comment nodes; it does not judge whether a comment is
  useful and it cannot rewrite prose. Make that judgment from the code and its
  surrounding contract.
- Do not remove license notices, generated-file markers, formatter/linter/tool
  directives, or a comment the user explicitly asked to retain.

## Installed-skill runtime

An installed copy must run against the target repository without assuming that
the Comment Hygiene source repository, its `Taskfile.yml`, Mise configuration,
or `scripts/comment-hygiene` wrapper is present. The distributed audit uses the
separately installed `uncomment` 3.7.0 command on `PATH`; that external
dependency is intentionally not bundled into the skill.

Before auditing from an installed copy, run this prerequisite check in the same
shell as the commands below. It resolves an actual executable and leaves its
verified path in `$uncomment_path`:

```sh
uncomment_path="$(command -v uncomment 2>/dev/null || true)"
if [ -z "$uncomment_path" ] || [ "${uncomment_path#*/}" = "$uncomment_path" ] || [ ! -f "$uncomment_path" ] || [ ! -x "$uncomment_path" ]; then
  printf '%s\n' 'comment-hygiene: uncomment 3.7.0 is required as an executable on PATH; install the published release binary from https://github.com/Goldziher/uncomment/releases.' >&2
  exit 2
fi
if version="$("$uncomment_path" --version 2>/dev/null)"; then
  :
else
  printf '%s\n' 'comment-hygiene: could not run uncomment --version; check the active executable before continuing.' >&2
  exit 2
fi
if [ "$version" != "uncomment 3.7.0" ]; then
  printf '%s\n' 'comment-hygiene: expected uncomment 3.7.0; check the active binary before continuing.' >&2
  exit 2
fi
```

From any target repository, preview ordinary comments directly with the
location-independent command below. It is read-only and does not use a
Taskfile, Mise, or this repository's wrapper:

```sh
NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff -- "path/to/changed-file.py"
```

To include documentation, TODO, and FIXME candidates in the same read-only
preview, add the explicit broad-mode flags:

```sh
NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff --remove-doc --remove-todo --remove-fixme -- "path/to/changed-file.py"
```

Do not use a mutating `uncomment` command as a substitute for the review below;
the installed skill's audit boundary is preview-only.

## Source-repository workflow

1. From the `comment-hygiene` repository root, install the pinned tools once:

   ```sh
   mise trust
   mise run setup
   ```

2. Preview ordinary comment candidates for each changed source file. This command
   does not write files:

   ```sh
   mise exec -- task audit -- "path/to/changed-file.py"
   ```

3. Read each candidate with its adjacent code. Delete comments that merely restate
   a name, type, assignment, loop, branch, or return statement. Rewrite rather
   than delete a comment only if it can state a concrete invariant, rationale,
   compatibility constraint, security concern, or non-obvious trade-off.

4. Review documentation comments and TODO/FIXME comments separately. To include
   them in an AST-safe preview without writing files:

   ```sh
   mise exec -- task audit-all -- "path/to/changed-file.py"
   ```

   Retain public API documentation where the project convention requires it. A
   TODO/FIXME must identify the problem or trigger; otherwise delete it or turn
   it into a tracked task according to project policy.

5. Edit selected comments directly. Do not run `strip` as a substitute for this
   judgment. For an explicitly authorized bulk deletion of ordinary comments,
   preview first and then run:

   ```sh
   mise exec -- task strip -- "path/to/changed-file.py"
   ```

   `strip-all` also removes docs, TODOs, and FIXMEs; use it only with explicit
   authorization. Both targets still preserve recognized tool directives and
   comments protected by uncomment's `~keep` marker.

6. Inspect the final diff and run the affected project's formatter and tests.
   Confirm that every retained comment explains something the code alone does
   not make clear.

## Decision rule

Delete a comment by default when a competent reader can infer its content from
the current code. Retain or rewrite it only when it conveys intent, constraints,
or rationale unavailable from that code.

Do not claim this reduces model hallucinations as a measured result. It removes
one source of redundant and potentially stale context.
