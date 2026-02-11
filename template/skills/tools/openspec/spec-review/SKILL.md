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

Per-spec JSON in `.spec-review/{analysis}/specs/`, aggregated `results.json`, and markdown reports: `SPEC_COVERAGE_REPORT.md`, `TEST_QUALITY_REPORT.md`, `SPEC_QUALITY_REPORT.md`

## Quick Start

```bash
# Setup output directories (run once)
.claude/skills/spec-review/review-specs.sh setup

# Check progress for an analysis
.claude/skills/spec-review/review-specs.sh progress coverage --json

# Get next batch of specs to analyze
.claude/skills/spec-review/review-specs.sh batch coverage 12
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

### Step 4: Check Progress

```bash
.claude/skills/spec-review/review-specs.sh progress coverage --json
```

Returns: `{"status": "not_started", "total": 43, "completed": 0, "pending": [...]}`.
The orchestrator sees counts and a pending list -- never the full JSON results.

### Step 5: Dispatch Loop (coverage/tests)

Repeat until `progress` shows `status: "complete"`:

**a. Get next batch:**

```bash
.claude/skills/spec-review/review-specs.sh batch coverage 12
# Returns comma-separated spec names, e.g.: spec-a,spec-b,...,spec-l
```

**b. Split into groups and spawn subagents:**

Split the comma-separated result into 3 groups of ~4 specs each. Spawn 3 parallel Task subagents (subagent_type: "Explore", model: "sonnet").

Each subagent receives:
- The batch prompt from `COVERAGE.md` or `TESTS.md` (Subtask Prompt Template section)
- Its group of spec names substituted into the `<spec-1>, <spec-2>, ...` placeholders
- Instruction to write per-spec JSON files to `.spec-review/{analysis}/specs/<spec-name>.json`
- Instruction to return ONLY a one-line summary per spec (e.g., `Done: spec-a (5/8 impl), spec-b (3/3 impl)`)

**c. Check progress:**

After all subagents in the batch return:

```bash
.claude/skills/spec-review/review-specs.sh progress coverage --json
```

The orchestrator sees updated counts. Loop back to (a) if pending > 0.

**Context budget:** The orchestrator sees ~70 lines total across an entire run: progress counts + one-line summaries from subagents. It never reads per-spec JSON files or results.json.

**For structure analysis:** Use the existing approach in `STRUCTURE.md` (scripted detections + AI-analyzed detections). Structure analysis does not use the batch dispatch loop.

### Step 6: Aggregate and Report

After dispatch loop completes (or for structure, after its analysis):

```bash
# Merge per-spec JSONs into results.json
.claude/skills/spec-review/review-specs.sh aggregate coverage

# Generate markdown report from results.json
.claude/skills/spec-review/review-specs.sh report coverage
```

Repeat for each analysis type that was run.

### Step 7: Report Summary

```bash
.claude/skills/spec-review/review-specs.sh progress coverage
.claude/skills/spec-review/review-specs.sh progress tests
```

Report the final counts to the user:

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

Progress is tracked by per-spec JSON files on disk. To resume:

1. Run `/spec-review` again
2. `review-specs.sh progress <analysis> --json` shows completed/pending counts
3. The dispatch loop picks up from the first pending spec automatically

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Skip active changes check for structure | Suggests refactoring active work |
| Auto-create tasks without review | Clutters tracker without review |
| Mark scenarios covered without evidence | False confidence |
| Skip progress file updates | Lose resume capability |

## After Completion

Record this review:

```bash
.claude/scripts/systems-tracker.sh record spec-review
```
