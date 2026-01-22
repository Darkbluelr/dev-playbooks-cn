# Implementation Plan: achieve-augment-parity

---

## 元信息

| 字段 | 值 |
|------|-----|
| 维护者 | Planner (DevBooks) |
| 关联规范 | `openspec/changes/achieve-augment-parity/design.md` |
| 输入材料 | design.md, proposal.md, specs/*.md |
| 创建时间 | 2026-01-09 |
| 状态 | Draft |

---

## 模式选择

**当前模式**：`主线计划模式 (Main Plan Mode)`

---

# 计划区域

## 主线计划区 (Main Plan Area)

### MP1: Embedding 索引默认启用

**目的 (Why)**：让 Embedding 索引首次运行时自动构建，减少用户配置成本。

**交付物 (Deliverables)**：
- 修改 `setup/global-hooks/augment-context-global.sh`：新增索引检测与自动构建逻辑
- 扩展 `.devbooks/config.yaml` 配置项

**影响范围 (Files/Modules)**：
- `setup/global-hooks/augment-context-global.sh`（修改）
- `tools/devbooks-embedding.sh`（轻微修改，增强错误处理）

**验收标准 (Acceptance Criteria)**：
- AC-001: `devbooks-embedding.sh build` 退出码 0，且生成索引文件
- AC-006: 无 API Key 时优雅降级，输出 `fallback` 标记

**依赖 (Dependencies)**：无

**风险 (Risks)**：
- Embedding API 不可用时需确保降级逻辑正确

#### MP1.1: 索引检测逻辑

**交付物**：在 Hook 启动时检测 `.devbooks/embeddings/` 是否存在有效索引

**验收锚点**：
- 测试：索引存在时直接使用
- 测试：索引不存在时触发构建提示

**Trace**: AC-001, REQ-EMB-001, SC-EMB-002

#### MP1.2: 自动构建触发

**交付物**：首次运行且有 API Key 时，后台触发 `devbooks-embedding.sh build`

**验收锚点**：
- 测试：有 API Key 时触发后台构建
- 测试：构建过程不阻塞 Hook 首次响应

**Trace**: AC-001, REQ-EMB-001, SC-EMB-001

#### MP1.3: 降级逻辑

**交付物**：无 API Key 时跳过 Embedding，输出 `fallback.reason: no_api_key`

**验收锚点**：
- 测试：无 API Key 时 Hook 正常返回
- 测试：输出包含 `fallback` 字段

**Trace**: AC-006, REQ-EMB-003, SC-EMB-004

---

### MP2: Graph-RAG 上下文引擎

**目的 (Why)**：实现向量搜索 + CKB 图遍历的智能上下文检索。

**交付物 (Deliverables)**：
- 新增 `tools/graph-rag-context.sh`
- 修改 `setup/global-hooks/augment-context-global.sh`：集成 Graph-RAG 调用

**影响范围 (Files/Modules)**：
- `tools/graph-rag-context.sh`（新增）
- `setup/global-hooks/augment-context-global.sh`（修改）

**验收标准 (Acceptance Criteria)**：
- AC-002: 10 个预设查询相关性 ≥ 70%
- AC-007: `graph_rag.enabled: false` 时跳过 Graph-RAG
- AC-008: P95 延迟 < 3s

**依赖 (Dependencies)**：MP1（Embedding 索引）

**风险 (Risks)**：
- CKB 索引不完整导致图遍历失败
- 延迟超标

#### MP2.1: 向量搜索模块

**交付物**：实现 Embedding 向量搜索，返回 Top-K 相关代码片段

**验收锚点**：
- 测试：给定查询返回 ≤ K 个候选
- 测试：每个候选包含 `file_path`, `relevance_score`

**Trace**: AC-002, REQ-GRAG-001, SC-GRAG-001

#### MP2.2: CKB 图遍历模块

**交付物**：从锚点符号调用 CKB `getCallGraph` / `findReferences` 扩展上下文

**验收锚点**：
- 测试：遍历 callers/callees 到指定深度
- 测试：深度限制生效（`max_depth` 配置）

**Trace**: AC-002, REQ-GRAG-002, SC-GRAG-002, SC-GRAG-003

#### MP2.3: 动态 Token 预算

**交付物**：按 `token_budget` 配置裁剪输出，低相关性内容优先裁剪

**验收锚点**：
- 测试：输出 token 数 ≤ `token_budget`
- 测试：高相关性内容优先保留

**Trace**: REQ-GRAG-003, SC-GRAG-004

#### MP2.4: 缓存机制

**交付物**：实现查询结果缓存，缓存键为查询 hash，TTL 可配置

**验收锚点**：
- 测试：相同查询命中缓存
- 测试：缓存过期后重新计算

**Trace**: AC-008, REQ-GRAG-004, SC-GRAG-005

#### MP2.5: Hook 集成

**交付物**：在 `augment-context-global.sh` 中调用 `graph-rag-context.sh`，输出 `graphContext` 字段

**验收锚点**：
- 测试：Hook 输出包含 `graphContext`
- 测试：`graph_rag.enabled: false` 时不调用

**Trace**: AC-007, REQ-HOOK-001, REQ-HOOK-002

---

### MP3: LLM 重排序

**目的 (Why)**：使用 Haiku 对候选上下文进行语义重排序，提升相关性。

**交付物 (Deliverables)**：
- 新增 `tools/context-reranker.sh`
- 扩展配置项 `reranker.*`

**影响范围 (Files/Modules)**：
- `tools/context-reranker.sh`（新增）
- `setup/global-hooks/augment-context-global.sh`（修改）

**验收标准 (Acceptance Criteria)**：
- AC-003: `context-reranker.sh` 成功执行，输出 `ranked_results`
- AC-007: `reranker.enabled: false`（默认）时跳过

**依赖 (Dependencies)**：MP2（Graph-RAG 输出作为输入）

**风险 (Risks)**：
- API 调用增加延迟
- 重排序质量不稳定

#### MP3.1: 重排序脚本实现

**交付物**：实现 `context-reranker.sh`，接受候选列表，调用 Anthropic API (Haiku) 重排序

**验收锚点**：
- 测试：输入 JSON → 输出包含 `ranked_results`
- 测试：`--mock-llm` 参数返回固定结果

**Trace**: AC-003

#### MP3.2: 配置与开关

**交付物**：新增 `reranker.enabled`（默认 false）、`reranker.model` 配置项

**验收锚点**：
- 测试：`enabled: false` 时不调用 API
- 测试：`enabled: true` 时正常调用

**Trace**: AC-007, REQ-HOOK-002, SC-HOOK-004

---

### MP4: 多跳调用链追踪

**目的 (Why)**：封装 CKB 调用链追踪能力，支持 2-3 跳分析。

**交付物 (Deliverables)**：
- 新增 `tools/call-chain-tracer.sh`

**影响范围 (Files/Modules)**：
- `tools/call-chain-tracer.sh`（新增）

**验收标准 (Acceptance Criteria)**：
- AC-004: 输出包含 ≥ 2 层嵌套的调用链 JSON

**依赖 (Dependencies)**：无（依赖 CKB MCP Server）

**风险 (Risks)**：
- 循环依赖导致无限递归

#### MP4.1: 基础调用链追踪

**交付物**：实现 `--symbol`、`--direction`、`--depth` 参数，调用 CKB `getCallGraph`

**验收锚点**：
- 测试：`--direction callers` 返回调用方
- 测试：`--direction callees` 返回被调用方
- 测试：`--depth 2` 限制遍历深度

**Trace**: AC-004, REQ-CHAIN-001, SC-CHAIN-001, SC-CHAIN-002

#### MP4.2: 入口路径追溯

**交付物**：实现 `--trace-usage` 参数，调用 CKB `traceUsage`

**验收锚点**：
- 测试：返回从入口到目标的调用路径
- 测试：路径包含 `file_path`, `line`, `symbol_name`

**Trace**: AC-004, REQ-CHAIN-002, SC-CHAIN-003

#### MP4.3: 循环检测

**交付物**：记录已访问节点，检测到循环时终止并标记 `cycle_detected: true`

**验收锚点**：
- 测试：循环调用场景下正常返回
- 测试：输出包含 `cycle_detected` 标记

**Trace**: REQ-CHAIN-003, SC-CHAIN-004

---

### MP5: 简化版 Bug 定位

**目的 (Why)**：基于调用链 + 变更历史输出 Bug 候选位置推荐。

**交付物 (Deliverables)**：
- 新增 `tools/bug-locator.sh`

**影响范围 (Files/Modules)**：
- `tools/bug-locator.sh`（新增）

**验收标准 (Acceptance Criteria)**：
- AC-005: 输出 Top-5 候选列表，10 个 case 命中率 ≥ 60%

**依赖 (Dependencies)**：MP4（调用链追踪）

**风险 (Risks)**：
- 命中率不达标

#### MP5.1: 候选位置生成

**交付物**：解析错误信息，调用 `call-chain-tracer.sh` 获取相关符号，生成候选列表

**验收锚点**：
- 测试：给定错误信息返回 Top-5 候选
- 测试：每个候选包含 `file_path`, `confidence`, `reason`

**Trace**: AC-005, REQ-BUG-001, SC-BUG-001

#### MP5.2: 变更历史关联

**交付物**：获取 Git 历史，最近修改的文件权重提高

**验收锚点**：
- 测试：最近修改的文件 confidence 更高
- 测试：`--history-depth` 参数生效

**Trace**: REQ-BUG-002, SC-BUG-003

#### MP5.3: 热点交叉

**交付物**：与项目热点文件交叉，标记 `is_hotspot: true`

**验收锚点**：
- 测试：热点文件包含 `is_hotspot` 标记
- 测试：热点来源为 `devbooks-get-hotspots` 或 CKB

**Trace**: REQ-BUG-003, SC-BUG-004

---

### MP6: 测试与文档

**目的 (Why)**：确保质量闸门通过，文档更新。

**交付物 (Deliverables)**：
- BATS 测试文件
- 性能测试脚本
- 文档更新

**影响范围 (Files/Modules)**：
- `tests/` 目录（新增）
- `docs/` 目录（更新）

**验收标准 (Acceptance Criteria)**：
- AC-008: P95 延迟 < 3s
- 所有 AC 有对应测试

**依赖 (Dependencies)**：MP1-MP5

**风险 (Risks)**：
- 测试覆盖不足

#### MP6.1: BATS 单元测试

**交付物**：为 4 个新工具脚本编写 BATS 测试

**验收锚点**：
- `bats tests/` 100% pass
- 覆盖正常流程、降级流程、错误处理

**Trace**: 质量闸门

#### MP6.2: 性能测试脚本

**交付物**：编写 `tests/performance-test.sh`，测量 20 次查询延迟

**验收锚点**：
- 输出 P50, P95, P99 延迟
- AC-008: P95 < 3s

**Trace**: AC-008

#### MP6.3: 相关性评测

**交付物**：准备 10 个评测 case，编写评测脚本

**验收锚点**：
- AC-002: 相关性 ≥ 70%
- AC-005: Top-5 命中率 ≥ 60%

**Trace**: AC-002, AC-005

#### MP6.4: 文档更新

**交付物**：更新 `docs/Augment-vs-DevBooks-技术对比.md`、`docs/embedding-quickstart.md`

**验收锚点**：
- 文档反映新功能
- 新增 Graph-RAG 使用说明

---

## 临时计划区 (Temporary Plan Area)

> 仅用于计划外高优任务。当前为空。

| 任务 ID | 触发原因 | 影响面 | 最小修复范围 | 回归测试要求 |
|---------|----------|--------|--------------|--------------|
| （空） | - | - | - | - |

---

# 断点区 (Context Switch Breakpoint Area)

> 用于切换主线/临时计划时记录上下文。

| 字段 | 值 |
|------|-----|
| 当前任务 | - |
| 中断原因 | - |
| 恢复条件 | - |
| 待确认问题 | - |

---

# 计划细化区

## Scope & Non-goals

**Scope**：
- Embedding 索引默认启用与降级
- Graph-RAG 上下文引擎（向量搜索 + CKB 图遍历）
- LLM 重排序（可选，默认关闭）
- 多跳调用链追踪
- 简化版 Bug 定位

**Non-goals**：
- CFG/PDG 深度静态分析
- 实时索引更新
- 代码补全
- 跨仓库联邦

## Architecture Delta

**新增组件**：
- `tools/graph-rag-context.sh`
- `tools/context-reranker.sh`
- `tools/call-chain-tracer.sh`
- `tools/bug-locator.sh`

**依赖方向**：
- `augment-context-global.sh` → 新增工具脚本 → CKB MCP / Embedding Index / Anthropic API

**扩展点**：
- Embedding 提供商：配置 `embedding.provider`
- 重排序模型：配置 `reranker.model`
- 图遍历深度：配置 `graph_rag.max_depth`

## Data Contracts

详见 design.md 的 "Contract（契约计划）" 章节。

**关键契约**：
- Hook 输出格式：`graphContext`、`callChain`、`fallback` 字段
- schema_version: `1.0`
- 兼容策略：新增字段向后兼容

## Milestones

| 里程碑 | 内容 | 验收口径 | 预估工作量 |
|--------|------|----------|------------|
| M1 | MP1 + MP2.1-2.5 | AC-001, AC-002, AC-006, AC-007 | 2.5 天 |
| M2 | MP4.1-4.3 + MP5.1-5.3 | AC-004, AC-005 | 2.5 天 |
| M3 | MP3.1-3.2 | AC-003 | 1 天 |
| M4 | MP6.1-6.4 | AC-008, 质量闸门 | 2 天 |

**总计**：8 天

## Work Breakdown

**PR 切分建议**：

| PR | 包含任务 | 可并行 | 依赖 |
|----|----------|--------|------|
| PR-1 | MP1.1, MP1.2, MP1.3 | 是 | 无 |
| PR-2 | MP2.1, MP2.2, MP2.3, MP2.4, MP2.5 | 是（与 PR-4 并行） | PR-1 |
| PR-3 | MP3.1, MP3.2 | 是（与 PR-2 并行） | PR-2 |
| PR-4 | MP4.1, MP4.2, MP4.3 | 是（与 PR-2 并行） | 无 |
| PR-5 | MP5.1, MP5.2, MP5.3 | 否 | PR-4 |
| PR-6 | MP6.1, MP6.2, MP6.3, MP6.4 | 否 | PR-1 至 PR-5 |

**并行关系图**：

```
PR-1 (Embedding)
    │
    ├──► PR-2 (Graph-RAG) ──► PR-3 (Reranker)
    │         │
    │         └───────────────────┐
    │                             │
    └──► PR-4 (Call-chain) ──► PR-5 (Bug-locator)
                                  │
                                  ▼
                            PR-6 (Tests & Docs)
```

## Algorithm Spec

### Graph-RAG 上下文构建算法

**Inputs**：
- `query: string` - 用户查询
- `top_k: number` - 向量搜索返回数量
- `max_depth: number` - 图遍历深度
- `token_budget: number` - Token 预算

**Outputs**：
- `candidates: ContextCandidate[]` - 排序后的候选列表
- `token_count: number` - 实际 token 数

**Invariants**：
- `token_count ≤ token_budget`
- `candidates` 按 `relevance_score` 降序排列
- 每个 `candidate` 有唯一的 `(file_path, line_start, line_end)` 组合

**Failure Modes**：
- Embedding 索引不可用 → 降级到关键词搜索
- CKB 不可用 → 仅使用 Embedding 结果
- Token 预算用尽 → 截断低相关性候选

**核心流程**（伪代码）：

```
FUNCTION build_graph_rag_context(query, top_k, max_depth, token_budget):
    // Step 1: 向量搜索
    anchors = CALL embedding_search(query, top_k)
    IF anchors IS EMPTY:
        RETURN fallback_to_keyword(query)

    // Step 2: 图遍历扩展
    candidates = EMPTY LIST
    visited = EMPTY SET

    FOR EACH anchor IN anchors:
        symbol_id = RESOLVE symbol_id FROM anchor
        IF symbol_id NOT IN visited:
            ADD symbol_id TO visited
            graph_nodes = CALL ckb_get_call_graph(symbol_id, max_depth)
            FOR EACH node IN graph_nodes:
                candidate = BUILD candidate FROM node
                ADD candidate TO candidates

    // Step 3: 去重与排序
    candidates = DEDUPLICATE candidates BY (file_path, line_range)
    candidates = SORT candidates BY relevance_score DESC

    // Step 4: Token 预算裁剪
    total_tokens = 0
    result = EMPTY LIST
    FOR EACH candidate IN candidates:
        candidate_tokens = COUNT tokens IN candidate
        IF total_tokens + candidate_tokens > token_budget:
            BREAK
        ADD candidate TO result
        total_tokens = total_tokens + candidate_tokens

    RETURN result, total_tokens
```

**复杂度**：
- Time: O(top_k × max_depth × avg_graph_size)
- Space: O(candidates_count)
- IO: Embedding 查询 1 次 + CKB 查询 top_k 次

**边界条件与测试用例要点**：
1. `query` 为空 → 返回空结果
2. Embedding 索引为空 → 降级到关键词
3. `top_k = 0` → 返回空结果
4. `max_depth = 0` → 仅返回锚点，不遍历
5. `token_budget = 0` → 返回空结果
6. 所有候选都是同一文件 → 合并行范围
7. CKB 返回循环依赖 → 去重处理

### Bug 定位置信度计算算法

**Inputs**：
- `error_info: string` - 错误信息
- `call_chain: CallChainNode[]` - 调用链
- `git_history: GitCommit[]` - Git 历史
- `hotspots: Hotspot[]` - 热点文件

**Outputs**：
- `candidates: BugCandidate[]` - Top-N 候选列表

**核心流程**（伪代码）：

```
FUNCTION calculate_bug_candidates(error_info, call_chain, git_history, hotspots):
    candidates = EMPTY LIST

    // Step 1: 从调用链提取候选
    FOR EACH node IN call_chain:
        candidate = CREATE BugCandidate FROM node
        candidate.call_chain_score = CALCULATE distance_score(node.depth)
        ADD candidate TO candidates

    // Step 2: 计算变更历史分数
    FOR EACH candidate IN candidates:
        last_modified = FIND last_modified_date(candidate.file_path, git_history)
        candidate.history_score = CALCULATE recency_score(last_modified)

    // Step 3: 热点交叉
    FOR EACH candidate IN candidates:
        IF candidate.file_path IN hotspots:
            candidate.hotspot_score = hotspots[candidate.file_path].score
            candidate.is_hotspot = TRUE
        ELSE:
            candidate.hotspot_score = 0
            candidate.is_hotspot = FALSE

    // Step 4: 综合置信度
    FOR EACH candidate IN candidates:
        candidate.confidence =
            0.4 × candidate.call_chain_score +
            0.3 × candidate.history_score +
            0.15 × candidate.hotspot_score +
            0.15 × candidate.error_pattern_score

    // Step 5: 排序返回 Top-N
    candidates = SORT candidates BY confidence DESC
    RETURN TOP N candidates
```

**边界条件与测试用例要点**：
1. `error_info` 无法解析 → 返回基于热点的默认候选
2. `call_chain` 为空 → 仅使用 Git 历史和热点
3. 所有候选 confidence 相同 → 按文件路径字母排序
4. 候选数 < N → 返回所有候选
5. 热点列表为空 → hotspot_score 为 0

## Quality Gates

| 闸门 | 命令 | 阈值 | 阻断级别 |
|------|------|------|----------|
| ShellCheck | `shellcheck tools/*.sh setup/global-hooks/*.sh` | 0 warnings | CI 阻断 |
| BATS | `bats tests/` | 100% pass | CI 阻断 |
| 延迟 | `./tests/performance-test.sh` | P95 < 3s | CI 阻断 |
| 相关性 | 人工评测 | ≥ 70% | Review 阻断 |

## Observability

| 指标 | 采集方式 | 落点 |
|------|----------|------|
| hook_latency_ms | 脚本内 `date +%s%3N` | stdout |
| embedding_hit_rate | 缓存命中日志 | `.devbooks/logs/` |
| fallback_count | 降级计数 | stdout |

## Rollout & Rollback

**灰度策略**：
- 配置开关控制（`graph_rag.enabled`, `reranker.enabled`）
- 默认启用 Graph-RAG，默认关闭 Reranker

**回滚方式**：
1. 配置 `graph_rag.enabled: false` → 回退到关键词搜索
2. 恢复 `augment-context-global.sh` 到 v2.x → 完整回滚

## Risks & Edge Cases

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Embedding API 限流 | 中 | 中 | 本地 Ollama 备选 |
| CKB 索引过期 | 低 | 中 | 提示用户重建 |
| 延迟超标 | 中 | 高 | 缓存 + 超时降级 |

## Open Questions

| ID | 问题 | 影响 | 建议 |
|----|------|------|------|
| OQ-001 | 大型项目（>50k 文件）的索引策略？ | 性能 | 增量索引 + 热点目录优先 |
| OQ-002 | 相关性评测的评分标准需要细化？ | 验收 | 由 Test Owner 定义 |
| OQ-003 | Embedding 提供商默认优先级？ | 用户体验 | OpenAI > Azure > Ollama |

---

*编码计划由 devbooks-implementation-plan 生成*
*下一步：运行 `openspec validate achieve-augment-parity --strict` 并修复所有问题*
