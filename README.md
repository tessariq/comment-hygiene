# Comment Hygiene

[![CI](https://github.com/tessariq/comment-hygiene/actions/workflows/ci.yml/badge.svg)](https://github.com/tessariq/comment-hygiene/actions/workflows/ci.yml)

Review and remove low-value code comments without confusing comment-like text in
strings for comments.

Comment Hygiene uses the Rust [`uncomment`](https://github.com/Goldziher/uncomment)
CLI to find actual comment nodes with Tree-sitter. It does not use an LLM to
classify or rewrite comments: people and coding agents decide which candidates
are worth keeping.

## Start here

Choose the workflow that fits your use case:

- **Working in this repository?** Use the [direct-clone workflow](#direct-clone-workflow).
- **Using the portable skill in another repository?** See
  [install the skill](#install-the-skill). Amp is the currently verified
  installer integration.

The safety model is the same in both cases: preview first, review the diff, and
apply only the removals you intend.

## How it works

1. `uncomment` identifies comments from the language syntax tree.
2. `audit` presents a read-only diff of candidates.
3. You decide whether each comment adds intent, constraints, or rationale.
4. `strip` makes changes only after an explicit apply step.

This avoids treating string content such as `https://example.test/#fragment` as
a comment, which a text-only approach can do.

## Direct-clone workflow

### Requirements

- [Mise](https://mise.jdx.dev/)
- Git and Bash

Mise provisions this repository's pinned versions of `uncomment`, Task,
Lefthook, and Taskrail. No local Rust toolchain is required.

### Set up and preview

```sh
git clone https://github.com/tessariq/comment-hygiene.git
cd comment-hygiene
mise trust
mise run setup

# Preview ordinary comments in one or more files. This does not write files.
mise exec -- task audit -- "path/to/file.py" "path/to/another.ts"
```

Read the resulting diff. Remove only the ordinary comments you have deliberately
selected:

```sh
mise exec -- task strip -- "path/to/file.py"
```

### Commands

| Command | What it does | Writes files? |
| --- | --- | --- |
| `task audit -- PATH...` | Preview ordinary comments | No |
| `task audit-all -- PATH...` | Also preview docs, TODOs, and FIXMEs | No |
| `task strip -- PATH...` | Remove ordinary comments after explicit apply | Yes |
| `task strip-all -- PATH...` | Also remove docs, TODOs, and FIXMEs | Yes |
| `mise run test` | Run the representative AST-safety fixture | Temporary copy only |
| `mise run check` | Run policy, syntax, planning, and behavioral checks | No |

`strip-all` is deliberately broad. Use it only after reviewing `audit-all` and
deciding that documentation and tracked follow-ups should be removed.

## Install the skill

The portable skill is agent-agnostic: it defines the same conservative review
process for any compatible coding agent, without requiring this repository's
Taskfile, Mise configuration, or wrapper script.

> **Verified installation:** Amp is the only integration verified so far. The
> canonical skill is not Amp-specific, but do not infer discovery support for
> Claude Code, Codex, OpenCode, other agents, or other versions from an
> installer path alone. See [verified support](#verified-support) for scope.

### Install with Amp

Run one of these commands from the project that should receive the skill, or use
the global form to make it available across your projects.

```sh
# Project-local installation.
npx --yes skills@1.7.0 add \
  https://github.com/tessariq/comment-hygiene \
  --skill comment-hygiene \
  --agent amp \
  --yes

# User-local installation.
npx --yes skills@1.7.0 add \
  https://github.com/tessariq/comment-hygiene \
  --global \
  --skill comment-hygiene \
  --agent amp \
  --yes
```

The project target is `.agents/skills/comment-hygiene/SKILL.md`; the global
target is `~/.agents/skills/comment-hygiene/SKILL.md`. These are generated,
installer-managed copies of the canonical
[`skills/comment-hygiene/SKILL.md`](skills/comment-hygiene/SKILL.md). Do not
edit an installed copy as an independent fork.

### Update or remove an Amp installation

```sh
# Update: project-local / user-local.
npx --yes skills@1.7.0 update -p -y
npx --yes skills@1.7.0 update -g -y

# Remove an Amp-only installation: project-local / user-local.
npx --yes skills@1.7.0 remove comment-hygiene --agent amp --yes
npx --yes skills@1.7.0 remove comment-hygiene --global --agent amp --yes
```

If the installation is shared by several agents, remove all of those targets in
one command so shared source files and links are cleaned together:

```sh
# Add --global for a shared user-local installation.
npx --yes skills@1.7.0 remove comment-hygiene \
  --agent claude-code codex amp opencode \
  --yes
```

The observed `skills@1.7.0` project update after an Amp-only install also
created a Claude Code symlink and an `agent/skills/comment-hygiene` directory.
Review the installed skill list after updating. Removing only `--agent amp` in
that state can leave a dangling Claude Code symlink. The CLI may also leave
`skills-lock.json` and empty container directories; do not delete another
agent's skills during cleanup.

### Use the installed skill

The distributed skill requires the separately installed `uncomment 3.7.0`
release binary on `PATH`; it is intentionally not bundled. Confirm that exact
version in the same shell you will use for an audit:

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

Then preview ordinary comments from any target repository. This command is
read-only:

```sh
NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff -- "path/to/changed-file.py"
```

To include documentation, TODO, and FIXME candidates, add
`--remove-doc --remove-todo --remove-fixme`. Review the diff and follow the
skill's explicit judgment and safety rules; do not substitute a mutating direct
`uncomment` command for that review.

## Verified support

Clean-install verification used `skills@1.7.0` with public source revision
`e329be0487bfd077b06334141d2c7a01bb73b1e7`. It installed from that immutable
revision into a target without Comment Hygiene's Taskfile, Mise configuration,
or wrapper, ran the installed read-only workflow, and removed every temporary
installation afterward.

| Agent | Tested version | Result |
| --- | --- | --- |
| Amp | `0.0.1790006436-gaf5042` | **Verified** — `amp skills list --json` discovered the installed `workspace-agents` skill; ordinary and broad audits and cleanup passed. |
| Claude Code | Unavailable | **Unverified** — installation, runtime, and cleanup passed, but the executable and discovery were unavailable. |
| Codex | Unavailable | **Unverified** — installation, runtime, and cleanup passed, but the executable and discovery were unavailable. |
| OpenCode | Unavailable | **Unverified** — installation, runtime, and cleanup passed, but the executable and discovery were unavailable. |

The full scrubbed record, including observed destination types, is in the
[`T-005 clean-install evidence`](planning/artifacts/verification/T-005-verify-clean-agent-skill-installations/report.md).

## Safety and limitations

- Audits are read-only; the repository's mutating commands add `--apply` only
  for `strip` and `strip-all`.
- Keep license notices, generated-file markers, formatter or linter directives,
  and comments explicitly protected with `~keep`.
- A broad candidate list is not permission for bulk deletion.
- Project-specific `.uncommentrc.toml` rules can change preservation behavior;
  inspect them before relying on a preview.
- Syntax-aware detection cannot decide whether a comment is accurate or useful.
- The fixture covers a representative Python path, not every language supported
  by `uncomment`.

## Development

```sh
mise run setup
mise run check
```

`mise run setup` installs opt-in Git hooks. See
[`CONTRIBUTING.md`](CONTRIBUTING.md) for contribution and commit rules.

This repository uses [Taskrail](https://github.com/tessariq/taskrail) for
versioned specifications and tracked follow-up work:

```sh
mise run workflow:status
mise run workflow:validate
```

## License

Licensed under the [Apache License 2.0](LICENSE).
