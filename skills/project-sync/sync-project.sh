#!/usr/bin/env bash
# Sync project .claude/ with ~/.claude/template/
# Usage: sync-project.sh [--auto|--report|--force]
#
# Detects enabled tools by directory existence:
#   .beads/   → includes beads rules/skills/commands
#   openspec/ → includes openspec rules
#   Both      → includes workflow-integration

set -e

TEMPLATE_DIR="$HOME/.claude/template"
PROJECT_DIR=".claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Protected files (never auto-update, but shown in report)
PROTECTED_PATTERNS="CLAUDE.md|agents-src/_shared.yaml"

# Excluded files (skip entirely, not synced to projects)
# - README.md: template documentation
# Note: agents-src/*.yaml now synced (except _shared.yaml which is protected)
EXCLUDED_PATTERNS="README.md"

# Detect enabled tools
HAS_BEADS=false
HAS_OPENSPEC=false
[[ -d ".beads" ]] && HAS_BEADS=true
[[ -d "openspec" ]] && HAS_OPENSPEC=true

# Files that require specific tools
BEADS_FILES="rules/beads-workflow.md|skills/beads-cleanup/|commands/work.md|commands/status.md|commands/wrap.md"
OPENSPEC_FILES="rules/openspec.md|skills/quality/"
BEADS_AND_OPENSPEC_FILES="rules/workflow-integration.md"

# Parse arguments
MODE="auto"
case "${1:-}" in
  --auto)   MODE="auto" ;;
  --report) MODE="report" ;;
  --force)  MODE="force" ;;
  --help|-h)
    echo "Usage: sync-project.sh [--auto|--report|--force]"
    echo "  --auto    Apply all safe updates without prompts (default)"
    echo "  --report  Show report only, no changes"
    echo "  --force   Apply all updates including protected (dangerous)"
    echo ""
    echo "Tool detection:"
    echo "  .beads/   directory → syncs beads rules/skills/commands"
    echo "  openspec/ directory → syncs openspec rules"
    exit 0
    ;;
esac

# Check prerequisites
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo -e "${RED}Error: Template not found at $TEMPLATE_DIR${NC}"
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo -e "${RED}Error: No .claude/ directory. Run project-setup first.${NC}"
  exit 1
fi

# Track counts
count_up_to_date=0
count_updated=0
count_added=0
count_protected=0
count_skipped=0

# Temp files for reporting
updated_files=$(mktemp)
added_files=$(mktemp)
protected_files=$(mktemp)
skipped_files=$(mktemp)
trap "rm -f $updated_files $added_files $protected_files $skipped_files" EXIT

# Check if file is protected
is_protected() {
  local file="$1"
  if echo "$file" | grep -qE "^($PROTECTED_PATTERNS)$"; then
    return 0
  fi
  # Also check for PROJECT-SPECIFIC marker
  if [[ -f "$PROJECT_DIR/$file" ]] && grep -q "PROJECT-SPECIFIC" "$PROJECT_DIR/$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Check if file should be skipped based on tool detection
should_skip_for_tools() {
  local file="$1"

  # Beads-only files
  if echo "$file" | grep -qE "^($BEADS_FILES)"; then
    if [[ "$HAS_BEADS" != "true" ]]; then
      return 0  # Skip - beads not enabled
    fi
  fi

  # OpenSpec-only files
  if echo "$file" | grep -qE "^($OPENSPEC_FILES)$"; then
    if [[ "$HAS_OPENSPEC" != "true" ]]; then
      return 0  # Skip - openspec not enabled
    fi
  fi

  # Files requiring both beads and openspec
  if echo "$file" | grep -qE "^($BEADS_AND_OPENSPEC_FILES)$"; then
    if [[ "$HAS_BEADS" != "true" ]] || [[ "$HAS_OPENSPEC" != "true" ]]; then
      return 0  # Skip - need both tools
    fi
  fi

  return 1  # Don't skip
}

echo -e "${BLUE}Syncing project with template...${NC}"
echo ""
echo -e "Tools detected:"
echo -e "  Beads:    $([[ "$HAS_BEADS" == "true" ]] && echo "${GREEN}yes${NC}" || echo "${YELLOW}no${NC} (.beads/ not found)")"
echo -e "  OpenSpec: $([[ "$HAS_OPENSPEC" == "true" ]] && echo "${GREEN}yes${NC}" || echo "${YELLOW}no${NC} (openspec/ not found)")"
echo ""

# Find all template files
while IFS= read -r file; do
  rel_path="${file#$TEMPLATE_DIR/}"
  template_file="$file"
  project_file="$PROJECT_DIR/$rel_path"

  # Check if excluded (skip entirely)
  if echo "$rel_path" | grep -qE "^($EXCLUDED_PATTERNS)$"; then
    continue
  fi

  # Check if should skip based on tools
  if should_skip_for_tools "$rel_path"; then
    echo "$rel_path (tool not enabled)" >> "$skipped_files"
    ((count_skipped++)) || true
    continue
  fi

  # Check if protected
  if is_protected "$rel_path"; then
    if [[ -f "$project_file" ]]; then
      if ! diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
        echo "$rel_path" >> "$protected_files"
        ((count_protected++)) || true
      fi
    fi
    continue
  fi

  # File missing in project - add it
  if [[ ! -f "$project_file" ]]; then
    if [[ "$MODE" != "report" ]]; then
      mkdir -p "$(dirname "$project_file")"
      cp "$template_file" "$project_file"
      echo "$rel_path" >> "$added_files"
    else
      echo "$rel_path (would add)" >> "$added_files"
    fi
    ((count_added++)) || true
    continue
  fi

  # Compare files
  if diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
    ((count_up_to_date++)) || true
    continue
  fi

  # Files differ - update
  if [[ "$MODE" != "report" ]]; then
    cp "$template_file" "$project_file"
    echo "$rel_path" >> "$updated_files"
  else
    echo "$rel_path (would update)" >> "$updated_files"
  fi
  ((count_updated++)) || true
done < <(find "$TEMPLATE_DIR" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.ts" \) 2>/dev/null | sort)

# Report
echo -e "${GREEN}=== Sync Report ===${NC}"
echo ""

if [[ -s "$updated_files" ]]; then
  echo -e "${YELLOW}Updated ($count_updated):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$updated_files"
  echo ""
fi

if [[ -s "$added_files" ]]; then
  echo -e "${GREEN}Added ($count_added):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$added_files"
  echo ""
fi

if [[ -s "$skipped_files" ]]; then
  echo -e "${BLUE}Skipped ($count_skipped):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$skipped_files"
  echo ""
fi

if [[ -s "$protected_files" ]]; then
  echo -e "${RED}Protected (review manually):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$protected_files"
  echo ""
fi

echo -e "${BLUE}Summary:${NC}"
echo "  Up to date: $count_up_to_date"
echo "  Updated:    $count_updated"
echo "  Added:      $count_added"
echo "  Skipped:    $count_skipped (tools not enabled)"
echo "  Protected:  $count_protected"
echo ""

if [[ "$MODE" == "report" ]]; then
  echo -e "${YELLOW}Report mode - no changes made${NC}"
elif [[ $count_updated -gt 0 || $count_added -gt 0 ]]; then
  echo -e "${GREEN}Sync complete.${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. git diff .claude/  # Review changes"
  echo "  2. git add .claude/ && git commit -m 'chore: sync claude config'"

  # Check if agents need rebuild
  if grep -q "agents-src/" "$updated_files" "$added_files" 2>/dev/null; then
    echo ""
    echo -e "${YELLOW}Agent YAMLs changed. Rebuild with:${NC}"
    echo "  npx tsx .claude/scripts/build-agents.ts"
  fi
else
  echo -e "${GREEN}Everything up to date.${NC}"
fi
