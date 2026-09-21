# Optional coverage follow-ups

These are non-blocking follow-ups from the review of the comment-hygiene
prototype. They record useful regression coverage without changing the current
workflow or its acceptance criteria.

## Expand the behavioral fixture

Add representative cases for the public Task targets and assert that:

- `audit-all` previews documentation, TODO, and FIXME comments without changing
  the file.
- `strip-all` removes those additional categories after the intended apply step.
- URL-like text inside strings remains unchanged in both modes.
- Recognized linting or formatter directives remain intact.
- Standalone and trailing comments protected with `~keep` remain intact.

Keep the broad-mode cases separate from the ordinary-comment fixture so the test
identifies which removal policy changed if a future `uncomment` upgrade changes
its defaults.

## Suggested assertions

1. Copy the fixture and compare its checksum before and after `audit` and
   `audit-all`.
2. Assert that each audit output names the expected removable categories.
3. Apply `strip` and `strip-all` to separate copies through the Taskfile, then
   inspect the resulting text.
4. Assert that protected comments and string data remain while the selected
   ordinary or broad-mode comments are removed.
5. Run `mise run check` after adding the cases so the project check exercises the
   public targets as well as the wrapper.
