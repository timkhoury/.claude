#!/usr/bin/env bash
# Detect technologies in a project and output required rules
# Usage: detect-technologies.sh [--json|--rules|--techs|--report]
#
# Reads tech-detection.yaml and checks:
#   - package.json for dependencies
#   - Config files for existence
#   - Directories for existence
#
# Outputs:
#   --json    Full detection results as JSON
#   --rules   List of rule paths to copy (one per line)
#   --techs   List of detected technology names (one per line)
#   --report  Human-readable report (default)

set -e

CONFIG_FILE="$HOME/.claude/config/sync-config.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
MODE="report"
case "${1:-}" in
  --json)   MODE="json" ;;
  --rules)  MODE="rules" ;;
  --techs)  MODE="techs" ;;
  --report) MODE="report" ;;
  --help|-h)
    echo "Usage: detect-technologies.sh [--json|--rules|--techs|--report]"
    echo ""
    echo "Outputs:"
    echo "  --report  Human-readable report (default)"
    echo "  --techs   List of detected technology names"
    echo "  --rules   List of rule paths to copy"
    echo "  --json    Full detection results as JSON"
    exit 0
    ;;
esac

# Check config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config not found at $CONFIG_FILE" >&2
  exit 1
fi

# Check for yq or parse manually
if ! command -v yq &> /dev/null; then
  # Fallback: use node to parse YAML if available
  if command -v node &> /dev/null; then
    PARSER="node"
  else
    echo "Error: yq or node required to parse YAML" >&2
    exit 1
  fi
else
  PARSER="yq"
fi

# Helper: check if package exists in package.json
has_package() {
  local pkg="$1"
  if [[ ! -f "package.json" ]]; then
    return 1
  fi
  # Check both dependencies and devDependencies
  if command -v jq &> /dev/null; then
    jq -e "(.dependencies[\"$pkg\"] // .devDependencies[\"$pkg\"]) != null" package.json &> /dev/null
  else
    grep -q "\"$pkg\"" package.json 2>/dev/null
  fi
}

# Helper: check if config file exists (supports glob)
has_config() {
  local pattern="$1"
  ls $pattern &> /dev/null 2>&1
}

# Helper: check if directory exists
has_directory() {
  local dir="$1"
  [[ -d "$dir" ]]
}

# Arrays to track results
declare -a DETECTED_TECHS=()
declare -a DETECTED_RULES=()
declare -a ALWAYS_RULES=()

# Parse config and detect technologies using node
detect_with_node() {
  node --input-type=module -e "
import { readFileSync } from 'fs';
import { parse } from 'yaml';

const config = parse(readFileSync('$CONFIG_FILE', 'utf8'));
const detected = [];
const rules = [];

// Check each technology
for (const [name, tech] of Object.entries(config.technologies || {})) {
  let found = false;
  const detect = tech.detect || {};

  // Check packages
  for (const pkg of detect.packages || []) {
    try {
      const pkgJson = JSON.parse(readFileSync('package.json', 'utf8'));
      if (pkgJson.dependencies?.[pkg] || pkgJson.devDependencies?.[pkg]) {
        found = true;
        break;
      }
    } catch {}
  }

  // Check configs (simple file existence, no glob)
  if (!found) {
    for (const cfg of detect.configs || []) {
      try {
        readFileSync(cfg);
        found = true;
        break;
      } catch {}
    }
  }

  // Check directories
  if (!found) {
    for (const dir of detect.directories || []) {
      try {
        const { statSync } = await import('fs');
        if (statSync(dir).isDirectory()) {
          found = true;
          break;
        }
      } catch {}
    }
  }

  if (found) {
    detected.push(name);
    rules.push(...(tech.rules || []));
  }
}

// Check integrations
for (const integration of config.integrations || []) {
  const requires = integration.requires || [];
  const requiresAny = integration.requires_any || [];

  const hasAll = requires.every(t => detected.includes(t));
  const hasAny = requiresAny.length === 0 || requiresAny.some(t => detected.includes(t));

  if (hasAll && hasAny) {
    rules.push(...(integration.rules || []));
  }
}

// Always rules
const always = config.always?.rules || [];

// Output based on mode
const mode = '$MODE';
if (mode === 'json') {
  console.log(JSON.stringify({ detected, rules, always }, null, 2));
} else if (mode === 'techs') {
  detected.forEach(t => console.log(t));
} else if (mode === 'rules') {
  [...new Set([...always, ...rules])].forEach(r => console.log(r));
} else {
  // report mode
  console.log('Detected technologies:');
  if (detected.length === 0) {
    console.log('  (none)');
  } else {
    detected.forEach(t => console.log('  + ' + t));
  }
  console.log('');
  console.log('Rules to copy:');
  console.log('  Always:');
  always.forEach(r => console.log('    - ' + r));
  console.log('  Technology-specific:');
  if (rules.length === 0) {
    console.log('    (none)');
  } else {
    [...new Set(rules)].forEach(r => console.log('    - ' + r));
  }
}
" 2>/dev/null
}

# Parse config and detect using yq + bash
detect_with_yq() {
  # Get always rules
  ALWAYS_RULES=($(yq -r '.always.rules[]' "$CONFIG_FILE" 2>/dev/null || true))

  # Get technology names
  local techs=($(yq -r '.technologies | keys[]' "$CONFIG_FILE" 2>/dev/null))

  for tech in "${techs[@]}"; do
    local found=false

    # Check packages
    local packages=($(yq -r ".technologies.$tech.detect.packages[]" "$CONFIG_FILE" 2>/dev/null || true))
    for pkg in "${packages[@]}"; do
      if has_package "$pkg"; then
        found=true
        break
      fi
    done

    # Check configs
    if [[ "$found" == "false" ]]; then
      local configs=($(yq -r ".technologies.$tech.detect.configs[]" "$CONFIG_FILE" 2>/dev/null || true))
      for cfg in "${configs[@]}"; do
        if has_config "$cfg"; then
          found=true
          break
        fi
      done
    fi

    # Check directories
    if [[ "$found" == "false" ]]; then
      local dirs=($(yq -r ".technologies.$tech.detect.directories[]" "$CONFIG_FILE" 2>/dev/null || true))
      for dir in "${dirs[@]}"; do
        if has_directory "$dir"; then
          found=true
          break
        fi
      done
    fi

    if [[ "$found" == "true" ]]; then
      DETECTED_TECHS+=("$tech")
      local rules=($(yq -r ".technologies.$tech.rules[]" "$CONFIG_FILE" 2>/dev/null || true))
      DETECTED_RULES+=("${rules[@]}")
    fi
  done

  # Check integrations
  local num_integrations=$(yq -r '.integrations | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  for ((i=0; i<num_integrations; i++)); do
    local requires=($(yq -r ".integrations[$i].requires[]" "$CONFIG_FILE" 2>/dev/null || true))
    local requires_any=($(yq -r ".integrations[$i].requires_any[]" "$CONFIG_FILE" 2>/dev/null || true))

    local has_all=true
    for req in "${requires[@]}"; do
      if [[ ! " ${DETECTED_TECHS[*]} " =~ " $req " ]]; then
        has_all=false
        break
      fi
    done

    local has_any=true
    if [[ ${#requires_any[@]} -gt 0 ]]; then
      has_any=false
      for req in "${requires_any[@]}"; do
        if [[ " ${DETECTED_TECHS[*]} " =~ " $req " ]]; then
          has_any=true
          break
        fi
      done
    fi

    if [[ "$has_all" == "true" ]] && [[ "$has_any" == "true" ]]; then
      local rules=($(yq -r ".integrations[$i].rules[]" "$CONFIG_FILE" 2>/dev/null || true))
      DETECTED_RULES+=("${rules[@]}")
    fi
  done

  # Output based on mode
  case "$MODE" in
    json)
      echo "{"
      echo "  \"detected\": [$(printf '"%s",' "${DETECTED_TECHS[@]}" | sed 's/,$//')],"
      echo "  \"rules\": [$(printf '"%s",' "${DETECTED_RULES[@]}" | sed 's/,$//')],"
      echo "  \"always\": [$(printf '"%s",' "${ALWAYS_RULES[@]}" | sed 's/,$//')]"
      echo "}"
      ;;
    techs)
      printf '%s\n' "${DETECTED_TECHS[@]}"
      ;;
    rules)
      printf '%s\n' "${ALWAYS_RULES[@]}" "${DETECTED_RULES[@]}" | sort -u
      ;;
    report)
      echo -e "${GREEN}Detected technologies:${NC}"
      if [[ ${#DETECTED_TECHS[@]} -eq 0 ]]; then
        echo "  (none)"
      else
        for tech in "${DETECTED_TECHS[@]}"; do
          echo -e "  ${GREEN}+${NC} $tech"
        done
      fi
      echo ""
      echo -e "${BLUE}Rules to copy:${NC}"
      echo "  Always:"
      for rule in "${ALWAYS_RULES[@]}"; do
        echo "    - $rule"
      done
      echo "  Technology-specific:"
      if [[ ${#DETECTED_RULES[@]} -eq 0 ]]; then
        echo "    (none)"
      else
        printf '%s\n' "${DETECTED_RULES[@]}" | sort -u | while read -r rule; do
          echo "    - $rule"
        done
      fi
      ;;
  esac
}

# Run detection
if [[ "$PARSER" == "node" ]]; then
  detect_with_node
else
  detect_with_yq
fi
