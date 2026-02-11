#!/bin/bash
# PreToolUse hook for ExitPlanMode
# Appends execute-plan reminder to the plan file before ExitPlanMode reads it.
# This ensures the instruction survives plan mode context clearing.

PLANS_DIR="$HOME/.claude/plans"

# Find the most recently modified plan file
PLAN_FILE=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$PLAN_FILE" ]; then
  exit 0
fi

# Idempotent: skip if already appended
if grep -q "invoke.*execute-plan" "$PLAN_FILE" 2>/dev/null; then
  exit 0
fi

# Append the instruction
cat >> "$PLAN_FILE" << 'EOF'

---

**After approval, invoke `/execute-plan` to create the tasks and branch before implementing.**
EOF

exit 0
