# Comment hygiene prototype

**Status:** active prototype

This prototype evaluates an AST-safe workflow for reducing low-value comments in
code written by coding agents. It combines the Rust
[uncomment](https://github.com/Goldziher/uncomment) CLI with a Taskfile wrapper
and a portable agent skill. `uncomment` uses Tree-sitter to identify comment
nodes, avoiding false positives from comment-like text in strings.

The prototype does not use an LLM to classify or rewrite comments. An agent must
make that semantic judgment from the code and its surrounding contract.

## Scope

The wrapper offers a safe preview before an intentional in-place removal:

- `audit` previews ordinary comments that `uncomment` would remove.
- `audit-all` also previews documentation, TODO, and FIXME comments.
- `strip` removes ordinary comments after an explicit apply step.
- `strip-all` broadens removal to documentation, TODO, and FIXME comments.

Recognized tooling directives and `~keep`-protected comments remain protected by
`uncomment`. A broad audit is not permission to remove those comments; use it to
inspect them before direct edits.

## Setup

Mise installs the pinned Rust toolchain, `uncomment` 3.7.0, and Task 3.53.1:

```sh
cd prototypes/comment-hygiene
mise trust
mise run setup
```

## Use

Preview candidates without writing files:

```sh
mise exec -- task audit -- path/to/changed-file.py
```

Preview documentation and TODO/FIXME comments too:

```sh
mise exec -- task audit-all -- path/to/changed-file.py
```

After reviewing the preview, remove ordinary comments in place:

```sh
mise exec -- task strip -- path/to/changed-file.py
```

Use `strip-all` only for explicitly authorized bulk removal. It also removes
documentation, TODO, and FIXME comments. The implementation requires `--apply`
internally, so a direct invocation of `scripts/comment-hygiene strip` fails until
that flag is supplied.

See [`skills/comment-hygiene/SKILL.md`](skills/comment-hygiene/SKILL.md) for the
agent-facing workflow and decision rule.

Optional coverage follow-ups are recorded in [`notes.md`](notes.md).

## Verification

```sh
mise run test
mise run check
```

The behavioral test copies a Python fixture, invokes the real `uncomment` CLI
through the wrapper, and checks that ordinary comments are removed while a URL
inside a string and a TODO comment remain. It does not evaluate the quality of an
agent's semantic decisions or test every language supported by `uncomment`.

## Limitations

- `uncomment` has no JSON AST export or comment-quality analysis mode. Its
  previews are human-readable output with line ranges and diffs.
- AST recognition avoids comment-like strings but cannot determine whether a
  comment is accurate, necessary, or misleading.
- The `uncomment` preservation rules are its own configuration and versioned
  behavior. Check a project's `.uncommentrc.toml` before relying on a preview.
