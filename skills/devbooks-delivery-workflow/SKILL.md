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

> **定位**：本 Skill 是**编排层**，不是日常手动使用的 Skill。它在支持子 Agent 的 AI 编程工具（如 Claude Code with Task tool）中调用，自动编排完整的变更闭环。

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 核心职责：完整闭环编排

本 Skill 的核心能力是**编排子 Agent 完成完整变更闭环**。

### 闭环流程（8 个阶段）

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  1. Propose │ ──▶ │  2. Design  │ ──▶ │  3. Spec    │ ──▶ │  4. Plan    │
│  (提案)     │     │  (设计)     │     │  (规格)     │     │  (计划)     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       │                                                           │
       ▼                                                           ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  8. Archive │ ◀── │  7. Review  │ ◀── │  6. Code    │ ◀── │  5. Test    │
│  (归档)     │     │  (评审)     │     │  (实现)     │     │  (测试)     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### 阶段详解与对应 Skill

| 阶段 | Skill | 产物 | 角色 |
|------|-------|------|------|
| 1. Propose | `devbooks-proposal-author` | proposal.md | Author |
| 1.5 Challenge（可选） | `devbooks-proposal-challenger` | 质疑意见 | Challenger |
| 1.6 Judge（可选） | `devbooks-proposal-judge` | 裁决结果 | Judge |
| 2. Design | `devbooks-design-doc` | design.md | Designer |
| 3. Spec | `devbooks-spec-contract` | specs/*.md | Spec Owner |
| 4. Plan | `devbooks-implementation-plan` | tasks.md | Planner |
| 5. Test | `devbooks-test-owner` | verification.md + tests/ | Test Owner |
| 6. Code | `devbooks-coder` | src/ 实现 | Coder |
| 7. Review | `devbooks-code-review` | 评审意见 | Reviewer |
| 7.5 Test Review（可选） | `devbooks-test-reviewer` | 测试评审 | Test Reviewer |
| 8. Archive | `devbooks-archiver` | 归档到真理源 | Archiver |

### 编排逻辑

```
1. 接收用户需求
2. 调用 proposal-author 创建提案（自动生成 change-id）
3. [可选] 调用 proposal-challenger 质疑提案
4. [可选] 调用 proposal-judge 裁决
5. 调用 design-doc 创建设计文档
6. [如有对外契约] 调用 spec-contract 定义规格
7. 调用 implementation-plan 创建实现计划
8. 调用 test-owner 编写测试（独立 Agent）
9. 调用 coder 实现功能（独立 Agent）
10. 调用 code-review 评审代码
11. [可选] 调用 test-reviewer 评审测试
12. 调用 archiver 归档到真理源
```

### 角色隔离约束

**关键原则**：Test Owner 和 Coder 必须使用**独立的 Agent 实例/会话**。

| 角色 | 隔离要求 | 原因 |
|------|----------|------|
| Test Owner | 独立 Agent | 防止 Coder 篡改测试 |
| Coder | 独立 Agent | 防止 Coder 看到测试实现细节 |
| Reviewer | 独立 Agent（推荐） | 保持评审客观性 |

### 闸门检查点

每个阶段完成后，调用 `change-check.sh` 验证：

```bash
# 提案阶段检查
change-check.sh <change-id> --mode proposal

# 实现阶段检查（Test Owner）
change-check.sh <change-id> --mode apply --role test-owner

# 实现阶段检查（Coder）
change-check.sh <change-id> --mode apply --role coder

# 归档前检查
change-check.sh <change-id> --mode archive
```

## 参考骨架（按需读取）

- 工作流：`references/交付验收工作流.md`
- 模板：`references/变更验证与追溯模板.md`

## 可选检查脚本

脚本位于本 Skill 的 `scripts/` 目录（可执行；优先"跑脚本拿结果"，而不是把脚本正文读进上下文）。

- 初始化变更包骨架：`change-scaffold.sh <change-id> --project-root <repo-root> --change-root <change-root> --truth-root <truth-root>`
- 一键校验变更包：`change-check.sh <change-id> --mode <proposal|apply|review|archive|strict> --role <test-owner|coder|reviewer> --project-root <repo-root> --change-root <change-root> --truth-root <truth-root>`
- 结构守门决策校验（strict 会自动调用）：`guardrail-check.sh <change-id> --project-root <repo-root> --change-root <change-root>`
- 初始化 spec delta 骨架：`change-spec-delta-scaffold.sh <change-id> <capability> --project-root <repo-root> --change-root <change-root>`
- 证据采集（把 tests/命令输出落盘到 evidence）：`change-evidence.sh <change-id> --label <name> --project-root <repo-root> --change-root <change-root> -- <command> [args...]`
- 大规模机械变更（LSC）codemod 脚本骨架：`change-codemod-scaffold.sh <change-id> --name <codemod-name> --project-root <repo-root> --change-root <change-root>`
- 卫生检查（临时文件/进程清理）：`hygiene-check.sh <change-id> --project-root <repo-root> --change-root <change-root>`

## 质量闸门脚本（v2）

以下脚本用于强化质量闸门，拦截"假完成"：

- 角色交接检查：`handoff-check.sh <change-id> --project-root <repo-root> --change-root <change-root>`
- 环境声明检查：`env-match-check.sh <change-id> --project-root <repo-root> --change-root <change-root>`
- 审计全量扫描：`audit-scope.sh <directory> --format <markdown|json>`
- 进度仪表板：`progress-dashboard.sh <change-id> --project-root <repo-root> --change-root <change-root>`
- v2 闸门迁移：`migrate-to-v2-gates.sh <change-id> --project-root <repo-root> --change-root <change-root>`

### change-check.sh v2 新增检查项

| 检查项 | 触发模式 | 说明 | AC |
|--------|----------|------|-----|
| `check_evidence_closure()` | archive, strict | 验证 `evidence/green-final/` 存在且非空 | AC-001 |
| `check_task_completion_rate()` | strict | 验证任务完成率 100%（支持 SKIP-APPROVED） | AC-002 |
| `check_role_boundaries()` | apply --role | 验证角色边界（扩展自 check_no_tests_changed） | AC-003 |
| `check_skip_approval()` | strict | 验证 P0 任务跳过有审批记录 | AC-005 |
| `check_env_match()` | archive, strict | 调用 env-match-check.sh 检查环境声明 | AC-006 |
| `check_test_failure_in_evidence()` | archive, strict | 检测 Green 证据中的失败模式 | AC-007 |

### change-check.sh 基础检查项

| 检查项 | 触发模式 | 说明 |
|--------|----------|------|
| `check_proposal()` | 所有模式 | 检查 proposal.md 格式与决策状态 |
| `check_design()` | 所有模式 | 检查 design.md 结构（AC 列表、Problem Context 等） |
| `check_tasks()` | 所有模式 | 检查 tasks.md 结构（主线计划区、断点区） |
| `check_verification()` | 所有模式 | 检查 verification.md 四大必填节 |
| `check_spec_deltas()` | 所有模式 | 检查 specs/ 目录下 spec delta 格式 |
| `check_implicit_changes()` | apply, archive, strict | 检测隐式变更（依赖、配置、构建） |

### 角色边界约束

| 角色 | 禁止修改 |
|------|----------|
| Coder | `tests/**`、`verification.md`、`.devbooks/` |
| Test Owner | `src/**` |
| Reviewer | 代码文件（`.ts`、`.js`、`.py`、`.sh` 等） |

详细说明参见：`docs/quality-gates-guide.md`

## 架构合规检查（依赖卫士）

在合并前进行架构合规检查，防止依赖方向违规。

### guardrail-check.sh 完整选项

```bash
guardrail-check.sh <change-id> [options]

Options:
  --project-root <dir>   项目根目录
  --change-root <dir>    变更包目录
  --truth-root <dir>     真理目录（包含 architecture/c4.md）
  --role <role>          角色权限检查 (coder|test-owner|reviewer)
  --check-lockfile       检查 lockfile 变更是否声明
  --check-engineering    检查工程系统变更是否声明
  --check-layers         检查分层约束违规（依赖卫士核心）
  --check-cycles         检查循环依赖
  --check-hotspots       警告热点文件变更
```

### 分层约束检查内容

`--check-layers` 会检测以下违规：

| 违规类型 | 示例 | 严重程度 |
|----------|------|----------|
| 下层引用上层 | `base/` 导入 `platform/` | 🔴 Critical |
| common 引用 browser/node | `common/` 导入 `browser/` | 🔴 Critical |
| common 使用 DOM API | `document.` 在 common 中 | 🔴 Critical |
| core 引用 contrib | 违反扩展点设计 | 🟡 High |

### 推荐用法

```bash
# 完整架构检查（合并前）
guardrail-check.sh <change-id> \
  --truth-root devbooks \
  --check-layers \
  --check-cycles \
  --check-hotspots \
  --check-lockfile \
  --check-engineering

# 快速检查（日常开发）
guardrail-check.sh <change-id> --check-layers --check-cycles
```

### CI 集成示例

```yaml
# .github/workflows/pr.yml
- name: Architecture Compliance Check
  run: |
    ./scripts/guardrail-check.sh ${{ github.event.pull_request.number }} \
      --truth-root devbooks \
      --check-layers \
      --check-cycles
```

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的工作流阶段。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测变更包是否存在
2. 检测当前阶段（proposal/apply/archive）
3. 检测闸门状态

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **初始化模式** | 变更包不存在 | 创建变更包骨架 |
| **检查模式** | 带 --check 参数 | 只运行闸门检查 |
| **完整闭环** | 无特殊参数 | 执行完整 Design→Archive 流程 |

### 检测输出示例

```
检测结果：
- 变更包：存在
- 当前阶段：apply
- 闸门状态：proposal ✓, design ✓, tasks ✓
- 运行模式：检查模式（apply 阶段）
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 在工作流状态报告中标注索引可用性
3. 若不可用 → 建议在 apply 阶段前生成索引

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 架构检查 | 精确依赖分析 | 基于 import 语句 |
| 热点预警 | CKB 实时分析 | 不可用 |
| 影响评估 | 调用图分析 | 文件级估算 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 索引不可用，架构检查将使用基础模式。
建议手动生成 SCIP 索引以启用精确检查。
```
