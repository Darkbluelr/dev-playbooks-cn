---
name: devbooks-brownfield-bootstrap
description: devbooks-brownfield-bootstrap：存量项目初始化：在当前真理目录为空时生成项目画像、术语表、基线规格与最小验证锚点，避免“边补 specs 边改行为”。用户说“存量初始化/基线 specs/项目画像/建立 glossary/把老项目接入上下文协议”等时使用。
---

# DevBooks：存量项目初始化（Brownfield Bootstrap）

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

## 参考骨架与模板

- 工作流：`references/存量项目初始化.md`
- 一次性提示词：`references/9 存量项目初始化提示词.md`
- 模板（按需）：`references/10 术语表模板.md`
