#!/bin/bash
# DevBooks 全局 Hook 安装脚本
# 用途：安装 Augment 风格的自动上下文注入功能
# 效果：所有代码项目自动获得代码片段注入、热点文件分析

set -e

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[DevBooks]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[DevBooks]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[DevBooks]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

log_info "开始安装 DevBooks 全局 Hook..."

# 1. 创建目录
mkdir -p "$HOOKS_DIR"
log_ok "目录已创建: $HOOKS_DIR"

# 2. 复制 Hook 脚本
cp "$SCRIPT_DIR/augment-context-global.sh" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/augment-context-global.sh"
log_ok "Hook 脚本已安装: $HOOKS_DIR/augment-context-global.sh"

# 3. 更新 settings.json
if [ -f "$SETTINGS_FILE" ]; then
  # 备份现有配置
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"
  log_info "已备份现有配置"

  # 检查是否已有 hooks 配置
  if grep -q '"hooks"' "$SETTINGS_FILE"; then
    log_warn "settings.json 已有 hooks 配置，请手动合并以下内容："
    echo ""
    cat << 'EOF'
"hooks": {
  "UserPromptSubmit": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "~/.claude/hooks/augment-context-global.sh",
          "timeout": 5000
        }
      ]
    }
  ]
}
EOF
    echo ""
  else
    # 使用 jq 添加 hooks 配置
    if command -v jq &>/dev/null; then
      jq '. + {
        "hooks": {
          "UserPromptSubmit": [
            {
              "matcher": "",
              "hooks": [
                {
                  "type": "command",
                  "command": "~/.claude/hooks/augment-context-global.sh",
                  "timeout": 5000
                }
              ]
            }
          ]
        }
      }' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      log_ok "已更新 settings.json"
    else
      log_warn "未安装 jq，请手动编辑 $SETTINGS_FILE 添加 hooks 配置"
    fi
  fi
else
  # 创建新的 settings.json
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/augment-context-global.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
EOF
  log_ok "已创建 settings.json"
fi

# 4. 验证
log_info "验证安装..."

if [ -x "$HOOKS_DIR/augment-context-global.sh" ]; then
  log_ok "✓ Hook 脚本可执行"
else
  log_warn "✗ Hook 脚本不可执行"
fi

if grep -q "augment-context-global.sh" "$SETTINGS_FILE" 2>/dev/null; then
  log_ok "✓ settings.json 已配置"
else
  log_warn "✗ settings.json 未正确配置"
fi

echo ""
log_ok "安装完成！"
echo ""
echo "使用方法："
echo "  1. 在任意代码项目中启动 Claude Code"
echo "  2. 输入包含代码符号的问题，如：'分析 UserService 类'"
echo "  3. Claude 会自动收到相关代码片段和热点文件信息"
echo ""
echo "测试命令："
echo "  cd /path/to/your/project"
echo "  echo '{\"prompt\": \"分析 MyClass 类\"}' | ~/.claude/hooks/augment-context-global.sh"
echo ""
