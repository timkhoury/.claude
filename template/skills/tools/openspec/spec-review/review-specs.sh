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
#   detect          Find spec issues (small, large, orphan refs, empty reqs, clusters)
#   progress <analysis>  Show analysis progress (coverage|tests) [--json]
#   batch <analysis> [N] Get next N pending specs as comma-separated list (default: 12)
#   aggregate <analysis> Aggregate per-spec JSONs into results.json (coverage|tests)
#   report <analysis>    Generate markdown report from results.json (coverage|tests)
#
# Options:
#   --json          JSON output for scripting
#   --help          Show this help
#
# Detect flags (combine any):
#   --small         Specs with <3 requirements
#   --large         Specs with >12 requirements
#   --orphan-refs   Cross-references to non-existent specs
#   --empty-reqs    Requirements with 0 scenarios
#   --crossref-clusters  Specs with >3 cross-refs to same target

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

# Detect flags
DETECT_SMALL=false
DETECT_LARGE=false
DETECT_ORPHAN_REFS=false
DETECT_EMPTY_REQS=false
DETECT_CROSSREF_CLUSTERS=false
DETECT_ALL=true

# Parse global options
parse_options() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --json) OUTPUT_MODE="json"; shift ;;
      --help)
        head -29 "$0" | tail -27 | sed -E 's/^# ?//'
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
      jq -n --arg name "$name" --argjson reqs "$reqs" --argjson scenarios "$scenarios" \
        --arg size "$size" --arg prefix "$prefix" \
        '{name: $name, requirements: $reqs, scenarios: $scenarios, size: $size, prefix: $prefix}' | sed 's/^/    /'
    done
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
      printf '    %s' "$(jq -n --arg v "$f" '$v')"
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
      printf '    %s: %s' "$(jq -n --arg v "$prefix" '$v')" "${prefix_counts[$prefix]}"
    done
    echo ""
    echo "  },"
    echo "  \"crossReferences\": ["
    first=true
    for pair in "${crossref_pairs[@]}"; do
      if $first; then first=false; else echo ","; fi
      printf '    %s' "$(jq -n --arg v "$pair" '$v')"
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

# === Detect Helpers ===

detect_small() {
  local results=()
  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")
    local reqs
    reqs=$(count_requirements "$spec_file")
    if (( reqs < 3 )); then
      local prefix
      prefix=$(get_prefix "$name")
      results+=("$name|$reqs|$prefix")
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)
  printf '%s\n' "${results[@]}"
}

detect_large() {
  local results=()
  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")
    local reqs
    reqs=$(count_requirements "$spec_file")
    if (( reqs > 12 )); then
      results+=("$name|$reqs")
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)
  printf '%s\n' "${results[@]}"
}

detect_orphan_refs() {
  local results=()
  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")
    local refs
    refs=$(extract_crossrefs "$spec_file")
    if [[ -n "$refs" ]]; then
      IFS=',' read -ra ref_array <<< "$refs"
      for ref in "${ref_array[@]}"; do
        if [[ ! -d "$SPECS_DIR/$ref" ]]; then
          results+=("$name|$ref")
        fi
      done
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)
  printf '%s\n' "${results[@]}"
}

detect_empty_reqs() {
  local results=()
  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")
    local current_req=""
    local scenario_count=0
    local in_req=false

    while IFS= read -r line; do
      if [[ "$line" =~ ^###\ Requirement:\ (.+) ]]; then
        # Emit previous requirement if it had 0 scenarios
        if $in_req && (( scenario_count == 0 )); then
          results+=("$name|$current_req|0")
        fi
        current_req="${BASH_REMATCH[1]}"
        scenario_count=0
        in_req=true
      elif [[ "$line" =~ ^####\ Scenario: ]]; then
        scenario_count=$((scenario_count + 1))
      fi
    done < "$spec_file"

    # Check last requirement
    if $in_req && (( scenario_count == 0 )); then
      results+=("$name|$current_req|0")
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)
  printf '%s\n' "${results[@]}"
}

detect_crossref_clusters() {
  local results=()
  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    local name
    name=$(basename "$spec_dir")

    # Count each reference target (not deduplicated)
    local raw_refs
    raw_refs=$(grep -oE '\[([^\]]+)\]\(\.\.\/[^)]+\)' "$spec_file" 2>/dev/null || true)
    if [[ -n "$raw_refs" ]]; then
      # Extract target spec name from each ref, count per target
      local targets
      targets=$(echo "$raw_refs" | sed -E 's/.*\.\.\/([^/]+)\/.*/\1/' | sort | uniq -c | sort -rn)
      while read -r count target; do
        if (( count > 3 )); then
          results+=("$name|$target|$count")
        fi
      done <<< "$targets"
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)
  printf '%s\n' "${results[@]}"
}

cmd_detect() {
  if ! check_openspec; then
    if [[ "$OUTPUT_MODE" == "json" ]]; then
      echo '{"error": "No OpenSpec directory found"}'
    else
      echo -e "${RED}Error:${NC} No OpenSpec directory found at $SPECS_DIR"
    fi
    return 1
  fi

  # Determine which detections to run
  local run_small=$DETECT_ALL
  local run_large=$DETECT_ALL
  local run_orphan=$DETECT_ALL
  local run_empty=$DETECT_ALL
  local run_clusters=$DETECT_ALL

  $DETECT_SMALL && run_small=true
  $DETECT_LARGE && run_large=true
  $DETECT_ORPHAN_REFS && run_orphan=true
  $DETECT_EMPTY_REQS && run_empty=true
  $DETECT_CROSSREF_CLUSTERS && run_clusters=true

  # Run detections and collect results
  local small_results=() large_results=() orphan_results=() empty_results=() cluster_results=()

  if $run_small; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && small_results+=("$line")
    done < <(detect_small)
  fi

  if $run_large; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && large_results+=("$line")
    done < <(detect_large)
  fi

  if $run_orphan; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && orphan_results+=("$line")
    done < <(detect_orphan_refs)
  fi

  if $run_empty; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && empty_results+=("$line")
    done < <(detect_empty_reqs)
  fi

  if $run_clusters; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && cluster_results+=("$line")
    done < <(detect_crossref_clusters)
  fi

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    echo "{"
    echo "  \"detections\": {"

    # small
    echo "    \"small\": ["
    local first=true
    for item in "${small_results[@]}"; do
      IFS='|' read -r name reqs prefix <<< "$item"
      if $first; then first=false; else echo ","; fi
      jq -n --arg spec "$name" --argjson reqs "$reqs" --arg prefix "$prefix" \
        '{spec: $spec, requirements: $reqs, prefix: $prefix}' | sed 's/^/      /'
    done
    echo "    ],"

    # large
    echo "    \"large\": ["
    first=true
    for item in "${large_results[@]}"; do
      IFS='|' read -r name reqs <<< "$item"
      if $first; then first=false; else echo ","; fi
      jq -n --arg spec "$name" --argjson reqs "$reqs" \
        '{spec: $spec, requirements: $reqs}' | sed 's/^/      /'
    done
    echo "    ],"

    # orphanRefs
    echo "    \"orphanRefs\": ["
    first=true
    for item in "${orphan_results[@]}"; do
      IFS='|' read -r name target <<< "$item"
      if $first; then first=false; else echo ","; fi
      jq -n --arg spec "$name" --arg refs "$target" \
        '{spec: $spec, references: $refs, exists: false}' | sed 's/^/      /'
    done
    echo "    ],"

    # emptyReqs
    echo "    \"emptyReqs\": ["
    first=true
    for item in "${empty_results[@]}"; do
      IFS='|' read -r name requirement scenarios <<< "$item"
      if $first; then first=false; else echo ","; fi
      jq -n --arg spec "$name" --arg req "$requirement" --argjson scenarios "$scenarios" \
        '{spec: $spec, requirement: $req, scenarios: $scenarios}' | sed 's/^/      /'
    done
    echo "    ],"

    # crossrefClusters
    echo "    \"crossrefClusters\": ["
    first=true
    for item in "${cluster_results[@]}"; do
      IFS='|' read -r source target count <<< "$item"
      if $first; then first=false; else echo ","; fi
      jq -n --arg src "$source" --arg tgt "$target" --argjson count "$count" \
        '{source: $src, target: $tgt, count: $count}' | sed 's/^/      /'
    done
    echo "    ]"

    echo "  },"
    echo "  \"summary\": {"
    echo "    \"small\": ${#small_results[@]},"
    echo "    \"large\": ${#large_results[@]},"
    echo "    \"orphanRefs\": ${#orphan_results[@]},"
    echo "    \"emptyReqs\": ${#empty_results[@]},"
    echo "    \"crossrefClusters\": ${#cluster_results[@]}"
    echo "  }"
    echo "}"
  else
    echo -e "${BOLD}Spec Issue Detection${NC}"
    echo ""

    local total_issues=0

    if $run_small; then
      echo -e "${BOLD}Small Specs${NC} (<3 requirements) - ${CYAN}${#small_results[@]}${NC} found"
      if [[ ${#small_results[@]} -gt 0 ]]; then
        for item in "${small_results[@]}"; do
          IFS='|' read -r name reqs prefix <<< "$item"
          echo -e "  ${YELLOW}$name${NC} ($reqs reqs, prefix: $prefix)"
        done
      else
        echo -e "  ${GREEN}None${NC}"
      fi
      total_issues=$((total_issues + ${#small_results[@]}))
      echo ""
    fi

    if $run_large; then
      echo -e "${BOLD}Large Specs${NC} (>12 requirements) - ${CYAN}${#large_results[@]}${NC} found"
      if [[ ${#large_results[@]} -gt 0 ]]; then
        for item in "${large_results[@]}"; do
          IFS='|' read -r name reqs <<< "$item"
          echo -e "  ${YELLOW}$name${NC} ($reqs reqs)"
        done
      else
        echo -e "  ${GREEN}None${NC}"
      fi
      total_issues=$((total_issues + ${#large_results[@]}))
      echo ""
    fi

    if $run_orphan; then
      echo -e "${BOLD}Orphan References${NC} (to non-existent specs) - ${CYAN}${#orphan_results[@]}${NC} found"
      if [[ ${#orphan_results[@]} -gt 0 ]]; then
        for item in "${orphan_results[@]}"; do
          IFS='|' read -r name target <<< "$item"
          echo -e "  ${RED}$name${NC} -> $target"
        done
      else
        echo -e "  ${GREEN}None${NC}"
      fi
      total_issues=$((total_issues + ${#orphan_results[@]}))
      echo ""
    fi

    if $run_empty; then
      echo -e "${BOLD}Empty Requirements${NC} (0 scenarios) - ${CYAN}${#empty_results[@]}${NC} found"
      if [[ ${#empty_results[@]} -gt 0 ]]; then
        for item in "${empty_results[@]}"; do
          IFS='|' read -r name requirement scenarios <<< "$item"
          echo -e "  ${YELLOW}$name${NC}: $requirement"
        done
      else
        echo -e "  ${GREEN}None${NC}"
      fi
      total_issues=$((total_issues + ${#empty_results[@]}))
      echo ""
    fi

    if $run_clusters; then
      echo -e "${BOLD}Cross-Reference Clusters${NC} (>3 refs to same target) - ${CYAN}${#cluster_results[@]}${NC} found"
      if [[ ${#cluster_results[@]} -gt 0 ]]; then
        for item in "${cluster_results[@]}"; do
          IFS='|' read -r source target count <<< "$item"
          echo -e "  ${YELLOW}$source${NC} -> $target (${RED}$count${NC} refs)"
        done
      else
        echo -e "  ${GREEN}None${NC}"
      fi
      total_issues=$((total_issues + ${#cluster_results[@]}))
      echo ""
    fi

    echo -e "${BOLD}Total issues:${NC} $total_issues"
  fi
}

# === Progress & Batch ===

# Compute progress for an analysis type (coverage or tests)
# Sets these variables in the caller's scope:
#   PROGRESS_TOTAL, PROGRESS_COMPLETED, PROGRESS_FAILED
#   PROGRESS_PENDING (newline-separated), PROGRESS_COMPLETED_SPECS (newline-separated)
#   PROGRESS_STATUS (not_started|in_progress|complete)
compute_progress() {
  local analysis="$1"
  local analysis_dir="$AUDIT_DIR/$analysis/specs"

  PROGRESS_TOTAL=0
  PROGRESS_COMPLETED=0
  PROGRESS_FAILED=0
  PROGRESS_PENDING=""
  PROGRESS_COMPLETED_SPECS=""
  PROGRESS_STATUS="not_started"

  if ! check_openspec; then
    return 1
  fi

  # Collect all spec names
  local all_specs=()
  while IFS= read -r spec_file; do
    local spec_dir
    spec_dir=$(dirname "$spec_file")
    all_specs+=("$(basename "$spec_dir")")
  done < <(find "$SPECS_DIR" -name "spec.md" | sort)

  PROGRESS_TOTAL=${#all_specs[@]}

  if [[ $PROGRESS_TOTAL -eq 0 ]]; then
    PROGRESS_STATUS="complete"
    return 0
  fi

  # Check which specs have valid JSON in the analysis dir
  local pending=()
  local completed=()
  local failed=0

  for spec_name in "${all_specs[@]}"; do
    local json_file="$analysis_dir/$spec_name.json"
    if [[ -f "$json_file" ]]; then
      if jq empty "$json_file" 2>/dev/null; then
        completed+=("$spec_name")
      else
        failed=$((failed + 1))
        pending+=("$spec_name")
      fi
    else
      pending+=("$spec_name")
    fi
  done

  PROGRESS_COMPLETED=${#completed[@]}
  PROGRESS_FAILED=$failed
  PROGRESS_PENDING=$(printf '%s\n' "${pending[@]}")
  PROGRESS_COMPLETED_SPECS=$(printf '%s\n' "${completed[@]}")

  if [[ $PROGRESS_COMPLETED -eq 0 ]]; then
    PROGRESS_STATUS="not_started"
  elif [[ $PROGRESS_COMPLETED -eq $PROGRESS_TOTAL ]]; then
    PROGRESS_STATUS="complete"
  else
    PROGRESS_STATUS="in_progress"
  fi
}

cmd_progress() {
  local analysis="${ARG1:-}"

  if [[ -z "$analysis" ]]; then
    echo -e "${RED}Error:${NC} Missing analysis argument. Usage: $0 progress <coverage|tests> [--json]"
    return 1
  fi

  if [[ "$analysis" != "coverage" && "$analysis" != "tests" ]]; then
    echo -e "${RED}Error:${NC} Invalid analysis '$analysis'. Must be 'coverage' or 'tests'."
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error:${NC} jq is required for progress tracking"
    return 1
  fi

  if ! check_openspec; then
    if [[ "$OUTPUT_MODE" == "json" ]]; then
      echo '{"error": "No OpenSpec directory found"}'
    else
      echo -e "${RED}Error:${NC} No OpenSpec directory found at $SPECS_DIR"
    fi
    return 1
  fi

  compute_progress "$analysis"

  local pending_count
  if [[ -n "$PROGRESS_PENDING" ]]; then
    pending_count=$(echo "$PROGRESS_PENDING" | wc -l | tr -d ' ')
  else
    pending_count=0
  fi

  if [[ "$OUTPUT_MODE" == "json" ]]; then
    # Build pending array
    local pending_json="[]"
    if [[ -n "$PROGRESS_PENDING" ]]; then
      pending_json=$(echo "$PROGRESS_PENDING" | jq -R . | jq -s .)
    fi

    # Build completed array
    local completed_json="[]"
    if [[ -n "$PROGRESS_COMPLETED_SPECS" ]]; then
      completed_json=$(echo "$PROGRESS_COMPLETED_SPECS" | jq -R . | jq -s .)
    fi

    jq -n \
      --arg status "$PROGRESS_STATUS" \
      --argjson total "$PROGRESS_TOTAL" \
      --argjson completed "$PROGRESS_COMPLETED" \
      --argjson failed "$PROGRESS_FAILED" \
      --argjson pending "$pending_json" \
      --argjson completedSpecs "$completed_json" \
      '{status: $status, total: $total, completed: $completed, failed: $failed, pending: $pending, completedSpecs: $completedSpecs}'
  else
    local pct=0
    if [[ $PROGRESS_TOTAL -gt 0 ]]; then
      pct=$(( (PROGRESS_COMPLETED * 100) / PROGRESS_TOTAL ))
    fi

    echo -e "Progress: ${BOLD}$analysis${NC}"
    echo -e "  Status: ${CYAN}$PROGRESS_STATUS${NC}"
    echo -e "  Completed: ${GREEN}$PROGRESS_COMPLETED${NC}/$PROGRESS_TOTAL ($pct%)"
    echo -e "  Failed: ${YELLOW}$PROGRESS_FAILED${NC}"
    echo -e "  Pending: ${CYAN}$pending_count${NC}"
  fi
}

cmd_batch() {
  local analysis="${ARG1:-}"
  local batch_size="${ARG2:-12}"

  if [[ -z "$analysis" ]]; then
    echo -e "${RED}Error:${NC} Missing analysis argument. Usage: $0 batch <coverage|tests> [N]" >&2
    return 1
  fi

  if [[ "$analysis" != "coverage" && "$analysis" != "tests" ]]; then
    echo -e "${RED}Error:${NC} Invalid analysis '$analysis'. Must be 'coverage' or 'tests'." >&2
    return 1
  fi

  if ! [[ "$batch_size" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error:${NC} Batch size must be a number, got '$batch_size'." >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error:${NC} jq is required for batch operations" >&2
    return 1
  fi

  if ! check_openspec; then
    echo -e "${RED}Error:${NC} No OpenSpec directory found at $SPECS_DIR" >&2
    return 1
  fi

  compute_progress "$analysis"

  if [[ -z "$PROGRESS_PENDING" ]]; then
    return 0
  fi

  # Take first N pending specs and output as comma-separated
  echo "$PROGRESS_PENDING" | head -n "$batch_size" | paste -sd ',' -
}

# === Aggregate ===

cmd_aggregate() {
  local analysis="${ARG1:-}"

  if [[ -z "$analysis" ]]; then
    echo -e "${RED}Error:${NC} Missing analysis argument. Usage: $0 aggregate <coverage|tests>" >&2
    return 1
  fi

  if [[ "$analysis" != "coverage" && "$analysis" != "tests" ]]; then
    echo -e "${RED}Error:${NC} Invalid analysis '$analysis'. Must be 'coverage' or 'tests'." >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error:${NC} jq is required for aggregation" >&2
    return 1
  fi

  if ! check_openspec; then
    echo -e "${RED}Error:${NC} No OpenSpec directory found at $SPECS_DIR" >&2
    return 1
  fi

  local specs_dir="$AUDIT_DIR/$analysis/specs"
  local results_file="$AUDIT_DIR/$analysis/results.json"

  if [[ ! -d "$specs_dir" ]]; then
    echo -e "${RED}Error:${NC} No specs directory at $specs_dir. Run analysis first." >&2
    return 1
  fi

  compute_progress "$analysis"

  if [[ $PROGRESS_COMPLETED -eq 0 ]]; then
    echo -e "${RED}Error:${NC} No completed spec analyses found in $specs_dir" >&2
    return 1
  fi

  if [[ "$PROGRESS_STATUS" != "complete" ]]; then
    echo -e "${YELLOW}Warning:${NC} Only $PROGRESS_COMPLETED/$PROGRESS_TOTAL specs completed. Aggregating available results."
  fi

  # Aggregate all per-spec JSONs into a single results.json
  # shellcheck disable=SC2016
  local jq_expr

  if [[ "$analysis" == "coverage" ]]; then
    jq_expr='
def priority:
  if test("auth|security|permission|payment|error|fail|deny|invalid"; "i") then "high"
  elif test("create|update|delete|save|submit"; "i") then "medium"
  else "low"
  end;

{
  generatedAt: (now | todate),
  summary: {
    specsAnalyzed: length,
    totalScenarios: ([.[].scenarios.total] | add // 0),
    implementedScenarios: ([.[].scenarios.implemented] | add // 0),
    partialScenarios: ([.[].scenarios.partial] | add // 0),
    unimplementedScenarios: ([.[].scenarios.unimplemented] | add // 0),
    outdatedScenarios: ([.[].scenarios.outdated] | add // 0),
    coveragePercent: (
      ([.[].scenarios.total] | add // 0) as $total |
      if $total == 0 then 0
      else (([.[].scenarios.implemented] | add // 0) / $total * 100 | . * 10 | round / 10)
      end
    )
  },
  byCategory: (
    group_by(.spec | split("-")[0]) | map({
      key: .[0].spec | split("-")[0],
      value: {
        specs: length,
        scenarios: ([.[].scenarios.total] | add // 0),
        implemented: ([.[].scenarios.implemented] | add // 0),
        partial: ([.[].scenarios.partial] | add // 0),
        unimplemented: ([.[].scenarios.unimplemented] | add // 0),
        outdated: ([.[].scenarios.outdated] | add // 0)
      }
    }) | from_entries
  ),
  gaps: [
    .[] | .spec as $spec | .details[]? |
    select(.status == "unimplemented" or .status == "partial") |
    {
      spec: $spec,
      scenario: .scenario,
      priority: (.scenario | priority),
      missingConditions: (.missingConditions // [])
    }
  ],
  drift: [
    .[] | .spec as $spec | .details[]? |
    select(.status == "outdated") |
    {
      spec: $spec,
      scenario: .scenario,
      notes: (.notes // "")
    }
  ]
}'
  else
    # tests analysis
    jq_expr='
def priority:
  if test("auth|security|permission|payment|error|fail|deny|invalid"; "i") then "high"
  elif test("create|update|delete|save|submit"; "i") then "medium"
  else "low"
  end;

{
  generatedAt: (now | todate),
  summary: {
    specsAnalyzed: length,
    totalScenarios: ([.[].scenarios.total] | add // 0),
    coveredScenarios: ([.[].scenarios.covered] | add // 0),
    partialScenarios: ([.[].scenarios.partial] | add // 0),
    missingScenarios: ([.[].scenarios.missing] | add // 0),
    coveragePercent: (
      ([.[].scenarios.total] | add // 0) as $total |
      if $total == 0 then 0
      else (([.[].scenarios.covered] | add // 0) / $total * 100 | . * 10 | round / 10)
      end
    )
  },
  byCategory: (
    group_by(.spec | split("-")[0]) | map({
      key: .[0].spec | split("-")[0],
      value: {
        specs: length,
        scenarios: ([.[].scenarios.total] | add // 0),
        covered: ([.[].scenarios.covered] | add // 0),
        partial: ([.[].scenarios.partial] | add // 0),
        missing: ([.[].scenarios.missing] | add // 0)
      }
    }) | from_entries
  ),
  gaps: [
    .[] | .spec as $spec | .details[]? |
    select(.status == "missing" or .status == "partial") |
    {
      spec: $spec,
      scenario: .scenario,
      priority: (.scenario | priority),
      suggestion: (.suggestion // "")
    }
  ]
}'
  fi

  jq -s "$jq_expr" "$specs_dir"/*.json > "$results_file"

  echo -e "Wrote ${GREEN}$results_file${NC} ($PROGRESS_COMPLETED specs aggregated)"
}

# === Report ===

cmd_report() {
  local analysis="${ARG1:-}"

  if [[ -z "$analysis" ]]; then
    echo -e "${RED}Error:${NC} Missing analysis argument. Usage: $0 report <coverage|tests>" >&2
    return 1
  fi

  if [[ "$analysis" != "coverage" && "$analysis" != "tests" ]]; then
    echo -e "${RED}Error:${NC} Invalid analysis '$analysis'. Must be 'coverage' or 'tests'." >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error:${NC} jq is required for report generation" >&2
    return 1
  fi

  local results_file="$AUDIT_DIR/$analysis/results.json"

  if [[ ! -f "$results_file" ]]; then
    echo -e "${RED}Error:${NC} No results file at $results_file. Run 'aggregate $analysis' first." >&2
    return 1
  fi

  if [[ "$analysis" == "coverage" ]]; then
    report_coverage "$results_file"
  else
    report_tests "$results_file"
  fi
}

report_coverage() {
  local results_file="$1"
  local report_file="SPEC_COVERAGE_REPORT.md"

  # Extract values from results.json
  local generated_at specs_analyzed total_scenarios implemented partial unimplemented outdated coverage_pct
  generated_at=$(jq -r '.generatedAt' "$results_file")
  specs_analyzed=$(jq -r '.summary.specsAnalyzed' "$results_file")
  total_scenarios=$(jq -r '.summary.totalScenarios' "$results_file")
  implemented=$(jq -r '.summary.implementedScenarios' "$results_file")
  partial=$(jq -r '.summary.partialScenarios' "$results_file")
  unimplemented=$(jq -r '.summary.unimplementedScenarios' "$results_file")
  outdated=$(jq -r '.summary.outdatedScenarios' "$results_file")
  coverage_pct=$(jq -r '.summary.coveragePercent' "$results_file")

  # Compute percentages (integer arithmetic, no bc dependency)
  local impl_pct=0 partial_pct=0 unimpl_pct=0 outdated_pct=0
  if [[ $total_scenarios -gt 0 ]]; then
    impl_pct=$(( implemented * 100 / total_scenarios ))
    partial_pct=$(( partial * 100 / total_scenarios ))
    unimpl_pct=$(( unimplemented * 100 / total_scenarios ))
    outdated_pct=$(( outdated * 100 / total_scenarios ))
  fi

  # Generate gaps table
  local gaps_table
  gaps_table=$(jq -r '.gaps[] | "| \(.spec) | \(.scenario) | \(.priority) | \(.missingConditions | join("; ")) |"' "$results_file" 2>/dev/null || echo "")

  # Generate drift table
  local drift_table
  drift_table=$(jq -r '.drift[] | "| \(.spec) | \(.scenario) | \(.notes) |"' "$results_file" 2>/dev/null || echo "")

  cat > "$report_file" <<EOF
# Spec Coverage Report

**Generated:** $generated_at
**Implementation Coverage:** $implemented/$total_scenarios scenarios ($coverage_pct%)

## Summary

| Metric | Value |
|--------|-------|
| Specs Analyzed | $specs_analyzed |
| Implemented | $implemented ($impl_pct%) |
| Partial | $partial ($partial_pct%) |
| Unimplemented | $unimplemented ($unimpl_pct%) |
| Outdated (Drift) | $outdated ($outdated_pct%) |

## Unimplemented Scenarios

| Spec | Scenario | Priority | Missing |
|------|----------|----------|---------|
$gaps_table

## Spec Drift

| Spec | Scenario | Issue |
|------|----------|-------|
$drift_table
EOF

  echo -e "Wrote ${GREEN}$report_file${NC}"
}

report_tests() {
  local results_file="$1"
  local report_file="TEST_QUALITY_REPORT.md"

  # Extract values from results.json
  local generated_at specs_analyzed total_scenarios covered partial missing coverage_pct
  generated_at=$(jq -r '.generatedAt' "$results_file")
  specs_analyzed=$(jq -r '.summary.specsAnalyzed' "$results_file")
  total_scenarios=$(jq -r '.summary.totalScenarios' "$results_file")
  covered=$(jq -r '.summary.coveredScenarios' "$results_file")
  partial=$(jq -r '.summary.partialScenarios' "$results_file")
  missing=$(jq -r '.summary.missingScenarios' "$results_file")
  coverage_pct=$(jq -r '.summary.coveragePercent' "$results_file")

  # Compute percentages (integer arithmetic, no bc dependency)
  local covered_pct=0 partial_pct=0 missing_pct=0
  if [[ $total_scenarios -gt 0 ]]; then
    covered_pct=$(( covered * 100 / total_scenarios ))
    partial_pct=$(( partial * 100 / total_scenarios ))
    missing_pct=$(( missing * 100 / total_scenarios ))
  fi

  # Generate gaps table (high priority first)
  local gaps_table
  gaps_table=$(jq -r '[.gaps[] | select(.priority == "high")] + [.gaps[] | select(.priority == "medium")] + [.gaps[] | select(.priority == "low")] | .[] | "| \(.spec) | \(.scenario) | \(.priority) | \(.suggestion) |"' "$results_file" 2>/dev/null || echo "")

  cat > "$report_file" <<EOF
# Test Quality Report

**Generated:** $generated_at
**Spec Coverage:** $covered/$total_scenarios scenarios ($coverage_pct%)

## Summary

| Metric | Value |
|--------|-------|
| Specs Analyzed | $specs_analyzed |
| Covered | $covered ($covered_pct%) |
| Partial | $partial ($partial_pct%) |
| Missing | $missing ($missing_pct%) |

## High Priority Gaps

| Spec | Scenario | Priority | Suggestion |
|------|----------|----------|------------|
$gaps_table
EOF

  echo -e "Wrote ${GREEN}$report_file${NC}"
}

# === Main ===

main() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <command> [options]"
    echo "Run '$0 --help' for available commands"
    exit 1
  fi

  # Handle --help before command extraction
  if [[ "$1" == "--help" ]]; then
    head -29 "$0" | tail -27 | sed -E 's/^# ?//'
    exit 0
  fi

  local cmd="$1"
  shift

  # Capture positional args (non-flag) and flags separately
  ARG1=""
  ARG2=""
  local positional_index=0

  while [[ $# -gt 0 ]]; do
    case $1 in
      --json) OUTPUT_MODE="json"; shift ;;
      --small) DETECT_SMALL=true; DETECT_ALL=false; shift ;;
      --large) DETECT_LARGE=true; DETECT_ALL=false; shift ;;
      --orphan-refs) DETECT_ORPHAN_REFS=true; DETECT_ALL=false; shift ;;
      --empty-reqs) DETECT_EMPTY_REQS=true; DETECT_ALL=false; shift ;;
      --crossref-clusters) DETECT_CROSSREF_CLUSTERS=true; DETECT_ALL=false; shift ;;
      *)
        if [[ $positional_index -eq 0 ]]; then
          ARG1="$1"
        elif [[ $positional_index -eq 1 ]]; then
          ARG2="$1"
        fi
        positional_index=$((positional_index + 1))
        shift
        ;;
    esac
  done

  case $cmd in
    setup)      cmd_setup ;;
    status)     cmd_status ;;
    enumerate)  cmd_enumerate ;;
    test-health) cmd_test_health ;;
    structure)  cmd_structure ;;
    changes)    cmd_changes ;;
    detect)     cmd_detect ;;
    progress)   cmd_progress ;;
    batch)      cmd_batch ;;
    aggregate)  cmd_aggregate ;;
    report)     cmd_report ;;
    *)
      echo "Unknown command: $cmd"
      echo "Run '$0 --help' for available commands"
      exit 1
      ;;
  esac
}

main "$@"
