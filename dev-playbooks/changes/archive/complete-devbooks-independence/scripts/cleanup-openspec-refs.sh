#!/bin/bash
# cleanup-openspec-refs.sh - 批量清理 OpenSpec 引用
#
# 用法：
#   cleanup-openspec-refs.sh [--dry-run] [--verbose]
#
# 功能：
#   1. 删除 setup/openspec/ 目录
#   2. 删除 .claude/commands/openspec/ 目录
#   3. 删除 dev-playbooks/specs/openspec-integration/ 目录
#   4. 删除 rollback-to-openspec.sh 脚本
#   5. 更新文件中的 OpenSpec 引用
#
# 输出：修改的文件列表和行数

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 参数
DRY_RUN=false
VERBOSE=false

# 统计
DIRS_DELETED=0
FILES_MODIFIED=0
FILES_DELETED=0
LINES_CHANGED=0

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "用法: cleanup-openspec-refs.sh [--dry-run] [--verbose]"
            echo ""
            echo "选项:"
            echo "  --dry-run   预览模式，不实际修改文件"
            echo "  --verbose   输出详细日志"
            echo "  -h, --help  显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# 检测项目根目录
detect_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.devbooks/config.yaml" ]] || [[ -d "$dir/dev-playbooks" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

PROJECT_ROOT=$(detect_project_root)
log "项目根目录: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

if [[ "$DRY_RUN" == true ]]; then
    log_warn "DRY-RUN 模式：不会实际修改任何文件"
fi

# === 阶段 1：删除目录 ===
log ""
log "=== 阶段 1：删除目录 ==="

delete_directory() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        local file_count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
        log "删除目录: $dir ($file_count 个文件)"
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$dir"
        fi
        ((DIRS_DELETED++))
        ((FILES_DELETED+=file_count))
    else
        log_verbose "目录不存在，跳过: $dir"
    fi
}

# 删除 setup/openspec/
delete_directory "setup/openspec"

# 删除 .claude/commands/openspec/
delete_directory ".claude/commands/openspec"

# 删除 dev-playbooks/specs/openspec-integration/
delete_directory "dev-playbooks/specs/openspec-integration"

# === 阶段 2：删除文件 ===
log ""
log "=== 阶段 2：删除文件 ==="

delete_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        log "删除文件: $file"
        if [[ "$DRY_RUN" == false ]]; then
            rm -f "$file"
        fi
        ((FILES_DELETED++))
    else
        log_verbose "文件不存在，跳过: $file"
    fi
}

# 删除 rollback-to-openspec.sh
delete_file "skills/devbooks-delivery-workflow/scripts/rollback-to-openspec.sh"

# === 阶段 3：更新文件引用 ===
log ""
log "=== 阶段 3：更新文件引用 ==="

# 定义替换规则
# 格式: "旧文本|新文本"
declare -a REPLACEMENTS=(
    # 目录路径替换
    "openspec/specs/|dev-playbooks/specs/"
    "openspec/changes/|dev-playbooks/changes/"
    "openspec/project.md|dev-playbooks/project.md"
    "openspec/AGENTS.md|AGENTS.md"
    # 配置键替换
    "truth_root: openspec/|paths.specs: dev-playbooks/specs/"
    "change_root: openspec/changes/|paths.changes: dev-playbooks/changes/"
    "protocol: openspec|# protocol: devbooks (legacy openspec removed)"
    # Slash 命令替换
    "/devbooks-openspec-proposal|/devbooks:proposal"
    "/devbooks-openspec-apply|/devbooks:apply"
    "/devbooks-openspec-archive|/devbooks:archive"
    "devbooks-openspec-|devbooks-"
    # 品牌名称替换（保留历史引用）
    "OpenSpec 协议|DevBooks 协议"
    "OpenSpec 集成|DevBooks 集成"
    "OpenSpec 目录|dev-playbooks 目录"
)

# 需要处理的文件模式
FILE_PATTERNS=("*.md" "*.sh" "*.yaml" "*.yml" "*.js" "*.json")

# 排除的目录
EXCLUDE_DIRS=(".git" "node_modules" "backup" "changes" ".devbooks/backup")

# 构建 find 排除参数
FIND_EXCLUDE=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    FIND_EXCLUDE="$FIND_EXCLUDE -path '*/$dir/*' -prune -o"
done

# 查找需要处理的文件
log "搜索包含 OpenSpec 引用的文件..."
TARGET_FILES=$(eval "find . $FIND_EXCLUDE -type f \( -name '*.md' -o -name '*.sh' -o -name '*.yaml' -o -name '*.yml' -o -name '*.js' \) -print" 2>/dev/null | sort)

for file in $TARGET_FILES; do
    # 跳过已删除的目录中的文件
    [[ "$file" == *"setup/openspec"* ]] && continue
    [[ "$file" == *".claude/commands/openspec"* ]] && continue
    [[ "$file" == *"specs/openspec-integration"* ]] && continue

    # 检查文件是否包含 openspec 引用
    if ! grep -qi "openspec" "$file" 2>/dev/null; then
        continue
    fi

    log_verbose "处理文件: $file"

    # 计算该文件中的引用数
    local_refs=$(grep -ci "openspec" "$file" 2>/dev/null || echo "0")

    if [[ "$DRY_RUN" == true ]]; then
        log "  将修改: $file ($local_refs 处引用)"
        ((LINES_CHANGED+=local_refs))
        ((FILES_MODIFIED++))
    else
        # 创建临时文件
        tmp_file=$(mktemp)
        cp "$file" "$tmp_file"

        # 应用替换规则
        for replacement in "${REPLACEMENTS[@]}"; do
            old_text="${replacement%%|*}"
            new_text="${replacement#*|}"
            # 使用 sed 进行替换（兼容 macOS 和 Linux）
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s|${old_text}|${new_text}|g" "$tmp_file" 2>/dev/null || true
            else
                sed -i "s|${old_text}|${new_text}|g" "$tmp_file" 2>/dev/null || true
            fi
        done

        # 检查是否有变化
        if ! diff -q "$file" "$tmp_file" > /dev/null 2>&1; then
            mv "$tmp_file" "$file"
            log "  已修改: $file ($local_refs 处引用)"
            ((LINES_CHANGED+=local_refs))
            ((FILES_MODIFIED++))
        else
            rm "$tmp_file"
            log_verbose "  无变化: $file"
        fi
    fi
done

# === 阶段 4：清理空目录 ===
log ""
log "=== 阶段 4：清理空目录 ==="

if [[ "$DRY_RUN" == false ]]; then
    # 清理可能留下的空目录
    find setup -type d -empty -delete 2>/dev/null || true
    find .claude/commands -type d -empty -delete 2>/dev/null || true
fi

# === 统计报告 ===
log ""
log "=== 清理完成 ==="
log "删除目录: $DIRS_DELETED 个"
log "删除文件: $FILES_DELETED 个"
log "修改文件: $FILES_MODIFIED 个"
log "变更行数: $LINES_CHANGED 行（估算）"

if [[ "$DRY_RUN" == true ]]; then
    log ""
    log_warn "这是预览模式。要实际执行，请去掉 --dry-run 参数。"
fi

# === 验证 ===
log ""
log "=== 验证 ==="
remaining=$(grep -rn "openspec\|OpenSpec" . --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" --include="*.js" 2>/dev/null | grep -v backup | grep -v changes | grep -v "\.git" | wc -l | tr -d ' ')

if [[ "$remaining" -eq 0 ]]; then
    log "✅ AC-001 通过: 无 OpenSpec 引用残留"
else
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "当前仍有 $remaining 处 OpenSpec 引用（预览模式）"
    else
        log_error "❌ 仍有 $remaining 处 OpenSpec 引用，请检查"
        exit 1
    fi
fi
