#!/bin/bash
# DevBooks Embedding Service
# 代码向量化与语义搜索工具
#
# 功能：
#   1. 将代码库转换为向量表示
#   2. 语义搜索代码片段
#   3. 增量更新向量库
#   4. 集成到 DevBooks 工作流

set -e

# ==================== 配置 ====================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
CONFIG_FILE="${CONFIG_FILE:-$PROJECT_ROOT/.devbooks/embedding.yaml}"
VECTOR_DB_DIR=""
TEMP_DIR="/tmp/devbooks-embedding-$$"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[Embedding]${NC} $1" >&2; }
log_ok()    { echo -e "${GREEN}[Embedding]${NC} $1" >&2; }
log_warn()  { echo -e "${YELLOW}[Embedding]${NC} $1" >&2; }
log_error() { echo -e "${RED}[Embedding]${NC} $1" >&2; }
log_debug() {
  [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]] && echo -e "${CYAN}[Embedding]${NC} $1" >&2
}

# ==================== YAML 解析 ====================

# 简易 YAML 解析器（仅支持简单的 key: value 格式）
parse_yaml() {
  local file="$1"
  local prefix="$2"

  if [ ! -f "$file" ]; then
    log_error "配置文件不存在: $file"
    return 1
  fi

  # 移除注释和空行，处理环境变量替换
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$file" | \
  while IFS=: read -r key value; do
    # 移除前导/尾随空格
    key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # 跳过列表项
    [[ "$key" =~ ^- ]] && continue

    # 处理环境变量引用 ${VAR_NAME}
    if [[ "$value" =~ \$\{([^}]+)\} ]]; then
      local var_name="${BASH_REMATCH[1]}"
      value="${!var_name}"
    fi

    # 输出键值对
    if [ -n "$key" ] && [ -n "$value" ]; then
      echo "${prefix}${key}=${value}"
    fi
  done
}

# 加载配置
load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    log_warn "配置文件不存在: $CONFIG_FILE"
    log_info "使用默认配置"

    # 默认配置
    ENABLED=true
    API_MODEL="text-embedding-3-small"
    API_KEY="${OPENAI_API_KEY:-${EMBEDDING_API_KEY}}"
    API_BASE_URL="https://api.openai.com/v1"
    API_TIMEOUT=30
    BATCH_SIZE=50
    VECTOR_DB_DIR="$PROJECT_ROOT/.devbooks/embeddings"
    DIMENSION=1536
    INDEX_TYPE="flat"
    TOP_K=5
    SIMILARITY_THRESHOLD=0.7
    LOG_LEVEL="INFO"
    return 0
  fi

  log_debug "加载配置: $CONFIG_FILE"

  # 解析 YAML（简化版）
  local config=$(cat "$CONFIG_FILE")

  # 提取配置值
  ENABLED=$(echo "$config" | grep -E "^enabled:" | awk '{print $2}')
  API_MODEL=$(echo "$config" | grep -E "^\s*model:" | awk '{print $2}')
  API_KEY=$(echo "$config" | grep -E "^\s*api_key:" | awk '{print $2}')
  API_BASE_URL=$(echo "$config" | grep -E "^\s*base_url:" | awk '{print $2}')
  API_TIMEOUT=$(echo "$config" | grep -E "^\s*timeout:" | awk '{print $2}')
  BATCH_SIZE=$(echo "$config" | grep -E "^\s*batch_size:" | awk '{print $2}')

  local storage_path=$(echo "$config" | grep -E "^\s*storage_path:" | awk '{print $2}')
  VECTOR_DB_DIR="$PROJECT_ROOT/${storage_path:-.devbooks/embeddings}"

  DIMENSION=$(echo "$config" | grep -E "^\s*dimension:" | awk '{print $2}')
  INDEX_TYPE=$(echo "$config" | grep -E "^\s*index_type:" | awk '{print $2}')
  TOP_K=$(echo "$config" | grep -E "^\s*top_k:" | awk '{print $2}')
  SIMILARITY_THRESHOLD=$(echo "$config" | grep -E "^\s*similarity_threshold:" | awk '{print $2}')
  LOG_LEVEL=$(echo "$config" | grep -E "^\s*level:" | awk '{print $2}')

  # 处理环境变量引用
  if [[ "$API_KEY" =~ \$\{([^}]+)\} ]]; then
    local var_name="${BASH_REMATCH[1]}"
    API_KEY="${!var_name}"
  fi

  # 设置默认值
  ENABLED="${ENABLED:-true}"
  API_MODEL="${API_MODEL:-text-embedding-3-small}"
  API_BASE_URL="${API_BASE_URL:-https://api.openai.com/v1}"
  API_TIMEOUT="${API_TIMEOUT:-30}"
  BATCH_SIZE="${BATCH_SIZE:-50}"
  DIMENSION="${DIMENSION:-1536}"
  INDEX_TYPE="${INDEX_TYPE:-flat}"
  TOP_K="${TOP_K:-5}"
  SIMILARITY_THRESHOLD="${SIMILARITY_THRESHOLD:-0.7}"
  LOG_LEVEL="${LOG_LEVEL:-INFO}"

  log_debug "配置已加载: model=$API_MODEL, dimension=$DIMENSION, top_k=$TOP_K"
}

# ==================== API 调用 ====================

# 调用 OpenAI 兼容的 Embedding API
call_embedding_api() {
  local input_text="$1"
  local output_file="$2"

  if [ -z "$API_KEY" ]; then
    log_error "API Key 未配置"
    return 1
  fi

  local api_endpoint="${API_BASE_URL}/embeddings"

  log_debug "调用 API: $api_endpoint"

  # 构建请求体
  local request_body=$(jq -n \
    --arg model "$API_MODEL" \
    --arg input "$input_text" \
    '{model: $model, input: $input}')

  # 发送请求
  local response=$(curl -s -X POST "$api_endpoint" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    --max-time "$API_TIMEOUT" \
    -d "$request_body")

  # 检查错误
  if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    local error_msg=$(echo "$response" | jq -r '.error.message')
    log_error "API 错误: $error_msg"
    return 1
  fi

  # 提取向量
  echo "$response" | jq -r '.data[0].embedding | @json' > "$output_file"

  if [ ! -s "$output_file" ]; then
    log_error "未获取到向量数据"
    return 1
  fi

  log_debug "向量已保存: $output_file"
  return 0
}

# 批量生成向量
batch_embed() {
  local input_file="$1"
  local output_dir="$2"

  mkdir -p "$output_dir"

  local total_lines=$(wc -l < "$input_file")
  local batch_count=$((total_lines / BATCH_SIZE + 1))

  log_info "批量向量化: $total_lines 项，分 $batch_count 批"

  local line_num=0
  local batch_num=0
  local batch_items=()

  while IFS=$'\t' read -r file_path text; do
    batch_items+=("$file_path|$text")
    ((line_num++))

    # 达到批量大小或最后一行
    if [ ${#batch_items[@]} -ge $BATCH_SIZE ] || [ $line_num -eq $total_lines ]; then
      ((batch_num++))
      log_info "处理批次 $batch_num / $batch_count ..."

      # 构建批量请求
      local inputs_json=$(printf '%s\n' "${batch_items[@]}" | awk -F'|' '{print $2}' | jq -R -s -c 'split("\n") | map(select(length > 0))')

      local request_body=$(jq -n \
        --arg model "$API_MODEL" \
        --argjson inputs "$inputs_json" \
        '{model: $model, input: $inputs}')

      # 发送请求
      local response=$(curl -s -X POST "${API_BASE_URL}/embeddings" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        --max-time "$API_TIMEOUT" \
        -d "$request_body")

      # 检查错误
      if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        local error_msg=$(echo "$response" | jq -r '.error.message')
        log_error "API 错误: $error_msg"
        return 1
      fi

      # 保存每个向量
      local idx=0
      for item in "${batch_items[@]}"; do
        local file_path="${item%%|*}"
        local vector=$(echo "$response" | jq -r ".data[$idx].embedding | @json")

        # 生成向量文件名（使用文件路径的 hash）
        local hash=$(echo "$file_path" | md5sum | awk '{print $1}' || echo "$file_path" | md5 | awk '{print $1}')

        echo "$vector" > "$output_dir/$hash.json"
        echo -e "$file_path\t$hash" >> "$output_dir/index.tsv"

        ((idx++))
      done

      batch_items=()
      sleep 0.5  # 避免 API 限流
    fi
  done < "$input_file"

  log_ok "向量化完成: $line_num 项"
}

# ==================== 代码提取 ====================

# 提取代码文件
extract_code_files() {
  local output_file="$1"

  log_info "提取代码文件..."

  # 读取配置中的文件扩展名
  local extensions="ts,tsx,js,jsx,py,go,rs,java,md"
  local exclude_dirs="node_modules|dist|build|\.git|__pycache__|venv|\.venv|target|\.next"

  > "$output_file"

  # 使用 find 查找文件
  find "$PROJECT_ROOT" -type f \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
       -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \
       -o -name "*.md" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/.git/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/venv/*" \
    ! -path "*/.venv/*" \
    ! -path "*/target/*" \
    ! -path "*/.next/*" \
    ! -name "*.test.ts" \
    ! -name "*.spec.ts" \
    ! -name "*.test.js" \
    ! -name "*.min.js" \
    2>/dev/null | while read -r file; do

    # 获取相对路径
    local rel_path="${file#$PROJECT_ROOT/}"

    # 读取文件内容（限制大小）
    if [ -f "$file" ] && [ $(wc -c < "$file") -lt 1000000 ]; then
      local content=$(cat "$file" | tr '\n' ' ' | head -c 10000)
      echo -e "$rel_path\t$content" >> "$output_file"
    fi
  done

  local file_count=$(wc -l < "$output_file")
  log_ok "提取完成: $file_count 个文件"
}

# ==================== 向量数据库 ====================

# 初始化向量数据库
init_vector_db() {
  log_info "初始化向量数据库: $VECTOR_DB_DIR"

  mkdir -p "$VECTOR_DB_DIR"

  # 创建元数据文件
  cat > "$VECTOR_DB_DIR/metadata.json" <<EOF
{
  "model": "$API_MODEL",
  "dimension": $DIMENSION,
  "index_type": "$INDEX_TYPE",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

  > "$VECTOR_DB_DIR/index.tsv"

  log_ok "向量数据库已初始化"
}

# 构建向量索引
build_index() {
  log_info "开始构建向量索引..."

  if [ "$ENABLED" != "true" ]; then
    log_warn "Embedding 功能未启用"
    return 1
  fi

  # 初始化
  init_vector_db

  # 提取代码文件
  local code_files="$TEMP_DIR/code_files.tsv"
  extract_code_files "$code_files"

  if [ ! -s "$code_files" ]; then
    log_warn "未找到代码文件"
    return 0
  fi

  # 批量生成向量
  batch_embed "$code_files" "$VECTOR_DB_DIR"

  # 更新元数据
  local file_count=$(wc -l < "$VECTOR_DB_DIR/index.tsv")
  local updated_metadata=$(jq \
    --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg count "$file_count" \
    '.updated_at = $updated | .file_count = ($count | tonumber)' \
    "$VECTOR_DB_DIR/metadata.json")

  echo "$updated_metadata" > "$VECTOR_DB_DIR/metadata.json"

  log_ok "索引构建完成: $file_count 个文件"
}

# 增量更新索引
update_index() {
  log_info "增量更新向量索引..."

  if [ ! -f "$VECTOR_DB_DIR/index.tsv" ]; then
    log_warn "索引不存在，执行全量构建"
    build_index
    return $?
  fi

  # 检查修改的文件
  local modified_files="$TEMP_DIR/modified_files.tsv"
  > "$modified_files"

  # 获取索引更新时间
  local index_mtime=$(stat -f %m "$VECTOR_DB_DIR/index.tsv" 2>/dev/null || stat -c %Y "$VECTOR_DB_DIR/index.tsv" 2>/dev/null)

  # 查找比索引更新的文件
  extract_code_files "$TEMP_DIR/all_files.tsv"

  while IFS=$'\t' read -r file_path content; do
    local full_path="$PROJECT_ROOT/$file_path"
    if [ -f "$full_path" ]; then
      local file_mtime=$(stat -f %m "$full_path" 2>/dev/null || stat -c %Y "$full_path" 2>/dev/null)
      if [ "$file_mtime" -gt "$index_mtime" ]; then
        echo -e "$file_path\t$content" >> "$modified_files"
      fi
    fi
  done < "$TEMP_DIR/all_files.tsv"

  local modified_count=$(wc -l < "$modified_files" 2>/dev/null || echo 0)

  if [ "$modified_count" -eq 0 ]; then
    log_ok "索引已是最新，无需更新"
    return 0
  fi

  log_info "发现 $modified_count 个修改的文件"

  # 删除旧向量
  while IFS=$'\t' read -r file_path hash; do
    rm -f "$VECTOR_DB_DIR/$hash.json"
  done < <(grep -Ff <(cut -f1 "$modified_files") "$VECTOR_DB_DIR/index.tsv" 2>/dev/null || true)

  # 重建这些文件的向量
  batch_embed "$modified_files" "$VECTOR_DB_DIR"

  log_ok "增量更新完成: $modified_count 个文件"
}

# ==================== 搜索 ====================

# 计算余弦相似度
cosine_similarity() {
  local vec1="$1"
  local vec2="$2"

  # 使用 Python 计算（如果可用）
  if command -v python3 &>/dev/null; then
    python3 -c "
import json
import sys
from math import sqrt

v1 = json.loads('$vec1')
v2 = json.loads('$vec2')

dot = sum(a*b for a, b in zip(v1, v2))
norm1 = sqrt(sum(a*a for a in v1))
norm2 = sqrt(sum(b*b for b in v2))

similarity = dot / (norm1 * norm2) if norm1 > 0 and norm2 > 0 else 0
print(f'{similarity:.6f}')
"
  else
    # 降级：返回随机相似度（仅用于测试）
    echo "0.500000"
  fi
}

# 语义搜索
semantic_search() {
  local query="$1"
  local top_k="${2:-$TOP_K}"

  log_info "语义搜索: \"$query\""

  if [ ! -f "$VECTOR_DB_DIR/index.tsv" ]; then
    log_error "向量索引不存在，请先运行: $0 build"
    return 1
  fi

  # 生成查询向量
  local query_vector_file="$TEMP_DIR/query_vector.json"
  call_embedding_api "$query" "$query_vector_file" || return 1

  local query_vector=$(cat "$query_vector_file")

  # 搜索相似向量
  local results="$TEMP_DIR/search_results.tsv"
  > "$results"

  log_info "计算相似度..."

  while IFS=$'\t' read -r file_path hash; do
    local vector_file="$VECTOR_DB_DIR/$hash.json"

    if [ ! -f "$vector_file" ]; then
      continue
    fi

    local file_vector=$(cat "$vector_file")
    local similarity=$(cosine_similarity "$query_vector" "$file_vector")

    # 过滤低于阈值的结果
    if (( $(echo "$similarity >= $SIMILARITY_THRESHOLD" | bc -l 2>/dev/null || echo 1) )); then
      echo -e "$similarity\t$file_path" >> "$results"
    fi
  done < "$VECTOR_DB_DIR/index.tsv"

  # 排序并返回 top-k
  if [ -s "$results" ]; then
    log_ok "找到 $(wc -l < "$results") 个相关结果"

    sort -rn "$results" | head -n "$top_k" | while IFS=$'\t' read -r score file; do
      echo "[$score] $file"

      # 显示代码片段
      local full_path="$PROJECT_ROOT/$file"
      if [ -f "$full_path" ]; then
        echo "---"
        head -n 10 "$full_path" | sed 's/^/  /'
        echo ""
      fi
    done
  else
    log_warn "未找到相关结果"
  fi
}

# ==================== 工具命令 ====================

# 显示帮助
show_help() {
  cat << EOF
DevBooks Embedding Service - 代码向量化与语义搜索

用法:
  $0 [命令] [选项]

命令:
  build                构建完整向量索引
  update              增量更新向量索引
  search <查询>       语义搜索代码
  status              显示索引状态
  clean               清理向量数据库
  config              显示当前配置
  help                显示此帮助

选项:
  --config <文件>      指定配置文件（默认: .devbooks/embedding.yaml）
  --top-k <数量>       返回结果数（默认: 5）
  --threshold <值>     相似度阈值（默认: 0.7）
  --debug             启用调试模式

示例:
  # 初次使用：构建索引
  $0 build

  # 增量更新索引
  $0 update

  # 语义搜索
  $0 search "用户认证相关的函数"
  $0 search "处理支付的代码" --top-k 10

  # 查看状态
  $0 status

环境变量:
  OPENAI_API_KEY       OpenAI API 密钥
  EMBEDDING_API_KEY    通用 Embedding API 密钥
  PROJECT_ROOT         项目根目录

配置文件:
  .devbooks/embedding.yaml

EOF
}

# 显示状态
show_status() {
  log_info "向量索引状态"
  echo ""

  if [ ! -f "$VECTOR_DB_DIR/metadata.json" ]; then
    echo "  状态: 未初始化"
    echo ""
    echo "  运行 '$0 build' 来构建索引"
    return 0
  fi

  local metadata=$(cat "$VECTOR_DB_DIR/metadata.json")

  echo "  模型: $(echo "$metadata" | jq -r '.model')"
  echo "  向量维度: $(echo "$metadata" | jq -r '.dimension')"
  echo "  索引类型: $(echo "$metadata" | jq -r '.index_type')"
  echo "  文件数量: $(echo "$metadata" | jq -r '.file_count // 0')"
  echo "  创建时间: $(echo "$metadata" | jq -r '.created_at')"
  echo "  更新时间: $(echo "$metadata" | jq -r '.updated_at')"
  echo ""

  # 计算索引大小
  if [ -d "$VECTOR_DB_DIR" ]; then
    local size=$(du -sh "$VECTOR_DB_DIR" | awk '{print $1}')
    echo "  索引大小: $size"
  fi

  echo ""
}

# 显示配置
show_config() {
  log_info "当前配置"
  echo ""

  echo "  配置文件: $CONFIG_FILE"
  echo "  启用状态: $ENABLED"
  echo "  模型: $API_MODEL"
  echo "  API 地址: $API_BASE_URL"
  echo "  批量大小: $BATCH_SIZE"
  echo "  向量数据库: $VECTOR_DB_DIR"
  echo "  向量维度: $DIMENSION"
  echo "  索引类型: $INDEX_TYPE"
  echo "  Top-K: $TOP_K"
  echo "  相似度阈值: $SIMILARITY_THRESHOLD"
  echo "  日志级别: $LOG_LEVEL"
  echo ""
}

# 清理向量数据库
clean_vector_db() {
  log_warn "清理向量数据库: $VECTOR_DB_DIR"

  if [ -d "$VECTOR_DB_DIR" ]; then
    rm -rf "$VECTOR_DB_DIR"
    log_ok "已清理"
  else
    log_info "向量数据库不存在"
  fi
}

# ==================== 主函数 ====================

main() {
  # 创建临时目录
  mkdir -p "$TEMP_DIR"
  trap "rm -rf '$TEMP_DIR'" EXIT

  # 加载配置
  load_config

  # 解析命令
  local command="${1:-help}"
  shift || true

  case "$command" in
    build)
      build_index "$@"
      ;;
    update)
      update_index "$@"
      ;;
    search)
      if [ -z "$1" ]; then
        log_error "请提供搜索查询"
        echo "用法: $0 search <查询>"
        exit 1
      fi
      semantic_search "$@"
      ;;
    status)
      show_status
      ;;
    config)
      show_config
      ;;
    clean)
      clean_vector_db
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      log_error "未知命令: $command"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

# 解析全局选项
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --top-k)
      TOP_K="$2"
      shift 2
      ;;
    --threshold)
      SIMILARITY_THRESHOLD="$2"
      shift 2
      ;;
    --debug)
      LOG_LEVEL="DEBUG"
      shift
      ;;
    *)
      break
      ;;
  esac
done

# 运行主函数
main "$@"
