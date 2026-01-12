#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# entropy-report.sh
# ============================================================================
# Generates a human-readable markdown report from entropy metrics.
#
# Reference: "The Mythical Man-Month" Chapter 16 "No Silver Bullet" - Controlling complexity is key to software development
# ============================================================================

usage() {
  cat <<'EOF' >&2
usage: entropy-report.sh [--input <file>] [--output <file>] [--project-root <dir>] [--truth-root <dir>]

Generates a markdown report from entropy metrics JSON.

Options:
  --input          Input metrics JSON file (default: latest in <truth-root>/_meta/entropy/)
  --output         Output markdown file (default: <truth-root>/_meta/entropy/entropy-report-YYYY-MM-DD.md)
  --project-root   Project root directory (default: pwd)
  --truth-root     Truth root directory (default: specs)

Examples:
  entropy-report.sh
  entropy-report.sh --input metrics-2024-01-15.json --output report.md
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
input_file=""
output_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --input)
      input_file="${2:-}"
      shift 2
      ;;
    --output)
      output_file="${2:-}"
      shift 2
      ;;
    --project-root)
      project_root="${2:-}"
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

# Normalize paths
project_root="${project_root%/}"
truth_root="${truth_root%/}"

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

entropy_dir="${truth_dir}/_meta/entropy"

# Find latest metrics file if not specified
if [[ -z "$input_file" ]]; then
  input_file=$(find "$entropy_dir" -name "metrics-*.json" -type f 2>/dev/null | sort -r | head -1)
  if [[ -z "$input_file" ]]; then
    echo "error: no metrics file found in ${entropy_dir}" >&2
    echo "hint: run entropy-measure.sh first" >&2
    exit 1
  fi
fi

if [[ ! -f "$input_file" ]]; then
  echo "error: input file not found: ${input_file}" >&2
  exit 1
fi

# Set default output file
if [[ -z "$output_file" ]]; then
  output_file="${entropy_dir}/entropy-report-$(date +%Y-%m-%d).md"
fi

# Ensure output directory exists
mkdir -p "$(dirname "$output_file")"

echo "generating report from: ${input_file}"

# ============================================================================
# Extract metrics
# ============================================================================

timestamp=$(jq -r '.timestamp' "$input_file")
project=$(jq -r '.project_root' "$input_file")
days=$(jq -r '.analysis_period_days' "$input_file")

# Structural metrics
file_p95=$(jq -r '.metrics.structural.file_lines_p95 // "N/A"' "$input_file")
file_mean=$(jq -r '.metrics.structural.file_lines_mean // "N/A"' "$input_file")
complexity_mean=$(jq -r '.metrics.structural.complexity_mean // "N/A"' "$input_file")
complexity_p95=$(jq -r '.metrics.structural.complexity_p95 // "N/A"' "$input_file")

# Change metrics
hotspot_count=$(jq -r '.metrics.change.hotspot_count // "N/A"' "$input_file")
total_files=$(jq -r '.metrics.change.total_files // "N/A"' "$input_file")
hotspot_ratio=$(jq -r '.metrics.change.hotspot_ratio // "N/A"' "$input_file")

# Test metrics
test_lines=$(jq -r '.metrics.test.test_lines // "N/A"' "$input_file")
code_lines=$(jq -r '.metrics.test.code_lines // "N/A"' "$input_file")
test_code_ratio=$(jq -r '.metrics.test.test_code_ratio // "N/A"' "$input_file")
flaky_ratio=$(jq -r '.metrics.test.flaky_ratio // "N/A"' "$input_file")
coverage=$(jq -r '.metrics.test.coverage // "N/A"' "$input_file")

# Dependency metrics
outdated=$(jq -r '.metrics.dependency.outdated // "N/A"' "$input_file")
total_deps=$(jq -r '.metrics.dependency.total // "N/A"' "$input_file")
outdated_ratio=$(jq -r '.metrics.dependency.outdated_ratio // "N/A"' "$input_file")
vulnerabilities=$(jq -r '.metrics.dependency.vulnerabilities // "N/A"' "$input_file")

# Thresholds
t_file_p95=$(jq -r '.thresholds.structural.file_lines_p95 // 500' "$input_file")
t_hotspot=$(jq -r '.thresholds.change.hotspot_ratio // 0.1' "$input_file")
t_test_ratio=$(jq -r '.thresholds.test.test_code_ratio_min // 0.5' "$input_file")
t_outdated=$(jq -r '.thresholds.dependency.outdated_ratio // 0.2' "$input_file")

# Alerts
alert_count=$(jq -r '.summary.total_alerts' "$input_file")
healthy_count=$(jq -r '.summary.dimensions_healthy' "$input_file")

# Health status helper
health_status() {
  local value="$1"
  local threshold="$2"
  local compare="${3:-lt}"  # lt = less than is healthy, gt = greater than is healthy

  if [[ "$value" == "N/A" || "$value" == "null" ]]; then
    echo "⚪"
    return
  fi

  local result
  if [[ "$compare" == "lt" ]]; then
    result=$(echo "$value <= $threshold" | bc -l 2>/dev/null || echo 0)
  else
    result=$(echo "$value >= $threshold" | bc -l 2>/dev/null || echo 0)
  fi

  if [[ "$result" -eq 1 ]]; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

# ============================================================================
# Generate report
# ============================================================================

cat > "$output_file" << EOF
# System Entropy Report

> Generated: ${timestamp}
> Project path: ${project}
> Analysis period: ${days} days

---

## Overview

| Dimension | Health Status | Key Metric |
|-----------|---------------|------------|
| Structural Entropy | $(health_status "$file_p95" "$t_file_p95" "lt") | File lines P95: ${file_p95} |
| Change Entropy | $(health_status "$hotspot_ratio" "$t_hotspot" "lt") | Hotspot file ratio: ${hotspot_ratio} |
| Test Entropy | $(health_status "$test_code_ratio" "$t_test_ratio" "gt") | Test/code ratio: ${test_code_ratio} |
| Dependency Entropy | $(health_status "$outdated_ratio" "$t_outdated" "lt") | Outdated dependency ratio: ${outdated_ratio} |

**Healthy dimensions**: ${healthy_count}/4 | **Alerts**: ${alert_count}

---

## A) Structural Entropy

> Source: Static code analysis

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| File lines P95 | ${file_p95} | < ${t_file_p95} | $(health_status "$file_p95" "$t_file_p95" "lt") |
| File lines mean | ${file_mean} | - | ⚪ |
| Cyclomatic complexity mean | ${complexity_mean} | < 10 | ⚪ |
| Cyclomatic complexity P95 | ${complexity_p95} | < 20 | ⚪ |

**Recommendation**: Focus on files above P95, consider splitting.

---

## B) Change Entropy

> Source: Git history analysis (past ${days} days)

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| Hotspot file count | ${hotspot_count} / ${total_files} | - | ⚪ |
| Hotspot file ratio | ${hotspot_ratio} | < ${t_hotspot} | $(health_status "$hotspot_ratio" "$t_hotspot" "lt") |

**Hotspot definition**: Files modified more than 5 times during the analysis period

**Recommendation**: Frequently modified files may need refactoring or splitting.

---

## C) Test Entropy

> Source: Test file statistics

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| Test code lines | ${test_lines} | - | ⚪ |
| Production code lines | ${code_lines} | - | ⚪ |
| Test/code ratio | ${test_code_ratio} | > ${t_test_ratio} | $(health_status "$test_code_ratio" "$t_test_ratio" "gt") |
| Flaky test ratio | ${flaky_ratio} | < 0.01 | ⚪ |
| Code coverage | ${coverage} | > 0.7 | ⚪ |

**Recommendation**: When test/code ratio is below 0.5, prioritize adding tests.

---

## D) Dependency Entropy

> Source: Dependency analysis

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| Outdated dependency count | ${outdated} / ${total_deps} | - | ⚪ |
| Outdated dependency ratio | ${outdated_ratio} | < ${t_outdated} | $(health_status "$outdated_ratio" "$t_outdated" "lt") |
| Security vulnerability count | ${vulnerabilities} | = 0 | $(health_status "$vulnerabilities" "0" "lt") |

**Recommendation**: Regularly update dependencies, prioritize fixing security vulnerabilities.

---

## Alert Details

EOF

# Add alerts
if [[ "$alert_count" -gt 0 ]]; then
  jq -r '.alerts[] | "- **[\(.level | ascii_upcase)]** \(.dimension): \(.message)"' "$input_file" >> "$output_file"
else
  echo "No alerts" >> "$output_file"
fi

cat >> "$output_file" << EOF

---

## Trend Analysis

> Trend charts can be generated after multiple data collections

View historical data: \`${entropy_dir}/history.json\`

---

## Recommended Actions

EOF

# Generate recommendations based on alerts
if [[ "$alert_count" -gt 0 ]]; then
  echo "1. Address high-priority issues from the alerts above" >> "$output_file"
  echo "2. Run \`change-check.sh\` to ensure change package completeness" >> "$output_file"
  echo "3. Consider using \`devbooks-proposal-author\` to initiate refactoring proposal" >> "$output_file"
else
  echo "No urgent action needed currently, recommend regular monitoring of entropy metrics." >> "$output_file"
fi

cat >> "$output_file" << EOF

---

*Report automatically generated by entropy-report.sh*
*Reference: "The Mythical Man-Month" Chapter 16 "No Silver Bullet"*
EOF

echo "ok: report generated: ${output_file}"
