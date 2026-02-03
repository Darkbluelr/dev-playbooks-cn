#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-completion-contract.sh <change-id> [options]

Description:
  Validate completion.contract.yaml for a change package and write a gate log.

Arguments:
  change-id               Change package ID.

Options:
  --project-root <dir>    Project root directory (default: DEVBOOKS_PROJECT_ROOT or pwd)
  --change-root <dir>     Change root directory (default: DEVBOOKS_CHANGE_ROOT or changes)
  -h, --help              Show this help message

Examples:
  check-completion-contract.sh 20260129-1312-add-check-completion-contract \
    --project-root /path/to/repo \
    --change-root dev-playbooks/changes
EOF
}

errorf() {
  # errorf "<summary>" "<location>" "<expected>" "<actual>" "<fix>"
  local summary="${1:-}"
  local location="${2:-}"
  local expected="${3:-}"
  local actual="${4:-}"
  local fix="${5:-}"

  if [[ -z "$location" ]]; then
    location="<unknown>"
  fi
  if [[ -z "$expected" ]]; then
    expected="<unspecified>"
  fi
  if [[ -z "$actual" ]]; then
    actual="<unspecified>"
  fi
  if [[ -z "$fix" ]]; then
    fix="<unspecified>"
  fi

  printf '%s\n' "ERROR: ${summary}" >&2
  printf '%s\n' "  Location: ${location}" >&2
  printf '%s\n' "  Expected: ${expected}" >&2
  printf '%s\n' "  Actual: ${actual}" >&2
  printf '%s\n' "  Fix: ${fix}" >&2
}

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_quotes() {
  local value="$1"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  printf '%s' "$value"
}

normalize_scalar() {
  local value
  value="$(trim_value "$1")"
  value="$(strip_quotes "$value")"
  printf '%s' "$value"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

join_errors() {
  local IFS=";"
  printf '%s' "${errors[*]}"
}

if [[ $# -eq 0 ]]; then
  errorf "missing change-id" "" "non-empty <change-id>" "none" "pass <change-id> as the first argument"
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_id="$1"
shift

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  errorf "invalid change-id" "" "non-empty change-id without leading '-'" "$change_id" "pass a valid <change-id>"
  exit 2
fi

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-root)
      if [[ -z "${2:-}" ]]; then
        errorf "missing value for --project-root" "" "path argument" "empty" "provide --project-root <dir>"
        exit 2
      fi
      project_root="$2"
      shift 2
      ;;
    --change-root)
      if [[ -z "${2:-}" ]]; then
        errorf "missing value for --change-root" "" "path argument" "empty" "provide --change-root <dir>"
        exit 2
      fi
      change_root="$2"
      shift 2
      ;;
    *)
      errorf "unknown option" "skills/devbooks-delivery-workflow/scripts/check-completion-contract.sh" \
        "known options (see --help)" "$1" "rerun with --help"
      exit 2
      ;;
  esac
done

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_root_dir="$change_root"
else
  change_root_dir="${project_root}/${change_root}"
fi

change_dir="${change_root_dir}/${change_id}"
contract_path="${change_dir}/completion.contract.yaml"
log_path="${change_dir}/evidence/gates/check-completion-contract.log"

mkdir -p "${change_dir}/evidence/gates"

logical_change_id="$change_id"
if [[ "$change_id" == archive/* ]]; then
  logical_change_id="${change_id#archive/}"
fi

errors=()
first_error_summary=""
first_error_location=""
first_error_expected=""
first_error_actual=""
first_error_fix=""

add_error() {
  local code="$1"
  local summary="$2"
  local location="$3"
  local expected="$4"
  local actual="$5"
  local fix="$6"

  errors+=("$code")
  if [[ -z "$first_error_summary" ]]; then
    first_error_summary="$summary"
    first_error_location="$location"
    first_error_expected="$expected"
    first_error_actual="$actual"
    first_error_fix="$fix"
  fi
}

write_log() {
  local status="$1"
  local errors_joined="$2"
  local errors_count="$3"
  {
    printf 'run_at=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    printf 'status=%s\n' "$status"
    printf 'change_id=%s\n' "$change_id"
    printf 'contract_path=%s\n' "$contract_path"
    printf 'errors_count=%s\n' "$errors_count"
    printf 'errors=%s\n' "$errors_joined"
  } >"$log_path"
}

fail_and_exit() {
  local errors_joined
  errors_joined="$(join_errors)"
  write_log "fail" "$errors_joined" "${#errors[@]}"
  errorf "$first_error_summary" "$first_error_location" "$first_error_expected" "$first_error_actual" "$first_error_fix"
  exit 1
}

key_location() {
  local pattern="$1"
  local match
  if match=$(grep -nE "$pattern" "$contract_path" | head -n 1); then
    if [[ -n "$match" ]]; then
      printf '%s:%s' "$contract_path" "${match%%:*}"
      return 0
    fi
  fi
  printf '%s' "$contract_path"
}

yaml_violation_location=""
yaml_violation_actual=""
yaml_violation_expected="block-style YAML with 2-space indentation and no tabs/flow/anchors/merge/multiline scalars"
yaml_violation_fix="rewrite completion.contract.yaml to the supported YAML subset"

set_yaml_violation() {
  local match="$1"
  local line_no="${match%%:*}"
  local line_text="${match#*:}"
  yaml_violation_location="${contract_path}:${line_no}"
  yaml_violation_actual="$(trim_value "$line_text")"
}

validate_yaml_subset() {
  local match=""

  if match=$(grep -n $'\t' "$contract_path" | head -n 1); then
    if [[ -n "$match" ]]; then
      set_yaml_violation "$match"
      return 1
    fi
  fi

  local first_line=""
  first_line="$(awk 'NF { print; exit }' "$contract_path" 2>/dev/null || true)"
  if [[ "$first_line" == "---" || "$first_line" == "..." ]]; then
    yaml_violation_location="${contract_path}:1"
    yaml_violation_actual="$first_line"
    return 1
  fi

  if match=$(grep -nE '\{[^}]*\}|\[[^]]*\]' "$contract_path" | head -n 1); then
    if [[ -n "$match" ]]; then
      set_yaml_violation "$match"
      return 1
    fi
  fi

  if match=$(grep -nE '<<:' "$contract_path" | head -n 1); then
    if [[ -n "$match" ]]; then
      set_yaml_violation "$match"
      return 1
    fi
  fi

  if match=$(grep -nE '(^[[:space:]]*[|>])|(:[[:space:]]*[|>])' "$contract_path" | head -n 1); then
    if [[ -n "$match" ]]; then
      set_yaml_violation "$match"
      return 1
    fi
  fi

  if match=$(grep -nE '(^|[[:space:]])[&*][A-Za-z0-9_-]+' "$contract_path" | head -n 1); then
    if [[ -n "$match" ]]; then
      set_yaml_violation "$match"
      return 1
    fi
  fi

  if match=$(awk '
    match($0, /^[ ]+/) {
      if (RLENGTH % 2 != 0) {
        print NR ":" $0
        exit 0
      }
    }
    END { exit 1 }
  ' "$contract_path"); then
    if [[ -n "$match" ]]; then
      set_yaml_violation "$match"
      return 1
    fi
  fi

  return 0
}

yaml_top_value() {
  local key="$1"
  local value=""
  if value=$(awk -v k="$key" '
    $0 ~ "^" k ":[[:space:]]*" {
      sub("^" k ":[[:space:]]*", "", $0)
      print $0
      exit 0
    }
  ' "$contract_path"); then
    printf '%s' "$value"
    return 0
  fi
  return 1
}

intent_value() {
  local key="$1"
  local value=""
  if value=$(awk -v k="$key" '
    $0 ~ "^intent:[[:space:]]*$" { inside=1; next }
    inside {
      if ($0 ~ "^[^[:space:]]") { exit }
      if ($0 ~ "^[[:space:]]+" k ":[[:space:]]*") {
        sub("^[[:space:]]+" k ":[[:space:]]*", "", $0)
        print $0
        found=1
        exit
      }
    }
    END { exit found ? 0 : 1 }
  ' "$contract_path"); then
    printf '%s' "$value"
    return 0
  fi
  return 1
}

decision_lock_value() {
  local value=""
  if value=$(awk '
    $0 ~ "^decision_locks:[[:space:]]*$" { inside=1; next }
    inside {
      if ($0 ~ "^[^[:space:]]") { exit }
      if ($0 ~ "^[[:space:]]+forbid_weakening_without_decision:[[:space:]]*") {
        sub("^[[:space:]]+forbid_weakening_without_decision:[[:space:]]*", "", $0)
        print $0
        found=1
        exit
      }
    }
    END { exit found ? 0 : 1 }
  ' "$contract_path"); then
    printf '%s' "$value"
    return 0
  fi
  return 1
}

section_has_id() {
  local section="$1"
  if awk -v s="$section" '
    $0 ~ "^" s ":[[:space:]]*$" { inside=1; next }
    inside {
      if ($0 ~ "^[^[:space:]]") { exit }
      if ($0 ~ "^[[:space:]]*- id:[[:space:]]*") { found=1; exit }
    }
    END { exit found ? 0 : 1 }
  ' "$contract_path"; then
    return 0
  fi
  return 1
}

if [[ ! -f "$contract_path" ]]; then
  add_error "missing_contract" \
    "completion.contract.yaml not found" \
    "$contract_path" \
    "file exists at ${contract_path}" \
    "missing" \
    "create completion.contract.yaml under the change directory"
  fail_and_exit
fi

if ! validate_yaml_subset; then
  add_error "invalid_yaml_subset" \
    "unsupported YAML subset" \
    "$yaml_violation_location" \
    "$yaml_violation_expected" \
    "$yaml_violation_actual" \
    "$yaml_violation_fix"
  fail_and_exit
fi

schema_location="$(key_location '^schema_version:[[:space:]]*')"
if grep -qE '^schema_version:[[:space:]]*' "$contract_path"; then
  schema_raw="$(yaml_top_value 'schema_version' || true)"
  schema_value="$(normalize_scalar "$schema_raw")"
  if [[ "$schema_value" != "1.0.0" ]]; then
    add_error "invalid_schema_version" \
      "schema_version must be 1.0.0" \
      "$schema_location" \
      "schema_version: 1.0.0" \
      "${schema_value:-<empty>}" \
      "set schema_version to 1.0.0"
  fi
else
  add_error "missing_schema_version" \
    "schema_version is missing" \
    "$schema_location" \
    "schema_version: 1.0.0" \
    "missing" \
    "add schema_version: 1.0.0"
fi

change_location="$(key_location '^change_id:[[:space:]]*')"
if grep -qE '^change_id:[[:space:]]*' "$contract_path"; then
  change_raw="$(yaml_top_value 'change_id' || true)"
  change_value="$(normalize_scalar "$change_raw")"
  if [[ "$change_value" != "$logical_change_id" ]]; then
    add_error "change_id_mismatch" \
      "change_id does not match change-id argument" \
      "$change_location" \
      "$logical_change_id" \
      "${change_value:-<empty>}" \
      "set change_id to ${logical_change_id}"
  fi
else
  add_error "change_id_mismatch" \
    "change_id is missing" \
    "$change_location" \
    "$logical_change_id" \
    "missing" \
    "add change_id: ${logical_change_id}"
fi

summary_location="$(key_location '^[[:space:]]+summary:[[:space:]]*')"
if summary_raw="$(intent_value 'summary')"; then
  summary_value="$(normalize_scalar "$summary_raw")"
  if [[ -z "$summary_value" ]]; then
    add_error "missing_intent_summary" \
      "intent.summary is empty" \
      "$summary_location" \
      "non-empty summary" \
      "<empty>" \
      "set intent.summary to a non-empty string"
  fi
else
  add_error "missing_intent_summary" \
    "intent.summary is missing" \
    "$summary_location" \
    "intent.summary with non-empty value" \
    "missing" \
    "add intent.summary under intent"
fi

quality_location="$(key_location '^[[:space:]]+deliverable_quality:[[:space:]]*')"
if quality_raw="$(intent_value 'deliverable_quality')"; then
  quality_value="$(normalize_scalar "$quality_raw")"
  case "$quality_value" in
    outline|draft|complete|operational)
      ;;
    *)
      add_error "invalid_deliverable_quality" \
        "intent.deliverable_quality is invalid" \
        "$quality_location" \
        "outline|draft|complete|operational" \
        "${quality_value:-<empty>}" \
        "set intent.deliverable_quality to an allowed value"
      ;;
  esac
else
  add_error "invalid_deliverable_quality" \
    "intent.deliverable_quality is missing" \
    "$quality_location" \
    "outline|draft|complete|operational" \
    "missing" \
    "add intent.deliverable_quality under intent"
fi

if ! section_has_id "deliverables"; then
  add_error "empty_deliverables" \
    "deliverables list missing '- id:' entry" \
    "$(key_location '^deliverables:[[:space:]]*$')" \
    "deliverables list with at least one '- id:' entry" \
    "missing '- id:'" \
    "add deliverables entries with - id:"
fi

if ! section_has_id "obligations"; then
  add_error "empty_obligations" \
    "obligations list missing '- id:' entry" \
    "$(key_location '^obligations:[[:space:]]*$')" \
    "obligations list with at least one '- id:' entry" \
    "missing '- id:'" \
    "add obligations entries with - id:"
fi

if ! section_has_id "checks"; then
  add_error "empty_checks" \
    "checks list missing '- id:' entry" \
    "$(key_location '^checks:[[:space:]]*$')" \
    "checks list with at least one '- id:' entry" \
    "missing '- id:'" \
    "add checks entries with - id:"
fi

decision_location="$(key_location '^[[:space:]]+forbid_weakening_without_decision:[[:space:]]*')"
if decision_raw="$(decision_lock_value)"; then
  decision_value="$(normalize_scalar "$decision_raw")"
  decision_value_lower="$(to_lower "$decision_value")"
  if [[ "$decision_value_lower" != "true" ]]; then
    add_error "invalid_decision_lock" \
      "decision_locks.forbid_weakening_without_decision must be true" \
      "$decision_location" \
      "true" \
      "${decision_value:-<empty>}" \
      "set forbid_weakening_without_decision to true"
  fi
else
  add_error "invalid_decision_lock" \
    "decision_locks.forbid_weakening_without_decision is missing" \
    "$decision_location" \
    "true" \
    "missing" \
    "add decision_locks.forbid_weakening_without_decision: true"
fi

if (( ${#errors[@]} > 0 )); then
  fail_and_exit
fi

write_log "pass" "" "0"
exit 0
