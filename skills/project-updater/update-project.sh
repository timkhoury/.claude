#!/usr/bin/env bash
# Update project .claude/ from ~/.claude/template/
# Usage: update-project.sh [--help]
#
# Report-only: Shows what differs between template and project.
# Claude reads the report and decides which files to copy.
#
# Uses tech detection to identify relevant rules:
#   - Always checks: meta/, patterns/, workflow/ rules
#   - Tech-specific: Only checks rules for detected technologies
#   - Never syncs: project/ directories (project-specific)
#
# Tool detection for workflow files:
#   .beads/   → includes beads rules/skills/commands
#   openspec/ → includes openspec rules

set -eo pipefail

# Source shared libraries
source "$HOME/.claude/scripts/lib/common.sh"
source "$HOME/.claude/scripts/lib/sync-common.sh"

# Script-specific paths
DETECT_SCRIPT="$HOME/.claude/scripts/detect-technologies.sh"
HOOKS_SCRIPT="$HOME/.claude/skills/project-updater/sync-hooks.sh"

# Excluded files (skip entirely, not synced to projects)
# Note: hooks/ is synced separately via sync-hooks.sh and copied in setup-project.sh
EXCLUDED_PATTERNS="README.md|rules/project/|skills/project/"

# Detect enabled tools (for workflow files)
HAS_BEADS=false
HAS_OPENSPEC=false
[[ -d ".beads" ]] && HAS_BEADS=true
[[ -d "openspec" ]] && HAS_OPENSPEC=true

# Files that require specific tools (for workflow detection)
# Paths match template structure (before flattening)
BEADS_FILES="rules/workflow/beads-workflow.md|skills/tools/beads/|skills/workflow/work/|commands/work.md|commands/status.md|commands/wrap.md"
OPENSPEC_FILES="rules/workflow/openspec.md|skills/tools/openspec/"
BEADS_AND_OPENSPEC_FILES="rules/workflow/workflow-integration.md"

# Get detected technologies and required rules/skills
DETECTED_RULES=""
DETECTED_SKILLS=""
DETECTED_TECHS=""
if [[ -x "$DETECT_SCRIPT" ]]; then
  DETECTED_RULES=$("$DETECT_SCRIPT" --rules 2>/dev/null || true)
  DETECTED_SKILLS=$("$DETECT_SCRIPT" --skills 2>/dev/null || true)
  DETECTED_TECHS=$("$DETECT_SCRIPT" --techs 2>/dev/null || true)
fi

# Parse arguments
case "${1:-}" in
  --help|-h)
    echo "Usage: update-project.sh"
    echo ""
    echo "Report-only: Shows what differs between template and project."
    echo "Claude reads the report and decides which files to copy."
    echo ""
    echo "Tech detection:"
    echo "  Uses ~/.claude/scripts/detect-technologies.sh to identify"
    echo "  rules for detected technologies (package.json, config files)."
    echo ""
    echo "Tool detection:"
    echo "  .beads/   directory → checks beads rules/skills/commands"
    echo "  openspec/ directory → checks openspec rules"
    exit 0
    ;;
  "")
    # No arguments - report mode (the only mode)
    ;;
  *)
    echo "Unknown argument: $1"
    echo "Usage: update-project.sh [--help]"
    exit 1
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
count_changed=0
count_added=0
count_protected=0
count_skipped=0
count_unused=0
count_syncignored=0
count_changelog_deleted=0

# Temp files for reporting (from sync-common.sh: changed_files, added_files, protected_files, skipped_files)
setup_sync_temp_files
unused_files=$(mktemp)
syncignored_files=$(mktemp)
changelog_deleted_files=$(mktemp)
# shellcheck disable=SC2064
trap "rm -f $changed_files $added_files $protected_files $skipped_files $unused_files $syncignored_files $changelog_deleted_files" EXIT

# Extended is_protected check (adds PROJECT-SPECIFIC marker check)
is_protected_extended() {
  local file="$1"
  if is_protected "$file"; then
    return 0
  fi
  # Also check for PROJECT-SPECIFIC marker
  if [[ -f "$PROJECT_DIR/$file" ]] && grep -q "PROJECT-SPECIFIC" "$PROJECT_DIR/$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Check if tech rule should be synced based on detection
should_sync_tech_rule() {
  local file="$1"

  # Only applies to tech rules
  if [[ ! "$file" =~ ^rules/tech/ ]]; then
    return 0  # Not a tech rule, proceed with sync
  fi

  # If no detection script or no rules detected, sync everything
  if [[ -z "$DETECTED_RULES" ]]; then
    return 0
  fi

  # Detection script outputs "tech/x.md", template has "rules/tech/x.md"
  local tech_path="${file#rules/}"

  # Check if this rule is in the detected list
  if echo "$DETECTED_RULES" | grep -qF "$tech_path"; then
    return 0  # Rule needed, sync it
  fi

  return 1  # Rule not needed for detected technologies
}

# Check if tech skill should be synced based on detection
should_sync_tech_skill() {
  local file="$1"

  # Only applies to tech skills (skills/tech/*)
  if [[ ! "$file" =~ ^skills/tech/ ]]; then
    return 0  # Not a tech skill, proceed with sync
  fi

  # If no detection script or no skills detected, sync everything
  if [[ -z "$DETECTED_SKILLS" ]]; then
    return 0
  fi

  # Detection script outputs "tech/x/", template has "skills/tech/x/"
  local skill_path="${file#skills/}"
  local skill_folder="${skill_path%/*}/"

  # Check if this skill is in the detected list
  if echo "$DETECTED_SKILLS" | grep -qF "$skill_folder"; then
    return 0  # Skill needed, sync it
  fi

  return 1  # Skill not needed for detected technologies
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

# Show detected technologies
if [[ -n "$DETECTED_TECHS" ]]; then
  echo -e "Technologies detected:"
  echo "$DETECTED_TECHS" | while read -r tech; do
    [[ -n "$tech" ]] && echo -e "  ${GREEN}+${NC} $tech"
  done
  echo ""
fi

echo -e "Tools detected:"
echo -e "  Beads:    $([[ "$HAS_BEADS" == "true" ]] && echo "${GREEN}yes${NC}" || echo "${YELLOW}no${NC} (.beads/ not found)")"
echo -e "  OpenSpec: $([[ "$HAS_OPENSPEC" == "true" ]] && echo "${GREEN}yes${NC}" || echo "${YELLOW}no${NC} (openspec/ not found)")"
echo ""

# Find all template files
while IFS= read -r file; do
  rel_path="${file#"$TEMPLATE_DIR"/}"
  template_file="$file"

  # Flatten skill path for project
  flat_rel_path=$(flatten_skill_path "$rel_path")
  project_file="$PROJECT_DIR/$flat_rel_path"

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

  # Check if tech rule should be synced based on detection
  if ! should_sync_tech_rule "$rel_path"; then
    ((count_skipped++)) || true
    continue
  fi

  # Check if tech skill should be synced based on detection
  if ! should_sync_tech_skill "$rel_path"; then
    ((count_skipped++)) || true
    continue
  fi

  # Check if protected
  if is_protected_extended "$rel_path"; then
    if [[ -f "$project_file" ]]; then
      if ! diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
        echo "$rel_path" >> "$protected_files"
        ((count_protected++)) || true
      fi
    fi
    continue
  fi

  # File missing in project - check why before suggesting to add
  if [[ ! -f "$project_file" ]]; then
    # Check if project opted out via .syncignore
    if is_syncignored "$flat_rel_path"; then
      echo "$flat_rel_path (per .syncignore)" >> "$syncignored_files"
      ((count_syncignored++)) || true
      continue
    fi

    # Check if this was intentionally deleted from template scope
    if was_deleted_from_template "$rel_path"; then
      echo "$flat_rel_path (removed from template)" >> "$changelog_deleted_files"
      ((count_changelog_deleted++)) || true
      continue
    fi

    # Genuinely new file - would add
    # Store both paths: project_path|template_path (for display)
    if [[ "$flat_rel_path" != "$rel_path" ]]; then
      echo "$flat_rel_path|$rel_path" >> "$added_files"
    else
      echo "$flat_rel_path" >> "$added_files"
    fi
    ((count_added++)) || true
    continue
  fi

  # Compare files
  if diff -q "$template_file" "$project_file" >/dev/null 2>&1; then
    ((count_up_to_date++)) || true
    continue
  fi

  # Files differ - would update
  # Get modification timestamps for both files
  project_mtime=$(stat -f "%m" "$project_file" 2>/dev/null || stat -c "%Y" "$project_file" 2>/dev/null)
  template_mtime=$(stat -f "%m" "$template_file" 2>/dev/null || stat -c "%Y" "$template_file" 2>/dev/null)
  project_mtime_human=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$project_file" 2>/dev/null || date -d "@$(stat -c '%Y' "$project_file")" "+%Y-%m-%d %H:%M" 2>/dev/null)
  template_mtime_human=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$template_file" 2>/dev/null || date -d "@$(stat -c '%Y' "$template_file")" "+%Y-%m-%d %H:%M" 2>/dev/null)

  if [[ "$template_mtime" -gt "$project_mtime" ]]; then
    newer="template"
  elif [[ "$project_mtime" -gt "$template_mtime" ]]; then
    newer="project"
  else
    newer="same"
  fi

  # Store: project_path|template_path|project_mtime|template_mtime|newer
  if [[ "$flat_rel_path" != "$rel_path" ]]; then
    echo "$flat_rel_path|$rel_path|$project_mtime_human|$template_mtime_human|$newer" >> "$changed_files"
  else
    echo "$flat_rel_path||$project_mtime_human|$template_mtime_human|$newer" >> "$changed_files"
  fi
  ((count_changed++)) || true
done < <(find_syncable_files "$TEMPLATE_DIR")

# Note _project.yaml if missing (starter template for project-specific rules)
if [[ ! -f "$PROJECT_DIR/agents-src/_project.yaml" ]] && [[ -f "$TEMPLATE_DIR/agents-src/_project.yaml" ]]; then
  echo "agents-src/_project.yaml (starter template)" >> "$added_files"
  ((count_added++)) || true
fi

# Check for unused tech rules in project (rules that exist but aren't needed)
if [[ -n "$DETECTED_RULES" ]] && [[ -d "$PROJECT_DIR/rules/tech" ]]; then
  while IFS= read -r project_tech_file; do
    rel_path="${project_tech_file#"$PROJECT_DIR"/}"
    tech_path="${rel_path#rules/}"

    # Check if this rule is in the detected list
    if ! echo "$DETECTED_RULES" | grep -qF "$tech_path"; then
      echo "$rel_path" >> "$unused_files"
      ((count_unused++)) || true
    fi
  done < <(find "$PROJECT_DIR/rules/tech" -name "*.md" -type f | sort)
fi

# Report
echo -e "${GREEN}=== Sync Report ===${NC}"
echo ""

if [[ -s "$changed_files" ]]; then
  echo -e "${YELLOW}Changed ($count_changed):${NC}"
  while IFS='|' read -r project_path template_path project_mtime template_mtime newer; do
    if [[ "$newer" == "template" ]]; then
      direction="${GREEN}template is newer${NC} -> sync to project"
    elif [[ "$newer" == "project" ]]; then
      direction="${RED}project is newer${NC} -> use /template-updater"
    else
      direction="same timestamp"
    fi
    echo -e "  - $project_path"
    if [[ -n "$template_path" ]]; then
      echo "      from: $template_path"
    fi
    echo -e "      template: $template_mtime  |  project: $project_mtime  ($direction)"
  done < "$changed_files"
  echo ""
fi

if [[ -s "$added_files" ]]; then
  echo -e "${GREEN}Added ($count_added):${NC}"
  while IFS= read -r f; do
    if [[ "$f" == *"|"* ]]; then
      project_path="${f%%|*}"
      template_path="${f##*|}"
      echo "  - $project_path"
      echo "      from: $template_path"
    else
      echo "  - $f"
    fi
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

if [[ -s "$syncignored_files" ]]; then
  echo -e "${BLUE}Ignored ($count_syncignored - per .syncignore):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$syncignored_files"
  echo ""
fi

if [[ -s "$changelog_deleted_files" ]]; then
  echo -e "${BLUE}Skipped ($count_changelog_deleted - removed from template):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$changelog_deleted_files"
  echo ""
fi

if [[ -s "$protected_files" ]]; then
  echo -e "${RED}Protected (review manually):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$protected_files"
  echo ""
fi

if [[ -s "$unused_files" ]]; then
  echo -e "${YELLOW}Unused (tech not detected):${NC}"
  while IFS= read -r f; do
    echo "  - $f"
  done < "$unused_files"
  echo ""
  echo -e "${YELLOW}Note: Remove unused rules manually if desired.${NC}"
  echo ""
fi

echo -e "${BLUE}Summary:${NC}"
echo "  Up to date: $count_up_to_date"
echo "  Changed:    $count_changed"
echo "  Added:      $count_added"
echo "  Skipped:    $count_skipped (tools not enabled)"
echo "  Ignored:    $count_syncignored (per .syncignore)"
echo "  Removed:    $count_changelog_deleted (removed from template)"
echo "  Protected:  $count_protected"
echo "  Unused:     $count_unused (tech not detected)"
echo ""

if [[ $count_changed -gt 0 || $count_added -gt 0 ]]; then
  echo -e "${YELLOW}Report only - no changes made${NC}"
  echo ""
  echo "Claude should review the differences and copy files as needed."
else
  echo -e "${GREEN}Everything up to date.${NC}"
fi

# Run hooks sync report
echo ""
if [[ -x "$HOOKS_SCRIPT" ]]; then
  "$HOOKS_SCRIPT" --report
fi
