#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
usage: guardrail-check.sh <change-id> [options]

Options:
  --project-root <dir>   Project root directory (default: current dir)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory for architecture constraints
  --role <role>          Role to check permissions for (coder|test-owner|reviewer)
  --check-lockfile       Check if lockfile changes require explicit declaration
  --check-engineering    Check if engineering system changes require approval
  --check-layers         Check layering constraints (dependency guard)
  --check-cycles         Check for circular dependencies
  --check-hotspots       Warn if changes touch high-risk hotspots
  -h, --help             Show this help message

Exit codes:
  0 - All checks passed
  1 - Guardrail violation detected
  2 - Invalid arguments
  3 - Missing required files
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_id="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-}"
role=""
check_lockfile=false
check_engineering=false
check_layers=false
check_cycles=false
check_hotspots=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --change-root)
      change_root="${2:-}"
      shift 2
      ;;
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --role)
      role="${2:-}"
      shift 2
      ;;
    --check-lockfile)
      check_lockfile=true
      shift
      ;;
    --check-engineering)
      check_engineering=true
      shift
      ;;
    --check-layers)
      check_layers=true
      shift
      ;;
    --check-cycles)
      check_cycles=true
      shift
      ;;
    --check-hotspots)
      check_hotspots=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$project_root" || -z "$change_root" ]]; then
  usage
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  # ripgrep is preferred but not always installed in minimal environments.
  # We keep guardrail-check usable by falling back to grep/egrep.
  if ! command -v grep >/dev/null 2>&1; then
    echo "error: missing dependency: rg (ripgrep) or grep" >&2
    exit 2
  fi
fi

if [[ "$change_root" = /* ]]; then
  file="${change_root}/${change_id}/verification.md"
else
  file="${project_root}/${change_root}/${change_id}/verification.md"
fi


if [[ ! -f "$file" ]]; then
  echo "error: missing ${file}" >&2
  exit 2
fi

# Check if guardrail section exists - if not, skip (guardrail review not applicable)
if command -v rg >/dev/null 2>&1; then
  has_guardrail_section=$(rg -n "^F\\) Structural Quality Gate Record|^## F\\) Structural Quality Gate" "$file" >/dev/null 2>&1 && echo yes || echo no)
else
  has_guardrail_section=$(grep -nE "^F\) Structural Quality Gate Record|^## F\) Structural Quality Gate" "$file" >/dev/null 2>&1 && echo yes || echo no)
fi

if [[ "$has_guardrail_section" != "yes" ]]; then
  echo "ok: guardrail section not present (not applicable for ${change_id})"
  exit 0
fi

if command -v rg >/dev/null 2>&1; then
  decision_line=$(rg -n "^- Decision and Authorization:" "$file" || true)
else
  decision_line=$(grep -nE "^- Decision and Authorization:" "$file" || true)
fi
if [[ -z "$decision_line" ]]; then
  echo "error: guardrail section exists but missing '- Decision and Authorization:' line in ${file}" >&2
  exit 1
fi

value="$(echo "$decision_line" | sed -E 's/^[0-9]+:- Decision and Authorization: *//')"

if [[ -z "$value" || "$value" == "<"* || "$value" == "TBD"* ]]; then
  echo "error: unresolved guardrail decision in ${file}" >&2
  exit 1
fi

echo "ok: guardrail decision present for ${change_id}"

# =============================================================================
# Role Permission Checks (inspired by VS Code role permission separation)
# =============================================================================

# Define file patterns forbidden for each role.
# Use a plain function instead of associative arrays for bash 3.2 compatibility (macOS default).
role_forbidden_patterns() {
  local role_name="$1"
  case "$role_name" in
    coder)
      echo "tests/|test/|\\.test\\.|\\.spec\\.|__tests__|verification\\.md"
      ;;
    test-owner)
      echo ""  # test-owner can modify test files
      ;;
    reviewer)
      echo ".*"  # reviewer should not modify any files
      ;;
    *)
      echo ""
      ;;
  esac
}

# Define sensitive files forbidden for all roles (similar to VS Code engineering system protection)
SENSITIVE_PATTERNS="\.devbooks/|\.github/workflows/|build/|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock"

check_role_permissions() {
  local role="$1"
  local change_path="$2"

  if [[ -z "$role" ]]; then
    return 0
  fi

  echo "info: checking role permissions for '${role}'..."

  # Get list of changed files (from git diff or change package record)
  local changed_files=""
  if [[ -d "${project_root}/.git" ]]; then
    changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null || true)
  fi

  # If no git, try reading from proposal.md Impact section
  if [[ -z "$changed_files" && -f "${change_path}/proposal.md" ]]; then
    changed_files=$(grep -A 100 "^## Impact" "${change_path}/proposal.md" | grep -E "^\s*-\s+\`" | sed 's/.*`\([^`]*\)`.*/\1/' || true)
  fi

  if [[ -z "$changed_files" ]]; then
    echo "warn: cannot determine changed files, skipping role permission check"
    return 0
  fi

  local forbidden
  forbidden="$(role_forbidden_patterns "$role")"
  local violations=""

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Check role-specific forbidden patterns
    if [[ -n "$forbidden" ]] && echo "$file" | grep -qE "$forbidden"; then
      violations="${violations}\n  - ${file} (forbidden for role '${role}')"
    fi

    # Check sensitive files (forbidden for all roles unless explicitly declared)
    if echo "$file" | grep -qE "$SENSITIVE_PATTERNS"; then
      # Check if proposal.md has engineering-system-change tag
      if ! grep -q "engineering-system-change" "${change_path}/proposal.md" 2>/dev/null; then
        violations="${violations}\n  - ${file} (sensitive file requires 'engineering-system-change' tag in proposal.md)"
      fi
    fi
  done <<< "$changed_files"

  if [[ -n "$violations" ]]; then
    echo -e "error: role permission violations detected:${violations}" >&2
    return 1
  fi

  echo "ok: role permissions check passed for '${role}'"
  return 0
}

# =============================================================================
# Lockfile Idempotency Check (inspired by VS Code no-package-lock-changes.yml)
# =============================================================================

check_lockfile_changes() {
  local change_path="$1"

  echo "info: checking lockfile changes..."

  local lockfiles="package-lock.json yarn.lock pnpm-lock.yaml Cargo.lock Gemfile.lock poetry.lock"
  local changed_lockfiles=""

  if [[ -d "${project_root}/.git" ]]; then
    for lockfile in $lockfiles; do
      if cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null | grep -q "^${lockfile}$"; then
        changed_lockfiles="${changed_lockfiles} ${lockfile}"
      fi
    done
  fi

  if [[ -n "$changed_lockfiles" ]]; then
    # Check if proposal.md explicitly declares dependency changes
    if ! grep -qE "(dependency|deps|upgrade|update.*package)" "${change_path}/proposal.md" 2>/dev/null; then
      echo "error: lockfile changes detected (${changed_lockfiles}) but proposal.md does not declare dependency changes" >&2
      echo "hint: add dependency change description to proposal.md or use '--check-lockfile=false'" >&2
      return 1
    fi
  fi

  echo "ok: lockfile check passed"
  return 0
}

# =============================================================================
# Engineering System Change Check
# =============================================================================

check_engineering_changes() {
  local change_path="$1"

  echo "info: checking engineering system changes..."

  local eng_patterns="\.devbooks/|\.github/|build/|scripts/|Makefile|gulpfile|webpack\.config|vite\.config|tsconfig|eslint\.config|\.eslintrc"
  local eng_changes=""

  if [[ -d "${project_root}/.git" ]]; then
    eng_changes=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null | grep -E "$eng_patterns" || true)
  fi

  if [[ -n "$eng_changes" ]]; then
    # Check if proposal.md has engineering-system-change tag
    if ! grep -q "engineering-system-change" "${change_path}/proposal.md" 2>/dev/null; then
      echo "error: engineering system changes detected but proposal.md missing 'engineering-system-change' tag:" >&2
      echo "$eng_changes" | sed 's/^/  - /' >&2
      return 1
    fi
  fi

  echo "ok: engineering system check passed"
  return 0
}

# =============================================================================
# Layering Constraints Check (Dependency Guard)
# Prevent dependency direction violations (upper layer cannot directly depend on lower layer implementation details)
# =============================================================================

check_layering_constraints() {
  local change_path="$1"
  local constraints_file="${truth_root}/architecture/c4.md"

  echo "info: checking layering constraints (dependency guard)..."

  # Skip if no truth_root or constraints file doesn't exist
  if [[ -z "$truth_root" ]]; then
    echo "warn: --truth-root not specified, skipping layering check"
    return 0
  fi

  if [[ ! -f "$constraints_file" ]]; then
    echo "warn: no layering constraints file found at ${constraints_file}, skipping"
    return 0
  fi

  if ! command -v rg >/dev/null 2>&1; then
    echo "error: missing dependency: rg (ripgrep) required for layering checks" >&2
    return 2
  fi

  # Get changed files
  local changed_files=""
  if [[ -d "${project_root}/.git" ]]; then
    changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null || true)
  fi

  if [[ -z "$changed_files" ]]; then
    echo "warn: cannot determine changed files, skipping layering check"
    return 0
  fi

  local violations=""

  # Parse layering rules from constraints file
  # Format: | base | src/base/ | ... | (none) | platform, domain, ... |

  # Common layering violation checks
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! "$file" =~ \.(ts|tsx|js|jsx|py|go|java|rs)$ ]] && continue

    local file_path="${project_root}/${file}"
    [[ ! -f "$file_path" ]] && continue

    # Check if base layer imports platform/domain/application/ui
    if [[ "$file" =~ ^src/base/ ]] || [[ "$file" =~ /base/ ]]; then
      if rg -q "from ['\"].*(platform|domain|application|app|ui)/" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: base layer imports upper layer"
      fi
    fi

    # Check if common layer imports browser/node specific code
    if [[ "$file" =~ /common/ ]]; then
      if rg -q "from ['\"].*(browser|node)/" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: common layer imports platform-specific code"
      fi
      # Check if using DOM API
      if rg -q "(document\.|window\.|navigator\.)" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: common layer uses DOM API"
      fi
    fi

    # Check if core imports contrib
    if [[ "$file" =~ /core/ ]] || [[ "$file" =~ /services/ ]]; then
      if rg -q "from ['\"].*contrib/" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: core imports contrib (violates extension point design)"
      fi
    fi

  done <<< "$changed_files"

  if [[ -n "$violations" ]]; then
    echo -e "error: layering constraint violations detected:${violations}" >&2
    echo "hint: see ${constraints_file} for allowed dependencies" >&2
    return 1
  fi

  echo "ok: layering constraints check passed"
  return 0
}

# =============================================================================
# Circular Dependency Check
# =============================================================================

check_circular_dependencies() {
  echo "info: checking for circular dependencies..."

  # Check if madge tool is available
  if command -v madge >/dev/null 2>&1; then
    local circular=""
    circular=$(cd "$project_root" && madge --circular --warning src/ 2>/dev/null | grep -E "^\s+[a-zA-Z]" || true)

    if [[ -n "$circular" ]]; then
      echo "error: circular dependencies detected:" >&2
      echo "$circular" | sed 's/^/  /' >&2
      return 1
    fi
  else
    # Fallback: use simple grep to detect common circular patterns
    echo "info: madge not available, using basic circular detection"

    if ! command -v rg >/dev/null 2>&1; then
      echo "error: missing dependency: rg (ripgrep) required for fallback circular checks" >&2
      return 2
    fi

    # Check if files both import each other (simple heuristic)
    if [[ -d "${project_root}/.git" ]]; then
      local changed_files
      changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null | grep -E '\.(ts|js|tsx|jsx)$' || true)

      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local file_path="${project_root}/${file}"
        [[ ! -f "$file_path" ]] && continue

        # Get file's imports
        local imports
        imports=$(rg "^import .* from ['\"]\./" "$file_path" 2>/dev/null | sed "s/.*from ['\"]\\([^'\"]*\\)['\"].*/\\1/" || true)

        # Check if imported files import current file back
        local file_base
        file_base=$(basename "$file" | sed 's/\.[^.]*$//')

        while IFS= read -r imported; do
          [[ -z "$imported" ]] && continue
          local imported_path="${project_root}/$(dirname "$file")/${imported}"
          [[ "$imported_path" =~ \.ts$ ]] || imported_path="${imported_path}.ts"

          if [[ -f "$imported_path" ]] && rg -q "from ['\"].*${file_base}['\"]" "$imported_path" 2>/dev/null; then
            echo "warn: potential circular dependency: ${file} <-> ${imported}" >&2
          fi
        done <<< "$imports"
      done <<< "$changed_files"
    fi
  fi

  echo "ok: circular dependency check passed"
  return 0
}

# =============================================================================
# Hotspot Warning Check
# Hotspot = High change frequency x High complexity
# =============================================================================

check_hotspot_changes() {
  local change_path="$1"
  local hotspots_file="${truth_root}/architecture/hotspots.md"

  echo "info: checking if changes touch hotspots..."

  # If hotspots file exists, read hotspot list from it
  local hotspot_files=""
  if [[ -n "$truth_root" && -f "$hotspots_file" ]]; then
    hotspot_files=$(grep -E "^\| " "$hotspots_file" | grep -v "File\|---" | awk -F'|' '{print $2}' | tr -d ' ' || true)
  fi

  # If no hotspots file, try computing from git history
  if [[ -z "$hotspot_files" && -d "${project_root}/.git" ]]; then
    echo "info: no hotspots.md found, computing from git history (top 10 churn files)..."
    hotspot_files=$(cd "$project_root" && git log --oneline --name-only --since="30 days ago" 2>/dev/null | \
      grep -E '\.(ts|tsx|js|jsx|py|go|java|rs)$' | \
      sort | uniq -c | sort -rn | head -10 | awk '{print $2}' || true)
  fi

  if [[ -z "$hotspot_files" ]]; then
    echo "info: no hotspot data available, skipping"
    return 0
  fi

  # Get changed files
  local changed_files=""
  if [[ -d "${project_root}/.git" ]]; then
    changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null || true)
  fi

  # Check if changed files touch hotspots
  local hotspot_hits=""
  while IFS= read -r changed; do
    [[ -z "$changed" ]] && continue
    if echo "$hotspot_files" | grep -qF "$changed"; then
      hotspot_hits="${hotspot_hits}\n  - ${changed}"
    fi
  done <<< "$changed_files"

  if [[ -n "$hotspot_hits" ]]; then
    echo -e "warn: changes touch high-risk hotspots (high churn x complexity):${hotspot_hits}" >&2
    echo "hint: consider extra review and testing for these files" >&2
    # This is a warning, not an error, does not block merge
  fi

  echo "ok: hotspot check completed"
  return 0
}

# =============================================================================
# Run Additional Checks
# =============================================================================

exit_code=0

update_exit_code() {
  local rc="$1"

  if [[ $rc -eq 0 ]]; then
    return 0
  fi

  # Preserve usage/tooling errors for callers that rely on exit code semantics.
  if [[ $rc -eq 2 ]]; then
    exit_code=2
    return 0
  fi

  # If we have already hit a tooling error, keep 2 as the final status.
  if [[ $exit_code -ne 2 ]]; then
    exit_code=1
  fi

  return 0
}

# Role permission check
if [[ -n "$role" ]]; then
  change_path=$(dirname "$file")
  if check_role_permissions "$role" "$change_path"; then
    :
  else
    update_exit_code $?
  fi
fi

# Lockfile check
if [[ "$check_lockfile" == "true" ]]; then
  change_path=$(dirname "$file")
  if check_lockfile_changes "$change_path"; then
    :
  else
    update_exit_code $?
  fi
fi

# Engineering system change check
if [[ "$check_engineering" == "true" ]]; then
  change_path=$(dirname "$file")
  if check_engineering_changes "$change_path"; then
    :
  else
    update_exit_code $?
  fi
fi

# Layering constraint check (Dependency Guard)
if [[ "$check_layers" == "true" ]]; then
  change_path=$(dirname "$file")
  if check_layering_constraints "$change_path"; then
    :
  else
    update_exit_code $?
  fi
fi

# Circular dependency check
if [[ "$check_cycles" == "true" ]]; then
  if check_circular_dependencies; then
    :
  else
    update_exit_code $?
  fi
fi

# Hotspot warning check (warning only, does not affect exit code)
if [[ "$check_hotspots" == "true" ]]; then
  change_path=$(dirname "$file")
  check_hotspot_changes "$change_path"
  # Hotspots are just warnings, do not affect exit_code
fi

exit $exit_code
