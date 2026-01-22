# Proposal: achieve-augment-parity

> 产物落点：`openspec/changes/achieve-augment-parity/proposal.md`
> 状态：Draft
> 创建时间：2026-01-09

---

## 1. Why（问题与目标）

### 1.1 问题陈述

DevBooks 当前实现仅达到 Augment Code **35-40%** 的能力水平，核心差距集中在三个维度：

| 维度 | Augment | DevBooks 现状 | 差距 |
|------|---------|---------------|------|
| **代码理解深度** | 图基语义理解 (UCG) | 关键词 + CKB 单层 | 中 |
| **上下文注入** | 智能子图检索 + LLM 重排序 | Hook 注入（固定 ~2k tokens） | 中 |
| **Bug 定位** | 执行路径追踪 (CFG/PDG) | 仅符号搜索 | 大 |

### 1.2 目标

**在单次变更中将 DevBooks 提升至 Augment 60-70% 能力水平**，具体目标：

1. **代码理解深度**：从"关键词匹配"升级到"图遍历 + 向量语义"
2. **上下文注入**：从"固定模板注入"升级到"Graph-RAG 智能检索"
3. **Bug 定位**：从"无能力"升级到"简化版调用链追踪"

### 1.3 成功指标

| 指标 | 当前值 | 目标值 | 验证方法 |
|------|-------|-------|---------|
| Augment 相似度 | 35-40% | 60-70% | 功能矩阵对比 |
| 上下文相关性 | 低（关键词） | 中高（语义） | 人工评测 10 个 case |
| 调用链追踪深度 | 0 跳 | 2-3 跳 | 测试用例验证 |

---

## 2. What Changes（范围与非目标）

### 2.1 变更范围（In Scope）

#### 模块 1：Embedding 索引默认启用

| 项目 | 说明 |
|------|------|
| 变更文件 | `setup/global-hooks/augment-context-global.sh` |
| 变更内容 | 首次运行时自动构建 Embedding 索引；索引缺失时显示构建命令 |
| 依赖 | OpenAI API Key（或本地 Ollama） |
| 降级策略 | 无 API Key 时降级到关键词搜索 |

#### 模块 2：Graph-RAG 上下文引擎

| 项目 | 说明 |
|------|------|
| 新增文件 | `tools/graph-rag-context.sh` |
| 变更文件 | `setup/global-hooks/augment-context-global.sh` |
| 功能 | 向量搜索定位锚点 → CKB 图遍历扩展 → 动态 Token 预算 |
| 依赖 | CKB MCP Server、Embedding 索引 |

#### 模块 3：LLM 重排序

| 项目 | 说明 |
|------|------|
| 新增文件 | `tools/context-reranker.sh` |
| 功能 | 使用小模型（Haiku）对候选上下文重排序 |
| 依赖 | Anthropic API（Haiku） |
| 备注 | 默认关闭，通过配置启用；需 A/B 测试验证 ROI |

#### 模块 4：多跳调用链追踪

| 项目 | 说明 |
|------|------|
| 新增文件 | `tools/call-chain-tracer.sh` |
| 功能 | 封装 CKB `getCallGraph` + `traceUsage`，支持 2-3 跳追踪 |
| 依赖 | CKB MCP Server、SCIP 索引 |

#### 模块 5：简化版 Bug 定位

| 项目 | 说明 |
|------|------|
| 新增文件 | `tools/bug-locator.sh` |
| 功能 | 基于调用链 + 变更历史的候选位置推荐（非精确定位） |
| 依赖 | 模块 4、Git 历史 |
| 定位 | **候选推荐**，验收标准为 Top-5 命中率 ≥ 60% |

### 2.2 非目标（Out of Scope）

| 项目 | 原因 |
|------|------|
| 控制流图 (CFG) | 需要语言特定的深度 AST 分析，ROI 低 |
| 数据流图 (PDG) | 同上，且需要 2-3 个月开发 |
| 实时索引更新 | 当前 Git Hook 触发足够，实时性不是首要目标 |
| 代码补全 | 超出 DevBooks 定位（变更管理框架） |
| 跨仓库联邦 | 复杂度高，留待后续版本 |

### 2.3 影响范围

| 影响类型 | 文件/模块 | 影响程度 |
|----------|----------|----------|
| 新增文件 | 4 个 Shell 脚本 | 新增 |
| 修改文件 | `augment-context-global.sh` | 中度重构 |
| 配置变更 | `.devbooks/config.yaml` | 新增配置项 |
| 文档变更 | `docs/Augment-vs-DevBooks-技术对比.md` | 更新对比 |
| 依赖变更 | 需要 OpenAI API Key 或 Ollama | 新增依赖（可选） |

---

## 3. Impact（影响分析）

### 分析模式
- [ ] 图基分析（SCIP 索引）
- [x] 文本搜索（降级模式）

**索引状态**：SCIP 索引不可用，使用文本搜索进行影响分析。

---

### 3.1 Scope（影响范围）

#### 直接影响文件

| 文件 | 影响类型 | 变更性质 | 风险等级 |
|------|----------|----------|----------|
| `setup/global-hooks/augment-context-global.sh` | 中度重构 | 新增 Graph-RAG 调用逻辑 | 中 ⚠️ |
| `.devbooks/config.yaml` | 配置扩展 | 新增 `embedding.*` 和 `graph_rag.*` 配置项 | 低 |
| `setup/global-hooks/install.sh` | 轻微修改 | 可能需更新安装逻辑以支持新依赖检查 | 低 |

#### 新增文件（4个工具脚本）

| 文件路径 | 功能 | 依赖 | 复杂度估算 |
|---------|------|------|-----------|
| `tools/graph-rag-context.sh` | 向量搜索 + CKB 图遍历 | CKB MCP + Embedding 索引 | 高 |
| `tools/context-reranker.sh` | LLM 重排序（Haiku） | Anthropic API | 中 |
| `tools/call-chain-tracer.sh` | 多跳调用链追踪 | CKB MCP + SCIP 索引 | 中 |
| `tools/bug-locator.sh` | 简化版 Bug 定位 | `call-chain-tracer.sh` + Git 历史 | 中 |

#### 间接影响文件

| 文件 | 影响原因 | 建议行动 |
|------|----------|----------|
| `tools/devbooks-embedding.sh` | 索引构建将被默认启用调用 | 需确保错误处理健壮 |
| `docs/embedding-quickstart.md` | 需更新文档说明默认启用逻辑 | 更新文档 |
| `openspec/specs/embedding/spec.md` | 需更新规格反映默认启用行为 | 更新规格 |
| `openspec/specs/global-hooks/spec.md` | Hook 输出格式变化 | 更新规格 |

#### 热点重叠分析

**热点文件**（最近30天变更频率 Top 5）：
```
4 changes - setup/README.md
3 changes - skills/devbooks-spec-delta/SKILL.md
3 changes - skills/devbooks-router/SKILL.md
3 changes - skills/devbooks-impact-analysis/SKILL.md
3 changes - .claude/hooks/augment-context.sh
```

**热点重叠**：
- ⚠️ `setup/README.md`：高频变更文件，需格外注意文档一致性
- ⚠️ `.claude/hooks/augment-context.sh`：旧版 Hook 实现，需确认是否需要同步更新

#### 统计汇总

- **直接影响**：3 个现有文件
- **新增文件**：4 个工具脚本
- **间接影响**：4 个文档/规格文件
- **热点重叠**：2 个高风险区域
- **项目规模**：~2500 个代码文件

---

### 3.2 Impacts（具体影响）

#### 3.2.1 架构层面影响

**新增依赖关系**：
```
augment-context-global.sh (v3.0)
    ├── [新增] graph-rag-context.sh
    │   ├── [新增依赖] Embedding 索引 (.devbooks/embeddings/)
    │   ├── [已有] CKB MCP Server (mcp__ckb__*)
    │   └── [新增依赖] OpenAI API / Ollama
    ├── [新增] context-reranker.sh
    │   └── [新增依赖] Anthropic API (Haiku)
    ├── [新增] call-chain-tracer.sh
    │   ├── [已有] CKB MCP (getCallGraph, traceUsage)
    │   └── [已有] SCIP 索引
    └── [新增] bug-locator.sh
        ├── [依赖] call-chain-tracer.sh
        └── [已有] Git 历史分析
```

**C4 层级影响**：
- **C2 容器层**：`tools/` 容器新增 4 个脚本，职责扩展
- **C3 组件层**：`augment-context-global.sh` 从"简单符号搜索"升级到"Graph-RAG 引擎"
- **分层约束检查**：✅ 符合架构守则（tooling 层调用 content 层与外部 API）

#### 3.2.2 对外契约影响

| 契约类型 | 变更内容 | 兼容性 | 风险评估 |
|---------|----------|--------|----------|
| Hook 输出格式 | 新增 `graphContext` 字段（可选） | ✅ 向后兼容 | 低 - Claude Code 忽略未知字段 |
| 配置文件 Schema | 新增 `embedding.*` 和 `graph_rag.*` 配置块 | ✅ 向后兼容 | 低 - 旧配置继续有效 |
| CLI 工具接口 | 新增 4 个命令行工具 | ✅ 新增 | 低 - 不影响现有工具 |
| Embedding 索引格式 | 保持不变 | ✅ 兼容 | 低 |
| SCIP 索引格式 | 保持不变（读取） | ✅ 兼容 | 低 |

**破坏性变更**：❌ 无

#### 3.2.3 数据与存储影响

| 数据类型 | 变更 | 磁盘占用估算 | 备注 |
|---------|------|-------------|------|
| Embedding 索引 | 新增 `.devbooks/embeddings/` | 50-200MB | 取决于项目规模 |
| Graph-RAG 缓存 | 新增 `.devbooks/cache/graph-context/` | 10-50MB | 动态增长 |
| LLM 重排序缓存 | 新增 `.devbooks/cache/reranker/` | 5-20MB | 可配置 TTL |
| 配置文件 | `.devbooks/config.yaml` 扩展 | +1KB | 忽略不计 |

**总磁盘占用增量**：65-270MB（取决于项目规模与缓存策略）

#### 3.2.4 性能影响

| 场景 | 当前延迟 | 预期延迟 | 变化 | 缓解措施 |
|------|---------|---------|------|----------|
| 首次查询（无索引） | <1s | 引导构建索引 | N/A | 异步预构建 |
| 首次查询（有索引） | <1s | 2-3s | +1-2s | 增量缓存 |
| 后续查询（命中缓存） | <1s | 1-1.5s | +0-0.5s | 可接受 |
| Embedding 索引构建 | N/A | 1-5 分钟 | 新增 | 后台异步执行 |

**风险点**：
- ⚠️ Graph-RAG 首次查询可能较慢（2-3s），需优化
- ⚠️ LLM 重排序增加 API 调用延迟（~500ms）

#### 3.2.5 测试影响

| 测试类型 | 现有测试 | 需新增 | 需修改 | 估算工作量 |
|---------|---------|--------|--------|-----------|
| 单元测试（BATS） | 0 个 | 4 个脚本测试 | N/A | 1 天 |
| 集成测试 | 0 个 | 1 个端到端测试 | N/A | 0.5 天 |
| Mock 更新 | N/A | CKB MCP mock | N/A | 0.5 天 |
| 性能测试 | 0 个 | 1 个延迟基准 | N/A | 0.5 天 |

**测试覆盖率影响**：当前无测试 → 需建立测试基础设施

#### 3.2.6 文档与规格影响

| 文档 | 变更类型 | 优先级 |
|------|----------|--------|
| `docs/Augment-vs-DevBooks-技术对比.md` | 更新能力对比（35% → 60%） | 高 |
| `docs/embedding-quickstart.md` | 新增 Graph-RAG 使用说明 | 高 |
| `setup/README.md` | 新增依赖安装说明（API Keys） | 高 |
| `openspec/specs/global-hooks/spec.md` | 更新 Hook 输出格式规格 | 中 |
| `openspec/specs/embedding/spec.md` | 更新默认启用行为 | 中 |

---

### 3.3 Risks（风险）

#### 高风险（需立即缓解）

| 风险 ID | 描述 | 概率 | 影响 | 缓解措施 | 责任人 |
|---------|------|------|------|----------|--------|
| R-001 | `augment-context-global.sh` 重构引入回归 | 中 | 高 | 完整的回归测试 + 灰度发布 | Coder |
| R-002 | Embedding API 成本失控 | 中 | 高 | 支持本地 Ollama + 使用量监控 | Design Owner |
| R-003 | Graph-RAG 延迟过高影响用户体验 | 中 | 高 | 增量缓存 + P95 延迟 <3s 闸门 | Coder |

#### 中风险（需监控）

| 风险 ID | 描述 | 概率 | 影响 | 缓解措施 |
|---------|------|------|------|----------|
| R-004 | CKB 索引不完整导致图遍历失败 | 低 | 中 | 自动降级到关键词搜索 |
| R-005 | LLM 重排序质量不稳定 | 中 | 低 | 可配置关闭 + A/B 测试 |
| R-006 | 4 个新工具脚本增加维护成本 | 高 | 中 | 统一错误处理 + 日志规范 |
| R-007 | 与现有 Hook 版本冲突 | 低 | 中 | 版本检测 + 迁移脚本 |

#### 低风险（可接受）

| 风险 ID | 描述 | 概率 | 影响 | 备注 |
|---------|------|------|------|------|
| R-008 | 用户未配置 API Key | 高 | 低 | 降级到基础模式 + 安装引导 |
| R-009 | 磁盘占用增加（~200MB） | 高 | 低 | 现代机器可接受 |

#### 技术债务引入风险

| 债务 | 引入原因 | 偿还计划 |
|------|----------|----------|
| 4 个新脚本缺少单元测试 | 时间约束 | 1-2 周内补齐 |
| Graph-RAG 缓存策略简化 | MVP 优先 | 后续版本优化 |
| 调用链追踪仅支持 2-3 跳 | 不实现 CFG/PDG | 明确标注限制 |

---

### 3.4 Minimal Diff（最小改动建议）

#### 策略 A：完整实现（提案原方案）

**优点**：
- 一次性实现所有 5 个模块
- 模块间依赖关系清晰，集成成本低
- 能力提升明显（35% → 60-70%）

**缺点**：
- 范围大，风险集中
- 首次发布可能不稳定
- 工作量估算 8 天，可能延期

#### 策略 B：分阶段实施（推荐）

**第一阶段**（优先级 P0，2-3 天）：
1. ✅ Embedding 索引默认启用（模块 1）
2. ✅ Graph-RAG 上下文引擎（模块 2）
   - 不含 LLM 重排序
   - 降级到简单的相似度排序

**第二阶段**（优先级 P1，2-3 天）：
3. ✅ 多跳调用链追踪（模块 4）
4. ✅ 简化版 Bug 定位（模块 5）

**第三阶段**（优先级 P2，可选）：
5. ⚠️ LLM 重排序（模块 3）
   - 作为实验性功能
   - 默认关闭，通过配置启用

**理由**：
- 分阶段降低单次变更风险
- 可提前验证 Graph-RAG 效果
- LLM 重排序 ROI 存疑，可延后验证

#### 策略 C：最小 MVP（激进）

**范围**：
1. ✅ Graph-RAG 上下文引擎（仅向量搜索 + 单跳扩展）
2. ✅ Embedding 索引默认启用

**放弃**：
- ❌ LLM 重排序
- ❌ 多跳调用链（>2 跳）
- ❌ Bug 定位工具

**适用场景**：
- 快速验证 POC
- 时间紧迫
- 风险规避优先

---

### 3.5 Open Questions（待决问题）

#### 技术决策类

| ID | 问题 | 影响范围 | 紧急度 | 建议决策者 |
|----|------|----------|--------|-----------|
| Q-001 | 是否在一次变更中完成所有 5 个模块？ | 范围 | 高 | Proposal Judge |
| Q-002 | Embedding 是否应该默认启用（需 API Key）？ | 用户体验 | 高 | Proposal Judge |
| Q-003 | LLM 重排序是否值得做（成本/效果平衡）？ | 功能范围 | 中 | Proposal Judge |
| Q-004 | Graph-RAG 延迟目标是多少？（当前 P95 <3s） | 性能 | 中 | Design Owner |
| Q-005 | 调用链追踪支持多少跳？（2-3 跳 vs 5+ 跳） | 功能深度 | 中 | Design Owner |

#### 实现细节类

| ID | 问题 | 需求方 | 建议解决方式 |
|----|------|--------|-------------|
| Q-006 | Embedding 索引失败时的降级策略？ | Coder | 自动降级 + 错误提示 |
| Q-007 | 多个 Embedding 提供商如何切换？ | Coder | 配置文件 `provider` 字段 |
| Q-008 | Graph-RAG 缓存 TTL 设置多久？ | Coder | 默认 5 分钟，可配置 |
| Q-009 | 调用链追踪如何处理循环依赖？ | Coder | 记录已访问节点，检测环 |
| Q-010 | Bug 定位工具输出格式？ | Test Owner | Markdown 列表 + 置信度分数 |

#### 验收标准类

| ID | 问题 | 影响 | 建议 AC |
|----|------|------|---------|
| Q-011 | Graph-RAG 相关性如何量化评估？ | AC-002 | 人工评测 10 个 case，相关性 > 70% |
| Q-012 | 延迟闸门设置多少？ | AC-007 | P95 < 3s，P99 < 5s |
| Q-013 | Embedding 索引构建超时？ | AC-001 | 小项目 <1min，中项目 <5min |

---

### 3.6 Transaction Scope

**`None`** - 本变更不涉及数据库事务，所有操作都是文件级别的读写与 API 调用。

---

### 3.7 价值信号（预期）

| 信号 | 基线（v2.3） | 目标（v3.0） | 提升幅度 | 验证方法 |
|------|-------------|-------------|---------|---------|
| Augment 能力相似度 | 35-40% | 60-70% | +25-30% | 功能矩阵对比 |
| 上下文相关性 | 低（关键词） | 中高（语义） | +50%+ | 人工评测 10 个 case |
| 调用链追踪深度 | 0 跳 | 2-3 跳 | 无限 → 有限 | 测试用例验证 |
| Bug 定位候选精度 | N/A | Top-5 包含真因 > 60% | 新增能力 | 评测集验证 |
| Hook 注入延迟（P95） | <1s | <3s | +2s（可接受） | 性能测试 |

---

### 3.8 影响分析总结

#### 关键发现

1. **架构影响可控**：新增 4 个独立工具脚本，符合分层约束，无破坏性变更。
2. **热点重叠风险**：`setup/README.md` 和 `.claude/hooks/augment-context.sh` 需格外注意。
3. **性能风险中等**：Graph-RAG 首次查询延迟可能达 2-3s，需缓存优化。
4. **测试基础设施缺失**：当前无测试，需从零建立测试体系。
5. **分阶段实施更安全**：建议采用策略 B（分 3 阶段），降低风险。

#### 推荐行动

| 优先级 | 行动 | 责任人 | 时间节点 |
|--------|------|--------|----------|
| P0 | 决策：完整实施 vs 分阶段（Q-001） | Judge | 提案裁决前 |
| P0 | 决策：Embedding 默认启用策略（Q-002） | Judge | 提案裁决前 |
| P1 | 建立测试基础设施（BATS + Mock） | Test Owner | Apply 阶段前 |
| P1 | 性能基准与闸门定义（Q-004, Q-012） | Design Owner | Design 阶段 |
| P2 | LLM 重排序 ROI 评估（Q-003） | Impact Analyst | 可延后到第三阶段 |

---

## 4. Risks & Rollback（风险与回滚）

### 4.1 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Embedding API 成本超预期 | 中 | 中 | 支持本地 Ollama 作为免费替代 |
| Graph-RAG 延迟过高 | 中 | 高 | 增量缓存 + 异步预取 |
| CKB 索引不完整 | 低 | 中 | 降级到关键词搜索 |
| LLM 重排序质量不稳定 | 中 | 低 | 可配置关闭重排序 |
| 调用链追踪深度不足 | 中 | 中 | 明确标注为"简化版"，不承诺 CFG/PDG |

### 4.2 业务风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 用户不愿配置 API Key | 高 | 中 | 提供 Ollama 本地方案 |
| 与现有工作流冲突 | 低 | 低 | 所有新功能可通过配置关闭 |

### 4.3 回滚策略

| 场景 | 回滚方式 |
|------|---------|
| Graph-RAG 失败 | 配置 `graph_rag.enabled: false`，降级到原 Hook |
| Embedding 索引构建失败 | 跳过语义搜索，使用关键词搜索 |
| 重排序效果差 | 配置 `reranker.enabled: false` |
| 整体回滚 | 恢复 `augment-context-global.sh` 到 v2.3 |

---

## 5. Validation（验收锚点）

### 5.1 验收标准

| AC-ID | 验收标准 | 验证方法 |
|-------|---------|---------|
| AC-001 | Embedding 索引可自动构建 | `devbooks-embedding.sh build` 成功 |
| AC-002 | Graph-RAG 可检索相关上下文 | 测试 10 个查询，相关性 > 70% |
| AC-003 | LLM 重排序可运行 | `context-reranker.sh` 成功执行 |
| AC-004 | 调用链追踪支持 2-3 跳 | `call-chain-tracer.sh` 输出正确调用链 |
| AC-005 | Bug 定位可输出候选位置 | `bug-locator.sh` 输出排序后的候选列表，Top-5 命中率 ≥ 60% |
| AC-006 | 无 API Key 时优雅降级 | 降级到关键词搜索，无报错 |
| AC-007 | 所有功能可通过配置关闭 | 验证各开关生效 |
| AC-008 | 延迟 < 3s（P95） | 性能测试 |

### 5.2 证据落点

| 证据类型 | 路径 |
|---------|------|
| 测试报告 | `openspec/changes/achieve-augment-parity/evidence/test-report.md` |
| 性能数据 | `openspec/changes/achieve-augment-parity/evidence/performance.md` |
| 相关性评测 | `openspec/changes/achieve-augment-parity/evidence/relevance-eval.md` |
| 降级验证 | `openspec/changes/achieve-augment-parity/evidence/fallback-test.md` |

---

## 6. Debate Packet（争议点与待决问题）

### 6.1 需要辩论的核心问题

| ID | 问题 | Author 立场 | 预期 Challenger 立场 |
|----|------|------------|---------------------|
| D-001 | 是否应该在一次变更中完成所有 5 个模块？ | 是，模块间强依赖，分开做会增加集成成本 | 否，范围太大，应分 2-3 次变更 |
| D-002 | Embedding 是否应该默认启用（需 API Key）？ | 是，这是追平的核心能力 | 否，会增加用户配置成本 |
| D-003 | 简化版 Bug 定位是否有价值（无 CFG/PDG）？ | 有，调用链追踪已覆盖 60% 场景 | 无，没有 CFG/PDG 就是玩具 |
| D-004 | LLM 重排序的 ROI 是否足够？ | 高，显著提升上下文相关性 | 低，增加延迟和成本，效果不稳定 |

### 6.2 不确定点

| ID | 不确定点 | 影响 | 解决方案 |
|----|---------|------|---------|
| U-001 | Embedding 索引大小（项目规模相关） | 存储成本 | 实测后确定，可能需要分片策略 |
| U-002 | Graph-RAG 延迟（依赖 CKB 性能） | 用户体验 | 需性能测试后确定是否需要优化 |
| U-003 | Haiku 重排序质量（依赖 prompt 设计） | 功能效果 | 需 A/B 测试确定最优 prompt |

### 6.3 风险透明声明

1. **本变更不承诺达到 Augment 100%**：目标是 60-70%，差距主要在 CFG/PDG 等深度静态分析能力。
2. **依赖外部 API**：需要 OpenAI/Anthropic API Key，无 Key 时部分功能不可用。
3. **首次运行可能较慢**：Embedding 索引构建需要 1-5 分钟（取决于项目规模）。

---

## 7. Decision Log（决策日志）

### 7.1 决策状态

**`Approved`** - 2026-01-09 Proposal Judge 裁决（合并为单次变更）

### 7.2 需要裁决的问题清单

| ID | 问题 | 状态 | 裁决 |
|----|------|------|------|
| D-001 | 是否在一次变更中完成所有 5 个模块 | ✅ Resolved | **是，一次变更完成全部 5 个模块** |
| D-002 | Embedding 是否默认启用 | ✅ Resolved | **默认启用 + 优雅降级** |
| D-003 | 简化版 Bug 定位是否值得做 | ✅ Resolved | **保留，定位为"候选推荐"，Top-5 命中率 ≥ 60%** |
| D-004 | LLM 重排序是否纳入本次变更 | ✅ Resolved | **纳入，默认关闭，通过配置启用** |

### 7.3 决策记录

**决策时间**: 2026-01-09
**决策者**: Proposal Judge (DevBooks) + 用户确认

#### 关键决策

**1. 范围确认（D-001）**

- **决策**：一次变更完成全部 5 个模块
- **理由**：模块间强依赖，分开做会增加集成成本
- **工作量**：8 天

**2. Embedding 启用策略（D-002）**

- 默认启用，但提供优雅降级
- 无 API Key 时降级到关键词搜索模式
- 新增配置项：`embedding.enabled`、`embedding.fallback_to_keyword`

**3. Bug 定位定位（D-003）**

- 保留但明确为"候选位置推荐"（非精确定位）
- 验收标准：Top-5 命中率 ≥ 60%

**4. LLM 重排序（D-004）**

- 纳入本次变更
- 默认关闭，通过 `reranker.enabled: true` 启用
- 需 A/B 测试验证 ROI（提升 > 20%，延迟增加 < 1s）

#### 质量闸门

- 行为测试：覆盖正常流程、无 Embedding、CKB 失败三种场景
- 性能测试：P95 延迟 < 3s（中型项目）
- 契约测试：Hook 输出格式兼容性
- 静态检查：ShellCheck + BATS 语法检查零告警

#### 必须提供的证据

| 证据类型 | 路径 |
|---------|------|
| 测试报告 | `evidence/test-report.md` |
| 性能数据 | `evidence/performance.md` |
| 相关性评测 | `evidence/relevance-eval.md` |
| 降级验证 | `evidence/fallback-test.md` |

**签字**: DevBooks Proposal Judge + 用户确认

---

## 附录 A：技术方案概览

### Graph-RAG 流程

```
用户查询
    │
    ▼
┌─────────────────────┐
│ 1. 向量搜索定位锚点 │ ← Embedding 索引
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 2. CKB 图遍历扩展   │ ← getCallGraph / findReferences
│    - callers (2跳)  │
│    - callees (2跳)  │
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 3. 动态 Token 预算  │ ← 4k-16k tokens
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 4. LLM 重排序       │ ← Haiku (可选)
└─────────┬───────────┘
          ▼
     高相关性上下文
```

### 调用链追踪流程

```
目标符号
    │
    ▼
┌─────────────────────┐
│ 1. CKB traceUsage   │ ← 从入口到目标的路径
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 2. Git 历史关联     │ ← 最近修改的文件优先
└─────────┬───────────┘
          ▼
┌─────────────────────┐
│ 3. 热点交叉         │ ← 热点文件标记
└─────────┬───────────┘
          ▼
     候选位置排序列表
```

---

## 附录 B：工作量估算

| 模块 | 预估工作量 | 依赖 |
|------|-----------|------|
| Embedding 默认启用 | 0.5 天 | 无 |
| Graph-RAG 上下文引擎 | 2 天 | Embedding |
| LLM 重排序 | 1 天 | Graph-RAG |
| 多跳调用链追踪 | 1.5 天 | CKB |
| 简化版 Bug 定位 | 1 天 | 调用链追踪 |
| 测试与文档 | 2 天 | 全部 |
| **总计** | **8 天** | - |

---

*提案由 devbooks-proposal-author 生成*
*已通过 Proposal Judge 裁决：Approved*
*下一步：执行 `devbooks-design-doc` 进入 Design 阶段*
