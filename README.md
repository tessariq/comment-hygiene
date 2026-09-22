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

Mise provisions the pinned `uncomment`, Task, Lefthook, and Taskrail versions used
by this repository. `uncomment` is installed from its published release binary,
so contributors do not need a local Rust toolchain.

## Quick start

```sh
git clone https://github.com/tessariq/comment-hygiene.git
cd comment-hygiene
mise trust
mise run setup
```

Preview ordinary comments in one or more changed files:

```sh
mise exec -- task audit -- "path/to/file.py" "path/to/another.ts"
```

Review the diff, then remove the ordinary comments you have intentionally
selected:

```sh
mise exec -- task strip -- "path/to/file.py"
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

The direct-clone workflow above and the distributed installation below are
separate. A distributed install uses the canonical public source
[`skills/comment-hygiene/SKILL.md`](skills/comment-hygiene/SKILL.md); installer
outputs are generated files, not alternate instruction sources. Do not edit an
installed copy as an independent fork.

### Verified agent support

The clean-install verification used `skills@1.7.0` against public source
revision `e329be0487bfd077b06334141d2c7a01bb73b1e7`. It installed the source
from that immutable revision, checked the installed runtime in a target with no
Comment Hygiene Taskfile, Mise configuration, or source wrapper, and removed
each temporary installation afterward. The full scrubbed record is in
[`T-005 clean-install evidence`](planning/artifacts/verification/T-005-verify-clean-agent-skill-installations/report.md).

| Agent | Tested agent version | Installed destination | Discovery and runtime result | Support |
| --- | --- | --- | --- | --- |
| Claude Code | unavailable in the verification environment | `.claude/skills/comment-hygiene/SKILL.md` (regular file observed) | Installation/runtime/cleanup passed; the `claude` executable and discovery were unavailable | **Unverified** |
| Codex | unavailable in the verification environment | `.agents/skills/comment-hygiene/SKILL.md` (regular file observed) | Installation/runtime/cleanup passed; the `codex` executable and discovery were unavailable | **Unverified** |
| Amp | `0.0.1790006436-gaf5042` | `.agents/skills/comment-hygiene/SKILL.md` (regular file observed) | `amp skills list --json` found the installed `workspace-agents` skill; the ordinary and broad read-only audits and cleanup passed | **Verified** |
| OpenCode | unavailable in the verification environment | `.agents/skills/comment-hygiene/SKILL.md` (regular file observed) | Installation/runtime/cleanup passed; the `opencode` executable and discovery were unavailable | **Unverified** |

Only Amp is verified. A known installer path is not evidence of agent support;
do not infer compatibility with Claude Code, Codex, OpenCode, other agents, or
other agent versions from this table.

For the single verified Amp target, `skills@1.7.0` creates a regular
installer-managed file at the path shown above. When all four agent targets are
selected, v1.7.0 creates a regular canonical copy under
`.agents/skills/comment-hygiene` and a Claude Code symlink under
`.claude/skills/comment-hygiene`; pass `--copy` when regular copies are
required.

### Install, update, and remove Amp

The project target is `.agents/skills/comment-hygiene/SKILL.md`; the user-local
`--global` target is `~/.agents/skills/comment-hygiene/SKILL.md`.

Install the verified project-local target from the repository root of the
project where the skill should be available:

```sh
npx --yes skills@1.7.0 add \
  https://github.com/tessariq/comment-hygiene \
  --skill comment-hygiene \
  --agent amp \
  --yes
```

For a user-local installation available across projects, use the global target:

```sh
npx --yes skills@1.7.0 add \
  https://github.com/tessariq/comment-hygiene \
  --global \
  --skill comment-hygiene \
  --agent amp \
  --yes
```

The corresponding update commands are:

```sh
# Project-local installation.
npx --yes skills@1.7.0 update -p -y

# User-local installation.
npx --yes skills@1.7.0 update -g -y
```

Updates are not guaranteed to be target-exclusive. The observed `skills@1.7.0`
project update after an Amp-only install also created a Claude Code symlink and
an `agent/skills/comment-hygiene` directory. Review the resulting skill list
after updating and remove unintended targets. In that state, removing only
`--agent amp` can delete the shared `.agents/skills` source while leaving a
dangling Claude Code symlink; use the all-agent cleanup below instead.

Remove a project-local or user-local installation that was created for Amp
alone with:

```sh
# Project-local installation.
npx --yes skills@1.7.0 remove comment-hygiene --agent amp --yes

# User-local installation.
npx --yes skills@1.7.0 remove comment-hygiene --global --agent amp --yes
```

For a multi-agent project install, remove every selected agent in one command
so the shared `.agents/skills` source and any agent links are cleaned together:

```sh
npx --yes skills@1.7.0 remove comment-hygiene \
  --agent claude-code codex amp opencode \
  --yes
```

For a shared user-local installation, include `--global` in the same cleanup:

```sh
npx --yes skills@1.7.0 remove comment-hygiene \
  --global \
  --agent claude-code codex amp opencode \
  --yes
```

The CLI may leave `skills-lock.json` and empty container directories after
removal. Do not delete another agent's skills when cleaning a shared target.

### Installed runtime

The distributed skill requires the separately installed `uncomment 3.7.0`
release binary. It is intentionally not bundled with the skill. Check the
prerequisite in the same shell as the audit commands:

```sh
uncomment_path="$(command -v uncomment 2>/dev/null || true)"
if [ -z "$uncomment_path" ] || [ "${uncomment_path#*/}" = "$uncomment_path" ] || [ ! -f "$uncomment_path" ] || [ ! -x "$uncomment_path" ]; then
  printf '%s\n' 'comment-hygiene: install uncomment 3.7.0 from https://github.com/Goldziher/uncomment/releases.' >&2
  exit 2
fi
[ "$("$uncomment_path" --version 2>/dev/null)" = 'uncomment 3.7.0' ] || {
  printf '%s\n' 'comment-hygiene: expected uncomment 3.7.0.' >&2
  exit 2
}
```

From any target repository, preview ordinary comments without a Taskfile, Mise
configuration, or copied wrapper:

```sh
NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff -- "path/to/changed-file.py"
```

To include documentation, TODO, and FIXME candidates, add
`--remove-doc --remove-todo --remove-fixme`. These commands are read-only;
review the diff and keep the installed skill's explicit judgment and apply
safety rules.

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

Licensed under the [Apache License 2.0](LICENSE).
