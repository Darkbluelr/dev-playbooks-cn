#!/bin/bash
# DevBooks COD 模型增量更新脚本
# 用途：持久化并增量更新代码地图产物（模块依赖图、热点、领域概念）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[COD]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[COD]${NC} $1"; }
echo_error() { echo -e "${RED}[COD]${NC} $1"; }

# 参数解析
PROJECT_ROOT="."
TRUTH_ROOT=""
FORCE=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        --truth-root) TRUTH_ROOT="$2"; shift 2 ;;
        --force) FORCE=true; shift ;;
        --quiet) QUIET=true; shift ;;
        -h|--help)
            echo "用法: cod-update.sh [options]"
            echo ""
            echo "Options:"
            echo "  --project-root <dir>  项目根目录 (默认: .)"
            echo "  --truth-root <dir>    真理目录 (自动检测)"
            echo "  --force               强制全量更新"
            echo "  --quiet               静默模式"
            exit 0
            ;;
        *) echo_error "未知参数: $1"; exit 1 ;;
    esac
done

cd "$PROJECT_ROOT"

# 自动检测 truth-root
if [ -z "$TRUTH_ROOT" ]; then
    if [ -f "dev-playbooks/project.md" ]; then
        TRUTH_ROOT="dev-playbooks/specs"
    elif [ -f ".devbooks/config.yaml" ]; then
        TRUTH_ROOT=$(grep 'truth_root:' .devbooks/config.yaml | awk '{print $2}' | tr -d '"' || echo "specs")
    else
        TRUTH_ROOT="specs"
    fi
fi

# 确保目录存在
mkdir -p "$TRUTH_ROOT/architecture"
mkdir -p "$TRUTH_ROOT/_meta"
mkdir -p ".devbooks/cache/cod"

# 缓存文件路径
CACHE_DIR=".devbooks/cache/cod"
HASH_FILE="$CACHE_DIR/source-hash.txt"
ARCHITECTURE_CACHE="$CACHE_DIR/architecture.json"
HOTSPOTS_CACHE="$CACHE_DIR/hotspots.json"
CONCEPTS_CACHE="$CACHE_DIR/concepts.json"

# 计算源文件 hash（用于检测变更）
calculate_source_hash() {
    # 只计算源代码文件的 hash，忽略 node_modules 等
    find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
        -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" ! -path "*/build/*" \
        -exec md5sum {} \; 2>/dev/null | sort | md5sum | cut -d' ' -f1
}

# 检查是否需要更新
needs_update() {
    if [ "$FORCE" = true ]; then
        return 0
    fi

    if [ ! -f "$HASH_FILE" ]; then
        return 0
    fi

    local old_hash=$(cat "$HASH_FILE")
    local new_hash=$(calculate_source_hash)

    if [ "$old_hash" != "$new_hash" ]; then
        return 0
    fi

    # 检查产物是否存在
    if [ ! -f "$TRUTH_ROOT/architecture/module-graph.md" ]; then
        return 0
    fi

    return 1
}

# 使用 CKB MCP 获取架构（如果可用）
fetch_architecture_via_mcp() {
    # 检查 CKB 是否可用（通过检查 index.scip）
    if [ ! -f "index.scip" ]; then
        echo_warn "SCIP 索引不存在，跳过图基架构分析"
        return 1
    fi

    # 这里无法直接调用 MCP，但可以检查缓存
    if [ -f "$ARCHITECTURE_CACHE" ]; then
        local cache_age=$(( ($(date +%s) - $(stat -f%m "$ARCHITECTURE_CACHE" 2>/dev/null || stat -c%Y "$ARCHITECTURE_CACHE" 2>/dev/null)) ))
        if [ $cache_age -lt 3600 ]; then  # 1小时内的缓存有效
            echo_info "使用缓存的架构数据"
            return 0
        fi
    fi

    return 1
}

# 基于文件系统生成模块依赖图（降级方案）
generate_module_graph_fallback() {
    local output="$TRUTH_ROOT/architecture/module-graph.md"
    local temp_file=$(mktemp)

    echo_info "生成模块依赖图（文件系统分析）..."

    cat > "$temp_file" << 'EOF'
# 模块依赖图

> 自动生成于 $(date +%Y-%m-%d)，基于文件系统分析

## 目录结构

```
EOF

    # 生成目录树
    if command -v tree &> /dev/null; then
        tree -d -L 3 -I 'node_modules|.git|dist|build|__pycache__|.venv|vendor' >> "$temp_file" 2>/dev/null || true
    else
        find . -type d -maxdepth 3 \
            ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
            ! -path "*/build/*" ! -path "*/__pycache__/*" ! -path "*/.venv/*" \
            2>/dev/null | head -50 >> "$temp_file"
    fi

    echo '```' >> "$temp_file"
    echo "" >> "$temp_file"

    # 分析导入关系
    echo "## 主要依赖关系" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "| 模块 | 依赖数 | 被依赖数 |" >> "$temp_file"
    echo "|------|--------|----------|" >> "$temp_file"

    # TypeScript/JavaScript 项目
    if [ -f "package.json" ]; then
        for dir in src lib app; do
            if [ -d "$dir" ]; then
                local import_count=$(grep -r "^import\|^from" "$dir" 2>/dev/null | wc -l || echo 0)
                local export_count=$(grep -r "^export" "$dir" 2>/dev/null | wc -l || echo 0)
                echo "| \`$dir/\` | $import_count | $export_count |" >> "$temp_file"
            fi
        done
    fi

    # Python 项目
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        for dir in src lib app; do
            if [ -d "$dir" ]; then
                local import_count=$(grep -r "^import\|^from" "$dir" --include="*.py" 2>/dev/null | wc -l || echo 0)
                echo "| \`$dir/\` | $import_count | - |" >> "$temp_file"
            fi
        done
    fi

    echo "" >> "$temp_file"
    echo "---" >> "$temp_file"

    # 只在内容变化时更新
    if [ -f "$output" ]; then
        if ! diff -q "$temp_file" "$output" > /dev/null 2>&1; then
            mv "$temp_file" "$output"
            echo_info "模块依赖图已更新: $output"
        else
            rm "$temp_file"
            [ "$QUIET" = false ] && echo_info "模块依赖图无变化"
        fi
    else
        mv "$temp_file" "$output"
        echo_info "模块依赖图已创建: $output"
    fi
}

# 生成热点文件报告
generate_hotspots() {
    local output="$TRUTH_ROOT/architecture/hotspots.md"
    local temp_file=$(mktemp)

    echo_info "生成技术债热点..."

    cat > "$temp_file" << EOF
# 技术债热点

> 自动生成于 $(date +%Y-%m-%d)
> 热点分数 = 变更频率 × 复杂度估算

## 高频变更文件（近 30 天）

| 文件 | 变更次数 | 行数 | 风险等级 |
|------|----------|------|----------|
EOF

    # 使用 Git 历史分析
    if [ -d ".git" ]; then
        git log --since="30 days ago" --name-only --pretty=format: 2>/dev/null | \
            grep -v '^$' | \
            grep -v 'node_modules\|dist\|build\|\.lock\|package-lock' | \
            sort | uniq -c | sort -rn | head -15 | \
            while read count file; do
                if [ -f "$file" ]; then
                    local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
                    local risk="🟢 Normal"
                    if [ $count -gt 10 ] && [ $lines -gt 300 ]; then
                        risk="🔴 Critical"
                    elif [ $count -gt 5 ] && [ $lines -gt 200 ]; then
                        risk="🟡 High"
                    fi
                    echo "| \`$file\` | $count | $lines | $risk |"
                fi
            done >> "$temp_file"
    else
        echo "| (无 Git 历史) | - | - | - |" >> "$temp_file"
    fi

    echo "" >> "$temp_file"
    echo "## 大文件（潜在复杂度）" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "| 文件 | 行数 |" >> "$temp_file"
    echo "|------|------|" >> "$temp_file"

    find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
        ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
        -exec wc -l {} \; 2>/dev/null | \
        sort -rn | head -10 | \
        while read lines file; do
            echo "| \`$file\` | $lines |"
        done >> "$temp_file"

    # 只在内容变化时更新
    if [ -f "$output" ]; then
        # 比较时忽略日期行
        if ! diff <(tail -n +4 "$temp_file") <(tail -n +4 "$output") > /dev/null 2>&1; then
            mv "$temp_file" "$output"
            echo_info "热点报告已更新: $output"
        else
            rm "$temp_file"
            [ "$QUIET" = false ] && echo_info "热点报告无变化"
        fi
    else
        mv "$temp_file" "$output"
        echo_info "热点报告已创建: $output"
    fi
}

# 生成领域概念（基于命名分析）
generate_key_concepts() {
    local output="$TRUTH_ROOT/_meta/key-concepts.md"
    local temp_file=$(mktemp)

    echo_info "生成领域概念..."

    cat > "$temp_file" << EOF
# 领域概念（Key Concepts）

> 自动生成于 $(date +%Y-%m-%d)
> 基于代码命名模式分析

## 核心类/接口

| 概念 | 出现次数 | 典型位置 |
|------|----------|----------|
EOF

    # 提取 PascalCase 命名（类名）
    grep -rho '\b[A-Z][a-z]*[A-Z][a-zA-Z]*\b' \
        --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" --include="*.go" \
        . 2>/dev/null | \
        grep -v 'node_modules\|dist\|build' | \
        sort | uniq -c | sort -rn | head -15 | \
        while read count name; do
            local location=$(grep -rl "\b$name\b" --include="*.ts" --include="*.py" . 2>/dev/null | head -1 || echo "-")
            echo "| \`$name\` | $count | \`$location\` |"
        done >> "$temp_file"

    echo "" >> "$temp_file"
    echo "## 常见动词（操作）" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "| 动词 | 出现次数 |" >> "$temp_file"
    echo "|------|----------|" >> "$temp_file"

    # 提取函数名中的动词
    grep -rho '\b\(get\|set\|create\|update\|delete\|fetch\|save\|load\|process\|handle\|validate\)[A-Za-z]*\b' \
        --include="*.ts" --include="*.js" --include="*.py" \
        . 2>/dev/null | \
        grep -v 'node_modules' | \
        sed 's/[A-Z]/ /g' | awk '{print tolower($1)}' | \
        sort | uniq -c | sort -rn | head -10 | \
        while read count verb; do
            echo "| \`$verb\` | $count |"
        done >> "$temp_file"

    # 只在内容变化时更新
    if [ -f "$output" ]; then
        if ! diff <(tail -n +4 "$temp_file") <(tail -n +4 "$output") > /dev/null 2>&1; then
            mv "$temp_file" "$output"
            echo_info "领域概念已更新: $output"
        else
            rm "$temp_file"
            [ "$QUIET" = false ] && echo_info "领域概念无变化"
        fi
    else
        mv "$temp_file" "$output"
        echo_info "领域概念已创建: $output"
    fi
}

# 主流程
main() {
    if needs_update; then
        echo_info "检测到代码变更，更新 COD 产物..."

        # 尝试使用 MCP，否则降级
        if ! fetch_architecture_via_mcp; then
            generate_module_graph_fallback
        fi

        generate_hotspots
        generate_key_concepts

        # 保存新的 hash
        calculate_source_hash > "$HASH_FILE"

        echo_info "COD 产物更新完成"
    else
        [ "$QUIET" = false ] && echo_info "代码无变更，跳过更新"
    fi
}

main
