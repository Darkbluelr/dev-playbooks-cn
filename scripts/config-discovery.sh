#!/bin/bash
# scripts/config-discovery.sh
# DevBooks Protocol Discovery Layer - 配置发现脚本
#
# 用途：发现并输出当前项目的 DevBooks 配置
# 返回格式：key=value（每行一个），可被 Shell 或 AI 解析
#
# 优先级：
#   1. .devbooks/config.yaml（优先检查 root: dev-playbooks/）
#   2. dev-playbooks/（无 config.yaml 时）
#   3. project.md（通用模板协议）
#
# 用法：
#   ./config-discovery.sh [project-root]
#   source <(./config-discovery.sh)  # 直接导入为 shell 变量
#
# 功能：
#   - 支持 dev-playbooks/ 路径
#   - 自动加载 constitution.md
#   - 纯 Bash YAML 解析（无 yq 依赖）
#   - 弃用警告：truth_root/change_root 别名（建议迁移到 paths.specs/paths.changes）

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# 颜色输出（仅在 stderr）
log_info() { echo "[INFO] $*" >&2; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

# ============================================
# 纯 Bash YAML 解析（无 yq 依赖）
# ============================================

# 读取简单键值对
get_yaml_value() {
    local file="$1" key="$2"
    grep "^${key}:" "$file" 2>/dev/null | sed 's/^[^:]*: *//' | tr -d '"'"'" | tr -d '/' || true
}

# 读取嵌套键（一层深度）
get_yaml_nested_value() {
    local file="$1" parent="$2" key="$3"
    # 查找 parent: 下的 key:
    awk -v parent="$parent" -v key="$key" '
        $0 ~ "^" parent ":" { in_parent = 1; next }
        in_parent && /^[a-z]/ { in_parent = 0 }
        in_parent && $0 ~ "^  " key ":" {
            gsub(/^[^:]*: */, "")
            gsub(/["'"'"']/, "")
            print
            exit
        }
    ' "$file" 2>/dev/null || true
}

# ============================================
# 解析真理根目录
# ============================================

resolve_truth_root() {
    local root="$1"

    # 从 config.yaml 读取 root 配置
    if [[ -f "${root}/.devbooks/config.yaml" ]]; then
        local config_root
        config_root=$(get_yaml_value "${root}/.devbooks/config.yaml" "root")
        if [[ -n "$config_root" && -d "${root}/${config_root}" ]]; then
            echo "${config_root}"
            return 0
        fi
    fi

    # 检查 dev-playbooks/ 目录
    if [[ -d "${root}/dev-playbooks" ]]; then
        echo "dev-playbooks"
        return 0
    fi

    # 未找到
    echo ""
    return 1
}

# ============================================
# 加载宪法
# ============================================

load_constitution() {
    local config_root="$1"
    local constitution_file="${PROJECT_ROOT}/${config_root}/constitution.md"

    if [[ -f "$constitution_file" ]]; then
        log_info "Loading constitution from: $constitution_file"
        echo "constitution_loaded=true"
        echo "constitution_path=${config_root}/constitution.md"
        return 0
    else
        # 检查是否强制要求宪法
        local require_constitution="false"
        if [[ -f "${PROJECT_ROOT}/.devbooks/config.yaml" ]]; then
            require_constitution=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "constraints" "require_constitution")
        fi

        if [[ "$require_constitution" == "true" ]]; then
            log_error "Constitution file missing: $constitution_file"
            echo "constitution_loaded=false"
            echo "constitution_path="
            echo "constitution_error=missing"
            return 1
        fi

        log_warn "Constitution file not found (optional): $constitution_file"
        echo "constitution_loaded=false"
        echo "constitution_path="
        return 0
    fi
}

# ============================================
# 检查文件是否存在
# ============================================

check_file() {
    [[ -f "$PROJECT_ROOT/$1" ]]
}

# ============================================
# 输出配置
# ============================================

output_config() {
    echo "config_source=$1"
    echo "protocol=$2"
    echo "truth_root=$3"
    echo "change_root=$4"
    echo "agents_doc=$5"

    # 可选字段
    [[ -n "${6:-}" ]] && echo "project_profile=$6"
    [[ -n "${7:-}" ]] && echo "apply_requires_role=$7"
}

# ============================================
# 新格式输出（DevBooks 2.0）
# ============================================

output_config_v2() {
    local config_root="$1"

    echo "# DevBooks 2.0 Configuration"
    echo "devbooks_version=2.0"
    echo "config_root=${config_root}"

    # 从 config.yaml 读取路径配置
    if [[ -f "${PROJECT_ROOT}/.devbooks/config.yaml" ]]; then
        local specs_path changes_path staged_path
        specs_path=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "paths" "specs")
        changes_path=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "paths" "changes")
        staged_path=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "paths" "staged")

        echo "specs_dir=${config_root}/${specs_path:-specs/}"
        echo "changes_dir=${config_root}/${changes_path:-changes/}"
        echo "staged_dir=${config_root}/${staged_path:-specs/_staged/}"
    else
        echo "specs_dir=${config_root}/specs/"
        echo "changes_dir=${config_root}/changes/"
        echo "staged_dir=${config_root}/specs/_staged/"
    fi

    # 适应度配置
    if [[ -f "${PROJECT_ROOT}/.devbooks/config.yaml" ]]; then
        local fitness_mode fitness_rules
        fitness_mode=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "fitness" "mode")
        fitness_rules=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "fitness" "rules_file")

        echo "fitness_mode=${fitness_mode:-warn}"
        echo "fitness_rules=${config_root}/${fitness_rules:-specs/architecture/fitness-rules.md}"
    fi

    # AC 追溯配置
    if [[ -f "${PROJECT_ROOT}/.devbooks/config.yaml" ]]; then
        local coverage_threshold
        coverage_threshold=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "tracing" "coverage_threshold")
        echo "ac_coverage_threshold=${coverage_threshold:-80}"
    fi
}

# ============================================
# 主逻辑
# ============================================

main() {
    # 解析真理根目录
    local truth_root
    truth_root=$(resolve_truth_root "$PROJECT_ROOT") || {
        log_warn "No DevBooks configuration found"
        log_warn "Searched for:"
        log_warn "  - .devbooks/config.yaml with root: dev-playbooks/"
        log_warn "  - dev-playbooks/"
        log_warn "  - dev-playbooks/project.md"
        log_warn "  - project.md"

        echo "config_source=none"
        echo "protocol=unknown"
        echo "truth_root="
        echo "change_root="
        echo "agents_doc="

        exit 1
    }

    log_info "Found configuration root: $truth_root"

    # 加载宪法（如果存在）
    load_constitution "$truth_root" || {
        log_error "Constitution loading failed"
        exit 1
    }

    # 根据目录判断协议类型
    case "$truth_root" in
        dev-playbooks)
            # DevBooks 协议
            log_info "Using DevBooks protocol"

            output_config \
                ".devbooks/config.yaml" \
                "devbooks" \
                "${truth_root}/specs/" \
                "${truth_root}/changes/" \
                "${truth_root}/project.md" \
                "${truth_root}/specs/_meta/project-profile.md" \
                "true"

            echo ""
            output_config_v2 "$truth_root"
            ;;

        *)
            # Template 协议
            log_info "Using template protocol"

            output_config \
                "project.md" \
                "template" \
                "specs/" \
                "changes/" \
                "project.md" \
                "specs/_meta/project-profile.md" \
                "false"
            ;;
    esac

    exit 0
}

# 运行主函数
main
