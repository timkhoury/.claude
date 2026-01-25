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

### Deciding Where Rules Go

```
Is this rule project-specific?
│
├─ YES (specific to this codebase's architecture)
│  └─ rules/project/* ONLY
│     Examples: database schema separation, env vars, project URLs
│
└─ NO (reusable across projects)
   │
   ├─ Technology pattern?
   │  └─ rules/tech/{tech}.md
   │
   ├─ Cross-cutting pattern?
   │  └─ rules/patterns/{pattern}.md
   │
   ├─ Workflow process?
   │  └─ rules/workflow/{workflow}.md
   │
   └─ Claude Code configuration?
      └─ rules/meta/{topic}.md
```

**Key question:** Would this rule make sense in a different project using the same technology? If no → `project/`.

### Tech Rules

**One technology per file.** Cross-technology patterns belong in integration files.

| Pattern | Example |
|---------|---------|
| Pure technology | `nextjs.md`, `supabase.md` |
| Integration | `nextjs-supabase.md`, `tailwind-shadcn.md` |

### Testing Rules (`tech/testing/`)

Testing-related rules live in `tech/testing/`. Naming depends on whether the technology is a testing framework:

| Technology Type | Naming | Example |
|-----------------|--------|---------|
| Testing framework | Use framework name | `vitest.md`, `playwright.md` |
| Non-testing tech with testing patterns | Add `-testing` suffix | `supabase-testing.md` |

**Why the suffix?** It distinguishes testing patterns for a technology from its general usage patterns. `supabase.md` covers clients, RLS, and queries; `supabase-testing.md` covers test cleanup and fixtures.

## Skills Directory

**IMPORTANT:** Skills must be directly in `.claude/skills/` - subdirectories are not supported.

```
.claude/skills/
├── adr-writer/           # Authoring - ADR creation
├── agent-writer/         # Authoring - Agent definitions
├── skill-writer/         # Authoring - Skill creation
├── pr-check/             # Quality - Pre-PR validation
├── quality-audit/        # Quality - Combined spec/test audit
├── rules-review/         # Quality - Rules organization
├── spec-quality/         # Quality - OpenSpec structure
├── work/                 # Workflow - Task execution
├── beads-cleanup/        # Workflow - Issue cleanup
├── agent-browser/        # Automation - Browser testing
└── supabase-advisors/    # Project-specific (NEVER synced)
```

### Skills Conventions

**Naming for organization:**
- Descriptive names indicate purpose (`adr-writer`, `pr-check`, `spec-quality`)
- Prefix only when needed for clarity (`quality-audit` not just `audit`)
- Project-specific skills stay in project, detected by sync tools

**Syncing:**
- Template skills sync bidirectionally between `~/.claude/template/skills/` and `.claude/skills/`
- Project-specific skills (like `supabase-advisors`) never sync to template
- Detection is automatic - if skill exists in template, it syncs; if not, it stays local

## Template Sync Rules

**From project to template (`template-updater`):**
- Syncs `rules/tech/`, `rules/patterns/`, `rules/workflow/`, `rules/meta/`
- Syncs skills that exist in both template and project
- **Never syncs** `rules/project/` or project-only skills

**From template to project (`project-sync`):**
- Updates template skills that exist in project
- Adds new template skills
- **Never overwrites** `rules/project/` or project-only skills

## Adding New Content

| Content Type | Location |
|--------------|----------|
| Technology pattern (reusable) | `rules/tech/{tech}.md` |
| Integration pattern | `rules/tech/{tech-a}-{tech-b}.md` |
| Project-specific rule | `rules/project/{name}.md` |
| Reusable skill | `skills/{skill-name}/SKILL.md` |
| Project-specific skill | `skills/{skill-name}/SKILL.md` (not in template) |

**Skill naming guidelines:**
- Use descriptive names that indicate purpose
- Add prefixes only when needed for clarity (e.g., `quality-audit` not `audit`)
- Project-only skills naturally stay separate through sync detection
