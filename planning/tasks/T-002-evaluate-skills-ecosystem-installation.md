---
id: T-002-evaluate-skills-ecosystem-installation
title: Evaluate skills ecosystem installation
status: completed
priority: medium
spec_ref: specs/v1.2.0.md#installer-and-discovery-contract
dependencies: []
updated_at: "2026-09-21T16:59:05Z"
---

# T-002-evaluate-skills-ecosystem-installation Evaluate skills ecosystem installation

## Description

Establish the distribution decision before implementation. Evaluate the current
`npx skills` workflow against the canonical source layout and consult primary
Claude Code, Codex, Amp, and OpenCode skill-discovery documentation. Separate
source-layout recognition, installer target placement, and actual agent discovery
in the resulting support matrix.

## Acceptance

- The exact `npx skills` version and source-enumeration command are recorded.
- The evaluation records project and user install locations, copy/symlink behavior,
  and update/removal semantics for each candidate agent target.
- The support matrix has a primary-source locator and an observed result for every
  Claude Code, Codex, Amp, and OpenCode claim; unavailable local agents are marked
  unverified, not assumed compatible.
- The selected installation contract keeps `skills/comment-hygiene/SKILL.md` as
  the sole maintained instruction source, or records the evidence requiring a
  layout change.
- A concise decision record identifies the runtime-boundary work delegated to
  T-004 and the clean-environment evidence delegated to T-005.

## Verification Notes

- Use a non-writing source-enumeration command first, then inspect the selected
  installer's documented target paths without modifying a user-level skill path.
- Preserve command output, source URLs and access dates, tool versions, and any
  qualification that prevents a compatibility claim.

## Implementation Notes

- This task decides the contract; it does not claim clean installation or a
  functional distributed runtime. Those are T-005 and T-004 respectively.
- 2026-09-21T16:58:48Z: verification pass
- 2026-09-21T16:59:05Z: Decision record committed with skills@1.7.0 source contract, paths, copy/symlink and update/removal observations, primary docs, Amp discovery evidence, explicit unverified cells, and T-004/T-005 boundaries.
