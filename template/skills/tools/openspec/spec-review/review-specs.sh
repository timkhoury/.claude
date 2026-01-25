#!/usr/bin/env bash
# review-specs.sh - Deterministic operations for spec-review skill
#
# Usage:
#   ./review-specs.sh <command> [options]
#
# Commands:
#   setup           Create output directories, add to .gitignore
#   status          Check prerequisites and progress files
#   enumerate       List all specs with requirement/scenario counts
#   test-health     Run tests and report pass/fail/skip counts
#   structure       Analyze spec organization (sizes, prefixes, cross-refs)
#   changes         Check for active OpenSpec changes
#
# Options:
#   --json          JSON output for scripting
#   --help          Show this help

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
SPECS_DIR="openspec/specs"
AUDIT_DIR=".spec-review"
COVERAGE_DIR="$AUDIT_DIR/coverage"
TESTS_DIR="$AUDIT_DIR/tests"
STRUCTURE_DIR="$AUDIT_DIR/structure"

# Output mode
OUTPUT_MODE="report"

# Parse global options
parse_options() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --json) OUTPUT_MODE="json"; shift ;;
      --help)
        head -20 "$0" | tail -18 | sed 's/^# //'
        exit 0
        ;;
      *) break ;;
    esac
  done
  echo "$@"
}

# Check if OpenSpec exists
check_openspec() {
  if [[ -d "$SPECS_DIR" ]]; then
    return 0
  else
    return 1
  fi
}

# Count specs
count_specs() {
  if check_openspec; then
    find "$SPECS_DIR" -name "spec.md" 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

# Count requirements in a spec file
count_requirements() {
  local file="$1"
  local count
  count=$(grep -c "^### Requirement:" "$file" 2>/dev/null || echo "0")
  echo "${count//[^0-9]/}"
}

# Count scenarios in a spec file
count_scenarios() {
  local file="$1"
  local count
  count=$(grep -c "^#### Scenario:" "$file" 2>/dev/null || echo "0")
  echo "${count//[^0-9]/}"
}

# Extract cross-references from a spec
extract_crossrefs() {
  local file="$1"
  local refs
  refs=$(grep -oE '\[([^\]]+)\]\(\.\.\/[^)]+\)' "$file" 2>/dev/null || true)
  if [[ -n "$refs" ]]; then
    echo "$refs" | sed -E 's/.*\.\.\/([^/]+)\/.*/\1/' | sort -u | tr '\n' ',' | sed 's/,$//'
  fi
}

# Get spec name prefix (before first hyphen)
get_prefix() {
  local name="$1"
  echo "$name" | cut -d'-' -f1
}

# Classify spec size
classify_size() {
  local reqs="$1"
  if (( reqs == 1 )); then echo "tiny"
  elif (( reqs <= 3 )); then echo "small"
  elif (( reqs <= 8 )); then echo "medium"
  elif (( reqs <= 12 )); then echo "large"
  else echo "huge"
  fi
}

# === Commands ===

cmd_setup() {
  echo -e "${BOLD}Setting up spec-review directories${NC}"
  echo ""

  mkdir -p "$COVERAGE_DIR/specs" "$TESTS_DIR/specs" "$STRUCTURE_DIR"
  echo -e "${GREEN}Created:${NC}"
  echo "  $COVERAGE_DIR/specs"
  echo "  $TESTS_DIR/specs"
  echo "  $STRUCTURE_DIR"

  # Add to .gitignore if not already present
  local gitignore=".gitignore"

  if ! grep -q "^${AUDIT_DIR}/$" "$gitignore" 2>/dev/null; then
    echo "${AUDIT_DIR}/" >> "$gitignore"
    echo -e "${GREEN}Updated:${NC} .gitignore"
  else
    echo -e "${CYAN}Already in:${NC} .gitignore"
  fi
}

cmd_status() {
  local has_openspec=false
  local spec_count=0
  local coverage_progress=""
  local tests_progress=""

  if check_openspec; then
    has_openspec=true
    spec_count=$(count_specs)
  fi

  # Check progress files
  if [[ -f "$COVERAGE_DIR/progress.json" ]]; then
    coverage_progress=$(cat "$COVERAGE_DIR/progress.json")
  fi

  if [[ -f "$TESTS_DIR/progress.json" ]]; then
    tests_progress=$(cat "$TESTS_DIR/progress.json")
  fi

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    cat <<EOF
{
  "hasOpenspec": $has_openspec,
  "specCount": $spec_count,
  "auditDir": "$AUDIT_DIR",
  "directories": {
    "root": $([ -d "$AUDIT_DIR" ] && echo "true" || echo "false"),
    "coverage": $([ -d "$COVERAGE_DIR" ] && echo "true" || echo "false"),
    "tests": $([ -d "$TESTS_DIR" ] && echo "true" || echo "false"),
    "structure": $([ -d "$STRUCTURE_DIR" ] && echo "true" || echo "false")
  },
  "progress": {
    "coverage": ${coverage_progress:-null},
    "tests": ${tests_progress:-null}
  }
}
EOF
  else
    echo -e "${BOLD}Spec Review Status${NC}"
    echo ""

    if $has_openspec; then
      echo -e "OpenSpec: ${GREEN}Found${NC} ($spec_count specs)"
    else
      echo -e "OpenSpec: ${YELLOW}Not found${NC} ($SPECS_DIR missing)"
    fi

    echo ""
    echo -e "${BOLD}Output Directory${NC} ($AUDIT_DIR)"
    [ -d "$AUDIT_DIR" ] && echo -e "  Root: ${GREEN}exists${NC}" || echo -e "  Root: ${YELLOW}missing${NC} (run 'setup')"
    [ -d "$COVERAGE_DIR" ] && echo -e "  coverage/: ${GREEN}exists${NC}" || echo -e "  coverage/: ${YELLOW}missing${NC}"
    [ -d "$TESTS_DIR" ] && echo -e "  tests/: ${GREEN}exists${NC}" || echo -e "  tests/: ${YELLOW}missing${NC}"
    [ -d "$STRUCTURE_DIR" ] && echo -e "  structure/: ${GREEN}exists${NC}" || echo -e "  structure/: ${YELLOW}missing${NC}"

    echo ""
    echo -e "${BOLD}Progress Files${NC}"
    if [[ -n "$coverage_progress" ]]; then
      local status completed total
      status=$(echo "$coverage_progress" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
      completed=$(echo "$coverage_progress" | grep -o '"completed":[0-9]*' | cut -d':' -f2)
      total=$(echo "$coverage_progress" | grep -o '"total":[0-9]*' | cut -d':' -f2)
      echo -e "  Coverage: ${CYAN}$status${NC} ($completed/$total specs)"
    else
      echo -e "  Coverage: ${YELLOW}none${NC}"
    fi

    if [[ -n "$tests_progress" ]]; then
      local status completed total
      status=$(echo "$tests_progress" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
      completed=$(echo "$tests_progress" | grep -o '"completed":[0-9]*' | cut -d':' -f2)
      total=$(echo "$tests_progress" | grep -o '"total":[0-9]*' | cut -d':' -f2)
      echo -e "  Tests: ${CYAN}$status${NC} ($completed/$total specs)"
    else
      echo -e "  Tests: ${YELLOW}none${NC}"
    fi
  fi
}

cmd_enumerate() {
  if ! check_openspec; then
    if [[ "$OUTPUT_MODE" == "json" ]]; then
      echo '{"error": "No OpenSpec directory found", "specs": []}'
    else
      echo -e "${RED}Error:${NC} No OpenSpec directory found at $SPECS_DIR"
    fi
    return 1
  fi

  local specs=()
  local total_reqs=0
  local total_scenarios=0

  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")
    local reqs
    reqs=$(count_requirements "$spec_file")
    local scenarios
    scenarios=$(count_scenarios "$spec_file")
    local size
    size=$(classify_size "$reqs")
    local prefix
    prefix=$(get_prefix "$name")

    specs+=("$name|$reqs|$scenarios|$size|$prefix")
    total_reqs=$((total_reqs + reqs))
    total_scenarios=$((total_scenarios + scenarios))
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    echo "{"
    echo "  \"total\": ${#specs[@]},"
    echo "  \"totalRequirements\": $total_reqs,"
    echo "  \"totalScenarios\": $total_scenarios,"
    echo "  \"specs\": ["
    local first=true
    for s in "${specs[@]}"; do
      IFS='|' read -r name reqs scenarios size prefix <<< "$s"
      if $first; then first=false; else echo ","; fi
      printf '    {"name": "%s", "requirements": %s, "scenarios": %s, "size": "%s", "prefix": "%s"}' \
        "$name" "$reqs" "$scenarios" "$size" "$prefix"
    done
    echo ""
    echo "  ]"
    echo "}"
  else
    echo -e "${BOLD}Spec Enumeration${NC}"
    echo ""
    echo -e "Total: ${CYAN}${#specs[@]}${NC} specs, ${CYAN}$total_reqs${NC} requirements, ${CYAN}$total_scenarios${NC} scenarios"
    echo ""
    printf "%-40s %5s %5s %8s %s\n" "Spec" "Reqs" "Scen" "Size" "Prefix"
    printf "%-40s %5s %5s %8s %s\n" "----" "----" "----" "----" "------"

    # Sort by requirements descending
    printf '%s\n' "${specs[@]}" | sort -t'|' -k2 -nr | while IFS='|' read -r name reqs scenarios size prefix; do
      local size_color="$NC"
      if [[ "$size" == "huge" ]]; then size_color="$RED"
      elif [[ "$size" == "large" ]]; then size_color="$YELLOW"
      elif [[ "$size" == "small" ]] || [[ "$size" == "tiny" ]]; then size_color="$CYAN"
      fi
      printf "%-40s %5s %5s ${size_color}%8s${NC} %s\n" "$name" "$reqs" "$scenarios" "$size" "$prefix"
    done
  fi
}

cmd_test_health() {
  local unit_passed=0 unit_failed=0 unit_skipped=0
  local e2e_passed=0 e2e_failed=0
  local skipped_files=()

  # Find skipped tests
  while IFS= read -r file; do
    skipped_files+=("$file")
  done < <(grep -rl "(it|test)\.skip\(" src e2e 2>/dev/null || true)

  # Count test files
  local unit_files e2e_files
  unit_files=$(find src -name "*.test.ts" 2>/dev/null | wc -l | tr -d ' ')
  e2e_files=$(find e2e -name "*.spec.ts" 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    echo "{"
    echo "  \"unitTestFiles\": $unit_files,"
    echo "  \"e2eTestFiles\": $e2e_files,"
    echo "  \"skippedTestFiles\": ["
    local first=true
    for f in "${skipped_files[@]}"; do
      if $first; then first=false; else echo ","; fi
      printf '    "%s"' "$f"
    done
    if [[ ${#skipped_files[@]} -gt 0 ]]; then echo ""; fi
    echo "  ],"
    echo "  \"note\": \"Run 'npm run test' and 'npm run test:e2e' for actual pass/fail counts\""
    echo "}"
  else
    echo -e "${BOLD}Test Health Check${NC}"
    echo ""
    echo -e "${BOLD}Test Files${NC}"
    echo -e "  Unit tests: ${CYAN}$unit_files${NC} files"
    echo -e "  E2E tests: ${CYAN}$e2e_files${NC} files"

    if [[ ${#skipped_files[@]} -gt 0 ]]; then
      echo ""
      echo -e "${BOLD}Skipped Tests${NC} (${YELLOW}${#skipped_files[@]} files${NC})"
      for f in "${skipped_files[@]}"; do
        echo "  $f"
      done
    fi

    echo ""
    echo -e "${CYAN}Note:${NC} Run 'npm run test' and 'npm run test:e2e' for actual pass/fail counts"
  fi
}

cmd_structure() {
  if ! check_openspec; then
    if [[ "$OUTPUT_MODE" == "json" ]]; then
      echo '{"error": "No OpenSpec directory found"}'
    else
      echo -e "${RED}Error:${NC} No OpenSpec directory found at $SPECS_DIR"
    fi
    return 1
  fi

  # Collect stats
  local tiny=0 small=0 medium=0 large=0 huge=0
  declare -A prefix_counts
  local crossref_pairs=()

  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")
    local reqs
    reqs=$(count_requirements "$spec_file")
    local size
    size=$(classify_size "$reqs")
    local prefix
    prefix=$(get_prefix "$name")
    local crossrefs
    crossrefs=$(extract_crossrefs "$spec_file")

    case $size in
      tiny) tiny=$((tiny + 1)) ;;
      small) small=$((small + 1)) ;;
      medium) medium=$((medium + 1)) ;;
      large) large=$((large + 1)) ;;
      huge) huge=$((huge + 1)) ;;
    esac

    prefix_counts[$prefix]=$((${prefix_counts[$prefix]:-0} + 1))

    if [[ -n "$crossrefs" ]]; then
      crossref_pairs+=("$name -> $crossrefs")
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    echo "{"
    echo "  \"sizeDistribution\": {"
    echo "    \"tiny\": $tiny,"
    echo "    \"small\": $small,"
    echo "    \"medium\": $medium,"
    echo "    \"large\": $large,"
    echo "    \"huge\": $huge"
    echo "  },"
    echo "  \"prefixes\": {"
    local first=true
    for prefix in "${!prefix_counts[@]}"; do
      if $first; then first=false; else echo ","; fi
      printf '    "%s": %s' "$prefix" "${prefix_counts[$prefix]}"
    done
    echo ""
    echo "  },"
    echo "  \"crossReferences\": ["
    first=true
    for pair in "${crossref_pairs[@]}"; do
      if $first; then first=false; else echo ","; fi
      printf '    "%s"' "$pair"
    done
    if [[ ${#crossref_pairs[@]} -gt 0 ]]; then echo ""; fi
    echo "  ]"
    echo "}"
  else
    echo -e "${BOLD}Structure Analysis${NC}"
    echo ""

    echo -e "${BOLD}Size Distribution${NC}"
    printf "  %-10s %s\n" "tiny" "$tiny"
    printf "  %-10s %s\n" "small" "$small"
    printf "  %-10s %s\n" "medium" "$medium"
    printf "  %-10s %s\n" "large" "$large"
    printf "  %-10s %s\n" "huge" "$huge"

    echo ""
    echo -e "${BOLD}Prefix Groups${NC} (potential clusters)"
    for prefix in $(echo "${!prefix_counts[@]}" | tr ' ' '\n' | sort); do
      local count=${prefix_counts[$prefix]}
      if (( count > 1 )); then
        echo -e "  ${CYAN}$prefix${NC}: $count specs"
      fi
    done

    if [[ ${#crossref_pairs[@]} -gt 0 ]]; then
      echo ""
      echo -e "${BOLD}Cross-References${NC}"
      for pair in "${crossref_pairs[@]}"; do
        echo "  $pair"
      done
    fi
  fi
}

cmd_changes() {
  if ! command -v npx &> /dev/null; then
    echo -e "${RED}Error:${NC} npx not found"
    return 1
  fi

  local output
  output=$(npx openspec list 2>&1 || true)

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    if echo "$output" | grep -q "No active changes"; then
      echo '{"activeChanges": [], "hasActiveChanges": false}'
    else
      echo '{"activeChanges": "parse_output_manually", "hasActiveChanges": true, "raw": '"$(echo "$output" | jq -Rs .)"'}'
    fi
  else
    echo -e "${BOLD}Active OpenSpec Changes${NC}"
    echo ""
    if echo "$output" | grep -q "No active changes"; then
      echo -e "${GREEN}None${NC} - all specs safe to refactor"
    else
      echo "$output"
      echo ""
      echo -e "${YELLOW}Warning:${NC} Do not suggest refactoring specs affected by active changes"
    fi
  fi
}

# === Main ===

main() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <command> [options]"
    echo "Run '$0 --help' for available commands"
    exit 1
  fi

  local cmd="$1"
  shift

  # Parse remaining options
  while [[ $# -gt 0 ]]; do
    case $1 in
      --json) OUTPUT_MODE="json"; shift ;;
      *) shift ;;
    esac
  done

  case $cmd in
    setup)      cmd_setup ;;
    status)     cmd_status ;;
    enumerate)  cmd_enumerate ;;
    test-health) cmd_test_health ;;
    structure)  cmd_structure ;;
    changes)    cmd_changes ;;
    *)
      echo "Unknown command: $cmd"
      echo "Run '$0 --help' for available commands"
      exit 1
      ;;
  esac
}

main "$@"
