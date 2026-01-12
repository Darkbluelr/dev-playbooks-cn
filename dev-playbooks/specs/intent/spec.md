# intent

---
owner: Spec Gardener
last_verified: 2026-01-10
status: Active
freshness_check: 3 Months
---

## Purpose

描述意图四分类能力：从二分类（code/non-code）升级到四分类（debug/refactor/feature/docs）。

---

## Requirements

### Requirement: REQ-INT-001 意图四分类

系统 **SHALL** 支持四分类意图识别，从二分类（code/non-code）升级到四分类。

**四类意图**：
1. **debug**：调试、修复 Bug、错误排查
2. **refactor**：重构、优化、性能改进
3. **feature**：新功能、新能力
4. **docs**：文档、注释、说明

**验收条件**：
- 新增函数 `get_intent_type()` 返回四类之一
- 准确率 ≥ 80%（基于 20 个预设查询）
- 分类逻辑基于关键词匹配（无需 LLM）

#### Scenario: SC-INT-001 调试类意图识别

- **GIVEN** `devbooks-common.sh` 已加载
- **WHEN** 调用 `get_intent_type "fix authentication bug"`
- **THEN** 返回 `"debug"`

**Trace**: AC-007, SPEC-INT-001 CT-INT-001

---

### Requirement: REQ-INT-002 向后兼容性

系统 **SHALL** 保持向后兼容，新增函数不破坏现有调用方。

**兼容性要求**：
- 原有函数 `is_code_intent()` 保持不变
- `is_code_intent()` 内部调用 `get_intent_type()`（重构实现）
- 6 个现有调用方不需要修改

**验收条件**：
- 所有现有测试用例仍通过
- 现有调用方行为与原版一致
- 新增函数可独立使用

#### Scenario: SC-INT-002 向后兼容 is_code_intent

- **GIVEN** `devbooks-common.sh` 已加载
- **WHEN** 调用 `is_code_intent "fix bug"`
- **THEN** 返回 true（debug 属于 code intent）

**Trace**: AC-008, SPEC-INT-001 CT-INT-002

---

### Requirement: REQ-INT-003 关键词规则

系统 **SHALL** 基于清晰的关键词规则进行四分类，易于理解和维护。

**关键词规则**：

| 类别 | 关键词（正则表达式） | 优先级 |
|------|---------------------|--------|
| **debug** | `debug\|fix\|bug\|error\|issue\|problem\|crash\|fail` | 1（最高） |
| **refactor** | `refactor\|optimize\|improve\|performance\|clean\|simplify` | 2 |
| **docs** | `doc\|comment\|readme\|explain\|example\|guide` | 3 |
| **feature** | 默认（不匹配上述任何类别） | 4（最低） |

**验收条件**：
- 关键词规则写在注释中
- 支持大小写不敏感匹配
- 优先级从高到低匹配（debug > refactor > docs > feature）

#### Scenario: SC-INT-003 优先级匹配

- **GIVEN** 输入包含多个类别关键词 "fix and refactor module"
- **WHEN** 调用 `get_intent_type`
- **THEN** 返回 `"debug"`（优先级最高）

**Trace**: SPEC-INT-001 CT-INT-003

---

### Requirement: REQ-INT-004 调用方影响验证

系统 **SHALL** 验证 6 个现有调用方的兼容性。

**调用方**：
1. `.claude/hooks/context-inject.sh`
2. `setup/global-hooks/context-inject-global.sh`
3. （其他使用 `is_code_intent` 的脚本）

**验收条件**：
- 每个调用方都通过回归测试
- 可选：部分调用方使用 `get_intent_type()` 增强功能
- 无破坏性变更

#### Scenario: SC-INT-004 调用方回归测试

- **GIVEN** `context-inject.sh` Hook 使用 `is_code_intent`
- **WHEN** Hook 执行
- **THEN** 行为与更新前一致

**Trace**: SPEC-INT-001 CT-INT-004

---

### Requirement: REQ-INT-005 测试覆盖

系统 **SHALL** 为意图四分类功能提供充分的测试覆盖。

**测试要求**：
- 意图分类测试用例 ≥ 4（批准条件，每类至少 1 个）
- 准确率测试：20 个预设查询准确率 ≥ 80%
- 边界测试：空字符串、特殊字符、多关键词混合

#### Scenario: SC-INT-005 准确率测试

- **GIVEN** 20 个预设查询及预期结果
- **WHEN** 运行准确率测试
- **THEN** 准确率 ≥ 80%

**Trace**: SPEC-INT-001 CT-INT-005

---

## 数据驱动实例

### 意图分类对照表

| 查询示例 | 预期结果 | 匹配关键词 |
|----------|---------|-----------|
| `"fix authentication bug"` | debug | fix, bug |
| `"debug network issue"` | debug | debug, issue |
| `"refactor auth module"` | refactor | refactor |
| `"optimize query performance"` | refactor | optimize, performance |
| `"add OAuth support"` | feature | 无（默认） |
| `"implement rate limiting"` | feature | 无（默认） |
| `"update API documentation"` | docs | doc |
| `"write user guide"` | docs | guide |

### is_code_intent 映射规则

| 意图类型 | is_code_intent 返回值 | 说明 |
|----------|----------------------|------|
| debug | true | 代码相关 |
| refactor | true | 代码相关 |
| feature | true | 代码相关 |
| docs | false | 非代码相关 |

### 边界情况处理

| 输入 | 预期结果 | 说明 |
|------|---------|------|
| `""` | feature | 空字符串默认 |
| `"   "` | feature | 空白字符默认 |
| `"!@#$%^&*()"` | feature | 特殊字符默认 |
| `"FIX BUG"` | debug | 大小写不敏感 |

### 函数接口

#### get_intent_type()（新增）

```bash
# 获取查询意图类型（四分类）
# 用法: intent=$(get_intent_type "fix authentication bug")
# 返回: debug | refactor | feature | docs
get_intent_type() {
  local query="$1"
  # 实现见 tools/devbooks-common.sh
}
```

#### is_code_intent()（重构）

```bash
# 判断查询是否为代码相关意图（向后兼容）
# 用法: if is_code_intent "query"; then ...; fi
# 返回: 0（code intent）或 1（non-code intent）
is_code_intent() {
  local intent=$(get_intent_type "$1")
  [ "$intent" != "docs" ]
}
```

---

*规格由 boost-local-intelligence 变更包创建（2026-01-10），Spec Gardener 归档*
