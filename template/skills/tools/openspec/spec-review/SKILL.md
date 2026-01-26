---
name: spec-review
description: >
  Analyze OpenSpec specs for implementation coverage, test coverage, and structural quality.
  Use for quality audits before releases or when tracking spec health.
---

# Spec Review

Comprehensive OpenSpec analysis covering implementation coverage, test coverage, and structural organization.

## Usage

```
/spec-review              # All three analyses
/spec-review coverage     # Implementation coverage only
/spec-review tests        # Test coverage only
/spec-review structure    # Spec organization only
```

## Output

All output goes to `.spec-review/` with `{analysis}/results.json` and progress files for resume. Reports: `SPEC_COVERAGE_REPORT.md`, `TEST_QUALITY_REPORT.md`, `SPEC_QUALITY_REPORT.md`

## Quick Start

```bash
# Setup output directories (run once)
.claude/skills/spec-review/review-specs.sh setup

# Check prerequisites and progress
.claude/skills/spec-review/review-specs.sh status

# Enumerate specs with counts
.claude/skills/spec-review/review-specs.sh enumerate
```

## Workflow

### Step 1: Parse Arguments

Determine which analyses to run:

| Argument | Analyses |
|----------|----------|
| (none) | coverage + tests + structure |
| `coverage` | coverage only |
| `tests` | tests only |
| `structure` | structure only |

### Step 2: Run Setup and Status

```bash
# Ensure directories exist
.claude/skills/spec-review/review-specs.sh setup

# Check prerequisites and progress
.claude/skills/spec-review/review-specs.sh status
```

If no OpenSpec directory:
- `coverage`: Report "No OpenSpec specs found" and exit
- `tests`: Run test health check only (see TESTS.md fallback section)
- `structure`: Report "No OpenSpec specs found" and exit

### Step 3: Check for Active Changes (structure only)

```bash
.claude/skills/spec-review/review-specs.sh changes
```

If active changes exist, mark affected specs as BLOCKED in the structure analysis.

### Step 4: Enumerate Specs

```bash
# Get spec list with requirement/scenario counts
.claude/skills/spec-review/review-specs.sh enumerate --json
```

Resume from progress files if status is `in_progress`.

### Step 5: Run Analyses

Based on args, read the appropriate reference files:

| Analysis | Reference File | Purpose |
|----------|----------------|---------|
| coverage | `COVERAGE.md` | Implementation evidence search |
| tests | `TESTS.md` | Test matching strategies |
| structure | `STRUCTURE.md` | Detection algorithms |

**Shared formats:** Read `PATTERNS.md` for JSON structures and report templates.

**Subtask delegation:** Each spec analysis spawns a subtask using the prompts in the reference files. This preserves main context.

### Step 6: Generate Reports

After all specs analyzed, aggregate results and generate markdown reports per PATTERNS.md.

### Step 7: Report Summary

```markdown
## Spec Review Complete

| Analysis | Coverage |
|----------|----------|
| Implementation | X% (Y/Z scenarios) |
| Test Coverage | X% (Y/Z scenarios) |
| Structure Issues | N found (H high, M medium, L low) |

Reports generated:
- SPEC_COVERAGE_REPORT.md
- TEST_QUALITY_REPORT.md
- SPEC_QUALITY_REPORT.md
```

## Sequential Execution (Full Audit)

When running all analyses:

1. Run **coverage** first - produces implementation evidence
2. Run **tests** second - produces test coverage
3. Run **structure** last - uses both for context

This order allows structure analysis to reference coverage gaps.

## Pause/Resume

Each analysis maintains its own progress file. To resume:

1. Run `/spec-review` again
2. Skill detects existing progress files
3. Resumes from last checkpoint

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Skip active changes check for structure | Suggests refactoring active work |
| Auto-create beads issues | Clutters tracker without review |
| Mark scenarios covered without evidence | False confidence |
| Skip progress file updates | Lose resume capability |

## After Completion

Record this review:

```bash
.claude/scripts/review-tracker.sh record spec-review
```
