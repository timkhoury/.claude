---
name: systems-check
description: >
  Show aggregate status of maintenance tasks with cadence-based recommendations.
  Tracks execution history per-repo. Use when checking which tasks are due
  or selecting one to run.
---

# Systems Check

Aggregate dashboard for maintenance tasks with cadence-based recommendations.

## Tracked Tasks

| Task | Cadence | Scope | Purpose |
|------|---------|-------|---------|
| template-review | 7 days | Global | Template structure and sync-config integrity |
| sync | 7 days | Project | Bidirectional template/project config sync |
| rules-review | 7 days | Project | Rule organization and separation of concerns |
| skills-review | 7 days | Project | Skill context efficiency |
| permissions-review | 7 days | Project | Permission promotion to global settings |
| spec-review | 14 days | Project | OpenSpec implementation and test coverage |
| tools-updater | 14 days | Global | Check for OpenSpec updates |
| deps-updater | 14 days | Project | Dependency updates and security audit |
| memory-review | 14 days | Project | Prune redundant auto-memory entries |
| claude-audit | 30 days | Global | Audit Claude Code config against platform changes |

## Workflow

### Step 1: Check Status

```bash
~/.claude/template/scripts/systems-tracker.sh status
```

Shows all applicable tasks with days since last run and overdue status.

### Step 2: Get Recommendations

```bash
~/.claude/template/scripts/systems-tracker.sh recommend
```

Lists tasks that are due, sorted by priority (never-run first, then most overdue).

### Step 3: Present Options

Display a summary table:

```markdown
## Systems Status

| Task | Scope | Description | Last Run | Status |
|------|-------|-------------|----------|--------|
| template-review | Global | Template structure and sync-config integrity | 10 days | Due (3 days overdue) |
| sync | Project | Bidirectional template/project config sync | 8 days | Due (1 day overdue) |
| rules-review | Project | Rule organization and separation of concerns | 5 days | OK (2 days remaining) |
| spec-review | Project | OpenSpec implementation and test coverage | 20 days | Due (6 days overdue) |
```

### Step 4: Ask User Selection

Use `AskUserQuestion` with single-select:

- Show top 3-4 recommended tasks as options (most overdue first)
- Include "Skip" option to exit without running any
- Single selection only - run one task at a time

### Step 5: Execute Selected Task

Invoke the selected task using the `Skill` tool:

```
Skill: sync
```

The individual skill will automatically record its completion via `systems-tracker.sh record <name>`.

### Step 6: Offer Next Task (if applicable)

If more tasks are due after completion, ask if the user wants to run another. Otherwise, show summary and exit.

## Commands

```bash
# Show status of all tasks
~/.claude/template/scripts/systems-tracker.sh status

# JSON output for parsing
~/.claude/template/scripts/systems-tracker.sh status json

# Get recommendations (sorted by priority)
~/.claude/template/scripts/systems-tracker.sh recommend

# Record a task completion (called by individual skills)
~/.claude/template/scripts/systems-tracker.sh record <name>

# Initialize history files
~/.claude/template/scripts/systems-tracker.sh init
```

## History Files

| Scope | File | Tasks Tracked |
|-------|------|---------------|
| Global | `~/.claude/.systems-check.json` | template-review, tools-updater, claude-audit |
| Project | `./.systems-check.json` | sync, rules-review, skills-review, permissions-review, spec-review, deps-updater, memory-review |

Both files are gitignored. The script automatically routes to the correct file.

## Conditional Inclusion

Tasks are only shown if applicable:

- `template-review`: Always included
- `tools-updater`: Always included
- `sync`: Only if `.claude/` exists
- `rules-review`: Only if `.claude/rules/` exists
- `skills-review`: Only if `.claude/skills/` exists
- `permissions-review`: Only if `.claude/settings.local.json` exists
- `spec-review`: Only if `.openspec/` or `specs/` exists
- `deps-updater`: Only if `package.json`, `Cargo.toml`, `go.mod`, or similar exists
- `memory-review`: Always included
- `claude-audit`: Always included
