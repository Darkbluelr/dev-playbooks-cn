# DevBooks Skill 详解

> 本文档详细介绍 DevBooks 的 19 个 Skills，包括每个 Skill 的特色、功能和使用场景。

---

## 定位与文本规范

DevBooks 本体是非 MCP 工具，但提供 MCP 可选集成点，便于按需接入外部能力，同时保留少量自检脚本作为护栏。
DevBooks 以协议、工作流、文本规范为主线，确保技能说明可追溯与可验证。

约束：技能描述需要稳定、可扫描、可复用。
取舍：优先统一结构表达，减少个性化叙述。
影响：维护成本下降，跨角色理解一致。

---

## 目录

- [工作流入口](#工作流入口)
- [提案阶段](#提案阶段)
- [设计阶段](#设计阶段)
- [规格阶段](#规格阶段)
- [计划阶段](#计划阶段)
- [测试阶段](#测试阶段)
- [实现阶段](#实现阶段)
- [评审阶段](#评审阶段)
- [归档阶段](#归档阶段)
- [质量保证](#质量保证)
- [存量项目](#存量项目)
- [完整闭环](#完整闭环)

---

## 工作流入口

### devbooks-router

**角色**：工作流引导

**特色**：
- 检测项目当前状态
- 确定从哪个 skill 开始
- 给出最短闭环路径

**使用场景**：
- 不确定下一步该做什么
- 项目状态不清楚
- 需要工作流指导

**调用方式**：
```bash
/devbooks-router
```

**输出**：
- 当前项目状态分析
- 推荐的下一步 skill
- 完整闭环路径建议

---

## 提案阶段

### devbooks-proposal-author

**角色**：Proposal Author（提案撰写者）

**特色**：
- 撰写变更提案（Why/What/Impact）
- 包含 Debate Packet（对辩材料）
- 对设计性决策呈现选项给用户

**使用场景**：
- 开始新功能开发
- 重大重构
- 破坏性变更

**调用方式**：
```bash
/devbooks-proposal-author
```

**输出**：
- `proposal.md`：包含 Why/What/Impact/Open Questions
- 设计选项（如有）

**关键约束**：
- 必须说明变更背景与目标
- 必须分析影响范围和风险
- 必须提出未解决的问题

---

### devbooks-proposal-challenger

**角色**：Challenger（质疑者）

**特色**：
- 对 proposal.md 发起质疑
- 指出风险/遗漏/不一致
- 发现缺失的验收标准和未覆盖场景

**使用场景**：
- 提案评审
- 风险评估
- 查漏补缺

**调用方式**：
```bash
/devbooks-proposal-challenger
```

**输出**：
- 质疑报告
- 风险清单
- 改进建议

**关键约束**：
- 以证据优先、声明存疑的原则质疑
- 不盲目信任提案内容

---

### devbooks-proposal-judge

**角色**：Judge（裁决者）

**特色**：
- 对 proposal 阶段进行裁决
- 输出 Approved/Revise/Rejected
- 写回 proposal.md 的 Decision Log

**使用场景**：
- 提案最终决策
- 提案评审结束

**调用方式**：
```bash
/devbooks-proposal-judge
```

**输出**：
- 裁决结果（Approved/Revise/Rejected）
- Decision Log

**关键约束**：
- 必须给出明确的裁决结果
- 必须写回 Decision Log

---

## 设计阶段

### devbooks-design-doc

**角色**：Design Owner（设计负责人）

**特色**：
- 产出变更包的设计文档（design.md）
- 只写 What/Constraints 与 AC-xxx
- 不写实现步骤

**使用场景**：
- 定义功能需求
- 定义验收标准
- 定义约束条件

**调用方式**：
```bash
/devbooks-design-doc
```

**输出**：
- `design.md`：包含 What/Constraints/AC-xxx/C4 Delta

**关键约束**：
- 不能包含实现步骤
- 必须定义清晰的 AC-xxx
- 必须说明约束条件

---


## 规格阶段

### devbooks-spec-contract

**角色**：Spec Owner（规格负责人）

**特色**：
- 定义对外行为规格与契约
- 包含 Requirements/Scenarios/API/Schema
- 定义兼容性策略与迁移方案
- 建议或生成 contract tests

**使用场景**：
- 定义 API 接口
- 定义数据模型
- 定义对外契约

**调用方式**：
```bash
/devbooks-spec-contract
```

**输出**：
- `spec.md`：包含 API/Schema/兼容性策略
- Contract Tests（可选）

**关键约束**：
- 必须定义清晰的对外契约
- 必须考虑兼容性

---

## 计划阶段

### devbooks-implementation-plan

**角色**：Planner（计划制定者）

**特色**：
- 从设计文档推导编码计划（tasks.md）
- 输出可跟踪的主线计划/临时计划/断点区
- 绑定验收锚点

**使用场景**：
- 制定实现计划
- 任务拆解
- 并行拆分

**调用方式**：
```bash
/devbooks-implementation-plan
```

**输出**：
- `tasks.md`：包含主线计划/临时计划/验收锚点

**关键约束**：
- 不能引用 tests/ 目录
- 必须绑定 AC-xxx

---

## 测试阶段

### devbooks-test-owner

**角色**：Test Owner（测试负责人）

**特色**：
- 把设计/规格转成可执行验收测试
- 强调与实现（Coder）独立对话
- 先跑出 Red 基线

**使用场景**：
- 编写验收测试
- 编写 contract tests
- 编写 fitness tests

**调用方式**：
```bash
# 在独立对话中
/devbooks-test-owner
```

**输出**：
- `verification.md`：测试策略与追溯文档
- `tests/`：测试代码

**关键约束**：
- 必须在独立对话中工作
- 必须先跑出 Red 基线
- 不能看 Coder 的实现

---

### devbooks-test-reviewer

**角色**：Test Reviewer（测试评审者）

**特色**：
- 评审 tests/ 测试质量
- 检查覆盖、边界、可读性、可维护性
- 只输出评审意见，不修改代码

**使用场景**：
- 测试代码评审
- 测试质量检查

**调用方式**：
```bash
/devbooks-test-reviewer
```

**输出**：
- 测试评审报告
- 改进建议

**关键约束**：
- 不修改测试代码
- 只评审质量

---

## 实现阶段

### devbooks-coder

**角色**：Coder（编码者）

**特色**：
- 严格按 tasks.md 实现功能
- 禁止修改 tests/
- 以测试/静态检查为唯一完成判据

**使用场景**：
- 功能实现
- Bug 修复

**调用方式**：
```bash
# 在独立对话中
/devbooks-coder
```

**输出**：
- 实现代码
- Green 证据（测试通过）

**关键约束**：
- 不能修改 tests/ 目录
- 不能修改设计文档
- 完成标准是测试通过，而非自评

---

## 评审阶段

### devbooks-reviewer

**角色**：Reviewer（代码评审者）

**特色**：
- 做可读性/一致性/依赖健康/坏味道审查
- 只输出审查意见与可执行建议
- 不讨论业务正确性

**使用场景**：
- 代码评审
- 可维护性检查

**调用方式**：
```bash
/devbooks-reviewer
```

**输出**：
- 代码评审报告
- 改进建议

**关键约束**：
- 不评审业务正确性（由测试保证）
- 只关注可维护性

---

## 归档阶段

### devbooks-archiver

**角色**：Archiver（归档者）

**特色**：
- 归档阶段的唯一入口
- 负责完整的归档闭环：
  - 自动回写设计（Design Backport）
  - 规格合并到真理（Spec Merge）
  - 文档同步检查（Docs Consistency）
  - 变更包归档移动

**使用场景**：
- 变更完成后归档
- 合并到真理

**调用方式**：
```bash
/devbooks-archiver
```

**输出**：
- 更新后的真理目录
- 归档后的变更包

**关键约束**：
- 必须在所有质量闸门通过后才能归档

---

### devbooks-docs-consistency

**角色**：Docs Consistency（文档一致性检查）

**特色**：
- 检查并维护项目文档与代码的一致性
- 支持增量扫描、自定义规则、完备性检查
- 可在变更包内按需运行或全局检查

**使用场景**：
- 文档一致性检查
- 归档前验证
- 全局文档审计

**调用方式**：
```bash
# 增量扫描（变更包上下文）
/devbooks-docs-consistency

# 全局扫描
/devbooks-docs-consistency --global

# 只检查不修改
/devbooks-docs-consistency --check
```

**输出**：
- 文档一致性检查报告
- 完备性检查报告

**关键约束**：
- 只检查、不修改代码

---

## 质量保证

### devbooks-impact-analysis

**角色**：Impact Analyzer（影响分析者）

**特色**：
- 跨模块/跨文件/对外契约变更前做影响分析
- 产出可直接写入 proposal.md 的 Impact 部分
- 包含 Scope/Impacts/Risks/Minimal Diff/Open Questions

**使用场景**：
- 变更前影响评估
- 风险分析
- 改动面控制

**调用方式**：
```bash
/devbooks-impact-analysis
```

**输出**：
- 影响分析报告
- 受影响模块清单
- 风险评估

**关键约束**：
- 必须分析跨模块影响

---

### devbooks-convergence-audit

**角色**：Convergence Auditor（收敛性审计者）

**特色**：
- 评估多个变更包闭环后是否有效推进
- 检测"边修边破"和"循环打转"反模式
- 以证据优先、声明存疑的原则审计

**使用场景**：
- 跑了几个变更包闭环后，评估是否真正推进
- 检测是否陷入"修复一个 Bug 引入两个 Bug"的循环
- 工作流健康度审计

**调用方式**：
```bash
/devbooks-convergence-audit
```

**输出**：
- 收敛性评估报告
- 反模式检测结果
- 改进建议

**关键约束**：
- 以证据为准，不信任声明
- 需要至少 2-3 个变更包的历史数据

---

### devbooks-entropy-monitor

**角色**：Entropy Monitor（熵度量监控者）

**特色**：
- 定期采集系统熵度量（结构熵/变更熵/测试熵/依赖熵）
- 生成量化报告
- 当指标超阈值时建议重构

**使用场景**：
- 系统健康度监控
- 技术债务度量
- 重构预警

**调用方式**：
```bash
/devbooks-entropy-monitor
```

**输出**：
- 熵度量报告
- 趋势分析
- 重构建议

**关键约束**：
- 定期运行以跟踪趋势

---

## 存量项目

### devbooks-brownfield-bootstrap

**角色**：Brownfield Bootstrap（存量项目初始化）

**特色**：
- 在当前真理目录为空时生成项目画像、术语表、基线规格
- 避免"边补 specs 边改行为"
- 建立最小验证锚点

**使用场景**：
- 存量项目接入 DevBooks
- 建立基线 specs
- 生成项目画像

**调用方式**：
```bash
/devbooks-brownfield-bootstrap
```

**输出**：
- `project-profile.md`：项目画像
- `glossary.md`：术语表
- 基线规格
- 最小验证锚点

**关键约束**：
- 只在真理目录为空时运行

---

## 完整闭环

### devbooks-delivery-workflow

**角色**：Delivery Workflow（完整交付工作流）

**特色**：
- 完整闭环编排器
- 在支持子 Agent 的 AI 编程工具中调用
- 自动编排 Proposal → Design → Spec → Plan → Test → Implement → Review → Archive 全流程

**使用场景**：
- 自动化完整工作流
- 从头到尾跑完闭环

**调用方式**：
```bash
/devbooks-delivery-workflow
```

**输出**：
- 完整的变更包
- 所有阶段的产物

**关键约束**：
- 需要 AI 工具支持子 Agent

---

## Skill 对比表

| Skill | 阶段 | 角色 | 独立对话 | 主要产物 |
|-------|------|------|----------|----------|
| devbooks-router | 入口 | 引导 | 否 | 路径建议 |
| devbooks-proposal-author | Proposal | Author | 否 | proposal.md |
| devbooks-proposal-challenger | Proposal | Challenger | 否 | 质疑报告 |
| devbooks-proposal-judge | Proposal | Judge | 否 | Decision Log |
| devbooks-design-doc | Design | Design Owner | 否 | design.md |
| devbooks-spec-contract | Spec | Spec Owner | 否 | spec.md |
| devbooks-implementation-plan | Plan | Planner | 否 | tasks.md |
| devbooks-test-owner | Test | Test Owner | 是 | tests/ + verification.md |
| devbooks-test-reviewer | Review | Test Reviewer | 否 | 测试评审报告 |
| devbooks-coder | Implement | Coder | 是 | 实现代码 + Green 证据 |
| devbooks-reviewer | Review | Reviewer | 否 | 代码评审报告 |
| devbooks-archiver | Archive | Archiver | 否 | 归档变更包 |
| devbooks-docs-consistency | Archive | Docs Checker | 否 | 文档一致性报告 |
| devbooks-impact-analysis | Quality | Analyzer | 否 | 影响分析报告 |
| devbooks-convergence-audit | Quality | Auditor | 否 | 收敛性报告 |
| devbooks-entropy-monitor | Quality | Monitor | 否 | 熵度量报告 |
| devbooks-brownfield-bootstrap | Init | Bootstrap | 否 | 项目画像 + 基线 |
| devbooks-delivery-workflow | Full | Orchestrator | 否 | 完整变更包 |

---

## 使用建议

### 最小工作流

如果只想快速开始，最小工作流是：

```bash
1. /devbooks-design-doc
2. /devbooks-test-owner（独立对话）
3. /devbooks-coder（独立对话）
4. /devbooks-archiver
```

### 完整工作流

如果要严格遵循 DevBooks 规范：

```bash
1. /devbooks-proposal-author
2. /devbooks-proposal-challenger
3. /devbooks-proposal-judge
4. /devbooks-design-doc
5. /devbooks-spec-contract
6. /devbooks-implementation-plan
7. /devbooks-test-owner（独立对话）
8. /devbooks-coder（独立对话）
9. /devbooks-reviewer
10. /devbooks-archiver
```

### 存量项目工作流

如果是存量项目接入：

```bash
1. /devbooks-brownfield-bootstrap
2. /devbooks-convergence-audit
3. 开始正常工作流
```

---

## 总结

DevBooks 提供 19 个 Skills，覆盖从提案到归档的完整工作流：

- **入口引导**：router
- **提案阶段**：proposal-author, proposal-challenger, proposal-judge
- **设计阶段**：design-doc, design-backport
- **规格阶段**：spec-contract
- **计划阶段**：implementation-plan
- **测试阶段**：test-owner, test-reviewer
- **实现阶段**：coder
- **评审阶段**：reviewer
- **归档阶段**：archiver, docs-consistency
- **质量保证**：impact-analysis, convergence-audit, entropy-monitor
- **存量项目**：brownfield-bootstrap
- **完整闭环**：delivery-workflow

每个 Skill 都有明确的角色定位和约束，组合使用可以构建高质量的 AI 辅助开发工作流。

---

**相关文档**：
- [使用指南](./使用指南.md)
