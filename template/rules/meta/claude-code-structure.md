# Claude Code Directory Structure

> Convention for organizing `.claude/` configuration.

## Rules Directory

```
.claude/rules/
├── tech/           # Technology-specific patterns (ONE tech per file)
├── patterns/       # Cross-cutting patterns (data retention, component org)
├── workflow/       # Workflow rules (beads, openspec, session management)
├── meta/           # Meta rules about Claude Code itself
└── project/        # Project-specific rules (NEVER synced to template)
```

### Rules Conventions

| Directory | Content | Synced to Template |
|-----------|---------|-------------------|
| `tech/` | Single-technology patterns | Yes |
| `patterns/` | Reusable patterns | Yes |
| `workflow/` | Workflow processes | Yes |
| `meta/` | Claude Code configuration | Yes |
| `project/` | Project-specific content | **No** |

### Tech Rules

**One technology per file.** Cross-technology patterns belong in integration files.

| Pattern | Example |
|---------|---------|
| Pure technology | `nextjs.md`, `supabase.md` |
| Integration | `nextjs-supabase.md`, `tailwind-shadcn.md` |

## Skills Directory

```
.claude/skills/
├── authoring/      # Creating things (adr-writer, agent-writer, skill-writer)
├── quality/        # Review/audit (pr-check, rules-review, spec-quality)
├── workflow/       # Work execution (beads-cleanup, work)
├── automation/     # Automated tasks (agent-browser)
└── project/        # Project-specific skills (NEVER synced to template)
```

### Skills Conventions

| Directory | Content | Synced to Template |
|-----------|---------|-------------------|
| `authoring/` | Skills for creating artifacts | Yes |
| `quality/` | Review, audit, quality checks | Yes |
| `workflow/` | Work execution, session management | Yes |
| `automation/` | Browser, external tools | Yes |
| `project/` | Project-specific tools | **No** |

## Template Sync Rules

**From project to template (`template-updater`):**
- Syncs `rules/tech/`, `rules/patterns/`, `rules/workflow/`, `rules/meta/`
- Syncs `skills/authoring/`, `skills/quality/`, `skills/workflow/`, `skills/automation/`
- **Never syncs** `*/project/` directories

**From template to project (`project-sync`):**
- Updates all template-worthy directories
- **Never overwrites** `*/project/` directories

## Adding New Content

| Content Type | Location |
|--------------|----------|
| Technology pattern (reusable) | `rules/tech/{tech}.md` |
| Integration pattern | `rules/tech/{tech-a}-{tech-b}.md` |
| Project-specific rule | `rules/project/{name}.md` |
| Reusable skill | `skills/{category}/{skill-name}/SKILL.md` |
| Project-specific skill | `skills/project/{skill-name}/SKILL.md` |
