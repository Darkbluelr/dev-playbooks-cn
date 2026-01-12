# 编码计划：boost-local-intelligence

> 提升 DevBooks 本地智能能力的实现计划

---

## 元信息

| 字段 | 内容 |
|------|------|
| 变更包 ID | boost-local-intelligence |
| 维护者 | Planner |
| 创建时间 | 2026-01-09 |
| 输入材料 | `design.md`, `specs/embedding/spec.md`, `specs/graph-rag/spec.md`, `specs/entropy/spec.md`, `specs/intent/spec.md` |
| 关联规范 | SPEC-EMB-001, SPEC-GRG-001, SPEC-ENT-001, SPEC-INT-001 |
| DoD 覆盖 | 行为测试、契约测试、结构测试、静态检查 |

---

## 【模式选择】

**当前模式**：主线计划模式（Main Plan Area）

---

<!-- 计划区域：必须处于文档最上方 -->

## 【主线计划区】(Main Plan Area)

### MP1: 本地 Embedding 向量化（P1 - 高优先级）

**目的（Why）**：
- 实现本地优先的 Embedding 方案，消除对 OpenAI API 的强依赖
- 支持企业防火墙环境与隐私合规场景
- 提供三级降级机制保证基本可用性

**交付物（Deliverables）**：
- `tools/devbooks-embedding.sh` 增加 Ollama 集成
- `tools/embedding-helper.py` 支持本地模型
- `.devbooks/config.yaml` 新增 `embedding.provider` 配置
- 测试用例：CT-EMB-001, CT-EMB-002, CT-EMB-003

**影响范围（Files/Modules）**：
- 核心文件：`tools/devbooks-embedding.sh`, `tools/embedding-helper.py`
- 配置文件：`.devbooks/config.yaml`
- 调用方：`.claude/hooks/augment-context.sh`, `setup/global-hooks/augment-context-global.sh`
- 文档：`docs/embedding-quickstart.md`, `使用说明书.md`

**验收标准（Acceptance Criteria）**：
- AC-001：Ollama 可用时自动使用本地模型
- AC-002：Ollama 不可用时自动降级到 OpenAI API
- AC-003：API 不可用时降级到关键词搜索
- AC-008：向后兼容（不带新参数时行为一致）

**依赖（Dependencies）**：无

**风险（Risks）**：
- R1：Ollama 未安装导致 Embedding 不可用 → 三级降级缓解
- R5：热点文件 `augment-context.sh` 改动引入 Bug → 增加 BATS 测试（批准条件）

**可并行**：否（其他任务依赖本任务的配置模式）

---

#### MP1.1: Ollama 检测与配置解析

**描述**：实现 Ollama 可用性检测与配置读取逻辑

**接口/契约**：
- 函数：`_detect_ollama()` → 返回 boolean
- 函数：`_parse_embedding_config()` → 返回配置对象
- 配置 Schema：见 `SPEC-EMB-001` § 3.2

**涉及文件**：
- `tools/devbooks-embedding.sh`（新增函数）

**验收标准**：
- 执行 `ollama list` 成功则返回 true
- 读取 `embedding.provider`, `embedding.ollama.*` 配置项
- 配置优先级：CLI 参数 > config.yaml > 自动检测

**验收锚点**：CT-EMB-001（Ollama Provider 基础功能）

**依赖**：无

**可并行**：是

---

#### MP1.2: Ollama API 调用封装

**描述**：实现 Ollama API 调用逻辑，生成向量

**接口/契约**：
- 函数：`_embed_with_ollama(query, model, endpoint)` → 返回向量数组
- API Endpoint：`http://localhost:11434/api/embeddings`
- 请求/响应格式：见 `SPEC-EMB-001` § 7.2.1

**涉及文件**：
- `tools/devbooks-embedding.sh`（新增函数）
- `tools/embedding-helper.py`（可选：Python 实现）

**验收标准**：
- 调用 Ollama API 成功返回 768 维向量
- 超时时间 30s（可配置）
- 错误处理：连接失败/模型未下载/超时

**验收锚点**：CT-EMB-001（Ollama Provider 基础功能）

**依赖**：MP1.1

**可并行**：否（依赖 MP1.1）

---

#### MP1.3: 三级降级机制

**描述**：实现 Ollama → OpenAI API → 关键词搜索的降级路径

**接口/契约**：
- 函数：`_select_provider(config)` → 返回实际使用的 provider
- 降级路径：见 `design.md` P1 § 降级路径

**涉及文件**：
- `tools/devbooks-embedding.sh`（修改主流程）

**验收标准**：
- L1 不可用时自动降级到 L2
- L2 不可用时自动降级到 L3（关键词搜索）
- 每次降级输出清晰日志
- JSON 输出包含 `source` 字段

**验收锚点**：AC-002, AC-003, CT-EMB-002（三级降级机制）

**依赖**：MP1.1, MP1.2

**可并行**：否（依赖 MP1.1, MP1.2）

---

#### MP1.4: JSON 输出增强

**描述**：为 JSON 输出新增元数据字段（source, model, embedding_dim）

**接口/契约**：
- JSON Schema：见 `SPEC-EMB-001` § 3.3
- 新增字段：`source`, `model`, `metadata.provider`, `metadata.latency_ms`

**涉及文件**：
- `tools/devbooks-embedding.sh`（修改输出格式）

**验收标准**：
- JSON Schema 校验通过
- 向后兼容（旧字段保持不变）
- 新增字段完整

**验收锚点**：CT-EMB-001

**依赖**：MP1.3

**可并行**：否（依赖 MP1.3）

---

#### MP1.5: CLI 参数扩展

**描述**：为 `devbooks-embedding.sh` 新增 CLI 参数

**接口/契约**：
- 新增参数：`--provider`, `--ollama-model`, `--ollama-endpoint`, `--timeout`
- 参数说明：见 `SPEC-EMB-001` § 3.1

**涉及文件**：
- `tools/devbooks-embedding.sh`（参数解析）

**验收标准**：
- 参数解析正确
- CLI 参数优先级高于配置文件
- 帮助信息更新

**验收锚点**：CT-EMB-001

**依赖**：MP1.1

**可并行**：是（与 MP1.2 并行）

---

#### MP1.6: 配置文件更新

**描述**：更新 `.devbooks/config.yaml` 增加 Ollama 配置

**接口/契约**：
- 新增字段：`embedding.provider`, `embedding.ollama.*`
- Schema：见 `SPEC-EMB-001` § 3.2

**涉及文件**：
- `.devbooks/config.yaml`（新增配置节）

**验收标准**：
- 配置文件格式正确
- 注释说明完整
- 向后兼容（旧配置仍可读取）

**验收锚点**：CT-EMB-003（向后兼容性）

**依赖**：无

**可并行**：是

---

#### MP1.7: 文档更新

**描述**：更新 Embedding 相关文档，说明 Ollama 使用方式

**涉及文件**：
- `docs/embedding-quickstart.md`（新增 Ollama 安装章节）
- `使用说明书.md`（说明本地 vs API 质量差异 4-8%）

**验收标准**：
- 文档包含 Ollama 安装步骤
- 说明质量差异与使用建议
- 包含配置示例

**验收锚点**：批准条件 § 3（文档更新要求）

**依赖**：MP1.1 ~ MP1.6（实现完成后更新文档）

**可并行**：否（依赖实现完成）

---

### MP2: CKB 真实图遍历（P2 - 高优先级）

**目的（Why）**：
- 替换 import 解析为真实的 CKB MCP API 调用
- 提升图遍历精度（从 60% 提升到 85%）
- 支持 2-4 跳多跳遍历

**交付物（Deliverables）**：
- `tools/graph-rag-context.sh` 集成 CKB API
- `tools/call-chain-tracer.sh` 增强调用链追踪
- `.devbooks/config.yaml` 新增 `graph_rag.ckb.*` 配置
- 测试用例：CT-GRG-001, CT-GRG-002, CT-GRG-003

**影响范围（Files/Modules）**：
- 核心文件：`tools/graph-rag-context.sh`, `tools/call-chain-tracer.sh`
- 配置文件：`.devbooks/config.yaml`
- 调用方：`.claude/hooks/augment-context.sh`, `setup/global-hooks/augment-context-global.sh`

**验收标准（Acceptance Criteria）**：
- AC-004：CKB API 替代 import 解析
- AC-005：图遍历支持 2-4 跳

**依赖（Dependencies）**：MP1（配置模式依赖）

**风险（Risks）**：
- R2：CKB MCP 不可用导致图遍历失败 → 保留 import 解析作为降级

**可并行**：部分可并行（MP2.1 可与 MP1 并行）

---

#### MP2.1: CKB 可用性检测

**描述**：实现 CKB MCP 在线检测与缓存机制

**接口/契约**：
- 函数：`_check_ckb_status()` → 返回 boolean
- API：`mcp__ckb__getStatus`
- 超时时间：1s
- 缓存 TTL：5 分钟

**涉及文件**：
- `tools/graph-rag-context.sh`（新增函数）

**验收标准**：
- 检测成功率 > 99%
- 检测延迟 < 100ms
- 缓存生效

**验收锚点**：CT-GRG-001（CKB API 基础功能）

**依赖**：无

**可并行**：是（与 MP1 并行）

---

#### MP2.2: CKB API 调用封装

**描述**：封装 CKB MCP API 调用逻辑（searchSymbols, getCallGraph, findReferences）

**接口/契约**：
- 函数：`_ckb_search_symbols(query, limit, kinds)` → 返回符号列表
- 函数：`_ckb_get_call_graph(symbol_id, depth, direction)` → 返回调用图
- 函数：`_ckb_find_references(symbol_id, limit)` → 返回引用列表
- API 规范：见 `SPEC-GRG-001` § 3.4

**涉及文件**：
- `tools/graph-rag-context.sh`（新增函数）
- `tools/call-chain-tracer.sh`（调用上述函数）

**验收标准**：
- 3 个 CKB API 调用成功
- 超时时间 5s
- 错误处理完整

**验收锚点**：CT-GRG-001（CKB API 基础功能）

**依赖**：MP2.1

**可并行**：否（依赖 MP2.1）

---

#### MP2.3: 图遍历主流程重构

**描述**：重构 `graph-rag-context.sh` 主流程，优先使用 CKB API

**接口/契约**：
- 流程：Embedding 向量搜索 → CKB 可用性检测 → CKB API 图遍历 OR import 解析降级
- 降级路径：见 `design.md` P2 § 降级路径

**涉及文件**：
- `tools/graph-rag-context.sh`（修改主流程）

**验收标准**：
- CKB 可用时使用 CKB API
- CKB 不可用时降级到 import 解析
- 日志输出清晰

**验收锚点**：AC-004, CT-GRG-002（降级机制）

**依赖**：MP2.1, MP2.2

**可并行**：否（依赖 MP2.1, MP2.2）

---

#### MP2.4: 多跳图遍历

**描述**：实现 2-4 跳图遍历，支持 BFS 策略与循环检测

**接口/契约**：
- 函数：`_traverse_graph(root_symbol_id, max_depth)` → 返回多跳节点列表
- 策略：BFS 遍历
- 循环检测：通过 `symbol_id` 去重

**涉及文件**：
- `tools/call-chain-tracer.sh`（新增遍历逻辑）

**验收标准**：
- 支持 `--max-depth 2~4`
- 返回结果包含深度信息（`depth: 0, 1, 2, ...`）
- 检测并标记循环引用

**验收锚点**：AC-005, CT-GRG-003（多跳图遍历）, CT-GRG-007（循环引用检测）

**依赖**：MP2.2

**可并行**：否（依赖 MP2.2）

---

#### MP2.5: JSON 输出增强

**描述**：为 JSON 输出新增 CKB 相关字段（source, symbol_id, depth, callers, callees）

**接口/契约**：
- JSON Schema：见 `SPEC-GRG-001` § 3.3
- 新增字段：`candidates[].source`, `candidates[].symbol_id`, `candidates[].depth`, `metadata.ckb_available`

**涉及文件**：
- `tools/graph-rag-context.sh`（修改输出格式）
- `tools/call-chain-tracer.sh`（修改输出格式）

**验收标准**：
- JSON Schema 校验通过
- 向后兼容（旧字段保持不变）
- CKB 可用时输出完整字段，import 降级时部分字段为 null

**验收锚点**：CT-GRG-004（JSON 输出格式）

**依赖**：MP2.3, MP2.4

**可并行**：否（依赖 MP2.3, MP2.4）

---

#### MP2.6: 配置文件更新

**描述**：更新 `.devbooks/config.yaml` 增加 CKB 配置

**接口/契约**：
- 新增字段：`graph_rag.ckb.enabled`, `graph_rag.ckb.fallback_to_import`, `graph_rag.max_depth`
- Schema：见 `SPEC-GRG-001` § 3.2

**涉及文件**：
- `.devbooks/config.yaml`（新增配置节）

**验收标准**：
- 配置文件格式正确
- 注释说明完整
- 向后兼容

**验收锚点**：CT-GRG-006（向后兼容性）

**依赖**：无

**可并行**：是

---

### MP3: 熵度量可视化（P3 - 中优先级）

**目的（Why）**：
- 为熵度量报告增加 Mermaid 图表与 ASCII 仪表盘
- 提升报告可读性与用户体验

**交付物（Deliverables）**：
- `tools/devbooks-entropy-viz.sh`（新建）
- `skills/devbooks-entropy-monitor/SKILL.md`（更新产物格式）
- `.devbooks/config.yaml` 新增 `features.entropy_visualization`
- 测试用例：CT-ENT-001, CT-ENT-002, CT-ENT-003

**影响范围（Files/Modules）**：
- 新建文件：`tools/devbooks-entropy-viz.sh`
- 修改文件：`skills/devbooks-entropy-monitor/SKILL.md`
- 配置文件：`.devbooks/config.yaml`

**验收标准（Acceptance Criteria）**：
- AC-006：熵报告包含 Mermaid 图（≥ 2 个）
- AC-006：熵报告包含 ASCII 仪表盘

**依赖（Dependencies）**：无（独立任务）

**风险（Risks）**：
- R4：熵可视化在某些终端渲染异常 → 提供纯文本 fallback

**可并行**：是（与 MP1, MP2 并行）

---

#### MP3.1: Mermaid 图表生成函数

**描述**：实现 Mermaid 图表生成逻辑

**接口/契约**：
- 函数：`generate_mermaid_trend_chart(data_array)` → 返回 Mermaid 代码块
- 函数：`generate_mermaid_hotspot_chart(hotspot_files)` → 返回 Mermaid 代码块
- 图表规范：见 `SPEC-ENT-001` § 3.2

**涉及文件**：
- `tools/devbooks-entropy-viz.sh`（新建）

**验收标准**：
- 趋势折线图（xychart-beta）生成正确
- 热点文件图（graph TD）生成正确
- 颜色规则符合规范（红/黄/绿）

**验收锚点**：CT-ENT-001（Mermaid 图表生成）

**依赖**：无

**可并行**：是

---

#### MP3.2: ASCII 仪表盘生成函数

**描述**：实现 ASCII 仪表盘生成逻辑

**接口/契约**：
- 函数：`generate_ascii_dashboard(health_score, entropy_metrics)` → 返回 ASCII 仪表盘文本
- 仪表盘规范：见 `SPEC-ENT-001` § 3.3

**涉及文件**：
- `tools/devbooks-entropy-viz.sh`（新建）

**验收标准**：
- 彩色版本（ANSI 颜色码）生成正确
- 纯文本版本（NO_COLOR）生成正确
- 进度条长度固定 40 字符
- 状态图标清晰（✅ ⚠️ 🔴）

**验收锚点**：CT-ENT-002（ASCII 仪表盘生成）

**依赖**：无

**可并行**：是（与 MP3.1 并行）

---

#### MP3.3: 熵报告格式更新

**描述**：更新 `devbooks-entropy-monitor` Skill，调用可视化工具生成报告

**接口/契约**：
- 调用 `devbooks-entropy-viz.sh` 生成可视化内容
- 报告结构：见 `SPEC-ENT-001` § 3.1

**涉及文件**：
- `skills/devbooks-entropy-monitor/SKILL.md`（更新产物格式）

**验收标准**：
- 报告包含 Mermaid 图表章节
- 报告包含 ASCII 仪表盘章节
- 原有文本表格保持不变（向后兼容）

**验收锚点**：AC-006, CT-ENT-003（向后兼容性）

**依赖**：MP3.1, MP3.2

**可并行**：否（依赖 MP3.1, MP3.2）

---

#### MP3.4: 配置文件更新

**描述**：更新 `.devbooks/config.yaml` 增加可视化配置

**接口/契约**：
- 新增字段：`features.entropy_visualization`, `features.entropy_mermaid`, `features.entropy_ascii_dashboard`
- Schema：见 `SPEC-ENT-001` § 3.4

**涉及文件**：
- `.devbooks/config.yaml`（新增配置节）

**验收标准**：
- 配置文件格式正确
- 注释说明完整
- 禁用可视化后报告恢复原版格式

**验收锚点**：CT-ENT-003（向后兼容性）

**依赖**：无

**可并行**：是

---

#### MP3.5: 终端兼容性测试

**描述**：在多个终端环境下测试 ASCII 仪表盘显示效果

**涉及文件**：
- 测试环境：macOS Terminal, iTerm2, Linux gnome-terminal, Windows Terminal, VS Code 终端, SSH 终端

**验收标准**：
- 所有终端显示正常
- 支持 `NO_COLOR` 环境变量
- 无乱码、无换行问题

**验收锚点**：CT-ENT-004（终端兼容性）

**依赖**：MP3.2

**可并行**：否（依赖 MP3.2）

---

### MP4: 配置统一与默认启用（P4 - 中优先级）

**目的（Why）**：
- 统一并简化 `.devbooks/config.yaml` 配置
- 设置最智能的默认值（`embedding.provider: auto`）

**交付物（Deliverables）**：
- `.devbooks/config.yaml`（完整配置示例）
- 配置注释完善

**影响范围（Files/Modules）**：
- 配置文件：`.devbooks/config.yaml`

**验收标准（Acceptance Criteria）**：
- 批准条件 § 1：`embedding.provider` 默认值为 `auto`

**依赖（Dependencies）**：MP1, MP2, MP3（所有配置项依赖）

**风险（Risks）**：无

**可并行**：否（依赖所有配置项）

---

#### MP4.1: 配置分组与注释

**描述**：整理 `.devbooks/config.yaml`，分组清晰，注释完善

**接口/契约**：
- 配置分组：embedding, graph_rag, ckb, features
- 注释要求：每个配置项都有注释说明
- 完整示例：见 `design.md` P4 § 接口变更

**涉及文件**：
- `.devbooks/config.yaml`（整理格式）

**验收标准**：
- 配置分组清晰
- 每个字段都有注释
- 默认值设置合理

**验收锚点**：批准条件 § 1（默认 provider 调整）

**依赖**：MP1.6, MP2.6, MP3.4

**可并行**：否（依赖 MP1.6, MP2.6, MP3.4）

---

### MP5: 意图四分类增强（P5 - 中优先级）

**目的（Why）**：
- 扩展意图识别从二分类升级到四分类
- 支持 debug/refactor/feature/docs 四类场景

**交付物（Deliverables）**：
- `tools/devbooks-common.sh` 新增 `get_intent_type()` 函数
- 测试用例：CT-INT-001, CT-INT-002, CT-INT-003

**影响范围（Files/Modules）**：
- 核心文件：`tools/devbooks-common.sh`
- 调用方：`.claude/hooks/augment-context.sh`, `setup/global-hooks/augment-context-global.sh`, `tools/graph-rag-context.sh`, `tools/bug-locator.sh`, `tools/call-chain-tracer.sh`

**验收标准（Acceptance Criteria）**：
- AC-007：意图四分类生效
- 准确率 ≥ 80%（20 个预设查询）

**依赖（Dependencies）**：无（独立任务）

**风险（Risks）**：
- 调用方兼容性风险 → 保持向后兼容，新增函数不改变原有函数

**可并行**：是（与 MP1, MP2, MP3 并行）

---

#### MP5.1: `get_intent_type()` 函数实现

**描述**：实现四分类意图识别函数

**接口/契约**：
- 函数签名：`get_intent_type(query)` → 返回 `debug | refactor | feature | docs`
- 关键词规则：见 `SPEC-INT-001` § REQ-INT-003
- 实现示例：见 `SPEC-INT-001` § 3.2

**涉及文件**：
- `tools/devbooks-common.sh`（新增函数）

**验收标准**：
- 四分类逻辑正确
- 优先级匹配（debug > refactor > docs > feature）
- 大小写不敏感

**验收锚点**：AC-007, CT-INT-001（四分类基础功能）

**依赖**：无

**可并行**：是

---

#### MP5.2: `is_code_intent()` 重构

**描述**：重构原有函数，内部调用 `get_intent_type()`

**接口/契约**：
- 函数签名保持不变：`is_code_intent(query)` → 返回 0 或 1
- 实现：调用 `get_intent_type()` 并判断 `!= "docs"`

**涉及文件**：
- `tools/devbooks-common.sh`（修改实现）

**验收标准**：
- 向后兼容（行为与原版一致）
- 所有现有调用方测试通过

**验收锚点**：CT-INT-002（向后兼容性）

**依赖**：MP5.1

**可并行**：否（依赖 MP5.1）

---

#### MP5.3: 调用方兼容性验证

**描述**：验证 6 个现有调用方的兼容性

**涉及文件**：
- `.claude/hooks/augment-context.sh`
- `setup/global-hooks/augment-context-global.sh`
- `tools/graph-rag-context.sh`
- `tools/bug-locator.sh`
- `tools/call-chain-tracer.sh`

**验收标准**：
- 所有调用方回归测试通过
- 行为与原版一致

**验收锚点**：CT-INT-004（调用方影响验证）

**依赖**：MP5.2

**可并行**：否（依赖 MP5.2）

---

## 【临时计划区】(Temporary Plan Area)

> 预留模板（用于计划外高优任务，当前为空）

**触发条件**：测试失败、生产问题、紧急需求

**约束**：临时计划不得破坏主线计划的总体架构约束

---

<!-- 计划细化区：在计划区域之后 -->

## 【计划细化区】

### Scope & Non-goals

#### In Scope

1. **P1: 本地 Embedding**
   - Ollama 集成（nomic-embed-text 或 mxbai-embed-large）
   - 三级降级机制（Ollama → OpenAI API → 关键词搜索）
   - CLI 参数与配置扩展
   - 向后兼容

2. **P2: CKB 真实图遍历**
   - CKB MCP API 集成（searchSymbols, getCallGraph, findReferences）
   - 多跳图遍历（2-4 跳，BFS 策略）
   - import 解析作为降级
   - 循环引用检测

3. **P3: 熵度量可视化**
   - Mermaid 图表（趋势折线图 + 热点文件图）
   - ASCII 仪表盘（彩色 + 纯文本）
   - 终端兼容性（macOS, Linux, Windows）

4. **P4: 配置统一**
   - 默认 provider 调整为 `auto`
   - 配置分组清晰（embedding, graph_rag, ckb, features）
   - 注释完善

5. **P5: 意图四分类**
   - 新增 `get_intent_type()` 函数
   - 向后兼容 `is_code_intent()`
   - 6 个调用方兼容性验证

#### Non-goals

- ❌ 数据流分析（PDG）
- ❌ 40万+文件规模支持
- ❌ 200ms 延迟优化
- ❌ 架构漂移检测
- ❌ 动态 Token 预算（原 P6，已裁决排除）
- ❌ Web 仪表盘（熵可视化）

---

### Architecture Delta

#### 新增组件

| 组件 | 路径 | 功能 | 调用者 |
|------|------|------|--------|
| `devbooks-entropy-viz.sh` | `tools/devbooks-entropy-viz.sh` | 生成 Mermaid 图表 + ASCII 仪表盘 | `skills/devbooks-entropy-monitor` |

#### 修改的组件

| 组件 | 原功能 | 新增功能 | 影响范围 |
|------|--------|---------|---------|
| `devbooks-embedding.sh` | 仅支持 OpenAI API | 支持 Ollama + 三级降级 | Embedding 所有调用方 |
| `graph-rag-context.sh` | 仅 import 解析 | 优先使用 CKB API + import 降级 | Graph-RAG 所有调用方 |
| `call-chain-tracer.sh` | 单跳调用链 | 支持 2-4 跳图遍历 | 调用链分析 |
| `devbooks-common.sh` | 二分类意图识别 | 四分类意图识别（新增函数） | 6 个调用方 |
| `devbooks-entropy-monitor` | 纯文本报告 | 增加 Mermaid 图表 + ASCII 仪表盘 | 熵度量所有用户 |

#### 依赖方向变化

```
调用层（Hooks）
    │
    ├──► devbooks-embedding.sh ──┬──► Ollama（L1，优先）
    │                             ├──► OpenAI API（L2，降级）
    │                             └──► 关键词搜索（L3，兜底）
    │
    ├──► graph-rag-context.sh ──┬──► CKB MCP API（优先）
    │         │                  └──► import 解析（降级）
    │         └──► call-chain-tracer.sh ──► CKB MCP API
    │
    └──► devbooks-common.sh ──► 四分类（debug/refactor/feature/docs）

skills/devbooks-entropy-monitor
    │
    └──► devbooks-entropy-viz.sh ──┬──► Mermaid 代码生成
                                     └──► ASCII 仪表盘渲染
```

---

### Data Contracts

#### Embedding JSON 输出契约

**新增字段**（向后兼容）：
- `source`: `"ollama"` | `"openai"` | `"keyword"`
- `model`: 使用的模型名称（如 `"nomic-embed-text"`）
- `metadata.provider`: 实际使用的 provider
- `metadata.latency_ms`: 延迟（毫秒）

**Schema 版本**：1.0（保持不变）

**兼容性**：旧字段保持不变，新字段为新增

**契约测试**：CT-EMB-001

---

#### Graph-RAG JSON 输出契约

**新增字段**（向后兼容）：
- `candidates[].source`: `"ckb"` | `"import"`
- `candidates[].symbol_id`: 符号稳定 ID（仅 CKB）
- `candidates[].depth`: 图遍历深度
- `candidates[].callers`: 调用者列表（仅 CKB）
- `candidates[].callees`: 被调用者列表（仅 CKB）
- `metadata.ckb_available`: CKB 是否可用
- `metadata.graph_depth`: 实际遍历深度

**Schema 版本**：1.0（保持不变）

**兼容性**：旧字段保持不变，新字段为新增（import 降级时部分字段为 null）

**契约测试**：CT-GRG-004

---

#### 配置文件契约

**新增字段**（向后兼容）：

```yaml
# Embedding 配置
embedding:
  provider: auto  # 新增
  ollama:         # 新增节
    model: nomic-embed-text
    endpoint: http://localhost:11434
    timeout: 30

# Graph-RAG 配置
graph_rag:
  ckb:            # 新增节
    enabled: true
    fallback_to_import: true
    timeout: 5
  max_depth: 2    # 新增

# 功能特性配置
features:
  entropy_visualization: true  # 新增
```

**兼容性**：旧配置格式仍可读取，新字段为可选

**契约测试**：CT-EMB-003, CT-GRG-006, CT-ENT-003

---

### Milestones

#### Milestone 1: 本地 Embedding 完成（MP1）

**验收口径**：
- AC-001, AC-002, AC-003 全部通过
- CT-EMB-001, CT-EMB-002, CT-EMB-003 全部通过
- 文档更新完成（批准条件 § 3）

**预计完成**：主线计划中 MP1.1 ~ MP1.7 全部完成

---

#### Milestone 2: CKB 图遍历完成（MP2）

**验收口径**：
- AC-004, AC-005 全部通过
- CT-GRG-001, CT-GRG-002, CT-GRG-003, CT-GRG-004 全部通过

**预计完成**：主线计划中 MP2.1 ~ MP2.6 全部完成

---

#### Milestone 3: 熵可视化完成（MP3）

**验收口径**：
- AC-006 通过
- CT-ENT-001, CT-ENT-002, CT-ENT-003, CT-ENT-004 全部通过

**预计完成**：主线计划中 MP3.1 ~ MP3.5 全部完成

---

#### Milestone 4: 意图四分类完成（MP5）

**验收口径**：
- AC-007 通过
- CT-INT-001, CT-INT-002, CT-INT-003, CT-INT-004, CT-INT-005 全部通过

**预计完成**：主线计划中 MP5.1 ~ MP5.3 全部完成

---

#### Milestone 5: 全部完成（MP1 ~ MP5）

**验收口径**：
- 所有 AC 全部通过
- 所有契约测试全部通过
- 所有批准条件满足

**预计完成**：主线计划全部完成 + 配置统一（MP4）

---

### Work Breakdown

#### PR 切分建议

| PR | 任务包 | 可并行 | 预计行数 | 依赖 |
|----|--------|--------|---------|------|
| **PR-1** | MP1.1, MP1.2, MP1.5, MP1.6 | 部分并行 | ~150 行 | 无 |
| **PR-2** | MP1.3, MP1.4 | 串行 | ~100 行 | PR-1 |
| **PR-3** | MP1.7（文档） | 独立 | ~50 行 | PR-2 |
| **PR-4** | MP2.1, MP2.2, MP2.6 | 部分并行 | ~180 行 | 无 |
| **PR-5** | MP2.3, MP2.4, MP2.5 | 串行 | ~150 行 | PR-4 |
| **PR-6** | MP3.1, MP3.2, MP3.4 | 部分并行 | ~120 行 | 无 |
| **PR-7** | MP3.3, MP3.5 | 串行 | ~50 行 | PR-6 |
| **PR-8** | MP5.1, MP5.2, MP5.3 | 串行 | ~80 行 | 无 |
| **PR-9** | MP4.1（配置统一） | 独立 | ~30 行 | PR-1 ~ PR-8 |

**总计**：9 个 PR，约 910 行代码（不含测试）

**并行策略**：
- PR-1, PR-4, PR-6, PR-8 可并行开发
- PR-2, PR-5, PR-7 依赖各自的前置 PR
- PR-3, PR-9 为收尾任务

---

### Deprecation & Cleanup

#### 无弃用项

本次变更为纯增量变更，无弃用或删除的 API/配置/文件。

**兼容性保证**：
- 所有原有 CLI 参数保持不变
- 所有原有配置字段保持不变
- 所有原有函数保持不变
- 所有原有 JSON 输出字段保持不变

---

### Dependency Policy

#### One Version Rule

- Ollama 模型版本：`nomic-embed-text:latest` 或 `mxbai-embed-large:latest`
- 不锁定特定版本，使用最新稳定版

#### Strict Deps

- CKB MCP：要求 `>= 1.0`
- Ollama：要求 `>= 0.1.0`

#### Lock 文件对齐

- 无 lock 文件（Bash 项目）

---

### Quality Gates

#### Lint

- **工具**：shellcheck
- **阈值**：无 error，warning ≤ 5
- **执行**：每次 commit 前

#### 复杂度

- **工具**：bash-complexity-analyzer（自定义）
- **阈值**：单函数圈复杂度 ≤ 15
- **执行**：PR 合并前

#### 重复度

- **工具**：人工检查（Bash 无成熟工具）
- **阈值**：重复代码块 ≤ 10 行
- **执行**：Code Review

#### 依赖规则

- **约束**：
  - Hooks 不得直接依赖 CKB MCP（通过 tools/ 封装）
  - tools/ 不得直接依赖 skills/（单向依赖）
- **验证**：架构适配测试

---

### Guardrail Conflicts

#### 代理指标风险评估

**风险信号**：无

**本次变更不涉及以下代理指标驱动的要求**：
- ❌ 行数限制
- ❌ 文件数限制
- ❌ 机械拆分
- ❌ 命名格式硬性要求

**质量优先指标**（已覆盖）：
- ✅ 复杂度控制（单函数 ≤ 15）
- ✅ 耦合度控制（单向依赖）
- ✅ 测试质量（契约测试覆盖）
- ✅ 依赖方向（Hooks → tools/ → external）

---

### Observability

#### 指标

| 指标 | 说明 | 目标值 | 采集方式 |
|------|------|--------|---------|
| Embedding 延迟（P95） | Ollama/API 响应时间 | < 3s | 日志分析 |
| Graph-RAG 延迟（P95） | CKB API 响应时间 | < 3s | 日志分析 |
| 降级频率 | Ollama/CKB 降级次数 | < 5% | 日志统计 |
| 意图分类准确率 | 四分类准确率 | ≥ 80% | 预设查询测试 |

#### 日志落点

- Embedding 日志：`/tmp/devbooks-embedding.log`
- Graph-RAG 日志：`/tmp/devbooks-graph-rag.log`
- 熵度量日志：`openspec/specs/_meta/entropy/entropy.log`

#### 审计

- 无审计要求（开发工具，无敏感操作）

---

### Rollout & Rollback

#### 灰度策略

- 无灰度（开发工具，直接发布）

#### 开关

- **Embedding provider**：配置项 `embedding.provider`（auto/ollama/openai/keyword）
- **CKB 启用**：配置项 `graph_rag.ckb.enabled`（true/false）
- **熵可视化**：配置项 `features.entropy_visualization`（true/false）

#### 回滚

##### 配置回滚

1. **禁用 Ollama**：
   ```yaml
   embedding:
     provider: openai  # 强制使用 API
   ```

2. **禁用 CKB**：
   ```yaml
   graph_rag:
     ckb:
       enabled: false  # 强制使用 import 解析
   ```

3. **禁用可视化**：
   ```yaml
   features:
     entropy_visualization: false
   ```

##### 代码回滚

- 所有新功能封装在独立函数/文件中
- 通过 `git revert <commit>` 可完全回滚
- 回滚后自动恢复到原有行为

---

### Risks & Edge Cases

#### Risk Matrix

| 风险 ID | 风险描述 | 概率 | 影响 | 缓解措施 | 责任人 |
|--------|---------|-----|-----|---------|--------|
| **R1** | Ollama 未安装导致 Embedding 不可用 | 高 | 中 | 三级降级：Ollama → API → 关键词 | Coder |
| **R2** | CKB MCP 不可用导致图遍历失败 | 中 | 中 | 保留 import 解析作为降级 | Coder |
| **R3** | 本地模型质量不如 API | 低 | 低 | 文档说明差异（4-8%），用户可选 | Coder |
| **R4** | 熵可视化在某些终端渲染异常 | 中 | 低 | 提供纯文本 fallback | Coder |
| **R5** | 热点文件 `augment-context.sh` 改动引入 Bug | 中 | 高 | 增加 BATS 测试覆盖（批准条件） | Test Owner |

#### Edge Cases

1. **空字符串查询**：
   - 场景：用户输入空字符串
   - 处理：默认返回 `feature` 类别

2. **Ollama 模型下载中**：
   - 场景：用户首次使用，模型正在下载
   - 处理：等待下载完成或提示用户并降级

3. **CKB 索引缺失**：
   - 场景：代码库未建立 SCIP 索引
   - 处理：自动降级到 import 解析，日志提示用户运行 `devbooks-index-bootstrap`

4. **循环引用检测失败**：
   - 场景：复杂循环调用导致检测失败
   - 处理：限制遍历深度，避免无限递归

5. **终端不支持 ANSI 颜色**：
   - 场景：古老终端不支持彩色
   - 处理：检测 `NO_COLOR` 环境变量或 `$TERM`，降级到纯文本

---

### Open Questions

| 问题 ID | 问题 | 状态 | 决策者 | 预计决策时间 |
|--------|------|------|--------|-------------|
| **Q1** | Ollama 模型选择：`nomic-embed-text` vs `mxbai-embed-large`？ | Open | Test Owner | 实测对比后决策 |
| **Q2** | CKB API 可用性检测超时时间设置为 1s 是否合理？ | Open | Planner | 根据实测调整 |
| **Q3** | Mermaid 图表在不同 Markdown 渲染器的兼容性？ | Open | Test Owner | 测试验证后确认 |

**决策原则**：
- Q1：优先选择速度快的模型（如果质量差异 < 5%）
- Q2：如果 1s 超时频繁，可调整为 2s
- Q3：优先保证 GitHub/GitLab 兼容，其他渲染器为 nice-to-have

---

## 【断点区】(Context Switch Breakpoint Area)

> 用于记录主线/临时计划切换时的上下文恢复点

**当前状态**：无断点（初始状态）

**切换记录模板**：
```markdown
### Breakpoint-001: <日期>

**原因**：<切换原因，如紧急 Bug 修复>
**暂停位置**：<暂停的任务包，如 MP1.3>
**暂停时状态**：<已完成/进行中/未开始>
**恢复清单**：
- [ ] 恢复环境（如重新拉取分支）
- [ ] 阅读暂停位置的上下文
- [ ] 继续执行

**临时计划**：
- TP1: <临时任务描述>
- TP2: <临时任务描述>

**回归主线时间**：<预计时间>
```

---

## Design Backport Candidates（需回写设计）

> 编码计划中发现的设计未明确的新约束/新概念，需回写到 `design.md`

**当前状态**：无需回写（设计文档已充分明确）

**候选变更**（若在实施中发现）：
- 若 Ollama 模型下载时间超过 10s，需在设计中说明"首次使用需等待模型下载"
- 若 CKB API 超时时间 1s 不够，需在设计中调整为 2s 并说明原因

---

## Algorithm Spec（复杂算法规范）

### Algorithm-1: 三级降级逻辑

**Inputs**：
- `config`: 配置对象（`embedding.provider`, `embedding.ollama.*`, `embedding.openai.*`）
- `query`: 用户查询字符串

**Outputs**：
- `provider`: 实际使用的 provider（`ollama` | `openai` | `keyword`）
- `result`: 向量结果或文件列表

**Invariants**（不变量）**：
- 至少返回一个 provider（关键词搜索始终可用）
- 降级不可逆（不会从 L3 升级到 L2）

**Failure Modes**（失败模式）**：
- 所有 provider 失败：返回空结果，日志记录错误

**核心流程**（伪代码）**：

```
FUNCTION select_provider(config, query):
  IF config.provider == "auto" THEN
    // 自动检测
    IF detect_ollama_available() THEN
      RETURN "ollama"
    ELSE IF detect_openai_api_available() THEN
      RETURN "openai"
    ELSE
      RETURN "keyword"
    END IF
  ELSE
    // 使用指定 provider
    RETURN config.provider
  END IF
END FUNCTION

FUNCTION embed_with_fallback(config, query):
  provider = select_provider(config, query)

  CASE provider OF
    "ollama":
      TRY
        result = embed_with_ollama(query)
        RETURN result
      CATCH timeout OR connection_error THEN
        LOG "Ollama 不可用，降级到 OpenAI API"
        provider = "openai"
        FALLTHROUGH
      END TRY

    "openai":
      TRY
        result = embed_with_openai(query)
        RETURN result
      CATCH api_error OR no_api_key THEN
        LOG "OpenAI API 不可用，降级到关键词搜索"
        provider = "keyword"
        FALLTHROUGH
      END TRY

    "keyword":
      result = search_with_ripgrep(query)
      RETURN result
  END CASE
END FUNCTION
```

**复杂度与资源上限**：
- **Time**：O(1)（单次检测 + 单次调用）
- **Space**：O(n)（n 为返回结果数量）
- **IO**：最多 3 次网络请求（检测 + Ollama + OpenAI）
- **预算**：总延迟 < 10s（3s Ollama + 5s API + 2s 关键词）

**边界条件与测试用例要点**：
1. Ollama 可用 → 返回 Ollama 结果
2. Ollama 不可用 + API 可用 → 返回 API 结果
3. 所有不可用 → 返回关键词搜索结果
4. 空查询 → 返回空结果
5. 超时场景 → 自动降级

---

### Algorithm-2: 多跳图遍历（BFS）

**Inputs**：
- `root_symbol_id`: 根符号 ID
- `max_depth`: 最大遍历深度（2-4）
- `direction`: 遍历方向（`callers` | `callees` | `both`）

**Outputs**：
- `nodes`: 多跳节点列表（包含 `symbol_id`, `depth`, `callers`, `callees`）

**Invariants**（不变量）**：
- 每个节点只访问一次（通过 `symbol_id` 去重）
- 深度单调递增（不会出现深度回退）

**Failure Modes**（失败模式）**：
- CKB API 超时：返回已遍历节点
- 循环引用：检测并标记，避免无限递归

**核心流程**（伪代码）**：

```
FUNCTION traverse_graph(root_symbol_id, max_depth, direction):
  visited = SET()  // 已访问的符号 ID
  queue = QUEUE()  // BFS 队列
  result = LIST()  // 结果列表

  // 初始化
  queue.ENQUEUE({symbol_id: root_symbol_id, depth: 0})

  WHILE NOT queue.EMPTY() DO
    node = queue.DEQUEUE()

    // 去重
    IF node.symbol_id IN visited THEN
      CONTINUE
    END IF

    visited.ADD(node.symbol_id)

    // 超过最大深度
    IF node.depth > max_depth THEN
      CONTINUE
    END IF

    // 获取调用关系
    IF direction IN ["callers", "both"] THEN
      callers = ckb_get_callers(node.symbol_id)
      FOR EACH caller IN callers DO
        IF caller.symbol_id NOT IN visited THEN
          queue.ENQUEUE({symbol_id: caller.symbol_id, depth: node.depth + 1})
        END IF
      END FOR
    END IF

    IF direction IN ["callees", "both"] THEN
      callees = ckb_get_callees(node.symbol_id)
      FOR EACH callee IN callees DO
        IF callee.symbol_id NOT IN visited THEN
          queue.ENQUEUE({symbol_id: callee.symbol_id, depth: node.depth + 1})
        END IF
      END FOR
    END IF

    // 记录结果
    result.ADD(node)
  END WHILE

  RETURN result
END FUNCTION
```

**复杂度与资源上限**：
- **Time**：O(N + E)（N 为节点数，E 为边数）
- **Space**：O(N)（visited 集合 + 队列）
- **IO**：O(N)（每个节点调用一次 CKB API）
- **预算**：
  - 节点数上限：200（避免爆炸）
  - 总延迟：< 10s（5s/100 nodes）

**边界条件与测试用例要点**：
1. 单跳遍历（depth=1）→ 返回直接调用关系
2. 多跳遍历（depth=3）→ 返回 3 跳内所有节点
3. 循环引用（A → B → A）→ 检测并去重，避免无限递归
4. 节点数爆炸（> 200）→ 截断并日志警告
5. CKB API 超时 → 返回已遍历节点，标记不完整

---

### Algorithm-3: 意图四分类匹配

**Inputs**：
- `query`: 用户查询字符串

**Outputs**：
- `intent`: 意图类型（`debug` | `refactor` | `feature` | `docs`）

**Invariants**（不变量）**：
- 必然返回四类之一
- 优先级固定（debug > refactor > docs > feature）

**Failure Modes**（失败模式）**：
- 无（关键词匹配无失败场景）

**核心流程**（伪代码）**：

```
FUNCTION get_intent_type(query):
  // 处理空字符串
  IF query IS EMPTY THEN
    RETURN "feature"
  END IF

  // 转换为小写（大小写不敏感）
  query_lower = TO_LOWERCASE(query)

  // 优先级 1：调试类
  IF MATCH(query_lower, "debug|fix|bug|error|issue|problem|crash|fail") THEN
    RETURN "debug"
  END IF

  // 优先级 2：重构类
  IF MATCH(query_lower, "refactor|optimize|improve|performance|clean|simplify") THEN
    RETURN "refactor"
  END IF

  // 优先级 3：文档类
  IF MATCH(query_lower, "doc|comment|readme|explain|example|guide") THEN
    RETURN "docs"
  END IF

  // 优先级 4：默认为新功能类
  RETURN "feature"
END FUNCTION
```

**复杂度与资源上限**：
- **Time**：O(m)（m 为查询字符串长度）
- **Space**：O(1)（无额外空间）
- **IO**：无

**边界条件与测试用例要点**：
1. 空字符串 → 返回 `feature`
2. 单关键词匹配 → 返回对应类别
3. 多关键词混合 → 返回优先级最高的类别
4. 大小写混合 → 不敏感匹配
5. 特殊字符 → 返回 `feature`

---

## 附录：测试覆盖清单

> 所有契约测试与验收锚点的完整清单

### Embedding 测试（P1）

| 测试 ID | 测试名称 | 类型 | 优先级 | 验收锚点 |
|--------|---------|------|--------|----------|
| CT-EMB-001 | Ollama Provider 基础功能 | 集成测试 | P0 | AC-001 |
| CT-EMB-002 | 三级降级机制 | 集成测试 | P0 | AC-002, AC-003 |
| CT-EMB-003 | 向后兼容性 | 回归测试 | P0 | AC-008 |
| CT-EMB-004 | 性能基准测试 | 性能测试 | P1 | - |
| CT-EMB-005 | 错误处理 | 异常测试 | P1 | - |

### Graph-RAG 测试（P2）

| 测试 ID | 测试名称 | 类型 | 优先级 | 验收锚点 |
|--------|---------|------|--------|----------|
| CT-GRG-001 | CKB API 基础功能 | 集成测试 | P0 | AC-004 |
| CT-GRG-002 | 降级机制 | 集成测试 | P0 | AC-004 |
| CT-GRG-003 | 多跳图遍历 | 功能测试 | P1 | AC-005 |
| CT-GRG-004 | JSON 输出格式 | 契约测试 | P0 | AC-004 |
| CT-GRG-005 | 性能基准测试 | 性能测试 | P1 | - |
| CT-GRG-006 | 向后兼容性 | 回归测试 | P0 | AC-008 |
| CT-GRG-007 | 循环引用检测 | 边界测试 | P1 | AC-005 |

### 熵可视化测试（P3）

| 测试 ID | 测试名称 | 类型 | 优先级 | 验收锚点 |
|--------|---------|------|--------|----------|
| CT-ENT-001 | Mermaid 图表生成 | 功能测试 | P0 | AC-006 |
| CT-ENT-002 | ASCII 仪表盘生成 | 功能测试 | P0 | AC-006 |
| CT-ENT-003 | 向后兼容性 | 回归测试 | P0 | AC-008 |
| CT-ENT-004 | 终端兼容性 | 兼容性测试 | P1 | - |
| CT-ENT-005 | 可视化测试覆盖 | 单元测试 + 集成测试 | P1 | 批准条件 § 2 |

### 意图分类测试（P5）

| 测试 ID | 测试名称 | 类型 | 优先级 | 验收锚点 |
|--------|---------|------|--------|----------|
| CT-INT-001 | 四分类基础功能 | 单元测试 | P0 | AC-007 |
| CT-INT-002 | 向后兼容性 | 回归测试 | P0 | AC-008 |
| CT-INT-003 | 关键词规则 | 功能测试 | P1 | AC-007 |
| CT-INT-004 | 调用方影响验证 | 集成测试 | P1 | - |
| CT-INT-005 | 准确率测试 | 验收测试 | P1 | AC-007 |
| CT-INT-006 | 边界测试 | 边界测试 | P2 | - |

**总计**：22 个契约测试用例

**批准条件测试要求**：
- ✅ 熵可视化测试用例 ≥ 3（CT-ENT-001, CT-ENT-002, CT-ENT-003）
- ✅ 意图分类测试用例 ≥ 4（CT-INT-001, CT-INT-002, CT-INT-003, CT-INT-004）
- ✅ 为 `augment-context.sh` 增加 BATS 测试覆盖（在 Test Owner 阶段完成）

---

**编码计划完成时间**：2026-01-09
**维护者**：Planner
**下一步**：等待 Test Owner 产出 `verification.md` + `tests/**`
