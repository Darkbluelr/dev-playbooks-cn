#!/usr/bin/env bash

set -u
set -o pipefail

usage() {
  cat <<'EOF'
Usage:
  archive-decider.sh CHANGE_ID --project-root PROJECT_ROOT --change-root CHANGE_ROOT --truth-root TRUTH_ROOT [--mode archive|strict] [--output OUTPUT_PATH]

Description:
  Emit a DevBooks G6 archive decider gate report JSON.

Arguments:
  CHANGE_ID                      Change package ID.

Required options:
  --project-root PROJECT_ROOT     Project root directory.
  --change-root CHANGE_ROOT       Change root directory.
  --truth-root TRUTH_ROOT         Truth root directory.

Optional options:
  --mode archive|strict           Mode (default: archive).
  --output OUTPUT_PATH            Override output path (relative paths are resolved from --project-root).
  -h, --help                      Show this help message.
EOF
}

err() {
  printf '%s\n' "$*" >&2
}

emit_error() {
  local message="${1:-unknown error}"
  local expected="${2:-N/A}"
  local actual="${3:-N/A}"
  local fix="${4:-N/A}"
  local source="${BASH_SOURCE[1]-${BASH_SOURCE[0]-archive-decider.sh}}"
  local line="${BASH_LINENO[0]-0}"

  source="${source##*/}"
  err "ERROR: ${message}"
  err "  Location: ${source}:${line}"
  err "  Expected: ${expected}"
  err "  Actual: ${actual}"
  err "  Fix: ${fix}"
}

die_error() {
  emit_error "$@"
  exit 2
}

die_usage() {
  local message="$*"
  emit_error "${message}" "Valid arguments and required values (see --help)" "${message}" "Run with --help and provide required options."
  err ""
  usage >&2
  exit 2
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=skills/devbooks-delivery-workflow/scripts/lib/upstream-claims.sh
source "${script_dir}/lib/upstream-claims.sh"

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

resolve_from_root() {
  local root="$1"
  local path="$2"
  root="${root%/}"
  if [[ "$path" = /* ]]; then
    printf '%s' "$path"
    return 0
  fi
  printf '%s' "${root}/${path}"
}

is_dir() {
  local path="$1"
  [[ -d "$path" ]]
}

canonical_dir() {
  local path="$1"
  (cd "$path" 2>/dev/null && pwd)
}

mtime_epoch() {
  local path="$1"
  local out=""
  if out="$(stat -c %Y "$path" 2>/dev/null)"; then
    printf '%s' "$out"
    return 0
  fi
  if out="$(stat -f %m "$path" 2>/dev/null)"; then
    printf '%s' "$out"
    return 0
  fi
  return 1
}

resolve_contract_path() {
  local raw="$1"
  local candidate=""

  if [[ -z "$raw" ]]; then
    printf '%s' ""
    return 0
  fi

  if [[ "$raw" = /* ]]; then
    printf '%s' "$raw"
    return 0
  fi

  if [[ "$raw" == truth://* ]]; then
    candidate="${truth_root_dir%/}/${raw#truth://}"
    printf '%s' "$candidate"
    return 0
  fi

  raw="${raw#./}"
  candidate="${change_dir%/}/${raw}"
  if [[ -e "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  candidate="${project_root_abs%/}/${raw}"
  if [[ -e "$candidate" ]]; then
    printf '%s' "$candidate"
    return 0
  fi

  printf '%s' "${change_dir%/}/${raw}"
}

normalize_relpath() {
  local path="$1"
  path="$(trim_value "$path")"
  while [[ "$path" == ./* ]]; do
    path="${path#./}"
  done
  path="${path#/}"
  printf '%s' "$path"
}

is_safe_relpath_under_dir() {
  local rel="$1"
  local prefix="$2"
  rel="$(normalize_relpath "$rel")"
  if [[ -z "$rel" ]]; then
    return 1
  fi
  if [[ "$rel" == /* ]]; then
    return 1
  fi
  if [[ "$rel" == ../* || "$rel" == *"/../"* || "$rel" == *"/.." || "$rel" == ".." ]]; then
    return 1
  fi
  if [[ "$rel" != "${prefix}"* ]]; then
    return 1
  fi
  return 0
}

resolve_evidence_path() {
  local raw="$1"
  local rel
  rel="$(normalize_relpath "$raw")"
  printf '%s' "${change_dir%/}/${rel}"
}

markdown_plain_lines() {
  local file="$1"
  awk '
    BEGIN { in_fence=0 }
    {
      line=$0
      sub(/\r$/, "", line)

      if (line ~ /^[[:space:]]*```/) {
        in_fence = !in_fence
        next
      }
      if (line ~ /^[[:space:]]*~~~/) {
        in_fence = !in_fence
        next
      }

      if (in_fence) next
      if (line ~ /^[[:space:]]*>/) next

      print line
    }
  ' "$file" 2>/dev/null || true
}

decision_status_from_proposal() {
  local file="$1"
  local pattern='^- (Decision Status|Decision)[:：] *(Pending|Approved|Revise|Rejected)([[:space:]]|$)'
  markdown_plain_lines "$file" \
    | grep -E "$pattern" 2>/dev/null \
    | head -n 1 \
    | sed -E 's/^- (Decision Status|Decision)[:：] *//'
}

verification_status_from_file() {
  local file="$1"
  local pattern='^- Status[:：] *(Draft|Ready|Done|Archived)([[:space:]]|$)'
  markdown_plain_lines "$file" \
    | grep -E "$pattern" 2>/dev/null \
    | head -n 1 \
    | sed -E 's/^- Status[:：] *//'
}

extract_contract_records() {
  local contract_file="$1"
  awk '
    function trim(s) {
      sub(/^[ \t\r\n]+/, "", s)
      sub(/[ \t\r\n]+$/, "", s)
      return s
    }
    function strip_quotes(s) {
      s = trim(s)
      if (s ~ /^".*"$/) {
        s = substr(s, 2, length(s) - 2)
      } else if (s ~ /^'\''.*'\''$/) {
        s = substr(s, 2, length(s) - 2)
      }
      return s
    }
    function normalize_scalar(s) {
      return strip_quotes(s)
    }

    function reset_item() {
      item_id = ""
      item_path = ""
      item_severity = ""
      delete item_list
      item_list_count = 0
      delete item_tags
      item_tags_count = 0
      delete item_list2
      item_list2_count = 0
      in_list = ""
    }

    function flush_item() {
      if (section == "deliverables") {
        if (item_id != "" && item_path != "") {
          print "deliverable\t" item_id "\t" item_path
        }
      } else if (section == "obligations") {
        if (item_id != "") {
          print "obligation\t" item_id "\t" item_severity
          for (i = 1; i <= item_list_count; i++) {
            if (item_list[i] != "") {
              print "obligation_applies\t" item_id "\t" item_list[i]
            }
          }
          for (i = 1; i <= item_tags_count; i++) {
            if (item_tags[i] != "") {
              print "obligation_tag\t" item_id "\t" item_tags[i]
            }
          }
        }
      } else if (section == "checks") {
        if (item_id != "") {
          print "check\t" item_id
          for (i = 1; i <= item_list_count; i++) {
            if (item_list[i] != "") {
              print "check_covers\t" item_id "\t" item_list[i]
            }
          }
          for (i = 1; i <= item_list2_count; i++) {
            if (item_list2[i] != "") {
              print "check_artifact\t" item_id "\t" item_list2[i]
            }
          }
        }
      }
      reset_item()
    }

    BEGIN {
      section = ""
      upstream_claims_present = 0
      reset_item()
    }

    {
      line = $0
      sub(/\r$/, "", line)

      # Top-level keys (indent 0)
      if (line ~ /^[^[:space:]][^:]*:[[:space:]]*/) {
        flush_item()
        key = line
        sub(/:.*/, "", key)
        if (key == "deliverables" || key == "obligations" || key == "checks" || key == "upstream_claims") {
          section = key
        } else {
          section = ""
        }
        next
      }

      if (section == "") {
        next
      }

      # Item start (indent 2)
      if (line ~ /^  -[[:space:]]*/) {
        flush_item()
        rest = line
        sub(/^  -[[:space:]]*/, "", rest)
        if (rest ~ /^id:[[:space:]]*/) {
          sub(/^id:[[:space:]]*/, "", rest)
          item_id = normalize_scalar(rest)
        }
        if (section == "upstream_claims") {
          upstream_claims_present = 1
        }
        next
      }

      # Item key lines (indent 4)
      if (line ~ /^    [A-Za-z0-9_]+:[[:space:]]*/) {
        in_list = ""
      }

      if (section == "deliverables") {
        if (line ~ /^    id:[[:space:]]*/) {
          rest = line
          sub(/^    id:[[:space:]]*/, "", rest)
          item_id = normalize_scalar(rest)
        } else if (line ~ /^    path:[[:space:]]*/) {
          rest = line
          sub(/^    path:[[:space:]]*/, "", rest)
          item_path = normalize_scalar(rest)
        }
      } else if (section == "obligations") {
        if (line ~ /^    id:[[:space:]]*/) {
          rest = line
          sub(/^    id:[[:space:]]*/, "", rest)
          item_id = normalize_scalar(rest)
        } else if (line ~ /^    severity:[[:space:]]*/) {
          rest = line
          sub(/^    severity:[[:space:]]*/, "", rest)
          item_severity = normalize_scalar(rest)
        } else if (line ~ /^    applies_to:[[:space:]]*$/) {
          in_list = "applies_to"
        } else if (line ~ /^      -[[:space:]]*/ && in_list == "applies_to") {
          rest = line
          sub(/^      -[[:space:]]*/, "", rest)
          item_list[++item_list_count] = normalize_scalar(rest)
        } else if (line ~ /^    tags:[[:space:]]*$/) {
          in_list = "tags"
        } else if (line ~ /^    tags:[[:space:]]*[[][^]]*[]][[:space:]]*$/) {
          rest = line
          sub(/^    tags:[[:space:]]*/, "", rest)
          rest = trim(rest)
          gsub(/^[[]/, "", rest)
          gsub(/[]]$/, "", rest)
          n = split(rest, parts, /,/)
          for (i = 1; i <= n; i++) {
            t = normalize_scalar(parts[i])
            if (t != "") {
              item_tags[++item_tags_count] = t
            }
          }
          in_list = ""
        } else if (line ~ /^      -[[:space:]]*/ && in_list == "tags") {
          rest = line
          sub(/^      -[[:space:]]*/, "", rest)
          item_tags[++item_tags_count] = normalize_scalar(rest)
        }
      } else if (section == "checks") {
        if (line ~ /^    id:[[:space:]]*/) {
          rest = line
          sub(/^    id:[[:space:]]*/, "", rest)
          item_id = normalize_scalar(rest)
        } else if (line ~ /^    covers:[[:space:]]*$/) {
          in_list = "covers"
        } else if (line ~ /^    artifacts:[[:space:]]*$/) {
          in_list = "artifacts"
        } else if (line ~ /^      -[[:space:]]*/ && in_list == "covers") {
          rest = line
          sub(/^      -[[:space:]]*/, "", rest)
          item_list[++item_list_count] = normalize_scalar(rest)
        } else if (line ~ /^      -[[:space:]]*/ && in_list == "artifacts") {
          rest = line
          sub(/^      -[[:space:]]*/, "", rest)
          item_list2[++item_list2_count] = normalize_scalar(rest)
        }
      } else if (section == "upstream_claims") {
        # We only need presence detection here.
      }
    }

    END {
      flush_item()
      if (upstream_claims_present == 1) {
        print "upstream_claims_present\ttrue"
      }
    }
  ' "$contract_file" 2>/dev/null || true
}

list_contains_line() {
  local list="$1"
  local needle="$2"
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == "$needle" ]]; then
      return 0
    fi
  done <<EOF
${list}
EOF
  return 1
}

append_line_list() {
  local current="$1"
  local item="$2"
  if [[ -z "$item" ]]; then
    printf '%s' "$current"
    return 0
  fi
  if [[ -z "$current" ]]; then
    printf '%s' "$item"
    return 0
  fi
  printf '%s' "${current}"$'\n'"${item}"
}

ensure_fix_reason() {
  local reason
  local has_fix="false"
  if [[ "$status" != "fail" ]]; then
    return 0
  fi
  if (( ${#failure_reasons[@]} > 0 )); then
    for reason in "${failure_reasons[@]}"; do
      if [[ "$reason" == *"Fix:"* ]]; then
        has_fix="true"
        break
      fi
    done
  fi
  if [[ "$has_fix" == "true" ]]; then
    return 0
  fi
  if [[ "$completion_contract_present" != "true" ]]; then
    failure_reasons+=("Fix: Add completion.contract.yaml (or completion.contract.yml) under ${change_dir} with deliverables/obligations/checks.")
  elif [[ "$contract_parse_ok" != "true" ]]; then
    failure_reasons+=("Fix: Ensure completion.contract.yaml has deliverables/obligations/checks and re-run archive-decider.sh.")
  elif [[ "$scope_evidence_status" == "fail" ]]; then
    failure_reasons+=("Fix: Generate required scope evidence artifacts under evidence/gates (reference-integrity.report.json, check-completion-contract.log, and docs-consistency.report.json when applicable), then re-run archive-decider.sh.")
  elif [[ "$runbook_structure_status" == "fail" ]]; then
    failure_reasons+=("Fix: Restore required RUNBOOK sections (## Cover View, ## Context Capsule) and re-run runbook-derive.sh, then re-run archive-decider.sh.")
  elif [[ "$freshness_status" == "fail" ]]; then
    failure_reasons+=("Fix: Refresh evidence artifacts so mtime >= covered deliverables, then re-run archive-decider.sh.")
  elif [[ "$state_status" == "fail" ]]; then
    failure_reasons+=("Fix: Close proposal/tasks/verification open items and re-run archive-decider.sh.")
  elif [[ "$upstream_claims_present" == "true" ]]; then
    failure_reasons+=("Fix: Make upstream_claims satisfiable (resolvable set_ref, valid claim, must coverage, subset deferred + resolvable next_action_ref) and re-run archive-decider.sh.")
  else
    failure_reasons+=("Fix: Resolve listed failure_reasons and re-run archive-decider.sh.")
  fi
}

if [[ $# -eq 0 ]]; then
  die_usage "missing CHANGE_ID"
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_id="$1"
shift

if [[ -z "$change_id" || "$change_id" == -* ]]; then
  die_usage "invalid CHANGE_ID: $change_id"
fi

project_root=""
change_root=""
truth_root=""
mode="archive"
output_override=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-root)
      [[ -n "${2:-}" ]] || die_usage "missing value for --project-root"
      project_root="$2"
      shift 2
      ;;
    --change-root)
      [[ -n "${2:-}" ]] || die_usage "missing value for --change-root"
      change_root="$2"
      shift 2
      ;;
    --truth-root)
      [[ -n "${2:-}" ]] || die_usage "missing value for --truth-root"
      truth_root="$2"
      shift 2
      ;;
    --mode)
      [[ -n "${2:-}" ]] || die_usage "missing value for --mode"
      mode="$2"
      shift 2
      ;;
    --output)
      [[ -n "${2:-}" ]] || die_usage "missing value for --output"
      output_override="$2"
      shift 2
      ;;
    *)
      die_usage "unknown argument: $1"
      ;;
  esac
done

[[ -n "$project_root" ]] || die_usage "--project-root is required"
[[ -n "$change_root" ]] || die_usage "--change-root is required"
[[ -n "$truth_root" ]] || die_usage "--truth-root is required"

case "$mode" in
  archive|strict) ;;
  *) die_usage "invalid --mode: $mode (expected archive|strict)" ;;
esac

if ! is_dir "$project_root"; then
  die_error \
    "project root is not a directory" \
    "An existing directory for --project-root" \
    "Not a directory: ${project_root}" \
    "Provide a valid project root directory."
fi

project_root_abs="$(canonical_dir "$project_root")"
if [[ -z "$project_root_abs" ]]; then
  die_error \
    "failed to resolve project root" \
    "Resolvable directory path for --project-root" \
    "Cannot resolve: ${project_root}" \
    "Check path spelling and permissions."
fi

if [[ "$change_root" = /* ]]; then
  change_root_dir="$change_root"
else
  change_root_dir="${project_root_abs%/}/${change_root%/}"
fi

if [[ "$truth_root" = /* ]]; then
  truth_root_dir="$truth_root"
else
  truth_root_dir="${project_root_abs%/}/${truth_root%/}"
fi

change_dir="${change_root_dir%/}/${change_id}"
if [[ ! -d "$change_dir" ]]; then
  die_error \
    "change package directory not found" \
    "Existing change directory at ${change_root_dir%/}/${change_id}" \
    "Missing: ${change_dir}" \
    "Create the change package directory or correct --change-root/CHANGE_ID."
fi

if [[ -n "$output_override" ]]; then
  output_path="$(resolve_from_root "$project_root_abs" "$output_override")"
else
  output_path="${change_dir}/evidence/gates/G6-archive-decider.json"
fi

output_rel_path=""
if [[ "$output_path" == "${change_dir%/}/"* ]]; then
  output_rel_path="${output_path#"${change_dir%/}"/}"
fi

contract_yaml="${change_dir}/completion.contract.yaml"
contract_yml="${change_dir}/completion.contract.yml"
completion_contract_path=""
completion_contract_present="false"

if [[ -f "$contract_yaml" ]]; then
  completion_contract_path="$contract_yaml"
  completion_contract_present="true"
elif [[ -f "$contract_yml" ]]; then
  completion_contract_path="$contract_yml"
  completion_contract_present="true"
fi

status="pass"
next_action="DevBooks"
failure_reasons=()
unmet_obligations=()
freshness_status="pass"
freshness_stale_artifacts=()
freshness_checked_paths=()
scope_evidence_triggered="false"
scope_evidence_status="pass"
scope_evidence_required_artifacts=()
scope_evidence_missing_artifacts=()
scope_evidence_invalid_artifacts=()
docs_consistency_required="false"
docs_consistency_triggers=()
runbook_structure_triggered="false"
runbook_structure_status="pass"
runbook_structure_missing_sections=()
context_capsule_length_triggered="false"
context_capsule_length_status="pass"
context_capsule_nonempty_lines=0
context_capsule_max_nonempty_lines=120
weak_link_obligations=()
weak_link_unmet_obligations=()
state_status="pass"
state_issues=()
upstream_claims_present="false"
artifacts=()
upstream_claims_evaluation_json="[]"

checks=(
  "completion-contract"
  "manual-only-block"
  "unmet-obligations"
  "freshness-evaluation"
  "scope-evidence-bundle"
  "runbook-structure-evaluation"
  "context-capsule-length-evaluation"
  "state-consistency-evaluation"
  "upstream-claims-evaluation"
)

contract_parse_ok="false"
deliverable_ids=()
deliverable_paths=()
obligation_ids=()
obligation_severities=()
obligation_applies=()
obligation_tags=()
check_ids=()
check_covers=()
check_artifacts=()

if [[ "$completion_contract_present" != "true" ]]; then
  status="fail"
  next_action="Bootstrap"
  failure_reasons+=("missing required input: completion.contract.yaml (or completion.contract.yml)")
elif [[ ! -r "$completion_contract_path" ]]; then
  status="fail"
  next_action="Bootstrap"
  failure_reasons+=("completion contract is not readable: ${completion_contract_path}")
else
  current_obligation_idx=-1
  current_check_idx=-1
  while IFS=$'\t' read -r record_kind a b; do
    case "$record_kind" in
      deliverable)
        deliverable_ids+=("$a")
        deliverable_paths+=("$b")
        ;;
      obligation)
        obligation_ids+=("$a")
        obligation_severities+=("$b")
        obligation_applies+=("")
        obligation_tags+=("")
        current_obligation_idx=$((${#obligation_ids[@]} - 1))
        ;;
      obligation_applies)
        if (( current_obligation_idx >= 0 )); then
          obligation_applies[current_obligation_idx]="$(append_line_list "${obligation_applies[current_obligation_idx]}" "$b")"
        fi
        ;;
      obligation_tag)
        if (( current_obligation_idx >= 0 )); then
          obligation_tags[current_obligation_idx]="$(append_line_list "${obligation_tags[current_obligation_idx]}" "$b")"
        fi
        ;;
      check)
        check_ids+=("$a")
        check_covers+=("")
        check_artifacts+=("")
        current_check_idx=$((${#check_ids[@]} - 1))
        ;;
      check_covers)
        if (( current_check_idx >= 0 )); then
          check_covers[current_check_idx]="$(append_line_list "${check_covers[current_check_idx]}" "$b")"
        fi
        ;;
      check_artifact)
        if (( current_check_idx >= 0 )); then
          check_artifacts[current_check_idx]="$(append_line_list "${check_artifacts[current_check_idx]}" "$b")"
        fi
        ;;
      upstream_claims_present)
        upstream_claims_present="true"
        ;;
      *)
        ;;
    esac
  done < <(extract_contract_records "$completion_contract_path")

  if [[ ${#deliverable_ids[@]} -gt 0 && ${#obligation_ids[@]} -gt 0 && ${#check_ids[@]} -gt 0 ]]; then
    contract_parse_ok="true"
  else
    status="fail"
    next_action="Bootstrap"
    failure_reasons+=("failed to parse completion contract (expected deliverables/obligations/checks YAML subset): $completion_contract_path")
  fi
fi

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

read_completion_contract_check_types() {
  local contract="$1"
  awk '
    BEGIN { in_checks=0; in_item=0 }
    /^checks:[[:space:]]*$/ { in_checks=1; next }
    in_checks && /^[^[:space:]]/ { in_checks=0; in_item=0 }
    in_checks && $0 ~ /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { in_item=1; next }
    in_item && $0 ~ /^[[:space:]]+type:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]+type:[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      gsub(/["'"'"']/, "", line)
      if (line != "") print line
      next
    }
  ' "$contract" 2>/dev/null || true
}

enforce_manual_only_block() {
  local proposal_file="${change_dir}/proposal.md"
  if [[ ! -f "$proposal_file" ]]; then
    return 0
  fi
  if [[ "$completion_contract_present" != "true" || -z "$completion_contract_path" || ! -f "$completion_contract_path" ]]; then
    return 0
  fi

  local risk_level
  risk_level="$(extract_front_matter_value "$proposal_file" "risk_level")"
  case "${risk_level}" in
    medium|high) ;;
    *) return 0 ;;
  esac

  local has_any=false
  local has_manual=false
  local has_non_manual=false
  local t
  while IFS= read -r t || [[ -n "$t" ]]; do
    t="$(trim_value "$t")"
    [[ -n "$t" ]] || continue
    has_any=true
    if [[ "$t" == "manual" ]]; then
      has_manual=true
    else
      has_non_manual=true
    fi
  done < <(read_completion_contract_check_types "$completion_contract_path")

  if [[ "$has_any" == true && "$has_manual" == true && "$has_non_manual" != true ]]; then
    status="fail"
    next_action="DevBooks"
    failure_reasons+=("manual-only anchors are forbidden when risk_level=${risk_level} (must include at least one non-manual check type in completion.contract.yaml)")
  fi
}

enforce_manual_only_block

json_extract_string_value() {
  local file="$1"
  local key="$2"
  local match=""
  match="$(grep -Eo "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | head -n 1 || true)"
  if [[ -z "$match" ]]; then
    return 1
  fi
  printf '%s' "$match" | sed -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\\1/"
}

json_extract_number_value() {
  local file="$1"
  local key="$2"
  local match=""
  match="$(grep -Eo "\"${key}\"[[:space:]]*:[[:space:]]*[0-9]+" "$file" 2>/dev/null | head -n 1 || true)"
  if [[ -z "$match" ]]; then
    return 1
  fi
  printf '%s' "$match" | sed -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([0-9]+).*/\\1/"
}

log_extract_kv() {
  local file="$1"
  local key="$2"
  local match=""
  match="$(grep -E "^${key}=" "$file" 2>/dev/null | head -n 1 || true)"
  if [[ -z "$match" ]]; then
    return 1
  fi
  printf '%s' "${match#"${key}"=}"
}

append_scope_invalid() {
  local path="$1"
  local reason="$2"
  if [[ -n "$reason" ]]; then
    scope_evidence_invalid_artifacts+=("${path}: ${reason}")
  else
    scope_evidence_invalid_artifacts+=("${path}")
  fi
}

validate_reference_integrity_report() {
  local rel="evidence/gates/reference-integrity.report.json"
  local abs="${change_dir%/}/${rel}"
  if [[ ! -f "$abs" ]]; then
    scope_evidence_missing_artifacts+=("$rel")
    return 1
  fi
  local status_value=""
  status_value="$(json_extract_string_value "$abs" "status" || true)"
  if [[ -z "$status_value" ]]; then
    append_scope_invalid "$rel" "missing status"
    return 1
  fi
  if [[ "$status_value" != "pass" ]]; then
    append_scope_invalid "$rel" "status=${status_value} (expected pass)"
    return 1
  fi
  local violations_count=""
  violations_count="$(json_extract_number_value "$abs" "violations_count" || true)"
  if [[ -z "$violations_count" ]]; then
    append_scope_invalid "$rel" "missing summary.violations_count"
    return 1
  fi
  if [[ "$violations_count" != "0" ]]; then
    append_scope_invalid "$rel" "violations_count=${violations_count} (expected 0)"
    return 1
  fi
  return 0
}

validate_completion_contract_log() {
  local rel="evidence/gates/check-completion-contract.log"
  local abs="${change_dir%/}/${rel}"
  if [[ ! -f "$abs" ]]; then
    scope_evidence_missing_artifacts+=("$rel")
    return 1
  fi
  local status_value=""
  status_value="$(log_extract_kv "$abs" "status" || true)"
  if [[ -z "$status_value" ]]; then
    append_scope_invalid "$rel" "missing status"
    return 1
  fi
  if [[ "$status_value" != "pass" ]]; then
    append_scope_invalid "$rel" "status=${status_value} (expected pass)"
    return 1
  fi
  local errors_count=""
  errors_count="$(log_extract_kv "$abs" "errors_count" || true)"
  if [[ -z "$errors_count" ]]; then
    append_scope_invalid "$rel" "missing errors_count"
    return 1
  fi
  if [[ "$errors_count" != "0" ]]; then
    append_scope_invalid "$rel" "errors_count=${errors_count} (expected 0)"
    return 1
  fi
  if ! grep -q '^errors=' "$abs" 2>/dev/null; then
    append_scope_invalid "$rel" "missing errors"
    return 1
  fi
  local errors_value=""
  errors_value="$(log_extract_kv "$abs" "errors" || true)"
  if [[ -n "$errors_value" ]]; then
    append_scope_invalid "$rel" "errors is not empty"
    return 1
  fi
  return 0
}

validate_docs_consistency_report() {
  local rel="evidence/gates/docs-consistency.report.json"
  local abs="${change_dir%/}/${rel}"
  if [[ ! -f "$abs" ]]; then
    scope_evidence_missing_artifacts+=("$rel")
    return 1
  fi

  local status_value=""
  status_value="$(json_extract_string_value "$abs" "status" || true)"
  if [[ -z "$status_value" ]]; then
    append_scope_invalid "$rel" "missing status"
    return 1
  fi
  if [[ "$status_value" != "pass" ]]; then
    append_scope_invalid "$rel" "status=${status_value} (expected pass)"
    return 1
  fi

  local issues_count=""
  issues_count="$(json_extract_number_value "$abs" "issues_count" || true)"
  if [[ -n "$issues_count" ]]; then
    if [[ "$issues_count" != "0" ]]; then
      append_scope_invalid "$rel" "issues_count=${issues_count} (expected 0)"
      return 1
    fi
    return 0
  fi

  # Backward-compatible formats: missing_paths: [] OR issues: []
  if grep -Eq '"missing_paths"[[:space:]]*:[[:space:]]*\\[[[:space:]]*\\]' "$abs" 2>/dev/null; then
    return 0
  fi
  if grep -Eq '"issues"[[:space:]]*:[[:space:]]*\\[[[:space:]]*\\]' "$abs" 2>/dev/null; then
    return 0
  fi

  append_scope_invalid "$rel" "missing summary.issues_count (and no empty missing_paths/issues fallback)"
  return 1
}

calculate_docs_consistency_requirement() {
  docs_consistency_required="false"
  docs_consistency_triggers=()

  if [[ "$contract_parse_ok" != "true" ]]; then
    return 0
  fi

  local path
  for path in "${deliverable_paths[@]}"; do
    path="$(normalize_relpath "$path")"
    case "$path" in
      README.md|docs/*|dev-playbooks/docs/*|templates/*)
        docs_consistency_required="true"
        docs_consistency_triggers+=("deliverables include docs/templates (${path})")
        break
        ;;
    esac
  done

  local i
  for ((i = 0; i < ${#obligation_ids[@]}; i++)); do
    local obligation_id="${obligation_ids[$i]}"
    local severity="${obligation_severities[$i]}"
    [[ "$severity" == "must" ]] || continue
    local tags_list="${obligation_tags[$i]}"
    if list_contains_line "$tags_list" "weak_link" && list_contains_line "$tags_list" "docs"; then
      docs_consistency_required="true"
      docs_consistency_triggers+=("weak_link docs must obligation (${obligation_id})")
      break
    fi
  done
}

evaluate_scope_evidence_bundle() {
  local proposal_file_local="${change_dir}/proposal.md"
  if [[ ! -f "$proposal_file_local" ]]; then
    scope_evidence_triggered="false"
    scope_evidence_status="pass"
    return 0
  fi

  local risk_level
  local request_kind
  local intervention_level
  risk_level="$(trim_value "$(extract_front_matter_value "$proposal_file_local" "risk_level" || true)")"
  request_kind="$(trim_value "$(extract_front_matter_value "$proposal_file_local" "request_kind" || true)")"
  intervention_level="$(trim_value "$(extract_front_matter_value "$proposal_file_local" "intervention_level" || true)")"

  case "$risk_level" in
    low|medium|high) ;;
    *) risk_level="low" ;;
  esac

  case "$request_kind" in
    debug|change|epic|void|bootstrap|governance) ;;
    *) request_kind="change" ;;
  esac

  # Higher-scope trigger: team/org intervention level.
  # Backwards compatible: missing/unknown -> local (non-triggering).
  case "$intervention_level" in
    local|team|org) ;;
    ""|*) intervention_level="local" ;;
  esac

  local triggered="false"
  case "$risk_level" in
    medium|high) triggered="true" ;;
  esac
  case "$request_kind" in
    epic|governance) triggered="true" ;;
  esac
  case "$intervention_level" in
    team|org) triggered="true" ;;
  esac

  if [[ "$triggered" != "true" ]]; then
    scope_evidence_triggered="false"
    scope_evidence_status="pass"
    return 0
  fi

  scope_evidence_triggered="true"
  scope_evidence_status="pass"
  scope_evidence_required_artifacts=()
  scope_evidence_missing_artifacts=()
  scope_evidence_invalid_artifacts=()

  calculate_docs_consistency_requirement

  # Auto-generate docs-consistency report when it is required as scope evidence.
  # This reduces "manual step" drift: archive-decider can deterministically produce the required artifact.
  if [[ "$docs_consistency_required" == "true" ]]; then
    if [[ -x "${script_dir}/docs-consistency-check.sh" ]]; then
      "${script_dir}/docs-consistency-check.sh" "$change_id" \
        --project-root "$project_root_abs" \
        --change-root "$change_root_dir" \
        --truth-root "$truth_root_dir" >/dev/null 2>&1 || true
    fi
  fi

  scope_evidence_required_artifacts+=("evidence/gates/reference-integrity.report.json")
  scope_evidence_required_artifacts+=("evidence/gates/check-completion-contract.log")
  if [[ "$docs_consistency_required" == "true" ]]; then
    scope_evidence_required_artifacts+=("evidence/gates/docs-consistency.report.json")
  fi

  local local_ok=true
  validate_reference_integrity_report || local_ok=false
  validate_completion_contract_log || local_ok=false
  if [[ "$docs_consistency_required" == "true" ]]; then
    validate_docs_consistency_report || local_ok=false
  fi

  if [[ "$local_ok" != true ]]; then
    scope_evidence_status="fail"
    status="fail"
    if [[ "$next_action" != "Bootstrap" ]]; then
      next_action="DevBooks"
    fi
    local p
    if (( ${#scope_evidence_missing_artifacts[@]} > 0 )); then
      for p in "${scope_evidence_missing_artifacts[@]}"; do
        failure_reasons+=("scope evidence missing: ${p}")
      done
    fi
    if (( ${#scope_evidence_invalid_artifacts[@]} > 0 )); then
      for p in "${scope_evidence_invalid_artifacts[@]}"; do
        failure_reasons+=("scope evidence invalid: ${p}")
      done
    fi
  fi
}

evaluate_scope_evidence_bundle

evaluate_runbook_structure() {
  local proposal_file_local="${change_dir}/proposal.md"
  local runbook_file="${change_dir}/RUNBOOK.md"

  runbook_structure_triggered="false"
  runbook_structure_status="pass"
  runbook_structure_missing_sections=()

  if [[ ! -f "$proposal_file_local" ]]; then
    return 0
  fi

  local risk_level
  local request_kind
  local intervention_level
  risk_level="$(trim_value "$(extract_front_matter_value "$proposal_file_local" "risk_level" || true)")"
  request_kind="$(trim_value "$(extract_front_matter_value "$proposal_file_local" "request_kind" || true)")"
  intervention_level="$(trim_value "$(extract_front_matter_value "$proposal_file_local" "intervention_level" || true)")"

  case "$risk_level" in
    low|medium|high) ;;
    *) risk_level="low" ;;
  esac

  case "$request_kind" in
    debug|change|epic|void|bootstrap|governance) ;;
    *) request_kind="change" ;;
  esac

  case "$intervention_level" in
    local|team|org) ;;
    ""|*) intervention_level="local" ;;
  esac

  local triggered="false"
  case "$risk_level" in
    medium|high) triggered="true" ;;
  esac
  case "$request_kind" in
    epic|governance) triggered="true" ;;
  esac
  case "$intervention_level" in
    team|org) triggered="true" ;;
  esac

  if [[ "$triggered" != "true" ]]; then
    return 0
  fi

  runbook_structure_triggered="true"

  if [[ ! -f "$runbook_file" ]]; then
    runbook_structure_status="fail"
    status="fail"
    if [[ "$next_action" != "Bootstrap" ]]; then
      next_action="DevBooks"
    fi
    failure_reasons+=("missing RUNBOOK.md (required for risk_level=${risk_level}, request_kind=${request_kind}, intervention_level=${intervention_level})")
    failure_reasons+=("Fix: Restore RUNBOOK.md from template (templates/dev-playbooks/changes/RUNBOOK.md) or re-run change-scaffold.sh, then re-run runbook-derive.sh.")
    return 0
  fi

  if ! grep -qE '^##[[:space:]]+Cover View' "$runbook_file" 2>/dev/null; then
    runbook_structure_missing_sections+=("## Cover View")
  fi
  if ! grep -qE '^##[[:space:]]+Context Capsule' "$runbook_file" 2>/dev/null; then
    runbook_structure_missing_sections+=("## Context Capsule")
  fi

  if (( ${#runbook_structure_missing_sections[@]} > 0 )); then
    runbook_structure_status="fail"
    status="fail"
    if [[ "$next_action" != "Bootstrap" ]]; then
      next_action="DevBooks"
    fi
    local sec
    for sec in "${runbook_structure_missing_sections[@]}"; do
      failure_reasons+=("RUNBOOK missing required section: ${sec}")
    done
    failure_reasons+=("Fix: Re-add missing RUNBOOK sections (use templates/dev-playbooks/changes/RUNBOOK.md) and re-run runbook-derive.sh.")
  fi
}

evaluate_runbook_structure

count_context_capsule_nonempty_lines() {
  local runbook_file="$1"
  awk '
    BEGIN { in_section=0; n=0 }
    {
      line=$0
      sub(/\r$/, "", line)
      if (in_section==0 && line ~ /^##[[:space:]]+Context Capsule/) { in_section=1; next }
      if (in_section==1) {
        if (line ~ /^##[[:space:]]+/) { exit }
        if (line ~ /[^[:space:]]/) { n++ }
      }
    }
    END { print n }
  ' "$runbook_file" 2>/dev/null || printf '0'
}

evaluate_context_capsule_length() {
  context_capsule_length_triggered="false"
  context_capsule_length_status="pass"
  context_capsule_nonempty_lines=0

  if [[ "$runbook_structure_triggered" != "true" ]]; then
    return 0
  fi
  context_capsule_length_triggered="true"

  local runbook_file="${change_dir}/RUNBOOK.md"
  if [[ ! -f "$runbook_file" ]]; then
    return 0
  fi
  if ! grep -qE '^##[[:space:]]+Context Capsule' "$runbook_file" 2>/dev/null; then
    return 0
  fi

  local count
  count="$(count_context_capsule_nonempty_lines "$runbook_file" || true)"
  if [[ -z "$count" ]]; then
    count="0"
  fi
  context_capsule_nonempty_lines="$count"

  if [[ "$context_capsule_nonempty_lines" =~ ^[0-9]+$ ]] && (( context_capsule_nonempty_lines > context_capsule_max_nonempty_lines )); then
    context_capsule_length_status="warn"
    # SHOULD: treat as an invalidity signal (route to Knife/Void), but do not hard-block as MUST.
    if [[ "$status" != "fail" ]]; then
      status="warn"
      if [[ "$next_action" == "DevBooks" ]]; then
        next_action="Knife"
      fi
    fi
    failure_reasons+=("Context Capsule too long: ${context_capsule_nonempty_lines} non-empty lines (should be <= ${context_capsule_max_nonempty_lines}). Signal: route to Knife/Void to re-slice or clarify; keep Context Capsule <=2 pages.")
  fi
}

evaluate_context_capsule_length

deliverable_path_for_id() {
  local deliverable_id="$1"
  local i
  for ((i = 0; i < ${#deliverable_ids[@]}; i++)); do
    if [[ "${deliverable_ids[$i]}" == "$deliverable_id" ]]; then
      printf '%s' "${deliverable_paths[$i]}"
      return 0
    fi
  done
  return 1
}

obligation_applies_for_id() {
  local obligation_id="$1"
  local i
  for ((i = 0; i < ${#obligation_ids[@]}; i++)); do
    if [[ "${obligation_ids[$i]}" == "$obligation_id" ]]; then
      printf '%s' "${obligation_applies[$i]}"
      return 0
    fi
  done
  return 1
}

if [[ "$contract_parse_ok" == "true" ]]; then
  declare -a all_artifacts=()
  declare -a must_unmet=()
  declare -a should_unmet=()

  weak_link_obligations=()
  local_i=0
  for ((local_i = 0; local_i < ${#obligation_ids[@]}; local_i++)); do
    if list_contains_line "${obligation_tags[$local_i]}" "weak_link"; then
      weak_link_obligations+=("${obligation_ids[$local_i]}")
    fi
  done

  local_i=0
  for ((local_i = 0; local_i < ${#check_ids[@]}; local_i++)); do
    while IFS= read -r artifact_raw || [[ -n "$artifact_raw" ]]; do
      artifact_raw="$(trim_value "$artifact_raw")"
      [[ -n "$artifact_raw" ]] || continue
      all_artifacts+=("$artifact_raw")
    done <<EOF
${check_artifacts[$local_i]}
EOF
  done

  # MP2: unmet obligations based on checks[].covers + checks[].artifacts existence.
  local_i=0
  for ((local_i = 0; local_i < ${#obligation_ids[@]}; local_i++)); do
    obligation_id="${obligation_ids[$local_i]}"
    severity="${obligation_severities[$local_i]}"
    proven="false"

    local_j=0
    for ((local_j = 0; local_j < ${#check_ids[@]}; local_j++)); do
      if ! list_contains_line "${check_covers[$local_j]}" "$obligation_id"; then
        continue
      fi

      check_id="${check_ids[$local_j]}"
      check_ok="true"
      if [[ -z "${check_artifacts[$local_j]}" ]]; then
        check_ok="false"
      else
        while IFS= read -r artifact_raw || [[ -n "$artifact_raw" ]]; do
          artifact_raw="$(trim_value "$artifact_raw")"
          [[ -n "$artifact_raw" ]] || continue
          artifact_rel="$(normalize_relpath "$artifact_raw")"
          # The archive decider emits its own gate report at output_path. If a completion
          # contract lists that same path as a check artifact, treat it as "to be generated"
          # rather than requiring it to pre-exist before this script runs.
          if [[ -n "$output_rel_path" && "$artifact_rel" == "$output_rel_path" ]]; then
            continue
          fi
          if ! is_safe_relpath_under_dir "$artifact_rel" "evidence/"; then
            failure_reasons+=("invalid check artifact path (must be under evidence/): ${artifact_raw} (check ${check_id})")
            check_ok="false"
            break
          fi
          artifact_abs="$(resolve_evidence_path "$artifact_rel")"
          if [[ ! -e "$artifact_abs" ]]; then
            check_ok="false"
            break
          fi
        done <<EOF
${check_artifacts[$local_j]}
EOF
      fi

      if [[ "$check_ok" == "true" ]]; then
        proven="true"
        break
      fi
    done

    if [[ "$proven" != "true" ]]; then
      unmet_obligations+=("$obligation_id")
      case "$severity" in
        must) must_unmet+=("$obligation_id") ;;
        should) should_unmet+=("$obligation_id") ;;
        *) failure_reasons+=("unknown obligation severity for ${obligation_id}: ${severity}") ;;
      esac
    fi
  done

  if [[ ${#must_unmet[@]} -gt 0 ]]; then
    status="fail"
    next_action="DevBooks"
    failure_reasons+=("unmet must obligations: $(printf '%s' "${must_unmet[*]}")")
  fi

  if [[ ${#should_unmet[@]} -gt 0 ]]; then
    if [[ "$mode" == "strict" ]]; then
      status="fail"
      next_action="DevBooks"
      failure_reasons+=("unmet should obligations in strict mode: $(printf '%s' "${should_unmet[*]}")")
    elif [[ "$status" != "fail" ]]; then
      status="warn"
      failure_reasons+=("unmet should obligations: $(printf '%s' "${should_unmet[*]}")")
    fi
  fi

  # MP3: freshness evaluation (artifact mtime >= max covered deliverables mtime).
  local_j=0
  for ((local_j = 0; local_j < ${#check_ids[@]}; local_j++)); do
    max_cover_mtime=-1
    covers_any="false"
    check_id="${check_ids[$local_j]}"

    while IFS= read -r covered_obligation_id || [[ -n "$covered_obligation_id" ]]; do
      covered_obligation_id="$(trim_value "$covered_obligation_id")"
      [[ -n "$covered_obligation_id" ]] || continue
      covers_any="true"

      applies_list="$(obligation_applies_for_id "$covered_obligation_id" || true)"
      while IFS= read -r deliverable_id || [[ -n "$deliverable_id" ]]; do
        deliverable_id="$(trim_value "$deliverable_id")"
        [[ -n "$deliverable_id" ]] || continue
        deliverable_rel="$(deliverable_path_for_id "$deliverable_id" || true)"
        if [[ -z "$deliverable_rel" ]]; then
          freshness_status="fail"
          failure_reasons+=("missing deliverable path for ${deliverable_id} (from ${covered_obligation_id})")
          continue
        fi
        freshness_checked_paths+=("$deliverable_rel")

        deliverable_abs="$(resolve_contract_path "$deliverable_rel")"
        deliverable_mtime="$(mtime_epoch "$deliverable_abs" || true)"
        if [[ -z "$deliverable_mtime" ]]; then
          freshness_status="fail"
          failure_reasons+=("failed to read mtime for covered deliverable: ${deliverable_rel}")
          continue
        fi
        if (( deliverable_mtime > max_cover_mtime )); then
          max_cover_mtime="$deliverable_mtime"
        fi
      done <<EOF
${applies_list}
EOF
    done <<EOF
${check_covers[$local_j]}
EOF

    if [[ "$covers_any" != "true" ]]; then
      continue
    fi

    if (( max_cover_mtime < 0 )); then
      freshness_status="fail"
      continue
    fi

    while IFS= read -r artifact_rel || [[ -n "$artifact_rel" ]]; do
      artifact_rel="$(trim_value "$artifact_rel")"
      [[ -n "$artifact_rel" ]] || continue
      artifact_rel_norm="$(normalize_relpath "$artifact_rel")"
      freshness_checked_paths+=("$artifact_rel_norm")

      # Avoid self-referential freshness failures: output_path is written after evaluation.
      # If a contract includes the gate report itself as an artifact, skip it here.
      if [[ -n "$output_rel_path" && "$artifact_rel_norm" == "$output_rel_path" ]]; then
        continue
      fi

      if ! is_safe_relpath_under_dir "$artifact_rel_norm" "evidence/"; then
        freshness_status="fail"
        failure_reasons+=("invalid check artifact path (must be under evidence/): ${artifact_rel} (check ${check_id})")
        freshness_stale_artifacts+=("$artifact_rel_norm")
        continue
      fi

      artifact_abs="$(resolve_evidence_path "$artifact_rel_norm")"
      artifact_mtime="$(mtime_epoch "$artifact_abs" || true)"
      if [[ -z "$artifact_mtime" ]]; then
        freshness_status="fail"
        freshness_stale_artifacts+=("$artifact_rel_norm")
        continue
      fi
      if (( artifact_mtime < max_cover_mtime )); then
        freshness_status="fail"
        freshness_stale_artifacts+=("$artifact_rel_norm")
      fi
    done <<EOF
${check_artifacts[$local_j]}
EOF
  done

  if [[ "$freshness_status" == "fail" ]]; then
    status="fail"
    next_action="DevBooks"
  fi

  # Artifacts list (stable, de-duped)
  if [[ ${#all_artifacts[@]} -gt 0 ]]; then
    all_artifacts_sorted=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      all_artifacts_sorted+=("$line")
    done < <(printf '%s\n' "${all_artifacts[@]}" | awk 'NF' | LC_ALL=C sort -u)
    all_artifacts=("${all_artifacts_sorted[@]}")
  fi

  if [[ ${#unmet_obligations[@]} -gt 0 ]]; then
    unmet_sorted=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      unmet_sorted+=("$line")
    done < <(printf '%s\n' "${unmet_obligations[@]}" | awk 'NF' | LC_ALL=C sort -u)
    unmet_obligations=("${unmet_sorted[@]}")
  fi

  if [[ ${#weak_link_obligations[@]} -gt 0 ]]; then
    weak_link_sorted=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      weak_link_sorted+=("$line")
    done < <(printf '%s\n' "${weak_link_obligations[@]}" | awk 'NF' | LC_ALL=C sort -u)
    weak_link_obligations=("${weak_link_sorted[@]}")
  fi

  if [[ ${#weak_link_obligations[@]} -gt 0 && ${#unmet_obligations[@]} -gt 0 ]]; then
    weak_link_unmet_obligations=()
    local_i=0
    for ((local_i = 0; local_i < ${#unmet_obligations[@]}; local_i++)); do
      unmet_id="${unmet_obligations[$local_i]}"
      local_j=0
      for ((local_j = 0; local_j < ${#weak_link_obligations[@]}; local_j++)); do
        if [[ "$unmet_id" == "${weak_link_obligations[$local_j]}" ]]; then
          weak_link_unmet_obligations+=("$unmet_id")
          break
        fi
      done
    done
  fi

  if [[ ${#weak_link_unmet_obligations[@]} -gt 0 ]]; then
    weak_link_unmet_sorted=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      weak_link_unmet_sorted+=("$line")
    done < <(printf '%s\n' "${weak_link_unmet_obligations[@]}" | awk 'NF' | LC_ALL=C sort -u)
    weak_link_unmet_obligations=("${weak_link_unmet_sorted[@]}")
  fi

  if [[ ${#freshness_checked_paths[@]} -gt 0 ]]; then
    checked_sorted=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      checked_sorted+=("$line")
    done < <(printf '%s\n' "${freshness_checked_paths[@]}" | awk 'NF' | LC_ALL=C sort -u)
    freshness_checked_paths=("${checked_sorted[@]}")
  fi

  if [[ ${#freshness_stale_artifacts[@]} -gt 0 ]]; then
    stale_sorted=()
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -n "$line" ]] || continue
      stale_sorted+=("$line")
    done < <(printf '%s\n' "${freshness_stale_artifacts[@]}" | awk 'NF' | LC_ALL=C sort -u)
    freshness_stale_artifacts=("${stale_sorted[@]}")
  fi

  if (( ${#all_artifacts[@]} > 0 )); then
    artifacts=("${all_artifacts[@]}")
  fi
fi

if [[ "$scope_evidence_triggered" == "true" && ${#scope_evidence_required_artifacts[@]} -gt 0 ]]; then
  artifacts+=("${scope_evidence_required_artifacts[@]}")
fi

if (( ${#artifacts[@]} > 0 )); then
  artifacts_sorted=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    artifacts_sorted+=("$line")
  done < <(printf '%s\n' "${artifacts[@]}" | awk 'NF' | LC_ALL=C sort -u)
  artifacts=("${artifacts_sorted[@]}")
fi

# MP4: state consistency evaluation (safe-skip for fixtures missing proposal/tasks/verification)
proposal_file="${change_dir}/proposal.md"
tasks_file="${change_dir}/tasks.md"
verification_file="${change_dir}/verification.md"

files_present=0
[[ -f "$proposal_file" ]] && files_present=$((files_present + 1))
[[ -f "$tasks_file" ]] && files_present=$((files_present + 1))
[[ -f "$verification_file" ]] && files_present=$((files_present + 1))

if (( files_present == 0 )); then
  state_status="pass"
elif (( files_present != 3 )); then
  state_status="fail"
  [[ -f "$proposal_file" ]] || state_issues+=("missing proposal.md")
  [[ -f "$tasks_file" ]] || state_issues+=("missing tasks.md")
  [[ -f "$verification_file" ]] || state_issues+=("missing verification.md")
else
  decision_status="$(trim_value "$(decision_status_from_proposal "$proposal_file" || true)")"
  if [[ -z "$decision_status" ]]; then
    state_status="fail"
    state_issues+=("proposal decision status missing (expected '- Decision Status: Approved')")
  elif [[ "$decision_status" != "Approved" ]]; then
    state_status="fail"
    state_issues+=("proposal decision not Approved (actual: ${decision_status})")
  fi

  vstatus="$(trim_value "$(verification_status_from_file "$verification_file" || true)")"
  if [[ -z "$vstatus" ]]; then
    state_status="fail"
    state_issues+=("verification status missing (expected '- Status: Done')")
  elif [[ "$vstatus" == "Draft" || "$vstatus" == "Ready" ]]; then
    state_status="fail"
    state_issues+=("verification not closed (actual: ${vstatus})")
  fi

  open_task_lines="$(markdown_plain_lines "$tasks_file" | grep -E '^- \\[ \\]' 2>/dev/null | grep -v 'SKIP-APPROVED:' 2>/dev/null || true)"
  if [[ -n "$open_task_lines" ]]; then
    state_status="fail"
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="$(trim_value "$line")"
      [[ -n "$line" ]] || continue
      state_issues+=("tasks unchecked: ${line}")
    done <<EOF
${open_task_lines}
EOF
  fi

  trace_lines="$(markdown_plain_lines "$verification_file" \
    | grep -E '^[|][[:space:]]*AC-[0-9]{3}[[:space:]]*[|].*[|][[:space:]]*(TBD|Pending|Draft|TODO)[[:space:]]*[|]' 2>/dev/null || true)"
  if [[ -n "$trace_lines" ]]; then
    state_status="fail"
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="$(trim_value "$line")"
      [[ -n "$line" ]] || continue
      state_issues+=("trace matrix unclosed: ${line}")
    done <<EOF
${trace_lines}
EOF
  fi

  manual_lines="$(markdown_plain_lines "$verification_file" \
    | grep -E '^- \\[ \\] MANUAL-[0-9]{3}([[:space:]]|$)' 2>/dev/null || true)"
  if [[ -n "$manual_lines" ]]; then
    state_status="fail"
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="$(trim_value "$line")"
      [[ -n "$line" ]] || continue
      state_issues+=("manual checklist unchecked: ${line}")
    done <<EOF
${manual_lines}
EOF
  fi
fi

if [[ "$state_status" == "fail" ]]; then
  status="fail"
  next_action="DevBooks"
  local_i=0
  for ((local_i = 0; local_i < ${#state_issues[@]}; local_i++)); do
    failure_reasons+=("${state_issues[$local_i]}")
  done
fi

# MP5: upstream_claims evaluation (Requirement Set Index MUST coverage + ref integrity).
csv_to_json_array() {
  local csv="$1"
  local -a items=()
  local item
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    items+=("$item")
  done < <(uc_split_csv_to_array "$csv" || true)
  if (( ${#items[@]} > 0 )); then
    json_array "${items[@]}"
    return 0
  fi
  printf '%s' "[]"
}

if [[ "$upstream_claims_present" == "true" && "$completion_contract_present" == "true" && -n "$completion_contract_path" ]]; then
  uc_set_context "$truth_root_dir" "$change_root_dir"
  if ! uc_parse_contract_upstream_claims "$completion_contract_path"; then
    status="fail"
    next_action="DevBooks"
    failure_reasons+=("failed to parse upstream_claims from completion contract: ${completion_contract_path}")
  elif [[ ${#UC_SET_REFS[@]} -gt 0 ]]; then
    local_any_fail="false"
    if ! uc_evaluate_upstream_claims; then
      local_any_fail="true"
    fi

    eval_items_json=""
    eval_first=true

    local_i=0
    for ((local_i = 0; local_i < ${#UC_EVAL_SET_REFS[@]}; local_i++)); do
      set_ref="${UC_EVAL_SET_REFS[$local_i]}"
      set_path="${UC_EVAL_SET_PATHS[$local_i]}"
      claim="${UC_EVAL_CLAIMS[$local_i]}"
      item_status="${UC_EVAL_STATUS[$local_i]}"
      must_total="${UC_EVAL_MUST_TOTAL[$local_i]}"
      must_covered="${UC_EVAL_MUST_COVERED[$local_i]}"
      uncovered_json="$(csv_to_json_array "${UC_EVAL_UNCOVERED_MUST_CSV[$local_i]}")"
      deferred_json="$(csv_to_json_array "${UC_EVAL_DEFERRED_CSV[$local_i]}")"
      errors_json="$(csv_to_json_array "${UC_EVAL_ERRORS_CSV[$local_i]}")"
      next_action_ref="${UC_EVAL_NEXT_ACTION_REFS[$local_i]}"
      next_action_path="${UC_EVAL_NEXT_ACTION_PATHS[$local_i]}"
      next_action_resolvable="${UC_EVAL_NEXT_ACTION_RESOLVABLE[$local_i]}"

      item_json="$(cat <<EOF
{"set_ref":"$(json_escape "$set_ref")","claim":"$(json_escape "$claim")","status":"$(json_escape "$item_status")","must_total":${must_total},"must_covered":${must_covered},"uncovered_must":${uncovered_json},"deferred":${deferred_json},"next_action_ref":"$(json_escape "$next_action_ref")","next_action_resolvable":$( [[ "$next_action_resolvable" == true ]] && printf 'true' || printf 'false' ),"set_path":"$(json_escape "$set_path")","next_action_path":"$(json_escape "$next_action_path")","errors":${errors_json}}
EOF
)"

      if [[ "$eval_first" == true ]]; then
        eval_first=false
        eval_items_json="${item_json}"
      else
        eval_items_json="${eval_items_json},${item_json}"
      fi

      if [[ "$item_status" == "fail" ]]; then
        failure_reasons+=("upstream_claims failed: set_ref=${set_ref} claim=${claim}")
      fi
    done

    upstream_claims_evaluation_json="[${eval_items_json}]"

    if [[ "$local_any_fail" == "true" ]]; then
      status="fail"
      next_action="DevBooks"
      failure_reasons+=("upstream_claims not satisfied (see upstream_claims_evaluation)")
    fi
  fi
fi

ensure_fix_reason

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
checks_json="$(json_array "${checks[@]}")"
artifacts_json="[]"
if (( ${#artifacts[@]} > 0 )); then
  artifacts_json="$(json_array "${artifacts[@]}")"
fi
if [[ ${#failure_reasons[@]} -eq 0 ]]; then
  failure_reasons_json="[]"
else
  failure_reasons_sorted=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    failure_reasons_sorted+=("$line")
  done < <(printf '%s\n' "${failure_reasons[@]}" | awk 'NF' | LC_ALL=C sort -u)
  failure_reasons_json="$(json_array "${failure_reasons_sorted[@]}")"
fi
unmet_obligations_json="[]"
if (( ${#unmet_obligations[@]} > 0 )); then
  unmet_obligations_json="$(json_array "${unmet_obligations[@]}")"
fi
freshness_stale_artifacts_json="[]"
if (( ${#freshness_stale_artifacts[@]} > 0 )); then
  freshness_stale_artifacts_json="$(json_array "${freshness_stale_artifacts[@]}")"
fi
freshness_checked_paths_json="[]"
if (( ${#freshness_checked_paths[@]} > 0 )); then
  freshness_checked_paths_json="$(json_array "${freshness_checked_paths[@]}")"
fi
freshness_evaluation_json="$(cat <<EOF
{"status":"$(json_escape "$freshness_status")","stale_artifacts":${freshness_stale_artifacts_json},"checked_paths":${freshness_checked_paths_json}}
EOF
)"

scope_evidence_required_json="[]"
if (( ${#scope_evidence_required_artifacts[@]} > 0 )); then
  scope_evidence_required_json="$(json_array "${scope_evidence_required_artifacts[@]}")"
fi
scope_evidence_missing_json="[]"
if (( ${#scope_evidence_missing_artifacts[@]} > 0 )); then
  scope_evidence_missing_json="$(json_array "${scope_evidence_missing_artifacts[@]}")"
fi
scope_evidence_invalid_json="[]"
if (( ${#scope_evidence_invalid_artifacts[@]} > 0 )); then
  scope_evidence_invalid_json="$(json_array "${scope_evidence_invalid_artifacts[@]}")"
fi
docs_consistency_triggers_json="[]"
if (( ${#docs_consistency_triggers[@]} > 0 )); then
  docs_consistency_triggers_json="$(json_array "${docs_consistency_triggers[@]}")"
fi
scope_evidence_bundle_evaluation_json="$(cat <<EOF
{"triggered":$( [[ "$scope_evidence_triggered" == "true" ]] && printf 'true' || printf 'false' ),"status":"$(json_escape "$scope_evidence_status")","required_artifacts":${scope_evidence_required_json},"missing_artifacts":${scope_evidence_missing_json},"invalid_artifacts":${scope_evidence_invalid_json},"docs_consistency_required":$( [[ "$docs_consistency_required" == "true" ]] && printf 'true' || printf 'false' ),"docs_consistency_triggers":${docs_consistency_triggers_json}}
EOF
)"

runbook_missing_sections_json="[]"
if (( ${#runbook_structure_missing_sections[@]} > 0 )); then
  runbook_missing_sections_json="$(json_array "${runbook_structure_missing_sections[@]}")"
fi
runbook_structure_evaluation_json="$(cat <<EOF
{"triggered":$( [[ "$runbook_structure_triggered" == "true" ]] && printf 'true' || printf 'false' ),"status":"$(json_escape "$runbook_structure_status")","missing_sections":${runbook_missing_sections_json}}
EOF
)"

context_capsule_length_evaluation_json="$(cat <<EOF
{"triggered":$( [[ "$context_capsule_length_triggered" == "true" ]] && printf 'true' || printf 'false' ),"status":"$(json_escape "$context_capsule_length_status")","nonempty_lines":${context_capsule_nonempty_lines},"max_nonempty_lines":${context_capsule_max_nonempty_lines}}
EOF
)"

weak_link_obligations_json="[]"
if (( ${#weak_link_obligations[@]} > 0 )); then
  weak_link_obligations_json="$(json_array "${weak_link_obligations[@]}")"
fi
weak_link_unmet_obligations_json="[]"
if (( ${#weak_link_unmet_obligations[@]} > 0 )); then
  weak_link_unmet_obligations_json="$(json_array "${weak_link_unmet_obligations[@]}")"
fi
weak_link_evaluation_json="$(cat <<EOF
{"weak_link_obligations":${weak_link_obligations_json},"unmet_weak_link_obligations":${weak_link_unmet_obligations_json}}
EOF
)"

state_issues_json="[]"
if (( ${#state_issues[@]} > 0 )); then
  state_issues_json="$(json_array "${state_issues[@]}")"
fi
state_consistency_evaluation_json="$(cat <<EOF
{"status":"$(json_escape "$state_status")","issues":${state_issues_json}}
EOF
)"

output_dir="$(dirname "$output_path")"
if ! mkdir -p "$output_dir" 2>/dev/null; then
  die_error \
    "cannot create output directory" \
    "Writable output directory" \
    "Cannot create: ${output_dir}" \
    "Ensure directory exists and is writable, or use --output to point to a writable path."
fi

tmp_path="${output_path}.tmp.$$"
if ! cat >"$tmp_path" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G6",
  "mode": "$(json_escape "$mode")",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$timestamp")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "project_root": "$(json_escape "$project_root_abs")",
    "change_root": "$(json_escape "$change_root_dir")",
    "truth_root": "$(json_escape "$truth_root_dir")",
    "change_dir": "$(json_escape "$change_dir")",
    "output_path": "$(json_escape "$output_path")",
    "completion_contract_path": "$(json_escape "$completion_contract_path")",
    "completion_contract_present": ${completion_contract_present}
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${failure_reasons_json},
  "next_action": "$(json_escape "$next_action")",
  "unmet_obligations": ${unmet_obligations_json},
  "freshness_evaluation": ${freshness_evaluation_json},
  "scope_evidence_bundle_evaluation": ${scope_evidence_bundle_evaluation_json},
  "runbook_structure_evaluation": ${runbook_structure_evaluation_json},
  "context_capsule_length_evaluation": ${context_capsule_length_evaluation_json},
  "weak_link_evaluation": ${weak_link_evaluation_json},
  "state_consistency_evaluation": ${state_consistency_evaluation_json},
  "upstream_claims_evaluation": ${upstream_claims_evaluation_json}
}
EOF
then
  die_error \
    "failed to write report" \
    "Writable output path" \
    "Failed to write: ${tmp_path}" \
    "Ensure output directory is writable and has sufficient space."
fi

if ! mv -f "$tmp_path" "$output_path" 2>/dev/null; then
  rm -f "$tmp_path" 2>/dev/null || true
  die_error \
    "failed to finalize report" \
    "Writable output path" \
    "Failed to move report to: ${output_path}" \
    "Ensure output directory is writable and no permission issues block rename."
fi

case "$status" in
  pass|warn) exit 0 ;;
  fail) exit 1 ;;
  *) die_error "invalid status value" "pass|warn|fail" "${status}" "Check script logic or report a bug." ;;
esac
