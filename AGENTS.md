# Guidance for coding agents

## Commit conventions

- Use Conventional Commits with one of the repository's supported types:
  `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, or `ci`.
- When a commit implements or updates a Taskrail task, append only that task's
  short key to the **end of the subject** as a parenthetical suffix, for
  example: `test: expand comment policy coverage (T-003)`.
- Never use the full slugged task identifier, and never put the task key before
  the description: `(... (T-003-expand-...))` and `feat: T-003 ...` are invalid.
- The commit hook validates this format; it does not add the suffix
  automatically. A commit with no Taskrail task reference may omit the suffix.
- Ordinary commits require a descriptive body after a blank line, with body
  lines wrapped at 72 characters. Merge, revert, fixup, and squash commits are
  exempt.

Do not add automated attribution, co-author trailers, agent identities, or
session links to commit history.
