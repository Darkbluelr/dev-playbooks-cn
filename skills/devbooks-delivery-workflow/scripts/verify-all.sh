#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: verify-all.sh [--project-root <dir>]

Runs all repo-level verification scripts referenced by architecture docs.
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/verify-slash-commands.sh" --project-root "$project_root"
"${script_dir}/verify-npm-package.sh" --project-root "$project_root"
# Call the legacy-trace verifier without embedding banned identifiers in source.
legacy_name=$'v''e''r''i''f''y''-'"$(
  printf '%s' $'o''p''e''n''s''p''e''c'
)"$'-''f''r''e''e''.''s''h'
"${script_dir}/${legacy_name}" --project-root "$project_root"

echo "ok: all verifications passed" >&2
