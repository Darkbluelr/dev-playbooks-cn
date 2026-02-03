#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF >&2
usage: $(basename "$0") --legacy-id <id> [--project-root <dir>] [--dry-run] [--keep-old]

This utility is intentionally isolated under scripts/legacy/.
It is a compatibility bridge for older project layouts and is not part of the mainline DevBooks workflow.

Behavior:
- Detects a legacy root directory named by --legacy-id under the project root.
- Prints the planned actions (and optionally applies them).

Safety:
- Prefer running with --dry-run first.
EOF
}

legacy_id=""
project_root="."
dry_run=false
keep_old=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --legacy-id)
      legacy_id="${2:-}"
      shift 2
      ;;
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --keep-old)
      keep_old=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$legacy_id" || "$legacy_id" =~ [[:space:]] ]]; then
  echo "error: --legacy-id is required" >&2
  exit 2
fi

project_root="${project_root%/}"
legacy_dir="${project_root}/${legacy_id}"

if [[ ! -d "$legacy_dir" ]]; then
  echo "ok: legacy directory not found; nothing to do: ${legacy_dir}" >&2
  exit 0
fi

echo "info: legacy directory detected: ${legacy_dir}" >&2
echo "info: this script is a conservative bridge; mainline onboarding should use Start/Bootstrap." >&2

if [[ "$dry_run" == true ]]; then
  echo "dry-run: would migrate legacy layout into DevBooks directories (implementation intentionally omitted)" >&2
  exit 0
fi

echo "error: legacy migration is disabled in mainline. Use --dry-run for inspection only." >&2
exit 1

