# DevBooks 集成模板（协议无关）

> 目标：把 DevBooks 的**角色隔离**、**DoD（完成定义）**、**目录约定**、以及 `devbooks-*` Skills 索引，写入目标项目的“项目标牌文件（signpost file）”里（无需依赖 DevBooks 本体）。

---

## DevBooks 上下文（协议无关约定）

将以下信息添加到你的“项目标牌文件”（由项目上下文协议决定，常见候选：`CLAUDE.md`、`AGENTS.md`、`PROJECT.md` 等）：

- 目录根（Directory Roots）：
  - `<truth-root>`：当前真理目录根（默认建议：`specs/`）
  - `<change-root>`：变更包目录根（默认建议：`changes/`）

- 单次变更包文件落点（目录约定）：
  - `(<change-root>/<change-id>/proposal.md)`：提案
  - `(<change-root>/<change-id>/design.md)`：设计文档
  - `(<change-root>/<change-id>/tasks.md)`：编码计划
  - `(<change-root>/<change-id>/verification.md)`：验证与追溯（含追溯矩阵、MANUAL-* 清单、证据要求）
  - `(<change-root>/<change-id>/specs/**)`：本次变更的规格增量
  - `(<change-root>/<change-id>/evidence/**)`：证据（按需）

- 当前真理目录建议结构（非强制，但建议保持一致）：
  - `(<truth-root>/_meta/project-profile.md)`：项目画像/约束/闸门/格式约定
  - `(<truth-root>/_meta/glossary.md)`：统一语言术语表
  - `(<truth-root>/architecture/c4.md)`：C4 架构地图（当前真理）
  - `(<truth-root>/engineering/pitfalls.md)`：高 ROI 坑库（可选）

---

## 角色隔离（强制）

- Test Owner 与 Coder 必须在**独立对话/独立实例**中工作；允许并行，但不允许共享上下文造成“自证式测试”。
- Coder **禁止修改** `tests/**`；如需调整测试，必须交回 Test Owner 决策与修改。

---

## DoD（完成定义，MECE）

每次变更至少要声明覆盖哪些闸门；未覆盖项必须写明原因与补救计划（建议写入 `(<change-root>/<change-id>/verification.md)`）：

- 行为：unit/integration/e2e（按项目类型选择最小集合）
- 契约：OpenAPI/Proto/Schema/事件信封 + contract tests
- 结构：分层/依赖方向/无环（fitness tests）
- 静态/安全：lint/typecheck/build + SAST/secret scan
- 证据（按需）：截图/录屏/报告（UI、性能、安全排查）

---

## DevBooks Skills 索引（协议无关）

建议把下面的索引放入项目标牌文件，用来指导“什么时候用哪个 Skill”。

### 按角色

- Router：`devbooks-router` → 不确定下一步/阶段时做路由与产物落点建议（支持 Prototype 模式）
- Proposal Author：`devbooks-proposal-author` → `(<change-root>/<change-id>/proposal.md)`
- Proposal Challenger：`devbooks-proposal-challenger` → 质疑报告（可选写入变更包）
- Proposal Judge：`devbooks-proposal-judge` → 裁决回写到 `proposal.md`
- Impact Analyst：`devbooks-impact-analysis` → 影响分析（建议写回 proposal 的 Impact 部分）
- Design Owner：`devbooks-design-doc` → `(<change-root>/<change-id>/design.md)`
- Spec & Contract Owner：`devbooks-spec-contract` → `(<change-root>/<change-id>/specs/**)` + 契约计划
- Planner：`devbooks-implementation-plan` → `(<change-root>/<change-id>/tasks.md)`
- Test Owner：`devbooks-test-owner` → `(<change-root>/<change-id>/verification.md)` + `tests/**`
- Coder：`devbooks-coder` → 按 `tasks.md` 实现（禁止改 tests）
- Reviewer：`devbooks-code-review` → 评审意见（不改代码）
- Spec Gardener：`devbooks-spec-gardener` → 归档前修剪 `(<truth-root>/**)`
- C4 Map Maintainer：`devbooks-c4-map` → `(<truth-root>/architecture/c4.md)`
- Design Backport：`devbooks-design-backport` → 回写设计缺口/冲突

### 按工作流

- Proposal Debate：`devbooks-proposal-debate-workflow` → Author/Challenger/Judge 三角对辩
- Delivery Workflow：`devbooks-delivery-workflow` → 变更闭环 + 确定性脚本（scaffold/check/evidence）
- Brownfield Bootstrap：`devbooks-brownfield-bootstrap` → 存量项目初始化（`<truth-root>` 为空时）

### 按度量

- Entropy Monitor：`devbooks-entropy-monitor` → 系统熵度量（结构/变更/测试/依赖熵）+ 重构预警

### 按索引

- Index Bootstrap：`devbooks-index-bootstrap` → 生成 SCIP 索引，启用图基分析
- Federation：`devbooks-federation` → 跨仓库联邦分析与契约同步

---

## CI/CD 集成（可选）

把 `templates/ci/` 里的模板复制到目标项目的 `.github/workflows/`：

- `devbooks-guardrail.yml`：在 PR 上做复杂度/热点/分层违规/环依赖检查
- `devbooks-cod-update.yml`：push 后自动更新 COD 模型（模块图/热点/概念）

---

## 跨仓库联邦（可选）

多仓库项目可配置 `.devbooks/federation.yaml` 定义上下游依赖：

```bash
cp skills/devbooks-federation/templates/federation.yaml .devbooks/federation.yaml
```

详见 `skills/devbooks-federation/SKILL.md`

---

## 自动 Skill 路由规则（无感集成）

> 这些规则让 AI 可以根据用户意图自动选择 Skills，不需要用户显式点名。

### 意图识别与自动路由

| 用户意图模式 | 自动选择 Skills |
|-------------|------------------|
| “修 bug”、“定位问题”、“为什么报错” | `devbooks-impact-analysis` → `devbooks-coder` |
| “重构”、“优化代码”、“消除重复” | `devbooks-code-review` → `devbooks-coder` |
| “新功能”、“增加 XX”、“实现 XX” | `devbooks-router` → 输出闭环路线 |
| “写测试”、“补测试” | `devbooks-test-owner` |
