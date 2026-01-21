#!/usr/bin/env bash
# Initialize Claude Code configuration for a new project
# Usage: setup-project.sh [options]
#
# Copies template structure, optionally initializes tools, and builds agents.

set -e

TEMPLATE_DIR="$HOME/.claude/template"
PROJECT_DIR=".claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GitButler is managing the current directory
is_gitbutler_active() {
  command -v but >/dev/null 2>&1 && [[ -d ".git" ]] && but status >/dev/null 2>&1
}

# Defaults
TOOLS="all"
FRAMEWORK=""
SCAFFOLD_RULES=false
PROJECT_NAME=""
SKIP_INIT=false
SKIP_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tools=*)
      TOOLS="${1#*=}"
      shift
      ;;
    --framework=*)
      FRAMEWORK="${1#*=}"
      shift
      ;;
    --scaffold-rules)
      SCAFFOLD_RULES=true
      shift
      ;;
    --project-name=*)
      PROJECT_NAME="${1#*=}"
      shift
      ;;
    --skip-init)
      SKIP_INIT=true
      shift
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --help|-h)
      echo "Usage: setup-project.sh [options]"
      echo ""
      echo "Options:"
      echo "  --tools=TOOLS        Tools to enable: all, beads+openspec, beads, openspec, none"
      echo "                       (default: all = gitbutler+beads+openspec)"
      echo "  --framework=NAME     Framework: nextjs, react, node, other (optional)"
      echo "  --scaffold-rules     Create scaffolded rule files (architecture.md, etc.)"
      echo "  --project-name=NAME  Project name for beads prefix (default: directory name)"
      echo "  --skip-init          Skip tool initialization (bd init, openspec init)"
      echo "  --skip-build         Skip agent building step"
      echo ""
      echo "Examples:"
      echo "  setup-project.sh --tools=all --framework=nextjs --scaffold-rules"
      echo "  setup-project.sh --tools=beads --project-name=myapp"
      echo "  setup-project.sh --tools=none  # Just copy base template"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Run with --help for usage"
      exit 1
      ;;
  esac
done

# Derive project name from directory if not provided
if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME=$(basename "$(pwd)")
fi

# Parse tool flags
ENABLE_GITBUTLER=false
ENABLE_BEADS=false
ENABLE_OPENSPEC=false

case "$TOOLS" in
  all)
    ENABLE_GITBUTLER=true
    ENABLE_BEADS=true
    ENABLE_OPENSPEC=true
    ;;
  beads+openspec|openspec+beads)
    ENABLE_BEADS=true
    ENABLE_OPENSPEC=true
    ;;
  beads)
    ENABLE_BEADS=true
    ;;
  openspec)
    ENABLE_OPENSPEC=true
    ;;
  gitbutler)
    ENABLE_GITBUTLER=true
    ;;
  none)
    ;;
  *)
    echo -e "${RED}Unknown tools option: $TOOLS${NC}"
    echo "Valid options: all, beads+openspec, beads, openspec, gitbutler, none"
    exit 1
    ;;
esac

# Check prerequisites
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo -e "${RED}Error: Template not found at $TEMPLATE_DIR${NC}"
  exit 1
fi

# Check if already initialized
if [[ -d "$PROJECT_DIR" ]]; then
  echo -e "${YELLOW}Warning: .claude/ directory already exists${NC}"
  echo "This will update existing files. Continue? (y/N)"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo -e "${BLUE}Setting up Claude Code configuration...${NC}"
echo ""
echo "Project: $PROJECT_NAME"
echo "Tools:   $TOOLS"
[[ -n "$FRAMEWORK" ]] && echo "Framework: $FRAMEWORK"
echo ""

# Track what we do
files_copied=0
files_skipped=0

# Helper: copy file from template
copy_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -f "$TEMPLATE_DIR/$src" ]]; then
    echo -e "  ${YELLOW}Skip:${NC} $src (not in template)"
    ((files_skipped++)) || true
    return
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$TEMPLATE_DIR/$src" "$dst"
  echo -e "  ${GREEN}Copy:${NC} $src"
  ((files_copied++)) || true
}

# Helper: copy directory from template
copy_dir() {
  local src="$1"
  local dst="$2"

  if [[ ! -d "$TEMPLATE_DIR/$src" ]]; then
    echo -e "  ${YELLOW}Skip:${NC} $src/ (not in template)"
    ((files_skipped++)) || true
    return
  fi

  mkdir -p "$dst"
  cp -r "$TEMPLATE_DIR/$src/"* "$dst/" 2>/dev/null || true
  echo -e "  ${GREEN}Copy:${NC} $src/"
  ((files_copied++)) || true
}

echo -e "${BLUE}Phase 1: Copying base template...${NC}"
mkdir -p "$PROJECT_DIR"

# Always copy these
copy_file "CLAUDE.md" "./CLAUDE.md"
copy_file "baseline-agent.md" "$PROJECT_DIR/baseline-agent.md"
copy_dir "agents-src" "$PROJECT_DIR/agents-src"
copy_dir "scripts" "$PROJECT_DIR/scripts"

# Always copy these rules
copy_file "rules/landing-the-plane.md" "$PROJECT_DIR/rules/landing-the-plane.md"
copy_file "rules/deterministic-systems.md" "$PROJECT_DIR/rules/deterministic-systems.md"
copy_file "rules/research-patterns.md" "$PROJECT_DIR/rules/research-patterns.md"
copy_file "rules/documentation-lookup.md" "$PROJECT_DIR/rules/documentation-lookup.md"
copy_file "rules/agents-system.md" "$PROJECT_DIR/rules/agents-system.md"

# Always copy these skills
copy_dir "skills/pr-check" "$PROJECT_DIR/skills/pr-check"
copy_dir "skills/deps-update" "$PROJECT_DIR/skills/deps-update"
copy_dir "skills/adr-writer" "$PROJECT_DIR/skills/adr-writer"
copy_dir "skills/skill-writer" "$PROJECT_DIR/skills/skill-writer"
copy_dir "skills/agent-writer" "$PROJECT_DIR/skills/agent-writer"

# Always copy these commands
mkdir -p "$PROJECT_DIR/commands"
copy_file "commands/plan.md" "$PROJECT_DIR/commands/plan.md"
copy_file "commands/check.md" "$PROJECT_DIR/commands/check.md"
copy_file "commands/fix.md" "$PROJECT_DIR/commands/fix.md"
copy_file "commands/review.md" "$PROJECT_DIR/commands/review.md"
copy_file "commands/test.md" "$PROJECT_DIR/commands/test.md"

echo ""

# Tool-specific files
if [[ "$ENABLE_BEADS" == "true" ]]; then
  echo -e "${BLUE}Phase 2a: Copying Beads files...${NC}"
  copy_file "rules/beads-workflow.md" "$PROJECT_DIR/rules/beads-workflow.md"
  copy_dir "skills/beads-cleanup" "$PROJECT_DIR/skills/beads-cleanup"
  copy_file "commands/work.md" "$PROJECT_DIR/commands/work.md"
  copy_file "commands/status.md" "$PROJECT_DIR/commands/status.md"
  echo ""
fi

if [[ "$ENABLE_OPENSPEC" == "true" ]]; then
  echo -e "${BLUE}Phase 2b: Copying OpenSpec files...${NC}"
  copy_file "rules/openspec.md" "$PROJECT_DIR/rules/openspec.md"
  copy_dir "skills/quality" "$PROJECT_DIR/skills/quality"
  mkdir -p "$PROJECT_DIR/commands/openspec"
  copy_file "commands/openspec/proposal.md" "$PROJECT_DIR/commands/openspec/proposal.md"
  copy_file "commands/openspec/apply.md" "$PROJECT_DIR/commands/openspec/apply.md"
  copy_file "commands/openspec/archive.md" "$PROJECT_DIR/commands/openspec/archive.md"
  echo ""
fi

if [[ "$ENABLE_BEADS" == "true" ]] && [[ "$ENABLE_OPENSPEC" == "true" ]]; then
  echo -e "${BLUE}Phase 2c: Copying Beads+OpenSpec integration files...${NC}"
  copy_file "rules/workflow-integration.md" "$PROJECT_DIR/rules/workflow-integration.md"
  copy_file "commands/wrap.md" "$PROJECT_DIR/commands/wrap.md"
  echo ""
fi

# Framework-specific setup
if [[ -n "$FRAMEWORK" ]]; then
  echo -e "${BLUE}Phase 3: Framework-specific setup ($FRAMEWORK)...${NC}"
  case "$FRAMEWORK" in
    nextjs)
      # Could copy nextjs-specific skills/rules if they exist in template
      echo "  Framework noted in CLAUDE.md (customize manually)"
      ;;
    react)
      echo "  Framework noted in CLAUDE.md (customize manually)"
      ;;
    node)
      echo "  Framework noted in CLAUDE.md (customize manually)"
      ;;
    *)
      echo "  No framework-specific files"
      ;;
  esac
  echo ""
fi

# Scaffold rules
if [[ "$SCAFFOLD_RULES" == "true" ]]; then
  echo -e "${BLUE}Phase 4: Creating scaffolded rule files...${NC}"

  if [[ ! -f "$PROJECT_DIR/rules/architecture.md" ]]; then
    cat > "$PROJECT_DIR/rules/architecture.md" << 'EOF'
# Architecture

## Overview

<!-- Describe your architecture here -->

## Key Patterns

<!-- Document important patterns -->

## Data Flow

<!-- How data moves through the system -->
EOF
    echo -e "  ${GREEN}Create:${NC} rules/architecture.md"
  else
    echo -e "  ${YELLOW}Skip:${NC} rules/architecture.md (exists)"
  fi

  if [[ ! -f "$PROJECT_DIR/rules/project-overview.md" ]]; then
    cat > "$PROJECT_DIR/rules/project-overview.md" << 'EOF'
# Project Overview

<!-- Brief description of the project -->

## Development Commands

```bash
# Add your common commands here
npm run dev          # Start dev server
npm run build        # Production build
npm run test         # Run tests
```

## File Organization

<!-- Describe how files are organized -->

## Naming Conventions

<!-- Project-specific naming rules -->
EOF
    echo -e "  ${GREEN}Create:${NC} rules/project-overview.md"
  else
    echo -e "  ${YELLOW}Skip:${NC} rules/project-overview.md (exists)"
  fi

  if [[ ! -f "$PROJECT_DIR/rules/danger-zone.md" ]]; then
    cat > "$PROJECT_DIR/rules/danger-zone.md" << 'EOF'
# Danger Zone

> These actions cause problems. Never do them.

## Commands

| Never | Consequence |
|-------|-------------|
| <!-- Add project-specific "never do" rules --> | |

## Code Patterns

| Never | Consequence |
|-------|-------------|
| <!-- Add anti-patterns to avoid --> | |
EOF
    echo -e "  ${GREEN}Create:${NC} rules/danger-zone.md"
  else
    echo -e "  ${YELLOW}Skip:${NC} rules/danger-zone.md (exists)"
  fi
  echo ""
fi

# Tool initialization
if [[ "$SKIP_INIT" != "true" ]]; then
  echo -e "${BLUE}Phase 5: Tool initialization...${NC}"

  if [[ "$ENABLE_BEADS" == "true" ]]; then
    if [[ -d ".beads" ]]; then
      echo -e "  ${YELLOW}Beads:${NC} Already initialized"
    elif command -v bd &> /dev/null; then
      echo -e "  ${GREEN}Beads:${NC} Initializing..."
      bd init --prefix="$PROJECT_NAME" 2>/dev/null || echo -e "    ${YELLOW}Warning: bd init failed${NC}"
    else
      echo -e "  ${YELLOW}Beads:${NC} CLI not installed (run: npm install -g beads-ui@latest)"
    fi
  fi

  if [[ "$ENABLE_OPENSPEC" == "true" ]]; then
    if [[ -d "openspec" ]]; then
      echo -e "  ${YELLOW}OpenSpec:${NC} Already initialized"
    elif command -v openspec &> /dev/null; then
      echo -e "  ${GREEN}OpenSpec:${NC} Initializing..."
      openspec init --tools=claude 2>/dev/null || echo -e "    ${YELLOW}Warning: openspec init failed${NC}"
    else
      echo -e "  ${YELLOW}OpenSpec:${NC} CLI not installed (run: npm install -g @fission-ai/openspec@latest)"
    fi
  fi

  if [[ "$ENABLE_GITBUTLER" == "true" ]]; then
    if command -v but &> /dev/null; then
      if but status &> /dev/null; then
        echo -e "  ${YELLOW}GitButler:${NC} Already initialized"
      else
        echo -e "  ${YELLOW}GitButler:${NC} Open GitButler desktop app to initialize"
      fi
    else
      echo -e "  ${YELLOW}GitButler:${NC} CLI not installed (run: curl -fsSL https://app.gitbutler.com/install.sh | sh)"
    fi
  fi
  echo ""
fi

# Build agents
if [[ "$SKIP_BUILD" != "true" ]]; then
  echo -e "${BLUE}Phase 6: Building agents...${NC}"

  if [[ -f "$PROJECT_DIR/scripts/build-agents.ts" ]]; then
    # Check for yaml package
    if ! npm list yaml &> /dev/null; then
      echo "  Installing yaml package..."
      npm install --save-dev yaml 2>/dev/null || true
    fi

    # Build agents
    if command -v npx &> /dev/null; then
      echo "  Running build-agents.ts..."
      npx tsx "$PROJECT_DIR/scripts/build-agents.ts" 2>/dev/null && \
        echo -e "  ${GREEN}Agents built successfully${NC}" || \
        echo -e "  ${YELLOW}Warning: Agent build failed (run manually: npx tsx $PROJECT_DIR/scripts/build-agents.ts)${NC}"
    else
      echo -e "  ${YELLOW}npx not available - run manually: npx tsx $PROJECT_DIR/scripts/build-agents.ts${NC}"
    fi
  else
    echo -e "  ${YELLOW}build-agents.ts not found${NC}"
  fi
  echo ""
fi

# Summary
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Project: $PROJECT_NAME"
echo "Files copied: $files_copied"
[[ $files_skipped -gt 0 ]] && echo "Files skipped: $files_skipped"
echo ""
echo "Tools enabled:"
[[ "$ENABLE_GITBUTLER" == "true" ]] && echo "  - GitButler"
[[ "$ENABLE_BEADS" == "true" ]] && echo "  - Beads"
[[ "$ENABLE_OPENSPEC" == "true" ]] && echo "  - OpenSpec"
[[ "$TOOLS" == "none" ]] && echo "  - (none)"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review and customize CLAUDE.md"
echo "  2. Review and customize .claude/rules/ files"
[[ "$ENABLE_BEADS" == "true" ]] && echo "  3. Run 'bd ready' to see available work"
echo ""
if is_gitbutler_active; then
  echo "  but status  # See files to commit"
  echo "  but stage <file> <branch>  # Stage files"
  echo "  but commit <branch> --only -m 'chore: add claude code configuration'"
else
  echo "  git add .claude/ CLAUDE.md"
  [[ "$ENABLE_BEADS" == "true" ]] && echo "  git add .beads/"
  [[ "$ENABLE_OPENSPEC" == "true" ]] && echo "  git add openspec/"
  echo "  git commit -m 'chore: add claude code configuration'"
fi
