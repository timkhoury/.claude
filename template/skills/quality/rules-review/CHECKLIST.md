# Rules Review Checklist

## Tech Rules Analysis

For each file in `.claude/rules/tech/`:

1. **Title/tagline** - Does it mention only one technology?
2. **Code examples** - Do they import from multiple frameworks?
3. **Decision tables** - Do they compare "use X vs use Y" across technologies?
4. **Anti-patterns** - Do they reference other technologies?

## Project Rules Analysis

For each file in `.claude/rules/project/`:

1. **Is it project-specific?** (architecture, config, team conventions)
2. **Is it a workflow?** → Candidate for skill instead
3. **Is it setup instructions?** → Should be a skill

## Rules vs Skills Decision

For each rule file, ask:

1. **Is this needed for typical coding tasks?** If no → skill candidate
2. **Is this a workflow with steps?** If yes → should be a skill
3. **Does it reference external tools/commands primarily?** If yes → likely skill
4. **Would an agent need this for most implementations?** If no → skill candidate

### Decision Table

| Factor | Rule (Always Loaded) | Skill (On-Demand) |
|--------|---------------------|-------------------|
| **Frequency** | Needed for most tasks | Needed occasionally |
| **Content type** | Patterns, conventions | Workflows, step-by-step |
| **Context** | Shapes how code is written | Guides specific operations |
| **Size** | Any size if always relevant | Large files waste context |

### Common Patterns

| Pattern | Likely Should Be |
|---------|------------------|
| Setup instructions | Skill |
| Git subtree/submodule workflows | Skill |
| Troubleshooting guides (large) | Skill |
| External service workflows | Skill |
| Code conventions | Rule |
| Architecture decisions | Rule |

## Agent Config Review

Check `.claude/agents-src/_project.yaml`:

```bash
# Find non-project includes
grep -E '\$includes\.(tech|patterns|meta|testing)\.' .claude/agents-src/_project.yaml
```

| Pattern | Likely Intentional | Likely Mistake |
|---------|-------------------|----------------|
| Adding rules template lacks | Project needs extra context | Should update template |
| Duplicating template includes | Redundant, remove | - |

## After Completion

```bash
.claude/scripts/systems-tracker.sh record rules-review
```
