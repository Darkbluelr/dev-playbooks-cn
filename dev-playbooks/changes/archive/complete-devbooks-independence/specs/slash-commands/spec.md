# Spec Delta: slash-commands (complete-devbooks-independence)

> 产物落点：`dev-playbooks/changes/complete-devbooks-independence/specs/slash-commands/spec.md`
>
> 状态：**Merged**（已合并到真理源 `dev-playbooks/specs/slash-commands/spec.md`）
> Owner：Spec Owner
> last_verified：2026-01-12
> merged_by：Spec Gardener
> merge_date：2026-01-12

---

## ADDED Requirements

### Requirement: REQ-SLASH-001 DevBooks 原生 Slash 命令体系

系统 SHALL 提供以 `/devbooks:` 为前缀的原生 Slash 命令体系，支持完整的变更管理工作流。

**命令清单**：

| 命令 | 触发的 Skills | 用途 |
|------|---------------|------|
| `/devbooks:proposal` | devbooks-proposal-author | 启动提案阶段 |
| `/devbooks:design` | devbooks-design-doc | 设计阶段 |
| `/devbooks:apply` | devbooks-test-owner / devbooks-coder | 实现阶段 |
| `/devbooks:review` | devbooks-code-review | 评审阶段 |
| `/devbooks:archive` | devbooks-spec-gardener | 归档阶段 |
| `/devbooks:router` | devbooks-router | 智能路由 |
| `/devbooks:quick` | proposal → apply → archive | 快速模式 |

**Trace**: AC-005, AC-006, AC-007, AC-008, AC-009, AC-010

---

### Requirement: REQ-SLASH-002 Apply 阶段角色子命令

`/devbooks:apply` 命令 SHALL 支持 `--role` 参数，允许用户指定执行角色。

**可选角色**：
- `test-owner`：执行 devbooks-test-owner
- `coder`：执行 devbooks-coder
- `reviewer`：执行 devbooks-code-review（评审模式）

**约束**：
- 若 `role_isolation: true`，系统 SHALL 阻止在同一会话中切换 test-owner 和 coder 角色

**Trace**: AC-007

---

### Requirement: REQ-SLASH-003 快速模式量化边界

`/devbooks:quick` 命令 SHALL 仅适用于满足以下条件的小变更：
- 影响文件数 ≤ 5 个
- 无跨模块变更
- 无对外接口变更
- 无需 AC 追溯

系统 SHOULD 在条件不满足时提示用户使用完整流程。

**Trace**: AC-010

---

## REMOVED Requirements

### Requirement: REQ-SLASH-R01 移除 OpenSpec Slash 命令

系统 SHALL 移除以下命令：
- `/openspec:proposal`
- `/openspec:apply`
- `/openspec:archive`

**不提供向后兼容别名**。

**Trace**: AC-001, AC-003

---

## Scenarios

### Scenario: SC-SLASH-001 用户启动提案阶段

- **GIVEN** 用户在 Claude Code 会话中
- **WHEN** 用户输入 `/devbooks:proposal`
- **THEN** 系统加载 devbooks-proposal-author Skill
- **AND** 系统提示用户提供变更背景信息

**Trace**: AC-005

---

### Scenario: SC-SLASH-002 用户执行快速模式

- **GIVEN** 用户有一个小型变更（≤ 5 个文件，无跨模块）
- **WHEN** 用户输入 `/devbooks:quick`
- **THEN** 系统依次执行 proposal → apply → archive
- **AND** 跳过 design 和 review 阶段

**Trace**: AC-010

---

### Scenario: SC-SLASH-003 快速模式边界检查失败

- **GIVEN** 用户有一个大型变更（> 5 个文件 或 跨模块）
- **WHEN** 用户输入 `/devbooks:quick`
- **THEN** 系统输出警告提示
- **AND** 建议用户使用完整流程（proposal → design → apply → review → archive）

**Trace**: AC-010

---

### Scenario: SC-SLASH-004 角色隔离强制执行

- **GIVEN** 配置 `role_isolation: true`
- **AND** 用户在当前会话已执行 `/devbooks:apply --role test-owner`
- **WHEN** 用户尝试执行 `/devbooks:apply --role coder`
- **THEN** 系统拒绝执行
- **AND** 提示用户在新会话中执行 coder 角色

**Trace**: AC-007

---

### Scenario: SC-SLASH-005 旧命令不可用

- **GIVEN** 用户在已升级到 DevBooks 2.0 的项目中
- **WHEN** 用户输入 `/openspec:proposal`
- **THEN** 系统提示命令不存在
- **AND** 建议使用 `/devbooks:proposal`

**Trace**: AC-003
