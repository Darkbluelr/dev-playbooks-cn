#!/usr/bin/env bash
# handoff-check.sh - Verify role handoff has proper confirmation
#
# This script checks that handoff.md exists and has proper confirmation
# signatures from both roles involved in the handoff.
#
# Reference: harden-devbooks-quality-gates design.md AC-004

set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: handoff-check.sh <change-id> [options]

Verify role handoff has proper confirmation:
1. Checks handoff.md exists
2. Verifies all parties have confirmed (default behavior)
3. Returns exit code based on verification status

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change packages root (default: changes)
  --allow-partial       Allow partial confirmation (at least one [x])
  -h, --help            Show this help message

Exit Codes:
  0 - All checks passed
  1 - Check failed
  2 - Usage error

Examples:
  handoff-check.sh my-change-001
  handoff-check.sh my-change-001 --change-root dev-playbooks/changes
  handoff-check.sh my-change-001 --allow-partial
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
allow_partial=false

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
    --allow-partial)
      allow_partial=true
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

handoff_file="${change_dir}/handoff.md"

echo "handoff-check: checking '${change_id}'"
echo "  change-dir: ${change_dir}"

# Check change directory exists
if [[ ! -d "$change_dir" ]]; then
  echo "error: missing change directory: ${change_dir}" >&2
  exit 1
fi

# Check handoff.md exists
if [[ ! -f "$handoff_file" ]]; then
  echo "error: missing handoff.md: ${handoff_file}" >&2
  exit 1
fi

# Check for confirmation section
if ! grep -qE "确认签名|确认|Confirmation|Confirm" "$handoff_file" 2>/dev/null; then
  echo "error: handoff.md missing confirmation section" >&2
  exit 1
fi

# Count confirmed checkboxes (lines with [x] or [X])
confirmed_count=$(grep -cE "^- \[[xX]\]" "$handoff_file" 2>/dev/null) || confirmed_count=0
unconfirmed_count=$(grep -cE "^- \[ \]" "$handoff_file" 2>/dev/null) || unconfirmed_count=0
total_count=$((confirmed_count + unconfirmed_count))

echo "  signatures: ${confirmed_count}/${total_count} confirmed"

if [[ "$confirmed_count" -eq 0 ]]; then
  echo "error: no confirmed signatures in handoff.md (need at least one [x])" >&2
  exit 1
fi

# Default: require all parties to confirm
if [[ "$allow_partial" != true ]]; then
  if [[ "$unconfirmed_count" -gt 0 ]]; then
    echo "error: incomplete signatures - all parties must confirm (${confirmed_count}/${total_count})" >&2
    exit 1
  fi
fi

echo "ok: handoff verification passed"
exit 0
