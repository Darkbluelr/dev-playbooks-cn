#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: devbooks-complexity.sh [--path <dir>] [--output <file>]

Description:
  Emit a lightweight complexity summary based on line counts.

Options:
  --path <dir>    Target directory (default: current dir)
  --output <file> Write report to file (default: stdout)
  -h, --help      Show this help message
EOF
}

path="."
output=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      path="${2:-}"
      shift 2
      ;;
    --output)
      output="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$path" ]]; then
  echo "ERROR: --path is required" >&2
  exit 2
fi

if [[ ! -d "$path" ]]; then
  echo "ERROR: path not found: $path" >&2
  exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

find "$path" -type f \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "*/dev-playbooks/changes/archive/*" \
  -print0 \
  | xargs -0 wc -l 2>/dev/null >"$tmp_file" || true

total_lines="$(awk 'END {print $1}' "$tmp_file" 2>/dev/null || echo 0)"
file_count="$(awk 'NR>1 {count++} END {print count+0}' "$tmp_file" 2>/dev/null || echo 0)"

report="# Complexity Summary\n\n"
report+="path: ${path}\n"
report+="files: ${file_count}\n"
report+="total_lines: ${total_lines}\n"

if [[ -n "$output" ]]; then
  printf "%b" "$report" >"$output"
else
  printf "%b" "$report"
fi

exit 0
