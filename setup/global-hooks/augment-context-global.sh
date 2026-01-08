#!/bin/bash
# DevBooks Global Context Injection Hook
# 全局生效，自动检测代码项目并注入上下文
# 版本: 1.0

# ==================== 配置 ====================
MAX_SNIPPETS=3
MAX_LINES=20
SEARCH_TIMEOUT=2
CACHE_DIR="${TMPDIR:-/tmp}/.devbooks-cache"
CACHE_TTL=300

# ==================== 输入处理 ====================
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
CWD="${WORKING_DIRECTORY:-$(pwd)}"

[ -z "$PROMPT" ] && { echo '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":""}}'; exit 0; }

# ==================== 项目检测 ====================
is_code_project() {
  local dir="$1"
  # 检查常见项目标识文件
  [ -f "$dir/package.json" ] && return 0
  [ -f "$dir/tsconfig.json" ] && return 0
  [ -f "$dir/pyproject.toml" ] && return 0
  [ -f "$dir/setup.py" ] && return 0
  [ -f "$dir/requirements.txt" ] && return 0
  [ -f "$dir/go.mod" ] && return 0
  [ -f "$dir/Cargo.toml" ] && return 0
  [ -f "$dir/pom.xml" ] && return 0
  [ -f "$dir/build.gradle" ] && return 0
  [ -f "$dir/Makefile" ] && return 0
  [ -f "$dir/CMakeLists.txt" ] && return 0
  [ -d "$dir/.git" ] && return 0
  return 1
}

# 非代码项目则跳过
is_code_project "$CWD" || { echo '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":""}}'; exit 0; }

# ==================== 创建缓存目录 ====================
mkdir -p "$CACHE_DIR" 2>/dev/null

# ==================== 缓存机制 ====================
get_cache_key() {
  echo "$1" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$1" | md5 2>/dev/null
}

get_cached() {
  local key=$(get_cache_key "$1")
  local cache_file="$CACHE_DIR/$key"
  if [ -f "$cache_file" ]; then
    local age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)))
    if [ "$age" -lt "$CACHE_TTL" ]; then
      cat "$cache_file"
      return 0
    fi
  fi
  return 1
}

set_cache() {
  local key=$(get_cache_key "$1")
  echo "$2" > "$CACHE_DIR/$key" 2>/dev/null
}

# ==================== 意图检测 ====================
CODE_INTENT_PATTERN='修复|fix|bug|错误|重构|refactor|优化|添加|新增|实现|implement|删除|remove|修改|update|change|分析|analyze|影响|impact|引用|reference|调用|call|依赖|depend|函数|function|方法|method|类|class|模块|module|\.ts|\.tsx|\.js|\.py|\.go|src/|lib/'
NON_CODE_PATTERN='^(天气|weather|翻译|translate|写邮件|email|闲聊|chat|你好|hello|hi)'

is_code_intent() {
  echo "$1" | grep -qiE "$CODE_INTENT_PATTERN"
}

is_non_code() {
  echo "$1" | grep -qiE "$NON_CODE_PATTERN"
}

# ==================== 符号提取 ====================
extract_symbols() {
  local q="$1"
  local cached=$(get_cached "symbols:$q")
  [ -n "$cached" ] && { echo "$cached"; return; }

  local result=$(
    {
      # camelCase (如 getUserById)
      echo "$q" | grep -oE '\b[a-z][a-zA-Z0-9]*[A-Z][a-zA-Z0-9]*\b'
      # PascalCase (如 UserService)
      echo "$q" | grep -oE '\b[A-Z][a-zA-Z0-9]*[a-z][a-zA-Z0-9]*\b'
      # 反引号内容 (如 `search`)
      echo "$q" | grep -oE '\`[^\`]+\`' | tr -d '\`'
      # 文件路径
      echo "$q" | grep -oE '[a-zA-Z0-9_/\-]+\.(ts|tsx|js|jsx|py|go|sh|md)'
      # snake_case (如 get_user_by_id)
      echo "$q" | grep -oE '\b[a-z]+_[a-z_]+\b'
      # 英文单词（4+ 字符且不是常见停用词）
      echo "$q" | tr ' ' '\n' | grep -oE '^[a-zA-Z]{4,}$' | grep -ivE '^(that|this|with|from|have|been|will|would|could|should|about|after|before|through|function|class|method|implement|analyze|analysis)$'
    } | grep -v '^$' | awk '!seen[$0]++' | head -$MAX_SNIPPETS
  )
  set_cache "symbols:$q" "$result"
  echo "$result"
}

# ==================== 代码搜索 ====================
# macOS 兼容的超时函数
run_with_timeout() {
  local timeout_sec="$1"
  shift
  if command -v gtimeout &>/dev/null; then
    gtimeout "$timeout_sec" "$@"
  elif command -v timeout &>/dev/null; then
    timeout "$timeout_sec" "$@"
  else
    # 无超时命令，直接执行（依赖 ripgrep 自身的性能）
    "$@"
  fi
}

search_symbol() {
  local sym="$1"
  [ -z "$sym" ] && return

  local cached=$(get_cached "search:$CWD:$sym")
  [ -n "$cached" ] && { echo "$cached"; return; }

  local result=""
  if command -v rg &>/dev/null; then
    result=$(run_with_timeout "$SEARCH_TIMEOUT" rg \
      --max-count=1 \
      --max-filesize=500K \
      --smart-case \
      -n -C 3 \
      -t py -t js -t ts -t go -t sh \
      -g '!node_modules' -g '!dist' -g '!build' -g '!.git' -g '!*.lock' -g '!coverage' -g '!__pycache__' -g '!.venv' -g '!venv' \
      "$sym" "$CWD" 2>/dev/null | head -$MAX_LINES)
  else
    result=$(grep -rn \
      --include='*.ts' --include='*.js' --include='*.py' --include='*.go' \
      --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build --exclude-dir=.git --exclude-dir=__pycache__ --exclude-dir=.venv \
      -A 2 -B 1 "$sym" "$CWD" 2>/dev/null | head -$MAX_LINES)
  fi

  [ -n "$result" ] && set_cache "search:$CWD:$sym" "$result"
  echo "$result"
}

# 顺序搜索（简化版，避免子 shell 问题）
do_search() {
  local symbols="$1"
  local results=""

  while IFS= read -r symbol; do
    [ -z "$symbol" ] && continue
    local snippet=$(search_symbol "$symbol")
    if [ -n "$snippet" ]; then
      results="${results}

🔍 $symbol:
\`\`\`
$snippet
\`\`\`"
    fi
  done <<< "$symbols"

  echo "$results"
}

# ==================== 热点文件 ====================
get_hotspots() {
  [ -d "$CWD/.git" ] || return
  local cached=$(get_cached "hotspots:$CWD")
  [ -n "$cached" ] && { echo "$cached"; return; }

  local result=$(git -C "$CWD" log \
    --since="30 days ago" \
    --name-only \
    --pretty=format: \
    --max-count=200 \
    2>/dev/null | \
    grep -v '^$' | \
    grep -vE 'node_modules|dist|build|\.lock|\.md$|\.json$|__pycache__|\.pyc$' | \
    sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "  🔥 %s (%d changes)\n", $2, $1}')

  [ -n "$result" ] && set_cache "hotspots:$CWD" "$result"
  echo "$result"
}

check_index() {
  if [ -f "$CWD/index.scip" ]; then
    echo "✅ SCIP 索引可用"
  elif [ -d "$CWD/.git/ckb" ]; then
    echo "✅ CKB 索引可用"
  else
    echo "💡 提示：可启用 CKB 加速代码分析"
  fi
}

# ==================== 主逻辑 ====================
main() {
  is_non_code "$PROMPT" && { echo '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":""}}'; exit 0; }
  is_code_intent "$PROMPT" || { echo '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":""}}'; exit 0; }

  local CONTEXT="[DevBooks 自动上下文]

$(check_index)"

  local SYMBOLS=$(extract_symbols "$PROMPT")
  local SNIPPETS=""
  if [ -n "$SYMBOLS" ]; then
    SNIPPETS=$(do_search "$SYMBOLS")
  fi

  if [ -n "$SNIPPETS" ]; then
    CONTEXT="${CONTEXT}

📦 相关代码：$SNIPPETS"
  fi

  local HOTSPOTS=$(get_hotspots)
  [ -n "$HOTSPOTS" ] && CONTEXT="${CONTEXT}

🔥 热点文件：
$HOTSPOTS"

  CONTEXT="${CONTEXT}

💡 可用工具：analyzeImpact / findReferences / getCallGraph"

  # 正确的 Hook 输出格式
  jq -n --arg ctx "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": $ctx
      }
    }'
}

# 带总超时执行 - 直接调用 main（内部搜索已有独立超时）
main
