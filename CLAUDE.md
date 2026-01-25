# Global Claude Code Preferences

Personal preferences applied across all projects.

## Git Workflow

- **Use GitButler** when available - invoke `gitbutler` skill before git operations
- **Conventional commits** - `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `perf:`
- **Single-line commit messages** - no body, no footers, no Co-Authored-By
- **Never push automatically** - only push when explicitly requested or at session end

## Code Style

- **No emojis** in code, commits, or UI copy unless explicitly requested
- **Professional tone** - no exclamation marks, no marketing speak
- **Minimal changes** - only modify what's directly requested, avoid scope creep

## Communication

- **Concise responses** - get to the point, avoid filler
- **No time estimates** - don't predict how long tasks will take
- **Cite file:line** when referencing code locations

## Session Management

- **Track multi-step work** - use appropriate tracking (beads, TodoWrite, or project-specific)
- **Land the plane** - ensure all work is committed and pushed before ending
- **Document remaining work** - don't leave loose ends undocumented

## Rules vs Skills

- **Rules** are always loaded - use for patterns, conventions, project structure
- **Skills** are on-demand - use for workflows, external tools, step-by-step processes
- Don't duplicate rule content in skills - it's redundant overhead

## Danger Zone

**Development Style:**
- Never propose changes to code you haven't read - wrong assumptions, broken fixes
- Never add features beyond what was asked - scope creep, wasted effort
- Never create helpers/abstractions for one-time operations - unnecessary complexity
- Never add error handling for scenarios that can't happen - code bloat, confusion
- Never design for hypothetical future requirements - over-engineering
- Never add docstrings/comments to unchanged code - noise, not signal

**Over-Engineering Prevention:**
- Only make changes that are directly requested or clearly necessary
- A bug fix doesn't need surrounding code cleaned up
- A simple feature doesn't need extra configurability
- Trust internal code and framework guarantees
- Only validate at system boundaries (user input, external APIs)
- Three similar lines of code is better than a premature abstraction

**Code Exploration Requirement:**
- ALWAYS read and understand relevant files before proposing code edits
- Do not speculate about code you have not inspected
- If the user references a specific file/path, open and inspect it first
- Thoroughly review style, conventions, and abstractions before implementing
