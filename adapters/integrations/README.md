# Integrations

The integration layer maps the framework's canonical command files to the right locations and formats for each AI agent.

## How it works

```
framework/commands/org.*.md   ← canonical source (agent-agnostic prompts)
        │
        ▼
integrations/{agent}/         ← defines target location + naming + frontmatter
        │
        ▼
setup.sh / setup.ps1          ← copies files to the right place
        │
        ▼
.claude/commands/org.*.md     ← where Claude Code finds commands
.github/prompts/org.*.prompt.md  ← where Copilot finds them
.cursor/rules/org.*.mdc       ← where Cursor finds them
... etc
```

## Supported integrations

| Agent | Key | Target directory | Invocation | Confidence |
|-------|-----|-----------------|------------|------------|
| Claude Code | `claude` | `.claude/commands/` | `/org.init` | ✅ |
| GitHub Copilot | `copilot` | `.github/prompts/` | via 📎 | ✅ |
| Cursor | `cursor` | `.cursor/rules/` | `/org.init` | ✅ |
| Windsurf | `windsurf` | `.windsurf/rules/` | `/org.init` | ✅ |
| Gemini CLI | `gemini` | `.gemini/commands/` | `/org.init` | ✅ |
| Zed | `zed` | `.agents/skills/` | `/org.init` | ✅ |
| Kimi Code | `kimi` | `.kimi-code/skills/` | `/org.init` | ✅ |
| opencode | `opencode` | `.opencode/commands/` | `/org.init` | ✅ |
| Hermes | `hermes` | `~/.hermes/skills/` ⚠️ GLOBAL | `/org.init` | ✅ |
| Antigravity (agy) | `agy` | `.agy/skills/` | `/org.init` | ⚠️ best-effort |
| Generic | `generic` | `.ai/commands/` | see agent docs | ✅ |

**Hermes** installs globally (`~/.hermes/skills/`) — commands appear in all Hermes sessions, not just this project.

**agy** path is inferred from convention since documentation was unreachable. If it doesn't work, check `integrations/agy/integration.yml` for the correction path.

## Setup

```bash
# Install for Claude Code (Bash/macOS/Linux)
./setup.sh --integration claude

# Install for Claude Code (PowerShell/Windows)
.\setup.ps1 -Integration claude

# Install for multiple agents
./setup.sh --integration claude copilot cursor
```

## State management

The active organization is tracked in `.org-kit/active`.

```bash
# Set active organization
echo "luna-waves" > .org-kit/active

# Or use a command after init (done automatically by /org.init)
```

## Adding a new integration

1. Create `integrations/{key}/integration.yml`
2. Add frontmatter adapter if needed (some agents need different YAML fields)
3. Add the case to `setup.sh` and `setup.ps1`
4. Test with `./setup.sh --integration {key} --dry-run`
