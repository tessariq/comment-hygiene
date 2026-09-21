---
id: T-006-document-verified-agent-support
title: Document verified agent support
status: todo
priority: medium
spec_ref: specs/v1.2.0.md#support-documentation
dependencies:
    - T-005-verify-clean-agent-skill-installations
updated_at: "2026-09-21T16:10:17Z"
---

# T-006-document-verified-agent-support Document verified agent support

## Description

Publish user-facing installation and support documentation using only the evidence
captured in T-002 and T-005. Cover direct clone use and the selected distributed
runtime without asking users to copy skill instructions into agent-specific files.

## Acceptance

- README documentation gives exact project-local and user-local installation,
  update, and removal commands for every verified agent target.
- A support matrix names tested agent and installer versions, source scope, and
  discovery evidence; unsupported or unverified cells are explicit.
- Documentation explains whether installer destinations are symlinks or copies,
  identifies the canonical source, and warns users not to edit generated copies.
- The runtime prerequisite and a minimal installed-skill audit example are
  documented separately from the existing direct-clone workflow.
- Existing v1.0 usage and safety claims remain accurate, and documentation makes
  no universal `SKILL.md` compatibility claim.

## Verification Notes

- Cross-check every command and compatibility statement against the recorded
  T-002 decision and T-005 evidence. Run commands in a clean target where
  practical and link any manual verification record.

## Implementation Notes

- Do not document a target as supported merely because its expected directory is
  known. The required threshold is the corresponding discovery and runtime result
  from T-005.
