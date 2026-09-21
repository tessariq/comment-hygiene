---
id: T-005-verify-clean-agent-skill-installations
title: Verify clean agent-skill installations
status: blocked
priority: high
spec_ref: specs/v1.2.0.md#clean-environment-verification
dependencies:
    - T-004-implement-portable-installed-skill-runtime
updated_at: "2026-09-21T17:55:58Z"
---

# T-005-verify-clean-agent-skill-installations Verify clean agent-skill installations

## Description

Create reproducible clean-environment verification for the installer contract and
portable runtime from T-002 and T-004. Exercise each of Claude Code, Codex, Amp,
and OpenCode that will be documented as supported; distinguish a verified
discovery result from a filesystem-only installation result.

## Acceptance

- The test uses an isolated temporary HOME and an empty target Git repository, and
  does not read or write a developer's existing agent configuration.
- For every agent claimed supported, the test records the installer version,
  public source revision, exact command, installed path, destination type, and
  agent discovery evidence.
- Each claimed target successfully performs the installed skill's read-only audit
  against a fixture; the fixture is byte-for-byte unchanged afterward.
- A missing agent executable or unsupported discovery mechanism fails the claimed
  support cell clearly rather than producing a false pass.
- Test artifacts are deterministic, scrubbed of sensitive paths and credentials,
  and suitable for CI or a documented manual verification procedure.

## Verification Notes

- Start from the public source rather than the current working tree so the test
  proves the distribution path users receive.
- Capture tool and agent versions with the exact discovery command or UI-equivalent
  CLI output used as evidence. Test cleanup in both success and failure paths.

## Implementation Notes

- This task depends on the runtime boundary in T-004; it must not silently invoke
  the source repository's root Taskfile to make an installed skill appear to work.
- If a required agent cannot run non-interactively, provide a bounded manual
  verification recipe and leave its support status unverified until performed.
- 2026-09-21T17:55:58Z: Blocked pending publication of T-004: clean install from public main resolves revision 2ab968c, whose installed SKILL.md lacks the portable runtime. Local T-004 commit 2c4c4a9 is unpushed; pushing requires explicit authorization.
