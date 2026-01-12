#!/bin/bash
# DevBooks 系统依赖安装脚本
# 支持 macOS (Homebrew) 和 Linux (apt/yum)
#
# 用法: ./scripts/install-dependencies.sh [--all | --minimal | --dev]
#   --minimal  只安装必需依赖 (jq, ripgrep)
#   --all      安装所有依赖（默认）
#   --dev      额外安装开发依赖 (shellcheck)

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测操作系统
detect_os() {
  case "$(uname -s)" in
    Darwin*) echo "macos" ;;
    Linux*)  echo "linux" ;;
    *)       echo "unknown" ;;
  esac
}

# 检测包管理器
detect_package_manager() {
  if command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v yum &>/dev/null; then
    echo "yum"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  else
    echo "unknown"
  fi
}

# 检查命令是否存在
check_command() {
  command -v "$1" &>/dev/null
}

# 安装单个工具
install_tool() {
  local tool="$1"
  local pkg_manager="$2"

  if check_command "$tool"; then
    log_info "$tool 已安装 ($(which $tool))"
    return 0
  fi

  log_info "安装 $tool..."
  case "$pkg_manager" in
    brew)
      case "$tool" in
        radon) pip3 install radon ;;
        gocyclo)
          if check_command go; then
            go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
          else
            log_warn "跳过 gocyclo（需要 Go 环境）"
            return 0
          fi
          ;;
        *) brew install "$tool" ;;
      esac
      ;;
    apt)
      case "$tool" in
        ripgrep) sudo apt-get install -y ripgrep ;;
        radon) pip3 install radon ;;
        scc)
          log_warn "scc 需要手动安装: https://github.com/boyter/scc#installation"
          return 0
          ;;
        gocyclo)
          if check_command go; then
            go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
          else
            log_warn "跳过 gocyclo（需要 Go 环境）"
            return 0
          fi
          ;;
        *) sudo apt-get install -y "$tool" ;;
      esac
      ;;
    yum|dnf)
      case "$tool" in
        radon) pip3 install radon ;;
        scc)
          log_warn "scc 需要手动安装: https://github.com/boyter/scc#installation"
          return 0
          ;;
        gocyclo)
          if check_command go; then
            go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
          else
            log_warn "跳过 gocyclo（需要 Go 环境）"
            return 0
          fi
          ;;
        *) sudo "$pkg_manager" install -y "$tool" ;;
      esac
      ;;
    *)
      log_error "未知包管理器，请手动安装 $tool"
      return 1
      ;;
  esac
}

# 主函数
main() {
  local mode="${1:---all}"
  local os=$(detect_os)
  local pkg_manager=$(detect_package_manager)

  log_info "检测到操作系统: $os"
  log_info "检测到包管理器: $pkg_manager"
  echo ""

  # 必需依赖
  local required_tools=(jq ripgrep)

  # 推荐依赖（复杂度计算）
  local recommended_tools=(scc radon gocyclo)

  # 开发依赖
  local dev_tools=(shellcheck)

  # 根据模式选择安装范围
  local tools_to_install=()
  case "$mode" in
    --minimal)
      tools_to_install=("${required_tools[@]}")
      log_info "安装模式: 最小依赖"
      ;;
    --dev)
      tools_to_install=("${required_tools[@]}" "${recommended_tools[@]}" "${dev_tools[@]}")
      log_info "安装模式: 全部 + 开发依赖"
      ;;
    --all|*)
      tools_to_install=("${required_tools[@]}" "${recommended_tools[@]}")
      log_info "安装模式: 全部推荐依赖"
      ;;
  esac
  echo ""

  # 安装工具
  local failed=()
  for tool in "${tools_to_install[@]}"; do
    if ! install_tool "$tool" "$pkg_manager"; then
      failed+=("$tool")
    fi
  done
  echo ""

  # 验证安装
  log_info "=== 安装验证 ==="
  echo ""
  echo "必需工具:"
  for tool in "${required_tools[@]}"; do
    if check_command "$tool"; then
      echo "  ✅ $tool: $(which $tool)"
    else
      echo "  ❌ $tool: 未安装"
    fi
  done
  echo ""
  echo "复杂度工具:"
  for tool in "${recommended_tools[@]}"; do
    if check_command "$tool"; then
      echo "  ✅ $tool: $(which $tool)"
    else
      echo "  ⚠️ $tool: 未安装（可选）"
    fi
  done
  echo ""

  if [[ "$mode" == "--dev" ]]; then
    echo "开发工具:"
    for tool in "${dev_tools[@]}"; do
      if check_command "$tool"; then
        echo "  ✅ $tool: $(which $tool)"
      else
        echo "  ⚠️ $tool: 未安装（可选）"
      fi
    done
    echo ""
  fi

  # 总结
  if [ ${#failed[@]} -eq 0 ]; then
    log_info "✅ 所有依赖安装完成！"
  else
    log_warn "以下工具安装失败，请手动安装: ${failed[*]}"
  fi
}

# 帮助信息
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat << 'EOF'
DevBooks 系统依赖安装脚本

用法:
  ./scripts/install-dependencies.sh [选项]

选项:
  --minimal   只安装必需依赖 (jq, ripgrep)
  --all       安装所有推荐依赖（默认）
  --dev       额外安装开发依赖 (shellcheck)
  --help      显示此帮助信息

依赖说明:
  必需依赖:
    - jq        JSON 处理（Hook 输出格式化）
    - ripgrep   代码搜索（符号定义查找）

  推荐依赖:
    - scc       通用复杂度计算（JS/TS/Go/Java 等）
    - radon     Python 圈复杂度
    - gocyclo   Go 圈复杂度

  开发依赖:
    - shellcheck  Shell 脚本静态分析

示例:
  ./scripts/install-dependencies.sh           # 安装全部推荐依赖
  ./scripts/install-dependencies.sh --minimal # 只安装必需依赖
  ./scripts/install-dependencies.sh --dev     # 安装全部 + 开发依赖
EOF
  exit 0
fi

main "$@"
