---
name: devbooks-delivery-workflow
description: devbooks-delivery-workflow：完整闭环编排器，在支持子 Agent 的 AI 编程工具中调用，自动编排 Proposal→Design→Spec→Plan→Test→Implement→Review→Archive 全流程。用户说"跑一遍闭环/完整交付/从头到尾跑完/自动化变更流程"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
  - Task
---

# DevBooks：交付验收工作流（完整闭环编排器）

> **定位**：本 Skill 是**纯编排层**，不是执行层。它只负责**调用子 Agent**，绝不自己执行任何变更工作。

---

## 🚨 绝对禁令（ABSOLUTE RULES）

> **这些规则没有例外，违反即失败。**

### 禁令 1：禁止主 Agent 直接工作

```
❌ 禁止：主 Agent 自己写 proposal.md / design.md / tests/ / src/
❌ 禁止：主 Agent 直接修改任何变更包内容
❌ 禁止：主 Agent 跳过子 Agent 调用

✅ 必须：所有工作通过 Task 工具调用子 Agent 完成
✅ 必须：每个阶段都有对应的子 Agent 调用
✅ 必须：主 Agent 只做编排、等待、验证
```

### 禁令 2：禁止跳过任何强制阶段

```
❌ 禁止：跳过 Challenger/Judge 阶段
❌ 禁止：跳过 Test-Reviewer 阶段
❌ 禁止：跳过 Code-Review 阶段
❌ 禁止：跳过 Green-Verify 阶段
❌ 禁止：未通过 strict 检查就归档

✅ 必须：完整执行 12 个强制阶段
✅ 必须：每个阶段的子 Agent 返回成功才能继续
```

### 禁令 3：禁止假完成归档

```
❌ 禁止：evidence/green-final/ 不存在或为空时归档
❌ 禁止：verification.md AC 覆盖率 < 100% 时归档
❌ 禁止：tasks.md 存在未完成任务时归档
❌ 禁止：change-check.sh --mode strict 失败时归档

✅ 必须：Archiver 子 Agent 先运行检查脚本
✅ 必须：所有检查通过后才执行归档
```

### 禁令 4：禁止演示模式（NO DEMO MODE）

```
❌ 禁止：将工作流当作"演示"或"展示"
❌ 禁止：输出"演示已完成"、"工作流演示"等措辞
❌ 禁止：声称完成但实际产物不存在或为空
❌ 禁止：用"模拟"、"假设"、"如果"代替实际执行

✅ 必须：每个阶段都要产出真实的、可验证的产物
✅ 必须：产物必须写入文件系统（可通过 ls/cat 验证）
✅ 必须：使用"执行"、"完成"、"已创建"等真实动作词汇
✅ 必须：如果无法真实执行，立即停止并告知用户
```

**检测演示模式的信号**：
- 使用"演示"、"展示"、"模拟"等词汇
- 声称完成但没有实际文件写入
- 提供"选项 A/B"而非执行下一步
- 输出"后续建议"而非继续执行

### 禁令 5：禁止忽略 REVISE REQUIRED

```
❌ 禁止：收到 REVISE REQUIRED 后继续下一阶段
❌ 禁止：收到 REVISE REQUIRED 后声称"已完成"
❌ 禁止：收到 REVISE REQUIRED 后提供"选项"让用户选择
❌ 禁止：收到 REJECTED 后继续执行

✅ 必须：Judge 返回 REVISE → 回到阶段 1 重写提案
✅ 必须：Judge 返回 REJECTED → 停止流程，告知用户
✅ 必须：Test-Review 返回 REVISE REQUIRED → 回到阶段 7 修复测试
✅ 必须：Code-Review 返回 REVISE REQUIRED → 回到阶段 8 修复代码
✅ 必须：修复后重新执行评审阶段，直到通过
```

**回退执行流程**：
```
Test-Review REVISE REQUIRED:
    → 回到阶段 7（Test-Red）
    → 修复测试问题
    → 重新执行阶段 7-9
    → 循环直到 Test-Review 通过

Code-Review REVISE REQUIRED:
    → 回到阶段 8（Code）
    → 修复代码问题
    → 重新执行阶段 8-10
    → 循环直到 Code-Review 通过
```

### 禁令 6：禁止部分完成前进

```
❌ 禁止：tasks.md 任务完成率 < 100% 时进入下一阶段
❌ 禁止：测试覆盖率 < AC 要求时进入下一阶段
❌ 禁止：存在空壳测试（skip/todo/not_implemented）时进入 Code 阶段
❌ 禁止：存在未实现函数（raise NotImplementedError）时进入 Review 阶段

✅ 必须：阶段 7 完成时，所有测试必须是真实的、可执行的
✅ 必须：阶段 8 完成时，tasks.md 所有任务 100% 完成
✅ 必须：如果发现范围过大，必须拆分变更包，不能部分完成
```

**空壳测试的定义**：
```python
# 以下都是空壳测试，禁止存在：
def test_something():
    pass

def test_something():
    pytest.skip("not implemented")

def test_something():
    # TODO: implement
    assert True

def test_something():
    raise NotImplementedError
```

---

## 前置：配置发现（协议无关）

执行前**必须**按以下顺序查找配置：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议
3. `project.md`（如存在）→ template 协议
4. 若仍无法确定 → **停止并询问用户**

---

## 完整闭环流程（12 个强制阶段）

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         强制流程（无可选阶段）                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────┐   ┌───────────┐   ┌─────────┐   ┌─────────┐                │
│  │1.Propose│──▶│2.Challenge│──▶│ 3.Judge │──▶│4.Design │                │
│  └─────────┘   └───────────┘   └─────────┘   └─────────┘                │
│       │                                            │                     │
│       │              ┌─────────────────────────────┘                     │
│       │              ▼                                                   │
│       │        ┌─────────┐   ┌─────────┐   ┌─────────┐                  │
│       │        │ 5.Spec  │──▶│ 6.Plan  │──▶│7.Test-R │                  │
│       │        └─────────┘   └─────────┘   └─────────┘                  │
│       │                                          │                       │
│       │              ┌───────────────────────────┘                       │
│       │              ▼                                                   │
│       │        ┌─────────┐   ┌──────────┐   ┌──────────┐                │
│       │        │ 8.Code  │──▶│9.TestRev │──▶│10.CodeRev│                │
│       │        └─────────┘   └──────────┘   └──────────┘                │
│       │                                            │                     │
│       │              ┌─────────────────────────────┘                     │
│       │              ▼                                                   │
│       │        ┌───────────┐   ┌─────────┐                              │
│       └───────▶│11.GreenV  │──▶│12.Archive│                              │
│                └───────────┘   └─────────┘                              │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### 阶段详解与子 Agent 调用

| # | 阶段 | 子 Agent | Skill | 产物 | 强制 |
|---|------|----------|-------|------|------|
| 1 | Propose | `devbooks-proposal-author` | devbooks-proposal-author | proposal.md | ✅ |
| 2 | Challenge | `devbooks-challenger` | devbooks-proposal-challenger | 质疑意见 | ✅ |
| 3 | Judge | `devbooks-judge` | devbooks-proposal-judge | Decision Log | ✅ |
| 4 | Design | `devbooks-designer` | devbooks-design-doc | design.md | ✅ |
| 5 | Spec | `devbooks-spec-owner` | devbooks-spec-contract | specs/*.md | ✅ |
| 6 | Plan | `devbooks-planner` | devbooks-implementation-plan | tasks.md | ✅ |
| 7 | Test-Red | `devbooks-test-owner` | devbooks-test-owner | verification.md + tests/ | ✅ |
| 8 | Code | `devbooks-coder` | devbooks-coder | src/ 实现 | ✅ |
| 9 | Test-Review | `devbooks-reviewer` | devbooks-test-reviewer | 测试评审意见 | ✅ |
| 10 | Code-Review | `devbooks-reviewer` | devbooks-code-review | 代码评审意见 | ✅ |
| 11 | Green-Verify | `devbooks-test-owner` | devbooks-test-owner | evidence/green-final/ | ✅ |
| 12 | Archive | `devbooks-archiver` | devbooks-archiver | 归档到 archive/ | ✅ |

---

## 编排逻辑（伪代码）

```python
def run_delivery_workflow(user_requirement):
    """
    主 Agent 只执行此编排逻辑，不做任何实际工作
    """

    # ==================== 阶段 1: Propose ====================
    change_id = call_subagent("devbooks-proposal-author", {
        "task": "创建变更提案",
        "requirement": user_requirement
    })
    verify_output(f"{change_root}/{change_id}/proposal.md")

    # ==================== 阶段 2: Challenge ====================
    challenge_result = call_subagent("devbooks-challenger", {
        "task": "质疑提案",
        "change_id": change_id
    })
    # 不跳过，即使没有质疑也要运行

    # ==================== 阶段 3: Judge ====================
    judge_result = call_subagent("devbooks-judge", {
        "task": "裁决提案",
        "change_id": change_id,
        "challenge_result": challenge_result
    })
    if judge_result == "REJECTED":
        return "提案被拒绝，流程终止"
    if judge_result == "REVISE":
        # 回到阶段 1，重新编写提案
        return run_delivery_workflow(revised_requirement)
    # judge_result == "APPROVED" 继续

    # ==================== 阶段 4: Design ====================
    call_subagent("devbooks-designer", {
        "task": "创建设计文档",
        "change_id": change_id
    })
    verify_output(f"{change_root}/{change_id}/design.md")

    # ==================== 阶段 5: Spec ====================
    call_subagent("devbooks-spec-owner", {
        "task": "定义规格契约",
        "change_id": change_id
    })
    # specs/ 目录可能为空（无对外契约时）

    # ==================== 阶段 6: Plan ====================
    call_subagent("devbooks-planner", {
        "task": "创建实现计划",
        "change_id": change_id
    })
    verify_output(f"{change_root}/{change_id}/tasks.md")

    # ==================== 阶段 7: Test-Red ====================
    # 必须使用独立 Agent 会话
    call_subagent("devbooks-test-owner", {
        "task": "编写测试并建立 Red 基线",
        "change_id": change_id,
        "isolation": "required"  # 强制隔离
    })
    verify_output(f"{change_root}/{change_id}/verification.md")
    verify_output(f"{change_root}/{change_id}/evidence/red-baseline/")

    # ==================== 阶段 8: Code ====================
    # 必须使用独立 Agent 会话
    call_subagent("devbooks-coder", {
        "task": "按 tasks.md 实现功能",
        "change_id": change_id,
        "isolation": "required"  # 强制隔离
    })

    # ==================== 阶段 9: Test-Review ====================
    test_review_result = call_subagent("devbooks-reviewer", {
        "task": "评审测试质量",
        "change_id": change_id,
        "review_type": "test-review"
    })
    if test_review_result == "REVISE REQUIRED":
        # 回到阶段 7，修复测试问题
        goto_stage(7)

    # ==================== 阶段 10: Code-Review ====================
    code_review_result = call_subagent("devbooks-reviewer", {
        "task": "评审代码质量",
        "change_id": change_id,
        "review_type": "code-review"
    })
    if code_review_result == "REVISE REQUIRED":
        # 回到阶段 8，修复代码问题
        goto_stage(8)

    # ==================== 阶段 11: Green-Verify ====================
    # 必须使用独立 Agent 会话（与阶段 7 相同的 Test Owner）
    call_subagent("devbooks-test-owner", {
        "task": "运行所有测试并收集 Green 证据",
        "change_id": change_id,
        "isolation": "required",
        "phase": "green-verify"
    })
    verify_output(f"{change_root}/{change_id}/evidence/green-final/")

    # ==================== 阶段 12: Archive ====================
    # Archiver 会自动运行 change-check.sh --mode strict
    call_subagent("devbooks-archiver", {
        "task": "执行归档",
        "change_id": change_id
    })

    return "闭环完成"
```

---

## 子 Agent 调用模板

### 调用格式

使用 Task 工具调用子 Agent：

```markdown
## 调用 devbooks-proposal-author 子 Agent

请执行以下任务：
- 使用 devbooks-proposal-author skill
- 为以下需求创建变更提案：[需求描述]
- 生成符合规范的 change-id
- 完成后输出 change-id 和 proposal.md 路径
```

### 各阶段调用示例

| 阶段 | 子 Agent | 调用 Prompt |
|------|----------|-------------|
| 1 | devbooks-proposal-author | "使用 devbooks-proposal-author skill 为 [需求] 创建变更提案" |
| 2 | devbooks-challenger | "使用 devbooks-proposal-challenger skill 质疑变更 [change-id] 的提案" |
| 3 | devbooks-judge | "使用 devbooks-proposal-judge skill 裁决变更 [change-id]" |
| 4 | devbooks-designer | "使用 devbooks-design-doc skill 为变更 [change-id] 创建设计文档" |
| 5 | devbooks-spec-owner | "使用 devbooks-spec-contract skill 为变更 [change-id] 定义规格" |
| 6 | devbooks-planner | "使用 devbooks-implementation-plan skill 为变更 [change-id] 创建计划" |
| 7 | devbooks-test-owner | "使用 devbooks-test-owner skill 为变更 [change-id] 编写测试并建立 Red 基线" |
| 8 | devbooks-coder | "使用 devbooks-coder skill 为变更 [change-id] 实现功能" |
| 9 | devbooks-reviewer | "使用 devbooks-test-reviewer skill 评审变更 [change-id] 的测试" |
| 10 | devbooks-reviewer | "使用 devbooks-code-review skill 评审变更 [change-id] 的代码" |
| 11 | devbooks-test-owner | "使用 devbooks-test-owner skill 运行变更 [change-id] 的所有测试并收集 Green 证据" |
| 12 | devbooks-archiver | "使用 devbooks-archiver skill 归档变更 [change-id]" |

---

## 角色隔离约束

**关键原则**：Test Owner 和 Coder 必须使用**独立的 Agent 实例/会话**。

| 角色 | 隔离要求 | 原因 |
|------|----------|------|
| Test Owner (阶段 7, 11) | 独立 Agent | 防止 Coder 篡改测试 |
| Coder (阶段 8) | 独立 Agent | 防止 Coder 看到测试实现细节 |
| Reviewer (阶段 9, 10) | 独立 Agent（推荐） | 保持评审客观性 |

---

## 闸门检查点

### 阶段闸门

| 检查点 | 时机 | 命令 |
|--------|------|------|
| 提案完成 | 阶段 3 后 | `change-check.sh <change-id> --mode proposal` |
| 设计完成 | 阶段 6 后 | `change-check.sh <change-id> --mode apply --role test-owner` |
| 实现完成 | 阶段 10 后 | `change-check.sh <change-id> --mode apply --role coder` |
| 归档前 | 阶段 12 前 | `change-check.sh <change-id> --mode strict` |

### 归档前强制检查项

Archiver 子 Agent 必须验证：

| 检查项 | 要求 |
|--------|------|
| evidence/green-final/ | 存在且非空 |
| verification.md AC 覆盖 | 100%（所有 AC 有对应测试） |
| tasks.md 任务完成率 | 100%（所有 [x] 或 SKIP-APPROVED） |
| change-check.sh --mode strict | 全部通过 |

---

## 错误处理

### Judge 返回 REVISE

```
阶段 3 返回 REVISE
    ↓
通知用户裁决意见
    ↓
回到阶段 1，携带修改建议
    ↓
重新执行阶段 1-3
```

### Review 返回 REVISE REQUIRED

```
阶段 9（Test-Review）返回 REVISE REQUIRED
    ↓
回到阶段 7，修复测试问题
    ↓
重新执行阶段 7-9

阶段 10（Code-Review）返回 REVISE REQUIRED
    ↓
回到阶段 8，修复代码问题
    ↓
重新执行阶段 8-10
```

### Archive 检查失败

```
阶段 12 检查失败
    ↓
输出失败原因（缺失 evidence / AC 未覆盖 / 任务未完成）
    ↓
回到相应阶段修复
    ↓
重新执行到阶段 12
```

---

## 上下文感知

### 检测流程

1. 检测变更包是否存在
2. 检测当前阶段（哪些阶段已完成）
3. 从断点继续执行

### 断点续跑

若变更包已存在部分产物，从最近完成的阶段继续：

```
检测结果：
- 变更包：存在
- 已完成阶段：1-6（proposal, challenge, judge, design, spec, plan）
- 下一阶段：7（Test-Red）
- 运行模式：断点续跑
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 在工作流状态报告中标注索引可用性
3. 若不可用 → 建议在 apply 阶段前生成索引

---

## 参考骨架（按需读取）

- 工作流：`references/交付验收工作流.md`
- 模板：`references/变更验证与追溯模板.md`

## 可选检查脚本

脚本位于本 Skill 的 `scripts/` 目录：

- 初始化变更包骨架：`change-scaffold.sh`
- 一键校验变更包：`change-check.sh`
- 结构守门决策校验：`guardrail-check.sh`
- 证据采集：`change-evidence.sh`
- 进度仪表板：`progress-dashboard.sh`
