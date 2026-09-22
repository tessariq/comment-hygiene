# Clean agent-skill installation verification

- Installer: `skills@1.7.0`
- Installer version: `1.7.0`
- Public source: `https://github.com/tessariq/comment-hygiene`
- Public source revision: `e329be0487bfd077b06334141d2c7a01bb73b1e7`
- Runtime prerequisite: `uncomment 3.7.0` (`uncomment 3.7.0`)
- Environment: isolated temporary `HOME`, XDG config/cache, Git/npm config, and allowlisted command environment per agent
- Claimed support threshold: Amp requires its executable, discovery, runtime, and cleanup plus a passing OpenCode install/cleanup cell; other cells remain unverified without a supported non-interactive discovery result.

| Agent | Installer version | Agent version | Source revision | Install | Exact install command | Installed path | Destination | Frontmatter | Discovery evidence | Runtime audit | Exact cleanup command | Cleanup | Support |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `claude-code` | `1.7.0` | `unavailable` | `e329be0487bfd077b06334141d2c7a01bb73b1e7` | pass | `npx --yes skills@1.7.0 add https://github.com/tessariq/comment-hygiene/tree/e329be0487bfd077b06334141d2c7a01bb73b1e7 --skill comment-hygiene --agent claude-code --yes` | `.claude/skills/comment-hygiene/SKILL.md` | `regular-file` | `pass` | unverified: agent executable unavailable | pass (ordinary/broad dry-runs and fixture preservation) | `npx --yes skills@1.7.0 remove comment-hygiene --agent claude-code --yes` | pass (skill path removed; skills-lock.json retained) | **unverified** |
| `codex` | `1.7.0` | `unavailable` | `e329be0487bfd077b06334141d2c7a01bb73b1e7` | pass | `npx --yes skills@1.7.0 add https://github.com/tessariq/comment-hygiene/tree/e329be0487bfd077b06334141d2c7a01bb73b1e7 --skill comment-hygiene --agent codex --yes` | `.agents/skills/comment-hygiene/SKILL.md` | `regular-file` | `pass` | unverified: agent executable unavailable | pass (ordinary/broad dry-runs and fixture preservation) | `npx --yes skills@1.7.0 remove comment-hygiene --agent codex --yes` | pass (skill path removed; skills-lock.json retained) | **unverified** |
| `opencode` | `1.7.0` | `unavailable` | `e329be0487bfd077b06334141d2c7a01bb73b1e7` | pass | `npx --yes skills@1.7.0 add https://github.com/tessariq/comment-hygiene/tree/e329be0487bfd077b06334141d2c7a01bb73b1e7 --skill comment-hygiene --agent opencode --yes` | `.agents/skills/comment-hygiene/SKILL.md` | `regular-file` | `pass` | unverified: agent executable unavailable | pass (ordinary/broad dry-runs and fixture preservation) | `npx --yes skills@1.7.0 remove comment-hygiene --agent opencode --yes` | pass (skill path removed; skills-lock.json retained) | **unverified** |
| `amp` | `1.7.0` | `0.0.1790006436-gaf5042` | `e329be0487bfd077b06334141d2c7a01bb73b1e7` | pass | `npx --yes skills@1.7.0 add https://github.com/tessariq/comment-hygiene/tree/e329be0487bfd077b06334141d2c7a01bb73b1e7 --skill comment-hygiene --agent amp --yes` | `.agents/skills/comment-hygiene/SKILL.md` | `regular-file` | `pass` | amp skills list --json: workspace-agents at .agents/skills/comment-hygiene | pass (ordinary/broad dry-runs and fixture preservation) | `npx --yes skills@1.7.0 remove comment-hygiene --agent amp --yes` | pass (skill path removed; skills-lock.json retained) | **verified** |

All temporary targets and logs are removed on exit; the report contains no temporary paths or command output.
