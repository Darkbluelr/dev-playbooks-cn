# 规格：文档一致性核心功能

## ADDED Requirements

### Requirement: REQ-CORE-001 Skill 改名与别名机制

**描述**: 将 `devbooks-docs-sync` 改名为 `devbooks-docs-consistency`,并提供别名机制确保向后兼容。

**理由**: "consistency"准确反映职责(一致性检查),"sync"暗示双向同步容易误导用户。

**优先级**: P0

**关联 AC**: AC-001

**依赖**: 无

**约束**:
- 别名机制保留 6 个月
- 调用旧名称时输出弃用警告
- 功能完全兼容,无破坏性变更


#### Scenario: SC-CORE-001-AUTO Skill 改名与别名机制 最小场景

- **Given**: 需求 CORE-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-CORE-002 自定义规则引擎

**描述**: 支持项目特定的文档规范检查,包括持续规则(配置文件)和一次性任务(命令行参数)。

**理由**: 不同项目有不同的文档规范,需要支持自定义规则。

**优先级**: P0

**关联 AC**: AC-002

**依赖**: 无

**约束**:
- 规则引擎必须幂等
- 规则执行失败不阻塞其他规则
- 提供合理默认值,零配置可用


#### Scenario: SC-CORE-002-AUTO 自定义规则引擎 最小场景

- **Given**: 需求 CORE-002 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-CORE-003 增量扫描

**描述**: 利用 git 历史只扫描变更文件,减少 token 消耗 90%。

**理由**: 全量扫描在大型项目中 token 消耗过高,不可持续。

**优先级**: P0

**关联 AC**: AC-003, AC-012

**依赖**: Git 仓库

**约束**:
- 增量扫描 token 消耗 < 全量扫描 20%
- 扫描时间 < 10 秒
- 增量扫描失败时自动回退到全量扫描
- 不能遗漏任何变更文件


#### Scenario: SC-CORE-001 用户调用旧名称 devbooks-docs-sync

**关联需求**: REQ-CORE-001

**Given**:
- 用户在命令行调用 `devbooks-docs-sync`
- 别名机制已配置

**When**:
- 系统接收到调用请求

**Then**:
- 重定向到 `devbooks-docs-consistency`
- 输出弃用警告: "devbooks-docs-sync 已弃用,请使用 devbooks-docs-consistency"
- 功能正常执行

**验收标准**:
- 调用成功完成
- 警告信息正确显示
- 功能行为与新名称完全一致

#### Scenario: SC-CORE-002 用户配置持续规则

**关联需求**: REQ-CORE-002

**Given**:
- 用户在 `docs-rules.yaml` 中配置规则: `forbidden_words: ["智能", "高效"]`
- 文档中包含 "这是一个智能的解决方案"

**When**:
- 运行文档一致性检查

**Then**:
- 检测到违反规则
- 输出警告: "文档包含禁用词语: 智能"
- 提供修复建议

**验收标准**:
- 规则正确解析
- 违规内容正确检测
- 警告信息清晰

#### Scenario: SC-CORE-003 用户执行一次性清理任务

**关联需求**: REQ-CORE-002

**Given**:
- 用户需要删除所有文档中的 `@augment` 引用
- 多个文档包含 `@augment` 引用

**When**:
- 运行命令: `devbooks-docs-consistency --once "remove:@augment"`

**Then**:
- 扫描所有文档
- 检测所有 `@augment` 引用
- 输出清理报告

**验收标准**:
- 所有 `@augment` 引用被检测
- 报告包含文件路径和行号
- 不修改文件(只检查)

#### Scenario: SC-CORE-004 增量扫描检测变更文件

**关联需求**: REQ-CORE-003

**Given**:
- Git 仓库存在
- 自上次扫描以来修改了 3 个文档文件
- 项目共有 100 个文档文件

**When**:
- 运行增量扫描

**Then**:
- 只扫描 3 个变更文件
- Token 消耗 < 全量扫描 20%
- 扫描时间 < 10 秒
- 记录 token 消耗到 `evidence/token-usage.log`

**验收标准**:
- 只处理变更文件
- Token 消耗符合预期
- 扫描时间符合预期
- 日志正确记录

#### Scenario: SC-CORE-005 增量扫描失败回退到全量扫描

**关联需求**: REQ-CORE-003

**Given**:
- Git 仓库不存在或 git diff 失败
- 用户运行增量扫描

**When**:
- 系统检测到 git 不可用

**Then**:
- 输出警告: "增量扫描失败,回退到全量扫描"
- 自动执行全量扫描
- 功能正常完成

**验收标准**:
- 降级机制正确触发
- 警告信息清晰
- 全量扫描正常执行

#### Scenario: SC-CORE-006 规则引擎幂等性

**关联需求**: REQ-CORE-002

**Given**:
- 配置规则: `remove:@augment`
- 文档已经不包含 `@augment`

**When**:
- 多次运行规则检查

**Then**:
- 每次检查结果一致
- 不产生重复警告
- 不修改已清理的文档

**验收标准**:
- 规则执行结果幂等
- 无重复操作
- 无副作用

#### Scenario: SC-CORE-007 零配置可用

**关联需求**: REQ-CORE-002

**Given**:
- 用户未配置任何规则文件
- 首次运行文档一致性检查

**When**:
- 运行 `devbooks-docs-consistency`

**Then**:
- 使用默认规则
- 检查基本文档一致性
- 功能正常工作

**验收标准**:
- 无需配置即可运行
- 默认规则合理
- 输出有用的检查结果
