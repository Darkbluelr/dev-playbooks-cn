# global-hooks（Spec Delta）

---
change_id: achieve-augment-parity
capability: global-hooks
delta_type: MODIFIED
trace: AC-006, AC-007, AC-008
---

## 目的

描述本次变更对全局 Hook 能力的修改：输出格式扩展、Graph-RAG 集成、降级策略。

---

## MODIFIED Requirements

### Requirement: REQ-HOOK-001 Hook 输出格式扩展

系统 **SHALL** 在 Hook 输出中支持可选的 `graphContext`、`callChain`、`fallback` 字段，同时保持与现有 `additionalContext` 字段的向后兼容。

- 新增字段为可选，不影响现有消费者
- `graphContext.schema_version` 必须为 `1.0`
- `callChain.schema_version` 必须为 `1.0`

#### Scenario: SC-HOOK-001 正常模式输出完整上下文

- **GIVEN** 系统已配置 API Key 且 CKB 索引可用
- **WHEN** 用户发起查询
- **THEN** Hook 输出包含 `additionalContext` 字段
- **AND** Hook 输出包含 `graphContext` 字段（含 `schema_version`、`source`、`token_count`、`candidates`）

Trace: AC-002

#### Scenario: SC-HOOK-002 降级模式输出 fallback 标记

- **GIVEN** 系统未配置 API Key 或 CKB 索引不可用
- **WHEN** 用户发起查询
- **THEN** Hook 输出包含 `additionalContext` 字段（使用关键词搜索结果）
- **AND** Hook 输出包含 `fallback` 字段（含 `reason` 和 `degraded_to`）

Trace: AC-006

---

### Requirement: REQ-HOOK-002 功能开关控制

系统 **SHALL** 支持通过配置文件控制各功能模块的启用状态。

- `graph_rag.enabled: false` 时，跳过 Graph-RAG 处理
- `reranker.enabled: false` 时，跳过 LLM 重排序
- 配置变更后，下一次查询立即生效

#### Scenario: SC-HOOK-003 通过配置关闭 Graph-RAG

- **GIVEN** 配置文件中 `graph_rag.enabled: false`
- **WHEN** 用户发起查询
- **THEN** Hook 输出不包含 `graphContext` 字段
- **AND** Hook 使用关键词搜索作为上下文来源

Trace: AC-007

#### Scenario: SC-HOOK-004 通过配置关闭重排序

- **GIVEN** 配置文件中 `reranker.enabled: false`
- **WHEN** 用户发起查询
- **THEN** Graph-RAG 结果直接输出，不经过 LLM 重排序

Trace: AC-007

---

### Requirement: REQ-HOOK-003 延迟性能约束

系统 **SHALL** 确保 Hook 执行延迟 P95 < 3000ms。

- 对于 20 次连续查询，第 19 次（95% 位）延迟必须 < 3000ms
- 超时时自动降级到关键词搜索

#### Scenario: SC-HOOK-005 延迟超时降级

- **GIVEN** 外部 API 响应缓慢（>3s）
- **WHEN** 用户发起查询
- **THEN** Hook 在 3s 内返回结果
- **AND** 输出包含 `fallback.reason: timeout`

Trace: AC-008

---

## 数据驱动实例

### Hook 输出格式对照表

| 场景 | additionalContext | graphContext | callChain | fallback |
|------|-------------------|--------------|-----------|----------|
| 正常模式（全功能） | ✓ 包含 | ✓ 包含 | 按需包含 | ✗ 不包含 |
| 无 API Key | ✓ 包含（关键词） | ✗ 不包含 | ✗ 不包含 | ✓ reason=no_api_key |
| CKB 不可用 | ✓ 包含（Embedding） | ✓ 包含 | ✗ 不包含 | ✓ reason=ckb_unavailable |
| 超时 | ✓ 包含（关键词） | ✗ 不包含 | ✗ 不包含 | ✓ reason=timeout |
| Graph-RAG 关闭 | ✓ 包含（关键词） | ✗ 不包含 | ✗ 不包含 | ✗ 不包含 |

---

*Spec delta 由 devbooks-spec-contract 生成*
