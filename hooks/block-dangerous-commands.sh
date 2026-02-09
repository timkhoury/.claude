#!/bin/bash
# Hook: Block dangerous bash commands
#
# Blocks rm -rf on sensitive paths and .env file modifications.
# Runs on PreToolUse for Bash commands.
#
# Exit 0: allow
# Exit 2: block (with message)

INPUT=$(cat)

# Fast exit: only process Bash commands
if [[ "$INPUT" != *"command"* ]]; then
  exit 0
fi

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Block rm -rf on root, home, or broad paths
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|(-[a-zA-Z]*f[a-zA-Z]*r))\s+(/|~|\$HOME|\.\./)'; then
  echo "BLOCKED: rm -rf on a sensitive path. Review the command and confirm with the user."
  exit 2
fi

# Block writing to .env files (prevent accidental credential exposure)
if echo "$COMMAND" | grep -qE '(>|>>)\s*\.env(\.|$)'; then
  echo "BLOCKED: Writing to .env file via redirect. Use the Edit tool instead."
  exit 2
fi

exit 0
