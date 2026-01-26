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
