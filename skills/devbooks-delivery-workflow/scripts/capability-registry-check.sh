#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: capability-registry-check.sh <change-id> [--mode <proposal|apply|review|archive|strict>] [--project-root <dir>] [--truth-root <dir>] [--out <path>]

Reads capability registry from:
  <truth-root>/_meta/capabilities.yaml

Validates:
  1) registry -> path exists
  2) registry -> paths are unique
  3) truth root directories -> all registered (excluding _meta/_staged)

Notes:
  - If registry file is missing or lacks schema_version, the check is treated as "not enforced" and exits 0.
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
truth_root="${truth_root%/}"

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

registry_path="${truth_dir}/_meta/capabilities.yaml"

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

schema_version=""
if [[ -f "$registry_path" ]]; then
  schema_version="$(awk -F: '/^schema_version:/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); gsub(/["'\'']/, "", $2); print $2; exit }' "$registry_path" 2>/dev/null || true)"
fi

checks=("registry-exists" "paths-exist" "paths-unique" "all-registered")
missing_paths=()
unregistered_paths=()
duplicate_paths=()

status="pass"
next_action="DevBooks"
artifacts=()

if [[ ! -f "$registry_path" || -z "$schema_version" ]]; then
  status="warn"
  reason="capability registry not enforced (missing registry file or schema_version)"
  if [[ -n "$out_path" ]]; then
    mkdir -p "$(dirname "$out_path")"
    tmp="${out_path}.tmp.$$"
    cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G6",
  "mode": "$(json_escape "$mode")",
  "check_id": "capability-registry-check",
  "status": "warn",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "truth_dir": "$(json_escape "$truth_dir")",
    "registry_path": "$(json_escape "$registry_path")"
  },
  "checks": $(json_array "${checks[@]}"),
  "artifacts": $(json_array),
  "failure_reasons": $(json_array "$reason"),
  "next_action": "$(json_escape "$next_action")",
  "missing_paths": [],
  "unregistered_paths": [],
  "duplicate_paths": []
}
EOF
    mv -f "$tmp" "$out_path"
  fi
  exit 0
fi

pairs_cmd() {
  awk '
    BEGIN { in_caps=0; id=""; }
    /^capabilities:[[:space:]]*$/ { in_caps=1; next }
    in_caps==1 && /^[^[:space:]#]/ { in_caps=0 }
    in_caps==1 {
      if ($0 ~ /^[[:space:]]{2}[A-Za-z0-9_-]+:[[:space:]]*$/) {
        id=$0
        sub(/^[[:space:]]{2}/,"",id)
        sub(/:[[:space:]]*$/,"",id)
        next
      }
      if ($0 ~ /^[[:space:]]{2}-[[:space:]]capability_id:[[:space:]]*/) {
        id=$0
        sub(/^[[:space:]]{2}-[[:space:]]capability_id:[[:space:]]*/,"",id)
        gsub(/["'\'']/, "", id)
        next
      }
      if ($0 ~ /^[[:space:]]{4}path:[[:space:]]*/) {
        path=$0
        sub(/^[[:space:]]{4}path:[[:space:]]*/,"",path)
        gsub(/["'\'']/, "", path)
        if (id != "") {
          printf "%s\t%s\n", id, path
        }
        next
      }
    }
  ' "$registry_path" 2>/dev/null | sed '/^[[:space:]]*$/d'
}

seen_paths=()
seen_ids=()

while IFS=$'\t' read -r cap_id cap_path; do
  [[ -n "$cap_id" ]] || continue
  [[ -n "$cap_path" ]] || continue
  cap_path="${cap_path%/}/"
  registered_paths+=("$cap_path")

  dup_index=-1
  for i in "${!seen_paths[@]}"; do
    if [[ "${seen_paths[$i]}" == "$cap_path" ]]; then
      dup_index="$i"
      break
    fi
  done
  if [[ "$dup_index" -ge 0 ]]; then
    duplicate_paths+=("duplicate path '${cap_path}' for '${cap_id}' and '${seen_ids[$dup_index]}'")
  else
    seen_paths+=("$cap_path")
    seen_ids+=("$cap_id")
  fi

  if [[ ! -d "${truth_dir}/${cap_path%/}" ]]; then
    missing_paths+=("registry path missing on disk: ${cap_id} -> ${cap_path}")
  fi
done < <(pairs_cmd)

while IFS= read -r dir; do
  [[ -n "$dir" ]] || continue
  base="$(basename "$dir")"
  case "$base" in
    _meta|_staged) continue ;;
  esac
  rel="${base}/"
  registered=false
  for p in "${seen_paths[@]}"; do
    if [[ "$p" == "$rel" ]]; then
      registered=true
      break
    fi
  done
  if [[ "$registered" != true ]]; then
    unregistered_paths+=("truth directory not registered: ${rel}")
  fi
done < <(find "$truth_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

failure_reasons=()
if [[ ${#missing_paths[@]} -gt 0 ]]; then
  status="fail"
  failure_reasons+=("${missing_paths[@]}")
fi
if [[ ${#duplicate_paths[@]} -gt 0 ]]; then
  status="fail"
  failure_reasons+=("${duplicate_paths[@]}")
fi
if [[ ${#unregistered_paths[@]} -gt 0 ]]; then
  status="fail"
  failure_reasons+=("${unregistered_paths[@]}")
fi

if [[ -n "$out_path" ]]; then
  mkdir -p "$(dirname "$out_path")"
  tmp="${out_path}.tmp.$$"
  artifacts=("$(printf '%s' "${registry_path#"$project_root"/}" 2>/dev/null || printf '%s' "$registry_path")")

  # NOTE: bash 3.2 + set -u treats "${arr[@]}" as unbound when arr is empty.
  # Build JSON fragments conditionally to avoid expanding empty arrays.
  checks_json="$(json_array "${checks[@]}")"
  artifacts_json="$(json_array "${artifacts[@]}")"

  failure_reasons_json="[]"
  if [[ ${#failure_reasons[@]} -gt 0 ]]; then
    failure_reasons_json="$(json_array "${failure_reasons[@]}")"
  fi

  missing_paths_json="[]"
  if [[ ${#missing_paths[@]} -gt 0 ]]; then
    missing_paths_json="$(json_array "${missing_paths[@]}")"
  fi

  unregistered_paths_json="[]"
  if [[ ${#unregistered_paths[@]} -gt 0 ]]; then
    unregistered_paths_json="$(json_array "${unregistered_paths[@]}")"
  fi

  duplicate_paths_json="[]"
  if [[ ${#duplicate_paths[@]} -gt 0 ]]; then
    duplicate_paths_json="$(json_array "${duplicate_paths[@]}")"
  fi

  cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G6",
  "mode": "$(json_escape "$mode")",
  "check_id": "capability-registry-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "truth_dir": "$(json_escape "$truth_dir")",
    "registry_path": "$(json_escape "$registry_path")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${failure_reasons_json},
  "next_action": "$(json_escape "$next_action")",
  "missing_paths": ${missing_paths_json},
  "unregistered_paths": ${unregistered_paths_json},
  "duplicate_paths": ${duplicate_paths_json}
}
EOF
  mv -f "$tmp" "$out_path"
fi

if [[ "$status" == "fail" ]]; then
  printf '%s\n' "error: capability registry mismatch" >&2
  printf '%s\n' "${failure_reasons[@]}" >&2
  exit 1
fi

exit 0
