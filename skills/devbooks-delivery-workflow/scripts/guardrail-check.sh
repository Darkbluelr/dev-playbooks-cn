#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: guardrail-check.sh <change-id> [--project-root <dir>] [--change-root <dir>]" >&2
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

if ! command -v rg >/dev/null 2>&1; then
  echo "error: missing dependency: rg (ripgrep)" >&2
  exit 2
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

if ! rg -n "^F\\) 结构质量守门记录" "$file" >/dev/null; then
  echo "error: missing section '结构质量守门记录' in ${file}" >&2
  exit 1
fi

decision_line=$(rg -n "^- 决策与授权：" "$file" || true)
if [[ -z "$decision_line" ]]; then
  echo "error: missing '- 决策与授权：' line in ${file}" >&2
  exit 1
fi

value="$(echo "$decision_line" | sed -E 's/^[0-9]+:- 决策与授权： *//')"

if [[ -z "$value" || "$value" == "<"* || "$value" == "TBD"* ]]; then
  echo "error: unresolved guardrail decision in ${file}" >&2
  exit 1
fi

echo "ok: guardrail decision present for ${change_id}"
