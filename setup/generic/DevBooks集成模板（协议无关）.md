# DevBooks 集成模板（协议无关）

> 目标：把 DevBooks 的角色隔离、DoD、目录落点与 `devbooks-*` Skills 索引写进项目上下文（不依赖 DevBooks）。

---

## DevBooks Context（协议无关约定）

在你的“项目指路牌文件”里追加以下信息（文件名由你的上下文协议决定；常见候选：`CLAUDE.md`、`AGENTS.md`、`PROJECT.md` 等）：

- 目录根：
  - `<truth-root>`：当前真理目录根（默认建议 `specs/`）
  - `<change-root>`：变更包目录根（默认建议 `changes/`）

- 单次变更包（Change Package）落点（目录约定）：
  - `(<change-root>/<change-id>/proposal.md)`：提案
  - `(<change-root>/<change-id>/design.md)`：设计文档
  - `(<change-root>/<change-id>/tasks.md)`：编码计划
  - `(<change-root>/<change-id>/verification.md)`：验证与追溯（含追溯矩阵、MANUAL-* 清单与证据要求）
  - `(<change-root>/<change-id>/specs/**)`：本次规格 delta
  - `(<change-root>/<change-id>/evidence/**)`：证据（按需）

- 当前真理（Current Truth）推荐结构（不强制，但建议统一）：
  - `(<truth-root>/_meta/project-profile.md)`：项目画像/约束/闸门/格式约定
  - `(<truth-root>/_meta/glossary.md)`：统一语言表（术语）
  - `(<truth-root>/architecture/c4.md)`：C4 架构地图（当前真理）
  - `(<truth-root>/engineering/pitfalls.md)`：高 ROI 坑库（可选）

---

## 角色隔离（强制）

- Test Owner 与 Coder 必须独立对话/独立实例；允许并行但不得共享上下文。
- Coder 禁止修改 `tests/**`；如需调整测试只能交还 Test Owner 决策与改动。

---

## DoD（Definition of Done，MECE）

每次变更至少声明覆盖到哪些闸门；缺失项必须写原因与补救计划（建议写入 `(<change-root>/<change-id>/verification.md)`）：

- 行为（Behavior）：unit/integration/e2e（按项目类型最小集）
- 契约（Contract）：OpenAPI/Proto/Schema/事件 envelope + contract tests
- 结构（Structure）：分层/依赖方向/禁止循环（fitness tests）
- 静态与安全（Static/Security）：lint/typecheck/build + SAST/secret scan
- 证据（Evidence，按需）：截图/录像/报告（UI、性能、安全 triage）

---

## DevBooks Skills 索引（协议无关）

建议把下列索引写进项目指路牌文件，作为"何时用哪个 Skill"的路标：

### 角色类

- Router：`devbooks-router` → 不确定下一步/阶段时用于路由与给出产物落点（支持 Prototype 模式）
- Proposal Author：`devbooks-proposal-author` → `(<change-root>/<change-id>/proposal.md)`
- Proposal Challenger：`devbooks-proposal-challenger` → 质疑报告（不写入变更包也可以）
- Proposal Judge：`devbooks-proposal-judge` → 裁决写回 `proposal.md`
- Impact Analyst：`devbooks-impact-analysis` → 影响分析（建议写入 proposal 的 Impact 部分）
- Design Owner：`devbooks-design-doc` → `(<change-root>/<change-id>/design.md)`
- Spec & Contract Owner：`devbooks-spec-contract` → `(<change-root>/<change-id>/specs/**)` + 契约计划（合并了原 spec-delta + contract-data）
- Planner：`devbooks-implementation-plan` → `(<change-root>/<change-id>/tasks.md)`
- Test Owner：`devbooks-test-owner` → `(<change-root>/<change-id>/verification.md)` + `tests/**`【输出管理：>50行截断】
- Coder：`devbooks-coder` → 实现（禁改 tests）【断点续做 + 输出管理】
- Reviewer：`devbooks-code-review` → 评审意见
- Spec Gardener：`devbooks-spec-gardener` → 归档前修剪 `(<truth-root>/**)`
- C4 Map Maintainer：`devbooks-c4-map` → `(<truth-root>/architecture/c4.md)`
- Design Backport：`devbooks-design-backport` → 回写设计缺口/冲突

### 工作流类

- Proposal Debate：`devbooks-proposal-debate-workflow` → Author/Challenger/Judge 三角对辩
- Delivery Workflow：`devbooks-delivery-workflow` → 变更闭环 + 确定性脚本（scaffold/check/evidence）
- Brownfield Bootstrap：`devbooks-brownfield-bootstrap` → 存量项目初始化（当 `<truth-root>` 为空）

### 度量类

- Entropy Monitor：`devbooks-entropy-monitor` → 系统熵度量（结构熵/变更熵/测试熵/依赖熵）+ 重构预警

### 索引类

- Index Bootstrap：`devbooks-index-bootstrap` → 自动生成 SCIP 索引，激活图基分析能力
- Federation：`devbooks-federation` → 跨仓库联邦分析与契约同步（多仓库项目时）

---

## CI/CD 集成（可选）

将 `templates/ci/` 中的模板复制到项目 `.github/workflows/`：

- `devbooks-guardrail.yml`：PR 时自动检查复杂度、热点、分层违规、循环依赖
- `devbooks-cod-update.yml`：Push 后自动更新 COD 模型（模块图、热点、概念）

---

## 跨仓库联邦（可选）

多仓库项目可配置 `.devbooks/federation.yaml` 定义上下游依赖关系：

```bash
cp skills/devbooks-federation/templates/federation.yaml .devbooks/federation.yaml
```

详见 `skills/devbooks-federation/SKILL.md`

---

## 自动 Skill 路由规则（无感集成）

> 以下规则让 AI 根据用户意图自动选择 Skill，无需用户显式点名。

### 意图识别与自动路由

| 用户意图模式 | 自动使用的 Skills |
|------------|------------------|
| "修复 Bug"、"定位问题"、"为什么报错" | `devbooks-impact-analysis` → `devbooks-coder` |
| "重构"、"优化代码"、"消除重复" | `devbooks-code-review` → `devbooks-coder` |
| "新功能"、"添加 XX"、"实现 XX" | `devbooks-router` → 完整闭环 |
| "写测试"、"补测试" | `devbooks-test-owner` |
| "继续"、"下一步" | 检查 `tasks.md` → `devbooks-coder` |
| "评审"、"Review" | `devbooks-code-review` |

### 图基分析自动启用

**前置检查**：调用 `mcp__ckb__getStatus` 检查索引状态
- 可用时：自动使用 `analyzeImpact`/`findReferences`/`getCallGraph`/`getHotspots`
- 不可用时：降级为 `Grep`/`Glob` 文本搜索

### 热点文件自动警告

执行 `devbooks-coder` 或 `devbooks-code-review` 前**必须**调用 `mcp__ckb__getHotspots`：
- 🔴 Critical（Top 5）：输出警告 + 建议增加测试
- 🟡 High（Top 10）：输出提示 + 重点审查
- 🟢 Normal：正常执行

### 变更包状态自动识别

| 状态 | 自动建议 |
|-----|---------|
| 只有 `proposal.md` | → `devbooks-design-doc` |
| 有 `design.md` 无 `tasks.md` | → `devbooks-implementation-plan` |
| 有 `tasks.md` 未完成 | → `devbooks-coder` |
| tasks 全部完成 | → `devbooks-code-review` 或归档 |
