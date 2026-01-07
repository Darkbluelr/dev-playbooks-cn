#!/bin/bash
# DevBooks 子图缓存管理脚本
# 用途：缓存常用的 CKB MCP 查询结果，减少重复查询

set -e

CACHE_DIR=".devbooks/cache/graph"
CACHE_TTL=3600  # 默认缓存 1 小时（秒）

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[Cache]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[Cache]${NC} $1"; }

# 参数解析
ACTION=""
KEY=""
VALUE=""
TTL=$CACHE_TTL

while [[ $# -gt 0 ]]; do
    case $1 in
        get|set|clear|status|warm) ACTION="$1"; shift ;;
        --key) KEY="$2"; shift 2 ;;
        --value) VALUE="$2"; shift 2 ;;
        --ttl) TTL="$2"; shift 2 ;;
        --project-root) cd "$2"; shift 2 ;;
        -h|--help)
            echo "用法: graph-cache.sh <action> [options]"
            echo ""
            echo "Actions:"
            echo "  get     获取缓存"
            echo "  set     设置缓存"
            echo "  clear   清除缓存"
            echo "  status  显示缓存状态"
            echo "  warm    预热缓存"
            echo ""
            echo "Options:"
            echo "  --key <name>      缓存键名"
            echo "  --value <data>    缓存值"
            echo "  --ttl <seconds>   缓存过期时间 (默认: 3600)"
            echo "  --project-root    项目根目录"
            exit 0
            ;;
        *) shift ;;
    esac
done

# 确保缓存目录存在
mkdir -p "$CACHE_DIR"

# 计算缓存文件路径
get_cache_file() {
    local key="$1"
    local hash=$(echo "$key" | md5sum | cut -d' ' -f1)
    echo "$CACHE_DIR/${hash}.json"
}

# 检查缓存是否有效
is_cache_valid() {
    local cache_file="$1"
    local ttl="${2:-$CACHE_TTL}"

    if [ ! -f "$cache_file" ]; then
        return 1
    fi

    local file_age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null) ))

    if [ $file_age -gt $ttl ]; then
        return 1
    fi

    return 0
}

# 获取缓存
cache_get() {
    local cache_file=$(get_cache_file "$KEY")

    if is_cache_valid "$cache_file" "$TTL"; then
        cat "$cache_file"
        return 0
    else
        return 1
    fi
}

# 设置缓存
cache_set() {
    local cache_file=$(get_cache_file "$KEY")

    # 创建缓存元数据
    cat > "$cache_file" << EOF
{
  "key": "$KEY",
  "timestamp": $(date +%s),
  "ttl": $TTL,
  "data": $VALUE
}
EOF

    echo_info "已缓存: $KEY"
}

# 清除缓存
cache_clear() {
    if [ -n "$KEY" ]; then
        local cache_file=$(get_cache_file "$KEY")
        rm -f "$cache_file"
        echo_info "已清除: $KEY"
    else
        rm -rf "$CACHE_DIR"/*
        echo_info "已清除所有缓存"
    fi
}

# 显示缓存状态
cache_status() {
    echo "=== DevBooks 子图缓存状态 ==="
    echo ""

    if [ ! -d "$CACHE_DIR" ] || [ -z "$(ls -A "$CACHE_DIR" 2>/dev/null)" ]; then
        echo "缓存为空"
        return
    fi

    local total=0
    local valid=0
    local expired=0

    echo "| 键 | 大小 | 年龄 | 状态 |"
    echo "|-----|------|------|------|"

    for cache_file in "$CACHE_DIR"/*.json; do
        if [ -f "$cache_file" ]; then
            total=$((total + 1))

            local size=$(du -h "$cache_file" | cut -f1)
            local age=$(( ($(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null)) ))
            local age_min=$((age / 60))

            local key=$(jq -r '.key // "unknown"' "$cache_file" 2>/dev/null || echo "unknown")
            local ttl=$(jq -r '.ttl // 3600' "$cache_file" 2>/dev/null || echo 3600)

            local status="✅ 有效"
            if [ $age -gt $ttl ]; then
                status="❌ 过期"
                expired=$((expired + 1))
            else
                valid=$((valid + 1))
            fi

            # 截断长键名
            if [ ${#key} -gt 30 ]; then
                key="${key:0:27}..."
            fi

            echo "| $key | $size | ${age_min}m | $status |"
        fi
    done

    echo ""
    echo "总计: $total 个缓存, $valid 有效, $expired 过期"
}

# 预热缓存（常用查询）
cache_warm() {
    echo_info "预热缓存..."

    # 检查 SCIP 索引是否存在
    if [ ! -f "index.scip" ]; then
        echo_warn "SCIP 索引不存在，无法预热图缓存"
        return 1
    fi

    # 缓存常用查询结果
    # 注意：实际的 MCP 调用需要在 Claude Code 中执行
    # 这里只是创建缓存占位符和清理过期缓存

    # 清理过期缓存
    for cache_file in "$CACHE_DIR"/*.json; do
        if [ -f "$cache_file" ]; then
            if ! is_cache_valid "$cache_file"; then
                rm -f "$cache_file"
                echo_info "清理过期: $(basename "$cache_file")"
            fi
        fi
    done

    echo_info "缓存预热完成"
    echo ""
    echo "提示：在 Claude Code 中使用以下命令预热常用查询："
    echo "  - mcp__ckb__getArchitecture(depth=2)"
    echo "  - mcp__ckb__getHotspots(limit=20)"
    echo "  - mcp__ckb__listKeyConcepts(limit=12)"
}

# 主逻辑
case "$ACTION" in
    get) cache_get ;;
    set) cache_set ;;
    clear) cache_clear ;;
    status) cache_status ;;
    warm) cache_warm ;;
    *)
        echo "请指定操作: get, set, clear, status, warm"
        echo "使用 -h 查看帮助"
        exit 1
        ;;
esac
