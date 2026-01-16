---
name: devbooks-impact-analysis
description: devbooks-impact-analysis：跨模块/跨文件/对外契约变更前做影响分析，产出可直接写入 proposal.md 的 Impact 部分（Scope/Impacts/Risks/Minimal Diff/Open Questions）。用户说"做影响分析/改动面控制/引用查找/受影响模块/兼容性风险"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Bash
---

# DevBooks：影响分析（Impact Analysis）

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

- **必须**写入：`<change-root>/<change-id>/proposal.md` 的 Impact 部分
- 备选：独立 `impact-analysis.md` 文件（后续回填到 proposal.md）

## 输出行为（关键约束）

> **黄金法则**：**直接写入文档，禁止输出到对话窗口**

### 必须遵守

1. **直接写入**：使用 `Edit` 或 `Write` 工具将分析结果直接写入目标文档
2. **禁止回显**：不要在对话中显示完整的分析内容
3. **简短通知**：完成后只需告知用户"影响分析已写入 `<文件路径>`"

### 正确行为 vs 错误行为

| 场景 | ❌ 错误行为 | ✅ 正确行为 |
|------|------------|------------|
| 分析完成 | 在对话中输出完整 Impact 表格 | 使用 Edit 工具写入 proposal.md |
| 通知用户 | 复述分析内容 | "影响分析已写入 `changes/xxx/proposal.md`" |
| 大量结果 | 分页输出到对话 | 全部写入文件，告知文件位置 |

### 示例对话

```
用户：分析一下修改 UserService 的影响

AI：[使用 Grep/CKB 分析引用]
    [使用 Edit 工具写入 proposal.md]

    影响分析已写入 `changes/refactor-user/proposal.md` 的 Impact 部分。
    - 直接影响：8 个文件
    - 间接影响：12 个文件
    - 风险等级：中等

    如需查看详情，请打开该文件。
```

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 使用 `Grep` 搜索符号引用，`Glob` 查找相关文件。
3) 严格按完整提示词输出影响分析 Markdown：`references/影响分析提示词.md`。

## 输出格式

```markdown
## Impact Analysis

### Scope
- 直接影响：X 个文件
- 间接影响：Y 个文件

### Impacts
| 文件 | 影响类型 | 风险等级 |
|------|----------|----------|
| ... | 直接调用 | 高 |

### Risks
- ...

### Minimal Diff
- ...

### Open Questions
- ...
```

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的分析范围。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测变更包是否存在
2. 检测 `proposal.md` 中是否已有 Impact 章节
3. 检测是否有 CKB 索引可用（增强分析能力）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **新建分析** | Impact 章节不存在 | 执行完整影响分析 |
| **增量分析** | Impact 已存在，有新变更 | 更新受影响文件列表 |
| **增强分析** | CKB 索引可用 | 使用调用图进行精确分析 |
| **基础分析** | CKB 索引不可用 | 使用 Grep 文本搜索分析 |

### 检测输出示例

```
检测结果：
- proposal.md：存在，Impact 章节缺失
- CKB 索引：可用
- 运行模式：新建分析 + 增强模式
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__analyzeImpact` | 符号级影响分析 | 2s |
| `mcp__ckb__findReferences` | 精确引用查找 | 2s |
| `mcp__ckb__getCallGraph` | 调用图分析 | 2s |
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若 CKB 可用 → 使用 `analyzeImpact` 和 `findReferences` 进行精确分析
3. 若超时或失败 → 降级到基础模式（Grep 文本搜索）

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 引用查找 | 符号级精确匹配 | 文本 Grep 搜索 |
| 影响范围 | 调用图传递分析 | 直接引用统计 |
| 风险评估 | 基于调用深度量化 | 基于文件数量估算 |
| 跨模块分析 | 自动识别模块边界 | 需手动指定范围 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 不可用，使用 Grep 文本搜索进行影响分析。
分析结果可能不够精确，建议手动生成 SCIP 索引后重新分析。
```

