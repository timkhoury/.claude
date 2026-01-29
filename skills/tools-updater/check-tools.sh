#!/usr/bin/env bash
#
# check-tools.sh - Check installed vs latest versions of OpenSpec and beads
#
# Usage:
#   check-tools.sh [--json|--report] [--tool openspec|beads]
#
# Options:
#   --json      Output JSON for scripting
#   --report    Human-readable report (default)
#   --tool      Check specific tool only
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
TOOL_FILTER=""

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
        --tool)
            TOOL_FILTER="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: check-tools.sh [--json|--report] [--tool openspec|beads]"
            echo ""
            echo "Options:"
            echo "  --json      Output JSON for scripting"
            echo "  --report    Human-readable report (default)"
            echo "  --tool      Check specific tool only (openspec or beads)"
            echo "  --help      Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Detect platform
detect_platform() {
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    # Normalize arch
    [[ "$arch" == "x86_64" ]] && arch="amd64"
    [[ "$arch" == "aarch64" ]] && arch="arm64"

    echo "${os}_${arch}"
}

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

# Get installed beads version
get_beads_installed() {
    if command -v bd &>/dev/null; then
        # Extract just the semver (e.g., "0.49.1" from "bd version 0.49.1 (...)")
        bd version 2>/dev/null | sed -E 's/bd version ([0-9]+\.[0-9]+\.[0-9]+).*/\1/' || echo ""
    else
        echo ""
    fi
}

# Get latest beads version from GitHub
get_beads_latest() {
    local response
    response=$(curl -s "https://api.github.com/repos/steveyegge/beads/releases/latest" 2>/dev/null)
    echo "$response" | jq -r '.tag_name // ""' 2>/dev/null | sed 's/^v//' || echo ""
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

# Check beads
check_beads() {
    local installed latest status
    installed=$(get_beads_installed)
    latest=$(get_beads_latest)
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
    local platform openspec_result beads_result
    local openspec_installed openspec_latest openspec_status
    local beads_installed beads_latest beads_status
    local any_updates=false

    platform=$(detect_platform)

    # Check tools
    if [[ -z "$TOOL_FILTER" ]] || [[ "$TOOL_FILTER" == "openspec" ]]; then
        openspec_result=$(check_openspec)
        IFS='|' read -r openspec_installed openspec_latest openspec_status <<< "$openspec_result"
        [[ "$openspec_status" == "outdated" ]] && any_updates=true
    fi

    if [[ -z "$TOOL_FILTER" ]] || [[ "$TOOL_FILTER" == "beads" ]]; then
        beads_result=$(check_beads)
        IFS='|' read -r beads_installed beads_latest beads_status <<< "$beads_result"
        [[ "$beads_status" == "outdated" ]] && any_updates=true
    fi

    # Output
    if [[ "$MODE" == "json" ]]; then
        local json="{\"platform\":\"$platform\",\"tools\":{"
        local first=true

        if [[ -n "${openspec_installed+x}" ]]; then
            json+="\"openspec\":{\"installed\":\"$openspec_installed\",\"latest\":\"$openspec_latest\",\"status\":\"$openspec_status\"}"
            first=false
        fi

        if [[ -n "${beads_installed+x}" ]]; then
            [[ "$first" == "false" ]] && json+=","
            json+="\"beads\":{\"installed\":\"$beads_installed\",\"latest\":\"$beads_latest\",\"status\":\"$beads_status\"}"
        fi

        json+="},\"anyUpdates\":$any_updates}"
        echo "$json"
    else
        echo "Tool Version Check"
        echo "=================="
        echo "Platform: $platform"
        echo ""

        if [[ -n "${openspec_installed+x}" ]]; then
            output_report "OpenSpec" "$openspec_installed" "$openspec_latest" "$openspec_status"
        fi

        if [[ -n "${beads_installed+x}" ]]; then
            output_report "beads" "$beads_installed" "$beads_latest" "$beads_status"
        fi

        echo ""
        if [[ "$any_updates" == "true" ]]; then
            echo -e "${YELLOW}Updates available. Run /tools-updater upgrade to update.${NC}"
        else
            echo -e "${GREEN}All tools are up to date.${NC}"
        fi
    fi
}

main
