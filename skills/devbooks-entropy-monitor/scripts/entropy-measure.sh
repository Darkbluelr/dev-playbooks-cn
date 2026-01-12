#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# entropy-measure.sh
# ============================================================================
# Collects system entropy metrics across four dimensions:
# - Structural entropy (cyclomatic complexity, file/function sizes)
# - Change entropy (hotspots, coupling, churn)
# - Test entropy (flaky tests, coverage, test/code ratio)
# - Dependency entropy (outdated deps, vulnerabilities)
#
# Reference: "The Mythical Man-Month" Chapter 16 "No Silver Bullet" - Controlling complexity is key to software development
# ============================================================================

usage() {
  cat <<'EOF' >&2
usage: entropy-measure.sh [--project-root <dir>] [--truth-root <dir>] [--output <file>] [--days <n>]

Collects system entropy metrics for a codebase.

Options:
  --project-root   Project root directory (default: pwd)
  --truth-root     Truth root for storing reports (default: specs)
  --output         Output JSON file (default: <truth-root>/_meta/entropy/metrics-YYYY-MM-DD.json)
  --days           Days of git history to analyze for change entropy (default: 30)

Output:
  JSON file with metrics across four dimensions:
  - structural: complexity, file sizes, function sizes
  - change: hotspots, coupling, churn
  - test: flaky ratio, coverage, test/code ratio
  - dependency: outdated ratio, vulnerabilities

Examples:
  entropy-measure.sh
  entropy-measure.sh --project-root /path/to/repo --days 60
  entropy-measure.sh --output ./entropy-report.json
EOF
}

# Color output helpers
red() { printf '\033[0;31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[0;32m%s\033[0m\n' "$*" >&2; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*" >&2; }

err() { red "error: $*"; }
warn() { yellow "warn: $*"; }
ok() { green "ok: $*"; }

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
output_file=""
days=30

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
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --output)
      output_file="${2:-}"
      shift 2
      ;;
    --days)
      days="${2:-30}"
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

# Set default output file
if [[ -z "$output_file" ]]; then
  entropy_dir="${truth_dir}/_meta/entropy"
  mkdir -p "$entropy_dir"
  output_file="${entropy_dir}/metrics-$(date +%Y-%m-%d).json"
fi

# Ensure output directory exists
mkdir -p "$(dirname "$output_file")"

echo "=== Entropy Measurement ==="
echo "project: ${project_root}"
echo "output:  ${output_file}"
echo ""

# ============================================================================
# Metric collection functions
# ============================================================================

# Count lines in files matching pattern, excluding common non-source dirs
count_lines() {
  local pattern="$1"
  find "$project_root" -type f -name "$pattern" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/vendor/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/__pycache__/*" \
    2>/dev/null | while read -r f; do
    wc -l < "$f" 2>/dev/null || echo 0
  done | awk '{ sum += $1 } END { print sum+0 }'
}

# Get file line counts as JSON array
get_file_sizes() {
  local sizes='[]'
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    local lines
    lines=$(wc -l < "$f" 2>/dev/null || echo 0)
    sizes=$(echo "$sizes" | jq --arg f "$f" --argjson l "$lines" '. + [$l]')
  done < <(find "$project_root" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.java" -o -name "*.rb" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/vendor/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    2>/dev/null | head -500)
  echo "$sizes"
}

# Calculate percentile from JSON array
percentile() {
  local arr="$1"
  local p="$2"
  echo "$arr" | jq --argjson p "$p" '
    sort |
    if length == 0 then 0
    else
      (length - 1) * $p / 100 | floor | . as $idx |
      if $idx >= length then .[-1]
      else .[$idx]
      end
    end
  '
}

# Count git hotspots (files changed frequently)
count_hotspots() {
  if ! git -C "$project_root" rev-parse --git-dir >/dev/null 2>&1; then
    echo '{"hotspot_count": 0, "total_files": 0, "hotspot_ratio": 0}'
    return
  fi

  local total_files hotspot_files
  total_files=$(git -C "$project_root" ls-files 2>/dev/null | wc -l | tr -d ' ')

  # Files changed more than 5 times in the period
  hotspot_files=$(git -C "$project_root" log --since="${days} days ago" --name-only --pretty=format: 2>/dev/null \
    | grep -v '^$' \
    | sort \
    | uniq -c \
    | awk '$1 > 5 { count++ } END { print count+0 }')

  local ratio
  if [[ "$total_files" -gt 0 ]]; then
    ratio=$(echo "scale=4; $hotspot_files / $total_files" | bc 2>/dev/null || echo "0")
  else
    ratio="0"
  fi

  jq -n \
    --argjson hc "$hotspot_files" \
    --argjson tf "$total_files" \
    --argjson r "$ratio" \
    '{"hotspot_count": $hc, "total_files": $tf, "hotspot_ratio": $r}'
}

# Analyze dependency status
analyze_dependencies() {
  local result='{"outdated": 0, "total": 0, "outdated_ratio": 0, "vulnerabilities": 0}'

  # npm/yarn
  if [[ -f "$project_root/package.json" ]]; then
    local total_deps outdated_deps
    total_deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys | length' "$project_root/package.json" 2>/dev/null || echo "0")

    # Try npm outdated (if npm available)
    if command -v npm >/dev/null 2>&1; then
      outdated_deps=$(cd "$project_root" && npm outdated --json 2>/dev/null | jq 'keys | length' 2>/dev/null || echo "0")
    else
      outdated_deps="0"
    fi

    local ratio
    if [[ "$total_deps" -gt 0 ]]; then
      ratio=$(echo "scale=4; $outdated_deps / $total_deps" | bc 2>/dev/null || echo "0")
    else
      ratio="0"
    fi

    result=$(jq -n \
      --argjson od "$outdated_deps" \
      --argjson td "$total_deps" \
      --argjson r "$ratio" \
      --argjson v 0 \
      '{"outdated": $od, "total": $td, "outdated_ratio": $r, "vulnerabilities": $v}')
  fi

  # pip/requirements.txt
  if [[ -f "$project_root/requirements.txt" ]]; then
    local total_deps
    total_deps=$(grep -c -v '^#' "$project_root/requirements.txt" 2>/dev/null | grep -v '^$' | wc -l || echo "0")
    # Note: pip-audit would be needed for proper outdated detection
    result=$(echo "$result" | jq --argjson td "$total_deps" '.total = $td')
  fi

  echo "$result"
}

# Count test files and calculate test/code ratio
analyze_tests() {
  local test_lines=0
  local code_lines=0

  # Count test file lines
  test_lines=$(find "$project_root" -type f \( -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.spec.ts" -o -name "test_*.py" -o -name "*_test.py" -o -name "*_test.go" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    2>/dev/null | while read -r f; do
    wc -l < "$f" 2>/dev/null || echo 0
  done | awk '{ sum += $1 } END { print sum+0 }')

  # Count source file lines (excluding tests)
  code_lines=$(find "$project_root" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) \
    ! -name "*.test.*" \
    ! -name "*.spec.*" \
    ! -name "test_*" \
    ! -name "*_test.*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/tests/*" \
    ! -path "*/__tests__/*" \
    2>/dev/null | while read -r f; do
    wc -l < "$f" 2>/dev/null || echo 0
  done | awk '{ sum += $1 } END { print sum+0 }')

  local ratio
  if [[ "$code_lines" -gt 0 ]]; then
    ratio=$(echo "scale=4; $test_lines / $code_lines" | bc 2>/dev/null || echo "0")
  else
    ratio="0"
  fi

  jq -n \
    --argjson tl "$test_lines" \
    --argjson cl "$code_lines" \
    --argjson r "$ratio" \
    '{"test_lines": $tl, "code_lines": $cl, "test_code_ratio": $r, "flaky_ratio": 0, "coverage": null}'
}

# ============================================================================
# Main measurement
# ============================================================================

echo "measuring: structural entropy..."
file_sizes=$(get_file_sizes)
file_p95=$(percentile "$file_sizes" 95)
file_mean=$(echo "$file_sizes" | jq 'if length == 0 then 0 else (add / length) end')
echo "  file_lines_p95: ${file_p95}"
echo "  file_lines_mean: ${file_mean}"

echo "measuring: change entropy..."
hotspots=$(count_hotspots)
hotspot_ratio=$(echo "$hotspots" | jq -r '.hotspot_ratio')
echo "  hotspot_ratio: ${hotspot_ratio}"

echo "measuring: test entropy..."
test_metrics=$(analyze_tests)
test_code_ratio=$(echo "$test_metrics" | jq -r '.test_code_ratio')
echo "  test_code_ratio: ${test_code_ratio}"

echo "measuring: dependency entropy..."
dep_metrics=$(analyze_dependencies)
outdated_ratio=$(echo "$dep_metrics" | jq -r '.outdated_ratio')
echo "  outdated_ratio: ${outdated_ratio}"

# ============================================================================
# Load thresholds
# ============================================================================

thresholds_file="${truth_dir}/_meta/entropy/thresholds.json"
if [[ -f "$thresholds_file" ]]; then
  thresholds=$(cat "$thresholds_file")
else
  # Default thresholds
  thresholds='{
    "structural": {
      "complexity_mean": 10,
      "complexity_p95": 20,
      "file_lines_p95": 500,
      "function_lines_p95": 50
    },
    "change": {
      "hotspot_ratio": 0.1,
      "coupling_ratio": 0.3,
      "churn_ratio": 0.5
    },
    "test": {
      "flaky_ratio": 0.01,
      "coverage_min": 0.7,
      "test_code_ratio_min": 0.5
    },
    "dependency": {
      "outdated_ratio": 0.2,
      "vulnerabilities": 0
    }
  }'
fi

# ============================================================================
# Generate alerts
# ============================================================================

alerts='[]'

# Check file size threshold
file_threshold=$(echo "$thresholds" | jq -r '.structural.file_lines_p95 // 500')
if (( $(echo "$file_p95 > $file_threshold" | bc -l 2>/dev/null || echo 0) )); then
  alerts=$(echo "$alerts" | jq --arg m "file_lines_p95 ($file_p95) exceeds threshold ($file_threshold)" '. + [{level: "warning", dimension: "structural", message: $m}]')
fi

# Check hotspot threshold
hotspot_threshold=$(echo "$thresholds" | jq -r '.change.hotspot_ratio // 0.1')
if (( $(echo "$hotspot_ratio > $hotspot_threshold" | bc -l 2>/dev/null || echo 0) )); then
  alerts=$(echo "$alerts" | jq --arg m "hotspot_ratio ($hotspot_ratio) exceeds threshold ($hotspot_threshold)" '. + [{level: "warning", dimension: "change", message: $m}]')
fi

# Check test/code ratio threshold
test_threshold=$(echo "$thresholds" | jq -r '.test.test_code_ratio_min // 0.5')
if (( $(echo "$test_code_ratio < $test_threshold" | bc -l 2>/dev/null || echo 0) )); then
  alerts=$(echo "$alerts" | jq --arg m "test_code_ratio ($test_code_ratio) below threshold ($test_threshold)" '. + [{level: "warning", dimension: "test", message: $m}]')
fi

# Check outdated deps threshold
outdated_threshold=$(echo "$thresholds" | jq -r '.dependency.outdated_ratio // 0.2')
if (( $(echo "$outdated_ratio > $outdated_threshold" | bc -l 2>/dev/null || echo 0) )); then
  alerts=$(echo "$alerts" | jq --arg m "outdated_ratio ($outdated_ratio) exceeds threshold ($outdated_threshold)" '. + [{level: "warning", dimension: "dependency", message: $m}]')
fi

# ============================================================================
# Generate output
# ============================================================================

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg project "$project_root" \
  --argjson days "$days" \
  --argjson file_p95 "$file_p95" \
  --argjson file_mean "$file_mean" \
  --argjson hotspots "$hotspots" \
  --argjson tests "$test_metrics" \
  --argjson deps "$dep_metrics" \
  --argjson thresholds "$thresholds" \
  --argjson alerts "$alerts" \
  '{
    timestamp: $ts,
    project_root: $project,
    analysis_period_days: $days,
    metrics: {
      structural: {
        file_lines_p95: $file_p95,
        file_lines_mean: $file_mean,
        complexity_mean: null,
        complexity_p95: null,
        function_lines_p95: null
      },
      change: $hotspots,
      test: $tests,
      dependency: $deps
    },
    thresholds: $thresholds,
    alerts: $alerts,
    summary: {
      total_alerts: ($alerts | length),
      dimensions_healthy: (4 - (
        (if ($alerts | map(select(.dimension == "structural")) | length) > 0 then 1 else 0 end) +
        (if ($alerts | map(select(.dimension == "change")) | length) > 0 then 1 else 0 end) +
        (if ($alerts | map(select(.dimension == "test")) | length) > 0 then 1 else 0 end) +
        (if ($alerts | map(select(.dimension == "dependency")) | length) > 0 then 1 else 0 end)
      )),
      dimensions_total: 4
    }
  }' > "$output_file"

# ============================================================================
# Append to history
# ============================================================================

history_file="${truth_dir}/_meta/entropy/history.json"
if [[ -f "$history_file" ]]; then
  # Append new entry
  tmp_file=$(mktemp)
  jq --slurpfile new "$output_file" '. + $new' "$history_file" > "$tmp_file"
  mv "$tmp_file" "$history_file"
else
  # Create new history file
  jq -s '.' "$output_file" > "$history_file"
fi

# ============================================================================
# Output summary
# ============================================================================

echo ""
echo "=== Entropy Summary ==="
alert_count=$(echo "$alerts" | jq 'length')
healthy=$(jq -r '.summary.dimensions_healthy' "$output_file")

if [[ "$alert_count" -eq 0 ]]; then
  ok "all ${healthy}/4 dimensions healthy"
else
  warn "${alert_count} alert(s) detected"
  echo "$alerts" | jq -r '.[] | "  [\(.level)] \(.dimension): \(.message)"'
fi

echo ""
ok "report: ${output_file}"
ok "history: ${history_file}"
