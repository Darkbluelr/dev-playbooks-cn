#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: dependency-audit.sh [options]

Description:
  Run a dependency audit and write a log for evidence review.

Options:
  --project-root DIR  Project root directory (default: current dir)
  --output FILE       Output log file path (default: dependency-audit.log)
  -h, --help          Show this help message

Examples:
  dependency-audit.sh --output evidence/audit/dependency-audit.log
USAGE
}

project_root="$(pwd)"
output_file="dependency-audit.log"

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
    --output)
      output_file="${2:-}"
      shift 2
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
 done

if [[ -z "$project_root" || -z "$output_file" ]]; then
  echo "ERROR: project root and output file are required" >&2
  exit 2
fi

pkg_file="${project_root}/package.json"
lock_file="${project_root}/package-lock.json"

if [[ ! -f "$pkg_file" ]]; then
  echo "ERROR: package.json not found at ${pkg_file}" >&2
  exit 1
fi

mkdir -p "$(dirname "$output_file")"

{
  echo "Dependency Audit"
  echo "run_at: $(date +%Y-%m-%dT%H:%M:%S%z)"
  echo "project_root: ${project_root}"
  echo "package.json: ${pkg_file}"
  if [[ -f "$lock_file" ]]; then
    echo "package-lock.json: ${lock_file}"
  else
    echo "package-lock.json: missing"
  fi
  echo ""
} >"$output_file"

status=0

if command -v npm >/dev/null 2>&1; then
  temp_output="$(mktemp)"
  if npm --prefix "$project_root" audit --json >"$temp_output" 2>/dev/null; then
    echo "npm_audit: ok" >>"$output_file"
    echo "summary: no audit errors" >>"$output_file"
  else
    status=1
    echo "npm_audit: failed" >>"$output_file"
    echo "summary: audit reported issues or failed" >>"$output_file"
  fi
  echo "" >>"$output_file"
  echo "raw_audit_json:" >>"$output_file"
  cat "$temp_output" >>"$output_file"
  rm -f "$temp_output"
else
  status=1
  echo "npm_audit: skipped (npm not found)" >>"$output_file"
  echo "summary: audit not executed" >>"$output_file"
fi

exit "$status"
