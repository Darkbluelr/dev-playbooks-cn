# Design: achieve-augment-parity

> 产物落点：`openspec/changes/achieve-augment-parity/design.md`

---

## 元信息

| 字段 | 值 |
|------|-----|
| 版本 | 1.0 |
| 状态 | Archived |
| 更新时间 | 2026-01-09（Design Backport 于归档前） |
| 适用范围 | DevBooks v3.0 |
| Owner | Design Owner |
| last_verified | 2026-01-09 |
| freshness_check | 1 Month |

---

## ⚡ Acceptance Criteria（验收标准）

| AC-ID | 验收标准 | Pass 判据 | Fail 判据 | 验收方式 |
|-------|---------|----------|----------|----------|
| AC-001 | Embedding 索引可自动构建 | `./tools/devbooks-embedding.sh build` 退出码 0，且 `.devbooks/embeddings/` 目录下生成至少 1 个 `*.tsv` 文件 | 命令报错或无输出文件 | A |
| AC-002 | Graph-RAG 可检索相关上下文 | 对 10 个预设查询，人工评测相关性得分 ≥ 70%（评分标准：完全相关=1，部分相关=0.5，无关=0） | 相关性得分 < 70% | B |
| AC-003 | LLM 重排序可运行 | `./tools/context-reranker.sh --query "test" --input test-input.json` 退出码 0，且输出包含 `ranked_results` 字段 | 命令报错或输出格式错误 | A |
| AC-004 | 调用链追踪支持 2-3 跳 | `./tools/call-chain-tracer.sh --symbol "testFunc" --depth 3` 输出包含 ≥ 2 层嵌套的调用链 JSON | 输出为空或仅 1 层 | A |
| AC-005 | Bug 定位可输出候选位置 | `./tools/bug-locator.sh --error "TypeError"` 输出 Top-5 候选列表，且对 10 个预设 case 命中率 ≥ 60% | 无输出或命中率 < 60% | B |
| AC-006 | 无 API Key 时优雅降级 | 移除所有 API Key 环境变量后，Hook 正常执行且输出包含 `fallback: keyword` 标记 | Hook 报错退出或输出为空 | A |
| AC-007 | 所有功能可通过配置关闭 | 设置 `graph_rag.enabled: false`、`reranker.enabled: false` 后，Hook 输出不包含对应功能的结果 | 配置无效，功能仍执行 | A |
| AC-008 | 延迟 P95 < 3s | 对 20 次查询进行性能测试，排序后第 19 次（95%位）延迟 < 3000ms | P95 ≥ 3000ms | A |

---

## ⚡ Goals / Non-goals / Red Lines

### Goals（本次变更目标）

1. **代码理解深度升级**：从"关键词匹配"升级到"向量语义检索 + CKB 图遍历"
2. **上下文注入智能化**：从"固定模板注入（~2k tokens）"升级到"Graph-RAG 智能检索（4k-16k tokens 动态预算）"
3. **Bug 定位能力新增**：从"无能力"升级到"简化版调用链追踪 + 候选位置推荐"
4. **能力对齐**：将 DevBooks 与 Augment Code 的能力相似度从 35-40% 提升至 60-70%

### Non-goals（不在本次范围）

1. **不实现控制流图 (CFG)**：需要语言特定的深度 AST 分析，ROI 低
2. **不实现数据流图 (PDG)**：复杂度高，需 2-3 个月开发，超出本次范围
3. **不实现实时索引更新**：当前 Git Hook 触发足够，实时性不是首要目标
4. **不实现代码补全**：超出 DevBooks 定位（变更管理框架）
5. **不实现跨仓库联邦**：复杂度高，留待后续版本

### Red Lines（不可破的约束）

1. **向后兼容**：现有 Hook 配置（`~/.claude/settings.json`）必须继续有效，无需用户手动迁移
2. **无强制依赖**：不强制要求 API Key；无 Key 时必须优雅降级到关键词搜索
3. **不破坏现有输出格式**：Hook 输出的 `additionalContext` 字段结构保持兼容，新字段为可选
4. **配置可控**：所有新功能必须可通过配置关闭

---

## 执行摘要

**目标**：单次变更将 DevBooks 从"关键词 + 固定注入"升级到"Graph-RAG + 调用链追踪"，能力对齐 Augment 60-70%。

**核心矛盾**：要提升代码理解深度和上下文相关性，必须引入外部依赖（Embedding API）和更复杂的图遍历逻辑，但不能破坏现有用户的零配置体验。

**解法**：默认启用高级功能 + 优雅降级 + 配置开关。

---

## Problem Context（问题背景）

### 为什么要解决这个问题

DevBooks 当前实现仅达到 Augment Code **35-40%** 的能力水平。用户在使用 Claude Code 时，上下文注入的相关性不足，导致 AI 无法准确理解代码库结构和调用关系。

### 当前系统的摩擦点

| 摩擦点 | 现状 | 影响 |
|--------|------|------|
| 上下文检索 | 关键词 grep + 固定 2k tokens | 相关代码遗漏率高 |
| 调用关系理解 | 仅 CKB 单层符号查询 | 无法追踪多跳调用链 |
| Bug 定位 | 无能力 | 用户需手动定位 |

### 若不解决的后果

- 用户持续使用 Augment Code 作为主力工具，DevBooks 沦为辅助
- 无法提供差异化价值，项目长期价值存疑

---

## 价值链映射

```
Goal: DevBooks ≈ Augment 60-70%
        │
        ▼
阻碍: 代码理解浅（关键词）、上下文相关性低、无调用链追踪
        │
        ▼
杠杆: Embedding 语义检索 + CKB 图遍历 + 调用链追踪
        │
        ▼
最小方案: 5 个模块（Embedding 默认启用 + Graph-RAG + 重排序 + 调用链 + Bug 定位）
```

---

## 背景与现状评估

### 现有资产

| 资产 | 位置 | 可复用程度 |
|------|------|------------|
| Embedding 工具 | `tools/devbooks-embedding.sh` | 高（仅需包装） |
| CKB MCP Server | 外部依赖 | 高（已集成） |
| 全局 Hook | `setup/global-hooks/augment-context-global.sh` | 中（需重构） |
| 配置模板 | `.devbooks/embedding.*.yaml` | 高 |

### 主要风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Embedding API 成本失控 | 中 | 高 | 支持本地 Ollama + 使用量监控 |
| Graph-RAG 延迟过高 | 中 | 高 | 增量缓存 + P95 延迟 <3s 闸门 |
| CKB 索引不完整 | 低 | 中 | 自动降级到关键词搜索 |

---

## 设计原则

### 核心原则

1. **渐进增强（Progressive Enhancement）**：基础功能无依赖可用，高级功能按需启用
2. **优雅降级（Graceful Degradation）**：任何外部依赖失败时，自动回退到基础模式
3. **配置优于约定（Configuration over Convention）**：所有行为可通过 `.devbooks/config.yaml` 覆盖

### 变化点识别（Variation Points）

| 变化点 | 最可能变化的原因 | 封装策略 |
|--------|------------------|----------|
| Embedding 提供商 | API 定价、性能、可用性 | 配置文件 `embedding.provider` + 适配器模式 |
| 图遍历深度 | 项目规模、性能限制 | 配置 `graph_rag.max_depth` |
| Token 预算 | LLM 上下文窗口大小 | 配置 `graph_rag.token_budget` |
| 重排序模型 | 新模型发布、成本变化 | 配置 `reranker.model` |

---

## 目标架构

### Bounded Context

本次变更涉及 **tooling 层** 的扩展，不涉及 runtime 层（MCP Server）。

```
┌─────────────────────────────────────────────────────────────┐
│  Claude Code（外部）                                          │
│  └── Hook 调用 → augment-context-global.sh                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  tooling 层（本次变更范围）                                    │
│                                                             │
│  augment-context-global.sh (v3.0)                           │
│      │                                                      │
│      ├── graph-rag-context.sh [新增]                        │
│      │   ├── 向量搜索（Embedding 索引）                      │
│      │   ├── CKB 图遍历（getCallGraph / findReferences）    │
│      │   └── 动态 Token 预算                                 │
│      │                                                      │
│      ├── context-reranker.sh [新增]                         │
│      │   └── Haiku 重排序（可选）                            │
│      │                                                      │
│      ├── call-chain-tracer.sh [新增]                        │
│      │   └── CKB traceUsage + getCallGraph 封装             │
│      │                                                      │
│      └── bug-locator.sh [新增]                              │
│          └── 调用链 + Git 历史 → 候选位置                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  外部依赖                                                    │
│  ├── CKB MCP Server（已有）                                  │
│  ├── SCIP 索引（已有）                                       │
│  ├── Embedding 索引（新依赖，可选）                           │
│  ├── OpenAI API / Ollama（新依赖，可选）                      │
│  └── Anthropic API Haiku（新依赖，可选）                      │
└─────────────────────────────────────────────────────────────┘
```

### 依赖方向

- tooling 层 → 外部 API（单向依赖，符合分层约束）
- 新增工具脚本 → 现有工具脚本（可复用）

### 关键扩展点

| 扩展点 | 接口 | 扩展方式 |
|--------|------|----------|
| Embedding 提供商 | `embedding.provider` 配置 | 新增 provider 类型即可 |
| 重排序模型 | `reranker.model` 配置 | 新增 model 类型即可 |
| 图遍历策略 | `graph-rag-context.sh` 内部 | 修改遍历逻辑 |

### Testability & Seams（可测试性与接缝）

**测试接缝（Seams）**：
- `graph-rag-context.sh` 接受 `--mock-embedding` 参数，使用固定向量进行测试
- `context-reranker.sh` 接受 `--mock-llm` 参数，返回固定排序结果
- `call-chain-tracer.sh` 接受 `--mock-ckb` 参数，使用预置调用图
- 所有脚本通过 `DEVBOOKS_DEBUG=1` 环境变量输出详细日志

**Pinch Points（汇点）**：
- `augment-context-global.sh` 主入口：所有功能路径的汇聚点
- `graph-rag-context.sh` 向量搜索：Graph-RAG 的核心逻辑

**依赖隔离策略**：
- CKB MCP Server → 通过 `mcp__ckb__*` 工具调用，可被 mock JSON 替代
- Embedding API → 通过配置 `embedding.provider: mock` 切换为测试模式
- Anthropic API → 通过配置 `reranker.enabled: false` 跳过

### C4 Delta

> 本小节由 devbooks-c4-map 生成。Proposal 阶段**不修改**当前真理 `openspec/specs/architecture/c4.md`，仅记录变更影响。

#### C1 系统上下文变更

| 变更类型 | 元素 | 说明 |
|----------|------|------|
| 新增外部依赖 | OpenAI API | Embedding 向量生成（可选） |
| 新增外部依赖 | Ollama 本地服务 | Embedding 向量生成（本地替代） |
| 新增外部依赖 | Anthropic API (Haiku) | LLM 重排序（可选） |
| 无变更 | Claude Code | 主要用户，通过 Hook 调用 |
| 无变更 | CKB MCP Server | 已有依赖，图遍历能力 |

**C1 上下文图（变更后）**：

```
┌─────────────────────────────────────────────────────────────────┐
│                        开发者                                    │
│                          │                                      │
│                          ▼                                      │
│                    ┌──────────┐                                 │
│                    │Claude Code│                                │
│                    └────┬─────┘                                 │
│                         │ Hook 调用                              │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              DevBooks / Dev Playbooks                     │  │
│  │                                                           │  │
│  │  ┌─────────────┐  ┌────────────┐  ┌──────────────────┐  │  │
│  │  │  skills/    │  │  tools/    │  │ setup/global-hooks│  │  │
│  │  └─────────────┘  └─────┬──────┘  └────────┬─────────┘  │  │
│  │                         │                   │             │  │
│  └─────────────────────────┼───────────────────┼─────────────┘  │
│                            │                   │                 │
│           ┌────────────────┼───────────────────┼────────────┐   │
│           │                ▼                   ▼            │   │
│           │  ┌──────────────────────────────────────────┐  │   │
│           │  │            外部依赖                       │  │   │
│           │  │  ┌─────────┐ ┌──────┐ ┌────────────────┐ │  │   │
│           │  │  │CKB MCP  │ │Ollama│ │OpenAI/Anthropic│ │  │   │
│           │  │  │(已有)   │ │(新增)│ │(新增)          │ │  │   │
│           │  │  └─────────┘ └──────┘ └────────────────┘ │  │   │
│           │  └──────────────────────────────────────────┘  │   │
│           └────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

#### C2 容器级变更

| 容器 | 变更类型 | 变更内容 |
|------|----------|----------|
| `tools/` | 扩展 | 新增 4 个工具脚本 |
| `setup/global-hooks/` | 修改 | `augment-context-global.sh` 重构 |
| `.devbooks/` | 扩展 | 新增配置项、缓存目录 |
| 其他容器 | 无变更 | `skills/`, `prompts/`, `mcp/devbooks-mcp-server/` 等 |

**C2 容器图（tools/ 扩展详情）**：

```
tools/（容器）
├── devbooks-embedding.sh     [已有] Embedding 索引构建
├── devbooks-complexity.sh    [已有] 复杂度分析
├── graph-rag-context.sh      [新增] Graph-RAG 上下文引擎
├── context-reranker.sh       [新增] LLM 重排序
├── call-chain-tracer.sh      [新增] 调用链追踪
└── bug-locator.sh            [新增] Bug 定位
```

#### C3 组件级变更

**本次变更对 C3 组件的影响**：

| 层级 | 元素 | 变更类型 | 说明 |
|------|------|----------|------|
| C3 | `augment-context-global.sh` | 重构 | 从"简单符号搜索"升级到"Graph-RAG 引擎" |
| C3 | `graph-rag-context.sh` | 新增 | Graph-RAG 核心组件 |
| C3 | `context-reranker.sh` | 新增 | LLM 重排序组件 |
| C3 | `call-chain-tracer.sh` | 新增 | 调用链追踪组件 |
| C3 | `bug-locator.sh` | 新增 | Bug 定位组件 |

**C3 组件依赖图**：

```
┌───────────────────────────────────────────────────────────────┐
│                  setup/global-hooks/                           │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │             augment-context-global.sh (v3.0)             │  │
│  │                         │                                │  │
│  │      ┌──────────────────┼──────────────────┐            │  │
│  │      │                  │                  │            │  │
│  │      ▼                  ▼                  ▼            │  │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │  │
│  │ │graph-rag-   │  │context-     │  │devbooks-        │  │  │
│  │ │context.sh   │  │reranker.sh  │  │embedding.sh     │  │  │
│  │ └──────┬──────┘  └──────┬──────┘  └─────────────────┘  │  │
│  │        │                │                               │  │
│  └────────┼────────────────┼───────────────────────────────┘  │
│           │                │                                   │
└───────────┼────────────────┼───────────────────────────────────┘
            │                │
            ▼                ▼
┌───────────────────────────────────────────────────────────────┐
│                       tools/                                   │
│  ┌─────────────────┐  ┌─────────────────┐                     │
│  │call-chain-      │  │bug-locator.sh   │                     │
│  │tracer.sh        │◄─┤                 │                     │
│  └────────┬────────┘  └─────────────────┘                     │
│           │                                                    │
└───────────┼────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────┐
│                    外部依赖                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐   │
│  │ CKB MCP     │  │ Embedding   │  │ Anthropic API       │   │
│  │ Server      │  │ Index       │  │ (Haiku)             │   │
│  └─────────────┘  └─────────────┘  └─────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

#### 依赖方向变化

| 源组件 | 目标组件 | 变更类型 | 方向 |
|--------|----------|----------|------|
| `augment-context-global.sh` | `graph-rag-context.sh` | 新增 | → |
| `augment-context-global.sh` | `context-reranker.sh` | 新增（可选） | → |
| `augment-context-global.sh` | `devbooks-embedding.sh` | 新增 | → |
| `graph-rag-context.sh` | CKB MCP Server | 新增 | → |
| `graph-rag-context.sh` | Embedding Index | 新增 | → |
| `call-chain-tracer.sh` | CKB MCP Server | 新增 | → |
| `bug-locator.sh` | `call-chain-tracer.sh` | 新增 | → |
| `bug-locator.sh` | Git（历史分析） | 新增 | → |
| `context-reranker.sh` | Anthropic API | 新增 | → |

#### Architecture Guardrails 新增建议

**分层约束更新**：

| 层级 | 目录 | 可依赖 | 禁止依赖 |
|------|------|--------|----------|
| tooling | `tools/`, `setup/` | `docs/`, 外部 API | `mcp/devbooks-mcp-server/` |
| **新增约束** | `tools/*.sh` | 其他 `tools/*.sh`（无循环） | 直接写入 `openspec/` |

**Fitness Tests 条目（建议新增）**：

| Test ID | 类型 | 描述 | 验证方式 |
|---------|------|------|----------|
| FT-001 | 依赖方向 | `tools/` 内脚本禁止循环依赖 | 静态分析脚本调用关系 |
| FT-002 | 接口一致性 | 新工具必须支持 `--help`、`--version` | 遍历检查 |
| FT-003 | 可测试性 | 新工具必须支持 `--mock-*` 参数 | 遍历检查 |
| FT-004 | 降级策略 | 外部依赖失败时必须有降级路径 | 测试覆盖 |
| FT-005 | 配置隔离 | 新配置项必须有默认值 | 配置 schema 验证 |

**归档任务提醒**：

在 Archive 阶段，需将以下变更合并到 `openspec/specs/architecture/c4.md`：
1. C1：新增外部依赖（OpenAI API、Ollama、Anthropic API）
2. C2：`tools/` 容器扩展说明
3. C3：新增 4 个组件
4. Guardrails：新增 5 个 Fitness Tests 条目

---

## 领域模型（Domain Model）

### Data Model

**@ValueObject: EmbeddingVector**
- `file_path: string` - 文件路径
- `chunk_id: string` - 分块 ID
- `vector: float[]` - 向量表示
- `content_hash: string` - 内容哈希（用于增量更新）

**@ValueObject: ContextCandidate**
- `file_path: string` - 文件路径
- `line_start: number` - 起始行
- `line_end: number` - 结束行
- `relevance_score: float` - 相关性分数（0-1）
- `source: enum[keyword, embedding, graph]` - 来源

**@ValueObject: CallChainNode**
- `symbol_id: string` - CKB 符号 ID
- `file_path: string` - 文件路径
- `line: number` - 行号
- `depth: number` - 深度（跳数）
- `callers: CallChainNode[]` - 调用方
- `callees: CallChainNode[]` - 被调用方

**@ValueObject: BugCandidate**
- `file_path: string` - 文件路径
- `line_range: [number, number]` - 行范围
- `confidence: float` - 置信度（0-1）
- `reason: string` - 推荐原因

### Business Rules

| BR-ID | 规则 | 触发条件 | 约束内容 | 违反时行为 |
|-------|------|----------|----------|------------|
| BR-001 | Token 预算不可超限 | Graph-RAG 输出 | 输出总 token 数 ≤ `graph_rag.token_budget` | 截断低相关性内容 |
| BR-002 | 降级优先级顺序 | 任何组件失败 | Graph-RAG → Embedding → Keyword | 跳过失败组件，继续下一级 |
| BR-003 | 调用链深度限制 | 图遍历 | 深度 ≤ `graph_rag.max_depth`（默认 3） | 停止遍历，返回已收集结果 |
| BR-004 | 缓存 TTL | 查询缓存 | 缓存有效期 = `graph_rag.cache_ttl`（默认 300s） | 过期后重新计算 |

### Invariants（固定规则）

- `[Invariant]` Hook 输出的 `additionalContext` 必须是有效 JSON
- `[Invariant]` 降级后的输出必须包含 `fallback` 字段标明降级原因
- `[Invariant]` 所有工具脚本的退出码：0=成功，1=参数错误，2=依赖缺失，3=运行时错误

---

## 核心数据与事件契约

### Hook 输出格式（扩展）

**现有格式**（保持兼容）：
```json
{
  "additionalContext": "string | markdown"
}
```

**扩展格式**（新增可选字段）：
```json
{
  "additionalContext": "string | markdown",
  "graphContext": {
    "schema_version": "1.0",
    "source": "graph-rag | embedding | keyword",
    "token_count": 1234,
    "candidates": [
      {
        "file_path": "string",
        "relevance_score": 0.85,
        "source": "embedding"
      }
    ]
  },
  "callChain": {
    "schema_version": "1.0",
    "target_symbol": "string",
    "depth": 3,
    "paths": [],
    "cycle_detected": false,
    "cycle_at": "symbol_id | null"
  },
  "fallback": {
    "reason": "no_api_key | ckb_unavailable | timeout",
    "degraded_to": "keyword"
  }
}
```

### 版本化策略

| 字段 | schema_version | 兼容策略 |
|------|----------------|----------|
| graphContext | 1.0 | 新增字段向后兼容，删除字段需提前 2 个版本警告 |
| callChain | 1.0 | 同上 |
| fallback | 1.0 | 同上 |

### 兼容窗口

- 旧版 Hook 配置：永久兼容（新字段被忽略）
- 旧版 config.yaml：永久兼容（新配置使用默认值）

---

## Contract（契约计划）

> 本章节由 devbooks-spec-contract 生成

### API 版本管理检查清单

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 新增 API 是否声明了版本？ | ✅ | `schema_version: "1.0"` 在每个新增字段中 |
| 破坏性变更是否有迁移路径？ | ✅ | 无破坏性变更，仅新增可选字段 |
| 旧版本客户端是否仍能正常工作？ | ✅ | 新字段为可选，旧客户端忽略 |

### 模式演化兼容策略

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 向前兼容 | ✅ | 新消费者可处理无 `graphContext` 的旧输出 |
| 向后兼容 | ✅ | 旧消费者忽略 `graphContext` 等新字段 |
| 弃用窗口 | N/A | 本次无弃用字段 |
| Schema 版本管理 | ✅ | 每个新结构包含 `schema_version` |

### 配置契约

**新增配置项**（`.devbooks/config.yaml`）：

```yaml
# Graph-RAG 配置
graph_rag:
  enabled: true                 # 是否启用 Graph-RAG
  max_depth: 2                  # 图遍历最大深度 (1-4)
  token_budget: 8000            # Token 预算 (4000-16000)
  cache_ttl: 300                # 缓存 TTL (秒)
  top_k: 10                     # 向量搜索返回数量

# 重排序配置
reranker:
  enabled: false                # 是否启用 LLM 重排序（默认关闭）
  model: haiku                  # 重排序模型

# Embedding 配置（扩展）
embedding:
  auto_build: true              # 首次运行时自动构建索引
  fallback_to_keyword: true     # 失败时降级到关键词搜索
```

**配置兼容策略**：
- 新配置项均有默认值，旧配置文件无需修改
- 缺失的配置项使用默认值
- 无效配置值记录警告，使用默认值

### Contract Test IDs

| Test ID | 类型 | 覆盖场景 | 对应 AC/Requirement |
|---------|------|----------|---------------------|
| CT-001 | schema | Hook 输出格式验证 | REQ-HOOK-001, AC-002 |
| CT-002 | behavior | 降级模式触发 | REQ-HOOK-002, AC-006 |
| CT-003 | behavior | 配置开关生效 | REQ-HOOK-002, AC-007 |
| CT-004 | schema | graphContext 结构 | REQ-GRAG-001 |
| CT-005 | schema | callChain 结构 | REQ-CHAIN-001, AC-004 |
| CT-006 | behavior | 缓存命中 | REQ-GRAG-004, AC-008 |
| CT-007 | schema | bug-locator 输出结构 | REQ-BUG-001, AC-005 |
| CT-008 | config | 配置默认值 | REQ-HOOK-002 |
| CT-009 | config | 配置无效值处理 | REQ-HOOK-002 |
| CT-010 | compat | 旧配置兼容性 | Red Lines |

### 追溯摘要

| AC/Requirement | 契约文件 | Contract Test ID |
|----------------|----------|------------------|
| AC-001 | embedding/spec.md | - |
| AC-002 | graph-rag/spec.md, global-hooks/spec.md | CT-001, CT-004 |
| AC-003 | - | - |
| AC-004 | call-chain/spec.md | CT-005 |
| AC-005 | bug-locator/spec.md | CT-007 |
| AC-006 | global-hooks/spec.md, embedding/spec.md | CT-002 |
| AC-007 | global-hooks/spec.md | CT-003 |
| AC-008 | global-hooks/spec.md, graph-rag/spec.md | CT-006 |

---

## 关键机制

### 质量闸门

| 闸门 | 检查方式 | 阈值 | 失败处理 |
|------|----------|------|----------|
| ShellCheck | `shellcheck *.sh` | 0 warnings | CI 阻断 |
| BATS 测试 | `bats tests/` | 100% pass | CI 阻断 |
| 延迟闸门 | 性能测试脚本 | P95 < 3s | CI 阻断 |
| 相关性评测 | 人工评测 | ≥ 70% | Review 阻断 |

### 预算化

- Token 预算：默认 8k，最大 16k，可配置
- API 调用预算：Embedding 每文件限制 1 次/天，重排序每查询限制 1 次

### 缓存隔离

| 缓存类型 | 位置 | TTL | 隔离策略 |
|----------|------|-----|----------|
| Embedding 索引 | `.devbooks/embeddings/` | 持久化 | 按 content_hash 增量更新 |
| Graph-RAG 缓存 | `.devbooks/cache/graph-context/` | 5 分钟 | 按查询 hash 隔离 |
| 重排序缓存 | `.devbooks/cache/reranker/` | 5 分钟 | 按输入 hash 隔离 |

---

## 可观测性与验收

### Metrics

| 指标 | 采集方式 | 用途 |
|------|----------|------|
| hook_latency_ms | 脚本内计时 | 性能监控 |
| embedding_hit_rate | 缓存命中统计 | 缓存效率 |
| fallback_count | 降级计数 | 稳定性监控 |
| relevance_score_avg | 相关性分数均值 | 质量监控 |

### KPI

| KPI | 基线 | 目标 | 验证周期 |
|-----|------|------|----------|
| Augment 能力相似度 | 35-40% | 60-70% | 发布后 1 周 |
| 上下文相关性 | 低 | ≥ 70% | 发布后 1 周 |
| P95 延迟 | <1s | <3s | 每次发布 |

---

## 安全、合规与多租户隔离

### 安全考量

| 风险 | 缓解措施 |
|------|----------|
| API Key 泄露 | 仅从环境变量读取，禁止写入日志 |
| 代码泄露到外部 API | 用户需自行决定使用 OpenAI/本地 Ollama |
| 缓存数据安全 | 缓存目录仅本地存储，不上传 |

### 合规

- 不收集用户数据
- 不发送遥测
- 所有 API 调用需用户显式配置

### 多租户隔离

- 不适用（本项目为单租户本地工具）

---

## 里程碑

| 里程碑 | 内容 | 验收标准 |
|--------|------|----------|
| M1 | Embedding 默认启用 + Graph-RAG | AC-001, AC-002, AC-006, AC-007 |
| M2 | 调用链追踪 + Bug 定位 | AC-004, AC-005 |
| M3 | LLM 重排序 | AC-003 |
| M4 | 性能优化 + 文档 | AC-008 |

---

## Deprecation Plan

| 废弃项 | 标记版本 | 警告版本 | 移除版本 |
|--------|----------|----------|----------|
| 无 | - | - | - |

本次变更无废弃项，所有现有功能保持兼容。

---

## Design Rationale（设计决策理由）

### 为什么选择 Graph-RAG 而非纯 Embedding

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 纯 Embedding | 实现简单 | 无法理解代码结构关系 | 不采用 |
| 纯 CKB 图遍历 | 结构关系准确 | 无语义理解 | 不采用 |
| Graph-RAG（Embedding + 图遍历） | 兼具语义 + 结构 | 实现复杂 | **采用** |

### 为什么 LLM 重排序默认关闭

1. 增加 ~500ms 延迟
2. 增加 API 成本
3. 效果存疑，需 A/B 测试验证
4. 用户可按需开启

### 为什么不实现 CFG/PDG

1. 需要语言特定的深度 AST 分析
2. 开发周期 2-3 个月
3. 调用链追踪已覆盖 60% 使用场景
4. ROI 不足

---

## Design Backport（归档前补充决策）

> 本小节在 Archive 阶段由 devbooks-design-backport 补充，记录实现过程中确定的 Design-level 决策。

### 调用链循环检测策略

**背景**：tasks.md MP4.3 定义了循环检测机制，属于用户可感知的对外契约。

**决策**：
- 调用链追踪遇到循环依赖时，输出字段 `cycle_detected: true`
- 循环检测通过记录已访问节点实现，检测到重复节点时终止遍历

**对外契约影响**：
```json
{
  "callChain": {
    "cycle_detected": true,   // 新增可选字段
    "cycle_at": "symbol_id"   // 新增可选字段
  }
}
```

### Bug 定位置信度权重

**背景**：tasks.md MP5.1-5.3 定义了置信度计算公式，属于影响排序行为的关键决策。

**决策**：
```
confidence = 0.4 × call_chain_score
           + 0.3 × history_score
           + 0.15 × hotspot_score
           + 0.15 × error_pattern_score
```

**权重设计理由**：
- 调用链距离（0.4）：越靠近错误源的代码越可能是问题所在
- 变更历史（0.3）：最近修改的代码更可能引入 Bug
- 热点文件（0.15）：高频修改的文件通常需要更多关注
- 错误模式匹配（0.15）：与错误信息直接相关的代码

### Embedding 提供商优先级

**背景**：design.md OQ-001 未明确提供商优先级，tasks.md OQ-003 给出了建议。

**决策**：
- 默认优先级：`OpenAI > Azure OpenAI > Ollama`
- 配置覆盖：用户可通过 `embedding.provider` 配置指定使用哪个提供商

**理由**：
- OpenAI 兼容性最广、API 最稳定
- Azure OpenAI 适合企业环境
- Ollama 适合离线/隐私敏感场景

### 算法复杂度约束

**背景**：tasks.md Algorithm Spec 定义了复杂度上限，属于系统级性能约束。

**决策**：
- Graph-RAG 时间复杂度：`O(top_k × max_depth × avg_graph_size)`
- Graph-RAG 空间复杂度：`O(candidates_count)`
- Graph-RAG I/O 复杂度：Embedding 查询 1 次 + CKB 查询 ≤ top_k 次

**性能红线**：
- 单次查询总 CKB 调用数 ≤ 10（由 top_k 限制）
- 单次查询总延迟 P95 < 3s（由 AC-008 约束）

---

## Trade-offs（权衡取舍）

### 本设计放弃了什么

1. **精确 Bug 定位**：仅提供候选推荐，非精确定位
2. **实时索引**：使用 Git Hook 触发，非实时更新
3. **完全离线**：高级功能需要 API Key

### 接受的已知不完美

1. **首次查询较慢**：需要构建索引，可能 1-5 分钟
2. **Graph-RAG 延迟增加**：从 <1s 增加到 2-3s
3. **相关性不完美**：目标 70%，非 100%

### 不适用场景

1. 极大型项目（>100k 文件）：索引构建时间过长
2. 需要实时代码补全的场景
3. 需要精确 Bug 定位（CFG/PDG）的场景

---

## 风险与降级策略

### Failure Modes

| 失败模式 | 检测方式 | 降级路径 |
|----------|----------|----------|
| Embedding API 不可用 | API 调用超时/错误 | 使用关键词搜索 |
| CKB 索引不完整 | `mcp__ckb__getStatus` 检查 | 跳过图遍历，仅用 Embedding |
| 重排序 API 失败 | API 调用错误 | 使用原始排序 |
| 缓存损坏 | 读取异常 | 清除缓存，重新计算 |

### Degrade Paths

```
完整模式: Graph-RAG + 重排序
    ↓ (重排序 API 失败)
降级模式1: Graph-RAG（无重排序）
    ↓ (CKB 不可用)
降级模式2: Embedding 搜索
    ↓ (Embedding API 失败)
降级模式3: 关键词搜索（基线）
```

---

## ⚡ DoD 完成定义（Definition of Done）

### 何时算"完成"

本设计在以下条件全部满足时算"完成"：

1. **AC 全部通过**：AC-001 至 AC-008 全部 Pass
2. **闸门全绿**：ShellCheck 0 warnings，BATS 100% pass，P95 < 3s
3. **证据齐全**：`evidence/` 目录包含全部必需证据

### 必须通过的闸门清单

| 闸门 | 命令 | 预期结果 |
|------|------|----------|
| ShellCheck | `shellcheck tools/*.sh setup/global-hooks/*.sh` | 0 warnings |
| BATS 测试 | `bats tests/` | 100% pass |
| 延迟闸门 | `./tests/performance-test.sh` | P95 < 3s |
| 降级测试 | `./tests/fallback-test.sh` | 全部场景通过 |

### 必须产出的证据

| 证据类型 | 路径 | 内容 |
|----------|------|------|
| 测试报告 | `evidence/test-report.md` | BATS 测试输出 |
| 性能数据 | `evidence/performance.md` | 20 次查询延迟数据 |
| 相关性评测 | `evidence/relevance-eval.md` | 10 个 case 的评测结果 |
| 降级验证 | `evidence/fallback-test.md` | 各降级场景测试结果 |

### 与 AC 的交叉引用

| 证据 | 验证的 AC |
|------|-----------|
| test-report.md | AC-001, AC-003, AC-004, AC-006, AC-007 |
| performance.md | AC-008 |
| relevance-eval.md | AC-002, AC-005 |
| fallback-test.md | AC-006 |

---

## Open Questions

| ID | 问题 | 影响 | 建议解决方式 | 状态 |
|----|------|------|--------------|------|
| OQ-001 | Embedding 提供商优先级？ | 用户体验 | 默认 OpenAI > Azure > Ollama | ✅ Resolved（见 Design Backport） |
| OQ-002 | 大型项目（>50k 文件）的索引策略？ | 性能 | 建议增量索引 + 只索引热点目录 | Open |
| OQ-003 | 相关性评测的评分标准细化？ | 验收 | 由 Test Owner 在 verification.md 中定义 | ✅ Resolved（见 verification.md） |

---

*设计文档由 devbooks-design-doc 生成*
*下一步：执行 `devbooks-spec-contract` 进入规格与契约阶段*
