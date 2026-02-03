#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: verification-anchors-check.sh <change-id> [options]

Validate deterministic verification anchors contract.

Implementation note:
  - This check validates extra fields on completion.contract.yaml checks[] entries:
      runner, timeout_seconds, requires_network, success_criteria, failure_next_action
  - Enforced when risk_level=high or request_kind=epic (G3 contexts), and in archive/strict semantics.

Options:
  --mode <proposal|apply|review|archive|strict>   Mode for enforcement (default: strict)
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --out <path>           Output report path (default: evidence/gates/verification-anchors-check.json)
  -h, --help             Show help

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

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

proposal_file="${change_dir}/proposal.md"
contract_file="${change_dir}/completion.contract.yaml"

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/verification-anchors-check.json"
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

risk_level="low"
request_kind=""
if [[ -f "$proposal_file" ]]; then
  v="$(extract_front_matter_value "$proposal_file" "risk_level")"
  if [[ -n "$v" ]]; then
    risk_level="$v"
  fi
  request_kind="$(extract_front_matter_value "$proposal_file" "request_kind")"
fi

required=false
if [[ "$risk_level" == "high" || "$request_kind" == "epic" || "$mode" == "archive" || "$mode" == "strict" ]]; then
  required=true
fi

checks=("required-trigger")
artifacts=()
missing=()

if [[ "$required" != true ]]; then
  checks+=("skip-not-required")
fi

if [[ "$required" == true ]]; then
  if [[ ! -f "$contract_file" ]]; then
    missing+=("missing completion.contract.yaml: ${contract_file}")
  else
    artifacts+=("completion.contract.yaml")
  fi

  if [[ -f "$contract_file" ]]; then
    # Parse checks[] items and ensure extra fields exist per check.
    in_checks=false
    in_item=false
    current_id=""
    have_runner=false
    have_timeout=false
    have_requires_network=false
    have_success=false
    have_failure_next_action=false
    in_artifacts=false
    artifacts_count=0

    flush_item() {
      if [[ "$in_item" != true ]]; then
        return 0
      fi
      local missing_fields=()
      [[ "$have_runner" == true ]] || missing_fields+=("runner")
      [[ "$have_timeout" == true ]] || missing_fields+=("timeout_seconds")
      [[ "$have_requires_network" == true ]] || missing_fields+=("requires_network")
      [[ $artifacts_count -gt 0 ]] || missing_fields+=("artifacts[]")
      [[ "$have_success" == true ]] || missing_fields+=("success_criteria")
      [[ "$have_failure_next_action" == true ]] || missing_fields+=("failure_next_action")
      if [[ ${#missing_fields[@]} -gt 0 ]]; then
        missing+=("check ${current_id} missing anchor fields: $(printf '%s ' "${missing_fields[@]}")")
      fi
      in_item=false
      in_artifacts=false
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ ^checks:[[:space:]]*$ ]]; then
        in_checks=true
        continue
      fi
      if [[ "$in_checks" != true ]]; then
        continue
      fi
      if [[ "$line" =~ ^[^[:space:]] && "$line" != "checks:"* ]]; then
        # leaving checks section
        break
      fi

      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*([A-Za-z0-9._-]+)[[:space:]]*$ ]]; then
        flush_item
        in_item=true
        current_id="${BASH_REMATCH[1]}"
        have_runner=false
        have_timeout=false
        have_requires_network=false
        have_success=false
        have_failure_next_action=false
        in_artifacts=false
        artifacts_count=0
        continue
      fi

      if [[ "$in_item" != true ]]; then
        continue
      fi

      if [[ "$line" =~ ^[[:space:]]*runner:[[:space:]]*(local|ci|both)[[:space:]]*$ ]]; then
        have_runner=true
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]*timeout_seconds:[[:space:]]*([0-9]+(\.[0-9]+)?)[[:space:]]*$ ]]; then
        have_timeout=true
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]*requires_network:[[:space:]]*(true|false)[[:space:]]*$ ]]; then
        have_requires_network=true
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]*artifacts:[[:space:]]*$ ]]; then
        in_artifacts=true
        continue
      fi
      if [[ "$in_artifacts" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*([^[:space:]].*)$ ]]; then
        artifacts_count=$((artifacts_count + 1))
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]*success_criteria:[[:space:]]*.+$ ]]; then
        have_success=true
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]*failure_next_action:[[:space:]]*(Void|Bootstrap|Knife|DevBooks)[[:space:]]*$ ]]; then
        have_failure_next_action=true
        continue
      fi
    done <"$contract_file"
    flush_item
  fi
fi

status="pass"
next_action="DevBooks"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="fail"
  next_action="DevBooks"
fi

checks_json="$(json_array "${checks[@]}")"
artifacts_json="[]"
if [[ ${#artifacts[@]} -gt 0 ]]; then
  artifacts_json="$(json_array "${artifacts[@]}")"
fi
missing_json="[]"
if [[ ${#missing[@]} -gt 0 ]]; then
  missing_json="$(json_array "${missing[@]}")"
fi

tmp="${out_file}.tmp.$$"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G3",
  "mode": "$(json_escape "$mode")",
  "check_id": "verification-anchors-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "risk_level": "$(json_escape "$risk_level")",
    "request_kind": "$(json_escape "$request_kind")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${missing_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "verification anchors check failed: $out_file"
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi

exit 0
