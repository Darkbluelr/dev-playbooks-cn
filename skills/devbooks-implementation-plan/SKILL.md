---
name: devbooks-implementation-plan
description: devbooks-implementation-plan：从设计文档推导编码计划（tasks.md），输出可跟踪的主线计划/临时计划/断点区，并绑定验收锚点。用户说"写编码计划/Implementation Plan/tasks.md/任务拆解/并行拆分/里程碑/验收锚点"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：编码计划（Implementation Plan）

## 工作流位置感知（Workflow Position Awareness）

> **核心原则**：Implementation Plan 在 Design Doc 之后执行，为 Test Owner 和 Coder 提供任务清单。

### 我在整体工作流中的位置

```
proposal → design → [Implementation Plan] → test-owner(阶段1) → coder → ...
                            ↓
                    tasks.md（任务清单）
```

### Implementation Plan 的职责

| 允许 | 禁止 |
|------|------|
| 从 design.md 推导任务 | ❌ 参考 tests/（避免实现偏见） |
| 绑定验收锚点 (AC-xxx) | ❌ 写实现代码 |
| 拆分并行任务 | ❌ 执行任务 |

### 产出：tasks.md 结构

```markdown
## 主线计划区
- [ ] MP1.1 任务描述 (AC-001)
- [ ] MP1.2 任务描述 (AC-002)

## 临时计划区
（紧急任务）

## 断点区
（中断续做信息）
```

---

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

## 产物落点

- 编码计划：`<change-root>/<change-id>/tasks.md`

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/编码计划提示词.md`（只从设计推导，不参考 tests/）。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的运行模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `design.md` 是否存在（计划的输入）
2. 检测 `tasks.md` 是否已存在
3. 若存在，检测进度（完成/进行中/待开始）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **新建计划** | `tasks.md` 不存在 | 从 design.md 推导完整计划 |
| **更新计划** | `tasks.md` 存在，design.md 有更新 | 同步计划与设计变更 |
| **添加临时任务** | 发现计划外紧急任务 | 添加到临时计划区 |

### Planner 约束

- 只读 design.md 和 specs/
- **不得参考 tests/**（避免实现偏见）
- 不得写实现代码

### 检测输出示例

```
检测结果：
- design.md：存在，AC 数量 14 个
- tasks.md：不存在
- 运行模式：新建计划
```

---

## 下一步推荐

**参考**：`skills/_shared/workflow-next-steps.md`

完成 implementation-plan 后，**必须**的下一步是：

| 条件 | 下一个 Skill | 原因 |
|------|--------------|------|
| 始终 | `devbooks-test-owner` | Test Owner 必须先产出 Red 基线 |

**关键**：
- Test Owner **必须在单独的会话/实例中工作**
- 绝不在 implementation-plan 后直接推荐 `devbooks-coder`
- 工作流顺序是：
```
implementation-plan → test-owner (会话A) → coder (会话B)
```

### 输出模板

完成 implementation-plan 后，输出：

```markdown
## 推荐的下一步

**下一步：`devbooks-test-owner`**（必须在单独的会话中）

原因：实现计划已完成。下一步是让 Test Owner 创建验证测试并产出 Red 基线。Test Owner 和 Coder 必须在不同会话中工作以确保角色隔离。

### 如何调用（在新会话中）
```
运行 devbooks-test-owner skill 处理变更 <change-id>
```

**重要**：Test Owner 产出 Red 基线后，在另一个单独的会话中启动 Coder：
```
运行 devbooks-coder skill 处理变更 <change-id>
```
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

