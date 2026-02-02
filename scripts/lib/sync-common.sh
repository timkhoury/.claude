#!/usr/bin/env bash
# sync-common.sh - Shared functions for template/project sync scripts
#
# Source this file after common.sh:
#   source "$HOME/.claude/scripts/lib/common.sh"
#   source "$HOME/.claude/scripts/lib/sync-common.sh"
#
# Provides:
#   - Shared constants (paths, patterns)
#   - Skill path flattening
#   - Protected file detection
#   - File finding utilities

# Prevent double-sourcing
[[ -n "${_SYNC_COMMON_SH_LOADED:-}" ]] && return 0
_SYNC_COMMON_SH_LOADED=1

# ==============================================================================
# Shared paths
# ==============================================================================

TEMPLATE_DIR="$HOME/.claude/template"
PROJECT_DIR=".claude"
CONFIG_FILE="$HOME/.claude/config/sync-config.yaml"
CHANGELOG_FILE="$HOME/.claude/config/changelog.yaml"

# ==============================================================================
# Skill categories (used for path flattening)
# Template organizes skills by category, projects flatten them
# ==============================================================================

SKILL_CATEGORIES="authoring|quality|workflow|automation|meta|tech|tools"
SKILL_CATEGORIES_ARRAY=(authoring quality workflow automation meta tech tools)

# ==============================================================================
# Protected patterns (files that should not be auto-synced)
# ==============================================================================

PROTECTED_PATTERNS="CLAUDE.md|agents-src/_project.yaml"

# ==============================================================================
# File type patterns
# ==============================================================================

# Syncable file extensions for Claude Code config
SYNCABLE_EXTENSIONS=("*.md" "*.yaml" "*.ts" "*.sh")

# ==============================================================================
# Functions
# ==============================================================================

# Check if file matches protected patterns
# Usage: if is_protected "path/to/file"; then ...
is_protected() {
  local file="$1"
  echo "$file" | grep -qE "^($PROTECTED_PATTERNS)$"
}

# Flatten skill path from template structure to project structure
# Template: skills/{category}/{skill}/ or skills/tools/{tool}/{skill}/
# Project:  skills/{skill}/
#
# Usage: flat_path=$(flatten_skill_path "skills/quality/rules-review/SKILL.md")
# Returns: skills/rules-review/SKILL.md
flatten_skill_path() {
  local rel_path="$1"

  # Handle tools: skills/tools/{tool}/{skill}/ -> skills/{skill}/
  if [[ "$rel_path" =~ ^skills/tools/[^/]+/([^/]+/.+)$ ]]; then
    echo "skills/${BASH_REMATCH[1]}"
  # Handle categories: skills/{category}/{skill}/ -> skills/{skill}/
  elif [[ "$rel_path" =~ ^skills/($SKILL_CATEGORIES)/([^/]+/.+)$ ]]; then
    echo "skills/${BASH_REMATCH[2]}"
  else
    echo "$rel_path"
  fi
}

# Expand skill path from project structure to find in template
# Project:  skills/{skill}/
# Template: skills/{category}/{skill}/ or skills/tools/{tool}/{skill}/
#
# Usage: template_path=$(expand_skill_path "skills/rules-review/SKILL.md")
# Returns: skills/quality/rules-review/SKILL.md (if found) or empty
expand_skill_path() {
  local rel_path="$1"
  local skill_name file_name

  # Only process flattened skill paths
  if [[ ! "$rel_path" =~ ^skills/([^/]+)/(.+)$ ]]; then
    return
  fi

  skill_name="${BASH_REMATCH[1]}"
  file_name="${BASH_REMATCH[2]}"

  # Skip if already a category or project-specific
  if [[ "$skill_name" =~ ^($SKILL_CATEGORIES|project)$ ]]; then
    return
  fi

  # Check standard categories
  for category in "${SKILL_CATEGORIES_ARRAY[@]}"; do
    local candidate="$TEMPLATE_DIR/skills/$category/$skill_name/$file_name"
    if [[ -f "$candidate" ]]; then
      echo "skills/$category/$skill_name/$file_name"
      return
    fi
  done

  # Check tools subdirectories
  if [[ -d "$TEMPLATE_DIR/skills/tools" ]]; then
    while IFS= read -r tool_dir; do
      local candidate="$tool_dir/$skill_name/$file_name"
      if [[ -f "$candidate" ]]; then
        echo "skills/tools/$(basename "$tool_dir")/$skill_name/$file_name"
        return
      fi
    done < <(find "$TEMPLATE_DIR/skills/tools" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi
}

# Find all syncable files in a directory
# Usage: while IFS= read -r file; do ...; done < <(find_syncable_files "$dir")
find_syncable_files() {
  local dir="$1"
  find "$dir" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.ts" -o -name "*.sh" \) | sort
}

# Create temp files for sync reporting with automatic cleanup
# Usage: setup_sync_temp_files
# Sets: $changed_files, $added_files, $protected_files, etc.
setup_sync_temp_files() {
  changed_files=$(mktemp)
  added_files=$(mktemp)
  protected_files=$(mktemp)
  skipped_files=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm -f $changed_files $added_files $protected_files $skipped_files" EXIT
}

# ==============================================================================
# Changelog and Syncignore Functions
# ==============================================================================

# Check if path was intentionally deleted from template (in changelog)
# Usage: if was_deleted_from_template "rules/workflow/old-rule.md"; then ...
was_deleted_from_template() {
  local path="$1"
  [[ -f "$CHANGELOG_FILE" ]] || return 1
  # Look for delete entries matching this path
  grep -A1 "type: delete" "$CHANGELOG_FILE" 2>/dev/null | grep -q "path: $path"
}

# Check if path was renamed in template (in changelog)
# Usage: if was_renamed_in_template "skills/old-path/SKILL.md"; then ...
# Returns the new path via stdout if found
get_renamed_path() {
  local path="$1"
  [[ -f "$CHANGELOG_FILE" ]] || return 1
  # Look for rename entries matching this path as 'from'
  local entry
  entry=$(awk -v path="$path" '
    /type: rename/ { in_rename=1; next }
    in_rename && /from:/ && $2 == path { found=1; next }
    in_rename && found && /to:/ { print $2; exit }
    /^[^ ]/ || /^  -/ { in_rename=0; found=0 }
  ' "$CHANGELOG_FILE" 2>/dev/null)
  [[ -n "$entry" ]] && echo "$entry" && return 0
  return 1
}

# Check if path is ignored by project (.syncignore)
# Usage: if is_syncignored "skills/some-skill/"; then ...
is_syncignored() {
  local path="$1"
  local syncignore_file="${PROJECT_DIR:-.claude}/.syncignore"
  [[ -f "$syncignore_file" ]] || return 1

  # Check each pattern in .syncignore (supports globs)
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    # Skip empty lines and comments
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    # Remove trailing whitespace
    pattern="${pattern%"${pattern##*[![:space:]]}"}"
    # Check if path matches pattern (supports * and ** globs)
    # shellcheck disable=SC2053
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
    # Also check if path starts with pattern (for directory patterns)
    if [[ "$pattern" == */ && "$path" == "$pattern"* ]]; then
      return 0
    fi
  done < "$syncignore_file"
  return 1
}
