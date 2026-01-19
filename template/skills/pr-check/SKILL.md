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

## Configuration

Customize these commands for your project:

| Check | Default Command | Your Project |
|-------|-----------------|--------------|
| Lint | `npm run lint` | <!-- customize --> |
| Typecheck | `npm run typecheck` | <!-- customize --> |
| Test | `npm run test` | <!-- customize --> |
| Build | `npm run build` | <!-- customize --> |

## Execution

All tasks use:
- `subagent_type: general-purpose`
- `model: haiku`

### Wave 1: Parallel (single message with 3 Task tools)

| Task | Prompt |
|------|--------|
| Lint | Run lint command. Report pass/fail with error summary if failed. |
| Typecheck | Run typecheck command. Report pass/fail with error summary if failed. |
| Test | Run test command. Report pass/fail with test count (N passed, M skipped). |

### Wave 2: Sequential (after Lint and Typecheck pass)

| Task | Prompt |
|------|--------|
| Build | Run build command. Report pass/fail with error summary if failed. |

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

## Customization Examples

### Node.js / npm
```bash
npm run lint
npm run typecheck
npm run test
npm run build
```

### Python / pytest
```bash
ruff check .
mypy .
pytest
python -m build
```

### Go
```bash
golangci-lint run
go build ./...
go test ./...
```

### Rust
```bash
cargo clippy
cargo build
cargo test
```
