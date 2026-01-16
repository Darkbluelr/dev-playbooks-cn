# Spec 结构模板

> 本模板定义了 Spec 真理文件的标准结构，确保 Spec 可被验证、可被追溯、可被测试生成。

## 文件位置

```
<truth-root>/specs/<capability>/spec.md
```

## 标准结构

```markdown
---
# 元信息（必填）
capability: <能力名称>
owner: @<负责人>
last_verified: YYYY-MM-DD
last_referenced_by: <最后引用的 change-id>
health: active | stale | deprecated
freshness_check: monthly | quarterly | on-change
---

# <Capability 名称> 规格

## Glossary（术语表）

> 本能力专属术语，与 `<truth-root>/_meta/glossary.md` 保持一致。

| 术语 | 定义 | 约束 |
|------|------|------|
| Order | 订单实体 | 必须有至少一个 OrderItem |
| OrderItem | 订单项 | qty > 0, price >= 0 |

## Invariants（不变量）

> 必须始终成立的约束，违反即为系统 Bug。

| ID | 描述 | 验证方式 |
|----|------|----------|
| INV-001 | 订单总额 = SUM(item.price * item.qty) | A（自动测试） |
| INV-002 | 库存数量 >= 0 | A（自动测试） |
| INV-003 | 已发货订单不可取消 | A（状态机测试） |

## Contracts（契约）

### Preconditions（前置条件）

| ID | 操作 | 条件 | 违反时行为 |
|----|------|------|-----------|
| PRE-001 | 创建订单 | user.isAuthenticated | 返回 401 |
| PRE-002 | 支付订单 | order.status == 'pending' | 返回 400 |

### Postconditions（后置条件）

| ID | 操作 | 保证 |
|----|------|------|
| POST-001 | 创建订单成功 | 生成唯一 order.id |
| POST-002 | 支付成功 | inventory.decreased(qty) |

## State Machine（状态机）

> 如果本能力涉及状态流转，必须定义状态机。

### 状态集

```
States: {Created, Paid, Shipped, Done, Cancelled}
```

### 转换规则

| 当前状态 | 动作 | 目标状态 | 条件 |
|----------|------|----------|------|
| Created | pay | Paid | payment.success |
| Created | cancel | Cancelled | - |
| Paid | ship | Shipped | inventory.reserved |
| Paid | refund | Cancelled | - |
| Shipped | deliver | Done | - |

### 禁止转换

| 当前状态 | 动作 | 原因 |
|----------|------|------|
| Shipped | cancel | 违反 INV-003 |
| Done | * | 终态，不可转出 |
| Cancelled | * | 终态，不可转出 |

## Requirements（需求）

### REQ-001: <需求标题>

**描述**：<一句话描述>

**SHALL/SHOULD/MAY**：
- 系统 **SHALL** ...
- 系统 **SHOULD** ...

**Trace**：AC-001（来自 design.md）

#### Scenario: <场景名>

- **GIVEN** 用户已登录且购物车非空
- **WHEN** 用户点击"提交订单"
- **THEN** 系统创建订单并返回订单 ID

**数据实例**（边界条件）：

| 输入 | 预期输出 | 说明 |
|------|----------|------|
| qty=1, price=100 | total=100 | 正常值 |
| qty=0 | 拒绝 | 边界-零值 |
| qty=-1 | 拒绝 | 边界-负值 |

---

## 变更历史

| 日期 | 变更包 | 变更内容 |
|------|--------|----------|
| 2024-01-16 | 20240116-1030-add-cancel | 新增取消订单场景 |
```

## 使用指南

### 1. 谁来写 Spec？

- **spec-contract skill**：负责创建/更新 spec delta
- **archiver skill**：负责将 spec delta 合并到 truth-root

### 2. 谁来读 Spec？

| Skill | 读取目的 |
|-------|----------|
| design-doc | 检查设计是否与现有 Spec 冲突，引用 REQ-xxx |
| test-owner | 从契约/状态机生成测试 |
| impact-analysis | 识别受影响的 Spec |
| code-review | 检查术语一致性 |
| archiver | 更新元信息，建立引用链 |

### 3. 测试生成映射

| Spec 元素 | 生成的测试类型 |
|-----------|---------------|
| INV-xxx | 不变量测试 |
| PRE-xxx | 前置条件测试（满足+违反） |
| POST-xxx | 后置条件测试 |
| State Transition | 状态转换测试 |
| Forbidden Transition | 禁止转换测试 |
| Data Instance Table | 参数化测试用例 |

### 4. 健康度检测

Spec 文件的 `health` 字段由 entropy-monitor 自动检测：

| 条件 | health 状态 |
|------|-------------|
| last_verified < 90 天 | `active` |
| last_verified > 90 天 | `stale`（需要 review） |
| 明确标记废弃 | `deprecated` |
| last_referenced_by 为空超过 6 个月 | 建议删除 |
