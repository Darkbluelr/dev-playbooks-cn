# test-reviewer

---
owner: Spec Gardener
last_verified: 2026-01-10
status: Active
freshness_check: 3 Months
source_change: split-augment-add-test-reviewer
---

## Purpose

描述 test-reviewer 角色能力：Apply 阶段专注于测试质量评审，与 reviewer（实现代码评审）职责分离。

---

## Requirements

### Requirement: REQ-TR-001 test-reviewer 角色定义

test-reviewer **MUST** 作为 Apply 阶段的测试评审角色，专注于评审测试质量。

**规范**：
- test-reviewer **MUST** 只评审 `tests/` 目录下的测试文件
- test-reviewer **MUST NOT** 修改任何代码文件
- test-reviewer **MUST NOT** 评审 `src/` 或其他实现目录
- test-reviewer **MUST** 产出测试质量评审报告
- test-reviewer **SHALL** 检查测试与 `verification.md` 规格的一致性

**角色属性**：

| 属性 | 值 |
|------|-----|
| 名称 | test-reviewer |
| 阶段 | Apply |
| Skill | `devbooks-test-reviewer` |
| 输入 | `verification.md`, `tests/` |
| 输出 | `test-review-notes.md`（不写入变更包） |

**职责边界**：

| 评审维度 | test-reviewer | reviewer |
|----------|:-------------:|:--------:|
| 测试覆盖率 | Yes | No |
| 测试边界条件 | Yes | No |
| 测试可读性 | Yes | No |
| 测试可维护性 | Yes | No |
| 测试与规格一致性 | Yes | No |
| 实现代码逻辑 | No | Yes |
| 实现代码风格 | No | Yes |
| 实现代码依赖 | No | Yes |
| 修改代码权限 | No | No |

#### Scenario: SC-TR-001 test-reviewer 执行评审

- **GIVEN** 用户指定变更包 ID
- **WHEN** 调用 test-reviewer 角色
- **THEN** 按职责边界矩阵执行测试质量评审

**Trace**: AC-005

---

### Requirement: REQ-TR-002 devbooks-test-reviewer Skill

系统 **MUST** 提供 `devbooks-test-reviewer` Skill 实现 test-reviewer 角色。

**规范**：
- Skill **MUST** 位于 `skills/devbooks-test-reviewer/SKILL.md`
- Skill **MUST** 定义输入为 `verification.md` 和 `tests/` 目录
- Skill **MUST** 产出包含五个维度评估的报告
- Skill **MUST NOT** 修改任何文件

**评审维度**：

| 维度 | 评审要点 | 输出格式 |
|------|----------|----------|
| coverage | 测试是否覆盖所有 AC 项？是否有遗漏的分支？ | 覆盖率评分（高/中/低）+ 遗漏清单 |
| boundary | 边界条件是否覆盖？空值、极值、异常输入？ | 边界评分 + 建议补充用例 |
| readability | 测试名称是否清晰？断言是否易懂？ | 可读性评分 + 改进建议 |
| maintainability | 测试是否易于维护？是否有重复代码？是否过度耦合实现细节？ | 可维护性评分 + 风险点 |
| spec_alignment | 测试是否与 verification.md 中定义的规格一致？ | 一致性评分 + 差异清单 |

#### Scenario: SC-TR-002 Skill 调用返回评审报告

- **GIVEN** 用户调用 `/devbooks-test-reviewer`
- **WHEN** Skill 执行完成
- **THEN** 返回包含五个维度评估的评审报告

**Trace**: AC-005

---

### Requirement: REQ-TR-003 test-review-notes.md 输出格式

test-reviewer **MUST** 产出符合规定格式的评审报告。

**规范**：
- 报告 **MUST** 包含评审范围信息（目录、文件数、用例数）
- 报告 **MUST** 包含五个维度的评分（coverage/boundary/readability/maintainability/spec_alignment）
- 报告 **MUST** 使用 高/中/低 三级评分
- 报告 **SHALL** 列出遗漏项和改进建议
- 报告 **MUST NOT** 写入变更包目录

#### Scenario: SC-TR-003 生成符合模板的评审报告

- **GIVEN** test-reviewer 完成评审
- **WHEN** 输出评审报告
- **THEN** 报告格式符合 test-review-notes.md 模板

**Trace**: AC-005

---

### Requirement: REQ-TR-004 角色隔离约束

test-reviewer **MUST NOT** 越界执行 reviewer 的职责。

**规范**：
- test-reviewer **MUST** 拒绝评审 `src/` 目录
- test-reviewer **MUST** 在收到越界请求时输出明确拒绝信息
- test-reviewer **MUST** 建议用户使用 reviewer 角色

#### Scenario: SC-TR-004 test-reviewer 拒绝评审实现代码

- **GIVEN** 用户要求 test-reviewer 评审 `src/` 目录
- **WHEN** test-reviewer 检测到请求目标是 `src/`
- **THEN** 拒绝并提示 "test-reviewer 只评审 tests/ 目录，实现代码请使用 reviewer"

**Trace**: CON-ROLE-001

---

### Requirement: REQ-TR-005 规格差异检测

test-reviewer **SHALL** 检测 `verification.md` 与 `tests/` 的差异。

**规范**：
- test-reviewer **SHALL** 识别 verification.md 中定义但测试中未覆盖的验证项
- test-reviewer **SHALL** 识别测试中存在但 verification.md 未定义的测试用例
- test-reviewer **SHALL** 在报告的"差异清单"中列出所有差异

#### Scenario: SC-TR-005 检测规格不一致

- **GIVEN** verification.md 定义了 VT-001 ~ VT-005 五个验证项
- **AND** tests/ 目录只有 VT-001 ~ VT-003 的测试
- **WHEN** test-reviewer 执行评审
- **THEN** 报告中的"差异清单"列出 VT-004 和 VT-005 缺失

**Trace**: CON-ROLE-003

---

## Contract Tests

| CT-ID | 契约 | 测试描述 | 验证方式 |
|-------|------|----------|----------|
| CT-TR-001 | Skill 可用性 | `devbooks-test-reviewer` Skill 存在且可调用 | `ls skills/devbooks-test-reviewer/SKILL.md` |
| CT-TR-002 | 角色定义 | `dev-playbooks/project.md` 包含 test-reviewer 定义 | `grep "test-reviewer" dev-playbooks/project.md` |
| CT-TR-003 | 输入约束 | test-reviewer 只读取 `tests/` 目录 | Skill 实现验证 |
| CT-TR-004 | 输出格式 | 产出符合 `test-review-notes.md` 模板 | 格式验证 |
| CT-TR-005 | 权限约束 | test-reviewer 不修改任何文件 | Skill 实现验证 |
| CT-TR-006 | 规格检查 | 检测 verification.md 与 tests/ 的差异 | 场景测试 |

---

*规格由 split-augment-add-test-reviewer 变更包新增，Spec Gardener 归档（2026-01-10）*
