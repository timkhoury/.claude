#!/usr/bin/env bash
# PreToolUse hook: Reject "git commit" commands
# Reads tool input JSON from stdin, checks for git commit in command

set -euo pipefail

# Read the tool input JSON from stdin
input=$(cat)

# Extract the command from the JSON
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Check if command contains "git commit"
if [[ "$command" =~ git[[:space:]]+commit ]]; then
  echo "Use 'but commit <branch> --only -m \"message\"' instead of 'git commit'. GitButler manages commits for this project."
  exit 2
fi

exit 0
