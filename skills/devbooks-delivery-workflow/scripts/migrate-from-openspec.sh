#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/migrate-to-devbooks-2.sh
# OpenSpec → DevBooks 2.0 迁移脚本
#
# 将 dev-playbooks/ 目录结构迁移到 dev-playbooks/。
# 支持幂等执行、状态检查点、引用更新。
#
# 用法：
#   ./migrate-to-devbooks-2.sh [选项]
#   ./migrate-to-devbooks-2.sh --help
#
# 退出码：
#   0 - 迁移成功
#   1 - 迁移失败
#   2 - 用法错误

set -euo pipefail

VERSION="1.0.0"

# 默认配置
project_root="."
dry_run=false
keep_old=false
force=false
checkpoint_file=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
OpenSpec → DevBooks 2.0 迁移脚本 (migrate-to-devbooks-2.sh)

用法：
  ./migrate-to-devbooks-2.sh [选项]

选项：
  --project-root DIR  项目根目录（默认：当前目录）
  --dry-run           模拟运行，不实际修改文件
  --keep-old          迁移后保留 dev-playbooks/ 目录
  --force             强制重新执行所有步骤（忽略检查点）
  --help, -h          显示帮助

迁移步骤：
  1. [STRUCTURE] 创建 dev-playbooks/ 目录结构
  2. [CONTENT]   迁移 specs/ 和 changes/ 内容
  3. [CONFIG]    创建/更新 .devbooks/config.yaml
  4. [REFS]      更新所有文档中的路径引用
  5. [CLEANUP]   清理（可选保留旧目录）

特性：
  - 幂等执行：可安全重复运行
  - 状态检查点：支持断点续做
  - 引用更新：自动批量替换路径
  - 回滚支持：配合 migrate-from-openspec.sh 使用

EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# 检查点管理
init_checkpoint() {
    checkpoint_file="${project_root}/.devbooks/.migrate-checkpoint"
    if [[ "$force" == true ]]; then
        rm -f "$checkpoint_file" 2>/dev/null || true
    fi
}

save_checkpoint() {
    local step="$1"
    if [[ "$dry_run" == false ]]; then
        mkdir -p "$(dirname "$checkpoint_file")"
        echo "$step" >> "$checkpoint_file"
    fi
}

is_step_done() {
    local step="$1"
    if [[ -f "$checkpoint_file" ]]; then
        grep -qx "$step" "$checkpoint_file" 2>/dev/null
        return $?
    fi
    return 1
}

# 步骤1：创建目录结构
step_structure() {
    log_step "1. 创建目录结构"

    if is_step_done "STRUCTURE" && [[ "$force" == false ]]; then
        log_info "目录结构已创建（跳过）"
        return 0
    fi

    local dirs=(
        "dev-playbooks"
        "dev-playbooks/specs"
        "dev-playbooks/specs/_meta"
        "dev-playbooks/specs/_meta/anti-patterns"
        "dev-playbooks/specs/_staged"
        "dev-playbooks/specs/architecture"
        "dev-playbooks/changes"
        "dev-playbooks/changes/archive"
        "dev-playbooks/scripts"
    )

    for dir in "${dirs[@]}"; do
        local full_path="${project_root}/${dir}"
        if [[ ! -d "$full_path" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] mkdir -p $full_path"
            else
                mkdir -p "$full_path"
            fi
        fi
    done

    save_checkpoint "STRUCTURE"
    log_pass "目录结构创建完成"
}

# 步骤2：迁移内容
step_content() {
    log_step "2. 迁移内容"

    if is_step_done "CONTENT" && [[ "$force" == false ]]; then
        log_info "内容已迁移（跳过）"
        return 0
    fi

    local openspec_dir="${project_root}/openspec"

    if [[ ! -d "$openspec_dir" ]]; then
        log_warn "dev-playbooks/ 目录不存在，跳过内容迁移"
        save_checkpoint "CONTENT"
        return 0
    fi

    # 迁移 specs/
    if [[ -d "${openspec_dir}/specs" ]]; then
        log_info "迁移 specs/ ..."
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp -r ${openspec_dir}/specs/* ${project_root}/dev-playbooks/specs/"
        else
            cp -r "${openspec_dir}/specs/"* "${project_root}/dev-playbooks/specs/" 2>/dev/null || true
        fi
    fi

    # 迁移 changes/
    if [[ -d "${openspec_dir}/changes" ]]; then
        log_info "迁移 changes/ ..."
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp -r ${openspec_dir}/changes/* ${project_root}/dev-playbooks/changes/"
        else
            cp -r "${openspec_dir}/changes/"* "${project_root}/dev-playbooks/changes/" 2>/dev/null || true
        fi
    fi

    # 迁移 project.md
    if [[ -f "${openspec_dir}/project.md" ]]; then
        log_info "迁移 project.md ..."
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp ${openspec_dir}/project.md ${project_root}/dev-playbooks/project.md"
        else
            cp "${openspec_dir}/project.md" "${project_root}/dev-playbooks/project.md" 2>/dev/null || true
        fi
    fi

    save_checkpoint "CONTENT"
    log_pass "内容迁移完成"
}

# 步骤3：创建/更新配置
step_config() {
    log_step "3. 创建/更新配置"

    if is_step_done "CONFIG" && [[ "$force" == false ]]; then
        log_info "配置已更新（跳过）"
        return 0
    fi

    local config_dir="${project_root}/.devbooks"
    local config_file="${config_dir}/config.yaml"

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] 创建/更新 ${config_file}"
    else
        mkdir -p "$config_dir"

        # 如果配置文件不存在或需要更新
        if [[ ! -f "$config_file" ]] || grep -q "root: dev-playbooks/" "$config_file" 2>/dev/null; then
            cat > "$config_file" << 'YAML'
# DevBooks 2.0 配置
# 由 migrate-to-devbooks-2.sh 生成

root: dev-playbooks/
constitution: constitution.md
project: project.md

paths:
  specs: specs/
  changes: changes/
  staged: specs/_staged/
  archive: changes/archive/

constraints:
  require_constitution: true
  allow_legacy_protocol: false

fitness:
  mode: warn
  rules_file: specs/architecture/fitness-rules.md

tracing:
  coverage_threshold: 80
  evidence_dir: evidence/
YAML
        fi
    fi

    save_checkpoint "CONFIG"
    log_pass "配置更新完成"
}

# 步骤4：更新引用
step_refs() {
    log_step "4. 更新路径引用"

    if is_step_done "REFS" && [[ "$force" == false ]]; then
        log_info "引用已更新（跳过）"
        return 0
    fi

    local files_updated=0

    # 查找需要更新的文件
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # 跳过二进制文件和 .git 目录
        [[ "$file" == *".git"* ]] && continue
        [[ "$file" == *".png" ]] && continue
        [[ "$file" == *".jpg" ]] && continue
        [[ "$file" == *".ico" ]] && continue

        # 检查是否包含 dev-playbooks/ 引用
        if grep -q "dev-playbooks/" "$file" 2>/dev/null; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] 更新引用: $file"
            else
                # macOS 兼容的 sed
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' 's|dev-playbooks/|dev-playbooks/|g' "$file"
                else
                    sed -i 's|dev-playbooks/|dev-playbooks/|g' "$file"
                fi
            fi
            files_updated=$((files_updated + 1))
        fi
    done < <(find "${project_root}" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.ts" -o -name "*.js" -o -name "*.json" \) 2>/dev/null)

    save_checkpoint "REFS"
    log_pass "已更新 ${files_updated} 个文件的引用"
}

# 步骤5：清理
step_cleanup() {
    log_step "5. 清理"

    if is_step_done "CLEANUP" && [[ "$force" == false ]]; then
        log_info "清理已完成（跳过）"
        return 0
    fi

    local openspec_dir="${project_root}/openspec"

    if [[ "$keep_old" == true ]]; then
        log_info "保留 dev-playbooks/ 目录（--keep-old）"
    elif [[ -d "$openspec_dir" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] rm -rf $openspec_dir"
        else
            # 创建备份
            local backup_dir="${project_root}/.devbooks/backup/openspec-$(date +%Y%m%d%H%M%S)"
            mkdir -p "$(dirname "$backup_dir")"
            mv "$openspec_dir" "$backup_dir"
            log_info "已备份 dev-playbooks/ 到 ${backup_dir}"
        fi
    fi

    save_checkpoint "CLEANUP"
    log_pass "清理完成"
}

# 验证迁移结果
verify_migration() {
    log_step "验证迁移结果"

    local errors=0

    # 检查目录结构
    local required_dirs=(
        "dev-playbooks"
        "dev-playbooks/specs"
        "dev-playbooks/changes"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "${project_root}/${dir}" ]]; then
            log_error "缺少目录: $dir"
            errors=$((errors + 1))
        fi
    done

    # 检查配置文件
    if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
        log_error "缺少配置文件: .devbooks/config.yaml"
        errors=$((errors + 1))
    fi

    # 检查残留引用（仅警告）
    local remaining_refs
    remaining_refs=$(grep -r "dev-playbooks/" "${project_root}" --include="*.md" --include="*.yaml" --include="*.sh" 2>/dev/null | grep -v ".devbooks/backup" | wc -l || echo "0")
    if [[ "$remaining_refs" -gt 0 ]]; then
        log_warn "仍有 ${remaining_refs} 处 dev-playbooks/ 引用"
    fi

    if [[ "$errors" -eq 0 ]]; then
        log_pass "迁移验证通过"
        return 0
    else
        log_error "迁移验证失败，${errors} 个错误"
        return 1
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_help; exit 0 ;;
            --version|-v) echo "migrate-to-devbooks-2.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --keep-old) keep_old=true; shift ;;
            --force) force=true; shift ;;
            -*) log_error "未知选项: $1"; exit 2 ;;
            *) log_error "未知参数: $1"; exit 2 ;;
        esac
    done

    log_info "OpenSpec → DevBooks 2.0 迁移"
    log_info "项目根目录: ${project_root}"
    [[ "$dry_run" == true ]] && log_info "模式: DRY-RUN"
    [[ "$force" == true ]] && log_info "模式: FORCE"

    init_checkpoint

    # 执行迁移步骤
    step_structure
    step_content
    step_config
    step_refs
    step_cleanup

    # 验证
    if [[ "$dry_run" == false ]]; then
        verify_migration
    fi

    log_pass "迁移完成！"
    exit 0
}

main "$@"
