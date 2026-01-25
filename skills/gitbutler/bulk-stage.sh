#!/usr/bin/env bash
# bulk-stage.sh - Stage multiple files to a GitButler branch one at a time
#
# Usage: bulk-stage.sh <branch> <file1> [file2] [file3] ...
#        bulk-stage.sh --dry-run <branch> <file1> [file2] ...
#        bulk-stage.sh --verbose <branch> <file1> [file2] ...
#
# This script handles the GitButler limitation where file IDs shift after
# each stage operation. It runs but status before each stage to get the
# current file ID.

set -euo pipefail

# Source shared library
source "$HOME/.claude/scripts/lib/common.sh"

DRY_RUN=false
VERBOSE=false

usage() {
    echo "Usage: $(basename "$0") [--dry-run] [--verbose] <branch> <file1> [file2] ..."
    echo ""
    echo "Stage multiple files to a GitButler branch, refreshing IDs between each."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be staged without actually staging"
    echo "  --verbose    Show detailed output including commands being run"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") my-branch src/file1.ts src/file2.ts"
    echo "  $(basename "$0") --dry-run feature-x src/*.ts"
    echo "  $(basename "$0") --verbose my-branch src/file.ts"
    exit 0
}

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
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
    die "Missing arguments. Usage: $(basename "$0") [--dry-run] <branch> <file1> [file2] ..."
fi

BRANCH="$1"
shift
FILES=("$@")

# Validate GitButler is available
validate_gitbutler

# Validate branch name
validate_branch "$BRANCH"

info "Staging ${#FILES[@]} file(s) to branch: ${BRANCH}"
if [[ "$DRY_RUN" == true ]]; then
    warn "(dry-run mode - no changes will be made)"
fi
echo ""

# Track results (use || true to avoid bash arithmetic exit code quirk)
staged=0
failed=0
not_found=0

for filepath in "${FILES[@]}"; do
    # Check if file exists on disk
    if [[ ! -e "$filepath" ]]; then
        warn "File does not exist: $filepath"
        ((not_found++)) || true
        continue
    fi

    # Get current file status using shared helper
    if ! status_output=$(get_but_status); then
        warn "Failed to get GitButler status"
        ((failed++)) || true
        continue
    fi

    # Find the file ID using shared helper
    file_id=$(get_file_id "$status_output" "$filepath")

    if [[ -z "$file_id" ]]; then
        warn "skip $filepath (not in uncommitted changes - may already be staged or unmodified)"
        ((not_found++)) || true
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "  would stage $filepath (id: $file_id)"
        ((staged++)) || true
    else
        info "  staging $filepath (id: $file_id)..."
        [[ "$VERBOSE" == true ]] && echo "    Running: but stage $file_id $BRANCH"
        if stage_output=$(but stage "$file_id" "$BRANCH" 2>&1); then
            success "    done"
            ((staged++)) || true
        else
            echo -e "${RED}    failed: ${stage_output}${NC}"
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
