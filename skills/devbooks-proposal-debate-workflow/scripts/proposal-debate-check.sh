#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: proposal-debate-check.sh <change-id> [--project-root <dir>] [--change-root <dir>]

Checks that a proposal has completed the debate decision:
- proposal.md contains '## Debate Packet' and '## Decision Log'
- 'Decision Log' contains '- 决策状态：Approved | Revise | Rejected'
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
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$project_root" || -z "$change_root" ]]; then
  usage
  exit 2
fi

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "error: missing dependency: rg (ripgrep)" >&2
  exit 2
fi

if [[ "$change_root" = /* ]]; then
  file="${change_root}/${change_id}/proposal.md"
else
  file="${project_root}/${change_root}/${change_id}/proposal.md"
fi


if [[ ! -f "$file" ]]; then
  echo "error: missing ${file}" >&2
  exit 2
fi

if ! rg -n "^## Debate Packet$" "$file" >/dev/null; then
  echo "error: missing 'Debate Packet' section in ${file}" >&2
  exit 1
fi

if ! rg -n "^## Decision Log" "$file" >/dev/null; then
  echo "error: missing 'Decision Log' section in ${file}" >&2
  exit 1
fi

decision_line=$(rg -n "^- 决策状态：" "$file" -m 1 || true)
if [[ -z "$decision_line" ]]; then
  echo "error: missing '- 决策状态：' line in ${file}" >&2
  exit 1
fi

value="$(echo "$decision_line" | sed -E 's/^[0-9]+:- 决策状态： *//')"

case "$value" in
  Approved|Revise|Rejected) ;;
  Pending) echo "error: decision is still Pending (debate not concluded): ${file}" >&2; exit 1 ;;
  *) echo "error: 决策状态必须为 Approved | Revise | Rejected（当前：${value}）" >&2; exit 1 ;;
esac

echo "ok: proposal decision present for ${change_id}"
