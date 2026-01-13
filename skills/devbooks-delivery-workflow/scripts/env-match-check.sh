#!/usr/bin/env bash
# env-match-check.sh - Verify test environment declaration exists in verification.md
#
# This script checks that verification.md contains a test environment declaration
# section, which is required for archive mode to ensure reproducibility.
#
# Reference: harden-devbooks-quality-gates design.md AC-006

set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: env-match-check.sh <change-id> [options]

Verify test environment declaration exists in verification.md:
1. Checks verification.md exists
2. Verifies "Test Environment Declaration" or "Test Environment" section exists
3. Returns exit code based on verification status

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change packages root (default: changes)
  -h, --help            Show this help message

Exit Codes:
  0 - Environment declaration found
  1 - Check failed (missing section)
  2 - Usage error

Examples:
  env-match-check.sh my-change-001
  env-match-check.sh my-change-001 --change-root dev-playbooks/changes
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
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Validate change-id
if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

# Build paths
project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

verification_file="${change_dir}/verification.md"

echo "env-match-check: checking '${change_id}'"
echo "  change-dir: ${change_dir}"

# Check change directory exists
if [[ ! -d "$change_dir" ]]; then
  echo "error: missing change directory: ${change_dir}" >&2
  exit 1
fi

# Check verification.md exists
if [[ ! -f "$verification_file" ]]; then
  echo "error: missing verification.md: ${verification_file}" >&2
  exit 1
fi

# Check for environment declaration section
# Accept both Chinese and English section names
env_section_pattern="Test Environment Declaration|Test Environment|Environment Declaration|Runtime Environment|测试环境声明|测试环境|环境声明|运行环境"

if grep -qE "^#+ *(${env_section_pattern})" "$verification_file" 2>/dev/null; then
  echo "ok: environment declaration section found"
  exit 0
fi

# Also check for environment content without explicit heading
# Pattern: lines starting with "- Runtime:" or "- Environment:" etc.
env_content_pattern="^- *((Runtime|Environment|Database|External)[:：]|(运行环境|环境|数据库|外部依赖)[:：])"

if grep -qE "${env_content_pattern}" "$verification_file" 2>/dev/null; then
  echo "ok: environment declaration content found"
  exit 0
fi

# No environment declaration found
echo "error: verification.md missing test environment declaration section" >&2
echo "hint: add a '## Test Environment Declaration' / '## 测试环境声明' section with runtime, database, and external dependency info" >&2
exit 1
