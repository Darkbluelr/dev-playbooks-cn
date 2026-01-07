---
name: devbooks-spec-delta
description: devbooks-spec-delta：产出规格 delta（Requirements/Scenarios），把设计验收点转成可追溯的规范条目。用户说“写规格/spec delta/需求条目/场景/requirements/scenarios/规格变更”等时使用。
---

# DevBooks：规格 Delta（Spec Delta）

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

- 规格 delta：`<change-root>/<change-id>/specs/<capability>/spec.md`

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/5 规格变更提示词.md`。
