#!/usr/bin/env bash
# Detect technologies/tools and output sync configuration
# Usage: detect-technologies.sh [--json|--rules|--skills|--commands|--techs|--tools|--report]
#
# Reads sync-config.yaml and checks:
#   - package.json for dependencies
#   - Config files for existence
#   - Directories for existence
#
# Outputs:
#   --json     Full detection results as JSON
#   --rules    List of rule paths to copy (one per line)
#   --skills   List of skill paths to copy (one per line)
#   --commands List of command paths to copy (one per line)
#   --techs    List of detected technology names (one per line)
#   --tools    List of detected tool names (one per line)
#   --report   Human-readable report (default)

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
  --json)     MODE="json" ;;
  --rules)    MODE="rules" ;;
  --skills)   MODE="skills" ;;
  --commands) MODE="commands" ;;
  --techs)    MODE="techs" ;;
  --tools)    MODE="tools" ;;
  --report)   MODE="report" ;;
  --help|-h)
    echo "Usage: detect-technologies.sh [--json|--rules|--skills|--commands|--techs|--tools|--report]"
    echo ""
    echo "Outputs:"
    echo "  --report   Human-readable report (default)"
    echo "  --techs    List of detected technology names"
    echo "  --tools    List of detected tool names (beads, openspec)"
    echo "  --rules    List of rule paths to copy"
    echo "  --skills   List of skill paths to copy"
    echo "  --commands List of command paths to copy"
    echo "  --json     Full detection results as JSON"
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
import { readFileSync, statSync } from 'fs';
import { parse } from 'yaml';

const config = parse(readFileSync('$CONFIG_FILE', 'utf8'));
const detectedTechs = [];
const detectedTools = [];
const techRules = [];
const toolRules = [];
const toolSkills = [];
const toolCommands = [];

// Helper to check directory existence
const hasDir = (dir) => { try { return statSync(dir).isDirectory(); } catch { return false; } };
const hasFile = (file) => { try { readFileSync(file); return true; } catch { return false; } };
const hasPackage = (pkg) => {
  try {
    const pkgJson = JSON.parse(readFileSync('package.json', 'utf8'));
    return !!(pkgJson.dependencies?.[pkg] || pkgJson.devDependencies?.[pkg]);
  } catch { return false; }
};

// Check each technology (two passes: direct detection first, then requires-based)
const techEntries = Object.entries(config.technologies || {});

// Pass 1: Direct detection (packages, configs, directories)
for (const [name, tech] of techEntries) {
  const detect = tech.detect || {};
  if (detect.requires) continue; // Skip requires-based, handled in pass 2
  let found = (detect.packages || []).some(hasPackage) ||
              (detect.configs || []).some(hasFile) ||
              (detect.directories || []).some(hasDir);
  if (found) {
    detectedTechs.push(name);
    techRules.push(...(tech.rules || []));
  }
}

// Pass 2: Requires-based detection (integrations)
for (const [name, tech] of techEntries) {
  const detect = tech.detect || {};
  if (!detect.requires) continue; // Only requires-based
  const requires = detect.requires || [];
  const requiresAny = detect.requires_any || [];
  const hasAll = requires.every(t => detectedTechs.includes(t));
  const hasAny = requiresAny.length === 0 || requiresAny.some(t => detectedTechs.includes(t));
  if (hasAll && hasAny) {
    detectedTechs.push(name);
    techRules.push(...(tech.rules || []));
  }
}

// Check each tool (two passes: direct detection first, then requires-based)
const toolEntries = Object.entries(config.tools || {});

// Pass 1: Direct detection (directories)
for (const [name, tool] of toolEntries) {
  const detect = tool.detect || {};
  if (detect.requires) continue; // Skip requires-based, handled in pass 2
  let found = (detect.directories || []).some(hasDir);
  if (found) {
    detectedTools.push(name);
    toolRules.push(...(tool.rules || []));
    toolSkills.push(...(tool.skills || []));
    toolCommands.push(...(tool.commands || []));
  }
}

// Pass 2: Requires-based detection (integrations)
for (const [name, tool] of toolEntries) {
  const detect = tool.detect || {};
  if (!detect.requires) continue; // Only requires-based
  const requires = detect.requires || [];
  const hasAll = requires.every(t => detectedTools.includes(t));
  if (hasAll) {
    detectedTools.push(name);
    toolRules.push(...(tool.rules || []));
    toolSkills.push(...(tool.skills || []));
    toolCommands.push(...(tool.commands || []));
  }
}

// Always rules and skills
const alwaysRules = config.always?.rules || [];
const alwaysSkills = config.always?.skills || [];

// Output based on mode
const mode = '$MODE';
if (mode === 'json') {
  console.log(JSON.stringify({ detectedTechs, detectedTools, techRules, toolRules, toolSkills, toolCommands, alwaysRules, alwaysSkills }, null, 2));
} else if (mode === 'techs') {
  detectedTechs.forEach(t => console.log(t));
} else if (mode === 'tools') {
  detectedTools.forEach(t => console.log(t));
} else if (mode === 'rules') {
  [...new Set([...alwaysRules, ...techRules, ...toolRules])].forEach(r => console.log(r));
} else if (mode === 'skills') {
  [...new Set([...alwaysSkills, ...toolSkills])].forEach(s => console.log(s));
} else if (mode === 'commands') {
  [...new Set(toolCommands)].forEach(c => console.log(c));
} else {
  // report mode
  console.log('Detected technologies:');
  detectedTechs.length ? detectedTechs.forEach(t => console.log('  + ' + t)) : console.log('  (none)');
  console.log('');
  console.log('Detected tools:');
  detectedTools.length ? detectedTools.forEach(t => console.log('  + ' + t)) : console.log('  (none)');
  console.log('');
  console.log('Rules to copy:');
  console.log('  Always:');
  alwaysRules.forEach(r => console.log('    - ' + r));
  console.log('  Technology-specific:');
  techRules.length ? [...new Set(techRules)].forEach(r => console.log('    - ' + r)) : console.log('    (none)');
  console.log('  Tool-specific:');
  toolRules.length ? [...new Set(toolRules)].forEach(r => console.log('    - ' + r)) : console.log('    (none)');
  console.log('');
  console.log('Skills to copy:');
  console.log('  Always:');
  alwaysSkills.forEach(s => console.log('    - ' + s));
  console.log('  Tool-specific:');
  toolSkills.length ? [...new Set(toolSkills)].forEach(s => console.log('    - ' + s)) : console.log('    (none)');
  console.log('');
  console.log('Commands to copy:');
  toolCommands.length ? [...new Set(toolCommands)].forEach(c => console.log('  - ' + c)) : console.log('  (none)');
}
" 2>/dev/null
}

# Parse config and detect using yq + bash
detect_with_yq() {
  # Get always rules and skills
  ALWAYS_RULES=($(yq -r '.always.rules[]' "$CONFIG_FILE" 2>/dev/null || true))
  ALWAYS_SKILLS=($(yq -r '.always.skills[]' "$CONFIG_FILE" 2>/dev/null || true))

  # Arrays for tool detection
  declare -a DETECTED_TOOLS=()
  declare -a TOOL_RULES=()
  declare -a TOOL_SKILLS=()
  declare -a TOOL_COMMANDS=()

  # Get technology names
  local techs=($(yq -r '.technologies | keys[]' "$CONFIG_FILE" 2>/dev/null))

  # Pass 1: Direct detection (packages, configs, directories)
  for tech in "${techs[@]}"; do
    # Skip requires-based (handled in pass 2)
    local has_requires=$(yq -r ".technologies.$tech.detect.requires // empty" "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$has_requires" ]]; then
      continue
    fi

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

  # Pass 2: Requires-based detection (integrations within technologies)
  for tech in "${techs[@]}"; do
    local requires=($(yq -r ".technologies.$tech.detect.requires[]" "$CONFIG_FILE" 2>/dev/null || true))
    if [[ ${#requires[@]} -eq 0 ]]; then
      continue
    fi

    local requires_any=($(yq -r ".technologies.$tech.detect.requires_any[]" "$CONFIG_FILE" 2>/dev/null || true))

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
      DETECTED_TECHS+=("$tech")
      local rules=($(yq -r ".technologies.$tech.rules[]" "$CONFIG_FILE" 2>/dev/null || true))
      DETECTED_RULES+=("${rules[@]}")
    fi
  done

  # Check tools
  local tools=($(yq -r '.tools | keys[]' "$CONFIG_FILE" 2>/dev/null || true))

  # Pass 1: Direct detection (directories)
  for tool in "${tools[@]}"; do
    # Skip requires-based (handled in pass 2)
    local has_requires=$(yq -r ".tools.$tool.detect.requires // empty" "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$has_requires" ]]; then
      continue
    fi

    local found=false
    local dirs=($(yq -r ".tools.$tool.detect.directories[]" "$CONFIG_FILE" 2>/dev/null || true))
    for dir in "${dirs[@]}"; do
      if has_directory "$dir"; then
        found=true
        break
      fi
    done

    if [[ "$found" == "true" ]]; then
      DETECTED_TOOLS+=("$tool")
      local rules=($(yq -r ".tools.$tool.rules[]" "$CONFIG_FILE" 2>/dev/null || true))
      local skills=($(yq -r ".tools.$tool.skills[]" "$CONFIG_FILE" 2>/dev/null || true))
      local commands=($(yq -r ".tools.$tool.commands[]" "$CONFIG_FILE" 2>/dev/null || true))
      TOOL_RULES+=("${rules[@]}")
      TOOL_SKILLS+=("${skills[@]}")
      TOOL_COMMANDS+=("${commands[@]}")
    fi
  done

  # Pass 2: Requires-based detection (integrations within tools)
  for tool in "${tools[@]}"; do
    local requires=($(yq -r ".tools.$tool.detect.requires[]" "$CONFIG_FILE" 2>/dev/null || true))
    if [[ ${#requires[@]} -eq 0 ]]; then
      continue
    fi

    local has_all=true
    for req in "${requires[@]}"; do
      if [[ ! " ${DETECTED_TOOLS[*]} " =~ " $req " ]]; then
        has_all=false
        break
      fi
    done

    if [[ "$has_all" == "true" ]]; then
      DETECTED_TOOLS+=("$tool")
      local rules=($(yq -r ".tools.$tool.rules[]" "$CONFIG_FILE" 2>/dev/null || true))
      local skills=($(yq -r ".tools.$tool.skills[]" "$CONFIG_FILE" 2>/dev/null || true))
      local commands=($(yq -r ".tools.$tool.commands[]" "$CONFIG_FILE" 2>/dev/null || true))
      TOOL_RULES+=("${rules[@]}")
      TOOL_SKILLS+=("${skills[@]}")
      TOOL_COMMANDS+=("${commands[@]}")
    fi
  done

  # Output based on mode
  case "$MODE" in
    json)
      echo "{"
      echo "  \"detectedTechs\": [$(printf '"%s",' "${DETECTED_TECHS[@]}" | sed 's/,$//')],"
      echo "  \"detectedTools\": [$(printf '"%s",' "${DETECTED_TOOLS[@]}" | sed 's/,$//')],"
      echo "  \"techRules\": [$(printf '"%s",' "${DETECTED_RULES[@]}" | sed 's/,$//')],"
      echo "  \"toolRules\": [$(printf '"%s",' "${TOOL_RULES[@]}" | sed 's/,$//')],"
      echo "  \"toolSkills\": [$(printf '"%s",' "${TOOL_SKILLS[@]}" | sed 's/,$//')],"
      echo "  \"toolCommands\": [$(printf '"%s",' "${TOOL_COMMANDS[@]}" | sed 's/,$//')],"
      echo "  \"alwaysRules\": [$(printf '"%s",' "${ALWAYS_RULES[@]}" | sed 's/,$//')],"
      echo "  \"alwaysSkills\": [$(printf '"%s",' "${ALWAYS_SKILLS[@]}" | sed 's/,$//')]"
      echo "}"
      ;;
    techs)
      printf '%s\n' "${DETECTED_TECHS[@]}"
      ;;
    tools)
      printf '%s\n' "${DETECTED_TOOLS[@]}"
      ;;
    rules)
      printf '%s\n' "${ALWAYS_RULES[@]}" "${DETECTED_RULES[@]}" "${TOOL_RULES[@]}" | sort -u
      ;;
    skills)
      printf '%s\n' "${ALWAYS_SKILLS[@]}" "${TOOL_SKILLS[@]}" | sort -u
      ;;
    commands)
      printf '%s\n' "${TOOL_COMMANDS[@]}" | sort -u
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
      echo -e "${GREEN}Detected tools:${NC}"
      if [[ ${#DETECTED_TOOLS[@]} -eq 0 ]]; then
        echo "  (none)"
      else
        for tool in "${DETECTED_TOOLS[@]}"; do
          echo -e "  ${GREEN}+${NC} $tool"
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
      echo "  Tool-specific:"
      if [[ ${#TOOL_RULES[@]} -eq 0 ]]; then
        echo "    (none)"
      else
        printf '%s\n' "${TOOL_RULES[@]}" | sort -u | while read -r rule; do
          echo "    - $rule"
        done
      fi
      echo ""
      echo -e "${BLUE}Skills to copy:${NC}"
      echo "  Always:"
      for skill in "${ALWAYS_SKILLS[@]}"; do
        echo "    - $skill"
      done
      echo "  Tool-specific:"
      if [[ ${#TOOL_SKILLS[@]} -eq 0 ]]; then
        echo "    (none)"
      else
        printf '%s\n' "${TOOL_SKILLS[@]}" | sort -u | while read -r skill; do
          echo "    - $skill"
        done
      fi
      echo ""
      echo -e "${BLUE}Commands to copy:${NC}"
      if [[ ${#TOOL_COMMANDS[@]} -eq 0 ]]; then
        echo "  (none)"
      else
        printf '%s\n' "${TOOL_COMMANDS[@]}" | sort -u | while read -r cmd; do
          echo "  - $cmd"
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
