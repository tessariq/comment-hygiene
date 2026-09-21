---
id: T-003-expand-behavioral-coverage
title: Expand behavioral coverage
status: completed
priority: medium
spec_ref: specs/v1.2.0.md#expanded-behavioral-coverage
dependencies: []
updated_at: "2026-09-21T18:14:18Z"
---

# T-003-expand-behavioral-coverage Expand behavioral coverage

## Description

Add separate fixtures for broad comment removal and protected comments so changes
to one policy produce focused failures without obscuring ordinary-comment behavior.

## Acceptance

- Audits are proven read-only in ordinary and broad modes.
- Broad stripping covers docs, TODOs, and FIXMEs.
- URL-like strings, recognized directives, and `~keep` comments remain intact.
- Existing ordinary-mode assertions continue to pass.

## Verification Notes

- Run the public Task targets against temporary fixture copies through the pinned
  `uncomment` binary.

## Implementation Notes

- Proposed v1.2 work migrated from the former optional coverage notes.
- 2026-09-21T18:14:18Z: verification pass
- 2026-09-21T18:14:18Z: Expanded behavioral coverage with separate broad/protected fixtures, read-only audit checks, exact strip expectations, and preserved string/directive/~keep safety behavior.
