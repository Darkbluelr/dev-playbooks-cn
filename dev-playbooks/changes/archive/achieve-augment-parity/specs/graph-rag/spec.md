# graph-rag（Spec Delta）

---
change_id: achieve-augment-parity
capability: graph-rag
delta_type: ADDED
trace: AC-002, AC-008
---

## 目的

描述新增的 Graph-RAG 上下文引擎能力：向量搜索 + CKB 图遍历 + 动态 Token 预算。

---

## ADDED Requirements

### Requirement: REQ-GRAG-001 向量语义检索锚点定位

系统 **SHALL** 使用 Embedding 向量搜索定位与用户查询最相关的代码锚点。

- 输入：用户查询文本
- 输出：Top-K 相关代码片段（默认 K=10）
- 相关性分数范围：0.0-1.0

#### Scenario: SC-GRAG-001 向量搜索返回相关代码

- **GIVEN** Embedding 索引可用且包含项目代码
- **WHEN** 用户查询"订单处理逻辑"
- **THEN** 系统返回与订单处理相关的代码片段
- **AND** 每个片段包含 `file_path`、`line_range`、`relevance_score`

Trace: AC-002

---

### Requirement: REQ-GRAG-002 CKB 图遍历扩展

系统 **SHALL** 以向量搜索锚点为起点，使用 CKB 图遍历扩展相关上下文。

- 遍历方向：callers（调用方）、callees（被调用方）
- 遍历深度：可配置，默认 2 跳，最大 4 跳
- 遍历策略：BFS 优先，避免循环

#### Scenario: SC-GRAG-002 图遍历扩展调用链

- **GIVEN** CKB 索引可用且锚点符号存在于索引中
- **WHEN** 系统从锚点符号开始图遍历
- **THEN** 返回 callers 和 callees 列表
- **AND** 每个节点包含 `symbol_id`、`file_path`、`depth`

Trace: AC-002

#### Scenario: SC-GRAG-003 图遍历深度限制

- **GIVEN** 配置 `graph_rag.max_depth: 2`
- **WHEN** 系统执行图遍历
- **THEN** 遍历在深度 2 处停止
- **AND** 深度 > 2 的节点不包含在结果中

Trace: AC-002

---

### Requirement: REQ-GRAG-003 动态 Token 预算

系统 **SHALL** 根据配置的 Token 预算动态裁剪输出内容。

- Token 预算范围：4k-16k（可配置）
- 默认预算：8k
- 裁剪策略：按相关性分数从低到高裁剪

#### Scenario: SC-GRAG-004 Token 预算裁剪

- **GIVEN** 配置 `graph_rag.token_budget: 4000` 且候选内容超过 4000 tokens
- **WHEN** 系统构建最终输出
- **THEN** 输出总 token 数 ≤ 4000
- **AND** 低相关性内容被优先裁剪

Trace: AC-002

---

### Requirement: REQ-GRAG-004 缓存机制

系统 **SHALL** 对 Graph-RAG 查询结果进行缓存，避免重复计算。

- 缓存键：查询文本 hash
- 缓存 TTL：可配置，默认 300s
- 缓存位置：`.devbooks/cache/graph-context/`

#### Scenario: SC-GRAG-005 缓存命中

- **GIVEN** 相同查询在 5 分钟内已执行过
- **WHEN** 用户再次发起相同查询
- **THEN** 系统直接返回缓存结果
- **AND** 不触发向量搜索和图遍历

Trace: AC-008

---

## 数据驱动实例

### Graph-RAG 输出结构

| 字段 | 类型 | 说明 | 必需 |
|------|------|------|------|
| schema_version | string | 固定 "1.0" | 是 |
| source | enum | "graph-rag" \| "embedding" \| "keyword" | 是 |
| token_count | number | 实际输出 token 数 | 是 |
| candidates | array | 候选代码片段列表 | 是 |
| candidates[].file_path | string | 文件路径 | 是 |
| candidates[].line_start | number | 起始行号 | 是 |
| candidates[].line_end | number | 结束行号 | 是 |
| candidates[].relevance_score | number | 相关性分数 (0-1) | 是 |
| candidates[].source | enum | "embedding" \| "graph" | 是 |

### 配置项对照表

| 配置项 | 类型 | 默认值 | 范围 |
|--------|------|--------|------|
| graph_rag.enabled | boolean | true | - |
| graph_rag.max_depth | number | 2 | 1-4 |
| graph_rag.token_budget | number | 8000 | 4000-16000 |
| graph_rag.cache_ttl | number | 300 | 60-3600 |
| graph_rag.top_k | number | 10 | 5-50 |

---

*Spec delta 由 devbooks-spec-contract 生成*
