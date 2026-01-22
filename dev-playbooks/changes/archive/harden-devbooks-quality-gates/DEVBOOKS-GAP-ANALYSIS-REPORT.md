# DevBooks 工作流缺陷诊断报告

> **生成日期**: 2026-01-11
> **分析依据**: 审计变更回顾报告 + DevBooks Skills/Scripts 源码分析
> **结论**: DevBooks 存在 **5 个缺失环节** 和 **4 个薄弱环节**，导致修复后问题反升

---

## 执行摘要

通过对比成功案例（工程实践、安全修复）与失败案例（代码质量、测试质量、数据完整性），结合 DevBooks 源码分析，诊断出以下根因：

| 问题类别 | 数量 | 影响 |
|----------|------|------|
| **缺失环节** | 5 | 导致流程断裂、假完成 |
| **薄弱环节** | 4 | 导致验收放水、质量下降 |
| **设计缺陷** | 3 | 导致角色断档、任务跳过 |

**核心结论**：问题不是"修复引入新问题"，而是 DevBooks 工作流在以下环节缺失或不严格：
1. Red-Green 闭环的 **Green 证据强制检查**
2. **角色交接握手** 确认机制
3. **任务降级审批** 流程
4. **原始审计精度** 工具
5. **测试环境匹配** 验证

---

## 第一部分：缺失环节诊断

### 缺失 #1: Green 证据强制检查 (Critical)

**问题描述**：
`change-check.sh` 检查了 Red 基线的存在（通过 `verification.md` 引用），但**没有强制检查 `evidence/green-final/` 目录**。

**源码证据** (`change-check.sh:302-359`):
```bash
check_verification() {
  # 检查 verification.md 存在 ✓
  # 检查追溯矩阵格式 ✓
  # 检查 AC 行存在 ✓
  # ❌ 没有检查 evidence/green-final/ 存在
  # ❌ 没有检查 Green 测试结果与 Red 基线对比
}
```

**失败案例影响**：
- 代码质量变更：`evidence/green-final/` 不存在即归档
- 测试质量变更：4 个测试失败仍被归档

**修复方案**：

```bash
# 新增检查函数（建议添加到 change-check.sh）
check_evidence_closure() {
  local red_dir="${change_dir}/evidence/red-baseline"
  local green_dir="${change_dir}/evidence/green-final"

  if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
    # 强制要求 Red-Green 闭环
    if [[ ! -d "$red_dir" ]]; then
      err "missing red baseline evidence: ${red_dir}"
    fi
    if [[ ! -d "$green_dir" ]]; then
      err "missing green final evidence: ${green_dir}"
    fi

    # 检查 Green 证据中没有失败
    if [[ -f "${green_dir}/test-summary.json" ]]; then
      local failures
      failures=$(jq -r '.failures // 0' "${green_dir}/test-summary.json" 2>/dev/null || echo "unknown")
      if [[ "$failures" != "0" && "$failures" != "unknown" ]]; then
        err "green evidence has ${failures} test failures: ${green_dir}/test-summary.json"
      fi
    fi
  fi
}
```

---

### 缺失 #2: 角色交接握手机制 (Critical)

**问题描述**：
`devbooks-coder` 和 `devbooks-test-owner` 强调"独立对话/独立实例"，但**没有定义交接确认机制**。

**源码证据** (`devbooks-router/SKILL.md:106-117`):
```markdown
默认路由（强制角色隔离）：
- Test Owner（独立对话/独立实例）：`devbooks-test-owner`
- Coder（独立对话/独立实例）：`devbooks-coder`
# ❌ 没有定义交接协议
# ❌ 没有握手确认文件
```

**失败案例影响**：
- 测试质量变更：Coder 写了 `handoff-to-test-owner.md`，但 Test Owner 从未接手
- 执行链断裂：`Coder执行 → handoff → Test Owner未接手 ❌`

**修复方案**：

新增 **交接协议文件** (`<change-root>/<change-id>/handoff.md`):

```markdown
# 角色交接记录

## 交接方
- 角色: [Coder | Test Owner]
- 完成时间: YYYY-MM-DD HH:MM
- 完成任务: [任务列表]
- 交接内容: [说明]

## 接收方确认 (必填)
- 角色: [Test Owner | Coder]
- 确认时间: YYYY-MM-DD HH:MM
- 确认状态: [已接收 | 有阻塞]
- 阻塞原因: [如有]

## 系统验证
- [ ] 交接方任务全部完成
- [ ] 接收方确认已填写
- [ ] 无阻塞或阻塞已解决
```

新增 **交接检查脚本** (`handoff-check.sh`):

```bash
check_handoff_complete() {
  local handoff_file="${change_dir}/handoff.md"

  if [[ ! -f "$handoff_file" ]]; then
    warn "no handoff record found: ${handoff_file}"
    return 0
  fi

  # 检查接收方确认
  if ! rg -n "确认时间: [0-9]{4}-[0-9]{2}-[0-9]{2}" "$handoff_file" >/dev/null; then
    err "handoff missing receiver confirmation: ${handoff_file}"
  fi

  # 检查确认状态
  if rg -n "确认状态: 有阻塞" "$handoff_file" >/dev/null; then
    err "handoff has unresolved blocker: ${handoff_file}"
  fi
}
```

---

### 缺失 #3: 任务降级审批流程 (High)

**问题描述**：
核心任务（如 MP2/MP3 代码拆分）可以被"建议单独变更处理"而跳过，**没有 Judge 审批机制**。

**源码证据** (`devbooks-coder/SKILL.md:75-81`):
```markdown
### 角色边界约束
- **禁止修改 `tests/**`**
- **禁止修改 `verification.md`**
# ❌ 没有规定核心任务跳过需要审批
# ❌ 没有定义"核心任务"vs"可选任务"
```

**失败案例影响**：
- 代码质量：MP2/MP3（核心拆分任务）被跳过，任务完成率仅 25%
- 测试质量：MP1（无效断言修复）完全未执行

**修复方案**：

1. **任务分级定义** (在 `tasks.md` 模板中):

```markdown
## 任务分级

| 级别 | 标记 | 跳过条件 |
|------|------|----------|
| **P0-必须** | `[P0]` | 禁止跳过，必须完成 |
| **P1-重要** | `[P1]` | 需 Judge 审批才能跳过 |
| **P2-可选** | `[P2]` | 可自行决定跳过 |

### 主线计划区

- [P0] MP1: 基础设施搭建
- [P0] MP2: 核心模块拆分 ← 禁止跳过
- [P1] MP3: 性能优化
- [P2] MP4: 文档完善
```

2. **任务跳过审批** (`change-check.sh` 增强):

```bash
check_task_completion() {
  local tasks_file="${change_dir}/tasks.md"

  # 检查 P0 任务是否全部完成
  local p0_total p0_done
  p0_total=$(rg -c "^\s*- \[.\] \[P0\]" "$tasks_file" 2>/dev/null || echo "0")
  p0_done=$(rg -c "^\s*- \[x\] \[P0\]" "$tasks_file" 2>/dev/null || echo "0")

  if [[ "$p0_total" -gt 0 && "$p0_done" -lt "$p0_total" ]]; then
    err "P0 tasks incomplete: ${p0_done}/${p0_total} (P0 tasks cannot be skipped)"
  fi

  # 检查 P1 任务跳过是否有审批
  local p1_skipped
  p1_skipped=$(rg -c "^\s*- \[SKIP\] \[P1\]" "$tasks_file" 2>/dev/null || echo "0")

  if [[ "$p1_skipped" -gt 0 ]]; then
    # 检查是否有对应的 Judge 审批
    if ! rg -n "## Task Skip Approval" "$tasks_file" >/dev/null; then
      err "P1 tasks skipped without Judge approval: ${tasks_file}"
    fi
  fi
}
```

3. **任务跳过审批模板**:

```markdown
## Task Skip Approval

| 任务 ID | 跳过原因 | Judge 裁决 | 裁决时间 |
|---------|----------|-----------|----------|
| MP3 | 范围过大需独立变更 | Approved | 2026-01-10 |
```

---

### 缺失 #4: 原始审计精度工具 (High)

**问题描述**：
原始审计采样不完整（仅检查特定目录），导致问题数量被严重低估。

**源码证据**：
- DevBooks 没有提供**全量扫描工具**
- 用户依赖手工选取文件，导致 7 处异常捕获 → 实际 96+ 处

**失败案例影响**：
| 维度 | 原始审计 | 实际规模 | 低估倍数 |
|------|---------|---------|---------|
| 异常捕获 | 7 处 | 96+ 处 | 13x |
| 无效断言 | 7 处 | 17 处 | 2.4x |
| 覆盖盲区 | 24 文件 | 42+ 文件 | 1.75x |

**修复方案**：

新增 **审计精度脚本** (`audit-scope.sh`):

```bash
#!/usr/bin/env bash
# audit-scope.sh - 确保审计覆盖全量代码
set -euo pipefail

usage() {
  cat <<'EOF'
usage: audit-scope.sh <pattern> [--project-root <dir>] [--exclude <pattern>]

Performs full-codebase scan and generates audit scope report.

Examples:
  # 扫描所有异常捕获
  audit-scope.sh "except Exception" --project-root /path/to/project

  # 扫描所有无效断言
  audit-scope.sh "assert True|assert False|pass$" --type py

  # 生成覆盖报告
  audit-scope.sh --coverage-report
EOF
}

scan_pattern() {
  local pattern="$1"
  local project_root="${2:-.}"

  echo "=== 全量扫描: ${pattern} ==="

  # 统计总数
  local total
  total=$(rg -c "$pattern" "$project_root" --type-add 'src:*.{py,ts,js,go,java}' --type src 2>/dev/null | awk -F: '{sum+=$2} END {print sum}')

  echo "总计: ${total} 处"

  # 按目录分布
  echo ""
  echo "=== 按目录分布 ==="
  rg -c "$pattern" "$project_root" --type-add 'src:*.{py,ts,js,go,java}' --type src 2>/dev/null | sort -t: -k2 -rn | head -20

  # 生成 JSON 报告
  local report_file="${project_root}/audit-scope-report.json"
  cat > "$report_file" <<EOJSON
{
  "pattern": "${pattern}",
  "total": ${total},
  "scan_time": "$(date -Iseconds)",
  "method": "full-codebase-scan",
  "files_scanned": $(find "$project_root" -type f \( -name "*.py" -o -name "*.ts" -o -name "*.js" \) | wc -l)
}
EOJSON

  echo ""
  echo "报告已生成: ${report_file}"
}

# 与原始审计对比
compare_with_original() {
  local original_count="$1"
  local actual_count="$2"

  local ratio
  ratio=$(echo "scale=2; $actual_count / $original_count" | bc)

  if (( $(echo "$ratio > 2" | bc -l) )); then
    echo "⚠️ 警告: 原始审计严重低估 (${ratio}x)"
    echo "   原始审计: ${original_count}"
    echo "   实际数量: ${actual_count}"
    echo "   建议: 使用全量扫描重新制定修复计划"
  fi
}
```

---

### 缺失 #5: 测试环境匹配验证 (High)

**问题描述**：
`devbooks-test-owner` 没有强制验证**测试环境与生产环境匹配**。

**源码证据** (`devbooks-test-owner/SKILL.md:98-103`):
```markdown
## 测试环境要求

| 测试类型 | 运行环境 | 依赖 |
|----------|----------|------|
| 单元测试 | Node.js | 无外部依赖 |
| 集成测试 | Node.js + 测试数据库 | Docker |
# ❌ 没有强制验证数据库类型匹配
# ❌ 没有禁止 SQLite 替代 PostgreSQL
```

**失败案例影响**：
- 数据完整性变更：SQLite 测试通过，但 PostgreSQL 特性（CheckConstraint）未验证
- Alembic 升级测试被 SKIP

**修复方案**：

1. **环境声明强制** (在 `verification.md` 模板中):

```markdown
## 测试环境声明 (必填)

| 环境类型 | 生产环境 | 测试环境 | 匹配验证 |
|----------|----------|----------|----------|
| 数据库 | PostgreSQL 15 | PostgreSQL 15 | ✅ 匹配 |
| 缓存 | Redis 7 | Redis 7 | ✅ 匹配 |
| 运行时 | Python 3.11 | Python 3.11 | ✅ 匹配 |

### 环境不匹配声明 (如有)

| 组件 | 差异 | 风险评估 | 缓解措施 |
|------|------|----------|----------|
| 无 | - | - | - |
```

2. **环境检查脚本** (`env-match-check.sh`):

```bash
check_db_environment() {
  local verification_file="${change_dir}/verification.md"

  # 检查是否有 SQLite 替代 PostgreSQL 的风险
  if rg -n "SQLite" "$verification_file" >/dev/null; then
    if rg -n "PostgreSQL|生产环境" "$verification_file" >/dev/null; then
      warn "detected SQLite in tests but PostgreSQL in production"

      # 检查是否声明了风险
      if ! rg -n "环境不匹配声明" "$verification_file" >/dev/null; then
        err "SQLite/PostgreSQL mismatch not declared in verification.md"
      fi
    fi
  fi

  # 检查 Alembic 测试是否被跳过
  local evidence_dir="${change_dir}/evidence"
  if [[ -d "$evidence_dir" ]]; then
    if rg -r "SKIPPED.*alembic|alembic.*SKIPPED" "$evidence_dir" >/dev/null 2>&1; then
      err "Alembic migration tests were skipped - must run on target database"
    fi
  fi
}
```

---

## 第二部分：薄弱环节诊断

### 薄弱 #1: 验收闸门 strict 模式不够严格

**当前检查项** (`change-check.sh`):
- ✅ 文件存在检查
- ✅ 格式/章节检查
- ✅ 占位符/TODO 检查
- ✅ 决策状态检查
- ❌ **缺失**: 任务完成率检查
- ❌ **缺失**: 证据闭环检查
- ❌ **缺失**: 测试通过率检查

**修复方案** (增强 `change-check.sh`):

```bash
# 任务完成率检查
check_task_completion_rate() {
  local tasks_file="${change_dir}/tasks.md"

  if [[ ! -f "$tasks_file" ]]; then
    return 0
  fi

  local total done rate
  total=$(rg -c "^\s*- \[.\]" "$tasks_file" 2>/dev/null || echo "0")
  done=$(rg -c "^\s*- \[x\]" "$tasks_file" 2>/dev/null || echo "0")

  if [[ "$total" -eq 0 ]]; then
    return 0
  fi

  rate=$((done * 100 / total))
  echo "  task completion: ${done}/${total} (${rate}%)"

  if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
    if [[ "$rate" -lt 100 ]]; then
      err "task completion rate ${rate}% < 100% (archive/strict requires all tasks done)"
    fi
  fi

  # 额外警告：完成率过低
  if [[ "$rate" -lt 50 ]]; then
    warn "task completion rate ${rate}% is very low - review before continuing"
  fi
}
```

---

### 薄弱 #2: Reviewer 阻塞项可被降级绕过

**问题描述**：
`devbooks-code-review` 产出的阻塞项可以被 Judge 降级为"非阻断"而绕过。

**失败案例**：
- 数据完整性：Reviewer 标记的 S1/S2 被 Judge 降级
- SQLite 测试假象被忽视

**修复方案**：

1. **阻塞项分级定义**:

```markdown
## 阻塞项分级

| 级别 | 含义 | 降级条件 |
|------|------|----------|
| 🔴 **Critical** | 必须修复才能归档 | 不可降级 |
| 🟠 **High** | 需要修复或提供豁免理由 | 需 Judge + 证据 |
| 🟡 **Medium** | 建议修复 | 可记录为技术债务 |
```

2. **降级审批模板**:

```markdown
## Blocker Downgrade Approval

| Blocker ID | 原级别 | 降级后 | 降级理由 | 证据 | Judge 签名 |
|------------|--------|--------|----------|------|-----------|
| S1 | Critical | - | 不可降级 | - | - |
| S2 | High | Medium | [具体理由] | [链接] | @judge |
```

---

### 薄弱 #3: 追溯矩阵 TODO 检查时机过晚

**问题描述**：
追溯矩阵中的 TODO 只在 `strict` 模式检查，导致问题积累到归档阶段才暴露。

**修复方案**：

将 TODO 检查提前到 `apply` 模式:

```bash
# change-check.sh 修改
if [[ "$mode" == "apply" || "$mode" == "archive" || "$mode" == "strict" ]]; then
  if rg -n "^\\| AC-[0-9]{3} \\|.*\\| *TODO *\\|" "$verification_file" >/dev/null; then
    if [[ "$mode" == "apply" ]]; then
      warn "verification trace matrix has TODO rows: ${verification_file}"
    else
      err "verification trace matrix still has TODO rows: ${verification_file}"
    fi
  fi
fi
```

---

### 薄弱 #4: 技术债务记录不强制

**问题描述**：
发现但未修复的问题没有强制记录为技术债务。

**成功案例对比**：
- 工程实践：显式记录 TD-ENG-001/002
- 安全修复：显式记录风险接受声明

**修复方案**：

1. **技术债务强制检查** (`change-check.sh`):

```bash
check_technical_debt() {
  local design_file="${change_dir}/design.md"
  local evidence_dir="${change_dir}/evidence"

  # 检查是否有未解决的问题但没有 TD 记录
  if [[ -d "$evidence_dir" ]]; then
    local unresolved
    unresolved=$(rg -c "TODO|FIXME|SKIP|未解决|待处理" "$evidence_dir" 2>/dev/null || echo "0")

    if [[ "$unresolved" -gt 0 ]]; then
      # 检查是否有对应的 TD 记录
      if [[ -f "$design_file" ]]; then
        if ! rg -n "^### TD-" "$design_file" >/dev/null; then
          warn "found ${unresolved} unresolved items but no TD-xxx records in design.md"
        fi
      fi
    fi
  fi
}
```

2. **技术债务模板** (在 `design.md`):

```markdown
## Technical Debt

### TD-001: [债务名称]

- **来源**: [Code Review / 审计 / 实现过程]
- **问题**: [具体描述]
- **影响**: [对系统的影响]
- **建议处理时机**: [下个迭代 / Q2 / 独立变更包]
- **跟踪**: [关联的 Issue/变更包 ID]
```

---

## 第三部分：设计缺陷诊断

### 设计缺陷 #1: 角色隔离有定义但执行无保障

**问题**：
- `devbooks-router` 定义了"独立对话/独立实例"
- 但没有机制**检测**是否真的在独立实例执行
- 没有机制**确认**角色切换时的上下文传递

**影响**：
- Test Owner 任务被 Coder "顺便"跳过
- 角色职责边界模糊

**修复方案**：

新增 **角色隔离 Skill** (`devbooks-role-isolation/SKILL.md`):

```markdown
# DevBooks：角色隔离守卫（Role Isolation Guard）

## 触发时机

在以下场景自动触发：
1. 用户说"以 Coder 角色..."或"以 Test Owner 角色..."
2. 检测到 tasks.md 中有角色标记的任务
3. 检测到跨角色操作尝试

## 检查项

### 1. 角色声明检查

```bash
# 检查当前对话是否声明了角色
check_role_declaration() {
  if [[ -z "${DEVBOOKS_ROLE:-}" ]]; then
    err "no role declared - please specify --role <coder|test-owner>"
  fi
}
```

### 2. 角色边界检查

| 角色 | 可修改 | 禁止修改 |
|------|--------|----------|
| Coder | src/**、*.py、*.ts | tests/**、verification.md |
| Test Owner | tests/**、verification.md | src/**（除测试 fixtures） |
| Reviewer | 无（只读） | 所有代码文件 |

### 3. 跨角色操作拦截

```bash
# 实时拦截违规操作
intercept_violation() {
  local role="$1"
  local file="$2"

  case "$role" in
    coder)
      if [[ "$file" =~ ^tests/ ]]; then
        err "Coder cannot modify tests/** - please handoff to Test Owner"
        return 1
      fi
      ;;
    test-owner)
      if [[ "$file" =~ ^src/ && ! "$file" =~ fixtures ]]; then
        err "Test Owner cannot modify src/** - please handoff to Coder"
        return 1
      fi
      ;;
  esac
}
```
```

---

### 设计缺陷 #2: 原型提升缺少质量闸门

**问题** (`devbooks-router/SKILL.md:140-176`):
- 原型模式允许"绕过 lint/复杂度阈值"
- 提升到生产的检查清单不够严格

**修复方案**：

增强 `prototype-promote.sh`:

```bash
# 原型提升前的强制检查
check_prototype_quality() {
  local prototype_dir="${change_dir}/prototype/src"

  # 1. 代码质量基线
  echo "=== 代码质量检查 ==="
  local lint_errors
  lint_errors=$(npm run lint -- "$prototype_dir" 2>&1 | rg -c "error" || echo "0")
  if [[ "$lint_errors" -gt 10 ]]; then
    err "prototype has ${lint_errors} lint errors - fix before promoting"
  fi

  # 2. 测试覆盖率
  echo "=== 测试覆盖率检查 ==="
  # (实现略)

  # 3. 表征测试 → 验收测试转换
  echo "=== 测试类型检查 ==="
  local char_tests acc_tests
  char_tests=$(find "${change_dir}/prototype/characterization" -name "*.test.*" | wc -l)
  acc_tests=$(find "${change_dir}/tests" -name "*.test.*" 2>/dev/null | wc -l || echo "0")

  if [[ "$acc_tests" -eq 0 && "$char_tests" -gt 0 ]]; then
    err "prototype has characterization tests but no acceptance tests - Test Owner must create verification.md first"
  fi
}
```

---

### 设计缺陷 #3: 缺少全局进度可视化

**问题**：
- 各维度的修复进度分散在各自的 `tasks.md`
- 没有全局视图显示"哪些修复了、哪些恶化了"

**修复方案**：

新增 **进度仪表板脚本** (`progress-dashboard.sh`):

```bash
#!/usr/bin/env bash
# progress-dashboard.sh - 生成修复进度仪表板

generate_dashboard() {
  local change_root="${1:-.}"

  echo "# 修复进度仪表板"
  echo ""
  echo "| 维度 | 任务完成率 | AC 通过率 | Red-Green | 状态 |"
  echo "|------|-----------|----------|-----------|------|"

  for change_dir in "${change_root}"/*/; do
    local name=$(basename "$change_dir")
    local tasks_file="${change_dir}/tasks.md"
    local verification_file="${change_dir}/verification.md"
    local red_dir="${change_dir}/evidence/red-baseline"
    local green_dir="${change_dir}/evidence/green-final"

    # 计算任务完成率
    local task_rate="N/A"
    if [[ -f "$tasks_file" ]]; then
      local total=$(rg -c "^\s*- \[.\]" "$tasks_file" 2>/dev/null || echo "0")
      local done=$(rg -c "^\s*- \[x\]" "$tasks_file" 2>/dev/null || echo "0")
      if [[ "$total" -gt 0 ]]; then
        task_rate="$((done * 100 / total))%"
      fi
    fi

    # 计算 AC 通过率
    local ac_rate="N/A"
    if [[ -f "$verification_file" ]]; then
      local ac_total=$(rg -c "AC-[0-9]{3}" "$verification_file" 2>/dev/null || echo "0")
      local ac_pass=$(rg -c "PASS" "$verification_file" 2>/dev/null || echo "0")
      if [[ "$ac_total" -gt 0 ]]; then
        ac_rate="$((ac_pass * 100 / ac_total))%"
      fi
    fi

    # Red-Green 状态
    local rg_status="❌"
    if [[ -d "$red_dir" && -d "$green_dir" ]]; then
      rg_status="✅"
    elif [[ -d "$red_dir" ]]; then
      rg_status="🔴"
    fi

    # 总体状态
    local status="⏳"
    if [[ "$task_rate" == "100%" && "$rg_status" == "✅" ]]; then
      status="✅"
    elif [[ "$task_rate" =~ ^[0-4][0-9]?% ]]; then
      status="⚠️"
    fi

    echo "| ${name} | ${task_rate} | ${ac_rate} | ${rg_status} | ${status} |"
  done
}
```

---

## 第四部分：改进路线图

### Phase 1: 紧急修复 (P0, 本周)

| 改进项 | 文件 | 工作量 |
|--------|------|--------|
| Green 证据强制检查 | `change-check.sh` | 0.5d |
| 任务完成率检查 | `change-check.sh` | 0.5d |
| 测试失败拦截 | `change-check.sh` | 0.5d |

### Phase 2: 流程完善 (P1, 下周)

| 改进项 | 新增文件 | 工作量 |
|--------|----------|--------|
| 角色交接握手机制 | `handoff-check.sh` | 1d |
| 任务分级与跳过审批 | `tasks.md` 模板更新 | 0.5d |
| 环境匹配验证 | `env-match-check.sh` | 1d |

### Phase 3: 工具增强 (P2, 本月)

| 改进项 | 新增文件 | 工作量 |
|--------|----------|--------|
| 审计精度全量扫描 | `audit-scope.sh` | 1d |
| 进度仪表板 | `progress-dashboard.sh` | 0.5d |
| 角色隔离守卫 | `devbooks-role-isolation/` | 2d |

---

## 第五部分：验证清单

### 改进后的验收标准

修复完成后，以下场景应该被正确拦截：

| 场景 | 期望行为 |
|------|----------|
| 无 Green 证据归档 | `change-check.sh --mode archive` 报错 |
| 任务完成率 < 100% 归档 | `change-check.sh --mode strict` 报错 |
| Coder 修改 tests/** | `change-check.sh --role coder` 报错 |
| 角色交接无确认 | `handoff-check.sh` 报错 |
| P0 任务被跳过 | `change-check.sh` 报错 |
| SQLite 替代 PostgreSQL 未声明 | `env-match-check.sh` 报错 |
| 测试失败但归档 | `change-check.sh` 检查 evidence 报错 |

### 成功指标

| 指标 | 当前 | 目标 |
|------|------|------|
| 假完成率 | ~40% | < 5% |
| 角色断档率 | ~30% | 0% |
| 任务跳过未审批率 | ~50% | 0% |
| 审计低估倍数 | 2-13x | < 1.5x |

---

## 附录：快速修复参考

### A. change-check.sh 增强补丁

```bash
# 在 change-check.sh 末尾添加以下检查

# === 新增检查 ===

check_evidence_closure() {
  if [[ "$mode" != "archive" && "$mode" != "strict" ]]; then
    return 0
  fi

  local red_dir="${change_dir}/evidence/red-baseline"
  local green_dir="${change_dir}/evidence/green-final"

  if [[ ! -d "$red_dir" ]]; then
    err "missing red baseline evidence (archive/strict): ${red_dir}"
  fi

  if [[ ! -d "$green_dir" ]]; then
    err "missing green final evidence (archive/strict): ${green_dir}"
  fi

  # 检查 Green 证据中没有失败
  for summary in "${green_dir}"/*.json; do
    [[ -f "$summary" ]] || continue
    if command -v jq >/dev/null 2>&1; then
      local failures
      failures=$(jq -r '.failures // .failed // 0' "$summary" 2>/dev/null || echo "0")
      if [[ "$failures" != "0" ]]; then
        err "green evidence has ${failures} failures: ${summary}"
      fi
    fi
  done
}

check_task_completion_rate() {
  local tasks_file="${change_dir}/tasks.md"
  [[ -f "$tasks_file" ]] || return 0

  local total done
  total=$(rg -c "^\s*- \[.\]" "$tasks_file" 2>/dev/null || echo "0")
  done=$(rg -c "^\s*- \[x\]" "$tasks_file" 2>/dev/null || echo "0")

  [[ "$total" -eq 0 ]] && return 0

  local rate=$((done * 100 / total))
  echo "  task completion: ${done}/${total} (${rate}%)"

  if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
    if [[ "$rate" -lt 100 ]]; then
      err "task completion ${rate}% < 100% (archive/strict)"
    fi
  fi
}

# 在主检查流程中调用
check_evidence_closure
check_task_completion_rate
```

### B. 新增模板文件

参见报告正文中的各模板定义。

---

**报告完成**

> 本报告基于 DevBooks Skills 源码分析和用户提供的审计变更回顾报告生成。
> 建议按 Phase 1 → Phase 2 → Phase 3 顺序实施改进。
