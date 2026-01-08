# setup/（上下文协议适配器）

目标：把 **DevBooks Skills（`devbooks-*`）** 接入你的"上下文协议/上下文管理工具"，让项目具备统一、可追溯的落盘约定。

## 🚀 快速开始（推荐）

**一键安装所有功能**：

```bash
./setup/global-hooks/install.sh
```

或让 AI 执行：
> 请按照 `setup/openspec/完整安装提示词.md` 完成 DevBooks 完整安装。

## 目录

| 目录 | 说明 |
|------|------|
| `openspec/` | OpenSpec 协议适配器 + **完整安装提示词** |
| `global-hooks/` | 全局 Hook 安装（Augment 风格上下文注入） |
| `hooks/` | Git Hooks + Claude Code Hooks 模板 |
| `template/` | 协议无关的集成模板 |

## 安装文档索引

| 文档 | 用途 |
|------|------|
| `openspec/完整安装提示词.md` | **统一入口**：安装所有组件（Hook + MCP + OpenSpec + Embedding） |
| `openspec/安装提示词.md` | 仅 OpenSpec 协议集成 |
| `global-hooks/README.md` | 仅全局 Hook 安装 |
| `hooks/README.md` | Git Hooks 配置 |

## 核心概念

DevBooks Skills 本身是 **协议无关** 的；它们只依赖两个目录根的定义：
- `<truth-root>`：当前真理目录根（默认建议 `specs/`）
- `<change-root>`：变更包目录根（默认建议 `changes/`）

不同上下文协议只是把这两个目录根"映射"到各自的目录与项目指路牌文件里。

## 安装后效果

- ✅ 每次对话自动注入相关代码片段和热点文件
- ✅ CKB 图分析工具可用（analyzeImpact/findReferences/getCallGraph）
- ✅ DevBooks Skills 可用（devbooks-coder/devbooks-test-owner 等）
- ✅ 全局生效，无需每个项目单独配置

