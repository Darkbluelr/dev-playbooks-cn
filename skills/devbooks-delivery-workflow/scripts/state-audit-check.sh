#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: state-audit-check.sh <change-id> [options]

Validate state.audit.yaml (state machine transitions + evidence requirements).

This check is designed to enforce "abnormal transition constraints":
  - no jump transitions (must be auditable)
  - abnormal states require reason (+ rollback requires evidence)
  - archive cannot be reached directly from pending/failed/rollback/etc

Options:
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory (default: specs)
  --out <path>           Output report path (default: evidence/gates/state-audit-check.json)
  -h, --help             Show this help message

Exit codes:
  0 - pass
  1 - fail
  2 - usage error
EOF
}

errorf() {
  # errorf "<summary>" "<location>" "<expected>" "<actual>" "<fix>"
  local summary="${1:-}"
  local location="${2:-}"
  local expected="${3:-}"
  local actual="${4:-}"
  local fix="${5:-}"

  printf '%s\n' "ERROR: ${summary}" >&2
  [[ -n "$location" ]] && printf '%s\n' "  Location: ${location}" >&2
  [[ -n "$expected" ]] && printf '%s\n' "  Expected: ${expected}" >&2
  [[ -n "$actual" ]] && printf '%s\n' "  Actual: ${actual}" >&2
  [[ -n "$fix" ]] && printf '%s\n' "  Fix: ${fix}" >&2
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
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
out_path=""

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
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    *)
      errorf "unknown option" "" "known options (see --help)" "$1" "rerun with --help"
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  errorf "invalid change-id" "" "non-empty change-id without leading '-'" "$change_id" "pass a valid <change-id>"
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"
truth_root="${truth_root%/}"

if [[ "$change_root" = /* ]]; then
  change_root_dir="$change_root"
else
  change_root_dir="${project_root}/${change_root}"
fi

change_dir="${change_root_dir}/${change_id}"
if [[ ! -d "$change_dir" ]]; then
  errorf "missing change directory" "" "directory exists" "$change_dir" "check --change-root/--project-root and change-id"
  exit 1
fi

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/state-audit-check.json"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
fi

audit_file="${change_dir}/state.audit.yaml"

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
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

json_array() {
  local first=1
  local item
  printf '['
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then
      printf ','
    fi
    first=0
    printf '"%s"' "$(json_escape "$item")"
  done
  printf ']'
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

allowed_states="pending in_progress review completed archived blocked failed rollback suspended cancelled"

is_allowed_state() {
  local s="$1"
  local t
  for t in $allowed_states; do
    if [[ "$t" == "$s" ]]; then
      return 0
    fi
  done
  return 1
}

is_allowed_transition() {
  local from="$1"
  local to="$2"
  case "${from}->${to}" in
    "pending->in_progress") return 0 ;;
    "in_progress->review") return 0 ;;
    "in_progress->completed") return 0 ;;
    "in_progress->blocked") return 0 ;;
    "in_progress->failed") return 0 ;;
    "in_progress->rollback") return 0 ;;
    "in_progress->suspended") return 0 ;;
    "in_progress->cancelled") return 0 ;;
    "review->in_progress") return 0 ;;
    "review->completed") return 0 ;;
    "review->blocked") return 0 ;;
    "review->failed") return 0 ;;
    "review->rollback") return 0 ;;
    "blocked->in_progress") return 0 ;;
    "blocked->cancelled") return 0 ;;
    "failed->in_progress") return 0 ;;
    "failed->cancelled") return 0 ;;
    "suspended->in_progress") return 0 ;;
    "suspended->cancelled") return 0 ;;
    "rollback->in_progress") return 0 ;;
    "rollback->cancelled") return 0 ;;
    "completed->archived") return 0 ;;
    *) return 1 ;;
  esac
}

checks=("state-audit-file")
artifacts=()
failure_reasons=()

if [[ ! -f "$audit_file" ]]; then
  failure_reasons+=("missing state.audit.yaml: ${audit_file}")
else
  artifacts+=("state.audit.yaml")
fi

if [[ -f "$audit_file" ]]; then
  checks+=("state-machine")
  prev_to=""
  entry_index=-1

  current_from=""
  current_to=""
  current_reason=""
  current_evidence=()

  flush_entry() {
    if [[ $entry_index -lt 0 ]]; then
      return 0
    fi

    if [[ -z "$current_to" ]]; then
      failure_reasons+=("entry missing to_state (index=${entry_index})")
      return 0
    fi

    if [[ "$current_from" != "null" && -n "$current_from" ]]; then
      if ! is_allowed_state "$current_from"; then
        failure_reasons+=("entry invalid from_state (index=${entry_index}): ${current_from}")
      fi
    fi

    if ! is_allowed_state "$current_to"; then
      failure_reasons+=("entry invalid to_state (index=${entry_index}): ${current_to}")
    fi

    # No jump: current_from must equal previous to_state (except first entry / from_state=null)
    if [[ -n "$prev_to" && "$current_from" != "$prev_to" ]]; then
      failure_reasons+=("jump transition detected (index=${entry_index}): prev_to=${prev_to}, entry.from_state=${current_from}")
    fi

    # Allowed edge (skip for first entry with from_state=null)
    if [[ -n "$prev_to" && -n "$current_to" ]]; then
      if ! is_allowed_transition "$prev_to" "$current_to"; then
        failure_reasons+=("invalid state transition: ${prev_to} -> ${current_to} (index=${entry_index})")
      fi
    fi

    # Abnormal states require reason
    case "$current_to" in
      blocked|failed|rollback|suspended|cancelled)
        if [[ -z "$(trim "${current_reason:-}")" ]]; then
          failure_reasons+=("abnormal state requires reason: to_state=${current_to} (index=${entry_index})")
        fi
        ;;
    esac

    # Rollback requires evidence
    if [[ "$current_to" == "rollback" ]]; then
      if [[ ${#current_evidence[@]} -eq 0 ]]; then
        failure_reasons+=("rollback entry requires evidence_refs (index=${entry_index})")
      fi
      for ev in "${current_evidence[@]}"; do
        [[ -n "$ev" ]] || continue
        ev_abs="${change_dir}/${ev}"
        if [[ ! -f "$ev_abs" ]]; then
          failure_reasons+=("rollback evidence_ref missing: ${ev_abs} (index=${entry_index})")
        else
          artifacts+=("${ev}")
        fi
      done
    fi

    prev_to="$current_to"
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Start of a new entry
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*from_state:[[:space:]]*(.*)$ ]]; then
      flush_entry
      entry_index=$((entry_index + 1))
      current_from="$(trim "${BASH_REMATCH[1]}")"
      current_from="${current_from//\"/}"
      current_from="${current_from//\'/}"
      current_to=""
      current_reason=""
      current_evidence=()
      continue
    fi

    if [[ "$entry_index" -lt 0 ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*to_state:[[:space:]]*(.*)$ ]]; then
      current_to="$(trim "${BASH_REMATCH[1]}")"
      current_to="${current_to//\"/}"
      current_to="${current_to//\'/}"
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*reason:[[:space:]]*(.*)$ ]]; then
      current_reason="$(trim "${BASH_REMATCH[1]}")"
      current_reason="${current_reason#\"}"
      current_reason="${current_reason%\"}"
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*evidence_refs:[[:space:]]*\\[\\][[:space:]]*$ ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*([^[:space:]].*)$ ]]; then
      # evidence_refs list item (only when evidence_refs section is active by indentation)
      if [[ "$line" =~ ^[[:space:]]{6}-[[:space:]]*([^[:space:]].*)$ ]]; then
        ev="$(trim "${BASH_REMATCH[1]}")"
        ev="${ev#\"}"
        ev="${ev%\"}"
        [[ -n "$ev" ]] && current_evidence+=("$ev")
      fi
    fi
  done <"$audit_file"

  flush_entry

  if [[ $entry_index -lt 0 ]]; then
    failure_reasons+=("state.audit.yaml has no entries")
  fi
fi

status="pass"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  status="fail"
fi

checks_json="$(json_array "${checks[@]}")"
artifacts_json="[]"
if [[ ${#artifacts[@]} -gt 0 ]]; then
  artifacts_json="$(json_array "${artifacts[@]}")"
fi
reasons_json="[]"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  reasons_json="$(json_array "${failure_reasons[@]}")"
fi

tmp="${out_file}.tmp.$$"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G0",
  "mode": "strict",
  "check_id": "state-audit-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${reasons_json},
  "next_action": "DevBooks"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "state audit check failed" "$out_file" "status=pass" "status=${status}" "fix state.audit.yaml transitions/evidence"
  printf '%s\n' "${failure_reasons[@]}" >&2
  exit 1
fi

exit 0
