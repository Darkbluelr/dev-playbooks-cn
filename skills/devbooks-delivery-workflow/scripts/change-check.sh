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
  # Pattern includes intentional Chinese quotes for detecting placeholders
  # shellcheck disable=SC2140
  if rg -n '<change-id>|<truth-root>|<change-root>|<一句话目标>|<capability>|<you>|YYYY-MM-DD|<session/agent>|<填"无"|TODO\b' "$file" >/dev/null; then
    return 0
  fi
  return 1
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

  # Check same line
  if [[ "$line" =~ SKIP-APPROVED: ]]; then
    return 0
  fi

  # Check previous line
  if [[ -n "$prev_line" ]]; then
    if [[ "$strict_html" == true ]]; then
      if [[ "$prev_line" =~ \<\!--[[:space:]]*SKIP-APPROVED: ]]; then
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
      if [[ "$next_line" =~ \<\!--[[:space:]]*SKIP-APPROVED: ]]; then
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

  [[ $i -gt 0 ]] && _PREV_LINE="${_LINES[$((i-1))]}"
  [[ $((i+1)) -lt $_LINE_COUNT ]] && _NEXT_LINE="${_LINES[$((i+1))]}"
}

check_proposal() {
  require_file "$proposal_file" || return 0

  # Support both numbered (## 1. Why...) and unnumbered (## Why...) headings
  for h in "Why" "What Changes" "Impact" "Risks" "Validation" "Debate Packet" "Decision Log"; do
    if ! rg -n "^## [0-9]*\\.? *${h}" "$proposal_file" >/dev/null; then
      err "proposal missing heading containing '${h}': ${proposal_file}"
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

  # Support headings with Chinese annotations: ## Acceptance Criteria（验收标准）
  if ! rg -n "^## Acceptance Criteria|^## 验收标准" "$design_file" >/dev/null; then
    err "design missing '## Acceptance Criteria' heading: ${design_file}"
  fi

  if ! rg -n "AC-[0-9]{3}" "$design_file" >/dev/null; then
    err "design missing any AC-xxx items: ${design_file}"
  fi

  # ============================================================================
  # 设计模式借鉴：Problem Context / Rationale / Trade-offs 必填检查
  # ============================================================================
  if [[ "$mode" == "apply" || "$mode" == "archive" || "$mode" == "strict" ]]; then
    if ! rg -n "^## Problem Context|^## 问题背景" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        err "design missing '## Problem Context' section (strict): ${design_file}"
      else
        warn "design missing '## Problem Context' section (recommended): ${design_file}"
      fi
    fi

    if ! rg -n "^## Design Rationale|^## 设计决策理由" "$design_file" >/dev/null; then
      if [[ "$mode" == "strict" ]]; then
        err "design missing '## Design Rationale' section (strict): ${design_file}"
      else
        warn "design missing '## Design Rationale' section (recommended): ${design_file}"
      fi
    fi

    if ! rg -n "^## Trade-offs|^## 权衡取舍" "$design_file" >/dev/null; then
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
      err "tasks still contains unchecked items without skip approval (archive/strict): ${tasks_file}"
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
    # G) section is recommended but not blocking
    if ! rg -n "^## G\\) 价值流与度量|^G\\) 价值流与度量" "$verification_file" >/dev/null; then
      warn "verification missing 'G) 价值流与度量' section (recommended for strict): ${verification_file}"
    else
      # Only check 目标价值信号 if G) section exists
      if ! rg -n "^- 目标价值信号：" "$verification_file" >/dev/null; then
        warn "verification missing '- 目标价值信号：' line (recommended): ${verification_file}"
      fi
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

# =============================================================================
# Constitution Check (DevBooks 2.0)
# Verify project constitution is present and valid
# =============================================================================
check_constitution() {
  # Only run in strict mode
  if [[ "$mode" != "strict" ]]; then
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
    err "constitution check failed (strict): 项目宪法缺失或无效"
    return 0
  fi
}

# =============================================================================
# Fitness Check (DevBooks 2.0)
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
      err "fitness check failed (strict): 架构适应度检查失败"
    else
      warn "fitness check warnings detected"
    fi
  fi
}

# =============================================================================
# AC-001: Green Evidence Closure Check (《人月神话》第6章 "沟通")
# Block archive when Green evidence is missing
# =============================================================================
check_evidence_closure() {
  # Only run in archive/strict modes
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local evidence_dir="${change_dir}/evidence/green-final"

  if [[ ! -d "$evidence_dir" ]]; then
    err "缺少 Green 证据: evidence/green-final/ 不存在 (AC-001)"
    return 0
  fi

  # Check if directory has at least one file
  local file_count
  file_count=$(find "$evidence_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$file_count" -eq 0 ]]; then
    err "缺少 Green 证据: evidence/green-final/ 为空 (AC-001)"
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
    err "任务完成率 ${rate}% (${completed_tasks}/${total_tasks})，需要 100% (AC-002)"
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
        err "测试失败: Green 证据中包含失败模式，不能归档 (AC-007)"
        echo "  文件: $file" >&2
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
        err "P0 任务跳过需审批: ${p0_task_name} (AC-005)"
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
    err "测试环境声明缺失: verification.md 需要包含 '测试环境声明' 部分 (AC-006)"
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
  if ! rg -n "^## Documentation Impact|^## 文档影响" "$design_file" >/dev/null; then
    if [[ "$mode" == "strict" ]]; then
      err "design.md 缺少 '## Documentation Impact/文档影响' 章节 (AC-008)"
    else
      warn "design.md 缺少 '## Documentation Impact/文档影响' 章节（建议添加）"
    fi
    return 0
  fi

  # Check for "无需更新" declaration - if checked, skip further checks
  if rg -n "^\- \[x\] 本次变更为内部重构|^\- \[x\] 本次变更仅修复" "$design_file" >/dev/null; then
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
    unchecked_items=$(rg -n "^\- \[ \] 新增脚本|^\- \[ \] 新增配置|^\- \[ \] 新增工作流|^\- \[ \] API" "$design_file" || true)

    if [[ -n "$unchecked_items" && "$mode" == "strict" ]]; then
      err "文档更新检查清单有未完成项 (AC-008)"
      echo "  未完成项:" >&2
      printf "%s\n" "$unchecked_items" | head -3 | sed 's/^/    /' >&2
    fi
  fi

  # In strict mode, verify declared docs are actually modified
  if [[ "$mode" == "strict" ]] && command -v git >/dev/null 2>&1; then
    if git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      # Extract declared P0 docs from design.md
      local declared_docs
      declared_docs=$(rg -o "\| (README\.md|docs/[^|]+\.md|使用说明[^|]*\.md|CHANGELOG\.md) \|" "$design_file" 2>/dev/null | sed 's/| //g; s/ |//g' | sort -u || true)

      if [[ -n "$declared_docs" ]]; then
        # Get changed files
        local changed_files
        changed_files=$(git -C "$project_root" diff --name-only HEAD 2>/dev/null || git -C "$project_root" diff --name-only 2>/dev/null || true)

        while IFS= read -r doc; do
          [[ -n "$doc" ]] || continue
          # Check if the declared doc is in the changed files
          if ! printf "%s\n" "$changed_files" | grep -qF "$doc"; then
            warn "声明需更新但未修改: $doc (建议检查)"
          fi
        done <<< "$declared_docs"
      fi
    fi
  fi
}

# =============================================================================
# AC-003: Role Boundary Check (Enhanced from check_no_tests_changed)
# Enforce role-specific file modification boundaries
# Refactored: split into per-role helper functions for maintainability
# =============================================================================

# Helper: Report role violation with changed files list (DRY extraction)
_report_role_violation() {
  local role_name="$1" forbidden_target="$2" changed_list="$3"
  err "角色违规: ${role_name} 禁止修改 ${forbidden_target} (AC-003)"
  echo "  检测到变更:" >&2
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
    err "角色违规: Coder 禁止修改 verification.md (AC-003)"
  fi

  # Coder cannot modify .devbooks/ config
  if printf "%s\n" "$changed" | grep -qE "^\.devbooks/"; then
    err "角色违规: Coder 禁止修改 .devbooks/ 配置 (AC-003)"
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
    _report_role_violation "Reviewer" "代码文件" "$code_changed"
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
# Implicit Change Detection (《人月神话》第7章 "巴比伦塔")
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
  # DevBooks 2.0: Constitution check
  check_constitution               # Constitution validity check (strict mode)
  # DevBooks 2.0: Fitness check
  check_fitness                    # Architecture fitness check (apply/archive/strict)
  # New quality gates (harden-devbooks-quality-gates)
  check_evidence_closure       # AC-001: Green evidence required for archive
  check_task_completion_rate   # AC-002: 100% completion for strict mode
  check_test_failure_in_evidence  # AC-007: No failures in Green evidence
  check_skip_approval          # AC-005: P0 skip requires approval
  check_env_match              # AC-006: Environment declaration required
  check_docs_impact            # AC-008: Documentation impact declared and fulfilled
fi

if [[ $errors -gt 0 ]]; then
  echo "fail: ${errors} error(s), ${warnings} warning(s)" >&2
  exit 1
fi

echo "ok: ${warnings} warning(s)"
