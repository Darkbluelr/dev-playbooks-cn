#!/bin/bash
# scripts/config-discovery.sh
# DevBooks Protocol Discovery Layer - 配置发现脚本
#
# 用途：发现并输出当前项目的 DevBooks 配置
# 返回格式：key=value（每行一个），可被 Shell 或 AI 解析
#
# 优先级：
#   1. .devbooks/config.yaml
#   2. openspec/project.md（存在即为 OpenSpec 协议）
#   3. project.md（通用模板协议）
#
# 用法：
#   ./config-discovery.sh [project-root]
#   source <(./config-discovery.sh)  # 直接导入为 shell 变量

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# 颜色输出（仅在 stderr）
log_info() { echo "[INFO] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }

# 解析 YAML 的简化实现（不依赖 yq）
# 只处理简单的 key: value 格式
parse_yaml_simple() {
    local file="$1"
    grep -E "^[a-z_]+:" "$file" 2>/dev/null | \
        sed 's/: */=/' | \
        sed 's/ *$//' | \
        sed "s/['\"]//g" || true
}

# 检查文件是否存在
check_file() {
    [ -f "$PROJECT_ROOT/$1" ]
}

# 输出配置
output_config() {
    echo "config_source=$1"
    echo "protocol=$2"
    echo "truth_root=$3"
    echo "change_root=$4"
    echo "agents_doc=$5"

    # 可选字段
    [ -n "${6:-}" ] && echo "project_profile=$6"
    [ -n "${7:-}" ] && echo "apply_requires_role=$7"
}

# ============================================
# 优先级 1：.devbooks/config.yaml
# ============================================
if check_file ".devbooks/config.yaml"; then
    log_info "Found .devbooks/config.yaml"

    CONFIG_FILE="$PROJECT_ROOT/.devbooks/config.yaml"

    # 解析配置
    PROTOCOL=$(grep "^protocol:" "$CONFIG_FILE" | sed 's/protocol: *//' | tr -d "'" | tr -d '"' || echo "")
    TRUTH_ROOT=$(grep "^truth_root:" "$CONFIG_FILE" | sed 's/truth_root: *//' | tr -d "'" | tr -d '"' || echo "")
    CHANGE_ROOT=$(grep "^change_root:" "$CONFIG_FILE" | sed 's/change_root: *//' | tr -d "'" | tr -d '"' || echo "")
    AGENTS_DOC=$(grep "^agents_doc:" "$CONFIG_FILE" | sed 's/agents_doc: *//' | tr -d "'" | tr -d '"' || echo "")
    PROJECT_PROFILE=$(grep "^project_profile:" "$CONFIG_FILE" | sed 's/project_profile: *//' | tr -d "'" | tr -d '"' || echo "")

    # 检查 constraints
    APPLY_REQUIRES_ROLE=$(grep "apply_requires_role:" "$CONFIG_FILE" | sed 's/.*apply_requires_role: *//' | tr -d "'" | tr -d '"' || echo "true")

    output_config \
        ".devbooks/config.yaml" \
        "${PROTOCOL:-openspec}" \
        "${TRUTH_ROOT:-openspec/specs/}" \
        "${CHANGE_ROOT:-openspec/changes/}" \
        "${AGENTS_DOC:-openspec/project.md}" \
        "$PROJECT_PROFILE" \
        "$APPLY_REQUIRES_ROLE"

    exit 0
fi

# ============================================
# 优先级 2：openspec/project.md（OpenSpec 协议）
# ============================================
if check_file "openspec/project.md"; then
    log_info "Found openspec/project.md - using OpenSpec protocol"

    # OpenSpec 默认映射
    output_config \
        "openspec/project.md" \
        "openspec" \
        "openspec/specs/" \
        "openspec/changes/" \
        "openspec/project.md" \
        "openspec/specs/_meta/project-profile.md" \
        "true"

    exit 0
fi

# ============================================
# 优先级 3：project.md（通用模板协议）
# ============================================
if check_file "project.md"; then
    log_info "Found project.md - using template protocol"

    # Template 默认映射
    output_config \
        "project.md" \
        "template" \
        "specs/" \
        "changes/" \
        "project.md" \
        "specs/_meta/project-profile.md" \
        "false"

    exit 0
fi

# ============================================
# 未找到配置
# ============================================
log_warn "No DevBooks configuration found"
log_warn "Searched for:"
log_warn "  - .devbooks/config.yaml"
log_warn "  - openspec/project.md"
log_warn "  - project.md"

echo "config_source=none"
echo "protocol=unknown"
echo "truth_root="
echo "change_root="
echo "agents_doc="

exit 1
