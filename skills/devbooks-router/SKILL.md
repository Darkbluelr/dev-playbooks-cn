---
name: devbooks-router
description: devbooks-router：DevBooks 工作流入口引导：帮助用户确定从哪个 skill 开始，检测项目当前状态，给出最短闭环路径。用户说"下一步怎么做/从哪开始/按 devbooks 跑闭环/项目状态"等时使用。注意：skill 完成后的路由由各 skill 自己负责，无需调用 router。
recommended_experts: ["System Architect", "Product Manager"]
allowed-tools:
  - Glob
  - Grep
  - Read
  - Bash
---

# DevBooks：工作流入口引导（Router）

## 渐进披露
### 基础层（必读）
目标：判定当前阶段并给出最短闭环路由（Skill + 产物路径 + 理由）。
输入：用户请求、配置映射（truth-root/change-root）、已有产物与变更包状态。
输出：最小关键问题 + 3–6 条路由结果 + 下一步建议。
边界：不直接产出变更包文件；不替代其他 Skill；必须先读取 agents_doc。
证据：路由结果中引用的产物路径与检测结论。

### 进阶层（可选）
适用：需要 Impact 画像解析、降级策略或详细路由规则时。

### 扩展层（可选）
适用：需要原型轨道、归档前检查或上下文检测细则时。

## 核心要点
- 先做配置发现（优先读取 `.devbooks/config.yaml`）与规则文档读取，再进入路由判断。
- 输出 2 个最小关键问题 + 3–6 条路由结果（含路径与理由）。
- 用户要求“直接开始产出”时，切换到目标 Skill 的输出模式。
- Start 为默认入口，使用 Router 输出阶段建议与路径。

## 参考资料
- `skills/devbooks-router/references/路由规则与模板.md`：入口定位、配置发现、Impact 画像、路由规则、原型模式与上下文检测。

## 推荐 MCP 能力类型
- 代码检索（code-search）
- 引用追踪（reference-tracking）
- 影响分析（impact-analysis）
