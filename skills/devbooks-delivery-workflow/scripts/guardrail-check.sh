#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<EOF
usage: guardrail-check.sh <change-id> [options]

Options:
  --project-root <dir>   Project root directory (default: current dir)
  --change-root <dir>    Change root directory (default: changes)
  --truth-root <dir>     Truth root directory for architecture constraints
  --role <role>          Role to check permissions for (coder|test-owner|reviewer)
  --check-lockfile       Check if lockfile changes require explicit declaration
  --check-engineering    Check if engineering system changes require approval
  --check-layers         Check layering constraints (dependency guard)
  --check-cycles         Check for circular dependencies
  --check-hotspots       Warn if changes touch high-risk hotspots
  -h, --help             Show this help message

Exit codes:
  0 - All checks passed
  1 - Guardrail violation detected
  2 - Invalid arguments
  3 - Missing required files
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
truth_root="${DEVBOOKS_TRUTH_ROOT:-}"
role=""
check_lockfile=false
check_engineering=false
check_layers=false
check_cycles=false
check_hotspots=false

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
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --role)
      role="${2:-}"
      shift 2
      ;;
    --check-lockfile)
      check_lockfile=true
      shift
      ;;
    --check-engineering)
      check_engineering=true
      shift
      ;;
    --check-layers)
      check_layers=true
      shift
      ;;
    --check-cycles)
      check_cycles=true
      shift
      ;;
    --check-hotspots)
      check_hotspots=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$project_root" || -z "$change_root" ]]; then
  usage
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "error: missing dependency: rg (ripgrep)" >&2
  exit 2
fi

if [[ "$change_root" = /* ]]; then
  file="${change_root}/${change_id}/verification.md"
else
  file="${project_root}/${change_root}/${change_id}/verification.md"
fi


if [[ ! -f "$file" ]]; then
  echo "error: missing ${file}" >&2
  exit 2
fi

# Check if guardrail section exists - if not, skip (guardrail review not applicable)
if ! rg -n "^F\\) 结构质量守门记录|^## F\\) 结构质量守门" "$file" >/dev/null 2>&1; then
  echo "ok: guardrail section not present (not applicable for ${change_id})"
  exit 0
fi

decision_line=$(rg -n "^- 决策与授权：" "$file" || true)
if [[ -z "$decision_line" ]]; then
  echo "error: guardrail section exists but missing '- 决策与授权：' line in ${file}" >&2
  exit 1
fi

value="$(echo "$decision_line" | sed -E 's/^[0-9]+:- 决策与授权： *//')"

if [[ -z "$value" || "$value" == "<"* || "$value" == "TBD"* ]]; then
  echo "error: unresolved guardrail decision in ${file}" >&2
  exit 1
fi

echo "ok: guardrail decision present for ${change_id}"

# =============================================================================
# Role Permission Checks (借鉴 VS Code 的角色权限分离机制)
# =============================================================================

# 定义角色禁止修改的文件模式
declare -A ROLE_FORBIDDEN_PATTERNS
ROLE_FORBIDDEN_PATTERNS[coder]="tests/|test/|\.test\.|\.spec\.|__tests__|verification\.md"
ROLE_FORBIDDEN_PATTERNS[test-owner]=""  # test-owner 可以修改测试文件
ROLE_FORBIDDEN_PATTERNS[reviewer]=".*"  # reviewer 不应修改任何文件

# 定义所有角色都禁止修改的敏感文件（类似 VS Code 的 engineering system 保护）
SENSITIVE_PATTERNS="\.devbooks/|\.github/workflows/|build/|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock"

check_role_permissions() {
  local role="$1"
  local change_path="$2"

  if [[ -z "$role" ]]; then
    return 0
  fi

  echo "info: checking role permissions for '${role}'..."

  # 获取变更的文件列表（从 git diff 或变更包记录）
  local changed_files=""
  if [[ -d "${project_root}/.git" ]]; then
    changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null || true)
  fi

  # 如果没有 git，尝试从 proposal.md 的 Impact 部分读取
  if [[ -z "$changed_files" && -f "${change_path}/proposal.md" ]]; then
    changed_files=$(grep -A 100 "^## Impact" "${change_path}/proposal.md" | grep -E "^\s*-\s+\`" | sed 's/.*`\([^`]*\)`.*/\1/' || true)
  fi

  if [[ -z "$changed_files" ]]; then
    echo "warn: cannot determine changed files, skipping role permission check"
    return 0
  fi

  local forbidden="${ROLE_FORBIDDEN_PATTERNS[$role]:-}"
  local violations=""

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # 检查角色特定的禁止模式
    if [[ -n "$forbidden" ]] && echo "$file" | grep -qE "$forbidden"; then
      violations="${violations}\n  - ${file} (forbidden for role '${role}')"
    fi

    # 检查敏感文件（所有角色都禁止，除非明确声明）
    if echo "$file" | grep -qE "$SENSITIVE_PATTERNS"; then
      # 检查 proposal.md 是否有 engineering-system-change 标签
      if ! grep -q "engineering-system-change" "${change_path}/proposal.md" 2>/dev/null; then
        violations="${violations}\n  - ${file} (sensitive file requires 'engineering-system-change' tag in proposal.md)"
      fi
    fi
  done <<< "$changed_files"

  if [[ -n "$violations" ]]; then
    echo -e "error: role permission violations detected:${violations}" >&2
    return 1
  fi

  echo "ok: role permissions check passed for '${role}'"
  return 0
}

# =============================================================================
# Lockfile Idempotency Check (借鉴 VS Code 的 no-package-lock-changes.yml)
# =============================================================================

check_lockfile_changes() {
  local change_path="$1"

  echo "info: checking lockfile changes..."

  local lockfiles="package-lock.json yarn.lock pnpm-lock.yaml Cargo.lock Gemfile.lock poetry.lock"
  local changed_lockfiles=""

  if [[ -d "${project_root}/.git" ]]; then
    for lockfile in $lockfiles; do
      if cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null | grep -q "^${lockfile}$"; then
        changed_lockfiles="${changed_lockfiles} ${lockfile}"
      fi
    done
  fi

  if [[ -n "$changed_lockfiles" ]]; then
    # 检查 proposal.md 是否明确声明了依赖变更
    if ! grep -qE "(dependency|依赖|deps|升级|upgrade|update.*package)" "${change_path}/proposal.md" 2>/dev/null; then
      echo "error: lockfile changes detected (${changed_lockfiles}) but proposal.md does not declare dependency changes" >&2
      echo "hint: add dependency change description to proposal.md or use '--check-lockfile=false'" >&2
      return 1
    fi
  fi

  echo "ok: lockfile check passed"
  return 0
}

# =============================================================================
# Engineering System Change Check
# =============================================================================

check_engineering_changes() {
  local change_path="$1"

  echo "info: checking engineering system changes..."

  local eng_patterns="\.devbooks/|\.github/|build/|scripts/|Makefile|gulpfile|webpack\.config|vite\.config|tsconfig|eslint\.config|\.eslintrc"
  local eng_changes=""

  if [[ -d "${project_root}/.git" ]]; then
    eng_changes=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null | grep -E "$eng_patterns" || true)
  fi

  if [[ -n "$eng_changes" ]]; then
    # 检查 proposal.md 是否有 engineering-system-change 标签
    if ! grep -q "engineering-system-change" "${change_path}/proposal.md" 2>/dev/null; then
      echo "error: engineering system changes detected but proposal.md missing 'engineering-system-change' tag:" >&2
      echo "$eng_changes" | sed 's/^/  - /' >&2
      return 1
    fi
  fi

  echo "ok: engineering system check passed"
  return 0
}

# =============================================================================
# Layering Constraints Check (依赖卫士 - Dependency Guard)
# 防止依赖方向违规（上层不可直接依赖下层实现细节）
# =============================================================================

check_layering_constraints() {
  local change_path="$1"
  local constraints_file="${truth_root}/architecture/c4.md"

  echo "info: checking layering constraints (dependency guard)..."

  # 如果没有 truth_root 或约束文件不存在，跳过
  if [[ -z "$truth_root" ]]; then
    echo "warn: --truth-root not specified, skipping layering check"
    return 0
  fi

  if [[ ! -f "$constraints_file" ]]; then
    echo "warn: no layering constraints file found at ${constraints_file}, skipping"
    return 0
  fi

  # 获取变更的文件
  local changed_files=""
  if [[ -d "${project_root}/.git" ]]; then
    changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null || true)
  fi

  if [[ -z "$changed_files" ]]; then
    echo "warn: cannot determine changed files, skipping layering check"
    return 0
  fi

  local violations=""

  # 解析约束文件中的分层规则
  # 格式：| base | src/base/ | ... | （无） | platform, domain, ... |

  # 常见的分层违规检查
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! "$file" =~ \.(ts|tsx|js|jsx|py|go|java|rs)$ ]] && continue

    local file_path="${project_root}/${file}"
    [[ ! -f "$file_path" ]] && continue

    # 检查 base 层是否引用了 platform/domain/application/ui
    if [[ "$file" =~ ^src/base/ ]] || [[ "$file" =~ /base/ ]]; then
      if rg -q "from ['\"].*(platform|domain|application|app|ui)/" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: base layer imports upper layer"
      fi
    fi

    # 检查 common 层是否引用了 browser/node 特定代码
    if [[ "$file" =~ /common/ ]]; then
      if rg -q "from ['\"].*(browser|node)/" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: common layer imports platform-specific code"
      fi
      # 检查是否使用了 DOM API
      if rg -q "(document\.|window\.|navigator\.)" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: common layer uses DOM API"
      fi
    fi

    # 检查 core 是否引用了 contrib
    if [[ "$file" =~ /core/ ]] || [[ "$file" =~ /services/ ]]; then
      if rg -q "from ['\"].*contrib/" "$file_path" 2>/dev/null; then
        violations="${violations}\n  - ${file}: core imports contrib (violates extension point design)"
      fi
    fi

  done <<< "$changed_files"

  if [[ -n "$violations" ]]; then
    echo -e "error: layering constraint violations detected:${violations}" >&2
    echo "hint: see ${constraints_file} for allowed dependencies" >&2
    return 1
  fi

  echo "ok: layering constraints check passed"
  return 0
}

# =============================================================================
# Circular Dependency Check (循环依赖检测)
# =============================================================================

check_circular_dependencies() {
  echo "info: checking for circular dependencies..."

  # 检查是否有 madge 工具可用
  if command -v madge >/dev/null 2>&1; then
    local circular=""
    circular=$(cd "$project_root" && madge --circular --warning src/ 2>/dev/null | grep -E "^\s+[a-zA-Z]" || true)

    if [[ -n "$circular" ]]; then
      echo "error: circular dependencies detected:" >&2
      echo "$circular" | sed 's/^/  /' >&2
      return 1
    fi
  else
    # 降级：使用简单的 grep 检测常见的循环模式
    echo "info: madge not available, using basic circular detection"

    # 检查是否有文件同时被导入又导入同一个模块（简单启发式）
    if [[ -d "${project_root}/.git" ]]; then
      local changed_files
      changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null | grep -E '\.(ts|js|tsx|jsx)$' || true)

      while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local file_path="${project_root}/${file}"
        [[ ! -f "$file_path" ]] && continue

        # 获取文件的 imports
        local imports
        imports=$(rg "^import .* from ['\"]\./" "$file_path" 2>/dev/null | sed "s/.*from ['\"]\\([^'\"]*\\)['\"].*/\\1/" || true)

        # 检查这些被导入的文件是否又导入了当前文件
        local file_base
        file_base=$(basename "$file" | sed 's/\.[^.]*$//')

        while IFS= read -r imported; do
          [[ -z "$imported" ]] && continue
          local imported_path="${project_root}/$(dirname "$file")/${imported}"
          [[ "$imported_path" =~ \.ts$ ]] || imported_path="${imported_path}.ts"

          if [[ -f "$imported_path" ]] && rg -q "from ['\"].*${file_base}['\"]" "$imported_path" 2>/dev/null; then
            echo "warn: potential circular dependency: ${file} <-> ${imported}" >&2
          fi
        done <<< "$imports"
      done <<< "$changed_files"
    fi
  fi

  echo "ok: circular dependency check passed"
  return 0
}

# =============================================================================
# Hotspot Warning Check (热点警告)
# 热点 = 高变更频率 × 高复杂度
# =============================================================================

check_hotspot_changes() {
  local change_path="$1"
  local hotspots_file="${truth_root}/architecture/hotspots.md"

  echo "info: checking if changes touch hotspots..."

  # 如果有热点文件，从中读取热点列表
  local hotspot_files=""
  if [[ -n "$truth_root" && -f "$hotspots_file" ]]; then
    hotspot_files=$(grep -E "^\| " "$hotspots_file" | grep -v "文件\|File\|---" | awk -F'|' '{print $2}' | tr -d ' ' || true)
  fi

  # 如果没有热点文件，尝试使用 git 历史计算
  if [[ -z "$hotspot_files" && -d "${project_root}/.git" ]]; then
    echo "info: no hotspots.md found, computing from git history (top 10 churn files)..."
    hotspot_files=$(cd "$project_root" && git log --oneline --name-only --since="30 days ago" 2>/dev/null | \
      grep -E '\.(ts|tsx|js|jsx|py|go|java|rs)$' | \
      sort | uniq -c | sort -rn | head -10 | awk '{print $2}' || true)
  fi

  if [[ -z "$hotspot_files" ]]; then
    echo "info: no hotspot data available, skipping"
    return 0
  fi

  # 获取变更的文件
  local changed_files=""
  if [[ -d "${project_root}/.git" ]]; then
    changed_files=$(cd "$project_root" && git diff --name-only HEAD~1 2>/dev/null || true)
  fi

  # 检查变更文件是否触及热点
  local hotspot_hits=""
  while IFS= read -r changed; do
    [[ -z "$changed" ]] && continue
    if echo "$hotspot_files" | grep -qF "$changed"; then
      hotspot_hits="${hotspot_hits}\n  - ${changed}"
    fi
  done <<< "$changed_files"

  if [[ -n "$hotspot_hits" ]]; then
    echo -e "warn: changes touch high-risk hotspots (high churn × complexity):${hotspot_hits}" >&2
    echo "hint: consider extra review and testing for these files" >&2
    # 这是警告，不是错误，不阻止合并
  fi

  echo "ok: hotspot check completed"
  return 0
}

# =============================================================================
# Run Additional Checks
# =============================================================================

exit_code=0

# 角色权限检查
if [[ -n "$role" ]]; then
  change_path=$(dirname "$file")
  if ! check_role_permissions "$role" "$change_path"; then
    exit_code=1
  fi
fi

# Lockfile 检查
if [[ "$check_lockfile" == "true" ]]; then
  change_path=$(dirname "$file")
  if ! check_lockfile_changes "$change_path"; then
    exit_code=1
  fi
fi

# 工程系统变更检查
if [[ "$check_engineering" == "true" ]]; then
  change_path=$(dirname "$file")
  if ! check_engineering_changes "$change_path"; then
    exit_code=1
  fi
fi

# 分层约束检查（依赖卫士）
if [[ "$check_layers" == "true" ]]; then
  change_path=$(dirname "$file")
  if ! check_layering_constraints "$change_path"; then
    exit_code=1
  fi
fi

# 循环依赖检查
if [[ "$check_cycles" == "true" ]]; then
  if ! check_circular_dependencies; then
    exit_code=1
  fi
fi

# 热点警告检查（警告不阻止，但记录）
if [[ "$check_hotspots" == "true" ]]; then
  change_path=$(dirname "$file")
  check_hotspot_changes "$change_path"
  # 热点只是警告，不影响 exit_code
fi

exit $exit_code
