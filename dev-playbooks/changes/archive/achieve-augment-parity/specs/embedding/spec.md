# embedding（Spec Delta）

---
change_id: achieve-augment-parity
capability: embedding
delta_type: MODIFIED
trace: AC-001, AC-006
---

## 目的

描述本次变更对 Embedding 能力的修改：默认启用、自动构建、优雅降级。

---

## MODIFIED Requirements

### Requirement: REQ-EMB-001 Embedding 索引默认启用

系统 **SHALL** 在首次运行时自动尝试构建 Embedding 索引，无需用户手动触发。

- 检测到 API Key 时，自动构建索引
- 索引不存在时，显示构建命令提示
- 构建过程异步执行，不阻塞 Hook 首次响应

#### Scenario: SC-EMB-001 首次运行自动构建索引

- **GIVEN** 系统已配置 API Key 且 `.devbooks/embeddings/` 目录不存在
- **WHEN** Hook 首次执行
- **THEN** 系统触发后台索引构建任务
- **AND** 用户收到"索引构建中"提示

Trace: AC-001

#### Scenario: SC-EMB-002 索引已存在时直接使用

- **GIVEN** `.devbooks/embeddings/` 目录存在且包含有效索引文件
- **WHEN** Hook 执行
- **THEN** 系统直接使用现有索引
- **AND** 不触发重新构建

Trace: AC-001

---

### Requirement: REQ-EMB-002 多提供商支持

系统 **SHALL** 支持多种 Embedding 提供商，并可通过配置切换。

- 支持提供商：OpenAI、Azure OpenAI、Ollama（本地）
- 配置项：`embedding.provider`
- 切换提供商后，下一次构建使用新提供商

#### Scenario: SC-EMB-003 切换到本地 Ollama

- **GIVEN** 配置 `embedding.provider: ollama` 且本地 Ollama 服务可用
- **WHEN** 执行 `devbooks-embedding.sh build`
- **THEN** 索引使用 Ollama 生成的向量
- **AND** 不消耗云端 API 配额

Trace: AC-001

---

### Requirement: REQ-EMB-003 无 API Key 优雅降级

系统 **SHALL** 在无 API Key 时优雅降级到关键词搜索，而非报错退出。

- 检测到无 API Key 时，跳过 Embedding 相关功能
- 输出 `fallback.reason: no_api_key`
- 用户体验不中断

#### Scenario: SC-EMB-004 无 API Key 降级

- **GIVEN** 系统未配置任何 Embedding API Key
- **WHEN** 用户发起查询
- **THEN** Hook 正常返回结果（使用关键词搜索）
- **AND** 输出包含 `fallback: { reason: "no_api_key", degraded_to: "keyword" }`

Trace: AC-006

---

## 数据驱动实例

### 提供商配置对照表

| 提供商 | 配置值 | 所需环境变量 | 离线可用 |
|--------|--------|--------------|----------|
| OpenAI | `openai` | `OPENAI_API_KEY` | 否 |
| Azure OpenAI | `azure` | `AZURE_OPENAI_KEY`, `AZURE_OPENAI_ENDPOINT` | 否 |
| Ollama | `ollama` | 无（本地服务） | 是 |
| Mock（测试） | `mock` | 无 | 是 |

### 索引文件结构

| 文件 | 说明 | 格式 |
|------|------|------|
| `index.tsv` | 向量索引主文件 | TSV（file_path, chunk_id, vector_base64） |
| `metadata.json` | 索引元数据 | JSON（provider, created_at, file_count） |
| `chunks/` | 分块内容缓存 | 文本文件 |

---

*Spec delta 由 devbooks-spec-contract 生成*
