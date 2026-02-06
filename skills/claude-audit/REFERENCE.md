# Claude Audit Reference

## Documentation URLs

### Model Information

| Purpose | URL |
|---------|-----|
| Model overview | `https://docs.anthropic.com/en/docs/about-claude/models` |
| API reference | `https://docs.anthropic.com/en/api/getting-started` |
| Anthropic blog | `https://www.anthropic.com/news` |

### Claude Code

| Purpose | URL |
|---------|-----|
| Claude Code changelog | `https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md` |
| Claude Code releases | `https://github.com/anthropics/claude-code/releases` |
| Claude Code docs | `https://docs.anthropic.com/en/docs/claude-code` |

### SDK

| Purpose | URL |
|---------|-----|
| TypeScript SDK | `https://github.com/anthropics/anthropic-sdk-typescript/releases` |
| Python SDK | `https://github.com/anthropics/anthropic-sdk-python/releases` |

## Files to Audit

### Global Configuration

| File | What to Check |
|------|---------------|
| `~/.claude/CLAUDE.md` | Model references, capability claims, feature mentions |
| `~/.claude/rules/*.md` | Git rules, global patterns |

### Template Files

| File | What to Check |
|------|---------------|
| `~/.claude/template/rules/tech/*.md` | Framework-specific patterns |
| `~/.claude/template/rules/patterns/*.md` | Cross-cutting patterns |
| `~/.claude/template/rules/workflow/*.md` | Workflow references |
| `~/.claude/template/rules/meta/*.md` | Meta rules, agent system |
| `~/.claude/template/skills/*/SKILL.md` | Skill definitions |

### Project Files

| File | What to Check |
|------|---------------|
| `.claude/rules/project/*.md` | Project-specific references |
| `.claude/agents-src/*.yaml` | Agent model references |
| `.claude/agents/*.md` | Generated agent definitions |
| `CLAUDE.md` | Project instructions |

## Grep Patterns

### Model References

```bash
# Model IDs (current and potentially outdated)
grep -rn "claude-\(opus\|sonnet\|haiku\)-[0-9]" --include="*.md" --include="*.yaml"

# Model family names
grep -rn "Claude [0-9]\.\|Opus [0-9]\.\|Sonnet [0-9]\.\|Haiku [0-9]\." --include="*.md"

# Model capability assumptions
grep -rn "200k context\|context window\|token limit\|knowledge cutoff" --include="*.md"
```

### Claude Code Features

```bash
# Hook references
grep -rn "PreToolUse\|PostToolUse\|hook\|allowedTools" --include="*.md" --include="*.json"

# Config format
grep -rn "settings\.json\|settings\.local\|CLAUDE\.md" --include="*.md"

# CLI features
grep -rn "slash command\|MCP\|tool_use\|subagent" --include="*.md"
```

### Deprecated Patterns

```bash
# Old model IDs
grep -rn "claude-3\|claude-2\|claude-instant" --include="*.md" --include="*.yaml"

# Potentially deprecated features
grep -rn "\.clauderc\|claude\.json\|ANTHROPIC_API_KEY" --include="*.md"
```

## Systems Tracker Integration

- **Cadence**: 30 days
- **Scope**: Global
- **History file**: `~/.claude/.systems-check.json`
- **Record command**: `~/.claude/template/scripts/systems-tracker.sh record claude-audit`
