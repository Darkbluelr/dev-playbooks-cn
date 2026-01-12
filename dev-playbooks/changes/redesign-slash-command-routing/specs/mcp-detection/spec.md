# Spec Delta: MCP Detection

---
capability: mcp-detection
owner: Spec Owner
status: Draft
created: 2026-01-12
last_verified: 2026-01-12
freshness_check: 1 Month
---

> 产物落点：`dev-playbooks/changes/redesign-slash-command-routing/specs/mcp-detection/spec.md`

---

## ADDED Requirements

### Requirement: REQ-MCP-001 MCP 检测触发

Skill 执行时 SHALL 自动触发 MCP 检测机制，检查 CKB 等 MCP Server 的可用性。

Trace: AC-006

#### Scenario: SC-MCP-001-01 检测触发

- **GIVEN** 用户执行任意 DevBooks Skill
- **WHEN** Skill 初始化
- **THEN** 日志显示 MCP 检测尝试（`[MCP 检测] 正在检查 CKB 可用性...`）

---

### Requirement: REQ-MCP-002 MCP 检测超时

MCP 检测 SHALL 设置 2 秒超时，超时后自动降级到基础模式。

Trace: AC-007

#### Scenario: SC-MCP-002-01 超时降级

- **GIVEN** CKB MCP Server 不可用或响应超过 2 秒
- **WHEN** Skill 执行 MCP 检测
- **THEN** 2 秒后输出 `[MCP 检测超时，已降级为基础模式]`
- **AND** Skill 继续执行（不阻塞）

#### Scenario: SC-MCP-002-02 检测成功

- **GIVEN** CKB MCP Server 可用且响应时间 < 2 秒
- **WHEN** Skill 执行 MCP 检测
- **THEN** 输出 `[MCP 检测成功，已启用增强模式]`
- **AND** Skill 使用增强模式（CKB 工具）

---

### Requirement: REQ-MCP-003 降级行为

MCP 不可用时，Skill SHALL 降级到基础模式，使用 Grep + Glob 代替 CKB 工具。

Trace: AC-007

#### Scenario: SC-MCP-003-01 基础模式可用

- **GIVEN** MCP 检测超时或失败
- **WHEN** Skill 需要搜索代码
- **THEN** 使用 Grep/Glob 工具执行搜索
- **AND** 功能正常完成（仅损失部分增强能力）

---

### Requirement: REQ-MCP-004 SKILL.md MCP 章节

每个 SKILL.md SHALL 包含"MCP 增强"章节，说明：
1. 检测方式（调用 `mcp__ckb__getStatus()`）
2. 超时时间（2s）
3. 降级策略

Trace: AC-006

#### Scenario: SC-MCP-004-01 SKILL.md 包含 MCP 章节

- **GIVEN** 任意 SKILL.md（如 `skills/devbooks-coder/SKILL.md`）
- **WHEN** 检查文件内容
- **THEN** 包含 `## MCP 增强` 或等效章节

---

## 追溯摘要

| AC-xxx | Requirement | 说明 |
|--------|-------------|------|
| AC-006 | REQ-MCP-001, REQ-MCP-004 | MCP 检测触发 |
| AC-007 | REQ-MCP-002, REQ-MCP-003 | 超时降级 |
