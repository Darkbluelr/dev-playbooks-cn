#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: required-gates-check.sh <change-id> [options]

Validate proposal.required_gates against derived_required_gates.

Options:
  --project-root <dir>     Project root directory (default: pwd)
  --change-root <dir>      Change root directory (default: changes)
  --truth-root <dir>       Truth root directory (default: specs)
  --out <path>             Output report path (default: evidence/gates/required-gates-check.json)
  -h, --help               Show this help message

Exit codes:
  0 - pass
  1 - fail
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

change_dir="${change_root_dir}/${change_id}"
if [[ ! -d "$change_dir" ]]; then
  errorf "missing change directory" "" "directory exists" "$change_dir" "check --change-root/--project-root and change-id"
  exit 1
fi

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/required-gates-check.json"
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

proposal_file="${change_dir}/proposal.md"
if [[ ! -f "$proposal_file" ]]; then
  errorf "missing proposal.md" "$proposal_file" "proposal.md exists" "missing" "create proposal.md with front matter"
  exit 1
fi

extract_required_gates_from_proposal() {
  awk '
    BEGIN { in_yaml=0; in_list=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 && $0 ~ /^required_gates:[[:space:]]*$/ { in_list=1; next }
    in_list==1 {
      if ($0 ~ /^[^[:space:]]/) { exit }
      if ($0 ~ /^[[:space:]]*-[[:space:]]*G[0-6][[:space:]]*$/) {
        line=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        print line
      }
    }
  ' "$proposal_file" 2>/dev/null || true
}

proposal_gates=()
while IFS= read -r g; do
  [[ -n "$g" ]] || continue
  proposal_gates+=("$g")
done < <(extract_required_gates_from_proposal)

derive_report="${change_dir}/evidence/gates/required-gates-derive.json"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
derive_script="${script_dir}/required-gates-derive.sh"
if [[ ! -x "$derive_script" ]]; then
  errorf "missing required-gates-derive.sh" "$derive_script" "executable script" "missing" "ensure scripts are installed"
  exit 1
fi

# Always (re)generate the derived report to avoid stale gate derivations.
"$derive_script" "$change_id" --project-root "$project_root" --change-root "$change_root" --truth-root "$truth_root" --out "evidence/gates/required-gates-derive.json" >/dev/null 2>&1 || true

if [[ ! -f "$derive_report" ]]; then
  errorf "missing derived report" "$derive_report" "report exists" "missing" "rerun required-gates-derive.sh"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  errorf "node not found" "" "node available to parse derived report" "missing" "install node >=18"
  exit 1
fi

derived_gates=()
while IFS= read -r g; do
  [[ -n "$g" ]] || continue
  derived_gates+=("$g")
done < <(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));(o.derived_required_gates||[]).forEach(g=>process.stdout.write(String(g)+"\n"));' "$derive_report" 2>/dev/null || true)

derived_status="$(node -e 'const fs=require("fs");const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String(o.status||""));' "$derive_report" 2>/dev/null || true)"

missing=()

if [[ ${#proposal_gates[@]} -eq 0 ]]; then
  missing+=("proposal.required_gates is missing or empty")
fi

if [[ "$derived_status" != "pass" ]]; then
  missing+=("required_gates derivation did not pass (status=${derived_status:-unknown}); see ${derive_report}")
fi

if [[ ${#derived_gates[@]} -gt 0 ]]; then
  for g in "${derived_gates[@]}"; do
    found=false
    for pg in "${proposal_gates[@]:-}"; do
      if [[ "$pg" == "$g" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" != true ]]; then
      missing+=("proposal.required_gates missing derived gate: ${g}")
    fi
  done
fi

status="pass"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="fail"
fi

proposal_json="[]"
if [[ ${#proposal_gates[@]} -gt 0 ]]; then
  proposal_json="$(json_array "${proposal_gates[@]}")"
fi
derived_json="[]"
if [[ ${#derived_gates[@]} -gt 0 ]]; then
  derived_json="$(json_array "${derived_gates[@]}")"
fi
missing_json="[]"
if [[ ${#missing[@]} -gt 0 ]]; then
  missing_json="$(json_array "${missing[@]}")"
fi

derive_report_rel="$derive_report"
if [[ "$derive_report_rel" == "${project_root}/"* ]]; then
  derive_report_rel="${derive_report_rel#"${project_root}"/}"
fi

tmp="${out_file}.tmp.$$"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G1",
  "mode": "strict",
  "check_id": "required-gates-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "proposal_required_gates": ${proposal_json},
    "derived_required_gates": ${derived_json},
    "derive_report": "$(json_escape "$derive_report_rel")"
  },
  "checks": ["required_gates"],
  "artifacts": ["$(json_escape "$derive_report_rel")"],
  "failure_reasons": ${missing_json},
  "next_action": "DevBooks"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "required_gates check failed" "$out_file" "status=pass" "status=${status}" "align proposal.required_gates with derived_required_gates"
  printf '%s\n' "${missing[@]}" >&2
  exit 1
fi

exit 0
