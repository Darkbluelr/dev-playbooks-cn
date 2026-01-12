---
name: devbooks-design-backport
description: devbooks-design-backport：把实现过程中发现的新约束/冲突/缺口回写到 design.md（保持设计为黄金真理），并标注决策与影响。用户说"回写设计/补充设计文档/Design Backport/设计与实现不一致/需要澄清约束"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：回写设计文档（Design Backport）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
4. `project.md`（如存在）→ template 协议，使用默认映射
5. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词执行：`references/回写设计文档提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，识别需要回写的内容。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `design.md` 是否存在
2. 检测实现过程中是否有新发现（冲突/约束/缺口）
3. 对比设计与实现的差异

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **冲突回写** | 发现设计与实现冲突 | 记录冲突点和解决方案 |
| **约束回写** | 发现新的实现约束 | 补充约束条件到设计 |
| **缺口回写** | 发现设计未覆盖的场景 | 补充遗漏的设计决策 |

### 检测输出示例

```
检测结果：
- design.md：存在
- 发现内容：2 个新约束，1 个设计冲突
- 运行模式：约束回写 + 冲突回写
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

