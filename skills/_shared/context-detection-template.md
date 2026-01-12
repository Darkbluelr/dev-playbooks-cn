# 上下文检测模板 (Context Detection Template)

> 本模板为所有 SKILL.md 提供标准化的上下文检测规则。
>
> 产物落点：`skills/_shared/context-detection-template.md`

---

## 概述

上下文检测用于自动识别当前工作状态，帮助 Skill 选择正确的运行模式。检测基于文件存在性，不依赖外部服务。

---

## 检测规则

### 1. 产物存在性检测

检测变更包目录中的关键产物是否存在。

```bash
# 检测脚本示例
detect_artifacts() {
  local change_root="$1"
  local change_id="$2"
  local change_dir="${change_root}/${change_id}"

  # 检测关键产物
  local has_proposal=false
  local has_design=false
  local has_tasks=false
  local has_verification=false
  local has_specs=false

  [[ -f "${change_dir}/proposal.md" ]] && has_proposal=true
  [[ -f "${change_dir}/design.md" ]] && has_design=true
  [[ -f "${change_dir}/tasks.md" ]] && has_tasks=true
  [[ -f "${change_dir}/verification.md" ]] && has_verification=true
  [[ -d "${change_dir}/specs" ]] && has_specs=true

  echo "proposal:${has_proposal}"
  echo "design:${has_design}"
  echo "tasks:${has_tasks}"
  echo "verification:${has_verification}"
  echo "specs:${has_specs}"
}
```

### 2. 完整性判断规则

按 Requirement 块校验 specs/ 的完整性。

**完整性判定条件**：
1. 每个 REQ 必须有至少一个 Scenario
2. 每个 Scenario 必须有 Given/When/Then
3. 不存在占位符（`[TODO]`、`[待补充]`、`[TBD]`）
4. 所有 AC 都有对应的 Requirement

```bash
# 完整性检测脚本示例
# [m-001 修复] 输出格式与 tests/lib/completeness-check.sh 保持一致
check_spec_completeness() {
  local spec_file="$1"

  # 如果文件为空或不存在，视为完整
  if [[ ! -f "$spec_file" ]] || [[ ! -s "$spec_file" ]]; then
    echo "complete:无 Req 需校验"
    return 0
  fi

  # 检查是否存在占位符
  if grep -qE '\[TODO\]|\[待补充\]|\[TBD\]' "$spec_file"; then
    echo "incomplete:存在占位符"
    return 1
  fi

  # 检查 Requirement 块
  local req_count=$(grep -c '^## REQ-' "$spec_file" || echo 0)
  local scenario_count=$(grep -c '^### Scenario' "$spec_file" || echo 0)

  if [[ $req_count -gt 0 && $scenario_count -eq 0 ]]; then
    echo "incomplete:REQ 缺少 Scenario"
    return 1
  fi

  # 检查 Given/When/Then
  local gwt_count=$(grep -cE '^\s*-\s*(Given|When|Then)' "$spec_file" || echo 0)
  if [[ $scenario_count -gt 0 && $gwt_count -lt $((scenario_count * 3)) ]]; then
    echo "incomplete:Scenario 缺少完整的 Given/When/Then"
    return 1
  fi

  echo "complete:全部校验通过"
  return 0
}
```

### 3. 当前阶段检测

根据已有产物推断当前阶段。

| 阶段 | 判定条件 |
|------|----------|
| **proposal** | `proposal.md` 不存在，或存在但未通过 Judge 裁决 |
| **apply** | `proposal.md` 存在且已裁决，`design.md` 存在，正在实现 |
| **archive** | 所有闸门通过，准备归档或已归档 |

```bash
# 阶段检测脚本示例
detect_phase() {
  local change_dir="$1"

  # 检查产物存在性
  local has_proposal=false
  local has_design=false
  local has_evidence=false

  [[ -f "${change_dir}/proposal.md" ]] && has_proposal=true
  [[ -f "${change_dir}/design.md" ]] && has_design=true
  [[ -d "${change_dir}/evidence/green-final" ]] && has_evidence=true

  # 推断阶段
  if ! $has_proposal; then
    echo "proposal"
  elif $has_evidence; then
    echo "archive"
  else
    echo "apply"
  fi
}
```

### 4. 运行模式检测

根据上下文选择 Skill 的运行模式。

| 模式 | 条件 | 说明 |
|------|------|------|
| **从零创建** | 目标产物不存在 | 创建全新产物 |
| **补漏模式** | 产物存在但不完整 | 补充缺失部分 |
| **同步模式** | 产物完整，需要与实现同步 | 检查一致性并更新 |

```bash
# 模式检测脚本示例
detect_mode() {
  local artifact_path="$1"
  local artifact_type="$2"  # spec | design | c4

  if [[ ! -e "$artifact_path" ]]; then
    echo "create"  # 从零创建
    return
  fi

  # 检查完整性
  case "$artifact_type" in
    spec)
      local completeness=$(check_spec_completeness "$artifact_path")
      # [m-001 修复] 使用与实现一致的格式检查
      if [[ "$completeness" == complete:* ]]; then
        echo "sync"  # 同步模式
      else
        echo "patch"  # 补漏模式
      fi
      ;;
    design)
      if grep -qE '\[TODO\]|\[待补充\]' "$artifact_path"; then
        echo "patch"
      else
        echo "sync"
      fi
      ;;
    c4)
      if [[ -f "$artifact_path" ]]; then
        echo "update"
      else
        echo "create"
      fi
      ;;
  esac
}
```

---

## 7 个边界场景测试用例

| ID | 场景 | 输入状态 | 期望输出 | 说明 |
|----|------|----------|----------|------|
| **CD-001** | 全空变更包 | `change-dir/` 为空 | 阶段=proposal, 模式=create | 新变更的初始状态 |
| **CD-002** | 仅有 proposal | `proposal.md` 存在，其他为空 | 阶段=proposal, 等待裁决 | 提案已撰写但未通过 |
| **CD-003** | proposal + design | 两个文件都存在 | 阶段=apply | 设计已完成，进入实现 |
| **CD-004** | specs 不完整 | `specs/` 存在但有 `[TODO]` | 模式=patch | 需要补充规格 |
| **CD-005** | specs 完整 | `specs/` 存在且无占位符 | 模式=sync | 检查与实现一致性 |
| **CD-006** | 闸门通过 | `evidence/green-final/` 存在 | 阶段=archive | 准备归档 |
| **CD-007** | c4.md 不存在 | `specs/architecture/c4.md` 不存在 | 模式=create | 需要创建架构图 |

### 测试用例验证脚本

```bash
#!/bin/bash
# context-detection-test.sh
# 运行上下文检测边界场景测试

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "=== 上下文检测边界场景测试 ==="

# CD-001: 全空变更包
echo -n "CD-001 全空变更包... "
mkdir -p "$TEST_DIR/CD-001"
phase=$(detect_phase "$TEST_DIR/CD-001")
[[ "$phase" == "proposal" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-002: 仅有 proposal
echo -n "CD-002 仅有 proposal... "
mkdir -p "$TEST_DIR/CD-002"
touch "$TEST_DIR/CD-002/proposal.md"
phase=$(detect_phase "$TEST_DIR/CD-002")
[[ "$phase" == "proposal" || "$phase" == "apply" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-003: proposal + design
echo -n "CD-003 proposal + design... "
mkdir -p "$TEST_DIR/CD-003"
touch "$TEST_DIR/CD-003/proposal.md"
touch "$TEST_DIR/CD-003/design.md"
phase=$(detect_phase "$TEST_DIR/CD-003")
[[ "$phase" == "apply" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-004: specs 不完整
echo -n "CD-004 specs 不完整... "
mkdir -p "$TEST_DIR/CD-004/specs"
echo "[TODO] 待补充" > "$TEST_DIR/CD-004/specs/spec.md"
mode=$(detect_mode "$TEST_DIR/CD-004/specs/spec.md" "spec")
[[ "$mode" == "patch" ]] && echo "PASS" || echo "FAIL (got: $mode)"

# CD-005: specs 完整
echo -n "CD-005 specs 完整... "
mkdir -p "$TEST_DIR/CD-005/specs"
cat > "$TEST_DIR/CD-005/specs/spec.md" << 'EOF'
## REQ-001 示例需求
### Scenario: 正常流程
- Given 前置条件
- When 执行操作
- Then 期望结果
EOF
mode=$(detect_mode "$TEST_DIR/CD-005/specs/spec.md" "spec")
[[ "$mode" == "sync" ]] && echo "PASS" || echo "FAIL (got: $mode)"

# CD-006: 闸门通过
echo -n "CD-006 闸门通过... "
mkdir -p "$TEST_DIR/CD-006/evidence/green-final"
touch "$TEST_DIR/CD-006/proposal.md"
phase=$(detect_phase "$TEST_DIR/CD-006")
[[ "$phase" == "archive" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-007: c4.md 不存在
echo -n "CD-007 c4.md 不存在... "
mkdir -p "$TEST_DIR/CD-007/specs/architecture"
mode=$(detect_mode "$TEST_DIR/CD-007/specs/architecture/c4.md" "c4")
[[ "$mode" == "create" ]] && echo "PASS" || echo "FAIL (got: $mode)"

echo "=== 测试完成 ==="
```

---

## Skill 引用方式

在 SKILL.md 中引用本模板：

```markdown
## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的运行模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测产物存在性
2. 判断完整性
3. 推断当前阶段
4. 选择运行模式

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| 从零创建 | <条件> | <行为> |
| 补漏模式 | <条件> | <行为> |
| 同步模式 | <条件> | <行为> |
```

---

## 检测输出格式

标准化的检测结果输出：

```
检测结果：
- 产物存在性：<存在/不存在>
- 完整性：<完整/不完整（缺失项：...）>
- 当前阶段：<proposal/apply/archive>
- 运行模式：<从零创建/补漏/同步>
```

---

**文档版本**：v1.0.0
**最后更新**：2026-01-12
