# Spec Delta: Router Enhancement

---
capability: router
owner: Spec Owner
status: Draft
created: 2026-01-12
last_verified: 2026-01-12
freshness_check: 1 Month
---

> 产物落点：`dev-playbooks/changes/redesign-slash-command-routing/specs/router/spec.md`

---

## MODIFIED Requirements

### Requirement: REQ-RT-001 Router 读取 Impact 画像

Router SHALL 读取 `proposal.md` 中的 Impact 章节（结构化 YAML），并据此推导执行计划。

Trace: AC-003

#### Scenario: SC-RT-001-01 成功解析 Impact 画像

- **GIVEN** `proposal.md` 包含结构化 Impact 画像（YAML 格式）
- **WHEN** Router 执行
- **THEN** 输出执行计划，包含命令序列和原因

**Impact 画像结构**：

```yaml
impact_profile:
  external_api: true/false
  architecture_boundary: true/false
  data_model: true/false
  cross_repo: true/false
  risk_level: high/medium/low
  affected_modules:
    - name: <module-path>
      type: add/modify/delete
      files: <count>
```

---

### Requirement: REQ-RT-002 Router 输出格式

Router 输出的执行计划 SHALL 包含以下结构：
1. 影响画像摘要
2. 分阶段命令序列
3. 跳过的步骤及原因

Trace: AC-003

#### Scenario: SC-RT-002-01 完整执行计划输出

- **GIVEN** Router 成功解析 Impact 画像
- **WHEN** 输出执行计划
- **THEN** 输出包含以下章节：

```markdown
# 执行计划：<change-id>

## 影响画像
- 对外 API：是/否
- 架构边界：是/否
- 数据模型：是/否
- 跨仓库：是/否
- 风险等级：高/中/低

## 完整流程

### Phase 1: Proposal
| 序号 | 命令 | 状态 | 原因 |
|------|------|------|------|
| 1 | `/devbooks:proposal` | ✅/⬜ | - |

## 跳过的步骤（原因）
- `/devbooks:xxx` - 原因
```

---

### Requirement: REQ-RT-003 Router 解析失败处理

当 Router 无法解析 Impact 画像时，SHALL 输出错误提示和降级方案。

Trace: AC-012

#### Scenario: SC-RT-003-01 无 Impact 画像

- **GIVEN** `proposal.md` 不存在或不包含 Impact 章节
- **WHEN** Router 执行
- **THEN** 输出错误提示：`[Router 错误] 未找到 Impact 画像，请先运行 /devbooks:impact`
- **AND** 输出降级方案：`建议使用直达命令 /devbooks:<skill> 手动执行`

#### Scenario: SC-RT-003-02 Impact 画像格式错误

- **GIVEN** `proposal.md` 包含 Impact 章节但格式不符合预期
- **WHEN** Router 执行
- **THEN** 输出错误提示：`[Router 错误] Impact 画像格式错误，缺失字段：external_api, risk_level`
- **AND** 输出降级方案

---

### Requirement: REQ-RT-004 Router 推导规则

Router SHALL 根据 Impact 画像推导需要执行的 Skill：

| 条件 | 推荐 Skill |
|------|-----------|
| architecture_boundary = true | devbooks-c4-map |
| external_api = true | devbooks-spec-contract |
| data_model = true | devbooks-spec-contract |
| 任意 affected_modules | devbooks-impact-analysis |
| risk_level = high | devbooks-proposal-challenger, devbooks-proposal-judge |

Trace: AC-003

#### Scenario: SC-RT-004-01 架构边界变更

- **GIVEN** Impact 画像包含 `architecture_boundary: true`
- **WHEN** Router 推导执行计划
- **THEN** 执行计划包含 `/devbooks:c4`

#### Scenario: SC-RT-004-02 对外 API 变更

- **GIVEN** Impact 画像包含 `external_api: true`
- **WHEN** Router 推导执行计划
- **THEN** 执行计划包含 `/devbooks:spec`

---

### Requirement: REQ-RT-005 Router 解析成功率

Router 对历史变更的解析成功率 SHALL ≥ 80%。

Trace: AC-003

#### Scenario: SC-RT-005-01 解析成功率验证

- **GIVEN** 5 个历史变更包的 proposal.md
- **WHEN** Router 依次解析
- **THEN** 成功解析 ≥ 4 个（成功率 ≥ 80%）
- **AND** 记录到 `evidence/router-parse-stats.md`

---

## ADDED Requirements

### Requirement: REQ-RT-006 双入口模式文档

Router SKILL.md SHALL 明确说明双入口模式：
1. **主入口**：`/devbooks:router` — 适用于复杂变更（>5 文件或跨模块）
2. **直达入口**：`/devbooks:<skill>` — 适用于已知 Skill、简单变更、调试场景

Trace: AC-003

#### Scenario: SC-RT-006-01 文档包含双入口说明

- **GIVEN** `skills/devbooks-router/SKILL.md`
- **WHEN** 检查文件内容
- **THEN** 包含"双入口模式"或"入口选择"章节

---

## 追溯摘要

| AC-xxx | Requirement | 说明 |
|--------|-------------|------|
| AC-003 | REQ-RT-001, REQ-RT-002, REQ-RT-004, REQ-RT-005, REQ-RT-006 | Router 读取 Impact 画像并输出执行计划 |
| AC-012 | REQ-RT-003 | Router 解析失败时输出错误提示和降级方案 |
