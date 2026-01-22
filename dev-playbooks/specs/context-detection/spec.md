# Spec: Context Detection

---
owner: Spec Owner
last_verified: 2026-01-12
status: Active
freshness_check: 3 Months
source_change: redesign-slash-command-routing
---

## 1. Requirements

### REQ-CD-001: 上下文检测模板

系统 SHALL 提供 `skills/_shared/context-detection-template.md`，定义上下文检测的标准规则。

**模板内容**：
- 产物存在性检测规则
- 完整性判断规则（7 个边界场景）
- 当前阶段检测规则

Trace: AC-011

---

### REQ-CD-002: 产物存在性检测

Skill 执行时 SHALL 自动检测变更包内产物的存在性，并据此选择运行模式：

| 检测结果 | 运行模式 |
|----------|----------|
| `<change-root>/<change-id>/specs/` 不存在 | 从零创建 |
| 存在但不完整（有占位符或 REQ 缺 Scenario） | 补漏模式 |
| 存在且完整 | 同步到真理源 |

Trace: AC-004, AC-005

---

### REQ-CD-003: 完整性判断规则

完整性判断 SHALL 按 Requirement 分组校验：

1. 每个 REQ-xxx 必须至少有一个 Scenario
2. 每个 Scenario 必须有 Given/When/Then
3. 不存在占位符（`[TODO]`、`[待补充]`）

**边界场景测试**：

| # | 场景 | spec.md 内容 | 期望结果 |
|---|------|-------------|----------|
| 1 | 空文件 | 无内容 | 完整（无 Req 需校验） |
| 2 | 单 Req 无 Scenario | `### Requirement: REQ-001` | 不完整：REQ-001 缺少 Scenario |
| 3 | 单 Req 单 Scenario 完整 | REQ-001 + Scenario + Given/When/Then | 完整 |
| 4 | 单 Req 单 Scenario 缺 Then | REQ-001 + Scenario + Given/When | 不完整：缺少 Then |
| 5 | 多 Req 部分完整 | REQ-001 完整 + REQ-002 缺 Scenario | 不完整：REQ-002 缺少 Scenario |
| 6 | 含占位符 | REQ-001 完整 + `[TODO]` | 不完整：存在占位符 |
| 7 | Scenario 跨 Req 误判 | REQ-001 无 Scenario + REQ-002 有 Scenario | 不完整：REQ-001 缺少 Scenario（按块分组，不误判） |

Trace: AC-004, AC-011

---

### REQ-CD-004: 当前阶段检测

Skill 执行时 SHALL 根据已有文件推断当前阶段：

| 文件状态 | 阶段判定 |
|----------|----------|
| 只有 proposal.md | proposal 阶段 |
| 有 design.md + tasks.md | apply 阶段 |
| 有 verification.md + 测试通过 | archive 阶段 |

Trace: AC-004, AC-005

---

### REQ-CD-005: C4 上下文检测

`devbooks-c4-map` 执行时 SHALL 自动检测 c4.md 存在性：

| 检测结果 | 运行模式 |
|----------|----------|
| `<truth-root>/architecture/c4.md` 不存在 | 新增 delta |
| 存在 | 更新真理 |

Trace: AC-005

---

## 2. Scenarios

### SC-CD-001: 从零创建模式

- **GIVEN** `<change-root>/<change-id>/specs/` 目录不存在
- **WHEN** 执行 `devbooks-spec-contract`
- **THEN** 输出"运行模式：从零创建"

---

### SC-CD-002: 补漏模式

- **GIVEN** `<change-root>/<change-id>/specs/` 目录存在
- **AND** spec.md 中存在 `[TODO]` 占位符
- **WHEN** 执行 `devbooks-spec-contract`
- **THEN** 输出"运行模式：补漏"

---

### SC-CD-003: 同步模式

- **GIVEN** `<change-root>/<change-id>/specs/` 目录存在
- **AND** spec.md 完整（无占位符，所有 Req 有 Scenario，所有 Scenario 有 Given/When/Then）
- **WHEN** 执行 `devbooks-spec-contract`
- **THEN** 输出"运行模式：同步到真理源"

---

### SC-CD-004: 阶段检测 - proposal

- **GIVEN** 变更包只有 `proposal.md`
- **WHEN** Skill 执行上下文检测
- **THEN** 输出"当前阶段：proposal"

---

### SC-CD-005: 阶段检测 - apply

- **GIVEN** 变更包有 `proposal.md`、`design.md`、`tasks.md`
- **WHEN** Skill 执行上下文检测
- **THEN** 输出"当前阶段：apply"

---

### SC-CD-006: C4 新增 delta 模式

- **GIVEN** `dev-playbooks/specs/architecture/c4.md` 不存在
- **WHEN** 执行 `devbooks-c4-map`
- **THEN** 输出"运行模式：新增 delta"

---

## 3. Contract Tests

| ID | 场景 | 断言 |
|----|------|------|
| CT-CD-001 | 三种模式检测 | 正确识别从零/补漏/同步模式 |
| CT-CD-002 | 7 边界场景完整性判断 | 全部正确判断 |
| CT-CD-003 | 阶段检测 | 正确识别 proposal/apply/archive |
| CT-CD-004 | C4 上下文检测 | 正确识别新增/更新模式 |

---

## 4. 关联规格

- `specs/slash-commands/spec.md`：Slash 命令规格
- `specs/mcp/spec.md`：MCP 检测规格
