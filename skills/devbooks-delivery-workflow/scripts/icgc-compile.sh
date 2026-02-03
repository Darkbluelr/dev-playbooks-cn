#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: icgc-compile.sh <change-id> [options]

ICGC compiler (Intent → Contract → Gates):
  - Ensure completion.contract.yaml exists (scaffold if missing)
  - Align proposal metadata:
      - completion_contract (relative path)
      - deliverable_quality (must equal contract.intent.deliverable_quality)
      - required_gates (derived deterministically)

By default this script runs in dry-run mode and only writes a report.

Options:
  --apply               Apply changes to proposal.md (default: dry-run)
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change root directory (default: changes)
  --truth-root <dir>    Truth root directory (default: specs)
  --out <path>          Output report path (default: evidence/gates/icgc-compile.json)
  -h, --help            Show help

Exit codes:
  0 - pass (or dry-run)
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

apply=false
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
    --apply)
      apply=true
      shift
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
  errorf "missing change directory: ${change_dir}"
  exit 1
fi

proposal_file="${change_dir}/proposal.md"
contract_file="${change_dir}/completion.contract.yaml"

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/icgc-compile.json"
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

read_contract_quality() {
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

actions=()
errors=()

if [[ ! -f "$contract_file" ]]; then
  template="${project_root}/templates/dev-playbooks/changes/completion.contract.yaml"
  if [[ -f "$template" ]]; then
    if [[ "$apply" == true ]]; then
      cp "$template" "$contract_file"
      actions+=("created completion.contract.yaml from template")
    else
      actions+=("would create completion.contract.yaml from template")
    fi
  else
    errors+=("missing completion.contract.yaml and template not found: ${template}")
  fi
fi

if [[ ! -f "$proposal_file" ]]; then
  errors+=("missing proposal.md: ${proposal_file}")
fi

contract_quality=""
if [[ -f "$contract_file" ]]; then
  contract_quality="$(read_contract_quality "$contract_file")"
  if [[ -z "$contract_quality" ]]; then
    errors+=("completion.contract.yaml missing intent.deliverable_quality")
  fi
fi

# Derive required gates
derive_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
derive_script="${derive_script_dir}/required-gates-derive.sh"
if [[ ! -x "$derive_script" ]]; then
  errors+=("missing required-gates-derive.sh: ${derive_script}")
fi

derive_report="${change_dir}/evidence/gates/required-gates-derive.json"
derived_gates=()
if [[ ${#errors[@]} -eq 0 ]]; then
  "$derive_script" "$change_id" --project-root "$project_root" --change-root "$change_root" --truth-root "$truth_root" --out "evidence/gates/required-gates-derive.json" >/dev/null || true
  if [[ ! -f "$derive_report" ]]; then
    errors+=("missing derived report after running derivation: ${derive_report}")
  elif command -v node >/dev/null 2>&1; then
    while IFS= read -r g; do
      [[ -n "$g" ]] && derived_gates+=("$g")
    done < <(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));(o.derived_required_gates||[]).forEach(g=>process.stdout.write(String(g)+"\n"));' "$derive_report" 2>/dev/null || true)
  else
    errors+=("node not found; cannot read derived_gates from JSON report")
  fi
fi

if [[ "$apply" == true && ${#errors[@]} -eq 0 ]]; then
  # Patch proposal front matter in-place (minimal YAML subset, only replace scalar keys + required_gates list)
  tmp="${proposal_file}.tmp.$$"
  in_yaml=false
  replaced_contract=false
  replaced_quality=false
  replaced_gates=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "---" && "$in_yaml" == false ]]; then
      in_yaml=true
      printf '%s\n' "$line" >>"$tmp"
      continue
    fi
    if [[ "$line" == "---" && "$in_yaml" == true ]]; then
      # Ensure missing keys are appended before closing front matter
      if [[ "$replaced_contract" != true ]]; then
        printf '%s\n' "completion_contract: completion.contract.yaml" >>"$tmp"
      fi
      if [[ "$replaced_quality" != true ]]; then
        printf '%s\n' "deliverable_quality: ${contract_quality}" >>"$tmp"
      fi
      if [[ "$replaced_gates" != true ]]; then
        printf '%s\n' "required_gates:" >>"$tmp"
        for g in "${derived_gates[@]}"; do
          printf '%s\n' "  - ${g}" >>"$tmp"
        done
      fi
      printf '%s\n' "$line" >>"$tmp"
      in_yaml=false
      continue
    fi

    if [[ "$in_yaml" == true ]]; then
      if [[ "$line" =~ ^completion_contract:[[:space:]]* ]]; then
        printf '%s\n' "completion_contract: completion.contract.yaml" >>"$tmp"
        replaced_contract=true
        continue
      fi
      if [[ "$line" =~ ^deliverable_quality:[[:space:]]* ]]; then
        printf '%s\n' "deliverable_quality: ${contract_quality}" >>"$tmp"
        replaced_quality=true
        continue
      fi
      if [[ "$line" =~ ^required_gates:[[:space:]]*$ ]]; then
        printf '%s\n' "required_gates:" >>"$tmp"
        for g in "${derived_gates[@]}"; do
          printf '%s\n' "  - ${g}" >>"$tmp"
        done
        replaced_gates=true
        # skip original list items until a non-indented line or end marker
        while IFS= read -r next_line || [[ -n "$next_line" ]]; do
          if [[ "$next_line" == "---" ]]; then
            # handled by outer loop; push back via temp file is hard, so emit and stop
            printf '%s\n' "$next_line" >>"$tmp"
            in_yaml=false
            break
          fi
          if [[ "$next_line" =~ ^[^[:space:]] ]]; then
            # start of next key; emit and continue normal processing
            printf '%s\n' "$next_line" >>"$tmp"
            break
          fi
        done
        continue
      fi
    fi

    printf '%s\n' "$line" >>"$tmp"
  done <"$proposal_file"

  mv -f "$tmp" "$proposal_file"
  actions+=("updated proposal.md: completion_contract/deliverable_quality/required_gates")
else
  actions+=("dry-run: proposal.md not modified (use --apply)")
fi

status="pass"
if [[ ${#errors[@]} -gt 0 ]]; then
  status="fail"
fi

actions_json="[]"
if [[ ${#actions[@]} -gt 0 ]]; then
  actions_json="$(json_array "${actions[@]}")"
fi
errors_json="[]"
if [[ ${#errors[@]} -gt 0 ]]; then
  errors_json="$(json_array "${errors[@]}")"
fi
derived_json="[]"
if [[ ${#derived_gates[@]} -gt 0 ]]; then
  derived_json="$(json_array "${derived_gates[@]}")"
fi

tmp_report="${out_file}.tmp.$$"
cat >"$tmp_report" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G0",
  "mode": "strict",
  "check_id": "icgc-compile",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "apply": $( [[ "$apply" == true ]] && echo "true" || echo "false" ),
    "contract_quality": "$(json_escape "$contract_quality")"
  },
  "derived_required_gates": ${derived_json},
  "actions": ${actions_json},
  "failure_reasons": ${errors_json},
  "next_action": "DevBooks"
}
EOF
mv -f "$tmp_report" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "ICGC compile failed: $out_file"
  printf '%s\n' "${errors[@]}" >&2
  exit 1
fi

exit 0
