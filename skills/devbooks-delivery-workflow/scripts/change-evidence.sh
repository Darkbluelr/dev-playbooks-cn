#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-evidence.sh <change-id> [--project-root <dir>] [--change-root <dir>] [--label <name>] [--out <file>] -- <command> [args...]

Runs a command and captures its combined stdout/stderr into:
  <change-root>/<change-id>/evidence/

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
label="evidence"
out_path=""

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
    --label)
      label="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    --)
      shift
      break
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

if [[ -z "$label" || "$label" =~ [[:space:]] ]]; then
  echo "error: invalid --label (no whitespace): '$label'" >&2
  exit 2
fi

if [[ $# -lt 1 ]]; then
  echo "error: missing command after '--'" >&2
  usage
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

evidence_dir="${change_dir}/evidence"
mkdir -p "$evidence_dir"

sanitize() {
  printf '%s' "$1" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//'
}

ts="$(date +%Y%m%d-%H%M%S)"
safe_label="$(sanitize "$label")"
if [[ -z "$safe_label" ]]; then
  safe_label="evidence"
fi

if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${evidence_dir}/${out_path}"
  fi
else
  out_file="${evidence_dir}/${ts}-${safe_label}.log"
fi

mkdir -p "$(dirname "$out_file")"

cmd_pretty="$(printf '%q ' "$@")"

{
  echo "# Evidence capture"
  echo "# change-id: ${change_id}"
  echo "# timestamp: $(date -Iseconds)"
  echo "# project-root: ${project_root}"
  echo "# cwd: ${project_root}"
  echo "# command: ${cmd_pretty}"
  echo
} >"$out_file"

echo "devbooks: capturing evidence -> ${out_file}"
echo "devbooks: running: ${cmd_pretty}"

set +e
(
  cd "$project_root"
  "$@" 2>&1
) | tee -a "$out_file"
exit_code="${PIPESTATUS[0]}"
set -e

{
  echo
  echo "# exit_code: ${exit_code}"
} >>"$out_file"

if [[ "$exit_code" -ne 0 ]]; then
  echo "fail: command exit_code=${exit_code} (evidence recorded)" >&2
  exit "$exit_code"
fi

echo "ok: evidence recorded"

