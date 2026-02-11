---
name: Wrap
description: End-of-session workflow - archive specs, complete tasks, run quality gates, push changes
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
1. **Ask the user**: "OpenSpec change `<change-id>` is still active. Should I verify and archive it?"
2. If yes: Run `/opsx:verify <change-id>` first, then `/opsx:archive <change-id>`
3. If no: Note it as remaining work

### Step 2: Check In-Progress Tasks

```
TaskList -> find tasks where status = "in_progress" or status = "pending"
```

For each in-progress task:
1. **Ask the user**: "Task #<id>: <subject> is still in progress. Should I complete it?"
2. If yes: `TaskUpdate({ taskId: "<id>", status: "completed" })`
3. If no: Note it as remaining work

For pending tasks (not blocked):
1. Note as remaining work in handoff summary

### Step 3: Push

```bash
but push <branch>            # Push only branches worked on THIS session
```

**Only push branches where you made commits during this session.** Do not push unrelated branches that happen to have unpushed commits from previous sessions.

### Step 5: Verify Completion and Check PRs

```bash
but status                   # Verify all branches pushed
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

### Completed Tasks
- [x] Task #<id>: <subject> (if any)

### Pushed (this session)
- [x] Branch: `<branch-name>` -> origin
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

- **Verify before archiving OpenSpec** - Run `/opsx:verify` before `/opsx:archive`
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
