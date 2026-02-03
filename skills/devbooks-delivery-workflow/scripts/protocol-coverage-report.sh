#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: protocol-coverage-report.sh <change-id> [options]

Generate DevBooks Protocol v1.1 coverage report JSON from the coverage mapping contract.

Options:
  --project-root <dir>  Project root (default: pwd)
  --change-root <dir>   Change root (default: changes)
  --truth-root <dir>    Truth root (default: specs)
  --mapping <path>      Override mapping path (default: <truth-root>/protocol-core/protocol-v1.1-coverage-mapping.yaml)
  --out <path>          Output path (default: evidence/gates/protocol-v1.1-coverage.report.json under change dir)
  -h, --help            Show this help message

Exit codes:
  0 - report written, status=pass
  1 - report written, status=warn|fail
  2 - usage error
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

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
mapping_override=""
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
    --mapping)
      mapping_override="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

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

if [[ ! -d "$change_dir" ]]; then
  echo "error: missing change directory: ${change_dir}" >&2
  exit 2
fi

mapping_path=""
if [[ -n "$mapping_override" ]]; then
  if [[ "$mapping_override" = /* ]]; then
    mapping_path="$mapping_override"
  else
    mapping_path="${project_root}/${mapping_override#/}"
  fi
else
  mapping_path="${truth_dir}/protocol-core/protocol-v1.1-coverage-mapping.yaml"
fi

if [[ ! -f "$mapping_path" ]]; then
  echo "error: missing mapping file: ${mapping_path}" >&2
  exit 2
fi

mkdir -p "${change_dir}/evidence/gates"

if [[ -z "$out_path" ]]; then
  out_file="${change_dir}/evidence/gates/protocol-v1.1-coverage.report.json"
else
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

trim_value() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

strip_quotes() {
  local v
  v="$(trim_value "$1")"
  v="${v#\"}"
  v="${v%\"}"
  v="${v#\'}"
  v="${v%\'}"
  printf '%s' "$v"
}

yaml_top_scalar() {
  local key="$1"
  awk -v k="$key" '
    $0 ~ ("^" k ":[[:space:]]*") {
      sub(("^" k ":[[:space:]]*"), "", $0)
      print $0
      exit
    }
  ' "$mapping_path" 2>/dev/null || true
}

to_abs_project() {
  local p="$1"
  if [[ -z "$p" ]]; then
    printf '%s' ""
    return 0
  fi
  if [[ "$p" = /* ]]; then
    printf '%s' "$p"
    return 0
  fi
  p="${p#/}"
  printf '%s' "${project_root}/${p}"
}

strip_fragment() {
  local p="$1"
  p="${p%%#*}"
  printf '%s' "$p"
}

resolve_ref() {
  local token="$1"
  token="$(strip_fragment "$token")"

  if [[ "$token" == truth://* ]]; then
    printf '%s' "${truth_dir}/${token#truth://}"
    return 0
  fi
  if [[ "$token" == change://* ]]; then
    local rest="${token#change://}"
    # Allow both change://<change-id>/<path> and change://<path>
    if [[ "$rest" == "${change_id}/"* ]]; then
      rest="${rest#${change_id}/}"
    fi
    printf '%s' "${change_dir}/${rest}"
    return 0
  fi
  if [[ "$token" == capability://* ]]; then
    # capability:// is semantic-only here; cannot be resolved to a file path without registry.
    printf '%s' ""
    return 0
  fi

  # Default: treat as project-relative
  to_abs_project "$token"
}

resolve_evidence() {
  local token="$1"
  token="$(strip_fragment "$token")"

  if [[ "$token" == truth://* || "$token" == change://* || "$token" == capability://* ]]; then
    resolve_ref "$token"
    return 0
  fi

  if [[ "$token" = /* ]]; then
    printf '%s' "$token"
    return 0
  fi

  token="${token#/}"
  printf '%s' "${change_dir}/${token}"
}

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

sha256_file() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" 2>/dev/null | awk '{print $1}'
    return 0
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" 2>/dev/null | awk '{print $1}'
    return 0
  fi
  return 1
}

design_source_path_raw="$(strip_quotes "$(yaml_top_scalar "design_source_path")")"
design_source_sha_expected="$(strip_quotes "$(yaml_top_scalar "design_source_sha256")")"

design_source_abs="$(to_abs_project "$design_source_path_raw")"
design_source_sha_actual=""
design_source_exists=false

if [[ -n "$design_source_abs" && -f "$design_source_abs" ]]; then
  design_source_exists=true
  design_source_sha_actual="$(sha256_file "$design_source_abs" || true)"
fi

design_sha_matches=false
if [[ "$design_source_exists" == true && -n "$design_source_sha_actual" && -n "$design_source_sha_expected" ]]; then
  if [[ "$design_source_sha_actual" == "$design_source_sha_expected" ]]; then
    design_sha_matches=true
  fi
fi

items_tmp="${out_file}.items.tmp.$$"
trap 'rm -f "$items_tmp" 2>/dev/null || true' EXIT
: >"$items_tmp"

items_first=true

must_total=0
must_covered=0
should_total=0
should_covered=0
uncovered=0

append_item() {
  local item_json="$1"
  if [[ "$items_first" == true ]]; then
    items_first=false
  else
    printf '%s\n' "," >>"$items_tmp"
  fi
  printf '%s' "$item_json" >>"$items_tmp"
}

count_item() {
  local keyword="$1"
  local covered_flag="$2"

  case "$keyword" in
    MUST)
      must_total=$((must_total + 1))
      if [[ "$covered_flag" == true ]]; then
        must_covered=$((must_covered + 1))
      fi
      ;;
    SHOULD)
      should_total=$((should_total + 1))
      if [[ "$covered_flag" == true ]]; then
        should_covered=$((should_covered + 1))
      fi
      ;;
  esac

  if [[ "$covered_flag" != true ]]; then
    uncovered=$((uncovered + 1))
  fi
}

# Synthetic guard item: design source SHA256 match
{
  artifacts_json="$(json_array "$mapping_path" "$design_source_path_raw")"
  anchors_json="$(json_array "contract:protocol-v1.1-coverage-mapping")"
  evidence_json="[]"

  covered_flag=false
  [[ "$design_sha_matches" == true ]] && covered_flag=true

  item_json="$(cat <<EOF
{
  "id": "DESIGN-SOURCE-SHA256-MATCH",
  "keyword": "MUST",
  "line": 1,
  "text": "design_source_sha256 must match SHA256(design_source_path)",
  "covered": $( [[ "$covered_flag" == true ]] && printf 'true' || printf 'false' ),
  "artifacts": ${artifacts_json},
  "anchors": ${anchors_json},
  "evidence": ${evidence_json},
  "deviation": ""
}
EOF
)"
  append_item "$item_json"
  count_item "MUST" "$covered_flag"
}

item_id=""
item_keyword=""
item_line=""
item_text=""
deviation=""
in_section=""
artifacts=()
anchors=()
evidence=()

flush_item() {
  if [[ -z "$item_id" ]]; then
    return 0
  fi

  local -a reasons=()

  if [[ ${#artifacts[@]} -eq 0 ]]; then
    reasons+=("missing artifacts[]")
  else
    local a
    for a in "${artifacts[@]}"; do
      local resolved
      resolved="$(resolve_ref "$a")"
      if [[ -z "$resolved" || ! -e "$resolved" ]]; then
        reasons+=("unresolvable artifact: ${a}")
      fi
    done
  fi

  if [[ ${#anchors[@]} -eq 0 ]]; then
    reasons+=("missing anchors[]")
  fi

  if [[ ${#evidence[@]} -eq 0 ]]; then
    reasons+=("missing evidence[]")
  else
    local e
    for e in "${evidence[@]}"; do
      local resolved
      resolved="$(resolve_evidence "$e")"
      if [[ -z "$resolved" || ! -e "$resolved" ]]; then
        reasons+=("missing evidence: ${e}")
      fi
    done
  fi

  local covered_flag=false
  if [[ ${#reasons[@]} -eq 0 ]]; then
    covered_flag=true
  fi

  local artifacts_json="[]"
  local anchors_json="[]"
  local evidence_json="[]"

  if [[ ${#artifacts[@]} -gt 0 ]]; then
    artifacts_json="$(json_array "${artifacts[@]}")"
  fi
  if [[ ${#anchors[@]} -gt 0 ]]; then
    anchors_json="$(json_array "${anchors[@]}")"
  fi
  if [[ ${#evidence[@]} -gt 0 ]]; then
    evidence_json="$(json_array "${evidence[@]}")"
  fi

  local deviation_value
  deviation_value="$(json_escape "${deviation:-}")"

  local item_json
  item_json="$(cat <<EOF
{
  "id": "$(json_escape "$item_id")",
  "keyword": "$(json_escape "$item_keyword")",
  "line": ${item_line:-1},
  "text": "$(json_escape "$item_text")",
  "covered": $( [[ "$covered_flag" == true ]] && printf 'true' || printf 'false' ),
  "artifacts": ${artifacts_json},
  "anchors": ${anchors_json},
  "evidence": ${evidence_json},
  "deviation": "${deviation_value}"
}
EOF
)"

  append_item "$item_json"
  count_item "$item_keyword" "$covered_flag"

  item_id=""
  item_keyword=""
  item_line=""
  item_text=""
  deviation=""
  in_section=""
  artifacts=()
  anchors=()
  evidence=()
}

in_items=false

while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="${raw%$'\r'}"

  if [[ "$line" == "items:" ]]; then
    in_items=true
    continue
  fi

  if [[ "$in_items" != true ]]; then
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]+-[[:space:]]id:[[:space:]] ]]; then
    flush_item
    item_id="$(strip_quotes "${line#*- id:}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]+keyword:[[:space:]] ]]; then
    item_keyword="$(strip_quotes "${line#*keyword:}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]+line:[[:space:]] ]]; then
    item_line="$(strip_quotes "${line#*line:}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]+text:[[:space:]] ]]; then
    item_text="$(strip_quotes "${line#*text:}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]+deviation:[[:space:]] ]]; then
    deviation="$(strip_quotes "${line#*deviation:}")"
    continue
  fi

  case "$line" in
    "    artifacts:"*)
      in_section="artifacts"
      continue
      ;;
    "    anchors:"*)
      in_section="anchors"
      continue
      ;;
    "    evidence:"*)
      in_section="evidence"
      continue
      ;;
  esac

  if [[ "$line" =~ ^[[:space:]]+-[[:space:]] ]]; then
    value="$(strip_quotes "${line#*- }")"
    case "$in_section" in
      artifacts) artifacts+=("$value") ;;
      anchors) anchors+=("$value") ;;
      evidence) evidence+=("$value") ;;
    esac
  fi
done <"$mapping_path"

flush_item

status="pass"
if [[ $uncovered -gt 0 ]]; then
  status="fail"
fi

next_action="DevBooks"

summary_json="$(cat <<EOF
{
  "must_total": ${must_total},
  "must_covered": ${must_covered},
  "should_total": ${should_total},
  "should_covered": ${should_covered},
  "uncovered": ${uncovered},
  "design_source_sha256_expected": "$(json_escape "${design_source_sha_expected:-}")",
  "design_source_sha256_actual": "$(json_escape "${design_source_sha_actual:-}")",
  "design_source_exists": $( [[ "$design_source_exists" == true ]] && printf 'true' || printf 'false' )
}
EOF
)"

artifacts_top="$(json_array "$mapping_path" "${design_source_path_raw:-}")"

tmp="${out_file}.tmp.$$"
mkdir -p "$(dirname "$out_file")"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(iso_now)")",
  "design_source_path": "$(json_escape "${design_source_path_raw:-}")",
  "design_source_sha256": "$(json_escape "${design_source_sha_expected:-}")",
  "summary": ${summary_json},
  "items": [
$(cat "$items_tmp")
  ],
  "next_action": "$(json_escape "$next_action")",
  "artifacts": ${artifacts_top}
}
EOF

mv -f "$tmp" "$out_file"

if [[ "$status" == "pass" ]]; then
  exit 0
fi
exit 1

