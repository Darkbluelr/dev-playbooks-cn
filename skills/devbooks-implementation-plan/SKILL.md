---
name: devbooks-implementation-plan
description: devbooks-implementation-plan：从设计文档推导编码计划（tasks.md），输出可跟踪的主线计划/临时计划/断点区，并绑定验收锚点。用户说"写编码计划/Implementation Plan/tasks.md/任务拆解/并行拆分/里程碑/验收锚点"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：编码计划（Implementation Plan）

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

- 编码计划：`<change-root>/<change-id>/tasks.md`

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/2 编码计划提示词.md`（只从设计推导，不参考 tests/）。
