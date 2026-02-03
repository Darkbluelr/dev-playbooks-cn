#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: check-anti-weakening.sh <change-id> [options]

Detect "anti-weakening" inconsistencies between completion.contract.yaml and
change package narratives (Non-Goals / Verification blocks).

Required inputs (in change directory):
  - completion.contract.yaml
  - verification.md

Optional inputs (only scan Non-Goals blocks if present):
  - proposal.md
  - design.md

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change root directory (default: changes)
  --out <path>          Override output path (default: evidence/gates/anti-weakening-check.json)
                        Relative paths are resolved from the change directory.
  -h, --help            Show this help message

Exit codes:
  0 - pass or warn
  1 - fail (blocking violations)
  2 - error (usage / missing inputs / unsupported YAML)

Report write policy:
  - exit in {0,1}: always writes report (default or --out)
  - exit = 2: does NOT write report by default; only writes when --out is explicitly provided
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
out_path=""
out_path_explicit=false

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
    --out)
      out_path="${2:-}"
      out_path_explicit=true
      shift 2
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_quotes() {
  local value
  value="$(trim_value "$1")"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  printf '%s' "$value"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Regex patterns that contain shell metacharacters (e.g., '>', backticks) must be
# stored in variables and expanded unquoted in [[ ... =~ $re ]] to avoid
# tokenization / command substitution issues.
FENCE_RE='^[[:space:]]*(```|~~~)'
BLOCKQUOTE_RE='^[[:space:]]*>'
YAML_MULTILINE_PIPE_RE=':[[:space:]]*[|]$'
YAML_MULTILINE_GT_RE=':[[:space:]]*>$'

utc_rfc3339() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

quality_rank() {
  local q
  q="$(to_lower "$(strip_quotes "$1")")"
  case "$q" in
    outline) echo 0 ;;
    draft) echo 1 ;;
    complete) echo 2 ;;
    operational) echo 3 ;;
    inherit) echo -1 ;;
    *)
      echo -2
      ;;
  esac
}

rank_to_quality() {
  local r="$1"
  case "$r" in
    0) echo "outline" ;;
    1) echo "draft" ;;
    2) echo "complete" ;;
    3) echo "operational" ;;
    *) echo "" ;;
  esac
}

list_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

declare -a V_RULE_ID=()
declare -a V_SEVERITY=()
declare -a V_FILE=()
declare -a V_LINE=()
declare -a V_EXCERPT=()
declare -a V_FIX=()

add_violation() {
  local rule_id="$1"
  local severity="$2"
  local file="$3"
  local line="$4"
  local excerpt="$5"
  local fix="$6"

  V_RULE_ID+=("$rule_id")
  V_SEVERITY+=("$severity")
  V_FILE+=("$file")
  V_LINE+=("$line")
  V_EXCERPT+=("$excerpt")
  V_FIX+=("$fix")
}

report_status_from_violations() {
  local has_error=false
  local has_block=false
  local has_warn=false
  local i
  for ((i=0; i<${#V_SEVERITY[@]}; i++)); do
    case "${V_SEVERITY[$i]}" in
      error) has_error=true ;;
      block) has_block=true ;;
      warn) has_warn=true ;;
    esac
  done

  if [[ "$has_error" == true ]]; then
    echo "error"
    return 0
  fi
  if [[ "$has_block" == true ]]; then
    echo "fail"
    return 0
  fi
  if [[ "$has_warn" == true ]]; then
    echo "warn"
    return 0
  fi
  echo "pass"
}

counts_from_violations() {
  local errors=0
  local warns=0
  local i
  for ((i=0; i<${#V_SEVERITY[@]}; i++)); do
    case "${V_SEVERITY[$i]}" in
      warn) warns=$((warns + 1)) ;;
      block|error) errors=$((errors + 1)) ;;
    esac
  done
  printf '%s %s\n' "$errors" "$warns"
}

resolve_out_file() {
  local default_rel="evidence/gates/anti-weakening-check.json"
  local candidate="$default_rel"
  if [[ -n "$out_path" ]]; then
    candidate="$out_path"
  fi

  if [[ "$candidate" = /* ]]; then
    printf '%s' "$candidate"
    return 0
  fi
  printf '%s' "${change_dir}/${candidate}"
}

write_report() {
  local status="$1"
  local exit_code="$2"
  local report_file="$3"
  local errors_count="$4"
  local warnings_count="$5"

  local i
  local violations_json=""
  for ((i=0; i<${#V_RULE_ID[@]}; i++)); do
    local obj
    obj="{\"rule_id\":\"$(json_escape "${V_RULE_ID[$i]}")\",\"severity\":\"$(json_escape "${V_SEVERITY[$i]}")\",\"file\":\"$(json_escape "${V_FILE[$i]}")\",\"line\":${V_LINE[$i]},\"excerpt\":\"$(json_escape "${V_EXCERPT[$i]}")\",\"fix_suggestion\":\"$(json_escape "${V_FIX[$i]}")\"}"
    if [[ -z "$violations_json" ]]; then
      violations_json="$obj"
    else
      violations_json="${violations_json},${obj}"
    fi
  done

  mkdir -p "$(dirname "$report_file")"

  cat >"$report_file" <<JSON
{"schema_version":"1.0.0","check_id":"anti-weakening-check","change_id":"$(json_escape "$change_id")","status":"$(json_escape "$status")","generated_at":"$(json_escape "$(utc_rfc3339)")","errors_count":${errors_count},"warnings_count":${warnings_count},"violations":[${violations_json}]}
JSON

  if [[ "$exit_code" -eq 0 ]]; then
    return 0
  fi
}

fail_error() {
  local message="$1"
  local rule_id="${2:-AW-E001}"

  echo "error: ${message}" >&2
  add_violation "$rule_id" "error" "" 0 "$message" "Fix the input/usage and retry. If needed, pass --out to write an error report for machine parsing."

  local status
  status="$(report_status_from_violations)"
  read -r errors_count warnings_count <<<"$(counts_from_violations)"

  if [[ "$out_path_explicit" == true ]]; then
    local report_file
    report_file="$(resolve_out_file)"
    write_report "$status" 2 "$report_file" "$errors_count" "$warnings_count"
  fi

  exit 2
}

if [[ ! -d "$change_dir" ]]; then
  fail_error "missing change directory: ${change_dir}" "AW-E002"
fi

contract_file="${change_dir}/completion.contract.yaml"
if [[ ! -f "$contract_file" ]]; then
  if [[ -f "${change_dir}/completion.contract.yml" ]]; then
    contract_file="${change_dir}/completion.contract.yml"
  fi
fi

verification_file="${change_dir}/verification.md"

if [[ ! -f "$contract_file" ]]; then
  fail_error "missing completion.contract.yaml: ${contract_file}" "AW-E101"
fi

if [[ ! -r "$contract_file" ]]; then
  fail_error "completion.contract.yaml is not readable: ${contract_file}" "AW-E102"
fi

if [[ ! -f "$verification_file" ]]; then
  fail_error "missing verification.md: ${verification_file}" "AW-E103"
fi

if [[ ! -r "$verification_file" ]]; then
  fail_error "verification.md is not readable: ${verification_file}" "AW-E104"
fi

intent_quality=""
intent_quality_rank_val=-2

deliverables_key_present=false

declare -a DELIVERABLE_IDS=()
declare -a DELIVERABLE_QUALITIES=()
declare -a OBLIGATION_IDS=()

parse_contract() {
  local file="$1"

  local line
  local lineno=0

  local section=""
  local list_indent=-1
  local current_item_type=""

  local current_deliverable_id=""
  local current_deliverable_quality=""
  local current_obligation_id=""

  finalize_item() {
    if [[ "$current_item_type" == "deliverables" ]]; then
      if [[ -z "$current_deliverable_id" || -z "$current_deliverable_quality" ]]; then
        fail_error "deliverables list item missing id or quality (line ${lineno})" "AW-E201"
      fi
      DELIVERABLE_IDS+=("$current_deliverable_id")
      DELIVERABLE_QUALITIES+=("$current_deliverable_quality")
      current_deliverable_id=""
      current_deliverable_quality=""
      current_item_type=""
    elif [[ "$current_item_type" == "obligations" ]]; then
      if [[ -z "$current_obligation_id" ]]; then
        fail_error "obligations list item missing id (line ${lineno})" "AW-E202"
      fi
      OBLIGATION_IDS+=("$current_obligation_id")
      current_obligation_id=""
      current_item_type=""
    fi
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))

    if [[ "$line" == *$'\t'* ]]; then
      fail_error "unsupported YAML: tabs are not allowed (line ${lineno})" "AW-E203"
    fi

    local trimmed
    trimmed="$(trim_value "$line")"

    if [[ -z "$trimmed" ]]; then
      continue
    fi
    if [[ "$trimmed" == \#* ]]; then
      continue
    fi
    if [[ "$trimmed" == "&"* || "$trimmed" == "*"* || "$trimmed" == "<<:"* ]]; then
      fail_error "unsupported YAML: anchors/aliases/merge keys not allowed (line ${lineno})" "AW-E204"
    fi
    if [[ "$trimmed" == *"|" || "$trimmed" == *">" ]]; then
      # Conservative: treat any literal style marker as unsupported.
      if [[ "$trimmed" =~ $YAML_MULTILINE_PIPE_RE || "$trimmed" =~ $YAML_MULTILINE_GT_RE ]]; then
        fail_error "unsupported YAML: multi-line scalars not allowed (line ${lineno})" "AW-E205"
      fi
    fi

    # Heading-level (top/nested) key detection.
    if [[ "$line" =~ ^([[:space:]]*)([A-Za-z0-9_][A-Za-z0-9_\\-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
      local indent="${BASH_REMATCH[1]}"
      local key="${BASH_REMATCH[2]}"
      local value="${BASH_REMATCH[3]}"
      local indent_len="${#indent}"

      # New mapping key at indentation <= current list item means we might be leaving item.
      if [[ "$current_item_type" != "" && "$indent_len" -le "$list_indent" ]]; then
        finalize_item
      fi

      if [[ "$indent_len" -eq 0 ]]; then
        section="$key"
        if [[ "$key" == "deliverables" ]]; then
          deliverables_key_present=true
          list_indent="$indent_len"
        elif [[ "$key" == "obligations" ]]; then
          list_indent="$indent_len"
        fi
      elif [[ "$section" == "intent" && "$key" == "deliverable_quality" ]]; then
        intent_quality="$(strip_quotes "$value")"
        if [[ -z "$intent_quality" ]]; then
          fail_error "missing intent.deliverable_quality (line ${lineno})" "AW-E210"
        fi
      elif [[ "$current_item_type" == "deliverables" ]]; then
        if [[ "$key" == "id" ]]; then
          current_deliverable_id="$(strip_quotes "$value")"
        elif [[ "$key" == "quality" ]]; then
          current_deliverable_quality="$(strip_quotes "$value")"
        fi
      elif [[ "$current_item_type" == "obligations" ]]; then
        if [[ "$key" == "id" ]]; then
          current_obligation_id="$(strip_quotes "$value")"
        fi
      fi

      continue
    fi

    # List item detection.
    if [[ "$line" =~ ^([[:space:]]*)-[[:space:]]*(.*)$ ]]; then
      local indent="${BASH_REMATCH[1]}"
      local rest="${BASH_REMATCH[2]}"
      local indent_len="${#indent}"

      # Ignore nested list items inside the current deliverables/obligations item
      # (e.g., obligations[].applies_to). Only treat list items at the current list
      # indentation as new items.
      if [[ "$current_item_type" != "" && "$indent_len" -gt "$list_indent" ]]; then
        continue
      fi

      # Determine which list we are currently in based on last seen section.
      if [[ "$section" == "deliverables" ]]; then
        finalize_item
        current_item_type="deliverables"
        list_indent="$indent_len"
        current_deliverable_id=""
        current_deliverable_quality=""
      elif [[ "$section" == "obligations" ]]; then
        finalize_item
        current_item_type="obligations"
        list_indent="$indent_len"
        current_obligation_id=""
      else
        # Ignore list items in other sections.
        continue
      fi

      # Support "- key: value" inline on the list item line.
      if [[ "$rest" =~ ^([A-Za-z0-9_][A-Za-z0-9_\\-]*)[[:space:]]*:[[:space:]]*(.*)$ ]]; then
        local key="${BASH_REMATCH[1]}"
        local value="${BASH_REMATCH[2]}"
        if [[ "$current_item_type" == "deliverables" ]]; then
          if [[ "$key" == "id" ]]; then
            current_deliverable_id="$(strip_quotes "$value")"
          elif [[ "$key" == "quality" ]]; then
            current_deliverable_quality="$(strip_quotes "$value")"
          fi
        elif [[ "$current_item_type" == "obligations" ]]; then
          if [[ "$key" == "id" ]]; then
            current_obligation_id="$(strip_quotes "$value")"
          fi
        fi
      fi

      continue
    fi
  done <"$file"

  finalize_item

  if [[ -z "$intent_quality" ]]; then
    fail_error "missing intent.deliverable_quality" "AW-E211"
  fi
}

parse_contract "$contract_file"

intent_quality_rank_val="$(quality_rank "$intent_quality")"
if [[ "$intent_quality_rank_val" -lt 0 ]]; then
  fail_error "invalid intent.deliverable_quality: '${intent_quality}'" "AW-E212"
fi

max_deliverable_rank=-1
if [[ "$deliverables_key_present" == true ]]; then
  if [[ ${#DELIVERABLE_IDS[@]} -eq 0 ]]; then
    # key present but empty list => ok
    :
  else
    i=0
    for ((i=0; i<${#DELIVERABLE_QUALITIES[@]}; i++)); do
      q="${DELIVERABLE_QUALITIES[$i]}"
      r=""
      r="$(quality_rank "$q")"
      if [[ "$r" -eq -1 ]]; then
        r="$intent_quality_rank_val"
      fi
      if [[ "$r" -lt 0 ]]; then
        fail_error "invalid deliverables[].quality: '${q}'" "AW-E213"
      fi
      if [[ "$r" -gt "$max_deliverable_rank" ]]; then
        max_deliverable_rank="$r"
      fi
    done
  fi
fi

effective_rank="$intent_quality_rank_val"
if [[ "$max_deliverable_rank" -gt "$effective_rank" ]]; then
  effective_rank="$max_deliverable_rank"
fi

weak_phrases=(
  "only scaffold"
  "scaffold only"
  "structure-only"
  "structure only"
  "no semantic validation"
  "do not validate semantics"
  "skip semantic validation"
  "skip semantic acceptance"
  "no correctness guarantee"
  "correctness not guaranteed"
)

scan_markdown_blocks() {
  local file="$1"
  local scan_non_goals="$2"
  local scan_verification="$3"

  local lineno=0
  local in_block=false
  local block_type=""
  local block_level=0
  local in_fence=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))

    if [[ "$line" =~ $FENCE_RE ]]; then
      if [[ "$in_fence" == false ]]; then
        in_fence=true
      else
        in_fence=false
      fi
      continue
    fi

    if [[ "$in_fence" == true ]]; then
      continue
    fi

    if [[ "$line" =~ $BLOCKQUOTE_RE ]]; then
      continue
    fi

    if [[ "$line" =~ ^(#{1,6})[[:space:]]*(.*)$ ]]; then
      local hashes="${BASH_REMATCH[1]}"
      local text="${BASH_REMATCH[2]}"
      local level="${#hashes}"
      local text_trimmed
      text_trimmed="$(trim_value "$text")"

      if [[ "$in_block" == true && "$level" -le "$block_level" ]]; then
        in_block=false
        block_type=""
        block_level=0
      fi

      local text_lower
      text_lower="$(to_lower "$text_trimmed")"

      if [[ "$scan_non_goals" == true ]]; then
        if [[ "$text_lower" =~ ^non-goals([[:space:]]|$) ]]; then
          in_block=true
          block_type="non_goals"
          block_level="$level"
          continue
        fi
      fi

      if [[ "$scan_verification" == true ]]; then
        if [[ "$text_lower" =~ ^verification([[:space:]]|$) ]] || [[ "$text_lower" =~ ^validation([[:space:]]|$) ]]; then
          in_block=true
          block_type="verification"
          block_level="$level"
          continue
        fi
      fi

      continue
    fi

    if [[ "$in_block" != true ]]; then
      continue
    fi

    local excerpt
    excerpt="$(trim_value "$line")"
    local line_lower
    line_lower="$(to_lower "$line")"

    if [[ "$block_type" == "non_goals" ]]; then
      # AW-F003 / AW-W003 id references
      local ids
      ids="$(printf '%s\n' "$line" | grep -oE '[OD]-[0-9]{3,}' 2>/dev/null | sort -u || true)"
      if [[ -n "$ids" ]]; then
        while IFS= read -r id; do
          [[ -n "$id" ]] || continue
          if list_contains "$id" "${OBLIGATION_IDS[@]}" || list_contains "$id" "${DELIVERABLE_IDS[@]}"; then
            add_violation "AW-F003" "block" "$file" "$lineno" "$excerpt" "Do not declare contract obligations/deliverables as out of scope inside Non-Goals. If you must weaken scope, record an explicit decision and update the contract/acceptance accordingly."
          else
            add_violation "AW-W003" "warn" "$file" "$lineno" "$excerpt" "Verify whether this ID is an example or a typo. If it's an example, move it into a code fence or a blockquote; if it's real, align it with the contract."
          fi
        done <<<"$ids"
      fi
    fi

    # Weak phrases (AW-F001/AW-F002)
    if [[ "$effective_rank" -ge 2 ]]; then
      local phrase
      for phrase in "${weak_phrases[@]}"; do
        local phrase_lower
        phrase_lower="$(to_lower "$phrase")"
        if [[ "$line_lower" == *"$phrase_lower"* ]]; then
          if [[ "$block_type" == "non_goals" ]]; then
            add_violation "AW-F001" "block" "$file" "$lineno" "$excerpt" "When the contract requires complete/operational, Non-Goals must not state scaffold-only / no semantic validation. Either update the narrative to match the contract, or lower the contract quality and align acceptance criteria."
          elif [[ "$block_type" == "verification" ]]; then
            add_violation "AW-F002" "block" "$file" "$lineno" "$excerpt" "When the contract requires complete/operational, Verification must not state scaffold-only / no semantic validation. Either add semantic acceptance/validation, or lower the contract quality."
          fi
          break
        fi
      done
    fi
  done <"$file"
}

if [[ -f "${change_dir}/design.md" ]]; then
  scan_markdown_blocks "${change_dir}/design.md" true false
fi
if [[ -f "${change_dir}/proposal.md" ]]; then
  scan_markdown_blocks "${change_dir}/proposal.md" true false
fi

scan_markdown_blocks "$verification_file" false true

status="$(report_status_from_violations)"
read -r errors_count warnings_count <<<"$(counts_from_violations)"

exit_code=0
case "$status" in
  error) exit_code=2 ;;
  fail) exit_code=1 ;;
  warn|pass) exit_code=0 ;;
esac

if [[ "$exit_code" -eq 2 ]]; then
  # Default no report, unless --out is explicitly provided.
  if [[ "$out_path_explicit" == true ]]; then
    report_file="$(resolve_out_file)"
    write_report "$status" "$exit_code" "$report_file" "$errors_count" "$warnings_count"
  fi
  exit 2
fi

report_file="$(resolve_out_file)"
write_report "$status" "$exit_code" "$report_file" "$errors_count" "$warnings_count"
exit "$exit_code"
