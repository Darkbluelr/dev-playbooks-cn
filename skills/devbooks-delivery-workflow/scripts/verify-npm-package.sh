#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: verify-npm-package.sh [--project-root <dir>]

Checks the npm package metadata is consistent for the CLI entrypoint.
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

pkg="${project_root}/package.json"
if [[ ! -f "$pkg" ]]; then
  echo "error: missing package.json: ${pkg}" >&2
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "error: missing dependency: rg (ripgrep)" >&2
  exit 2
fi

extract_json_string_field() {
  local file="$1"
  local key="$2"
  rg -n "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" "$file" -m 1 2>/dev/null \
    | sed -E "s/.*\\\"${key}\\\"[[:space:]]*:[[:space:]]*\\\"([^\\\"]+)\\\".*/\\1/" \
    | head -n 1
}

pkg_name="$(extract_json_string_field "$pkg" "name")"
if [[ -z "$pkg_name" ]]; then
  echo "error: missing package name in package.json" >&2
  exit 1
fi

# Expect a bin mapping for the package name (common pattern for CLI packages).
bin_path="$(rg -n "\"${pkg_name}\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" "$pkg" -m 1 2>/dev/null \
  | sed -E "s/.*\\\"${pkg_name}\\\"[[:space:]]*:[[:space:]]*\\\"([^\\\"]+)\\\".*/\\1/" \
  | head -n 1)"

if [[ -z "$bin_path" ]]; then
  echo "error: missing bin mapping for '${pkg_name}' in package.json" >&2
  exit 1
fi

if [[ "$bin_path" != bin/* ]]; then
  echo "error: expected bin path under bin/ (got: ${bin_path})" >&2
  exit 1
fi

if [[ ! -f "${project_root}/${bin_path}" ]]; then
  echo "error: bin entrypoint not found: ${bin_path} (from package.json)" >&2
  exit 1
fi

echo "ok: npm package metadata verified (name=${pkg_name}, bin=${bin_path})" >&2
