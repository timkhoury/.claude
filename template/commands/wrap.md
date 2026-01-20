---
name: Wrap
description: End-of-session workflow - archive specs, close beads, run quality gates, push changes
category: Workflow
tags: [wrap, session, end, landing]
---

# Wrap Command

Complete end-of-session workflow that ensures nothing is left behind. This command orchestrates the full "landing the plane" sequence.

## Usage

```
/wrap
```

No arguments needed. The command will interactively guide you through the completion process.

## Workflow Steps

Execute these steps in order:

### Step 1: Check Active OpenSpec Changes (if using OpenSpec)

```bash
openspec list
```

For each active change:
1. **Ask the user**: "OpenSpec change `<change-id>` is still active. Should I archive it?"
2. If yes: Run `/openspec:archive <change-id>`
3. If no: Note it as remaining work

### Step 2: Check In-Progress Beads

```bash
bd list --status=in_progress
```

For each in-progress bead:
1. **Check if linked to archived OpenSpec**: If the bead title matches a just-archived change-id, close it automatically with `bd close <id> --reason="Archived: <change-id>"`
2. **Otherwise ask the user**: "Bead `<id>: <title>` is still in progress. Should I close it?"
3. If yes: `bd close <id> --reason="Completed"`
4. If no: Note it as remaining work

### Step 3: Run Quality Gates (if code changed)

Check if session branches contain **actual code changes** (not just markdown/docs):
```bash
but status -f    # Shows committed files per commit
```

Look for code file extensions in the session branch commits:
- **Code files** (run pr-check): `.ts`, `.tsx`, `.js`, `.jsx`, `.css`, `.sql`, `.py`, `.go`, `.rs`
- **Build config** (run pr-check): `package.json`, `tsconfig.json`, config files
- **Docs/tooling** (skip pr-check): `.md`, `.sh`, `.yaml`

If code files were changed:
1. Ask user if they want to run quality gates
2. If yes: Run pr-check or equivalent
3. If quality gates fail: Report issues and ask how to proceed

Skip this step entirely for documentation-only sessions.

### Step 4: Sync and Push

```bash
bd sync                      # Sync beads to remote
but push <branch>            # Push only branches worked on THIS session
```

**Only push branches where you made commits during this session.** Do not push unrelated branches that happen to have unpushed commits from previous sessions.

To identify session branches:
- Track which branches you committed to during the conversation
- These are the only branches to push

If other branches have unpushed commits, mention them in the handoff summary but do not push them.

### Step 5: Verify Completion and Check PRs

```bash
but status                   # Verify all branches pushed
bd list --status=in_progress # Verify no forgotten beads
openspec list                # Verify no forgotten changes (if using OpenSpec)
```

For each pushed branch, check if a PR exists:
```bash
gh pr view <branch-name> --json url,state --jq '"\(.url) (\(.state))"' 2>/dev/null || echo "No PR"
```

If a PR exists, include the link in the summary. If no PR exists, note that one can be created.

### Step 6: Generate Handoff Summary

Output a summary:

```markdown
## Session Wrap-up Complete

### Archived
- [x] OpenSpec: <change-id> (if any)

### Closed
- [x] Bead: <id> - <title> (if any)

### Pushed (this session)
- [x] Branch: `<branch-name>` → origin
  - PR: <pr-url> (OPEN/MERGED) _or_ "No PR - create with `gh pr create --head <branch-name>`"

### Other Unpushed Branches
- <branch-name>: <n> commits (from previous session)

_None_ (if all branches are pushed)

### Remaining Work
- [ ] <any items user chose not to complete>

### Next Session
<Brief context for picking up work>
```

## Important Rules

- **Never skip archiving OpenSpec before closing related beads** - The order matters
- **Always push** - Work is not complete until pushed to remote
- **Report remaining work** - If user chooses not to complete something, document it clearly
- **Generate handoff** - Always provide context for the next session

## Error Handling

| Situation | Action |
|-----------|--------|
| OpenSpec archive fails | Report error, ask user how to proceed |
| Quality gates fail | Report failures, ask if user wants to fix or skip |
| Push fails | Report error, suggest resolution |
| No active work | Skip to verification and report clean state |
