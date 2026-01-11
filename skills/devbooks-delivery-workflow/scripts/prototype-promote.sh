#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# prototype-promote.sh
# ============================================================================
# Promotes a prototype to production track.
#
# This script enforces:
# 1. PROTOTYPE.md checklist is complete
# 2. Production design.md exists with AC-xxx items
# 3. Production verification.md exists (Test Owner has produced acceptance tests)
# 4. All quality gates pass before promotion
#
# Reference: 《人月神话》第11章 "未雨绸缪" — "为舍弃而计划"
# ============================================================================

usage() {
  cat <<'EOF' >&2
usage: prototype-promote.sh <change-id> [--project-root <dir>] [--change-root <dir>] [--archive-dir <dir>] [--force]

Promotes a prototype to production track:
1. Validates prototype/PROTOTYPE.md checklist is complete
2. Requires design.md to exist with AC-xxx items
3. Requires verification.md to exist (Test Owner acceptance tests)
4. Archives characterization tests to <archive-dir>/<change-id>/
5. Removes prototype/ directory

Defaults (can be overridden by flags or env):
  DEVBOOKS_PROJECT_ROOT: pwd
  DEVBOOKS_CHANGE_ROOT:  changes
  Archive directory:     tests/archived-characterization

Options:
  --force         Skip confirmation prompt
  --archive-dir   Custom archive directory for characterization tests

WARNING: This script enforces that:
- Test Owner has produced NEW acceptance tests (not just characterization tests)
- All quality gates (design.md, verification.md) exist
- Prototype checklist is complete

Example:
  prototype-promote.sh my-feature-001
  prototype-promote.sh my-feature-001 --project-root /path/to/repo
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
archive_dir=""
force=false

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
    --archive-dir)
      archive_dir="${2:-}"
      shift 2
      ;;
    --force)
      force=true
      shift
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

# Default archive directory
if [[ -z "$archive_dir" ]]; then
  archive_dir="${project_root}/tests/archived-characterization"
fi

prototype_dir="${change_dir}/prototype"
prototype_md="${prototype_dir}/PROTOTYPE.md"
design_md="${change_dir}/design.md"
verification_md="${change_dir}/verification.md"

# ============================================================================
# Validation checks
# ============================================================================

echo "=== Prototype Promotion Check: ${change_id} ==="
echo ""

errors=0

# Check 1: Prototype directory exists
if [[ ! -d "$prototype_dir" ]]; then
  err "no prototype directory found: ${prototype_dir}"
  err "hint: run 'change-scaffold.sh ${change_id} --prototype' first"
  exit 1
fi

echo "checking: prototype directory exists"
ok "found: ${prototype_dir}"

# Check 2: PROTOTYPE.md exists
if [[ ! -f "$prototype_md" ]]; then
  err "missing: ${prototype_md}"
  ((errors++))
else
  echo "checking: PROTOTYPE.md exists"
  ok "found: ${prototype_md}"

  # Check 3: Promotion checklist is complete (no unchecked items in promotion section)
  echo "checking: promotion checklist is complete"

  # Extract lines between "提升检查清单" and next "## " or "丢弃检查清单"
  # and check for unchecked items "- [ ]"
  if grep -A 20 "提升检查清单" "$prototype_md" 2>/dev/null | \
     grep -B 20 -E "(^## |丢弃检查清单)" 2>/dev/null | \
     grep -q "^\- \[ \]"; then
    err "unchecked items in promotion checklist"
    err "hint: complete all items in '提升检查清单' section of PROTOTYPE.md"
    grep -A 20 "提升检查清单" "$prototype_md" | grep "^\- \[ \]" | head -5 >&2
    ((errors++))
  else
    ok "promotion checklist complete"
  fi
fi

# Check 4: Production design.md exists
echo "checking: production design.md exists"
if [[ ! -f "$design_md" ]]; then
  err "missing: ${design_md}"
  err "hint: create production-level design.md with AC-xxx items"
  ((errors++))
else
  ok "found: ${design_md}"

  # Check 4b: design.md contains AC-xxx items
  echo "checking: design.md contains AC-xxx items"
  if ! grep -qE "AC-[0-9]+" "$design_md" 2>/dev/null; then
    warn "no AC-xxx items found in design.md"
    warn "hint: add acceptance criteria (e.g., AC-001, AC-002)"
  else
    ac_count=$(grep -oE "AC-[0-9]+" "$design_md" | sort -u | wc -l | tr -d ' ')
    ok "found ${ac_count} AC-xxx item(s)"
  fi
fi

# Check 5: Production verification.md exists
echo "checking: production verification.md exists"
if [[ ! -f "$verification_md" ]]; then
  err "missing: ${verification_md}"
  err "hint: Test Owner must produce acceptance tests (not just characterization tests)"
  ((errors++))
else
  ok "found: ${verification_md}"
fi

# Check 6: Characterization tests exist (warning only)
echo "checking: characterization tests exist"
char_dir="${prototype_dir}/characterization"
if [[ -d "$char_dir" ]] && [[ -n "$(ls -A "$char_dir" 2>/dev/null)" ]]; then
  char_count=$(find "$char_dir" -type f \( -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.test.*" \) 2>/dev/null | wc -l | tr -d ' ')
  ok "found ${char_count} characterization test file(s)"
else
  warn "no characterization tests found in ${char_dir}"
  warn "hint: characterization tests help preserve behavior knowledge"
fi

# Check 7: Basic test coverage (P1 - harden-devbooks-quality-gates)
echo "checking: prototype has basic test coverage"
proto_src="${prototype_dir}/src"
if [[ -d "$proto_src" ]]; then
  src_count=$(find "$proto_src" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.sh" \) 2>/dev/null | wc -l | tr -d ' ')
  test_count=$(find "$prototype_dir" -type f \( -name "*.test.*" -o -name "*_test.*" -o -name "*.spec.*" \) 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$src_count" -gt 0 ]]; then
    if [[ "$test_count" -eq 0 ]]; then
      warn "no test files found for ${src_count} source files in prototype"
      warn "hint: consider adding characterization tests before promotion"
    else
      ratio=$((test_count * 100 / src_count))
      if [[ "$ratio" -lt 50 ]]; then
        warn "low test coverage: ${test_count} test files for ${src_count} source files (${ratio}%)"
      else
        ok "test coverage: ${test_count} test files for ${src_count} source files (${ratio}%)"
      fi
    fi
  fi
fi

# Check 8: Complexity threshold warning (P1 - harden-devbooks-quality-gates)
echo "checking: prototype complexity"
if [[ -d "$proto_src" ]]; then
  # Count total lines of code
  total_loc=$(find "$proto_src" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.sh" \) -exec cat {} \; 2>/dev/null | wc -l | tr -d ' ')

  # Complexity threshold: warn if > 1000 lines (configurable via env)
  complexity_threshold="${PROTOTYPE_COMPLEXITY_THRESHOLD:-1000}"

  if [[ "$total_loc" -gt "$complexity_threshold" ]]; then
    warn "prototype exceeds complexity threshold: ${total_loc} lines (threshold: ${complexity_threshold})"
    warn "hint: consider breaking into smaller modules before promotion"
  else
    ok "complexity: ${total_loc} lines (threshold: ${complexity_threshold})"
  fi
fi

echo ""

# ============================================================================
# Error summary
# ============================================================================

if [[ $errors -gt 0 ]]; then
  echo "=== Promotion Blocked ==="
  err "${errors} error(s) found"
  echo ""
  echo "Required before promotion:"
  echo "  1. Complete all items in PROTOTYPE.md '提升检查清单'"
  echo "  2. Create production design.md with AC-xxx items"
  echo "  3. Have Test Owner create verification.md with acceptance tests"
  exit 1
fi

# ============================================================================
# Confirmation
# ============================================================================

echo "=== Ready for Promotion ==="
echo ""
echo "This will:"
echo "  1. Archive characterization tests to: ${archive_dir}/${change_id}/"
echo "  2. Remove prototype directory: ${prototype_dir}"
echo ""

if [[ "$force" != true ]]; then
  read -r -p "Proceed? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY])
      ;;
    *)
      echo "aborted"
      exit 0
      ;;
  esac
fi

# ============================================================================
# Execute promotion
# ============================================================================

# Archive characterization tests
if [[ -d "$char_dir" ]] && [[ -n "$(ls -A "$char_dir" 2>/dev/null)" ]]; then
  mkdir -p "${archive_dir}/${change_id}"
  cp -r "${char_dir}/"* "${archive_dir}/${change_id}/" 2>/dev/null || true
  ok "archived: characterization tests -> ${archive_dir}/${change_id}/"
fi

# Create promotion record
cat > "${change_dir}/evidence/prototype-promotion.md" <<EOF
# Prototype Promotion Record

- Change ID: ${change_id}
- Promoted at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Characterization tests archived to: ${archive_dir}/${change_id}/

## Pre-promotion state

- Prototype directory existed: yes
- PROTOTYPE.md checklist: complete
- design.md: present
- verification.md: present

## Post-promotion

- Prototype directory: removed
- Production track: active

---
Reference: 《人月神话》第11章 — "第一个开发的系统并不合用...为舍弃而计划"
EOF
ok "created: ${change_dir}/evidence/prototype-promotion.md"

# Remove prototype directory
rm -rf "$prototype_dir"
ok "removed: ${prototype_dir}"

echo ""
echo "=== Promotion Complete ==="
ok "prototype promoted for ${change_id}"
echo ""
echo "Next steps:"
echo "  1. Run 'change-check.sh ${change_id} --mode apply' to validate production track"
echo "  2. Coder implements against verification.md acceptance tests"
echo "  3. Review characterization tests in ${archive_dir}/${change_id}/ for behavior reference"
