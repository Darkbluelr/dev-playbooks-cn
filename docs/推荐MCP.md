# 已配置的 MCP 服务器

> 本项目推荐使用的 MCP 服务器详细配置和使用指南
>
> 日期：2025-12-30
> 配置级别：User Scope（所有项目可用）

---

## 📋 目录

1. [概览](#概览)
2. [TaskMaster AI](#taskmaster-ai)
3. [CKB (Code Knowledge Backend)](#ckb-code-knowledge-backend)
4. [tree-sitter-mcp](#tree-sitter-mcp)
5. [Context7](#context7)
6. [GitHub MCP Server](#github-mcp-server)
7. [Playwright MCP](#playwright-mcp)
8. [配置位置](#配置位置)

---

## 概览

### 当前已配置的 MCP 服务器

| 服务器 | 类型 | 作用域 | 主要功能 |
|--------|------|--------|----------|
| **task-master** | 任务管理 | User Scope | AI 驱动的任务管理系统 |
| **ckb** | 代码分析 | User Scope | 代码符号搜索、引用查找 |
| **tree-sitter-mcp** | 代码搜索 | User Scope | 语义代码搜索和分析 |
| **context7** | 代码文档 | User Scope | 实时获取最新的库文档和代码示例 |
| **github** | GitHub集成 | User Scope | GitHub仓库、Issues、PR管理和自动化 |
| **playwright** | 浏览器自动化 | User Scope | 网页自动化测试、爬取和交互 |

**配置文件**：`~/.claude.json` (顶层 `mcpServers` 字段)

**作用范围**：✅ 所有项目

---

## TaskMaster AI

### 基本信息

- **npm 包**：`task-master-ai`
- **类型**：AI 驱动的任务管理系统
- **安装方式**：npx（自动下载）
- **官方文档**：[https://docs.task-master.dev](https://docs.task-master.dev)
- **GitHub**：[eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master)

### 功能特性

- ✅ **任务管理**：创建、更新、删除、搜索任务
- ✅ **优先级管理**：设置任务优先级（高、中、低）
- ✅ **状态跟踪**：待办、进行中、已完成
- ✅ **智能分析**：AI 驱动的任务分析和建议
- ✅ **自然语言交互**：通过对话管理任务
- ✅ **多模型支持**：支持 Claude、GPT 等多种 AI 模型

### 配置

```json
{
  "mcpServers": {
    "task-master": {
      "command": "npx",
      "args": ["-y", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "sk-...",
        "ANTHROPIC_BASE_URL": "https://anyrouter.top",
        "OPENAI_API_KEY": "sk-...",
        "OPENAI_BASE_URL": "https://anyrouter.top/v1",
        "TASK_MASTER_TOOLS": "core"
      }
    }
  }
}
```

### 环境变量说明

| 变量 | 必需 | 说明 |
|------|------|------|
| `ANTHROPIC_API_KEY` | ✅ | Claude 模型的 API Key |
| `ANTHROPIC_BASE_URL` | ❌ | 自定义 Anthropic API 端点 |
| `OPENAI_API_KEY` | ❌ | OpenAI GPT 模型的 API Key |
| `OPENAI_BASE_URL` | ❌ | 自定义 OpenAI API 端点 |
| `TASK_MASTER_TOOLS` | ❌ | 启用的工具集合：`core`/`standard`/`all`/自定义逗号列表 |

### 工具集合（TASK_MASTER_TOOLS）

> 说明：`task-master-ai` 实际读取的是 `TASK_MASTER_TOOLS`（不是 `TASK_MASTER_TOOL_MODE`）。

常见取值：

- `core`：精简工具集（默认/推荐）
- `standard`：标准工具集
- `all`：启用全部工具
- `tool_a,tool_b,...`：自定义工具白名单（逗号分隔）

**当前使用**：`core` 模式

### 使用示例

**创建任务**：
```
使用 task-master 创建任务：完成 MCP 配置文档
```

**列出任务**：
```
使用 task-master 列出所有待办任务
```

**更新任务状态**：
```
使用 task-master 将任务标记为已完成
```

**搜索任务**：
```
使用 task-master 搜索关于"文档"的任务
```

### 模型配置（可选）

如果想指定使用的 AI 模型，可以创建配置文件：

```bash
# 交互式配置
npx task-master-ai models --setup

# 或直接设置
npx task-master-ai models --set-main=gpt-4o
npx task-master-ai models --set-research=claude-3-5-sonnet-20241022
npx task-master-ai models --set-fallback=gpt-3.5-turbo
```

配置文件位置：`~/.taskmaster/config.json`

### 支持的 API 提供商

- Anthropic (Claude)
- OpenAI (GPT-4, GPT-3.5)
- Perplexity
- Google (Gemini)
- Mistral
- Groq
- OpenRouter
- xAI (Grok)
- Azure OpenAI
- Ollama (本地)

---

## CKB (Code Knowledge Backend)

### 基本信息

- **版本**：7.5.0
- **类型**：语言无关的代码理解层
- **安装位置**：`/usr/local/bin/ckb`
- **GitHub**：[simplyliz/codemcp](https://github.com/simplyliz/codemcp)

### 功能特性

- ✅ **符号搜索**：快速查找函数、类、变量
- ✅ **查找引用**：找到符号的所有使用位置
- ✅ **影响分析**：评估代码修改的影响范围
- ✅ **架构视图**：项目结构和依赖关系
- ✅ **Git 集成**：Blame 信息和历史追踪

### 后端支持

- **LSP** (Language Server Protocol)：支持 Python、TypeScript、Go 等
- **SCIP**：预计算索引（适用于 Go/Java/TypeScript）
- **Git**：仓库历史和 blame 信息

### 配置

```json
{
  "mcpServers": {
    "ckb": {
      "command": "/usr/local/bin/ckb",
      "args": ["mcp"]
    }
  }
}
```

### 安装步骤

#### 1. 安装 CKB 二进制

```bash
# 克隆仓库
cd ~/Projects/mcps
git clone https://github.com/simplyliz/codemcp.git
cd codemcp

# 设置 Go 代理（国内环境）
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 编译
go build -o ckb ./cmd/ckb

# 安装到系统路径
sudo cp ckb /usr/local/bin/ckb
sudo chmod +x /usr/local/bin/ckb

# 验证安装
ckb --version
```

#### 2. 安装 Python LSP 支持

```bash
pip3 install python-lsp-server

# 验证安装
python3 -m pylsp --version
```

#### 3. 为项目初始化 CKB

```bash
cd /path/to/your/project
ckb init
```

这会创建 `.ckb/config.json` 配置文件。

### 项目配置文件

位置：`项目/.ckb/config.json`

```json
{
  "backends": {
    "lsp": {
      "enabled": true,
      "servers": {
        "python": {
          "command": "python3",
          "args": ["-m", "pylsp"]
        }
      }
    },
    "git": {
      "enabled": true
    }
  }
}
```

### 使用示例

**搜索符号**：
```
使用 CKB 搜索项目中的 FastAPI 符号
```

**查找引用**：
```
使用 CKB 查找 get_user 函数的所有引用
```

**影响分析**：
```
使用 CKB 分析修改 User 类的影响
```

### 常用命令

```bash
# 查看系统状态
ckb status

# 搜索符号
ckb search <符号名>

# 查找引用
ckb refs <符号名>

# 获取架构概览
ckb arch

# 运行诊断
ckb doctor
```

### 支持的语言

- ✅ Python (通过 LSP)
- ✅ TypeScript/JavaScript (通过 LSP)
- ✅ Go (通过 SCIP + LSP)
- ✅ Java (通过 SCIP)
- ✅ 任何有 Git 历史的项目

### 注意事项

⚠️ **每个项目需要单独初始化**：虽然 CKB MCP 服务器是 User Scope（全局可用），但每个项目需要运行 `ckb init` 来创建项目特定的配置。

---

## tree-sitter-mcp

### 基本信息

- **npm 包**：`@nendo/tree-sitter-mcp`
- **类型**：语义代码搜索
- **安装方式**：npx（自动下载）
- **GitHub**：[nendo/tree-sitter-mcp](https://github.com/nendo/tree-sitter-mcp)

### 功能特性

- ✅ **实时代码解析**：无需预生成索引
- ✅ **语义搜索**：理解代码结构的搜索
- ✅ **AST 查询**：抽象语法树级别的分析
- ✅ **多语言支持**：支持主流编程语言
- ✅ **轻量级**：不需要复杂配置

### 配置

```json
{
  "mcpServers": {
    "tree-sitter-mcp": {
      "command": "npx",
      "args": ["-y", "@nendo/tree-sitter-mcp", "--mcp"]
    }
  }
}
```

### 特点

- ✅ 首次使用时自动安装
- ✅ 自动更新到最新版本
- ✅ 无需维护本地安装
- ✅ 适用于任何项目（无需初始化）
- ✅ 零配置

### 使用示例

**分析文件结构**：
```
使用 tree-sitter 分析 backend/main.py 的结构
```

**查找函数定义**：
```
使用 tree-sitter 查找所有异步函数定义
```

**代码模式搜索**：
```
使用 tree-sitter 搜索所有 try-except 块
```

### 支持的语言

- Python
- JavaScript/TypeScript
- Go
- Rust
- C/C++
- Java
- Ruby
- 以及更多...

### 优势对比

| 特性 | tree-sitter-mcp | CKB |
|------|----------------|-----|
| 安装复杂度 | 简单（自动） | 中等（需编译） |
| 项目初始化 | 不需要 | 需要 |
| 语义理解 | 中等 | 高 |
| 引用查找 | 基础 | 完整 |
| 适用场景 | 快速搜索 | 深度分析 |

---

## Context7

### 基本信息

- **npm 包**：`@upstash/context7-mcp`
- **版本**：2.0.0+
- **类型**：实时代码文档服务
- **安装方式**：npx（自动下载）
- **官方网站**：[context7.com](https://context7.com)
- **GitHub**：[upstash/context7](https://github.com/upstash/context7)

### 功能特性

- ✅ **实时文档**：获取最新的、版本特定的库文档
- ✅ **代码示例**：直接获取最新的代码示例和API使用方法
- ✅ **库匹配**：智能识别并匹配项目使用的库
- ✅ **无缝集成**：无需切换标签页查文档
- ✅ **避免幻觉**：消除过时的代码建议和不存在的API
- ✅ **广泛支持**：支持主流库和框架

### 配置

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

**带 API Key 的配置**（可选，用于更高的速率限制和私有仓库）：

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "your-api-key"
      }
    }
  }
}
```

### 环境变量说明

| 变量 | 必需 | 说明 |
|------|------|------|
| `CONTEXT7_API_KEY` | ❌ | Context7 API Key（可选，用于更高速率限制和私有仓库访问）|

**获取 API Key**：访问 [context7.com/dashboard](https://context7.com/dashboard) 创建账户并获取密钥。

### 可用工具

Context7 提供以下工具供 LLM 使用：

1. **resolve-library-id**：将库名称解析为 Context7 兼容的库 ID
   - `query` (必需): 用户的问题或任务
   - `libraryName` (必需): 要搜索的库名称

2. **query-docs**：使用库 ID 检索文档
   - `libraryId` (必需): Context7 库 ID（如 `/mongodb/docs`）
   - `query` (必需): 要获取相关文档的问题或任务

### 使用示例

#### 基础使用（推荐添加规则）

在 CLAUDE.md 或设置中添加规则，自动调用 Context7：

```markdown
Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.
```

添加此规则后，直接提问即可：

```
创建一个 Next.js 中间件，检查 cookies 中的有效 JWT，
并将未认证用户重定向到 /login
```

#### 手动触发

如果未设置规则，在提示中添加 `use context7`：

```
配置 Cloudflare Worker 脚本以缓存 JSON API 响应 5 分钟。use context7
```

#### 指定库 ID（高级）

如果已知确切的库 ID，可以直接指定：

```
使用 Supabase 实现基本身份验证。
use library /supabase/supabase for API and docs.
```

### 支持的库和框架

Context7 支持数千个库，包括但不限于：

**Web 框架**：
- Next.js, React, Vue, Angular, Svelte
- Express, Fastify, Koa, NestJS

**云服务**：
- AWS SDK, Google Cloud, Azure
- Cloudflare Workers, Vercel, Netlify

**数据库**：
- MongoDB, PostgreSQL, MySQL
- Supabase, Firebase, PlanetScale

**工具库**：
- Lodash, Axios, Prisma
- TailwindCSS, shadcn/ui

**查找更多**：访问 [context7.com](https://context7.com) 搜索可用库。

### 特点

- ✅ **零配置**：首次使用时自动安装
- ✅ **自动更新**：npx 自动使用最新版本
- ✅ **版本感知**：获取特定版本的文档
- ✅ **社区驱动**：库由社区贡献和维护
- ✅ **轻量级**：无需本地索引或预处理

### 代理配置

Context7 支持标准的 HTTPS 代理环境变量：

```bash
export https_proxy=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

### 优势对比

| 特性 | Context7 | CKB | tree-sitter-mcp |
|------|----------|-----|-----------------|
| 安装复杂度 | 简单（自动） | 中等（需编译） | 简单（自动） |
| 文档来源 | 在线最新 | 本地代码 | 本地代码 |
| 版本特定 | ✅ | ❌ | ❌ |
| 代码示例 | ✅ 最新 | ❌ | ❌ |
| 离线使用 | ❌ | ✅ | ✅ |
| 适用场景 | 查库文档 | 分析本地代码 | 搜索本地代码 |

### 故障排查

#### Context7 连接失败

**常见原因**：
- 网络连接问题
- 代理配置错误
- 速率限制（未使用 API Key）

**解决方案**：
```bash
# 测试连接
curl -I https://api.context7.com

# 检查代理设置
echo $https_proxy

# 获取 API Key 以提高速率限制
# 访问 context7.com/dashboard
```

#### 库未找到

**解决方案**：
1. 检查库名称拼写
2. 访问 [context7.com](https://context7.com) 搜索可用库
3. 如果库不存在，可以提交添加请求

#### 首次运行慢

**原因**：npx 需要下载包（正常现象）

**解决方案**：等待下载完成，后续运行会很快

---

## GitHub MCP Server

### 基本信息

- **Docker 镜像**：`ghcr.io/github/github-mcp-server`
- **版本**：0.26.3+
- **类型**：GitHub 平台集成
- **安装方式**：Docker（推荐）或源码构建
- **官方仓库**：[github/github-mcp-server](https://github.com/github/github-mcp-server)
- **维护方**：GitHub 官方

### 功能特性

- ✅ **仓库管理**：浏览代码、搜索文件、分析提交、理解项目结构
- ✅ **Issue & PR 自动化**：创建、更新、管理 Issues 和 Pull Requests
- ✅ **CI/CD 智能**：监控 GitHub Actions 工作流、分析构建失败、管理发布
- ✅ **代码分析**：检查安全发现、审查 Dependabot 警告、代码模式分析
- ✅ **团队协作**：访问讨论、管理通知、分析团队活动
- ✅ **多功能工具集**：支持 Gists、Labels、Projects、Stargazers 等

### 配置

#### 基础配置（Docker）

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE"
      }
    }
  }
}
```

#### 带工具集配置

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "-e",
        "GITHUB_TOOLSETS",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE",
        "GITHUB_TOOLSETS": "repos,issues,pull_requests,actions"
      }
    }
  }
}
```

#### GitHub Enterprise 配置

对于 GitHub Enterprise Server 或 Enterprise Cloud with data residency (ghe.com)：

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "-e",
        "GITHUB_HOST",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE",
        "GITHUB_HOST": "https://your-ghes-domain.com"
      }
    }
  }
}
```

### 获取 GitHub Personal Access Token (PAT)

#### 步骤 1：创建 PAT

1. 访问 [GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
2. 点击 **Generate new token** > **Generate new token (classic)**
3. 填写 Token 描述（如 "Claude Code MCP"）
4. 选择过期时间（建议 90 天）
5. 选择所需权限（Scopes）

#### 步骤 2：推荐的权限范围

**基础权限**（只读访问）：
- ✅ `repo` - 完整仓库访问（包括私有仓库）
- ✅ `read:org` - 读取组织信息
- ✅ `read:user` - 读取用户信息

**完整功能**（读写访问）：
- ✅ `repo` - 完整仓库访问
- ✅ `workflow` - 更新 GitHub Actions 工作流
- ✅ `admin:org` - 管理组织（如需要）
- ✅ `gist` - 创建和管理 Gists
- ✅ `notifications` - 访问通知
- ✅ `user` - 用户信息
- ✅ `read:discussion` - 读取讨论
- ✅ `write:discussion` - 写入讨论

#### 步骤 3：保存 Token

⚠️ **重要**：复制生成的 Token 并保存到安全的地方。离开页面后将无法再次查看！

#### 步骤 4：配置到 Claude Code

将 Token 添加到 `~/.claude.json` 配置文件中：

```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

### 环境变量说明

| 变量 | 必需 | 说明 |
|------|------|------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | ✅ | GitHub Personal Access Token |
| `GITHUB_TOOLSETS` | ❌ | 启用的工具集（逗号分隔） |
| `GITHUB_TOOLS` | ❌ | 启用的特定工具（逗号分隔） |
| `GITHUB_HOST` | ❌ | GitHub Enterprise 主机名 |
| `GITHUB_READ_ONLY` | ❌ | 只读模式（设为 `1` 启用） |
| `GITHUB_LOCKDOWN_MODE` | ❌ | 锁定模式（设为 `1` 启用） |
| `GITHUB_DYNAMIC_TOOLSETS` | ❌ | 动态工具集发现（设为 `1` 启用） |

### 可用工具集

GitHub MCP Server 支持通过工具集（toolsets）控制可用功能：

#### 默认工具集（无配置时）

- `context` - 用户和 GitHub 上下文信息
- `repos` - 仓库管理
- `issues` - Issue 管理
- `pull_requests` - PR 管理
- `users` - 用户信息

#### 所有可用工具集

| 工具集 | 描述 |
|--------|------|
| `context` | 🔰 当前用户和 GitHub 上下文（强烈推荐）|
| `actions` | ⚙️ GitHub Actions 工作流和 CI/CD |
| `code_security` | 🔐 代码安全扫描 |
| `dependabot` | 🤖 Dependabot 工具 |
| `discussions` | 💬 GitHub Discussions |
| `gists` | 📝 GitHub Gist |
| `git` | 🌳 Git API 低级操作 |
| `issues` | 🐛 Issue 管理 |
| `labels` | 🏷️ 标签管理 |
| `notifications` | 🔔 通知管理 |
| `orgs` | 🏢 组织管理 |
| `projects` | 📊 GitHub Projects |
| `pull_requests` | 🔀 Pull Request 管理 |
| `repos` | 📦 仓库管理 |
| `secret_protection` | 🔒 Secret 扫描 |
| `security_advisories` | 🛡️ 安全公告 |
| `stargazers` | ⭐ Star 管理 |
| `users` | 👥 用户信息 |

#### 特殊工具集

- `all` - 启用所有可用工具集
- `default` - 默认配置（context, repos, issues, pull_requests, users）

### 使用示例

#### 仓库管理

```
使用 GitHub MCP 列出我的所有仓库
```

```
获取 owner/repo 仓库的文件内容：src/main.py
```

```
搜索 owner/repo 中包含 "authentication" 的文件
```

#### Issue 管理

```
在 owner/repo 中创建一个新 Issue：标题"修复登录Bug"，描述"用户无法登录"
```

```
列出 owner/repo 中所有打开的 Issues
```

```
给 Issue #123 添加评论："已修复，请测试"
```

#### Pull Request 管理

```
在 owner/repo 创建 PR：从 feature-branch 到 main
```

```
列出 owner/repo 中所有待审查的 PRs
```

```
获取 PR #456 的评审意见
```

#### CI/CD 监控

```
查看 owner/repo 中最近的 GitHub Actions 运行状态
```

```
获取工作流运行 ID 123456 的日志
```

### 工具集配置示例

#### 只读模式（推荐新手）

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_READ_ONLY": "1"
  }
}
```

#### 指定工具集

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_TOOLSETS": "repos,issues,pull_requests,actions"
  }
}
```

#### 启用所有工具

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_TOOLSETS": "all"
  }
}
```

#### 动态工具集发现

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_DYNAMIC_TOOLSETS": "1"
  }
}
```

### 特点

- ✅ **官方支持**：GitHub 官方维护
- ✅ **功能完整**：覆盖 GitHub 平台大部分 API
- ✅ **灵活配置**：支持工具集、只读模式、锁定模式
- ✅ **企业支持**：支持 GitHub Enterprise Server 和 Cloud
- ✅ **容器化**：使用 Docker 运行，环境隔离
- ✅ **自动更新**：Docker 镜像自动获取最新版本

### 前置要求

#### 1. Docker 安装

确保已安装 Docker：

```bash
# 检查 Docker 是否安装
docker --version

# 如果未安装，请访问 https://docs.docker.com/get-docker/
```

#### 2. Docker 运行状态

```bash
# 确保 Docker 正在运行
docker ps

# 如果出错，启动 Docker Desktop 或 Docker 服务
```

#### 3. 拉取镜像（可选）

首次使用时会自动拉取，也可以提前拉取：

```bash
docker pull ghcr.io/github/github-mcp-server
```

### 优势对比

| 特性 | GitHub MCP | CKB | tree-sitter-mcp |
|------|-----------|-----|-----------------|
| 安装复杂度 | 中等（需 Docker） | 中等（需编译） | 简单（自动） |
| GitHub 集成 | ✅ 完整 | ❌ | ❌ |
| 本地代码分析 | ❌ | ✅ | ✅ |
| Issue/PR 管理 | ✅ | ❌ | ❌ |
| CI/CD 监控 | ✅ | ❌ | ❌ |
| 需要网络 | ✅ | ❌ | ❌ |
| 需要认证 | ✅ PAT | ❌ | ❌ |

### 故障排查

#### Docker 相关问题

**问题：Docker 镜像拉取失败**

```bash
# 检查 Docker 登录状态
docker logout ghcr.io

# 重新拉取镜像
docker pull ghcr.io/github/github-mcp-server
```

**问题：Docker 未运行**

```bash
# macOS: 启动 Docker Desktop
open -a Docker

# Linux: 启动 Docker 服务
sudo systemctl start docker
```

#### 权限问题

**问题：PAT 权限不足**

检查 Token 权限：
1. 访问 [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. 点击 Token 名称
3. 检查并添加缺失的权限
4. 重新生成 Token（如需要）

**问题：API 速率限制**

GitHub API 有速率限制：
- 未认证：60 次/小时
- 已认证：5000 次/小时

使用 PAT 可大幅提高限制。

#### 连接问题

**问题：无法连接到 GitHub**

```bash
# 测试网络连接
curl -I https://api.github.com

# 如果使用代理，配置 Docker 代理
# 编辑 ~/.docker/config.json
```

**问题：GitHub Enterprise 连接失败**

确保 `GITHUB_HOST` 配置正确：
- GitHub Enterprise Server: `https://your-ghes.com`
- GitHub Enterprise Cloud (ghe.com): `https://yourorg.ghe.com`

#### 工具相关问题

**问题：工具未显示**

检查工具集配置：
```bash
# 查看当前配置
cat ~/.claude.json | grep -A 20 '"github"'

# 尝试启用所有工具
# 在配置中添加 "GITHUB_TOOLSETS": "all"
```

**问题：只读操作失败**

如果只需要读取权限，使用只读模式：
```json
{
  "env": {
    "GITHUB_READ_ONLY": "1"
  }
}
```

### 安全最佳实践

#### 1. Token 管理

- ⚠️ **不要提交**：永远不要将 PAT 提交到 Git 仓库
- ⚠️ **定期轮换**：建议每 90 天轮换一次 Token
- ⚠️ **最小权限**：只授予必需的权限
- ⚠️ **及时撤销**：不再使用时立即撤销 Token

#### 2. 权限控制

- 使用只读模式（`GITHUB_READ_ONLY=1`）进行探索
- 使用工具集限制可用功能
- 对生产环境使用锁定模式（`GITHUB_LOCKDOWN_MODE=1`）

#### 3. 审计

- 定期检查 [GitHub Security Log](https://github.com/settings/security-log)
- 监控 Token 使用情况
- 及时发现异常活动

---

## Playwright MCP

### 基本信息

- **npm 包**：`@playwright/mcp@latest`
- **版本**：0.0.54+
- **类型**：浏览器自动化
- **安装方式**：npx（自动下载）
- **官方仓库**：[microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp)
- **官方网站**：[playwright.dev](https://playwright.dev)
- **维护方**：Microsoft 官方

### 功能特性

- ✅ **浏览器自动化**：使用 Playwright 自动化浏览器操作
- ✅ **无需视觉模型**：基于 Accessibility Tree 而非截图，速度快且轻量
- ✅ **确定性工具**：避免基于截图方法的模糊性
- ✅ **多浏览器支持**：Chrome、Firefox、WebKit (Safari)、Microsoft Edge
- ✅ **页面交互**：点击、输入、导航、表单提交等
- ✅ **内容提取**：获取页面文本、元素信息
- ✅ **测试断言**：可选的测试功能支持
- ✅ **PDF 生成**：可选的 PDF 导出功能
- ✅ **视觉功能**：可选的坐标点击（需要 vision 能力）

### 配置

#### 基础配置（推荐）

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest"
      ]
    }
  }
}
```

#### 带参数配置

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--browser=chrome",
        "--viewport-size=1280x720",
        "--timeout-action=10000"
      ]
    }
  }
}
```

#### Headless 模式配置

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--headless"
      ]
    }
  }
}
```

### 常用配置参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `--browser` | 浏览器类型 | chrome | chrome, firefox, webkit, msedge |
| `--headless` | 无头模式运行 | false (显示浏览器) | --headless |
| `--viewport-size` | 浏览器窗口大小 | 默认大小 | --viewport-size=1280x720 |
| `--device` | 模拟设备 | 无 | --device="iPhone 15" |
| `--timeout-action` | 操作超时（毫秒）| 5000 | --timeout-action=10000 |
| `--timeout-navigation` | 导航超时（毫秒）| 60000 | --timeout-navigation=30000 |
| `--user-agent` | 自定义 UA | 默认 UA | --user-agent="Custom UA" |
| `--ignore-https-errors` | 忽略 HTTPS 错误 | false | --ignore-https-errors |
| `--caps` | 额外功能 | 无 | --caps=vision,pdf,testing |

### 高级配置选项

#### 代理配置

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--proxy-server=http://myproxy:3128",
        "--proxy-bypass=.com,chromium.org"
      ]
    }
  }
}
```

#### 持久化用户数据

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--user-data-dir=/path/to/profile"
      ]
    }
  }
}
```

#### 隔离会话

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--isolated",
        "--storage-state=/path/to/state.json"
      ]
    }
  }
}
```

#### 启用额外功能

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--caps=vision,pdf,testing"
      ]
    }
  }
}
```

### 用户配置文件位置

Playwright MCP 默认使用持久化配置文件存储登录状态：

**macOS**：
```
~/Library/Caches/ms-playwright/mcp-{channel}-profile
```

**Linux**：
```
~/.cache/ms-playwright/mcp-{channel}-profile
```

**Windows**：
```
%USERPROFILE%\AppData\Local\ms-playwright\mcp-{channel}-profile
```

可以使用 `--user-data-dir` 参数自定义位置。

### 核心工具

Playwright MCP 提供以下核心自动化工具：

#### 1. 浏览器管理
- **打开浏览器**：启动新的浏览器实例
- **关闭浏览器**：关闭当前浏览器
- **新建标签页**：创建新的标签页
- **切换标签页**：在标签页间切换
- **关闭标签页**：关闭指定标签页

#### 2. 页面操作
- **导航**：访问 URL
- **点击**：点击页面元素
- **输入文本**：在输入框中输入内容
- **选择**：下拉菜单选择
- **提交表单**：提交表单数据
- **滚动**：页面滚动操作

#### 3. 内容提取
- **获取页面快照**：获取结构化页面内容（Accessibility Tree）
- **提取文本**：获取元素文本内容
- **获取属性**：读取元素属性
- **截图**：保存页面截图（需要 vision）

#### 4. 等待操作
- **等待元素**：等待元素出现
- **等待导航**：等待页面加载完成
- **等待条件**：等待自定义条件满足

### 可选功能（通过 --caps 启用）

#### Vision 功能
启用基于坐标的点击：
```bash
--caps=vision
```

功能：
- 基于坐标点击元素
- 需要视觉模型支持
- 适用于复杂页面布局

#### PDF 功能
启用 PDF 生成：
```bash
--caps=pdf
```

功能：
- 生成页面 PDF
- 自定义 PDF 选项
- 保存到指定路径

#### Testing 功能
启用测试断言：
```bash
--caps=testing
```

功能：
- expect() 断言
- 元素可见性检查
- 内容匹配验证

#### Tracing 功能
启用调试追踪：
```bash
--caps=tracing
```

功能：
- 记录操作轨迹
- 性能分析
- 调试辅助

### 使用示例

#### 基础浏览

```
使用 Playwright 打开浏览器，访问 https://example.com
```

#### 表单填写

```
使用 Playwright：
1. 访问 https://forms.example.com
2. 在 #username 输入 "testuser"
3. 在 #password 输入 "password123"
4. 点击 #submit 按钮
```

#### 内容提取

```
使用 Playwright 访问 https://news.example.com，提取所有文章标题
```

#### 网页测试

```
使用 Playwright 测试登录流程：
1. 访问登录页
2. 输入凭据
3. 提交表单
4. 验证是否重定向到仪表板
```

#### 截图保存

```
使用 Playwright 访问 https://example.com 并保存截图
```

### 使用场景

#### 适用于：

- 🌐 **网页测试**：自动化 UI 测试、E2E 测试
- 📊 **数据爬取**：从动态网页提取数据
- 🔐 **表单自动化**：自动填写和提交表单
- 📸 **页面截图**：批量生成网页截图
- 📄 **PDF 生成**：将网页转换为 PDF
- 🔍 **网页监控**：定期检查网页变化
- 🎯 **SPA 交互**：与 React、Vue 等单页应用交互
- 🛒 **电商操作**：自动化购物流程测试

#### 不适用于：

- ❌ **大规模爬虫**：不适合高频率大规模爬取（有性能开销）
- ❌ **实时监控**：浏览器资源占用较高
- ❌ **简单 API 调用**：使用 HTTP 客户端更高效

### 特点

- ✅ **零配置**：首次使用时自动安装
- ✅ **自动更新**：npx 自动使用最新版本
- ✅ **跨浏览器**：支持 Chrome、Firefox、WebKit、Edge
- ✅ **快速可靠**：基于 Accessibility Tree，比视觉方法更快
- ✅ **移动模拟**：支持模拟移动设备
- ✅ **网络控制**：可拦截和修改网络请求
- ✅ **文件上传/下载**：支持文件操作
- ✅ **多标签页**：并行操作多个标签页

### 前置要求

#### 1. Node.js

```bash
# 检查 Node.js 版本（需要 18+）
node --version

# 如果版本过低，请升级 Node.js
```

#### 2. 浏览器（首次运行自动安装）

Playwright 会在首次运行时自动下载所需的浏览器：
- Chromium（用于 Chrome）
- Firefox
- WebKit（用于 Safari）

可以手动安装：
```bash
npx playwright install
```

### 浏览器扩展模式（高级）

使用 Chrome 扩展连接到现有浏览器：

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--extension"
      ]
    }
  }
}
```

**前提条件**：
1. 安装 "Playwright MCP Bridge" Chrome 扩展
2. 仅支持 Edge/Chrome
3. 可以使用已登录的浏览器会话

**用途**：
- 利用现有的浏览器状态和登录会话
- 无需重新登录
- 适合需要已认证状态的操作

### 优势对比

| 特性 | Playwright MCP | Selenium | Puppeteer |
|------|---------------|----------|-----------|
| 安装复杂度 | 简单（自动） | 复杂（需驱动） | 简单 |
| 多浏览器支持 | ✅ 全面 | ✅ 全面 | ❌ 仅 Chrome |
| 速度 | ⚡ 快 | 🐢 慢 | ⚡ 快 |
| API 设计 | 现代 | 传统 | 现代 |
| 移动模拟 | ✅ | 部分 | ✅ |
| 与 Claude Code 集成 | ✅ 原生 | ❌ | ❌ |
| LLM 友好 | ✅ 结构化 | ❌ | ❌ |

### 安全与限制

#### 网站访问控制

可以限制允许访问的网站：

```bash
--allowed-origins="https://example.com;https://trusted.com"
```

或阻止特定网站：

```bash
--blocked-origins="https://malicious.com"
```

⚠️ **重要**：这不是安全边界，仅作为防护栏使用。

#### Service Workers

阻止 Service Workers：

```bash
--block-service-workers
```

#### 沙箱模式

默认启用浏览器沙箱。在某些环境（如 Docker）中可能需要禁用：

```bash
--no-sandbox
```

⚠️ **警告**：禁用沙箱会降低安全性，仅在必要时使用。

### 故障排查

#### 浏览器未安装

**问题**：首次运行时提示缺少浏览器

**解决方案**：
```bash
# 手动安装所有浏览器
npx playwright install

# 或安装特定浏览器
npx playwright install chromium
```

#### 首次运行慢

**原因**：npx 需要下载包和浏览器（正常现象）

**解决方案**：等待下载完成，后续运行会很快

#### Headless 模式调试困难

**解决方案**：
1. 移除 `--headless` 参数查看浏览器
2. 启用 tracing：`--caps=tracing`
3. 保存截图进行调试

#### 超时错误

**问题**：操作超时

**解决方案**：
```bash
# 增加超时时间
--timeout-action=30000
--timeout-navigation=90000
```

#### 权限错误

**问题**：需要某些权限（如地理位置、通知）

**解决方案**：
```bash
--grant-permissions=geolocation,clipboard-read,clipboard-write
```

#### Docker 环境问题

**问题**：在 Docker 中运行失败

**解决方案**：
```dockerfile
# Dockerfile 示例
FROM mcr.microsoft.com/playwright:v1.48.0-noble

WORKDIR /app

# 安装依赖
RUN npm install -g playwright

# 运行时使用 --no-sandbox
CMD ["npx", "@playwright/mcp@latest", "--headless", "--no-sandbox"]
```

### 独立服务器模式（高级）

在没有显示器的系统或需要远程访问时，可以运行独立 HTTP 服务器：

```bash
# 启动服务器
npx @playwright/mcp@latest --port 8931

# 在 MCP 客户端配置中
{
  "mcpServers": {
    "playwright": {
      "url": "http://localhost:8931/mcp"
    }
  }
}
```

**特点**：
- HTTP 传输
- 适合远程访问
- 适合无显示环境

### 配置文件

可以使用配置文件管理复杂设置：

```json
// playwright-mcp-config.json
{
  "browser": "chrome",
  "headless": true,
  "viewport": { "width": 1280, "height": 720 },
  "ignoreHTTPSErrors": true,
  "timeout": {
    "action": 10000,
    "navigation": 60000
  },
  "proxy": {
    "server": "http://myproxy:3128",
    "bypass": ".com,chromium.org"
  }
}
```

使用配置文件：
```bash
--config=/path/to/config.json
```

### 与 GitHub MCP Server 对比

| 特性 | Playwright MCP | GitHub MCP |
|------|---------------|-----------|
| 安装复杂度 | 简单（npx） | 中等（Docker） |
| 主要用途 | 浏览器自动化 | GitHub 集成 |
| 需要认证 | ❌（部分网站需要） | ✅ PAT |
| 网络依赖 | ✅ | ✅ |
| 资源占用 | 高（浏览器） | 低 |
| 适用场景 | 网页测试/爬取 | 代码仓库管理 |

### 与其他 MCP 服务器的协同

Playwright 可以与其他 MCP 服务器协同工作：

#### + Context7
- Playwright 访问文档网站
- Context7 获取最新 API 文档
- 结合使用获取动态生成的文档

#### + GitHub MCP
- Playwright 测试 GitHub Pages 网站
- GitHub MCP 管理源代码
- 自动化部署后的测试流程

#### + tree-sitter-mcp
- tree-sitter 分析本地测试文件
- Playwright 运行浏览器测试
- 全栈测试覆盖

### 最佳实践

#### 1. 选择合适的模式

```bash
# 开发调试：显示浏览器
--browser=chrome

# 生产环境：无头模式
--headless

# CI/CD：无头 + 沙箱禁用
--headless --no-sandbox
```

#### 2. 优化性能

```bash
# 减少超时
--timeout-action=3000

# 使用持久化会话避免重复登录
--user-data-dir=~/.playwright-profile

# 复用浏览器上下文
--shared-browser-context
```

#### 3. 保存调试信息

```bash
# 保存会话
--save-session

# 保存追踪
--save-trace

# 保存视频
--save-video=1280x720
```

#### 4. 权限管理

```bash
# 授予必要权限
--grant-permissions=geolocation,notifications

# 限制访问域名
--allowed-origins="https://trusted.com"
```

### 更新 Playwright MCP

```bash
# npx 会自动使用最新版本
# 无需手动更新

# 如需清理缓存
npx clear-npx-cache

# 重新安装浏览器
npx playwright install
```

---

## 配置位置

### User Scope 配置

**文件**：`~/.claude.json`

**结构**：
```json
{
  "mcpServers": {
    "task-master": { ... },
    "ckb": { ... },
    "tree-sitter-mcp": { ... },
    "context7": { ... },
    "github": { ... },
    "playwright": { ... }
  },
  "projects": {
    ...
  }
}
```

### Codex CLI 配置（与 Claude Code 同步）

如果你也在使用 Codex CLI，并希望复用同一套 MCP：

- **Codex 配置文件**：`~/.codex/config.toml`
- **字段**：`mcp_servers`
- **重要**：部分版本需要开启 `features.rmcp_client = true` 才会在 Codex 中加载 MCP 工具
- **推荐**：使用本仓库脚本从 Claude 配置一键同步到 Codex：`scripts/sync_mcp_from_claude_to_codex.py`
- **教程**：`mcp_codex.md`

### 项目特定配置

**CKB 配置**：`项目/.ckb/config.json`

**TaskMaster 配置**：`~/.taskmaster/config.json`（可选）

---

## 使用场景

### TaskMaster AI 适用于

- 📋 项目任务管理和追踪
- ✅ 开发待办事项记录
- 🔧 代码重构任务规划
- 🐛 Bug 修复任务跟踪
- 📊 项目进度管理

### CKB 适用于

- 🏗️ 大型代码库的架构理解
- 🔍 查找符号引用
- 📈 影响分析（修改代码前评估影响）
- 🕒 Git blame 和历史分析
- 🔗 依赖关系追踪

### tree-sitter-mcp 适用于

- ⚡ 快速代码搜索
- 🌳 语义分析
- 🆕 临时项目（无需初始化）
- 🪶 轻量级代码理解
- 🔎 代码模式匹配

### Context7 适用于

- 📚 查询最新的库文档和 API
- 💡 获取实时代码示例
- 🔧 学习新库或框架的使用方法
- ⚡ 避免过时的代码建议
- 🌐 快速了解库的配置和最佳实践

### GitHub MCP Server 适用于

- 🔍 浏览和搜索 GitHub 仓库
- 🐛 创建和管理 Issues
- 🔀 创建和审查 Pull Requests
- ⚙️ 监控 CI/CD 工作流
- 👥 团队协作和项目管理
- 🔐 安全扫描和 Dependabot 管理

### Playwright MCP 适用于

- 🌐 网页自动化测试和 E2E 测试
- 📊 从动态网页爬取数据
- 🔐 自动化表单填写和提交
- 📸 批量生成网页截图
- 📄 将网页转换为 PDF
- 🔍 定期监控网页变化
- 🎯 与单页应用（React、Vue 等）交互
- 🛒 电商流程自动化测试

---

## 故障排查

### TaskMaster 无法启动

**常见原因**：
- 缺少 API Key
- API 端点不可访问
- npx 下载失败

**解决方案**：
```bash
# 检查环境变量
cat ~/.claude.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
env = data['mcpServers']['task-master']['env']
print('环境变量:', list(env.keys()))
"

# 测试 API 连接
curl -I https://anyrouter.top
```

### CKB 显示 "LSP not ready"

**解决方案**：
```bash
# 验证 pylsp 安装
python3 -m pylsp --version

# 检查项目配置
cat .ckb/config.json

# 重新初始化
ckb init
```

### tree-sitter-mcp 首次运行慢

**原因**：npx 需要下载包（正常现象）

**解决方案**：等待下载完成，后续运行会很快

### Context7 相关问题

请参考 [Context7 章节](#context7) 的故障排查部分。

### GitHub MCP Server 相关问题

请参考 [GitHub MCP Server 章节](#github-mcp-server) 的故障排查部分。

### Playwright MCP 相关问题

请参考 [Playwright MCP 章节](#playwright-mcp) 的故障排查部分。

---

## 维护和更新

### 更新 TaskMaster

```bash
# 使用 npx 会自动使用最新版本
# 无需手动更新
```

### 更新 CKB

```bash
cd ~/Projects/mcps/codemcp
git pull
go build -o ckb ./cmd/ckb
sudo cp ckb /usr/local/bin/ckb
```

### 更新 tree-sitter-mcp

```bash
# 使用 npx -y 会自动下载最新版本
# 无需手动更新
```

### 更新 Context7

```bash
# 使用 npx -y 会自动下载最新版本
# 无需手动更新
```

### 更新 GitHub MCP Server

```bash
# Docker 镜像会自动拉取最新版本
# 或手动更新：
docker pull ghcr.io/github/github-mcp-server
```

### 更新 Playwright MCP

```bash
# npx 会自动使用最新版本
# 无需手动更新

# 如需清理缓存
npx clear-npx-cache

# 重新安装浏览器
npx playwright install
```

---

## 参考资源

### TaskMaster AI
- [官方文档](https://docs.task-master.dev)
- [GitHub 仓库](https://github.com/eyaltoledano/claude-task-master)
- [npm 包](https://www.npmjs.com/package/task-master-ai)

### CKB
- [GitHub 仓库](https://github.com/simplyliz/codemcp)
- [MCP 服务器列表](https://mcp.lobehub.com/)

### tree-sitter-mcp
- [GitHub 仓库](https://github.com/nendo/tree-sitter-mcp)
- [npm 包](https://www.npmjs.com/package/@nendo/tree-sitter-mcp)

### Context7
- [官方网站](https://context7.com)
- [GitHub 仓库](https://github.com/upstash/context7)
- [npm 包](https://www.npmjs.com/package/@upstash/context7-mcp)
- [获取 API Key](https://context7.com/dashboard)
- [添加项目到 Context7](https://github.com/upstash/context7#-adding-projects)

### GitHub MCP Server
- [GitHub 仓库](https://github.com/github/github-mcp-server)
- [Docker 镜像](https://github.com/github/github-mcp-server/pkgs/container/github-mcp-server)
- [官方文档](https://github.com/github/github-mcp-server#readme)
- [安装指南](https://github.com/github/github-mcp-server/tree/main/docs)
- [创建 PAT](https://github.com/settings/tokens)

### Playwright MCP
- [官方仓库](https://github.com/microsoft/playwright-mcp)
- [官方网站](https://playwright.dev)
- [npm 包](https://www.npmjs.com/package/@playwright/mcp)
- [Chrome 扩展](https://github.com/microsoft/playwright-mcp/tree/main/extension)
- [Docker 使用](https://github.com/microsoft/playwright-mcp#docker)

### 通用资源
- [MCP 协议规范](https://modelcontextprotocol.io/)
- [Claude Code MCP 文档](https://docs.claude.com/en/docs/claude-code/mcp)
- [MCP 服务器市场](https://mcp.lobehub.com/)

---

**文档更新日期**：2025-12-30
**作者**：Claude Code
**维护**：定期更新配置和使用说明
