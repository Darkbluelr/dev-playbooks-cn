#!/bin/bash
# scripts/config-discovery.sh (devbooks)
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

# 读取顶层标量（不裁剪尾部斜杠，不做路径化处理）
get_yaml_top_scalar_raw() {
    local file="$1" key="$2"
    awk -v k="$key" '
        $0 ~ "^" k ":[[:space:]]*" {
            line=$0
            sub("^[^:]*:[[:space:]]*", "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            gsub(/["'"'"']/, "", line)
            print line
            exit
        }
    ' "$file" 2>/dev/null || true
}

# 读取顶层 bool（true/false）
get_yaml_top_bool() {
    local file="$1" key="$2"
    local v
    v="$(get_yaml_top_scalar_raw "$file" "$key")"
    case "$v" in
        true|false) printf '%s' "$v" ;;
        "") printf '%s' "" ;;
        *) printf '%s' "" ;;
    esac
}

# 读取嵌套 bool：parent.key（true/false）
get_yaml_nested_bool() {
    local file="$1" parent="$2" key="$3"
    local v
    v="$(get_yaml_nested_value "$file" "$parent" "$key")"
    case "$v" in
        true|false) printf '%s' "$v" ;;
        "") printf '%s' "" ;;
        *) printf '%s' "" ;;
    esac
}

# 读取顶层列表：key: \n  - item
get_yaml_top_list_csv() {
    local file="$1" key="$2"
    awk -v k="$key" '
        function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
        $0 ~ "^" k ":[[:space:]]*$" { in=1; next }
        in && $0 ~ "^[^[:space:]]" { exit }
        in && $0 ~ "^[[:space:]]*-[[:space:]]*" {
            line=$0
            sub("^[[:space:]]*-[[:space:]]*", "", line)
            line=trim(line)
            gsub(/["'"'"']/, "", line)
            if (line != "") {
                items[count++] = line
            }
        }
        END {
            for (i=0; i<count; i++) {
                if (i>0) printf ","
                printf "%s", items[i]
            }
        }
    ' "$file" 2>/dev/null || true
}

# 读取嵌套列表：parent: \n  key: \n    - item
get_yaml_nested_list_csv() {
    local file="$1" parent="$2" key="$3"
    awk -v p="$parent" -v k="$key" '
        function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
        $0 ~ "^" p ":[[:space:]]*$" { in_parent=1; next }
        in_parent && /^[^[:space:]]/ { in_parent=0; in_list=0 }
        in_parent && $0 ~ "^  " k ":[[:space:]]*$" { in_list=1; next }
        in_list && $0 ~ "^  [^[:space:]]" { in_list=0 }
        in_list && $0 ~ "^[[:space:]]*-[[:space:]]*" {
            line=$0
            sub("^[[:space:]]*-[[:space:]]*", "", line)
            line=trim(line)
            gsub(/["'"'"']/, "", line)
            if (line != "") items[count++] = line
        }
        END {
            for (i=0; i<count; i++) {
                if (i>0) printf ","
                printf "%s", items[i]
            }
        }
    ' "$file" 2>/dev/null || true
}

# 读取顶层 map：key: \n  a: b
get_yaml_top_map_json() {
    local file="$1" key="$2"
    awk -v k="$key" '
        function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
        function esc(s){
            gsub(/\\/,"\\\\",s)
            gsub(/"/,"\\\"",s)
            gsub(/\r/,"",s)
            return s
        }
        $0 ~ "^" k ":[[:space:]]*$" { in=1; next }
        in && $0 ~ "^[^[:space:]]" { exit }
        in && $0 ~ "^  [A-Za-z0-9_.-]+:[[:space:]]*" {
            line=$0
            sub("^  ","", line)
            split(line, parts, ":")
            key=trim(parts[1])
            value=line
            sub("^[^:]*:[[:space:]]*", "", value)
            value=trim(value)
            gsub(/["'"'"']/, "", value)
            if (key != "") {
                keys[count]=key
                values[count]=value
                count++
            }
        }
        END {
            printf "{"
            for (i=0; i<count; i++) {
                if (i>0) printf ","
                printf "\"%s\":\"%s\"", esc(keys[i]), esc(values[i])
            }
            printf "}"
        }
    ' "$file" 2>/dev/null || true
}

shell_quote_single() {
    # 单引号安全包裹：foo'bar -> 'foo'\''bar'
    local s="${1:-}"
    printf "'%s'" "${s//\'/\'\\\'\'}"
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
# 新格式输出（Dev-Playbooks）
# ============================================

output_config_v2() {
    local config_root="$1"

    # v2 稳定字段（供脚本/测试夹具使用）：顺序固定
    # 注意：这些字段是“协议合同”，不可随意改名/改顺序。
    local specs_path="specs"
    local changes_path="changes"
    local staged_path="specs/_staged"
    local require_constitution="true"
    local fitness_mode="warn"
    local coverage_threshold="80"

    # 扩展字段（AI Native Framework）
    local gate_profile="standard"
    local model_profile="default"
    local model_capacity_factor="1.0"
    local void_enabled="false"
    local enabled_packs_csv=""
    local platform_targets_csv=""
    local slice_limits_json="{}"
    local truth_mapping_json="{}"
    local skill_injection_csv=""

    if [[ -f "${PROJECT_ROOT}/.devbooks/config.yaml" ]]; then
        specs_path=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "paths" "specs")
        changes_path=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "paths" "changes")
        staged_path=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "paths" "staged")
        require_constitution=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "constraints" "require_constitution")
        fitness_mode=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "fitness" "mode")
        coverage_threshold=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "tracing" "coverage_threshold")

        gate_profile="$(get_yaml_top_scalar_raw "${PROJECT_ROOT}/.devbooks/config.yaml" "gate_profile")"
        model_profile="$(get_yaml_top_scalar_raw "${PROJECT_ROOT}/.devbooks/config.yaml" "model_profile")"
        model_capacity_factor="$(get_yaml_top_scalar_raw "${PROJECT_ROOT}/.devbooks/config.yaml" "model_capacity_factor")"
        void_enabled="$(get_yaml_nested_bool "${PROJECT_ROOT}/.devbooks/config.yaml" "void" "enabled")"
        enabled_packs_csv="$(get_yaml_nested_list_csv "${PROJECT_ROOT}/.devbooks/config.yaml" "extensions" "enabled_packs")"
        platform_targets_csv="$(get_yaml_top_list_csv "${PROJECT_ROOT}/.devbooks/config.yaml" "platform_targets")"
        slice_limits_json="$(get_yaml_top_map_json "${PROJECT_ROOT}/.devbooks/config.yaml" "slice_limits")"
        truth_mapping_json="$(get_yaml_top_map_json "${PROJECT_ROOT}/.devbooks/config.yaml" "truth_mapping")"
        skill_injection_csv="$(get_yaml_top_list_csv "${PROJECT_ROOT}/.devbooks/config.yaml" "skill_injection")"
    fi

    # defaults + normalize
    specs_path="${specs_path:-specs/}"
    changes_path="${changes_path:-changes/}"
    staged_path="${staged_path:-specs/_staged/}"
    require_constitution="${require_constitution:-true}"
    fitness_mode="${fitness_mode:-warn}"
    coverage_threshold="${coverage_threshold:-80}"

    specs_path="${specs_path%/}"
    changes_path="${changes_path%/}"
    staged_path="${staged_path%/}"

    echo "CONFIG_VERSION=2"
    echo "ROOT=${config_root}"
    echo "CONSTITUTION_LOADED=true"
    echo "SPECS_DIR=${config_root}/${specs_path}"
    echo "CHANGES_DIR=${config_root}/${changes_path}"
    echo "SCRIPTS_DIR=${config_root}/scripts"
    echo "REQUIRE_CONSTITUTION=${require_constitution}"
    echo "FITNESS_ENABLED=true"
    echo "FITNESS_MODE=${fitness_mode}"
    echo "AC_COVERAGE_THRESHOLD=${coverage_threshold}"
    echo "GATE_PROFILE=${gate_profile:-standard}"
    echo "MODEL_PROFILE=${model_profile:-default}"
    echo "MODEL_CAPACITY_FACTOR=${model_capacity_factor:-1.0}"
    echo "VOID_ENABLED=${void_enabled:-false}"
    echo "EXTENSIONS_ENABLED_PACKS_CSV=${enabled_packs_csv}"
    echo "PLATFORM_TARGETS_CSV=${platform_targets_csv}"
    echo "SLICE_LIMITS_JSON=$(shell_quote_single "${slice_limits_json:-{}}")"
    echo "TRUTH_MAPPING_JSON=$(shell_quote_single "${truth_mapping_json:-{}}")"
    echo "SKILL_INJECTION_CSV=${skill_injection_csv}"

    echo ""

    # 向后兼容：保留旧字段（供人类阅读/调试）
    echo "# Dev-Playbooks Configuration"
    echo "devbooks_version=2.0"
    echo "config_root=${config_root}"
    echo "specs_dir=${config_root}/${specs_path}/"
    echo "changes_dir=${config_root}/${changes_path}/"
    echo "staged_dir=${config_root}/${staged_path}/"

    if [[ -f "${PROJECT_ROOT}/.devbooks/config.yaml" ]]; then
        local fitness_rules
        fitness_rules=$(get_yaml_nested_value "${PROJECT_ROOT}/.devbooks/config.yaml" "fitness" "rules_file")
        echo "fitness_rules=${config_root}/${fitness_rules:-specs/architecture/fitness-rules.md}"
        echo "ac_coverage_threshold=${coverage_threshold}"
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
