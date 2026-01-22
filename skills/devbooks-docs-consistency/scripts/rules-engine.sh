#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: rules-engine.sh [--rules <path>] [--once "remove:@pattern"] --input <file>

Options:
  --rules <path>     YAML rules file
  --once <action>    One-time action (e.g. remove:@augment)
  --input <file>     Document file to check
EOF
}

RULES_PATH=""
ONCE_ACTION=""
INPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rules)
      RULES_PATH="$2"
      shift 2
      ;;
    --once)
      ONCE_ACTION="$2"
      shift 2
      ;;
    --input)
      INPUT_PATH="$2"
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
  echo "Input file not found: $INPUT_PATH" >&2
  exit 2
fi

report_violation() {
  local rule_id="$1"
  local pattern="$2"
  local file_path="$3"
  echo "rule_id=${rule_id} file=${file_path} forbidden=${pattern}"
}

run_once_action() {
  local action="$1"
  local file_path="$2"

  if [[ -z "$action" ]]; then
    return 0
  fi

  if [[ "$action" != remove:* ]]; then
    echo "Unsupported once action: $action" >&2
    return 2
  fi

  local pattern="${action#remove:}"
  if grep -q "$pattern" "$file_path"; then
    echo "once_action=remove pattern=$pattern file=$file_path"
  else
    echo "once_action=remove pattern=$pattern file=$file_path (not found)"
  fi
}

validate_yaml() {
  local file_path="$1"
  local has_rules=0
  local has_invalid=0
  local indent_error=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^rules:[[:space:]]*(\[\])?[[:space:]]*$ ]]; then
      has_rules=1
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]* ]]; then
      has_rules=1
    fi

    if [[ "$line" =~ ^[[:space:]]*pattern[[:space:]]+[^:]+$ ]]; then
      has_invalid=1
    fi
  done < "$file_path"

  if [[ "$has_invalid" -eq 1 ]]; then
    return 1
  fi
  if [[ "$has_rules" -eq 0 ]]; then
    return 1
  fi
  return 0
}

extract_rules() {
  local file_path="$1"

  python3 - "$file_path" <<'PY'
import sys

file_path = sys.argv[1]
rules = []
current = None

with open(file_path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.rstrip("\n")
        if line.strip().startswith("rules:"):
            continue
        if line.lstrip().startswith("- "):
            if current:
                rules.append(current)
            current = {}
            line = line.lstrip()[2:]
        if current is None:
            continue
        if ":" in line:
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip().strip('"')
            current[key] = value
    if current:
        rules.append(current)

for rule in rules:
    rule_id = rule.get("id", "")
    rule_type = rule.get("type", "")
    rule_target = rule.get("target", "")
    rule_action = rule.get("action", "")
    rule_pattern = rule.get("pattern", "")
    rule_replacement = rule.get("replacement", "")
    if rule_id:
        print("|".join([rule_id, rule_type, rule_target, rule_action, rule_pattern, rule_replacement]))
PY
}

detect_conflicts() {
  local rules_file="$1"
  local conflict=0
  local seen=""

  while IFS='|' read -r rule_id rule_type rule_target rule_action rule_pattern rule_replacement; do
    if [[ -z "$rule_id" ]]; then
      continue
    fi
    if [[ "$rule_action" == "replace" ]]; then
      local key="${rule_target}|${rule_pattern}"
      local existing
      existing=$(printf "%s\n" "$seen" | awk -F'=' -v k="$key" '$1==k {print $2}' | tail -n 1)
      if [[ -n "$existing" && "$existing" != "$rule_replacement" ]]; then
        echo "conflict detected: rule_id=$rule_id conflicts_with=$key"
        conflict=1
      else
        seen+="${key}=${rule_replacement}\n"
      fi
    fi
  done < <(extract_rules "$rules_file")

  if [[ "$conflict" -eq 1 ]]; then
    return 1
  fi
  return 0
}

apply_rules() {
  local rules_file="$1"
  local file_path="$2"
  local violations=0
  local matched_rules=0

  while IFS='|' read -r rule_id rule_type rule_target rule_action rule_pattern rule_replacement; do
    if [[ -z "$rule_id" ]]; then
      continue
    fi
    matched_rules=1
    case "$rule_action" in
      check)
        if grep -q "$rule_pattern" "$file_path"; then
          report_violation "$rule_id" "$rule_pattern" "$file_path"
          violations=1
        fi
        ;;
      remove)
        if grep -q "$rule_pattern" "$file_path"; then
          report_violation "$rule_id" "$rule_pattern" "$file_path"
          violations=1
        fi
        ;;
      replace)
        if grep -q "$rule_pattern" "$file_path"; then
          report_violation "$rule_id" "$rule_pattern" "$file_path"
          violations=1
        fi
        ;;
      *)
        echo "unsupported action: $rule_action" >&2
        return 2
        ;;
    esac
  done < <(extract_rules "$rules_file")

  if [[ "$matched_rules" -eq 0 ]]; then
    return 0
  fi

  if [[ "$violations" -eq 1 ]]; then
    return 1
  fi
  return 0
}

if [[ -n "$ONCE_ACTION" ]]; then
  run_once_action "$ONCE_ACTION" "$INPUT_PATH"
  exit 0
fi

if [[ -z "$RULES_PATH" ]]; then
  echo "no rules file provided"
  exit 0
fi

if [[ ! -f "$RULES_PATH" ]]; then
  echo "rules file not found: $RULES_PATH" >&2
  exit 2
fi

if ! validate_yaml "$RULES_PATH"; then
  echo "invalid yaml rules: $RULES_PATH" >&2
  exit 2
fi

if ! detect_conflicts "$RULES_PATH"; then
  exit 2
fi

apply_rules "$RULES_PATH" "$INPUT_PATH"
