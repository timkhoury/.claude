#!/usr/bin/env bash
# Audit project settings.local.json for permissions that could be global
# Usage: audit-permissions.sh [--report|--json]
#
# Identifies permissions in .claude/settings.local.json that appear generic
# enough to move to ~/.claude/settings.json

set -e

GLOBAL_SETTINGS="$HOME/.claude/settings.json"
LOCAL_SETTINGS=".claude/settings.local.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
MODE="report"
case "${1:-}" in
  --json)   MODE="json" ;;
  --report) MODE="report" ;;
  --help|-h)
    echo "Usage: audit-permissions.sh [--report|--json]"
    echo "  --report  Human-readable report (default)"
    echo "  --json    Output as JSON for programmatic use"
    echo ""
    echo "Identifies permissions in .claude/settings.local.json that could"
    echo "be moved to global ~/.claude/settings.json"
    exit 0
    ;;
esac

# Check prerequisites
if [[ ! -f "$GLOBAL_SETTINGS" ]]; then
  echo -e "${RED}Error: Global settings not found at $GLOBAL_SETTINGS${NC}" >&2
  exit 1
fi

if [[ ! -f "$LOCAL_SETTINGS" ]]; then
  if [[ "$MODE" == "json" ]]; then
    echo '{"error": "No .claude/settings.local.json in current project", "candidates": [], "project_specific": []}'
  else
    echo -e "${YELLOW}No .claude/settings.local.json in current project.${NC}"
  fi
  exit 0
fi

# Patterns that indicate generic/global permissions
# These are tools/patterns useful across many projects
GENERIC_PATTERNS=(
  # Package managers (any project)
  "^Bash\(npm "
  "^Bash\(npx eslint"
  "^Bash\(npx prettier"
  "^Bash\(npx tsc"
  "^Bash\(npx tsx"
  "^Bash\(npx playwright"
  "^Bash\(yarn "
  "^Bash\(pnpm "
  "^Bash\(bun "
  # Docker (general dev tool)
  "^Bash\(docker "
  # System utilities
  "^Bash\(lsof"
  "^Bash\(printenv"
  "^Bash\(xargs"
  "^Bash\(/dev/null"
  # Home directory scripts (personal tools)
  "^Bash\(~/\."
  "^Bash\(\\\$HOME/\."
  # General MCP tools (not project-specific servers)
  "^mcp__Bright_Data__"
  "^mcp__chrome-devtools__"
  "^mcp__obsidian"
  "^mcp__ide__"
  "^mcp__Ref__"
  # Personal file access
  "^Read\(/Users/"
  "^Read\(\\\$HOME/"
  # Generic web domains (documentation sites)
  "^WebFetch\(domain:developers\."
  "^WebFetch\(domain:docs\."
  "^WebFetch\(domain:.*\.dev\)"
  "^WebFetch\(domain:headlessui"
  "^WebFetch\(domain:tailwindcss"
  "^WebFetch\(domain:reactjs"
  "^WebFetch\(domain:nextjs"
  "^WebFetch\(domain:www\.shadcn"
  # Generic skills (workflow tools)
  "^Skill\(frontend-design"
  "^Skill\(pr-check"
  "^Skill\(template-updater"
  "^Skill\(agent-browser"
  "^Skill\(beads:"
  "^Skill\(openspec:"
  "^Skill\(gitbutler"
  "^Skill\(adr-writer"
  "^Skill\(skill-writer"
  "^Skill\(agent-writer"
  "^Skill\(work"
  "^WebSearch$"
)

# Patterns that indicate project-specific permissions
# These should stay in settings.local.json
PROJECT_SPECIFIC_PATTERNS=(
  # Project-specific CLIs
  "^Bash\(npx supabase"
  "^Bash\(supabase "
  "^Bash\(npx prisma"
  "^Bash\(prisma "
  "^Bash\(npx drizzle"
  "^Bash\(npx shadcn"
  # Database connections (project-specific credentials)
  "^Bash\(psql"
  "^Bash\(PGPASSWORD"
  "^Bash\(mysql"
  "^Bash\(mongo"
  # Project MCP servers
  "^mcp__supabase__"
  "^mcp__stripe__"
  "^mcp__vercel__"
  # Project-local scripts
  "^Bash\(\.claude/"
  "^Bash\(\./scripts/"
  # Project-specific domains
  "^WebFetch\(domain:supabase\.com"
  "^WebFetch\(domain:stripe\.com"
  "^WebFetch\(domain:vercel\.com"
)

# Extract permissions from JSON
extract_permissions() {
  local file="$1"
  # Use jq if available, otherwise fall back to grep/sed
  if command -v jq &>/dev/null; then
    jq -r '.permissions.allow[]? // empty' "$file" 2>/dev/null || echo ""
  else
    grep -o '"[^"]*"' "$file" | tr -d '"' | grep -E "^(Bash|Read|Write|Edit|WebFetch|WebSearch|Skill|mcp__)" || echo ""
  fi
}

# Check if permission matches any pattern in array
matches_patterns() {
  local perm="$1"
  shift
  local patterns=("$@")

  for pattern in "${patterns[@]}"; do
    if echo "$perm" | grep -qE "$pattern"; then
      return 0
    fi
  done
  return 1
}

# Get permissions
local_perms=$(extract_permissions "$LOCAL_SETTINGS")
global_perms=$(extract_permissions "$GLOBAL_SETTINGS")

# Track results
candidates=()
project_specific=()
already_global=()
unknown=()

while IFS= read -r perm; do
  [[ -z "$perm" ]] && continue

  # Check if already in global settings
  if echo "$global_perms" | grep -qF "$perm"; then
    already_global+=("$perm")
    continue
  fi

  # Check if project-specific
  if matches_patterns "$perm" "${PROJECT_SPECIFIC_PATTERNS[@]}"; then
    project_specific+=("$perm")
    continue
  fi

  # Check if generic/global candidate
  if matches_patterns "$perm" "${GENERIC_PATTERNS[@]}"; then
    candidates+=("$perm")
    continue
  fi

  # Unknown - needs manual review
  unknown+=("$perm")
done <<< "$local_perms"

# Output results
if [[ "$MODE" == "json" ]]; then
  # JSON output
  echo "{"
  echo '  "candidates": ['
  first=true
  for c in "${candidates[@]}"; do
    [[ "$first" == "true" ]] || echo ","
    printf '    "%s"' "$c"
    first=false
  done
  echo ""
  echo "  ],"
  echo '  "project_specific": ['
  first=true
  for p in "${project_specific[@]}"; do
    [[ "$first" == "true" ]] || echo ","
    printf '    "%s"' "$p"
    first=false
  done
  echo ""
  echo "  ],"
  echo '  "already_global": ['
  first=true
  for a in "${already_global[@]}"; do
    [[ "$first" == "true" ]] || echo ","
    printf '    "%s"' "$a"
    first=false
  done
  echo ""
  echo "  ],"
  echo '  "needs_review": ['
  first=true
  for u in "${unknown[@]}"; do
    [[ "$first" == "true" ]] || echo ","
    printf '    "%s"' "$u"
    first=false
  done
  echo ""
  echo "  ]"
  echo "}"
else
  # Human-readable report
  echo -e "${BLUE}=== Permission Audit Report ===${NC}"
  echo ""

  if [[ ${#candidates[@]} -gt 0 ]]; then
    echo -e "${GREEN}Candidates for global settings:${NC}"
    echo -e "${CYAN}(These look generic enough to move to ~/.claude/settings.json)${NC}"
    for c in "${candidates[@]}"; do
      echo "  + $c"
    done
    echo ""
  fi

  if [[ ${#unknown[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Needs manual review:${NC}"
    echo -e "${CYAN}(Couldn't auto-classify - review if these are project-specific)${NC}"
    for u in "${unknown[@]}"; do
      echo "  ? $u"
    done
    echo ""
  fi

  if [[ ${#project_specific[@]} -gt 0 ]]; then
    echo -e "${BLUE}Project-specific (keep local):${NC}"
    for p in "${project_specific[@]}"; do
      echo "  - $p"
    done
    echo ""
  fi

  if [[ ${#already_global[@]} -gt 0 ]]; then
    echo -e "${GREEN}Already in global settings:${NC}"
    for a in "${already_global[@]}"; do
      echo "  ✓ $a"
    done
    echo ""
  fi

  echo -e "${BLUE}Summary:${NC}"
  echo "  Global candidates:  ${#candidates[@]}"
  echo "  Needs review:       ${#unknown[@]}"
  echo "  Project-specific:   ${#project_specific[@]}"
  echo "  Already global:     ${#already_global[@]}"
  echo ""

  if [[ ${#candidates[@]} -gt 0 || ${#unknown[@]} -gt 0 ]]; then
    echo -e "${YELLOW}To migrate permissions:${NC}"
    echo "  1. Review the candidates above"
    echo "  2. Add desired permissions to ~/.claude/settings.json"
    echo "  3. Remove them from .claude/settings.local.json"
  else
    echo -e "${GREEN}All permissions are properly categorized.${NC}"
  fi
fi
