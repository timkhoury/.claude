#!/usr/bin/env bash
# branch-health.sh - Overview of branch status and health
#
# Usage: branch-health.sh [--json]
#
# Shows:
# - Branches with unpushed commits
# - Branches with uncommitted changes
# - Remote sync status
# - Merge/rebase status

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

JSON_OUTPUT=false

usage() {
    echo "Usage: $(basename "$0") [--json]"
    echo ""
    echo "Show branch health overview."
    echo ""
    echo "Options:"
    echo "  --json    Output in JSON format"
    echo "  --help    Show this help message"
    exit 0
}

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Get status outputs
status_output=$(but status -v 2>/dev/null || true)
pull_check=$(but pull --check 2>/dev/null || true)

# Parse branches and their state
declare -A branches           # branch_name -> commit_count
declare -A branch_pushed      # branch_name -> true/false
declare -A branch_staged      # branch_name -> staged_file_count
declare -A branch_commits     # branch_name -> commit_ids

current_branch=""
in_staged_section=false
staged_count=0

while IFS= read -r line; do
    # Detect branch header: "╭┄tk [tk-branch-1] (no commits)" or "╭┄tk [tk-branch-1]"
    if [[ "$line" =~ ╭┄([a-z]+)[[:space:]]+\[([^\]]+)\] ]]; then
        # Save previous branch's staged count
        if [[ -n "$current_branch" ]]; then
            branch_staged["$current_branch"]=$staged_count
        fi

        branch_id="${BASH_REMATCH[1]}"
        current_branch="${BASH_REMATCH[2]}"
        in_staged_section=false
        staged_count=0

        # Check for "no commits" or count commits
        if [[ "$line" =~ \(no\ commits\) ]]; then
            branches["$current_branch"]=0
        elif [[ "$line" =~ \(([0-9]+)\ commit ]]; then
            branches["$current_branch"]="${BASH_REMATCH[1]}"
        else
            branches["$current_branch"]=0
        fi

        # Check if pushed (has origin reference)
        if [[ "$line" =~ \[origin/ ]]; then
            branch_pushed["$current_branch"]=true
        else
            branch_pushed["$current_branch"]=false
        fi
        continue
    fi

    # Detect staged section: "╭┄m0 [staged to branch-name]"
    if [[ "$line" =~ \[staged\ to\ ([^\]]+)\] ]]; then
        staged_branch="${BASH_REMATCH[1]}"
        in_staged_section=true
        continue
    fi

    # Count staged files
    if [[ "$in_staged_section" == true ]]; then
        if [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]] ]]; then
            ((staged_count++)) || true
        fi
        # End of staged section
        if [[ "$line" =~ ╭┄ ]] || [[ "$line" =~ ^┊╭ ]]; then
            in_staged_section=false
            if [[ -n "${staged_branch:-}" ]]; then
                branch_staged["$staged_branch"]=$staged_count
            fi
            staged_count=0
        fi
    fi

    # Detect commit lines under a branch
    if [[ -n "$current_branch" ]] && [[ "$line" =~ ^[[:space:]]*([a-f0-9]{7}) ]]; then
        commit_id="${BASH_REMATCH[1]}"
        if [[ -z "${branch_commits[$current_branch]:-}" ]]; then
            branch_commits["$current_branch"]="$commit_id"
        else
            branch_commits["$current_branch"]="${branch_commits[$current_branch]},$commit_id"
        fi
    fi
done <<< "$status_output"

# Save last branch's staged count
if [[ -n "$current_branch" ]]; then
    branch_staged["$current_branch"]=$staged_count
fi

# Parse upstream status
upstream_commits=0
if [[ "$pull_check" =~ ([0-9]+)\ new\ commits ]]; then
    upstream_commits="${BASH_REMATCH[1]}"
fi

base_branch=""
if [[ "$pull_check" =~ Base\ branch:[[:space:]]+([^[:space:]]+) ]]; then
    base_branch="${BASH_REMATCH[1]}"
fi

# Count unstaged files
unstaged_count=0
while IFS= read -r line; do
    if [[ "$line" =~ \[unstaged\ changes\] ]]; then
        continue
    fi
    if [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]] ]]; then
        ((unstaged_count++)) || true
    fi
done <<< "$(echo "$status_output" | sed -n '/\[unstaged changes\]/,/╭┄[a-z]/p' | sed '$d')"

# Output
if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{"
    echo "  \"base_branch\": \"$base_branch\","
    echo "  \"upstream_commits\": $upstream_commits,"
    echo "  \"unstaged_files\": $unstaged_count,"
    echo "  \"branches\": {"

    first=true
    for branch in "${!branches[@]}"; do
        if [[ "$first" != true ]]; then
            echo ","
        fi
        first=false
        commits="${branches[$branch]}"
        pushed="${branch_pushed[$branch]:-false}"
        staged="${branch_staged[$branch]:-0}"
        echo -n "    \"$branch\": {\"commits\": $commits, \"pushed\": $pushed, \"staged_files\": $staged}"
    done
    echo ""
    echo "  }"
    echo "}"
    exit 0
fi

# Human-readable output
echo -e "${BLUE}Branch Health Report${NC}"
echo -e "${DIM}────────────────────${NC}"
echo ""

# Upstream status
echo -e "${CYAN}Remote Status${NC}"
if [[ $upstream_commits -gt 0 ]]; then
    echo -e "  ${YELLOW}⚠${NC}  $upstream_commits new commit(s) on $base_branch"
    echo -e "      Run ${DIM}but pull${NC} to update"
else
    echo -e "  ${GREEN}✓${NC}  Up to date with $base_branch"
fi
echo ""

# Unstaged files
if [[ $unstaged_count -gt 0 ]]; then
    echo -e "${CYAN}Unstaged Changes${NC}"
    echo -e "  ${YELLOW}⚠${NC}  $unstaged_count file(s) not assigned to any branch"
    echo ""
fi

# Branch details
if [[ ${#branches[@]} -gt 0 ]]; then
    echo -e "${CYAN}Virtual Branches${NC}"

    for branch in "${!branches[@]}"; do
        commits="${branches[$branch]}"
        pushed="${branch_pushed[$branch]:-false}"
        staged="${branch_staged[$branch]:-0}"

        # Status indicator
        if [[ "$pushed" == true ]]; then
            status_icon="${GREEN}✓${NC}"
            push_status="pushed"
        elif [[ $commits -gt 0 ]]; then
            status_icon="${YELLOW}↑${NC}"
            push_status="${YELLOW}$commits unpushed${NC}"
        else
            status_icon="${DIM}○${NC}"
            push_status="no commits"
        fi

        echo -e "  $status_icon  ${BLUE}$branch${NC}"
        echo -e "      Commits: $commits ($push_status)"

        if [[ $staged -gt 0 ]]; then
            echo -e "      Staged: $staged file(s) ready to commit"
        fi
    done
else
    echo -e "${CYAN}Virtual Branches${NC}"
    echo -e "  ${DIM}No virtual branches${NC}"
fi

echo ""
echo -e "${DIM}Run 'but status -v' for full details${NC}"
