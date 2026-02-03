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

# DevBooks：Delivery（统一入口 / 路由 / 闭环编排器）

## 渐进披露
### 基础层（必读）
目标：以 **Delivery 为唯一入口**，基于 `request_kind` 选择**最小充分闭环**并编排执行，直至可归档（或明确进入 Void/Bootstrap 以补齐前置）。
输入：用户目标/上下文、配置映射、已有变更包产物与阶段状态。
输出：路由结果（`request_kind` + 最短闭环 + 升级条件）与对应产物（proposal/design/spec/tasks/verification/evidence/gate reports…）。
边界：主 Agent 只编排与校验；需要产物时必须调用对应子 Skill；遵守角色隔离与闸门规则（尤其是 Test Owner vs Coder）。
证据：产物路径、闸门脚本报告、评审输出与归档结果。

### 进阶层（可选）
适用：需要禁令细则、阶段表或断点续跑规则时。

### 扩展层（可选）
适用：需要闸门处理、追溯模板或脚本工具指引时。

## 核心要点
- 只负责编排，不直接产出提案/设计/测试/代码。
- **不再强制固定“12 阶段”**：以 `request_kind` 驱动“该做的做、该省的省”，但该强制的闸门与证据一项不漏。
- 先完成配置发现（优先读取 `.devbooks/config.yaml`），再执行子 Agent 调用。
- `request_kind`（debug|change|epic|void|bootstrap|governance）是主轴：决定最短闭环与升级条件。
- **SSOT 维护（无上游时自动创建）**：若项目缺少可引用的上游 SSOT，Delivery 在 `request_kind=bootstrap` 路径中必须先落盘最小 SSOT 包：`<truth-root>/ssot/SSOT.md` + `<truth-root>/ssot/requirements.index.yaml`（并可用 `requirements-ledger-derive.sh` 派生进度视图）。
- **SSOT 变更同步（治理路径）**：当用户诉求是“修改/同步 SSOT 或索引账本”时，Delivery 应路由到 `request_kind=governance` 并调用 `devbooks-ssot-maintainer`（delta → index sync → 可选 ledger refresh）。
- 必须遵守 `references/编排禁令与阶段表.md` 中的 **P3-3 行动规范**（主代理只编排、产物落盘编号、change 串线防护、归档需跑 Archiver）。

## 参考资料
- `skills/devbooks-delivery-workflow/references/编排禁令与阶段表.md`：绝对禁令、按 `request_kind` 路由与断点续跑。
- `skills/devbooks-delivery-workflow/references/子Agent调用规范.md`：子 Agent 调用格式与隔离要求。
- `skills/devbooks-delivery-workflow/references/编排逻辑伪代码.md`：编排主逻辑。
- `skills/devbooks-delivery-workflow/references/闸门检查与错误处理.md`：闸门检查点与回退策略。
- `skills/devbooks-delivery-workflow/references/交付验收工作流.md`：完整交付流程说明。
- `skills/devbooks-delivery-workflow/references/变更验证与追溯模板.md`：验证与追溯模板。

## 推荐 MCP 能力类型
- 代码检索（code-search）
- 引用追踪（reference-tracking）
- 影响分析（impact-analysis）
