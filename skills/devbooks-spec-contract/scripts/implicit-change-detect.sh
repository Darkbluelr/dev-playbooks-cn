#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# implicit-change-detect.sh
# ============================================================================
# Detects implicit changes not declared in design.md.
#
# Implicit change = changes that affect system behavior but are not explicitly
#                   declared in the proposal/design documents.
#
# Detection categories:
# - Dependency changes (package.json, requirements.txt, go.mod, etc.)
# - Configuration changes (*.env*, *.config.*, *.json, *.yaml)
# - Build changes (Makefile, tsconfig.json, webpack.config.*, Dockerfile, etc.)
#
# Reference: "The Mythical Man-Month" Chapter 7 "Why Did the Tower of Babel Fail?" - Implicit changes are dangerous
# ============================================================================

usage() {
  cat <<'EOF' >&2
usage: implicit-change-detect.sh <change-id> [--base <commit>] [--project-root <dir>] [--change-root <dir>]

Detects implicit changes not declared in design.md.

Detection categories:
- Dependency changes (package.json, requirements.txt, go.mod, etc.)
- Configuration changes (*.env*, *.config.*, *.json, *.yaml)
- Build changes (Makefile, tsconfig.json, webpack.config.*, Dockerfile, etc.)

Options:
  --base          Base commit to compare against (default: HEAD~1)
  --project-root  Project root directory (default: pwd)
  --change-root   Change package root (default: changes)

Output:
  JSON report to <change-root>/<change-id>/evidence/implicit-changes.json

Examples:
  implicit-change-detect.sh feat-001
  implicit-change-detect.sh feat-001 --base origin/main
  implicit-change-detect.sh feat-001 --project-root /path/to/repo
EOF
}

# Color output helpers
red() { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[0;32m%s\033[0m\n' "$*" >&2; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*" >&2; }

err() { red "error: $*"; }
warn() { yellow "warn: $*"; }
ok() { green "ok: $*"; }

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
base_commit="HEAD~1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --base)
      base_commit="${2:-}"
      shift 2
      ;;
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --change-root)
      change_root="${2:-}"
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" ]]; then
  err "change-id is required"
  exit 2
fi

# Normalize paths
project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

output_file="${change_dir}/evidence/implicit-changes.json"
design_file="${change_dir}/design.md"

mkdir -p "$(dirname "$output_file")"

# Check if we're in a git repo
if ! git -C "$project_root" rev-parse --git-dir >/dev/null 2>&1; then
  err "not a git repository: ${project_root}"
  exit 1
fi

# Validate base commit
if ! git -C "$project_root" rev-parse --verify "$base_commit" >/dev/null 2>&1; then
  warn "base commit not found: ${base_commit}, using HEAD"
  base_commit="HEAD"
fi

echo "=== Implicit Change Detection: ${change_id} ==="
echo "base: ${base_commit}"
echo ""

# ============================================================================
# Detection functions
# ============================================================================

# Detect dependency changes
detect_dependency_changes() {
  local changes='[]'

  # npm/yarn: package.json
  if [[ -f "$project_root/package.json" ]]; then
    local old_deps new_deps
    old_deps=$(git -C "$project_root" show "${base_commit}:package.json" 2>/dev/null | jq -r '.dependencies // {} | to_entries | .[] | "\(.key)@\(.value)"' 2>/dev/null | sort || echo "")
    new_deps=$(jq -r '.dependencies // {} | to_entries | .[] | "\(.key)@\(.value)"' "$project_root/package.json" 2>/dev/null | sort || echo "")

    # Find added/removed/changed
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      pkg=$(echo "$line" | cut -d'@' -f1)
      if ! echo "$old_deps" | grep -q "^${pkg}@"; then
        changes=$(echo "$changes" | jq --arg pkg "$pkg" --arg ver "$(echo "$line" | cut -d'@' -f2-)" \
          '. + [{name: $pkg, type: "npm", change: "added", new_version: $ver}]')
      fi
    done <<< "$new_deps"

    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      pkg=$(echo "$line" | cut -d'@' -f1)
      old_ver=$(echo "$line" | cut -d'@' -f2-)
      new_line=$(echo "$new_deps" | grep "^${pkg}@" || true)
      if [[ -z "$new_line" ]]; then
        changes=$(echo "$changes" | jq --arg pkg "$pkg" --arg ver "$old_ver" \
          '. + [{name: $pkg, type: "npm", change: "removed", old_version: $ver}]')
      else
        new_ver=$(echo "$new_line" | cut -d'@' -f2-)
        if [[ "$old_ver" != "$new_ver" ]]; then
          changes=$(echo "$changes" | jq --arg pkg "$pkg" --arg old "$old_ver" --arg new "$new_ver" \
            '. + [{name: $pkg, type: "npm", change: "version_change", old_version: $old, new_version: $new}]')
        fi
      fi
    done <<< "$old_deps"
  fi

  # pip: requirements.txt
  if [[ -f "$project_root/requirements.txt" ]]; then
    local old_reqs new_reqs
    old_reqs=$(git -C "$project_root" show "${base_commit}:requirements.txt" 2>/dev/null | grep -v '^#' | grep -v '^$' | sort || echo "")
    new_reqs=$(grep -v '^#' "$project_root/requirements.txt" 2>/dev/null | grep -v '^$' | sort || echo "")

    # Simple diff detection
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      pkg=$(echo "$line" | sed 's/[=<>!].*//')
      if ! echo "$old_reqs" | grep -q "^${pkg}"; then
        changes=$(echo "$changes" | jq --arg pkg "$pkg" --arg spec "$line" \
          '. + [{name: $pkg, type: "pip", change: "added", spec: $spec}]')
      fi
    done <<< "$new_reqs"
  fi

  # go.mod
  if [[ -f "$project_root/go.mod" ]]; then
    local go_diff
    go_diff=$(git -C "$project_root" diff "${base_commit}" -- "go.mod" 2>/dev/null || true)
    if [[ -n "$go_diff" ]]; then
      changes=$(echo "$changes" | jq '. + [{name: "go.mod", type: "go", change: "modified"}]')
    fi
  fi

  echo "$changes"
}

# Detect configuration changes
detect_config_changes() {
  local changes='[]'
  local config_patterns=(
    "*.env"
    "*.env.*"
    ".env"
    ".env.*"
    "*.config.js"
    "*.config.ts"
    "*.config.json"
    "config/*.json"
    "config/*.yaml"
    "config/*.yml"
    "*.yaml"
    "*.yml"
  )

  for pattern in "${config_patterns[@]}"; do
    local diff_output
    diff_output=$(git -C "$project_root" diff "${base_commit}" --name-only -- "$pattern" 2>/dev/null || true)

    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      # Check if it's a real config file (not node_modules, etc.)
      if [[ "$file" != *"node_modules"* && "$file" != *"vendor"* ]]; then
        changes=$(echo "$changes" | jq --arg f "$file" '. + [{file: $f, type: "config"}]')
      fi
    done <<< "$diff_output"
  done

  echo "$changes"
}

# Detect build changes
detect_build_changes() {
  local changes='[]'
  local build_patterns=(
    "Makefile"
    "*.gradle"
    "build.gradle"
    "pom.xml"
    "tsconfig.json"
    "tsconfig.*.json"
    "webpack.config.*"
    "vite.config.*"
    "rollup.config.*"
    "Dockerfile"
    "Dockerfile.*"
    "docker-compose.yml"
    "docker-compose.*.yml"
    ".github/workflows/*.yml"
    ".gitlab-ci.yml"
    "Jenkinsfile"
  )

  for pattern in "${build_patterns[@]}"; do
    local diff_output
    diff_output=$(git -C "$project_root" diff "${base_commit}" --name-only -- "$pattern" 2>/dev/null || true)

    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      changes=$(echo "$changes" | jq --arg f "$file" '. + [{file: $f, type: "build"}]')
    done <<< "$diff_output"
  done

  echo "$changes"
}

# Check if change is declared in design.md
check_declared() {
  local item="$1"
  local type="$2"

  if [[ ! -f "$design_file" ]]; then
    echo "unknown"
    return
  fi

  # Search for the item in design.md (case-insensitive)
  if grep -qi "$item" "$design_file" 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# ============================================================================
# Main execution
# ============================================================================

echo "detecting: dependency changes..."
dependency_changes=$(detect_dependency_changes)
dep_count=$(echo "$dependency_changes" | jq 'length')
echo "  found: ${dep_count}"

echo "detecting: configuration changes..."
config_changes=$(detect_config_changes)
cfg_count=$(echo "$config_changes" | jq 'length')
echo "  found: ${cfg_count}"

echo "detecting: build changes..."
build_changes=$(detect_build_changes)
bld_count=$(echo "$build_changes" | jq 'length')
echo "  found: ${bld_count}"

total=$((dep_count + cfg_count + bld_count))

# Check declaration status
if [[ -f "$design_file" ]]; then
  echo ""
  echo "checking: declaration status in design.md..."

  # Add declared field to each change
  dependency_changes=$(echo "$dependency_changes" | jq --arg df "$design_file" '
    map(. + {declared: (
      if .name then
        ($df | @sh | "grep -qi " + (.name | @sh) + " " + . + " 2>/dev/null && echo true || echo false" | @sh) == "true"
      else
        false
      end
    )})
  ')
fi

# Generate report
jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg base "$base_commit" \
  --arg change_id "$change_id" \
  --arg design_exists "$(test -f "$design_file" && echo 'true' || echo 'false')" \
  --argjson deps "$dependency_changes" \
  --argjson configs "$config_changes" \
  --argjson builds "$build_changes" \
  '{
    timestamp: $ts,
    base_commit: $base,
    change_id: $change_id,
    design_md_exists: ($design_exists == "true"),
    dependency_changes: $deps,
    config_changes: $configs,
    build_changes: $builds,
    summary: {
      total: (($deps | length) + ($configs | length) + ($builds | length)),
      dependency: ($deps | length),
      config: ($configs | length),
      build: ($builds | length)
    }
  }' > "$output_file"

echo ""
echo "=== Detection Summary ==="
echo "  dependencies: ${dep_count}"
echo "  config:       ${cfg_count}"
echo "  build:        ${bld_count}"
echo "  total:        ${total}"
echo ""
ok "report: ${output_file}"

# Output warning if implicit changes detected
if [[ $total -gt 0 ]]; then
  echo ""
  warn "implicit changes detected!"
  echo ""
  echo "Recommended actions:"
  echo "  1. Review ${output_file}"
  echo "  2. Declare significant changes in design.md"
  echo "  3. Add contract tests for dependency/config changes"
  echo "  4. Run 'change-check.sh ${change_id} --mode apply' to validate"

  if [[ ! -f "$design_file" ]]; then
    echo ""
    warn "design.md not found - cannot check declaration status"
  fi
fi
