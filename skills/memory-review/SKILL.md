---
name: memory-review
description: >
  Review auto-memory for redundant entries already covered by rules or skills.
  Use when auditing memory, cleaning up MEMORY.md, or after adding new rules.
---

# Memory Review

Audit MEMORY.md files for entries that duplicate knowledge already in rules or skills.

## Why This Matters

Auto-memory captures lessons learned during sessions. Over time, some of those lessons get codified into rules. The memory entries then become redundant context that wastes tokens on every session.

## Review Process

### Step 1: Locate Memory Files

Check both project-specific and global memory:

```bash
# Project memory (path varies by project)
ls ~/.claude/projects/*/memory/MEMORY.md

# Global memory
ls ~/.claude/MEMORY.md
```

Read each file and list every distinct memory entry.

### Step 2: Search Rules for Coverage

For each memory entry, search rules and skills for overlapping content:

```bash
# Search project rules
grep -ri "<keyword>" .claude/rules/

# Search global rules
grep -ri "<keyword>" ~/.claude/rules/

# Search skills (some encode operational knowledge)
grep -ri "<keyword>" .claude/skills/
```

### Step 3: Classify Each Entry

| Classification | Action |
|----------------|--------|
| **Fully covered** by a rule | Remove from memory |
| **Partially covered** | Keep the uncovered part, remove the rest |
| **Not covered** anywhere | Keep in memory (or consider creating a rule) |
| **Outdated/wrong** | Remove from memory |

### Step 4: Report Findings

Present findings as a table before making changes:

```markdown
| Memory Entry | Status | Covered By |
|-------------|--------|------------|
| "Use -p flag for commits" | Fully covered | `.claude/rules/git-rules.md` |
| "Vitest mock pattern" | Not covered | - |
```

### Step 5: Apply Changes

After user confirms, edit MEMORY.md to remove redundant entries. If a memory file becomes empty, leave just the `# Memory` header.

## After Completion

```bash
~/.claude/template/scripts/systems-tracker.sh record memory-review
```
