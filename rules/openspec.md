# OpenSpec Rules (when openspec/ folder exists)

These rules apply when the project uses OpenSpec for change management.

## Slash Commands

```bash
/openspec:proposal <description>   # Create new OpenSpec change proposal
/openspec:apply <change-id>        # Implement an approved OpenSpec change
/openspec:archive <change-id>      # Archive a deployed OpenSpec change
```

**Invalid commands - do NOT use:**
```bash
npx openspec new ...               # This command does NOT exist
npx openspec proposal ...          # Use slash command instead
```

**Validation command:**
```bash
npx openspec validate --specs --strict   # Validate all specs with strict mode
npx openspec validate <change-id>        # Validate specific change
```

## When to Use OpenSpec

- Planning complex features or architectural changes
- Breaking changes or new capabilities
- Features requiring cross-cutting changes
- Anything that benefits from upfront design and structured implementation

## Commit Timing

Use gitbutler skill for commits during OpenSpec workflows:

| Command | When to commit |
|---------|----------------|
| `/openspec:proposal` | After validation passes - commit all proposal files to new branch |
| `/openspec:apply` | After each logical unit of work (task or task group) - incremental commits |
| `/openspec:archive` | After archiving - commit the moved files and any spec updates |

This ensures atomic commits with clear history, not one large commit at the end.

## PR Creation

```bash
gh pr create --head <branch-name>  # Handles push automatically
```

Do NOT include "Generated with Claude Code" footer in PR descriptions or commit messages.

## Danger Zone

| Never Do | Consequence |
|----------|-------------|
| Mark manual testing tasks as complete | Only humans can verify manual tests |
| Mark tasks complete without doing them | False progress, bugs slip through |

## Reference

For detailed OpenSpec workflow, format, and conventions, see `openspec/AGENTS.md` in the project.
