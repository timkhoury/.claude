---
name: rules-updater
description: >
  Analyzes current conversation context to extract patterns worth codifying into rules.
  Writes to both project and template locations to keep them in sync.
  Use when a session revealed corrections, gotchas, or best practices that should be
  remembered. Triggers: "update rules", "extract patterns", "learn from this", "codify this".
---

# Rules Updater

Extracts patterns from conversation context and proposes rule updates. Handles sync between project and template.

## Critical Rules

1. **Only codify repeated patterns** - Single occurrences may be edge cases, not rules
2. **User corrections are high signal** - When user corrects Claude, that's a rule candidate
3. **Write to both locations** - Syncable rules go to project AND template
4. **Project rules stay local** - `rules/project/` never syncs to template

## Sync Locations

| Rule Type | Project Location | Template Location |
|-----------|------------------|-------------------|
| Tech patterns | `.claude/rules/tech/` | `~/.claude/template/rules/tech/` |
| Cross-cutting | `.claude/rules/patterns/` | `~/.claude/template/rules/patterns/` |
| Workflow | `.claude/rules/workflow/` | `~/.claude/template/rules/workflow/` |
| Meta | `.claude/rules/meta/` | `~/.claude/template/rules/meta/` |
| **Project-specific** | `.claude/rules/project/` | **Never synced** |

## When to Use

| Trigger | Example |
|---------|---------|
| User made a correction | "No, always use X instead of Y" |
| Discovered a gotcha | API behavior that wasn't obvious |
| Pattern emerged from debugging | Root cause that will recur |
| Best practice crystallized | After trying multiple approaches |
| Session had repeated friction | Same issue came up multiple times |

## Workflow

### 1. Scan Conversation Context

Review the current session for:

| Signal | Weight | Example |
|--------|--------|---------|
| User corrections | High | "That's wrong, use..." |
| Repeated mistakes | High | Same error multiple times |
| Debugging discoveries | Medium | "Ah, the issue was..." |
| Workarounds applied | Medium | Non-obvious solutions |
| Tool/API gotchas | Medium | Unexpected behavior |

### 2. Check Existing Rules

Search both locations:

```bash
# Project rules
grep -r "keyword" .claude/rules/

# Template rules
grep -r "keyword" ~/.claude/template/rules/
```

| If Found | Action |
|----------|--------|
| Rule exists but incomplete | Propose amendment to both |
| Rule exists and covers it | Skip (no duplication) |
| Related rule exists | Propose addition to that file |
| No related rule | Propose new rule |

### 3. Classify and Locate

| Pattern Type | Syncs? | Files to Update |
|--------------|--------|-----------------|
| Technology-specific | Yes | Both project + template |
| Integration pattern | Yes | Both project + template |
| Cross-cutting | Yes | Both project + template |
| Workflow | Yes | Both project + template |
| **Project-specific** | **No** | Project only |

### 4. Write to Both Locations

For syncable rules, always write to BOTH:

```bash
# 1. Update project rule
# .claude/rules/{category}/{file}.md

# 2. Update template rule (same content)
# ~/.claude/template/rules/{category}/{file}.md
```

**Important:** Content must be identical in both locations to stay in sync.

### 5. Present to User

Show:
1. What pattern was identified
2. Classification (syncable vs project-only)
3. Both file paths that will be updated
4. Exact text to add
5. Ask for approval before making changes

## Output Format

```markdown
## Patterns Identified

### 1. [Pattern Name]
**Source:** [What triggered this - user correction, debugging, etc.]
**Rule:** [The pattern to remember]
**Type:** [Syncable / Project-only]
**Files:**
- `.claude/rules/{category}/{file}.md`
- `~/.claude/template/rules/{category}/{file}.md` (if syncable)

**Addition:**
[Exact markdown to add]

---

## Actions Required

- [ ] Update `.claude/rules/tech/example.md`
- [ ] Update `~/.claude/template/rules/tech/example.md`
- [ ] Rebuild agents: `npm run build:agents` (if bundle affected)
```

## Anti-Patterns

| Don't | Why |
|-------|-----|
| Update only one location | Rules drift out of sync |
| Codify one-off edge cases | Clutters rules with noise |
| Add user preferences as rules | Preferences != patterns |
| Duplicate existing content | Increases maintenance burden |
| Skip user approval | User owns the rules |

## After Approval

1. Edit both files with identical content
2. If rule bundles affected, rebuild agents: `npm run build:agents`
3. Commit changes: `but commit <branch> -m "docs: add rule for [pattern]"`
