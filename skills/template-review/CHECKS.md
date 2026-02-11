# Check Descriptions

Detailed documentation for each validation check.

## sync-config

Validates `~/.claude/config/sync-config.yaml` references.

### Rules Paths
- Every path in `always.rules[]` must exist in `template/rules/`
- Every path in `technologies.<name>.rules[]` must exist
- Every path in `tools.<name>.rules[]` must exist
- Directories must exist; files must be valid markdown

### Skills Paths
- Every path in `always.skills[]` must exist in `template/skills/`
- Skill directories must contain `SKILL.md`
- Nested paths like `tools/openspec/spec-review/` are valid

### Commands Paths
- Every path in `tools.<name>.commands[]` must exist in `template/commands/`
- Subdirectory paths like `openspec/proposal.md` are valid

### Requires References
- Every name in `detect.requires[]` must be a defined technology or tool
- Every name in `detect.requires_any[]` must be defined
- Tool requires can only reference other tools
- Technology requires can only reference other technologies

## skills

Validates skill directory structure.

### Directory Requirements
- Every directory containing files in `template/skills/` must have `SKILL.md`
- Category directories (authoring/, quality/, etc.) don't need SKILL.md
- Only leaf directories with implementation files need SKILL.md

### Frontmatter Requirements
- `name:` field must be present and non-empty
- `description:` field must be present and non-empty
- Description should be <300 characters (warning if exceeded)

### Supporting Files
- Files like `PATTERNS.md`, `REFERENCE.md` are allowed
- Shell scripts (`.sh`) should be executable
- Orphaned supporting files without `SKILL.md` are errors

## rules

Validates rule file structure.

### File Requirements
- All `.md` files in `template/rules/` must be valid markdown
- Files should have a top-level heading
- Empty files are warnings

### Organization
- Subdirectories should match sync-config categories
- Files referenced in sync-config must exist

## commands

Validates command file existence.

### File Requirements
- All paths in sync-config `commands[]` must exist
- Files must be markdown (`.md`)
- Subdirectory structure is preserved

## circular

Detects circular dependencies in requires chains.

### Detection Algorithm
1. Build dependency graph from all `detect.requires[]`
2. Traverse graph looking for cycles
3. Report first cycle found with full path

### Example Cycle
```
ERROR: Circular dependency detected:
  tool-a -> tool-b -> tool-c -> tool-a
```

## Severity Levels

| Level | Exit Code | Meaning |
|-------|-----------|---------|
| ERROR | 2 | Breaking issue, must fix |
| WARN | 1 | Non-breaking, review recommended |
| OK | 0 | Check passed |

### Error Examples
- Missing file referenced in sync-config
- Skill directory without SKILL.md
- Circular dependency
- Invalid requires reference

### Warning Examples
- Skill description >300 characters
- Empty rule file
- Unused rule file (not in sync-config)
