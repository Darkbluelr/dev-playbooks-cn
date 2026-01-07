---
name: devbooks-impact-analysis
description: devbooks-impact-analysis：跨模块/跨文件/对外契约变更前做影响分析，产出可直接写入 proposal.md 的 Impact 部分（Scope/Impacts/Risks/Minimal Diff/Open Questions）。用户说“做影响分析/改动面控制/引用查找/受影响模块/兼容性风险”等时使用。
---

# DevBooks：影响分析（Impact Analysis）

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

- 推荐写入：`<change-root>/<change-id>/proposal.md` 的 Impact 部分（或独立分析文档后再回填）

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出影响分析 Markdown：`references/6 影响分析提示词.md`。
