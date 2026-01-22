---
last_referenced_by: 20260122-0827-enhance-docs-consistency
last_verified: 2026-01-23
health: active
---

# 规格：专家角色声明机制

## ADDED Requirements

### Requirement: REQ-EXPERT-001 Skill 包含专家角色字段

**描述**: 每个 skill.md 包含 `recommended_experts` 字段,声明推荐的专家角色。

**理由**: 明确每个 skill 适合的专家角色,帮助 AI 选择合适的角色执行任务。

**优先级**: P0

**关联 AC**: AC-010

**依赖**: 无

**约束**:
- 字段格式统一
- 专家角色来自标准列表
- 至少声明 1 个专家角色


#### Scenario: SC-EXPERT-001-AUTO Skill 包含专家角色字段 最小场景

- **Given**: 需求 EXPERT-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-EXPERT-002 AI 行为规范包含角色声明协议

**描述**: `skills/_shared/references/AI行为规范.md` 包含专家角色声明协议,说明如何使用 `recommended_experts` 字段。

**理由**: 统一 AI 使用专家角色的方式,确保一致性。

**优先级**: P0

**关联 AC**: AC-010

**依赖**: REQ-EXPERT-001

**约束**:
- 协议清晰易懂
- 包含使用示例
- 说明角色选择逻辑


#### Scenario: SC-EXPERT-002-AUTO AI 行为规范包含角色声明协议 最小场景

- **Given**: 需求 EXPERT-002 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-EXPERT-003 专家列表文档

**描述**: 创建 `skills/_shared/references/专家列表.md`,列出所有可用的专家角色及其职责。

**理由**: 提供标准专家角色列表,避免角色命名不一致。

**优先级**: P0

**关联 AC**: AC-010

**依赖**: 无

**约束**:
- 列表完整
- 职责描述清晰
- 包含使用场景


#### Scenario: SC-EXPERT-001 Skill 声明专家角色

**关联需求**: REQ-EXPERT-001

**Given**:
- `skills/devbooks-proposal-author/skill.md` 需要声明专家角色

**When**:
- 添加 `recommended_experts` 字段

**Then**:
- 字段内容: `["Product Manager", "System Architect"]`
- 字段位置在 skill 元信息部分
- 格式正确

**验收标准**:
- 字段存在
- 格式正确
- 专家角色合理

#### Scenario: SC-EXPERT-002 验证专家角色字段存在

**关联需求**: REQ-EXPERT-001

**Given**:
- 所有 skills 已更新

**When**:
- 运行验证命令: `grep -q "recommended_experts" skills/devbooks-proposal-author/skill.md`

**Then**:
- 命令返回成功(退出码 0)

**验收标准**:
- 字段存在
- 验证命令正确

#### Scenario: SC-EXPERT-003 AI 行为规范包含角色声明协议

**关联需求**: REQ-EXPERT-002

**Given**:
- `skills/_shared/references/AI行为规范.md` 需要更新

**When**:
- 添加专家角色声明协议章节

**Then**:
- 章节标题: "## 专家角色声明协议"
- 说明如何读取 `recommended_experts` 字段
- 说明如何选择合适的角色
- 包含使用示例

**验收标准**:
- 章节内容完整
- 说明清晰
- 示例正确

#### Scenario: SC-EXPERT-004 创建专家列表文档

**关联需求**: REQ-EXPERT-003

**Given**:
- 需要创建专家列表文档

**When**:
- 创建 `skills/_shared/references/专家列表.md`

**Then**:
- 文件包含所有标准专家角色
- 每个角色有职责描述
- 每个角色有使用场景说明

**验收标准**:
- 文件存在
- 内容完整
- 格式正确

#### Scenario: SC-EXPERT-005 专家列表包含常用角色

**关联需求**: REQ-EXPERT-003

**Given**:
- 专家列表文档已创建

**When**:
- 检查文档内容

**Then**:
- 包含角色: Product Manager, System Architect, Test Engineer, Security Expert, Performance Engineer
- 每个角色有清晰的职责描述
- 每个角色有使用场景示例

**验收标准**:
- 所有常用角色都有
- 职责描述清晰
- 使用场景合理

#### Scenario: SC-EXPERT-006 AI 根据专家角色选择行为

**关联需求**: REQ-EXPERT-002

**Given**:
- Skill 声明 `recommended_experts: ["System Architect"]`
- AI 执行该 skill

**When**:
- AI 读取专家角色字段

**Then**:
- AI 采用 System Architect 角色
- 输出符合该角色的专业性
- 关注架构层面的问题

**验收标准**:
- AI 正确识别角色
- 行为符合角色定位
- 输出质量提升

#### Scenario: SC-EXPERT-007 多个专家角色的处理

**关联需求**: REQ-EXPERT-001

**Given**:
- Skill 声明 `recommended_experts: ["Product Manager", "System Architect"]`

**When**:
- AI 执行该 skill

**Then**:
- AI 综合两个角色的视角
- 既关注业务价值(Product Manager)
- 又关注技术架构(System Architect)

**验收标准**:
- AI 正确处理多角色
- 输出综合两个视角
- 不偏废任一角色
