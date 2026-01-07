---
description: 用 DevBooks 质量优先流程编写 OpenSpec proposal（proposal/design/spec deltas/tasks）并严格 validate
argument-hint: request or feature description (add "--prototype" for spike/exploration)
---

$ARGUMENTS

你正在执行 **OpenSpec 的 proposal 阶段**，但要求使用 **DevBooks 的质量优先工作方式** 来组织产物与决策。

硬约束（必须遵守）：
- 这是 proposal 阶段：**禁止写实现代码**，只允许产出变更包文档（proposal/design/spec deltas/tasks）。
- 先读再写：必须先阅读 `openspec/project.md`，并按其中的真理源与目录落点执行。

**Prototype 模式检测**：
- 如果参数包含 `--prototype`、`spike`、`原型`、`快速验证`、`技术验证`、`Plan to Throw One Away` 等关键词：启用 Prototype 模式
- Prototype 模式下的差异：
  - 骨架命令使用 `--prototype` 参数：`change-scaffold.sh <change-id> --prototype ...`
  - 产物目录多一层：`openspec/changes/<change-id>/prototype/`
  - Test Owner 产出表征测试（不需要 Red 基线）
  - Coder 可绕过 lint/复杂度阈值，但禁止直接落到仓库 `src/`
  - 提升到生产需要显式触发 `prototype-promote.sh`

目标：
- 生成一个可严格验证（`openspec validate <id> --strict`）的变更包：
  - `openspec/changes/<change-id>/proposal.md`
  - `openspec/changes/<change-id>/tasks.md`
  - `openspec/changes/<change-id>/design.md`（非小改动必须；只写 What/Constraints + AC-xxx）
  - `openspec/changes/<change-id>/specs/<capability>/spec.md`（仅当对外行为/契约/数据不变量发生变化时）

步骤（按顺序执行，不要跳步）：
1) 建立上下文
   - 阅读 `openspec/project.md`
   - 运行 `openspec list` 与 `openspec list --specs` 了解已有变更与现有 specs
   - 用 `rg`/`ls`/读文件把本提案锚定到“当前实现事实”
2) 选择 `change-id`
   - 生成一个唯一、动词开头、语义清晰的 `change-id`
3) （推荐）用 DevBooks 脚本生成变更包骨架（确定性落盘）
   - 先设置：`DEVBOOKS_SCRIPTS="${CODEX_HOME:-$HOME/.codex}/skills/devbooks-delivery-workflow/scripts"`
   - 运行：`"$DEVBOOKS_SCRIPTS/change-scaffold.sh" <change-id> --project-root "$(pwd)" --change-root openspec/changes --truth-root openspec/specs`
4) 产出 proposal（DevBooks 风格）
   - 以“为什么要改/改什么/不改什么/影响面/风险与回滚/验收锚点”为骨架写 `proposal.md`
   - 若是“坏味道重构”且不改变对外行为：必须明确写出 **Behavior-Preserving** 声明，并把“安全网（tests/验证计划）”写进 proposal
5) 产出 design（DevBooks 风格）
   - 为非小改动写 `design.md`：只写 What/Constraints + AC-xxx；禁止写实现步骤
6) 产出 spec deltas（按需）
   - 仅当“对外行为/契约/数据不变量”变化时才写 spec deltas
   - 每条 Requirement 至少 1 个 Scenario（GIVEN/WHEN/THEN），并尽量 Trace 到 AC-xxx
   - （可选）先用脚本创建文件骨架：`"$DEVBOOKS_SCRIPTS/change-spec-delta-scaffold.sh" <change-id> <capability> --project-root "$(pwd)" --change-root openspec/changes`
7) 产出 tasks（DevBooks 风格）
   - `tasks.md` 必须是小步、可验证、可并行的 TODO 列表（含测试/工具/闸门）
   - tasks 只能从 design/spec 推导；不要在 tasks 里写设计决策
8) 严格验证
   - （推荐）先跑 DevBooks 结构校验：`"$DEVBOOKS_SCRIPTS/change-check.sh" <change-id> --mode proposal --project-root "$(pwd)" --change-root openspec/changes --truth-root openspec/specs`
   - 运行 `openspec validate <change-id> --strict` 并修复所有问题

输出要求：
- 列出你创建/更新的文件清单
- 给出下一步建议（典型为并行：apply test owner 与 apply coder；之后 reviewer；最后 archive）
