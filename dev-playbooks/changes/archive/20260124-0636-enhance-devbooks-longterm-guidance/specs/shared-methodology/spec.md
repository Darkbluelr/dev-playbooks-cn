---
last_referenced_by: 20260124-0636-enhance-devbooks-longterm-guidance
last_verified: 2026-01-24
health: active
---

# 规格：共享方法论文档

## ADDED Requirements

### Requirement: REQ-METH-001 提取完备性思维框架

**描述**: 将 `/Users/ozbombor/Projects/dev-playbooks-cn/如何构建完备的系统.md` 迁移到 `skills/_shared/references/完备性思维框架.md`。

**理由**: 完备性思维框架是通用方法论,应该作为共享文档供多个 skills 引用。

**优先级**: P0

**关联 AC**: AC-006

**依赖**: 无

**约束**:
- 内容完整迁移
- 格式保持一致
- 至少 3 个 skills 引用该文档


#### Scenario: SC-METH-001-AUTO 提取完备性思维框架 最小场景

- **Given**: 需求 METH-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-METH-002 Skills 引用共享文档

**描述**: 至少 3 个 skills 在其 skill.md 中引用完备性思维框架文档。

**理由**: 确保共享文档被实际使用,避免成为孤立文档。

**优先级**: P0

**关联 AC**: AC-006

**依赖**: REQ-METH-001

**约束**:
- 引用路径正确
- 引用上下文清晰
- 引用方式一致


#### Scenario: SC-METH-001 迁移完备性思维框架文档

**关联需求**: REQ-METH-001

**Given**:
- 源文件 `/Users/ozbombor/Projects/dev-playbooks-cn/如何构建完备的系统.md` 存在
- 目标目录 `skills/_shared/references/` 存在

**When**:
- 执行文档迁移

**Then**:
- 文件复制到 `skills/_shared/references/完备性思维框架.md`
- 内容完整保留
- 格式正确

**验收标准**:
- 目标文件存在
- 内容与源文件一致
- 格式无破坏

#### Scenario: SC-METH-002 devbooks-docs-consistency 引用共享文档

**关联需求**: REQ-METH-002

**Given**:
- 完备性思维框架文档已迁移
- `skills/devbooks-docs-consistency/skill.md` 存在

**When**:
- 更新 skill.md

**Then**:
- 添加引用: "参考 `skills/_shared/references/完备性思维框架.md`"
- 引用上下文清晰(在完备性检查章节)

**验收标准**:
- 引用路径正确
- 引用位置合适
- 上下文清晰

#### Scenario: SC-METH-003 devbooks-proposal-author 引用共享文档

**关联需求**: REQ-METH-002

**Given**:
- 完备性思维框架文档已迁移
- `skills/devbooks-proposal-author/skill.md` 存在

**When**:
- 更新 skill.md

**Then**:
- 添加引用: "参考 `skills/_shared/references/完备性思维框架.md`"
- 引用上下文清晰(在 Challenger 审视章节)

**验收标准**:
- 引用路径正确
- 引用位置合适
- 上下文清晰

#### Scenario: SC-METH-004 devbooks-design-doc 引用共享文档

**关联需求**: REQ-METH-002

**Given**:
- 完备性思维框架文档已迁移
- `skills/devbooks-design-doc/skill.md` 存在

**When**:
- 更新 skill.md

**Then**:
- 添加引用: "参考 `skills/_shared/references/完备性思维框架.md`"
- 引用上下文清晰(在约束定义章节)

**验收标准**:
- 引用路径正确
- 引用位置合适
- 上下文清晰

#### Scenario: SC-METH-005 验证引用数量

**关联需求**: REQ-METH-002

**Given**:
- 完备性思维框架文档已迁移
- 多个 skills 已更新

**When**:
- 运行验证命令: `grep -r "完备性思维框架" skills/*/skill.md | wc -l`

**Then**:
- 输出结果 >= 3

**验收标准**:
- 引用数量符合要求
- 引用分布合理

### Requirement: REQ-METH-003 长期视野/反短视机制

**描述**: 在共享方法论文档中新增“长期视野/反短视”机制,内容限定在流程、结构、文本规范、少量自检脚本入口四类要素。

**理由**: 强化长期维护与演进视角,降低短期决策偏差。

**优先级**: P0

**关联 AC**: AC-102

**依赖**: 无

**约束**:
- 四类要素必须同时出现
- 至少引用一个现有自检脚本路径(如 `skills/devbooks-delivery-workflow/scripts/change-check.sh`)
- 不扩展到运行时代码或外部依赖

**长期尺度判定（默认规则）**:
- 不以日历时长为唯一标准；以变更包生命周期与规范演进周期作为主尺度
- 命中检查清单任意两项 → 归为长期尺度；命中一项 → 记录为中期关注；未命中 → 视为短期
- 不同项目使用相同维度清单；阈值可在 `dev-playbooks/specs/_meta/project-profile.md` 或变更包 `proposal.md` 的范围说明中覆盖，未覆盖则采用默认规则
- 覆盖必须写入变更包 `proposal.md` 的 Decision Log（可追溯）

**长期尺度检查清单（流程/结构/文本规范/自检脚本入口）**:
- 流程：影响两个及以上阶段/角色的交接规则（proposal/design/spec/tasks/test-owner/coder/reviewer/archiver）
- 结构：触及真理源或变更包结构规则，或新增/修改 `skills/_shared/references/` 下的共享文档
- 文本规范：新增/修改统一模板、字段关键词或可扫描规则（如 REQ/SC/AC、三段式规则）
- 自检脚本入口：需要明确引用至少一个守门脚本入口（如 `skills/devbooks-delivery-workflow/scripts/change-check.sh` 或 `skills/devbooks-delivery-workflow/scripts/guardrail-check.sh`）

#### Scenario: SC-METH-006 长期视野机制要素齐备

**关联需求**: REQ-METH-003

**Given**:
- 共享方法论文档已更新

**When**:
- 阅读“长期视野/反短视”机制条目

**Then**:
- 条目包含流程、结构、文本规范、自检脚本入口四类要素
- 至少出现一个现有自检脚本路径

**验收标准**:
- 四类要素齐备
- 脚本路径可追溯

### Requirement: REQ-METH-004 人类建议校准提示词机制

**描述**: 共享方法论文档必须定义“人类建议校准”提示词机制,包含触发条件与固定输出格式。

**理由**: 在高影响或不确定决策时引入人工偏好校准入口。

**优先级**: P0

**关联 AC**: AC-103

**依赖**: 无

**约束**:
- 触发条件至少覆盖跨模块或对外契约变更、多方案取舍、长期维护风险、安全或合规风险
- 固定输出字段行首为“直觉价值：”“偏离最佳实践/不成熟点：”“推荐方案：”
- 不包含实现步骤

**最小提示词模板落点**:
- 参考 `skills/_shared/references/人类建议校准提示词.md`
- 共享方法论文档只引用模板，不展开实现步骤

**触发条件（可扫描）**:
- 跨模块或对外契约变更
- 多方案取舍（存在两个及以上可选方向）
- 长期维护风险（涉及共享规范、模板或守门规则）
- 安全或合规风险

**边界**:
- 不替代 proposal/design/spec 的决策记录
- 不用于纯执行型修改或低影响的格式调整
- 不输出实现步骤、命令或代码细节

#### Scenario: SC-METH-007 人类建议校准触发与输出格式

**关联需求**: REQ-METH-004

**Given**:
- 变更描述满足触发条件

**When**:
- 阅读“人类建议校准”提示词机制条目

**Then**:
- 条目明确触发条件
- 输出格式包含固定字段行首关键词

**验收标准**:
- 触发条件可扫描
- 字段格式固定且完整

### Requirement: REQ-METH-005 约束/取舍/影响三段式可扫描规则

**描述**: 共享方法论文档必须定义“约束/取舍/影响”三段式可扫描规则,用于理由、决策、取舍说明相关段落。

**理由**: 提升文档审阅可扫描性与一致性检查可操作性。

**优先级**: P0

**关联 AC**: AC-106

**依赖**: 无

**约束**:
- 同一小节内同时出现行首关键词“约束：”“取舍：”“影响：”
- 允许列表或段落格式
- 不适用于代码块、命令输出、引用块

约束：同一小节内同时出现行首关键词“约束：”“取舍：”“影响：”。
取舍：使用固定关键词便于扫描，接受表达自由度下降。
影响：规则化检查更容易，文档评审更高效。

#### Scenario: SC-METH-008 三段式规则可扫描

**关联需求**: REQ-METH-005

**Given**:
- 文档存在理由类段落

**When**:
- 执行三段式规则检查

**Then**:
- 同一小节内出现“约束：”“取舍：”“影响：”行首关键词
- 代码块、命令输出、引用块不在判定范围

**验收标准**:
- 规则可被扫描
- 非适用范围不被误判
