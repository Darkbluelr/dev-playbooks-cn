#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/spec-preview.sh
# 规格冲突预检脚本
#
# 读取变更包的 spec delta，检查暂存层中的冲突。
#
# 用法：
#   ./spec-preview.sh <change-id> [选项]
#   ./spec-preview.sh --help
#
# 退出码：
#   0 - 无冲突
#   1 - 检测到冲突
#   2 - 用法错误

set -euo pipefail

VERSION="1.0.0"

# 默认值
project_root="."
change_root="changes"
truth_root="specs"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助
show_help() {
    cat << 'EOF'
规格冲突预检脚本 (spec-preview.sh)

用法：
  ./spec-preview.sh <change-id> [选项]

选项：
  --project-root DIR  项目根目录，默认为当前目录
  --change-root DIR   变更包目录，默认为 changes
  --truth-root DIR    真理源目录，默认为 specs
  --help, -h          显示此帮助信息
  --version, -v       显示版本信息

冲突检测：
  1. 文件级冲突：同一目标文件被多个变更包修改
  2. 内容级冲突：同一 REQ-xxx 被修改

退出码：
  0 - 无冲突
  1 - 检测到冲突
  2 - 用法错误

示例：
  ./spec-preview.sh my-feature
  ./spec-preview.sh my-feature --change-root dev-playbooks/changes

EOF
}

show_version() {
    echo "spec-preview.sh v${VERSION}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

# 主函数
main() {
    local change_id=""

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
            --project-root)
                project_root="${2:-.}"
                shift 2
                ;;
            --change-root)
                change_root="${2:-changes}"
                shift 2
                ;;
            --truth-root)
                truth_root="${2:-specs}"
                shift 2
                ;;
            -*)
                log_error "未知选项: $1"
                exit 2
                ;;
            *)
                change_id="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$change_id" ]]; then
        log_error "缺少 change-id"
        exit 2
    fi

    # 构建路径
    local change_dir="${project_root}/${change_root}/${change_id}"
    local staged_dir="${project_root}/${truth_root}/_staged"
    local specs_delta_dir="${change_dir}/specs"

    log_info "预检变更包: ${change_id}"
    log_info "  变更目录: ${change_dir}"
    log_info "  暂存目录: ${staged_dir}"

    # 检查变更包存在
    if [[ ! -d "$change_dir" ]]; then
        log_error "变更包不存在: ${change_dir}"
        exit 2
    fi

    # 检查是否有 spec delta
    if [[ ! -d "$specs_delta_dir" ]]; then
        log_info "无 spec delta，跳过预检"
        exit 0
    fi

    local conflicts=0
    local file_conflicts=""
    local req_conflicts=""

    # 文件级冲突检测
    log_info "检查文件级冲突..."
    while IFS= read -r delta_file; do
        [[ -z "$delta_file" ]] && continue

        local relative_path="${delta_file#$specs_delta_dir/}"
        local staged_path="${staged_dir}/${relative_path}"

        if [[ -f "$staged_path" ]]; then
            file_conflicts="${file_conflicts}  ${relative_path}\n"
            conflicts=$((conflicts + 1))
        fi
    done < <(find "$specs_delta_dir" -type f -name "*.md" 2>/dev/null)

    # 内容级冲突检测（REQ-xxx）
    log_info "检查内容级冲突..."
    local current_reqs
    current_reqs=$(grep -rhoE "REQ-[A-Z0-9]+-[0-9]+" "$specs_delta_dir" 2>/dev/null | sort -u || true)

    if [[ -n "$current_reqs" && -d "$staged_dir" ]]; then
        while IFS= read -r req; do
            [[ -z "$req" ]] && continue

            if grep -rq "$req" "$staged_dir" 2>/dev/null; then
                req_conflicts="${req_conflicts}  ${req}\n"
                conflicts=$((conflicts + 1))
            fi
        done <<< "$current_reqs"
    fi

    # 输出结果
    echo ""
    if [[ $conflicts -gt 0 ]]; then
        log_error "检测到 ${conflicts} 个冲突"

        if [[ -n "$file_conflicts" ]]; then
            echo -e "\n文件级冲突:"
            echo -e "$file_conflicts"
        fi

        if [[ -n "$req_conflicts" ]]; then
            echo -e "\n内容级冲突 (REQ-xxx):"
            echo -e "$req_conflicts"
        fi

        exit 1
    fi

    log_pass "无冲突，可以暂存"
    exit 0
}

main "$@"
