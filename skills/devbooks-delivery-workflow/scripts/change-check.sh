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
- This script is protocol-agnostic. For OpenSpec, pass --change-root openspec/changes --truth-root openspec/specs.
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

err() {
  echo "error: $*" >&2
  errors=$((errors + 1))
}

warn() {
  echo "warn: $*" >&2
  warnings=$((warnings + 1))
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    err "missing file: ${file}"
    return 1
  fi
  return 0
}

contains_placeholder() {
  local file="$1"
  if rg -n "<change-id>|<truth-root>|<change-root>|<一句话目标>|<capability>|<you>|YYYY-MM-DD|<session/agent>|<填“无”|TODO\\b" "$file" >/dev/null; then
    return 0
  fi
  return 1
}

check_proposal() {
  require_file "$proposal_file" || return 0

  for h in "## Why" "## What Changes" "## Impact" "## Risks & Rollback" "## Validation" "## Debate Packet" "## Decision Log"; do
    if ! rg -n "^${h}$" "$proposal_file" >/dev/null; then
      err "proposal missing heading '${h}': ${proposal_file}"
    fi
  done

  if ! rg -n "^- 价值信号与观测口径：" "$proposal_file" >/dev/null; then
    if [[ "$mode" == "strict" ]]; then
      err "proposal missing '- 价值信号与观测口径：' (strict): ${proposal_file}"
    else
      warn "proposal missing '- 价值信号与观测口径：' (recommended): ${proposal_file}"
    fi
  fi

  if ! rg -n "^- 价值流瓶颈假设" "$proposal_file" >/dev/null; then
    if [[ "$mode" == "strict" ]]; then
      err "proposal missing '- 价值流瓶颈假设...' (strict): ${proposal_file}"
    else
      warn "proposal missing '- 价值流瓶颈假设...' (recommended): ${proposal_file}"
    fi
  fi

  local decision_line
  decision_line=$(rg -n "^- 决策状态：" "$proposal_file" -m 1 || true)
  if [[ -z "$decision_line" ]]; then
    err "proposal missing '- 决策状态：' line: ${proposal_file}"
    return 0
  fi

  local value
  value="$(echo "$decision_line" | sed -E 's/^[0-9]+:- 决策状态： *//')"

  case "$value" in
    Pending|Approved|Revise|Rejected) ;;
    *)
      err "proposal has invalid decision status '${value}': ${proposal_file}"
      ;;
  esac

  if [[ "$mode" == "apply" || "$mode" == "archive" || "$mode" == "strict" ]]; then
    if [[ "$value" != "Approved" ]]; then
      err "proposal decision status must be Approved for ${mode}: ${proposal_file}"
    fi
  fi

  if [[ "$mode" == "strict" ]]; then
    if contains_placeholder "$proposal_file"; then
      err "proposal contains placeholders/TODO (strict): ${proposal_file}"
    fi
  fi
}

check_design() {
  if [[ ! -f "$design_file" ]]; then
    if [[ "$mode" == "proposal" ]]; then
      warn "missing design.md (recommended for non-trivial changes): ${design_file}"
      return 0
    fi
    err "missing design.md: ${design_file}"
    return 0
  fi

  if ! rg -n "^## Acceptance Criteria$" "$design_file" >/dev/null; then
    err "design missing '## Acceptance Criteria' heading: ${design_file}"
  fi

  if ! rg -n "AC-[0-9]{3}" "$design_file" >/dev/null; then
    err "design missing any AC-xxx items: ${design_file}"
  fi

  # ============================================================================
  # 设计模式借鉴：Problem Context / Rationale / Trade-offs 必填检查
  # ============================================================================
  if [[ "$mode" == "apply" || "$mode" == "archive" || "$mode" == "strict" ]]; then
    if ! rg -n "^## Problem Context$|^## 问题背景$" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        err "design missing '## Problem Context' section (strict): ${design_file}"
      else
        warn "design missing '## Problem Context' section (recommended): ${design_file}"
      fi
    fi

    if ! rg -n "^## Design Rationale$|^## 设计决策理由$" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        err "design missing '## Design Rationale' section (strict): ${design_file}"
      else
        warn "design missing '## Design Rationale' section (recommended): ${design_file}"
      fi
    fi

    if ! rg -n "^## Trade-offs$|^## 权衡取舍$" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        err "design missing '## Trade-offs' section (strict): ${design_file}"
      else
        warn "design missing '## Trade-offs' section (recommended): ${design_file}"
      fi
    fi
  fi

  # ============================================================================
  # 设计模式借鉴：封装变化点检查（在设计原则章节）
  # ============================================================================
  if [[ "$mode" == "strict" ]]; then
    if ! rg -n "变化点|Variation Point|封装变化|Encapsulate.*Vari" "$design_file" >/dev/null; then
      warn "design may not have identified variation points (strict): ${design_file}"
    fi
  fi

  if [[ "$mode" == "strict" ]]; then
    if contains_placeholder "$design_file"; then
      err "design contains placeholders/TODO (strict): ${design_file}"
    fi
  fi
}

check_tasks() {
  require_file "$tasks_file" || return 0

  if ! rg -n "主线计划区|Main Plan Area" "$tasks_file" >/dev/null; then
    err "tasks missing '主线计划区/Main Plan Area': ${tasks_file}"
  fi

  if ! rg -n "断点区|Context Switch Breakpoint Area" "$tasks_file" >/dev/null; then
    err "tasks missing '断点区/Context Switch Breakpoint Area': ${tasks_file}"
  fi

  if ! rg -n "^- \\[[ xX]\\]" "$tasks_file" >/dev/null; then
    err "tasks missing checkbox items '- [ ]'/'- [x]': ${tasks_file}"
  fi

  if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
    if rg -n "^- \\[ \\]" "$tasks_file" >/dev/null; then
      err "tasks still contains unchecked items (archive/strict): ${tasks_file}"
    fi
  fi

  if [[ "$mode" == "strict" ]]; then
    if contains_placeholder "$tasks_file"; then
      err "tasks contains placeholders/TODO (strict): ${tasks_file}"
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
    err "missing verification.md: ${verification_file}"
    return 0
  fi

  for h in "A\\) 测试计划指令表" "B\\) 追溯矩阵" "C\\) 执行锚点" "D\\) MANUAL-\\* 清单"; do
    if ! rg -n "${h}" "$verification_file" >/dev/null; then
      err "verification missing section '${h}': ${verification_file}"
    fi
  done

  if ! rg -n "^\\| AC-[0-9]{3} \\|" "$verification_file" >/dev/null; then
    err "verification trace matrix missing any AC rows: ${verification_file}"
  fi

  if [[ "$mode" == "strict" ]]; then
    if ! rg -n "^G\\) 价值流与度量" "$verification_file" >/dev/null; then
      err "verification missing 'G) 价值流与度量' section (strict): ${verification_file}"
    fi

    if ! rg -n "^- 目标价值信号：" "$verification_file" >/dev/null; then
      err "verification missing '- 目标价值信号：' line (strict): ${verification_file}"
    fi

    if rg -n "^\\| AC-[0-9]{3} \\|.*\\| *TODO *\\|" "$verification_file" >/dev/null; then
      err "verification trace matrix still has TODO rows (strict): ${verification_file}"
    fi

    if contains_placeholder "$verification_file"; then
      err "verification contains placeholders/TODO (strict): ${verification_file}"
    fi

    if [[ -f "$design_file" ]]; then
      design_acs="$(extract_ac_ids "$design_file")"
      verification_acs="$(extract_ac_ids "$verification_file")"
      while IFS= read -r ac; do
        [[ -n "$ac" ]] || continue
        if ! printf "%s\n" "$verification_acs" | rg -x "$ac" >/dev/null; then
          err "verification missing AC '${ac}' from design: ${verification_file}"
        fi
      done <<<"$design_acs"
    fi

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -x "${script_dir}/guardrail-check.sh" ]]; then
      if ! "${script_dir}/guardrail-check.sh" "$change_id" --project-root "$project_root" --change-root "$change_root" >/dev/null; then
        err "guardrail-check failed (strict): ${verification_file}"
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
      err "spec delta missing '## ADDED|MODIFIED|REMOVED Requirements' headings: ${file}"
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
        err "spec delta has no '### Requirement:' entries: ${file}"
      elif [[ "$result" == "BAD_REQUIREMENTS" ]]; then
        err "spec delta has Requirement(s) without Scenario (count=${rest}): ${file}"
      fi
    }

    if [[ "$mode" == "strict" ]]; then
      if rg -n "<change-id>|<truth-root>|<change-root>|<capability>|TBD\\b|TODO\\b" "$file" >/dev/null; then
        err "spec delta contains placeholders/TBD/TODO (strict): ${file}"
      fi
    fi
  done < <(find "$specs_dir" -type f -name "spec.md" 2>/dev/null | sort)

  if [[ "$found_any" == false ]]; then
    return 0
  fi
}

check_no_tests_changed() {
  if [[ "$role" != "coder" && "$mode" != "strict" ]]; then
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git not found; cannot enforce 'coder must not modify tests/**'"
    return 0
  fi

  if ! git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "not a git worktree; cannot enforce 'coder must not modify tests/**'"
    return 0
  fi

  changed="$(
    {
      git -C "$project_root" diff --name-only
      git -C "$project_root" diff --cached --name-only
    } | sort -u
  )"

  if [[ -z "$changed" ]]; then
    return 0
  fi

  if printf "%s\n" "$changed" | rg -n "^tests/" >/dev/null; then
    err "detected changes under tests/** (coder forbidden):"
    printf "%s\n" "$changed" | rg "^tests/" >&2 || true
  fi
}

# ============================================================================
# Implicit Change Detection (《人月神话》第7章 "巴比伦塔")
# ============================================================================
check_implicit_changes() {
  # Only run in apply/archive/strict modes
  if [[ "$mode" != "apply" && "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local implicit_report="${change_dir}/evidence/implicit-changes.json"

  # Check if implicit-change-detect.sh is available
  local detect_script
  detect_script="$(dirname "$0")/../devbooks-contract-data/scripts/implicit-change-detect.sh"
  if [[ ! -x "$detect_script" ]]; then
    # Try alternate location
    detect_script="$(dirname "$0")/../../devbooks-contract-data/scripts/implicit-change-detect.sh"
  fi

  # If report doesn't exist and we can run detection, suggest it
  if [[ ! -f "$implicit_report" ]]; then
    if [[ -x "$detect_script" ]]; then
      warn "missing implicit change detection report: ${implicit_report}"
      warn "hint: run 'implicit-change-detect.sh ${change_id} --project-root ${project_root} --change-root ${change_root}'"
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
  check_proposal
  check_design
  check_tasks
  check_spec_deltas
  check_verification
  check_no_tests_changed
  check_implicit_changes
fi

if [[ $errors -gt 0 ]]; then
  echo "fail: ${errors} error(s), ${warnings} warning(s)" >&2
  exit 1
fi

echo "ok: ${warnings} warning(s)"
