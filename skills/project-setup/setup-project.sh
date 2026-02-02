#!/usr/bin/env bash
# Initialize Claude Code configuration for a new project
# Usage: setup-project.sh [options]
#
# Uses tech detection to copy only relevant rules:
#   - Always copies: meta/, patterns/, workflow/ rules
#   - Tech-specific: Only copies rules for detected technologies
#   - Creates: project/ directories (empty, for project-specific content)
#
# Copies template structure, optionally initializes tools, and builds agents.

set -eo pipefail

# Source shared libraries
source "$HOME/.claude/scripts/lib/common.sh"
source "$HOME/.claude/scripts/lib/sync-common.sh"

DETECT_SCRIPT="$HOME/.claude/scripts/detect-technologies.sh"

# Defaults
TOOLS="all"
FRAMEWORK=""
SCAFFOLD_RULES=false
PROJECT_NAME=""
SKIP_INIT=false
SKIP_BUILD=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tools=*)
      # Accept for backwards compatibility but gitbutler is always assumed
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
    --force|-f)
      FORCE=true
      shift
      ;;
    --help|-h)
      echo "Usage: setup-project.sh [options]"
      echo ""
      echo "Options:"
      echo "  --tools=TOOLS        Tools to enable: all, beads+openspec, beads, openspec, none"
      echo "                       (default: all = beads+openspec)"
      echo "  --framework=NAME     Framework hint (deprecated - uses auto-detection)"
      echo "  --scaffold-rules     Create scaffolded rule files (architecture.md, etc.)"
      echo "  --project-name=NAME  Project name for beads prefix (default: directory name)"
      echo "  --skip-init          Skip tool initialization (bd init, openspec init)"
      echo "  --skip-build         Skip agent building step"
      echo "  --force, -f          Skip confirmation if .claude/ already exists"
      echo ""
      echo "Tech detection:"
      echo "  Automatically detects technologies from package.json, config files,"
      echo "  and directories, then copies only relevant tech rules."
      echo ""
      echo "Examples:"
      echo "  setup-project.sh --tools=all --scaffold-rules"
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
ENABLE_BEADS=false
ENABLE_OPENSPEC=false

case "$TOOLS" in
  all)
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
  none)
    ;;
  *)
    echo -e "${RED}Unknown tools option: $TOOLS${NC}"
    echo "Valid options: all, beads+openspec, beads, openspec, none"
    exit 1
    ;;
esac

# Get detected technologies, rules, and skills
DETECTED_RULES=""
DETECTED_TECHS=""
DETECTED_SKILLS=""
if [[ -x "$DETECT_SCRIPT" ]]; then
  DETECTED_RULES=$("$DETECT_SCRIPT" --rules 2>/dev/null || true)
  DETECTED_TECHS=$("$DETECT_SCRIPT" --techs 2>/dev/null || true)
  DETECTED_SKILLS=$("$DETECT_SCRIPT" --skills 2>/dev/null || true)
fi

# Check prerequisites
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo -e "${RED}Error: Template not found at $TEMPLATE_DIR${NC}"
  exit 1
fi

# Check if already initialized
if [[ -d "$PROJECT_DIR" ]]; then
  warn ".claude/ directory already exists"
  if [[ "$FORCE" != "true" ]]; then
    if ! confirm "This will update existing files. Continue?"; then
      echo "Aborted."
      exit 0
    fi
  fi
fi

echo -e "${BLUE}Setting up Claude Code configuration...${NC}"
echo ""
echo "Project: $PROJECT_NAME"
echo "Tools:   $TOOLS"
echo ""

# Show detected technologies
if [[ -n "$DETECTED_TECHS" ]]; then
  echo -e "Technologies detected:"
  echo "$DETECTED_TECHS" | while read -r tech; do
    [[ -n "$tech" ]] && echo -e "  ${GREEN}+${NC} $tech"
  done
  echo ""
fi

# Initialize git if needed (idempotent - safe on existing repos)
if [[ ! -d ".git" ]]; then
  echo -e "${BLUE}Initializing git repository...${NC}"
  git init
  echo ""
else
  echo -e "${BLUE}Git repository already initialized${NC}"
  echo ""
fi

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
  # Check if directory has files before trying to copy
  if compgen -G "$TEMPLATE_DIR/$src/*" > /dev/null; then
    if ! cp -r "$TEMPLATE_DIR/$src/"* "$dst/"; then
      warn "Failed to copy $src/ to $dst/"
      ((files_skipped++)) || true
      return
    fi
  fi
  echo -e "  ${GREEN}Copy:${NC} $src/"
  ((files_copied++)) || true
}

# Helper: copy skill directory with path flattening
# Template: skills/{category}/{skill}/ or skills/tools/{tool}/{skill}/
# Project:  skills/{skill}/
copy_skill() {
  local template_skill_path="$1"  # e.g., "quality/rules-review" or "tools/beads/beads-cleanup"
  local skill_name="$2"           # e.g., "rules-review" or "beads-cleanup"

  local src="skills/$template_skill_path"
  local dst="$PROJECT_DIR/skills/$skill_name"

  if [[ ! -d "$TEMPLATE_DIR/$src" ]]; then
    echo -e "  ${YELLOW}Skip:${NC} $src/ (not in template)"
    ((files_skipped++)) || true
    return
  fi

  mkdir -p "$dst"
  if compgen -G "$TEMPLATE_DIR/$src/*" > /dev/null; then
    if ! cp -r "$TEMPLATE_DIR/$src/"* "$dst/"; then
      warn "Failed to copy $src/ to $dst/"
      ((files_skipped++)) || true
      return
    fi
  fi
  echo -e "  ${GREEN}Copy:${NC} $src/ -> skills/$skill_name/"
  ((files_copied++)) || true
}

# Helper: check if tech rule should be copied based on detection
should_copy_tech_rule() {
  local file="$1"

  # If no detection or no rules detected, copy everything
  if [[ -z "$DETECTED_RULES" ]]; then
    return 0
  fi

  # Detection script outputs "tech/x.md", template has "rules/tech/x.md"
  # Strip "rules/" prefix for comparison
  local tech_path="${file#rules/}"

  # Check if this rule is in the detected list
  if echo "$DETECTED_RULES" | grep -qF "$tech_path"; then
    return 0  # Rule needed, copy it
  fi

  return 1  # Rule not needed for detected technologies
}

# Helper: copy all files in a rule folder from template
copy_rule_folder() {
  local folder="$1"

  if [[ ! -d "$TEMPLATE_DIR/rules/$folder" ]]; then
    echo -e "  ${YELLOW}Skip:${NC} rules/$folder/ (not in template)"
    return
  fi

  mkdir -p "$PROJECT_DIR/rules/$folder"
  while IFS= read -r file; do
    local rel_path="${file#"$TEMPLATE_DIR"/}"
    local filename=$(basename "$file")
    cp "$file" "$PROJECT_DIR/rules/$folder/$filename"
    echo -e "  ${GREEN}Copy:${NC} $rel_path"
    ((files_copied++)) || true
  done < <(find "$TEMPLATE_DIR/rules/$folder" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort)
}

echo -e "${BLUE}Phase 1: Copying base template...${NC}"
mkdir -p "$PROJECT_DIR"

# Always copy these
copy_file "CLAUDE.md" "./CLAUDE.md"
copy_file "baseline-agent.md" "$PROJECT_DIR/baseline-agent.md"
# agents-src includes _template.yaml (template-controlled) and _project.yaml (starter template)
copy_dir "agents-src" "$PROJECT_DIR/agents-src"
copy_dir "scripts" "$PROJECT_DIR/scripts"

# Always copy these rule folders (from sync-config.yaml "always" section)
echo -e "  ${BLUE}Copying always-included rules...${NC}"
copy_rule_folder "meta"
copy_rule_folder "patterns"
copy_rule_folder "workflow"

# Copy tech-specific rules based on detection
echo -e "  ${BLUE}Copying tech-specific rules...${NC}"
if [[ -d "$TEMPLATE_DIR/rules/tech" ]]; then
  mkdir -p "$PROJECT_DIR/rules/tech"
  while IFS= read -r file; do
    rel_path="${file#"$TEMPLATE_DIR"/}"
    if should_copy_tech_rule "$rel_path"; then
      filename=$(basename "$file")
      cp "$file" "$PROJECT_DIR/rules/tech/$filename"
      echo -e "  ${GREEN}Copy:${NC} $rel_path"
      ((files_copied++)) || true
    else
      echo -e "  ${BLUE}Skip:${NC} $rel_path (tech not detected)"
      ((files_skipped++)) || true
    fi
  done < <(find "$TEMPLATE_DIR/rules/tech" -name "*.md" -type f 2>/dev/null | sort)
fi

# Create empty project/ directories
echo -e "  ${BLUE}Creating project-specific directories...${NC}"
mkdir -p "$PROJECT_DIR/rules/project"
mkdir -p "$PROJECT_DIR/skills/project"
echo -e "  ${GREEN}Create:${NC} rules/project/ (empty)"
echo -e "  ${GREEN}Create:${NC} skills/project/ (empty)"

# Copy skills based on detection (from sync-config.yaml "always.skills" section)
echo -e "  ${BLUE}Copying always-included skills...${NC}"
echo "$DETECTED_SKILLS" | while read -r skill_folder; do
  [[ -z "$skill_folder" ]] && continue
  # skill_folder is like "authoring/" or "quality/", copy all subdirectories with flattening
  if [[ -d "$TEMPLATE_DIR/skills/$skill_folder" ]]; then
    for skill_dir in "$TEMPLATE_DIR/skills/$skill_folder"*/; do
      [[ -d "$skill_dir" ]] || continue
      skill_name=$(basename "$skill_dir")
      # Flatten: skills/{category}/{skill}/ -> skills/{skill}/
      copy_skill "${skill_folder}${skill_name}" "$skill_name"
    done
  fi
done

# Always copy these commands
mkdir -p "$PROJECT_DIR/commands"
copy_file "commands/plan.md" "$PROJECT_DIR/commands/plan.md"
copy_file "commands/check.md" "$PROJECT_DIR/commands/check.md"
copy_file "commands/fix.md" "$PROJECT_DIR/commands/fix.md"
copy_file "commands/fix-tests.md" "$PROJECT_DIR/commands/fix-tests.md"

echo ""

# Tool-specific files
if [[ "$ENABLE_BEADS" == "true" ]]; then
  echo -e "${BLUE}Phase 2a: Copying Beads files...${NC}"
  # beads-workflow.md should already be in rules/workflow/ from Phase 1
  copy_skill "tools/beads/beads-cleanup" "beads-cleanup"
  copy_skill "workflow/work" "work"
  copy_file "commands/status.md" "$PROJECT_DIR/commands/status.md"
  echo ""
fi

if [[ "$ENABLE_OPENSPEC" == "true" ]]; then
  echo -e "${BLUE}Phase 2b: Copying OpenSpec files...${NC}"
  # openspec.md should already be in rules/workflow/ from Phase 1
  copy_skill "quality/rules-review" "rules-review"
  copy_skill "tools/openspec/spec-review" "spec-review"
  mkdir -p "$PROJECT_DIR/commands/openspec"
  copy_file "commands/openspec/proposal.md" "$PROJECT_DIR/commands/openspec/proposal.md"
  copy_file "commands/openspec/apply.md" "$PROJECT_DIR/commands/openspec/apply.md"
  copy_file "commands/openspec/archive.md" "$PROJECT_DIR/commands/openspec/archive.md"
  echo ""
fi

if [[ "$ENABLE_BEADS" == "true" ]] && [[ "$ENABLE_OPENSPEC" == "true" ]]; then
  echo -e "${BLUE}Phase 2c: Copying Beads+OpenSpec integration files...${NC}"
  # workflow-integration.md should already be in rules/workflow/ from Phase 1
  copy_file "commands/wrap.md" "$PROJECT_DIR/commands/wrap.md"
  echo ""
fi

# Scaffold rules
if [[ "$SCAFFOLD_RULES" == "true" ]]; then
  echo -e "${BLUE}Phase 3: Creating scaffolded rule files...${NC}"

  if [[ ! -f "$PROJECT_DIR/rules/project/architecture.md" ]]; then
    cat > "$PROJECT_DIR/rules/project/architecture.md" << 'EOF'
# Architecture

## Route/File Structure

<!-- Document key directories and their purposes -->

## Database

<!-- Database technology, schema patterns, key tables -->

## Key Features

<!-- Document major features and their implementation patterns -->

## External Integrations

<!-- Third-party services, APIs, webhooks -->
EOF
    echo -e "  ${GREEN}Create:${NC} rules/project/architecture.md"
  else
    echo -e "  ${YELLOW}Skip:${NC} rules/project/architecture.md (exists)"
  fi

  if [[ ! -f "$PROJECT_DIR/rules/project/overview.md" ]]; then
    cat > "$PROJECT_DIR/rules/project/overview.md" << 'EOF'
---
bundles: all
---

# Project Overview

<!-- Brief description of the project and its key technologies -->

## Development Commands

```bash
npm run dev          # Start dev server
npm run build        # Production build
npm run lint         # Run ESLint
npm run test         # Run tests
```

## Import Path Alias

<!-- Document import conventions, e.g., `@/` → `src/` -->

## File Naming Conventions

<!-- Document file naming rules, e.g., kebab-case for files -->

## Additional Documentation

<!-- Link to other docs, ADRs, or external resources -->

## Danger Zone

| Never | Consequence |
|-------|-------------|
| <!-- Add project-specific "never do" rules --> | |
EOF
    echo -e "  ${GREEN}Create:${NC} rules/project/overview.md"
  else
    echo -e "  ${YELLOW}Skip:${NC} rules/project/overview.md (exists)"
  fi
  echo ""
fi

# Tool initialization
if [[ "$SKIP_INIT" != "true" ]]; then
  echo -e "${BLUE}Phase 4: Tool initialization...${NC}"

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

  echo ""
fi

# Build agents
if [[ "$SKIP_BUILD" != "true" ]]; then
  echo -e "${BLUE}Phase 5: Building agents...${NC}"

  if [[ -f "$PROJECT_DIR/scripts/build-agents.ts" ]]; then
    # Check for required packages
    needs_install=false
    if ! npm list yaml &> /dev/null 2>&1; then
      needs_install=true
    fi
    if ! npm list tsx &> /dev/null 2>&1; then
      needs_install=true
    fi

    if [[ "$needs_install" == "true" ]]; then
      echo "  Installing yaml and tsx packages..."
      if ! npm install --save-dev yaml tsx; then
        warn "Failed to install packages (run manually: npm install --save-dev yaml tsx)"
      fi
    fi

    # Add build:agents npm script if missing
    if [[ -f "package.json" ]]; then
      if ! grep -q '"build:agents"' package.json; then
        echo "  Adding build:agents npm script..."
        # Use node to safely modify package.json
        node -e "
          const fs = require('fs');
          const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
          pkg.scripts = pkg.scripts || {};
          pkg.scripts['build:agents'] = 'npx tsx .claude/scripts/build-agents.ts';
          fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
        " 2>/dev/null && echo -e "  ${GREEN}Added build:agents script${NC}" || \
          echo -e "  ${YELLOW}Warning: Could not add npm script (add manually)${NC}"
      fi
    fi

    # Build agents
    if command -v npx &> /dev/null; then
      echo "  Running build-agents.ts..."
      npx tsx "$PROJECT_DIR/scripts/build-agents.ts" 2>/dev/null && \
        echo -e "  ${GREEN}Agents built successfully${NC}" || \
        echo -e "  ${YELLOW}Warning: Agent build failed (run manually: npm run build:agents)${NC}"
    else
      echo -e "  ${YELLOW}npx not available - run manually: npm run build:agents${NC}"
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
[[ "$ENABLE_BEADS" == "true" ]] && echo "  - Beads"
[[ "$ENABLE_OPENSPEC" == "true" ]] && echo "  - OpenSpec"
[[ "$TOOLS" == "none" ]] && echo "  - (none)"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review and customize CLAUDE.md"
echo "  2. Review and customize .claude/rules/ files"
[[ "$ENABLE_BEADS" == "true" ]] && echo "  3. Run 'bd ready' to see available work"
echo ""
echo "  but status  # See files to commit"
echo "  but stage <file> <branch>  # Stage files"
echo "  but commit <branch> --only -m 'chore: add claude code configuration'"
