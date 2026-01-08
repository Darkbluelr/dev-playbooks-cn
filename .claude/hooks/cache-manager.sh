#!/bin/bash
# DevBooks Hook 缓存管理工具

CACHE_DIR="${TMPDIR:-/tmp}/.devbooks-cache"

show_usage() {
  cat << EOF
用法: $0 [命令]

命令:
  stats     显示缓存统计
  clean     清理所有缓存
  prune     清理过期缓存（1天以上）
  inspect   检查缓存内容
  help      显示此帮助信息

示例:
  $0 stats        # 查看缓存统计
  $0 clean        # 清空所有缓存
  $0 prune        # 只删除过期缓存
EOF
}

show_stats() {
  if [ ! -d "$CACHE_DIR" ]; then
    echo "缓存目录不存在: $CACHE_DIR"
    return
  fi

  echo "================================"
  echo "DevBooks Hook 缓存统计"
  echo "================================"
  echo "缓存目录: $CACHE_DIR"
  echo ""

  # 文件数
  local file_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "缓存文件数: $file_count"

  # 总大小
  if command -v du &>/dev/null; then
    local total_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    echo "总大小: $total_size"
  fi

  # 最老的文件
  if [ "$file_count" -gt 0 ]; then
    echo ""
    echo "最老的缓存文件:"
    find "$CACHE_DIR" -type f -exec ls -lt {} + 2>/dev/null | tail -1 | awk '{print "  " $6" "$7" "$8" "$9}'
  fi

  # 最新的文件
  if [ "$file_count" -gt 0 ]; then
    echo ""
    echo "最新的缓存文件:"
    find "$CACHE_DIR" -type f -exec ls -lt {} + 2>/dev/null | head -2 | tail -1 | awk '{print "  " $6" "$7" "$8" "$9}'
  fi

  # 按类型分组（基于文件名前缀推测）
  echo ""
  echo "缓存类型分布:"
  echo "  符号提取缓存: $(grep -l "symbols:" "$CACHE_DIR"/* 2>/dev/null | wc -l | tr -d ' ')"
  echo "  搜索结果缓存: $(grep -l "search:" "$CACHE_DIR"/* 2>/dev/null | wc -l | tr -d ' ')"
  echo "  热点文件缓存: $(grep -l "hotspots:" "$CACHE_DIR"/* 2>/dev/null | wc -l | tr -d ' ')"
}

clean_cache() {
  if [ ! -d "$CACHE_DIR" ]; then
    echo "缓存目录不存在，无需清理"
    return
  fi

  local file_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$file_count" -eq 0 ]; then
    echo "缓存已经是空的"
    return
  fi

  echo "即将删除 $file_count 个缓存文件"
  read -p "确认删除？(y/N) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$CACHE_DIR"
    mkdir -p "$CACHE_DIR"
    echo "✅ 缓存已清理"
  else
    echo "❌ 操作已取消"
  fi
}

prune_cache() {
  if [ ! -d "$CACHE_DIR" ]; then
    echo "缓存目录不存在，无需清理"
    return
  fi

  echo "清理 1 天以上的过期缓存..."

  local before_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')

  find "$CACHE_DIR" -type f -mtime +1 -delete 2>/dev/null

  local after_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
  local deleted=$((before_count - after_count))

  echo "✅ 删除了 $deleted 个过期文件"
  echo "剩余 $after_count 个有效缓存文件"
}

inspect_cache() {
  if [ ! -d "$CACHE_DIR" ]; then
    echo "缓存目录不存在"
    return
  fi

  local file_count=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$file_count" -eq 0 ]; then
    echo "缓存为空"
    return
  fi

  echo "最近的 5 个缓存文件内容:"
  echo "================================"

  find "$CACHE_DIR" -type f -exec ls -t {} + 2>/dev/null | head -5 | while read -r file; do
    echo ""
    echo "文件: $(basename "$file")"
    echo "时间: $(ls -l "$file" | awk '{print $6" "$7" "$8}')"
    echo "大小: $(ls -lh "$file" | awk '{print $5}')"
    echo "内容预览:"
    head -5 "$file" 2>/dev/null | sed 's/^/  /'
    echo "..."
    echo "--------------------------------"
  done
}

# 主逻辑
case "${1:-help}" in
  stats)
    show_stats
    ;;
  clean)
    clean_cache
    ;;
  prune)
    prune_cache
    ;;
  inspect)
    inspect_cache
    ;;
  help|--help|-h)
    show_usage
    ;;
  *)
    echo "未知命令: $1"
    echo ""
    show_usage
    exit 1
    ;;
esac
