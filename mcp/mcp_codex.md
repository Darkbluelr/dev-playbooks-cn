# MCP 服务器配置指南（Codex CLI）

> Model Context Protocol (MCP) 在 Codex CLI 中的配置与管理指南  
> 日期：2025-12-31  
> 适用于：OpenAI Codex CLI（本地命令行）

---

## 📋 目录

1. [什么是 MCP](#什么是-mcp)
2. [配置文件位置与作用域](#配置文件位置与作用域)
3. [添加 MCP 服务器（推荐：CLI）](#添加-mcp-服务器推荐cli)
4. [管理 MCP 服务器](#管理-mcp-服务器)
5. [一键同步：Claude Code → Codex CLI（本项目推荐）](#一键同步claude-code--codex-cli本项目推荐)
6. [本项目的 MCP 服务器清单](#本项目的-mcp-服务器清单)
7. [验证与故障排查](#验证与故障排查)

---

## 什么是 MCP

**Model Context Protocol (MCP)** 是一种开放协议，让 Codex 这类 LLM Client 能够通过“服务器（Server）”访问外部工具与数据源（代码检索、任务管理、GitHub、浏览器自动化等）。

---

## 配置文件位置与作用域

### 1) 配置文件位置

Codex CLI 的默认配置文件为：

- `~/.codex/config.toml`（也可通过环境变量 `CODEX_HOME` 改到 `$CODEX_HOME/config.toml`）

### 1.1) 启用 MCP（重要）

在部分 Codex 版本中，MCP 客户端能力处于实验特性开关 `rmcp_client` 之后。  
如果你在 Codex UI 里看到 **“No MCP servers configured”**，但 `codex mcp list` 明明已经有配置，通常就是因为这个开关没开。

在 `~/.codex/config.toml` 里加入（或确保存在）：

```toml
[features]
rmcp_client = true
```

临时启用（仅对本次运行生效）也可以用：

```bash
codex --enable rmcp_client
```

### 2) MCP 配置结构（TOML）

Codex 使用 `mcp_servers` 字段配置 MCP 服务器（全局配置，所有项目可用）：

```toml
[mcp_servers.tree-sitter-mcp]
command = "npx"
args = ["-y", "@nendo/tree-sitter-mcp", "--mcp"]

[mcp_servers.github]
command = "docker"
args = ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"]

[mcp_servers.github.env]
GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_xxx"
```

> 注意：`[mcp_servers.<name>.env]` 下通常会存放密钥/Token，属于敏感信息（不要提交到 Git、注意备份与权限）。

---

## 添加 MCP 服务器（推荐：CLI）

Codex 提供了实验性的 MCP 管理命令：`codex mcp ...`

### 1) 添加 stdio 服务器（本项目使用的类型）

基本语法：

```bash
codex mcp add <name> -- <command> [args...]
```

示例（tree-sitter）：

```bash
codex mcp add tree-sitter-mcp -- npx -y @nendo/tree-sitter-mcp --mcp
```

### 2) 添加带环境变量的 stdio 服务器

基本语法：

```bash
codex mcp add <name> --env KEY=VALUE -- <command> [args...]
```

示例（GitHub MCP，Docker 方式）：

```bash
# 建议：先把 Token 放到环境变量，避免出现在 shell history 里
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxx"
codex mcp add github \
  --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
  -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
unset GITHUB_PERSONAL_ACCESS_TOKEN
```

### 3) 添加 streamable HTTP 服务器（可选）

如果你的 MCP Server 是“可流式 HTTP”：

```bash
codex mcp add <name> --url https://example.com/mcp
```

如需 bearer token，可使用：

```bash
codex mcp add <name> --url https://example.com/mcp --bearer-token-env-var MY_TOKEN_ENV
```

---

## 管理 MCP 服务器

### 列出服务器

```bash
codex mcp list
```

### 查看单个服务器详情

```bash
codex mcp get <name>
codex mcp get <name> --json
```

### 删除服务器

```bash
codex mcp remove <name>
```

---

## 一键同步：Claude Code → Codex CLI（本项目推荐）

本仓库提供同步脚本：`scripts/sync_mcp_from_claude_to_codex.py`

它会：

1. 读取 `~/.claude.json` 的 `mcpServers`
2. 使用 `codex mcp remove/add` 同步到 `~/.codex/config.toml` 的 `mcp_servers`
3. （默认）确保 `features.rmcp_client = true`，让 Codex 能真正加载 MCP 工具
4. （默认）对已知会“向 stdout 打日志”的 Node MCP 做 Codex 兼容修正（见下文故障排查）

运行：

```bash
python3 scripts/sync_mcp_from_claude_to_codex.py
```

> 安全提醒：该同步会把 `~/.claude.json` 里的 `env`（可能包含密钥/Token）写入 `~/.codex/config.toml`，请确保两者都处于你的本机私有配置范围内。

---

## 本项目的 MCP 服务器清单

本项目使用的 MCP 服务器列表与用途说明见：`mcp-servers.md`

当前清单（与 Claude Code 保持一致）：

- `task-master`：任务管理（TaskMaster AI）
- `ckb`：代码符号/引用分析（CKB）
- `tree-sitter-mcp`：语义代码搜索（tree-sitter）
- `context7`：实时库文档（Context7）
- `github`：GitHub 平台集成（GitHub MCP Server）
- `playwright`：浏览器自动化（Playwright MCP）

---

## 验证与故障排查

### 1) 验证是否配置成功

```bash
codex mcp list
```

若显示 `No MCP servers configured yet`，说明还没添加成功。

### 2) 常见问题

#### `codex mcp list` 显示空，但你确定之前配过

优先检查 `~/.codex/config.toml` 里是否还存在 `mcp_servers` 段落：

```bash
rg -n "^\\[mcp_servers\\." ~/.codex/config.toml
```

如果 `mcp_servers` 段落消失，通常是 **有其他工具重写了 `~/.codex/config.toml`**（例如某些“激活器/代理配置工具”只写模型提供商配置时会覆盖整个文件）。  
解决：重新运行本仓库同步脚本恢复 MCP 段落：

```bash
python3 scripts/sync_mcp_from_claude_to_codex.py
```

#### 你在用自定义 Codex Wrapper（会 `cat > ~/.codex/config.toml`）

如果你使用了自定义的 Codex 启动函数/脚本，并且它会动态生成配置（典型特征是脚本里有 `cat > "$HOME/.codex/config.toml"` 这类覆盖写入），那么你每次启动 Codex 都会把 `mcp_servers` 覆盖掉，导致：

- `codex mcp list` 变空
- Codex TUI `/mcp` 显示 “No MCP servers configured”

推荐做法：

1. 让你的 wrapper **在覆盖写入前**先从旧 `config.toml` 提取尾部（通常是 `[features]`/`[mcp_servers.*]`），覆盖写入后再追加回去。
2. 或者改用不覆盖配置的启动方式（直接运行 `codex`，只通过环境变量提供 key）。

#### Codex UI 显示 “No MCP servers configured”，但 `codex mcp list` 有内容

1. 确认特性开关已开启：`codex features list | rg rmcp_client`
2. 确认当前终端的 `CODEX_HOME` 与写入位置一致：`echo "$CODEX_HOME"`（默认应为空或 `~/.codex`）

#### `codex: command not found`

- 安装：`npm i -g @openai/codex` 或 `brew install --cask codex`
- 确认：`which codex` / `codex --version`

#### `npx` 首次运行很慢 / 失败

- 原因：首次需要下载包（正常现象）
- 解决：确保网络可用；必要时配置 npm registry/proxy；重试即可

#### `MCP startup failed: handshaking with MCP server failed: connection closed: initialize response`

这通常意味着 **MCP Server 在握手阶段退出**，或 **向 stdout 输出了非 JSON 行**（例如 `[INFO] ...` / `[WARN] ...`），导致 Codex 的 stdio MCP 客户端无法解析握手响应。

本项目里已知容易触发的两个 Server：

- `task-master`（`task-master-ai`）：在某些项目状态下会输出 `No configuration file found...` 到 stdout
- `tree-sitter-mcp`（`@nendo/tree-sitter-mcp`）：启动时会 `console.info` 到 stdout

解决（推荐）：直接运行同步脚本（默认已开启 `--apply-codex-fixups`），它会自动：

- 为 `tree-sitter-mcp` 追加 `--mcp`
- 在 `$CODEX_HOME/mcp-preloads/` 写入 Node preload，并通过 `NODE_OPTIONS=--require=...` 把 stdout 日志重定向到 stderr / 抑制 warning

```bash
python3 scripts/sync_mcp_from_claude_to_codex.py
```

手动修复（不推荐，但可用）：

1) 创建 preload 文件（以默认 `~/.codex` 为例；如果你设置过 `CODEX_HOME`，请替换路径）：

```bash
mkdir -p ~/.codex/mcp-preloads

cat > ~/.codex/mcp-preloads/task-master-ai.cjs <<'JS'
global._tmSuppressConfigWarnings = true;
console.log = console.error;
console.info = console.error;
console.debug = console.error;
JS

cat > ~/.codex/mcp-preloads/tree-sitter-mcp.cjs <<'JS'
console.log = console.error;
console.info = console.error;
console.debug = console.error;
JS
```

2) 重新添加 MCP（示例只展示关键点，API Key 请用你自己的环境变量注入）：

```bash
codex mcp remove task-master
codex mcp add task-master \
  --env NODE_OPTIONS="--require=$HOME/.codex/mcp-preloads/task-master-ai.cjs" \
  --env TASK_MASTER_TOOLS="core" \
  --env OPENAI_API_KEY="$OPENAI_API_KEY" \
  -- npx -y task-master-ai

codex mcp remove tree-sitter-mcp
codex mcp add tree-sitter-mcp \
  --env NODE_OPTIONS="--require=$HOME/.codex/mcp-preloads/tree-sitter-mcp.cjs" \
  -- npx -y @nendo/tree-sitter-mcp --mcp
```

> 改完配置后建议**重启一次 Codex TUI 会话**再 `/mcp`，因为 MCP 通常在会话启动时加载。

#### Docker 相关报错（GitHub MCP）

- 检查 Docker 是否可用：`docker ps`
- 确保镜像可拉取：`docker pull ghcr.io/github/github-mcp-server`
