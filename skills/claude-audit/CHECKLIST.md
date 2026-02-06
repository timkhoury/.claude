# Claude Audit Checklist

## 1. Model Version References

| Check | What to Look For |
|-------|------------------|
| Model IDs | Hardcoded model IDs (e.g., `claude-sonnet-4-5-20250929`) that may be superseded |
| Model family names | References to "Claude 4.5", "Opus 4.6" etc. that may be outdated |
| Capability claims | Statements about context window size, token limits, knowledge cutoff |
| Behavior assumptions | "Claude can/cannot do X" that may have changed |
| Agent model configs | Model selections in `.claude/agents-src/*.yaml` |

### Common Locations

- `~/.claude/CLAUDE.md` - Global model references
- `.claude/agents-src/*.yaml` - Agent model selections
- `.claude/rules/meta/agents-system.md` - Agent build system

## 2. API/SDK Changes

| Check | What to Look For |
|-------|------------------|
| Deprecated endpoints | API endpoints that have been replaced |
| New API features | Tool use improvements, streaming changes, batch API |
| SDK version | References to specific SDK versions |
| Authentication | API key format, header changes |
| Rate limits | Outdated rate limit assumptions |

### Common Locations

- `~/.claude/template/rules/tech/*.md` - Technology patterns
- `.claude/rules/project/infrastructure.md` - Infrastructure config

## 3. Claude Code Platform

| Check | What to Look For |
|-------|------------------|
| CLI commands | New or changed slash commands |
| Config format | Changes to CLAUDE.md, settings.json structure |
| Hook system | New hook types, changed hook behavior |
| MCP integration | New MCP capabilities, changed protocols |
| Permission model | Changes to allowed tools, permission settings |
| Subagent system | New agent types, changed capabilities |
| Context management | Changes to context window handling, compression |

### Common Locations

- `~/.claude/CLAUDE.md` - Global instructions
- `~/.claude/rules/git-rules.md` - Git workflow rules
- `~/.claude/template/rules/meta/*.md` - Meta rules
- `~/.claude/template/skills/*/SKILL.md` - Skill definitions

## 4. Skill/Rule Patterns

| Check | What to Look For |
|-------|------------------|
| Frontmatter format | Changes to skill/rule frontmatter schema |
| Deprecated workarounds | Workarounds for bugs that have been fixed |
| Tool references | References to tools that have been renamed or removed |
| Pattern freshness | Patterns based on old Claude Code behavior |

### Common Locations

- `~/.claude/template/skills/*/SKILL.md` - All skills
- `~/.claude/template/rules/workflow/*.md` - Workflow rules

## 5. Documentation Accuracy

| Check | What to Look For |
|-------|------------------|
| External links | URLs to docs that may have moved |
| Feature descriptions | Descriptions that may not match current behavior |
| Command examples | CLI examples that may use old syntax |
| Setup instructions | Installation/setup steps that may have changed |

### Common Locations

- `CLAUDE.md` files at all levels
- `docs/` directories
- `README.md` files
