#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: completeness-checker.sh --input <file> --config <dimensions.yaml> [--output <report>]
EOF
}

INPUT_PATH=""
CONFIG_PATH=""
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      INPUT_PATH="$2"
      shift 2
      ;;
    --config)
      CONFIG_PATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
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

if [[ -z "$INPUT_PATH" || -z "$CONFIG_PATH" ]]; then
  echo "Missing --input or --config" >&2
  usage >&2
  exit 2
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "input not found: $INPUT_PATH" >&2
  exit 2
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "config not found: $CONFIG_PATH" >&2
  exit 2
fi

report_line() {
  local name="$1"
  local ok="$2"
  local msg="$3"
  if [[ "$ok" == "1" ]]; then
    printf -- "- %s: ✓ %s\n" "$name" "$msg"
  else
    printf -- "- %s: ✗ %s\n" "$name" "$msg"
  fi
}

read_dimension_patterns() {
  local key="$1"
  python3 - "$CONFIG_PATH" "$key" <<'PY'
import sys

config_path = sys.argv[1]
target = sys.argv[2]
patterns = []
current = None
collecting = False

with open(config_path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.rstrip("\n")
        stripped = line.strip()
        if stripped.startswith("- name:"):
            current = stripped.split(":", 1)[1].strip()
            collecting = False
            continue
        if current == target and stripped.startswith("patterns:"):
            collecting = True
            continue
        if collecting:
            if stripped.startswith("-"):
                value = stripped.lstrip("-").strip().strip('"')
                if value:
                    patterns.append(value)
            elif stripped and not stripped.startswith("#"):
                collecting = False

for item in patterns:
    print(item)
PY
}

dimensions=()
while IFS= read -r line; do
  dimensions+=("$line")
done < <(python3 - "$CONFIG_PATH" <<'PY'
import sys

config_path = sys.argv[1]
with open(config_path, "r", encoding="utf-8") as fh:
    for raw in fh:
        stripped = raw.strip()
        if stripped.startswith("- name:"):
            print(stripped.split(":", 1)[1].strip())
PY
)

if [[ "${#dimensions[@]}" -eq 0 ]]; then
  echo "no dimensions defined" >&2
  exit 2
fi

output=""
output+="# 完备性检查报告\n\n"

for dim in "${dimensions[@]}"; do
  ok=0
  msg=""
  patterns=()
  while IFS= read -r line; do
    patterns+=("$line")
  done < <(read_dimension_patterns "$dim")
  if [[ "${#patterns[@]}" -eq 0 ]]; then
    msg="无匹配规则"
  else
    for pattern in "${patterns[@]}"; do
      if grep -q "$pattern" "$INPUT_PATH"; then
        ok=1
        msg="命中: $pattern"
        break
      fi
    done
    if [[ "$ok" -eq 0 ]]; then
      msg="缺少: ${patterns[*]}"
    fi
  fi
  output+="$(report_line "$dim" "$ok" "$msg")"$'\n'
done

if [[ -n "$OUTPUT_PATH" ]]; then
  printf "%b" "$output" > "$OUTPUT_PATH"
else
  printf "%b" "$output"
fi
