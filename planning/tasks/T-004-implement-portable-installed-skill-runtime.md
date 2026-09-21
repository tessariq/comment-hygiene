---
id: T-004-implement-portable-installed-skill-runtime
title: Implement portable installed-skill runtime
status: completed
priority: high
spec_ref: specs/v1.2.0.md#portable-execution-boundary
dependencies:
    - T-002-evaluate-skills-ecosystem-installation
updated_at: "2026-09-21T17:51:06Z"
---

# T-004-implement-portable-installed-skill-runtime Implement portable installed-skill runtime

## Description

Implement the runtime boundary selected by T-002 so a skill installed into a
different repository can perform its documented AST-safe audit without relying on
this repository's root Taskfile, Mise configuration, or wrapper path. Preserve
the existing clone-root workflow and retain exactly one maintained `SKILL.md`.

## Acceptance

- Distributed skill instructions invoke an explicit, location-independent command
  or bundled executable path and state all runtime prerequisites.
- The installed-skill audit runs against a temporary fixture from a target
  repository that has no Comment Hygiene Taskfile, Mise configuration, or copied
  root wrapper.
- The distributed audit remains read-only and preserves URL-like string data and
  protected/tool-directive comments according to the existing safety contract.
- Existing root commands (`task audit`, `task audit-all`, `task strip`, and
  `task strip-all`) remain backward compatible.
- There is one authoritative `SKILL.md`; agent-specific destination paths are
  installer output, not committed, independently edited instruction copies.

## Verification Notes

- Add focused automated coverage for the installed runtime boundary. Run the
  existing repository check plus the new targeted test against a temporary target
  directory.
- Record the command resolution path and prerequisite behavior, including a clear
  failure mode if a declared external dependency is intentionally not bundled.

## Implementation Notes

- Do not begin until T-002 records the selected installer and source contract.
- The task may add scripts or supporting resources beside the canonical skill,
  but must not use an alternate agent-specific SKILL.md as a workaround.
- 2026-09-21T17:51:01Z: verification pass
- 2026-09-21T17:51:06Z: Implemented portable installed-skill runtime with verified external uncomment 3.7.0 resolution, read-only audit examples, focused temporary-target coverage, and preserved root command compatibility; verification passed after independent review and disposition fixes.
