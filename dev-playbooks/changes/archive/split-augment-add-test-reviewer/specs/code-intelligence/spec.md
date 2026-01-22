# 规格：code-intelligence（代码理解能力拆分）

---
capability: code-intelligence
status: Ready
created: 2026-01-10
updated: 2026-01-10
owner: Spec & Contract Owner
change_ref: split-augment-add-test-reviewer
---

> 产物落点：`openspec/changes/split-augment-add-test-reviewer/specs/code-intelligence/spec.md`

## REMOVED Requirements

> 以下能力从 DevBooks 移除，迁移到独立项目 `code-intelligence-mcp`。

### Requirement: Embedding 语义检索能力

**描述**：基于向量嵌入的代码语义搜索能力，支持三级降级（Ollama → OpenAI → 关键词）。

**迁移目标**：`code-intelligence-mcp/scripts/embedding.sh`

**原文件**：
- `tools/devbooks-embedding.sh`
- `.devbooks/embedding.yaml`
- `.devbooks/embedding.local.yaml`
- `.devbooks/embedding.azure.yaml`

#### Scenario:语义搜索请求

**Given** 用户在 Claude Code 中提问代码相关问题
**When** Hook 检测到代码意图
**Then** 调用 Embedding 搜索返回语义相关代码片段

**迁移后变化**：
- Before：DevBooks Hook 调用 `tools/devbooks-embedding.sh`
- After：DevBooks Hook 调用 `code-intelligence-mcp` MCP Server

---

### Requirement:Graph-RAG 上下文引擎能力

**描述**：基于符号图的上下文扩展能力，支持 CKB 优先 + import 降级。

**迁移目标**：`code-intelligence-mcp/scripts/graph-rag.sh`

**原文件**：
- `tools/graph-rag-context.sh`

#### Scenario:调用链扩展

**Given** 用户查询某个函数的调用者
**When** Graph-RAG 引擎处理请求
**Then** 返回调用链上下文（最多 4 跳）

---

### Requirement:调用链追踪能力

**描述**：基于 CKB MCP Server 的调用链分析能力。

**迁移目标**：`code-intelligence-mcp/scripts/call-chain.sh`

**原文件**：
- `tools/call-chain-tracer.sh`

#### Scenario:追踪函数调用

**Given** 用户指定一个函数名
**When** 调用链追踪器执行
**Then** 返回该函数的调用者和被调用者（2-4 跳）

---

### Requirement:Bug 定位能力

**描述**：多维 Bug 定位能力，结合 Git 历史、调用链、复杂度分析。

**迁移目标**：`code-intelligence-mcp/scripts/bug-locator.sh`

**原文件**：
- `tools/bug-locator.sh`

#### Scenario:Bug 热点定位

**Given** 用户描述一个 Bug 症状
**When** Bug 定位器执行
**Then** 返回可能的 Bug 热点文件列表

---

### Requirement:LLM 重排序能力

**描述**：使用 LLM（Haiku）对搜索结果进行相关性重排序。

**迁移目标**：`code-intelligence-mcp/scripts/reranker.sh`

**原文件**：
- `tools/context-reranker.sh`

#### Scenario:搜索结果重排序

**Given** 语义搜索返回多个候选结果
**When** 重排序器执行
**Then** 返回按相关性排序的结果

---

### Requirement:复杂度分析能力

**描述**：圈复杂度评估工具。

**迁移目标**：`code-intelligence-mcp/scripts/complexity.sh`

**原文件**：
- `tools/devbooks-complexity.sh`

#### Scenario: 分析文件复杂度

**Given** 用户指定一个代码文件
**When** 复杂度分析器执行
**Then** 返回该文件的圈复杂度评分

---

### Requirement:熵度量可视化能力

**描述**：四维熵度量可视化（Mermaid 图表 + ASCII 仪表盘）。

**迁移目标**：`code-intelligence-mcp/scripts/entropy-viz.sh`

**原文件**：
- `tools/devbooks-entropy-viz.sh`

#### Scenario: 生成熵度量报告

**Given** 用户请求项目熵度量
**When** 熵度量可视化器执行
**Then** 返回四维熵度量图表

---

### Requirement:索引管理能力

**描述**：SCIP/LSP 索引管理。

**迁移目标**：`code-intelligence-mcp/scripts/indexer.sh`

**原文件**：
- `tools/devbooks-indexer.sh`

#### Scenario: 创建代码索引

**Given** 用户指定项目目录
**When** 索引管理器执行
**Then** 生成 SCIP 索引文件

---

### Requirement:上下文注入 Hook

**描述**：全局 Hook，为对话自动注入代码上下文。

**迁移目标**：`code-intelligence-mcp/hooks/`

**原文件**：
- `.claude/hooks/augment-context.sh`
- `.claude/hooks/augment-context-with-embedding.sh`
- `.claude/hooks/cache-manager.sh`
- `setup/global-hooks/augment-context-global.sh`

#### Scenario:对话上下文注入

**Given** 用户发送消息到 Claude Code
**When** UserPromptSubmit Hook 触发
**Then** 注入相关代码上下文到 system-reminder

**迁移后变化**：
- Phase 1：DevBooks Hook 保留副本 + deprecated 警告
- Phase 2：DevBooks Hook 只输出警告并重定向到 MCP
- Phase 3：DevBooks 移除 Hook 副本

---

## ADDED Requirements

### Requirement: MCP 依赖声明

DevBooks **MUST** 声明对 `code-intelligence-mcp` 的可选依赖。

**规范**：
- DevBooks Skills **MUST** 在 `.devbooks/config.yaml` 中声明 `mcp_dependencies.code_intelligence` 配置项
- DevBooks **MUST** 在需要代码理解能力时优先尝试 MCP 调用
- DevBooks **MUST** 在 MCP 不可用时提供降级路径

#### Scenario: 检测 MCP 可用性

**Given** DevBooks Skill 需要代码理解能力
**When** 检测 `code-intelligence-mcp` 是否可用
**Then**
- 可用：通过 MCP 协议调用
- 不可用：降级到本地脚本（如保留）或报错提示

---

### Requirement: 降级策略

系统 **MUST** 在 MCP 调用失败时执行降级处理。

**规范**：
- 系统 **MUST** 在 MCP 超时（默认 5 秒）时自动降级到本地脚本
- 系统 **MUST** 在 MCP 连接失败时尝试本地脚本
- 系统 **MUST** 在所有降级路径失败时输出明确错误信息
- 系统 **SHALL** 记录降级原因到输出中

#### Scenario:MCP 超时降级

**Given** MCP Server 响应超过 30 秒
**When** 超时触发
**Then** 自动降级到本地脚本，输出 "MCP 响应超时，使用本地脚本..."

#### Scenario:MCP 未启动降级

**Given** MCP Server 未启动
**When** 连接失败
**Then** 尝试本地脚本，输出 "MCP 未启动，使用本地脚本..."

#### Scenario:完全失败

**Given** MCP 和本地脚本都失败
**When** 所有降级路径耗尽
**Then** 报错退出，输出 "代码搜索不可用，请检查配置"

---

## 契约变更

### API 变更

| 契约 | Before | After | Breaking? |
|------|--------|-------|-----------|
| Hook 脚本路径 | `.claude/hooks/augment-context.sh` | `~/.local/share/code-intelligence-mcp/hooks/augment-context.sh` | Yes |
| Hook 配置 | `settings.json` 引用 DevBooks 路径 | `settings.json` 引用 MCP 路径 | Yes |
| `.devbooks/config.yaml` embedding 段 | 存在 | 移除（标记为 `# [MIGRATED]`） | Yes |
| `.devbooks/config.yaml` graph_rag 段 | 存在 | 移除 | Yes |
| `.devbooks/config.yaml` reranker 段 | 存在 | 移除 | Yes |
| `.devbooks/config.yaml` mcp_dependencies | 不存在 | 新增 | No |

### 兼容策略

| 阶段 | 策略 | 预计版本 |
|------|------|----------|
| Phase 1 | DevBooks 保留 Hook 副本，添加 deprecated 警告 | 当前版本 |
| Phase 2 | DevBooks Hook 只输出警告并重定向 | +1 版本 |
| Phase 3 | 移除 DevBooks Hook 副本 | +2 版本 |

### 迁移支持

| 工具 | 用途 |
|------|------|
| `migrate-to-mcp.sh` | 自动迁移脚本（支持 --dry-run） |
| `rollback-mcp.sh` | 回滚脚本 |
| `.devbooks/config.yaml.bak` | 配置备份 |

---

## Contract Tests

| CT-ID | 契约 | 测试描述 | 验证命令 |
|-------|------|----------|----------|
| CT-CI-001 | MCP 可用性 | MCP Server 可启动并响应 | `code-intelligence-mcp --version` |
| CT-CI-002 | 搜索功能 | 搜索返回结果 | `code-intelligence-mcp search "test"` |
| CT-CI-003 | Hook 警告 | DevBooks Hook 输出 deprecated 警告 | `grep -q "DEPRECATED" .claude/hooks/augment-context.sh` |
| CT-CI-004 | 配置迁移 | 迁移后旧配置被注释 | `grep -q "# \[MIGRATED\]" .devbooks/config.yaml` |
| CT-CI-005 | 配置备份 | 备份文件存在 | `test -f .devbooks/config.yaml.bak` |
| CT-CI-006 | 降级-MCP超时 | MCP 超时后降级到本地脚本 | 模拟测试 |
| CT-CI-007 | 降级-完全失败 | 所有降级失败后报错退出 | 模拟测试 |

---

## 元数据

| 字段 | 值 |
|------|-----|
| 创建日期 | 2026-01-10 |
| 状态 | Draft |
| 作者 | Spec & Contract Owner |

---

*此规格由 devbooks-spec-contract 产出。*
