---
name: Status
description: Show unified workflow status - OpenSpec changes, beads, and git state
category: Workflow
tags: [status, overview, orientation]
---

# Status Command

Display a unified view of current workflow state including OpenSpec changes, beads issues, and git status. Use this for orientation at session start or to check progress mid-session.

## Usage

```
/status
```

No arguments needed.

## Information Gathered

Run these commands to collect status:

```bash
openspec list                    # Active OpenSpec changes (if using OpenSpec)
bd list --status=in_progress     # In-progress beads
bd ready                         # Ready-to-work beads (no blockers)
but status                       # Git branches and uncommitted changes
```

### Checking Remote Push Status

To accurately determine if branches are pushed, compare local branch commits with remote:

```bash
# Get remote branch refs
git ls-remote --heads origin | grep -E "(branch1|branch2)"

# Compare: if remote SHA matches local SHA, branch is pushed
# Local SHA from `but status` output
# Remote SHA from `git ls-remote` output
```

**Logic:**
- If branch exists on remote AND remote SHA = local SHA → **Pushed**
- If branch exists on remote AND remote SHA ≠ local SHA → **Unpushed commits**
- If branch does NOT exist on remote → **Not pushed**

Do NOT rely on `git branch -vv` tracking info in GitButler workspaces - branches may be pushed without tracking configured.

## Output Format

Present the information in this format:

```markdown
## Workflow Status

### Active OpenSpec Changes
| Change ID | Summary |
|-----------|---------|
| <id> | <first line of proposal.md> |

_None active_ (if empty or not using OpenSpec)

### In-Progress Beads
| ID | Title | Linked to OpenSpec? |
|----|-------|---------------------|
| <id> | <title> | Yes: <change-id> / No |

_None in progress_ (if empty)

### Ready to Work
| ID | Title | Priority |
|----|-------|----------|
| <id> | <title> | P<n> |

_None ready_ (if empty)

### Git Status
**GitButler Branches:**
| Branch | Local SHA | Remote Status |
|--------|-----------|---------------|
| <branch> | <sha> | Pushed / Not pushed / Unpushed commits |

**Uncommitted changes:**
- <branch>: <n> files modified

_All clean_ (if nothing to report)

### Warnings
- <warning message if any inconsistencies detected>

_No warnings_ (if everything is consistent)
```

## Consistency Checks

After gathering status, check for these inconsistencies:

| Check | Warning Message |
|-------|-----------------|
| OpenSpec change exists but no matching in-progress bead | "OpenSpec `<id>` has no tracking bead - create one with `bd create --title=\"<id>\" --type=feature`" |
| In-progress bead matches archived OpenSpec | "Bead `<id>` tracks archived OpenSpec - close it with `bd close <id>`" |
| Uncommitted changes but no in-progress bead | "Uncommitted changes but no bead in progress - consider creating one" |
| Multiple OpenSpec changes active | "Multiple OpenSpec changes active - ensure they don't conflict" |
| Branch not pushed to remote | "Branch `<branch>` not pushed - run `but push <branch>` if work is complete" |

## Linking Detection

To detect if a bead is linked to an OpenSpec change:
- Check if bead title matches a change-id exactly
- Check if bead title contains the change-id
- Check if bead description references the change

## Usage Tips

- Run at **session start** to orient yourself
- Run **mid-session** to check what's in flight
- Run **before `/wrap`** to preview what needs to be completed
