#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: requirements-ledger-derive.sh [options]

Derive a lightweight requirements ledger (progress view) from archived change packages.

Defaults:
  - Reads requirements set: truth://ssot/requirements.index.yaml
  - Scans: <change-root>/archive/*
  - Writes: <truth-root>/ssot/requirements.ledger.yaml

Options:
  --project-root <dir>     Project root directory (default: pwd)
  --change-root <dir>      Change root directory (default: changes)
  --truth-root <dir>       Truth root directory (default: specs)
  --set-ref <truth://...>  Override requirements set ref (must end with requirements.index.yaml|yml)
  --out <path>             Override output path (relative to truth_root when not absolute)
  -h, --help               Show this help message

Notes:
- The ledger is a derived cache (可丢弃可重建), not SSOT.
- Ground truth remains archived change packages + evidence + gate reports.
EOF
}

die_usage() {
  echo "error: $*" >&2
  usage
  exit 2
}

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
set_ref="truth://ssot/requirements.index.yaml"
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
    --set-ref)
      set_ref="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    *)
      die_usage "unknown option: $1"
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

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

if [[ -z "$set_ref" || "$set_ref" != truth://* ]]; then
  die_usage "--set-ref must use truth:// (actual: ${set_ref:-<empty>})"
fi
if [[ "$set_ref" != truth://*requirements.index.yaml && "$set_ref" != truth://*requirements.index.yml ]]; then
  die_usage "--set-ref must end with requirements.index.yaml|yml (actual: ${set_ref})"
fi

set_rel="${set_ref#truth://}"
set_rel="${set_rel#/}"
set_file="${truth_dir%/}/${set_rel}"
if [[ ! -f "$set_file" ]]; then
  die_usage "requirements.index not found: ${set_ref} (resolved: ${set_file})"
fi

out_file=""
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${truth_dir%/}/${out_path}"
  fi
else
  out_file="${truth_dir%/}/ssot/requirements.ledger.yaml"
fi

mkdir -p "$(dirname "$out_file")"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/upstream-claims.sh
source "${script_dir}/lib/upstream-claims.sh"
uc_set_context "$truth_dir" "$change_root_dir"

tmp_events="$(mktemp)"
cleanup() {
  rm -f "$tmp_events" >/dev/null 2>&1 || true
}
trap cleanup EXIT

archive_dir="${change_root_dir%/}/archive"
if [[ -d "$archive_dir" ]]; then
  for change_dir in "$archive_dir"/*; do
    [[ -d "$change_dir" ]] || continue
    change_id="$(basename "$change_dir")"

    contract_file=""
    if [[ -f "${change_dir}/completion.contract.yaml" ]]; then
      contract_file="${change_dir}/completion.contract.yaml"
    elif [[ -f "${change_dir}/completion.contract.yml" ]]; then
      contract_file="${change_dir}/completion.contract.yml"
    else
      continue
    fi

    # Only count archived changes that have non-empty green evidence.
    if [[ ! -d "${change_dir}/evidence/green-final" ]]; then
      continue
    fi
    if ! find "${change_dir}/evidence/green-final" -type f -print -quit 2>/dev/null | grep -q .; then
      continue
    fi

    if ! uc_parse_contract_upstream_claims "$contract_file"; then
      continue
    fi

    for i in "${!UC_SET_REFS[@]}"; do
      item_set_ref="${UC_SET_REFS[$i]}"
      [[ -n "$item_set_ref" ]] || continue

      resolved="$(uc_resolve_set_ref "$item_set_ref" 2>/dev/null || true)"
      if [[ -z "$resolved" || "$resolved" != "$set_file" ]]; then
        continue
      fi

      claim="$(uc_to_lower "${UC_CLAIMS[$i]}")"
      next_action_ref="${UC_NEXT_ACTION_REFS[$i]}"

      case "$claim" in
        complete)
          printf '%s\n' "COMPLETE|${change_id}" >>"$tmp_events"
          ;;
        subset)
          while IFS= read -r rid; do
            [[ -n "$rid" ]] || continue
            printf '%s\n' "DONE|${rid}|${change_id}" >>"$tmp_events"
          done < <(uc_split_csv_to_array "${UC_COVERED_CSV[$i]}")
          while IFS= read -r rid; do
            [[ -n "$rid" ]] || continue
            printf '%s\n' "DEFERRED|${rid}|${change_id}|${next_action_ref}" >>"$tmp_events"
          done < <(uc_split_csv_to_array "${UC_DEFERRED_CSV[$i]}")
          ;;
        *)
          # Unknown claim values are ignored in derived ledger.
          ;;
      esac
    done
  done
fi

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Produce YAML (deterministic ordering from requirements.index.yaml).
awk -v set_ref="$set_ref" -v generated_at="$generated_at" '
  function trim(s) {
    sub(/^[ \t\r\n]+/, "", s)
    sub(/[ \t\r\n]+$/, "", s)
    return s
  }
  function strip_quotes(s) {
    s = trim(s)
    sub(/^"/, "", s); sub(/"$/, "", s)
    sub(/^'\''/, "", s); sub(/'\''$/, "", s)
    return s
  }
  FNR==NR {
    line=$0
    sub(/\r$/, "", line)
    if (line ~ /^[ \t]*#/) next
    if (!in_req && line ~ /^requirements:[ \t]*$/) { in_req=1; next }
    if (in_req && line ~ /^[^ \t-][A-Za-z0-9_.-]*:/) { in_req=0 }
    if (!in_req) next
    if (match(line, /^[ \t]*-[ \t]*id:[ \t]*([^ \t\r\n#]+)[ \t]*$/, m)) {
      id = strip_quotes(m[1])
      if (id != "") { order[++n]=id }
      next
    }
    next
  }
  {
    line=$0
    sub(/\r$/, "", line)
    if (line=="") next
    split(line, a, /\|/)
    kind=a[1]
    if (kind=="COMPLETE") {
      complete_change=a[2]
      next
    }
    id=a[2]; change=a[3]
    if (id=="") next
    if (kind=="DONE") {
      done[id]=change
      next
    }
    if (kind=="DEFERRED") {
      if (!(id in done)) {
        deferred[id]=change
        deferred_next[id]=a[4]
      }
      next
    }
  }
  END {
    print "schema_version: 1.0.0"
    print "set_ref: " set_ref
    print "generated_at: " generated_at
    print "note: \"derived cache; regenerate from archived change packages\""
    print ""
    print "requirements:"
    for (i=1; i<=n; i++) {
      id=order[i]
      status="planned"
      last_change=""
      next_action=""

      if (complete_change != "") {
        status="done"
        last_change=complete_change
      }
      if (id in deferred) {
        status="deferred"
        last_change=deferred[id]
        next_action=deferred_next[id]
      }
      if (id in done) {
        status="done"
        last_change=done[id]
        next_action=""
      }

      print "  - id: " id
      print "    status: " status
      print "    last_change_id: " (last_change=="" ? "\"\"" : last_change)
      print "    next_action_ref: " (next_action=="" ? "\"\"" : "\"" next_action "\"")
    }
  }
' "$set_file" "$tmp_events" >"$out_file"

echo "ok: wrote derived ledger: ${out_file}" >&2

