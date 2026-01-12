# 规格:意图四分类增强

> **改进项**：P5 - 意图四分类增强（优先级：中）
> **变更包**：boost-local-intelligence
> **版本**：1.0
> **状态**：Draft

---

## 元信息

| 字段 | 内容 |
|------|------|
| Spec ID | SPEC-INT-001 |
| 对应设计 | `design.md` P5 章节 |
| 涉及组件 | `tools/devbooks-common.sh` |
| 契约变更 | 函数接口（新增函数，保持向后兼容） |

---

## ADDED Requirements

### Requirement: REQ-INT-001 意图四分类

**描述**：系统必须支持四分类意图识别，从二分类（code/non-code）升级到四分类。

**优先级**：P0（必须）

**四类意图**：
1. **debug**：调试、修复 Bug、错误排查
2. **refactor**：重构、优化、性能改进
3. **feature**：新功能、新能力
4. **docs**：文档、注释、说明

**验收条件**：
- 新增函数 `get_intent_type()` 返回四类之一
- 准确率 ≥ 80%（基于 20 个预设查询）
- 分类逻辑基于关键词匹配（无需 LLM）

**关联契约**：CT-INT-001

#### Scenario: SC-INT-001
- **Given**: `devbooks-common.sh` 已加载
- **When**: 调用 `get_intent_type "fix authentication bug"`
- **Then**: 返回 `"debug"`

---

### Requirement: REQ-INT-002 向后兼容性

**描述**：新增函数必须保持向后兼容，不破坏现有调用方。

**优先级**：P0（必须）

**兼容性要求**：
- 原有函数 `is_code_intent()` 保持不变
- `is_code_intent()` 内部调用 `get_intent_type()`（重构实现）
- 6 个现有调用方不需要修改

**验收条件**：
- 所有现有测试用例仍通过
- 现有调用方行为与原版一致
- 新增函数可独立使用

**关联契约**：CT-INT-002

#### Scenario: SC-INT-002
- **Given**: `devbooks-common.sh` 已加载
- **When**: 调用 `is_code_intent "fix bug"`
- **Then**: 返回 true（debug 属于 code intent）

---

### Requirement: REQ-INT-003 关键词规则

**描述**：四分类必须基于清晰的关键词规则，易于理解和维护。

**优先级**：P1（高）

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

**关联契约**：CT-INT-003

#### Scenario: SC-INT-003
- **Given**: 输入包含多个类别关键词 "fix and refactor module"
- **When**: 调用 `get_intent_type`
- **Then**: 返回 `"debug"`（优先级最高）

---

### Requirement: REQ-INT-004 调用方影响验证

**描述**：必须验证 6 个现有调用方的兼容性。

**优先级**：P1（高）

**6 个调用方**：
1. `.claude/hooks/augment-context.sh`
2. `setup/global-hooks/augment-context-global.sh`
3. `tools/graph-rag-context.sh`
4. `tools/bug-locator.sh`
5. `tools/call-chain-tracer.sh`
6. （待补充）

**验收条件**：
- 每个调用方都通过回归测试
- 可选：部分调用方使用 `get_intent_type()` 增强功能
- 无破坏性变更

**关联契约**：CT-INT-004

#### Scenario: SC-INT-004
- **Given**: `augment-context.sh` Hook 使用 `is_code_intent`
- **When**: Hook 执行
- **Then**: 行为与更新前一致

---

### Requirement: REQ-INT-005 测试覆盖

**描述**：意图四分类功能必须有充分的测试覆盖。

**优先级**：P1（高）

**测试要求**：
- 意图分类测试用例 ≥ 4（批准条件，每类至少 1 个）
- 准确率测试：20 个预设查询准确率 ≥ 80%
- 边界测试：空字符串、特殊字符、多关键词混合

**验收条件**：
- 所有测试用例通过
- 测试覆盖率 > 80%

**关联契约**：CT-INT-005

#### Scenario: SC-INT-005
- **Given**: 20 个预设查询及预期结果
- **When**: 运行准确率测试
- **Then**: 准确率 ≥ 80%

---

## 2. Scenarios（场景）

### SC-INT-001: 调试类意图识别

**场景描述**：用户查询包含调试相关关键词，系统正确识别为 `debug`。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
source tools/devbooks-common.sh
result=$(get_intent_type "fix authentication bug")
echo "$result"
```

**Then（预期结果）**：
- 输出：`debug`
- 匹配关键词：`fix`, `bug`

**关联需求**：REQ-INT-001, REQ-INT-003

---

### SC-INT-002: 重构类意图识别

**场景描述**：用户查询包含重构相关关键词，系统正确识别为 `refactor`。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
result=$(get_intent_type "refactor auth module for better performance")
echo "$result"
```

**Then（预期结果）**：
- 输出：`refactor`
- 匹配关键词：`refactor`, `performance`

**关联需求**：REQ-INT-001, REQ-INT-003

---

### SC-INT-003: 新功能类意图识别

**场景描述**：用户查询不包含特殊关键词，默认识别为 `feature`。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
result=$(get_intent_type "add OAuth 2.0 support")
echo "$result"
```

**Then（预期结果）**：
- 输出：`feature`
- 匹配关键词：无（默认类别）

**关联需求**：REQ-INT-001, REQ-INT-003

---

### SC-INT-004: 文档类意图识别

**场景描述**：用户查询包含文档相关关键词，系统正确识别为 `docs`。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
result=$(get_intent_type "update API documentation")
echo "$result"
```

**Then（预期结果）**：
- 输出：`docs`
- 匹配关键词：`doc`

**关联需求**：REQ-INT-001, REQ-INT-003

---

### SC-INT-005: 优先级匹配

**场景描述**：用户查询包含多个类别的关键词，按优先级匹配（debug > refactor > docs > feature）。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
# 包含 fix（debug）和 refactor（refactor）
result=$(get_intent_type "fix and refactor authentication module")
echo "$result"
```

**Then（预期结果）**：
- 输出：`debug`（优先级更高）
- 匹配关键词：`fix`（优先级 1）而非 `refactor`（优先级 2）

**关联需求**：REQ-INT-003

---

### SC-INT-006: 向后兼容 `is_code_intent()`

**场景描述**：原有函数 `is_code_intent()` 行为与原版一致。

**Given（前置条件）**：
- 函数 `is_code_intent()` 内部调用 `get_intent_type()`

**When（操作）**：
```bash
# 调试类（code intent）
is_code_intent "fix bug" && echo "code" || echo "non-code"

# 重构类（code intent）
is_code_intent "refactor module" && echo "code" || echo "non-code"

# 文档类（non-code intent）
is_code_intent "update docs" && echo "code" || echo "non-code"
```

**Then（预期结果）**：
- `fix bug` → `code`
- `refactor module` → `code`
- `update docs` → `non-code`

**关联需求**：REQ-INT-002

---

### SC-INT-007: 大小写不敏感

**场景描述**：关键词匹配大小写不敏感。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
result1=$(get_intent_type "FIX BUG")
result2=$(get_intent_type "Fix Bug")
result3=$(get_intent_type "fix bug")
```

**Then（预期结果）**：
- `result1` = `debug`
- `result2` = `debug`
- `result3` = `debug`
- 三者结果一致

**关联需求**：REQ-INT-003

---

### SC-INT-008: 边界情况处理

**场景描述**：处理空字符串、特殊字符等边界情况。

**Given（前置条件）**：
- 函数 `get_intent_type()` 已实现

**When（操作）**：
```bash
result1=$(get_intent_type "")
result2=$(get_intent_type "   ")
result3=$(get_intent_type "!@#$%^&*()")
```

**Then（预期结果）**：
- `result1` = `feature`（空字符串默认为 feature）
- `result2` = `feature`（空白字符默认为 feature）
- `result3` = `feature`（特殊字符默认为 feature）

**关联需求**：REQ-INT-003

---

### SC-INT-009: 调用方增强（可选）

**场景描述**：部分调用方使用 `get_intent_type()` 优化逻辑。

**Given（前置条件）**：
- `tools/bug-locator.sh` 需要过滤调试类查询

**When（操作）**：
```bash
# 在 bug-locator.sh 中
intent=$(get_intent_type "$query")
if [ "$intent" = "debug" ]; then
  # 调试类查询，优化搜索策略
  use_error_log_search
else
  # 非调试类查询，使用通用搜索
  use_generic_search
fi
```

**Then（预期结果）**：
- 调试类查询使用优化策略
- 其他类别查询使用通用策略

**关联需求**：REQ-INT-004

---

## 3. API Specification（API 规范）

### 3.1 函数接口

#### `get_intent_type()`（新增）

**描述**：获取查询意图类型（四分类）

**函数签名**：
```bash
get_intent_type() {
  local query="$1"
  # 返回：debug | refactor | feature | docs
}
```

**参数**：
- `query`（必填）：用户查询字符串

**返回值**：
- `debug`：调试类
- `refactor`：重构类
- `feature`：新功能类
- `docs`：文档类

**示例**：
```bash
intent=$(get_intent_type "fix authentication bug")
echo "$intent"  # 输出：debug
```

---

#### `is_code_intent()`（原有，重构）

**描述**：判断查询是否为代码相关意图（向后兼容）

**函数签名**：
```bash
is_code_intent() {
  local query="$1"
  # 返回：0（code intent）或 1（non-code intent）
}
```

**参数**：
- `query`（必填）：用户查询字符串

**返回值**：
- `0`（true）：代码相关意图（debug/refactor/feature）
- `1`（false）：非代码意图（docs）

**实现**（重构）：
```bash
is_code_intent() {
  local intent=$(get_intent_type "$1")
  # 除了 docs，其他都是 code intent
  [ "$intent" != "docs" ]
}
```

**示例**：
```bash
if is_code_intent "fix bug"; then
  echo "code intent"
else
  echo "non-code intent"
fi
```

---

### 3.2 实现示例

#### 完整实现（`tools/devbooks-common.sh`）

```bash
#!/bin/bash

# 获取查询意图类型（四分类）
# 用法: intent=$(get_intent_type "fix authentication bug")
# 返回: debug | refactor | feature | docs
get_intent_type() {
  local query="$1"

  # 处理空字符串
  if [ -z "$query" ]; then
    echo "feature"
    return
  fi

  # 转换为小写（大小写不敏感）
  local query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

  # 优先级 1：调试类
  # 关键词：debug, fix, bug, error, issue, problem, crash, fail
  if echo "$query_lower" | grep -qE "debug|fix|bug|error|issue|problem|crash|fail"; then
    echo "debug"
    return
  fi

  # 优先级 2：重构类
  # 关键词：refactor, optimize, improve, performance, clean, simplify
  if echo "$query_lower" | grep -qE "refactor|optimize|improve|performance|clean|simplify"; then
    echo "refactor"
    return
  fi

  # 优先级 3：文档类
  # 关键词：doc, comment, readme, explain, example, guide
  if echo "$query_lower" | grep -qE "doc|comment|readme|explain|example|guide"; then
    echo "docs"
    return
  fi

  # 优先级 4：默认为新功能类
  echo "feature"
}

# 判断查询是否为代码相关意图（向后兼容）
# 用法: if is_code_intent "query"; then ...; fi
# 返回: 0（code intent）或 1（non-code intent）
is_code_intent() {
  local intent=$(get_intent_type "$1")
  # 除了 docs，其他都是 code intent
  [ "$intent" != "docs" ]
}
```

---

## 4. Quality Attributes（质量属性）

### 4.1 准确率

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 四分类准确率 | ≥ 80% | 20 个预设查询测试 |
| 边界情况处理 | 100% | 空字符串、特殊字符测试 |

### 4.2 性能

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 单次调用延迟 | < 10ms | 计时统计 |
| 内存占用 | 可忽略 | 纯 shell 函数，无额外内存 |

### 4.3 可维护性

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 代码行数 | < 50 行 | 统计 |
| 注释覆盖率 | 100% | 每个关键词规则都有注释 |
| 扩展性 | 易于新增类别 | 代码结构清晰 |

---

## 5. Contract Tests（契约测试计划）

### CT-INT-001: 四分类基础功能

**测试类型**：单元测试

**测试用例**：

| 查询 | 预期结果 | 匹配关键词 |
|------|---------|-----------|
| `"fix authentication bug"` | `debug` | `fix`, `bug` |
| `"refactor auth module"` | `refactor` | `refactor` |
| `"add OAuth support"` | `feature` | 无（默认） |
| `"update API docs"` | `docs` | `doc` |

**通过标准**：
- 所有测试用例 100% 通过

---

### CT-INT-002: 向后兼容性

**测试类型**：回归测试

**测试用例 2.1**：`is_code_intent()` 行为

| 查询 | 预期结果（原版） | 预期结果（新版） |
|------|----------------|----------------|
| `"fix bug"` | `true`（code） | `true`（code） |
| `"refactor"` | `true`（code） | `true`（code） |
| `"update docs"` | `false`（non-code） | `false`（non-code） |

**测试用例 2.2**：调用方兼容性

**步骤**：
1. 运行所有使用 `is_code_intent()` 的调用方
2. 验证行为与原版一致

**通过标准**：
- 所有调用方行为不变

---

### CT-INT-003: 关键词规则

**测试类型**：功能测试

**测试用例 3.1**：调试类关键词

| 查询 | 预期结果 |
|------|---------|
| `"debug issue"` | `debug` |
| `"fix error"` | `debug` |
| `"crash problem"` | `debug` |
| `"fail to load"` | `debug` |

**测试用例 3.2**：重构类关键词

| 查询 | 预期结果 |
|------|---------|
| `"optimize performance"` | `refactor` |
| `"improve code quality"` | `refactor` |
| `"clean up module"` | `refactor` |
| `"simplify logic"` | `refactor` |

**测试用例 3.3**：文档类关键词

| 查询 | 预期结果 |
|------|---------|
| `"add comment"` | `docs` |
| `"update readme"` | `docs` |
| `"explain algorithm"` | `docs` |
| `"write guide"` | `docs` |

---

### CT-INT-004: 调用方影响验证

**测试类型**：集成测试

**测试用例 4.1**：`.claude/hooks/augment-context.sh`

**步骤**：
1. 执行：`.claude/hooks/augment-context.sh "fix bug"`
2. 验证：正常工作，行为与原版一致

**测试用例 4.2**：`tools/bug-locator.sh`

**步骤**：
1. 修改 `bug-locator.sh` 使用 `get_intent_type()`（可选增强）
2. 执行：`./tools/bug-locator.sh "fix auth bug"`
3. 验证：调试类查询使用优化策略

---

### CT-INT-005: 准确率测试

**测试类型**：验收测试

**测试用例 5.1**：20 个预设查询

| ID | 查询 | 预期结果 | 实际结果 | 通过？ |
|----|------|---------|---------|--------|
| 1 | `"fix authentication bug"` | `debug` | - | - |
| 2 | `"debug network issue"` | `debug` | - | - |
| 3 | `"refactor auth module"` | `refactor` | - | - |
| 4 | `"optimize query performance"` | `refactor` | - | - |
| 5 | `"add OAuth support"` | `feature` | - | - |
| 6 | `"implement rate limiting"` | `feature` | - | - |
| 7 | `"update API documentation"` | `docs` | - | - |
| 8 | `"write user guide"` | `docs` | - | - |
| 9 | `"fix crash on startup"` | `debug` | - | - |
| 10 | `"improve code quality"` | `refactor` | - | - |
| ... | ... | ... | ... | ... |

**通过标准**：
- 准确率 ≥ 80%（≥ 16 个测试用例通过）

---

### CT-INT-006: 边界测试

**测试类型**：边界测试

**测试用例 6.1**：空字符串

**步骤**：
```bash
result=$(get_intent_type "")
[ "$result" = "feature" ] && echo "PASS" || echo "FAIL"
```

**测试用例 6.2**：空白字符

**步骤**：
```bash
result=$(get_intent_type "   ")
[ "$result" = "feature" ] && echo "PASS" || echo "FAIL"
```

**测试用例 6.3**：特殊字符

**步骤**：
```bash
result=$(get_intent_type "!@#$%^&*()")
[ "$result" = "feature" ] && echo "PASS" || echo "FAIL"
```

**测试用例 6.4**：多关键词混合

**步骤**：
```bash
# 包含 fix（debug）和 refactor（refactor），优先级 debug 更高
result=$(get_intent_type "fix and refactor module")
[ "$result" = "debug" ] && echo "PASS" || echo "FAIL"
```

---

## 6. Migration & Rollback（迁移与回滚）

### 6.1 迁移步骤

#### 对现有用户

1. **零配置用户**（使用默认行为）：
   - 无需任何操作
   - 原有调用方 `is_code_intent()` 行为不变
   - 可选：使用新函数 `get_intent_type()` 增强功能

2. **希望使用四分类的用户**：
   - 调用 `get_intent_type()` 函数
   - 根据返回值优化业务逻辑

### 6.2 回滚策略

#### 代码回滚

- 新增函数 `get_intent_type()` 封装在独立代码块
- 通过 `git revert` 可完全回滚
- 回滚后 `is_code_intent()` 恢复到原有实现

---

## 7. Dependencies（依赖）

### 7.1 外部依赖

| 依赖 | 版本 | 必须？ | 说明 |
|------|------|--------|------|
| `grep` | >= 2.0 | 是 | 正则表达式匹配 |
| `tr` | - | 是 | 大小写转换 |

### 7.2 内部依赖

| 组件 | 依赖关系 | 说明 |
|------|---------|------|
| 所有调用方 | `devbooks-common.sh` | 导入 `is_code_intent()` 或 `get_intent_type()` |

---

## 8. Open Issues（待解决问题）

| 问题 ID | 问题描述 | 状态 | 优先级 |
|--------|---------|------|--------|
| ISSUE-INT-001 | 是否需要支持中文关键词？（如"修复"、"重构"） | Open | P2 |
| ISSUE-INT-002 | 是否需要支持自定义关键词规则？（通过配置文件） | Open | P3 |
| ISSUE-INT-003 | 是否需要增加第五类：`test`（测试类）？ | Open | P3 |

---

## 9. References（参考资料）

| 资料 | 路径/链接 |
|------|---------|
| 设计文档 | `openspec/changes/boost-local-intelligence/design.md` |
| 原有实现 | `tools/devbooks-common.sh`（`is_code_intent()` 函数） |
| 正则表达式规范 | https://www.gnu.org/software/grep/manual/grep.html |

---

## 10. Approval & Sign-off（批准与签署）

| 角色 | 姓名 | 日期 | 签名 |
|------|------|------|------|
| Spec Owner | - | 2026-01-09 | Draft |
| Design Owner | - | - | Pending |
| Test Owner | - | - | Pending |

---

**变更历史**：

| 日期 | 作者 | 变更 |
|------|------|------|
| 2026-01-09 | Spec Owner | 初稿 |

---

**状态**：Draft → 等待 Test Owner 产出契约测试 → 等待 Coder 实现
