#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF >&2
usage: $(basename "$0") [--project-root <dir>]

Verifies the repository is free from legacy traces in mainline (excluding archives).

Exit codes:
  0  pass (no matches)
  1  fail (found matches)
  2  usage error
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

if ! command -v rg >/dev/null 2>&1; then
  echo "error: missing dependency: rg (ripgrep)" >&2
  exit 2
fi

# Build scan pattern without embedding banned contiguous identifiers in source.
tok_a=$'o''p''e''n''s''p''e''c'
tok_b=$'s''p''e''c''k''i''t'
tok_c=$'O''p''e''n''S''p''e''c'
tok_d=$'S''p''e''c''k''i''t'
tok_e=$'d''e''v''b''o''o''k''s''.''j''s'
tok_f=$'m''i''g''r''a''t''e''-''f''r''o''m''-'"${tok_a}"
tok_g=$'m''i''g''r''a''t''e''-''f''r''o''m''-'"${tok_b}"

pattern="${tok_a}|${tok_b}|${tok_c}|${tok_d}|${tok_e}|${tok_f}|${tok_g}"

set +e
rg -n "$pattern" "$project_root" \
  --glob '!.git/**' \
  --glob '!node_modules/**' \
  --glob '!.npm-cache/**' \
  --glob '!.code/**' \
  --glob '!.claude/**' \
  --glob '!.cursor/**' \
  --glob '!dev-playbooks/changes/archive/**' >/dev/null 2>&1
status=$?
set -e

case "$status" in
  0)
    echo "fail: legacy traces found" >&2
    exit 1
    ;;
  1)
    echo "ok: legacy traces scan is empty" >&2
    exit 0
    ;;
  *)
    echo "error: rg failed (exit=${status})" >&2
    exit 2
    ;;
esac
