#!/usr/bin/env bash
# commit-groups.sh - Analyze uncommitted files and suggest logical commit groupings
#
# Usage: commit-groups.sh [--json]
#
# Analyzes uncommitted files and groups them by:
# - Feature code + tests
# - Configuration/tooling
# - Documentation
# - Type definitions
# - Scripts/utilities

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
NC='\033[0m'

JSON_OUTPUT=false

usage() {
    echo "Usage: $(basename "$0") [--json]"
    echo ""
    echo "Analyze uncommitted files and suggest commit groupings."
    echo ""
    echo "Options:"
    echo "  --json    Output in JSON format"
    echo "  --help    Show this help message"
    echo ""
    echo "Groups files into categories:"
    echo "  - tests: Test files"
    echo "  - docs: Documentation and markdown"
    echo "  - config: Configuration files"
    echo "  - types: Type definitions"
    echo "  - scripts: Shell scripts and utilities"
    echo "  - source: Source code (grouped by directory)"
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

# Get uncommitted files from but status
status_output=$(but status -f 2>/dev/null || true)

# Arrays for categorization
declare -a test_files=()
declare -a doc_files=()
declare -a config_files=()
declare -a type_files=()
declare -a script_files=()
declare -A source_dirs  # directory -> file list

# File info arrays
declare -A file_ids     # path -> id
declare -A file_status  # path -> status (A/M/D/R)

# Parse files from unstaged section
in_unstaged=false

while IFS= read -r line; do
    # Detect unstaged section
    if [[ "$line" =~ \[unstaged\ changes\] ]]; then
        in_unstaged=true
        continue
    fi

    # End of unstaged section (hit a branch or staged section)
    if [[ "$in_unstaged" == true ]] && [[ "$line" =~ ╭┄[a-z] ]] && [[ ! "$line" =~ \[unstaged ]]; then
        break
    fi

    # Parse file line
    if [[ "$in_unstaged" == true ]]; then
        if [[ "$line" =~ ([a-z][a-z0-9]+)[[:space:]]+([ADMR])[[:space:]]+([^[:space:]].*[^[:space:]])[[:space:]]*$ ]]; then
            file_id="${BASH_REMATCH[1]}"
            status="${BASH_REMATCH[2]}"
            filepath="${BASH_REMATCH[3]}"

            file_ids["$filepath"]="$file_id"
            file_status["$filepath"]="$status"

            # Categorize the file
            filename=$(basename "$filepath")
            dirname=$(dirname "$filepath")
            ext="${filename##*.}"

            # Test files
            if [[ "$filepath" =~ \.test\. ]] || [[ "$filepath" =~ \.spec\. ]] || \
               [[ "$filepath" =~ __tests__ ]] || [[ "$filepath" =~ /test/ ]] || \
               [[ "$filename" =~ ^test_ ]]; then
                test_files+=("$filepath")

            # Documentation
            elif [[ "$ext" == "md" ]] || [[ "$ext" == "mdx" ]] || \
                 [[ "$ext" == "txt" ]] || [[ "$ext" == "rst" ]] || \
                 [[ "$filepath" =~ /docs/ ]] || [[ "$filename" == "README" ]]; then
                doc_files+=("$filepath")

            # Configuration
            elif [[ "$filename" =~ ^\..*rc$ ]] || [[ "$filename" =~ \.config\. ]] || \
                 [[ "$filename" == "package.json" ]] || [[ "$filename" == "tsconfig.json" ]] || \
                 [[ "$filename" == "Cargo.toml" ]] || [[ "$filename" == "pyproject.toml" ]] || \
                 [[ "$filename" == "Makefile" ]] || [[ "$filename" == "Dockerfile" ]] || \
                 [[ "$filename" =~ \.ya?ml$ ]] || [[ "$filename" =~ \.toml$ ]] || \
                 [[ "$ext" == "json" && "$dirname" == "." ]]; then
                config_files+=("$filepath")

            # Type definitions
            elif [[ "$filename" =~ \.d\.ts$ ]] || [[ "$filepath" =~ /types/ ]] || \
                 [[ "$filename" == "types.ts" ]] || [[ "$filename" == "interfaces.ts" ]]; then
                type_files+=("$filepath")

            # Scripts
            elif [[ "$ext" == "sh" ]] || [[ "$ext" == "bash" ]] || \
                 [[ "$filepath" =~ /scripts/ ]] || [[ "$filepath" =~ /bin/ ]]; then
                script_files+=("$filepath")

            # Source code - group by directory
            else
                # Use first two directory levels for grouping
                if [[ "$dirname" == "." ]]; then
                    group_dir="root"
                else
                    group_dir=$(echo "$dirname" | cut -d'/' -f1-2)
                fi

                if [[ -z "${source_dirs[$group_dir]:-}" ]]; then
                    source_dirs["$group_dir"]="$filepath"
                else
                    source_dirs["$group_dir"]="${source_dirs[$group_dir]}|$filepath"
                fi
            fi
        fi
    fi
done <<< "$status_output"

# Count total files
total_files=$(( ${#test_files[@]} + ${#doc_files[@]} + ${#config_files[@]} + ${#type_files[@]} + ${#script_files[@]} ))
for dir in "${!source_dirs[@]}"; do
    IFS='|' read -ra files <<< "${source_dirs[$dir]}"
    total_files=$((total_files + ${#files[@]}))
done

if [[ $total_files -eq 0 ]]; then
    echo -e "${GREEN}No uncommitted files to group.${NC}"
    exit 0
fi

# JSON output
if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{"
    echo "  \"total_files\": $total_files,"
    echo "  \"groups\": {"

    first_group=true

    # Output each group
    output_group() {
        local name="$1"
        shift
        local files=("$@")

        if [[ ${#files[@]} -eq 0 ]]; then
            return
        fi

        if [[ "$first_group" != true ]]; then
            echo ","
        fi
        first_group=false

        echo -n "    \"$name\": ["
        first_file=true
        for f in "${files[@]}"; do
            if [[ "$first_file" != true ]]; then
                echo -n ", "
            fi
            first_file=false
            echo -n "\"$f\""
        done
        echo -n "]"
    }

    output_group "tests" "${test_files[@]}"
    output_group "docs" "${doc_files[@]}"
    output_group "config" "${config_files[@]}"
    output_group "types" "${type_files[@]}"
    output_group "scripts" "${script_files[@]}"

    # Source directories
    for dir in "${!source_dirs[@]}"; do
        IFS='|' read -ra files <<< "${source_dirs[$dir]}"
        output_group "source:$dir" "${files[@]}"
    done

    echo ""
    echo "  }"
    echo "}"
    exit 0
fi

# Human-readable output
echo -e "${BLUE}Commit Grouping Suggestions${NC}"
echo -e "${DIM}────────────────────────────${NC}"
echo -e "Total uncommitted files: $total_files"
echo ""

print_group() {
    local title="$1"
    local color="$2"
    local prefix="$3"
    shift 3
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        return
    fi

    echo -e "${color}$title${NC} (${#files[@]} files)"
    echo -e "  ${DIM}Suggested: ${prefix}${NC}"
    for f in "${files[@]}"; do
        local id="${file_ids[$f]:-??}"
        local st="${file_status[$f]:-?}"
        echo -e "    ${CYAN}$id${NC} $st $f"
    done
    echo ""
}

# Print each group with suggested commit prefix
print_group "Tests" "$GREEN" "test: ..." "${test_files[@]}"
print_group "Documentation" "$MAGENTA" "docs: ..." "${doc_files[@]}"
print_group "Configuration" "$YELLOW" "chore: ..." "${config_files[@]}"
print_group "Type Definitions" "$CYAN" "types: ... or feat: ..." "${type_files[@]}"
print_group "Scripts" "$BLUE" "chore: ... or feat: ..." "${script_files[@]}"

# Source directories
for dir in "${!source_dirs[@]}"; do
    IFS='|' read -ra files <<< "${source_dirs[$dir]}"
    print_group "Source: $dir" "$BLUE" "feat: ... or fix: ..." "${files[@]}"
done

echo -e "${DIM}Tip: Related test files should usually be committed with their source files.${NC}"
echo -e "${DIM}Use 'bulk-stage.sh <branch> <files...>' to stage multiple files.${NC}"
