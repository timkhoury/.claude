#!/usr/bin/env bash
# validate-template.sh - Validate ~/.claude/template/ structure and sync-config
#
# Usage: validate-template.sh [--json|--report] [check...]
#
# Checks: sync-config, skills, rules, commands, circular
# If no checks specified, runs all.

set -euo pipefail

# Source shared library
source "$HOME/.claude/scripts/lib/common.sh"

TEMPLATE_DIR="$HOME/.claude/template"
CONFIG_FILE="$HOME/.claude/config/sync-config.yaml"

# Counters and result arrays
errors=0
warnings=0
declare -a error_msgs=()
declare -a warning_msgs=()
declare -a passed_msgs=()

# Output mode
MODE="report"
declare -a CHECKS=()

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
      echo "Usage: validate-template.sh [--json|--report] [check...]"
      echo ""
      echo "Checks: sync-config, skills, rules, commands, circular"
      echo "If no checks specified, runs all."
      echo ""
      echo "Exit codes:"
      echo "  0 - All checks pass"
      echo "  1 - Warnings found"
      echo "  2 - Errors found"
      exit 0
      ;;
    *)
      CHECKS+=("$1")
      shift
      ;;
  esac
done

# Default to all checks
if [[ ${#CHECKS[@]} -eq 0 ]]; then
  CHECKS=(sync-config skills rules commands circular)
fi

# Require yq
if ! command -v yq &>/dev/null; then
  echo "Error: yq required for YAML parsing" >&2
  exit 2
fi

# Output helpers
report_error() {
  ((errors++)) || true
  error_msgs+=("$1")
  if [[ "$MODE" == "report" ]]; then
    echo -e "  ${RED}ERROR:${NC} $1"
  fi
}

report_warning() {
  ((warnings++)) || true
  warning_msgs+=("$1")
  if [[ "$MODE" == "report" ]]; then
    echo -e "  ${YELLOW}WARN:${NC} $1"
  fi
}

report_ok() {
  passed_msgs+=("$1")
  if [[ "$MODE" == "report" ]]; then
    echo -e "  ${GREEN}OK:${NC} $1"
  fi
}

section() {
  if [[ "$MODE" == "report" ]]; then
    echo ""
    echo -e "${BOLD}Checking $1...${NC}"
  fi
}

# Check if a check should run
should_run() {
  local check="$1"
  for c in "${CHECKS[@]}"; do
    if [[ "$c" == "$check" ]]; then
      return 0
    fi
  done
  return 1
}

# Validate files exist
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config not found at $CONFIG_FILE" >&2
  exit 2
fi

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Error: Template directory not found at $TEMPLATE_DIR" >&2
  exit 2
fi

# Check sync-config paths
check_sync_config() {
  section "sync-config"

  # Check always.rules
  while IFS= read -r rule; do
    [[ -z "$rule" ]] && continue
    local path="$TEMPLATE_DIR/rules/$rule"
    if [[ -e "$path" ]]; then
      report_ok "always.rules: $rule"
    else
      report_error "always.rules: $rule not found"
    fi
  done < <(yq -r '.always.rules[]' "$CONFIG_FILE" 2>/dev/null || true)

  # Check always.skills
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    local path="$TEMPLATE_DIR/skills/$skill"
    if [[ -d "$path" ]]; then
      # Check for SKILL.md in the directory or subdirectories
      if [[ -f "$path/SKILL.md" ]] || find "$path" -name "SKILL.md" -type f 2>/dev/null | grep -q .; then
        report_ok "always.skills: $skill"
      else
        report_error "always.skills: $skill missing SKILL.md"
      fi
    else
      report_error "always.skills: $skill not found"
    fi
  done < <(yq -r '.always.skills[]' "$CONFIG_FILE" 2>/dev/null || true)

  # Check technology rules and skills
  while IFS= read -r tech; do
    [[ -z "$tech" ]] && continue

    while IFS= read -r rule; do
      [[ -z "$rule" ]] && continue
      local path="$TEMPLATE_DIR/rules/$rule"
      if [[ -e "$path" ]]; then
        report_ok "technologies.$tech.rules: $rule"
      else
        report_error "technologies.$tech.rules: $rule not found"
      fi
    done < <(yq -r ".technologies.$tech.rules[]" "$CONFIG_FILE" 2>/dev/null || true)

    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      local path="$TEMPLATE_DIR/skills/$skill"
      if [[ -d "$path" ]]; then
        if [[ -f "$path/SKILL.md" ]]; then
          report_ok "technologies.$tech.skills: $skill"
        else
          report_error "technologies.$tech.skills: $skill missing SKILL.md"
        fi
      else
        report_error "technologies.$tech.skills: $skill not found"
      fi
    done < <(yq -r ".technologies.$tech.skills[]" "$CONFIG_FILE" 2>/dev/null || true)
  done < <(yq -r '.technologies | keys[]' "$CONFIG_FILE" 2>/dev/null || true)

  # Check tool rules, skills, and commands
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue

    while IFS= read -r rule; do
      [[ -z "$rule" ]] && continue
      local path="$TEMPLATE_DIR/rules/$rule"
      if [[ -e "$path" ]]; then
        report_ok "tools.$tool.rules: $rule"
      else
        report_error "tools.$tool.rules: $rule not found"
      fi
    done < <(yq -r ".tools.$tool.rules[]" "$CONFIG_FILE" 2>/dev/null || true)

    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      local path="$TEMPLATE_DIR/skills/$skill"
      if [[ -d "$path" ]]; then
        if [[ -f "$path/SKILL.md" ]]; then
          report_ok "tools.$tool.skills: $skill"
        else
          report_error "tools.$tool.skills: $skill missing SKILL.md"
        fi
      else
        report_error "tools.$tool.skills: $skill not found"
      fi
    done < <(yq -r ".tools.$tool.skills[]" "$CONFIG_FILE" 2>/dev/null || true)

    while IFS= read -r cmd; do
      [[ -z "$cmd" ]] && continue
      local path="$TEMPLATE_DIR/commands/$cmd"
      if [[ -f "$path" ]]; then
        report_ok "tools.$tool.commands: $cmd"
      else
        report_error "tools.$tool.commands: $cmd not found"
      fi
    done < <(yq -r ".tools.$tool.commands[]" "$CONFIG_FILE" 2>/dev/null || true)
  done < <(yq -r '.tools | keys[]' "$CONFIG_FILE" 2>/dev/null || true)
}

# Check requires references
check_requires() {
  section "requires references"

  # Get all defined technology and tool names
  local all_techs=()
  local all_tools=()

  while IFS= read -r t; do
    [[ -n "$t" ]] && all_techs+=("$t")
  done < <(yq -r '.technologies | keys[]' "$CONFIG_FILE" 2>/dev/null || true)

  while IFS= read -r t; do
    [[ -n "$t" ]] && all_tools+=("$t")
  done < <(yq -r '.tools | keys[]' "$CONFIG_FILE" 2>/dev/null || true)

  # Check technology requires
  for tech in "${all_techs[@]}"; do
    while IFS= read -r req; do
      [[ -z "$req" ]] && continue
      local found=false
      for t in "${all_techs[@]}"; do
        if [[ "$t" == "$req" ]]; then
          found=true
          break
        fi
      done
      if [[ "$found" == "true" ]]; then
        report_ok "technologies.$tech.requires: $req"
      else
        report_error "technologies.$tech.requires: $req not defined"
      fi
    done < <(yq -r ".technologies.$tech.detect.requires[]" "$CONFIG_FILE" 2>/dev/null || true)

    while IFS= read -r req; do
      [[ -z "$req" ]] && continue
      local found=false
      for t in "${all_techs[@]}"; do
        if [[ "$t" == "$req" ]]; then
          found=true
          break
        fi
      done
      if [[ "$found" == "true" ]]; then
        report_ok "technologies.$tech.requires_any: $req"
      else
        report_error "technologies.$tech.requires_any: $req not defined"
      fi
    done < <(yq -r ".technologies.$tech.detect.requires_any[]" "$CONFIG_FILE" 2>/dev/null || true)
  done

  # Check tool requires
  for tool in "${all_tools[@]}"; do
    while IFS= read -r req; do
      [[ -z "$req" ]] && continue
      local found=false
      for t in "${all_tools[@]}"; do
        if [[ "$t" == "$req" ]]; then
          found=true
          break
        fi
      done
      if [[ "$found" == "true" ]]; then
        report_ok "tools.$tool.requires: $req"
      else
        report_error "tools.$tool.requires: $req not defined"
      fi
    done < <(yq -r ".tools.$tool.detect.requires[]" "$CONFIG_FILE" 2>/dev/null || true)
  done
}

# Check skill directory structure
check_skills() {
  section "skills"

  # Find all directories that contain files (leaf directories with content)
  while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue

    # Skip if directory only contains subdirectories (no files)
    local has_files=false
    while IFS= read -r f; do
      [[ -n "$f" ]] && has_files=true && break
    done < <(find "$dir" -maxdepth 1 -type f 2>/dev/null)

    [[ "$has_files" == "false" ]] && continue

    local skill_file="$dir/SKILL.md"
    local rel_path="${dir#"$TEMPLATE_DIR"/skills/}"

    if [[ -f "$skill_file" ]]; then
      # Check frontmatter
      if head -1 "$skill_file" | grep -q "^---"; then
        # Extract name
        local name
        name=$(sed -n '2,/^---$/p' "$skill_file" | grep "^name:" | head -1 | sed 's/^name:[[:space:]]*//')

        # Extract description (handles multiline)
        local desc
        desc=$(sed -n '2,/^---$/p' "$skill_file" | awk '
          /^description:/ { in_desc=1; sub(/^description:[[:space:]]*/, ""); if ($0 != "" && $0 !~ /^>/) print; next }
          in_desc && /^[a-z]+:/ { exit }
          in_desc { gsub(/^[[:space:]]+/, ""); print }
        ' | tr '\n' ' ' | sed 's/[[:space:]]*$//')

        if [[ -z "$name" ]]; then
          report_error "skills/$rel_path: missing name"
        else
          report_ok "skills/$rel_path: name '$name'"
        fi

        if [[ -z "$desc" ]]; then
          report_error "skills/$rel_path: missing description"
        elif [[ ${#desc} -gt 300 ]]; then
          report_warning "skills/$rel_path: description ${#desc} chars (>300)"
        else
          report_ok "skills/$rel_path: description ${#desc} chars"
        fi
      else
        report_error "skills/$rel_path: missing frontmatter"
      fi
    else
      report_error "skills/$rel_path: missing SKILL.md"
    fi
  done < <(find "$TEMPLATE_DIR/skills" -type d 2>/dev/null)
}

# Check rule files
check_rules() {
  section "rules"

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local rel_path="${file#"$TEMPLATE_DIR"/rules/}"

    if [[ ! -s "$file" ]]; then
      report_warning "rules/$rel_path: empty file"
    elif ! head -20 "$file" | grep -q "^#"; then
      report_warning "rules/$rel_path: no heading found"
    else
      report_ok "rules/$rel_path"
    fi
  done < <(find "$TEMPLATE_DIR/rules" -name "*.md" -type f 2>/dev/null)
}

# Check command files
check_commands() {
  section "commands"

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local rel_path="${file#"$TEMPLATE_DIR"/commands/}"

    if [[ ! -s "$file" ]]; then
      report_warning "commands/$rel_path: empty"
    else
      report_ok "commands/$rel_path"
    fi
  done < <(find "$TEMPLATE_DIR/commands" -name "*.md" -type f 2>/dev/null)
}

# Check for circular dependencies
check_circular() {
  section "circular dependencies"

  # Build and check graphs using bash (arrays used via nameref in detect_cycle)
  declare -A tech_deps
  declare -A tool_deps

  # Build technology dependency map
  while IFS= read -r tech; do
    [[ -z "$tech" ]] && continue
    local deps=""
    while IFS= read -r req; do
      [[ -z "$req" ]] && continue
      deps="$deps $req"
    done < <(yq -r ".technologies.$tech.detect.requires[]" "$CONFIG_FILE" 2>/dev/null || true)
    while IFS= read -r req; do
      [[ -z "$req" ]] && continue
      deps="$deps $req"
    done < <(yq -r ".technologies.$tech.detect.requires_any[]" "$CONFIG_FILE" 2>/dev/null || true)
    # shellcheck disable=SC2034  # Used via nameref in detect_cycle
    tech_deps[$tech]="${deps# }"
  done < <(yq -r '.technologies | keys[]' "$CONFIG_FILE" 2>/dev/null || true)

  # Build tool dependency map
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    local deps=""
    while IFS= read -r req; do
      [[ -z "$req" ]] && continue
      deps="$deps $req"
    done < <(yq -r ".tools.$tool.detect.requires[]" "$CONFIG_FILE" 2>/dev/null || true)
    # shellcheck disable=SC2034  # Used via nameref in detect_cycle
    tool_deps[$tool]="${deps# }"
  done < <(yq -r '.tools | keys[]' "$CONFIG_FILE" 2>/dev/null || true)

  # DFS cycle detection
  detect_cycle() {
    local -n graph=$1
    local type=$2
    declare -A visited
    declare -A rec_stack

    dfs() {
      local node=$1
      local path=$2
      visited[$node]=1
      rec_stack[$node]=1

      for neighbor in ${graph[$node]}; do
        if [[ -z "${visited[$neighbor]:-}" ]]; then
          local result
          result=$(dfs "$neighbor" "$path -> $neighbor")
          if [[ -n "$result" ]]; then
            echo "$result"
            return
          fi
        elif [[ -n "${rec_stack[$neighbor]:-}" ]]; then
          echo "$path -> $neighbor (cycle)"
          return
        fi
      done

      unset "rec_stack[$node]"
    }

    for node in "${!graph[@]}"; do
      if [[ -z "${visited[$node]:-}" ]]; then
        local result
        result=$(dfs "$node" "$node")
        if [[ -n "$result" ]]; then
          report_error "$type circular dependency: $result"
          return 1
        fi
      fi
    done
    return 0
  }

  local has_cycle=false
  if ! detect_cycle tech_deps "technologies"; then
    has_cycle=true
  fi
  if ! detect_cycle tool_deps "tools"; then
    has_cycle=true
  fi

  if [[ "$has_cycle" == "false" ]]; then
    report_ok "no circular dependencies"
  fi
}

# Run checks
if should_run "sync-config"; then
  check_sync_config
  check_requires
fi

if should_run "skills"; then
  check_skills
fi

if should_run "rules"; then
  check_rules
fi

if should_run "commands"; then
  check_commands
fi

if should_run "circular"; then
  check_circular
fi

# Output summary
if [[ "$MODE" == "json" ]]; then
  echo "{"
  echo "  \"errors\": ["
  first=true
  for msg in "${error_msgs[@]}"; do
    [[ "$first" == true ]] || echo ","
    first=false
    echo -n "    \"$(json_escape "$msg")\""
  done
  echo ""
  echo "  ],"
  echo "  \"warnings\": ["
  first=true
  for msg in "${warning_msgs[@]}"; do
    [[ "$first" == true ]] || echo ","
    first=false
    echo -n "    \"$(json_escape "$msg")\""
  done
  echo ""
  echo "  ],"
  echo "  \"passed\": ["
  first=true
  for msg in "${passed_msgs[@]}"; do
    [[ "$first" == true ]] || echo ","
    first=false
    echo -n "    \"$(json_escape "$msg")\""
  done
  echo ""
  echo "  ],"
  echo "  \"summary\": {"
  echo "    \"errors\": $errors,"
  echo "    \"warnings\": $warnings,"
  echo "    \"passed\": ${#passed_msgs[@]}"
  echo "  }"
  echo "}"
else
  echo ""
  echo -e "${BOLD}Summary:${NC}"
  if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    echo -e "  ${GREEN}All ${#passed_msgs[@]} checks passed${NC}"
  else
    [[ $errors -gt 0 ]] && echo -e "  ${RED}$errors errors${NC}"
    [[ $warnings -gt 0 ]] && echo -e "  ${YELLOW}$warnings warnings${NC}"
    echo -e "  ${GREEN}${#passed_msgs[@]} passed${NC}"
  fi
fi

# Exit with appropriate code
if [[ $errors -gt 0 ]]; then
  exit 2
elif [[ $warnings -gt 0 ]]; then
  exit 1
else
  exit 0
fi
