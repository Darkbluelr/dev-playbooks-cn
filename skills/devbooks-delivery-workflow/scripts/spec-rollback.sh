#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/spec-rollback.sh
# 规格回滚脚本
#
# 回滚规格同步操作。
#
# 用法：
#   ./spec-rollback.sh <change-id> [选项]
#   ./spec-rollback.sh --help
#
# 退出码：
#   0 - 回滚成功
#   1 - 回滚失败
#   2 - 用法错误

set -euo pipefail

VERSION="1.0.0"

project_root="."
truth_root="specs"
change_root="changes"
target="staged"
dry_run=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
规格回滚脚本 (spec-rollback.sh)

用法：
  ./spec-rollback.sh <change-id> [选项]

选项：
  --project-root DIR  项目根目录
  --truth-root DIR    真理源目录
  --change-root DIR   变更包目录
  --target TARGET     回滚目标：staged | draft
  --dry-run           模拟运行
  --help, -h          显示帮助

回滚目标：
  staged - 清理暂存层（保留变更包中的 spec delta）
  draft  - 回滚到变更包状态（清理暂存层，不动 specs）

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
            --version|-v) echo "spec-rollback.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --truth-root) truth_root="${2:-specs}"; shift 2 ;;
            --change-root) change_root="${2:-changes}"; shift 2 ;;
            --target) target="${2:-staged}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            -*) log_error "未知选项: $1"; exit 2 ;;
            *) change_id="$1"; shift ;;
        esac
    done

    if [[ -z "$change_id" ]]; then
        log_error "缺少 change-id"
        exit 2
    fi

    case "$target" in
        staged|draft) ;;
        *) log_error "无效的回滚目标: $target"; exit 2 ;;
    esac

    local staged_dir="${project_root}/${truth_root}/_staged/${change_id}"

    log_info "回滚变更包: ${change_id}"
    log_info "回滚目标: ${target}"

    case "$target" in
        staged)
            # 清理暂存层
            if [[ -d "$staged_dir" ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] 将删除: ${staged_dir}"
                else
                    rm -rf "$staged_dir"
                    log_pass "已清理暂存层: ${staged_dir}"
                fi
            else
                log_info "暂存层为空，无需清理"
            fi
            ;;

        draft)
            # 回滚到变更包状态（清理暂存层）
            if [[ -d "$staged_dir" ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] 将删除: ${staged_dir}"
                else
                    rm -rf "$staged_dir"
                    log_pass "已回滚到 draft 状态"
                fi
            else
                log_info "已在 draft 状态"
            fi
            ;;
    esac

    exit 0
}

main "$@"
