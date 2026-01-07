#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-codemod-scaffold.sh <change-id> [--name <codemod-name>] [--project-root <dir>] [--change-root <dir>] [--force]

Creates a runnable codemod script under:
  <change-root>/<change-id>/scripts/codemod-<codemod-name>.sh

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

change_id="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
name="lsc"
force=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --name)
      name="${2:-}"
      shift 2
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

if [[ -z "$name" || "$name" =~ [[:space:]] || "$name" == *"/"* ]]; then
  echo "error: invalid --name (no whitespace, no '/'): '$name'" >&2
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

target_dir="${change_dir}/scripts"
target_file="${target_dir}/codemod-${name}.sh"

if [[ -f "$target_file" && "$force" != true ]]; then
  echo "skip: ${target_file}"
  exit 0
fi

mkdir -p "$target_dir"

cat >"$target_file" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
usage: codemod-<name>.sh [--apply]

Runs a large-scale mechanical change. Default is dry-run.

Recommended flow:
  1) Implement the mechanical transformation deterministically.
  2) Run tests / static checks.
  3) Capture evidence to <change-root>/<change-id>/evidence/ via change-evidence.sh.
USAGE
}

apply=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --apply) apply=true; shift ;;
    *) usage; exit 2 ;;
  esac
done

repo_root="$(pwd)"

if [[ "$apply" != true ]]; then
  echo "dry-run: no changes applied"
  echo "repo_root: ${repo_root}"
  echo "next: edit this script to implement your codemod, then re-run with --apply"
  exit 0
fi

echo "apply: TODO implement codemod steps"
exit 2
EOF

chmod +x "$target_file"
echo "wrote: ${target_file}"
echo "ok: scaffolded codemod script for ${change_id} (${name})"

