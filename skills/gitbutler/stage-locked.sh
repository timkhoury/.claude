#!/usr/bin/env bash
# stage-locked.sh - Detect and stage locked files to their correct branches
#
# Usage: stage-locked.sh [--dry-run] [--auto]
#
# When files are locked (🔒) to a specific branch, they must be staged to
# that branch. This script detects locked files and stages them appropriately.

set -euo pipefail

# Source shared library
source "$HOME/.claude/scripts/lib/common.sh"

DRY_RUN=false
AUTO=false

usage() {
    echo "Usage: $(basename "$0") [--dry-run] [--auto]"
    echo ""
    echo "Detect and stage locked files to their correct branches."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show locked files without staging them"
    echo "  --auto       Automatically stage all locked files to their branches"
    echo "  --help       Show this help message"
    echo ""
    echo "Without --auto, shows locked files and prompts for confirmation."
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")              # Interactive mode"
    echo "  $(basename "$0") --dry-run    # Just show locked files"
    echo "  $(basename "$0") --auto       # Stage all automatically"
    exit 0
}

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --auto)
            AUTO=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# Validate GitButler is available
validate_gitbutler

info "Scanning for locked files..."
echo ""

# Get status output
if ! status_output=$(get_but_status); then
    die "Failed to get GitButler status"
fi

# Parse locked files
# Locked files appear with 🔒 and show which branch/commit they're locked to
# Format varies but typically: "🔒 locked to <branch>" or shows in a locked section

declare -A locked_files  # file_id -> branch
declare -A file_paths    # file_id -> path

current_locked_branch=""

while IFS= read -r line; do
    # Check for locked section markers
    # Format: "┊  🔒 locked to [branch-name]" or similar
    if [[ "$line" =~ 🔒.*locked.*\[([^\]]+)\] ]]; then
        current_locked_branch="${BASH_REMATCH[1]}"
        continue
    fi

    # Also check for inline lock indicator
    if [[ "$line" =~ 🔒 ]]; then
        # Try to extract branch from same line
        if [[ "$line" =~ \[([^\]]+)\] ]]; then
            current_locked_branch="${BASH_REMATCH[1]}"
        fi
    fi

    # If we're in a locked section, capture file entries
    if [[ -n "$current_locked_branch" ]]; then
        # Match file line: "   g0 M src/file.ts"
        if [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]]+([^[:space:]].*[^[:space:]])[[:space:]]*$ ]]; then
            file_id="${BASH_REMATCH[1]}"
            file_path="${BASH_REMATCH[3]}"
            locked_files["$file_id"]="$current_locked_branch"
            file_paths["$file_id"]="$file_path"
        fi
    fi

    # Reset locked branch when we hit a new section (branch header or unstaged)
    if [[ "$line" =~ ╭┄ ]] && [[ ! "$line" =~ 🔒 ]]; then
        current_locked_branch=""
    fi
done <<< "$status_output"

# Also look for the simpler format where lock icon appears on the file line itself
while IFS= read -r line; do
    if [[ "$line" =~ 🔒 ]] && [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]]+(.+)🔒[[:space:]]*\[([^\]]+)\] ]]; then
        file_id="${BASH_REMATCH[1]}"
        file_path="${BASH_REMATCH[3]}"
        locked_branch="${BASH_REMATCH[4]}"
        # Trim whitespace from path
        file_path="${file_path%"${file_path##*[![:space:]]}"}"
        locked_files["$file_id"]="$locked_branch"
        file_paths["$file_id"]="$file_path"
    fi
done <<< "$status_output"

if [[ ${#locked_files[@]} -eq 0 ]]; then
    echo -e "${GREEN}No locked files found.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found ${#locked_files[@]} locked file(s):${NC}"
echo ""

for file_id in "${!locked_files[@]}"; do
    branch="${locked_files[$file_id]}"
    path="${file_paths[$file_id]}"
    echo -e "  ${CYAN}$file_id${NC} $path -> ${BLUE}$branch${NC}"
done

echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}(dry-run mode - no changes made)${NC}"
    exit 0
fi

if [[ "$AUTO" != true ]]; then
    echo -n "Stage all locked files to their branches? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}Staging locked files...${NC}"

staged=0
failed=0

for file_id in "${!locked_files[@]}"; do
    branch="${locked_files[$file_id]}"
    path="${file_paths[$file_id]}"

    # Re-fetch current ID for this file (IDs may have shifted)
    current_status=$(but status -f 2>/dev/null || true)
    current_id=""

    while IFS= read -r line; do
        if [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]]+([^[:space:]].*[^[:space:]])[[:space:]]*$ ]]; then
            line_id="${BASH_REMATCH[1]}"
            line_path="${BASH_REMATCH[3]}"
            if [[ "$line_path" == "$path" ]]; then
                current_id="$line_id"
                break
            fi
        fi
    done <<< "$current_status"

    if [[ -z "$current_id" ]]; then
        echo -e "  ${YELLOW}skip${NC} $path (no longer in uncommitted changes)"
        continue
    fi

    echo -e "  ${BLUE}staging${NC} $path (id: $current_id) -> $branch"
    if but stage "$current_id" "$branch" 2>/dev/null; then
        echo -e "    ${GREEN}done${NC}"
        ((staged++)) || true
    else
        echo -e "    ${RED}failed${NC}"
        ((failed++)) || true
    fi
done

echo ""
echo -e "${BLUE}Summary:${NC}"
echo -e "  Staged: ${GREEN}$staged${NC}"
if [[ $failed -gt 0 ]]; then
    echo -e "  Failed: ${RED}$failed${NC}"
fi
