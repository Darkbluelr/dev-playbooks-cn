#!/bin/bash
# Augment-style context injection hook v2
# 自动检测意图 + 注入相关代码片段

# 配置
MAX_SNIPPETS=3
MAX_LINES=25

# 读取输入
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
CWD="${WORKING_DIRECTORY:-$(pwd)}"

[ -z "$PROMPT" ] && { echo '{}'; exit 0; }

# ==================== 意图检测 ====================
is_code_intent() {
  echo "$1" | grep -qiE '修复|fix|bug|错误|重构|refactor|优化|添加|新增|实现|implement|删除|remove|修改|update|change|分析|analyze|影响|impact|引用|reference|调用|call|依赖|depend|函数|function|方法|method|类|class|模块|module|\.ts|\.tsx|\.js|\.py|\.go|src/|lib/'
}

is_non_code() {
  echo "$1" | grep -qiE '^(天气|weather|翻译|translate|写邮件|email|闲聊|chat|你好|hello|hi)'
}

# ==================== 符号提取 ====================
extract_symbols() {
  local q="$1"
  {
    # camelCase (如 getUserById)
    echo "$q" | grep -oE '\b[a-z][a-zA-Z0-9]*[A-Z][a-zA-Z0-9]*\b'
    # PascalCase (如 UserService)
    echo "$q" | grep -oE '\b[A-Z][a-zA-Z0-9]*[a-z][a-zA-Z0-9]*\b'
    # 反引号内容
    echo "$q" | grep -oE '\`[^\`]+\`' | tr -d '\`'
    # 文件路径
    echo "$q" | grep -oE '[a-zA-Z0-9_/\-]+\.(ts|tsx|js|jsx|py|go)'
  } | grep -v '^$' | sort -u | head -$MAX_SNIPPETS
}

# ==================== 代码搜索 ====================
search_symbol() {
  local sym="$1"
  [ -z "$sym" ] && return

  if command -v rg &>/dev/null; then
    rg -n -C 4 --max-count=1 \
      -g '!node_modules' -g '!dist' -g '!build' -g '!.git' -g '!*.lock' \
      -g '*.ts' -g '*.tsx' -g '*.js' -g '*.jsx' -g '*.py' -g '*.go' \
      "$sym" "$CWD" 2>/dev/null | head -$MAX_LINES
  else
    grep -rn --include='*.ts' --include='*.js' --include='*.py' \
      -A 3 -B 2 "$sym" "$CWD" 2>/dev/null | \
      grep -v 'node_modules\|dist\|build' | head -$MAX_LINES
  fi
}

# ==================== 热点/索引 ====================
get_hotspots() {
  [ -d "$CWD/.git" ] || return
  git -C "$CWD" log --since="30 days ago" --name-only --pretty=format: 2>/dev/null | \
    grep -v '^$' | grep -vE 'node_modules|dist|build|\.lock|\.md$' | \
    sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "  🔥 %s (%d changes)\n", $2, $1}'
}

check_index() {
  if [ -f "$CWD/index.scip" ]; then
    echo "✅ SCIP 索引可用"
  else
    echo "⚠️ SCIP 索引不存在"
  fi
}

# ==================== 主逻辑 ====================
is_non_code "$PROMPT" && { echo '{}'; exit 0; }
is_code_intent "$PROMPT" || { echo '{}'; exit 0; }

# 构建上下文
CONTEXT="[DevBooks 自动上下文注入]

$(check_index)"

# 搜索代码片段
SNIPPETS=""
SYMBOLS=$(extract_symbols "$PROMPT")

if [ -n "$SYMBOLS" ]; then
  while IFS= read -r symbol; do
    [ -z "$symbol" ] && continue
    snippet=$(search_symbol "$symbol")
    if [ -n "$snippet" ]; then
      SNIPPETS="${SNIPPETS}

🔍 $symbol:
\`\`\`
$snippet
\`\`\`"
    fi
  done <<< "$SYMBOLS"
fi

if [ -n "$SNIPPETS" ]; then
  CONTEXT="${CONTEXT}

📦 相关代码：$SNIPPETS"
fi

# 热点
HOTSPOTS=$(get_hotspots)
[ -n "$HOTSPOTS" ] && CONTEXT="${CONTEXT}

🔥 热点文件：
$HOTSPOTS"

# 工具建议
CONTEXT="${CONTEXT}

💡 可用工具：analyzeImpact / findReferences / getCallGraph"

# 输出
jq -n --arg ctx "$CONTEXT" '{"additionalContext": $ctx}'
