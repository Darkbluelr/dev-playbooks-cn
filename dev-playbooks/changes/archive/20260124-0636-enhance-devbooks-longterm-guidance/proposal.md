# 提案：20260124-0636-enhance-devbooks-longterm-guidance

## Why（为什么要改）

- 问题：
  - DevBooks 说明偏向短期落地叙事，长期维护与可演进性关注不足，容易导向短视决策。
  - 部分文档将 DevBooks 描述为 MCP 工具，定位模糊，用户预期与使用路径混乱。
  - Skills 的渐进披露标准不一致，不同 Skill 的引导节奏与深度差异明显。
  - SKILL.md 的 MCP 章节绑定具体 MCP 名称，削弱替换与组合能力。
  - 缺少“人类建议校准”提示词机制，AI 在缺少人类偏好时缺少校准入口。
  - 文档理由表述存在固定目的-结论句式，约束与取舍难以被清晰评估。

- 目标：
  - 建立长期视野与反短视的明确原则与提示入口，强化可演进性。
  - 明确 DevBooks 定位为协议与工作流集合，不等同 MCP 工具。
  - 引入“人类建议校准”提示词机制，定义触发条件与输出格式。
  - 统一 Skills 的渐进披露规范与落地位置，减少使用断层。
  - 将 SKILL.md 的 MCP 章节改写为“推荐 MCP 能力类型”，保留可替换性。
  - 将文档理由表达调整为“约束-取舍-影响”格式。

## 参考资料1痛点映射

来源：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/参考资料1.md`。
范围说明：本节仅映射 DevBooks 定位内可通过文本规范与提示词机制落地的改进；凡未进入本次 Minimal Diff 的锚点，均标注为“既有机制/范围外（不新增 AC、不承诺本次落盘）”。

### 定位与痛点对应

- DevBooks 定位：AI 协作工作流 + 协议 + 文本规范 + 少量自检脚本；非 MCP 工具；MCP 作为可选生态集成点。
- 可靠性税：以证据优先与自检脚本入口降低信任成本，定位强调可验证流程与最小证据链。
- 对齐税：以协议化文档结构与统一术语降低提示词反复成本，定位强调流程与文本规范。
- 上下文脆弱：以渐进披露结构降低信息遗漏风险，定位强调结构化文本与关键信息位置。
- 安全倒退/供应链风险：仅通过文本规范与提示词机制提示依赖来源与风险边界，不引入执行工具。
- 理解债务：强调变更包追溯与验收锚点的可回溯性。
- 合规/影子AI/数据泄露：仅通过文本规范与提示词机制提示合规边界与人工确认，不引入执行工具。

### 主体维度（Subject）

- 痛点：认知债务、警觉性递减、谄媚效应 → 改进：流程强调角色隔离与证据优先，提示“人类建议校准”作为纠偏入口 → 预期可验证锚点：`dev-playbooks/specs/quality-gates/spec.md`（既有机制/范围外）、`skills/devbooks-delivery-workflow/scripts/change-check.sh`（既有机制/范围外）、`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff）
- 痛点：可靠性税导致“使用但不信任” → 改进：流程约束由 Test Owner 与 Reviewer 分工验证，文本规范要求 Decision Log 与验收锚点 → 预期可验证锚点：`dev-playbooks/specs/role-handoff/spec.md`（既有机制/范围外）、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md`（本次变更产物）

### 交互维度（Interaction）

- 痛点：对齐税（Prompt Engineering Tax） → 改进：结构化提案/设计/规格模板，减少反复改写，文本规范统一格式 → 预期可验证锚点：`dev-playbooks/project.md`（既有机制/范围外）、`dev-playbooks/specs/spec.md`（既有机制/范围外）、`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff）
- 痛点：上下文脆弱与“迷失中间” → 改进：协议发现与统一术语表，渐进披露结构强化关键信息位置 → 预期可验证锚点：`dev-playbooks/specs/protocol-discovery/spec.md`（既有机制/范围外）、`dev-playbooks/specs/_meta/glossary.md`（本次 Minimal Diff）、`dev-playbooks/specs/context-detection/spec.md`（既有机制/范围外）
- 痛点：时间错位与知识截断 → 改进：文档与规格作为当前真理源，明确变更包来源与版本记录 → 预期可验证锚点：`dev-playbooks/specs/_meta/docs-maintenance.md`（既有机制/范围外）、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md`（本次变更产物）

### 客体维度（Object）

- 痛点：代码重复、重构衰退、面条代码 → 改进：设计先行与规格驱动，结构强调变更包边界与 AC 追溯，文本规范要求验收标准清晰 → 预期可验证锚点：`dev-playbooks/specs/architecture/fitness-rules.md`（既有机制/范围外）、`dev-playbooks/specs/spec.md`（既有机制/范围外）、`dev-playbooks/specs/quality-gates/spec.md`（既有机制/范围外）
- 痛点：安全倒退、幻觉包与供应链安全 → 改进：对外契约与文本规范提示依赖来源、授权与风险边界，必要时触发“人类建议校准”，不引入执行工具 → 预期可验证锚点：`dev-playbooks/specs/script-contracts/spec.md`（既有机制/范围外）、`dev-playbooks/specs/mcp/spec.md`（本次 Minimal Diff）、`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff）

### 演化维度（Evolution）

- 痛点：理解债务与维护悬崖 → 改进：变更包追溯、Decision Log、验收锚点与文档一致性检查 → 预期可验证锚点：`dev-playbooks/specs/docs-consistency-core/spec.md`（既有机制/范围外）、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md`（本次变更产物）
- 痛点：文化异化与唯速度论 → 改进：长期视野/反短视提示与质量优先原则 → 预期可验证锚点：`README.md`（本次 Minimal Diff）、`docs/使用指南.md`（本次 Minimal Diff）、`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff）
- 痛点：法律与合规风险、影子AI/数据泄露 → 改进：提示词机制要求声明合规边界、授权来源与责任归属，必要时触发“人类建议校准”，不引入执行工具 → 预期可验证锚点：`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff）、`dev-playbooks/specs/_meta/glossary.md`（本次 Minimal Diff）

### 痛点 → 改进 → AC/验证锚点

| 痛点 | 改进（DevBooks 范围内） | AC/验证锚点 |
|---|---|---|
| 定位混淆（DevBooks 定位说明） | 文本规范统一定位声明，流程中强调工作流+协议+文本规范+自检脚本，MCP 仅作为可选集成点 | AC-101；锚点：`README.md`，`docs/使用指南.md`，`docs/Skill详解.md` |
| 认知债务、警觉性递减、谄媚效应 | “长期视野/反短视”原则 + “人类建议校准”提示词作为纠偏入口 | AC-102/AC-103；锚点：`dev-playbooks/specs/shared-methodology/spec.md`，`dev-playbooks/specs/_meta/glossary.md`（本次 Minimal Diff）；`skills/devbooks-delivery-workflow/scripts/change-check.sh`（既有机制/范围外） |
| 可靠性税导致“使用但不信任” | 强化证据优先与自检脚本入口提示，明确验收锚点 | AC-102；锚点：`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff）；`skills/devbooks-delivery-workflow/scripts/change-check.sh`（既有机制/范围外） |
| 对齐税（Prompt Engineering Tax） | 渐进披露模板与“约束-取舍-影响”三段式，减少反复提示成本 | AC-104/AC-106；锚点：`skills/**/SKILL.md`（本次 Minimal Diff 已逐项列出），`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff） |
| 上下文脆弱与“迷失中间” | 渐进披露层级强化关键信息位置 | AC-104；锚点：`skills/**/SKILL.md`（本次 Minimal Diff 已逐项列出） |
| 时间错位与知识截断 | 本次仅保留定位与提示词说明，不新增版本治理机制 | 既有机制/范围外（不新增 AC、不承诺本次落盘）；锚点：`dev-playbooks/specs/_meta/docs-maintenance.md`（既有机制/范围外） |
| 代码重复、重构衰退、面条代码 | 设计先行与结构约束属既有机制，本次不新增约束条款 | 既有机制/范围外（不新增 AC、不承诺本次落盘）；锚点：`dev-playbooks/specs/architecture/fitness-rules.md`（既有机制/范围外）、`dev-playbooks/specs/spec.md`（既有机制/范围外）、`dev-playbooks/specs/quality-gates/spec.md`（既有机制/范围外） |
| 安全倒退、幻觉包与供应链安全 | 仅以文本规范提示依赖来源/授权/风险边界，必要时触发“人类建议校准”，不引入执行工具 | AC-103/AC-106；锚点：`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff），`dev-playbooks/specs/_meta/glossary.md`（本次 Minimal Diff）；`dev-playbooks/specs/script-contracts/spec.md`（既有机制/范围外） |
| 理解债务与维护悬崖 | 文档一致性与追溯属既有机制，本次不新增规则 | 既有机制/范围外（不新增 AC、不承诺本次落盘）；锚点：`dev-playbooks/specs/docs-consistency-core/spec.md`（既有机制/范围外） |
| 文化异化与唯速度论 | “长期视野/反短视”提示与质量优先原则 | AC-102；锚点：`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff），`README.md`（本次 Minimal Diff），`docs/使用指南.md`（本次 Minimal Diff） |
| 法律与合规风险、影子AI/数据泄露 | 合规边界/授权来源/责任归属通过提示词机制显式化，必要时触发“人类建议校准”，不引入执行工具 | AC-103/AC-106；锚点：`dev-playbooks/specs/shared-methodology/spec.md`（本次 Minimal Diff），`dev-playbooks/specs/_meta/glossary.md`（本次 Minimal Diff） |

## What Changes（要改什么）

- 范围内：
  - 更新 `README.md` 与对外说明，补充“长期视野/反短视”指引与检查清单，澄清 DevBooks 定位为协议与工作流集合。
  - 在 `dev-playbooks/specs/shared-methodology/spec.md` 增补“人类建议校准”提示词机制，明确触发条件、期望输出与责任边界。
  - 检查并优化 Skills 的渐进披露描述，统一段落结构与层级提示，并同步 `docs/Skill详解.md` 的说明。
  - 将各 SKILL.md 的 MCP 章节改写为“推荐 MCP 能力类型”，移除具体 MCP 名称绑定。
  - 明确能力类型清单与命名规范，在 `dev-playbooks/docs/推荐MCP.md` 提供“能力类型→常见实现对照表”，并在 `README.md` 与 `docs/使用指南.md` 提供链接与摘要。
  - 清理文档理由表述，统一采用“约束-取舍-影响”表达格式。

- 范围外：
  - 不新增或修改任何运行时代码逻辑。
  - 不引入新的 MCP 服务或外部依赖。
  - 不调整脚本执行流程与参数。

### 推荐 MCP 能力类型（分类与命名规范）

- 分类清单（6 类）：
  - 代码检索
  - 结构与依赖分析
  - 影响分析
  - 文档与知识检索
  - 质量与安全检查
  - 运行与性能诊断

- 命名规范：
  - 中文名称采用“动词 + 对象”，2~6 个汉字，避免“增强/基础/可选”等相对词。
  - 英文标识可选，格式 `mcp-capability-<动词>-<对象>`，使用小写连字符。
  - SKILL.md 使用“推荐 MCP 能力类型”小节，列表格式为“类型名（可选英文标识）”。

- 对照表落点：`dev-playbooks/docs/推荐MCP.md`

### 规格冲突对齐策略

- 冲突点：
  - `dev-playbooks/specs/mcp/spec.md` 要求 SKILL.md 描述 MCP 检测方式与降级策略。
  - `dev-playbooks/specs/style-cleanup/spec.md` 要求删除 SKILL.md 的 MCP 增强相关章节。

- 取舍：
  - Skills 文档以职责单一与可替换性为优先，避免绑定具体 MCP 运行时细节。
  - MCP 检测与降级细节集中在 MCP 规格与对外文档中，避免在每个 SKILL.md 重复。

- 对齐方案与替代条款走向：
  - 更新 `dev-playbooks/specs/mcp/spec.md`：将 REQ-MCP-005 调整为“SKILL.md 只保留推荐 MCP 能力类型，不包含检测方式、超时与降级细节”，检测与降级说明保留在该规格与 `dev-playbooks/docs/推荐MCP.md`。
  - 更新 `dev-playbooks/specs/style-cleanup/spec.md`：将 REQ-STYLE-002 调整为“删除 MCP 增强/依赖服务/模式对比”，允许保留“推荐 MCP 能力类型”小节，并引用命名规范。

### 渐进披露统一模板

- 可扫描标题：`## 渐进披露`
- 固定层级标题：`### 基础层（必读）`、`### 进阶层（可选）`、`### 扩展层（可选）`
- 基础层必填字段（行首关键词）：`目标：`、`输入：`、`输出：`、`边界：`、`证据：`
- 进阶层字段（行首关键词）：`前置：`、`限制：`、`常见误用：`
- 扩展层字段（行首关键词）：`关联规范：`、`风险提示：`、`替代路径：`
- 渐进层级提示语（固定前缀）：
  - `提示语：适合首次使用者，聚焦最小必要信息。`
  - `提示语：适合需要定制者，包含边界与取舍。`
  - `提示语：适合维护者，包含关联规范与风险。`

模板示例（可直接复用）：
```markdown
## 渐进披露

### 基础层（必读）
提示语：适合首次使用者，聚焦最小必要信息。
目标：
输入：
输出：
边界：
证据：

### 进阶层（可选）
提示语：适合需要定制者，包含边界与取舍。
前置：
限制：
常见误用：

### 扩展层（可选）
提示语：适合维护者，包含关联规范与风险。
关联规范：
风险提示：
替代路径：
```

### “约束-取舍-影响”判定规则

- 适用范围：`README.md`、`docs/`、`dev-playbooks/specs/`、`skills/**/SKILL.md`、变更包文档（`proposal.md`/`design.md`/`specs/**`）。
- 可扫描关键词（行首）：`约束：`、`取舍：`、`影响：`
- 结构规则：
  - 同一小节内必须同时出现三条关键词。
  - 允许列表或段落格式，关键词必须位于行首。
  - 不适用范围：代码块、命令输出、引用块。
- 判定范围说明：用于理由、决策、取舍说明相关段落；纯事实描述段落不强制。

## Impact（影响分析）

- Value Signal and Observation: 无
- Value Stream Bottleneck Hypothesis: 无

- 受影响目录与说明：

| 目录 | 影响类型 | 说明 |
|---|---|---|
| `skills/` | 修改 | 更新 SKILL.md 的渐进披露与 MCP 能力类型说明 |
| `dev-playbooks/specs/` | 修改 | 补充长期视野、定位与提示词机制的规格或元信息 |
| `dev-playbooks/docs/` | 修改 | 更新 MCP 能力类型对照表与说明 |
| `docs/` | 修改 | 调整对外说明，统一定位与术语 |
| `scripts/` | 不变 | 不调整脚本行为与参数 |
| `tests/` | 可能修改 | 由 Test Owner 增补或调整测试覆盖新约束 |
| `mcp/` | 不变 | 不修改 MCP 配置与服务实现 |

- 对外契约与数据：
  - 对外契约：仅文档语义与规范层调整，不涉及 API/Schema/Event 变化。
  - 数据与迁移：无。

- 兼容性风险：
  - 旧文档与教程引用具体 MCP 名称，改为能力类型后需要映射理解，短期可能增加学习成本。
  - 定位澄清可能改变用户对 DevBooks 的功能预期，需要同步对外说明。

### Impact Analysis（影响分析）

- Scope（范围）：
  - 文档、规格与 Skills 文档层面的调整。
  - 不触及运行时代码、脚本执行逻辑与 MCP 服务实现。

- Impacts（影响）：
  - 用户将看到“长期视野/反短视”提示与“人类建议校准”提示词机制入口。
  - SKILL.md 从具体 MCP 名称转为能力类型提示，降低绑定成本。
  - 对外 MCP 推荐内容转为能力类型视角，提升可替换性。

- Risks（风险）：
  - 能力类型抽象可能降低新手的直观理解，需要通过对照表弥补。
  - 文档风格统一可能压缩个别 Skill 的细节表达，需要保留扩展段落空间。

- Minimal Diff（计划修改文件清单）：
  - `README.md`
  - `docs/使用指南.md`
  - `docs/Skill详解.md`
  - `dev-playbooks/docs/推荐MCP.md`
  - `dev-playbooks/specs/shared-methodology/spec.md`
  - `dev-playbooks/specs/mcp/spec.md`
  - `dev-playbooks/specs/style-cleanup/spec.md`
  - `dev-playbooks/specs/_meta/glossary.md`
  - `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/shared-methodology/spec.md`
  - `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/mcp/spec.md`
  - `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/style-cleanup/spec.md`
  - `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md`
  - `skills/devbooks-archiver/SKILL.md`
  - `skills/devbooks-brownfield-bootstrap/SKILL.md`
  - `skills/devbooks-coder/SKILL.md`
  - `skills/devbooks-convergence-audit/SKILL.md`
  - `skills/devbooks-delivery-workflow/SKILL.md`
  - `skills/devbooks-design-doc/SKILL.md`
  - `skills/devbooks-docs-consistency/SKILL.md`
  - `skills/devbooks-entropy-monitor/SKILL.md`
  - `skills/devbooks-impact-analysis/SKILL.md`
  - `skills/devbooks-implementation-plan/SKILL.md`
  - `skills/devbooks-proposal-author/SKILL.md`
  - `skills/devbooks-proposal-challenger/SKILL.md`
  - `skills/devbooks-proposal-judge/SKILL.md`
  - `skills/devbooks-reviewer/SKILL.md`
  - `skills/devbooks-router/SKILL.md`
  - `skills/devbooks-spec-contract/SKILL.md`
  - `skills/devbooks-test-owner/SKILL.md`
  - `skills/devbooks-test-reviewer/SKILL.md`
  - `tests/20260122-0827-enhance-docs-consistency/test_no_mcp_enhancement.bats`
  - `tests/complete-devbooks-independence/test_mcp_optional.bats`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_helper.bash`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_skills_templates.bats`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats`

- Open Questions（待决问题）：
  - “人类建议校准”提示词机制触发范围是否限定在高风险或设计性决策节点。
  - “长期视野/反短视”检查清单是否需要进入变更包模板。

## Risks（风险与回退）

- 风险与缓解：
  - 风险：能力类型替代具体 MCP 名称后，用户无法快速建立对应关系。  
    缓解：在文档中提供“能力类型→常见实现”对照说明。
  - 风险：渐进披露统一化可能简化某些 Skill 的专业引导。  
    缓解：保留“扩展段落”作为可选补充，明确适用场景。
  - 风险：“人类建议校准”提示词触发过频，降低效率。  
    缓解：定义明确触发条件，并限制在关键决策节点出现。

- 回退策略：
  - 通过后续变更包恢复原文档表述，并回退相关 SKILL.md 段落。
  - 保持变更包内的对照记录，便于比对与回滚。

## Validation（验证）

- 候选验收锚点：
  - DevBooks 定位在 `README.md`、`docs/使用指南.md` 与 `docs/Skill详解.md` 中保持一致，且不再表述为 MCP 工具。
  - 所有 SKILL.md 的 MCP 章节改为能力类型描述，不绑定具体 MCP 服务名。
  - Skills 的渐进披露段落结构一致，层级提示完整。
  - “人类建议校准”提示词机制在指定文档中出现，并包含触发条件与输出规范。
  - 文档语言为中文，理由表达采用“约束-取舍-影响”，无目的-结论句式。
  - 术语使用符合 `dev-playbooks/specs/_meta/glossary.md`。

- 测试影响评估（由 Test Owner 执行）：
  - 允许调整 `tests/20260122-0827-enhance-docs-consistency/test_no_mcp_enhancement.bats`，覆盖“禁止 MCP 增强/依赖/模式对比”且允许“推荐 MCP 能力类型”小节。
  - 允许调整 `tests/complete-devbooks-independence/test_mcp_optional.bats`，保持“可选 MCP”语义与能力类型指引一致。
  - 允许新增或调整测试点，验证 `dev-playbooks/docs/推荐MCP.md` 包含能力类型对照表与说明。
  - 允许新增或调整测试点，验证 `README.md` 与 `docs/使用指南.md` 的定位表述一致。
  - Coder 仍不得修改 `tests/`，由 Test Owner 负责测试变更。

- 证据位置：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/`

## Debate Packet（待决问题）

1. “人类建议校准”提示词机制的触发范围：
   - 选项 A：仅在高风险或设计性决策节点触发
   - 选项 B：提案/设计/规格阶段全部触发
   - 影响：A 成本低但覆盖窄，B 覆盖广但可能降低效率

2. “长期视野/反短视”检查清单落点：
   - 选项 A：仅在 `README.md` 与 `docs/使用指南.md` 提供
   - 选项 B：同时写入变更包模板
   - 影响：A 维护成本低，B 贴近工作流但需要调整模板与脚本

3. 渐进披露统一化强度：
   - 选项 A：统一章节结构与标题
   - 选项 B：仅统一关键段落，保留各 Skill 自由结构
   - 影响：A 一致性高，B 灵活性更强

## Decision Log

- Decision Status: Approved
truth-root=dev-playbooks/specs; change-root=dev-playbooks/changes

### [2026-01-24] 裁决：Revise Required

**专家视角**：Product Manager / System Architect

**理由摘要**：
- `.devbooks/config.yaml` 启用 `proposal.require_impact_analysis: true`，提案 Impact 仅有目录级表述，缺少影响分析产出与最小变更清单。
- `dev-playbooks/specs/mcp/spec.md` 的 REQ-MCP-005 要求保留 “MCP 增强”章节，`dev-playbooks/specs/style-cleanup/spec.md` 的 REQ-STYLE-002 要求删除相关章节，提案未给出对齐策略。
- “长期视野/反短视”与“人类建议校准”缺少操作性定义与可观察 AC；`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md`、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md`、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 仍为占位结构。
- 范围边界不完整：未列出要改写的 SKILL.md 与文档清单，未定义“推荐 MCP 能力类型”分类与命名规范，也未评估 `tests/20260122-0827-enhance-docs-consistency/test_no_mcp_enhancement.bats` 与 `tests/complete-devbooks-independence/test_mcp_optional.bats` 的约束影响。

**必须修改项**：
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 补充 Impact Analysis 段落，包含 Scope、Impacts、Risks、Minimal Diff、Open Questions，并列出具体文件清单。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 新增规格增量，明确 REQ-MCP-005 与 REQ-STYLE-002 的取舍与替换条款，并给出 AC Trace。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 补齐可观察 AC（AC-xxx），明确定义“长期视野/反短视”的可验证判据；`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 对应提供证据锚点与责任边界。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md` 增补“人类建议校准”术语定义与同义词约束。
- [ ] 在提案中列出本次修改的 SKILL.md 与文档清单（完整路径），并标注明确不在范围内的目录或文件。
- [ ] 给出“推荐 MCP 能力类型”的分类清单、命名规范，并指定“能力类型→常见实现”对照表的落点文档路径。
- [ ] 补充测试影响评估，说明 `tests/20260122-0827-enhance-docs-consistency/test_no_mcp_enhancement.bats` 与 `tests/complete-devbooks-independence/test_mcp_optional.bats` 的约束如何满足，给出“不改 tests/”的依据。

**验证要求**：
- [ ] Impact Analysis 段落包含 Scope、Impacts、Risks、Minimal Diff、Open Questions，且文件清单可逐条核对。
- [ ] 规格增量文件包含 REQ-MCP-005 与 REQ-STYLE-002 的对齐条款与 AC Trace。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md` 存在“人类建议校准”条目。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 明确证据落点 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/` 并给出验证命令清单。

### [2026-01-24] 裁决：Revise Required

**专家视角**：Product Manager / System Architect

**理由摘要**：
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 与 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 仍为模板，占位符未替换，未覆盖“长期视野/反短视”“人类建议校准”的可验证判据。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 仅含 README，未给出 REQ-MCP-005 与 REQ-STYLE-002 的替代条款文本与 AC Trace，对齐方案不可核验。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的 Minimal Diff 未包含术语表更新项，新增术语无法落入 glossary，渐进披露与“约束-取舍-影响”缺少可执行校验规则。
- “参考资料1痛点映射”未形成“痛点→改进→AC/验证锚点”闭环表，Validation 条目无法逐一对应痛点。

**必须修改项**：
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 增补 AC-xxx，覆盖“长期视野/反短视”“人类建议校准”，写明可观察 Pass/Fail；在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 建立 AC → Requirement/Scenario → Test/Command → Evidence 追溯，并给出证据命令或检查项。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 新增规格增量文件，写出 REQ-MCP-005 与 REQ-STYLE-002 的替代条款正文与 AC Trace，明确“SKILL.md 仅保留推荐 MCP 能力类型”与检测/降级细节的落点。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md` 补充“人类建议校准”“推荐 MCP 能力类型”定义与同义词约束，并在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的 Minimal Diff 清单加入该文件。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 增加“渐进披露统一模板”与“约束-取舍-影响”判定规则（可扫描关键词/结构），写明适用范围。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 添加“痛点→改进→AC/验证锚点”对照表，覆盖“参考资料1痛点映射”全部条目。

**验证要求**：
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 出现 AC-xxx 且 Pass/Fail 条件完整；`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 的 Traceability Matrix 与 Test Plan 有对应条目。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 中存在包含 REQ-MCP-005 与 REQ-STYLE-002 替代条款的 spec.md 文件，并含 AC Trace。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md` 包含上述术语定义；`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的 Minimal Diff 清单包含该文件路径。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 中包含“渐进披露统一模板”与“约束-取舍-影响”判定规则小节。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 中存在“痛点→改进→AC/验证锚点”对照表且覆盖全部痛点条目。

### [2026-01-24] 裁决：Revise

**专家视角**：Product Manager / System Architect

**理由摘要**：
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 仍为模板占位，AC-xxx 未落到可观察 Pass/Fail 判据。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 仍为模板占位，主线任务与 AC 绑定缺失。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 仍为模板占位，Test Plan、Traceability Matrix 与执行锚点未填充，证据落点不可核验。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 仅包含 `README.md`，缺少 `specs/mcp/spec.md`、`specs/style-cleanup/spec.md`、`specs/shared-methodology/spec.md` 与 `specs/_meta/glossary.md` 的增量条款，提案对齐方案缺少可核对文本。

**必须修改项**：
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 补齐 AC-xxx，覆盖“长期视野/反短视”“人类建议校准”“推荐 MCP 能力类型”“渐进披露”“约束-取舍-影响”，写明可观察 Pass/Fail 判据与证据锚点。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 填写主线任务（MP1.x），逐条引用 AC-xxx，并标注依赖与候选验证锚点。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 完成 Test Plan、Traceability Matrix、Execution Anchors，填写可执行命令或检查项与证据路径。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 新增 `shared-methodology/spec.md`、`mcp/spec.md`、`style-cleanup/spec.md`、`_meta/glossary.md` 的增量内容，写明 REQ-MCP-005 与 REQ-STYLE-002 的替代条款与 AC Trace。

**验证要求**：
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 中 AC-xxx 均包含可观察 Pass/Fail 判据与证据锚点。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 的每条 MP1.x 引用 AC-xxx，并含候选验证锚点。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 的 Traceability Matrix 与 Execution Anchors 有对应条目，证据路径指向 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/`。
- [ ] `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/` 新增的增量文件包含 REQ-MCP-005 与 REQ-STYLE-002 的替代条款正文与 AC Trace。

### [2026-01-24] 裁决：Revise Required

**理由摘要**：
- 从 Product Manager / System Architect 视角，`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 含 “Scope & Non-goals”“约束/取舍/影响”“验收标准”等 What/约束内容，违反 tasks 仅写 How 的前置检查。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 的 MP1.10 引入英文镜像同步，但提案的 What/Impact/Minimal Diff 未覆盖该范围，出现范围漂移。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的 Minimal Diff 未包含 `tests/20260124-0636-enhance-devbooks-longterm-guidance/` 下现有测试文件，与 `verification.md` 的验证锚点不一致。

**必须修改项**：
- [ ] 将 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 中的 What/约束/验收标准内容移除，仅保留实现步骤；必要的约束与验收标准回写到设计或提案。
- [ ] 删除 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 中 MP1.10 及所有英文镜像同步相关条目，后续如需同步另起变更包。
- [ ] 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的 Minimal Diff 清单补充以下测试文件路径：
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_helper.bash`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_skills_templates.bats`
  - `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats`

**验证要求**：
- [ ] `rg -n "Scope & Non-goals|约束：|取舍：|影响：|验收标准" dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 无输出。
- [ ] `rg -n "英文镜像" dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 无输出。
- [ ] `rg -n "tests/20260124-0636-enhance-devbooks-longterm-guidance/" dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 命中上述 4 个测试文件路径。

### [2026-01-24] 裁决：Approved

**专家视角**：Product Manager / System Architect

**理由摘要**：
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md` 已移除 What/约束/验收关键词，仅保留实现步骤与 AC 关联。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的 Minimal Diff 已补齐 4 个测试文件路径。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/mcp/spec.md` 与 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/style-cleanup/spec.md` 含 REQ-MCP-005 / REQ-STYLE-002 对齐条款。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md` 与 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 已给出 AC 与验证矩阵。

**验证要求**：
- [ ] `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats`
- [ ] `./skills/devbooks-delivery-workflow/scripts/change-check.sh 20260124-0636-enhance-devbooks-longterm-guidance --mode apply --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`

### [2026-01-24] 修订记录：回应 Challenger-7 收敛要求

**修订要点**：
- 删除“痛点→改进→AC/验证锚点”表内超出 AC-101~AC-106 的引用，改映射到 AC-101~AC-106 或标注为既有机制/范围外。
- 补齐合规/影子AI/供应链安全痛点的范围说明，限定为最小文本规范与提示词机制，不引入执行工具。
- “参考资料1痛点映射”开头新增来源路径说明，并统一标注表内锚点是否属于 Minimal Diff 或既有机制/范围外。
