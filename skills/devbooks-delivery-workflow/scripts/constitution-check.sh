#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/constitution-check.sh
# 宪法合规检查脚本
#
# 检查项目的 constitution.md 是否存在且格式正确。
#
# 用法：
#   ./constitution-check.sh [project-root]
#   ./constitution-check.sh --help
#
# 退出码：
#   0 - 宪法存在且有效
#   1 - 宪法缺失或无效
#   2 - 用法错误

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 版本
VERSION="1.0.0"

# 显示帮助
show_help() {
    cat << 'EOF'
宪法合规检查脚本 (constitution-check.sh)

用法：
  ./constitution-check.sh [选项] [project-root]

选项：
  --help, -h       显示此帮助信息
  --version, -v    显示版本信息
  --quiet, -q      静默模式，只输出错误

参数：
  project-root     项目根目录，默认为当前目录

检查项：
  1. constitution.md 文件存在
  2. 包含 "Part Zero" 章节
  3. 包含 "GIP-" 前缀的规则（至少 1 条）
  4. 包含 "逃生舱口" 章节

退出码：
  0 - 宪法存在且有效
  1 - 宪法缺失或无效
  2 - 用法错误

示例：
  ./constitution-check.sh                    # 检查当前目录
  ./constitution-check.sh /path/to/project   # 检查指定目录
  ./constitution-check.sh --quiet            # 静默模式

EOF
}

# 显示版本
show_version() {
    echo "constitution-check.sh v${VERSION}"
}

# 日志函数
log_info() {
    [[ "$QUIET" == "false" ]] && echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    [[ "$QUIET" == "false" ]] && echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
}

log_pass() {
    [[ "$QUIET" == "false" ]] && echo -e "${GREEN}[PASS]${NC} $*"
}

# 解析真理根目录
# 优先检查 dev-playbooks/，回退到 dev-playbooks/
resolve_truth_root() {
    local root="$1"

    # 检查 .devbooks/config.yaml 中的 root 配置
    if [[ -f "${root}/.devbooks/config.yaml" ]]; then
        local config_root
        config_root=$(grep "^root:" "${root}/.devbooks/config.yaml" 2>/dev/null | sed 's/root: *//' | tr -d "'" | tr -d '"' | tr -d '/' || true)
        if [[ -n "$config_root" && -d "${root}/${config_root}" ]]; then
            echo "${root}/${config_root}"
            return 0
        fi
    fi

    # 优先检查新路径 dev-playbooks/
    if [[ -d "${root}/dev-playbooks" ]]; then
        echo "${root}/dev-playbooks"
        return 0
    fi

    # 回退到旧路径 dev-playbooks/
    if [[ -d "${root}/devbooks" ]]; then
        echo "${root}/devbooks"
        return 0
    fi

    # 未找到
    echo ""
    return 1
}

# 检查宪法
check_constitution() {
    local root="${1:-.}"
    local errors=0
    local checks_passed=0
    local total_checks=4

    # 解析真理根目录
    local config_root
    config_root=$(resolve_truth_root "$root") || {
        log_error "无法找到配置根目录（dev-playbooks/ 或 dev-playbooks/）"
        return 1
    }

    local constitution="${config_root}/constitution.md"

    log_info "检查宪法文件: $constitution"

    # 检查 1: 文件存在
    if [[ -f "$constitution" ]]; then
        log_pass "constitution.md 存在"
        ((checks_passed++))
    else
        log_error "constitution.md 不存在: $constitution"
        ((errors++))
    fi

    # 如果文件不存在，直接返回
    if [[ ! -f "$constitution" ]]; then
        echo ""
        log_error "宪法检查失败: $errors 个错误"
        return 1
    fi

    # 检查 2: Part Zero 章节
    if grep -qE "^#+ *Part Zero" "$constitution" 2>/dev/null; then
        log_pass "包含 'Part Zero' 章节"
        ((checks_passed++))
    else
        log_error "缺少 'Part Zero' 章节"
        ((errors++))
    fi

    # 检查 3: GIP 规则
    local gip_count
    gip_count=$(grep -cE "^#+ *GIP-[0-9]+" "$constitution" 2>/dev/null || echo "0")
    if [[ "$gip_count" -gt 0 ]]; then
        log_pass "包含 GIP 规则 (${gip_count} 条)"
        ((checks_passed++))
    else
        log_error "缺少 GIP 规则（需要至少 1 条 GIP-xxx）"
        ((errors++))
    fi

    # 检查 4: 逃生舱口章节
    if grep -qE "^#+ *(逃生舱口|Escape Hatches?)" "$constitution" 2>/dev/null; then
        log_pass "包含 '逃生舱口' 章节"
        ((checks_passed++))
    else
        log_error "缺少 '逃生舱口' 章节"
        ((errors++))
    fi

    # 输出总结
    echo ""
    if [[ "$errors" -eq 0 ]]; then
        log_info "宪法检查通过: ${checks_passed}/${total_checks} 项检查通过"
        return 0
    else
        log_error "宪法检查失败: ${checks_passed}/${total_checks} 项检查通过, ${errors} 个错误"
        return 1
    fi
}

# 主函数
main() {
    QUIET="false"
    local project_root="."

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
            --quiet|-q)
                QUIET="true"
                shift
                ;;
            -*)
                log_error "未知选项: $1"
                echo "使用 --help 查看帮助" >&2
                exit 2
                ;;
            *)
                project_root="$1"
                shift
                ;;
        esac
    done

    # 检查项目根目录
    if [[ ! -d "$project_root" ]]; then
        log_error "项目根目录不存在: $project_root"
        exit 2
    fi

    # 执行检查
    if check_constitution "$project_root"; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main "$@"
