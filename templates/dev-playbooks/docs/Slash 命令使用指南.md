# DevBooks Slash 命令使用指南

本指南按变更闭环的阶段顺序，说明每个 Slash 命令的使用时机。

> **MCP 自动检测**：每个 Skill 执行时自动检测 MCP 可用性（2s 超时），无需手动选择"基础"或"增强"模式。

---

## 阶段概览

| 阶段 | 核心命令 | 说明 |
|------|----------|------|
| **Proposal** | proposal → impact → challenger/judge → design → spec → c4 → plan | 禁止写代码 |
| **Apply** | test → code → backport（如需） | 强制角色隔离 |
| **Review** | review → test-review | 审查代码与测试 |
| **Archive** | backport → spec → c4 → gardener | 合并到真理源 |
| **独立** | router / bootstrap / entropy / federation / index | 不属于单次变更 |

---

## Proposal（提案阶段）

> **核心原则**：禁止写实现代码，只产出设计文档

### 1. `/devbooks:proposal` - 创建变更提案（必做）

**使用时机**：每次变更的起点

```
/devbooks:proposal <你的需求>
```

**产物**：`<change-root>/<change-id>/proposal.md`

**包含内容**：
- Why（为什么要改）
- What（改什么）
- Impact（影响范围）
- Debate Packet（风险/替代方案/约束）

---

### 2. `/devbooks:impact` - 影响分析（跨模块/影响不清晰时必做）

**使用时机**：
- 变更涉及多个模块
- 不确定受影响范围
- 可能破坏兼容性

```
/devbooks:impact <change-id>
```

**产物**：更新 `proposal.md` 的 Impact 部分

**MCP 增强**：
- CKB 可用：使用 `analyzeImpact`、`getCallGraph`、`findReferences`
- CKB 不可用：降级为 Grep + Glob 文本搜索

---

### 3. `/devbooks:challenger` - 提案质疑（有争议/风险高时）

**使用时机**：
- 风险高、争议大
- 需要强约束审查
- 建议在新对话中执行（角色隔离）

```
/devbooks:challenger <change-id>
```

**产物**：质疑报告（结论必须为 `Approve | Revise | Reject`）

---

### 4. `/devbooks:judge` - 提案裁决（做了 Challenger 就必须）

**使用时机**：
- 有 Challenger 报告，需要最终裁决
- 建议在新对话中执行（角色隔离）

```
/devbooks:judge <change-id>
```

**产物**：更新 `proposal.md` 的 Decision Log（`Approved | Revise | Rejected`，禁止 Pending）

---

### 5. `/devbooks:debate` - 三角对辩流程（风险高/争议大时）

**使用时机**：
- 替代单独调用 challenger + judge
- 自动编排 Author → Challenger → Judge 流程

```
/devbooks:debate <change-id>
```

**产物**：
- 质疑报告
- 裁决结果
- 更新后的 `proposal.md`

---

### 6. `/devbooks:design` - 设计文档（非小改动建议做）

**使用时机**：
- 非 bug fix 或单行修改
- 需要明确约束、验收口径

```
/devbooks:design <change-id>
```

**产物**：`<change-root>/<change-id>/design.md`

**包含内容**：
- What（具体设计）
- Constraints（约束与边界）
- AC-xxx（验收标准）
- **禁止**写实现步骤

---

### 7. `/devbooks:spec` - 规格与契约（对外行为/契约变化时）

**使用时机**：
- 对外 API 变更
- 数据契约/Schema 变更
- 需要兼容策略

```
/devbooks:spec <change-id>
```

**产物**：
- `<change-root>/<change-id>/specs/<capability>/spec.md`（Requirements/Scenarios）
- 更新 `design.md` 的 Contract 章节

---

### 8. `/devbooks:c4` - C4 架构地图（边界/依赖变化时）

**使用时机**：
- 模块边界变化
- 依赖方向变化
- 新增/移除组件

```
/devbooks:c4 <change-id>
```

**Proposal 阶段行为**：
- **不修改**当前真理 `<truth-root>/architecture/c4.md`
- 输出 C4 Delta 到 `design.md`

---

### 9. `/devbooks:plan` - 实现计划（必做）

**使用时机**：
- 在 design.md 完成后
- Proposal 阶段的最后一步

```
/devbooks:plan <change-id>
```

**产物**：`<change-root>/<change-id>/tasks.md`

**包含内容**：
- 主线计划（Main Path）
- 临时计划（Temp Path，如有）
- 断点区（Breakpoint Zone）
- 每个任务的验收锚点

---

## Apply（实现阶段）

> **核心原则**：Test Owner 与 Coder 必须独立对话/独立实例

### 1. `/devbooks:test` - Test Owner（必做，必须新对话）

**使用时机**：
- Apply 阶段的第一步
- 必须先于 Coder 执行

```
/devbooks:test <change-id>
```

**角色约束**：
- 只读：`proposal.md`、`design.md`、`specs/**`
- 禁止参考：`tasks.md`

**产物**：
- `<change-root>/<change-id>/verification.md`（追溯矩阵）
- `tests/**`
- `evidence/` 下的失败证据

**要求**：必须先跑出 **Red** 基线

---

### 2. `/devbooks:code` - Coder（必做，必须新对话）

**使用时机**：
- Test Owner 完成后
- 必须在独立对话中执行

```
/devbooks:code <change-id>
```

**角色约束**：
- 严格按 `tasks.md` 实现
- **禁止**修改 `tests/**`
- 如需改测试，交还 Test Owner

**完成判据**：tests/静态检查/build 全绿

**MCP 增强**：
- CKB 可用：输出热点检查报告
- 热点 Top 5：先重构再修改

---

### 3. `/devbooks:backport` - 设计回写（发现设计缺口/冲突时）

**使用时机**：
- 实现中发现设计遗漏
- 需要上升到设计层的决策

```
/devbooks:backport <change-id>
```

**产物**：更新 `design.md`

**后续动作**：
- 重跑 Planner（更新 tasks.md）
- Test Owner 重新确认/补测试

---

## Review（评审阶段）

### 1. `/devbooks:review` - 代码评审（必做）

**使用时机**：
- Apply 阶段完成后
- PR 合并前

```
/devbooks:review <change-id>
```

**审查内容**：
- 可读性
- 依赖方向
- 一致性
- 复杂度
- 坏味道

**不讨论**：业务正确性

**MCP 增强**：
- CKB 可用：热点优先审查（Top 5 深度审查）

---

### 2. `/devbooks:test-review` - 测试评审（可选）

**使用时机**：
- 测试质量需特别关注
- 覆盖率/边界条件需审查

```
/devbooks:test-review <change-id>
```

**审查内容**：
- 测试覆盖率
- 边界条件
- 与 `verification.md` 的一致性

---

## Archive（归档阶段）

### 1. `/devbooks:backport` - 补齐遗漏决策

**使用时机**：归档前发现未记录的设计决策

---

### 2. `/devbooks:spec` - 落到真理源

**使用时机**：归档前需要把规格/契约更新到 `<truth-root>`

---

### 3. `/devbooks:c4` - 落到真理源

**使用时机**：归档前更新/校验 `<truth-root>/architecture/c4.md`

**Archive 阶段行为**：更新当前真理（而非只写 Delta）

---

### 4. `/devbooks:gardener` - 规格园丁（有 spec deltas 时）

**使用时机**：
- 本次变更产生了 spec deltas
- 需要合并到真理源

```
/devbooks:gardener <change-id>
```

**操作**：
- 去重/合并/归类/删除过时
- 只修改 `<truth-root>/**`
- 不修改 change 包内容

---

## 独立命令（不属于单次变更阶段）

### `/devbooks:router` - 路由建议（不确定下一步时）

**使用时机**：
- 不确定当前属于哪个阶段
- 需要 AI 给出最短闭环建议

```
/devbooks:router <你的需求>
```

---

### `/devbooks:bootstrap` - 存量项目初始化

**使用时机**：
- `<truth-root>` 为空
- 老项目首次接入 DevBooks

```
/devbooks:bootstrap
```

**产物**：
- 项目画像
- 术语表（可选）
- 基线规格
- 最小验证锚点

---

### `/devbooks:entropy` - 熵度量（定期体检）

**使用时机**：
- 定期代码健康检查
- 重构前获取量化数据

```
/devbooks:entropy
```

**产物**：熵度量报告（结构熵/变更熵/测试熵/依赖熵）

---

### `/devbooks:federation` - 跨仓库联邦分析

**使用时机**：
- 变更涉及对外 API/契约
- 多仓库项目需要分析下游影响

```
/devbooks:federation
```

**前置条件**：项目根目录存在 `.devbooks/federation.yaml`

---

### `/devbooks:index` - 索引引导

**使用时机**：
- `mcp__ckb__getStatus` 显示 SCIP 后端不可用
- 需要激活图基代码理解能力

```
/devbooks:index
```

**产物**：SCIP 索引文件

---

## 典型流程示例

### 小型变更（bug fix）

```
1. /devbooks:proposal <bug 描述>
2. /devbooks:plan <change-id>
3. /devbooks:test <change-id>    # 新对话
4. /devbooks:code <change-id>    # 新对话
5. /devbooks:review <change-id>
6. /devbooks:gardener <change-id>
```

### 中型变更（新功能）

```
1. /devbooks:proposal <功能需求>
2. /devbooks:impact <change-id>   # 跨模块时
3. /devbooks:design <change-id>
4. /devbooks:spec <change-id>     # 有契约变化时
5. /devbooks:plan <change-id>
6. /devbooks:test <change-id>     # 新对话
7. /devbooks:code <change-id>     # 新对话
8. /devbooks:review <change-id>
9. /devbooks:gardener <change-id>
```

### 大型/高风险变更

```
1. /devbooks:proposal <需求>
2. /devbooks:impact <change-id>
3. /devbooks:debate <change-id>   # 三角对辩
4. /devbooks:design <change-id>
5. /devbooks:spec <change-id>
6. /devbooks:c4 <change-id>       # 架构变化时
7. /devbooks:plan <change-id>
8. /devbooks:test <change-id>     # 新对话
9. /devbooks:code <change-id>     # 新对话
10. /devbooks:review <change-id>
11. /devbooks:gardener <change-id>
```

---

## 命令总览（24 个）

### 核心命令（21 个）

| 阶段 | 命令 | 对应 Skill |
|------|------|-----------|
| Proposal | `/devbooks:proposal` | `devbooks-proposal-author` |
| | `/devbooks:impact` | `devbooks-impact-analysis` |
| | `/devbooks:challenger` | `devbooks-proposal-challenger` |
| | `/devbooks:judge` | `devbooks-proposal-judge` |
| | `/devbooks:debate` | `devbooks-proposal-debate-workflow` |
| | `/devbooks:design` | `devbooks-design-doc` |
| | `/devbooks:spec` | `devbooks-spec-contract` |
| | `/devbooks:c4` | `devbooks-c4-map` |
| | `/devbooks:plan` | `devbooks-implementation-plan` |
| Apply | `/devbooks:test` | `devbooks-test-owner` |
| | `/devbooks:code` | `devbooks-coder` |
| | `/devbooks:backport` | `devbooks-design-backport` |
| Review | `/devbooks:review` | `devbooks-code-review` |
| | `/devbooks:test-review` | `devbooks-test-reviewer` |
| Archive | `/devbooks:gardener` | `devbooks-spec-gardener` |
| | `/devbooks:delivery` | `devbooks-delivery-workflow` |
| 独立 | `/devbooks:router` | `devbooks-router` |
| | `/devbooks:bootstrap` | `devbooks-brownfield-bootstrap` |
| | `/devbooks:entropy` | `devbooks-entropy-monitor` |
| | `/devbooks:federation` | `devbooks-federation` |
| | `/devbooks:index` | `devbooks-index-bootstrap` |

### 向后兼容命令（3 个）

| 命令 | 等价于 |
|------|--------|
| `/devbooks:coder` | `/devbooks:code` |
| `/devbooks:tester` | `/devbooks:test` |
| `/devbooks:reviewer` | `/devbooks:review` |
