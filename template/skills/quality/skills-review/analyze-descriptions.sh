#!/usr/bin/env bash
# analyze-descriptions.sh - Check skill description quality patterns
#
# Usage:
#   ./analyze-descriptions.sh [--report|--json] [--path <skills-dir>] [--all]
#
# Options:
#   --report    Human-readable report (default)
#   --json      JSON output for scripting
#   --path      Skills directory to analyze (default: both project + global)
#   --all       Analyze all locations (project + global + template)
#   --help      Show this help

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Quality thresholds
WORD_MIN=15
WORD_MAX=100

# Patterns
ACTION_VERBS=(
  "Create" "Update" "Analyze" "Execute" "Run" "Fetch" "Sync"
  "Validate" "Review" "Diagnose" "Clean" "Initialize" "Write"
  "Propagate" "Automate" "Set" "Invoke" "Find" "Check" "Build"
  "Deploy" "Test" "Debug" "Manage" "Show" "List" "Search"
  "Export" "Import" "Generate" "Delete" "Close" "Open" "Track"
  "Monitor" "Configure" "Install" "Remove" "Reset" "Restore"
  "Archive" "Implement" "Plan" "Get" "View" "Push" "Pull"
  "Edit" "Synchronize" "Audit" "Fix" "Merge" "Parse" "Render"
)

TRIGGER_PHRASES=(
  "Use when"
  "Use for"
  "Auto-invokes"
  "Auto-activates"
  "Invoke when"
)

RED_FLAG_PATTERNS=(
  "I will"
  "I can"
  "This skill"
  "Helper for"
  "Tool for"
  "A skill that"
  "A tool that"
)

# Defaults
OUTPUT_MODE="report"
SKILLS_PATHS=()
ANALYZE_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --report) OUTPUT_MODE="report"; shift ;;
    --json)   OUTPUT_MODE="json"; shift ;;
    --path)   SKILLS_PATHS+=("$2"); shift 2 ;;
    --all)    ANALYZE_ALL=true; shift ;;
    --help)
      head -13 "$0" | tail -11 | sed 's/^# //'
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Set default paths if none specified
if [[ ${#SKILLS_PATHS[@]} -eq 0 ]]; then
  SKILLS_PATHS=(".claude/skills")
  if [[ -d "$HOME/.claude/skills" ]]; then
    SKILLS_PATHS+=("$HOME/.claude/skills")
  fi
  if $ANALYZE_ALL && [[ -d "$HOME/.claude/template/skills" ]]; then
    SKILLS_PATHS+=("$HOME/.claude/template/skills")
  fi
fi

# Trim whitespace
trim() {
  local var="$1"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

# Extract description from YAML frontmatter
extract_description() {
  local file="$1"
  local in_frontmatter=false
  local in_description=false
  local description=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "---" ]]; then
      if $in_frontmatter; then
        break
      else
        in_frontmatter=true
        continue
      fi
    fi

    if ! $in_frontmatter; then
      continue
    fi

    if [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
      in_description=true
      local value="${BASH_REMATCH[1]}"
      value="${value#>}"
      value="${value#[[:space:]]}"
      if [[ -n "$value" ]]; then
        description="$value"
      fi
      continue
    fi

    if $in_description; then
      if [[ "$line" =~ ^[[:space:]]+(.*) ]]; then
        local continuation="${BASH_REMATCH[1]}"
        if [[ -n "$description" ]]; then
          description="$description $continuation"
        else
          description="$continuation"
        fi
      else
        break
      fi
    fi
  done < "$file"

  trim "$description"
}

# Count words in a string
count_words() {
  local text="$1"
  echo "$text" | wc -w | tr -d ' '
}

# Check if description starts with an action verb
# Accepts both base form (Create) and third-person singular (Creates)
check_action_verb() {
  local description="$1"
  local first_word
  first_word=$(echo "$description" | awk '{print $1}')

  for verb in "${ACTION_VERBS[@]}"; do
    # Match exact verb or verb with -s/-es suffix (third person singular)
    if [[ "$first_word" == "$verb" ]] || \
       [[ "$first_word" == "${verb}s" ]] || \
       [[ "$first_word" == "${verb}es" ]]; then
      return 0
    fi
  done
  return 1
}

# Check if description contains a trigger phrase
check_trigger_phrase() {
  local description="$1"

  for phrase in "${TRIGGER_PHRASES[@]}"; do
    if [[ "$description" == *"$phrase"* ]]; then
      return 0
    fi
  done
  return 1
}

# Check for red flag patterns
check_red_flags() {
  local description="$1"
  local flags=()

  for pattern in "${RED_FLAG_PATTERNS[@]}"; do
    if [[ "$description" == *"$pattern"* ]]; then
      flags+=("$pattern")
    fi
  done

  printf '%s\n' "${flags[@]}"
}

# Analyze a single skill description
analyze_description() {
  local skill_dir="$1"
  local skill_file="$skill_dir/SKILL.md"
  local name
  name=$(basename "$skill_dir")

  if [[ ! -f "$skill_file" ]]; then
    return
  fi

  local description
  description=$(extract_description "$skill_file")

  if [[ -z "$description" ]]; then
    echo "$name|0|MISSING|missing|none|none|"
    return
  fi

  local word_count
  word_count=$(count_words "$description")

  # Check action verb
  local action_status="ok"
  if ! check_action_verb "$description"; then
    action_status="missing"
  fi

  # Check trigger phrase
  local trigger_status="ok"
  if ! check_trigger_phrase "$description"; then
    trigger_status="missing"
  fi

  # Check length
  local length_status="ok"
  if (( word_count < WORD_MIN )); then
    length_status="short"
  elif (( word_count > WORD_MAX )); then
    length_status="long"
  fi

  # Check red flags
  local red_flags
  red_flags=$(check_red_flags "$description")

  # Output pipe-delimited data
  printf '%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$word_count" "$action_status" "$trigger_status" "$length_status" "$red_flags" "$description"
}

# Generate suggestion for missing action verb
suggest_action_verb() {
  local description="$1"
  local first_word
  first_word=$(echo "$description" | awk '{print $1}')

  # If it starts with "Use when", restructure
  if [[ "$description" =~ ^Use[[:space:]]when[[:space:]] ]]; then
    local rest
    rest=$(echo "$description" | sed 's/^Use when //')
    # Try to infer what it does from the rest
    if [[ "$rest" == *"creating"* ]] || [[ "$rest" == *"create"* ]]; then
      echo "Create and manage ... Use when $rest"
    elif [[ "$rest" == *"modifying"* ]] || [[ "$rest" == *"modify"* ]]; then
      echo "Update and modify ... Use when $rest"
    elif [[ "$rest" == *"review"* ]]; then
      echo "Review and analyze ... Use when $rest"
    else
      echo "[Action verb] ... Use when $rest"
    fi
    return
  fi

  echo "[Start with action verb: Create, Update, Analyze, Validate, etc.]"
}

# Generate suggestion for missing trigger
suggest_trigger() {
  local description="$1"
  echo "$description Use when [describe triggering scenarios]."
}

# Main execution
main() {
  local all_results=()
  local issues_count=0
  local healthy_count=0

  # Collect analyses from all paths
  for skills_path in "${SKILLS_PATHS[@]}"; do
    if [[ ! -d "$skills_path" ]]; then
      continue
    fi

    for skill_dir in "$skills_path"/*/; do
      if [[ -f "$skill_dir/SKILL.md" ]]; then
        result=$(analyze_description "$skill_dir")
        if [[ -n "$result" ]]; then
          # Add source path to result
          all_results+=("$skills_path|$result")
        fi
      fi
    done
  done

  case $OUTPUT_MODE in
    json)
      echo "["
      local first=true
      for r in "${all_results[@]}"; do
        IFS='|' read -r source name word_count action_status trigger_status length_status red_flags description <<< "$r"
        if $first; then
          first=false
        else
          echo ","
        fi
        cat <<EOF
{
  "source": "$source",
  "name": "$name",
  "wordCount": $word_count,
  "actionVerb": "$action_status",
  "triggerPhrase": "$trigger_status",
  "length": "$length_status",
  "redFlags": $(printf '%s' "$red_flags" | jq -Rs 'split("\n") | map(select(length > 0))'),
  "description": $(printf '%s' "$description" | jq -Rs .)
}
EOF
      done
      echo "]"
      ;;

    report)
      echo -e "${BOLD}=== DESCRIPTION QUALITY REPORT ===${NC}"
      echo ""

      # Group by source
      declare -A source_results
      for r in "${all_results[@]}"; do
        IFS='|' read -r source rest <<< "$r"
        source_results["$source"]+="$rest"$'\n'
      done

      local total_issues=0
      local total_healthy=0
      local issue_details=""

      for source in "${!source_results[@]}"; do
        local results="${source_results[$source]}"

        while IFS= read -r r; do
          [[ -z "$r" ]] && continue

          IFS='|' read -r name word_count action_status trigger_status length_status red_flags description <<< "$r"

          local has_issue=false
          local skill_issues=""

          # Check for issues
          if [[ "$action_status" == "missing" ]]; then
            has_issue=true
            local suggestion
            suggestion=$(suggest_action_verb "$description")
            skill_issues+="\n  ${YELLOW}[PATTERN]${NC} Missing action verb prefix - starts with \"$(echo "$description" | awk '{print $1}')\""
            skill_issues+="\n  ${DIM}CURRENT:${NC} ${description:0:80}..."
            skill_issues+="\n  ${DIM}SUGGEST:${NC} $suggestion"
          fi

          if [[ "$trigger_status" == "missing" ]]; then
            has_issue=true
            skill_issues+="\n  ${YELLOW}[TRIGGER]${NC} Missing \"Use when\" trigger clause"
            skill_issues+="\n  ${DIM}CURRENT:${NC} ${description:0:80}..."
            skill_issues+="\n  ${DIM}SUGGEST:${NC} ...Use when [describe triggering scenarios]."
          fi

          if [[ "$length_status" == "short" ]]; then
            has_issue=true
            skill_issues+="\n  ${YELLOW}[LENGTH]${NC} Too short ($word_count words) - may be too vague for reliable activation"
          elif [[ "$length_status" == "long" ]]; then
            has_issue=true
            skill_issues+="\n  ${YELLOW}[LENGTH]${NC} Too long ($word_count words) - trim to <$WORD_MAX words"
          fi

          if [[ -n "$red_flags" ]]; then
            while IFS= read -r flag; do
              [[ -z "$flag" ]] && continue
              has_issue=true
              skill_issues+="\n  ${RED}[RED FLAG]${NC} Contains: \"$flag\""
            done <<< "$red_flags"
          fi

          if [[ "$action_status" == "MISSING" ]]; then
            has_issue=true
            skill_issues+="\n  ${RED}[MISSING]${NC} No description found in frontmatter"
          fi

          if $has_issue; then
            ((total_issues++)) || true
            local short_source
            if [[ "$source" == "$HOME/.claude/skills" ]]; then
              short_source="global"
            elif [[ "$source" == "$HOME/.claude/template/skills" ]]; then
              short_source="template"
            else
              short_source="project"
            fi
            issue_details+="\n${CYAN}$name${NC} ${DIM}($short_source, $word_count words)${NC}$skill_issues\n"
          else
            ((total_healthy++)) || true
          fi

        done <<< "$results"
      done

      if (( total_issues > 0 )); then
        echo -e "${RED}ISSUES FOUND: $total_issues${NC}"
        echo ""
        echo -e "$issue_details"
      else
        echo -e "${GREEN}No issues found.${NC}"
        echo ""
      fi

      echo -e "${GREEN}HEALTHY: $total_healthy skills pass all checks${NC}"
      echo ""

      echo -e "${BOLD}Locations analyzed:${NC}"
      for source in "${!source_results[@]}"; do
        local count
        count=$(echo -n "${source_results[$source]}" | grep -c '^' || true)
        echo "  $source ($count skills)"
      done
      echo ""

      echo -e "${BOLD}Quality Criteria:${NC}"
      echo "  - Action verb: Description starts with third-person verb (Create, Update, Analyze...)"
      echo "  - Trigger phrase: Contains \"Use when\", \"Auto-invokes\", or similar"
      echo "  - Length: $WORD_MIN-$WORD_MAX words (not too vague, not context waste)"
      echo "  - Red flags: No first-person or generic terms"
      ;;
  esac
}

main
