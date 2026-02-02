#!/usr/bin/env bash
#
# SessionStart hook: Check if maintenance tasks are due
#
# Uses JSON output with systemMessage to display to user
#

TRACKER="$HOME/.claude/template/scripts/systems-tracker.sh"

# Bail if tracker doesn't exist
if [[ ! -x "$TRACKER" ]]; then
    exit 0
fi

# Get recommendations as JSON
recommendations=$("$TRACKER" recommend json 2>/dev/null)

# Check if there are any due tasks
count=$(echo "$recommendations" | jq -r 'length' 2>/dev/null || echo "0")

if [[ "$count" -eq 0 || "$count" == "0" ]]; then
    exit 0
fi

# Get all task names for display
task_names=$(echo "$recommendations" | jq -r '[.[].name] | join(", ")' 2>/dev/null)

# Build user message
if [[ "$count" -eq 1 ]]; then
    user_msg="$task_names is due - run /systems-check"
else
    user_msg="$count maintenance tasks due ($task_names) - run /systems-check"
fi

# Build detailed context for Claude
context=$(cat <<EOF
# Maintenance Tasks Due

Run \`/systems-check\` to review and execute:

$(echo "$recommendations" | jq -r '.[] | "- **\(.name)**: \(.reason)"' 2>/dev/null)
EOF
)

# Output JSON with both user message and Claude context
jq -n \
  --arg msg "$user_msg" \
  --arg ctx "$context" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "additionalContext": $ctx
    },
    "systemMessage": $msg
  }'

exit 0
