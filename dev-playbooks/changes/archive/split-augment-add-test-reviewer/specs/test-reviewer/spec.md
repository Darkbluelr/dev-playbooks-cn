# 规格：test-reviewer（测试评审角色）

---
capability: test-reviewer
status: Ready
created: 2026-01-10
updated: 2026-01-10
owner: Spec & Contract Owner
change_ref: split-augment-add-test-reviewer
---

> 产物落点：`openspec/changes/split-augment-add-test-reviewer/specs/test-reviewer/spec.md`

## ADDED Requirements

### Requirement: test-reviewer 角色定义

test-reviewer **MUST** 作为 Apply 阶段新增的测试评审角色，专注于评审测试质量。

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
| 测试覆盖率 | ✅ | ❌ |
| 测试边界条件 | ✅ | ❌ |
| 测试可读性 | ✅ | ❌ |
| 测试可维护性 | ✅ | ❌ |
| 测试与规格一致性 | ✅ | ❌ |
| 实现代码逻辑 | ❌ | ✅ |
| 实现代码风格 | ❌ | ✅ |
| 实现代码依赖 | ❌ | ✅ |
| 修改代码权限 | ❌ | ❌ |

#### Scenario: test-reviewer 执行评审

**Given** 用户指定变更包 ID
**When** 调用 test-reviewer 角色
**Then** 按职责边界矩阵执行测试质量评审

---

### Requirement: devbooks-test-reviewer Skill

系统 **MUST** 提供 `devbooks-test-reviewer` Skill 实现 test-reviewer 角色。

**规范**：
- Skill **MUST** 位于 `skills/devbooks-test-reviewer/SKILL.md`
- Skill **MUST** 定义输入为 `verification.md` 和 `tests/` 目录
- Skill **MUST** 产出包含五个维度评估的报告
- Skill **MUST NOT** 修改任何文件

**Skill 定义**：

```yaml
name: devbooks-test-reviewer
description: 以 Test Reviewer 角色评审测试质量
role: test-reviewer
stage: apply
inputs:
  - verification.md
  - tests/
outputs:
  - test-review-notes.md (不写入变更包)
constraints:
  - 只做测试质量评审，不修改测试代码
  - 不评审实现代码，只评审 tests/ 目录
  - 必须给出覆盖率评估、边界条件评估、可维护性评估
  - 必须检查测试与 verification.md 规格的一致性
```

**评审维度详解**：

| 维度 | 评审要点 | 输出格式 |
|------|----------|----------|
| coverage | 测试是否覆盖所有 AC 项？是否有遗漏的分支？ | 覆盖率评分（高/中/低）+ 遗漏清单 |
| boundary | 边界条件是否覆盖？空值、极值、异常输入？ | 边界评分 + 建议补充用例 |
| readability | 测试名称是否清晰？断言是否易懂？ | 可读性评分 + 改进建议 |
| maintainability | 测试是否易于维护？是否有重复代码？是否过度耦合实现细节？ | 可维护性评分 + 风险点 |
| spec_alignment | 测试是否与 verification.md 中定义的规格一致？ | 一致性评分 + 差异清单 |

#### Scenario: Skill 调用返回评审报告

**Given** 用户调用 `/devbooks-test-reviewer`
**When** Skill 执行完成
**Then** 返回包含五个维度评估的评审报告

---

### Requirement: test-review-notes.md 输出格式

test-reviewer **MUST** 产出符合规定格式的评审报告。

**规范**：
- 报告 **MUST** 包含评审范围信息（目录、文件数、用例数）
- 报告 **MUST** 包含五个维度的评分（coverage/boundary/readability/maintainability/spec_alignment）
- 报告 **MUST** 使用 高/中/低 三级评分
- 报告 **SHALL** 列出遗漏项和改进建议
- 报告 **MUST NOT** 写入变更包目录

#### Scenario: 生成符合模板的评审报告

**Given** test-reviewer 完成评审
**When** 输出评审报告
**Then** 报告格式符合 test-review-notes.md 模板

**模板**：

```markdown
# Test Review Notes: split-augment-add-test-reviewer

---
reviewer: test-reviewer
date: 2026-01-10
verification_ref: ./verification.md
---

## 1. 评审范围

- 评审目录：`tests/`
- 评审文件数：N
- 总测试用例数：M

## 2. 覆盖率评估

**评分**：高/中/低

**已覆盖的 AC 项**：
- [x] AC-001: ...
- [x] AC-002: ...

**遗漏的 AC 项**：
- [ ] AC-003: ...

## 3. 边界条件评估

**评分**：高/中/低

**已覆盖的边界**：
- 空值输入
- 极值输入

**建议补充的边界用例**：
- 并发场景
- 超时场景

## 4. 可读性评估

**评分**：高/中/低

**良好示例**：
- `test_user_login_with_valid_credentials`: 命名清晰

**改进建议**：
- `test_1`: 命名不清晰，建议改为 `test_xxx`

## 5. 可维护性评估

**评分**：高/中/低

**风险点**：
- `test_db_query.js`: 过度耦合数据库实现细节
- 重复的 setup 代码

## 6. 规格一致性评估

**评分**：高/中/低

**与 verification.md 一致的测试**：
- VT-001 → `tests/vt001.spec.js`

**差异清单**：
- VT-003 在 verification.md 中定义，但测试中未找到

## 7. 总结建议

1. ...
2. ...

## 元数据

| 字段 | 值 |
|------|-----|
| 评审日期 | 2026-01-10 |
| 评审者 | test-reviewer |
```

#### Scenario: 生成符合模板的评审报告

**Given** test-reviewer 完成评审
**When** 输出评审报告
**Then** 报告格式符合 test-review-notes.md 模板

---

### Requirement:Apply 阶段角色列表更新

`openspec/project.md` **MUST** 在 Apply 阶段角色列表中包含 test-reviewer。

**规范**：
- `openspec/project.md` **MUST** 在 Apply 阶段角色列表中包含 test-reviewer
- test-reviewer **MUST** 定义产物为 `test-review-notes.md`
- test-reviewer **MUST** 定义约束为"只看 tests/，不改代码"

**Before**：
```markdown
#### 阶段二：Apply（角色隔离，必须指定角色）

**可用角色与 Skills**：
| 角色 | Skill | 产物 | 约束 |
|------|-------|------|------|
| Test Owner | `devbooks-test-owner` | ... | ... |
| Coder | `devbooks-coder` | ... | ... |
| Reviewer | `devbooks-code-review` | ... | ... |
```

**After**：
```markdown
#### 阶段二：Apply（角色隔离，必须指定角色）

**可用角色与 Skills**：
| 角色 | Skill | 产物 | 约束 |
|------|-------|------|------|
| Test Owner | `devbooks-test-owner` | ... | ... |
| Coder | `devbooks-coder` | ... | ... |
| Reviewer | `devbooks-code-review` | ... | ... |
| Test Reviewer | `devbooks-test-reviewer` | `test-review-notes.md` | 只看 tests/，不改代码 |
```

#### Scenario: 验证角色列表更新

**Given** 变更完成
**When** 检查 project.md
**Then** Apply 阶段角色列表包含 test-reviewer

---

## 场景

### 场景：调用 test-reviewer 评审测试

**Given** Coder 已完成实现，测试已 Green
**When** 用户执行 `/openspec:apply test-reviewer split-augment-add-test-reviewer`
**Then**
1. test-reviewer 读取 `verification.md` 和 `tests/` 目录
2. 产出 `test-review-notes.md` 评审报告
3. 报告包含五个维度的评估（coverage/boundary/readability/maintainability/spec_alignment）
4. 报告不写入变更包，仅供参考

### 场景：test-reviewer 拒绝评审实现代码

**Given** 用户要求 test-reviewer 评审 `src/` 目录
**When** test-reviewer 检测到请求目标是 `src/`
**Then** 拒绝并提示 "test-reviewer 只评审 tests/ 目录，实现代码请使用 reviewer"

### 场景：test-reviewer 检测规格不一致

**Given** verification.md 定义了 VT-001 ~ VT-005 五个验证项
**And** tests/ 目录只有 VT-001 ~ VT-003 的测试
**When** test-reviewer 执行评审
**Then** 报告中的"差异清单"列出 VT-004 和 VT-005 缺失

---

## 契约变更

### 配置变更

| 配置项 | Before | After | Breaking? |
|--------|--------|-------|-----------|
| `openspec/project.md` Apply 角色列表 | 3 个角色 | 4 个角色（+test-reviewer） | No（兼容扩展） |

### 命令变更

| 命令 | Before | After |
|------|--------|-------|
| `/openspec:apply test-reviewer <id>` | 不存在 | 可用 |

### 无 Breaking Change

本需求为纯新增，不影响现有功能。

---

## Contract Tests

| CT-ID | 契约 | 测试描述 | 验证方式 |
|-------|------|----------|----------|
| CT-TR-001 | Skill 可用性 | `devbooks-test-reviewer` Skill 存在且可调用 | `ls skills/devbooks-test-reviewer/SKILL.md` |
| CT-TR-002 | 角色定义 | `openspec/project.md` 包含 test-reviewer 定义 | `grep "test-reviewer" openspec/project.md` |
| CT-TR-003 | 输入约束 | test-reviewer 只读取 `tests/` 目录 | Skill 实现验证 |
| CT-TR-004 | 输出格式 | 产出符合 `test-review-notes.md` 模板 | 格式验证 |
| CT-TR-005 | 权限约束 | test-reviewer 不修改任何文件 | Skill 实现验证 |
| CT-TR-006 | 规格检查 | 检测 verification.md 与 tests/ 的差异 | 场景测试 |

---

## 元数据

| 字段 | 值 |
|------|-----|
| 创建日期 | 2026-01-10 |
| 状态 | Draft |
| 作者 | Spec & Contract Owner |

---

*此规格由 devbooks-spec-contract 产出。*
