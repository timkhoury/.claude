# Release Note Keywords

Patterns for analyzing release notes and categorizing changes.

## Breaking Changes

Require migration research and rule updates.

| Pattern | Meaning |
|---------|---------|
| `BREAKING` | Explicit breaking change |
| `BREAKING CHANGE` | Conventional commit format |
| `removed` | Feature/option removed |
| `deprecated` | Feature marked for removal |
| `migration` | Requires migration steps |
| `upgrade guide` | Has upgrade instructions |
| `no longer` | Behavior changed |
| `renamed` | Command or option renamed |
| `replaced` | Old approach replaced |

## New Features

Consider for rule enhancement.

| Pattern | Meaning |
|---------|---------|
| `feat:` | Conventional commit feature |
| `added` | New capability |
| `new command` | New CLI command |
| `new option` | New flag/option |
| `now supports` | Extended capability |
| `introduces` | New concept |

## Command Changes

Update command references in rules.

| Pattern | Meaning |
|---------|---------|
| `renamed` | Command name changed |
| `flag changed` | Option syntax changed |
| `now requires` | New required argument |
| `default changed` | Default behavior changed |
| `moved to` | Command relocated |

## Bug Fixes

Informational only, no rule changes needed.

| Pattern | Meaning |
|---------|---------|
| `fix:` | Conventional commit fix |
| `fixed` | Bug resolved |
| `resolved` | Issue addressed |
| `corrected` | Error corrected |
| `patched` | Security/stability patch |

## Tool-Specific Patterns

### OpenSpec

| Pattern | Category | Action |
|---------|----------|--------|
| `artifact` | Feature | Check skill updates |
| `validate` | Feature | Check validation rules |
| `archive` | Feature | Check archive workflow |
| `spec format` | Breaking | Update spec examples |

## Analysis Workflow

1. Fetch release notes
2. Scan for breaking change patterns first
3. If breaking, WebSearch for "{tool} {version} migration guide"
4. Categorize remaining changes
5. Generate summary for user
6. Identify rule files that need updates
