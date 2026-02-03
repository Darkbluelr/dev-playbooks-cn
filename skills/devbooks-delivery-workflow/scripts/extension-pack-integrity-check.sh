#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: extension-pack-integrity-check.sh <change-id> [options]

Validate enabled Extension Packs (File System Contract + mapping executability).

Inputs:
  - .devbooks/config.yaml: extensions.enabled_packs[] (preferred)
  - or --enabled-packs "<csv>"

Options:
  --project-root <dir>     Project root directory (default: pwd)
  --change-root <dir>      Change root directory (default: changes)
  --truth-root <dir>       Truth root directory (default: specs)
  --enabled-packs <csv>    Override enabled packs list (comma-separated)
  --out <path>             Output report path (default: evidence/gates/extension-pack-integrity-check.json)
  -h, --help               Show this help message

Exit codes:
  0 - pass (or no enabled packs)
  1 - fail (missing/invalid pack or mapping not executable)
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
enabled_packs_csv="${DEVBOOKS_EXTENSIONS_ENABLED_PACKS_CSV:-}"
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
    --enabled-packs)
      enabled_packs_csv="${2:-}"
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

out_file="${change_dir}/evidence/gates/extension-pack-integrity-check.json"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
fi

discover_enabled_packs_csv() {
  if [[ -n "$enabled_packs_csv" ]]; then
    return 0
  fi

  local discovery="${project_root}/scripts/config-discovery.sh"
  if [[ -f "$discovery" ]]; then
    # config-discovery.sh may not be executable; run via bash.
    enabled_packs_csv="$(
      bash "$discovery" "$project_root" 2>/dev/null \
        | awk -F= '$1=="EXTENSIONS_ENABLED_PACKS_CSV" && !found { print $2; found=1 }'
    )"
  fi
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

is_safe_id() {
  local s="$1"
  [[ "$s" =~ ^[a-z0-9][a-z0-9-]*$ ]]
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

to_relpath() {
  local p="$1"
  if [[ "$p" == "${project_root}/"* ]]; then
    printf '%s' "${p#"${project_root}"/}"
    return 0
  fi
  printf '%s' "$p"
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

discover_enabled_packs_csv

checks=("config-enabled-packs")
artifacts=()
failure_reasons=()

enabled_packs=()
while IFS= read -r pack_id; do
  enabled_packs+=("$pack_id")
done < <(split_csv_to_lines "$enabled_packs_csv")

if [[ ${#enabled_packs[@]} -eq 0 ]]; then
  checks+=("no-enabled-packs")
fi

validate_mapping_file() {
  local file="$1"
  local file_rel
  file_rel="$(to_relpath "$file")"
  artifacts+=("$file_rel")

  # Minimal mapping executability: each gate_additions entry must contain gate_id, check_id, evidence_paths[]
  local ok=true

  local entry_gate=""
  local entry_check=""
  local evidence_count=0
  local in_gate_additions=false
  local in_entry=false
  local in_evidence=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^gate_additions:[[:space:]]*$ ]]; then
      in_gate_additions=true
      continue
    fi

    if [[ "$in_gate_additions" != true ]]; then
      continue
    fi

    # New entry begins: "  - gate_id: G5"
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*gate_id:[[:space:]]*(G[0-6])[[:space:]]*$ ]]; then
      # Flush previous entry
      if [[ "$in_entry" == true ]]; then
        if [[ -z "$entry_gate" || -z "$entry_check" || $evidence_count -le 0 ]]; then
          ok=false
          failure_reasons+=("mapping entry missing required fields (gate_id/check_id/evidence_paths): ${file_rel}")
        fi
      fi

      in_entry=true
      in_evidence=false
      entry_gate="${BASH_REMATCH[1]}"
      entry_check=""
      evidence_count=0
      continue
    fi

    if [[ "$in_entry" != true ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*check_id:[[:space:]]*([A-Za-z0-9._-]+)[[:space:]]*$ ]]; then
      entry_check="${BASH_REMATCH[1]}"
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*evidence_paths:[[:space:]]*$ ]]; then
      in_evidence=true
      continue
    fi

    if [[ "$in_evidence" == true && "$line" =~ ^[[:space:]]*-[[:space:]]*([^[:space:]].*)$ ]]; then
      local p
      p="$(trim "${BASH_REMATCH[1]}")"
      if [[ -n "$p" ]]; then
        # Evidence paths must be evidence/** and not contain ".."
        if [[ "$p" != evidence/* || "$p" == *".."* ]]; then
          ok=false
          failure_reasons+=("invalid evidence path in mapping (must be evidence/** and not contain '..'): ${file_rel} => ${p}")
        fi
        evidence_count=$((evidence_count + 1))
      fi
      continue
    fi
  done <"$file"

  # Flush last entry
  if [[ "$in_entry" == true ]]; then
    if [[ -z "$entry_gate" || -z "$entry_check" || $evidence_count -le 0 ]]; then
      ok=false
      failure_reasons+=("mapping entry missing required fields (gate_id/check_id/evidence_paths): ${file_rel}")
    fi
  fi

  if [[ "$ok" != true ]]; then
    return 1
  fi
  return 0
}

required=false
if [[ ${#enabled_packs[@]} -gt 0 ]]; then
  required=true
  for pack_id in "${enabled_packs[@]}"; do
  if ! is_safe_id "$pack_id"; then
    failure_reasons+=("invalid pack_id (expected [a-z0-9-]): ${pack_id}")
    continue
  fi

  local_pack_dir="${truth_dir}/_meta/extension-packs/${pack_id}"
  checks+=("pack:${pack_id}")

  if [[ ! -d "$local_pack_dir" ]]; then
    failure_reasons+=("missing pack directory: $(to_relpath "$local_pack_dir")")
    continue
  fi

  pack_yaml="${local_pack_dir}/pack.yaml"
  if [[ ! -f "$pack_yaml" ]]; then
    failure_reasons+=("missing pack.yaml: $(to_relpath "$pack_yaml")")
  else
    artifacts+=("$(to_relpath "$pack_yaml")")
    # Validate pack.yaml declares matching pack_id + schema_version
    declared_id="$(awk -F: '$1 ~ /^pack_id$/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); gsub(/["'"'"']/, "", $2); print $2; exit }' "$pack_yaml" 2>/dev/null || true)"
    declared_ver="$(awk -F: '$1 ~ /^schema_version$/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); gsub(/["'"'"']/, "", $2); print $2; exit }' "$pack_yaml" 2>/dev/null || true)"
    if [[ -z "$declared_ver" ]]; then
      failure_reasons+=("pack.yaml missing schema_version: $(to_relpath "$pack_yaml")")
    fi
    if [[ -n "$declared_id" && "$declared_id" != "$pack_id" ]]; then
      failure_reasons+=("pack.yaml pack_id mismatch: dir=${pack_id}, declared=${declared_id} ($(to_relpath "$pack_yaml"))")
    fi
  fi

  for must_dir in "mappings" "templates" "gates"; do
    if [[ ! -d "${local_pack_dir}/${must_dir}" ]]; then
      failure_reasons+=("missing required directory: $(to_relpath "${local_pack_dir}/${must_dir}")")
    fi
  done

  glossary_map=""
  if [[ -f "${local_pack_dir}/glossary-map.yaml" ]]; then
    glossary_map="${local_pack_dir}/glossary-map.yaml"
  elif [[ -f "${local_pack_dir}/glossary-map.yml" ]]; then
    glossary_map="${local_pack_dir}/glossary-map.yml"
  elif [[ -f "${local_pack_dir}/glossary-map.json" ]]; then
    glossary_map="${local_pack_dir}/glossary-map.json"
  fi
  if [[ -z "$glossary_map" ]]; then
    failure_reasons+=("missing glossary-map.*: $(to_relpath "$local_pack_dir")")
  else
    artifacts+=("$(to_relpath "$glossary_map")")
  fi

  # Validate mapping files
  if [[ -d "${local_pack_dir}/mappings" ]]; then
    found_any=false
    while IFS= read -r mf; do
      [[ -n "$mf" ]] || continue
      found_any=true
      checks+=("mapping:$(to_relpath "$mf")")
      validate_mapping_file "$mf" || true
    done < <(find "${local_pack_dir}/mappings" -type f \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | sort)

    if [[ "$found_any" != true ]]; then
      failure_reasons+=("pack has no mappings/*.yaml files: $(to_relpath "${local_pack_dir}/mappings")")
    fi
  fi
  done
fi

status="pass"
next_action="DevBooks"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  status="fail"
fi

enabled_packs_json="$(json_array)"
if [[ ${#enabled_packs[@]} -gt 0 ]]; then
  enabled_packs_json="$(json_array "${enabled_packs[@]}")"
fi

checks_json="$(json_array)"
if [[ ${#checks[@]} -gt 0 ]]; then
  checks_json="$(json_array "${checks[@]}")"
fi
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
  "gate_id": "G4",
  "mode": "strict",
  "check_id": "extension-pack-integrity-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "enabled_packs": ${enabled_packs_json}
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${reasons_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "Extension Pack integrity check failed" "$out_file" "status=pass" "status=${status}" "fix packs under truth_root/_meta/extension-packs and rerun"
  exit 1
fi

exit 0
