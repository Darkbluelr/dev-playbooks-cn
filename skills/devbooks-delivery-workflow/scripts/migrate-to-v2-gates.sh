#!/usr/bin/env bash
# migrate-to-v2-gates.sh - Help existing change packages comply with v2 quality gates
#
# This script creates missing evidence directories and adds required sections
# to verification.md to help existing change packages pass the new quality gates.
#
# Reference: harden-devbooks-quality-gates design.md AC-001, AC-002, AC-006

set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: migrate-to-v2-gates.sh <change-id> [options]

Migrate a change package to comply with v2 quality gates:
1. Creates evidence/red-baseline/ and evidence/green-final/ directories if missing
2. Adds "测试环境声明" section to verification.md if missing
3. Reports migration status

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change packages root (default: changes)
  --dry-run             Show what would be done without making changes
  -h, --help            Show this help message

Examples:
  migrate-to-v2-gates.sh my-change-001
  migrate-to-v2-gates.sh my-change-001 --dry-run
  migrate-to-v2-gates.sh my-change-001 --change-root dev-playbooks/changes
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
dry_run=false

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
    --dry-run)
      dry_run=true
      shift
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
evidence_dir="${change_dir}/evidence"
red_baseline="${evidence_dir}/red-baseline"
green_final="${evidence_dir}/green-final"

# Check change directory exists
if [[ ! -d "$change_dir" ]]; then
  echo "error: change directory not found: ${change_dir}" >&2
  exit 1
fi

echo "migrate-to-v2-gates: migrating '${change_id}'"
echo "  change-dir: ${change_dir}"
echo "  dry-run: ${dry_run}"
echo ""

changes_made=0
issues_found=0

# 1. Create evidence directories
echo "=== Checking evidence directories ==="

if [[ ! -d "$red_baseline" ]]; then
  echo "  [MISSING] evidence/red-baseline/"
  if [[ "$dry_run" == false ]]; then
    mkdir -p "$red_baseline"
    echo "README.md" > "${red_baseline}/.gitkeep"
    echo "  [CREATED] evidence/red-baseline/"
    changes_made=$((changes_made + 1))
  else
    echo "  [DRY-RUN] Would create evidence/red-baseline/"
  fi
else
  echo "  [OK] evidence/red-baseline/"
fi

if [[ ! -d "$green_final" ]]; then
  echo "  [MISSING] evidence/green-final/"
  if [[ "$dry_run" == false ]]; then
    mkdir -p "$green_final"
    echo "# Green Final Evidence" > "${green_final}/.gitkeep"
    echo "  [CREATED] evidence/green-final/"
    changes_made=$((changes_made + 1))
  else
    echo "  [DRY-RUN] Would create evidence/green-final/"
  fi
else
  echo "  [OK] evidence/green-final/"
fi

# 2. Check verification.md for test environment declaration
echo ""
echo "=== Checking verification.md ==="

if [[ ! -f "$verification_file" ]]; then
  echo "  [MISSING] verification.md - cannot add sections"
  issues_found=$((issues_found + 1))
else
  # Check for test environment declaration section
  if ! grep -q "测试环境声明" "$verification_file" 2>/dev/null; then
    echo "  [MISSING] 测试环境声明 section"
    if [[ "$dry_run" == false ]]; then
      # Add section before last heading or at end
      cat >> "$verification_file" << 'EOF'

## 测试环境声明

> 由 migrate-to-v2-gates.sh 自动添加，请填写实际环境信息

- 运行环境：<macOS / Linux / Windows / CI>
- 数据库：<N/A / MySQL / PostgreSQL / ...>
- 外部依赖：<无 / 具体服务名>
- 特殊配置：<无 / 具体配置>
EOF
      echo "  [ADDED] 测试环境声明 section to verification.md"
      changes_made=$((changes_made + 1))
    else
      echo "  [DRY-RUN] Would add 测试环境声明 section"
    fi
  else
    echo "  [OK] 测试环境声明 section exists"
  fi
fi

# 3. Summary
echo ""
echo "=== Migration Summary ==="
if [[ "$dry_run" == true ]]; then
  echo "  Mode: dry-run (no changes made)"
else
  echo "  Changes made: ${changes_made}"
fi
echo "  Issues found: ${issues_found}"

if [[ $issues_found -gt 0 ]]; then
  echo ""
  echo "warn: some issues require manual attention"
  exit 1
fi

if [[ $changes_made -gt 0 || "$dry_run" == true ]]; then
  echo ""
  echo "Next steps:"
  echo "  1. Add actual Red baseline evidence to evidence/red-baseline/"
  echo "  2. After tests pass, add Green evidence to evidence/green-final/"
  echo "  3. Update 测试环境声明 section in verification.md with actual environment"
  echo "  4. Run 'change-check.sh ${change_id} --mode archive' to verify compliance"
fi

echo ""
echo "ok: migration complete"
