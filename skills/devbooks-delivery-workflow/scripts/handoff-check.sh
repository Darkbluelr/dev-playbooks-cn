#!/usr/bin/env bash
# handoff-check.sh - Verify role handoff has proper confirmation
#
# This script checks that handoff.md exists and has proper confirmation
# signatures from both roles involved in the handoff.
#
# Reference: harden-devbooks-quality-gates design.md AC-004

set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: handoff-check.sh <change-id> [options]

Verify role handoff has proper confirmation:
1. Checks handoff.md exists
2. Verifies all parties have confirmed (default behavior)
3. When higher-scope triggers (risk_level=medium|high OR request_kind=epic|governance OR intervention_level=team|org), requires handoff.md references RUNBOOK.md#Context Capsule
4. When higher-scope triggers, requires handoff.md includes: continuation points, must-run anchors, weak-link obligations
5. Returns exit code based on verification status

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change packages root (default: changes)
  --allow-partial       Allow partial confirmation (at least one [x])
  -h, --help            Show this help message

Exit Codes:
  0 - All checks passed
  1 - Check failed
  2 - Usage error

Examples:
  handoff-check.sh my-change-001
  handoff-check.sh my-change-001 --change-root dev-playbooks/changes
  handoff-check.sh my-change-001 --allow-partial
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
allow_partial=false

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
    --allow-partial)
      allow_partial=true
      shift
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Validate change-id
if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

# Build paths
project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

handoff_file="${change_dir}/handoff.md"
proposal_file="${change_dir}/proposal.md"

echo "handoff-check: checking '${change_id}'"
echo "  change-dir: ${change_dir}"

# Extract change metadata for conditional requirements.
# Note: Some older change packages/tests may not have YAML front matter.
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

risk_level="low"
request_kind="change"
intervention_level="local"
if [[ -f "$proposal_file" ]]; then
  v="$(extract_front_matter_value "$proposal_file" "risk_level")"
  [[ -n "$v" ]] && risk_level="$v"
  v="$(extract_front_matter_value "$proposal_file" "request_kind")"
  [[ -n "$v" ]] && request_kind="$v"
  v="$(extract_front_matter_value "$proposal_file" "intervention_level")"
  [[ -n "$v" ]] && intervention_level="$v"
fi

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
  *) intervention_level="local" ;;
esac

echo "  risk_level: ${risk_level}"
echo "  request_kind: ${request_kind}"
echo "  intervention_level: ${intervention_level}"

# Check change directory exists
if [[ ! -d "$change_dir" ]]; then
  echo "error: missing change directory: ${change_dir}" >&2
  exit 1
fi

# Check handoff.md exists
if [[ ! -f "$handoff_file" ]]; then
  echo "error: missing handoff.md: ${handoff_file}" >&2
  exit 1
fi

# Extract markdown section body by heading regex (ERE).
# Stops at the next markdown heading (any level).
extract_section_body() {
  local file="$1"
  local heading_re="$2"
  awk -v heading_re="$heading_re" '
    BEGIN { in_section=0 }
    {
      line=$0
      sub(/\r$/, "", line)

      if (in_section==0 && line ~ heading_re) { in_section=1; next }
      if (in_section==1) {
        if (line ~ /^#{2,6}[[:space:]]+/) { exit }
        print line
      }
    }
  ' "$file" 2>/dev/null || true
}

trim_ws() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

section_must_have_value_or_na() {
  local file="$1"
  local heading_re="$2"
  local label="$3"

  local body line
  local na_bullet_re na_number_re item_bullet_re item_number_re
  na_bullet_re='^[-*][[:space:]]*(N/A|NA|None|无|无需|Not[[:space:]]+Applicable)($|[[:space:]])'
  na_number_re='^[0-9]+[.)][[:space:]]*(N/A|NA|None|无|无需|Not[[:space:]]+Applicable)($|[[:space:]])'
  item_bullet_re='^[-*][[:space:]]*[^<].+'
  item_number_re='^[0-9]+[.)][[:space:]]*[^<].+'
  body="$(extract_section_body "$file" "$heading_re")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim_ws "$line")"
    [[ -n "$line" ]] || continue

    # Ignore quotes and code fences.
    [[ "$line" == ">"* ]] && continue
    [[ "$line" == '```'* ]] && continue
    [[ "$line" == '~~~'* ]] && continue

    # Explicit N/A / None markers (allow both bullet and numbered list styles).
    if [[ "$line" =~ $na_bullet_re ]]; then
      return 0
    fi
    if [[ "$line" =~ $na_number_re ]]; then
      return 0
    fi

    # Real items: bullet/numbered lines whose content is not a template placeholder.
    if [[ "$line" =~ $item_bullet_re ]]; then
      return 0
    fi
    if [[ "$line" =~ $item_number_re ]]; then
      return 0
    fi
  done <<EOF
${body}
EOF

  echo "error: missing or empty '${label}' section in handoff.md (required for higher-scope handoff)" >&2
  echo "  fix: fill '${label}' (use 'N/A' when not applicable) in ${handoff_file}" >&2
  return 1
}

# Require a deterministic reference + key handoff fields for higher-scope work.
is_higher_scope=false
if [[ "$risk_level" == "medium" || "$risk_level" == "high" ]]; then
  is_higher_scope=true
elif [[ "$request_kind" == "epic" || "$request_kind" == "governance" ]]; then
  is_higher_scope=true
elif [[ "$intervention_level" == "team" || "$intervention_level" == "org" ]]; then
  is_higher_scope=true
fi

trigger_context="risk_level=${risk_level}, request_kind=${request_kind}, intervention_level=${intervention_level}"

if [[ "$is_higher_scope" == true ]]; then
  if ! grep -qE 'RUNBOOK\.md#[[:space:]]*Context Capsule' "$handoff_file" 2>/dev/null; then
    echo "error: missing Context Capsule reference in handoff.md (required for ${trigger_context})" >&2
    echo "  fix: add 'RUNBOOK.md#Context Capsule' to ${handoff_file}" >&2
    exit 1
  fi

  section_must_have_value_or_na "$handoff_file" '^#{2,6}[[:space:]]+.*(续做点|Continuation Points|Remaining Work|剩余工作).*$' "续做点 / Continuation Points" || exit 1
  section_must_have_value_or_na "$handoff_file" '^#{2,6}[[:space:]]+.*(必跑锚点|Must-run Anchors).*$' "必跑锚点 / Must-run Anchors" || exit 1
  section_must_have_value_or_na "$handoff_file" '^#{2,6}[[:space:]]+.*(弱连接义务|Weak-Link Obligations).*$' "弱连接义务 / Weak-Link Obligations" || exit 1
fi

# Check for confirmation section (supports both Chinese and English)
if ! grep -qE "Confirmation Signatures|Confirmation|Confirm|确认签名|确认|签名|交接" "$handoff_file" 2>/dev/null; then
  echo "error: handoff.md missing confirmation section" >&2
  exit 1
fi

# Count confirmed checkboxes (lines with [x] or [X])
confirmed_count=$(grep -cE "^- \[[xX]\]" "$handoff_file" 2>/dev/null) || confirmed_count=0
unconfirmed_count=$(grep -cE "^- \[ \]" "$handoff_file" 2>/dev/null) || unconfirmed_count=0
total_count=$((confirmed_count + unconfirmed_count))

echo "  signatures: ${confirmed_count}/${total_count} confirmed"

if [[ "$confirmed_count" -eq 0 ]]; then
  echo "error: no confirmed signatures in handoff.md (need at least one [x])" >&2
  exit 1
fi

# Default: require all parties to confirm
if [[ "$allow_partial" != true ]]; then
  if [[ "$unconfirmed_count" -gt 0 ]]; then
    echo "error: incomplete signatures - all parties must confirm (${confirmed_count}/${total_count})" >&2
    exit 1
  fi
fi

echo "ok: handoff verification passed"
exit 0
