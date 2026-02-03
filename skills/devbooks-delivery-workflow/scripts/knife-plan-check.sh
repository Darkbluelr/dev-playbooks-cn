#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: knife-plan-check.sh <change-id> [--mode <proposal|apply|review|archive|strict>] [--project-root <dir>] [--change-root <dir>] [--truth-root <dir>] [--out <path>]

When proposal front matter declares:
  - risk_level: high
  OR
  - request_kind: epic

This check enforces:
  - epic_id and slice_id are present in proposal front matter
  - a machine-readable Knife Plan exists at:
      <truth-root>/_meta/epics/<epic_id>/knife-plan.yaml|json
  - Knife Plan epic_id/slice_id match the change package metadata

Exit codes:
  0 - pass (or not required)
  1 - fail (required but missing/mismatch)
  2 - usage/runtime error
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
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

case "$mode" in
  proposal|apply|review|archive|strict) ;;
  *)
    echo "error: invalid --mode: '$mode'" >&2
    usage
    exit 2
    ;;
esac

project_root="${project_root%/}"
change_root="${change_root%/}"
truth_root="${truth_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

if [[ "$truth_root" = /* ]]; then
  truth_dir="${truth_root}"
else
  truth_dir="${project_root}/${truth_root}"
fi

proposal_file="${change_dir}/proposal.md"

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
      gsub(/^["'\'']|["'\'']$/, "", $0)
      print $0
      exit
    }
  ' "$file" 2>/dev/null || true
}

extract_front_matter_nested_value() {
  local file="$1"
  local parent="$2"
  local key="$3"
  awk -v p="$parent" -v k="$key" '
    BEGIN { in_yaml=0; in_parent=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 {
      if ($0 ~ ("^" p ":[[:space:]]*$")) { in_parent=1; next }
      if (in_parent==1) {
        if ($0 ~ /^[^[:space:]]/) { in_parent=0; next }
        if ($0 ~ ("^  " k ":[[:space:]]*")) {
          line=$0
          sub(("^  " k ":[[:space:]]*"), "", line)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
          gsub(/["'"'"']/, "", line)
          print line
          exit
        }
      }
    }
  ' "$file" 2>/dev/null || true
}

yaml_top_scalar() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    $0 ~ ("^" k ":[[:space:]]*") {
      sub(("^" k ":[[:space:]]*"), "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'\'']|["'\'']$/, "", $0)
      print $0
      exit
    }
  ' "$file" 2>/dev/null || true
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

json_escape() {
  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//\"/\\\"}"
  input="${input//$'\n'/\\n}"
  input="${input//$'\r'/\\r}"
  input="${input//$'\t'/\\t}"
  printf '%s' "$input"
}

json_array() {
  local first=1
  local item
  printf '%s' "["
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then
      printf '%s' ","
    fi
    first=0
    printf '"%s"' "$(json_escape "$item")"
  done
  printf '%s' "]"
}

risk_level="low"
request_kind="change"
epic_id=""
slice_id=""
state=""
truth_refs_knife_plan_revision=""

if [[ -f "$proposal_file" ]]; then
  v="$(extract_front_matter_value "$proposal_file" "risk_level")"
  [[ -n "$v" ]] && risk_level="$v"
  v="$(extract_front_matter_value "$proposal_file" "request_kind")"
  [[ -n "$v" ]] && request_kind="$v"
  epic_id="$(extract_front_matter_value "$proposal_file" "epic_id")"
  slice_id="$(extract_front_matter_value "$proposal_file" "slice_id")"
  state="$(extract_front_matter_value "$proposal_file" "state")"
  truth_refs_knife_plan_revision="$(extract_front_matter_nested_value "$proposal_file" "truth_refs" "knife_plan_revision")"
fi

required=false
if [[ "$risk_level" == "high" || "$request_kind" == "epic" ]]; then
  required=true
fi

checks=("front-matter")
artifacts=()
missing=()

knife_plan_path=""
knife_plan_format=""
knife_epic_id=""
knife_slice_id=""
knife_plan_id=""
knife_change_type=""
knife_risk_level=""

if [[ "$required" == true ]]; then
  checks+=("epic-slice-required")

  if [[ -z "$epic_id" ]]; then
    missing+=("missing epic_id in proposal front matter (required when risk_level=high or request_kind=epic)")
  fi
  if [[ -z "$slice_id" ]]; then
    missing+=("missing slice_id in proposal front matter (required when risk_level=high or request_kind=epic)")
  fi

  if [[ -n "$epic_id" ]]; then
    epic_dir="${truth_dir}/_meta/epics/${epic_id}"
    checks+=("knife-plan-path")

    if [[ -d "$epic_dir" ]]; then
      if [[ -f "${epic_dir}/knife-plan.yaml" ]]; then
        knife_plan_path="${epic_dir}/knife-plan.yaml"
        knife_plan_format="yaml"
      elif [[ -f "${epic_dir}/knife-plan.json" ]]; then
        knife_plan_path="${epic_dir}/knife-plan.json"
        knife_plan_format="json"
      fi
    fi

    if [[ -z "$knife_plan_path" ]]; then
      missing+=("missing Knife Plan under truth root: ${epic_dir}/knife-plan.(yaml|json)")
    else
      artifacts+=("${knife_plan_path#"${project_root}"/}")
      checks+=("knife-plan-parse")

      if [[ "$knife_plan_format" == "yaml" ]]; then
        knife_plan_id="$(yaml_top_scalar "$knife_plan_path" "plan_id")"
        knife_epic_id="$(yaml_top_scalar "$knife_plan_path" "epic_id")"
        knife_slice_id="$(yaml_top_scalar "$knife_plan_path" "slice_id")"
        knife_change_type="$(yaml_top_scalar "$knife_plan_path" "change_type")"
        knife_risk_level="$(yaml_top_scalar "$knife_plan_path" "risk_level")"
      else
        if ! command -v node >/dev/null 2>&1; then
          missing+=("cannot parse knife-plan.json: node is required but not found")
        else
          knife_plan_id="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(o.plan_id||""));' "$knife_plan_path" 2>/dev/null || true)"
          knife_epic_id="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(o.epic_id||""));' "$knife_plan_path" 2>/dev/null || true)"
          knife_slice_id="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(o.slice_id||""));' "$knife_plan_path" 2>/dev/null || true)"
          knife_change_type="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(o.change_type||""));' "$knife_plan_path" 2>/dev/null || true)"
          knife_risk_level="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(o.risk_level||""));' "$knife_plan_path" 2>/dev/null || true)"
        fi
      fi

      checks+=("knife-plan-consistency")
      if [[ -n "$knife_epic_id" && -n "$epic_id" && "$knife_epic_id" != "$epic_id" ]]; then
        missing+=("Knife Plan epic_id mismatch: proposal=${epic_id}, knife=${knife_epic_id}")
      fi
      if [[ -n "$knife_slice_id" && -n "$slice_id" && "$knife_slice_id" != "$slice_id" ]]; then
        missing+=("Knife Plan slice_id mismatch: proposal=${slice_id}, knife=${knife_slice_id}")
      fi

      if [[ -z "$knife_epic_id" ]]; then
        missing+=("Knife Plan missing required field: epic_id")
      fi
      if [[ -z "$knife_slice_id" ]]; then
        missing+=("Knife Plan missing required field: slice_id")
      fi
      if [[ -z "$knife_plan_id" ]]; then
        missing+=("Knife Plan missing required field: plan_id")
      fi
      if [[ -z "$knife_change_type" ]]; then
        missing+=("Knife Plan missing required field: change_type")
      fi
      case "$knife_risk_level" in
        low|medium|high) ;;
        "")
          missing+=("Knife Plan missing required field: risk_level")
          ;;
        *)
          missing+=("Knife Plan risk_level invalid (expected low|medium|high): ${knife_risk_level}")
          ;;
      esac

      # -----------------------------------------------------------------------
      # Knife Plan revision + immutable snapshot (protocol requirement)
      # -----------------------------------------------------------------------
      checks+=("knife-plan-revision")
      knife_plan_revision="$(yaml_top_scalar "$knife_plan_path" "plan_revision")"
      if [[ -z "$knife_plan_revision" ]]; then
        missing+=("Knife Plan missing required field: plan_revision")
      elif [[ ! "$knife_plan_revision" =~ ^[0-9]+$ ]]; then
        missing+=("Knife Plan plan_revision must be an integer: ${knife_plan_revision}")
      fi

      checks+=("knife-plan-revision-log")
      revision_log="${epic_dir}/knife-plan.revisions.yaml"
      if [[ ! -f "$revision_log" ]]; then
        missing+=("Knife Plan revision log missing: ${revision_log}")
      else
        artifacts+=("${revision_log#"${project_root}"/}")
        if [[ -n "$knife_plan_revision" ]]; then
          if ! rg -n "^[[:space:]]*-[[:space:]]*plan_revision:[[:space:]]*${knife_plan_revision}[[:space:]]*$" "$revision_log" >/dev/null 2>&1; then
            missing+=("Knife Plan revision log does not include plan_revision=${knife_plan_revision}: ${revision_log}")
          fi
        fi
      fi

      checks+=("knife-plan-snapshot")
      if [[ -n "$knife_plan_revision" ]]; then
        snapshot_dir="${epic_dir}/snapshots"
        snapshot_file="${snapshot_dir}/knife-plan.rev${knife_plan_revision}.yaml"
        if [[ ! -f "$snapshot_file" ]]; then
          missing+=("Knife Plan immutable snapshot missing: ${snapshot_file}")
        else
          artifacts+=("${snapshot_file#"${project_root}"/}")
        fi
      fi

      # -----------------------------------------------------------------------
      # Freeze referenced Knife Plan revision once the change enters in_progress+
      # -----------------------------------------------------------------------
      checks+=("knife-plan-revision-freeze")
      case "$state" in
        in_progress|review|completed|archived)
          if [[ -z "$truth_refs_knife_plan_revision" ]]; then
            missing+=("truth_refs.knife_plan_revision is required once state=${state} (to freeze Knife Plan revision)")
          elif [[ -n "$knife_plan_revision" && "$truth_refs_knife_plan_revision" != "$knife_plan_revision" ]]; then
            missing+=("truth_refs.knife_plan_revision mismatch: proposal=${truth_refs_knife_plan_revision}, knife=${knife_plan_revision}")
          fi
          ;;
      esac
    fi
  fi
fi

status="pass"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="fail"
fi

next_action="DevBooks"
if [[ "$required" == true && "$status" != "pass" ]]; then
  next_action="Knife"
fi

if [[ -n "$out_path" ]]; then
  mkdir -p "$(dirname "$out_path")"
  tmp="${out_path}.tmp.$$"

  checks_json="$(json_array "${checks[@]}")"

  artifacts_json="[]"
  if [[ ${#artifacts[@]} -gt 0 ]]; then
    artifacts_json="$(json_array "${artifacts[@]}")"
  fi

  missing_json="[]"
  if [[ ${#missing[@]} -gt 0 ]]; then
    missing_json="$(json_array "${missing[@]}")"
  fi

  cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G3",
  "mode": "$(json_escape "$mode")",
  "check_id": "knife-plan-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "risk_level": "$(json_escape "$risk_level")",
    "request_kind": "$(json_escape "$request_kind")",
    "epic_id": "$(json_escape "$epic_id")",
    "slice_id": "$(json_escape "$slice_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "change_dir": "$(json_escape "$change_dir")",
    "truth_dir": "$(json_escape "$truth_dir")",
    "knife_plan_path": "$(json_escape "$knife_plan_path")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${missing_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
  mv -f "$tmp" "$out_path"
fi

if [[ "$status" != "pass" ]]; then
  echo "error: Knife Plan check failed (required=${required})" >&2
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi

exit 0
