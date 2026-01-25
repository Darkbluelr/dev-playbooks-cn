# AI 原生工作流

本指南介绍 DevBooks 的 AI 原生工作流、角色边界与证据闭环。

## 入口

- 默认入口：Start（由 Router 输出最短闭环路径）
- 明确需求时可直接调用对应 Skill

## 角色与边界

| 角色 | 责任 | 关键约束 |
| --- | --- | --- |
| Test Owner | 产出验收测试与验证追溯 | 与 Coder 分离对话 |
| Coder | 按 tasks 实现 | 禁止修改 tests/ |
| Reviewer | 审查可维护性与一致性 | 不改 tests/ |

## 工作流阶段

1. Proposal：明确变更目标与影响范围
2. Design：定义验收标准（AC-xxx）与约束
3. Spec：编写对外契约与行为规格
4. Plan：拆分任务与验证锚点
5. Test：生成验收测试与追溯矩阵
6. Implement：实现并生成 Green 证据
7. Review：结构质量审查
8. Archive：同步规格与归档变更包

## 证据与闸门

- 证据目录：`evidence/red-baseline/`、`evidence/green-final/`、`evidence/gates/`、`evidence/risks/`
- 闸门模型：G0–G6，覆盖提案、实施、风险与归档
- 归档前必须具备 Green 证据日志

## 常用命令

- `/devbooks:start`：默认入口
- `/devbooks:router`：路由与阶段判断
- `/devbooks:proposal`：提案
- `/devbooks:design`：设计
- `/devbooks:spec`：规格
- `/devbooks:plan`：计划
- `/devbooks:test`：测试
- `/devbooks:code`：实现
- `/devbooks:review`：评审
- `/devbooks:archive`：归档

## 常见问题

- 找不到入口：先使用 `/devbooks:start`
- 变更范围不清晰：先补 Proposal 与 Impact
- 测试失败：交由 Coder 修复，但不可改 tests/
