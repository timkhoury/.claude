---
name: quality:spec-quality
description: >
  Analyze OpenSpec structure for organizational issues. Detects merge/split
  candidates, duplicates, naming inconsistencies, and boundary overlaps.
  Use when specs feel disorganized or after major changes.
model: claude-opus-4-5
allowed-tools: [Read, Glob, Grep, Bash, Task, Write, TodoWrite, AskUserQuestion]
---

# Spec Quality Analysis

Analyze the structure and organization of OpenSpec specifications. Detects structural issues and suggests refactoring actions to keep specs maintainable.

## What This Detects

| Issue Type | Detection Criteria | Suggested Action |
|------------|-------------------|------------------|
| **Small specs** | <3 requirements | Merge into parent spec |
| **Large specs** | >12 requirements | Split into focused specs |
| **Merge candidates** | >3 cross-references to same spec | Consolidate |
| **Entity clusters** | 2+ specs with same prefix | Create hierarchy |
| **Duplicate requirements** | >80% text similarity | Deduplicate |
| **Orphan references** | Reference to non-existent spec | Fix or remove |
| **Empty requirements** | Requirement with 0 scenarios | Add scenarios or remove |
| **Naming inconsistencies** | Mixed naming patterns | Standardize names |
| **Boundary overlaps** | Same WHEN conditions in multiple specs | Clarify ownership |
| **Contradictions** | Same WHEN, different THEN | Resolve conflict |

## Output Files

| File | Purpose |
|------|---------|
| `.spec-quality/index.json` | Spec index with metrics |
| `.spec-quality/issues.json` | Detected issues |
| `.spec-quality/results.json` | Aggregated analysis |
| `SPEC_QUALITY_REPORT.md` | Human-readable report with actions |

**Note:** Add `.spec-quality/` to `.gitignore` before running.

## Critical Rule: Block on Active Changes

**BEFORE running any analysis, check for active OpenSpec changes:**

```bash
npx openspec list
```

If any active changes exist:
1. **Report them** in the output
2. **Mark affected specs as BLOCKED** - do not suggest refactoring
3. **Continue analysis** for non-affected specs only

**Why:** Refactoring specs that have active changes creates merge conflicts and invalidates in-progress work.

### Blocked Spec Handling

When a spec is affected by an active change:

```json
{
  "spec": "organization-management",
  "blockedBy": "add-org-settings",
  "status": "blocked",
  "issues": []  // Issues detected but marked as blocked
}
```

In the report:

```markdown
## Blocked Specs (Active Changes)

| Spec | Blocked By | Change Status |
|------|------------|---------------|
| organization-management | add-org-settings | in-progress |
| billing-management-ui | stripe-webhooks-v2 | approved |

**Action:** Complete and archive these changes before refactoring affected specs.
```

## Before Starting

### 1. Check for Active Changes (REQUIRED)

```bash
npx openspec list
```

Parse output to identify:
- Active change IDs
- Which specs each change affects (check `openspec/changes/<id>/specs/`)

Build a blocked specs list.

### 2. Create Output Directory

```bash
mkdir -p .spec-quality
```

### 3. Enumerate All Specs

```bash
ls openspec/specs/*/spec.md | wc -l
```

## Analysis Phases

### Phase 1: Build Spec Index

For each spec, extract:

```json
{
  "spec": "oauth-authentication",
  "requirements": 11,
  "scenarios": 32,
  "size": "large",
  "entities": ["users", "sessions", "oauth_tokens"],
  "tables": ["auth.users", "auth.identities"],
  "routes": ["/auth/callback", "/auth/sign-in"],
  "crossRefs": ["user-profiles", "organization-context"],
  "prefix": "oauth",
  "lastModified": "2026-01-15"
}
```

**Size classification:**
- `tiny`: 1 requirement
- `small`: 2-3 requirements
- `medium`: 4-8 requirements
- `large`: 9-12 requirements
- `huge`: >12 requirements

### Phase 2: Detect Issues

Run detection algorithms on the index.

### Phase 3: Generate Recommendations

Prioritize and group issues into actionable refactoring tasks.

## Detection Algorithms

### 1. Small Spec Detection (Merge Candidates)

```
FOR each spec WHERE requirements < 3:
  IF spec has prefix matching another spec:
    SUGGEST merge into parent spec
  ELSE IF spec has >2 cross-refs to single other spec:
    SUGGEST merge into that spec
  ELSE:
    FLAG as standalone small spec (may be intentional)
```

**Output:**
```json
{
  "type": "merge_candidate",
  "spec": "org-settings",
  "reason": "small_spec",
  "requirements": 2,
  "suggestedTarget": "organization-management",
  "confidence": "high"
}
```

### 2. Large Spec Detection (Split Candidates)

```
FOR each spec WHERE requirements > 12:
  ANALYZE requirement groupings by:
    - Entity focus (different tables/routes)
    - Functional area (CRUD vs display vs validation)
    - User role (admin vs member)
  SUGGEST split based on natural groupings
```

**Output:**
```json
{
  "type": "split_candidate",
  "spec": "billing-management-ui",
  "reason": "large_spec",
  "requirements": 15,
  "suggestedSplit": [
    { "name": "billing-display", "requirements": ["Billing page display", "Invoice list"] },
    { "name": "billing-actions", "requirements": ["Update payment", "Cancel subscription"] }
  ],
  "confidence": "medium"
}
```

### 3. Cross-Reference Cluster Detection

```
BUILD reference graph: spec -> [referenced specs]
FIND clusters with high interconnection (>3 refs between pair)
SUGGEST consolidation for tightly coupled specs
```

**Output:**
```json
{
  "type": "cluster",
  "specs": ["organization-management", "organization-context", "organization-settings-ui"],
  "totalCrossRefs": 12,
  "reason": "tightly_coupled",
  "suggestion": "Consider consolidating into single 'organizations' spec or creating clear hierarchy"
}
```

### 4. Entity Prefix Analysis

```
EXTRACT prefixes from spec names (before first hyphen)
GROUP specs by prefix
FOR each prefix with 2+ specs:
  CHECK if parent spec exists
  IF no parent: SUGGEST creating hierarchy
  IF specs overlap: SUGGEST consolidation
```

**Output:**
```json
{
  "type": "prefix_cluster",
  "prefix": "github",
  "specs": ["github-app-integration", "github-oauth-token-management", "github-installation-realtime-detection"],
  "hasParent": false,
  "suggestion": "Create 'github' parent spec or consolidate related functionality"
}
```

### 5. Duplicate Requirement Detection

```
FOR each requirement text:
  NORMALIZE text (lowercase, remove punctuation)
  COMPUTE similarity with all other requirements
  IF similarity > 80%:
    FLAG as duplicate
```

Use Levenshtein distance or token-based similarity.

**Output:**
```json
{
  "type": "duplicate_requirement",
  "requirement": "Password must be at least 8 characters",
  "specs": ["auth-password", "user-settings"],
  "similarity": 0.95,
  "suggestion": "Keep in auth-password, reference from user-settings"
}
```

### 6. Orphan Reference Detection

```
EXTRACT all spec references from spec files
FOR each reference:
  CHECK if referenced spec exists
  IF not exists: FLAG as orphan
```

**Output:**
```json
{
  "type": "orphan_reference",
  "spec": "billing-management-ui",
  "reference": "payment-processing",
  "location": "spec.md:45",
  "suggestion": "Create payment-processing spec or remove reference"
}
```

### 7. Empty Requirement Detection

```
FOR each requirement:
  COUNT scenarios
  IF scenarios == 0:
    FLAG as empty requirement
```

**Output:**
```json
{
  "type": "empty_requirement",
  "spec": "repository-linking",
  "requirement": "Repository Permissions",
  "scenarios": 0,
  "suggestion": "Add scenarios or remove requirement"
}
```

### 8. Boundary Overlap Detection

```
EXTRACT WHEN conditions from all scenarios
NORMALIZE conditions
GROUP scenarios by WHEN condition
FOR each WHEN with scenarios in multiple specs:
  FLAG as boundary overlap
```

**Output:**
```json
{
  "type": "boundary_overlap",
  "condition": "WHEN user is on the dashboard",
  "specs": ["dashboard-view", "activity-page"],
  "scenarios": ["Dashboard shows activity", "Activity feed displays"],
  "suggestion": "Clarify which spec owns dashboard display vs activity"
}
```

### 9. Contradiction Detection

```
FOR each pair of scenarios with similar WHEN:
  COMPARE THEN conditions
  IF THEN conditions conflict:
    FLAG as contradiction
```

**Output:**
```json
{
  "type": "contradiction",
  "condition": "WHEN user has no organizations",
  "specA": { "spec": "organization-creation", "then": "redirect to create org" },
  "specB": { "spec": "dashboard-view", "then": "show empty state" },
  "suggestion": "Resolve which behavior is correct and update specs"
}
```

### 10. Naming Inconsistency Detection

```
ANALYZE spec naming patterns:
  - entity-action (repository-linking)
  - entity-context (organization-context)
  - feature-ui (billing-management-ui)
  - compound (github-app-user-auth)

FLAG specs that don't follow dominant pattern
SUGGEST consistent naming
```

**Output:**
```json
{
  "type": "naming_inconsistency",
  "spec": "oauth-authentication",
  "currentPattern": "feature-noun",
  "dominantPattern": "entity-action",
  "suggestion": "Rename to auth-oauth for consistency"
}
```

## Execution Workflow

### Step 1: Initialize

```bash
mkdir -p .spec-quality
ls openspec/specs/*/spec.md | wc -l  # Count specs
```

### Step 2: Build Index (Subtask)

Spawn subtask to build spec index:

```
Task tool call:
  description: "Build spec index"
  subagent_type: "Explore"
  model: "sonnet"
  prompt: |
    Build an index of all OpenSpec specs.

    For each spec in openspec/specs/*/spec.md:
    1. Count requirements (### Requirement:)
    2. Count scenarios (#### Scenario:)
    3. Extract entity references (table names, route paths)
    4. Extract cross-references to other specs
    5. Extract the spec name prefix (before first hyphen)

    Return JSON array of spec index entries.
```

### Step 3: Run Detections (Subtasks)

Spawn subtasks for each detection algorithm. Can run in parallel:

```
Task: Detect small/large specs (from index)
Task: Detect cross-reference clusters (from index)
Task: Detect duplicate requirements (read specs)
Task: Detect boundary overlaps (read specs)
```

### Step 4: Aggregate Results

Combine all detection results into `.spec-quality/results.json`.

### Step 5: Generate Report

Create `SPEC_QUALITY_REPORT.md` with prioritized actions.

## Results Format

Location: `.spec-quality/results.json`

```json
{
  "generatedAt": "2026-01-20T16:00:00Z",
  "activeChanges": [
    {
      "id": "add-org-settings",
      "status": "in-progress",
      "affectedSpecs": ["organization-management", "organization-settings-ui"]
    }
  ],
  "blockedSpecs": ["organization-management", "organization-settings-ui"],
  "summary": {
    "specsAnalyzed": 37,
    "specsBlocked": 2,
    "totalRequirements": 250,
    "totalScenarios": 850,
    "issuesFound": 15,
    "issuesBlocked": 3,
    "highPriority": 3,
    "mediumPriority": 7,
    "lowPriority": 5
  },
  "sizeDistribution": {
    "tiny": 2,
    "small": 8,
    "medium": 20,
    "large": 5,
    "huge": 2
  },
  "issues": [
    {
      "id": "issue-001",
      "type": "merge_candidate",
      "priority": "high",
      "spec": "org-settings",
      "blocked": false,
      "details": { ... },
      "suggestion": "Merge into organization-management"
    },
    {
      "id": "issue-002",
      "type": "split_candidate",
      "priority": "medium",
      "spec": "organization-management",
      "blocked": true,
      "blockedBy": "add-org-settings",
      "details": { ... },
      "suggestion": "[BLOCKED] Wait for add-org-settings to complete"
    }
  ],
  "clusters": [
    {
      "prefix": "organization",
      "specs": ["organization-management", "organization-context", "organization-settings-ui"],
      "recommendation": "Consider consolidation",
      "blocked": true,
      "blockedBy": ["add-org-settings"]
    }
  ],
  "index": [ ... ]
}
```

## Report Format

Location: `SPEC_QUALITY_REPORT.md`

```markdown
# Spec Quality Report

**Generated:** 2026-01-20
**Specs Analyzed:** 37
**Issues Found:** 15 (3 high, 7 medium, 5 low)

## Summary

| Size | Count |
|------|-------|
| Tiny (1 req) | 2 |
| Small (2-3 req) | 8 |
| Medium (4-8 req) | 20 |
| Large (9-12 req) | 5 |
| Huge (>12 req) | 2 |

## High Priority Issues

### 1. Merge Candidate: org-settings → organization-management

**Reason:** Small spec (2 requirements) with same entity prefix
**Action:** Merge requirements into organization-management
**Confidence:** High

### 2. Split Candidate: billing-management-ui

**Reason:** Large spec (15 requirements) with distinct functional areas
**Suggested Split:**
- `billing-display` - Billing page display, Invoice list, Usage display
- `billing-actions` - Update payment, Cancel subscription, Retry payment

**Confidence:** Medium

### 3. Contradiction: User with no organizations

**Specs:** organization-creation vs dashboard-view
**Conflict:**
- organization-creation says: "redirect to create org"
- dashboard-view says: "show empty state"
**Action:** Determine correct behavior and update one spec

## Medium Priority Issues

### 4. Prefix Cluster: github-*

**Specs:** github-app-integration, github-oauth-token-management, github-installation-realtime-detection, github-repository-rename-webhook
**No parent spec exists**
**Suggestion:** Create `github` parent spec or consolidate related functionality

### 5. Duplicate Requirement

**Requirement:** "User must be authenticated"
**Found in:** auth-protection, organization-context, dashboard-view
**Action:** Keep in auth-protection, reference from others

...

## Spec Index

| Spec | Reqs | Scenarios | Size | Cross-Refs | Issues |
|------|------|-----------|------|------------|--------|
| oauth-authentication | 11 | 32 | large | 3 | 0 |
| organization-management | 8 | 24 | medium | 5 | 1 |
| org-settings | 2 | 6 | small | 2 | 1 |
| billing-management-ui | 15 | 47 | huge | 4 | 1 |

## Cluster Map

```
organization-*
├── organization-management (8 reqs)
├── organization-context (4 reqs)
├── organization-creation (7 reqs)
└── organization-settings-ui (6 reqs)
    └── [MERGE] org-settings (2 reqs)

github-*
├── github-app-integration (5 reqs)
├── github-app-user-auth (3 reqs)
├── github-installation-realtime-detection (4 reqs)
├── github-oauth-token-management (3 reqs)
└── github-repository-rename-webhook (2 reqs)
    └── [CONSIDER] No parent spec
```

## Refactoring Checklist

- [ ] Merge org-settings into organization-management
- [ ] Split billing-management-ui into billing-display + billing-actions
- [ ] Resolve contradiction: organization-creation vs dashboard-view
- [ ] Create github parent spec or consolidate
- [ ] Deduplicate "User must be authenticated" requirement

---
*Source: .spec-quality/results.json*
```

## Thresholds (Configurable)

| Threshold | Default | Description |
|-----------|---------|-------------|
| `SMALL_SPEC_MAX` | 3 | Max requirements to be "small" |
| `LARGE_SPEC_MIN` | 12 | Min requirements to be "large" |
| `CLUSTER_REF_MIN` | 3 | Min cross-refs to form cluster |
| `DUPLICATE_SIMILARITY` | 0.80 | Min similarity for duplicate |
| `PREFIX_GROUP_MIN` | 2 | Min specs to form prefix group |

## Refactoring Actions

After reviewing the report, use OpenSpec commands to refactor:

### Merge Specs

```bash
# 1. Create change to merge
/openspec:proposal "Merge org-settings into organization-management"

# 2. In the change, update organization-management/spec.md to include
#    requirements from org-settings

# 3. Delete org-settings spec (in the change)

# 4. Apply and archive
/openspec:apply <change-id>
/openspec:archive <change-id>
```

### Split Specs

```bash
# 1. Create change to split
/openspec:proposal "Split billing-management-ui into focused specs"

# 2. Create new spec files in the change
# 3. Move requirements to appropriate specs
# 4. Delete original spec

# 5. Apply and archive
```

### Rename Specs

```bash
# Renaming requires creating new spec and migrating
/openspec:proposal "Rename oauth-authentication to auth-oauth"
```

## Quick Commands Reference

```bash
# === Analysis ===
ls openspec/specs/*/spec.md | wc -l           # Count specs
rg "^### Requirement:" openspec/specs | wc -l  # Count requirements
rg "^#### Scenario:" openspec/specs | wc -l    # Count scenarios

# === Size Analysis ===
for f in openspec/specs/*/spec.md; do
  count=$(rg -c "^### Requirement:" "$f" 2>/dev/null || echo 0)
  echo "$count $(dirname $f | xargs basename)"
done | sort -rn

# === Cross-Reference Search ===
rg "See \[" openspec/specs                     # Find cross-refs
rg "\[.*\]\(.*spec" openspec/specs             # Find spec links

# === Duplicate Detection ===
rg "^### Requirement:" openspec/specs --no-filename | sort | uniq -d

# === Prefix Groups ===
ls openspec/specs | cut -d'-' -f1 | sort | uniq -c | sort -rn
```

## When to Run This Skill

- **After major changes** - New features may create overlaps
- **Quarterly maintenance** - Specs drift over time
- **Before audits** - Clean up before coverage analysis
- **Team onboarding** - Ensure specs are understandable

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| **Skip active changes check** | Refactoring conflicts with in-progress work |
| Auto-refactor without review | May lose important distinctions |
| Refactor specs with active changes | Creates merge conflicts, invalidates work |
| Delete specs without checking implementations | Orphans code |
| Ignore contradictions | Specs become unreliable |

**CRITICAL: Always check for active changes FIRST:**

```bash
npx openspec list
```

If ANY active changes exist:
1. Identify which specs they affect
2. Mark those specs as BLOCKED in the analysis
3. Do NOT suggest refactoring blocked specs
4. Wait until changes are deployed and archived before refactoring
