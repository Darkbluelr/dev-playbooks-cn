---
name: devbooks-code-review
description: devbooks-code-review：以 Reviewer 角色做可读性/一致性/依赖健康/坏味道审查，只输出审查意见与可执行建议，不讨论业务正确性。用户说“帮我做代码评审/review 可维护性/坏味道/依赖风险/一致性建议”，或在 OpenSpec apply 阶段以 reviewer 执行时使用。
---

# DevBooks：代码评审（Reviewer）

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
2) 严格按完整提示词输出评审意见：`references/12 代码评审提示词.md`。
