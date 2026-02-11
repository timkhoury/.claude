# Shared Patterns

Common formats and structures used across all spec-review analyses.

## Progress Tracking

Progress is computed from file existence (no mutable progress file). The script scans `.spec-review/{analysis}/specs/` for valid JSON files and compares against `openspec/specs/`.

```bash
# Check progress
review-specs.sh progress coverage --json

# Get next batch of pending specs
review-specs.sh batch coverage 12
```

**Resume:** Re-run `/spec-review` - progress auto-detects completed specs from existing JSON files.

## Per-Spec Result Format

### Coverage Analysis

```json
{
  "spec": "<spec-name>",
  "analyzedAt": "<ISO timestamp>",
  "scenarios": { "total": 4, "implemented": 3, "partial": 0, "unimplemented": 1, "outdated": 0 },
  "details": [
    {
      "scenario": "<name>",
      "status": "implemented|partial|unimplemented|outdated",
      "evidence": [{ "file": "<path>", "line": 45, "description": "<what>" }],
      "missingConditions": ["<WHEN/THEN not found>"],
      "notes": "<explanation if partial/outdated>"
    }
  ]
}
```

### Test Analysis

```json
{
  "spec": "<spec-name>",
  "analyzedAt": "<ISO timestamp>",
  "scenarios": { "total": 4, "covered": 3, "partial": 0, "missing": 1 },
  "details": [
    {
      "scenario": "<name>",
      "status": "covered|partial|missing",
      "tests": [{ "file": "<path>", "line": 15, "name": "<test description>" }],
      "suggestion": "<what test to add if missing>"
    }
  ]
}
```

## Aggregated Results Format

### Coverage Results

Location: `.spec-review/coverage/results.json`

```json
{
  "generatedAt": "<ISO timestamp>",
  "summary": {
    "specsAnalyzed": 37,
    "totalScenarios": 180,
    "implementedScenarios": 150,
    "partialScenarios": 15,
    "unimplementedScenarios": 12,
    "outdatedScenarios": 3,
    "coveragePercent": 83.3
  },
  "byCategory": {
    "auth": { "specs": 6, "scenarios": 28, "implemented": 25, "partial": 2, "unimplemented": 1, "outdated": 0 }
  },
  "gaps": [{ "spec": "<name>", "scenario": "<name>", "priority": "high|medium|low", "missingConditions": ["..."] }],
  "drift": [{ "spec": "<name>", "scenario": "<name>", "notes": "Spec says X, code does Y" }]
}
```

### Test Results

Location: `.spec-review/tests/results.json`

```json
{
  "generatedAt": "<ISO timestamp>",
  "summary": {
    "specsAnalyzed": 37,
    "totalScenarios": 180,
    "coveredScenarios": 142,
    "partialScenarios": 10,
    "missingScenarios": 28,
    "coveragePercent": 78.9
  },
  "byCategory": { "auth": { "specs": 6, "scenarios": 28, "covered": 24, "partial": 2, "missing": 2 } },
  "gaps": [{ "spec": "<name>", "scenario": "<name>", "priority": "high|medium|low", "suggestion": "..." }],
  "testHealth": {
    "unitTests": { "passed": 145, "failed": 0, "skipped": 3 },
    "e2eTests": { "passed": 42, "failed": 0, "skipped": 0 },
    "flakyTests": []
  }
}
```

## Priority Assignment

| Priority | Scenario Contains |
|----------|-------------------|
| High | auth, security, permission, payment, error, fail, deny, invalid |
| Medium | create, update, delete, save, submit, core functionality |
| Low | display, show, view, UI, edge case, optional, polish |

## Category Extraction

Extract category from spec name prefix (before first hyphen):

- `oauth-authentication` → `oauth`
- `billing-management-ui` → `billing`
- `repository-linking` → `repository`

## Report Template (Coverage)

```markdown
# Spec Coverage Report

**Generated:** <date>
**Implementation Coverage:** X/Y scenarios (Z%)

## Summary

| Metric | Value |
|--------|-------|
| Specs Analyzed | 37 |
| Implemented | 150 (83%) |
| Partial | 15 (8%) |
| Unimplemented | 12 (7%) |
| Outdated (Drift) | 3 (2%) |

## Unimplemented Scenarios

| Spec | Scenario | Priority | Missing |
|------|----------|----------|---------|
| ... | ... | ... | ... |

## Spec Drift

| Spec | Scenario | Issue |
|------|----------|-------|
| ... | ... | ... |
```

## Report Template (Tests)

```markdown
# Test Quality Report

**Generated:** <date>
**Spec Coverage:** X/Y scenarios (Z%)

## Summary

| Metric | Value |
|--------|-------|
| Specs Analyzed | 37 |
| Covered | 142 (79%) |
| Partial | 10 (6%) |
| Missing | 28 (16%) |

## Test Health

| Suite | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| Unit | 145 | 0 | 3 |
| E2E | 42 | 0 | 0 |

## High Priority Gaps

| Spec | Scenario | Suggestion |
|------|----------|------------|
| ... | ... | ... |
```
