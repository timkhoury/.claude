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
│     Examples: architecture, infrastructure, testing config
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

**Agent configuration:** The `tech/testing/` folder is configured as a separate include (`$includes.testing`) in `_template.yaml`, not auto-discovered under `$includes.tech`. This allows the `testing` bundle to include only testing-related rules while other bundles get the full `tech/` folder.

## Rules vs Skills

| Use | When |
|-----|------|
| **Rule** | Always-needed context (patterns, conventions, architecture) |
| **Skill** | On-demand workflows (setup, sync, troubleshooting) |

**Quick test:** Is this needed for most coding tasks? → Rule. Is this a workflow triggered occasionally? → Skill.

Use `/rules-review` for detailed analysis of rule vs skill decisions.

## Skills Directory

**Template** (categorized for organization):

```
~/.claude/template/skills/
├── authoring/            # Content creation skills
│   ├── adr-writer/
│   ├── agent-writer/
│   └── skill-writer/
├── quality/              # Code and spec quality
│   ├── pr-check/
│   ├── quality-audit/
│   ├── rules-review/
│   ├── skills-review/
│   ├── spec-coverage/
│   ├── spec-quality/
│   └── test-quality/
├── workflow/             # Task and issue management
│   ├── beads-cleanup/
│   └── work/
├── automation/           # Automated processes
│   ├── agent-browser/
│   └── deps-updater/
├── meta/                 # Claude Code configuration
│   └── settings-updater/
└── tech/                 # Technology-specific (conditional)
    └── supabase-advisors/
```

**Project** (flat - categories are stripped on sync):

```
.claude/skills/
├── adr-writer/           # From authoring/
├── pr-check/             # From quality/
├── work/                 # From workflow/
├── agent-browser/        # From automation/
├── settings-updater/     # From meta/
├── supabase-advisors/    # From tech/ (if detected)
└── my-project-skill/     # Project-specific (never synced)
```

### Skills Conventions

**Naming for organization:**
- Descriptive names indicate purpose (`adr-writer`, `pr-check`, `spec-quality`)
- Prefix only when needed for clarity (`quality-audit` not just `audit`)
- Project-specific skills stay in project, detected by sync tools

**Template organization:**
- Template uses categories: `authoring/`, `quality/`, `workflow/`, `automation/`, `meta/`, `tech/`
- Categories are flattened when syncing to projects (e.g., `quality/rules-review/` → `rules-review/`)
- `tech/` skills are conditional - only synced when technology is detected

**Syncing:**
- Template skills sync bidirectionally between `~/.claude/template/skills/` and `.claude/skills/`
- Categories are flattened to project, unflattened when syncing back to template
- Tech-specific skills sync only when technology is detected
- Project-specific skills never sync to template
- Detection is automatic based on sync-config.yaml

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

| Content Type | Template Location | Project Location |
|--------------|-------------------|------------------|
| Technology pattern (reusable) | `rules/tech/{tech}.md` | Same |
| Integration pattern | `rules/tech/{tech-a}-{tech-b}.md` | Same |
| Project-specific rule | N/A | `rules/project/{name}.md` |
| Authoring skill | `skills/authoring/{name}/` | `skills/{name}/` |
| Quality skill | `skills/quality/{name}/` | `skills/{name}/` |
| Workflow skill | `skills/workflow/{name}/` | `skills/{name}/` |
| Automation skill | `skills/automation/{name}/` | `skills/{name}/` |
| Meta skill | `skills/meta/{name}/` | `skills/{name}/` |
| Tech-specific skill | `skills/tech/{name}/` | `skills/{name}/` (if detected) |
| Project-specific skill | N/A | `skills/{name}/` |

**Skill category guidelines:**
- `authoring/` - Content creation (ADRs, agents, skills, documentation)
- `quality/` - Code review, spec validation, testing patterns
- `workflow/` - Task management, issue tracking, process automation
- `automation/` - Browser testing, dependency updates, background processes
- `meta/` - Claude Code configuration and settings
- `tech/` - Technology-specific skills (conditional sync based on detection)

**Skill naming guidelines:**
- Use descriptive names that indicate purpose
- Add prefixes only when needed for clarity (e.g., `quality-audit` not `audit`)
- Categories are stripped when syncing to projects
- Project-only skills naturally stay separate through sync detection
