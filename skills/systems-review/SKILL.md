---
name: systems-review
description: >
  Aggregate review skill showing status of all reviews, recommendations based
  on cadence, and interactive selection. Tracks execution history per-repo.
---

# Systems Review

Aggregate dashboard for all review skills with cadence-based recommendations.

## Review Types

| Review | Cadence | Scope | Purpose |
|--------|---------|-------|---------|
| template-review | Every run | Global | Template structure and sync-config integrity |
| rules-review | 7 days | Project | Rule organization and separation of concerns |
| skills-review | 7 days | Project | Skill context efficiency |
| spec-review | 14 days | Project | OpenSpec implementation and test coverage |

## Workflow

### Step 1: Check Status

```bash
~/.claude/skills/systems-review/review-tracker.sh status
```

Shows all applicable reviews with days since last run and overdue status.

### Step 2: Get Recommendations

```bash
~/.claude/skills/systems-review/review-tracker.sh recommend
```

Lists reviews that are due, sorted by priority (never-run first, then most overdue).

### Step 3: Present Options

Display a summary table:

```markdown
## Review Status

| Review | Last Run | Status |
|--------|----------|--------|
| template-review | never | Due (run every session) |
| rules-review | 10 days | Due (3 days overdue) |
| skills-review | 5 days | OK (2 days remaining) |
| spec-review | 20 days | Due (6 days overdue) |
```

### Step 4: Ask User Selection

Use `AskUserQuestion` to let the user choose which reviews to run:

- Show recommended reviews as options
- Allow "Skip" to exit without running any
- Allow multiple selection if user wants to run several

### Step 5: Execute Selected Reviews

For each selected review, invoke using the `Skill` tool:

```
Skill: rules-review
Skill: skills-review
```

### Step 6: Confirm Completion

After each review completes, the individual skill will automatically record its completion via `review-tracker.sh record <name>`.

## Commands

```bash
# Show status of all reviews
~/.claude/skills/systems-review/review-tracker.sh status

# JSON output for parsing
~/.claude/skills/systems-review/review-tracker.sh status json

# Get recommendations (sorted by priority)
~/.claude/skills/systems-review/review-tracker.sh recommend

# Record a review completion (called by individual skills)
~/.claude/skills/systems-review/review-tracker.sh record <name>

# Initialize history files
~/.claude/skills/systems-review/review-tracker.sh init
```

## History Files

| Scope | File | Reviews Tracked |
|-------|------|-----------------|
| Global | `~/.claude/.systems-review.json` | template-review |
| Project | `./.systems-review.json` | rules-review, skills-review, spec-review |

Both files are gitignored. The script automatically routes to the correct file.

## Conditional Inclusion

Reviews are only shown if applicable:

- `template-review`: Always included
- `rules-review`: Only if `.claude/rules/` exists
- `skills-review`: Only if `.claude/skills/` exists
- `spec-review`: Only if `.openspec/` or `specs/` exists
