# Comment Hygiene

[![CI](https://github.com/tessariq/comment-hygiene/actions/workflows/ci.yml/badge.svg)](https://github.com/tessariq/comment-hygiene/actions/workflows/ci.yml)

Review and remove low-value code comments without mistaking comment-like text in
strings for comments.

Comment Hygiene combines the Rust
[`uncomment`](https://github.com/Goldziher/uncomment) CLI with a small safety
wrapper and a portable agent skill. Tree-sitter identifies actual comment nodes;
you or your coding agent decide which comments are useful.

## Why use it?

Comments that repeat the code create noise and become stale. Text-only removal is
risky, though: `https://example.test/#fragment` and similar string data can look
like comments to a regular expression.

This project keeps detection and judgment separate:

1. `uncomment` finds comments from the language syntax tree.
2. `audit` shows a dry-run diff without writing files.
3. A human or agent keeps comments that explain intent, constraints, or rationale.
4. `strip` requires an explicit apply step before it changes files.

It does **not** use an LLM to classify or rewrite comments.

## Requirements

- [Mise](https://mise.jdx.dev/)
- Git and Bash

Mise provisions the pinned Rust toolchain, `uncomment`, Task, Lefthook, and
Taskrail versions used by this repository.

## Quick start

```sh
git clone https://github.com/tessariq/comment-hygiene.git
cd comment-hygiene
mise trust
mise run setup
```

Preview ordinary comments in one or more changed files:

```sh
mise exec -- task audit -- path/to/file.py path/to/another.ts
```

Review the diff, then remove the ordinary comments you have intentionally
selected:

```sh
mise exec -- task strip -- path/to/file.py
```

## Commands

| Command | Behavior | Writes files? |
| --- | --- | --- |
| `task audit -- PATH...` | Preview ordinary comments | No |
| `task audit-all -- PATH...` | Also preview docs, TODO, and FIXME comments | No |
| `task strip -- PATH...` | Remove ordinary comments after the wrapper supplies `--apply` | Yes |
| `task strip-all -- PATH...` | Also remove docs, TODO, and FIXME comments | Yes |
| `mise run test` | Run the representative AST-safety fixture | Temporary copy only |
| `mise run check` | Run policy, syntax, planning, and behavioral checks | No |

`strip-all` is deliberately broad. Use it only after reviewing `audit-all` and
explicitly deciding that documentation and tracked follow-ups should be removed.
Recognized tooling directives and comments protected with `~keep` remain subject
to `uncomment`'s preservation rules.

## Agent skill

The portable skill at
[`skills/comment-hygiene/SKILL.md`](skills/comment-hygiene/SKILL.md) gives coding
agents a conservative review workflow and a simple decision rule:

> Delete a comment when a competent reader can infer it from the current code.
> Keep or rewrite it when it conveys intent, constraints, or rationale that the
> code does not make clear.

Package-manager installation for agent-skill ecosystems is planned rather than
claimed today. See the [v1.2 specification](specs/v1.2.0.md) for that roadmap.

## Safety model

- Audits are read-only.
- Mutating wrapper calls require `--apply`; public Task targets add it only for
  the explicit `strip` commands.
- License notices, generated-file markers, formatter directives, and explicitly
  protected comments should not be removed.
- A broad candidate list is never permission for bulk deletion.
- Project-specific `.uncommentrc.toml` rules can change preservation behavior;
  inspect them before relying on a preview.

## Development

```sh
mise run setup
mise run check
```

Git hooks are opt-in and installed by `mise run setup`. Lefthook runs the same
fast checks used in CI, enforces Conventional Commit messages with descriptive
bodies, and rejects automated attribution in commit history. See
[`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

This repository uses [Taskrail](https://github.com/tessariq/taskrail) for
versioned specifications and tracked follow-up work:

```sh
mise run workflow:status
mise run workflow:validate
```

The [v1.0 specification](specs/v1.0.0.md) records the existing behavior. Future
distribution and coverage work belongs to the [v1.2 specification](specs/v1.2.0.md).

## Limitations

- Syntax-aware detection cannot determine whether a comment is accurate or useful.
- `uncomment` previews are human-readable diffs, not a stable JSON analysis API.
- The fixture covers a representative Python path, not every language supported
  by `uncomment`.
- Comment Hygiene does not measure downstream model quality or hallucination rates.

## License

Licensed under the [Apache License 2.0](LICENSE). Hook-policy files adapted from
Taskrail retain the same license; see
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for provenance.
