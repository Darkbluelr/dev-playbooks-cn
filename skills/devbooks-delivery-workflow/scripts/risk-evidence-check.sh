#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: risk-evidence-check.sh <change-id> [--mode <proposal|apply|review|archive|strict>] [--project-root <dir>] [--change-root <dir>] [--truth-root <dir>] [--out <path>]

When proposal front matter declares:
  risk_level: medium|high

This check enforces:
  - rollback-plan.md exists under the change directory
  - evidence/risks/dependency-audit.log exists under the change directory

Options:
  --mode <...>          Mode for gate report metadata (default: strict)
  --project-root <dir>  Project root (default: pwd)
  --change-root <dir>   Change root (default: changes)
  --truth-root <dir>    Truth root (default: specs)
  --out <path>          Write a JSON report (optional)
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

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

discover_enabled_packs_csv() {
  local discovery="${project_root}/scripts/config-discovery.sh"
  if [[ -n "${DEVBOOKS_EXTENSIONS_ENABLED_PACKS_CSV:-}" ]]; then
    printf '%s' "${DEVBOOKS_EXTENSIONS_ENABLED_PACKS_CSV}"
    return 0
  fi
  if [[ -f "$discovery" ]]; then
    bash "$discovery" "$project_root" 2>/dev/null \
      | awk -F= '$1=="EXTENSIONS_ENABLED_PACKS_CSV" && !found { print $2; found=1 }'
    return 0
  fi
  printf '%s' ""
  return 0
}

split_csv_to_lines() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    return 0
  fi
  local part
  IFS=',' read -r -a parts <<<"$csv"
  for part in "${parts[@]}"; do
    part="$(trim "$part")"
    [[ -n "$part" ]] || continue
    printf '%s\n' "$part"
  done
}

risk_level="low"
if [[ -f "$proposal_file" ]]; then
  value="$(extract_front_matter_value "$proposal_file" "risk_level")"
  [[ -n "$value" ]] && risk_level="$value"
fi

missing=()
checks=("risk-front-matter")
artifacts=()

if [[ "$risk_level" == "medium" || "$risk_level" == "high" ]]; then
  checks+=("rollback-plan")
  checks+=("dependency-audit")
  checks+=("extension-pack-evidence")

  rollback_plan="${change_dir}/rollback-plan.md"
  if [[ ! -f "$rollback_plan" ]]; then
    missing+=("missing rollback-plan.md (回滚计划): ${rollback_plan}")
  else
    artifacts+=("rollback-plan.md")
  fi

  audit_log="${change_dir}/evidence/risks/dependency-audit.log"
  if [[ ! -f "$audit_log" ]]; then
    missing+=("missing dependency audit log (依赖审计): ${audit_log}")
  else
    artifacts+=("evidence/risks/dependency-audit.log")
  fi

  # Extension Pack: gate_additions for G5 may require additional evidence files.
  enabled_packs_csv="$(discover_enabled_packs_csv)"
  enabled_packs=()
  while IFS= read -r pack_id; do
    enabled_packs+=("$pack_id")
  done < <(split_csv_to_lines "$enabled_packs_csv")

  for pack_id in "${enabled_packs[@]:-}"; do
    [[ -n "$pack_id" ]] || continue
    pack_dir="${truth_dir}/_meta/extension-packs/${pack_id}"
    if [[ ! -d "$pack_dir" ]]; then
      missing+=("enabled pack missing under truth root: ${pack_dir}")
      continue
    fi

    while IFS= read -r mapping_file; do
      [[ -n "$mapping_file" ]] || continue

      # Parse minimal subset:
      # - only gate_additions entries with gate_id=G5
      # - optional when.risk_level list gate
      in_gate_additions=false
      in_entry=false
      in_evidence=false
      in_when=false
      in_when_risk=false
      entry_gate=""
      entry_applies=true
      entry_risk_levels=()

      flush_entry() {
        if [[ "$in_entry" != true ]]; then
          return 0
        fi
        if [[ "$entry_gate" == "G5" && "$entry_applies" == true ]]; then
          # Evidence paths already processed on read.
          :
        fi
        in_entry=false
        in_evidence=false
        in_when=false
        in_when_risk=false
        entry_gate=""
        entry_applies=true
        entry_risk_levels=()
      }

      while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^gate_additions:[[:space:]]*$ ]]; then
          in_gate_additions=true
          continue
        fi

        if [[ "$in_gate_additions" != true ]]; then
          continue
        fi

        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*gate_id:[[:space:]]*(G[0-6])[[:space:]]*$ ]]; then
          flush_entry
          in_entry=true
          entry_gate="${BASH_REMATCH[1]}"
          continue
        fi

        if [[ "$in_entry" != true ]]; then
          continue
        fi

        if [[ "$line" =~ ^[[:space:]]*when:[[:space:]]*$ ]]; then
          in_when=true
          continue
        fi

        if [[ "$in_when" == true && "$line" =~ ^[[:space:]]*risk_level:[[:space:]]*$ ]]; then
          in_when_risk=true
          entry_risk_levels=()
          continue
        fi

        if [[ "$in_when_risk" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*([a-z]+)[[:space:]]*$ ]]; then
          entry_risk_levels+=("${BASH_REMATCH[1]}")
          continue
        fi

        if [[ "$line" =~ ^[[:space:]]*evidence_paths:[[:space:]]*$ ]]; then
          in_evidence=true
          continue
        fi

        if [[ "$in_evidence" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*([^[:space:]].*)$ ]]; then
          p="$(trim "${BASH_REMATCH[1]}")"
          if [[ -n "$p" ]]; then
            # Apply when.risk_level filter (if present)
            if [[ ${#entry_risk_levels[@]} -gt 0 ]]; then
              entry_applies=false
              for rl in "${entry_risk_levels[@]}"; do
                if [[ "$rl" == "$risk_level" ]]; then
                  entry_applies=true
                  break
                fi
              done
            fi

            if [[ "$entry_gate" == "G5" && "$entry_applies" == true ]]; then
              evidence_abs="${change_dir}/${p}"
              if [[ ! -f "$evidence_abs" ]]; then
                missing+=("missing extension pack evidence (${pack_id}): ${evidence_abs}")
              else
                artifacts+=("$p")
              fi
            fi
          fi
          continue
        fi
      done <"$mapping_file"

      flush_entry
    done < <(find "${pack_dir}/mappings" -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | sort)
  done
fi

status="pass"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="fail"
fi

next_action="DevBooks"

if [[ -n "$out_path" ]]; then
  mkdir -p "$(dirname "$out_path")"
  tmp="${out_path}.tmp.$$"

  # NOTE: bash 3.2 + set -u treats "${arr[@]}" as unbound when arr is empty.
  # Build JSON fragments conditionally to avoid expanding empty arrays.
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
  "gate_id": "G5",
  "mode": "$(json_escape "$mode")",
  "check_id": "risk-evidence-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "risk_level": "$(json_escape "$risk_level")",
    "change_dir": "$(json_escape "$change_dir")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${missing_json},
  "next_action": "$(json_escape "$next_action")",
  "missing": ${missing_json}
}
EOF
  mv -f "$tmp" "$out_path"
fi

if [[ "$status" != "pass" ]]; then
  echo "error: risk evidence incomplete (risk_level=${risk_level})" >&2
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi

exit 0
