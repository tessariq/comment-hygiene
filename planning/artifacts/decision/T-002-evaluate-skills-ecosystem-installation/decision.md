# T-002 decision record: skills ecosystem installation

- Evaluated: 2026-09-21
- Installer: `skills` npm package `1.7.0`
- Public source: `https://github.com/tessariq/comment-hygiene`
- Observed source revision: `2ab968cee8842bdc4097b3ea742e0d611e1634ad` (`main`)
- Canonical skill: `skills/comment-hygiene/SKILL.md`

## Decision

Use the public repository with the pinned CLI invocation below. Keep
`skills/comment-hygiene/SKILL.md` as the only maintained instruction source.
Installer-created copies and symlinks are generated outputs; users must not edit
them as independent forks.

```sh
npx --yes skills@1.7.0 add \
  https://github.com/tessariq/comment-hygiene \
  --skill comment-hygiene \
  --agent claude-code codex amp opencode \
  --yes
```

The non-writing source-enumeration command used first was:

```sh
npx --yes skills@1.7.0 add \
  https://github.com/tessariq/comment-hygiene \
  --list
```

Observed output was `Found 1 skill`, containing `comment-hygiene` with the
repository's current description. The exact version command returned `1.7.0`.

## Installer observations

The CLI uses a shared universal project directory for Codex, Amp, and OpenCode:

| Scope | Claude Code | Codex, Amp, OpenCode |
| --- | --- | --- |
| Project, default | `.claude/skills/comment-hygiene/SKILL.md` | `.agents/skills/comment-hygiene/SKILL.md` |
| User, `--global` | `~/.claude/skills/comment-hygiene/SKILL.md` | `~/.agents/skills/comment-hygiene/SKILL.md` |

When all four agents are selected in the default project mode, v1.7.0 creates a
regular canonical copy at `.agents/skills/comment-hygiene` and a symlink at
`.claude/skills/comment-hygiene` pointing to it. A single selected target is a
regular installer-managed directory. Adding `--copy` creates independent regular
directories at both target paths instead of the Claude Code symlink.

The same target behavior was observed for user scope with `--global`. Amp also
documents `~/.config/agents/skills/` as a user-level location, and its discovery
precedence includes `~/.agents/skills/`; the selected CLI contract uses the
observed shared `~/.agents/skills/` path so Codex, Amp, and OpenCode share one
installer-managed source.

The project install creates `skills-lock.json` for source tracking. Removal
deletes the selected skill directory or link but may leave the lock file and
empty container directory for a project that has no other installed skills.

## Update and removal semantics

The observed management commands are:

```sh
# Refresh project-installed skills from their recorded sources.
npx --yes skills@1.7.0 update -p -y

# Refresh user-installed skills from their recorded sources.
npx --yes skills@1.7.0 update -g -y

# Remove an installation from a single-target project.
npx --yes skills@1.7.0 remove comment-hygiene --agent amp --yes

# Remove an installation from a single-target user scope.
npx --yes skills@1.7.0 remove comment-hygiene --global --agent amp --yes

# Remove a four-agent project installation completely.
npx --yes skills@1.7.0 remove comment-hygiene \
  --agent claude-code codex amp opencode --yes

# Remove a four-agent user installation completely.
npx --yes skills@1.7.0 remove comment-hygiene \
  --global --agent claude-code codex amp opencode --yes
```

Both update commands exited successfully and refreshed the public source in the
clean temporary checks. Removal from a single-target installation exited
successfully and removed that installed skill. Removal scope follows the
filesystem target, not the agent label: in a four-agent project install,
`--agent amp` deleted the shared `.agents/skills/comment-hygiene` directory and
left the `.claude/skills/comment-hygiene` symlink dangling. In the equivalent
four-agent global check, the same command exited zero but left the shared global
directory and symlink in place. The explicit four-agent removal command above
exited zero and removed both scopes cleanly. `--agent '*'` was rejected as an
invalid agent by v1.7.0 despite examples in the repository README, so it is not
the cleanup contract.

There is a second important v1.7.0 qualification: `update -p -y` run after an
Amp-only project install also materialized a Claude Code symlink and an
`agent/skills/comment-hygiene` directory; the resulting listing reported Claude
Code and Eve. This is not a target-exclusive update. T-005 must reproduce both
the shared-target removal behavior and this update side effect in its
clean-install procedure, and support documentation must not promise
side-effect-free updates until they are bounded or corrected.

## Support matrix

“Installer path observed” only means the CLI wrote the expected filesystem
location. “Discovery observed” requires the relevant agent or its documented
inspection command to run. No agent is declared supported by path alone.

| Agent claim | Primary source locator | Installer path observed | Discovery result in this evaluation | Status |
| --- | --- | --- | --- | --- |
| Claude Code | [Claude Code skills](https://code.claude.com/docs/en/skills) | Project `.claude/skills/comment-hygiene/SKILL.md`; user `~/.claude/skills/comment-hygiene/SKILL.md`; default multi-agent install symlinked the project path to `.agents` | `claude` executable unavailable; no runtime discovery performed | Unverified |
| Codex | [OpenAI Codex skills](https://developers.openai.com/codex/skills) | Project and user `.agents/skills/comment-hygiene/SKILL.md` | `codex` executable unavailable; no runtime discovery performed | Unverified |
| Amp | [Amp skills](https://ampcode.com/docs/customize/skills) and [Amp Agent Skills](https://ampcode.com/news/agent-skills) | Project and user `.agents/skills/comment-hygiene/SKILL.md` | `amp --version` returned `0.0.1790006436-gaf5042`; `amp skills list --json` found `comment-hygiene` with source `workspace-agents` and the installed `.agents/skills/comment-hygiene` base directory | Installer/discovery observed; runtime audit remains T-005 |
| OpenCode | [OpenCode skills](https://opencode.ai/docs/skills) | Project and user `.agents/skills/comment-hygiene/SKILL.md` | `opencode` executable unavailable; no runtime discovery performed | Unverified |

The CLI's `--list` result proves source-layout recognition for the one canonical
skill. It does not prove agent discovery or that the installed instructions can
run their audit outside this repository.

## Standard-layout check

The canonical file has the required YAML frontmatter fields:

```yaml
name: comment-hygiene
description: Review and reduce low-value code comments with AST-safe candidate detection from uncomment.
```

The directory name matches `name`, and the source enumeration found exactly one
skill. No alternate agent-specific `SKILL.md` is needed or selected.

## Follow-up boundaries

- **T-004:** replace the current repository-root-only runtime instructions with
  an explicit location-independent command or bundled support path. Preserve the
  existing clone-root Taskfile workflow and the one canonical `SKILL.md`; this
  record makes no claim that the current installed skill can already audit a
  foreign repository.
- **T-005:** start from the public revision in an isolated `HOME` and empty Git
  target; verify each agent's discovery evidence, installed path, destination
  type, read-only audit, byte-for-byte fixture preservation, cleanup, and the
  update side effect noted above. Keep Claude Code, Codex, and OpenCode
  unverified unless their actual discovery checks pass.

## Primary references and access date

All references below were accessed on 2026-09-21:

- [Skills CLI repository](https://github.com/vercel-labs/skills): source formats,
  `--list`, target agents, symlink/copy modes, update, and removal commands.
- [Agent Skills specification](https://agentskills.io/specification): required
  `SKILL.md` structure and `name`/`description` constraints.
- [Claude Code skills](https://code.claude.com/docs/en/skills): project and
  personal locations, symlink handling, discovery, and removal.
- [Codex skills](https://developers.openai.com/codex/skills): repository and user
  discovery locations, symlink support, and `/skills` inspection.
- [Amp skills](https://ampcode.com/docs/customize/skills): project and user
  locations, precedence, and management commands.
- [Amp Agent Skills](https://ampcode.com/news/agent-skills): `.agents/skills`
  project installation and compatible user locations.
- [OpenCode skills](https://opencode.ai/docs/skills): project/global compatible
  paths and required frontmatter.
