---
id: T-001-retrofit-the-standalone-v1-0-release
title: Retrofit the standalone v1.0 release
status: completed
priority: high
spec_ref: specs/v1.0.0.md#acceptance-criteria
dependencies: []
updated_at: "2026-09-21T14:16:25Z"
---

# T-001-retrofit-the-standalone-v1-0-release Retrofit the standalone v1.0 release

## Description

Extract the existing Comment Hygiene implementation into a standalone repository
while retaining its focused development history. Retrofit the shipped behavior as
the v1.0 specification, add a human-facing project README, and adopt Taskrail,
Taskrail-style Lefthook policy, and standalone CI.

## Acceptance

- The v1.0 specification matches the observable command and skill behavior.
- The original project commits remain reachable, with prohibited session metadata
  removed from commit messages before publication.
- README setup and usage commands work from the standalone repository root.
- The pinned project check and Taskrail validation pass.
- No public file or commit message names the source repository.

## Verification Notes

- Run `mise run check` after installing the pinned tools.
- Run a direct no-apply strip probe and compare the fixture before and after.
- Inspect all reachable commit messages and tracked files for forbidden source
  names and session metadata before the first push.

## Implementation Notes

- Retrospective record: the AST-safe wrapper, fixture, and skill predate Taskrail
  adoption. Verification recorded here applies to the extracted current state.
- The future package-manager skill installation idea belongs to v1.2, not v1.0.
- 2026-09-21T14:16:25Z: verification pass
- 2026-09-21T14:16:25Z: Retrospective v1.0 behavior and standalone repository workflow are implemented and reviewed.
