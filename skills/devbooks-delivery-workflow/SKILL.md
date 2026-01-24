---
name: devbooks-delivery-workflow
description: devbooks-delivery-workflow：完整闭环编排器，在支持子 Agent 的 AI 编程工具中调用，自动编排 Proposal→Design→Spec→Plan→Test→Implement→Review→Archive 全流程。用户说"跑一遍闭环/完整交付/从头到尾跑完/自动化变更流程"等时使用。
recommended_experts: ["System Architect", "Product Manager"]
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
  - Task
---

# DevBooks：交付验收工作流（完整闭环编排器）

## 渐进披露
### 基础层（必读）
目标：以主 Agent 纯编排方式完成 12 阶段闭环交付。
输入：用户目标、配置映射、已有变更包产物与阶段状态。
输出：子 Agent 调用序列、阶段进度与结果汇总。
边界：主 Agent 不直接改文件；必须通过 Task 调用子 Agent；遵守角色隔离与闸门规则。
证据：各阶段产物路径、脚本输出与评审结果记录。

### 进阶层（可选）
适用：需要禁令细则、阶段表或断点续跑规则时。

### 扩展层（可选）
适用：需要闸门处理、追溯模板或脚本工具指引时。

## 核心要点
- 只负责编排，不直接产出提案/设计/测试/代码。
- 12 阶段强制闭环，任一阶段失败必须回退修复。
- 先完成配置发现（优先读取 `.devbooks/config.yaml`），再执行子 Agent 调用。

## 参考资料
- `skills/devbooks-delivery-workflow/references/编排禁令与阶段表.md`：绝对禁令、12 阶段流程与断点续跑。
- `skills/devbooks-delivery-workflow/references/子Agent调用规范.md`：子 Agent 调用格式与隔离要求。
- `skills/devbooks-delivery-workflow/references/编排逻辑伪代码.md`：编排主逻辑。
- `skills/devbooks-delivery-workflow/references/闸门检查与错误处理.md`：闸门检查点与回退策略。
- `skills/devbooks-delivery-workflow/references/交付验收工作流.md`：完整交付流程说明。
- `skills/devbooks-delivery-workflow/references/变更验证与追溯模板.md`：验证与追溯模板。

## 推荐 MCP 能力类型
- 代码检索（code-search）
- 引用追踪（reference-tracking）
- 影响分析（impact-analysis）
