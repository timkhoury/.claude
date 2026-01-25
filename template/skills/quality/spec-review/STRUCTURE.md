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
npx openspec list
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

### Small Spec Detection

```
FOR each spec WHERE requirements < 3:
  IF spec prefix matches another spec:
    SUGGEST merge into parent
  ELSE IF >2 cross-refs to single spec:
    SUGGEST merge into that spec
  ELSE:
    FLAG as standalone (may be intentional)
```

### Large Spec Detection

```
FOR each spec WHERE requirements > 12:
  ANALYZE groupings by:
    - Entity focus (different tables/routes)
    - Functional area (CRUD vs display vs validation)
    - User role (admin vs member)
  SUGGEST split based on natural groupings
```

### Cross-Reference Cluster Detection

```
BUILD reference graph: spec -> [referenced specs]
FIND clusters with >3 refs between pair
SUGGEST consolidation for tightly coupled specs
```

### Entity Prefix Analysis

```
EXTRACT prefixes from spec names (before first hyphen)
GROUP specs by prefix
FOR each prefix with 2+ specs:
  CHECK if parent spec exists
  IF no parent: SUGGEST creating hierarchy
```

### Duplicate Requirement Detection

```
FOR each requirement text:
  NORMALIZE (lowercase, remove punctuation)
  COMPUTE similarity with all others
  IF similarity > 80%: FLAG as duplicate
```

### Boundary Overlap Detection

```
EXTRACT WHEN conditions from all scenarios
GROUP by normalized WHEN
FOR each WHEN in multiple specs:
  FLAG as boundary overlap
```

### Contradiction Detection

```
FOR each pair with similar WHEN:
  COMPARE THEN conditions
  IF THEN conditions conflict:
    FLAG as contradiction
```

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

## Quick Commands

```bash
# Count specs
ls openspec/specs/*/spec.md | wc -l

# Count requirements
rg "^### Requirement:" openspec/specs | wc -l

# Find cross-references
rg "See \[" openspec/specs

# Prefix groups
ls openspec/specs | cut -d'-' -f1 | sort | uniq -c | sort -rn
```
