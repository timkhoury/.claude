---
name: pr-check
description: >
  Run pre-PR quality checks (lint, typecheck, build, test) in parallel.
  Use when preparing to create a PR, before pushing changes, or when user
  says "pr check", "check pr", "run checks", or "pre-pr".
model: claude-haiku-4-5
allowed-tools: [Task]
---

# Pre-PR Quality Check

Run quality checks in two waves using fast subagent tasks.

## Finding Commands

Look in the project's CLAUDE.md or rules files for the specific commands. Common patterns:

| Check | Typical Commands |
|-------|------------------|
| Lint | `npm run lint`, `ruff check .`, `golangci-lint run`, `cargo clippy` |
| Typecheck | `npm run typecheck`, `mypy .`, `tsc --noEmit` |
| Test | `npm run test`, `pytest`, `go test ./...`, `cargo test` |
| Build | `npm run build`, `go build ./...`, `cargo build` |

Use whatever commands are documented for this specific project.

## Execution

All tasks use:
- `subagent_type: general-purpose`
- `model: haiku`

### Wave 1: Parallel (single message with 3 Task tools)

| Task | Prompt |
|------|--------|
| Lint | Run the project's lint command. Report pass/fail with error summary if failed. |
| Typecheck | Run the project's typecheck command. Report pass/fail with error summary if failed. |
| Test | Run the project's test command. Report pass/fail with test count (N passed, M skipped). |

### Wave 2: Sequential (after Lint and Typecheck pass)

| Task | Prompt |
|------|--------|
| Build | Run the project's build command. Report pass/fail with error summary if failed. |

**Note:** If Lint or Typecheck fails, skip the Build step and report failure.

## Output Format

After all tasks complete, summarize:

```
## PR Check: [PASSED/FAILED]

| Step | Status |
|------|--------|
| Lint | ✓ Pass / ✗ Fail |
| Typecheck | ✓ Pass / ✗ Fail |
| Build | ✓ Pass / ✗ Fail / ⏭ Skipped |
| Test | ✓ Pass (N passed, M skipped) / ✗ Fail |

[If any failed: show error output]
[If all passed: "Ready to create PR."]
```
