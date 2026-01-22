# Spec Delta: Slash Commands

---
capability: slash-commands
owner: Spec Owner
status: Draft
created: 2026-01-12
last_verified: 2026-01-12
freshness_check: 1 Month
---

> 产物落点：`dev-playbooks/changes/redesign-slash-command-routing/specs/slash-commands/spec.md`

---

## ADDED Requirements

### Requirement: REQ-SC-001 命令与 Skill 1:1 对应

系统 SHALL 提供 21 个 Slash 命令，每个命令与一个 DevBooks Skill 1:1 对应。

**命令清单**：

| 序号 | 命令名 | 对应 Skill |
|------|--------|------------|
| 1 | router | devbooks-router |
| 2 | proposal | devbooks-proposal-author |
| 3 | impact | devbooks-impact-analysis |
| 4 | challenger | devbooks-proposal-challenger |
| 5 | judge | devbooks-proposal-judge |
| 6 | debate | devbooks-proposal-debate-workflow |
| 7 | design | devbooks-design-doc |
| 8 | spec | devbooks-spec-contract |
| 9 | c4 | devbooks-c4-map |
| 10 | plan | devbooks-implementation-plan |
| 11 | test | devbooks-test-owner |
| 12 | code | devbooks-coder |
| 13 | review | devbooks-code-review |
| 14 | test-review | devbooks-test-reviewer |
| 15 | backport | devbooks-design-backport |
| 16 | gardener | devbooks-spec-gardener |
| 17 | entropy | devbooks-entropy-monitor |
| 18 | federation | devbooks-federation |
| 19 | bootstrap | devbooks-brownfield-bootstrap |
| 20 | index | devbooks-index-bootstrap |
| 21 | delivery | devbooks-delivery-workflow |

Trace: AC-001, AC-002

#### Scenario: SC-001-01 验证命令数量

- **GIVEN** DevBooks 已安装
- **WHEN** 用户检查命令模板目录
- **THEN** `templates/claude-commands/devbooks/` 目录包含 21 个 `.md` 文件

#### Scenario: SC-001-02 验证命令名称匹配

- **GIVEN** DevBooks 已安装
- **WHEN** 用户检查任意命令文件（如 `router.md`）
- **THEN** 文件内容包含 `skill: devbooks-router` 元数据

---

### Requirement: REQ-SC-002 命令模板结构

每个命令模板文件 SHALL 包含以下结构：
1. YAML front matter（包含 `skill:` 字段）
2. 命令提示词内容

Trace: AC-002

#### Scenario: SC-002-01 验证模板结构

- **GIVEN** 任意命令模板文件（如 `plan.md`）
- **WHEN** 解析文件内容
- **THEN** 文件以 `---` 开头，包含 `skill: devbooks-implementation-plan` 元数据

---

### Requirement: REQ-SC-003 向后兼容

系统 SHALL 保持现有 6 个命令（proposal/design/apply/review/archive/quick）的调用方式不变。

Trace: AC-008

#### Scenario: SC-003-01 验证旧命令可用

- **GIVEN** 用户已安装 DevBooks
- **WHEN** 用户调用 `/devbooks:proposal`
- **THEN** 命令正常执行，触发 `devbooks-proposal-author` Skill

---

## MODIFIED Requirements

### Requirement: REQ-SC-004 FT-009 规则更新

`c4.md` 中的 FT-009 规则 SHALL 从 `cmd_count -eq 6` 修改为 `cmd_count -eq 21`。

Trace: AC-009

#### Scenario: SC-004-01 验证 FT-009 规则

- **GIVEN** 架构闸门检查执行
- **WHEN** 检查 `templates/claude-commands/devbooks/*.md` 文件数量
- **THEN** 检查条件为 `cmd_count -eq 21`（精确值，非 -ge）

---

### Requirement: REQ-SC-005 验证脚本更新

`verify-slash-commands.sh` SHALL 包含对全部 21 个命令的存在性验证（AC-011 ~ AC-028）。

Trace: AC-010

#### Scenario: SC-005-01 验证脚本覆盖新命令

- **GIVEN** 验证脚本执行
- **WHEN** 检查 `router.md` 存在性
- **THEN** 输出验证结果（PASS 或 FAIL）

| 验证项 ID | 检查目标 |
|-----------|----------|
| AC-011 | router.md |
| AC-012 | impact.md |
| AC-013 | challenger.md |
| AC-014 | judge.md |
| AC-015 | debate.md |
| AC-016 | spec.md |
| AC-017 | c4.md |
| AC-018 | plan.md |
| AC-019 | test.md |
| AC-020 | code.md |
| AC-021 | test-review.md |
| AC-022 | backport.md |
| AC-023 | gardener.md |
| AC-024 | entropy.md |
| AC-025 | federation.md |
| AC-026 | bootstrap.md |
| AC-027 | index.md |
| AC-028 | delivery.md |

---

## 追溯摘要

| AC-xxx | Requirement | 说明 |
|--------|-------------|------|
| AC-001 | REQ-SC-001 | 21 个命令存在 |
| AC-002 | REQ-SC-001, REQ-SC-002 | 命令与 Skill 1:1 对应，模板结构正确 |
| AC-008 | REQ-SC-003 | 向后兼容 |
| AC-009 | REQ-SC-004 | FT-009 规则更新 |
| AC-010 | REQ-SC-005 | 验证脚本更新 |
