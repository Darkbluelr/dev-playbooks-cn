# 规格：文档风格偏好持久化

## ADDED Requirements

### Requirement: REQ-PERSIST-001 创建文档维护元数据文件

**描述**: 在 `dev-playbooks/specs/_meta/docs-maintenance.md` 创建文档维护元数据文件,记录文档风格偏好。

**理由**: 文档风格偏好应该持久化在版本控制中,避免每次都需要重新配置。

**优先级**: P0

**关联 AC**: AC-011

**依赖**: 无

**约束**:
- 文件格式为 YAML front matter + Markdown
- 包含 `style_preferences` 字段
- 版本控制跟踪


#### Scenario: SC-PERSIST-001-AUTO 创建文档维护元数据文件 最小场景

- **Given**: 需求 PERSIST-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-PERSIST-002 风格偏好字段

**描述**: `docs-maintenance.md` 包含 `use_emoji: false` 和 `use_fancy_words: false` 字段。

**理由**: 明确项目不使用 emoji 和浮夸词语的风格偏好。

**优先级**: P0

**关联 AC**: AC-011

**依赖**: REQ-PERSIST-001

**约束**:
- 字段名称统一
- 字段值类型正确(boolean)
- 默认值合理


#### Scenario: SC-PERSIST-002-AUTO 风格偏好字段 最小场景

- **Given**: 需求 PERSIST-002 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-PERSIST-003 风格偏好优先级

**描述**: 风格偏好优先级为: 命令行参数 > 配置文件 > 默认值。

**理由**: 提供灵活性,允许临时覆盖配置。

**优先级**: P1

**关联 AC**: AC-011

**依赖**: REQ-PERSIST-001

**约束**:
- 优先级逻辑清晰
- 覆盖行为可预测
- 不产生歧义


#### Scenario: SC-PERSIST-001 创建文档维护元数据文件

**关联需求**: REQ-PERSIST-001

**Given**:
- 目录 `dev-playbooks/specs/_meta/` 存在
- 文件 `docs-maintenance.md` 不存在

**When**:
- 创建文件

**Then**:
- 文件路径: `dev-playbooks/specs/_meta/docs-maintenance.md`
- 文件包含 YAML front matter
- 文件包含 Markdown 说明

**验收标准**:
- 文件存在
- 格式正确
- 内容完整

#### Scenario: SC-PERSIST-002 文档维护元数据内容

**关联需求**: REQ-PERSIST-001, REQ-PERSIST-002

**Given**:
- 创建 `docs-maintenance.md`

**When**:
- 检查文件内容

**Then**:
- 包含 `version: 1.0`
- 包含 `style_preferences:` 部分
- 包含 `use_emoji: false`
- 包含 `use_fancy_words: false`
- 包含 `forbidden_words: [...]` 列表

**验收标准**:
- 所有必需字段存在
- 字段值正确
- 格式符合 YAML 规范

#### Scenario: SC-PERSIST-003 验证文档维护元数据存在

**关联需求**: REQ-PERSIST-001

**Given**:
- 文件已创建

**When**:
- 运行验证命令: `test -f dev-playbooks/specs/_meta/docs-maintenance.md`

**Then**:
- 命令返回成功(退出码 0)

**验收标准**:
- 文件存在
- 路径正确

#### Scenario: SC-PERSIST-004 验证 style_preferences 字段存在

**关联需求**: REQ-PERSIST-002

**Given**:
- 文件已创建

**When**:
- 运行验证命令: `grep -q "style_preferences" dev-playbooks/specs/_meta/docs-maintenance.md`

**Then**:
- 命令返回成功(退出码 0)

**验收标准**:
- 字段存在
- 字段名称正确

#### Scenario: SC-PERSIST-005 命令行参数覆盖配置文件

**关联需求**: REQ-PERSIST-003

**Given**:
- 配置文件设置 `use_emoji: false`
- 命令行参数 `--use-emoji`

**When**:
- 运行文档一致性检查

**Then**:
- 使用命令行参数值(允许 emoji)
- 忽略配置文件值
- 输出说明使用了命令行参数

**验收标准**:
- 优先级正确
- 行为符合预期
- 输出清晰

#### Scenario: SC-PERSIST-006 配置文件覆盖默认值

**关联需求**: REQ-PERSIST-003

**Given**:
- 配置文件设置 `use_emoji: false`
- 无命令行参数
- 默认值为 `use_emoji: true`

**When**:
- 运行文档一致性检查

**Then**:
- 使用配置文件值(不允许 emoji)
- 忽略默认值

**验收标准**:
- 优先级正确
- 行为符合预期

#### Scenario: SC-PERSIST-007 使用默认值

**关联需求**: REQ-PERSIST-003

**Given**:
- 无配置文件
- 无命令行参数
- 默认值为 `use_emoji: true`

**When**:
- 运行文档一致性检查

**Then**:
- 使用默认值(允许 emoji)

**验收标准**:
- 默认值正确应用
- 行为符合预期

#### Scenario: SC-PERSIST-008 禁用词列表

**关联需求**: REQ-PERSIST-002

**Given**:
- 配置文件包含 `forbidden_words: ["智能", "高效", "强大"]`
- 文档包含"这是一个智能的解决方案"

**When**:
- 运行文档一致性检查

**Then**:
- 检测到违规词语"智能"
- 输出警告
- 建议修改

**验收标准**:
- 禁用词列表正确加载
- 检测逻辑正确
- 警告信息清晰

#### Scenario: SC-PERSIST-009 文档维护元数据版本控制

**关联需求**: REQ-PERSIST-001

**Given**:
- `docs-maintenance.md` 已创建
- Git 仓库存在

**When**:
- 提交文件到版本控制

**Then**:
- 文件被 git 跟踪
- 可以查看历史变更
- 可以回滚到旧版本

**验收标准**:
- 文件在版本控制中
- 历史记录可查
- 回滚功能正常
