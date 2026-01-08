#!/bin/bash
# augment-context.sh 配置快速参考

# ============================================
# 性能配置参数
# ============================================

# 最大代码片段数（默认: 3）
MAX_SNIPPETS=3

# 最大输出行数（默认: 20）
MAX_LINES=20

# 单个搜索超时（秒，默认: 2）
SEARCH_TIMEOUT=2

# 缓存目录（默认: /tmp/.devbooks-cache）
CACHE_DIR="${TMPDIR:-/tmp}/.devbooks-cache"

# 缓存有效期（秒，默认: 300 = 5分钟）
CACHE_TTL=300

# ============================================
# ripgrep 搜索参数
# ============================================

# 每文件最大匹配数（默认: 1）
--max-count=1

# 跳过大于此大小的文件（默认: 500K）
--max-filesize=500K

# 上下文行数（默认: 3）
-C 3

# ============================================
# 并行搜索配置
# ============================================

# 最大并发搜索数（默认: 3）
# 低性能机器建议: 2
# 高性能机器建议: 5
if [ ${#pids[@]} -ge 3 ]; then

# ============================================
# Git 热点配置
# ============================================

# Git log 最大提交数（默认: 200）
--max-count=200

# 热点文件统计时间范围（默认: 30 天）
--since="30 days ago"

# ============================================
# 常用命令
# ============================================

# 清理缓存
rm -rf "${TMPDIR:-/tmp}/.devbooks-cache"

# 查看缓存统计
ls -lh "${TMPDIR:-/tmp}/.devbooks-cache" | wc -l

# 清理过期缓存（1天以上）
find "${TMPDIR:-/tmp}/.devbooks-cache" -type f -mtime +1 -delete

# 运行性能测试
bash /Users/ozbombor/Projects/dev-playbooks/.claude/hooks/test-performance.sh

# 手动测试单次查询
echo '{"prompt":"your query"}' | WORKING_DIRECTORY=$(pwd) time bash .claude/hooks/augment-context.sh

# ============================================
# 性能调优建议
# ============================================

# 场景 1: 频繁重复查询
# 增加缓存时间
CACHE_TTL=3600  # 1小时

# 场景 2: 代码快速变化
# 减少缓存时间
CACHE_TTL=60    # 1分钟

# 场景 3: 搜索经常超时
# 增加超时时间（但保持总超时 3秒）
SEARCH_TIMEOUT=3

# 场景 4: 需要更多上下文
# 增加行数（会降低性能）
MAX_LINES=30
-C 5

# 场景 5: 低性能机器
# 减少并发和搜索范围
MAX_SNIPPETS=2
if [ ${#pids[@]} -ge 2 ]; then
--max-filesize=300K

# ============================================
# 故障排查
# ============================================

# 问题: Hook 总是超时
# 解决: 检查是否有大文件或深层目录
find . -type f -size +1M | grep -v node_modules

# 问题: 缓存不生效
# 解决: 检查缓存目录权限
ls -ld "${TMPDIR:-/tmp}/.devbooks-cache"

# 问题: 搜索结果不准确
# 解决: 清理缓存重试
rm -rf "${TMPDIR:-/tmp}/.devbooks-cache"

# 问题: 内存占用过高
# 解决: 减少并发数和缓存时间
MAX_SNIPPETS=2
CACHE_TTL=120

# ============================================
# 监控性能
# ============================================

# 查看平均执行时间
for i in {1..5}; do
  echo '{"prompt":"test query"}' | WORKING_DIRECTORY=$(pwd) time bash .claude/hooks/augment-context.sh 2>&1 | grep real
done

# 查看缓存命中率
# 1. 清理缓存
rm -rf "${TMPDIR:-/tmp}/.devbooks-cache"

# 2. 首次执行（应该较慢）
time echo '{"prompt":"test"}' | WORKING_DIRECTORY=$(pwd) bash .claude/hooks/augment-context.sh > /dev/null

# 3. 第二次执行（应该快很多）
time echo '{"prompt":"test"}' | WORKING_DIRECTORY=$(pwd) bash .claude/hooks/augment-context.sh > /dev/null

# ============================================
# 集成 CKB 索引（未来优化）
# ============================================

# 检查 CKB 是否可用
if [ -d "$CWD/.git/ckb" ]; then
  # 使用 CKB API 搜索（更快）
  # TODO: 实现 CKB 集成
fi
