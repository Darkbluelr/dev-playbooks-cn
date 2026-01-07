---
name: devbooks-coder
description: devbooks-coder：以 Coder 角色严格按 tasks.md 实现功能并跑闸门，禁止修改 tests/，以测试/静态检查为唯一完成判据。用户说“按计划实现/修复测试失败/让闸门全绿/实现任务项/不改测试”，或在 OpenSpec apply 阶段以 coder 执行时使用。
---

# DevBooks：实现负责人（Coder）

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

## 关键约束

- 禁止修改 `tests/**`（需要改测试必须交还 Test Owner）。

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词执行：`references/11 代码实现提示词.md`。
