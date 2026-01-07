# DevBooks 集成模板（协议无关）

> 目标：把 DevBooks 的角色隔离、DoD、目录落点与 `devbooks-*` Skills 索引写进项目上下文（不依赖 OpenSpec）。

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
- Spec Owner：`devbooks-spec-delta` → `(<change-root>/<change-id>/specs/**)`
- Planner：`devbooks-implementation-plan` → `(<change-root>/<change-id>/tasks.md)`
- Test Owner：`devbooks-test-owner` → `(<change-root>/<change-id>/verification.md)` + `tests/**`
- Coder：`devbooks-coder` → 实现（禁改 tests）
- Reviewer：`devbooks-code-review` → 评审意见
- Spec Gardener：`devbooks-spec-gardener` → 归档前修剪 `(<truth-root>/**)`
- C4 Map Maintainer：`devbooks-c4-map` → `(<truth-root>/architecture/c4.md)`
- Contract & Data Owner：`devbooks-contract-data` → 契约与数据定义 + contract tests
- Design Backport：`devbooks-design-backport` → 回写设计缺口/冲突

### 工作流类

- Proposal Debate：`devbooks-proposal-debate-workflow` → Author/Challenger/Judge 三角对辩
- Delivery Workflow：`devbooks-delivery-workflow` → 变更闭环 + 确定性脚本（scaffold/check/evidence）
- Brownfield Bootstrap：`devbooks-brownfield-bootstrap` → 存量项目初始化（当 `<truth-root>` 为空）

### 度量类

- Entropy Monitor：`devbooks-entropy-monitor` → 系统熵度量（结构熵/变更熵/测试熵/依赖熵）+ 重构预警
