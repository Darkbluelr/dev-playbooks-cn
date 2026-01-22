#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_RULES="${SCRIPT_DIR}/../references/doc-classification.yaml"

RULES_PATH="${DOC_CLASSIFICATION_RULES:-$DEFAULT_RULES}"
DOC_PATH="${1:-}"

if [[ -z "$DOC_PATH" ]]; then
  echo "usage: doc-classifier.sh <path>" >&2
  exit 2
fi

if [[ ! -f "$RULES_PATH" ]]; then
  echo "rules file not found: $RULES_PATH" >&2
  exit 2
fi

normalize_path() {
  local input="$1"
  echo "${input#./}"
}

collect_patterns() {
  local key="$1"
  python3 - "$RULES_PATH" "$key" <<'PY'
import sys

rules_path = sys.argv[1]
key = sys.argv[2]
patterns = []
collecting = False

with open(rules_path, "r", encoding="utf-8") as fh:
    for raw in fh:
        line = raw.rstrip("\n")
        if line.startswith(f"{key}:"):
            collecting = True
            continue
        if collecting:
            stripped = line.strip()
            if not stripped.startswith("-"):
                if stripped and not stripped.startswith("#"):
                    collecting = False
                elif not stripped:
                    continue
            if stripped.startswith("-"):
                value = stripped.lstrip("-").strip()
                if value.startswith("\"") and value.endswith("\""):
                    value = value[1:-1]
                if value:
                    patterns.append(value)

for item in patterns:
    print(item)
PY
}

matches_pattern() {
  local path="$1"
  local pattern="$2"
  python3 - "$path" "$pattern" <<'PY'
import sys
from pathlib import PurePosixPath

path = PurePosixPath(sys.argv[1])
pattern = sys.argv[2]
print("1" if path.match(pattern) else "0")
PY
}

doc_path=$(normalize_path "$DOC_PATH")

living_patterns=()
history_patterns=()
concept_patterns=()
while IFS= read -r line; do
  living_patterns+=("$line")
done < <(collect_patterns "living_docs")
while IFS= read -r line; do
  history_patterns+=("$line")
done < <(collect_patterns "history_docs")
while IFS= read -r line; do
  concept_patterns+=("$line")
done < <(collect_patterns "concept_docs")

match_types=()

for pattern in "${living_patterns[@]:-}"; do
  if [[ -n "$pattern" && $(matches_pattern "$doc_path" "$pattern") == "1" ]]; then
    match_types+=("living")
    break
  fi
done

for pattern in "${history_patterns[@]:-}"; do
  if [[ -n "$pattern" && $(matches_pattern "$doc_path" "$pattern") == "1" ]]; then
    match_types+=("history")
    break
  fi
done

for pattern in "${concept_patterns[@]:-}"; do
  if [[ -n "$pattern" && $(matches_pattern "$doc_path" "$pattern") == "1" ]]; then
    match_types+=("concept")
    break
  fi
done

if [[ "${#match_types[@]}" -eq 0 ]]; then
  echo "unknown"
  exit 0
fi

if [[ "${#match_types[@]}" -gt 1 ]]; then
  echo "conflict: ${match_types[*]}"
  exit 0
fi

echo "${match_types[0]}"
