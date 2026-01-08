#!/bin/bash
# DevBooks 后台索引守护进程
# 监听文件变化，自动触发 SCIP 索引更新

set -e

# 配置
DEBOUNCE_SECONDS=30      # 防抖：文件变化后等待秒数
INDEX_INTERVAL=300       # 最小索引间隔（秒）
WATCH_EXTENSIONS="ts,tsx,js,jsx,py,go,rs,java"
IGNORE_PATTERNS="node_modules|dist|build|\.git|__pycache__|\.lock"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[DevBooks]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[DevBooks]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[DevBooks]${NC} $1"; }
log_error() { echo -e "${RED}[DevBooks]${NC} $1"; }

# 检测项目语言
detect_language() {
  local dir="$1"
  if [ -f "$dir/tsconfig.json" ] || [ -f "$dir/package.json" ]; then
    echo "typescript"
  elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/requirements.txt" ]; then
    echo "python"
  elif [ -f "$dir/go.mod" ]; then
    echo "go"
  elif [ -f "$dir/Cargo.toml" ]; then
    echo "rust"
  else
    echo "unknown"
  fi
}

# 获取索引命令
get_index_command() {
  local lang="$1"
  case "$lang" in
    typescript)
      if command -v scip-typescript &>/dev/null; then
        echo "scip-typescript index --output index.scip"
      else
        echo ""
      fi
      ;;
    python)
      if command -v scip-python &>/dev/null; then
        echo "scip-python index . --output index.scip"
      else
        echo ""
      fi
      ;;
    go)
      if command -v scip-go &>/dev/null; then
        echo "scip-go --output index.scip"
      else
        echo ""
      fi
      ;;
    *)
      echo ""
      ;;
  esac
}

# 执行索引
do_index() {
  local dir="$1"
  local lang=$(detect_language "$dir")
  local cmd=$(get_index_command "$lang")

  if [ -z "$cmd" ]; then
    log_warn "无法为 $lang 项目生成索引（索引器未安装）"
    return 1
  fi

  log_info "开始索引 ($lang)..."
  local start_time=$(date +%s)

  if (cd "$dir" && eval "$cmd" 2>/dev/null); then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_ok "索引完成 (${duration}s)"
    return 0
  else
    log_error "索引失败"
    return 1
  fi
}

# 检查文件监听工具
check_watcher() {
  if command -v fswatch &>/dev/null; then
    echo "fswatch"
  elif command -v inotifywait &>/dev/null; then
    echo "inotifywait"
  else
    echo ""
  fi
}

# 使用 fswatch 监听（macOS）
watch_with_fswatch() {
  local dir="$1"
  local last_index=0

  log_info "使用 fswatch 监听文件变化..."

  fswatch -r -e "$IGNORE_PATTERNS" \
    --include "\\.($WATCH_EXTENSIONS)$" \
    "$dir" | while read -r changed_file; do

    local now=$(date +%s)
    local since_last=$((now - last_index))

    # 防抖 + 最小间隔
    if [ $since_last -lt $INDEX_INTERVAL ]; then
      continue
    fi

    log_info "检测到变化: $(basename "$changed_file")"
    sleep $DEBOUNCE_SECONDS

    if do_index "$dir"; then
      last_index=$(date +%s)
    fi
  done
}

# 使用 inotifywait 监听（Linux）
watch_with_inotify() {
  local dir="$1"
  local last_index=0

  log_info "使用 inotifywait 监听文件变化..."

  inotifywait -r -m -e modify,create,delete \
    --exclude "$IGNORE_PATTERNS" \
    "$dir" | while read -r path action file; do

    # 检查文件扩展名
    if ! echo "$file" | grep -qE "\.($WATCH_EXTENSIONS)$"; then
      continue
    fi

    local now=$(date +%s)
    local since_last=$((now - last_index))

    if [ $since_last -lt $INDEX_INTERVAL ]; then
      continue
    fi

    log_info "检测到变化: $file ($action)"
    sleep $DEBOUNCE_SECONDS

    if do_index "$dir"; then
      last_index=$(date +%s)
    fi
  done
}

# 轮询模式（无监听工具时的降级方案）
watch_with_polling() {
  local dir="$1"
  local poll_interval=${INDEX_INTERVAL:-300}

  log_warn "未找到文件监听工具，使用轮询模式（每 ${poll_interval}s）"

  while true; do
    local index_file="$dir/index.scip"

    if [ ! -f "$index_file" ]; then
      do_index "$dir"
    else
      # 检查是否有比索引更新的文件
      local newer_files=$(find "$dir" \
        -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.go" \) \
        -newer "$index_file" \
        ! -path "*/node_modules/*" ! -path "*/dist/*" ! -path "*/.git/*" \
        2>/dev/null | head -1)

      if [ -n "$newer_files" ]; then
        log_info "发现更新的文件，重新索引..."
        do_index "$dir"
      fi
    fi

    sleep $poll_interval
  done
}

# 主函数
main() {
  local project_dir="${1:-$(pwd)}"

  if [ ! -d "$project_dir" ]; then
    log_error "目录不存在: $project_dir"
    exit 1
  fi

  log_info "DevBooks 后台索引守护进程启动"
  log_info "项目目录: $project_dir"

  local lang=$(detect_language "$project_dir")
  log_info "检测到语言: $lang"

  # 首次索引
  if [ ! -f "$project_dir/index.scip" ]; then
    log_info "首次运行，生成初始索引..."
    do_index "$project_dir"
  else
    log_ok "索引已存在，跳过初始索引"
  fi

  # 选择监听方式
  local watcher=$(check_watcher)

  case "$watcher" in
    fswatch)
      watch_with_fswatch "$project_dir"
      ;;
    inotifywait)
      watch_with_inotify "$project_dir"
      ;;
    *)
      watch_with_polling "$project_dir"
      ;;
  esac
}

# 帮助信息
show_help() {
  cat << EOF
DevBooks 后台索引守护进程

用法:
  $0 [项目目录]          启动守护进程
  $0 --install           安装为 LaunchAgent (macOS)
  $0 --uninstall         卸载 LaunchAgent
  $0 --status            检查状态
  $0 --help              显示帮助

环境变量:
  DEBOUNCE_SECONDS       防抖时间（默认 30s）
  INDEX_INTERVAL         最小索引间隔（默认 300s）

依赖:
  - fswatch (macOS) 或 inotifywait (Linux) 用于文件监听
  - scip-typescript / scip-python / scip-go 用于生成索引

EOF
}

# 安装为 LaunchAgent (macOS)
install_launchagent() {
  local plist_path="$HOME/Library/LaunchAgents/com.devbooks.indexer.plist"
  local script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  local project_dir="${1:-$(pwd)}"

  cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.devbooks.indexer</string>
    <key>ProgramArguments</key>
    <array>
        <string>$script_path</string>
        <string>$project_dir</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/devbooks-indexer.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/devbooks-indexer.log</string>
</dict>
</plist>
EOF

  launchctl load "$plist_path"
  log_ok "LaunchAgent 已安装并启动"
  log_info "日志: /tmp/devbooks-indexer.log"
}

# 解析参数
case "${1:-}" in
  --help|-h)
    show_help
    exit 0
    ;;
  --install)
    install_launchagent "${2:-$(pwd)}"
    exit 0
    ;;
  --uninstall)
    launchctl unload "$HOME/Library/LaunchAgents/com.devbooks.indexer.plist" 2>/dev/null || true
    rm -f "$HOME/Library/LaunchAgents/com.devbooks.indexer.plist"
    log_ok "LaunchAgent 已卸载"
    exit 0
    ;;
  --status)
    if launchctl list | grep -q "com.devbooks.indexer"; then
      log_ok "守护进程运行中"
    else
      log_warn "守护进程未运行"
    fi
    exit 0
    ;;
  *)
    main "$@"
    ;;
esac
