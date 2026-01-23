# Agents System

This project uses a deterministic agent build system. Agent definitions in `.claude/agents-src/` generate markdown files in `.claude/agents/`.

## File Structure

```
.claude/
├── agents-src/           # Source definitions (edit these)
│   ├── _shared.yaml      # Shared includes, bundles, skill sets
│   └── *.yaml            # Individual agent definitions
├── agents/               # Generated output (do not edit)
│   └── *.md              # Built from agents-src/
└── scripts/
    └── build-agents.ts   # Build script
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
- `supabase-testing.md` → `$includes.tech.supabaseTesting`
- `tanstack-query.md` → `$includes.tech.tanstackQuery`

## When Modifying Rules

**If you add a new rule file:**
- Files in existing folders are auto-discovered on next build
- Just run `npm run build:agents` to include them

**If you add a new folder:**

```yaml
# _shared.yaml
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

## Keeping Bundles Current

When rules change significantly:
- Review which bundles should include/exclude the rule
- Consider if subagents need the rule baked in or can rely on main context
- Template rules (from `~/.claude/template/`) sync automatically but still need bundle updates
