#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: style-checker.sh [--meta <docs-maintenance.md>] [--use-emoji true|false] [--use-fancy-words true|false] --input <file>
EOF
}

META_PATH=""
INPUT_PATH=""
OVERRIDE_EMOJI=""
OVERRIDE_FANCY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --meta)
      META_PATH="$2"
      shift 2
      ;;
    --input)
      INPUT_PATH="$2"
      shift 2
      ;;
    --use-emoji)
      OVERRIDE_EMOJI="$2"
      shift 2
      ;;
    --use-fancy-words)
      OVERRIDE_FANCY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$INPUT_PATH" ]]; then
  echo "Missing --input" >&2
  usage >&2
  exit 2
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "input not found: $INPUT_PATH" >&2
  exit 2
fi

read_meta_flag() {
  local key="$1"
  local file_path="$2"
  if [[ -z "$file_path" || ! -f "$file_path" ]]; then
    echo ""
    return
  fi
  awk -v key="$key" '
    $0 ~ key":" {gsub(/^.*: /, "", $0); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print $0; exit}
  ' "$file_path"
}

use_emoji=""
use_fancy=""

if [[ -n "$OVERRIDE_EMOJI" ]]; then
  use_emoji="$OVERRIDE_EMOJI"
else
  use_emoji=$(read_meta_flag "use_emoji" "$META_PATH")
fi

if [[ -n "$OVERRIDE_FANCY" ]]; then
  use_fancy="$OVERRIDE_FANCY"
else
  use_fancy=$(read_meta_flag "use_fancy_words" "$META_PATH")
fi

if [[ -z "$use_emoji" ]]; then
  use_emoji="true"
fi

if [[ -z "$use_fancy" ]]; then
  use_fancy="true"
fi

exit_code=0

if [[ "$use_emoji" == "false" ]]; then
  if python3 - "$INPUT_PATH" <<'PY'
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8", errors="ignore") as fh:
        data = fh.read()
except OSError:
    sys.exit(1)

for ch in data:
    codepoint = ord(ch)
    if 0x1F300 <= codepoint <= 0x1FAFF:
        sys.exit(0)
sys.exit(1)
PY
  then
    echo "emoji detected in $INPUT_PATH"
    exit_code=1
  fi
fi

if [[ "$use_fancy" == "false" ]]; then
  if grep -qE "(最强大脑|智能|高效|强大|优雅|完美|革命性|颠覆性)" "$INPUT_PATH"; then
    echo "fancy words detected in $INPUT_PATH"
    exit_code=1
  fi
fi

exit "$exit_code"
