---
name: devbooks-archiver
description: devbooks-archiver：归档阶段的唯一入口，负责完整的归档闭环（自动回写→规格合并→文档同步检查→变更包归档移动）。用户说"归档/archive/收尾/闭环/合并到真理"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：归档器（Archiver）

## 工作流位置感知（Workflow Position Awareness）

> **核心原则**：Archiver 是归档阶段的**唯一入口**，负责完成从代码评审到变更包归档的所有收尾工作。

### 我在整体工作流中的位置

```
proposal → design → test-owner(P1) → coder → test-owner(P2) → code-review → [Archiver]
                                                                                  ↓
                                               自动回写 → 规格合并 → 文档检查 → 移动归档
```

### 为什么重命名为 Archiver？

| 旧名称 | 新名称 | 变更原因 |
|--------|--------|----------|
| `spec-gardener` | `archiver` | 职责已扩展，不仅是规格合并，而是完整的归档闭环 |

### Archiver 的完整职责

| 阶段 | 职责 | 说明 |
|------|------|------|
| 1 | 自动回写检测与处理 | 检测 deviation-log.md，自动回写设计文档 |
| 2 | 规格合并 | 将 specs/contracts 合并到 truth-root |
| 3 | 架构合并 | 将 design.md 的 Architecture Impact 合并到 c4.md |
| 4 | 文档同步检查 | 检查 design.md 的 Documentation Impact 是否已处理 |
| 5 | 变更包归档移动 | 将变更包移动到 `<change-root>/archive/` |

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

---

## 归档完整流程

### 第 1 步：前置检查

```markdown
前置检查清单：
- [ ] 变更包存在（<change-root>/<change-id>/）
- [ ] verification.md Status = Ready 或 Done
- [ ] evidence/green-final/ 存在且非空
- [ ] tasks.md 所有任务已完成（[x]）
- [ ] 代码评审已通过（verification.md Status = Done 由 Reviewer 设置）
```

若检查失败 → 停止并输出缺失项，建议用户先完成前置步骤。

### 第 2 步：自动回写检测与处理

> **设计决策**：归档阶段自动处理所有未回写的偏离，用户无需手动调用 design-backport。

**检测流程**：

```
1. 读取 <change-root>/<change-id>/deviation-log.md
2. 检查是否有 "| ❌" 未回写记录
   → 有：执行自动回写（步骤 3-5）
   → 无：跳过，直接进入合并阶段

3. 对每条未回写记录，判断是否为 Design-level 内容：
   - DESIGN_GAP, CONSTRAINT_CHANGE, API_CHANGE → 需要回写
   - 纯实现细节（文件名/类名/临时步骤） → 不回写，标记为 IMPL_ONLY

4. 执行设计回写：
   - 读取 design.md
   - 按 design-backport 协议的"可回写内容范围"更新
   - 在 design.md 末尾添加变更记录

5. 更新 deviation-log.md：
   - 将已回写的记录标记为 ✅
   - 记录回写时间和归档批次
```

**自动回写的内容范围**（继承自 design-backport）：

| 可回写 | 不可回写 |
|--------|----------|
| 对外语义/用户可感知行为 | 具体文件路径、类名/函数名 |
| 系统级不可变约束（Invariants） | PR 切分、任务执行顺序 |
| 核心数据契约与演进策略 | 过细的算法伪代码 |
| 跨阶段治理策略 | 脚本命令 |
| 关键取舍与决策 | 表名/字段名 |

### 第 3 步：规格合并

将变更包中的规格产物合并到 `<truth-root>`：

| 源路径 | 目标路径 | 合并策略 |
|--------|----------|----------|
| `<change-root>/<change-id>/specs/**` | `<truth-root>/specs/**` | 增量合并 |
| `<change-root>/<change-id>/contracts/**` | `<truth-root>/contracts/**` | 版本化合并 |

**Spec 元信息更新**（合并时必须执行）：

在合并 spec 到 truth-root 时，必须更新以下元信息：

```yaml
# 在每个被合并/引用的 spec 文件头部更新
---
last_referenced_by: <change-id>           # 最后引用此 spec 的变更包
last_verified: <归档日期>                  # 最后验证日期
health: active                            # 健康状态：active | stale | deprecated
---
```

**元信息更新规则**：

| 场景 | 更新行为 |
|------|----------|
| 新增 Spec | 创建完整元信息头 |
| 修改已有 Spec | 更新 `last_referenced_by` 和 `last_verified` |
| Spec 被设计文档引用但未修改 | 仅更新 `last_referenced_by` |
| 标记为废弃 | 设置 `health: deprecated` |

**建立引用追溯链**：

归档时，archiver 会自动扫描 design.md 中声明的 "受影响的 Spec"（Affected Specs），并更新这些 Spec 的 `last_referenced_by` 字段，即使它们没有被直接修改。这建立了从 Spec 到变更包的反向追溯链。

### 第 4 步：架构合并

> **设计决策**：C4 架构变更通过 design.md 的 Architecture Impact 章节记录，由 Archiver 在归档时合并到真理。

**C4 合并流程**：

1. **检测架构变更**：解析 `design.md` 中的 "Architecture Impact" 章节
2. **判断是否需要合并**：
   - 若 "无架构变更" 被勾选 → 跳过合并
   - 若 "有架构变更" → 执行合并
3. **执行合并**：
   - 读取 `<truth-root>/architecture/c4.md`（若不存在则创建）
   - 根据 Architecture Impact 中的变更描述更新对应章节
   - 更新 Container/Component 表格
   - 更新依赖关系
   - 更新分层约束（如有变更）
4. **记录合并日志**：在 c4.md 末尾添加变更记录

### 第 5 步：文档同步检查

检查 design.md 的 "Documentation Impact" 章节：

```markdown
检查项：
- [ ] 若声明了"需要更新的文档"，验证这些文档已更新
- [ ] 若勾选了"无需更新"，确认合理性
- [ ] 输出文档同步状态报告
```

**若有未处理的文档更新**：
- 输出警告，列出需要更新的文档
- 不阻塞归档，但在归档报告中标记为 "文档待更新"

### 第 6 步：变更包归档移动（新增）

将已完成的变更包移动到归档目录：

```bash
# 源路径
<change-root>/<change-id>/

# 目标路径
<change-root>/archive/<change-id>/
```

**移动流程**：

1. **创建归档目录**（如不存在）：`<change-root>/archive/`
2. **设置最终状态**：在 verification.md 中设置 `Status: Archived`
3. **添加归档时间戳**：在 verification.md 末尾添加 `Archived-At: <timestamp>`
4. **移动变更包**：`mv <change-root>/<change-id>/ <change-root>/archive/<change-id>/`
5. **输出归档完成报告**

**verification.md 归档状态更新**：

```markdown
---
status: Archived
archived-at: 2024-01-16T10:30:00Z
archived-by: devbooks-archiver
---
```

---

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词执行：`references/归档器提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的运行模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `<truth-root>/` 目录状态
2. 若提供 change-id，检测变更包归档条件
3. 检测重复/过时规格（维护模式）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **归档模式** | 提供 change-id 且闸门通过 | 执行完整归档流程（6步） |
| **维护模式** | 无 change-id | 执行 truth-root 去重、清理、整理 |
| **检查模式** | 带 --dry-run 参数 | 只输出计划，不实际修改/移动 |

### 归档模式完整流程图

```
┌─────────────────────────────────────────────────────────────┐
│                      归档模式流程                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 前置检查                                                 │
│     ├─ 变更包存在？                                          │
│     ├─ verification.md Status = Ready/Done？                │
│     ├─ evidence/green-final/ 存在？                          │
│     └─ tasks.md 全部完成？                                   │
│              │                                               │
│              ▼                                               │
│  2. 自动回写                                                 │
│     ├─ 读取 deviation-log.md                                │
│     ├─ 检测未回写记录                                        │
│     └─ 执行回写 → 更新标记                                   │
│              │                                               │
│              ▼                                               │
│  3. 规格合并                                                 │
│     ├─ specs/** → truth-root/specs/**                       │
│     └─ contracts/** → truth-root/contracts/**               │
│              │                                               │
│              ▼                                               │
│  4. 架构合并                                                 │
│     └─ Architecture Impact → c4.md                          │
│              │                                               │
│              ▼                                               │
│  5. 文档同步检查                                             │
│     └─ 检查 Documentation Impact 是否已处理                  │
│              │                                               │
│              ▼                                               │
│  6. 变更包归档移动                                           │
│     ├─ 设置 Status: Archived                                │
│     └─ mv <change-id>/ → archive/<change-id>/               │
│              │                                               │
│              ▼                                               │
│  ✅ 输出归档完成报告                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 检测输出示例

```
检测结果：
- truth-root：存在，包含 12 个 spec 文件
- 变更包：存在，闸门全绿
- 回写状态：2 条待回写记录
- 运行模式：归档模式（完整流程）
```

---

## 归档报告模板

归档完成后，输出以下报告：

```markdown
## 归档报告

### 变更包信息
- Change ID: <change-id>
- 归档时间: <timestamp>

### 执行摘要
| 步骤 | 状态 | 说明 |
|------|------|------|
| 前置检查 | ✅ | 全部通过 |
| 自动回写 | ✅ | 回写 2 条记录 |
| 规格合并 | ✅ | 合并 3 个 spec 文件 |
| 架构合并 | ⏭️ | 无架构变更 |
| 文档检查 | ⚠️ | README.md 待更新 |
| 归档移动 | ✅ | 已移动到 archive/ |

### 归档位置
`<change-root>/archive/<change-id>/`

### 后续建议
- [ ] 更新 README.md（文档检查警告）
```

---

## 维护模式职责

在维护模式下（无 change-id）执行：

- 检测重复的规格定义
- 清理过时/废弃的规格
- 整理目录结构
- 修复一致性问题

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`
