---
name: devbooks-proposal-challenger
description: devbooks-proposal-challenger：对 proposal.md 发起质疑（Challenger），指出风险/遗漏/不一致并给结论，避免共识稀释与机械指标误导。用户说"质疑提案/挑刺/风险评估/提案对辩 challenger"等时使用。
tools:
  - Glob
  - Grep
  - Read
---

# DevBooks：提案质疑（Proposal Challenger）

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

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出质疑报告：`references/14 提案质疑提示词.md`。
