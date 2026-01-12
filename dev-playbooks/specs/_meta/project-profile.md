# 项目画像：DevBooks / Dev Playbooks

## 1) 项目概览

### 1.1 目标用户与使用场景

- 目标用户：使用 Claude Code 或 Codex CLI 的开发者
- 使用场景：在项目中接入 DevBooks Skills、上下文协议适配、自动化守门与 MCP 工具
- 证据：`README.md`

### 1.2 主要能力清单

1. Skills 安装与分发（22+ 专业 Skills）
2. DevBooks 协议集成
3. 协议发现与配置解析
4. MCP 服务器与配置管理
5. 自动化守门与 CI 模板

## 2) 技术栈与运行时

### 2.1 语言与运行时

- Bash 脚本：安装、Hook、工具脚本
  - 证据：`scripts/install-skills.sh`，`setup/global-hooks/install.sh`，`tools/devbooks-embedding.sh`
- TypeScript / Node.js：DevBooks MCP Server
  - 证据：`mcp/devbooks-mcp-server/package.json`
- Python：配置同步脚本
  - 证据：`scripts/sync_mcp_from_claude_to_codex.py`
- Markdown：主要文档与规范载体
  - 证据：`README.md`，`使用说明书.md`

### 2.2 关键依赖与工具

- Node.js 版本要求：>= 18
  - 证据：`mcp/devbooks-mcp-server/package.json`
- 构建工具：TypeScript 编译器 tsc
  - 证据：`mcp/devbooks-mcp-server/package.json`
- 包管理器：npm
  - 证据：`mcp/devbooks-mcp-server/README.md`

## 3) Bounded Contexts（限界上下文）

| Context | 职责 | 核心 Entity | 上游依赖 | 下游消费者 | ACL |
|---|---|---|---|---|---|
| 安装与分发 | 将 Skills 与 Prompts 安装到本地运行时 | Skill@Entity, Prompt@Entity, InstallScript@Entity | 仓库目录结构 | Claude Code, Codex CLI | 无 |
| 上下文注入 | 为对话自动注入代码上下文 | HookScript@Entity, SettingsConfig@Entity | 本地配置文件 | Claude Code | 无 |
| 协议适配 | 将 DevBooks 协议映射到 DevBooks 或模板协议 | ProtocolConfig@Entity, AgentsDoc@Entity | DevBooks 项目 | DevBooks Skills | 无 |
| MCP 与索引 | 提供 MCP Server 与配置指引 | MCPServer@Entity, MCPConfig@Entity, Indexer@Entity | Node.js 运行时 | Claude Code, Codex CLI | 外部 MCP 服务配置 |
| 语义检索 | Embedding 生成与语义检索 | EmbeddingConfig@Entity, EmbeddingIndex@Entity | Embedding API | Hook 与搜索脚本 | Embedding API 提供商 |

## 4) 仓库结构与模块边界

### 4.1 目录职责

- `skills/`：DevBooks Skills 源码
- `prompts/`：Codex CLI 的命令入口
- `setup/`：协议适配模板与安装脚本
- `scripts/`：安装与辅助脚本
- `mcp/`：MCP 配置与 DevBooks MCP Server
- `tools/`：Embedding 与索引工具
- `templates/`：CI 模板与配置模板
- `docs/`：对外说明文档
- `dev-playbooks/`：DevBooks 协议与项目规则

### 4.2 已知依赖方向（基于脚本与文档引用）

- `scripts/install-skills.sh` 读取 `skills/` 与 `prompts/` 并复制到用户目录
- `setup/README.md` 引导执行 `scripts/install-skills.sh` 与 `setup/global-hooks/install.sh`
- `docs/embedding-quickstart.md` 引导执行 `tools/devbooks-embedding.sh`

## 5) 开发与调试（本地）

| 场景 | 命令 | 证据 |
|---|---|---|
| 安装 Skills | `./scripts/install-skills.sh` | `README.md` |
| 安装 Codex Prompts | `./scripts/install-skills.sh --with-codex-prompts` | `README.md` |
| 安装全局 Hook | `./setup/global-hooks/install.sh` | `setup/README.md` |
| 构建 MCP Server | `cd mcp/devbooks-mcp-server && npm install && npm run build` | `mcp/devbooks-mcp-server/README.md` |
| Embedding 构建 | `./tools/devbooks-embedding.sh build` | `docs/embedding-quickstart.md` |

## 6) 质量闸门（现状）

- 项目级统一测试入口：TBD（验证：确认是否存在 CI 或测试脚本）
- MCP Server 构建：`npm run build`
  - 证据：`mcp/devbooks-mcp-server/package.json`
- Lint 与类型检查：TBD（验证：查找仓库内的 lint 或 typecheck 命令）
- 安全扫描：TBD（验证：查找是否有 SAST 或 secret scan 说明）

## 7) 对外契约与数据定义（现状）

- Skills 安装脚本参数与目标路径
  - 证据：`scripts/install-skills.sh`
- Claude 全局 Hook 安装与配置文件位置
  - 证据：`setup/global-hooks/install.sh`
- DevBooks 协议集成与配置模板
  - 证据：`setup/dev-playbooks/README.md`，`setup/dev-playbooks/template.devbooks-config.yaml`
- 协议发现脚本输出格式
  - 证据：`scripts/config-discovery.sh`
- MCP 配置位置与用法
  - 证据：`mcp/mcp_claude.md`，`mcp/mcp_codex.md`
- Embedding 配置与索引位置
  - 证据：`docs/embedding-guide.md`，`tools/devbooks-embedding.sh`
- CI 模板与守门配置
  - 证据：`templates/ci/README.md`

## 8) 规格与变更包格式约定

- 规格增量段落标题：`## 新增需求`、`## 修改需求`、`## 移除需求`、`## 重命名需求`
- 需求标题格式：`### 需求：<名称>`
- 场景标题格式：`#### 场景：<名称>`
- 证据：`AGENTS.md`

## 9) 已知风险与高频坑

1. 安装脚本会写入用户目录，可能覆盖既有安装
   - 预防锚点：先执行 `./scripts/install-skills.sh --dry-run`
2. Hook 脚本依赖 ripgrep，未安装会影响上下文注入
   - 预防锚点：`command -v rg`，如缺失则安装 ripgrep
3. MCP 配置涉及密钥与本地配置文件，易被误提交
   - 预防锚点：将密钥放入环境变量并确认 `~/.claude.json` 与 `~/.codex/config.toml` 不纳入版本控制
4. Embedding 需要 API Key，缺失会导致索引失败
   - 预防锚点：确认 `OPENAI_API_KEY` 或对应提供商配置已设置

## 10) Open Questions

1. 是否存在统一的测试或 CI 入口命令
   - 验证：搜索仓库是否存在 `Makefile`、`package.json` 根目录脚本或 CI 工作流
2. DevBooks MCP Server 是否存在发布流程或版本策略
   - 验证：检查 `mcp/devbooks-mcp-server` 是否有发布文档或 tags
3. 是否需要定义本仓库自身的分层约束
   - 验证：评估是否需要新增分层规则文档并在 CI 模板中启用

## 元数据

| 字段 | 值 |
|---|---|
| 创建日期 | 2026-01-08 |
| 最后更新 | 2026-01-08 |
| 维护者 | TBD（验证：确认维护者信息） |
| 版本 | 0.1 |
