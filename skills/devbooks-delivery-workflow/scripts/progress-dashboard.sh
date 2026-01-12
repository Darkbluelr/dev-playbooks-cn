#!/usr/bin/env bash
# progress-dashboard.sh - Provide progress visualization for change packages
#
# This script displays a dashboard showing:
# - Task completion rate
# - Role status (handoff state)
# - Evidence status (Red/Green)
#
# Reference: harden-devbooks-quality-gates design.md AC-010

set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: progress-dashboard.sh <change-id> [options]

Display progress dashboard for a change package:
- Task completion rate and breakdown
- Role status (current role, handoff state)
- Evidence status (Red baseline, Green final)

Options:
  --project-root <dir>  Project root directory (default: pwd)
  --change-root <dir>   Change packages root (default: changes)
  --format <fmt>        Output format: text (default), markdown, json
  -h, --help            Show this help message

Exit Codes:
  0 - Dashboard generated successfully
  1 - Change package not found or error
  2 - Usage error

Examples:
  progress-dashboard.sh my-change-001
  progress-dashboard.sh my-change-001 --format markdown
  progress-dashboard.sh my-change-001 --change-root dev-playbooks/changes
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
output_format="text"

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
    --format)
      output_format="${2:-text}"
      shift 2
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

# Validate format
case "$output_format" in
  text|markdown|json) ;;
  *)
    echo "error: invalid --format: '$output_format' (use: text, markdown, json)" >&2
    exit 2
    ;;
esac

# Build paths
project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

# Check change directory exists
if [[ ! -d "$change_dir" ]]; then
  echo "error: change directory not found: ${change_dir}" >&2
  exit 1
fi

# Define file paths
tasks_file="${change_dir}/tasks.md"
handoff_file="${change_dir}/handoff.md"
proposal_file="${change_dir}/proposal.md"
design_file="${change_dir}/design.md"
verification_file="${change_dir}/verification.md"
red_evidence="${change_dir}/evidence/red-baseline"
green_evidence="${change_dir}/evidence/green-final"

# =============================================================================
# Collect Data
# =============================================================================

# Task completion
total_tasks=0
completed_tasks=0
p0_total=0
p0_completed=0
p1_total=0
p1_completed=0
p2_total=0
p2_completed=0

if [[ -f "$tasks_file" ]]; then
  # Count all tasks
  total_tasks=$(grep -cE "^- \[[xX ]\]" "$tasks_file" 2>/dev/null) || total_tasks=0
  completed_tasks=$(grep -cE "^- \[[xX]\]" "$tasks_file" 2>/dev/null) || completed_tasks=0

  # Count by priority
  p0_total=$(grep -cE "^- \[[xX ]\] \[P0\]" "$tasks_file" 2>/dev/null) || p0_total=0
  p0_completed=$(grep -cE "^- \[[xX]\] \[P0\]" "$tasks_file" 2>/dev/null) || p0_completed=0
  p1_total=$(grep -cE "^- \[[xX ]\] \[P1\]" "$tasks_file" 2>/dev/null) || p1_total=0
  p1_completed=$(grep -cE "^- \[[xX]\] \[P1\]" "$tasks_file" 2>/dev/null) || p1_completed=0
  p2_total=$(grep -cE "^- \[[xX ]\] \[P2\]" "$tasks_file" 2>/dev/null) || p2_total=0
  p2_completed=$(grep -cE "^- \[[xX]\] \[P2\]" "$tasks_file" 2>/dev/null) || p2_completed=0
fi

# Calculate completion rate
if [[ $total_tasks -gt 0 ]]; then
  completion_rate=$((completed_tasks * 100 / total_tasks))
else
  completion_rate=100
fi

# Role status
handoff_state="none"
if [[ -f "$handoff_file" ]]; then
  confirmed=$(grep -cE "^- \[[xX]\]" "$handoff_file" 2>/dev/null || echo "0")
  total_sigs=$(grep -cE "^- \[[xX ]\]" "$handoff_file" 2>/dev/null || echo "0")
  if [[ $confirmed -eq $total_sigs && $total_sigs -gt 0 ]]; then
    handoff_state="complete"
  elif [[ $confirmed -gt 0 ]]; then
    handoff_state="partial"
  else
    handoff_state="pending"
  fi
fi

# Determine current phase
current_phase="unknown"
if [[ ! -f "$proposal_file" ]]; then
  current_phase="proposal"
elif [[ ! -f "$design_file" ]]; then
  current_phase="design"
elif [[ ! -f "$verification_file" ]]; then
  current_phase="test-owner"
elif [[ $completion_rate -lt 100 ]]; then
  current_phase="coder"
else
  current_phase="review"
fi

# Evidence status
red_exists="no"
green_exists="no"
red_count=0
green_count=0

if [[ -d "$red_evidence" ]]; then
  red_count=$(find "$red_evidence" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ $red_count -gt 0 ]]; then
    red_exists="yes"
  fi
fi

if [[ -d "$green_evidence" ]]; then
  green_count=$(find "$green_evidence" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ $green_count -gt 0 ]]; then
    green_exists="yes"
  fi
fi

# Document status
proposal_exists=$([[ -f "$proposal_file" ]] && echo "yes" || echo "no")
design_exists=$([[ -f "$design_file" ]] && echo "yes" || echo "no")
tasks_exists=$([[ -f "$tasks_file" ]] && echo "yes" || echo "no")
verification_exists=$([[ -f "$verification_file" ]] && echo "yes" || echo "no")

# =============================================================================
# Output
# =============================================================================

case "$output_format" in
  text)
    echo "=================================================="
    echo "Progress Dashboard: ${change_id}"
    echo "=================================================="
    echo ""
    echo "## Task Completion"
    echo "  Total: ${completed_tasks}/${total_tasks} (${completion_rate}%)"
    echo "  [P0]: ${p0_completed}/${p0_total}"
    echo "  [P1]: ${p1_completed}/${p1_total}"
    echo "  [P2]: ${p2_completed}/${p2_total}"
    echo ""
    echo "## Role Status"
    echo "  Current Phase: ${current_phase}"
    echo "  Handoff State: ${handoff_state}"
    echo ""
    echo "## Evidence Status"
    echo "  Red Baseline: ${red_exists} (${red_count} files)"
    echo "  Green Final:  ${green_exists} (${green_count} files)"
    echo ""
    echo "## Document Status"
    echo "  proposal.md:     ${proposal_exists}"
    echo "  design.md:       ${design_exists}"
    echo "  tasks.md:        ${tasks_exists}"
    echo "  verification.md: ${verification_exists}"
    echo ""
    ;;

  markdown)
    echo "# Progress Dashboard: ${change_id}"
    echo ""
    echo "## Task Completion"
    echo ""
    echo "| Priority | Completed | Total | Rate |"
    echo "|----------|-----------|-------|------|"
    echo "| All | ${completed_tasks} | ${total_tasks} | ${completion_rate}% |"
    echo "| P0 | ${p0_completed} | ${p0_total} | - |"
    echo "| P1 | ${p1_completed} | ${p1_total} | - |"
    echo "| P2 | ${p2_completed} | ${p2_total} | - |"
    echo ""
    echo "## Role Status"
    echo ""
    echo "- **Current Phase**: ${current_phase}"
    echo "- **Handoff State**: ${handoff_state}"
    echo ""
    echo "## Evidence Status"
    echo ""
    echo "| Type | Exists | Files |"
    echo "|------|--------|-------|"
    echo "| Red Baseline | ${red_exists} | ${red_count} |"
    echo "| Green Final | ${green_exists} | ${green_count} |"
    echo ""
    echo "## Document Status"
    echo ""
    echo "| Document | Exists |"
    echo "|----------|--------|"
    echo "| proposal.md | ${proposal_exists} |"
    echo "| design.md | ${design_exists} |"
    echo "| tasks.md | ${tasks_exists} |"
    echo "| verification.md | ${verification_exists} |"
    ;;

  json)
    # Convert yes/no to JSON boolean true/false
    red_exists_bool=$([[ "$red_exists" == "yes" ]] && echo "true" || echo "false")
    green_exists_bool=$([[ "$green_exists" == "yes" ]] && echo "true" || echo "false")
    proposal_exists_bool=$([[ "$proposal_exists" == "yes" ]] && echo "true" || echo "false")
    design_exists_bool=$([[ "$design_exists" == "yes" ]] && echo "true" || echo "false")
    tasks_exists_bool=$([[ "$tasks_exists" == "yes" ]] && echo "true" || echo "false")
    verification_exists_bool=$([[ "$verification_exists" == "yes" ]] && echo "true" || echo "false")

    cat << EOF
{
  "changeId": "${change_id}",
  "tasks": {
    "total": ${total_tasks},
    "completed": ${completed_tasks},
    "completionRate": ${completion_rate},
    "byPriority": {
      "p0": {"total": ${p0_total}, "completed": ${p0_completed}},
      "p1": {"total": ${p1_total}, "completed": ${p1_completed}},
      "p2": {"total": ${p2_total}, "completed": ${p2_completed}}
    }
  },
  "role": {
    "currentPhase": "${current_phase}",
    "handoffState": "${handoff_state}"
  },
  "evidence": {
    "redBaseline": {"exists": ${red_exists_bool}, "fileCount": ${red_count}},
    "greenFinal": {"exists": ${green_exists_bool}, "fileCount": ${green_count}}
  },
  "documents": {
    "proposal": ${proposal_exists_bool},
    "design": ${design_exists_bool},
    "tasks": ${tasks_exists_bool},
    "verification": ${verification_exists_bool}
  }
}
EOF
    ;;
esac

exit 0
