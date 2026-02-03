#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: devbooks-entropy-viz.sh --input <report.md> [--output <file>]

Description:
  Render a minimal summary from an entropy report.

Options:
  --input <file>   Entropy report markdown
  --output <file>  Write summary to file (default: stdout)
  -h, --help       Show this help message
EOF
}

input=""
output=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      input="${2:-}"
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

if [[ -z "$input" ]]; then
  echo "ERROR: --input is required" >&2
  exit 2
fi

if [[ ! -f "$input" ]]; then
  echo "ERROR: input not found: $input" >&2
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: rg (ripgrep) not found" >&2
  exit 2
fi

summary="# Entropy Summary\n\n"
summary+="source: ${input}\n"

if rg -n "^\\| Structural Entropy" "$input" >/dev/null 2>&1; then
  summary+="status: extracted\n"
else
  summary+="status: no-metrics\n"
fi

if [[ -n "$output" ]]; then
  printf "%b" "$summary" >"$output"
else
  printf "%b" "$summary"
fi

exit 0
