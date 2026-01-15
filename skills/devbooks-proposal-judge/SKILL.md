---
name: devbooks-proposal-judge
description: devbooks-proposal-judge：对 proposal 阶段进行裁决（Judge），输出 Approved/Revise/Rejected 并写回 proposal.md 的 Decision Log。用户说"裁决提案/提案评审/Approved Revise Rejected/decision log"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：提案裁决（Proposal Judge）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出裁决：`references/提案裁决提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，确保角色隔离。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `proposal.md` 是否存在
2. 检测是否有 Challenger 的质疑意见
3. 检测当前会话是否已执行过 Author/Challenger 角色

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **首次裁决** | 无裁决记录 | 综合评估提案和质疑，输出裁决 |
| **复议裁决** | Author 修改后重新提交 | 重新评估修改内容 |

### 角色隔离检查

- [ ] 当前会话未执行过 Author
- [ ] 当前会话未执行过 Challenger

### 检测输出示例

```
检测结果：
- proposal.md：存在
- Challenger 意见：存在（3 个风险点）
- 角色隔离：✓
- 运行模式：首次裁决
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

