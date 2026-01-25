---
name: quality-audit
description: >
  Combined quality analysis: spec implementation coverage AND test coverage.
  Single pass through OpenSpec specs, produces both SPEC_COVERAGE_REPORT.md
  and TEST_QUALITY_REPORT.md. Use for comprehensive quality audits.
---

# Quality Audit

Orchestrates both spec-coverage and test-quality analysis for comprehensive quality audits.

## What This Does

Runs both quality checks and produces:
- `SPEC_COVERAGE_REPORT.md` - Implementation gaps (from spec-coverage)
- `TEST_QUALITY_REPORT.md` - Test gaps (from test-quality)

## Critical Rules

1. **Check for OpenSpec first** - If no `openspec/specs/` exists, run test-quality only
2. **Run sequentially** - spec-coverage first, then test-quality
3. **Combine results** - Merge into single `.quality-audit/results.json`

## Workflow

### Step 1: Check for OpenSpec

```bash
ls openspec/specs/ 2>/dev/null || echo "NO_OPENSPEC"
```

### Step 2: Run Spec Coverage (if OpenSpec exists)

```
Use the Skill tool:
  skill: "spec-coverage"
```

Wait for completion. The skill will produce:
- `.spec-coverage/results.json`
- `SPEC_COVERAGE_REPORT.md`

### Step 3: Run Test Quality

```
Use the Skill tool:
  skill: "test-quality"
```

Wait for completion. The skill will produce:
- `.test-quality/results.json`
- `TEST_QUALITY_REPORT.md`

### Step 4: Combine Results

Create `.quality-audit/results.json` by merging both result files:

```json
{
  "generatedAt": "<ISO timestamp>",
  "implementation": { /* from .spec-coverage/results.json */ },
  "testing": { /* from .test-quality/results.json */ },
  "summary": {
    "specsAnalyzed": <number>,
    "implementationCoverage": "<percent>%",
    "testCoverage": "<percent>%"
  }
}
```

### Step 5: Report Summary

```
## Quality Audit Complete

| Metric | Coverage |
|--------|----------|
| Implementation | X% (Y/Z scenarios) |
| Test Coverage | X% (Y/Z scenarios) |

Reports generated:
- SPEC_COVERAGE_REPORT.md
- TEST_QUALITY_REPORT.md
```

## Non-OpenSpec Fallback

If no `openspec/specs/` directory exists:

1. Skip spec-coverage
2. Run test-quality only
3. Report: "No OpenSpec specs found. Test quality report generated."

## When to Use Which Skill

| Skill | Use When |
|-------|----------|
| `/quality-audit` | Full audit - both implementation and tests |
| `/spec-coverage` | Only checking implementation coverage |
| `/test-quality` | Only checking test coverage |

This skill orchestrates both for convenience; use individual skills for focused checks.
