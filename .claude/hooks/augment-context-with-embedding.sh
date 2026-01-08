#!/bin/bash
# Augment-style context injection hook with Embedding support
# 自动检测意图 + 注入相关代码片段（支持语义搜索）

# 配置
MAX_SNIPPETS=3
MAX_LINES=25
USE_EMBEDDING=true  # 是否启用 Embedding 语义搜索

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

# ==================== Embedding 语义搜索 ====================
semantic_search() {
  local query="$1"
  local embedding_script="$CWD/tools/devbooks-embedding.sh"

  # 检查 Embedding 是否可用
  if [ ! -x "$embedding_script" ]; then
    return 1
  fi

  # 检查配置
  local config_file="$CWD/.devbooks/embedding.yaml"
  if [ ! -f "$config_file" ]; then
    return 1
  fi

  # 检查是否启用
  local enabled=$(grep -E "^enabled:" "$config_file" | awk '{print $2}')
  if [ "$enabled" != "true" ]; then
    return 1
  fi

  # 检查索引是否存在
  local vector_db="$CWD/.devbooks/embeddings/index.tsv"
  if [ ! -f "$vector_db" ]; then
    return 1
  fi

  # 执行语义搜索
  PROJECT_ROOT="$CWD" "$embedding_script" search "$query" --top-k 3 2>/dev/null
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
  local status=""

  # 检查 SCIP 索引
  if [ -f "$CWD/index.scip" ]; then
    status="✅ SCIP 索引可用"
  else
    status="⚠️ SCIP 索引不存在"
  fi

  # 检查 Embedding 索引
  if [ -f "$CWD/.devbooks/embeddings/index.tsv" ]; then
    local count=$(wc -l < "$CWD/.devbooks/embeddings/index.tsv" 2>/dev/null || echo 0)
    status="$status | ✅ Embedding 索引 ($count 文件)"
  fi

  echo "$status"
}

# ==================== 主逻辑 ====================
is_non_code "$PROMPT" && { echo '{}'; exit 0; }
is_code_intent "$PROMPT" || { echo '{}'; exit 0; }

# 构建上下文
CONTEXT="[DevBooks 自动上下文注入]

$(check_index)"

# 优先使用 Embedding 语义搜索
SNIPPETS=""

if [ "$USE_EMBEDDING" = "true" ]; then
  embedding_results=$(semantic_search "$PROMPT")

  if [ -n "$embedding_results" ]; then
    SNIPPETS="
🔍 语义搜索结果：
\`\`\`
$embedding_results
\`\`\`"
  fi
fi

# 降级到符号搜索
if [ -z "$SNIPPETS" ]; then
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

# 如果使用了 Embedding，添加提示
if [ -n "$embedding_results" ]; then
  CONTEXT="${CONTEXT}

ℹ️ 使用了语义搜索（Embedding）来找到最相关的代码"
fi

# 输出
jq -n --arg ctx "$CONTEXT" '{"additionalContext": $ctx}'
