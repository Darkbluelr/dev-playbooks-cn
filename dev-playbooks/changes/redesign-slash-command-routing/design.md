# Design: redesign-slash-command-routing

---
owner: Design Owner
status: Draft
version: 1.0.0
created: 2026-01-12
last_verified: 2026-01-12
freshness_check: 1 Month
---

> 产物落点：`dev-playbooks/changes/redesign-slash-command-routing/design.md`
>
> 本设计描述的是"本次变更应达成什么"，归档后合并进真理源。

---

## Acceptance Criteria（验收标准）

> **验收方式说明**：A = 机器裁判 | B = 工具证据+人签核 | C = 纯人工验收

| ID | 验收标准 | Pass/Fail 判据 | 验收方式 |
|----|----------|----------------|----------|
| AC-001 | 24 个 Slash 命令模板存在于 `templates/claude-commands/devbooks/` | `ls templates/claude-commands/devbooks/*.md \| wc -l` 输出 24 | A |
| AC-002 | 每个命令与对应 Skill 1:1 对应 | 命令文件名与 SKILL.md 中 `name:` 字段匹配（去除 `devbooks-` 前缀） | A |
| AC-003 | Router 能读取 Impact 画像并输出执行计划 | 给定 5 个历史变更的 proposal.md，Router 成功解析 ≥ 4 个（成功率 ≥ 80%） | B |
| AC-004 | `devbooks-spec-contract` 能自动检测模式 | 三种场景（无 specs/、有但不完整、完整）各测试 1 次，输出正确模式 | A |
| AC-005 | `devbooks-c4-map` 能自动检测模式 | 两种场景（无 c4.md、有 c4.md）各测试 1 次，输出正确模式 | A |
| AC-006 | MCP 检测机制在 Skill 执行时触发 | 执行任意 Skill 时，日志显示 MCP 检测尝试 | B |
| AC-007 | 检测超时（2s）时自动降级 | 模拟 MCP 不可用，2s 后 Skill 继续执行且输出降级提示 | A |
| AC-008 | 现有 6 个命令的调用方式保持兼容 | `/devbooks:proposal`、`/devbooks:design` 等原有命令正常工作 | A |
| AC-009 | C4 架构文档更新 | FT-009 规则检查条件为 `cmd_count -eq 24`（21 核心 + 3 向后兼容） | A |
| AC-010 | 验证脚本 `verify-slash-commands.sh` 更新 | 脚本包含 AC-011 ~ AC-028 验证项（21 个命令各一项） | A |
| AC-011 | `skills/_shared/context-detection-template.md` 存在 | 文件存在且包含完整性判断规则（含 7 个边界场景） | A |
| AC-012 | Router 解析失败时输出错误提示和降级方案 | 模拟无 Impact 画像时，输出明确错误 + 建议直达命令 | B |
| AC-013 | 回滚方案可执行 | dry-run 执行回滚命令无报错，记录到 `evidence/rollback-dry-run.log` | B |
| AC-014 | `dev-playbooks/project-profile.md` 同步更新 | 命令数量字段显示 21 | A |

---

## Goals / Non-goals / Red Lines

### Goals（本次变更目标）

1. **G-01**: 实现命令与 Skill 1:1 对应（21 个 Skill → 21 个核心 Slash 命令，另有 3 个向后兼容命令，共 24 个文件）
2. **G-02**: 建立双入口模式（Router 主入口 + 直达命令入口）
3. **G-03**: 实现 Skill 自动上下文感知（检测产物存在性、当前阶段）
4. **G-04**: 实现 MCP 运行时检测（自动增强或降级）
5. **G-05**: 补齐关键角色入口（Planner、Challenger、Judge、Impact Analyst）

### Non-goals（明确不做）

1. **NG-01**: 不改变 Skill 的核心职责定义
2. **NG-02**: 不改变变更包目录结构（`<change-root>/<change-id>/` 结构不变）
3. **NG-03**: 不改变角色隔离原则（Test Owner 与 Coder 独立对话）
4. **NG-04**: 不实现动态生成命令（留待未来迭代）
5. **NG-05**: 不版本化命令模板（使用 `--update-skills` 覆盖即可）

### Red Lines（不可破的约束）

1. **RL-01**: 现有 6 个命令（proposal/design/apply/review/archive/quick）的调用方式必须保持兼容
2. **RL-02**: 上下文检测只能基于文件存在性，不能依赖外部状态
3. **RL-03**: MCP 检测必须有超时机制（≤2s），不能阻塞 Skill 执行
4. **RL-04**: 变更不得影响现有变更包的归档流程

---

## Executive Summary（执行摘要）

当前 DevBooks 的 6 个阶段命令无法覆盖 21 个 Skills，导致关键角色（Planner、Challenger、Judge）无直接入口，用户认知负担高。本设计采用"命令与 Skill 1:1 + Router 驱动 + 上下文自动感知"方案，新增 15 个命令模板，使每个 Skill 都有专属入口，同时通过 Router 为复杂变更生成完整执行计划。

---

## Problem Context（问题背景）

### 为什么要解决这个问题

1. **用户体验差**：用户需要记忆大量命令和阶段组合，阅读完全体提示词文档才知道有哪些角色可用
2. **工作流断裂**：关键步骤（如 Planner 生成 tasks.md）没有入口，容易遗漏
3. **MCP 能力浪费**：即使安装了 CKB/code-intelligence，用户可能不知道如何利用

### 当前摩擦点

- 同一个 Skill（如 `devbooks-spec-contract`）在不同阶段需要不同的调用方式
- 用户需要手动选择"基础提示词"还是"完全体提示词"
- 阶段绑定过紧，部分 Skill（entropy-monitor、federation）不属于任何阶段

### 不解决的后果

- 用户流失（学习曲线过高）
- 质量下降（关键步骤被跳过）
- DevBooks 能力无法充分发挥

---

## Value Chain Mapping（价值链映射）

```
Goal: 降低用户认知负担，提升工作流完整性
    │
    ├── 阻碍：命令与 Skill 不对应，阶段绑定过紧
    │
    ├── 杠杆：命令 1:1 + Router 驱动 + 上下文感知
    │
    └── 最小方案：
        1. 新增 15 个命令模板文件
        2. 为 21 个 SKILL.md 添加上下文感知章节
        3. 更新 Router 输出格式
        4. 更新验证脚本与 C4 文档
```

---

## Design Principles（设计原则）

### 核心原则

1. **概念统一**：命令名 = Skill 名（去掉 `devbooks-` 前缀），消除映射记忆
2. **智能默认**：Skill 自动检测上下文，用户无需手动指定模式
3. **优雅降级**：MCP 不可用时自动降级，不阻塞核心功能
4. **向后兼容**：旧命令完全可用，只是增加新入口

### Variation Points（变化点识别）

| 变化点 | 变化频率 | 封装策略 |
|--------|----------|----------|
| 命令模板内容 | 中 | 每个命令一个独立 .md 文件 |
| 上下文检测规则 | 低 | 提取到 `context-detection-template.md` |
| MCP 检测逻辑 | 低 | 提取到各 SKILL.md 的标准章节 |
| Router 输出格式 | 中 | 模板化，易于调整 |

---

## Target Architecture（目标架构）

### Bounded Context（限界上下文）

本次变更涉及以下上下文：

1. **命令层**：`templates/claude-commands/devbooks/` — 用户入口
2. **Skill 层**：`skills/devbooks-*/SKILL.md` — 能力定义
3. **验证层**：`skills/devbooks-delivery-workflow/scripts/` — 质量闸门
4. **架构层**：`dev-playbooks/specs/architecture/c4.md` — 架构守护

### 依赖方向

```
用户
  │
  ├──► 命令层（21 个命令模板）
  │       │
  │       └──► Skill 层（21 个 SKILL.md）
  │               │
  │               ├──► context-detection-template.md（上下文检测规则）
  │               │
  │               └──► MCP 检测（CKB / code-intelligence）
  │
  └──► Router（/devbooks:router）
          │
          └──► 读取 Impact 画像 → 输出执行计划
```

### C4 Delta

> 详见本文档末尾"C4 Delta"章节（由 C4 Map Maintainer 填写）。

---

## Testability & Seams（可测试性与接缝）

### 测试接缝（Seams）

- **命令模板存在性**：`ls templates/claude-commands/devbooks/*.md | wc -l`
- **Skill 名称匹配**：对比命令文件名与 SKILL.md 的 `name:` 字段
- **上下文检测**：创建/删除特定文件，验证 Skill 输出模式

### Pinch Points（汇点）

- `verify-slash-commands.sh`：验证全部 21 个命令的存在性与正确性
- `context-detection-template.md`：所有 Skill 的上下文检测共用此规则

### 依赖隔离

- MCP 检测通过超时机制隔离（2s 超时后降级）
- 上下文检测仅依赖文件存在性，不依赖外部服务

---

## Domain Model（领域模型）

### Data Model

| 对象 | 类型 | 说明 |
|------|------|------|
| SlashCommand | @ValueObject | 命令模板文件，不可变 |
| ContextMode | @ValueObject | 上下文模式（从零/补漏/同步） |
| ImpactProfile | @ValueObject | 影响画像（YAML 结构） |
| ExecutionPlan | @ValueObject | Router 输出的执行计划 |

### Business Rules

| ID | 规则 | 触发条件 | 约束 | 违反行为 |
|----|------|----------|------|----------|
| BR-001 | 命令与 Skill 1:1 | 新增命令时 | 命令名 = Skill 名（去 devbooks- 前缀） | 拒绝创建 |
| BR-002 | 上下文检测优先级 | Skill 执行时 | 先检测产物存在性，再检测完整性 | - |
| BR-003 | MCP 超时降级 | MCP 检测时 | 超时 2s 必须降级 | 阻塞 Skill 执行 |
| BR-004 | Router 失败降级 | Router 解析失败时 | 输出错误提示 + 建议直达命令 | 静默失败 |

### Invariants（固定规则）

- `[Invariant]` 命令文件总数 = 24（21 核心 + 3 向后兼容）
- `[Invariant]` FT-009 检查值 = 24（命令文件总数）
- `[Invariant]` 上下文检测只读取文件，不修改文件

---

## Core Contracts（核心契约）

### 命令模板结构

每个命令模板文件（如 `router.md`）必须包含：

```markdown
---
skill: devbooks-<skill-name>
---

<命令提示词内容>
```

### Impact 画像结构（由 Impact Analyst 输出）

```yaml
impact_profile:
  external_api: true/false
  architecture_boundary: true/false
  data_model: true/false
  cross_repo: true/false
  risk_level: high/medium/low
  affected_modules:
    - name: <module-path>
      type: add/modify/delete
      files: <count>
```

### 上下文检测输出

```
检测结果：
- 产物存在性：存在/不存在
- 完整性：完整/不完整（缺失项：...）
- 当前阶段：proposal/apply/archive
- 运行模式：从零创建/补漏/同步到真理源
```

---

## Contract（契约章节）

> 由 Spec & Contract Owner 于 2026-01-12 填写

### API 变更

本次变更不涉及对外 API 变更。主要变更为内部命令模板和 SKILL.md 文件。

### 文件契约

| 契约类型 | 文件/路径 | 版本策略 |
|----------|-----------|----------|
| 命令模板 | `templates/claude-commands/devbooks/*.md` | 无版本化，`--update-skills` 覆盖 |
| 上下文检测规则 | `skills/_shared/context-detection-template.md` | 随 DevBooks 版本更新 |
| Impact 画像 | `proposal.md` 内嵌 YAML | 格式固定，扩展字段向前兼容 |

### 兼容策略

| 兼容类型 | 策略 | 说明 |
|----------|------|------|
| 向后兼容 | **完全兼容** | 现有 6 个命令保留，调用方式不变 |
| 向前兼容 | **部分兼容** | 新版本 DevBooks 生成的 proposal.md 可被旧版本用户手动处理 |
| 弃用策略 | **无弃用** | 不弃用任何现有功能 |

### Contract Test IDs

| Test ID | 类型 | 覆盖场景 | 关联 AC |
|---------|------|----------|---------|
| CT-SC-001 | 存在性 | 21 个命令模板全部存在 | AC-001 |
| CT-SC-002 | 结构 | 命令模板包含正确的 `skill:` 元数据 | AC-002 |
| CT-SC-003 | 兼容性 | 旧命令正常工作 | AC-008 |
| CT-CD-001 | 行为 | 上下文检测输出正确模式 | AC-004, AC-005 |
| CT-CD-002 | 边界 | 7 个完整性判断边界场景 | AC-011 |
| CT-MCP-001 | 行为 | MCP 检测触发 | AC-006 |
| CT-MCP-002 | 超时 | 2s 超时后降级 | AC-007 |
| CT-RT-001 | 行为 | Router 解析 Impact 画像 | AC-003 |
| CT-RT-002 | 错误处理 | Router 解析失败输出降级方案 | AC-012 |

### 追溯矩阵（AC → Contract Test）

| AC | Contract Test | 规格 Requirement |
|----|---------------|------------------|
| AC-001 | CT-SC-001 | REQ-SC-001 |
| AC-002 | CT-SC-002 | REQ-SC-001, REQ-SC-002 |
| AC-003 | CT-RT-001 | REQ-RT-001, REQ-RT-002, REQ-RT-004 |
| AC-004 | CT-CD-001 | REQ-CD-002, REQ-CD-003 |
| AC-005 | CT-CD-001 | REQ-CD-002, REQ-CD-005 |
| AC-006 | CT-MCP-001 | REQ-MCP-001 |
| AC-007 | CT-MCP-002 | REQ-MCP-002, REQ-MCP-003 |
| AC-008 | CT-SC-003 | REQ-SC-003 |
| AC-011 | CT-CD-002 | REQ-CD-001, REQ-CD-003 |
| AC-012 | CT-RT-002 | REQ-RT-003 |

---

## Documentation Impact（文档影响）

### 需要更新的文档

| 文档 | 更新原因 | 优先级 |
|------|----------|--------|
| `dev-playbooks/specs/architecture/c4.md` | FT-009 规则改为 21；templates/claude-commands/devbooks/ 组件表更新 | P0 |
| `README.md` | 更新命令列表（从 6 扩展到 21） | P1 |
| `docs/完全体提示词.md` | 更新角色入口说明 | P1 |
| `setup/generic/安装提示词.md` | 若引用命令列表需更新 | P2 |

### 无需更新的文档

- [x] 本次变更不涉及 constitution.md

### 文档更新检查清单

- [ ] 新增命令已在 README 中列出
- [ ] C4 组件表已更新
- [ ] FT-009 规则已更新
- [ ] 完全体提示词文档已更新角色入口

---

## Key Mechanisms（关键机制）

### 1. 上下文检测机制

**检测顺序**：
1. 产物存在性检测（检查 `<change-root>/<change-id>/specs/` 是否存在）
2. 完整性检测（按 Req 分组校验 Given/When/Then）
3. 当前阶段检测（基于已有文件推断）

**完整性判断规则**（详见 proposal.md §3 第 316-362 行）：
- 按 Requirement 块遍历
- 每个 REQ 必须有至少一个 Scenario
- 每个 Scenario 必须有 Given/When/Then
- 不存在占位符（`[TODO]`、`[待补充]`）

### 2. MCP 检测机制

**检测流程**：
1. 调用 `mcp__ckb__getStatus()` 检测 CKB
2. 设置 2s 超时
3. 根据结果选择提示词版本

**降级策略**：
- CKB 可用 → 完全体提示词
- CKB 不可用 → 基础提示词（Grep + Glob）
- 超时 → 输出 `[MCP 检测超时，已降级为基础模式]`

### 3. Router 推导机制

**输入**：`proposal.md` 的 Impact 章节（结构化 YAML）

**输出**：执行计划（命令序列 + 状态 + 原因）

**失败处理**：
- 无 Impact 画像 → 输出错误提示 + 缺失字段清单
- 解析失败 → 建议用户使用直达命令 `/devbooks:<skill>`

---

## Risks & Mitigation（风险与缓解）

| 风险 | 概率 | 影响 | 严重程度 | 缓解措施 |
|------|------|------|----------|---------|
| FT-009 规则断言失败 | 高 | 高 | Critical | 必须同步修改 c4.md 中 FT-009 的检查条件 |
| verify-slash-commands.sh 不覆盖新命令 | 高 | 中 | High | 新增 AC-011 ~ AC-028 验证项 |
| Router 解析失败 | 中 | 高 | High | 输出错误提示 + 降级方案 |
| Router 推荐流程不完整 | 中 | 中 | Medium | 明确声明"建议流程"，允许跳过 |
| Skill 上下文检测逻辑复杂 | 中 | 中 | Medium | 标准化模板 + 7 个边界场景测试 |
| MCP 检测失败导致功能降级 | 低 | 低 | Low | 2s 超时，降级到基础提示词仍可用 |

---

## Milestones（里程碑）

| 阶段 | 产物 | 验收标准 |
|------|------|----------|
| M1 | 命令模板创建 | AC-001, AC-002 通过 |
| M2 | 上下文感知实现 | AC-004, AC-005, AC-011 通过 |
| M3 | MCP 检测实现 | AC-006, AC-007 通过 |
| M4 | Router 增强 | AC-003, AC-012 通过 |
| M5 | 验证与文档更新 | AC-009, AC-010, AC-014 通过 |
| M6 | 兼容性验证 | AC-008 通过 |
| M7 | 回滚验证 | AC-013 通过 |

---

## Design Rationale（设计决策理由）

### 为什么选择方案 C（命令与 Skill 1:1 + Router 驱动）

| 方案 | 描述 | 被否决原因 |
|------|------|------------|
| A | 保持现状 + 补充文档 | 治标不治本，用户体验无改善 |
| B | 阶段入口 + --role 参数 | entropy-monitor、federation 不属于任何阶段，无法覆盖 |
| D | 动态生成命令 | 实现复杂，调试困难，留待未来迭代 |

**选择方案 C 的理由**：
1. 概念统一：命令与 Skill 1:1，无需记忆映射
2. 入口收敛：Router 生成完整计划，用户只需跟着走
3. 智能适配：MCP 自动检测，用户无感知升级/降级
4. 关键角色补齐：Planner、Challenger、Judge 有了直接入口

---

## Trade-offs（权衡取舍）

1. **命令数量增加（6 → 21）**：接受。用户主要通过 Router，不需要记忆全部命令。
2. **实现复杂度高**：接受。上下文检测逻辑基于文件存在性，规则明确，可测试。
3. **向后兼容成本**：最小化。旧命令保留，只是增加新命令。

---

## DoD（Definition of Done）

### 完成定义

本设计在以下条件全部满足时算"完成"：

1. **AC 全部通过**：AC-001 ~ AC-014 全部为 Pass
2. **闸门全绿**：`verify-slash-commands.sh` 执行无失败
3. **FT-009 通过**：`cmd_count -eq 21`
4. **证据齐全**：`evidence/` 目录包含以下文件：
   - `rollback-dry-run.log`
   - `router-parse-stats.md`
   - `context-detection-test.log`
   - `mcp-latency.log`

### 必须通过的闸门

| 闸门 | 命令 |
|------|------|
| 命令完整性 | `ls templates/claude-commands/devbooks/*.md \| wc -l` = 24 |
| FT-009 | `fitness-check.sh` 无失败 |
| 验证脚本 | `verify-slash-commands.sh` 无失败 |

### 与 AC 的交叉引用

- AC-001 ↔ 命令完整性闸门
- AC-009 ↔ FT-009 闸门
- AC-010 ↔ 验证脚本闸门
- AC-013 ↔ `evidence/rollback-dry-run.log`

---

## Open Questions

1. **Q**: 如果用户同时安装了多个版本的 DevBooks，命令模板如何处理？
   - **待定**：当前设计不处理多版本共存，使用 `--update-skills` 覆盖即可。

2. **Q**: 上下文检测的性能影响如何？
   - **待定**：检测基于文件存在性，预期 <100ms，实际数据需在 apply 阶段测量。

3. **Q**: 是否需要为每个命令添加 `--dry-run` 模式？
   - **待定**：当前只为 Router 添加 `--dry-run`，其他命令按需迭代。

---

## C4 Delta

> 由 C4 Map Maintainer 于 2026-01-12 填写
>
> **注意**：proposal 阶段不修改真理源 `dev-playbooks/specs/architecture/c4.md`，仅记录 Delta。

### C2 容器级变更

#### MODIFIED: templates/claude-commands/devbooks/ 组件

**现有描述**（c4.md:113-126）：

| 命令 | 触发 Skill | 说明 |
|------|------------|------|
| `proposal.md` | devbooks-proposal-author | 创建变更提案 |
| `design.md` | devbooks-design-doc | 创建设计文档 |
| `apply.md` | devbooks-test-owner / devbooks-coder / devbooks-code-review | 执行实现 |
| `review.md` | devbooks-code-review | 代码评审 |
| `archive.md` | devbooks-spec-gardener | 归档变更包 |
| `quick.md` | 多 Skill 组合 | 快速模式 |

**变更后描述**：

| 命令 | 触发 Skill | 说明 |
|------|------------|------|
| `router.md` | devbooks-router | 路由入口，生成执行计划 |
| `proposal.md` | devbooks-proposal-author | 创建变更提案 |
| `impact.md` | devbooks-impact-analysis | 影响分析 |
| `challenger.md` | devbooks-proposal-challenger | 提案质疑 |
| `judge.md` | devbooks-proposal-judge | 提案裁决 |
| `debate.md` | devbooks-proposal-debate-workflow | 提案辩论流程 |
| `design.md` | devbooks-design-doc | 创建设计文档 |
| `spec.md` | devbooks-spec-contract | 规格与契约 |
| `c4.md` | devbooks-c4-map | C4 架构地图 |
| `plan.md` | devbooks-implementation-plan | 实现计划 |
| `test.md` | devbooks-test-owner | 验收测试 |
| `code.md` | devbooks-coder | 代码实现 |
| `review.md` | devbooks-code-review | 代码评审 |
| `test-review.md` | devbooks-test-reviewer | 测试评审 |
| `backport.md` | devbooks-design-backport | 设计回写 |
| `gardener.md` | devbooks-spec-gardener | 规格园丁 |
| `entropy.md` | devbooks-entropy-monitor | 熵度量 |
| `federation.md` | devbooks-federation | 联邦分析 |
| `bootstrap.md` | devbooks-brownfield-bootstrap | 存量项目初始化 |
| `index.md` | devbooks-index-bootstrap | 索引初始化 |
| `delivery.md` | devbooks-delivery-workflow | 交付工作流 |

**合计**：24 个命令文件（21 个核心命令，新增 15 个 + 保留 6 个；另有 3 个向后兼容别名 apply/archive/quick）

---

### C3 组件级变更

#### ADDED: skills/_shared/ 目录

| 文件 | 作用 |
|------|------|
| `context-detection-template.md` | 上下文检测标准规则（产物存在性、完整性判断、阶段检测） |

#### MODIFIED: skills/devbooks-*/SKILL.md（21 个文件）

每个 SKILL.md 新增以下章节：

1. **上下文感知章节**：检测产物存在性、当前阶段
2. **MCP 增强章节**：检测 CKB 可用性，自动选择提示词版本

---

### Architecture Guardrails 变更

#### MODIFIED: FT-009 Slash 命令完整性

**现有规则**（c4.md:264-276）：

```bash
cmd_count=$(ls templates/claude-commands/devbooks/*.md 2>/dev/null | wc -l)
[[ "$cmd_count" -eq 6 ]] && echo "OK" || echo "FAIL"
```

**变更后规则**：

```bash
cmd_count=$(ls templates/claude-commands/devbooks/*.md 2>/dev/null | wc -l)
[[ "$cmd_count" -eq 24 ]] && echo "OK" || echo "FAIL"
```

**变更原因**：命令数量从 6 扩展到 24（21 核心 + 3 向后兼容），使用精确值 `-eq`。

---

### 依赖方向变更

**新增依赖路径**：

```
templates/claude-commands/devbooks/*.md
    │
    └──► skills/devbooks-*/SKILL.md（1:1 对应）
            │
            └──► skills/_shared/context-detection-template.md（共用）
```

**约束**：
- 命令模板只能引用对应的 SKILL.md
- SKILL.md 可以引用 `_shared/` 下的共用模板
- 禁止 `_shared/` 反向依赖具体 Skill

---

### 建议的 Fitness Tests 条目

| FT-ID | 规则 | 检查命令 | 严重程度 |
|-------|------|----------|----------|
| FT-010 | 命令名与 Skill 名 1:1 对应 | 对比命令文件名与 SKILL.md `name:` 字段 | High |
| FT-011 | `_shared/` 目录存在 | `ls skills/_shared/context-detection-template.md` | Medium |
| FT-012 | SKILL.md 包含上下文感知章节 | `rg "## 上下文" skills/devbooks-*/SKILL.md \| wc -l` ≥ 21 | Medium |

---

### 追溯

| C4 变更 | 关联 AC |
|---------|---------|
| templates/claude-commands/devbooks/ 扩展到 21 | AC-001 |
| FT-009 规则修改 | AC-009 |
| skills/_shared/context-detection-template.md 新增 | AC-011 |

---

**文档版本**：v1.0.1
**最后更新**：2026-01-12
**回写记录**：
- v1.0.1 (2026-01-12): Design Backport - 修正 AC-009 和 C4 Delta 中 FT-009 规则值从 21 改为 24（与 Invariants 和真理源 c4.md 保持一致）
