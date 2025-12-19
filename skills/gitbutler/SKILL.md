---
name: gitbutler
description: Invoke when user says "commit", "create a PR", or requests git operations. Use for commits, branches, status, virtual branch management, and PR creation. Don't use raw git commit.
---

# GitButler Workflow

GitButler manages multiple virtual branches simultaneously.

## Critical Rules

> **When the user says "commit", use GitButler (`but commit`), not `git commit`.**

- **Run `but status` after every action** - File IDs shift after commits, rubs, and other operations. Always refresh IDs before the next action.
- **Commit in logical groupings** - Group related changes into separate commits (e.g., feature + tests in one commit, config changes in another)
- **Use the `--only` flag** when committing: `but commit <branch> --only -m "..."`
- **Ask which branch** if target is ambiguous (multiple branches with changes)
- **Never push** without explicit user request

## Command Reference

| Command | Description |
|---------|-------------|
| `but status` | View uncommitted changes by branch (`-v` for details, `-f` for committed files) |
| `but branch new <name>` | Create new virtual branch |
| `but rub <file-id> <branch-id>` | Assign file to branch |
| `but commit <branch> --only -m "..."` | Commit only assigned files |
| `but push <branch>` | Push branch to remote |
| `but undo` | Undo last operation |
| `but oplog` | View operation history |
| `but restore <snapshot-id>` | Restore to specific snapshot |

## The `rub` Command

| Source | Target | Operation |
|--------|--------|-----------|
| File/Hunk | Branch | Assign to branch |
| File/Hunk | Commit | Amend commit |
| Commit | Commit | Squash |
| Commit | Branch | Move commit |

## Standard Workflow

```bash
but branch new feature-name           # 1. Create branch
# ... make changes ...
but status                            # 2. See file IDs
but rub <file-id> feature-name        # 3. Assign files to branch
but commit feature-name --only -m ""  # 4. Commit (use --only)
```

## Commit Workflow (Step by Step)

When user asks to commit:

1. Run `but status` to see branches and uncommitted changes
2. If multiple branches have changes, ask user which branch to commit to
3. **Group changes logically** - Identify distinct concerns:
   - Feature code + its tests = one commit
   - Config/tooling changes = separate commit
   - Documentation updates = separate commit
   - Unrelated bug fixes = separate commits
4. For each logical group:
   - Assign related files with `but rub <file-id> <branch>`
   - Use `but commit <branch> --only -m "<message>"`
5. Confirm success with `but status`

**Example logical groupings:**
```
# Group 1: Feature + tests
but status                        # Get current file IDs
but rub <component-file> my-branch
but rub <test-file> my-branch
but commit my-branch --only -m "Add feature X with tests"

# Group 2: Config change
but status                        # IDs shifted after commit - refresh!
but rub <config-file> my-branch
but commit my-branch --only -m "Update config for Y"
```

## ID Ambiguity

If you see "Source 'XX' is ambiguous", it means the short ID matches both an uncommitted file AND a committed file in the branch history.

**Understanding `but status` output:**
```
g8 D .claude/agents/supabase-expert.md
│  │  └── file path
│  └── status (D=Deleted, M=Modified, A=Added, R=Renamed)
└── ID (just "g8", NOT "g8D")
```

**Workaround: git add + commit without --only**
```bash
git add <file-path>              # Stage with git directly
but commit <branch> -m "..."     # Omit --only to include staged changes
```

**After using this workaround**, squash into the previous commit:
```bash
but rub <new-commit> <previous-commit>  # Squashes new into previous
```

## Squashing Commits

To combine commits (e.g., after using the ambiguity workaround):

```bash
but rub <commit-to-squash> <target-commit>
```

Example: `but rub abc123 def456` squashes abc123 into def456.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| `but commit` without `--only` | Includes unassigned files (exception: ID ambiguity workaround) |
| `but describe <sha>` | Opens interactive editor, hangs session |
| `but push --force` | Invalid flag - `but push` auto-handles force push when needed |
| `git push` instead of `but push` | Bypasses GitButler, use `but push <branch>` instead |
| `git commit` instead of `but commit` | Bypasses GitButler, breaks virtual branches |
| Push without asking | User decides when to push to remote |

## Recovery

```bash
but undo                    # Undo last operation
but oplog                   # See operation history
but restore <snapshot-id>   # Restore to specific point
```

## PR Creation

**Always ask the user before pushing or creating a PR.** The user decides when to push to remote.

```bash
# Only after user explicitly requests PR creation:
gh pr create --head <branch-name>  # Handles push automatically
```

---

## OpenSpec Integration (when openspec/ folder exists)

These workflows apply when the project uses OpenSpec for change management.

### OpenSpec Proposal Creation

When creating an OpenSpec proposal (via `/openspec:proposal`):

**After validation passes:**

1. `but branch new <change-id>` - Create branch matching the change ID exactly
2. `but status` - Get file IDs for the new proposal files
3. Assign all proposal files to the branch:
   - `openspec/changes/<change-id>/proposal.md`
   - `openspec/changes/<change-id>/tasks.md`
   - `openspec/changes/<change-id>/design.md` (if created)
   - `openspec/changes/<change-id>/specs/**/*.md` (all spec deltas)
4. `but commit <change-id> --only -m "Add OpenSpec proposal: <change-id>"`

**Commit message format:**
```
Add OpenSpec proposal: <change-id>

<One-line summary from proposal.md>
```

### OpenSpec Implementation

When implementing an OpenSpec change (via `/openspec:apply`):

**Before writing code:**

1. `but branch new <change-id>` - Branch name **MUST** match change ID exactly
2. Read the proposal, design, and tasks files in the change directory

**During implementation:**

- **Commit after each major section** from `tasks.md` (not at the end)
- **Include `tasks.md`** when assigning files to branch
- Use `but commit <branch> --only -m "..."` for each commit

**Task completion rules:**

| Condition | Action |
|-----------|--------|
| Code committed | ✅ Tick it off |
| Automated tests passing | ✅ Tick it off |
| Manual testing needed | ❌ DO NOT tick until user confirms |
| Tests to be written | ❌ DO NOT tick |

**Workflow:**
```
Create branch → Read proposal/design/tasks → Implement section →
Tick tasks → Commit → Repeat → Ask user about PR
```
