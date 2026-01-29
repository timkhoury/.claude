---
name: tools-updater
description: >
  Manage OpenSpec and beads tool updates. Check versions, analyze release notes,
  perform upgrades, and update Claude rules. Use when "update tools", "check beads",
  "upgrade openspec", "tool updates", or "check for updates".
---

# Tools Updater

Check and upgrade OpenSpec and beads tools with release note analysis.

## Critical Rules

1. **Check before upgrade** - Present findings first, never auto-upgrade
2. **Dry-run default** - Require explicit user confirmation
3. **Research breaking changes** - WebSearch for migration guides on major bumps
4. **Platform awareness** - Detect OS/arch for beads binary
5. **Backup rules** - Git snapshot before modifying any rule files

**See `REFERENCE.md` for API endpoints and rule locations.**
**See `KEYWORDS.md` for release note analysis patterns.**

## Usage

```bash
/tools-updater              # Full workflow (check + upgrade + rules)
/tools-updater check        # Version check only
/tools-updater upgrade      # Upgrade with confirmation
/tools-updater rules        # Analyze and update rules only
```

## Workflow

### Phase 1: Version Check

Run the check script:

```bash
~/.claude/skills/tools-updater/check-tools.sh --json
```

Compare installed vs latest versions. Exit early if all current.

### Phase 2: Fetch Release Notes

For tools with updates, fetch release notes via GitHub API:

| Tool | Endpoint |
|------|----------|
| OpenSpec | `https://api.github.com/repos/Fission-AI/OpenSpec/releases` |
| beads | `https://api.github.com/repos/steveyegge/beads/releases/latest` |

Use `WebFetch` with prompt to extract version, date, and changelog.

### Phase 3: Analyze Changes

Match release notes against `KEYWORDS.md` patterns. Categorize:

| Category | Action |
|----------|--------|
| Breaking changes | Warn, research migration, update rules |
| New features | Consider rule enhancement |
| Command changes | Update command references in rules |
| Bug fixes | Informational only |

Present summary with `AskUserQuestion`:
- Which tools to upgrade
- Options: All / Select individually / Skip

### Phase 4: Perform Upgrades

**OpenSpec:**
```bash
npm install -g @fission-ai/openspec@latest
openspec --version  # Verify
```

**beads:**
1. Detect platform (see `REFERENCE.md`)
2. Download from GitHub releases
3. Extract and install to `~/.local/bin/bd`
4. Verify: `bd version`

### Phase 5: Update Rules

For breaking changes or significant features:

1. Read relevant rule files (see `REFERENCE.md`)
2. Identify sections needing updates based on release notes
3. Generate proposed changes with diff preview
4. Apply after user confirmation
5. If in project context, run `/sync` to propagate

## After Completion

Record this review:

```bash
~/.claude/template/scripts/review-tracker.sh record tools-updater
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| Auto-upgrade without confirmation | Breaking changes slip through |
| Skip version verification | Upgrade may have failed silently |
| Modify rules without backup | Can't recover from bad edits |
| Ignore breaking change warnings | Rules become outdated |
| Skip `/sync` after rule changes | Projects stay out of sync |
