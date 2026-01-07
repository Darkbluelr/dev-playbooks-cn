---
name: devbooks-c4-map
description: devbooks-c4-map：维护/更新项目的 C4 架构地图（当前真理），并按变更输出 C4 Delta。用户说“画架构图/C4/边界/依赖方向/模块地图/架构地图维护”等时使用。
---

# DevBooks：C4 架构地图

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

- 权威 C4 地图：`<truth-root>/architecture/c4.md`

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/8 C4 架构地图提示词.md`。
