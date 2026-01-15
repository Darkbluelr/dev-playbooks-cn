# DevBooks 工作流下一步参考

本文档定义了每个 skill 的标准下一步推荐。所有 skill 应引用此文件以确保一致的工作流指导。

## 工作流顺序

```
┌─────────────────────────────────────────────────────────────────┐
│                     提案阶段 (PROPOSAL)                          │
│  proposal-author → impact-analysis → design-doc → spec-contract │
│                                          ↓                       │
│                                implementation-plan               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     实施阶段 (APPLY)                             │
│      test-owner (会话A) ←→ coder (会话B)                        │
│      (必须在不同会话中进行)                                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     评审阶段 (REVIEW)                            │
│                      code-review                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     归档阶段 (ARCHIVE)                           │
│                         archiver                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 下一步矩阵

| 当前 Skill | 下一步 | 条件 |
|------------|--------|------|
| `devbooks-proposal-author` | `devbooks-impact-analysis` | 如果跨模块影响不明确 |
| `devbooks-proposal-author` | `devbooks-design-doc` | 如果影响明确 |
| `devbooks-proposal-author` | `devbooks-proposal-challenger` | 如果高风险（可选） |
| `devbooks-impact-analysis` | `devbooks-design-doc` | 始终 |
| `devbooks-proposal-challenger` | `devbooks-proposal-judge` | 始终 |
| `devbooks-proposal-judge` | `devbooks-design-doc` | 如果 Approved/Revise |
| `devbooks-design-doc` | `devbooks-spec-contract` | 如果有外部行为/契约变更 |
| `devbooks-design-doc` | `devbooks-implementation-plan` | 如果无外部契约变更 |
| `devbooks-spec-contract` | `devbooks-implementation-plan` | 始终（绝不直接推荐 test-owner/coder） |
| `devbooks-implementation-plan` | `devbooks-test-owner` | 始终（必须单独会话） |
| `devbooks-test-owner` | `devbooks-coder` | Red 基线后（必须单独会话） |
| `devbooks-coder` | `devbooks-code-review` | 所有任务完成后 |
| `devbooks-code-review` | `devbooks-archiver` | 如果有 spec deltas |
| `devbooks-code-review` | 归档完成 | 如果无 spec deltas |
| `devbooks-test-reviewer` | `devbooks-coder` | 如果发现测试问题，交回 |
| `devbooks-design-backport` | `devbooks-implementation-plan` | 设计更新后重跑计划 |
| `devbooks-archiver` | 归档完成 | 始终 |

## 关键约束

### 提案阶段流程
```
proposal-author → [impact-analysis] → design-doc → [spec-contract] → implementation-plan
```
- 如果有外部行为/契约变更，`spec-contract` 是必需的
- 对于跨模块变更，推荐使用 `impact-analysis`
- **绝不从 spec-contract 或 design-doc 直接跳到 test-owner/coder**

### 实施阶段流程
```
implementation-plan → test-owner (会话A) ←→ coder (会话B)
```
- Test Owner 和 Coder **必须在不同会话中**
- Test Owner 先产出 Red 基线
- Coder 按 tasks.md 实现，让闸门变绿

### 角色隔离规则
- Author、Challenger、Judge：辩论需在不同会话
- Test Owner、Coder：不同会话（硬性要求）
- Coder **不能修改** `tests/**`

## 标准下一步输出格式

推荐下一步时，使用此格式：

```markdown
## 推荐的下一步

根据当前产物，推荐的下一个 skill 是：

**下一步：`devbooks-<skill-name>`**

原因：<为什么这个 skill 是工作流中的下一步>

### 如何调用
```
运行 devbooks-<skill-name> skill 处理变更 <change-id>
```

### 替代路径（如适用）
- 如果 <条件>：改用 `devbooks-<alternative-skill>`
```

## 常见错误避免

1. **在 spec-contract 后直接推荐 test-owner/coder**
   - 正确：spec-contract → implementation-plan → test-owner

2. **在 design-doc 后直接推荐 coder**
   - 正确：design-doc → [spec-contract] → implementation-plan → test-owner → coder

3. **在同一会话中推荐 test-owner 和 coder**
   - 正确：始终提醒"必须在不同会话中"

4. **跳过 implementation-plan**
   - implementation-plan 在实施阶段前是必需的
