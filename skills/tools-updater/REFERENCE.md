# Tools Updater Reference

## API Endpoints

### OpenSpec

| Purpose | URL |
|---------|-----|
| npm version | `npm info @fission-ai/openspec version` |
| GitHub releases | `https://api.github.com/repos/Fission-AI/OpenSpec/releases` |
| Release notes | `https://github.com/Fission-AI/OpenSpec/releases/tag/v{version}` |

## Rule Files to Update

### OpenSpec Rules

| File | When to Update |
|------|----------------|
| `~/.claude/template/rules/workflow/openspec.md` | Command changes, new options |
| `~/.claude/template/skills/openspec-*/SKILL.md` | Major version changes |

### Integration Rules

| File | When to Update |
|------|----------------|
| `~/.claude/template/rules/workflow/workflow-integration.md` | Cross-tool changes |

## Version Commands

| Tool | Command | Output Format |
|------|---------|---------------|
| OpenSpec | `openspec --version` | `openspec v1.2.3` |

## Cadence

- **Frequency**: 14 days
- **History file**: `~/.claude/.systems-check.json` (global)
- **Record command**: `~/.claude/template/scripts/systems-tracker.sh record tools-updater`
