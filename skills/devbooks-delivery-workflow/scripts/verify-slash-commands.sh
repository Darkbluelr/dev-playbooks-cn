#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: verify-slash-commands.sh [--project-root <dir>]

Checks:
- templates/claude-commands/devbooks contains 23 command files
- /devbooks:delivery maps to devbooks-delivery-workflow
EOF
}

project_root="."
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
    *)
      usage
      exit 2
      ;;
  esac
done

project_root="${project_root%/}"

dir="${project_root}/templates/claude-commands/devbooks"
if [[ ! -d "$dir" ]]; then
  echo "error: missing directory: ${dir}" >&2
  exit 1
fi

cmd_count="$(ls "$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$cmd_count" -ne 23 ]]; then
  echo "error: expected 23 slash command templates, got ${cmd_count}" >&2
  exit 1
fi

mapping="$(rg -n "^skill:" "${dir}/delivery.md" | head -1 || true)"
if [[ "$mapping" != *"devbooks-delivery-workflow"* ]]; then
  echo "error: /devbooks:delivery must map to devbooks-delivery-workflow (found: ${mapping:-<none>})" >&2
  exit 1
fi

echo "ok: slash commands verified" >&2
