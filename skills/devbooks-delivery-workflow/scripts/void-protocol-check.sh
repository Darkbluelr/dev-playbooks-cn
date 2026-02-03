#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: void-protocol-check.sh <change-id> [options]

Validate Void protocol artifacts when next_action=Void.

Required outputs (when triggered):
  - void/research_report.md
  - void/ADR.md
  - void/void.yaml  (Freeze/Thaw status)

Options:
  --mode <proposal|apply|review|archive|strict>   Mode for metadata (default: strict)
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --out <path>           Output report path (default: evidence/gates/void-protocol-check.json)
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
mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/void-protocol-check.json"
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

discover_void_enabled() {
  local discovery="${project_root}/scripts/config-discovery.sh"
  if [[ -n "${DEVBOOKS_VOID_ENABLED:-}" ]]; then
    printf '%s' "${DEVBOOKS_VOID_ENABLED}"
    return 0
  fi
  if [[ -f "$discovery" ]]; then
    bash "$discovery" "$project_root" 2>/dev/null \
      | awk -F= '$1=="VOID_ENABLED" && !found { print $2; found=1 }'
    return 0
  fi
  printf '%s' ""
  return 0
}

next_action=""
state=""
if [[ -f "$proposal_file" ]]; then
  next_action="$(extract_front_matter_value "$proposal_file" "next_action")"
  state="$(extract_front_matter_value "$proposal_file" "state")"
fi

required=false
if [[ "$next_action" == "Void" ]]; then
  required=true
fi

checks=("next_action")
artifacts=()
missing=()

void_dir="${change_dir}/void"
report_next_action="DevBooks"

if [[ "$required" == true ]]; then
  report_next_action="Void"
  checks+=("void-artifacts")

  # Void must be enabled by config to be a legal next_action.
  void_enabled="$(discover_void_enabled)"
  if [[ "$void_enabled" != "true" ]]; then
    missing+=("void.enabled is not enabled in config (VOID_ENABLED!=true), but next_action=Void was requested")
  fi

  if [[ ! -d "$void_dir" ]]; then
    missing+=("missing void/ directory: ${void_dir}")
  fi

  research="${void_dir}/research_report.md"
  adr="${void_dir}/ADR.md"
  status_yaml="${void_dir}/void.yaml"

  for f in "$research" "$adr" "$status_yaml"; do
    if [[ ! -f "$f" ]]; then
      missing+=("missing Void artifact: ${f}")
    else
      rel="${f#"${change_dir}"/}"
      artifacts+=("$rel")
      if [[ ! -s "$f" ]]; then
        missing+=("Void artifact is empty: ${f}")
      fi
    fi
  done

  freeze_status=""
  if [[ -f "$status_yaml" ]]; then
    freeze_status="$(awk -F: '$1 ~ /^status$/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); gsub(/["'"'"']/, "", $2); print $2; exit }' "$status_yaml" 2>/dev/null || true)"
    case "$freeze_status" in
      frozen|thawed) ;;
      "") missing+=("void.yaml missing status (expected frozen|thawed): ${status_yaml}") ;;
      *) missing+=("void.yaml invalid status (expected frozen|thawed): ${status_yaml} => ${freeze_status}") ;;
    esac
  fi

  # Freeze must block downstream progression.
  if [[ "$freeze_status" == "frozen" ]]; then
    case "$state" in
      in_progress|review|completed|archived)
        missing+=("state cannot progress while void.status=frozen (state=${state})")
        ;;
    esac
  fi
fi

status="pass"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="fail"
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
  "gate_id": "G0",
  "mode": "$(json_escape "$mode")",
  "check_id": "void-protocol-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "state": "$(json_escape "$state")",
    "next_action": "$(json_escape "$next_action")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${missing_json},
  "next_action": "$(json_escape "$report_next_action")"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "Void protocol check failed: $out_file"
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi

exit 0
