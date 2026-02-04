#!/usr/bin/env bash
# Sync template hooks to project settings.json
# Usage: sync-hooks.sh [--report|--apply]
#
# Reads hook definitions from sync-config.yaml and compares with project settings.
# Template hooks have a _templateId field to distinguish them from project hooks.
#
# --report: Show what would be synced (default)
# --apply:  Actually write changes to project settings.json

set -eo pipefail

# Source shared libraries
source "$HOME/.claude/scripts/lib/common.sh"

# Paths
CONFIG_FILE="$HOME/.claude/config/sync-config.yaml"
PROJECT_SETTINGS=".claude/settings.json"

# Parse arguments
MODE="report"
case "${1:-}" in
  --apply)
    MODE="apply"
    ;;
  --report|"")
    MODE="report"
    ;;
  --help|-h)
    echo "Usage: sync-hooks.sh [--report|--apply]"
    echo ""
    echo "Sync template hooks to project settings.json based on tool detection."
    echo ""
    echo "Options:"
    echo "  --report  Show what would be synced (default)"
    echo "  --apply   Write changes to project settings.json"
    echo ""
    echo "Template hooks have a _templateId field. Project hooks without this"
    echo "field are preserved. Same _templateId means project override wins."
    exit 0
    ;;
  *)
    echo "Unknown argument: $1"
    exit 1
    ;;
esac

# Check prerequisites
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}Error: sync-config.yaml not found at $CONFIG_FILE${NC}"
  exit 1
fi

if ! command -v yq &>/dev/null; then
  echo -e "${RED}Error: yq is required but not installed${NC}"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo -e "${RED}Error: jq is required but not installed${NC}"
  exit 1
fi

# Detect enabled tools
HAS_BEADS=false
HAS_OPENSPEC=false
[[ -d ".beads" ]] && HAS_BEADS=true
[[ -d "openspec" ]] && HAS_OPENSPEC=true

# Get all tools from config
get_tools() {
  yq -r '.tools | keys | .[]' "$CONFIG_FILE" 2>/dev/null || true
}

# Check if tool is enabled based on detection
is_tool_enabled() {
  local tool="$1"

  case "$tool" in
    beads)
      [[ "$HAS_BEADS" == "true" ]]
      ;;
    openspec)
      [[ "$HAS_OPENSPEC" == "true" ]]
      ;;
    "beads+openspec")
      [[ "$HAS_BEADS" == "true" ]] && [[ "$HAS_OPENSPEC" == "true" ]]
      ;;
    *)
      # Unknown tool - check if it has requires
      local requires
      requires=$(yq -r ".tools.\"$tool\".detect.requires // [] | .[]" "$CONFIG_FILE" 2>/dev/null || true)
      if [[ -n "$requires" ]]; then
        # All required tools must be enabled
        local all_enabled=true
        for req in $requires; do
          if ! is_tool_enabled "$req"; then
            all_enabled=false
            break
          fi
        done
        $all_enabled
      else
        false
      fi
      ;;
  esac
}

# Get hooks for a specific tool from config
get_tool_hooks() {
  local tool="$1"
  yq -o=json ".tools.\"$tool\".hooks // {}" "$CONFIG_FILE" 2>/dev/null || echo "{}"
}

# Get disabled template hooks from project settings
get_disabled_template_hooks() {
  if [[ -f "$PROJECT_SETTINGS" ]]; then
    jq -r '._disabledTemplateHooks // [] | .[]' "$PROJECT_SETTINGS" 2>/dev/null || true
  fi
}

# Check if a template ID is disabled
is_template_id_disabled() {
  local template_id="$1"
  local disabled
  disabled=$(get_disabled_template_hooks)
  echo "$disabled" | grep -qF "$template_id"
}

# Get existing project hooks for an event
get_project_hooks() {
  local event="$1"
  if [[ -f "$PROJECT_SETTINGS" ]]; then
    jq -c ".hooks.\"$event\" // []" "$PROJECT_SETTINGS" 2>/dev/null || echo "[]"
  else
    echo "[]"
  fi
}

# Check if hook with template ID exists in project
has_template_hook() {
  local event="$1"
  local template_id="$2"
  local hooks
  hooks=$(get_project_hooks "$event")
  echo "$hooks" | jq -e "any(._templateId == \"$template_id\")" &>/dev/null
}

# Check if similar hook exists without template ID (potential conflict)
has_similar_hook() {
  local event="$1"
  local matcher="$2"
  local type="$3"
  local hooks
  hooks=$(get_project_hooks "$event")
  # Check if there's a hook with same matcher and type but no _templateId
  echo "$hooks" | jq -e "any(select(._templateId == null) | .matcher == \"$matcher\" and .hooks[0].type == \"$type\")" &>/dev/null
}

# Collect all template hooks from enabled tools
collect_template_hooks() {
  local all_hooks="{}"

  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue

    if is_tool_enabled "$tool"; then
      local tool_hooks
      tool_hooks=$(get_tool_hooks "$tool")

      # Merge hooks into all_hooks
      if [[ "$tool_hooks" != "{}" ]]; then
        # For each event type in tool_hooks
        for event in $(echo "$tool_hooks" | jq -r 'keys | .[]'); do
          # Get hooks array for this event
          local event_hooks
          event_hooks=$(echo "$tool_hooks" | jq -c ".\"$event\"")

          # Append to existing hooks for this event
          all_hooks=$(echo "$all_hooks" | jq -c ".\"$event\" = ((.\"$event\" // []) + $event_hooks)")
        done
      fi
    fi
  done < <(get_tools)

  echo "$all_hooks"
}

# Track counts
count_to_add=0
count_up_to_date=0
count_disabled=0
count_conflict=0

# Arrays for reporting
declare -a hooks_to_add
declare -a hooks_up_to_date
declare -a hooks_disabled
declare -a hooks_conflict

echo -e "${BLUE}=== Hooks Sync ===${NC}"
echo ""
echo -e "Tools detected:"
echo -e "  Beads:    $([[ "$HAS_BEADS" == "true" ]] && echo "${GREEN}yes${NC}" || echo "${YELLOW}no${NC}")"
echo -e "  OpenSpec: $([[ "$HAS_OPENSPEC" == "true" ]] && echo "${GREEN}yes${NC}" || echo "${YELLOW}no${NC}")"
echo ""

# Collect all template hooks
template_hooks=$(collect_template_hooks)

if [[ "$template_hooks" == "{}" ]]; then
  echo -e "${GREEN}No template hooks to sync.${NC}"
  exit 0
fi

# Process each event type
for event in $(echo "$template_hooks" | jq -r 'keys | .[]'); do
  # Get hooks for this event
  hooks_array=$(echo "$template_hooks" | jq -c ".\"$event\"")
  hook_count=$(echo "$hooks_array" | jq 'length')

  for i in $(seq 0 $((hook_count - 1))); do
    hook=$(echo "$hooks_array" | jq -c ".[$i]")
    template_id=$(echo "$hook" | jq -r '._templateId')
    matcher=$(echo "$hook" | jq -r '.matcher')
    hook_type=$(echo "$hook" | jq -r '.type')

    # Convert YAML hook format to JSON settings.json format
    # YAML: { matcher, type, prompt|command, _templateId }
    # JSON: { matcher, hooks: [{ type, prompt|command }], _templateId }
    settings_hook=$(echo "$hook" | jq -c '{
      matcher: .matcher,
      hooks: [{type: .type} + (if .prompt then {prompt: .prompt} else {command: .command} end)],
      _templateId: ._templateId
    }')

    # Check if disabled
    if is_template_id_disabled "$template_id"; then
      hooks_disabled+=("$event: $matcher → $hook_type ($template_id)")
      ((count_disabled++)) || true
      continue
    fi

    # Check if already exists with same template ID
    if has_template_hook "$event" "$template_id"; then
      hooks_up_to_date+=("$event: $matcher → $hook_type ($template_id)")
      ((count_up_to_date++)) || true
      continue
    fi

    # Check for similar hook without template ID (potential conflict)
    if has_similar_hook "$event" "$matcher" "$hook_type"; then
      hooks_conflict+=("$event: $matcher → $hook_type (similar project hook exists)")
      ((count_conflict++)) || true
      continue
    fi

    # Hook should be added
    hooks_to_add+=("$event|$settings_hook|$template_id|$matcher|$hook_type")
    ((count_to_add++)) || true
  done
done

# Report
echo -e "${GREEN}=== Hooks Report ===${NC}"
echo ""

if [[ ${#hooks_to_add[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Template hooks to add ($count_to_add):${NC}"
  for entry in "${hooks_to_add[@]}"; do
    IFS='|' read -r event hook template_id matcher hook_type <<< "$entry"
    prompt=$(echo "$hook" | jq -r '.hooks[0].prompt')
    echo "  $event:"
    echo "    ${GREEN}+${NC} $matcher → $prompt ($template_id)"
  done
  echo ""
fi

if [[ ${#hooks_up_to_date[@]} -gt 0 ]]; then
  echo -e "${GREEN}Already synced ($count_up_to_date):${NC}"
  for desc in "${hooks_up_to_date[@]}"; do
    echo "  $desc"
  done
  echo ""
fi

if [[ ${#hooks_disabled[@]} -gt 0 ]]; then
  echo -e "${BLUE}Disabled by project ($count_disabled):${NC}"
  for desc in "${hooks_disabled[@]}"; do
    echo "  $desc"
  done
  echo ""
fi

if [[ ${#hooks_conflict[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Conflicts (similar project hook exists):${NC}"
  for desc in "${hooks_conflict[@]}"; do
    echo "  $desc"
  done
  echo ""
fi

# Summary
echo -e "${BLUE}Summary:${NC}"
echo "  To add:      $count_to_add"
echo "  Up to date:  $count_up_to_date"
echo "  Disabled:    $count_disabled"
echo "  Conflicts:   $count_conflict"
echo ""

# Apply if requested
if [[ "$MODE" == "apply" ]] && [[ $count_to_add -gt 0 ]]; then
  echo -e "${YELLOW}Applying changes...${NC}"

  # Start with existing settings or empty object
  if [[ -f "$PROJECT_SETTINGS" ]]; then
    current_settings=$(cat "$PROJECT_SETTINGS")
  else
    current_settings='{}'
  fi

  # Add each hook
  for entry in "${hooks_to_add[@]}"; do
    IFS='|' read -r event hook template_id matcher hook_type <<< "$entry"

    # Add hook to settings
    current_settings=$(echo "$current_settings" | jq -c "
      .hooks.\"$event\" = ((.hooks.\"$event\" // []) + [$hook])
    ")
  done

  # Write back with pretty formatting
  echo "$current_settings" | jq '.' > "$PROJECT_SETTINGS"

  echo -e "${GREEN}Added $count_to_add hook(s) to $PROJECT_SETTINGS${NC}"
elif [[ "$MODE" == "report" ]] && [[ $count_to_add -gt 0 ]]; then
  echo -e "${YELLOW}Report only - no changes made${NC}"
  echo "Run with --apply to add hooks to project settings."
fi
