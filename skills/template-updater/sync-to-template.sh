#!/usr/bin/env bash
# Sync project .claude/ improvements back to ~/.claude/template/
# Usage: sync-to-template.sh [--help]
#
# Report-only: Shows what differs between project and template.
# Claude reads the report and decides which files to copy.
#
# Identifies template-worthy files (rules, skills) in project:
# - Shows files that exist in both locations but differ
# - Shows NEW files from template-worthy directories
# - Skips project-specific directories (rules/project/)

set -eo pipefail

# Source shared libraries
source "$HOME/.claude/scripts/lib/common.sh"
source "$HOME/.claude/scripts/lib/sync-common.sh"

# Script-specific patterns
# Project-specific directories (never sync to template)
PROJECT_SPECIFIC_DIRS="rules/project|skills/project"

# Template-worthy directories (sync both updates AND new files)
TEMPLATE_WORTHY_DIRS="rules/tech|rules/meta|rules/patterns|rules/workflow|skills"

# Generated files (customized per-project, only sync template→project)
GENERATED_PATTERNS="agents/.*\.md"

# Parse arguments
case "${1:-}" in
  --help|-h)
    echo "Usage: sync-to-template.sh"
    echo ""
    echo "Report-only: Shows what differs between project and template."
    echo "Claude reads the report and decides which files to copy."
    echo ""
    echo "Identifies files in ~/.claude/template/ that differ from project."
    exit 0
    ;;
  "")
    # No arguments - report mode (the only mode)
    ;;
  *)
    echo "Unknown argument: $1"
    echo "Usage: sync-to-template.sh [--help]"
    exit 1
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
count_new=0
count_protected=0
count_generated=0

# Temp files for reporting
changed_files=$(mktemp)
new_files=$(mktemp)
protected_files=$(mktemp)
generated_files=$(mktemp)
# shellcheck disable=SC2064
trap "rm -f $changed_files $new_files $protected_files $generated_files" EXIT

# Script-specific helper functions
is_project_specific_dir() {
  local file="$1"
  echo "$file" | grep -qE "^($PROJECT_SPECIFIC_DIRS)/"
}

is_template_worthy() {
  local file="$1"
  echo "$file" | grep -qE "^($TEMPLATE_WORTHY_DIRS)/"
}

is_generated() {
  local file="$1"
  echo "$file" | grep -qE "^($GENERATED_PATTERNS)$"
}

echo -e "${BLUE}Checking project improvements for template sync...${NC}"
echo ""

# Find template files and compare with project versions
while IFS= read -r template_file; do
  rel_path="${template_file#"$TEMPLATE_DIR"/}"

  # Flatten skill path to find in project
  flat_rel_path=$(flatten_skill_path "$rel_path")
  project_file="$PROJECT_DIR/$flat_rel_path"

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

  # Skip generated files (agents, etc. - customized per project)
  if is_generated "$rel_path"; then
    if ! diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
      echo "$rel_path" >> "$generated_files"
      ((count_generated++)) || true
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
done < <(find_syncable_files "$TEMPLATE_DIR")

# Find NEW files in template-worthy directories (not yet in template)
while IFS= read -r project_file; do
  rel_path="${project_file#"$PROJECT_DIR"/}"
  template_file="$TEMPLATE_DIR/$rel_path"

  # Skip if already in template (direct path)
  if [[ -f "$template_file" ]]; then
    continue
  fi

  # Check if this skill file exists in template under a category
  expanded_path=$(expand_skill_path "$rel_path")
  if [[ -n "$expanded_path" && -f "$TEMPLATE_DIR/$expanded_path" ]]; then
    continue
  fi

  # Skip if in project-specific directory
  if is_project_specific_dir "$rel_path"; then
    continue
  fi

  # Skip if not in a template-worthy directory
  if ! is_template_worthy "$rel_path"; then
    continue
  fi

  # Skip protected patterns
  if is_protected "$rel_path"; then
    continue
  fi

  # Skip generated patterns
  if is_generated "$rel_path"; then
    continue
  fi

  # This is a new template-worthy file
  echo "$rel_path" >> "$new_files"
  ((count_new++)) || true
done < <(find_syncable_files "$PROJECT_DIR")

# Report
echo -e "${GREEN}=== Template Sync Report ===${NC}"
echo ""

if [[ -s "$new_files" ]]; then
  echo -e "${GREEN}New (not in template):${NC}"
  while IFS= read -r f; do
    echo "  + $f"
  done < "$new_files"
  echo ""
fi

if [[ -s "$changed_files" ]]; then
  echo -e "${YELLOW}Changed (differs from template):${NC}"
  while IFS= read -r f; do
    echo "  ~ $f"
  done < "$changed_files"
  echo ""
fi

if [[ -s "$generated_files" ]]; then
  echo -e "${BLUE}Skipped (generated/per-project):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$generated_files"
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
echo "  New:              $count_new"
echo "  Changed:          $count_would_update"
echo "  Generated:        $count_generated (skipped)"
echo "  Protected:        $count_protected (skipped)"
echo ""

total_changes=$((count_new + count_would_update))

if [[ $total_changes -gt 0 ]]; then
  echo -e "${YELLOW}Report only - no changes made${NC}"
  echo ""
  echo "Claude should review the differences and copy files as needed."
else
  echo -e "${GREEN}Template is up to date with project.${NC}"
fi
