# Agents System

This project uses a deterministic agent build system. Agent definitions in `.claude/agents-src/` generate markdown files in `.claude/agents/`.

## File Structure

```
.claude/
├── agents-src/           # Source definitions (edit these)
│   ├── _shared.yaml      # Shared includes, bundles, skill sets
│   └── *.yaml            # Individual agent definitions
├── agents/               # Generated output (do not edit)
│   └── *.md              # Built from agents-src/
└── scripts/
    └── build-agents.ts   # Build script
```

## When Modifying Rules

**If you add, remove, or rename a rule file in `.claude/rules/`:**

1. Update `_shared.yaml` includes section if the rule should be available to agents
2. Update rule bundles if the rule should be part of a bundle
3. Run `npm run build:agents` to regenerate agent files

**Example - adding a new rule:**

```yaml
# _shared.yaml
includes:
  newRule: "@/.claude/rules/new-rule.md"

ruleBundles:
  implementation:
    - $includes.newRule  # Add to relevant bundle(s)
```

## When Modifying Agents

**If you change an agent definition:**

1. Edit the YAML in `.claude/agents-src/`
2. Run `npm run build:agents`
3. Commit both the YAML source and generated `.md` file

**Never edit `.claude/agents/*.md` directly** - changes will be overwritten on next build.

## Build Command

```bash
npm run build:agents    # Regenerate all agents from YAML
```

## Rule Bundles

| Bundle | Purpose | Used By |
|--------|---------|---------|
| `implementation` | Full rules for coding tasks | task-implementer |
| `review` | Rules for code review | code-reviewer |
| `planning` | Architecture-focused rules | planner-researcher |
| `testing` | Minimal testing rules | tester |

## Keeping Bundles Current

When rules change significantly:
- Review which bundles should include/exclude the rule
- Consider if subagents need the rule baked in or can rely on main context
- Template rules (from `~/.claude/template/`) sync automatically but still need bundle updates
