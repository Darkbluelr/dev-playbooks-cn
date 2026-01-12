---
name: devbooks-proposal-author
description: devbooks-proposal-author：撰写变更提案 proposal.md（Why/What/Impact + Debate Packet），作为后续 Design/Spec/Plan 的入口。对设计性决策会呈现选项给用户选择。用户说"写提案/proposal/为什么要改/影响范围/坏味道重构提案"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：提案撰写（Proposal Author）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 核心职责

1. **提案撰写**：产出清晰、可审查、可落地的变更提案
2. **设计性决策交互**：对于无法客观判断好坏的设计选择，呈现选项给用户决策，不自行拍板

## 产物落点

- 提案：`<change-root>/<change-id>/proposal.md`

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/提案撰写提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的运行模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测变更包是否存在
2. 检测 `proposal.md` 是否已存在
3. 若存在，检测是否有 Decision Log（是否已裁决）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **新建提案** | 变更包不存在或 `proposal.md` 不存在 | 创建完整提案文档 |
| **修订提案** | `proposal.md` 存在，Judge 要求 Revise | 根据裁决意见修改提案 |
| **补充 Impact** | `proposal.md` 存在但缺少 Impact 章节 | 补充影响分析部分 |

### 检测输出示例

```
检测结果：
- 变更包状态：存在
- proposal.md：存在
- 裁决状态：Revise（需要修改）
- 运行模式：修订提案
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

