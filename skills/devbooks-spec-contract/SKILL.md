---
name: devbooks-spec-contract
description: devbooks-spec-contract：定义对外行为规格与契约（Requirements/Scenarios/API/Schema/兼容策略/迁移），并建议或生成 contract tests。合并了原 spec-delta 和 contract-data 的功能。用户说"写规格/spec/契约/OpenAPI/Schema/兼容策略/contract tests"等时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：规格与契约（Spec & Contract）

> 本 skill 合并了原 `devbooks-spec-delta` 和 `devbooks-contract-data` 的功能，减少选择困难。

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

## 产物落点

| 产物类型 | 落点路径 |
|----------|----------|
| 规格 delta | `<change-root>/<change-id>/specs/<capability>/spec.md` |
| 契约计划 | `<change-root>/<change-id>/design.md`（Contract 章节）或独立 `contract-plan.md` |
| Contract Test IDs | 写入 `verification.md` 的追溯矩阵 |
| 隐式变更报告 | `<change-root>/<change-id>/evidence/implicit-changes.json` |

---

## 使用场景判断

| 场景 | 需要做什么 |
|------|-----------|
| 只有行为变化（无 API/Schema） | 只输出 spec.md（Requirements/Scenarios） |
| 有 API/Schema/事件变化 | 输出 spec.md + 契约计划 + Contract Test IDs |
| 有兼容性风险 | 额外输出兼容策略、弃用策略、迁移方案 |
| 依赖/配置/构建变更 | 运行隐式变更检测 |

---

## 执行方式

### 标准流程

1) 先阅读并遵守：`_shared/references/通用守门协议.md`
2) 规格部分：按 `references/规格变更提示词.md` 输出 Requirements/Scenarios
3) 契约部分：按 `references/契约与数据定义提示词.md` 输出契约计划
4) **隐式变更检测（按需）**：`references/隐式变更检测提示词.md`

### 输出结构（一次性产出）

```markdown
## 规格 Delta（Spec）

### Requirements
- REQ-XXX-001: <需求描述>

### Scenarios
- SC-001: <场景描述>
  - Given: ...
  - When: ...
  - Then: ...

---

## 契约计划（Contract）

### API 变更
- 新增/修改端点：`POST /api/v1/orders`
- OpenAPI diff 位置：`contracts/openapi/orders.yaml`

### 兼容策略
- 向后兼容：是/否
- 弃用策略：<如有>
- 迁移方案：<如有>

### Contract Test IDs
| Test ID | 类型 | 覆盖场景 |
|---------|------|----------|
| CT-001 | schema | REQ-XXX-001 |
| CT-002 | behavior | SC-001 |
```

---

## 脚本

- 隐式变更检测：`scripts/implicit-change-detect.sh <change-id> [--base <commit>] [--project-root <dir>] [--change-root <dir>]`

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的运行模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `<change-root>/<change-id>/specs/` 是否存在
2. 若存在，判断完整性（是否有占位符、REQ 是否有 Scenario）
3. 根据检测结果选择运行模式

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **从零创建** | `specs/` 目录不存在或为空 | 创建完整规格文档结构，包含 Requirements/Scenarios |
| **补漏模式** | `specs/` 存在但不完整（有 `[TODO]`、REQ 缺 Scenario） | 补充缺失的 Requirement/Scenario，保留已有内容 |
| **同步模式** | `specs/` 完整，需要与实现同步 | 检查实现与规格一致性，输出 diff 报告 |

### 检测输出示例

```
检测结果：
- 产物存在性：specs/ 存在
- 完整性：不完整（缺失项：REQ-002 无 Scenario）
- 当前阶段：apply
- 运行模式：补漏模式
```

---

## 隐式变更检测（扩展功能）

> 来源：《人月神话》第7章"巴比伦塔" — "小组慢慢地修改自己程序的功能，隐含地更改了约定"

隐式变更 = 没有显式声明但会改变系统行为的变更。

**检测范围**：
- 依赖变更（package.json / requirements.txt / go.mod 等）
- 配置变更（*.env / *.config.* / *.yaml 等）
- 构建变更（tsconfig.json / Dockerfile / CI 配置等）

**与 change-check.sh 集成**：
- 在 `apply` / `archive` / `strict` 模式下自动检查隐式变更报告
- 高风险隐式变更需在 `design.md` 中声明

---

## 下一步推荐

**参考**：`skills/_shared/workflow-next-steps.md`

完成 spec-contract 后，**必须**的下一步是：

| 条件 | 下一个 Skill | 原因 |
|------|--------------|------|
| 始终 | `devbooks-implementation-plan` | 必须先创建 tasks.md 再进入实施阶段 |

**关键**：绝不在 spec-contract 后直接推荐 `devbooks-test-owner` 或 `devbooks-coder`。工作流顺序是：
```
spec-contract → implementation-plan → test-owner → coder
```

### 输出模板

完成 spec-contract 后，输出：

```markdown
## 推荐的下一步

**下一步：`devbooks-implementation-plan`**

原因：规格和契约已定义。下一步是创建实现计划（tasks.md），将工作分解为可追踪的任务，并绑定验证锚点。

### 如何调用
```
运行 devbooks-implementation-plan skill 处理变更 <change-id>
```
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__findReferences` | 检测契约引用范围 | 2s |
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若 CKB 可用 → 使用 `findReferences` 检测契约符号的引用范围
3. 若超时或失败 → 降级到 Grep 文本搜索

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 引用检测 | 符号级精确匹配 | Grep 文本搜索 |
| 契约影响范围 | 调用图分析 | 直接引用统计 |
| 兼容性风险 | 自动评估 | 手动判断 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 不可用，使用 Grep 文本搜索检测契约引用。
结果可能不够精确，建议手动生成 SCIP 索引。
```
