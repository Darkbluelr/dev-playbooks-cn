# MCP 服务器配置指南

> Model Context Protocol (MCP) 在 Claude Code 中的配置完整指南
>
> 日期：2026-01-05
> 适用于：Claude Code CLI

---

## 📋 目录

1. [什么是 MCP](#什么是-mcp)
2. [配置文件位置和作用域](#配置文件位置和作用域)
3. [添加 MCP 服务器](#添加-mcp-服务器)
4. [管理 MCP 服务器](#管理-mcp-服务器)
5. [验证与测试](#验证与测试)
6. [通用故障排查](#通用故障排查)
7. [已配置的服务器](#已配置的服务器)

---

## 什么是 MCP

**Model Context Protocol (MCP)** 是一种开放协议，让 AI 模型（如 Claude）能够安全地访问外部工具和数据源。MCP 服务器就像 AI 的"插件系统"，极大扩展了 Claude Code 的能力。

### 工作原理

```
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│ Claude Code │ ────▶  │ MCP Server  │ ────▶  │  Code/Data  │
│   (Client)  │ ◀────  │  (Plugin)   │ ◀────  │   Source    │
└─────────────┘        └─────────────┘        └─────────────┘
```

- **Client**：Claude Code（AI 助手）
- **Server**：MCP 服务器（工具提供者）
- **Source**：代码库、数据库、API、文件系统等

### MCP 能做什么

通过 MCP 服务器，Claude Code 可以：

- 🔍 **代码分析**：符号搜索、引用查找、架构理解
- 📋 **任务管理**：创建、跟踪、管理开发任务
- 🗄️ **数据库查询**：读取和分析数据库内容
- 🌐 **API 集成**：连接 GitHub、Jira、Slack 等服务
- 📂 **文件操作**：访问特定文件系统或云存储
- 🔧 **自定义工具**：运行自己编写的工具和脚本

---

## 配置文件位置和作用域

Claude Code CLI 支持三种配置作用域，选择合适的作用域取决于你的使用场景。

### 作用域对比

| 作用域 | 配置文件 | 配置位置 | 作用范围 | 适用场景 |
|--------|----------|----------|----------|----------|
| **User Scope** | `~/.claude.json` | 顶层 `mcpServers` | 所有项目 | 常用工具（推荐）|
| **Local Scope** | `~/.claude.json` | `projects[path].mcpServers` | 特定项目路径 | 项目特定工具 |
| **Project Scope** | `项目/.mcp.json` | 顶层 `mcpServers` | 团队共享 | 团队协作工具 |

---

### 1. User Scope（全局共享）⭐ 推荐

**最常用的配置方式**，一次配置在所有项目中都可用。

**配置文件**：`~/.claude.json`

**配置位置**：顶层 `mcpServers` 字段（与 `projects` 平级）

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "some-mcp-server"],
      "env": {
        "API_KEY": "your-api-key"
      }
    }
  },
  "projects": {
    ...
  }
}
```

**使用命令**：
```bash
claude mcp add --scope user <name> <url>
```

**特点**：
- ✅ 一次配置，所有项目可用
- ✅ API keys 集中管理
- ✅ 私有配置，不会提交到 Git
- ✅ 适合日常开发工具

---

### 2. Local Scope（项目专用）

仅在特定项目路径下生效，适合项目特定的配置。

**配置文件**：`~/.claude.json`

**配置位置**：`projects["项目路径"].mcpServers` 字段中

```json
{
  "projects": {
    "/Users/username/Projects/my-project": {
      "mcpServers": {
        "project-tool": {
          "command": "/path/to/tool",
          "args": ["--project", "my-project"]
        }
      }
    }
  }
}
```

**使用命令**：
```bash
claude mcp add --scope local <name> <url>  # 或不指定（默认）
```

**特点**：
- ✅ 只在指定项目路径下可用
- ✅ 私有配置，不会提交到 Git
- ✅ 适合实验性配置
- ✅ 适合包含敏感信息的项目工具

---

### 3. Project Scope（团队共享）

团队共享的配置，可以提交到版本控制。

**配置文件**：`项目根目录/.mcp.json`

```json
{
  "mcpServers": {
    "team-tool": {
      "command": "npx",
      "args": ["-y", "team-mcp-server"],
      "env": {
        "API_KEY": "${TEAM_API_KEY}"
      }
    }
  }
}
```

**使用命令**：
```bash
claude mcp add --scope project <name> <url>
```

**特点**：
- ✅ 可提交到 Git，团队共享
- ✅ 支持环境变量引用（如 `${VAR}`）
- ✅ 需要用户批准后才能使用（安全）
- ✅ 适合团队协作工具

---

### 作用域优先级

当多个作用域定义了同名的 MCP 服务器时，优先级为：

```
Local Scope > Project Scope > User Scope
```

---

## 添加 MCP 服务器

### 方法 1：使用 CLI 命令（推荐）

#### 添加 HTTP 服务器

```bash
# 基本语法
claude mcp add --transport http <name> <url>

# 示例：添加 Notion MCP
claude mcp add --transport http notion https://mcp.notion.com/mcp

# 带认证头的示例
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

#### 添加 SSE 服务器

```bash
# 基本语法
claude mcp add --transport sse <name> <url>

# 示例：添加 Asana MCP
claude mcp add --transport sse asana https://mcp.asana.com/sse
```

#### 添加 stdio 服务器

```bash
# 基本语法
claude mcp add --transport stdio <name> --env KEY=value -- <command> [args...]

# 示例：添加本地 MCP 服务器
claude mcp add --transport stdio my-server \
  --env API_KEY=abc123 \
  -- npx -y my-mcp-server

# 示例：添加 Python 脚本
claude mcp add --transport stdio python-server \
  --env CONFIG_PATH=/path/to/config \
  -- python3 /path/to/server.py
```

**重要**：`--` 用于分隔 Claude 的参数和 MCP 服务器的命令。

---

### 方法 2：手动编辑配置文件

#### User Scope 配置

编辑 `~/.claude.json`：

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "some-mcp-server"],
      "env": {
        "API_KEY": "your-key",
        "BASE_URL": "https://api.example.com"
      }
    }
  }
}
```

#### Project Scope 配置

创建 `项目根目录/.mcp.json`：

```json
{
  "mcpServers": {
    "team-server": {
      "command": "npx",
      "args": ["-y", "team-mcp-server"],
      "env": {
        "API_KEY": "${TEAM_API_KEY}"
      }
    }
  }
}
```

---

### 方法 3：从 JSON 添加

如果你有 MCP 服务器的 JSON 配置：

```bash
claude mcp add-json my-server '{"type":"http","url":"https://api.example.com/mcp"}'
```

---

### 方法 4：从 Claude Desktop 导入

如果你已在 Claude Desktop 配置过 MCP 服务器：

```bash
claude mcp add-from-claude-desktop
```

---

## 管理 MCP 服务器

### 查看所有服务器

```bash
# 列出所有配置的 MCP 服务器
claude mcp list

# 查看特定服务器的详细信息
claude mcp get <server-name>
```

### 移除服务器

```bash
claude mcp remove <server-name>
```

### 在 Claude Code 中管理

在 Claude Code 会话中：

```
/mcp
```

这会显示所有 MCP 服务器的状态，并允许你：
- ✅ 查看服务器状态
- ✅ 重新连接失败的服务器
- ✅ 禁用/启用服务器
- ✅ 进行 OAuth 认证（对于需要的服务器）

---

## 验证与测试

### 1. 验证配置文件

```bash
# 查看 User Scope 配置
python3 -c "
import json
with open('$HOME/.claude.json') as f:
    data = json.load(f)
    if 'mcpServers' in data:
        print('User Scope MCP 服务器:')
        for name in data['mcpServers'].keys():
            print(f'  ✅ {name}')
"

# 验证 JSON 格式
cat ~/.claude.json | python3 -m json.tool
```

### 2. 在 Claude Code 中测试

重启 Claude Code 后，运行：

```
/mcp
```

**预期结果**：
```
✅ server1 - Available
✅ server2 - Available
⚠️ server3 - Failed (错误信息)
```

### 3. 测试 MCP 功能

尝试使用 MCP 服务器提供的工具：

```
列出可用的 <server-name> 工具
```

或直接使用：

```
使用 <server-name> 执行 <操作>
```

---

## 通用故障排查

### 问题 1：`/mcp` 显示 "No MCP servers configured"

**可能原因**：
- 配置文件位置错误
- JSON 格式错误
- 配置在错误的作用域

**解决方案**：

```bash
# 检查配置是否存在
python3 -c "
import json
with open('/Users/$(whoami)/.claude.json') as f:
    data = json.load(f)
    print('User Scope:', 'mcpServers' in data)
    print('服务器数量:', len(data.get('mcpServers', {})))
"

# 验证 JSON 格式
python3 -m json.tool ~/.claude.json > /dev/null && echo "JSON 格式正确" || echo "JSON 格式错误"
```

---

### 问题 2：MCP 服务器显示 "Failed"

**可能原因**：
- 服务器命令不存在
- 缺少必需的环境变量
- 网络连接问题（远程服务器）
- 权限问题

**解决方案**：

```bash
# 检查命令是否存在（对于本地服务器）
which <command>

# 测试服务器连接（对于远程服务器）
curl -I <server-url>

# 查看详细错误信息
# 在 /mcp 界面中选择 "Reconnect" 或查看日志
```

---

### 问题 3：环境变量未生效

**解决方案**：

确保环境变量正确配置在 `env` 字段中：

```json
{
  "my-server": {
    "command": "npx",
    "args": ["-y", "server"],
    "env": {
      "API_KEY": "actual-value-here",
      "NOT_LIKE_THIS": "$API_KEY"  // ❌ 不会展开
    }
  }
}
```

对于 Project Scope，可以使用环境变量引用：

```json
{
  "my-server": {
    "env": {
      "API_KEY": "${MY_API_KEY}"  // ✅ 会从环境中读取
    }
  }
}
```

---

### 问题 4：stdio 服务器无法启动

**Windows 用户特别注意**：

在 Windows 上使用 npx 需要 `cmd /c` 包装：

```bash
claude mcp add --transport stdio my-server -- cmd /c npx -y my-mcp-server
```

---

### 问题 5：OAuth 认证失败

**解决方案**：

1. 在 `/mcp` 界面中选择服务器
2. 点击 "Authenticate"
3. 如果浏览器没有自动打开，复制 URL 手动访问
4. 完成授权后返回 Claude Code

如需清除认证：
```
/mcp
# 选择服务器 -> "Clear authentication"
```

---

## 高级配置

### 环境变量展开

在 Project Scope 的 `.mcp.json` 中支持环境变量展开：

```json
{
  "mcpServers": {
    "api-server": {
      "command": "${HOME}/bin/server",
      "args": ["--config", "${PROJECT_ROOT}/config.json"],
      "env": {
        "API_KEY": "${API_KEY}",
        "FALLBACK_VALUE": "${OPTIONAL_VAR:-default-value}"
      },
      "url": "${API_BASE_URL}/mcp"
    }
  }
}
```

支持的语法：
- `${VAR}` - 展开环境变量
- `${VAR:-default}` - 如果未设置则使用默认值

---

### 配置超时

```bash
# 设置 MCP 服务器启动超时（毫秒）
export MCP_TIMEOUT=10000

# 设置 MCP 工具调用超时（毫秒）
export MCP_TOOL_TIMEOUT=30000

claude
```

---

### 限制输出大小

```bash
# 设置 MCP 工具输出的最大 token 数
export MAX_MCP_OUTPUT_TOKENS=50000

claude
```

当 MCP 工具输出超过 10,000 tokens 时会显示警告。

---

## 已配置的服务器

本项目当前配置的 MCP 服务器及其详细使用说明，请查看：

📖 **[MCP 服务器使用指南](./mcp-servers.md)**

如果你希望在 **Codex CLI** 中使用相同的 MCP 配置，请查看：

📖 **[Codex CLI MCP 配置指南](./mcp_codex.md)**

该文档包含：
- TaskMaster AI（任务管理）
- CKB (Code Knowledge Backend)（代码分析）
- tree-sitter-mcp（代码搜索）

每个服务器的详细配置、使用示例、故障排查等信息。

---

## 查找更多 MCP 服务器

### 官方服务器市场

- [Claude Code MCP 文档](https://code.claude.com/docs/en/mcp) - 官方推荐的 MCP 服务器
- [MCP 服务器目录](https://mcp.lobehub.com/) - 社区维护的 MCP 服务器列表
- [GitHub MCP Topic](https://github.com/topics/mcp) - GitHub 上的 MCP 项目

### 常用类别

- **开发工具**：GitHub, GitLab, Jira, Linear
- **数据库**：PostgreSQL, MySQL, MongoDB
- **云服务**：AWS, Azure, GCP
- **通信**：Slack, Discord, Email
- **文件存储**：Google Drive, Dropbox, S3
- **监控**：Sentry, Datadog, New Relic

---

## 企业配置

对于需要集中管理 MCP 服务器的企业环境，支持：

### 托管配置

**位置**：
- macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
- Linux/WSL: `/etc/claude-code/managed-mcp.json`
- Windows: `C:\Program Files\ClaudeCode\managed-mcp.json`

**特点**：
- 系统管理员部署
- 用户无法修改
- 强制使用指定的 MCP 服务器

### 策略配置

在托管配置中使用白名单/黑名单：

```json
{
  "allowedMcpServers": [
    { "serverName": "approved-server" },
    { "serverUrl": "https://company.com/*" }
  ],
  "deniedMcpServers": [
    { "serverName": "blocked-server" }
  ]
}
```

---

## 参考资源

### 官方文档

- [Claude Code MCP 文档](https://code.claude.com/docs/en/mcp)
- [MCP 协议规范](https://modelcontextprotocol.io/)
- [MCP SDK](https://github.com/modelcontextprotocol/sdk)

### 社区资源

- [MCP 服务器市场](https://mcp.lobehub.com/)
- [Anthropic GitHub](https://github.com/anthropics)
- [MCP 示例](https://github.com/modelcontextprotocol/servers)

---

## 总结

### 快速开始清单

- [ ] 理解三种配置作用域
- [ ] 选择合适的作用域（推荐 User Scope）
- [ ] 使用 `claude mcp add` 命令添加服务器
- [ ] 使用 `/mcp` 验证服务器状态
- [ ] 查看[已配置服务器文档](./mcp-servers.md)了解使用方法

### 最佳实践

✅ **推荐做法**：
- 使用 User Scope 配置常用工具
- API Keys 存储在配置文件的 `env` 字段
- 定期检查 `/mcp` 确保服务器正常
- 使用 Project Scope 分享团队工具

❌ **避免**：
- 在 Project Scope 配置中硬编码敏感信息
- 混用多个作用域配置相同服务器
- 忽略服务器启动失败的警告

---

**文档更新日期**：2026-01-05
**作者**：Claude Code
**相关文档**：[MCP 服务器使用指南](./mcp-servers.md)
