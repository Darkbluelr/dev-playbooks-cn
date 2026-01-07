---
name: devbooks-proposal-debate-workflow
description: devbooks-proposal-debate-workflow：在 proposal 阶段执行“提案-质疑-裁决”三角对辩流程，强制三角色隔离并写回 Decision Log。用户说“提案对辩/三角色对抗/Challenger/Judge/proposal debate/decision log”等时使用。
---

# DevBooks：提案对辩工作流（Proposal Debate）

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

- 工作流：`references/提案对辩工作流.md`
- 模板：`references/11 提案对辩模板.md`

## 可选检查脚本

- `proposal-debate-check.sh <change-id> --project-root <repo-root> --change-root <change-root>`（脚本位于本 Skill 的 `scripts/proposal-debate-check.sh`）
