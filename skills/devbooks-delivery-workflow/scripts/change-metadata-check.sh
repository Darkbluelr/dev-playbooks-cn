#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-metadata-check.sh <change-id> [options]

Validate machine-readable change metadata (proposal.md front matter) and
bootstrap baseline presence.

This script is designed to back G0:
  - required metadata fields exist and are consistent
  - abnormal states require state_reason
  - archive/strict semantics require completion_contract + deliverable_quality
  - deliverable_quality must match completion.contract.yaml intent
  - truth baseline missing => next_action=Bootstrap (blocking)

Options:
  --mode <proposal|apply|review|archive|strict>   Mode for enforcement (default: strict)
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory (default: specs)
  --out <path>           Output report path (default: evidence/gates/change-metadata-check.json)
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

mode="strict"
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
    --mode)
      mode="${2:-}"
      shift 2
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

case "$mode" in
  proposal|apply|review|archive|strict) ;;
  *)
    errorf "invalid --mode" "" "proposal|apply|review|archive|strict" "$mode" "rerun with --help"
    exit 2
    ;;
esac

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

logical_change_id="$change_id"
if [[ "$change_id" == archive/* ]]; then
  logical_change_id="${change_id#archive/}"
fi

proposal_file="${change_dir}/proposal.md"

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/change-metadata-check.json"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
fi

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

extract_front_matter_value() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { in_yaml=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 && $0 ~ ("^" k ":[[:space:]]*") {
      sub(("^" k ":[[:space:]]*"), "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'"'"']|["'"'"']$/, "", $0)
      print $0
      exit
    }
  ' "$file" 2>/dev/null || true
}

has_front_matter_key() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { in_yaml=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 && $0 ~ ("^" k ":[[:space:]]*") { found=1; exit }
    END { exit (found ? 0 : 1) }
  ' "$file" 2>/dev/null
}

read_contract_deliverable_quality() {
  local contract="$1"
  awk '
    BEGIN { in_intent=0 }
    $0 ~ /^intent:[[:space:]]*$/ { in_intent=1; next }
    in_intent && /^[^[:space:]]/ { in_intent=0 }
    in_intent && $0 ~ /^[[:space:]]+deliverable_quality:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]+deliverable_quality:[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      gsub(/["'"'"']/, "", line)
      print line
      exit
    }
  ' "$contract" 2>/dev/null || true
}

is_relpath_safe() {
  local p="$1"
  [[ -n "$p" ]] || return 1
  [[ "$p" != /* ]] || return 1
  [[ "$p" != *".."* ]] || return 1
  [[ "$p" != change://* ]] || return 1
  [[ "$p" != truth://* ]] || return 1
  return 0
}

to_relpath() {
  local p="$1"
  if [[ "$p" == "${project_root}/"* ]]; then
    printf '%s' "${p#"${project_root}"/}"
    return 0
  fi
  printf '%s' "$p"
}

checks=("proposal-front-matter")
artifacts=()
failure_reasons=()
next_action="DevBooks"

if [[ ! -f "$proposal_file" ]]; then
  failure_reasons+=("missing proposal.md: $(to_relpath "$proposal_file")")
else
  artifacts+=("$(to_relpath "$proposal_file")")
fi

schema_version=""
meta_change_id=""
change_type=""
rq_kind=""
risk_level=""
intervention_level=""
state=""
state_reason=""
completion_contract=""
deliverable_quality=""

if [[ -f "$proposal_file" ]]; then
  schema_version="$(extract_front_matter_value "$proposal_file" "schema_version")"
  meta_change_id="$(extract_front_matter_value "$proposal_file" "change_id")"
  rq_kind="$(extract_front_matter_value "$proposal_file" "request_kind")"
  change_type="$(extract_front_matter_value "$proposal_file" "change_type")"
  risk_level="$(extract_front_matter_value "$proposal_file" "risk_level")"
  intervention_level="$(extract_front_matter_value "$proposal_file" "intervention_level")"
  state="$(extract_front_matter_value "$proposal_file" "state")"
  state_reason="$(extract_front_matter_value "$proposal_file" "state_reason")"
  completion_contract="$(extract_front_matter_value "$proposal_file" "completion_contract")"
  deliverable_quality="$(extract_front_matter_value "$proposal_file" "deliverable_quality")"
fi

if [[ -z "$schema_version" ]]; then
  failure_reasons+=("proposal front matter missing schema_version")
elif [[ "$schema_version" != "1.0.0" ]]; then
  failure_reasons+=("proposal schema_version unsupported (expected 1.0.0): ${schema_version}")
fi

if [[ -z "$meta_change_id" ]]; then
  failure_reasons+=("proposal front matter missing change_id")
elif [[ "$meta_change_id" != "$logical_change_id" ]]; then
  failure_reasons+=("proposal change_id mismatch: dir=${change_id}, expected_meta=${logical_change_id}, meta=${meta_change_id}")
fi

if [[ -z "$change_type" ]]; then
  failure_reasons+=("proposal front matter missing change_type")
fi

case "$rq_kind" in
  debug|change|epic|void|bootstrap|governance) ;;
  "") failure_reasons+=("proposal front matter missing request_kind") ;;
  *) failure_reasons+=("proposal request_kind invalid (expected debug|change|epic|void|bootstrap|governance): ${rq_kind}") ;;
esac

case "$risk_level" in
  low|medium|high) ;;
  "") failure_reasons+=("proposal front matter missing risk_level") ;;
  *) failure_reasons+=("proposal risk_level invalid (expected low|medium|high): ${risk_level}") ;;
esac

case "$intervention_level" in
  "") intervention_level="local" ;;
  local|team|org) ;;
  *) failure_reasons+=("proposal intervention_level invalid (expected local|team|org): ${intervention_level}") ;;
esac

allowed_states="pending in_progress review completed archived blocked failed rollback suspended cancelled"
if [[ -z "$state" ]]; then
  failure_reasons+=("proposal front matter missing state")
else
  ok=false
  for s in $allowed_states; do
    if [[ "$s" == "$state" ]]; then
      ok=true
      break
    fi
  done
  if [[ "$ok" != true ]]; then
    failure_reasons+=("proposal state invalid: ${state}")
  fi
fi

case "$state" in
  blocked|failed|rollback|suspended|cancelled)
    if [[ -z "$(trim "${state_reason:-}")" ]]; then
      failure_reasons+=("state_reason required for abnormal state: state=${state}")
    fi
    ;;
esac

# risk_flags MUST exist (can be empty object)
if [[ -f "$proposal_file" ]]; then
  if ! has_front_matter_key "$proposal_file" "risk_flags"; then
    failure_reasons+=("proposal front matter missing risk_flags (must exist even if empty)")
  fi
fi

# Baseline presence (Bootstrap DoR) - enforce in strict mode only.
if [[ "$mode" == "strict" || "$mode" == "archive" ]]; then
  checks+=("bootstrap-baseline")
  baseline_missing=()
  for f in \
    "${truth_dir}/_meta/project-profile.md" \
    "${truth_dir}/_meta/glossary.md" \
    "${truth_dir}/_meta/key-concepts.md" \
    "${truth_dir}/_meta/verification-anchors.md" \
    "${truth_dir}/ssot/SSOT.md" \
    "${truth_dir}/ssot/requirements.index.yaml"
  do
    if [[ ! -f "$f" ]]; then
      baseline_missing+=("$(to_relpath "$f")")
    else
      artifacts+=("$(to_relpath "$f")")
    fi
  done
  if [[ ${#baseline_missing[@]} -gt 0 ]]; then
    failure_reasons+=("truth baseline missing; next_action=Bootstrap; missing: $(printf '%s ' "${baseline_missing[@]}")")
    next_action="Bootstrap"
  fi
fi

# Archive/strict semantics: require completion_contract + deliverable_quality and must align with contract.
if [[ "$mode" == "strict" || "$mode" == "archive" ]]; then
  checks+=("completion-contract-link")

  if [[ -z "$completion_contract" ]]; then
    failure_reasons+=("completion_contract required for archive/strict")
  else
    if ! is_relpath_safe "$completion_contract"; then
      failure_reasons+=("completion_contract must be a safe relative path: ${completion_contract}")
    fi
    contract_abs="${change_dir}/${completion_contract}"
    if [[ ! -f "$contract_abs" ]]; then
      failure_reasons+=("completion_contract not found: $(to_relpath "$contract_abs")")
    else
      artifacts+=("$(to_relpath "$contract_abs")")
    fi
  fi

  case "$deliverable_quality" in
    outline|draft|complete|operational) ;;
    "") failure_reasons+=("deliverable_quality required for archive/strict") ;;
    *) failure_reasons+=("deliverable_quality invalid: ${deliverable_quality}") ;;
  esac

  if [[ -n "$completion_contract" ]]; then
    contract_abs="${change_dir}/${completion_contract}"
    if [[ -f "$contract_abs" ]]; then
      contract_quality="$(read_contract_deliverable_quality "$contract_abs")"
      if [[ -n "$contract_quality" && -n "$deliverable_quality" && "$contract_quality" != "$deliverable_quality" ]]; then
        failure_reasons+=("deliverable_quality mismatch: proposal=${deliverable_quality}, contract.intent.deliverable_quality=${contract_quality}")
      fi
    fi
  fi
fi

# High risk approvals (risk_level=high) - enforce in archive/strict semantics.
if [[ "$risk_level" == "high" && ( "$mode" == "strict" || "$mode" == "archive" ) ]]; then
  checks+=("approvals")
  if ! has_front_matter_key "$proposal_file" "approvals"; then
    failure_reasons+=("approvals required when risk_level=high")
  else
    for role in security compliance devops; do
      approval_path="$(awk -v r="$role" '
        BEGIN { in_yaml=0; in_app=0 }
        NR==1 && $0=="---" { in_yaml=1; next }
        in_yaml==1 && $0=="---" { exit }
        in_yaml==1 {
          if ($0 ~ /^approvals:[[:space:]]*$/) { in_app=1; next }
          if (in_app==1 && $0 ~ /^[^[:space:]]/) { in_app=0 }
          if (in_app==1 && $0 ~ ("^  " r ":[[:space:]]*")) {
            line=$0
            sub(("^  " r ":[[:space:]]*"), "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            gsub(/["'"'"']/, "", line)
            print line
            exit
          }
        }
      ' "$proposal_file" 2>/dev/null || true)"

      if [[ -z "$approval_path" ]]; then
        failure_reasons+=("approvals.${role} missing (risk_level=high)")
        continue
      fi
      if ! is_relpath_safe "$approval_path"; then
        failure_reasons+=("approvals.${role} must be a safe relative path: ${approval_path}")
        continue
      fi
      approval_abs="${change_dir}/${approval_path}"
      if [[ ! -f "$approval_abs" ]]; then
        failure_reasons+=("approvals.${role} evidence missing: $(to_relpath "$approval_abs")")
      else
        artifacts+=("$(to_relpath "$approval_abs")")
      fi
    done
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

mkdir -p "$(dirname "$out_file")"
tmp="${out_file}.tmp.$$"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G0",
  "mode": "$(json_escape "$mode")",
  "check_id": "change-metadata-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "risk_level": "$(json_escape "$risk_level")",
    "state": "$(json_escape "$state")",
    "next_action": "$(json_escape "$next_action")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${reasons_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "change metadata check failed (G0)" "$out_file" "status=pass" "status=${status}" "fix proposal front matter / baseline / approvals"
  printf '%s\n' "${failure_reasons[@]}" >&2
  exit 1
fi

exit 0
