# Contributing

Humans and AI agents both contribute here. Agentic coding and AI-assisted
contributions are welcome. This guide contains the human-facing rules; use the
active specification and repository checks for the full process.

## AI-assisted contributions

AI-generated and AI-assisted pull requests are welcome. Two rules apply:

1. **You own the diff.** Whoever opens the pull request is accountable for
   every line, AI-written or not. “The model wrote it” is not a review
   exemption.
2. **No bot attribution.** Do not add `Co-Authored-By: <bot>` or `Generated
   with …` trailers. The contributor’s name belongs on the commit; the AI is a
   tool, not a co-author.

The same quality gate applies regardless of how the code was produced.

## Setup

Install [Mise](https://mise.jdx.dev/), then provision the pinned tools and opt-in
Git hooks:

```sh
mise trust
mise run setup
```

## Checks

Run the same repository check used by CI:

```sh
mise run check
```

The behavioral fixture invokes the real pinned `uncomment` CLI. It verifies AST
handling rather than only checking command help or exit status.

## Commit policy

Use Conventional Commits with one of these types:

```text
feat fix refactor docs test chore perf ci
```

An optional lowercase scope and breaking-change `!` are supported. Ordinary
commits require a descriptive body after a blank line, with body lines wrapped at
72 characters. Merge, Revert, `fixup!`, and `squash!` messages are exempt from the
body requirement.

For commits implementing or updating a Taskrail task, append only the task's
short key to the end of the subject as a parenthetical suffix:

```text
feat: add a focused capability (T-012)
```

Do not use the full slugged task identifier or put the task key before the
description. The commit hook validates this convention; it does not append the
suffix automatically. Commits with no Taskrail task reference may omit it.

Do not add automated attribution, co-author trailers, agent identities, or session
links to commit history. Lefthook checks the pending author at pre-commit, validates
the message at commit time, and scans outgoing history before push.

## Taskrail

Taskrail owns committed specifications and planning state:

```sh
mise run workflow:status
mise run workflow:validate
```

Use the active specification for current work. Future v1.2 work is linked
explicitly to `specs/v1.2.0.md` until that specification is activated. Modify task
status and `planning/STATE.md` through Taskrail rather than editing them by hand.

## Pull requests

Keep changes focused. Include the outcome, verification commands and decisive
results, limitations, and unresolved questions. Update documentation whenever
behavior or contributor workflow changes.
