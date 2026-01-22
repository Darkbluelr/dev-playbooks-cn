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
