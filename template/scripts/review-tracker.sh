#!/usr/bin/env bash
#
# review-tracker.sh - Track review execution history
#
# Commands:
#   status      Show all reviews with days since last run
#   recommend   Show reviews due, sorted by priority
#   record      Record review completion
#   init        Create history files if missing
#
# File routing:
#   template-review -> ~/.claude/.systems-review.json
#   All others      -> ./.systems-review.json
#

set -euo pipefail

GLOBAL_FILE="$HOME/.claude/.systems-review.json"
PROJECT_FILE="./.systems-review.json"

# Cadences in days
declare -A CADENCES=(
    ["template-review"]=7
    ["rules-review"]=7
    ["skills-review"]=7
    ["spec-review"]=14
    ["permissions-review"]=7
)

# Which file each review uses
get_history_file() {
    local name="$1"
    if [[ "$name" == "template-review" ]]; then
        echo "$GLOBAL_FILE"
    else
        echo "$PROJECT_FILE"
    fi
}

# Ensure .systems-review.json is in .gitignore
ensure_gitignored() {
    local history_file="$1"
    local gitignore_dir gitignore_file entry

    gitignore_dir=$(dirname "$history_file")
    gitignore_file="$gitignore_dir/.gitignore"
    entry=".systems-review.json"

    # Check if already in .gitignore
    if [[ -f "$gitignore_file" ]] && grep -qxF "$entry" "$gitignore_file" 2>/dev/null; then
        return 0
    fi

    # Add to .gitignore
    echo "$entry" >> "$gitignore_file"
}

# Check if a review is applicable in current context
is_applicable() {
    local name="$1"
    case "$name" in
        template-review)
            # Always applicable (global scope)
            return 0
            ;;
        spec-review)
            # Only if .openspec/ or specs/ exists
            [[ -d ".openspec" || -d "specs" ]]
            ;;
        rules-review)
            # Only if .claude/rules/ exists
            [[ -d ".claude/rules" ]]
            ;;
        skills-review)
            # Only if .claude/skills/ exists
            [[ -d ".claude/skills" ]]
            ;;
        permissions-review)
            # Only if .claude/settings.local.json exists
            [[ -f ".claude/settings.local.json" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Get last run timestamp for a review
get_last_run() {
    local name="$1"
    local file
    file=$(get_history_file "$name")

    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi

    jq -r ".reviews[\"$name\"].lastRun // \"\"" "$file" 2>/dev/null || echo ""
}

# Calculate days since last run
days_since() {
    local last_run="$1"

    if [[ -z "$last_run" ]]; then
        echo "-1"  # Never run
        return
    fi

    local now last_epoch now_epoch
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Parse ISO8601 to epoch (macOS compatible)
    if [[ "$(uname)" == "Darwin" ]]; then
        last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_run" +%s 2>/dev/null || echo "0")
        now_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$now" +%s)
    else
        last_epoch=$(date -d "$last_run" +%s 2>/dev/null || echo "0")
        now_epoch=$(date -d "$now" +%s)
    fi

    # Treat parse failures as "never run"
    if [[ "$last_epoch" == "0" ]]; then
        echo "-1"
        return
    fi

    local diff=$(( (now_epoch - last_epoch) / 86400 ))
    echo "$diff"
}

# Command: init
cmd_init() {
    local created=()

    if [[ ! -f "$GLOBAL_FILE" ]]; then
        mkdir -p "$(dirname "$GLOBAL_FILE")"
        echo '{"version":1,"reviews":{}}' > "$GLOBAL_FILE"
        ensure_gitignored "$GLOBAL_FILE"
        created+=("$GLOBAL_FILE")
    fi

    if [[ ! -f "$PROJECT_FILE" ]]; then
        echo '{"version":1,"reviews":{}}' > "$PROJECT_FILE"
        ensure_gitignored "$PROJECT_FILE"
        created+=("$PROJECT_FILE")
    fi

    if [[ ${#created[@]} -eq 0 ]]; then
        echo "All history files already exist"
    else
        echo "Created: ${created[*]}"
    fi
}

# Command: status
cmd_status() {
    local format="${1:-text}"
    local json_array="[]"

    for name in "${!CADENCES[@]}"; do
        if is_applicable "$name"; then
            local last_run days cadence overdue
            last_run=$(get_last_run "$name")
            days=$(days_since "$last_run")
            cadence=${CADENCES[$name]}

            if [[ $days -eq -1 ]]; then
                overdue="true"
                days="never"
            elif [[ $cadence -eq 0 ]]; then
                overdue="true"
            elif [[ $days -ge $cadence ]]; then
                overdue="true"
            else
                overdue="false"
            fi

            if [[ "$format" == "json" ]]; then
                json_array=$(echo "$json_array" | jq \
                    --arg name "$name" \
                    --arg lastRun "$last_run" \
                    --arg daysSince "$days" \
                    --argjson cadence "$cadence" \
                    --argjson overdue "$overdue" \
                    '. += [{"name": $name, "lastRun": $lastRun, "daysSince": $daysSince, "cadence": $cadence, "overdue": $overdue}]')
            else
                local status_icon
                if [[ "$overdue" == "true" ]]; then
                    status_icon="*"
                else
                    status_icon=" "
                fi
                echo "$status_icon $name: ${days} days (cadence: ${cadence}d)"
            fi
        fi
    done

    if [[ "$format" == "json" ]]; then
        echo "$json_array"
    fi
}

# Command: recommend
cmd_recommend() {
    local format="${1:-text}"
    local recommendations=()

    # Collect applicable and overdue reviews
    for name in "${!CADENCES[@]}"; do
        if is_applicable "$name"; then
            local last_run days cadence priority
            last_run=$(get_last_run "$name")
            days=$(days_since "$last_run")
            cadence=${CADENCES[$name]}

            # Check if overdue
            local overdue=false
            if [[ $days -eq -1 ]]; then
                overdue=true
                priority=1000  # Never run = highest priority
            elif [[ $cadence -eq 0 ]]; then
                overdue=true
                priority=100  # Always run
            elif [[ $days -ge $cadence ]]; then
                overdue=true
                priority=$((days - cadence))  # Days overdue
            fi

            if [[ "$overdue" == "true" ]]; then
                recommendations+=("$priority|$name|$days|$cadence")
            fi
        fi
    done

    if [[ ${#recommendations[@]} -eq 0 ]]; then
        if [[ "$format" == "json" ]]; then
            echo "[]"
        else
            echo "All reviews are up to date"
        fi
        return
    fi

    # Sort by priority (descending)
    local sorted
    sorted=$(printf '%s\n' "${recommendations[@]}" | sort -t'|' -k1 -rn)

    if [[ "$format" == "json" ]]; then
        local json_array="[]"
        while IFS='|' read -r priority name days cadence; do
            local reason
            if [[ "$days" == "-1" ]]; then
                reason="never run"
                days="never"
            elif [[ $cadence -eq 0 ]]; then
                reason="run every session"
            else
                reason="$((days - cadence)) days overdue"
            fi
            json_array=$(echo "$json_array" | jq \
                --arg name "$name" \
                --arg daysSince "$days" \
                --argjson cadence "$cadence" \
                --arg reason "$reason" \
                '. += [{"name": $name, "daysSince": $daysSince, "cadence": $cadence, "reason": $reason}]')
        done <<< "$sorted"

        echo "$json_array"
    else
        echo "Reviews due:"
        while IFS='|' read -r priority name days cadence; do
            local reason
            if [[ "$days" == "-1" ]]; then
                reason="(never run)"
            elif [[ $cadence -eq 0 ]]; then
                reason="(run every session)"
            else
                reason="($((days - cadence)) days overdue)"
            fi
            echo "  - $name $reason"
        done <<< "$sorted"
    fi
}

# Command: record
cmd_record() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "Error: review name required" >&2
        exit 1
    fi

    local file now created_new=false
    file=$(get_history_file "$name")
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Create file if missing
    if [[ ! -f "$file" ]]; then
        mkdir -p "$(dirname "$file")"
        echo '{"version":1,"reviews":{}}' > "$file"
        ensure_gitignored "$file"
        created_new=true
    fi

    # Update using jq
    local tmp
    tmp=$(mktemp)
    jq ".reviews[\"$name\"] = {\"lastRun\": \"$now\"}" "$file" > "$tmp"
    mv "$tmp" "$file"

    echo "Recorded $name at $now in $file"
}

# Main
case "${1:-}" in
    status)
        cmd_status "${2:-text}"
        ;;
    recommend)
        cmd_recommend "${2:-text}"
        ;;
    record)
        cmd_record "${2:-}"
        ;;
    init)
        cmd_init
        ;;
    *)
        echo "Usage: review-tracker.sh {status|recommend|record|init} [args]"
        echo ""
        echo "Commands:"
        echo "  status [json]       Show all reviews with days since last run"
        echo "  recommend [json]    Show reviews due, sorted by priority"
        echo "  record <name>       Record review completion"
        echo "  init                Create history files if missing"
        exit 1
        ;;
esac
