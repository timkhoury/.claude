---
name: claude-audit
description: >
  Audit Claude Code configuration against latest platform changes, model updates,
  and feature releases. Use when "claude audit", "what's new", "model version",
  "platform updates", or "check claude changes".
---

# Claude Audit

Audit Claude Code configuration files against the latest platform changes, model updates, and feature releases.

## Critical Rules

1. **Research before reporting** - Always fetch latest info via WebSearch/WebFetch
2. **Categorize findings** - Breaking > Outdated > Opportunity > Info
3. **Present before applying** - Never auto-modify configuration files
4. **Record completion** - Always record via systems-tracker when done

**See `REFERENCE.md` for documentation URLs and files to audit.**
**See `CHECKLIST.md` for the full audit checklist.**

## Usage

```bash
/claude-audit              # Full audit workflow
/claude-audit models       # Model references only
/claude-audit platform     # Claude Code platform changes only
```

## Workflow

### Phase 1: Detect Current State

Scan configuration files for model references and Claude Code feature usage:

```bash
# Find model references across all config
grep -r "claude\|opus\|sonnet\|haiku" ~/.claude/CLAUDE.md ~/.claude/template/ ~/.claude/rules/ --include="*.md" --include="*.yaml" -l 2>/dev/null
```

Note the current model IDs, version references, and feature assumptions.

### Phase 2: Research Latest Changes

Use `WebSearch` and `WebFetch` to check:

1. **Model updates** - Latest model IDs, capabilities, deprecations
2. **Claude Code releases** - New CLI features, config format changes, hook updates
3. **API changes** - New parameters, deprecated endpoints, SDK updates

Sources to check (see `REFERENCE.md` for URLs):
- Anthropic changelog / blog
- Claude Code GitHub releases
- Claude API documentation

### Phase 3: Scan Configuration

Audit all configuration files against `CHECKLIST.md`:

| Scope | Files |
|-------|-------|
| Global | `~/.claude/CLAUDE.md`, `~/.claude/rules/` |
| Template | `~/.claude/template/rules/`, `~/.claude/template/skills/` |
| Project | `.claude/rules/`, `.claude/agents-src/` |
| Agents | `.claude/agents-src/*.yaml` |

### Phase 4: Report Findings

Present findings grouped by category:

| Category | Meaning | Action Required |
|----------|---------|-----------------|
| Breaking | Must fix - uses removed/deprecated features | Immediate |
| Outdated | Should fix - references old models/features | Soon |
| Opportunity | Could adopt - new features available | Optional |
| Info | No action - awareness only | None |

Format as a table with file, line, finding, and category.

Use `AskUserQuestion` to let user select which findings to address:
- Fix all Breaking + Outdated
- Fix Breaking only
- Review individually
- Skip (info only)

### Phase 5: Apply Approved Changes

For each approved fix:

1. Read the target file
2. Show the proposed change (old vs new)
3. Apply via Edit tool
4. If template files changed, suggest running `/sync`

## After Completion

Record this audit:

```bash
~/.claude/template/scripts/systems-tracker.sh record claude-audit
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Auto-apply changes without confirmation | Config breaks silently |
| Trust training data for current model IDs | May reference deprecated models |
| Skip WebSearch verification | Report stale information |
| Modify project files without sync | Template/project drift |
