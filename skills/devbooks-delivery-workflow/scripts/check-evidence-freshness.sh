#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: check-evidence-freshness.sh <change-id> [options]

Check evidence freshness (mtime):
  For a given change package, verify that evidence files are not older than
  the latest modification time among covered targets.

Rule:
  evidence_mtime >= max(covers_mtime)   (using >= to reduce FS timestamp granularity false blocks)

Options:
  --project-root <dir>   Project root directory (default: pwd)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory (default: specs)
  --covers <path>        Covered target path (file/dir). Repeatable. (required)
  --covers-from <file>   File containing covered target paths (one per line)
  --evidence <path>      Evidence path (file/dir). Repeatable. (default: evidence/gates + evidence/green-final)
  --evidence-from <file> File containing evidence paths (one per line)
  --out <path>           Output report path (default: evidence/gates/evidence-freshness-check.json in change dir)
  -h, --help             Show this help message

Path rules:
  - Absolute paths are supported.
  - Relative paths are treated as project-root relative.

Exit codes:
  0 - pass or skip (no evidence files found)
  1 - fail (stale evidence detected)
  2 - usage error (missing/invalid args, missing covers)
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

out_path=""
covers_from=""
evidence_from=""
declare -a covers=()
declare -a evidence_paths=()

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
    --covers)
      covers+=("${2:-}")
      shift 2
      ;;
    --covers-from)
      covers_from="${2:-}"
      shift 2
      ;;
    --evidence)
      evidence_paths+=("${2:-}")
      shift 2
      ;;
    --evidence-from)
      evidence_from="${2:-}"
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

if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
else
  out_file="${change_dir}/evidence/gates/evidence-freshness-check.json"
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
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

to_relpath() {
  local p="$1"
  if [[ "$p" == "${project_root}/"* ]]; then
    printf '%s' "${p#${project_root}/}"
    return 0
  fi
  printf '%s' "$p"
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

resolve_path_project_root() {
  local p="$1"
  if [[ "$p" = /* ]]; then
    printf '%s' "$p"
    return 0
  fi
  while [[ "$p" == ./* ]]; do
    p="${p#./}"
  done
  p="${p#/}"
  printf '%s' "${project_root}/${p}"
}

append_paths_from_file() {
  local file="$1"
  local kind="$2"
  if [[ -z "$file" ]]; then
    return 0
  fi
  local abs
  abs="$(resolve_path_project_root "$file")"
  if [[ ! -f "$abs" ]]; then
    errorf "${kind} list file not found" "" "file exists" "$abs" "fix the path or remove --${kind}-from"
    exit 2
  fi
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    line="$(trim_value "$line")"
    [[ -n "$line" ]] || continue
    [[ "$line" == "#"* ]] && continue
    if [[ "$kind" == "covers" ]]; then
      covers+=("$line")
    else
      evidence_paths+=("$line")
    fi
  done <"$abs"
}

append_paths_from_file "$covers_from" "covers"
append_paths_from_file "$evidence_from" "evidence"

if [[ ${#covers[@]} -eq 0 ]]; then
  errorf "missing covered targets" "" "at least one --covers <path> or --covers-from <file>" "none" "provide --covers/--covers-from"
  exit 2
fi

if [[ ${#evidence_paths[@]} -eq 0 ]]; then
  evidence_paths+=("${change_dir}/evidence/gates")
  evidence_paths+=("${change_dir}/evidence/green-final")
fi

collect_files() {
  local p="$1"
  if [[ -f "$p" ]]; then
    printf '%s\n' "$p"
    return 0
  fi
  if [[ -d "$p" ]]; then
    find "$p" -type f 2>/dev/null || true
    return 0
  fi
  return 1
}

declare -a covered_files=()
declare -a missing_covers=()
for cover in "${covers[@]}"; do
  cover_abs="$(resolve_path_project_root "$cover")"
  if [[ -f "$cover_abs" || -d "$cover_abs" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      covered_files+=("$f")
    done < <(collect_files "$cover_abs")
  else
    missing_covers+=("$cover_abs")
  fi
done

if [[ ${#missing_covers[@]} -gt 0 ]]; then
  errorf "covered target path not found" "" "covers path exists" "$(printf '%s' "${missing_covers[0]}")" "fix --covers/--covers-from paths"
  exit 2
fi

if [[ ${#covered_files[@]} -eq 0 ]]; then
  errorf "covered target expansion is empty" "" "at least one file under covers" "0 files" "use file paths or non-empty directories for --covers"
  exit 2
fi

max_target_mtime=-1
max_target_path=""
declare -a covered_targets_json=()
for f in "${covered_files[@]}"; do
  [[ -f "$f" ]] || continue
  t="$(mtime_epoch "$f" || true)"
  [[ -n "$t" ]] || continue
  if (( t > max_target_mtime )); then
    max_target_mtime="$t"
    max_target_path="$f"
  fi
  covered_targets_json+=("{\"path\":\"$(json_escape "$(to_relpath "$f")")\",\"mtime_epoch\":${t}}")
done

if (( max_target_mtime < 0 )); then
  errorf "failed to read mtime for covered targets" "" "stat works" "no mtimes readable" "ensure files exist and stat is available"
  exit 1
fi

declare -a evidence_files=()
declare -a missing_evidence_paths=()
for ep in "${evidence_paths[@]}"; do
  if [[ "$ep" = /* ]]; then
    ep_abs="$ep"
  else
    ep_abs="$(resolve_path_project_root "$ep")"
  fi
  if [[ -f "$ep_abs" || -d "$ep_abs" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      # Exclude out_file from evidence set (avoid self-fulfilling freshness)
      if [[ "$f" == "$out_file" ]]; then
        continue
      fi
      evidence_files+=("$f")
    done < <(collect_files "$ep_abs")
  else
    missing_evidence_paths+=("$ep_abs")
  fi
done

if [[ ${#missing_evidence_paths[@]} -gt 0 ]]; then
  errorf "evidence path not found" "" "evidence path exists" "$(printf '%s' "${missing_evidence_paths[0]}")" "fix --evidence/--evidence-from paths"
  exit 2
fi

write_report() {
  local status="$1"
  local next_action="$2"
  local violations_json="$3"
  local evidence_json="$4"
  local note="$5"

  local covered_json="[]"
  if (( ${#covered_targets_json[@]} > 0 )); then
    covered_json="[$(IFS=','; printf '%s' "${covered_targets_json[*]}")]"
  fi

  {
    printf '{'
    printf '"schema_version":1,'
    printf '"check_id":"evidence-freshness-check",'
    printf '"change_id":"%s",' "$(json_escape "$change_id")"
    printf '"status":"%s",' "$(json_escape "$status")"
    printf '"generated_at":"%s",' "$(json_escape "$(date -Iseconds)")"
    printf '"truth_root":"%s",' "$(json_escape "$(to_relpath "$truth_dir")")"
    printf '"max_covered_target":{"path":"%s","mtime_epoch":%s},' "$(json_escape "$(to_relpath "$max_target_path")")" "$max_target_mtime"
    printf '"covered_targets":%s,' "$covered_json"
    printf '"evidence_files":%s,' "$evidence_json"
    printf '"violations":%s,' "$violations_json"
    printf '"note":"%s",' "$(json_escape "$note")"
    printf '"next_action":"%s"' "$(json_escape "$next_action")"
    printf '}\n'
  } >"$out_file"
}

if [[ ${#evidence_files[@]} -eq 0 ]]; then
  write_report "skip" "collect-evidence" "[]" "[]" "no evidence files found under selected evidence paths"
  echo "info: skip (no evidence files found)"
  exit 0
fi

declare -a evidence_files_json=()
declare -a violations=()
for f in "${evidence_files[@]}"; do
  [[ -f "$f" ]] || continue
  t="$(mtime_epoch "$f" || true)"
  [[ -n "$t" ]] || continue
  evidence_files_json+=("{\"path\":\"$(json_escape "$(to_relpath "$f")")\",\"mtime_epoch\":${t}}")
  if (( t < max_target_mtime )); then
    delta=$((max_target_mtime - t))
    violations+=("{\"evidence_path\":\"$(json_escape "$(to_relpath "$f")")\",\"evidence_mtime_epoch\":${t},\"max_target_path\":\"$(json_escape "$(to_relpath "$max_target_path")")\",\"max_target_mtime_epoch\":${max_target_mtime},\"delta_seconds\":${delta}}")
  fi
done

evidence_json="[]"
if (( ${#evidence_files_json[@]} > 0 )); then
  evidence_json="[$(IFS=','; printf '%s' "${evidence_files_json[*]}")]"
fi

if (( ${#violations[@]} > 0 )); then
  violations_json="[$(IFS=','; printf '%s' "${violations[*]}")]"
  write_report "fail" "rerun-gates" "$violations_json" "$evidence_json" "evidence is older than covered targets (mtime freshness violation)"
  echo "fail: stale evidence detected (${#violations[@]} violation(s))" >&2
  exit 1
fi

write_report "pass" "DevBooks" "[]" "$evidence_json" "evidence mtime is fresh relative to covered targets"
echo "ok: evidence is fresh"
exit 0
