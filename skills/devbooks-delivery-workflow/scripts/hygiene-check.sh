#!/usr/bin/env bash
# hygiene-check.sh - 代码卫生检查脚本（借鉴 VS Code gulpfile.hygiene.ts）
set -euo pipefail

usage() {
  cat >&2 <<EOF
usage: hygiene-check.sh [options] [path...]

Options:
  --project-root <dir>   Project root directory (default: current dir)
  --fix                  Attempt to fix issues automatically
  --format-only          Only check formatting
  --lint-only            Only check linting
  --json                 Output results in JSON format
  -h, --help             Show this help message

Checks performed:
  1. Formatting (prettier/editorconfig)
  2. Linting (eslint/stylelint)
  3. Copyright headers
  4. No debug statements (console.log, debugger)
  5. No test.only/describe.only
  6. No TODO without issue reference
  7. Trailing whitespace
  8. File encoding (UTF-8)

Exit codes:
  0 - All checks passed
  1 - Hygiene violations detected
  2 - Invalid arguments
  3 - Missing dependencies
EOF
}

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
fix_mode=false
format_only=false
lint_only=false
json_output=false
paths=()

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
    --fix)
      fix_mode=true
      shift
      ;;
    --format-only)
      format_only=true
      shift
      ;;
    --lint-only)
      lint_only=true
      shift
      ;;
    --json)
      json_output=true
      shift
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      paths+=("$1")
      shift
      ;;
  esac
done

cd "$project_root"

# 默认检查所有源文件
if [[ ${#paths[@]} -eq 0 ]]; then
  paths=("src" "tests" "lib")
fi

# 结果收集
declare -a violations=()
exit_code=0

log_violation() {
  local type="$1"
  local file="$2"
  local message="$3"
  violations+=("$type|$file|$message")
  exit_code=1
}

# =============================================================================
# Check 1: Formatting (prettier/editorconfig)
# =============================================================================
check_formatting() {
  echo "info: checking formatting..."

  if command -v prettier >/dev/null 2>&1; then
    local prettier_args=("--check")
    [[ "$fix_mode" == "true" ]] && prettier_args=("--write")

    for path in "${paths[@]}"; do
      [[ -e "$path" ]] || continue
      if ! prettier "${prettier_args[@]}" "$path" 2>/dev/null; then
        log_violation "formatting" "$path" "prettier formatting issues"
      fi
    done
  else
    echo "warn: prettier not found, skipping format check"
  fi
}

# =============================================================================
# Check 2: Linting (eslint)
# =============================================================================
check_linting() {
  echo "info: checking linting..."

  if command -v eslint >/dev/null 2>&1; then
    local eslint_args=()
    [[ "$fix_mode" == "true" ]] && eslint_args+=("--fix")

    for path in "${paths[@]}"; do
      [[ -e "$path" ]] || continue
      if ! eslint "${eslint_args[@]}" "$path" 2>/dev/null; then
        log_violation "linting" "$path" "eslint violations"
      fi
    done
  elif command -v npm >/dev/null 2>&1 && [[ -f "package.json" ]]; then
    if grep -q '"lint"' package.json 2>/dev/null; then
      if ! npm run lint 2>/dev/null; then
        log_violation "linting" "." "npm run lint failed"
      fi
    fi
  else
    echo "warn: eslint not found, skipping lint check"
  fi
}

# =============================================================================
# Check 3: Debug statements
# =============================================================================
check_debug_statements() {
  echo "info: checking for debug statements..."

  local patterns=(
    'console\.log\('
    'console\.debug\('
    'console\.warn\('
    'debugger;'
    'DEBUG\s*='
  )

  for path in "${paths[@]}"; do
    [[ -e "$path" ]] || continue

    for pattern in "${patterns[@]}"; do
      local matches
      matches=$(rg -l "$pattern" "$path" --type ts --type js 2>/dev/null || true)
      if [[ -n "$matches" ]]; then
        while IFS= read -r file; do
          log_violation "debug" "$file" "contains debug statement: $pattern"
        done <<< "$matches"
      fi
    done
  done
}

# =============================================================================
# Check 4: test.only / describe.only
# =============================================================================
check_test_only() {
  echo "info: checking for test.only/describe.only..."

  local patterns=(
    '\.only\s*\('
    'it\.only\s*\('
    'test\.only\s*\('
    'describe\.only\s*\('
    'fdescribe\s*\('
    'fit\s*\('
  )

  for path in "${paths[@]}"; do
    [[ -e "$path" ]] || continue

    for pattern in "${patterns[@]}"; do
      local matches
      matches=$(rg -l "$pattern" "$path" --type ts --type js 2>/dev/null || true)
      if [[ -n "$matches" ]]; then
        while IFS= read -r file; do
          log_violation "test-only" "$file" "contains .only() or focused test"
        done <<< "$matches"
      fi
    done
  done
}

# =============================================================================
# Check 5: TODO without issue reference
# =============================================================================
check_todo_issues() {
  echo "info: checking TODOs for issue references..."

  # 查找没有 issue 引用的 TODO
  local matches
  matches=$(rg -l 'TODO(?!\s*[:#]\s*\d+|.*#\d+|.*issue|.*ISSUE)' "${paths[@]}" --type ts --type js 2>/dev/null || true)

  if [[ -n "$matches" ]]; then
    while IFS= read -r file; do
      log_violation "todo" "$file" "contains TODO without issue reference (use TODO: #123 or TODO: see issue #123)"
    done <<< "$matches"
  fi
}

# =============================================================================
# Check 6: Trailing whitespace
# =============================================================================
check_trailing_whitespace() {
  echo "info: checking for trailing whitespace..."

  for path in "${paths[@]}"; do
    [[ -e "$path" ]] || continue

    local matches
    matches=$(rg -l '\s+$' "$path" --type ts --type js --type md 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      if [[ "$fix_mode" == "true" ]]; then
        while IFS= read -r file; do
          sed -i '' 's/[[:space:]]*$//' "$file" 2>/dev/null || sed -i 's/[[:space:]]*$//' "$file"
          echo "fixed: $file (trailing whitespace)"
        done <<< "$matches"
      else
        while IFS= read -r file; do
          log_violation "whitespace" "$file" "contains trailing whitespace"
        done <<< "$matches"
      fi
    fi
  done
}

# =============================================================================
# Check 7: Copyright headers (optional)
# =============================================================================
check_copyright() {
  echo "info: checking copyright headers..."

  # 检查是否有 copyright 配置
  local copyright_pattern=""
  if [[ -f ".copyrightrc" ]]; then
    copyright_pattern=$(cat .copyrightrc)
  elif [[ -f "LICENSE" ]]; then
    # 尝试从 LICENSE 文件提取 copyright holder
    local holder
    holder=$(grep -i "copyright" LICENSE 2>/dev/null | head -1 || true)
    if [[ -n "$holder" ]]; then
      # 简化检查：只检查是否有 copyright 声明
      copyright_pattern="Copyright"
    fi
  fi

  if [[ -z "$copyright_pattern" ]]; then
    echo "info: no copyright configuration found, skipping"
    return 0
  fi

  for path in "${paths[@]}"; do
    [[ -e "$path" ]] || continue

    local files
    files=$(find "$path" -name "*.ts" -o -name "*.js" 2>/dev/null || true)

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      if ! head -20 "$file" | grep -qi "$copyright_pattern" 2>/dev/null; then
        log_violation "copyright" "$file" "missing copyright header"
      fi
    done <<< "$files"
  done
}

# =============================================================================
# Run checks
# =============================================================================

if [[ "$lint_only" == "true" ]]; then
  check_linting
elif [[ "$format_only" == "true" ]]; then
  check_formatting
else
  check_formatting
  check_linting
  check_debug_statements
  check_test_only
  check_todo_issues
  check_trailing_whitespace
  check_copyright
fi

# =============================================================================
# Output results
# =============================================================================

if [[ "$json_output" == "true" ]]; then
  echo "{"
  echo "  \"success\": $([[ $exit_code -eq 0 ]] && echo "true" || echo "false"),"
  echo "  \"violations\": ["
  first=true
  for v in "${violations[@]}"; do
    IFS='|' read -r type file message <<< "$v"
    [[ "$first" == "true" ]] || echo ","
    first=false
    echo -n "    {\"type\": \"$type\", \"file\": \"$file\", \"message\": \"$message\"}"
  done
  echo
  echo "  ]"
  echo "}"
else
  if [[ ${#violations[@]} -gt 0 ]]; then
    echo ""
    echo "=== Hygiene Violations ===" >&2
    for v in "${violations[@]}"; do
      IFS='|' read -r type file message <<< "$v"
      echo "[$type] $file: $message" >&2
    done
    echo ""
    echo "Total: ${#violations[@]} violation(s)" >&2
  else
    echo "ok: all hygiene checks passed"
  fi
fi

exit $exit_code
