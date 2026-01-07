---
name: devbooks-design-doc
description: devbooks-design-doc：产出变更包的设计文档（design.md），只写 What/Constraints 与 AC-xxx，不写实现步骤。用户说"写设计文档/Design Doc/架构设计/约束/验收标准/AC/C4 Delta"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：设计文档（Design Doc）

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

## 产物落点

- 设计文档：`<change-root>/<change-id>/design.md`

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/1 设计文档提示词.md`。
