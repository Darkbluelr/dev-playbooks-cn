# mcp

## 修改需求

### 需求：提供 DevBooks MCP Server 子项目

系统必须提供 DevBooks MCP Server 子项目，用于 MCP 工具集成。

#### 场景：构建 MCP Server
- **当** 在 `mcp/devbooks-mcp-server/` 执行 `npm install` 与 `npm run build`
- **那么** 产物 `dist/index.js` 可用于 MCP 配置
- **证据**：`mcp/devbooks-mcp-server/package.json`，`mcp/devbooks-mcp-server/README.md`

### 需求：提供 MCP 配置指南

系统必须提供 MCP 配置指南，说明 Claude Code 与 Codex CLI 的配置方式。

#### 场景：配置 Claude Code 与 Codex CLI
- **当** 阅读 MCP 配置文档
- **那么** 可以找到配置文件位置与示例配置
- **证据**：`mcp/mcp_claude.md`，`mcp/mcp_codex.md`

### 需求：提供 Claude 到 Codex 的 MCP 配置同步脚本

系统必须提供从 Claude 配置同步到 Codex 配置的脚本。

#### 场景：执行同步脚本
- **当** 运行 `python3 scripts/sync_mcp_from_claude_to_codex.py`
- **那么** 可将 Claude MCP 配置同步到 Codex 配置
- **证据**：`scripts/sync_mcp_from_claude_to_codex.py`，`mcp/mcp_codex.md`
