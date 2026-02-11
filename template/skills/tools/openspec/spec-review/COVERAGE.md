# Coverage Analysis

Implementation coverage analysis - maps OpenSpec scenarios to code.

## Evidence Search Locations

| Requirement Type | Search Locations |
|------------------|------------------|
| Server Actions | `src/server/actions/*.ts` |
| UI Components | `src/components/**/*.tsx`, `src/app/(application)/**/*.tsx` |
| Page Routes | `src/app/(application)/**/page.tsx` |
| API Routes | `src/app/api/**/*.ts` |
| Database Schema | `supabase/migrations/*.sql` |
| RLS Policies | `supabase/migrations/*.sql` |
| Hooks | `src/hooks/**/*.ts` |
| Utilities | `src/lib/**/*.ts` |

## Status Definitions

| Status | Meaning | Action |
|--------|---------|--------|
| **Implemented** | All WHEN/THEN conditions have code | None |
| **Partial** | Some conditions implemented | Complete missing |
| **Unimplemented** | No implementation found | Implement |
| **Outdated** | Code differs from spec | Update spec or fix code |

## Subtask Prompt Template

Use this prompt when spawning subtasks to analyze a batch of specs. Each subtask receives 3-4 specs and writes results to disk.

```
Analyze implementation coverage for these specs: <spec-1>, <spec-2>, <spec-3>, <spec-4>

## Instructions

For EACH spec in the batch:

1. Read `openspec/specs/<spec-name>/spec.md`
2. Extract ALL scenarios (lines starting with `#### Scenario:`)
3. For EACH scenario:
   a. Extract the scenario name and WHEN/THEN conditions
   b. Search for implementation evidence:
      - Server actions: `src/server/actions/*.ts`
      - Components: `src/components/**/*.tsx`, `src/app/**/*.tsx`
      - API routes: `src/app/api/**/*.ts`
      - Database: `supabase/migrations/*.sql`
      - Hooks/utilities: `src/lib/**/*.ts`, `src/hooks/**/*.ts`
   c. Verify the WHEN conditions trigger the expected behavior
   d. Verify the THEN outcomes are produced
4. Assign status to each scenario:
   - "implemented" = Code exists that fulfills the scenario
   - "partial" = Some conditions implemented, others missing
   - "unimplemented" = No implementation found
   - "outdated" = Implementation differs from spec

## Output

For each spec, write a JSON file to `.spec-review/coverage/specs/<spec-name>.json`:

{
  "spec": "<spec-name>",
  "analyzedAt": "<ISO timestamp>",
  "scenarios": {
    "total": <number>,
    "implemented": <number>,
    "partial": <number>,
    "unimplemented": <number>,
    "outdated": <number>
  },
  "details": [
    {
      "scenario": "<scenario name>",
      "status": "implemented|partial|unimplemented|outdated",
      "evidence": [
        { "file": "<path>", "line": <number>, "description": "<what it implements>" }
      ],
      "missingConditions": ["<WHEN/THEN condition not found>"],
      "notes": "<explanation if partial/outdated>"
    }
  ]
}

After writing all JSON files, return ONLY a one-line summary per spec:
Done: <spec-1> (X/Y impl), <spec-2> (X/Y impl), <spec-3> (X/Y impl)

Be thorough. Check server actions, components, routes, and database migrations.
```

## Aggregation Steps

After all specs analyzed:

1. Read all `.spec-review/coverage/specs/*.json` files
2. Sum counts across all specs
3. Build `byCategory` from spec name prefixes
4. Collect unimplemented scenarios into `gaps` with priority
5. Collect outdated scenarios into `drift`
6. Write `.spec-review/coverage/results.json`

## Relationship to Test Analysis

| Analysis | Question | Output |
|----------|----------|--------|
| Coverage | Is the spec **implemented**? | Implementation evidence |
| Tests | Is the spec **tested**? | Test coverage |

Run both for complete picture: verify specs are implemented, then verify implementations are tested.
