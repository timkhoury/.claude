#!/usr/bin/env bash
# resolve-ambiguous.sh - Handle ID ambiguity when staging files
#
# Usage: resolve-ambiguous.sh <branch> <file-path> [commit-message]
#
# When `but stage` fails because a short ID matches both an uncommitted file
# AND a committed file, this script uses the git add workaround:
# 1. git add <file-path>
# 2. but commit <branch> -m "message" (without --only)
# 3. Optionally squash into previous commit

set -euo pipefail

# Source shared library
source "$HOME/.claude/scripts/lib/common.sh"

usage() {
    echo "Usage: $(basename "$0") <branch> <file-path> [commit-message]"
    echo ""
    echo "Handle ID ambiguity when but stage fails."
    echo ""
    echo "Arguments:"
    echo "  branch          Target branch name"
    echo "  file-path       Path to the file to stage"
    echo "  commit-message  Optional commit message (default: 'wip: stage ambiguous file')"
    echo ""
    echo "Options:"
    echo "  --squash        Squash into the most recent commit on the branch"
    echo "  --dry-run       Show what would be done without doing it"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") my-branch src/file.ts"
    echo "  $(basename "$0") my-branch src/file.ts 'feat: add feature'"
    echo "  $(basename "$0") --squash my-branch src/file.ts"
    exit 0
}

DRY_RUN=false
SQUASH=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --squash)
            SQUASH=true
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
    die "Missing arguments. Usage: $(basename "$0") [--squash] [--dry-run] <branch> <file-path> [commit-message]"
fi

BRANCH="$1"
FILE_PATH="$2"
COMMIT_MSG="${3:-wip: stage ambiguous file}"

# Validate GitButler is available
validate_gitbutler

# Verify file exists
validate_file_exists "$FILE_PATH"

info "Resolving ambiguous file staging"
echo -e "  Branch: $BRANCH"
echo -e "  File: $FILE_PATH"
echo -e "  Message: $COMMIT_MSG"
if [[ "$SQUASH" == true ]]; then
    echo -e "  ${YELLOW}Will squash into previous commit${NC}"
fi
if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${YELLOW}(dry-run mode)${NC}"
fi
echo ""

# Get the most recent commit on the branch before we add ours (for squashing)
if [[ "$SQUASH" == true ]]; then
    # Parse but status to find the branch's most recent commit
    status_output=$(but status -v 2>/dev/null || true)
    # Look for commit IDs under this branch
    prev_commit=$(echo "$status_output" | grep -A5 "\[$BRANCH\]" | grep -oE '^[a-z][a-z0-9]+' | head -1 || true)
    if [[ -z "$prev_commit" ]]; then
        echo -e "${YELLOW}Warning: No previous commit found on branch '$BRANCH' to squash into${NC}"
        SQUASH=false
    else
        echo -e "  Previous commit: $prev_commit"
    fi
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}Would run:${NC}"
    echo "  git add \"$FILE_PATH\""
    echo "  but commit $BRANCH -m \"$COMMIT_MSG\""
    if [[ "$SQUASH" == true ]]; then
        echo "  but rub <new-commit> $prev_commit"
    fi
    exit 0
fi

# Step 1: Stage with git
echo -e "${BLUE}Step 1:${NC} git add \"$FILE_PATH\""
git add "$FILE_PATH"
echo -e "${GREEN}  done${NC}"

# Step 2: Commit without --only (includes git-staged files)
echo -e "${BLUE}Step 2:${NC} but commit $BRANCH -m \"$COMMIT_MSG\""
but commit "$BRANCH" -m "$COMMIT_MSG"
echo -e "${GREEN}  done${NC}"

# Step 3: Squash if requested
if [[ "$SQUASH" == true ]]; then
    # Get the new commit ID
    new_status=$(but status -v 2>/dev/null || true)
    new_commit=$(echo "$new_status" | grep -A5 "\[$BRANCH\]" | grep -oE '^[a-z][a-z0-9]+' | head -1 || true)

    if [[ -n "$new_commit" && "$new_commit" != "$prev_commit" ]]; then
        echo -e "${BLUE}Step 3:${NC} but rub $new_commit $prev_commit"
        but rub "$new_commit" "$prev_commit"
        echo -e "${GREEN}  done${NC}"
    else
        echo -e "${YELLOW}Warning: Could not identify new commit for squashing${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Successfully staged ambiguous file${NC}"
but status
