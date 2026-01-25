#!/usr/bin/env bash
# common.sh - Shared functions for Claude Code shell scripts
#
# Source this file at the top of scripts:
#   source "${BASH_SOURCE%/*}/../lib/common.sh"
# Or for scripts in skills/:
#   source "$HOME/.claude/scripts/lib/common.sh"
#
# Provides:
#   - Color definitions (respects NO_COLOR)
#   - Error handling (die, warn)
#   - GitButler validation
#   - File ID extraction from but status

# Prevent double-sourcing
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return 0
_COMMON_SH_LOADED=1

# ==============================================================================
# Colors (respect NO_COLOR environment variable)
# These are exported for use by scripts that source this file
# ==============================================================================

# shellcheck disable=SC2034 # Variables are used by sourcing scripts
if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  MAGENTA='\033[0;35m'
  DIM='\033[2m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  MAGENTA=''
  DIM=''
  BOLD=''
  NC=''
fi

# ==============================================================================
# Error handling
# ==============================================================================

# Print error message and exit
# Usage: die "message" [exit_code]
die() {
  local msg="$1"
  local code="${2:-1}"
  echo -e "${RED}Error:${NC} $msg" >&2
  exit "$code"
}

# Print warning message (non-fatal)
# Usage: warn "message"
warn() {
  echo -e "${YELLOW}Warning:${NC} $1" >&2
}

# Print info message
# Usage: info "message"
info() {
  echo -e "${BLUE}$1${NC}"
}

# Print success message
# Usage: success "message"
success() {
  echo -e "${GREEN}$1${NC}"
}

# ==============================================================================
# Validation functions
# ==============================================================================

# Check if a command exists
# Usage: require_command "git" "Please install git"
require_command() {
  local cmd="$1"
  local msg="${2:-$cmd is required but not installed}"
  if ! command -v "$cmd" &>/dev/null; then
    die "$msg"
  fi
}

# Validate GitButler is installed and workspace is initialized
# Usage: validate_gitbutler
validate_gitbutler() {
  if ! command -v but &>/dev/null; then
    die "GitButler (but) not installed. Install from: https://gitbutler.com"
  fi

  # Check if we're in a GitButler workspace
  if ! but status &>/dev/null 2>&1; then
    die "Not a GitButler workspace. Run 'but setup' to initialize."
  fi
}

# Validate branch name (alphanumeric, underscore, hyphen)
# Usage: validate_branch "my-branch"
validate_branch() {
  local branch="$1"
  if [[ -z "$branch" ]]; then
    die "Branch name is required"
  fi
  if [[ ! "$branch" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    die "Invalid branch name: $branch (must start with letter, contain only alphanumeric, underscore, hyphen)"
  fi
}

# Validate file path exists
# Usage: validate_file_exists "path/to/file"
validate_file_exists() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    die "File not found: $path"
  fi
}

# ==============================================================================
# GitButler helpers
# ==============================================================================

# Get but status output with error handling
# Usage: status=$(get_but_status) || exit 1
get_but_status() {
  local flags="${1:--f}"
  local output
  if ! output=$(but status "$flags" 2>&1); then
    echo "Failed to get GitButler status: $output" >&2
    return 1
  fi
  echo "$output"
}

# Extract file ID from but status output for a given file path
# Usage: id=$(get_file_id "$status_output" "path/to/file")
# Returns empty string if not found
get_file_id() {
  local status_output="$1"
  local filepath="$2"
  local file_id=""

  # Normalize path: remove leading ./ if present
  filepath="${filepath#./}"

  while IFS= read -r line; do
    # Match file lines: "┊   g0 A path/to/file" or "┊   g0 M path/to/file 🔒 commit"
    # Pattern: ID (2+ alphanumeric), status (single letter ADMRCU), path
    # Skip prefix characters (box-drawing, spaces) with .*
    if [[ "$line" =~ [[:space:]]([[:alnum:]]{2,})[[:space:]]+([ADMRCU])[[:space:]]+(.+)$ ]]; then
      local line_id="${BASH_REMATCH[1]}"
      local line_path="${BASH_REMATCH[3]}"
      # Strip lock indicator and commit hash if present (e.g., " 🔒 a2b66f8")
      line_path="${line_path%% 🔒*}"
      # Trim trailing whitespace from path
      line_path="${line_path%"${line_path##*[![:space:]]}"}"
      # Normalize path from status output too
      line_path="${line_path#./}"

      if [[ "$line_path" == "$filepath" ]]; then
        # Validate ID is at least 2 characters
        if [[ ${#line_id} -ge 2 ]]; then
          file_id="$line_id"
          break
        fi
      fi
    fi
  done <<< "$status_output"

  echo "$file_id"
}

# Parse all files from but status into associative arrays
# Usage:
#   declare -A file_ids file_statuses
#   parse_but_files "$status_output" file_ids file_statuses
# Result: file_ids["path/to/file"]="g0", file_statuses["path/to/file"]="M"
parse_but_files() {
  local status_output="$1"
  # shellcheck disable=SC2034 # These are namerefs, used via passed array names
  local -n ids_ref="$2"
  local -n statuses_ref="$3"

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*([[:alnum:]]{2,})[[:space:]]+([ADMRCU])[[:space:]]+(.+)$ ]]; then
      local file_id="${BASH_REMATCH[1]}"
      local file_status="${BASH_REMATCH[2]}"
      local file_path="${BASH_REMATCH[3]}"
      # Trim trailing whitespace
      file_path="${file_path%"${file_path##*[![:space:]]}"}"

      ids_ref["$file_path"]="$file_id"
      statuses_ref["$file_path"]="$file_status"
    fi
  done <<< "$status_output"
}

# Stage a file with retry logic (handles ID shifting)
# Usage: stage_file_with_retry "path/to/file" "branch-name" [max_retries]
stage_file_with_retry() {
  local filepath="$1"
  local branch="$2"
  local max_retries="${3:-3}"

  for ((i=0; i<max_retries; i++)); do
    local status
    if ! status=$(get_but_status); then
      warn "Failed to get status on retry $((i+1))"
      continue
    fi

    local id
    id=$(get_file_id "$status" "$filepath")
    if [[ -z "$id" ]]; then
      warn "File not found in uncommitted changes: $filepath"
      return 1
    fi

    if but stage "$id" "$branch" 2>/dev/null; then
      return 0
    fi

    # Brief pause before retry
    sleep 0.1
  done

  warn "Failed to stage after $max_retries retries: $filepath"
  return 1
}

# ==============================================================================
# Config helpers
# ==============================================================================

# Get path to sync config
get_sync_config_path() {
  echo "$HOME/.claude/config/sync-config.yaml"
}

# Check if yq is available
has_yq() {
  command -v yq &>/dev/null
}

# Check if node is available
has_node() {
  command -v node &>/dev/null
}

# Check if jq is available
has_jq() {
  command -v jq &>/dev/null
}

# ==============================================================================
# JSON helpers
# ==============================================================================

# Escape a string for JSON output
# Usage: escaped=$(json_escape "string with \"quotes\"")
json_escape() {
  local str="$1"
  # Escape backslashes first, then quotes, then newlines
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/\\r}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

# Output a JSON array from bash array
# Usage: json_array "${items[@]}"
json_array() {
  local items=("$@")
  local first=true
  echo -n "["
  for item in "${items[@]}"; do
    [[ "$first" == true ]] || echo -n ", "
    first=false
    echo -n "\"$(json_escape "$item")\""
  done
  echo -n "]"
}

# ==============================================================================
# Input helpers
# ==============================================================================

# Read with timeout (for CI compatibility)
# Usage: read_with_timeout "prompt" variable [timeout_seconds]
read_with_timeout() {
  local prompt="$1"
  # shellcheck disable=SC2034 # This is a nameref, used via passed variable name
  local -n var_ref="$2"
  local timeout="${3:-30}"

  if [[ -t 0 ]]; then
    # Interactive terminal - use read with timeout
    echo -n "$prompt"
    if ! read -r -t "$timeout" var_ref; then
      echo ""
      warn "Input timed out after ${timeout}s"
      var_ref=""
      return 1
    fi
  else
    # Non-interactive (piped input or CI) - read without timeout
    read -r var_ref || true
  fi
  return 0
}

# Confirm action with y/N prompt
# Usage: if confirm "Proceed?"; then ...; fi
confirm() {
  local prompt="${1:-Continue?}"
  local response

  if [[ -t 0 ]]; then
    echo -n "$prompt [y/N] "
    if ! read -r -t 30 response; then
      echo ""
      return 1
    fi
    [[ "$response" =~ ^[Yy]$ ]]
  else
    # Non-interactive - default to no
    return 1
  fi
}
