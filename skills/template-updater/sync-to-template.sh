#!/usr/bin/env bash
# Sync project .claude/ improvements back to ~/.claude/template/
# Usage: sync-to-template.sh [--auto|--report|--force]
#
# Only syncs files that ALREADY exist in the template.
# This prevents project-specific files from polluting the template.

set -e

TEMPLATE_DIR="$HOME/.claude/template"
PROJECT_DIR=".claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Protected files (never sync to template - contain project customization)
PROTECTED_PATTERNS="CLAUDE.md|agents-src/_shared.yaml"

# Project-specific files (exist in template but are meant to be customized per-project)
# These should only sync template→project, never project→template
PROJECT_SPECIFIC_PATTERNS="agents/.*\.md"

# Parse arguments
MODE="report"  # Default to report for safety (opposite of project-sync)
case "${1:-}" in
  --auto)   MODE="auto" ;;
  --report) MODE="report" ;;
  --force)  MODE="force" ;;
  --help|-h)
    echo "Usage: sync-to-template.sh [--auto|--report|--force]"
    echo "  --report  Show what would change, no modifications (default)"
    echo "  --auto    Apply all safe updates to template"
    echo "  --force   Apply all updates including protected (dangerous)"
    echo ""
    echo "Only syncs files that already exist in ~/.claude/template/"
    exit 0
    ;;
esac

# Check prerequisites
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo -e "${RED}Error: Template not found at $TEMPLATE_DIR${NC}"
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo -e "${RED}Error: No .claude/ directory in current project.${NC}"
  exit 1
fi

# Track counts
count_up_to_date=0
count_would_update=0
count_protected=0
count_project_specific=0

# Temp files for reporting
changed_files=$(mktemp)
protected_files=$(mktemp)
project_specific_files=$(mktemp)
trap "rm -f $changed_files $protected_files $project_specific_files" EXIT

# Check if file is protected
is_protected() {
  local file="$1"
  echo "$file" | grep -qE "^($PROTECTED_PATTERNS)$"
}

# Check if file is project-specific (generated or customized per project)
is_project_specific() {
  local file="$1"
  echo "$file" | grep -qE "^($PROJECT_SPECIFIC_PATTERNS)$"
}

echo -e "${BLUE}Checking project improvements for template sync...${NC}"
echo ""

# Find template files and compare with project versions
while IFS= read -r template_file; do
  rel_path="${template_file#$TEMPLATE_DIR/}"
  project_file="$PROJECT_DIR/$rel_path"

  # Skip if project doesn't have this file
  if [[ ! -f "$project_file" ]]; then
    continue
  fi

  # Skip protected files
  if is_protected "$rel_path"; then
    if ! diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
      echo "$rel_path" >> "$protected_files"
      ((count_protected++)) || true
    fi
    continue
  fi

  # Skip project-specific files (generated agents, etc.)
  if is_project_specific "$rel_path"; then
    if ! diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
      echo "$rel_path" >> "$project_specific_files"
      ((count_project_specific++)) || true
    fi
    continue
  fi

  # Compare files
  if diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
    ((count_up_to_date++)) || true
    continue
  fi

  # Files differ - this is a candidate for sync
  echo "$rel_path" >> "$changed_files"
  ((count_would_update++)) || true
done < <(find "$TEMPLATE_DIR" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.ts" \) 2>/dev/null | sort)

# Report
echo -e "${GREEN}=== Template Sync Report ===${NC}"
echo ""

if [[ -s "$changed_files" ]]; then
  echo -e "${YELLOW}Changed (template-worthy):${NC}"
  while IFS= read -r f; do
    if [[ "$MODE" == "report" ]]; then
      echo "  - $f (would update)"
    else
      echo "  - $f"
    fi
  done < "$changed_files"
  echo ""
fi

if [[ -s "$project_specific_files" ]]; then
  echo -e "${BLUE}Skipped (project-specific):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$project_specific_files"
  echo ""
fi

if [[ -s "$protected_files" ]]; then
  echo -e "${RED}Skipped (protected):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$protected_files"
  echo ""
fi

echo -e "${BLUE}Summary:${NC}"
echo "  Up to date:       $count_up_to_date"
echo "  Changed:          $count_would_update"
echo "  Project-specific: $count_project_specific (skipped)"
echo "  Protected:        $count_protected (skipped)"
echo ""

# Apply changes if not in report mode
if [[ "$MODE" == "report" ]]; then
  echo -e "${YELLOW}Report mode - no changes made${NC}"
  if [[ $count_would_update -gt 0 ]]; then
    echo ""
    echo "To apply changes, run:"
    echo "  ~/.claude/skills/template-updater/sync-to-template.sh --auto"
  fi
elif [[ $count_would_update -gt 0 ]]; then
  echo -e "${GREEN}Applying updates to template...${NC}"
  echo ""

  while IFS= read -r rel_path; do
    project_file="$PROJECT_DIR/$rel_path"
    template_file="$TEMPLATE_DIR/$rel_path"

    # Ensure directory exists
    mkdir -p "$(dirname "$template_file")"

    # Copy file
    cp "$project_file" "$template_file"
    echo "  Copied: $rel_path"
  done < "$changed_files"

  echo ""
  echo -e "${GREEN}Template updated.${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. cd ~/.claude && git diff  # Review changes"
  echo "  2. git add . && git commit -m 'chore: update template from project improvements'"
else
  echo -e "${GREEN}Template is up to date with project.${NC}"
fi
