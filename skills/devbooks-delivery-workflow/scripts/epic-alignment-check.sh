#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: epic-alignment-check.sh <change-id> [options]

Validate Epic Alignment Gate:
  - change.ac_ids == knife.slices[].ac_subset for the matching slice_id
  - (optional) depends_on topology checks when metadata provides depends_on

Required when:
  - proposal declares epic_id and slice_id
  - AND (risk_level=high OR request_kind=epic)
  - AND mode is archive/strict

Options:
  --mode <proposal|apply|review|archive|strict>   Mode for enforcement (default: strict)
  --project-root <dir>    Project root directory (default: pwd)
  --change-root <dir>     Change root directory (default: changes)
  --truth-root <dir>      Truth root directory (default: specs)
  --out <path>            Output report path (default: evidence/gates/epic-alignment-check.json)
  -h, --help              Show help

Exit codes:
  0 - pass (or not required)
  1 - fail
  2 - usage error
EOF
}

errorf() {
  printf '%s\n' "ERROR: $*" >&2
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
      errorf "unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

case "$mode" in
  proposal|apply|review|archive|strict) ;;
  *)
    errorf "invalid --mode: $mode"
    exit 2
    ;;
esac

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  errorf "invalid change-id: '$change_id'"
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
proposal_file="${change_dir}/proposal.md"

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/epic-alignment-check.json"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
fi

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

extract_front_matter_list() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { in_yaml=0; in_list=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 && $0 ~ ("^" k ":[[:space:]]*$") { in_list=1; next }
    in_list==1 {
      if ($0 ~ /^[^[:space:]]/) { exit }
      if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
        line=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        gsub(/["'"'"']/, "", line)
        if (line != "") print line
      }
    }
  ' "$file" 2>/dev/null || true
}

parse_yaml_slice_ac_subset() {
  local file="$1"
  local target_slice="$2"
  awk -v target="$target_slice" '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/["'"'"']/, "", s); return s }
    BEGIN { in_slices=0; in_target=0; in_ac=0; sid="" }
    /^slices:[[:space:]]*$/ { in_slices=1; next }
    in_slices && /^[^[:space:]]/ { in_slices=0; next }
    in_slices {
      if ($0 ~ /^  - slice_id:[[:space:]]*/) {
        sid=$0
        sub(/^  - slice_id:[[:space:]]*/, "", sid)
        sid=trim(sid)
        in_target = (sid==target ? 1 : 0)
        in_ac=0
        next
      }
      if (in_target!=1) next
      if ($0 ~ /^    ac_subset:[[:space:]]*$/) { in_ac=1; next }
      if (in_ac==1 && $0 ~ /^    [^[:space:]]/) { in_ac=0 }
      if (in_ac==1 && $0 ~ /^      -[[:space:]]*/) {
        v=$0
        sub(/^      -[[:space:]]*/, "", v)
        v=trim(v)
        if (v != "") print v
      }
    }
  ' "$file" 2>/dev/null || true
}

checks=("required-trigger")
artifacts=()
failure_reasons=()
next_action="DevBooks"

risk_level="low"
request_kind=""
epic_id=""
slice_id=""

if [[ -f "$proposal_file" ]]; then
  v="$(extract_front_matter_value "$proposal_file" "risk_level")"
  if [[ -n "$v" ]]; then
    risk_level="$v"
  fi
  request_kind="$(extract_front_matter_value "$proposal_file" "request_kind")"
  epic_id="$(extract_front_matter_value "$proposal_file" "epic_id")"
  slice_id="$(extract_front_matter_value "$proposal_file" "slice_id")"
fi

required=false
if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
  if [[ -n "$epic_id" && -n "$slice_id" && ( "$risk_level" == "high" || "$request_kind" == "epic" ) ]]; then
    required=true
  fi
fi

knife_plan_path=""
if [[ "$required" != true ]]; then
  checks+=("skip-not-required")
else
  checks+=("knife-plan-path")
  epic_dir="${truth_dir}/_meta/epics/${epic_id}"
  if [[ -f "${epic_dir}/knife-plan.yaml" ]]; then
    knife_plan_path="${epic_dir}/knife-plan.yaml"
  elif [[ -f "${epic_dir}/knife-plan.json" ]]; then
    knife_plan_path="${epic_dir}/knife-plan.json"
  else
    failure_reasons+=("missing Knife Plan: ${epic_dir}/knife-plan.(yaml|json)")
  fi
fi

if [[ "$required" == true && -n "$knife_plan_path" ]]; then
  knife_plan_rel="$knife_plan_path"
  if [[ "$knife_plan_rel" == "${project_root}/"* ]]; then
    knife_plan_rel="${knife_plan_rel#"${project_root}"/}"
  fi
  artifacts+=("$knife_plan_rel")
  checks+=("ac-subset-equality")

  if [[ "$knife_plan_path" == *.json ]]; then
    failure_reasons+=("knife-plan.json alignment is not supported yet (expected knife-plan.yaml)")
  else
    tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t devbooks_epic)"
    trap 'rm -rf "$tmp_dir" >/dev/null 2>&1 || true' EXIT

    change_ac_file="${tmp_dir}/change_acs.txt"
    slice_ac_file="${tmp_dir}/slice_acs.txt"

    extract_front_matter_list "$proposal_file" "ac_ids" | sort -u >"$change_ac_file" || true
    parse_yaml_slice_ac_subset "$knife_plan_path" "$slice_id" | sort -u >"$slice_ac_file" || true

    if [[ ! -s "$change_ac_file" ]]; then
      failure_reasons+=("missing change.ac_ids in proposal front matter")
    fi
    if [[ ! -s "$slice_ac_file" ]]; then
      failure_reasons+=("missing slice.ac_subset in Knife Plan for slice_id=${slice_id}")
    fi

    if [[ -s "$change_ac_file" && -s "$slice_ac_file" ]]; then
      missing_in_slice="$(comm -23 "$change_ac_file" "$slice_ac_file" || true)"
      extra_in_slice="$(comm -23 "$slice_ac_file" "$change_ac_file" || true)"
      if [[ -n "$missing_in_slice" ]]; then
        missing_fmt="$(printf '%s\n' "$missing_in_slice" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
        failure_reasons+=("AC alignment mismatch: in change but not in slice: ${missing_fmt}")
      fi
      if [[ -n "$extra_in_slice" ]]; then
        extra_fmt="$(printf '%s\n' "$extra_in_slice" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
        failure_reasons+=("AC alignment mismatch: in slice but not in change: ${extra_fmt}")
      fi
    fi
  fi
fi

status="pass"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  status="fail"
  next_action="Knife"
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
  "gate_id": "G3",
  "mode": "$(json_escape "$mode")",
  "check_id": "epic-alignment-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "risk_level": "$(json_escape "$risk_level")",
    "request_kind": "$(json_escape "$request_kind")",
    "epic_id": "$(json_escape "$epic_id")",
    "slice_id": "$(json_escape "$slice_id")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${reasons_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "Epic alignment check failed: $out_file"
  printf '%s\n' "${failure_reasons[@]}" >&2
  exit 1
fi

exit 0
