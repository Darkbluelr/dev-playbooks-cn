---
name: devbooks-spec-gardener
description: devbooks-spec-gardener：归档前修剪与维护 <truth-root>（去重合并/删除过时/目录整理/一致性修复），避免 specs 堆叠失控。用户说“规格园丁/specs 去重合并/归档前整理/清理过时规范”，或在 OpenSpec archive/归档前收尾时使用。
---

# DevBooks：规格园丁（Spec Gardener）

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
2) 严格按完整提示词执行：`references/10 规格园丁提示词.md`。
