#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-check.sh <change-id> [--mode <proposal|apply|review|archive|strict>] [--role <test-owner|coder|reviewer>] [--project-root <dir>] [--change-root <dir>] [--truth-root <dir>]

Defaults (can be overridden by flags or env):
  DEVBOOKS_PROJECT_ROOT: pwd
  DEVBOOKS_CHANGE_ROOT:  changes
  DEVBOOKS_TRUTH_ROOT:   specs

Notes:
- Use --change-root and --truth-root to customize paths for your project layout.
- "strict" is meant for archive-ready packages: tasks complete, decision approved, trace matrix not TODO, etc.
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

mode="${DEVBOOKS_MODE:-proposal}"
role="${DEVBOOKS_ROLE:-}"
project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"

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
    --role)
      role="${2:-}"
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

case "$role" in
  ""|test-owner|coder|reviewer) ;;
  *)
    echo "error: invalid --role: '$role'" >&2
    usage
    exit 2
    ;;
esac

# Prefer ripgrep; on macOS Homebrew installs it to /opt/homebrew/bin, which may
# not be present in non-interactive PATH.
if ! command -v rg >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/rg ]]; then
    export PATH="/opt/homebrew/bin:${PATH}"
  fi
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "error: missing dependency: rg (ripgrep)" >&2
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

proposal_file="${change_dir}/proposal.md"
design_file="${change_dir}/design.md"
tasks_file="${change_dir}/tasks.md"
verification_file="${change_dir}/verification.md"
specs_dir="${change_dir}/specs"

errors=0
warnings=0

# Config-driven gate profile (light|standard|strict) and derived context.
GATE_PROFILE="standard"
RISK_LEVEL="low"
REQUEST_KIND="change"
REQUIRED_GATES=()

# Gate report context (v1 schema)
G0_GATE_STATUS=""
G0_FAILURE_REASONS=()
G1_GATE_STATUS=""
G1_FAILURE_REASONS=()
G2_GATE_STATUS=""
G2_FAILURE_REASONS=()
G3_GATE_STATUS=""
G3_FAILURE_REASONS=()
G3_INPUT_PAIRS=()
G3_ARTIFACTS=()
G5_GATE_STATUS=""
G5_FAILURE_REASONS=()
G6_GATE_STATUS=""
G6_FAILURE_REASONS=()
G4_GATE_STATUS=""
G4_FAILURE_REASONS=()
RISK_FLAG_PROTOCOL_V1_1="false"

err() {
  echo "error: $*" >&2
  errors=$((errors + 1))
}

warn() {
  echo "warn: $*" >&2
  warnings=$((warnings + 1))
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

repo_relpath() {
  local p="${1:-}"
  if [[ -z "$p" ]]; then
    printf '%s' ""
    return 0
  fi

  # Normalize leading './'
  if [[ "$p" == ./* ]]; then
    p="${p#./}"
  fi

  # Normalize known macOS symlink prefixes for stable prefix matching:
  # - /var is a symlink to /private/var
  # - /tmp is a symlink to /private/tmp
  local p_norm="$p"
  local project_norm="$project_root"

  case "$p_norm" in
    /private/var/*) p_norm="/var/${p_norm#/private/var/}" ;;
    /private/tmp/*) p_norm="/tmp/${p_norm#/private/tmp/}" ;;
    /private/var) p_norm="/var" ;;
    /private/tmp) p_norm="/tmp" ;;
  esac

  case "$project_norm" in
    /private/var/*) project_norm="/var/${project_norm#/private/var/}" ;;
    /private/tmp/*) project_norm="/tmp/${project_norm#/private/tmp/}" ;;
    /private/var) project_norm="/var" ;;
    /private/tmp) project_norm="/tmp" ;;
  esac

  # Collapse duplicate slashes (e.g. TMPDIR may yield /T//foo)
  p_norm="$(printf '%s' "$p_norm" | tr -s '/')"
  project_norm="$(printf '%s' "$project_norm" | tr -s '/')"

  # Normalize to project-root relative when possible
  if [[ "$p_norm" == "${project_norm}/"* ]]; then
    p="${p_norm:$(( ${#project_norm} + 1 ))}"
  elif [[ "$p_norm" == "$project_norm" ]]; then
    p="."
  fi
  printf '%s' "$p"
}

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

extract_front_matter_list_values() {
  # Extract list items under a top-level YAML front matter list key.
  # Example:
  # required_gates:
  #   - G0
  #   - G1
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { in_yaml=0; in_list=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 && $0 ~ ("^" k ":[[:space:]]*$") { in_list=1; next }
    in_list==1 {
      if ($0 ~ /^[^[:space:]]/) { exit }
      if ($0 ~ /^[[:space:]]*-[[:space:]]*/) {
        line=$0
        sub(/^[[:space:]]*-[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        gsub(/["'\'']/, "", line)
        if (line != "") print line
      }
    }
  ' "$file" 2>/dev/null || true
}

extract_risk_flag_protocol_v1_1() {
  local file="$1"
  awk '
    BEGIN { in_yaml=0; in_flags=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 {
      if ($0 ~ /^risk_flags:[[:space:]]*$/) { in_flags=1; next }
      if (in_flags==1) {
        if ($0 ~ /^[^[:space:]]/) { exit }
        if ($0 ~ /^[[:space:]]+protocol_v1_1:[[:space:]]*/) {
          v=$0
          sub(/^[[:space:]]+protocol_v1_1:[[:space:]]*/, "", v)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
          gsub(/^["'\'']|["'\'']$/, "", v)
          print v
          exit
        }
      }
    }
  ' "$file" 2>/dev/null || true
}

discover_gate_profile_from_config() {
  local default_profile="standard"
  local discovery="${project_root}/scripts/config-discovery.sh"

  if [[ -n "${DEVBOOKS_GATE_PROFILE:-}" ]]; then
    printf '%s' "${DEVBOOKS_GATE_PROFILE}"
    return 0
  fi

  if [[ -f "$discovery" ]]; then
    # config-discovery.sh may not be executable; run via bash.
    bash "$discovery" "$project_root" 2>/dev/null \
      | awk -F= '$1=="GATE_PROFILE" && !found { print $2; found=1 }'
    return 0
  fi

  printf '%s' "$default_profile"
}

init_gate_policy() {
  # Gate profile from config + risk/intervention/required_gates from proposal.
  GATE_PROFILE="$(discover_gate_profile_from_config)"
  case "${GATE_PROFILE}" in
    light|standard|strict) ;;
    *) GATE_PROFILE="standard" ;;
  esac

  if [[ -f "$proposal_file" ]]; then
    v="$(extract_front_matter_value "$proposal_file" "risk_level")"
    if [[ -n "$v" ]]; then
      RISK_LEVEL="$v"
    fi
    v="$(extract_front_matter_value "$proposal_file" "request_kind")"
    if [[ -n "$v" ]]; then
      REQUEST_KIND="$v"
    fi

    v="$(extract_risk_flag_protocol_v1_1 "$proposal_file")"
    if [[ "$v" == "true" ]]; then
      RISK_FLAG_PROTOCOL_V1_1="true"
    else
      RISK_FLAG_PROTOCOL_V1_1="false"
    fi

    REQUIRED_GATES=()
    while IFS= read -r g; do
      [[ -n "$g" ]] || continue
      REQUIRED_GATES+=("$g")
    done < <(extract_front_matter_list_values "$proposal_file" "required_gates")
  fi

  case "$RISK_LEVEL" in
    low|medium|high) ;;
    *) RISK_LEVEL="low" ;;
  esac

  case "$REQUEST_KIND" in
    debug|change|epic|void|bootstrap|governance) ;;
    *) REQUEST_KIND="change" ;;
  esac
}

gate_is_required() {
  local gate_id="$1"
  if [[ ${#REQUIRED_GATES[@]} -eq 0 ]]; then
    return 0
  fi
  local g
  for g in "${REQUIRED_GATES[@]}"; do
    if [[ "$g" == "$gate_id" ]]; then
      return 0
    fi
  done
  return 1
}

gate_severity() {
  local gate_id="$1"
  if ! gate_is_required "$gate_id"; then
    printf '%s' "skip"
    return 0
  fi

  local sev="warn"
  case "$GATE_PROFILE" in
    strict)
      sev="block"
      ;;
    standard)
      case "$gate_id" in
        G0|G1|G2|G4|G6) sev="block" ;;
        G3|G5) sev="warn" ;;
        *) sev="warn" ;;
      esac
      ;;
    light)
      case "$gate_id" in
        G1|G4|G6) sev="block" ;;
        *) sev="warn" ;;
      esac
      ;;
  esac

  # Risk upgrades (presence-based enforcement)
  if [[ "$gate_id" == "G3" && ( "$RISK_LEVEL" == "high" || "$REQUEST_KIND" == "epic" ) ]]; then
    sev="block"
  fi
  if [[ "$gate_id" == "G5" && ( "$RISK_LEVEL" == "medium" || "$RISK_LEVEL" == "high" ) ]]; then
    sev="block"
  fi
  if [[ "$gate_id" == "G5" && "${RISK_FLAG_PROTOCOL_V1_1}" == "true" ]]; then
    sev="block"
  fi

  printf '%s' "$sev"
}

gate_record_failure() {
  local gate_id="$1"
  local message="$2"

  case "$gate_id" in
    G0) G0_FAILURE_REASONS+=("$message") ;;
    G1) G1_FAILURE_REASONS+=("$message") ;;
    G2) G2_FAILURE_REASONS+=("$message") ;;
    G3) G3_FAILURE_REASONS+=("$message") ;;
    G4) G4_FAILURE_REASONS+=("$message") ;;
    G5) G5_FAILURE_REASONS+=("$message") ;;
    G6) G6_FAILURE_REASONS+=("$message") ;;
  esac
}

gate_issue() {
  local gate_id="$1"
  shift
  local message="$*"

  local sev
  sev="$(gate_severity "$gate_id")"
  if [[ "$sev" == "skip" ]]; then
    warn "skipped ${gate_id} failure (not required): ${message}"
    return 0
  fi

  gate_record_failure "$gate_id" "$message"

  if [[ "$sev" == "warn" ]]; then
    warn "$message"
    case "$gate_id" in
      G0)
        if [[ "$G0_GATE_STATUS" != "fail" ]]; then
          G0_GATE_STATUS="warn"
        fi
        ;;
      G1)
        if [[ "$G1_GATE_STATUS" != "fail" ]]; then
          G1_GATE_STATUS="warn"
        fi
        ;;
      G2)
        if [[ "$G2_GATE_STATUS" != "fail" ]]; then
          G2_GATE_STATUS="warn"
        fi
        ;;
      G3)
        if [[ "$G3_GATE_STATUS" != "fail" ]]; then
          G3_GATE_STATUS="warn"
        fi
        ;;
      G4)
        if [[ "$G4_GATE_STATUS" != "fail" ]]; then
          G4_GATE_STATUS="warn"
        fi
        ;;
      G5)
        if [[ "$G5_GATE_STATUS" != "fail" ]]; then
          G5_GATE_STATUS="warn"
        fi
        ;;
      G6)
        if [[ "$G6_GATE_STATUS" != "fail" ]]; then
          G6_GATE_STATUS="warn"
        fi
        ;;
    esac
    return 0
  fi

  case "$gate_id" in
    G0) G0_GATE_STATUS="fail" ;;
    G1) G1_GATE_STATUS="fail" ;;
    G2) G2_GATE_STATUS="fail" ;;
    G3) G3_GATE_STATUS="fail" ;;
    G4) G4_GATE_STATUS="fail" ;;
    G5) G5_GATE_STATUS="fail" ;;
    G6) G6_GATE_STATUS="fail" ;;
  esac
  err "$message"
}

json_status_from_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  rg -o -- '"status"[[:space:]]*:[[:space:]]*"[^"]+"' "$file" -m 1 2>/dev/null \
    | sed -E 's/.*"status"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | head -n 1
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    gate_issue "G0" "missing file: ${file}"
    return 1
  fi
  return 0
}

contains_placeholder() {
  local file="$1"
  # Pattern includes intentional Chinese quotes for detecting placeholders
  # shellcheck disable=SC2140
  if rg -n '<change-id>|<truth-root>|<change-root>|<one-line-goal>|<one-sentence goal>|<one-sentence-goal>|<capability>|<you>|YYYY-MM-DD|<session/agent>|<fill "none"|TODO\b' "$file" >/dev/null; then
    return 0
  fi
  return 1
}

is_archive_change_id() {
  [[ "$change_id" == archive/* ]]
}

# =============================================================================
# Shared SKIP-APPROVED detection helper (DRY refactoring)
# Checks if a task at index has SKIP-APPROVED on prev/same/next line
# Usage: is_skip_approved "line" "prev_line" "next_line" [strict_html_comment]
# Note: Uses positional params instead of nameref for bash 3.2 compatibility
# =============================================================================
is_skip_approved() {
  local line="$1"
  local prev_line="${2:-}"
  local next_line="${3:-}"
  local strict_html="${4:-false}"
  local html_skip_pattern='^[[:space:]]*<!--[[:space:]]*SKIP-APPROVED:'

  # Check same line
  if [[ "$line" =~ SKIP-APPROVED: ]]; then
    return 0
  fi

  # Check previous line
  if [[ -n "$prev_line" ]]; then
    if [[ "$strict_html" == true ]]; then
      if [[ "$prev_line" =~ $html_skip_pattern ]]; then
        return 0
      fi
    else
      if [[ "$prev_line" =~ SKIP-APPROVED: ]]; then
        return 0
      fi
    fi
  fi

  # Check next line
  if [[ -n "$next_line" ]]; then
    if [[ "$strict_html" == true ]]; then
      if [[ "$next_line" =~ $html_skip_pattern ]]; then
        return 0
      fi
    else
      if [[ "$next_line" =~ SKIP-APPROVED: ]]; then
        return 0
      fi
    fi
  fi

  return 1
}

# =============================================================================
# Shared file reading helper (DRY refactoring)
# Reads file into global _LINES array and sets _LINE_COUNT
# Usage: _read_file_to_lines "$file_path"
# After call: use _LINES array and _LINE_COUNT variable
# =============================================================================
_LINES=()
_LINE_COUNT=0

_read_file_to_lines() {
  local file="$1"
  _LINES=()
  _LINE_COUNT=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    _LINES+=("$line")
  done < "$file"

  _LINE_COUNT=${#_LINES[@]}
}

# Helper: Get prev/next line context for iteration
# Usage: _get_line_context $index
# Sets: _PREV_LINE, _NEXT_LINE
_PREV_LINE=""
_NEXT_LINE=""

_get_line_context() {
  local i=$1
  _PREV_LINE=""
  _NEXT_LINE=""

  if [[ $i -gt 0 ]]; then
    _PREV_LINE="${_LINES[$((i - 1))]}"
  fi
  if [[ $((i + 1)) -lt $_LINE_COUNT ]]; then
    _NEXT_LINE="${_LINES[$((i + 1))]}"
  fi
}

check_proposal() {
  require_file "$proposal_file" || return 0

  # Support both numbered (## 1. Why...) and unnumbered (## Why...) headings
  for h in "Why" "What Changes" "Impact" "Risks" "Validation" "Debate Packet" "Decision Log"; do
    if ! rg -n "^## [0-9]*\\.? *${h}" "$proposal_file" >/dev/null; then
      gate_issue "G0" "proposal missing heading containing '${h}': ${proposal_file}"
    fi
  done

  if ! rg -n "^- (Value Signal and Observation|价值信号与观测口径)[:：]" "$proposal_file" >/dev/null; then
    if [[ "$mode" == "strict" ]]; then
      gate_issue "G0" "proposal missing '- Value Signal and Observation:' (strict): ${proposal_file}"
    else
      warn "proposal missing '- Value Signal and Observation:' (recommended): ${proposal_file}"
    fi
  fi

  if ! rg -n "^- (Value Stream Bottleneck Hypothesis|价值流瓶颈假设)[:：]?" "$proposal_file" >/dev/null; then
    if [[ "$mode" == "strict" ]]; then
      gate_issue "G0" "proposal missing '- Value Stream Bottleneck Hypothesis...' (strict): ${proposal_file}"
    else
      warn "proposal missing '- Value Stream Bottleneck Hypothesis...' (recommended): ${proposal_file}"
    fi
  fi
  local decision_line
  decision_line=$(rg -n "^- (Decision Status|Decision|决策状态|决策)[:：] *(Pending|Approved|Revise|Rejected)\b" "$proposal_file" -m 1 || true)
  if [[ -z "$decision_line" ]]; then
    gate_issue "G0" "proposal missing decision line (e.g., '- Decision Status: Approved' or '- 决策状态： Approved'): ${proposal_file}"
    return 0
  fi

  local value
  value="$(echo "$decision_line" | sed -E 's/^[0-9]+:- (Decision Status|Decision|决策状态|决策)[:：] *//')"

  case "$value" in
    Pending|Approved|Revise|Rejected) ;;
    *)
      gate_issue "G0" "proposal has invalid decision status '${value}': ${proposal_file}"
      ;;
  esac

  if [[ "$mode" == "apply" || "$mode" == "archive" || "$mode" == "strict" ]]; then
    if [[ "$value" != "Approved" ]]; then
      gate_issue "G0" "proposal decision status must be Approved for ${mode}: ${proposal_file}"
    fi
  fi

  if [[ "$mode" == "strict" ]]; then
    if contains_placeholder "$proposal_file"; then
      gate_issue "G0" "proposal contains placeholders/TODO (strict): ${proposal_file}"
    fi
  fi
}

check_design() {
  if [[ ! -f "$design_file" ]]; then
    if [[ "$mode" == "proposal" ]]; then
      warn "missing design.md (recommended for non-trivial changes): ${design_file}"
      return 0
    fi
    gate_issue "G0" "missing design.md: ${design_file}"
    return 0
  fi

  # Support headings with annotations: ## Acceptance Criteria
  if ! rg -n "^## Acceptance Criteria" "$design_file" >/dev/null; then
    gate_issue "G0" "design missing '## Acceptance Criteria' heading: ${design_file}"
  fi

  if ! rg -n "AC-[0-9]{3}" "$design_file" >/dev/null; then
    gate_issue "G0" "design missing any AC-xxx items: ${design_file}"
  fi

  # ============================================================================
  # Design pattern reference: Problem Context / Rationale / Trade-offs required
  # ============================================================================
  if [[ "$mode" == "apply" || "$mode" == "archive" || "$mode" == "strict" ]]; then
    if ! rg -n "^## Problem Context" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        gate_issue "G0" "design missing '## Problem Context' section (strict): ${design_file}"
      else
        warn "design missing '## Problem Context' section (recommended): ${design_file}"
      fi
    fi

    if ! rg -n "^## Design Rationale" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        gate_issue "G0" "design missing '## Design Rationale' section (strict): ${design_file}"
      else
        warn "design missing '## Design Rationale' section (recommended): ${design_file}"
      fi
    fi

    if ! rg -n "^## Trade-offs" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        gate_issue "G0" "design missing '## Trade-offs' section (strict): ${design_file}"
      else
        warn "design missing '## Trade-offs' section (recommended): ${design_file}"
      fi
    fi
  fi

  # ============================================================================
  # Design pattern reference: Encapsulate variation points check (in design principles)
  # ============================================================================
  if [[ "$mode" == "strict" ]]; then
    if ! rg -n "Variation Point|Encapsulate.*Vari" "$design_file" >/dev/null; then
      warn "design may not have identified variation points (strict): ${design_file}"
    fi
  fi

  if [[ "$mode" == "strict" ]]; then
    if contains_placeholder "$design_file"; then
      gate_issue "G0" "design contains placeholders/TODO (strict): ${design_file}"
    fi
  fi
}

check_tasks() {
  require_file "$tasks_file" || return 0

  if ! rg -n "Main Plan Area|主线计划区" "$tasks_file" >/dev/null; then
    gate_issue "G0" "tasks missing Main Plan Area/主线计划区: ${tasks_file}"
  fi

  if ! rg -n "Context Switch Breakpoint Area|断点区" "$tasks_file" >/dev/null; then
    gate_issue "G0" "tasks missing Context Switch Breakpoint Area/断点区: ${tasks_file}"
  fi

  if ! rg -n "^- \\[[ xX]\\]" "$tasks_file" >/dev/null; then
    gate_issue "G0" "tasks missing checkbox items '- [ ]'/'- [x]': ${tasks_file}"
  fi

  if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
    # Check for unchecked items that are NOT skip-approved
    local has_unapproved_unchecked=false
    _read_file_to_lines "$tasks_file"

    for ((i=0; i<_LINE_COUNT; i++)); do
      local line="${_LINES[$i]}"
      if [[ "$line" =~ ^-\ \[\ \] ]]; then
        _get_line_context "$i"
        # Found unchecked task, check if skip-approved using shared helper
        if ! is_skip_approved "$line" "$_PREV_LINE" "$_NEXT_LINE"; then
          has_unapproved_unchecked=true
          break
        fi
      fi
    done

    if [[ "$has_unapproved_unchecked" == true ]]; then
      gate_issue "G0" "tasks still contains unchecked items without skip approval (archive/strict): ${tasks_file}"
    fi
  fi

  if [[ "$mode" == "strict" ]]; then
    if contains_placeholder "$tasks_file"; then
      gate_issue "G0" "tasks contains placeholders/TODO (strict): ${tasks_file}"
    fi
  fi
}

extract_ac_ids() {
  local file="$1"
  rg -o "AC-[0-9]{3}" "$file" 2>/dev/null | sort -u || true
}

check_verification() {
  if [[ ! -f "$verification_file" ]]; then
    if [[ "$mode" == "proposal" ]]; then
      warn "missing verification.md (expected during apply by test-owner): ${verification_file}"
      return 0
    fi
    gate_issue "G0" "missing verification.md: ${verification_file}"
    return 0
  fi

  # ==========================================================================
  # AC-010: Verification Status Check
  # Status field controls change package lifecycle: Draft → Ready → Done → Archived
  # Only Reviewer can set Status to "Done" (Coder/Test Owner prohibited)
  # ==========================================================================
  if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
    local status_line
    status_line=$(rg -n "^- Status[:：] *(Draft|Ready|Done|Archived)\b" "$verification_file" -m 1 || true)
    if [[ -z "$status_line" ]]; then
      gate_issue "G0" "verification missing Status line (e.g., '- Status: Done'): ${verification_file}"
    else
      local status_value
      status_value="$(echo "$status_line" | sed -E 's/^[0-9]+:- Status[:：] *//')"
      if [[ "$status_value" != "Done" && "$status_value" != "Archived" ]]; then
        gate_issue "G0" "verification Status must be 'Done' or 'Archived' for ${mode} (current: '${status_value}'). Only Reviewer can set Status to Done: ${verification_file}"
      fi
    fi
  fi

  for h in "A\) (Test Plan Directive Table|测试计划指令表)" "B\) (Traceability Matrix|追溯矩阵)" "C\) (Execution Anchors|执行锚点)" "D\) (MANUAL-\* Checklist|MANUAL-\* 清单)"; do
    if ! rg -n "${h}" "$verification_file" >/dev/null; then
      gate_issue "G0" "verification missing section '${h}': ${verification_file}"
    fi
  done

  if ! rg -n "^\\| AC-[0-9]{3} \\|" "$verification_file" >/dev/null; then
    gate_issue "G0" "verification trace matrix missing any AC rows: ${verification_file}"
  fi

  if [[ "$mode" == "strict" ]]; then
    # G) section is recommended but not blocking
    if ! rg -n "^(## )?G\) (Value Stream and Metrics|价值流与度量)" "$verification_file" >/dev/null; then
      warn "verification missing 'G) Value Stream and Metrics' section (recommended for strict): ${verification_file}"
    else
      # Only check Target Value Signal if G) section exists
      if ! rg -n "^- (Target Value Signal|目标价值信号)[:：]" "$verification_file" >/dev/null; then
        warn "verification missing '- Target Value Signal:' line (recommended): ${verification_file}"
      fi
    fi

    if rg -n "^\\| AC-[0-9]{3} \\|.*\\| *TODO *\\|" "$verification_file" >/dev/null; then
      gate_issue "G0" "verification trace matrix still has TODO rows (strict): ${verification_file}"
    fi

    if contains_placeholder "$verification_file"; then
      gate_issue "G0" "verification contains placeholders/TODO (strict): ${verification_file}"
    fi

    if [[ -f "$design_file" ]]; then
      design_acs="$(extract_ac_ids "$design_file")"
      verification_acs="$(extract_ac_ids "$verification_file")"
      while IFS= read -r ac; do
        [[ -n "$ac" ]] || continue
        if ! printf "%s\n" "$verification_acs" | rg -x "$ac" >/dev/null; then
          gate_issue "G0" "verification missing AC '${ac}' from design: ${verification_file}"
        fi
      done <<<"$design_acs"
    fi

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -x "${script_dir}/guardrail-check.sh" ]]; then
      if ! "${script_dir}/guardrail-check.sh" "$change_id" --project-root "$project_root" --change-root "$change_root" >/dev/null; then
        gate_issue "G0" "guardrail-check failed (strict): ${verification_file}"
      fi
    else
      warn "missing guardrail-check.sh; skipping guardrail check"
    fi
  fi
}

check_spec_deltas() {
  if [[ ! -d "$specs_dir" ]]; then
    return 0
  fi

  local found_any=false
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    found_any=true
    if ! rg -n "^## (ADDED|MODIFIED|REMOVED) Requirements$" "$file" >/dev/null; then
      gate_issue "G0" "spec delta missing '## ADDED|MODIFIED|REMOVED Requirements' headings: ${file}"
    fi

    awk '
      BEGIN { req = 0; scen = 0; bad = 0; }
      /^### Requirement:/ {
        if (req > 0 && scen == 0) { bad++; }
        req++; scen = 0;
      }
      /^#### Scenario:/ { scen++; }
      END {
        if (req > 0 && scen == 0) { bad++; }
        if (req == 0) { print "NO_REQUIREMENTS"; exit 0; }
        if (bad > 0) { print "BAD_REQUIREMENTS " bad; exit 0; }
        print "OK";
      }
    ' "$file" | {
      read -r result rest || true
      if [[ "$result" == "NO_REQUIREMENTS" ]]; then
        gate_issue "G0" "spec delta has no '### Requirement:' entries: ${file}"
      elif [[ "$result" == "BAD_REQUIREMENTS" ]]; then
        gate_issue "G0" "spec delta has Requirement(s) without Scenario (count=${rest}): ${file}"
      fi
    }

    if [[ "$mode" == "strict" ]]; then
      if rg -n "<change-id>|<truth-root>|<change-root>|<capability>|TBD\\b|TODO\\b" "$file" >/dev/null; then
        gate_issue "G0" "spec delta contains placeholders/TBD/TODO (strict): ${file}"
      fi
    fi
  done < <(find "$specs_dir" -type f -name "spec.md" 2>/dev/null | sort)

  if [[ "$found_any" == false ]]; then
    return 0
  fi
}

# =============================================================================
# Constitution Check (Dev-Playbooks)
# Verify project constitution is present and valid
# =============================================================================
check_constitution() {
  # Only run in strict mode
  if [[ "$mode" != "strict" ]]; then
    return 0
  fi

  # Skip for non-DevBooks projects (e.g., minimal CI fixtures in tests/)
  # DevBooks projects usually have dev-playbooks/ (or devbooks/) or a .devbooks/config.yaml.
  if [[ ! -d "${project_root}/dev-playbooks" && ! -d "${project_root}/devbooks" && ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  # Find constitution-check.sh
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local constitution_script="${script_dir}/constitution-check.sh"

  if [[ ! -x "$constitution_script" ]]; then
    warn "constitution-check.sh not found; skipping constitution check"
    return 0
  fi

  # Run constitution check
  echo "  constitution check..."
  if ! "$constitution_script" "$project_root" --quiet 2>/dev/null; then
    gate_issue "G0" "constitution check failed (strict): project constitution missing or invalid"
    return 0
  fi
}

# =============================================================================
# Fitness Check (Dev-Playbooks)
# Verify architecture fitness rules
# =============================================================================
check_fitness() {
  # Only run in apply/archive/strict modes
  if [[ "$mode" != "apply" && "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # Find fitness-check.sh
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local fitness_script="${script_dir}/fitness-check.sh"

  if [[ ! -x "$fitness_script" ]]; then
    warn "fitness-check.sh not found; skipping fitness check"
    return 0
  fi

  # Determine fitness mode based on change-check mode
  local fitness_mode="warn"
  if [[ "$mode" == "strict" ]]; then
    fitness_mode="error"
  fi

  # Run fitness check
  echo "  fitness check (mode=${fitness_mode})..."
  if ! "$fitness_script" --project-root "$project_root" --mode "$fitness_mode" 2>/dev/null; then
    if [[ "$fitness_mode" == "error" ]]; then
      gate_issue "G4" "fitness check failed (strict): architecture fitness check failed"
    else
      warn "fitness check warnings detected"
    fi
  fi
}

# =============================================================================
# AC-001: Green Evidence Closure Check (Mythical Man-Month Ch.6 "Communication")
# Block archive when Green evidence is missing
# =============================================================================
check_evidence_closure() {
  # Only run in archive/strict modes
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local evidence_dir="${change_dir}/evidence/green-final"

  if [[ ! -d "$evidence_dir" ]]; then
    gate_issue "G2" "Missing Green evidence: evidence/green-final/ does not exist (AC-001)"
    return 0
  fi

  # Check if directory has at least one file
  local file_count
  file_count=$(find "$evidence_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$file_count" -eq 0 ]]; then
    gate_issue "G2" "Missing Green evidence: evidence/green-final/ is empty (AC-001)"
    return 0
  fi
}

# =============================================================================
# AC-002: Task Completion Rate Check (Enhanced)
# Enforce 100% task completion in strict mode with rate display
# Skip-approved tasks count as completed
# =============================================================================
check_task_completion_rate() {
  # Only run in strict mode for completion rate
  if [[ "$mode" != "strict" ]]; then
    return 0
  fi

  if [[ ! -f "$tasks_file" ]]; then
    return 0
  fi

  # Read file using shared helper
  _read_file_to_lines "$tasks_file"

  local total_tasks=0
  local completed_tasks=0

  for ((i=0; i<_LINE_COUNT; i++)); do
    local line="${_LINES[$i]}"

    # Count all checkbox items (both checked and unchecked)
    if [[ "$line" =~ ^-\ \[[\ xX]\] ]]; then
      total_tasks=$((total_tasks + 1))

      # Check if completed (checked)
      if [[ "$line" =~ ^-\ \[[xX]\] ]]; then
        completed_tasks=$((completed_tasks + 1))
      elif [[ "$line" =~ ^-\ \[\ \] ]]; then
        _get_line_context "$i"
        # Unchecked - check if skip-approved using shared helper
        if is_skip_approved "$line" "$_PREV_LINE" "$_NEXT_LINE"; then
          completed_tasks=$((completed_tasks + 1))
        fi
      fi
    fi
  done

  if [[ "$total_tasks" -eq 0 ]]; then
    # No tasks = 100% complete
    return 0
  fi

  local incomplete_tasks=$((total_tasks - completed_tasks))
  if [[ "$incomplete_tasks" -gt 0 ]]; then
    local rate=$((completed_tasks * 100 / total_tasks))
    gate_issue "G2" "Task completion rate ${rate}% (${completed_tasks}/${total_tasks}), need 100% (AC-002)"
  fi
}

# =============================================================================
# AC-007: Test Failure in Evidence Check
# Block archive when test failures exist in Green evidence
# Pattern is designed to avoid false positives like "0 tests FAIL" or comments
# =============================================================================
check_test_failure_in_evidence() {
  # Only run in archive/strict modes
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local evidence_dir="${change_dir}/evidence/green-final"

  if [[ ! -d "$evidence_dir" ]]; then
    # Already checked in check_evidence_closure
    return 0
  fi

  # Check for failure patterns in evidence files (use --no-ignore to search .log files)
  # Patterns designed for common test frameworks:
  #   - TAP: "not ok" at line start
  #   - Jest/Vitest: "FAIL " followed by path
  #   - pytest: "FAILED " at line start
  #   - Go: "--- FAIL:" at line start
  #   - BATS: "not ok" at line start
  #   - Generic: "FAIL:" "FAILED:" "[FAIL]" "[FAILED]" "[ERROR]" markers
  # Exclude: "0 tests FAIL", "0 failed", comments, variable names
  local fail_pattern='^not ok |^FAIL[: ]|^FAILED[: ]|^--- FAIL:|^\[FAIL\]|^\[FAILED\]|^\[ERROR\]|^ERROR:|: FAIL$|: FAILED$'

  if rg --no-ignore -l "$fail_pattern" "$evidence_dir" >/dev/null 2>&1; then
    # Double-check: exclude files that only have success patterns
    local fail_files
    fail_files=$(rg --no-ignore -l "$fail_pattern" "$evidence_dir" 2>/dev/null || true)

    for file in $fail_files; do
      # Check if the match is a real failure (not "0 tests failed" pattern)
      if rg --no-ignore "$fail_pattern" "$file" 2>/dev/null | grep -qvE "^[[:space:]]*#|0 (tests?|failures?|failed)"; then
        gate_issue "G2" "Test failure: Green evidence contains failure pattern, cannot archive (AC-007)"
        echo "  File: $file" >&2
        return 0
      fi
    done
  fi
}

# =============================================================================
# AC-005: P0 Skip Approval Check
# Enforce P0 task skip requires SKIP-APPROVED comment
# SKIP-APPROVED can be on the line before, same line, or line after the task
# =============================================================================
check_skip_approval() {
  # Only run in strict mode
  if [[ "$mode" != "strict" ]]; then
    return 0
  fi

  if [[ ! -f "$tasks_file" ]]; then
    return 0
  fi

  # Read file using shared helper
  _read_file_to_lines "$tasks_file"

  for ((i=0; i<_LINE_COUNT; i++)); do
    local line="${_LINES[$i]}"

    # Check for unchecked P0 task
    if [[ "$line" =~ ^-\ \[\ \]\ \[P0\] ]]; then
      local p0_task_name
      p0_task_name=$(echo "$line" | sed -E 's/^- \[ \] \[P0\] //')

      _get_line_context "$i"
      # Use shared helper with strict_html=true for prev/next line HTML comment check
      if ! is_skip_approved "$line" "$_PREV_LINE" "$_NEXT_LINE" true; then
        gate_issue "G2" "P0 task skip requires approval: ${p0_task_name} (AC-005)"
      fi
    fi
  done
}

# =============================================================================
# AC-006: Environment Match Check
# Call env-match-check.sh to verify test environment declaration
# =============================================================================
check_env_match() {
  # Only run in archive/strict modes
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # Check if env-match-check.sh exists
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local env_check_script="${script_dir}/env-match-check.sh"

  if [[ ! -x "$env_check_script" ]]; then
    warn "env-match-check.sh not found; skipping environment check"
    return 0
  fi

  # Run env-match-check
  if ! "$env_check_script" "$change_id" --project-root "$project_root" --change-root "$change_root" >/dev/null 2>&1; then
    gate_issue "G3" "Test environment declaration missing: verification.md needs 'Test Environment Declaration' section (AC-006)"
  fi
}

# =============================================================================
# Knife Plan Gate (REQ-KNIFE-004)
# When risk_level=high OR request_kind=epic, require a machine-readable
# Knife Plan under truth-root/_meta/epics/<epic_id>/knife-plan.(yaml|json)
# =============================================================================
check_knife_plan() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local knife_script="${script_dir}/knife-plan-check.sh"

  if [[ ! -x "$knife_script" ]]; then
    warn "knife-plan-check.sh not found; skipping Knife Plan gate"
    return 0
  fi

  local report_path="${change_dir}/evidence/gates/knife-plan-check-${mode}.json"
  local report_path_rel
  report_path_rel="$(repo_relpath "$report_path")"

  # Prepare G3 report enrichment (add-only) when Knife Plan gate is required.
  # Avoid parsing JSON: derive required/paths from proposal front matter + filesystem.
  G3_INPUT_PAIRS=()
  G3_ARTIFACTS=()

  local risk_level="low"
  local request_kind="change"
  local epic_id=""
  if [[ -f "$proposal_file" ]]; then
    v="$(extract_front_matter_value "$proposal_file" "risk_level")"
    if [[ -n "$v" ]]; then
      risk_level="$v"
    fi
    v="$(extract_front_matter_value "$proposal_file" "request_kind")"
    if [[ -n "$v" ]]; then
      request_kind="$v"
    fi
    epic_id="$(extract_front_matter_value "$proposal_file" "epic_id")"
  fi

  local required=false
  if [[ "$risk_level" == "high" || "$request_kind" == "epic" ]]; then
    required=true
  fi

  local truth_root_rel
  truth_root_rel="$(repo_relpath "$truth_dir")"

  if [[ "$required" == true ]]; then
    G3_INPUT_PAIRS+=("knife_plan_check_report=${report_path_rel}")
    G3_ARTIFACTS+=("${report_path_rel}")

    if [[ -n "$epic_id" ]]; then
      local epic_dir="${truth_dir}/_meta/epics/${epic_id}"
      local knife_plan_path=""
      if [[ -f "${epic_dir}/knife-plan.yaml" ]]; then
        knife_plan_path="${epic_dir}/knife-plan.yaml"
      elif [[ -f "${epic_dir}/knife-plan.json" ]]; then
        knife_plan_path="${epic_dir}/knife-plan.json"
      fi

      if [[ -n "$knife_plan_path" ]]; then
        local knife_plan_rel
        knife_plan_rel="$(repo_relpath "$knife_plan_path")"
        G3_INPUT_PAIRS+=("knife_plan_path=${knife_plan_rel}")
        G3_ARTIFACTS+=("${knife_plan_rel}")
      else
        G3_INPUT_PAIRS+=("knife_plan_expected_path=${truth_root_rel}/_meta/epics/${epic_id}/knife-plan.(yaml|json)")
      fi
    fi
  fi

  local rc=0
  "$knife_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_path" || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G3" "Knife Plan gate failed (REQ-KNIFE-004): ${report_path}"
  else
    if [[ -z "${G3_GATE_STATUS}" ]]; then
      G3_GATE_STATUS="pass"
    fi
  fi
}

# =============================================================================
# AC-008: Documentation Impact Check
# Verify documentation impact is declared and fulfilled
# =============================================================================
check_docs_impact() {
  # Only run in archive/strict modes
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  if [[ ! -f "$design_file" ]]; then
    return 0
  fi

  # Check if Documentation Impact section exists
  if ! rg -n "^## Documentation Impact" "$design_file" >/dev/null; then
    warn "design.md missing '## Documentation Impact' section (recommended)"
    return 0
  fi

  # Check for "no update needed" declaration - if checked, skip further checks
  if rg -n "^\- \[x\] This change is internal refactoring|^\- \[x\] This change only fixes" "$design_file" >/dev/null; then
    # Declared as no doc update needed, skip
    return 0
  fi

  # Check for P0 documentation updates that are NOT checked in the checklist
  # Look for unchecked P0 items in the table
  local has_p0_docs=false
  if rg -n "\| P0 \|" "$design_file" >/dev/null 2>&1; then
    has_p0_docs=true
  fi

  if [[ "$has_p0_docs" == true ]]; then
    # Check if documentation update checklist items are completed
    local unchecked_items
    unchecked_items=$(rg -n "^\- \[ \] New script|^\- \[ \] New config|^\- \[ \] New workflow|^\- \[ \] API" "$design_file" || true)

    if [[ -n "$unchecked_items" && "$mode" == "strict" ]]; then
      gate_issue "G4" "Documentation update checklist has incomplete items (AC-008)"
      echo "  Incomplete items:" >&2
      printf "%s\n" "$unchecked_items" | head -3 | sed 's/^/    /' >&2
    fi
  fi

  # In strict mode, verify declared docs are actually modified
  if [[ "$mode" == "strict" ]] && command -v git >/dev/null 2>&1; then
    if git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      # Extract declared P0 docs from design.md
      local declared_docs
      declared_docs=$(rg -o "\| (README\.md|docs/[^|]+\.md|CHANGELOG\.md) \|" "$design_file" 2>/dev/null | sed 's/| //g; s/ |//g' | sort -u || true)

      if [[ -n "$declared_docs" ]]; then
        # Get changed files
        local changed_files
        changed_files=$(git -C "$project_root" diff --name-only HEAD 2>/dev/null || git -C "$project_root" diff --name-only 2>/dev/null || true)

        while IFS= read -r doc; do
          [[ -n "$doc" ]] || continue
          # Check if the declared doc is in the changed files
          if ! printf "%s\n" "$changed_files" | grep -qF "$doc"; then
            warn "Declared to update but not modified: $doc (recommend checking)"
          fi
        done <<< "$declared_docs"
      fi
    fi
  fi
}

# =============================================================================
# G0: Change Metadata Contract + Baseline Bootstrap (REQ-CP-001/REQ-CP-002)
# =============================================================================
check_change_metadata_contract() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G0"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local meta_script="${script_dir}/change-metadata-check.sh"

  if [[ ! -x "$meta_script" ]]; then
    warn "change-metadata-check.sh not found; skipping change metadata contract check"
    return 0
  fi

  local report_rel="evidence/gates/change-metadata-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$meta_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G0" "change metadata contract check failed (G0): ${report_path}"
    return 0
  fi

  if [[ -z "$G0_GATE_STATUS" ]]; then
    G0_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G0: State Machine Abnormal Transition Constraints (state.audit.yaml)
# =============================================================================
check_state_audit_contract() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G0"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local audit_script="${script_dir}/state-audit-check.sh"

  if [[ ! -x "$audit_script" ]]; then
    warn "state-audit-check.sh not found; skipping state audit check"
    return 0
  fi

  local report_rel="evidence/gates/state-audit-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$audit_script" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G0" "state audit check failed (G0): ${report_path}"
    return 0
  fi

  if [[ -z "$G0_GATE_STATUS" ]]; then
    G0_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G0: Void Protocol Contract (when next_action=Void)
# =============================================================================
check_void_protocol_contract() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G0"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local void_script="${script_dir}/void-protocol-check.sh"

  if [[ ! -x "$void_script" ]]; then
    warn "void-protocol-check.sh not found; skipping void protocol check"
    return 0
  fi

  local report_rel="evidence/gates/void-protocol-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$void_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G0" "void protocol check failed (G0): ${report_path}"
    return 0
  fi

  if [[ -z "$G0_GATE_STATUS" ]]; then
    G0_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G1: required_gates derivation + deterministic validation
# =============================================================================
check_required_gates_contract() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G1"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local req_script="${script_dir}/required-gates-check.sh"

  if [[ ! -x "$req_script" ]]; then
    warn "required-gates-check.sh not found; skipping required_gates contract check"
    return 0
  fi

  local report_rel="evidence/gates/required-gates-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$req_script" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G1" "required_gates contract check failed (G1): ${report_path}"
    return 0
  fi

  if [[ -z "$G1_GATE_STATUS" ]]; then
    G1_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G3: Deterministic Verification Anchors Contract (Completion Contract checks[])
# =============================================================================
check_verification_anchors_contract() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G3"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local anchors_script="${script_dir}/verification-anchors-check.sh"

  if [[ ! -x "$anchors_script" ]]; then
    warn "verification-anchors-check.sh not found; skipping verification anchors contract check"
    return 0
  fi

  local report_rel="evidence/gates/verification-anchors-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$anchors_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G3" "verification anchors contract check failed (G3): ${report_path}"
    return 0
  fi

  if [[ -z "$G3_GATE_STATUS" ]]; then
    G3_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G3: Knife Correctness Gate (MECE/DAG/budget/independent-green)
# =============================================================================
check_knife_correctness_gate() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G3"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local k_script="${script_dir}/knife-correctness-check.sh"

  if [[ ! -x "$k_script" ]]; then
    warn "knife-correctness-check.sh not found; skipping Knife Correctness gate"
    return 0
  fi

  local report_rel="evidence/gates/knife-correctness-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$k_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G3" "Knife Correctness gate failed (G3): ${report_path}"
    return 0
  fi

  if [[ -z "$G3_GATE_STATUS" ]]; then
    G3_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G3: Epic Alignment Gate (change <-> Knife Plan slices)
# =============================================================================
check_epic_alignment_gate() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G3"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local a_script="${script_dir}/epic-alignment-check.sh"

  if [[ ! -x "$a_script" ]]; then
    warn "epic-alignment-check.sh not found; skipping Epic Alignment gate"
    return 0
  fi

  local report_rel="evidence/gates/epic-alignment-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$a_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G3" "Epic Alignment gate failed (G3): ${report_path}"
    return 0
  fi

  if [[ -z "$G3_GATE_STATUS" ]]; then
    G3_GATE_STATUS="pass"
  fi
}

# =============================================================================
# G4: Extension Pack Integrity (File System Contract + mapping executability)
# =============================================================================
check_extension_pack_integrity() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  # AI Native Framework extensions are opt-in via .devbooks/config.yaml.
  if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  if ! gate_is_required "G4"; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local pack_script="${script_dir}/extension-pack-integrity-check.sh"

  if [[ ! -x "$pack_script" ]]; then
    warn "extension-pack-integrity-check.sh not found; skipping Extension Pack integrity check"
    return 0
  fi

  local report_rel="evidence/gates/extension-pack-integrity-check.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  "$pack_script" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_rel" >/dev/null 2>&1 || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G4" "Extension Pack integrity check failed (G4): ${report_path}"
    return 0
  fi

  if [[ -z "$G4_GATE_STATUS" ]]; then
    G4_GATE_STATUS="pass"
  fi
}

# =============================================================================
# AC-005: Risk Evidence Constraint (medium/high)
# Enforce rollback plan + dependency audit evidence in archive/strict modes
# =============================================================================
check_risk_evidence() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local risk_check_script="${script_dir}/risk-evidence-check.sh"

  if [[ ! -f "$risk_check_script" ]]; then
    warn "risk-evidence-check.sh not found; skipping risk evidence check (AC-005)"
    return 0
  fi

  local report_rel="evidence/gates/risk-evidence-check-${mode}.json"
  local report_path="${change_dir}/${report_rel}"
  local rc=0
  bash "$risk_check_script" "$change_id" \
    --mode "$mode" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "$report_path" || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G5" "risk evidence check failed (AC-005): ${report_path}"
  else
    if [[ -z "${G5_GATE_STATUS}" ]]; then
      G5_GATE_STATUS="pass"
    fi
  fi

  # ---------------------------------------------------------------------------
  # P10 / Protocol v1.1 coverage report requirement (risk-driven enforcement)
  # Trigger: risk_level=high OR risk_flags.protocol_v1_1=true
  # Evidence: evidence/gates/protocol-v1.1-coverage.report.json
  # ---------------------------------------------------------------------------

  if [[ -f "$proposal_file" ]]; then
    local risk_level=""
    local protocol_v1_1=""
    risk_level="$(extract_front_matter_value "$proposal_file" "risk_level")"
    protocol_v1_1="$(extract_risk_flag_protocol_v1_1 "$proposal_file")"

    if [[ "$risk_level" == "high" || "$protocol_v1_1" == "true" ]]; then
      local mapping_file="${truth_dir}/protocol-core/protocol-v1.1-coverage-mapping.yaml"
      local coverage_report="${change_dir}/evidence/gates/protocol-v1.1-coverage.report.json"

      if [[ ! -f "$mapping_file" ]]; then
        gate_issue "G5" "missing protocol coverage mapping (P10): ${mapping_file}"
        return 0
      fi

      if [[ ! -f "$coverage_report" ]]; then
        gate_issue "G5" "missing protocol coverage report (P10): ${coverage_report}"
        return 0
      fi

      # Minimal contract checks (no external jsonschema dependency)
      if ! rg -n '"status"[[:space:]]*:[[:space:]]*"pass"' "$coverage_report" >/dev/null; then
        gate_issue "G5" "protocol coverage report status must be pass (P10): ${coverage_report}"
      fi

      if rg -n '"uncovered"[[:space:]]*:[[:space:]]*[1-9]' "$coverage_report" >/dev/null; then
        gate_issue "G5" "protocol coverage report uncovered>0 (P10): ${coverage_report}"
      fi

      local expected_sha=""
      expected_sha="$(awk -F': ' '$1=="design_source_sha256"{gsub(/"/,"",$2); print $2; exit}' "$mapping_file" 2>/dev/null || true)"
      if [[ -n "$expected_sha" ]]; then
        if ! rg -n "\"design_source_sha256\"[[:space:]]*:[[:space:]]*\"${expected_sha}\"" "$coverage_report" >/dev/null; then
          gate_issue "G5" "protocol coverage report design_source_sha256 mismatch (P10): ${coverage_report}"
        fi
      fi
    fi
  fi
}

# =============================================================================
# AC-004: Capability Registry Check (strict)
# Validate capability registry and truth directories are consistent.
# =============================================================================
check_capability_registry() {
  if [[ "$mode" != "strict" ]]; then
    return 0
  fi

  # Only run for DevBooks-like projects. Minimal test fixtures without dev-playbooks/
  # should not be forced to carry a registry.
  if [[ ! -d "${project_root}/dev-playbooks" && ! -f "${project_root}/.devbooks/config.yaml" ]]; then
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local cap_script="${script_dir}/capability-registry-check.sh"

  if [[ ! -x "$cap_script" ]]; then
    warn "capability-registry-check.sh not found; skipping capability registry check"
    return 0
  fi

  local report_path="${change_dir}/evidence/gates/capability-registry-check.report.json"
  local rc=0
  "$cap_script" "$change_id" \
    --project-root "$project_root" \
    --truth-root "$truth_root" \
    --out "$report_path" || rc=$?

  if [[ $rc -ne 0 ]]; then
    gate_issue "G6" "capability registry mismatch (AC-004): ${report_path}"
  fi
}

# =============================================================================
# G6 (archive): Archive Decider + Reference Integrity chain
# Must still emit minimal G6-archive-decider.json when dependencies are missing.
# =============================================================================
write_minimal_g6_archive_decider_report() {
  local report_path="$1"
  shift

  local reason_items=()
  local dep
  for dep in "$@"; do
    [[ -n "$dep" ]] || continue
    reason_items+=("missing dependency script: ${dep}")
  done

  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  local checks_json
  checks_json="$(json_array \
    "reference-integrity-check" \
    "check-completion-contract" \
    "check-anti-weakening" \
    "check-evidence-freshness" \
    "check-state-consistency" \
    "check-upstream-claims" \
    "archive-decider" \
  )"

  local reasons_json="[]"
  if [[ ${#reason_items[@]} -gt 0 ]]; then
    reasons_json="$(json_array "${reason_items[@]}")"
  fi

  local report_dir
  report_dir="$(dirname "$report_path")"
  mkdir -p "$report_dir"

  local tmp_path="${report_path}.tmp.$$"
  cat >"$tmp_path" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G6",
  "mode": "$(json_escape "$mode")",
  "status": "fail",
  "timestamp": "$(json_escape "$timestamp")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "project_root": "$(json_escape "$project_root")",
    "change_root": "$(json_escape "$change_root")",
    "truth_root": "$(json_escape "$truth_root")",
    "change_dir": "$(json_escape "$change_dir")",
    "report_path": "$(json_escape "$report_path")"
  },
  "checks": ${checks_json},
  "artifacts": [],
  "failure_reasons": ${reasons_json},
  "next_action": "DevBooks"
}
EOF

  mv -f "$tmp_path" "$report_path"
}

check_g6_archive_decider_chain() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  if is_archive_change_id; then
    echo "info: 已跳过历史包 G6 追溯 (${change_id})"
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local g6_report="${change_dir}/evidence/gates/G6-archive-decider.json"
  local ref_report="${change_dir}/evidence/gates/reference-integrity.report.json"

  local required_scripts=(
    "archive-decider.sh"
    "reference-integrity-check.sh"
    "check-completion-contract.sh"
    "check-anti-weakening.sh"
    "check-evidence-freshness.sh"
    "check-state-consistency.sh"
    "check-upstream-claims.sh"
  )

  local missing=()
  local name
  for name in "${required_scripts[@]}"; do
    if [[ ! -x "${script_dir}/${name}" ]]; then
      missing+=("$name")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    write_minimal_g6_archive_decider_report "$g6_report" "${missing[@]}"
    gate_issue "G6" "missing dependency scripts for G6 (${mode}): $(printf '%s ' "${missing[@]}")"
    return 0
  fi

  local ref_rc=0
  "${script_dir}/reference-integrity-check.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" || ref_rc=$?
  if [[ $ref_rc -ne 0 ]]; then
    gate_issue "G6" "reference integrity check failed (rc=${ref_rc}): ${ref_report}"
  fi

  if [[ ! -f "$ref_report" ]]; then
    gate_issue "G6" "missing reference integrity report (G6): ${ref_report}"
  else
    ref_status="$(json_status_from_file "$ref_report" || true)"
    if [[ "$ref_status" == "fail" ]]; then
      gate_issue "G6" "reference integrity report status=fail (G6): ${ref_report}"
    fi
  fi

  local contract_rc=0
  "${script_dir}/check-completion-contract.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" || contract_rc=$?
  if [[ $contract_rc -ne 0 ]]; then
    gate_issue "G6" "completion contract check failed (rc=${contract_rc}): ${change_dir}/evidence/gates/check-completion-contract.log"
  fi

  local anti_rc=0
  "${script_dir}/check-anti-weakening.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --out "evidence/gates/anti-weakening-check.json" || anti_rc=$?
  if [[ $anti_rc -ne 0 ]]; then
    gate_issue "G6" "anti-weakening check failed (rc=${anti_rc}): ${change_dir}/evidence/gates/anti-weakening-check.json"
  fi

  local state_rc=0
  "${script_dir}/check-state-consistency.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --state completed \
    --out "evidence/gates/state-consistency-check.json" || state_rc=$?
  if [[ $state_rc -ne 0 ]]; then
    gate_issue "G6" "state consistency check failed (rc=${state_rc}): ${change_dir}/evidence/gates/state-consistency-check.json"
  fi

  local upstream_rc=0
  "${script_dir}/check-upstream-claims.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --out "evidence/gates/upstream-claims-check.json" || upstream_rc=$?
  if [[ $upstream_rc -ne 0 ]]; then
    gate_issue "G6" "upstream claims check failed (rc=${upstream_rc}): ${change_dir}/evidence/gates/upstream-claims-check.json"
  fi

  local decider_rc=0
  "${script_dir}/archive-decider.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    --mode "$mode" || decider_rc=$?
  if [[ $decider_rc -ne 0 ]]; then
    gate_issue "G6" "archive-decider failed (rc=${decider_rc}): ${g6_report}"
  fi

  if [[ ! -f "$g6_report" ]]; then
    gate_issue "G6" "missing G6 archive decider report (G6): ${g6_report}"
    return 0
  fi

  local covers_args=()
  local contract_path=""
  if [[ -f "${change_dir}/completion.contract.yaml" ]]; then
    contract_path="${change_dir}/completion.contract.yaml"
  elif [[ -f "${change_dir}/completion.contract.yml" ]]; then
    contract_path="${change_dir}/completion.contract.yml"
  fi
  if [[ -n "$contract_path" ]]; then
    covers_args+=(--covers "$contract_path")
  fi
  if [[ -f "$proposal_file" ]]; then
    covers_args+=(--covers "$proposal_file")
  fi
  if [[ -f "$design_file" ]]; then
    covers_args+=(--covers "$design_file")
  fi
  if [[ -f "$tasks_file" ]]; then
    covers_args+=(--covers "$tasks_file")
  fi
  if [[ -f "$verification_file" ]]; then
    covers_args+=(--covers "$verification_file")
  fi
  if [[ -d "$specs_dir" ]]; then
    while IFS= read -r file; do
      [[ -n "$file" ]] || continue
      covers_args+=(--covers "$file")
    done < <(find "$specs_dir" -type f -name "spec.md" 2>/dev/null | sort)
  fi
  if [[ ${#covers_args[@]} -eq 0 ]]; then
    covers_args+=(--covers "$change_dir")
  fi

  local freshness_rc=0
  "${script_dir}/check-evidence-freshness.sh" "$change_id" \
    --project-root "$project_root" \
    --change-root "$change_root" \
    --truth-root "$truth_root" \
    "${covers_args[@]}" \
    --out "evidence/gates/evidence-freshness-check.json" || freshness_rc=$?
  if [[ $freshness_rc -ne 0 ]]; then
    gate_issue "G6" "evidence freshness check failed (rc=${freshness_rc}): ${change_dir}/evidence/gates/evidence-freshness-check.json"
  fi

  g6_status="$(json_status_from_file "$g6_report" || true)"
  case "$g6_status" in
    fail)
      gate_issue "G6" "G6 archive decider status=fail: ${g6_report}"
      ;;
    warn)
      warn "G6 archive decider status=warn: ${g6_report}"
      ;;
    pass|"")
      ;;
    *)
      warn "G6 archive decider has unknown status '${g6_status}': ${g6_report}"
      ;;
  esac
}

# =============================================================================
# AC-005: Gate Reports (strict)
# Emit evidence/gates/G{0..6}-<mode>.report.json for machine-readable auditing.
# =============================================================================
write_gate_report() {
  local gate_id="$1"
  local gate_mode="$2"
  local status="$3"
  local out_path="$4"
  local next_action="$5"
  shift 5

  local -a checks=()
  local -a artifacts=()
  local -a failure_reasons=()
  local -a input_pairs=()

  local phase="checks"
  local item
  for item in "$@"; do
    case "$item" in
      --checks) phase="checks" ;;
      --artifacts) phase="artifacts" ;;
      --reasons) phase="reasons" ;;
      --inputs) phase="inputs" ;;
      *)
        case "$phase" in
          checks) checks+=("$item") ;;
          artifacts) artifacts+=("$item") ;;
          reasons) failure_reasons+=("$item") ;;
          inputs) input_pairs+=("$item") ;;
        esac
        ;;
    esac
  done

  if [[ ${#checks[@]} -eq 0 ]]; then
    checks+=("change-check")
  fi

  mkdir -p "$(dirname "$out_path")"

  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # NOTE: bash 3.2 + set -u treats "${arr[@]}" as unbound when arr is empty.
  # Build JSON fragments conditionally to avoid expanding empty arrays.
  local checks_json
  checks_json="$(json_array "${checks[@]}")"

  local artifacts_json="[]"
  if [[ ${#artifacts[@]} -gt 0 ]]; then
    artifacts_json="$(json_array "${artifacts[@]}")"
  fi

  local failure_reasons_json="[]"
  if [[ ${#failure_reasons[@]} -gt 0 ]]; then
    failure_reasons_json="$(json_array "${failure_reasons[@]}")"
  fi

  local inputs_extra=""
  if [[ ${#input_pairs[@]} -gt 0 ]]; then
    local pair key value
    for pair in "${input_pairs[@]}"; do
      [[ -n "$pair" ]] || continue
      key="${pair%%=*}"
      value="${pair#*=}"
      [[ -n "$key" ]] || continue
      [[ -n "$value" ]] || continue
      inputs_extra="${inputs_extra},
    \"$(json_escape "$key")\": \"$(json_escape "$value")\""
    done
  fi

  local tmp="${out_path}.tmp.$$"
  cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "$(json_escape "$gate_id")",
  "mode": "$(json_escape "$gate_mode")",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$timestamp")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "change_dir": "$(json_escape "$change_dir")",
    "truth_dir": "$(json_escape "$truth_dir")",
    "role": "$(json_escape "$role")"${inputs_extra}
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${failure_reasons_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
  mv -f "$tmp" "$out_path"
}

emit_gate_reports() {
  if [[ "$mode" != "strict" ]]; then
    return 0
  fi

  local report_dir="${change_dir}/evidence/gates"
  mkdir -p "$report_dir"

  local overall="pass"
  if [[ $errors -gt 0 ]]; then
    overall="fail"
  elif [[ $warnings -gt 0 ]]; then
    overall="warn"
  fi

  local next_action="DevBooks"

  local g0_status="${G0_GATE_STATUS:-}"
  if [[ -z "$g0_status" ]]; then
    g0_status="pass"
  fi
  local -a g0_args
  g0_args=(--checks "proposal" "design" "spec-deltas" "tasks" "verification" "metadata" "state-audit" "void-protocol" "constitution")
  if [[ ${#G0_FAILURE_REASONS[@]} -gt 0 ]]; then
    g0_args+=(--reasons "${G0_FAILURE_REASONS[@]}")
  fi
  write_gate_report "G0" "$mode" "$g0_status" "${report_dir}/G0-${mode}.report.json" "$next_action" \
    "${g0_args[@]}"

  local g1_status="${G1_GATE_STATUS:-}"
  if [[ -z "$g1_status" ]]; then
    g1_status="pass"
  fi
  local -a g1_args
  g1_args=(--checks "role-boundaries" "required-gates")
  if [[ ${#G1_FAILURE_REASONS[@]} -gt 0 ]]; then
    g1_args+=(--reasons "${G1_FAILURE_REASONS[@]}")
  fi
  write_gate_report "G1" "$mode" "$g1_status" "${report_dir}/G1-${mode}.report.json" "$next_action" \
    "${g1_args[@]}"

  local g2_status="${G2_GATE_STATUS:-}"
  if [[ -z "$g2_status" ]]; then
    g2_status="pass"
  fi
  local -a g2_args
  g2_args=(--checks "evidence-closure" "task-completion" "test-failures")
  if [[ ${#G2_FAILURE_REASONS[@]} -gt 0 ]]; then
    g2_args+=(--reasons "${G2_FAILURE_REASONS[@]}")
  fi
  write_gate_report "G2" "$mode" "$g2_status" "${report_dir}/G2-${mode}.report.json" "$next_action" \
    "${g2_args[@]}"
  local g3_status="${G3_GATE_STATUS:-}"
  if [[ -z "$g3_status" ]]; then
    g3_status="pass"
  fi
  local -a g3_reasons=()
  if [[ ${#G3_FAILURE_REASONS[@]} -gt 0 ]]; then
    g3_reasons+=("${G3_FAILURE_REASONS[@]}")
    if [[ "$g3_status" == "pass" ]]; then
      g3_status="fail"
    fi
  fi
  local -a g3_args
  g3_args=(--checks "handoff" "env-match" "verification-anchors" "knife-plan" "knife-correctness" "epic-alignment")
  if [[ ${#G3_INPUT_PAIRS[@]} -gt 0 ]]; then
    g3_args+=(--inputs "${G3_INPUT_PAIRS[@]}")
  fi
  if [[ ${#G3_ARTIFACTS[@]} -gt 0 ]]; then
    g3_args+=(--artifacts "${G3_ARTIFACTS[@]}")
  fi
  if [[ ${#g3_reasons[@]} -gt 0 ]]; then
    g3_args+=(--reasons "${g3_reasons[@]}")
  fi
  write_gate_report "G3" "$mode" "$g3_status" "${report_dir}/G3-${mode}.report.json" "$next_action" \
    "${g3_args[@]}"
  local g4_status="${G4_GATE_STATUS:-}"
  if [[ -z "$g4_status" ]]; then
    g4_status="pass"
  fi
  local -a g4_args
  g4_args=(--checks "extension-pack" "docs-impact" "fitness")
  if [[ ${#G4_FAILURE_REASONS[@]} -gt 0 ]]; then
    g4_args+=(--reasons "${G4_FAILURE_REASONS[@]}")
  fi
  write_gate_report "G4" "$mode" "$g4_status" "${report_dir}/G4-${mode}.report.json" "$next_action" \
    "${g4_args[@]}"

  local g5_status="${G5_GATE_STATUS:-}"
  if [[ -z "$g5_status" ]]; then
    g5_status="pass"
  fi
  local g5_reasons=()
  if [[ ${#G5_FAILURE_REASONS[@]} -gt 0 ]]; then
    g5_reasons=("${G5_FAILURE_REASONS[@]}")
    if [[ "$g5_status" == "pass" ]]; then
      g5_status="fail"
    fi
  fi
  local -a g5_args
  g5_args=(--checks "risk-evidence")
  if [[ ${#g5_reasons[@]} -gt 0 ]]; then
    g5_args+=(--reasons "${g5_reasons[@]}")
  fi
  write_gate_report "G5" "$mode" "$g5_status" "${report_dir}/G5-${mode}.report.json" "$next_action" \
    "${g5_args[@]}"

  local g6_status="${G6_GATE_STATUS:-$overall}"
  local -a g6_reasons=()
  if [[ ${#G6_FAILURE_REASONS[@]} -gt 0 ]]; then
    g6_reasons+=("${G6_FAILURE_REASONS[@]}")
    g6_status="fail"
  elif [[ "$overall" == "fail" ]]; then
    g6_reasons+=("strict checks have errors; see stderr output for details")
    g6_status="fail"
  fi
  local -a g6_args
  g6_args=(--checks "capability-registry" "strict")
  if [[ ${#g6_reasons[@]} -gt 0 ]]; then
    g6_args+=(--reasons "${g6_reasons[@]}")
  fi
  write_gate_report "G6" "$mode" "$g6_status" "${report_dir}/G6-${mode}.report.json" "$next_action" \
    "${g6_args[@]}"
}

# =============================================================================
# AC-003: Role Boundary Check (Enhanced from check_no_tests_changed)
# Enforce role-specific file modification boundaries
# Refactored: split into per-role helper functions for maintainability
# =============================================================================

# Helper: Report role violation with changed files list (DRY extraction)
_report_role_violation() {
  local role_name="$1" forbidden_target="$2" changed_list="$3"
  err "Role violation: ${role_name} cannot modify ${forbidden_target} (AC-003)"
  echo "  Detected changes:" >&2
  printf "%s\n" "$changed_list" | head -5 | sed 's/^/    /' >&2
  if [[ $(printf "%s\n" "$changed_list" | wc -l) -gt 5 ]]; then
    echo "    ... and more" >&2
  fi
}

# Helper: Check Coder role boundaries
_check_coder_boundaries() {
  local changed="$1"

  # Coder cannot modify tests/**
  local tests_changed
  tests_changed=$(printf "%s\n" "$changed" | grep -E "^tests/" || true)
  if [[ -n "$tests_changed" ]]; then
    _report_role_violation "Coder" "tests/**" "$tests_changed"
  fi

  # Coder cannot modify verification.md
  if printf "%s\n" "$changed" | grep -qE "verification\.md$"; then
    err "Role violation: Coder cannot modify verification.md (AC-003)"
  fi

  # Coder cannot modify .devbooks/ config
  if printf "%s\n" "$changed" | grep -qE "^\.devbooks/"; then
    err "Role violation: Coder cannot modify .devbooks/ config (AC-003)"
  fi
}

# Helper: Check Test Owner role boundaries
_check_test_owner_boundaries() {
  local changed="$1"

  # Test Owner cannot modify src/**
  local src_changed
  src_changed=$(printf "%s\n" "$changed" | grep -E "^src/" || true)
  if [[ -n "$src_changed" ]]; then
    _report_role_violation "Test Owner" "src/**" "$src_changed"
  fi
}

# Helper: Check Reviewer role boundaries
_check_reviewer_boundaries() {
  local changed="$1"

  # Reviewer cannot modify any code files
  local code_changed
  code_changed=$(printf "%s\n" "$changed" | grep -E "\.(ts|js|tsx|jsx|py|sh)$" || true)
  if [[ -n "$code_changed" ]]; then
    _report_role_violation "Reviewer" "code files" "$code_changed"
  fi
}

check_role_boundaries() {
  # Only run when role is specified or in apply mode
  if [[ -z "$role" && "$mode" != "apply" ]]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git not found; cannot enforce role boundaries"
    return 0
  fi

  if ! git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "not a git worktree; cannot enforce role boundaries"
    return 0
  fi

  # Get changed files
  local changed
  changed="$(
    {
      git -C "$project_root" diff --name-only
      git -C "$project_root" diff --cached --name-only
    } | sort -u
  )"

  if [[ -z "$changed" ]]; then
    return 0
  fi

  # Dispatch to role-specific helper
  case "$role" in
    coder)      _check_coder_boundaries "$changed" ;;
    test-owner) _check_test_owner_boundaries "$changed" ;;
    reviewer)   _check_reviewer_boundaries "$changed" ;;
  esac
}

# Backward compatibility alias
check_no_tests_changed() {
  check_role_boundaries
}

# ============================================================================
# Implicit Change Detection (Mythical Man-Month Ch.7 "Tower of Babel")
# ============================================================================
check_implicit_changes() {
  # Only run in apply/archive/strict modes
  if [[ "$mode" != "apply" && "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local implicit_report="${change_dir}/evidence/implicit-changes.json"

  # Check if implicit-change-detect.sh is available (now in devbooks-spec-contract)
  local detect_script
  detect_script="$(dirname "$0")/../devbooks-spec-contract/scripts/implicit-change-detect.sh"
  if [[ ! -x "$detect_script" ]]; then
    # Try alternate location
    detect_script="$(dirname "$0")/../../devbooks-spec-contract/scripts/implicit-change-detect.sh"
  fi

  # If report doesn't exist and we can run detection, suggest it
  if [[ ! -f "$implicit_report" ]]; then
    if [[ -x "$detect_script" ]]; then
      warn "missing implicit change detection report: ${implicit_report}"
      warn "hint: run '${detect_script} ${change_id} --project-root ${project_root} --change-root ${change_root}'"
    fi
    return 0
  fi

  # Parse the report
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq not found; cannot parse implicit-changes.json"
    return 0
  fi

  local total_implicit
  total_implicit=$(jq -r '.summary.total // 0' "$implicit_report" 2>/dev/null || echo "0")

  if [[ "$total_implicit" -eq 0 ]]; then
    return 0
  fi

  echo "  implicit changes detected: ${total_implicit}"

  # In strict mode, check if high-risk changes are declared in design.md
  if [[ "$mode" == "strict" ]]; then
    local dep_count cfg_count bld_count
    dep_count=$(jq -r '.summary.dependency // 0' "$implicit_report" 2>/dev/null || echo "0")
    cfg_count=$(jq -r '.summary.config // 0' "$implicit_report" 2>/dev/null || echo "0")
    bld_count=$(jq -r '.summary.build // 0' "$implicit_report" 2>/dev/null || echo "0")

    if [[ "$dep_count" -gt 0 || "$cfg_count" -gt 0 || "$bld_count" -gt 0 ]]; then
      # Check if design.md exists and mentions these changes
      if [[ ! -f "$design_file" ]]; then
        err "implicit changes detected but design.md missing (strict): review ${implicit_report}"
      else
        # For strict mode, we just warn - full declaration check would need more sophisticated parsing
        warn "implicit changes detected (${total_implicit}): verify these are declared in design.md"
        warn "  dependencies: ${dep_count}, config: ${cfg_count}, build: ${bld_count}"
        warn "  report: ${implicit_report}"
      fi
    fi
  else
    # For non-strict modes, just warn
    warn "implicit changes detected (${total_implicit}): review ${implicit_report}"
  fi
}

echo "devbooks: checking change '${change_id}' (mode=${mode}${role:+, role=${role}})"
echo "  change-dir: ${change_dir}"
echo "  truth-dir:  ${truth_dir}"

if [[ ! -d "$change_dir" ]]; then
  err "missing change directory: ${change_dir}"
else
  init_gate_policy
  echo "  gate_profile: ${GATE_PROFILE} (risk_level=${RISK_LEVEL}, request_kind=${REQUEST_KIND})"
  if [[ ${#REQUIRED_GATES[@]} -gt 0 ]]; then
    echo "  required_gates: $(IFS=,; echo "${REQUIRED_GATES[*]}")"
  fi

  check_proposal
  check_design
  check_tasks
  check_spec_deltas
  check_verification
  check_change_metadata_contract
  check_state_audit_contract
  check_void_protocol_contract
  check_required_gates_contract
  check_no_tests_changed
  check_implicit_changes
  # Dev-Playbooks: Constitution check
  check_constitution               # Constitution validity check (strict mode)
  # Dev-Playbooks: Fitness check
  check_fitness                    # Architecture fitness check (apply/archive/strict)
  # New quality gates (harden-devbooks-quality-gates)
  check_evidence_closure       # AC-001: Green evidence required for archive
  check_task_completion_rate   # AC-002: 100% completion for strict mode
  check_test_failure_in_evidence  # AC-007: No failures in Green evidence
  check_skip_approval          # AC-005: P0 skip requires approval
  check_env_match              # AC-006: Environment declaration required
  check_verification_anchors_contract  # Deterministic anchors contract (archive/strict + high-risk/epic)
  check_knife_plan             # REQ-KNIFE-004: Knife Plan gate (high-risk/epic)
  check_knife_correctness_gate # REQ-KNIFE-005: Knife correctness hard invariants
  check_epic_alignment_gate    # REQ-KNIFE-006: Epic alignment with Knife Plan
  check_extension_pack_integrity  # Extension pack filesystem + mapping executability
  check_docs_impact            # AC-008: Documentation impact declared and fulfilled
  check_risk_evidence          # AC-005: Risk evidence + P10 (archive|strict)
  check_capability_registry    # AC-004: Capability registry consistency (strict)
  check_g6_archive_decider_chain  # G6: archive|strict chain (must emit G6-archive-decider.json)
  emit_gate_reports            # AC-005: G0-G6 strict reports
fi

if [[ $errors -gt 0 ]]; then
  echo "fail: ${errors} error(s), ${warnings} warning(s)" >&2
  exit 1
fi

echo "ok: ${warnings} warning(s)"
