#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/fitness-check.sh
# 架构适应度检查脚本
#
# 执行架构适应度函数检查，验证代码是否符合架构规则。
#
# 用法：
#   ./fitness-check.sh [选项]
#   ./fitness-check.sh --help
#
# 选项：
#   --mode MODE         检查模式：warn（警告）| error（阻断）
#   --rules FILE        规则文件路径
#   --project-root DIR  项目根目录
#   --file FILE         检查单个文件（用于测试）
#
# 退出码：
#   0 - 检查通过（或 warn 模式下有警告）
#   1 - 检查失败（error 模式下有违规）
#   2 - 用法错误

set -euo pipefail

# 版本
VERSION="1.0.0"

# 默认值
mode="warn"
rules_file=""
project_root="."
single_file=""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 计数器
errors=0
warnings=0

# 显示帮助
show_help() {
    cat << 'EOF'
架构适应度检查脚本 (fitness-check.sh)

用法：
  ./fitness-check.sh [选项]

选项：
  --mode MODE         检查模式：warn（仅警告）| error（阻断）
  --rules FILE        规则文件路径（默认: specs/architecture/fitness-rules.md）
  --project-root DIR  项目根目录，默认为当前目录
  --file FILE         检查单个文件（用于测试）
  --help, -h          显示此帮助信息
  --version, -v       显示版本信息

支持的规则类型：
  FR-001: 分层架构检查（Controller → Service → Repository）
  FR-002: 循环依赖检查（基础版）
  FR-003: 敏感文件守护

退出码：
  0 - 检查通过（或 warn 模式下有警告）
  1 - 检查失败（error 模式下有违规）
  2 - 用法错误

示例：
  ./fitness-check.sh                          # 默认检查
  ./fitness-check.sh --mode error             # 严格模式
  ./fitness-check.sh --rules custom-rules.md  # 自定义规则文件
  ./fitness-check.sh --file src/test.js       # 检查单个文件

EOF
}

# 显示版本
show_version() {
    echo "fitness-check.sh v${VERSION}"
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
    if [[ "$mode" == "error" ]]; then
        errors=$((errors + 1))
    else
        warnings=$((warnings + 1))
    fi
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
    warnings=$((warnings + 1))
}

# ============================================================================
# FR-001: 分层架构检查
# Controller 不应直接调用 Repository
# ============================================================================
check_layered_architecture() {
    log_info "FR-001: 检查分层架构..."

    local src_dir="${project_root}/src"
    local controllers_dir="${src_dir}/controllers"

    if [[ ! -d "$controllers_dir" ]]; then
        # 尝试其他常见路径
        controllers_dir="${src_dir}/controller"
        if [[ ! -d "$controllers_dir" ]]; then
            log_info "  未找到 controllers 目录，跳过"
            return 0
        fi
    fi

    local violations=""

    # 查找 Controller 中直接调用 Repository 的代码
    # 模式: Repository.xxx 或 import ... from '...repository'
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        # 检查直接调用 Repository 方法
        local matches
        matches=$(grep -nE "Repository\.(find|save|delete|update|create|get)|new [A-Z][a-zA-Z]*Repository" "$file" 2>/dev/null || true)

        if [[ -n "$matches" ]]; then
            violations="${violations}${file}:\n${matches}\n\n"
        fi
    done < <(find "$controllers_dir" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null)

    if [[ -n "$violations" ]]; then
        log_fail "FR-001: 分层架构违规 - Controller 直接访问 Repository"
        echo -e "  违规详情:\n$violations" >&2
        return 1
    fi

    log_pass "FR-001: 分层架构检查通过"
    return 0
}

# ============================================================================
# FR-002: 循环依赖检查（基础版）
# 检测明显的循环 import
# ============================================================================
check_circular_dependencies() {
    log_info "FR-002: 检查循环依赖..."

    local src_dir="${project_root}/src"

    if [[ ! -d "$src_dir" ]]; then
        log_info "  未找到 src 目录，跳过"
        return 0
    fi

    # 基础检查：同一目录下的互相引用
    # 这是一个简化版本，完整检测需要更复杂的图分析

    local circular_count=0

    # 查找可能的循环引用模式
    # 例如: a.ts import from './b' 且 b.ts import from './a'
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local dir
        dir=$(dirname "$file")
        local base
        base=$(basename "$file" | sed 's/\.\(ts\|js\|tsx\|jsx\)$//')

        # 获取该文件的相对导入
        local imports
        imports=$(grep -oE "from ['\"]\.\/[a-zA-Z0-9_-]+['\"]" "$file" 2>/dev/null | sed "s/from ['\"]\.\\///g; s/['\"]//g" || true)

        for imported in $imports; do
            local imported_file="${dir}/${imported}.ts"
            [[ ! -f "$imported_file" ]] && imported_file="${dir}/${imported}.js"
            [[ ! -f "$imported_file" ]] && continue

            # 检查被导入的文件是否反向导入
            if grep -qE "from ['\"]\./${base}['\"]" "$imported_file" 2>/dev/null; then
                log_warn "FR-002: 可能的循环依赖: ${file} <-> ${imported_file}"
                circular_count=$((circular_count + 1))
            fi
        done
    done < <(find "$src_dir" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | head -100)

    if [[ $circular_count -gt 0 ]]; then
        log_warn "FR-002: 检测到 ${circular_count} 处可能的循环依赖"
        return 0  # 只警告，不阻断
    fi

    log_pass "FR-002: 循环依赖检查通过"
    return 0
}

# ============================================================================
# FR-003: 敏感文件守护
# 防止敏感文件被意外修改或提交
# ============================================================================
check_sensitive_files() {
    log_info "FR-003: 检查敏感文件..."

    # 敏感文件模式
    local sensitive_patterns=(
        ".env"
        ".env.local"
        ".env.production"
        "credentials.json"
        "secrets.yaml"
        "*.pem"
        "*.key"
        "id_rsa"
        "id_ed25519"
    )

    local violations=0

    for pattern in "${sensitive_patterns[@]}"; do
        # 检查是否有敏感文件被跟踪
        if command -v git >/dev/null 2>&1 && git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local tracked
            tracked=$(git -C "$project_root" ls-files "$pattern" 2>/dev/null || true)
            if [[ -n "$tracked" ]]; then
                log_fail "FR-003: 敏感文件被 Git 跟踪: ${tracked}"
                violations=$((violations + 1))
            fi
        fi
    done

    # 检查 .gitignore 是否包含敏感模式
    local gitignore="${project_root}/.gitignore"
    if [[ -f "$gitignore" ]]; then
        local missing_patterns=()
        for pattern in ".env" "*.key" "*.pem"; do
            if ! grep -qE "^${pattern}$|^\\*${pattern}$" "$gitignore" 2>/dev/null; then
                missing_patterns+=("$pattern")
            fi
        done

        if [[ ${#missing_patterns[@]} -gt 0 ]]; then
            log_warn "FR-003: .gitignore 建议添加敏感文件模式: ${missing_patterns[*]}"
        fi
    fi

    if [[ $violations -eq 0 ]]; then
        log_pass "FR-003: 敏感文件检查通过"
        return 0
    fi

    return 1
}

# ============================================================================
# 检查单个文件（用于测试）
# ============================================================================
check_single_file() {
    local file="$1"

    log_info "检查文件: $file"

    if [[ ! -f "$file" ]]; then
        log_fail "文件不存在: $file"
        return 1
    fi

    # FR-001: 分层架构检查
    if [[ "$file" =~ controller ]]; then
        local matches
        matches=$(grep -nE "Repository\.(find|save|delete|update|create|get)" "$file" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            log_fail "FR-001: Controller 直接访问 Repository"
            echo "  $matches" >&2
            return 1
        fi
    fi

    log_pass "文件检查通过: $file"
    return 0
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --mode)
                mode="${2:-warn}"
                shift 2
                ;;
            --rules)
                rules_file="${2:-}"
                shift 2
                ;;
            --project-root)
                project_root="${2:-.}"
                shift 2
                ;;
            --file)
                single_file="${2:-}"
                shift 2
                ;;
            -*)
                echo "error: unknown option: $1" >&2
                echo "Use --help for usage" >&2
                exit 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # 验证模式
    case "$mode" in
        warn|error) ;;
        *)
            echo "error: invalid --mode: $mode (must be warn or error)" >&2
            exit 2
            ;;
    esac

    echo "=========================================="
    echo "架构适应度检查 (fitness-check.sh)"
    echo "模式: $mode"
    echo "项目: $project_root"
    echo "=========================================="
    echo ""

    # 单文件检查模式
    if [[ -n "$single_file" ]]; then
        check_single_file "$single_file"
        exit $?
    fi

    # 运行所有检查
    check_layered_architecture || true
    check_circular_dependencies || true
    check_sensitive_files || true

    # 输出总结
    echo ""
    echo "=========================================="
    echo "检查完成"
    echo "  错误: $errors"
    echo "  警告: $warnings"
    echo "=========================================="

    if [[ $errors -gt 0 ]]; then
        echo ""
        log_fail "检查失败: ${errors} 个错误"
        exit 1
    fi

    if [[ $warnings -gt 0 ]]; then
        echo ""
        log_warn "检查通过: ${warnings} 个警告"
        exit 0
    fi

    echo ""
    log_pass "检查通过: 无违规"
    exit 0
}

# 运行主函数
main "$@"
