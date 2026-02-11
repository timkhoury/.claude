#!/usr/bin/env bash
#
# check-tools.sh - Check installed vs latest versions of OpenSpec
#
# Usage:
#   check-tools.sh [--json|--report]
#
# Options:
#   --json      Output JSON for scripting
#   --report    Human-readable report (default)
#   --help      Show this help
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MODE="report"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            MODE="json"
            shift
            ;;
        --report)
            MODE="report"
            shift
            ;;
        --help|-h)
            echo "Usage: check-tools.sh [--json|--report]"
            echo ""
            echo "Options:"
            echo "  --json      Output JSON for scripting"
            echo "  --report    Human-readable report (default)"
            echo "  --help      Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Get installed OpenSpec version
get_openspec_installed() {
    if command -v openspec &>/dev/null; then
        openspec --version 2>/dev/null | sed 's/openspec v//' || echo ""
    else
        echo ""
    fi
}

# Get latest OpenSpec version from npm
get_openspec_latest() {
    npm info @fission-ai/openspec version 2>/dev/null || echo ""
}

# Compare versions (returns: "current", "outdated", "ahead", or "unknown")
compare_versions() {
    local installed="$1"
    local latest="$2"

    if [[ -z "$installed" ]]; then
        echo "not_installed"
        return
    fi

    if [[ -z "$latest" ]]; then
        echo "unknown"
        return
    fi

    if [[ "$installed" == "$latest" ]]; then
        echo "current"
    else
        # Simple version comparison (works for semver)
        local installed_parts latest_parts
        IFS='.' read -ra installed_parts <<< "$installed"
        IFS='.' read -ra latest_parts <<< "$latest"

        for i in 0 1 2; do
            local inst="${installed_parts[$i]:-0}"
            local lat="${latest_parts[$i]:-0}"

            # Remove any non-numeric suffix for comparison
            inst="${inst%%[^0-9]*}"
            lat="${lat%%[^0-9]*}"

            if [[ "$inst" -lt "$lat" ]]; then
                echo "outdated"
                return
            elif [[ "$inst" -gt "$lat" ]]; then
                echo "ahead"
                return
            fi
        done

        echo "current"
    fi
}

# Check OpenSpec
check_openspec() {
    local installed latest status
    installed=$(get_openspec_installed)
    latest=$(get_openspec_latest)
    status=$(compare_versions "$installed" "$latest")

    echo "$installed|$latest|$status"
}

# Output report format
output_report() {
    local tool="$1" installed="$2" latest="$3" status="$4"

    local status_icon status_color
    case "$status" in
        current)
            status_icon="[OK]"
            status_color="$GREEN"
            ;;
        outdated)
            status_icon="[UPDATE]"
            status_color="$YELLOW"
            ;;
        not_installed)
            status_icon="[MISSING]"
            status_color="$RED"
            ;;
        ahead)
            status_icon="[DEV]"
            status_color="$BLUE"
            ;;
        *)
            status_icon="[?]"
            status_color="$NC"
            ;;
    esac

    printf "${status_color}%-10s${NC} %-10s → %-10s %s\n" \
        "$status_icon" "${installed:-not installed}" "${latest:-unknown}" "$tool"
}

# Main
main() {
    local openspec_result
    local openspec_installed openspec_latest openspec_status
    local any_updates=false

    # Check OpenSpec
    openspec_result=$(check_openspec)
    IFS='|' read -r openspec_installed openspec_latest openspec_status <<< "$openspec_result"
    [[ "$openspec_status" == "outdated" ]] && any_updates=true

    # Output
    if [[ "$MODE" == "json" ]]; then
        echo "{\"tools\":{\"openspec\":{\"installed\":\"$openspec_installed\",\"latest\":\"$openspec_latest\",\"status\":\"$openspec_status\"}},\"anyUpdates\":$any_updates}"
    else
        echo "Tool Version Check"
        echo "=================="
        echo ""

        output_report "OpenSpec" "$openspec_installed" "$openspec_latest" "$openspec_status"

        echo ""
        if [[ "$any_updates" == "true" ]]; then
            echo -e "${YELLOW}Updates available. Run /tools-updater upgrade to update.${NC}"
        else
            echo -e "${GREEN}All tools are up to date.${NC}"
        fi
    fi
}

main
