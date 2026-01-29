# Tools Updater Reference

## API Endpoints

### OpenSpec

| Purpose | URL |
|---------|-----|
| npm version | `npm info @fission-ai/openspec version` |
| GitHub releases | `https://api.github.com/repos/Fission-AI/OpenSpec/releases` |
| Release notes | `https://github.com/Fission-AI/OpenSpec/releases/tag/v{version}` |

### beads

| Purpose | URL |
|---------|-----|
| GitHub releases | `https://api.github.com/repos/steveyegge/beads/releases/latest` |
| Release notes | `https://github.com/steveyegge/beads/releases/tag/v{version}` |

## Platform Mapping (beads binary)

| OS (`uname -s`) | Arch (`uname -m`) | Asset Pattern |
|-----------------|-------------------|---------------|
| Darwin | arm64 | `beads_*_darwin_arm64.tar.gz` |
| Darwin | x86_64 | `beads_*_darwin_amd64.tar.gz` |
| Linux | aarch64 | `beads_*_linux_arm64.tar.gz` |
| Linux | x86_64 | `beads_*_linux_amd64.tar.gz` |

## beads Installation

```bash
# 1. Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
[[ "$ARCH" == "aarch64" ]] && ARCH="arm64"

# 2. Download asset matching pattern: beads_*_${OS}_${ARCH}.tar.gz

# 3. Extract
tar -xzf beads_*.tar.gz

# 4. Install
mkdir -p ~/.local/bin
mv bd ~/.local/bin/
chmod +x ~/.local/bin/bd

# 5. Verify
bd version
```

## Rule Files to Update

### OpenSpec Rules

| File | When to Update |
|------|----------------|
| `~/.claude/template/rules/workflow/openspec.md` | Command changes, new options |
| `~/.claude/template/skills/openspec-*/SKILL.md` | Major version changes |

### beads Rules

| File | When to Update |
|------|----------------|
| `~/.claude/template/rules/workflow/beads-workflow.md` | Command changes, new options |

### Integration Rules

| File | When to Update |
|------|----------------|
| `~/.claude/template/rules/workflow/workflow-integration.md` | Cross-tool changes |

## Version Commands

| Tool | Command | Output Format |
|------|---------|---------------|
| OpenSpec | `openspec --version` | `openspec v1.2.3` |
| beads | `bd version` | `bd version 0.49.1 (commit: ...)` |

## Cadence

- **Frequency**: 14 days
- **History file**: `~/.claude/.systems-review.json` (global)
- **Record command**: `~/.claude/template/scripts/review-tracker.sh record tools-updater`
