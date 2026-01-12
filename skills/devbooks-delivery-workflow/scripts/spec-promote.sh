#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/spec-promote.sh
# 规格提升脚本
#
# 将暂存层的 spec delta 提升到真理层。
#
# 用法：
#   ./spec-promote.sh <change-id> [选项]
#   ./spec-promote.sh --help
#
# 退出码：
#   0 - 提升成功
#   1 - 提升失败
#   2 - 用法错误

set -euo pipefail

VERSION="1.0.0"

project_root="."
truth_root="specs"
dry_run=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
规格提升脚本 (spec-promote.sh)

用法：
  ./spec-promote.sh <change-id> [选项]

选项：
  --project-root DIR  项目根目录
  --truth-root DIR    真理源目录
  --dry-run           模拟运行
  --help, -h          显示帮助

流程：
  1. 检查前置条件（已 stage）
  2. 移动 _staged/<change-id>/ 内容到 specs/
  3. 清理 _staged/<change-id>/ 目录

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
            --version|-v) echo "spec-promote.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --truth-root) truth_root="${2:-specs}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            -*) log_error "未知选项: $1"; exit 2 ;;
            *) change_id="$1"; shift ;;
        esac
    done

    if [[ -z "$change_id" ]]; then
        log_error "缺少 change-id"
        exit 2
    fi

    local staged_dir="${project_root}/${truth_root}/_staged/${change_id}"
    local specs_dir="${project_root}/${truth_root}"

    log_info "提升变更包: ${change_id}"

    # 检查前置条件
    if [[ ! -d "$staged_dir" ]]; then
        log_error "未找到暂存内容: ${staged_dir}"
        log_error "请先运行 spec-stage.sh"
        exit 1
    fi

    # 提升文件
    local promoted=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local relative_path="${file#$staged_dir/}"
        local target_path="${specs_dir}/${relative_path}"
        local target_dir
        target_dir=$(dirname "$target_path")

        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] ${relative_path} -> ${target_path}"
        else
            mkdir -p "$target_dir"
            cp "$file" "$target_path"
        fi
        promoted=$((promoted + 1))
    done < <(find "$staged_dir" -type f 2>/dev/null)

    # 清理暂存目录
    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] 将删除: ${staged_dir}"
    else
        rm -rf "$staged_dir"
    fi

    log_pass "已提升 ${promoted} 个文件到真理层"
    exit 0
}

main "$@"
