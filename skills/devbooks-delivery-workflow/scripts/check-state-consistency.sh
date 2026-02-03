#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: check-state-consistency.sh <change-id> [options]

Check state consistency (closure) for a change package.

Trigger:
  - When state is "completed" or "archived" (from proposal.md front matter),
    OR when explicitly overridden via --state.

Blocking rules (minimal set, low false-positive):
  - proposal decision is not Approved
  - verification Status is Draft/Ready
  - traceability matrix contains TODO/TBD/Pending/Draft
  - MANUAL-* checklist contains unchecked items

Options:
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory (default: specs)
  --state <state>        Override state (useful for replay/dry checks)
  --proposal <path>      Override proposal file path (default: proposal.md in change dir)
  --verification <path>  Override verification file path (default: verification.md in change dir)
  --out <path>           Output report path (default: evidence/gates/state-consistency-check.json in change dir)
  -h, --help             Show this help message

Exit codes:
  0 - pass or skip (not in completed/archived state)
  1 - fail (blockers found)
  2 - usage error (invalid args)
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

state_override=""
proposal_override=""
verification_override=""
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
    --state)
      state_override="${2:-}"
      shift 2
      ;;
    --proposal)
      proposal_override="${2:-}"
      shift 2
      ;;
    --verification)
      verification_override="${2:-}"
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

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

change_dir="${change_root_dir}/${change_id}"
if [[ ! -d "$change_dir" ]]; then
  errorf "missing change directory" "" "directory exists" "$change_dir" "check --change-root/--project-root and change-id"
  exit 1
fi

mkdir -p "${change_dir}/evidence/gates"

if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
else
  out_file="${change_dir}/evidence/gates/state-consistency-check.json"
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
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

to_relpath() {
  local p="$1"
  if [[ "$p" == "${project_root}/"* ]]; then
    printf '%s' "${p#${project_root}/}"
    return 0
  fi
  printf '%s' "$p"
}

resolve_path_project_root() {
  local p="$1"
  if [[ -z "$p" ]]; then
    printf '%s' ""
    return 0
  fi
  if [[ "$p" = /* ]]; then
    printf '%s' "$p"
    return 0
  fi
  p="${p#/}"
  printf '%s' "${project_root}/${p}"
}

proposal_file=""
verification_file=""

if [[ -n "$proposal_override" ]]; then
  proposal_file="$(resolve_path_project_root "$proposal_override")"
else
  proposal_file="${change_dir}/proposal.md"
fi

if [[ -n "$verification_override" ]]; then
  verification_file="$(resolve_path_project_root "$verification_override")"
else
  verification_file="${change_dir}/verification.md"
fi

extract_front_matter() {
  local file="$1"
  awk '
    NR==1 && $0 ~ /^---/ { in=1; next }
    in && $0 ~ /^---/ { exit }
    in { print }
  ' "$file" 2>/dev/null || true
}

front_matter_value() {
  local key="$1"
  local front="$2"
  printf '%s\n' "$front" | awk -v k="$key" '
    $0 ~ "^[[:space:]]*" k ":[[:space:]]*" {
      line=$0
      sub("^[[:space:]]*" k ":[[:space:]]*", "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      print line
      exit
    }
  ' || true
}

decision_status_from_proposal() {
  local file="$1"
  local pattern='^- (Decision Status|Decision|决策状态|决策)[:：] *(Pending|Approved|Revise|Rejected)([[:space:]]|$)'
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$file" -m 1 2>/dev/null | sed -E 's/^[0-9]+:- (Decision Status|Decision|决策状态|决策)[:：] *//'
    return 0
  fi
  grep -nE "$pattern" "$file" 2>/dev/null | head -n 1 | sed -E 's/^[0-9]+:- (Decision Status|Decision|决策状态|决策)[:：] *//'
}

verification_status_from_file() {
  local file="$1"
  local pattern='^- Status[:：] *(Draft|Ready|Done|Archived)([[:space:]]|$)'
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$file" -m 1 2>/dev/null | sed -E 's/^[0-9]+:- Status[:：] *//'
    return 0
  fi
  grep -nE "$pattern" "$file" 2>/dev/null | head -n 1 | sed -E 's/^[0-9]+:- Status[:：] *//'
}

write_report() {
  local status="$1"
  local triggered="$2"
  local state_observed="$3"
  local blockers_json="$4"
  local next_action="$5"
  local note="$6"

  {
    printf '{'
    printf '"schema_version":1,'
    printf '"check_id":"state-consistency-check",'
    printf '"change_id":"%s",' "$(json_escape "$change_id")"
    printf '"status":"%s",' "$(json_escape "$status")"
    printf '"generated_at":"%s",' "$(json_escape "$(date -Iseconds)")"
    printf '"truth_root":"%s",' "$(json_escape "$(to_relpath "$truth_dir")")"
    printf '"state_observed":"%s",' "$(json_escape "$state_observed")"
    printf '"triggered":%s,' "$triggered"
    printf '"proposal_file":"%s",' "$(json_escape "$(to_relpath "$proposal_file")")"
    printf '"verification_file":"%s",' "$(json_escape "$(to_relpath "$verification_file")")"
    printf '"blockers":%s,' "$blockers_json"
    printf '"note":"%s",' "$(json_escape "$note")"
    printf '"next_action":"%s"' "$(json_escape "$next_action")"
    printf '}\n'
  } >"$out_file"
}

if [[ ! -f "$proposal_file" ]]; then
  blockers="[{\"kind\":\"missing_file\",\"file\":\"$(json_escape "$(to_relpath "$proposal_file")")\",\"fix_suggestion\":\"restore proposal.md\"}]"
  write_report "fail" "true" "unknown" "$blockers" "DevBooks" "proposal.md missing"
  echo "fail: proposal.md missing" >&2
  exit 1
fi

state_value=""
if [[ -n "$state_override" ]]; then
  state_value="$(to_lower "$(trim_value "$state_override")")"
else
  fm="$(extract_front_matter "$proposal_file")"
  state_raw="$(front_matter_value "state" "$fm")"
  state_value="$(to_lower "$(trim_value "$state_raw")")"
fi

if [[ "$state_value" != "completed" && "$state_value" != "archived" ]]; then
  write_report "skip" "false" "$state_value" "[]" "DevBooks" "not in completed/archived state"
  echo "info: skip (state=${state_value})"
  exit 0
fi

declare -a blockers=()

decision_status="$(trim_value "$(decision_status_from_proposal "$proposal_file" || true)")"
if [[ -z "$decision_status" ]]; then
  blockers+=("{\"kind\":\"missing_decision_status\",\"file\":\"$(json_escape "$(to_relpath "$proposal_file")")\",\"fix_suggestion\":\"add '- Decision Status: Approved' in proposal.md\"}")
elif [[ "$decision_status" != "Approved" ]]; then
  blockers+=("{\"kind\":\"decision_not_approved\",\"file\":\"$(json_escape "$(to_relpath "$proposal_file")")\",\"actual\":\"$(json_escape "$decision_status")\",\"fix_suggestion\":\"set proposal decision status to Approved before marking state=${state_value}\"}")
fi

if [[ ! -f "$verification_file" ]]; then
  blockers+=("{\"kind\":\"missing_file\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"fix_suggestion\":\"restore verification.md\"}")
else
  vstatus="$(trim_value "$(verification_status_from_file "$verification_file" || true)")"
  if [[ -z "$vstatus" ]]; then
    blockers+=("{\"kind\":\"missing_verification_status\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"fix_suggestion\":\"add '- Status: Done' in verification.md metadata\"}")
  elif [[ "$vstatus" == "Draft" || "$vstatus" == "Ready" ]]; then
    blockers+=("{\"kind\":\"verification_not_done\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"actual\":\"$(json_escape "$vstatus")\",\"fix_suggestion\":\"Reviewer sets Status to Done before state=${state_value}\"}")
  fi

  # Traceability matrix unresolved statuses
  trace_pattern='^[|][[:space:]]*AC-[0-9]{3}[[:space:]]*[|].*[|][[:space:]]*(TBD|Pending|Draft|TODO)[[:space:]]*[|]'
  if command -v rg >/dev/null 2>&1; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      line_no="${line%%:*}"
      row="${line#*:}"
      blockers+=("{\"kind\":\"trace_matrix_unclosed\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"line\":${line_no},\"excerpt\":\"$(json_escape "$(trim_value "$row")")\",\"fix_suggestion\":\"resolve trace matrix status to pass and remove TODO/TBD/Pending/Draft\"}")
    done < <(rg -n "$trace_pattern" "$verification_file" 2>/dev/null || true)
  else
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      line_no="${line%%:*}"
      row="${line#*:}"
      blockers+=("{\"kind\":\"trace_matrix_unclosed\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"line\":${line_no},\"excerpt\":\"$(json_escape "$(trim_value "$row")")\",\"fix_suggestion\":\"resolve trace matrix status to pass and remove TODO/TBD/Pending/Draft\"}")
    done < <(grep -nE "$trace_pattern" "$verification_file" 2>/dev/null || true)
  fi

  # MANUAL-* checklist unclosed items
  manual_pattern='^- \\[ \\] MANUAL-[0-9]{3}([[:space:]]|$)'
  if command -v rg >/dev/null 2>&1; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      line_no="${line%%:*}"
      item="${line#*:}"
      blockers+=("{\"kind\":\"manual_unclosed\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"line\":${line_no},\"excerpt\":\"$(json_escape "$(trim_value "$item")")\",\"fix_suggestion\":\"complete and sign off MANUAL checklist items before state=${state_value}\"}")
    done < <(rg -n "$manual_pattern" "$verification_file" 2>/dev/null || true)
  else
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      line_no="${line%%:*}"
      item="${line#*:}"
      blockers+=("{\"kind\":\"manual_unclosed\",\"file\":\"$(json_escape "$(to_relpath "$verification_file")")\",\"line\":${line_no},\"excerpt\":\"$(json_escape "$(trim_value "$item")")\",\"fix_suggestion\":\"complete and sign off MANUAL checklist items before state=${state_value}\"}")
    done < <(grep -nE "$manual_pattern" "$verification_file" 2>/dev/null || true)
  fi
fi

if (( ${#blockers[@]} > 0 )); then
  blockers_json="[$(IFS=','; printf '%s' "${blockers[*]}")]"
  write_report "fail" "true" "$state_value" "$blockers_json" "close-items" "state consistency blockers detected"
  echo "fail: state consistency blockers detected (${#blockers[@]} blocker(s))" >&2
  exit 1
fi

write_report "pass" "true" "$state_value" "[]" "DevBooks" "no blockers detected for completed/archived state"
echo "ok: state consistency passed"
exit 0
