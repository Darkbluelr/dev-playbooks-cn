# DevBooks / Dev Playbooks

DevBooks 是一套面向 **Claude Code / Codex CLI** 的「代理式 AI 编程工作流」：通过 **Skills + 上下文协议适配器**，把大型项目变更做成可控、可追溯、可归档的闭环（协议化上下文、可执行验收锚点、角色隔离、影响分析等）。

## 快速开始（安装到本机）

在本仓库根目录执行：

```bash
./scripts/install-skills.sh
```

如果你主要用 Codex CLI，并希望安装命令入口（prompts）：

```bash
./scripts/install-skills.sh --with-codex-prompts
```

## 接入你的项目（上下文协议适配）

- OpenSpec 项目：`setup/openspec/README.md`
- 协议无关模板：`setup/template/DevBooks集成模板（协议无关）.md`
- 自动化配置（Git Hooks / CI/CD）：`setup/hooks/README.md`
- 总览：`setup/README.md`

## 文档索引

- 入口手册：`使用说明书.md`
- Skills 速查表：`Skills使用说明.md`
- 角色说明：`角色使用说明.md`
- Skill 开发指南：`Skill开发指南.md`
- MCP 相关：`mcp/mcp-servers.md`、`mcp/mcp_codex.md`、`mcp/mcp_claude.md`

## 仓库结构

- `skills/`：`devbooks-*` skills 源码
- `prompts/`：Codex CLI 的 prompt 入口（可选安装）
- `setup/`：上下文协议适配器与集成模板
- `scripts/`：安装与辅助脚本
- `templates/`：CI/CD 模板、联邦配置模板、GitHub 模板等
- `mcp/`：MCP 配置与说明

