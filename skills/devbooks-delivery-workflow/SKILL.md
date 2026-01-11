---
name: devbooks-delivery-workflow
description: devbooks-delivery-workflow：把一次变更跑成可追溯闭环（Design→Plan→Trace→Verify→Implement→Archive），明确 DoD、追溯矩阵与角色隔离（Test Owner 与 Coder 分离）。用户说"跑一遍闭环/交付验收/追溯矩阵/DoD/关账归档/验收工作流"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：交付验收工作流（闭环骨架）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `openspec/project.md`（如存在）→ OpenSpec 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 参考骨架（按需读取）

- 工作流：`references/交付验收工作流.md`
- 模板：`references/9 变更验证与追溯模板.md`

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
  --truth-root openspec \
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
      --truth-root openspec \
      --check-layers \
      --check-cycles
```
