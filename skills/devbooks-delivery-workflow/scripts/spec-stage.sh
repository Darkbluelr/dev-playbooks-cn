#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/spec-stage.sh
# 规格暂存脚本
#
# 将变更包的 spec delta 同步到暂存层。
#
# 用法：
#   ./spec-stage.sh <change-id> [选项]
#   ./spec-stage.sh --help
#
# 退出码：
#   0 - 暂存成功
#   1 - 暂存失败（有冲突）
#   2 - 用法错误

set -euo pipefail

VERSION="1.0.0"

project_root="."
change_root="changes"
truth_root="specs"
dry_run=false
force=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
规格暂存脚本 (spec-stage.sh)

用法：
  ./spec-stage.sh <change-id> [选项]

选项：
  --project-root DIR  项目根目录
  --change-root DIR   变更包目录
  --truth-root DIR    真理源目录
  --dry-run           模拟运行，不实际修改文件
  --force             强制暂存，忽略冲突
  --help, -h          显示帮助

退出码：
  0 - 暂存成功
  1 - 暂存失败
  2 - 用法错误

EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }

main() {
    local change_id=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_help; exit 0 ;;
            --version|-v) echo "spec-stage.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --change-root) change_root="${2:-changes}"; shift 2 ;;
            --truth-root) truth_root="${2:-specs}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --force) force=true; shift ;;
            -*) log_error "未知选项: $1"; exit 2 ;;
            *) change_id="$1"; shift ;;
        esac
    done

    if [[ -z "$change_id" ]]; then
        log_error "缺少 change-id"
        exit 2
    fi

    local change_dir="${project_root}/${change_root}/${change_id}"
    local staged_dir="${project_root}/${truth_root}/_staged/${change_id}"
    local specs_delta_dir="${change_dir}/specs"

    log_info "暂存变更包: ${change_id}"

    if [[ ! -d "$specs_delta_dir" ]]; then
        log_info "无 spec delta，跳过暂存"
        exit 0
    fi

    # 调用 spec-preview 检查冲突
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ "$force" != true && -x "${script_dir}/spec-preview.sh" ]]; then
        if ! "${script_dir}/spec-preview.sh" "$change_id" --project-root "$project_root" --change-root "$change_root" --truth-root "$truth_root"; then
            log_error "存在冲突，使用 --force 强制暂存"
            exit 1
        fi
    fi

    # 执行暂存
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] 将创建: ${staged_dir}"
        log_info "[DRY-RUN] 将复制: ${specs_delta_dir}/* -> ${staged_dir}/"
    else
        mkdir -p "$staged_dir"
        cp -r "$specs_delta_dir"/* "$staged_dir"/
        log_pass "已暂存到: ${staged_dir}"
    fi

    exit 0
}

main "$@"
