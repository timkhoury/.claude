#!/usr/bin/env bash
# analyze-settings.sh - Analyze local vs global permissions
# Usage: analyze-settings.sh [--stale|--compare|--report]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GLOBAL_SETTINGS="$HOME/.claude/settings.json"
LOCAL_SETTINGS=".claude/settings.local.json"

MODE="${1:-report}"

# Check stale paths in global settings
check_stale_paths() {
  echo -e "${BLUE}=== Stale Path Check ===${NC}"
  echo ""

  # Extract script/skill paths from global settings, strip the :*)" suffix
  grep -oE '~/.claude/(scripts|skills)/[^":]+' "$GLOBAL_SETTINGS" 2>/dev/null | \
    sort -u | while read -r path; do
    expanded="${path/#\~/$HOME}"
    if [[ -f "$expanded" ]]; then
      echo -e "  ${GREEN}✓${NC} $path"
    else
      echo -e "  ${RED}✗${NC} $path (NOT FOUND)"
    fi
  done

  echo ""
}

# Get permissions from a settings file
get_permissions() {
  local file="$1"
  if [[ -f "$file" ]]; then
    jq -r '.permissions.allow[]? // empty' "$file" 2>/dev/null | sort
  fi
}

# Check if permission is project-specific
is_project_specific() {
  local perm="$1"

  # Absolute paths
  [[ "$perm" =~ ^Bash\(/Users/ ]] && return 0
  [[ "$perm" =~ ^Bash\(\./  ]] && return 0
  [[ "$perm" =~ ^Bash\(\.claude/scripts/ ]] && return 0
  [[ "$perm" =~ ^Bash\(\.claude/skills/ ]] && return 0

  # Environment-specific
  [[ "$perm" =~ ENV= ]] && return 0
  [[ "$perm" =~ PGPASSWORD ]] && return 0

  # Project MCP servers
  [[ "$perm" =~ ^mcp__supabase__ ]] && return 0
  [[ "$perm" =~ ^mcp__stripe__ ]] && return 0

  # Supabase local commands (project-specific)
  [[ "$perm" =~ supabase\ start ]] && return 0
  [[ "$perm" =~ supabase\ stop ]] && return 0
  [[ "$perm" =~ supabase\ db ]] && return 0
  [[ "$perm" =~ supabase\ link ]] && return 0
  [[ "$perm" =~ supabase\ migration ]] && return 0
  [[ "$perm" =~ ^Bash\(psql ]] && return 0

  # One-off commands (should be cleaned)
  [[ "$perm" =~ ^Bash\(for\ file ]] && return 0
  [[ "$perm" =~ ^Bash\(do\  ]] && return 0
  [[ "$perm" =~ ^Bash\(done\) ]] && return 0
  [[ "$perm" =~ ^Bash\(set\ \+ ]] && return 0

  return 1
}

# Check if permission is already in global (exact or wildcard)
is_in_global() {
  local perm="$1"
  local global_perms="$2"

  # Exact match
  echo "$global_perms" | grep -qxF "$perm" && return 0

  # Check wildcard coverage
  local base
  base=$(echo "$perm" | sed 's/:\*)$//' | sed 's/)$//')

  # If global has "Bash(npm run:*)" and local has "Bash(npm run test:*)", it's covered
  while [[ "$base" =~ \  ]]; do
    base="${base% *}"
    if echo "$global_perms" | grep -qF "${base}:*)"; then
      return 0
    fi
  done

  return 1
}

# Check if permission is safe to promote
is_safe() {
  local perm="$1"

  # Read-only commands are safe
  [[ "$perm" =~ status ]] && return 0
  [[ "$perm" =~ diff ]] && return 0
  [[ "$perm" =~ log ]] && return 0
  [[ "$perm" =~ show ]] && return 0
  [[ "$perm" =~ list ]] && return 0
  [[ "$perm" =~ ready ]] && return 0
  [[ "$perm" =~ test ]] && return 0
  [[ "$perm" =~ lint ]] && return 0
  [[ "$perm" =~ typecheck ]] && return 0
  [[ "$perm" =~ gen\ types ]] && return 0
  [[ "$perm" =~ version ]] && return 0

  return 1
}

# Check if permission needs confirmation (risky)
needs_confirmation() {
  local perm="$1"

  [[ "$perm" =~ commit ]] && return 0
  [[ "$perm" =~ push ]] && return 0
  [[ "$perm" =~ delete ]] && return 0
  [[ "$perm" =~ rm\  ]] && return 0
  [[ "$perm" =~ migrate ]] && return 0
  [[ "$perm" =~ deploy ]] && return 0
  [[ "$perm" =~ publish ]] && return 0

  return 1
}

# Compare local and global settings
compare_settings() {
  echo -e "${BLUE}=== Permission Comparison ===${NC}"
  echo ""

  if [[ ! -f "$LOCAL_SETTINGS" ]]; then
    echo "No local settings file found: $LOCAL_SETTINGS"
    return 0
  fi

  local global_perms local_perms
  global_perms=$(get_permissions "$GLOBAL_SETTINGS")
  local_perms=$(get_permissions "$LOCAL_SETTINGS")

  local safe=()
  local risky=()
  local project_specific=()
  local already_global=()
  local one_off=()

  while IFS= read -r perm; do
    [[ -z "$perm" ]] && continue

    # Check if it's a one-off command (should be cleaned)
    if [[ "$perm" =~ ^Bash\(for\ file ]] || [[ "$perm" =~ ^Bash\(do\  ]] || \
       [[ "$perm" =~ ^Bash\(done\) ]] || [[ "$perm" =~ ^Bash\(set\ \+ ]] || \
       [[ "$perm" =~ ^Bash\(bash:\*\) ]]; then
      one_off+=("$perm")
      continue
    fi

    if is_in_global "$perm" "$global_perms"; then
      already_global+=("$perm")
    elif is_project_specific "$perm"; then
      project_specific+=("$perm")
    elif is_safe "$perm"; then
      safe+=("$perm")
    elif needs_confirmation "$perm"; then
      risky+=("$perm")
    else
      # Default to safe if not explicitly risky
      safe+=("$perm")
    fi
  done <<< "$local_perms"

  # Output results
  if [[ ${#safe[@]} -gt 0 ]]; then
    echo -e "${GREEN}### ✅ Safe to Promote (${#safe[@]})${NC}"
    for p in "${safe[@]}"; do
      echo "  + $p"
    done
    echo ""
  fi

  if [[ ${#risky[@]} -gt 0 ]]; then
    echo -e "${YELLOW}### ⚠️ Needs Confirmation (${#risky[@]})${NC}"
    for p in "${risky[@]}"; do
      echo "  ? $p"
    done
    echo ""
  fi

  if [[ ${#project_specific[@]} -gt 0 ]]; then
    echo -e "${RED}### ❌ Keep Project-Local (${#project_specific[@]})${NC}"
    for p in "${project_specific[@]}"; do
      echo "  - $p"
    done
    echo ""
  fi

  if [[ ${#already_global[@]} -gt 0 ]]; then
    echo -e "${BLUE}### 🔄 Already Global (${#already_global[@]})${NC}"
    for p in "${already_global[@]}"; do
      echo "  = $p"
    done
    echo ""
  fi

  if [[ ${#one_off[@]} -gt 0 ]]; then
    echo -e "${YELLOW}### 🗑️ One-off Commands to Clean (${#one_off[@]})${NC}"
    for p in "${one_off[@]}"; do
      echo "  ~ $p"
    done
    echo ""
  fi

  echo "Summary:"
  echo "  Safe to promote:    ${#safe[@]}"
  echo "  Needs confirmation: ${#risky[@]}"
  echo "  Project-specific:   ${#project_specific[@]}"
  echo "  Already global:     ${#already_global[@]}"
  echo "  One-off (cleanup):  ${#one_off[@]}"
}

# Full report
full_report() {
  check_stale_paths
  compare_settings
}

# Main
case "$MODE" in
  --stale)
    check_stale_paths
    ;;
  --compare)
    compare_settings
    ;;
  --report|report)
    full_report
    ;;
  --help|-h)
    echo "Usage: analyze-settings.sh [--stale|--compare|--report]"
    echo ""
    echo "Options:"
    echo "  --stale    Check for stale paths in global settings"
    echo "  --compare  Compare local vs global permissions"
    echo "  --report   Full report (default)"
    exit 0
    ;;
  *)
    echo "Unknown option: $MODE"
    echo "Run with --help for usage"
    exit 1
    ;;
esac
