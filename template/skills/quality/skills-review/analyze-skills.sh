#!/usr/bin/env bash
# analyze-skills.sh - Analyze Claude Code skills for context efficiency
#
# Usage:
#   ./analyze-skills.sh [--report|--json|--csv] [--path <skills-dir>]
#
# Options:
#   --report    Human-readable report (default)
#   --json      JSON output for scripting
#   --csv       CSV output for spreadsheets
#   --path      Skills directory (default: .claude/skills)
#   --help      Show this help

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Thresholds
DESCRIPTION_TARGET=200
DESCRIPTION_WARN=300
FILE_TARGET=4000
FILE_WARN=10000
TABLE_ROWS_WARN=20

# Defaults
OUTPUT_MODE="report"
SKILLS_PATH=".claude/skills"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --report) OUTPUT_MODE="report"; shift ;;
    --json)   OUTPUT_MODE="json"; shift ;;
    --csv)    OUTPUT_MODE="csv"; shift ;;
    --path)   SKILLS_PATH="$2"; shift 2 ;;
    --help)
      head -15 "$0" | tail -13 | sed 's/^# //'
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Verify path exists
if [[ ! -d "$SKILLS_PATH" ]]; then
  echo "Error: Skills directory not found: $SKILLS_PATH" >&2
  exit 1
fi

# Trim whitespace from a value
trim() {
  local var="$1"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

# Extract description from YAML frontmatter
# Handles both single-line and multi-line (folded >) descriptions
extract_description() {
  local file="$1"
  local in_frontmatter=false
  local in_description=false
  local description=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect frontmatter boundaries
    if [[ "$line" == "---" ]]; then
      if $in_frontmatter; then
        # End of frontmatter
        break
      else
        in_frontmatter=true
        continue
      fi
    fi

    if ! $in_frontmatter; then
      continue
    fi

    # Check for description field
    if [[ "$line" =~ ^description:[[:space:]]*(.*) ]]; then
      in_description=true
      local value="${BASH_REMATCH[1]}"
      # Remove leading > for folded scalars
      value="${value#>}"
      value="${value#[[:space:]]}"
      if [[ -n "$value" ]]; then
        description="$value"
      fi
      continue
    fi

    # If we're in description and line starts with spaces, it's continuation
    if $in_description; then
      if [[ "$line" =~ ^[[:space:]]+(.*) ]]; then
        local continuation="${BASH_REMATCH[1]}"
        if [[ -n "$description" ]]; then
          description="$description $continuation"
        else
          description="$continuation"
        fi
      else
        # New field starts, end of description
        break
      fi
    fi
  done < "$file"

  trim "$description"
}

# Count markdown tables in file (lines starting with |)
count_table_rows() {
  local file="$1"
  local count
  count=$(grep -c '^|' "$file" 2>/dev/null || true)
  count="${count:-0}"
  count=$(trim "$count")
  # Ensure it's a valid number
  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    count=0
  fi
  echo "$count"
}

# Count code blocks
count_code_blocks() {
  local file="$1"
  local count
  count=$(grep -c '```' "$file" 2>/dev/null || true)
  count="${count:-0}"
  count=$(trim "$count")
  # Ensure it's a valid number
  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    count=0
  fi
  echo $(( count / 2 ))
}

# Analyze a single skill and output pipe-delimited data
analyze_skill() {
  local skill_dir="$1"
  local skill_file="$skill_dir/SKILL.md"
  local name
  name=$(basename "$skill_dir")

  if [[ ! -f "$skill_file" ]]; then
    return
  fi

  local file_size
  file_size=$(wc -c < "$skill_file")
  file_size=$(trim "$file_size")

  local description
  description=$(extract_description "$skill_file")
  local desc_len=${#description}

  local table_rows
  table_rows=$(count_table_rows "$skill_file")

  local code_blocks
  code_blocks=$(count_code_blocks "$skill_file")

  # Check for supporting files
  local has_patterns="false"
  local has_reference="false"
  [[ -f "$skill_dir/PATTERNS.md" ]] && has_patterns="true"
  [[ -f "$skill_dir/REFERENCE.md" ]] && has_reference="true"

  # Determine status
  local file_status="ok"
  local desc_status="ok"
  local table_status="ok"

  if (( file_size > FILE_WARN )); then
    file_status="critical"
  elif (( file_size > FILE_TARGET )); then
    file_status="warn"
  fi

  if (( desc_len > DESCRIPTION_WARN )); then
    desc_status="critical"
  elif (( desc_len > DESCRIPTION_TARGET )); then
    desc_status="warn"
  fi

  if (( table_rows > TABLE_ROWS_WARN )); then
    table_status="warn"
  fi

  # Output pipe-delimited data
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$file_size" "$file_status" "$desc_len" "$desc_status" \
    "$table_rows" "$table_status" "$code_blocks" "$has_patterns" "$has_reference" \
    "$description"
}

# Output JSON for a skill
output_json_skill() {
  local name="$1" file_size="$2" file_status="$3" desc_len="$4" desc_status="$5"
  local table_rows="$6" table_status="$7" code_blocks="$8"
  local has_patterns="$9" has_reference="${10}" description="${11}"

  cat <<EOF
{
  "name": "$name",
  "fileSize": $file_size,
  "fileStatus": "$file_status",
  "descriptionLength": $desc_len,
  "descriptionStatus": "$desc_status",
  "tableRows": $table_rows,
  "tableStatus": "$table_status",
  "codeBlocks": $code_blocks,
  "hasPatterns": $has_patterns,
  "hasReference": $has_reference,
  "description": $(printf '%s' "$description" | jq -Rs .)
}
EOF
}

# Main execution
main() {
  local results=()

  # Collect all skill analyses
  for skill_dir in "$SKILLS_PATH"/*/; do
    if [[ -f "$skill_dir/SKILL.md" ]]; then
      result=$(analyze_skill "$skill_dir")
      if [[ -n "$result" ]]; then
        results+=("$result")
      fi
    fi
  done

  case $OUTPUT_MODE in
    json)
      echo "["
      local first=true
      for r in "${results[@]}"; do
        IFS='|' read -r name file_size file_status desc_len desc_status \
          table_rows table_status code_blocks has_patterns has_reference description <<< "$r"
        if $first; then
          first=false
        else
          echo ","
        fi
        output_json_skill "$name" "$file_size" "$file_status" "$desc_len" "$desc_status" \
          "$table_rows" "$table_status" "$code_blocks" "$has_patterns" "$has_reference" "$description"
      done
      echo "]"
      ;;
    csv)
      echo "name,file_size,file_status,desc_length,desc_status,table_rows,code_blocks,has_patterns,has_reference,description"
      for r in "${results[@]}"; do
        IFS='|' read -r name file_size file_status desc_len desc_status \
          table_rows table_status code_blocks has_patterns has_reference description <<< "$r"
        # Escape description for CSV
        local escaped_desc
        escaped_desc=$(printf '%s' "$description" | sed 's/"/""/g')
        echo "\"$name\",$file_size,\"$file_status\",$desc_len,\"$desc_status\",$table_rows,$code_blocks,$has_patterns,$has_reference,\"$escaped_desc\""
      done
      ;;
    report)
      echo -e "${BOLD}Skills Analysis Report${NC}"
      echo "======================"
      echo ""
      echo -e "Path: ${CYAN}$SKILLS_PATH${NC}"
      echo -e "Skills found: ${CYAN}${#results[@]}${NC}"
      echo ""

      # Sort by file size descending
      local sorted
      sorted=$(printf '%s\n' "${results[@]}" | sort -t'|' -k2 -nr)

      # Summary table
      echo -e "${BOLD}Size Summary${NC} (sorted by size)"
      echo ""
      printf "%-35s %8s %8s %6s %6s\n" "Skill" "Size" "Desc" "Tables" "Code"
      printf "%-35s %8s %8s %6s %6s\n" "-----" "----" "----" "------" "----"

      local critical_count=0
      local warn_count=0

      while IFS='|' read -r name file_size file_status desc_len desc_status table_rows table_status code_blocks has_patterns has_reference description; do
        [[ -z "$name" ]] && continue

        # Format size
        local size_display
        if (( file_size > 1000 )); then
          size_display=$(printf "%.1fk" "$(echo "scale=1; $file_size/1000" | bc)")
        else
          size_display="${file_size}"
        fi

        # Color code
        local size_color="$NC"
        local desc_color="$NC"

        if [[ "$file_status" == "critical" ]]; then
          size_color="$RED"
          ((critical_count++)) || true
        elif [[ "$file_status" == "warn" ]]; then
          size_color="$YELLOW"
          ((warn_count++)) || true
        fi

        if [[ "$desc_status" == "critical" ]]; then
          desc_color="$RED"
        elif [[ "$desc_status" == "warn" ]]; then
          desc_color="$YELLOW"
        fi

        local table_color="$NC"
        if [[ "$table_status" == "warn" ]]; then
          table_color="$YELLOW"
        fi

        printf "%-35s ${size_color}%8s${NC} ${desc_color}%8s${NC} ${table_color}%6s${NC} %6s\n" \
          "$name" "$size_display" "$desc_len" "$table_rows" "$code_blocks"
      done <<< "$sorted"

      echo ""
      echo -e "${BOLD}Legend${NC}"
      echo -e "  Size:  Target <${FILE_TARGET}, ${YELLOW}Warn >${FILE_TARGET}${NC}, ${RED}Critical >${FILE_WARN}${NC}"
      echo -e "  Desc:  Target <${DESCRIPTION_TARGET}, ${YELLOW}Warn >${DESCRIPTION_TARGET}${NC}, ${RED}Critical >${DESCRIPTION_WARN}${NC}"
      echo -e "  Tables: ${YELLOW}Warn >${TABLE_ROWS_WARN} rows${NC} (consider extraction)"
      echo ""

      # Issues summary
      if (( critical_count > 0 )) || (( warn_count > 0 )); then
        echo -e "${BOLD}Issues Found${NC}"
        (( critical_count > 0 )) && echo -e "  ${RED}Critical: $critical_count skills over ${FILE_WARN} chars${NC}"
        (( warn_count > 0 )) && echo -e "  ${YELLOW}Warning: $warn_count skills over ${FILE_TARGET} chars${NC}"
        echo ""

        echo -e "${BOLD}Recommendations${NC}"
        while IFS='|' read -r name file_size file_status desc_len desc_status table_rows table_status code_blocks has_patterns has_reference description; do
          [[ -z "$name" ]] && continue

          if [[ "$file_status" == "critical" ]] || [[ "$file_status" == "warn" ]]; then
            echo ""
            echo -e "  ${CYAN}$name${NC} (${file_size} chars)"

            if [[ "$file_status" == "critical" ]]; then
              echo -e "    ${RED}[CRITICAL]${NC} File size needs reduction"
            fi

            if (( table_rows > TABLE_ROWS_WARN )); then
              echo -e "    ${YELLOW}[TABLES]${NC} $table_rows table rows - extract to PATTERNS.md"
            fi

            if (( code_blocks > 10 )); then
              echo -e "    ${YELLOW}[CODE]${NC} $code_blocks code blocks - consider trimming examples"
            fi

            if [[ "$desc_status" != "ok" ]]; then
              echo -e "    ${YELLOW}[DESC]${NC} Description $desc_len chars - trim to <$DESCRIPTION_TARGET"
            fi
          fi
        done <<< "$sorted"
      else
        echo -e "${GREEN}All skills within size targets.${NC}"
      fi
      ;;
  esac
}

main
