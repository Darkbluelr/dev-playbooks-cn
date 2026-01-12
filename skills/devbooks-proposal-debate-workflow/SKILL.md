---
name: devbooks-proposal-debate-workflow
description: devbooks-proposal-debate-workflow：在 proposal 阶段执行"提案-质疑-裁决"三角对辩流程，强制三角色隔离并写回 Decision Log。用户说"提案对辩/三角色对抗/Challenger/Judge/proposal debate/decision log"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：提案对辩工作流（Proposal Debate）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
4. `project.md`（如存在）→ template 协议，使用默认映射
5. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 参考骨架（按需读取）

- 工作流：`references/提案对辩工作流.md`
- 模板：`references/11 提案对辩模板.md`

## 可选检查脚本

- `proposal-debate-check.sh <change-id> --project-root <repo-root> --change-root <change-root>`（脚本位于本 Skill 的 `scripts/proposal-debate-check.sh`）

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的对辩阶段。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `proposal.md` 是否存在
2. 检测 Decision Log 状态
3. 检测当前对辩轮次

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **提案阶段** | 无 Decision Log | Author 撰写提案 |
| **质疑阶段** | 提案完成但无质疑 | Challenger 发起质疑 |
| **裁决阶段** | 质疑完成但无裁决 | Judge 给出裁决 |
| **已完成** | Decision Log 有最终裁决 | 只允许查看 |

### 检测输出示例

```
检测结果：
- proposal.md：存在
- Decision Log：有 1 轮质疑
- 当前轮次：第 1 轮
- 运行模式：裁决阶段
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`
