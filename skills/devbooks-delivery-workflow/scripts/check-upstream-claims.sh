#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: check-upstream-claims.sh <change-id> [options]

Evaluate completion.contract.yaml upstream_claims against requirements.index.yaml MUST set.

Options:
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory (default: specs)
  --contract <path>      Override contract path (default: completion.contract.yaml in change dir)
  --out <path>           Override output path (default: evidence/gates/upstream-claims-check.json in change dir)
  -h, --help             Show this help message

Exit codes:
  0 - pass or skip (no upstream_claims)
  1 - fail (any blocking rule violated)
  2 - usage error

Ref contract (enforced, MUST):
  - set_ref:
    - truth://.../requirements.index.yaml (or .yml)
    - resolves to a file under --truth-root
    - requirements.index schema_version must be 1.0.0
  - next_action_ref (required for claim=subset):
    - truth://... (file under --truth-root), OR
    - change://<next-change-id>/proposal.md (file under --change-root, draft or archive)
EOF
}

die_usage() {
  echo "error: $*" >&2
  usage
  exit 2
}

if [[ $# -eq 0 ]]; then
  die_usage "missing change-id"
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
contract_path=""
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
    --contract)
      contract_path="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    *)
      die_usage "unknown option: $1"
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  die_usage "invalid change-id: '$change_id'"
fi

project_root="${project_root%/}"
change_root="${change_root%/}"
truth_root="${truth_root%/}"

if [[ "$change_root" = /* ]]; then
  change_root_dir="${change_root}"
else
  change_root_dir="${project_root}/${change_root}"
fi

if [[ "$truth_root" = /* ]]; then
  truth_dir="${truth_root}"
else
  truth_dir="${project_root}/${truth_root}"
fi

change_dir="${change_root_dir}/${change_id}"
if [[ ! -d "$change_dir" ]]; then
  echo "error: missing change directory: ${change_dir}" >&2
  exit 1
fi

if [[ -n "$contract_path" ]]; then
  if [[ "$contract_path" = /* ]]; then
    contract_file="$contract_path"
  else
    contract_file="${change_dir}/${contract_path}"
  fi
else
  if [[ -f "${change_dir}/completion.contract.yaml" ]]; then
    contract_file="${change_dir}/completion.contract.yaml"
  elif [[ -f "${change_dir}/completion.contract.yml" ]]; then
    contract_file="${change_dir}/completion.contract.yml"
  else
    contract_file="${change_dir}/completion.contract.yaml"
  fi
fi

mkdir -p "${change_dir}/evidence/gates"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
else
  out_file="${change_dir}/evidence/gates/upstream-claims-check.json"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/upstream-claims.sh
source "${script_dir}/lib/upstream-claims.sh"
uc_set_context "$truth_dir" "$change_root_dir"

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
  local first=true
  printf '['
  local item
  for item in "$@"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      printf ','
    fi
    printf '"%s"' "$(json_escape "$item")"
  done
  printf ']'
}

csv_to_json_array() {
  local csv="$1"
  local -a items=()
  local item
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    items+=("$item")
  done < <(uc_split_csv_to_array "$csv")
  json_array "${items[@]+${items[@]}}"
}

write_report() {
  local status="$1"
  local errors_count="$2"
  local results_json="$3"

  {
    printf '{'
    printf '"schema_version":"1.0.0",'
    printf '"check_id":"upstream-claims-check",'
    printf '"change_id":"%s",' "$(json_escape "$change_id")"
    printf '"status":"%s",' "$(json_escape "$status")"
    printf '"generated_at":"%s",' "$(json_escape "$(date -u +"%Y-%m-%dT%H:%M:%SZ")")"
    printf '"errors_count":%s,' "$errors_count"
    printf '"results":%s' "$results_json"
    printf '}\n'
  } >"$out_file"
}

if ! uc_parse_contract_upstream_claims "$contract_file"; then
  write_report "skip" 0 "[]"
  echo "info: completion contract not found; skip: ${contract_file}"
  exit 0
fi

if [[ ${#UC_SET_REFS[@]} -eq 0 ]]; then
  write_report "skip" 0 "[]"
  echo "info: no upstream_claims; skip"
  exit 0
fi

overall_fail=false
if ! uc_evaluate_upstream_claims; then
  overall_fail=true
fi

errors_count=0
results_parts=()

for i in "${!UC_EVAL_SET_REFS[@]}"; do
  local_status="${UC_EVAL_STATUS[$i]}"
  if [[ "$local_status" == "fail" ]]; then
    err_csv="${UC_EVAL_ERRORS_CSV[$i]}"
    if [[ -n "$err_csv" ]]; then
      # Count comma-separated error items (safe: our library errors do not contain commas)
      errors_count=$((errors_count + $(awk -F',' 'NF{print NF}' <<<"$err_csv")))
    fi
  fi

  item_json_parts=()
  item_json_parts+=("\"set_ref\":\"$(json_escape "${UC_EVAL_SET_REFS[$i]}")\"")
  item_json_parts+=("\"set_path\":\"$(json_escape "${UC_EVAL_SET_PATHS[$i]}")\"")
  item_json_parts+=("\"claim\":\"$(json_escape "${UC_EVAL_CLAIMS[$i]}")\"")
  item_json_parts+=("\"status\":\"$(json_escape "$local_status")\"")
  item_json_parts+=("\"must_total\":${UC_EVAL_MUST_TOTAL[$i]}")
  item_json_parts+=("\"must_covered_count\":${UC_EVAL_MUST_COVERED[$i]}")
  item_json_parts+=("\"uncovered_must_ids\":$(csv_to_json_array "${UC_EVAL_UNCOVERED_MUST_CSV[$i]}")")
  item_json_parts+=("\"deferred_ids\":$(csv_to_json_array "${UC_EVAL_DEFERRED_CSV[$i]}")")
  item_json_parts+=("\"next_action_ref\":\"$(json_escape "${UC_EVAL_NEXT_ACTION_REFS[$i]}")\"")
  item_json_parts+=("\"next_action_path\":\"$(json_escape "${UC_EVAL_NEXT_ACTION_PATHS[$i]}")\"")
  item_json_parts+=("\"next_action_resolvable\":$( [[ "${UC_EVAL_NEXT_ACTION_RESOLVABLE[$i]}" == true ]] && printf 'true' || printf 'false' )")
  item_json_parts+=("\"errors\":$(csv_to_json_array "${UC_EVAL_ERRORS_CSV[$i]}")")

  item_json="{"
  first=true
  for part in "${item_json_parts[@]}"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      item_json+=","
    fi
    item_json+="$part"
  done
  item_json+="}"
  results_parts+=("$item_json")
done

results_json="["
for idx in "${!results_parts[@]}"; do
  if [[ $idx -gt 0 ]]; then
    results_json+=","
  fi
  results_json+="${results_parts[$idx]}"
done
results_json+="]"

if [[ "$overall_fail" == true ]]; then
  write_report "fail" "$errors_count" "$results_json"
  echo "fail: upstream_claims check failed (see ${out_file})" >&2
  exit 1
fi

write_report "pass" 0 "$results_json"
echo "ok: upstream_claims check passed (wrote ${out_file})"
exit 0

