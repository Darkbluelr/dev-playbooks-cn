#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# entropy-report.sh
# ============================================================================
# Generates a human-readable markdown report from entropy metrics.
#
# Reference: 《人月神话》第16章"没有银弹" — 控制复杂性是软件开发的关键
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
# 系统熵度量报告 / System Entropy Report

> 生成时间: ${timestamp}
> 项目路径: ${project}
> 分析周期: ${days} 天

---

## 概览 / Overview

| 维度 | 健康状态 | 主要指标 |
|------|---------|---------|
| 结构熵 | $(health_status "$file_p95" "$t_file_p95" "lt") | 文件行数 P95: ${file_p95} |
| 变更熵 | $(health_status "$hotspot_ratio" "$t_hotspot" "lt") | 热点文件占比: ${hotspot_ratio} |
| 测试熵 | $(health_status "$test_code_ratio" "$t_test_ratio" "gt") | 测试/代码比: ${test_code_ratio} |
| 依赖熵 | $(health_status "$outdated_ratio" "$t_outdated" "lt") | 过期依赖占比: ${outdated_ratio} |

**健康维度**: ${healthy_count}/4 | **告警数**: ${alert_count}

---

## A) 结构熵 / Structural Entropy

> 来源: 静态代码分析

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 文件行数 P95 | ${file_p95} | < ${t_file_p95} | $(health_status "$file_p95" "$t_file_p95" "lt") |
| 文件行数均值 | ${file_mean} | - | ⚪ |
| 圈复杂度均值 | ${complexity_mean} | < 10 | ⚪ |
| 圈复杂度 P95 | ${complexity_p95} | < 20 | ⚪ |

**建议**: 关注 P95 以上的大文件，考虑拆分。

---

## B) 变更熵 / Change Entropy

> 来源: Git 历史分析 (过去 ${days} 天)

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 热点文件数 | ${hotspot_count} / ${total_files} | - | ⚪ |
| 热点文件占比 | ${hotspot_ratio} | < ${t_hotspot} | $(health_status "$hotspot_ratio" "$t_hotspot" "lt") |

**热点定义**: 在分析周期内被修改超过 5 次的文件

**建议**: 高频修改的文件可能需要重构或拆分。

---

## C) 测试熵 / Test Entropy

> 来源: 测试文件统计

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 测试代码行数 | ${test_lines} | - | ⚪ |
| 生产代码行数 | ${code_lines} | - | ⚪ |
| 测试/代码比 | ${test_code_ratio} | > ${t_test_ratio} | $(health_status "$test_code_ratio" "$t_test_ratio" "gt") |
| Flaky 测试占比 | ${flaky_ratio} | < 0.01 | ⚪ |
| 代码覆盖率 | ${coverage} | > 0.7 | ⚪ |

**建议**: 测试/代码比低于 0.5 时，应优先补充测试。

---

## D) 依赖熵 / Dependency Entropy

> 来源: 依赖分析

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 过期依赖数 | ${outdated} / ${total_deps} | - | ⚪ |
| 过期依赖占比 | ${outdated_ratio} | < ${t_outdated} | $(health_status "$outdated_ratio" "$t_outdated" "lt") |
| 安全漏洞数 | ${vulnerabilities} | = 0 | $(health_status "$vulnerabilities" "0" "lt") |

**建议**: 定期更新依赖，优先修复安全漏洞。

---

## 告警详情 / Alerts

EOF

# Add alerts
if [[ "$alert_count" -gt 0 ]]; then
  jq -r '.alerts[] | "- **[\(.level | ascii_upcase)]** \(.dimension): \(.message)"' "$input_file" >> "$output_file"
else
  echo "无告警 ✅" >> "$output_file"
fi

cat >> "$output_file" << EOF

---

## 趋势分析 / Trend Analysis

> 需要多次采集数据后才能生成趋势图

查看历史数据: \`${entropy_dir}/history.json\`

---

## 行动建议 / Recommended Actions

EOF

# Generate recommendations based on alerts
if [[ "$alert_count" -gt 0 ]]; then
  echo "1. 处理上述告警中的高优先级问题" >> "$output_file"
  echo "2. 运行 \`change-check.sh\` 确保变更包完整性" >> "$output_file"
  echo "3. 考虑使用 \`devbooks-proposal-author\` 发起重构提案" >> "$output_file"
else
  echo "当前无需紧急行动，建议定期监控熵指标变化。" >> "$output_file"
fi

cat >> "$output_file" << EOF

---

*报告由 entropy-report.sh 自动生成*
*参考: 《人月神话》第16章"没有银弹"*
EOF

echo "ok: report generated: ${output_file}"
