#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-spec-delta-scaffold.sh <change-id> <capability> [--project-root <dir>] [--change-root <dir>] [--force]

Creates a spec delta markdown file at:
  <change-root>/<change-id>/specs/<capability>/spec.md

Defaults (can be overridden by flags or env):
  DEVBOOKS_PROJECT_ROOT: pwd
  DEVBOOKS_CHANGE_ROOT:  changes
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

change_id="${1:-}"
capability="${2:-}"
shift 2 || true

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
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

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

if [[ -z "$capability" || "$capability" == "-"* || "$capability" =~ [[:space:]] ]]; then
  echo "error: invalid capability: '$capability'" >&2
  exit 2
fi

if [[ "$capability" = /* || "$capability" == *".."* ]]; then
  echo "error: capability must be a relative path segment (no absolute path / '..'): '$capability'" >&2
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

spec_file="${change_dir}/specs/${capability}/spec.md"

if [[ -f "$spec_file" && "$force" != true ]]; then
  echo "skip: ${spec_file}"
  exit 0
fi

mkdir -p "$(dirname "$spec_file")"

cat >"$spec_file" <<EOF
# Spec Delta: ${capability} (${change_id})

> Output location: \`${change_root}/${change_id}/specs/${capability}/spec.md\`
>
> Note: Spec delta is only required when "external behavior/contracts/data invariants" change.

## ADDED Requirements

### Requirement: TODO
- Source: AC-xxx / Proposal / Decision
- Notes:

#### Scenario: TODO
GIVEN ...
WHEN ...
THEN ...

## MODIFIED Requirements

### Requirement: TODO
- Source: AC-xxx / Proposal / Decision
- Notes:

#### Scenario: TODO
GIVEN ...
WHEN ...
THEN ...

## REMOVED Requirements

### Requirement: TODO
- Source: AC-xxx / Proposal / Decision
- Notes:

#### Scenario: TODO
GIVEN ...
WHEN ...
THEN ...
EOF

echo "wrote: ${spec_file}"
echo "ok: scaffolded spec delta for ${change_id} (${capability})"

