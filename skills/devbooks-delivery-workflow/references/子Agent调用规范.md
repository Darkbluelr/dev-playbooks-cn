# 子 Agent 调用规范

## 调用格式

使用 Task 工具调用子 Agent：

```markdown
## 调用 devbooks-proposal-author 子 Agent

请执行以下任务：
- 使用 devbooks-proposal-author skill
- 为以下需求创建变更提案：[需求描述]
- 生成符合规范的 change-id
- 完成后输出 change-id 和 proposal.md 路径
```

## 各阶段调用示例

| 阶段 | 子 Agent | 调用 Prompt |
|------|----------|-------------|
| 1 | devbooks-proposal-author | "使用 devbooks-proposal-author skill 为 [需求] 创建变更提案" |
| 2 | devbooks-challenger | "使用 devbooks-proposal-challenger skill 质疑变更 [change-id] 的提案" |
| 3 | devbooks-judge | "使用 devbooks-proposal-judge skill 裁决变更 [change-id]" |
| 4 | devbooks-designer | "使用 devbooks-design-doc skill 为变更 [change-id] 创建设计文档" |
| 5 | devbooks-spec-owner | "使用 devbooks-spec-contract skill 为变更 [change-id] 定义规格" |
| 6 | devbooks-planner | "使用 devbooks-implementation-plan skill 为变更 [change-id] 创建计划" |
| 7 | devbooks-test-owner | "使用 devbooks-test-owner skill 为变更 [change-id] 编写测试并建立 Red 基线" |
| 8 | devbooks-coder | "使用 devbooks-coder skill 为变更 [change-id] 实现功能" |
| 9 | devbooks-reviewer | "使用 devbooks-test-reviewer skill 评审变更 [change-id] 的测试" |
| 10 | devbooks-reviewer | "使用 devbooks-code-review skill 评审变更 [change-id] 的代码" |
| 11 | devbooks-test-owner | "使用 devbooks-test-owner skill 运行变更 [change-id] 的所有测试并收集 Green 证据" |
| 12 | devbooks-archiver | "使用 devbooks-archiver skill 归档变更 [change-id]" |

## 角色隔离约束

**关键原则**：Test Owner 和 Coder 必须使用**独立的 Agent 实例/会话**。

| 角色 | 隔离要求 | 原因 |
|------|----------|------|
| Test Owner (阶段 7, 11) | 独立 Agent | 防止 Coder 篡改测试 |
| Coder (阶段 8) | 独立 Agent | 防止 Coder 看到测试实现细节 |
| Reviewer (阶段 9, 10) | 独立 Agent（推荐） | 保持评审客观性 |
