---
id: T-002-evaluate-skills-ecosystem-installation
title: Evaluate skills ecosystem installation
status: todo
priority: medium
spec_ref: specs/v1.2.0.md#skills-ecosystem-installation
dependencies: []
updated_at: "2026-09-21T14:00:29Z"
---

# T-002-evaluate-skills-ecosystem-installation Evaluate skills ecosystem installation

## Description

Research and implement an installation path compatible with established agent-skill
tooling, including evaluation of the `npx skills` workflow. Keep one authoritative
skill definition and make only evidence-backed compatibility claims.

## Acceptance

- The chosen installer contract and repository layout are documented.
- Installation succeeds in a clean temporary environment.
- A compatible agent discovers the installed skill metadata and instructions.
- Direct use from a repository clone remains supported.

## Verification Notes

- Record the tested installer version, exact clean-environment command, installed
  path, and discovery result.

## Implementation Notes

- Proposed v1.2 work; package-manager support is not implemented in v1.0.
