#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: required-gates-derive.sh <change-id> [options]

Derive required_gates deterministically from:
  - change metadata (proposal.md front matter): request_kind, change_type, risk_level, risk_flags
  - completion contract: completion.contract.yaml (intent/check types)
  - gate_profile: .devbooks/config.yaml (via scripts/config-discovery.sh output)

Options:
  --project-root <dir>     Project root directory (default: pwd)
  --change-root <dir>      Change root directory (default: changes)
  --truth-root <dir>       Truth root directory (default: specs)
  --out <path>             Output report path (default: evidence/gates/required-gates-derive.json)
  -h, --help               Show this help message

Exit codes:
  0 - success (report written)
  1 - fail (cannot derive deterministically due to missing inputs)
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

out_file="${change_dir}/evidence/gates/required-gates-derive.json"
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

discover_gate_profile() {
  local discovery="${project_root}/scripts/config-discovery.sh"
  if [[ -n "${DEVBOOKS_GATE_PROFILE:-}" ]]; then
    printf '%s' "${DEVBOOKS_GATE_PROFILE}"
    return 0
  fi
  if [[ -f "$discovery" ]]; then
    bash "$discovery" "$project_root" 2>/dev/null \
      | awk -F= '$1=="GATE_PROFILE" && !found { print $2; found=1 }'
    return 0
  fi
  printf '%s' "standard"
}

read_completion_contract_quality() {
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

read_completion_contract_check_types_csv() {
  local contract="$1"
  awk '
    BEGIN { in_checks=0; in_item=0; t=""; count=0 }
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    $0 ~ /^checks:[[:space:]]*$/ { in_checks=1; next }
    in_checks && /^[^[:space:]]/ { in_checks=0; in_item=0 }
    in_checks && $0 ~ /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { in_item=1; next }
    in_item && $0 ~ /^[[:space:]]+type:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]+type:[[:space:]]*/, "", line)
      line=trim(line)
      gsub(/["'"'"']/, "", line)
      if (line != "") { types[count++] = line }
      next
    }
    END {
      for (i=0; i<count; i++) {
        if (i>0) printf ","
        printf "%s", types[i]
      }
    }
  ' "$contract" 2>/dev/null || true
}

matrix_min_gates_csv() {
  local change_type="$1"
  case "$change_type" in
    feature|feat)
      printf '%s' "G0,G1,G2,G4,G6"
      ;;
    refactor)
      printf '%s' "G0,G1,G2,G4,G6"
      ;;
    migration)
      printf '%s' "G0,G1,G2,G4,G6"
      ;;
    compliance)
      printf '%s' "G0,G1,G3,G4,G6"
      ;;
    hotfix)
      printf '%s' "G0,G1,G2,G4,G6"
      ;;
    spike|spike-prototype|prototype)
      printf '%s' "G0,G1,G2,G6"
      ;;
    docs)
      printf '%s' "G0,G1,G6"
      ;;
    protocol)
      printf '%s' "G0,G1,G2,G4,G5,G6"
      ;;
    *)
      # Unknown types: keep minimal always-on gates.
      printf '%s' "G0,G1,G6"
      ;;
  esac
}

profile_min_gates_csv() {
  local profile="$1"
  case "$profile" in
    light)
      printf '%s' "G0,G1,G4,G6"
      ;;
    standard)
      printf '%s' "G0,G1,G2,G4,G6"
      ;;
    strict)
      printf '%s' "G0,G1,G2,G3,G4,G5,G6"
      ;;
    *)
      printf '%s' "G0,G1,G2,G4,G6"
      ;;
  esac
}

union_gates() {
  # union_gates "<csv1>" "<csv2>" ... => prints newline-separated unique gate ids sorted by numeric
  local combined=""
  local csv
  for csv in "$@"; do
    [[ -n "$csv" ]] || continue
    if [[ -z "$combined" ]]; then
      combined="$csv"
    else
      combined="${combined},${csv}"
    fi
  done

  if [[ -z "$combined" ]]; then
    return 0
  fi

  printf '%s\n' "$combined" \
    | tr ',' '\n' \
    | awk 'NF { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0); print }' \
    | grep -E '^G[0-6]$' \
    | sort -u \
    | sort
}

proposal_file="${change_dir}/proposal.md"
contract_file="${change_dir}/completion.contract.yaml"

change_type=""
risk_level="low"
request_kind=""
gate_profile=""
deliverable_quality=""
contract_check_types_csv=""

errors=()

if [[ ! -f "$proposal_file" ]]; then
  errors+=("missing proposal.md: ${proposal_file}")
else
  change_type="$(extract_front_matter_value "$proposal_file" "change_type")"
  risk_level="$(extract_front_matter_value "$proposal_file" "risk_level")"
  request_kind="$(extract_front_matter_value "$proposal_file" "request_kind")"
fi

if [[ ! -f "$contract_file" ]]; then
  errors+=("missing completion.contract.yaml: ${contract_file}")
else
  deliverable_quality="$(read_completion_contract_quality "$contract_file")"
  contract_check_types_csv="$(read_completion_contract_check_types_csv "$contract_file")"
fi

gate_profile="$(discover_gate_profile)"
gate_profile="$(trim "${gate_profile:-standard}")"

case "$gate_profile" in
  light|standard|strict) ;;
  *) gate_profile="standard" ;;
esac

if [[ -z "$change_type" ]]; then
  errors+=("missing change_type in proposal front matter")
fi

case "$risk_level" in
  low|medium|high) ;;
  "") risk_level="low" ;;
  *) errors+=("invalid risk_level (expected low|medium|high): ${risk_level}") ;;
esac

case "$request_kind" in
  debug|change|epic|void|bootstrap|governance) ;;
  "") errors+=("missing request_kind in proposal front matter") ;;
  *) errors+=("invalid request_kind (expected debug|change|epic|void|bootstrap|governance): ${request_kind}") ;;
esac

derived_gates=()

if [[ ${#errors[@]} -eq 0 ]]; then
  matrix_csv="$(matrix_min_gates_csv "$change_type")"
  profile_csv="$(profile_min_gates_csv "$gate_profile")"

  extra_csv=""
  # Risk triggers
  if [[ "$risk_level" == "medium" || "$risk_level" == "high" ]]; then
    extra_csv="${extra_csv},G5"
  fi
  if [[ "$risk_level" == "high" || "$request_kind" == "epic" ]]; then
    extra_csv="${extra_csv},G3"
  fi
  # Contract triggers (conservative): security/perf checks imply G5
  if [[ -n "$contract_check_types_csv" ]]; then
    if printf '%s\n' "$contract_check_types_csv" | tr ',' '\n' | grep -Eq '^(security|perf)$'; then
      extra_csv="${extra_csv},G5"
    fi
  fi
  # Deliverable quality triggers (draft+ implies at least G2 for reproducible anchors)
  case "$deliverable_quality" in
    draft|complete|operational)
      extra_csv="${extra_csv},G2"
      ;;
  esac

  while IFS= read -r g; do
    [[ -n "$g" ]] || continue
    derived_gates+=("$g")
  done < <(union_gates "$matrix_csv" "$profile_csv" "$extra_csv")
fi

status="pass"
if [[ ${#errors[@]} -gt 0 ]]; then
  status="fail"
fi

mkdir -p "$(dirname "$out_file")"
tmp="${out_file}.tmp.$$"

errors_json="[]"
if [[ ${#errors[@]} -gt 0 ]]; then
  errors_json="$(json_array "${errors[@]}")"
fi
derived_json="[]"
if [[ ${#derived_gates[@]} -gt 0 ]]; then
  derived_json="$(json_array "${derived_gates[@]}")"
fi

cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G1",
  "mode": "strict",
  "check_id": "required-gates-derive",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "truth_root": "$(json_escape "$truth_root")",
    "change_type": "$(json_escape "$change_type")",
    "risk_level": "$(json_escape "$risk_level")",
    "request_kind": "$(json_escape "$request_kind")",
    "gate_profile": "$(json_escape "$gate_profile")",
    "contract_deliverable_quality": "$(json_escape "$deliverable_quality")",
    "contract_check_types_csv": "$(json_escape "$contract_check_types_csv")"
  },
  "derived_required_gates": ${derived_json},
  "failure_reasons": ${errors_json},
  "next_action": "DevBooks"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "required_gates derivation failed" "$out_file" "status=pass" "status=${status}" "fix proposal/contract inputs and rerun"
  exit 1
fi

exit 0
