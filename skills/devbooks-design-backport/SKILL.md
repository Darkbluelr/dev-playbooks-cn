---
name: devbooks-design-backport
description: devbooks-design-backport：把实现过程中发现的新约束/冲突/缺口回写到 design.md（保持设计为黄金真理），并标注决策与影响。用户说"回写设计/补充设计文档/Design Backport/设计与实现不一致/需要澄清约束"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：回写设计文档（Design Backport）

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
2) 严格按完整提示词执行：`references/3 回写设计文档提示词.md`。
