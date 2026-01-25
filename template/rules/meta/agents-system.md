# Agents System

This project uses a deterministic agent build system. Agent definitions in `.claude/agents-src/` generate markdown files in `.claude/agents/`.

## File Structure

```
.claude/
├── agents-src/           # Source definitions (edit these)
│   ├── _template.yaml    # Template-controlled (syncs from ~/.claude/template/)
│   ├── _project.yaml     # Project-specific (never syncs)
│   └── *.yaml            # Individual agent definitions
├── agents/               # Generated output (do not edit)
│   └── *.md              # Built from agents-src/
└── scripts/
    └── build-agents.ts   # Build script
```

## Template vs Project Configuration

The configuration is split into two files with clear ownership:

| File | Ownership | Contains | Syncs |
|------|-----------|----------|-------|
| `_template.yaml` | Template | defaults, skillSets, toolSets, includes, colors, base ruleBundles | Yes |
| `_project.yaml` | Project | Project-specific rules added to bundles | No |

### Project Rules Auto-Discovery

Project rules in `rules/project/*.md` are **automatically discovered** and assigned to bundles based on frontmatter:

```markdown
---
bundles: all                    # All bundles (implementation, review, planning, testing)
bundles: [review]               # Specific bundles only
---
# (no frontmatter)              # Default: [implementation, review, planning]
```

**Convention:**
- Most rules need no frontmatter (default covers common case)
- Use `bundles: all` for rules every agent needs (overview, testing)
- Use `bundles: [specific]` for agent-specific rules (code-review checklist)

### Merge Strategy

Build order: explicit `_project.yaml` → auto-discovered → template rules

```yaml
# _project.yaml (explicit overrides - optional)
ruleBundles:
  implementation:
    - $includes.project.specialRule    # First (if specified)

# Auto-discovered from frontmatter     # Second
# Template rules                        # Last
```

### Customization Examples

**Most projects need no `_project.yaml`** - frontmatter handles bundle assignment.

**Override when needed:**
```yaml
# _project.yaml - only for edge cases
ruleBundles:
  implementation:
    - $includes.project.specialRule    # Prepend specific rule
```

**Add project-specific skillSets:**
```yaml
# _project.yaml
skillSets:
  customTools:
    - my-custom-skill
```

## Folder-Based Includes

The build system supports folder-based includes for automatic rule discovery.

**Folder includes** (trailing `/` indicates folder):
```yaml
includes:
  tech: "@/.claude/rules/tech/"       # All .md files in folder
  patterns: "@/.claude/rules/patterns/"
```

**Using in bundles:**
```yaml
ruleBundles:
  implementation:
    - $includes.tech                   # All files from tech/
    - $includes.patterns               # All files from patterns/
    - $includes.project.overview       # Specific file from project/
```

**File naming convention:** kebab-case files map to camelCase keys:
- `supabase-testing.md` -> `$includes.tech.supabaseTesting`
- `tanstack-query.md` -> `$includes.tech.tanstackQuery`
- `nextjs-tanstack-query.md` -> `$includes.tech.nextjsTanstackQuery`

## When Modifying Rules

**If you add a new rule file:**
- Files in existing folders are auto-discovered on next build
- Just run `npm run build:agents` to include them

**If you add a new folder:**

```yaml
# _template.yaml (if template-level)
includes:
  newFolder: "@/.claude/rules/new-folder/"

ruleBundles:
  implementation:
    - $includes.newFolder  # All rules from folder
```

## When Modifying Agents

**If you change an agent definition:**

1. Edit the YAML in `.claude/agents-src/`
2. Run `npm run build:agents`
3. Commit both the YAML source and generated `.md` file

**Never edit `.claude/agents/*.md` directly** - changes will be overwritten on next build.

## Build Command

```bash
npm run build:agents    # Regenerate all agents from YAML
```

## Rule Bundles

| Bundle | Purpose | Used By |
|--------|---------|---------|
| `implementation` | Full rules for coding tasks | task-implementer |
| `review` | Rules for code review | code-reviewer |
| `planning` | Architecture-focused rules | planner-researcher |
| `testing` | Minimal testing rules | tester |

## Sync Behavior

| Action | `_template.yaml` | `_project.yaml` |
|--------|------------------|-----------------|
| `/project-sync` | Updated from template | Protected (copied if missing) |
| `/template-updater` | Synced to template | Never synced |
| `/project-setup` | Copied from template | Copied as starter |

## Keeping Bundles Current

When rules change significantly:
- Review which bundles should include/exclude the rule
- Template rules go in `_template.yaml`, project rules in `_project.yaml`
- Consider if subagents need the rule baked in or can rely on main context
