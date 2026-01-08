# DevBooks 全局 Hook 安装指南

## 功能说明

安装后，**所有代码项目**将自动获得 Augment 风格的上下文增强：

| 功能 | 说明 |
|------|------|
| 代码片段注入 | 自动搜索并注入与问题相关的代码 |
| 热点文件分析 | 显示最近 30 天高频修改的文件 |
| 工具建议 | 提示可用的 CKB 分析工具 |
| 项目检测 | 自动识别代码项目，非代码目录不触发 |

## 安装方法

### 方法 1：运行安装脚本（推荐）

```bash
cd /path/to/dev-playbooks
./setup/global-hooks/install.sh
```

### 方法 2：手动安装

1. **复制 Hook 脚本**

```bash
mkdir -p ~/.claude/hooks
cp setup/global-hooks/augment-context-global.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/augment-context-global.sh
```

2. **配置 settings.json**

编辑 `~/.claude/settings.json`，添加：

```json
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
```

### 方法 3：让 AI 安装

在 Claude Code 中说：

> 请帮我安装 DevBooks 的全局 Hook 功能。运行 `setup/global-hooks/install.sh`。

## 验证安装

```bash
# 测试 Hook 输出
cd /path/to/any/code/project
echo '{"prompt": "分析 MyClass 类"}' | ~/.claude/hooks/augment-context-global.sh
```

预期输出：

```json
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "[DevBooks 自动上下文]\n\n📦 相关代码：..."
  }
}
```

## 使用效果

安装后，在任意代码项目中输入：

```
分析 UserService 类的实现
```

Claude 将收到类似这样的注入上下文：

```
[DevBooks 自动上下文]

💡 提示：可启用 CKB 加速代码分析

📦 相关代码：

🔍 UserService:
  backend/services/user_service.py:15
  class UserService:
      """用户服务实现"""
      ...

🔥 热点文件：
  🔥 src/api/routes.py (12 changes)
  🔥 src/models/user.py (8 changes)

💡 可用工具：analyzeImpact / findReferences / getCallGraph
```

## 卸载

```bash
rm ~/.claude/hooks/augment-context-global.sh
# 然后从 ~/.claude/settings.json 中移除 hooks 配置
```

## 依赖

- `jq` - JSON 处理（安装：`brew install jq`）
- `rg` (ripgrep) - 快速搜索（安装：`brew install ripgrep`）

如果没有 ripgrep，会降级使用 grep，但速度较慢。

## 与项目级 Hook 的区别

| 类型 | 配置位置 | 适用范围 |
|------|----------|----------|
| 全局 Hook | `~/.claude/` | 所有项目 |
| 项目 Hook | `.claude/` | 单个项目 |

全局 Hook 会自动检测项目类型，只在代码项目中激活。
