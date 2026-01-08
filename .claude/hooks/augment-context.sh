#!/bin/bash
# Augment-style context injection hook
# 在用户提交时自动检测意图并注入上下文

set -e

# 读取 stdin 的 JSON 输入
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# 如果没有 prompt，直接退出
if [ -z "$PROMPT" ]; then
  echo '{}'
  exit 0
fi

# 代码意图检测（简化版）
is_code_intent() {
  local query="$1"
  # 代码相关关键词
  if echo "$query" | grep -qiE '修复|fix|bug|错误|重构|refactor|优化|添加|新增|实现|implement|删除|remove|修改|update|分析|analyze|影响|impact|引用|reference|调用|call|依赖|depend|\.ts|\.tsx|\.js|\.py|\.go|src/|lib/'; then
    return 0
  fi
  # 非代码意图排除
  if echo "$query" | grep -qiE '天气|weather|翻译|translate|写邮件|email|闲聊|chat'; then
    return 1
  fi
  return 1
}

# 获取热点文件
get_hotspots() {
  local cwd="${WORKING_DIRECTORY:-$(pwd)}"
  if [ -d "$cwd/.git" ]; then
    git -C "$cwd" log --since="30 days ago" --name-only --pretty=format: 2>/dev/null | \
      grep -v '^$' | \
      grep -vE 'node_modules|dist|build|\.lock' | \
      sort | uniq -c | sort -rn | head -5 | \
      awk '{print "  🔥 " $2 " (" $1 " changes)"}' || true
  fi
}

# 检查 SCIP 索引
check_index() {
  local cwd="${WORKING_DIRECTORY:-$(pwd)}"
  if [ -f "$cwd/index.scip" ]; then
    local age_hours=$(( ($(date +%s) - $(stat -f %m "$cwd/index.scip" 2>/dev/null || stat -c %Y "$cwd/index.scip" 2>/dev/null)) / 3600 ))
    if [ "$age_hours" -gt 24 ]; then
      echo "⚠️ SCIP 索引已过期（${age_hours}h），建议更新"
    else
      echo "✅ SCIP 索引可用，图分析已启用"
    fi
  else
    echo "⚠️ SCIP 索引不存在，使用 devbooks_ensure_index 生成"
  fi
}

# 主逻辑
if is_code_intent "$PROMPT"; then
  INDEX_STATUS=$(check_index)
  HOTSPOTS=$(get_hotspots)

  CONTEXT="[DevBooks 自动上下文注入]

$INDEX_STATUS"

  if [ -n "$HOTSPOTS" ]; then
    CONTEXT="$CONTEXT

🔥 热点文件（近30天高频修改）：
$HOTSPOTS"
  fi

  CONTEXT="$CONTEXT

💡 推荐：
  - 使用 mcp__ckb__analyzeImpact 分析影响
  - 使用 mcp__ckb__findReferences 查找引用
  - 修改热点文件时增加测试覆盖"

  # 输出 JSON，additionalContext 会被注入到提示词中
  jq -n --arg ctx "$CONTEXT" '{"additionalContext": $ctx}'
else
  echo '{}'
fi
