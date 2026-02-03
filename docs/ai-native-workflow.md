# AI 原生工作流

本指南介绍 DevBooks 的 AI 原生工作流、角色边界与证据闭环。

## 入口

- 唯一入口：`/devbooks:delivery`（生成变更包骨架、路由 `request_kind`，并驱动最小充分闭环执行）
- Delivery 会冻结 `deliverable_quality` 并写入 `completion.contract.yaml#intent.deliverable_quality`（作为归档裁判输入）
- 明确目标时可直接调用对应 Skill（Proposal/Design/Test/…），但默认从 Delivery 进入
- 当 `risk_level=high` 或 `request_kind=epic`：先用 Knife 生成 Knife Plan，再进入变更包执行

## 角色与边界

| 角色 | 责任 | 关键约束 |
| --- | --- | --- |
| Test Owner | 产出验收测试与验证追溯 | 与 Coder 分离对话 |
| Coder | 按 tasks 实现 | 禁止修改 tests/ |
| Reviewer | 审查可维护性与一致性 | 不改 tests/ |

## 行动规范（P3-3）

> 这些规范用于让执行可收敛、产物可追溯、证据可审计（避免串线/漏落盘/假完成）。

1. **角色隔离**：Test Owner 与 Coder 必须独立对话；Coder 禁止修改 `tests/**`。
2. **写入变更包**：所有产物必须落盘到变更包目录（proposal/design/tasks/verification/specs/evidence），禁止只在对话中“口头交付”。
3. **避免多变更串线**：并行变更时始终显式声明当前 `change-id`；继续执行前先检查变更包进度。
4. **完成判据**：以 Green Evidence + 闸门通过为准；必须执行到 Archive 阶段（不要中途停在 Review/Test）。
5. **高风险前置**：`risk_level=high` 或 `request_kind=epic` 必须先产出 Knife Plan（G3 强制项）。

## 工作流节点（按 request_kind 组合）

1. Proposal：明确变更目标与影响范围
2. Design：定义验收标准（AC-xxx）与约束
3. Spec：编写对外契约与行为规格
4. Plan：拆分任务与验证锚点
5. Knife（按需）：将 Epic 切片并落盘 Knife Plan（高风险/史诗级变更强制）
6. Test：生成验收测试与追溯矩阵
7. Implement：实现并生成 Green 证据
8. Review：结构质量审查
9. Archive：同步规格与归档变更包

## 证据与闸门

- 证据目录：`evidence/red-baseline/`、`evidence/green-final/`、`evidence/gates/`、`evidence/risks/`
- 闸门模型：G0–G6，覆盖提案、实施、风险与归档
- 归档前必须具备 Green 证据日志
- 闸门报告：`evidence/gates/G0-<mode>.report.json`（G0–G6）
- 协议覆盖报告：`evidence/gates/protocol-v1.1-coverage.report.json`
- 依赖审计证据：`evidence/risks/dependency-audit.log`
- 闸门验证用例矩阵（T9）：`docs/gate-validation-cases.md`

## 常用命令

- `/devbooks:delivery`：唯一入口（路由 request_kind + 驱动闭环）
- `/devbooks:knife`：Epic 切片与 Knife Plan（高风险/史诗级变更）
- `/devbooks:proposal`：提案
- `/devbooks:design`：设计
- `/devbooks:spec`：规格
- `/devbooks:plan`：计划
- `/devbooks:test`：测试
- `/devbooks:code`：实现
- `/devbooks:review`：评审
- `/devbooks:archive`：归档

## 常见问题

- 找不到入口：先使用 `/devbooks:delivery`
- 变更范围不清晰：先补 Proposal 与 Impact
- 测试失败：交由 Coder 修复，但不可改 tests/
