#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: generate-protocol-v1.1-coverage-report.sh [args...]

Thin wrapper for:
  dev-playbooks/scripts/maintenance/generate-protocol-v1.1-coverage-report.sh

Rationale:
- Provide a stable repo-level entrypoint that is not excluded by gitignore rules.
- Keep the implementation SSOT under dev-playbooks/ (protocol-managed scripts).

Pass --help to see the underlying script options.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
target="${repo_root}/dev-playbooks/scripts/maintenance/generate-protocol-v1.1-coverage-report.sh"

if [[ ! -x "$target" ]]; then
  echo "error: missing underlying generator script: ${target}" >&2
  echo "hint: ensure dev-playbooks is present and the maintenance script is executable" >&2
  exit 2
fi

exec "$target" "$@"

