#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'EOF' >&2
usage: reference-integrity-check.sh <change-id> [options]

Scan text files for semantic references and validate:
- Resolvability (target exists)
- State legality (Truth must not depend on Draft)

Supported schemes:
  - truth://<path>
  - change://<change-id>/<relpath>
  - capability://<capability-id>

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change packages root (default: changes)
  --truth-root <dir>    Truth root directory (default: specs)
  --scan-root <path>    Override scan root (default: current change package dir)
  -h, --help            Show this help message

Output (fixed):
  - <change-dir>/evidence/gates/reference-integrity.report.json

Exit codes:
  0 - pass (no violations)
  1 - fail (violations found)
  2 - usage error or runtime error
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
scan_root=""

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
    --scan-root)
      scan_root="${2:-}"
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
  exit 2
fi

out_file="${change_dir}/evidence/gates/reference-integrity.report.json"
mkdir -p "$(dirname "$out_file")"

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

to_relpath() {
  local abs="$1"
  case "$abs" in
    "${project_root}/"*)
      printf '%s' "${abs#"${project_root}"/}"
      ;;
    *)
      printf '%s' "$abs"
      ;;
  esac
}

strip_ref_punct() {
  local token="$1"
  while [[ -n "$token" ]]; do
    case "${token: -1}" in
      ')'|']'|'}'|','|'.'|';'|':'|'"'|\'|'`')
        token="${token%?}"
        ;;
      *)
        break
        ;;
    esac
  done
  printf '%s' "$token"
}

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

capability_registry_path() {
  printf '%s' "${truth_dir}/_meta/capabilities.yaml"
}

lookup_capability() {
  local cap_id="$1"
  local registry="$2"

  if [[ ! -f "$registry" ]]; then
    return 1
  fi

  awk -v id="$cap_id" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s; }
    BEGIN { in_caps=0; cur=""; in_alias=0; }
    /^capabilities:[[:space:]]*$/ { in_caps=1; next }
    in_caps {
      if ($0 ~ /^[^[:space:]]/) { exit }
      if ($0 ~ /^  [A-Za-z0-9_.-]+:[[:space:]]*$/) {
        cur=$0
        sub(/^  /, "", cur)
        sub(/:.*/, "", cur)
        in_alias=0
        next
      }
      if (cur == "") { next }

      if (cur == id && $0 ~ /^    path:[[:space:]]*/) {
        v=$0
        sub(/^    path:[[:space:]]*/, "", v)
        v=trim(v)
        sub(/^"/, "", v); sub(/"$/, "", v)
        sub(/\/$/, "", v)
        print "FOUND|" v
        exit
      }

      if ($0 ~ /^    aliases:[[:space:]]*/) {
        v=$0
        sub(/^    aliases:[[:space:]]*/, "", v)
        v=trim(v)
        if (v ~ /^\[.*\]$/) {
          gsub(/^\[/, "", v); gsub(/\]$/, "", v)
          n=split(v, a, /,/)
          for (i=1; i<=n; i++) {
            t=trim(a[i])
            sub(/^"/, "", t); sub(/"$/, "", t)
            if (t == id) {
              print "ALIAS|" cur
              exit
            }
          }
          next
        }
        if (v == "") {
          in_alias=1
        } else {
          in_alias=0
        }
        next
      }

      if (in_alias == 1) {
        if ($0 ~ /^      -[[:space:]]*/) {
          t=$0
          sub(/^      -[[:space:]]*/, "", t)
          t=trim(t)
          sub(/^"/, "", t); sub(/"$/, "", t)
          if (t == id) {
            print "ALIAS|" cur
            exit
          }
          next
        }
        if ($0 !~ /^      /) {
          in_alias=0
        }
      }
    }
  ' "$registry" 2>/dev/null
}

items_json=""
violations_json=""
items_first=true
violations_first=true

files_scanned=0
refs_found=0
violations_count=0

add_item() {
  local source_path="$1"
  local source_line="$2"
  local ref_text="$3"
  local scheme="$4"
  local resolved_path="$5"
  local resolved_state="$6"
  local status="$7"
  local reason="$8"

  local src_out res_out
  src_out="$(to_relpath "$source_path")"
  res_out=""
  if [[ -n "$resolved_path" ]]; then
    res_out="$(to_relpath "$resolved_path")"
  fi

  local item
  item="{\"source_path\":\"$(json_escape "$src_out")\",\"source_line\":${source_line},\"ref_text\":\"$(json_escape "$ref_text")\",\"scheme\":\"$(json_escape "$scheme")\",\"resolved_path\":\"$(json_escape "$res_out")\",\"resolved_state\":\"$(json_escape "$resolved_state")\",\"status\":\"$(json_escape "$status")\",\"reason\":\"$(json_escape "$reason")\"}"

  if [[ "$items_first" == true ]]; then
    items_first=false
  else
    items_json+=","
  fi
  items_json+="${item}"

  refs_found=$((refs_found + 1))

  if [[ "$status" != "pass" ]]; then
    violations_count=$((violations_count + 1))
    if [[ "$violations_first" == true ]]; then
      violations_first=false
    else
      violations_json+=","
    fi
    violations_json+="${item}"
  fi
}

resolve_truth_ref() {
  local ref="$1"
  local path="${ref#truth://}"
  path="${path#/}"
  printf '%s' "${truth_dir}/${path}"
}

resolve_change_ref() {
  local ref="$1"
  local rest="${ref#change://}"
  rest="${rest#/}"
  local ref_change_id="${rest%%/*}"
  local rel="${rest#*/}"
  if [[ "$ref_change_id" == "$rest" ]]; then
    rel=""
  fi
  printf '%s\n' "$ref_change_id" "$rel"
}

process_ref() {
  local source_file="$1"
  local line_no="$2"
  local ref="$3"

  local scheme="${ref%%://*}"
  local resolved_path=""
  local resolved_state=""
  local status="pass"
  local reason="ok"

  case "$scheme" in
    truth)
      resolved_path="$(resolve_truth_ref "$ref")"
      resolved_state="truth"
      if [[ ! -e "$resolved_path" ]]; then
        status="fail"
        reason="unresolved_reference"
      fi
      ;;
    change)
      local ref_change_id rel
      ref_change_id=""
      rel=""
      {
        read -r ref_change_id
        read -r rel
      } < <(resolve_change_ref "$ref")

      if [[ -z "$ref_change_id" ]]; then
        status="fail"
        reason="unresolved_reference"
      else
        local candidate_archive candidate_draft
        candidate_archive="${change_root_dir}/archive/${ref_change_id}"
        candidate_draft="${change_root_dir}/${ref_change_id}"

        if [[ -n "$rel" ]]; then
          if [[ -e "${candidate_archive}/${rel}" ]]; then
            resolved_path="${candidate_archive}/${rel}"
            resolved_state="archive"
          elif [[ -e "${candidate_draft}/${rel}" ]]; then
            resolved_path="${candidate_draft}/${rel}"
            resolved_state="draft"
          else
            status="fail"
            reason="unresolved_reference"
          fi
        else
          if [[ -d "${candidate_archive}" ]]; then
            resolved_path="${candidate_archive}"
            resolved_state="archive"
          elif [[ -d "${candidate_draft}" ]]; then
            resolved_path="${candidate_draft}"
            resolved_state="draft"
          else
            status="fail"
            reason="unresolved_reference"
          fi
        fi

        if [[ "$status" == "pass" ]]; then
          case "$source_file" in
            "${truth_dir}/"*)
              if [[ "$resolved_state" == "draft" ]]; then
                status="fail"
                reason="truth_depends_on_draft"
              fi
              ;;
          esac
        fi
      fi
      ;;
    capability)
      local cap_id="${ref#capability://}"
      cap_id="${cap_id#/}"
      cap_id="${cap_id%/}"

      local registry
      registry="$(capability_registry_path)"
      if [[ ! -f "$registry" ]]; then
        status="fail"
        reason="capability_registry_missing"
        resolved_state="truth"
      else
        local result
        result="$(lookup_capability "$cap_id" "$registry" || true)"
        if [[ -z "$result" ]]; then
          status="fail"
          reason="unresolved_reference"
        else
          local kind="${result%%|*}"
          local value="${result#*|}"

          if [[ "$kind" == "ALIAS" ]]; then
            status="fail"
            reason="unsupported_alias"
            resolved_state="truth"
          elif [[ "$kind" != "FOUND" || -z "$value" ]]; then
            status="fail"
            reason="unresolved_reference"
          else
            value="${value%/}"
            resolved_path="${truth_dir}/${value}"
            resolved_state="truth"
            if [[ ! -d "$resolved_path" ]]; then
              status="fail"
              reason="unresolved_reference"
            fi
          fi
        fi
      fi
      ;;
    *)
      status="fail"
      reason="unknown_scheme"
      ;;
  esac

  add_item "$source_file" "$line_no" "$ref" "$scheme" "$resolved_path" "$resolved_state" "$status" "$reason"
}

scan_file() {
  local file="$1"
  local is_markdown=false
  case "$file" in
    *.md) is_markdown=true ;;
  esac

  files_scanned=$((files_scanned + 1))

  local in_fence=false
  local line_no=0
  # shellcheck disable=SC2094
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))

    if [[ "$is_markdown" == true ]]; then
      if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
        if [[ "$in_fence" == false ]]; then
          in_fence=true
        else
          in_fence=false
        fi
        continue
      fi
      if [[ "$in_fence" == true ]]; then
        continue
      fi
    else
      # For YAML/JSON, ignore comment-only lines to avoid false positives from
      # commented examples (e.g., upstream_claims templates).
      if [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
      fi
    fi

    # NOTE: Avoid per-line process substitution (< <(...)) here; bash 3.2 on macOS
    # can hit Trace/BPT traps when scanning large UTF-8 markdown files repeatedly.
    local refs
    refs="$(printf '%s' "$line" | grep -oE '(truth|change|capability)://[^[:space:]<>]+' 2>/dev/null || true)"
    [[ -n "$refs" ]] || continue

    while IFS= read -r ref_raw || [[ -n "$ref_raw" ]]; do
      [[ -n "$ref_raw" ]] || continue
      local ref
      ref="$(strip_ref_punct "$ref_raw")"
      [[ -n "$ref" ]] || continue
      process_ref "$file" "$line_no" "$ref"
    done <<<"$refs"
  done <"$file"
}

scan_dir="$change_dir"
if [[ -n "$scan_root" ]]; then
  if [[ "$scan_root" = /* ]]; then
    scan_dir="$scan_root"
  else
    scan_dir="${project_root}/${scan_root}"
  fi
fi

if [[ ! -d "$scan_dir" ]]; then
  echo "error: scan root is not a directory: ${scan_dir}" >&2
  exit 2
fi

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  scan_file "$file"
done < <(
  find "$scan_dir" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
    ! -path "*/.git/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/evidence/*" \
    2>/dev/null | sort
)

report_status="pass"
exit_code=0
if [[ "$violations_count" -gt 0 ]]; then
  report_status="fail"
  exit_code=1
fi

{
  printf '{'
  printf '"schema_version":"1.0.0",'
  printf '"generated_at":"%s",' "$(json_escape "$(iso_now)")"
  printf '"status":"%s",' "$(json_escape "$report_status")"
  printf '"summary":{'
  printf '"files_scanned":%d,' "$files_scanned"
  printf '"refs_found":%d,' "$refs_found"
  printf '"violations_count":%d' "$violations_count"
  printf '},'
  printf '"items":[%s],' "$items_json"
  printf '"violations":[%s]' "$violations_json"
  printf '}\n'
} >"$out_file"

exit "$exit_code"
