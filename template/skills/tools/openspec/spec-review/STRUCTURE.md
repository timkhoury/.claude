# Structure Analysis

Spec organization analysis - detects structural issues and suggests refactoring.

## Issue Types

| Issue Type | Detection Criteria | Suggested Action |
|------------|-------------------|------------------|
| Small specs | <3 requirements | Merge into parent |
| Large specs | >12 requirements | Split into focused specs |
| Merge candidates | >3 cross-refs to same spec | Consolidate |
| Entity clusters | 2+ specs with same prefix | Create hierarchy |
| Duplicate requirements | >80% text similarity | Deduplicate |
| Orphan references | Reference to non-existent spec | Fix or remove |
| Empty requirements | Requirement with 0 scenarios | Add scenarios or remove |
| Naming inconsistencies | Mixed naming patterns | Standardize |
| Boundary overlaps | Same WHEN in multiple specs | Clarify ownership |
| Contradictions | Same WHEN, different THEN | Resolve conflict |

## Active Changes Check (REQUIRED)

**Before analysis, check for active OpenSpec changes:**

```bash
./review-specs.sh changes
```

If active changes exist:
1. Identify affected specs (check `openspec/changes/<id>/specs/`)
2. Mark those specs as BLOCKED
3. Continue analysis for non-affected specs only

**Why:** Refactoring specs with active changes creates merge conflicts.

## Size Classification

| Size | Requirements |
|------|-------------|
| tiny | 1 |
| small | 2-3 |
| medium | 4-8 |
| large | 9-12 |
| huge | >12 |

## Detection Algorithms

### Scripted Detections (deterministic)

Run all detections at once, or specific ones:

```bash
./review-specs.sh detect              # All detections
./review-specs.sh detect --small      # Specs with <3 requirements
./review-specs.sh detect --large      # Specs with >12 requirements
./review-specs.sh detect --orphan-refs      # Cross-refs to non-existent specs
./review-specs.sh detect --empty-reqs       # Requirements with 0 scenarios
./review-specs.sh detect --crossref-clusters  # Specs with >3 cross-refs to same target
./review-specs.sh detect --small --json     # JSON output
```

### AI-Analyzed Detections (require judgment)

These require semantic understanding and cannot be scripted:

| Detection | Why AI | What to look for |
|-----------|--------|-----------------|
| Duplicate requirements | Semantic similarity (>80% text match) | Normalize, compare requirement text |
| Boundary overlaps | Intent understanding of WHEN conditions | Same WHEN in multiple specs |
| Contradictions | Comparing THEN outcomes for same WHEN | Conflicting behavior |
| Split/merge suggestions | Domain knowledge for grouping | Entity focus, functional area, user role |

### Entity Prefix Analysis

Uses `./review-specs.sh structure` (prefix groups section) combined with AI judgment for hierarchy suggestions.

## Spec Index Entry

Build this for each spec:

```json
{
  "spec": "oauth-authentication",
  "requirements": 11,
  "scenarios": 32,
  "size": "large",
  "entities": ["users", "sessions"],
  "tables": ["auth.users"],
  "routes": ["/auth/callback"],
  "crossRefs": ["user-profiles"],
  "prefix": "oauth",
  "blocked": false,
  "blockedBy": null
}
```

## Results Format

```json
{
  "generatedAt": "<ISO timestamp>",
  "activeChanges": [{ "id": "...", "status": "...", "affectedSpecs": ["..."] }],
  "blockedSpecs": ["..."],
  "summary": {
    "specsAnalyzed": 37,
    "specsBlocked": 2,
    "issuesFound": 15,
    "highPriority": 3,
    "mediumPriority": 7,
    "lowPriority": 5
  },
  "sizeDistribution": { "tiny": 2, "small": 8, "medium": 20, "large": 5, "huge": 2 },
  "issues": [
    {
      "id": "issue-001",
      "type": "merge_candidate",
      "priority": "high",
      "spec": "org-settings",
      "blocked": false,
      "details": { "requirements": 2, "suggestedTarget": "organization-management" },
      "suggestion": "Merge into organization-management"
    }
  ],
  "clusters": [{ "prefix": "organization", "specs": ["..."], "hasParent": false }]
}
```

## Report Template

```markdown
# Spec Quality Report

**Generated:** <date>
**Issues Found:** N (H high, M medium, L low)

## Blocked Specs (Active Changes)

| Spec | Blocked By | Status |
|------|------------|--------|
| ... | ... | ... |

## Size Distribution

| Size | Count |
|------|-------|
| Tiny | 2 |
| Small | 8 |
| Medium | 20 |
| Large | 5 |
| Huge | 2 |

## High Priority Issues

### 1. Merge Candidate: org-settings -> organization-management
**Reason:** Small spec (2 requirements) with same entity prefix
**Action:** Merge requirements

## Refactoring Checklist

- [ ] Issue 1 action
- [ ] Issue 2 action
```

