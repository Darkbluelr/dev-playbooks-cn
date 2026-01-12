---
name: devbooks-spec-gardener
description: devbooks-spec-gardener：归档前修剪与维护 <truth-root>（去重合并/删除过时/目录整理/一致性修复），避免 specs 堆叠失控。用户说"规格园丁/specs 去重合并/归档前整理/清理过时规范"，或在 DevBooks archive/归档前收尾时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：规格园丁（Spec Gardener）

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
2) 严格按完整提示词执行：`references/规格园丁提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的维护模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `<truth-root>/` 目录状态
2. 若提供 change-id，检测变更包归档条件
3. 检测重复/过时规格

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **归档模式** | 提供 change-id 且闸门通过 | 将变更包产物合并到 truth-root |
| **维护模式** | 无 change-id | 执行去重、清理、整理操作 |
| **检查模式** | 带 --dry-run 参数 | 只输出建议，不实际修改 |

### 检测输出示例

```
检测结果：
- truth-root：存在，包含 12 个 spec 文件
- 变更包：存在，闸门全绿
- 运行模式：归档模式
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

