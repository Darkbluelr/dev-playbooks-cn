---
name: devbooks-proposal-challenger
description: devbooks-proposal-challenger：对 proposal.md 发起质疑（Challenger）+ 查漏补缺，指出风险/遗漏/不一致并给结论，发现缺失的验收标准和未覆盖场景。用户说"质疑提案/挑刺/风险评估/提案对辩 challenger/查漏补缺"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
---

# DevBooks：提案质疑 + 查漏补缺（Proposal Challenger）

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

## 核心职责

1. **质疑审查**：对提案进行强约束审查，指出风险、不一致和设计缺陷
2. **查漏补缺**：主动发现提案中遗漏的内容，包括：
   - 缺失的验收标准（AC）
   - 未覆盖的边界场景
   - 未定义的回滚策略
   - 遗漏的依赖分析
   - 缺少的证据落点

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出质疑报告：`references/提案质疑提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，确保角色隔离。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `proposal.md` 是否存在
2. 检测当前会话是否已执行过 Author 角色
3. 检测是否已有 Challenger 的质疑意见

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **首次质疑** | 无质疑记录 | 执行完整质疑流程 |
| **补充质疑** | 已有质疑，Author 修改后 | 针对修改部分补充质疑 |

### 角色隔离检查

- [ ] 当前会话未执行过 Author
- [ ] 当前会话未执行过 Judge

### 检测输出示例

```
检测结果：
- proposal.md：存在
- 角色隔离：✓（当前会话未执行 Author/Judge）
- 质疑历史：无
- 运行模式：首次质疑
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

