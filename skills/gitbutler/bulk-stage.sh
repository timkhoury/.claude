#!/usr/bin/env bash
# bulk-stage.sh - Stage multiple files to a GitButler branch one at a time
#
# Usage: bulk-stage.sh <branch> <file1> [file2] [file3] ...
#        bulk-stage.sh --dry-run <branch> <file1> [file2] ...
#
# This script handles the GitButler limitation where file IDs shift after
# each stage operation. It runs but status before each stage to get the
# current file ID.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false

usage() {
    echo "Usage: $(basename "$0") [--dry-run] <branch> <file1> [file2] ..."
    echo ""
    echo "Stage multiple files to a GitButler branch, refreshing IDs between each."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be staged without actually staging"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") my-branch src/file1.ts src/file2.ts"
    echo "  $(basename "$0") --dry-run feature-x src/*.ts"
    exit 0
}

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -lt 2 ]]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $(basename "$0") [--dry-run] <branch> <file1> [file2] ..."
    exit 1
fi

BRANCH="$1"
shift
FILES=("$@")

echo -e "${BLUE}Staging ${#FILES[@]} file(s) to branch: ${BRANCH}${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}(dry-run mode - no changes will be made)${NC}"
fi
echo ""

# Track results (use || true to avoid bash arithmetic exit code quirk)
staged=0
failed=0
not_found=0

for filepath in "${FILES[@]}"; do
    # Get current file status
    status_output=$(but status -f 2>/dev/null || true)

    # Find the file ID by matching the filepath
    # Format: "g0 A rules/template-rules.md" -> extract "g0"
    # The file path is at the end of each line, ID is at the start
    file_id=""

    while IFS= read -r line; do
        # File lines look like: "┊   g0 A rules/template-rules.md"
        # Extract: ID (g0), status (A), and path (rules/template-rules.md)
        # The ID is 2+ alphanumeric chars, status is single letter, path is rest
        if [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]]+([^[:space:]].*[^[:space:]])[[:space:]]*$ ]]; then
            line_id="${BASH_REMATCH[1]}"
            line_path="${BASH_REMATCH[3]}"

            # Check if this line matches our target file
            if [[ "$line_path" == "$filepath" ]]; then
                file_id="$line_id"
                break
            fi
        fi
    done <<< "$status_output"

    if [[ -z "$file_id" ]]; then
        echo -e "${YELLOW}  skip${NC} $filepath (not found in uncommitted changes)"
        ((not_found++)) || true
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}  would stage${NC} $filepath (id: $file_id)"
        ((staged++)) || true
    else
        echo -e "${BLUE}  staging${NC} $filepath (id: $file_id)..."
        if but stage "$file_id" "$BRANCH" 2>/dev/null; then
            echo -e "${GREEN}    done${NC}"
            ((staged++)) || true
        else
            echo -e "${RED}    failed${NC}"
            ((failed++)) || true
        fi
    fi
done

echo ""
echo -e "${BLUE}Summary:${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "  Would stage: ${GREEN}$staged${NC}"
else
    echo -e "  Staged: ${GREEN}$staged${NC}"
fi
if [[ $failed -gt 0 ]]; then
    echo -e "  Failed: ${RED}$failed${NC}"
fi
if [[ $not_found -gt 0 ]]; then
    echo -e "  Not found: ${YELLOW}$not_found${NC}"
fi

# Exit with appropriate code
if [[ $failed -gt 0 ]]; then
    exit 1
elif [[ $staged -eq 0 ]]; then
    exit 1
else
    exit 0
fi
