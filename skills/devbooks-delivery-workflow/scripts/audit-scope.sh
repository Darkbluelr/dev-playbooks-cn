#!/usr/bin/env bash
# audit-scope.sh - Provide full-scope audit scanning for precision improvement
#
# This script scans a directory and outputs metrics for audit purposes:
# - File count by type
# - Line count
# - Complexity metrics (if available)
# - Hotspot file list (high churn + high complexity)
#
# Reference: harden-devbooks-quality-gates design.md AC-011

set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: audit-scope.sh <directory> [options]

Provide full-scope audit scanning for a directory:
- File count by type
- Total line count
- Complexity metrics (if tools available)
- Hotspot identification

Options:
  --format <fmt>    Output format: text (default), markdown, json
  --exclude <pat>   Exclude pattern (can be used multiple times)
  -h, --help        Show this help message

Exit Codes:
  0 - Scan completed successfully
  1 - Scan error or directory not found
  2 - Usage error

Examples:
  audit-scope.sh src/
  audit-scope.sh src/ --format markdown
  audit-scope.sh src/ --format json --exclude node_modules
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

target_dir="$1"
shift

output_format="text"
declare -a exclude_patterns=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --format)
      output_format="${2:-text}"
      shift 2
      ;;
    --exclude)
      exclude_patterns+=("${2:-}")
      shift 2
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Validate format
case "$output_format" in
  text|markdown|json) ;;
  *)
    echo "error: invalid --format: '$output_format' (use: text, markdown, json)" >&2
    exit 2
    ;;
esac

# Check directory exists
if [[ ! -d "$target_dir" ]]; then
  echo "error: directory not found: ${target_dir}" >&2
  exit 1
fi

# Build find exclude arguments as array
declare -a find_exclude_args=()
if [[ ${#exclude_patterns[@]} -gt 0 ]]; then
  for pat in "${exclude_patterns[@]}"; do
    find_exclude_args+=(-not -path "*/${pat}/*")
  done
fi

# =============================================================================
# Collect Metrics
# =============================================================================

# Count files by type
count_files() {
  local ext="$1"
  find "$target_dir" -type f -name "*.$ext" ${find_exclude_args[@]+"${find_exclude_args[@]}"} 2>/dev/null | wc -l | tr -d ' '
}

# Count total lines
count_lines() {
  local ext="$1"
  find "$target_dir" -type f -name "*.$ext" ${find_exclude_args[@]+"${find_exclude_args[@]}"} -exec cat {} \; 2>/dev/null | wc -l | tr -d ' '
}

# Total file count
total_files=$(find "$target_dir" -type f ${find_exclude_args[@]+"${find_exclude_args[@]}"} 2>/dev/null | wc -l | tr -d ' ')

# Count by common types
sh_count=$(count_files "sh")
ts_count=$(count_files "ts")
js_count=$(count_files "js")
md_count=$(count_files "md")
yml_count=$(count_files "yml")
yaml_count=$(count_files "yaml")
json_count=$(count_files "json")
py_count=$(count_files "py")

# Line counts
sh_lines=$(count_lines "sh")
ts_lines=$(count_lines "ts")
js_lines=$(count_lines "js")

# Total lines (for major code types)
total_lines=$((sh_lines + ts_lines + js_lines))

# Identify potential hotspots (largest files)
hotspots=""
if command -v wc >/dev/null 2>&1; then
  hotspots=$(find "$target_dir" -type f \( -name "*.sh" -o -name "*.ts" -o -name "*.js" -o -name "*.py" \) ${find_exclude_args[@]+"${find_exclude_args[@]}"} -exec wc -l {} \; 2>/dev/null | sort -rn | head -10)
fi

# =============================================================================
# Output
# =============================================================================

case "$output_format" in
  text)
    echo "=================================================="
    echo "Audit Scope: ${target_dir}"
    echo "=================================================="
    echo ""
    echo "## File Count Summary"
    echo "  Total files: ${total_files}"
    echo "  Shell (.sh): ${sh_count}"
    echo "  TypeScript (.ts): ${ts_count}"
    echo "  JavaScript (.js): ${js_count}"
    echo "  Markdown (.md): ${md_count}"
    echo "  YAML (.yml/.yaml): $((yml_count + yaml_count))"
    echo "  JSON (.json): ${json_count}"
    echo "  Python (.py): ${py_count}"
    echo ""
    echo "## Line Count (Code)"
    echo "  Shell: ${sh_lines}"
    echo "  TypeScript: ${ts_lines}"
    echo "  JavaScript: ${js_lines}"
    echo "  Total: ${total_lines}"
    echo ""
    echo "## Potential Hotspots (Top 10 by line count)"
    if [[ -n "$hotspots" ]]; then
      echo "$hotspots" | while read -r line; do
        echo "  $line"
      done
    else
      echo "  (no code files found)"
    fi
    echo ""
    ;;

  markdown)
    echo "# Audit Scope: ${target_dir}"
    echo ""
    echo "## File Count Summary"
    echo ""
    echo "| Type | Count |"
    echo "|------|-------|"
    echo "| Total | ${total_files} |"
    echo "| Shell (.sh) | ${sh_count} |"
    echo "| TypeScript (.ts) | ${ts_count} |"
    echo "| JavaScript (.js) | ${js_count} |"
    echo "| Markdown (.md) | ${md_count} |"
    echo "| YAML | $((yml_count + yaml_count)) |"
    echo "| JSON | ${json_count} |"
    echo "| Python (.py) | ${py_count} |"
    echo ""
    echo "## Line Count (Code)"
    echo ""
    echo "| Type | Lines |"
    echo "|------|-------|"
    echo "| Shell | ${sh_lines} |"
    echo "| TypeScript | ${ts_lines} |"
    echo "| JavaScript | ${js_lines} |"
    echo "| **Total** | **${total_lines}** |"
    echo ""
    echo "## Potential Hotspots"
    echo ""
    if [[ -n "$hotspots" ]]; then
      echo "| Lines | File |"
      echo "|-------|------|"
      echo "$hotspots" | while read -r lines file; do
        echo "| ${lines} | ${file} |"
      done
    else
      echo "(no code files found)"
    fi
    ;;

  json)
    # Build hotspots JSON array
    hotspots_json="[]"
    if [[ -n "$hotspots" ]]; then
      hotspots_json="["
      first=true
      while read -r lines file; do
        if [[ "$first" == true ]]; then
          first=false
        else
          hotspots_json+=","
        fi
        hotspots_json+="{\"lines\":${lines},\"file\":\"${file}\"}"
      done <<< "$hotspots"
      hotspots_json+="]"
    fi

    cat << EOF
{
  "directory": "${target_dir}",
  "fileCount": {
    "total": ${total_files},
    "shell": ${sh_count},
    "typescript": ${ts_count},
    "javascript": ${js_count},
    "markdown": ${md_count},
    "yaml": $((yml_count + yaml_count)),
    "json": ${json_count},
    "python": ${py_count}
  },
  "lineCount": {
    "shell": ${sh_lines},
    "typescript": ${ts_lines},
    "javascript": ${js_lines},
    "total": ${total_lines}
  },
  "hotspots": ${hotspots_json}
}
EOF
    ;;
esac

exit 0
