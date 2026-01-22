---
last_referenced_by: 20260122-0827-enhance-docs-consistency
last_verified: 2026-01-23
health: active
---

# 规格：Skills 集成

## ADDED Requirements

### Requirement: REQ-INTEG-001 devbooks-archiver 集成

**描述**: `devbooks-archiver` 在归档前调用 `devbooks-docs-consistency` 检查文档一致性。

**理由**: 归档前确保文档与代码一致,避免归档不完整的变更包。

**优先级**: P0

**关联 AC**: AC-007

**依赖**: REQ-CORE-001

**约束**:
- 集成调用不阻塞归档流程
- 检查结果记录到 evidence/
- 调用使用新名称


#### Scenario: SC-INTEG-001-AUTO devbooks-archiver 集成 最小场景

- **Given**: 需求 INTEG-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-INTEG-002 devbooks-brownfield-bootstrap 集成

**描述**: `devbooks-brownfield-bootstrap` 初始化时生成 `docs-maintenance.md` 元数据文件。

**理由**: 存量项目初始化时需要建立文档维护基线。

**优先级**: P0

**关联 AC**: AC-007

**依赖**: REQ-CORE-001

**约束**:
- 生成默认配置
- 配置格式正确
- 路径正确


#### Scenario: SC-INTEG-002-AUTO devbooks-brownfield-bootstrap 集成 最小场景

- **Given**: 需求 INTEG-002 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-INTEG-003 devbooks-proposal-author 集成

**描述**: `devbooks-proposal-author` 包含 Challenger 审视部分,引用完备性思维框架。

**理由**: 提案阶段需要考虑完备性,避免遗漏关键约束。

**优先级**: P1

**关联 AC**: AC-007

**依赖**: REQ-METH-001

**约束**:
- 引用路径正确
- 引用上下文清晰
- 不破坏现有流程


#### Scenario: SC-INTEG-001 archiver 归档前检查文档

**关联需求**: REQ-INTEG-001

**Given**:
- 用户运行 `devbooks-archiver` 归档变更包
- 变更包文档存在不一致

**When**:
- archiver 调用 `devbooks-docs-consistency`

**Then**:
- 执行文档一致性检查
- 输出警告信息
- 生成检查报告到 `evidence/docs-consistency-report.md`
- 归档流程继续(不阻塞)

**验收标准**:
- 检查正确执行
- 警告正确显示
- 报告正确生成
- 归档流程不中断

#### Scenario: SC-INTEG-002 archiver 调用使用新名称

**关联需求**: REQ-INTEG-001

**Given**:
- `skills/devbooks-archiver/skill.md` 需要更新
- 当前调用 `devbooks-docs-sync`

**When**:
- 更新集成调用代码

**Then**:
- 调用改为 `devbooks-docs-consistency`
- 功能正常工作
- 无弃用警告

**验收标准**:
- 调用名称正确
- 功能正常
- 无警告信息

#### Scenario: SC-INTEG-003 brownfield-bootstrap 生成元数据

**关联需求**: REQ-INTEG-002

**Given**:
- 用户在存量项目运行 `devbooks-brownfield-bootstrap`
- 项目根目录为 `/project`

**When**:
- bootstrap 执行初始化

**Then**:
- 生成 `/project/dev-playbooks/specs/_meta/docs-maintenance.md`
- 文件包含默认配置
- 配置格式正确

**验收标准**:
- 文件路径正确
- 文件内容正确
- 配置格式符合 schema

#### Scenario: SC-INTEG-004 brownfield-bootstrap 生成的配置内容

**关联需求**: REQ-INTEG-002

**Given**:
- bootstrap 生成 `docs-maintenance.md`

**When**:
- 检查文件内容

**Then**:
- 包含 `version: 1.0`
- 包含 `style_preferences`
- 包含 `use_emoji: false`
- 包含 `use_fancy_words: false`

**验收标准**:
- 所有必需字段存在
- 字段值合理
- 格式正确

#### Scenario: SC-INTEG-005 proposal-author 包含 Challenger 审视

**关联需求**: REQ-INTEG-003

**Given**:
- `skills/devbooks-proposal-author/skill.md` 需要更新

**When**:
- 更新 skill.md

**Then**:
- 添加 Challenger 审视章节
- 引用完备性思维框架
- 说明如何审视提案完备性

**验收标准**:
- 章节内容清晰
- 引用路径正确
- 流程合理

#### Scenario: SC-INTEG-006 验证 archiver 集成

**关联需求**: REQ-INTEG-001

**Given**:
- `skills/devbooks-archiver/skill.md` 已更新

**When**:
- 运行验证命令: `grep -q "devbooks-docs-consistency" skills/devbooks-archiver/skill.md`

**Then**:
- 命令返回成功(退出码 0)

**验收标准**:
- 集成调用存在
- 调用名称正确
