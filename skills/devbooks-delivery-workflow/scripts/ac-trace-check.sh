#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/ac-trace-check.sh
# AC-ID 追溯覆盖率检查脚本
#
# 检查 AC-ID 从设计到测试的追溯覆盖率。
#
# 用法：
#   ./ac-trace-check.sh <change-id> [选项]
#   ./ac-trace-check.sh --help
#
# 选项：
#   --threshold N       覆盖率阈值（默认 80）
#   --output FORMAT     输出格式（text|json，默认 text）
#   --project-root DIR  项目根目录
#   --change-root DIR   变更包目录
#
# 退出码：
#   0 - 覆盖率达标
#   1 - 覆盖率未达标
#   2 - 用法错误

set -euo pipefail

# 版本
VERSION="1.0.0"

# 默认值
threshold=80
output_format="text"
project_root="."
change_root="changes"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助
show_help() {
    cat << 'EOF'
AC-ID 追溯覆盖率检查脚本 (ac-trace-check.sh)

用法：
  ./ac-trace-check.sh <change-id> [选项]

选项：
  --threshold N       覆盖率阈值，默认 80（百分比）
  --output FORMAT     输出格式：text | json，默认 text
  --project-root DIR  项目根目录，默认为当前目录
  --change-root DIR   变更包目录，默认为 changes
  --help, -h          显示此帮助信息
  --version, -v       显示版本信息

算法：
  1. 从 design.md 提取所有 AC-xxx
  2. 从 tasks.md 提取任务中引用的 AC-xxx
  3. 从 tests/ 提取测试标记的 AC-xxx
  4. 计算：覆盖率 = (已追溯 AC 数) / (总 AC 数) × 100%
  5. 对比阈值，返回退出码

退出码：
  0 - 覆盖率达标
  1 - 覆盖率未达标
  2 - 用法错误

示例：
  ./ac-trace-check.sh my-feature                     # 默认检查
  ./ac-trace-check.sh my-feature --threshold 90     # 90% 阈值
  ./ac-trace-check.sh my-feature --output json      # JSON 输出
  ./ac-trace-check.sh my-feature --change-root dev-playbooks/changes

EOF
}

# 显示版本
show_version() {
    echo "ac-trace-check.sh v${VERSION}"
}

# 日志函数
log_info() {
    [[ "$output_format" == "text" ]] && echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_pass() {
    [[ "$output_format" == "text" ]] && echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    [[ "$output_format" == "text" ]] && echo -e "${RED}[FAIL]${NC} $*"
}

log_warn() {
    [[ "$output_format" == "text" ]] && echo -e "${YELLOW}[WARN]${NC} $*"
}

# 提取 AC-ID
extract_ac_ids() {
    local file="$1"
    grep -oE "AC-[A-Z0-9]+" "$file" 2>/dev/null | sort -u || true
}

# 从目录提取 AC-ID
extract_ac_ids_from_dir() {
    local dir="$1"
    local pattern="${2:-*.test.*}"
    find "$dir" -type f \( -name "*.test.ts" -o -name "*.test.js" -o -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.bats" -o -name "*_test.py" -o -name "*_test.go" \) 2>/dev/null | while read -r file; do
        grep -oE "AC-[A-Z0-9]+" "$file" 2>/dev/null || true
    done | sort -u
}

# 计算覆盖率
calculate_coverage() {
    local design_acs="$1"
    local tasks_acs="$2"
    local test_acs="$3"

    # 获取 AC 列表
    local design_list=()
    local tasks_list=()
    local test_list=()
    local covered_list=()
    local uncovered_list=()

    while IFS= read -r ac; do
        [[ -n "$ac" ]] && design_list+=("$ac")
    done <<< "$design_acs"

    while IFS= read -r ac; do
        [[ -n "$ac" ]] && tasks_list+=("$ac")
    done <<< "$tasks_acs"

    while IFS= read -r ac; do
        [[ -n "$ac" ]] && test_list+=("$ac")
    done <<< "$test_acs"

    local total=${#design_list[@]}

    if [[ $total -eq 0 ]]; then
        # 没有 AC，算作 100% 覆盖
        echo "100 0 0"
        return
    fi

    # 计算覆盖的 AC
    local covered=0
    for ac in "${design_list[@]}"; do
        local in_test=false
        for test_ac in "${test_list[@]}"; do
            if [[ "$ac" == "$test_ac" ]]; then
                in_test=true
                covered_list+=("$ac")
                break
            fi
        done
        if [[ "$in_test" == false ]]; then
            uncovered_list+=("$ac")
        else
            covered=$((covered + 1))
        fi
    done

    local rate=0
    if [[ $total -gt 0 ]]; then
        rate=$((covered * 100 / total))
    fi

    echo "$rate $covered $total"

    # 输出未覆盖列表到 stderr
    if [[ ${#uncovered_list[@]} -gt 0 && "$output_format" == "text" ]]; then
        echo "uncovered: ${uncovered_list[*]}" >&2
    fi
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
            --threshold)
                threshold="${2:-80}"
                shift 2
                ;;
            --output)
                output_format="${2:-text}"
                shift 2
                ;;
            --project-root)
                project_root="${2:-.}"
                shift 2
                ;;
            --change-root)
                change_root="${2:-changes}"
                shift 2
                ;;
            -*)
                echo "error: unknown option: $1" >&2
                echo "Use --help for usage" >&2
                exit 2
                ;;
            *)
                change_id="$1"
                shift
                ;;
        esac
    done

    # 验证参数
    if [[ -z "$change_id" ]]; then
        echo "error: missing change-id" >&2
        echo "Use --help for usage" >&2
        exit 2
    fi

    # 构建路径
    local change_dir
    if [[ "$change_root" = /* ]]; then
        change_dir="${change_root}/${change_id}"
    else
        change_dir="${project_root}/${change_root}/${change_id}"
    fi

    local design_file="${change_dir}/design.md"
    local tasks_file="${change_dir}/tasks.md"
    local tests_dir="${project_root}/tests"

    log_info "检查变更包: ${change_id}"
    log_info "设计文件: ${design_file}"
    log_info "任务文件: ${tasks_file}"
    log_info "测试目录: ${tests_dir}"

    # 检查文件存在
    if [[ ! -f "$design_file" ]]; then
        if [[ "$output_format" == "json" ]]; then
            echo '{"error": "design.md not found", "coverage": 0}'
        else
            log_fail "design.md 不存在: ${design_file}"
        fi
        exit 1
    fi

    # 提取 AC-ID
    local design_acs tasks_acs test_acs

    design_acs=$(extract_ac_ids "$design_file")
    tasks_acs=""
    if [[ -f "$tasks_file" ]]; then
        tasks_acs=$(extract_ac_ids "$tasks_file")
    fi

    test_acs=""
    if [[ -d "$tests_dir" ]]; then
        test_acs=$(extract_ac_ids_from_dir "$tests_dir")
    fi

    # 计算覆盖率
    local result
    result=$(calculate_coverage "$design_acs" "$tasks_acs" "$test_acs")
    read -r rate covered total <<< "$result"

    # 输出结果
    if [[ "$output_format" == "json" ]]; then
        local uncovered_json="[]"
        # 重新计算未覆盖列表
        local uncovered_acs=""
        while IFS= read -r ac; do
            [[ -z "$ac" ]] && continue
            if ! echo "$test_acs" | grep -qx "$ac"; then
                if [[ -z "$uncovered_acs" ]]; then
                    uncovered_acs="\"$ac\""
                else
                    uncovered_acs="${uncovered_acs},\"$ac\""
                fi
            fi
        done <<< "$design_acs"

        cat << EOF
{
  "change_id": "${change_id}",
  "coverage": ${rate},
  "threshold": ${threshold},
  "covered": ${covered},
  "total": ${total},
  "uncovered": [${uncovered_acs}],
  "pass": $([ "$rate" -ge "$threshold" ] && echo "true" || echo "false")
}
EOF
    else
        echo ""
        echo "AC 追溯覆盖率报告"
        echo "================"
        echo "变更包: ${change_id}"
        echo "总 AC 数: ${total}"
        echo "已覆盖: ${covered}"
        echo "覆盖率: ${rate}%"
        echo "阈值: ${threshold}%"
        echo ""

        if [[ $rate -ge $threshold ]]; then
            log_pass "覆盖率 ${rate}% >= ${threshold}%，检查通过"
            exit 0
        else
            log_fail "覆盖率 ${rate}% < ${threshold}%，检查失败"
            exit 1
        fi
    fi

    # JSON 模式下的退出码
    if [[ $rate -ge $threshold ]]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main "$@"
