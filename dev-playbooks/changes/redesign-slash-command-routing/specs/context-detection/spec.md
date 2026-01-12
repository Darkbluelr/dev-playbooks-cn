# Spec Delta: Context Detection

---
capability: context-detection
owner: Spec Owner
status: Draft
created: 2026-01-12
last_verified: 2026-01-12
freshness_check: 1 Month
---

> 产物落点：`dev-playbooks/changes/redesign-slash-command-routing/specs/context-detection/spec.md`

---

## ADDED Requirements

### Requirement: REQ-CD-001 上下文检测模板

系统 SHALL 提供 `skills/_shared/context-detection-template.md`，定义上下文检测的标准规则。

Trace: AC-011

#### Scenario: SC-CD-001-01 验证模板存在

- **GIVEN** DevBooks 已安装
- **WHEN** 检查 `skills/_shared/context-detection-template.md`
- **THEN** 文件存在且包含完整性判断规则

---

### Requirement: REQ-CD-002 产物存在性检测

Skill 执行时 SHALL 自动检测变更包内产物的存在性：
- `<change-root>/<change-id>/specs/` 不存在 → "从零创建"模式
- 存在但不完整 → "补漏"模式
- 存在且完整 → "同步到真理源"模式

Trace: AC-004, AC-005

#### Scenario: SC-CD-002-01 从零创建模式

- **GIVEN** `<change-root>/<change-id>/specs/` 目录不存在
- **WHEN** 执行 `devbooks-spec-contract`
- **THEN** 输出"运行模式：从零创建"

#### Scenario: SC-CD-002-02 补漏模式

- **GIVEN** `<change-root>/<change-id>/specs/` 目录存在
- **AND** spec.md 中存在 `[TODO]` 占位符
- **WHEN** 执行 `devbooks-spec-contract`
- **THEN** 输出"运行模式：补漏"

#### Scenario: SC-CD-002-03 同步模式

- **GIVEN** `<change-root>/<change-id>/specs/` 目录存在
- **AND** spec.md 完整（无占位符，所有 Req 有 Scenario，所有 Scenario 有 Given/When/Then）
- **WHEN** 执行 `devbooks-spec-contract`
- **THEN** 输出"运行模式：同步到真理源"

---

### Requirement: REQ-CD-003 完整性判断规则

完整性判断 SHALL 按 Requirement 分组校验：
1. 每个 REQ-xxx 必须至少有一个 Scenario
2. 每个 Scenario 必须有 Given/When/Then
3. 不存在占位符（`[TODO]`、`[待补充]`）

Trace: AC-004, AC-011

#### Scenario: SC-CD-003-01 空文件

- **GIVEN** spec.md 文件为空
- **WHEN** 执行完整性检查
- **THEN** 判定为"完整"（无 Req 需校验）

| # | 场景 | spec.md 内容 | 期望结果 |
|---|------|-------------|----------|
| 1 | 空文件 | 无内容 | 完整（无 Req 需校验） |
| 2 | 单 Req 无 Scenario | `### Requirement: REQ-001` | 不完整：REQ-001 缺少 Scenario |
| 3 | 单 Req 单 Scenario 完整 | REQ-001 + Scenario + Given/When/Then | 完整 |
| 4 | 单 Req 单 Scenario 缺 Then | REQ-001 + Scenario + Given/When | 不完整：缺少 Then |
| 5 | 多 Req 部分完整 | REQ-001 完整 + REQ-002 缺 Scenario | 不完整：REQ-002 缺少 Scenario |
| 6 | 含占位符 | REQ-001 完整 + `[TODO]` | 不完整：存在占位符 |
| 7 | Scenario 跨 Req 误判 | REQ-001 无 Scenario + REQ-002 有 Scenario | 不完整：REQ-001 缺少 Scenario |

---

### Requirement: REQ-CD-004 当前阶段检测

Skill 执行时 SHALL 根据已有文件推断当前阶段：
- 只有 proposal.md → proposal 阶段
- 有 design.md + tasks.md → apply 阶段
- 有 verification.md + 测试通过 → archive 阶段

Trace: AC-004, AC-005

#### Scenario: SC-CD-004-01 proposal 阶段检测

- **GIVEN** 变更包只有 `proposal.md`
- **WHEN** Skill 执行上下文检测
- **THEN** 输出"当前阶段：proposal"

#### Scenario: SC-CD-004-02 apply 阶段检测

- **GIVEN** 变更包有 `proposal.md`、`design.md`、`tasks.md`
- **WHEN** Skill 执行上下文检测
- **THEN** 输出"当前阶段：apply"

---

### Requirement: REQ-CD-005 C4 上下文检测

`devbooks-c4-map` 执行时 SHALL 自动检测 c4.md 存在性：
- `<truth-root>/architecture/c4.md` 不存在 → "新增 delta"模式
- 存在 → "更新真理"模式

Trace: AC-005

#### Scenario: SC-CD-005-01 新增 delta 模式

- **GIVEN** `dev-playbooks/specs/architecture/c4.md` 不存在
- **WHEN** 执行 `devbooks-c4-map`
- **THEN** 输出"运行模式：新增 delta"

---

## 追溯摘要

| AC-xxx | Requirement | 说明 |
|--------|-------------|------|
| AC-004 | REQ-CD-002, REQ-CD-003, REQ-CD-004 | spec-contract 自动检测模式 |
| AC-005 | REQ-CD-002, REQ-CD-004, REQ-CD-005 | c4-map 自动检测模式 |
| AC-011 | REQ-CD-001, REQ-CD-003 | context-detection-template.md 存在且完整 |
