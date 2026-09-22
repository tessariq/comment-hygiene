# Verification Plan

- Task: `T-005-verify-clean-agent-skill-installations`
- Title: Verify clean agent-skill installations
- Requested result: pass
- Summary: Public skills@1.7.0 installs verified from an immutable source revision; Amp discovery and installed runtime passed, other agent cells remain explicitly unverified.
- Details: Implemented scripts/test-clean-install.sh and Taskfile test:clean-install. The harness uses temporary HOME/XDG/npm/Git configuration and an allowlisted environment, resolves the canonical public main revision once, installs from the immutable GitHub tree URL, records exact commands/paths/destination/discovery/runtime/cleanup evidence, validates leading frontmatter, runs ordinary and broad read-only fixture audits with preservation checks, always attempts cleanup, and gates Amp support on the OpenCode cell. Committed evidence: planning/artifacts/verification/T-005-verify-clean-agent-skill-installations/report.md. Normal and simulated failure regressions passed; repository checks, syntax, diff, and TaskRail validation passed. Independent General and Security review findings were fixed and disposition verification found no new task-relevant issues.
