---
last_referenced_by: 20260122-0827-enhance-docs-consistency
last_verified: 2026-01-23
health: active
---

# 规格：文档分类

## ADDED Requirements

### Requirement: REQ-CLASS-001 文档类型分类

**描述**: 区分活体文档(README.md、docs/*.md)、历史文档(CHANGELOG.md)、概念性文档(architecture/*.md)。

**理由**: 不同类型文档的检查策略不同,需要准确分类。

**优先级**: P0

**关联 AC**: AC-005

**依赖**: 无

**约束**:
- 分类规则可配置
- 默认分类规则合理
- 分类结果准确


#### Scenario: SC-CLASS-001-AUTO 文档类型分类 最小场景

- **Given**: 需求 CLASS-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-CLASS-002 分类规则可配置

**描述**: 文档分类规则可通过配置文件自定义。

**理由**: 不同项目的文档组织方式不同。

**优先级**: P1

**关联 AC**: AC-005

**依赖**: REQ-CLASS-001

**约束**:
- 配置格式清晰
- 支持路径模式匹配
- 提供默认配置


#### Scenario: SC-CLASS-001 识别活体文档

**关联需求**: REQ-CLASS-001

**Given**:
- 文件路径为 `README.md`
- 运行文档分类

**When**:
- 系统分析文件路径

**Then**:
- 分类为"活体文档"
- 应用完整检查策略

**验收标准**:
- 分类结果正确
- 检查策略正确应用

#### Scenario: SC-CLASS-002 识别历史文档

**关联需求**: REQ-CLASS-001

**Given**:
- 文件路径为 `CHANGELOG.md`
- 运行文档分类

**When**:
- 系统分析文件路径

**Then**:
- 分类为"历史文档"
- 跳过一致性检查

**验收标准**:
- 分类结果正确
- 检查策略正确应用

#### Scenario: SC-CLASS-003 识别概念性文档

**关联需求**: REQ-CLASS-001

**Given**:
- 文件路径为 `architecture/system-design.md`
- 运行文档分类

**When**:
- 系统分析文件路径

**Then**:
- 分类为"概念性文档"
- 只检查结构,不检查与代码一致性

**验收标准**:
- 分类结果正确
- 检查策略正确应用

#### Scenario: SC-CLASS-004 自定义分类规则

**关联需求**: REQ-CLASS-002

**Given**:
- 用户在 `doc-classification.yaml` 中配置: `living_docs: ["docs/**/*.md", "guides/**/*.md"]`
- 文件路径为 `guides/getting-started.md`

**When**:
- 运行文档分类

**Then**:
- 分类为"活体文档"
- 应用完整检查策略

**验收标准**:
- 自定义规则正确加载
- 分类结果正确
- 检查策略正确应用

#### Scenario: SC-CLASS-005 默认分类规则

**关联需求**: REQ-CLASS-001

**Given**:
- 用户未配置分类规则
- 文件路径为 `docs/api.md`

**When**:
- 运行文档分类

**Then**:
- 使用默认分类规则
- 分类为"活体文档"
- 应用完整检查策略

**验收标准**:
- 默认规则正确应用
- 分类结果正确
- 检查策略正确应用
