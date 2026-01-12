# Spec: DevBooks Slash Commands

---
owner: Spec Owner
last_verified: 2026-01-12
status: Active
freshness_check: 3 Months
source_change: redesign-slash-command-routing
---

## 1. Requirements

### REQ-SLASH-001: DevBooks 原生 Slash 命令体系

系统 SHALL 提供以 `/devbooks:` 为前缀的原生 Slash 命令体系，支持完整的变更管理工作流。

> 来源：redesign-slash-command-routing 变更（命令数量从 7 扩展到 24）

**核心命令清单（21 个）**：

| 命令 | 触发的 Skill | 用途 |
|------|--------------|------|
| `/devbooks:router` | devbooks-router | 路由入口，生成执行计划 |
| `/devbooks:proposal` | devbooks-proposal-author | 创建变更提案 |
| `/devbooks:challenger` | devbooks-proposal-challenger | 提案质疑 |
| `/devbooks:judge` | devbooks-proposal-judge | 提案裁决 |
| `/devbooks:debate` | devbooks-proposal-debate-workflow | 三角对辩工作流 |
| `/devbooks:design` | devbooks-design-doc | 创建设计文档 |
| `/devbooks:backport` | devbooks-design-backport | 回写设计文档 |
| `/devbooks:plan` | devbooks-implementation-plan | 编码计划 |
| `/devbooks:spec` | devbooks-spec-contract | 规格与契约定义 |
| `/devbooks:gardener` | devbooks-spec-gardener | 规格园丁（归档维护） |
| `/devbooks:test` | devbooks-test-owner | 测试负责人 |
| `/devbooks:test-review` | devbooks-test-reviewer | 测试评审 |
| `/devbooks:code` | devbooks-coder | 实现负责人 |
| `/devbooks:review` | devbooks-code-review | 代码评审 |
| `/devbooks:delivery` | devbooks-delivery-workflow | 交付验收工作流 |
| `/devbooks:c4` | devbooks-c4-map | C4 架构地图 |
| `/devbooks:impact` | devbooks-impact-analysis | 影响分析 |
| `/devbooks:entropy` | devbooks-entropy-monitor | 熵度量与预警 |
| `/devbooks:federation` | devbooks-federation | 跨仓库联邦分析 |
| `/devbooks:bootstrap` | devbooks-brownfield-bootstrap | 存量项目初始化 |
| `/devbooks:index` | devbooks-index-bootstrap | 索引引导 |

**向后兼容命令（3 个）**：

| 命令 | 说明 |
|------|------|
| `/devbooks:apply` | 保留，触发 test-owner/coder/reviewer |
| `/devbooks:archive` | 保留，触发 spec-gardener |
| `/devbooks:quick` | 保留，快速模式 |

**验收条件**：
- 命令定义文件存在于 `templates/claude-commands/devbooks/`
- 每个命令正确触发对应 Skill
- 命令总数 = 24（21 核心 + 3 向后兼容）

Trace: AC-001, AC-002

---

### REQ-SLASH-002: 命令模板结构

每个命令模板文件 SHALL 包含以下结构：
1. YAML front matter（包含 `skill:` 字段）
2. 命令提示词内容

Trace: AC-002

---

### REQ-SLASH-003: Apply 阶段角色子命令

`/devbooks:apply` 命令 SHALL 支持 `--role` 参数，允许用户指定执行角色。

**可选角色**：
- `test-owner`：执行 devbooks-test-owner
- `coder`：执行 devbooks-coder
- `reviewer`：执行 devbooks-code-review（评审模式）

**约束**：
- 若 `role_isolation: true`，系统 SHALL 阻止在同一会话中切换 test-owner 和 coder 角色

**验收条件**：
- 角色参数正确解析
- 角色隔离逻辑生效

---

### REQ-SLASH-004: 快速模式量化边界

`/devbooks:quick` 命令 SHALL 仅适用于满足以下条件的小变更：
- 影响文件数 <= 5 个
- 无跨模块变更
- 无对外接口变更
- 无需 AC 追溯

系统 SHOULD 在条件不满足时提示用户使用完整流程。

**验收条件**：
- 边界检查逻辑存在
- 超限时输出警告

---

### REQ-SLASH-005: 向后兼容

系统 SHALL 保持现有 6 个命令（proposal/design/apply/review/archive/quick）的调用方式不变。

Trace: AC-008

---

### REQ-SLASH-006: FT-009 规则

`c4.md` 中的 FT-009 规则 SHALL 使用 `cmd_count -eq 24`（精确值）。

Trace: AC-009

---

### REQ-SLASH-R01: 移除 OpenSpec Slash 命令（历史）

系统已移除以下命令：
- `/openspec:proposal`
- `/openspec:apply`
- `/openspec:archive`

**不提供向后兼容别名**。

---

## 2. Scenarios

### SC-SLASH-001: 用户启动提案阶段

- **GIVEN** 用户在 Claude Code 会话中
- **WHEN** 用户输入 `/devbooks:proposal`
- **THEN** 系统加载 devbooks-proposal-author Skill
- **AND** 系统提示用户提供变更背景信息

---

### SC-SLASH-002: 用户执行快速模式

- **GIVEN** 用户有一个小型变更（<= 5 个文件，无跨模块）
- **WHEN** 用户输入 `/devbooks:quick`
- **THEN** 系统依次执行 proposal -> apply -> archive
- **AND** 跳过 design 和 review 阶段

---

### SC-SLASH-003: 快速模式边界检查失败

- **GIVEN** 用户有一个大型变更（> 5 个文件 或 跨模块）
- **WHEN** 用户输入 `/devbooks:quick`
- **THEN** 系统输出警告提示
- **AND** 建议用户使用完整流程（proposal -> design -> apply -> review -> archive）

---

### SC-SLASH-004: 角色隔离强制执行

- **GIVEN** 配置 `role_isolation: true`
- **AND** 用户在当前会话已执行 `/devbooks:apply --role test-owner`
- **WHEN** 用户尝试执行 `/devbooks:apply --role coder`
- **THEN** 系统拒绝执行
- **AND** 提示用户在新会话中执行 coder 角色

---

### SC-SLASH-005: 旧命令不可用

- **GIVEN** 用户在已升级到 DevBooks 2.0 的项目中
- **WHEN** 用户输入 `/openspec:proposal`
- **THEN** 系统提示命令不存在
- **AND** 建议使用 `/devbooks:proposal`

---

### SC-SLASH-006: 验证命令数量（新增）

- **GIVEN** DevBooks 已安装
- **WHEN** 用户检查命令模板目录
- **THEN** `ls templates/claude-commands/devbooks/*.md | wc -l` 输出 24

Trace: AC-001

---

### SC-SLASH-007: 验证命令名称匹配（新增）

- **GIVEN** DevBooks 已安装
- **WHEN** 用户检查任意命令文件（如 `router.md`）
- **THEN** 文件内容包含 `skill: devbooks-router` 元数据

Trace: AC-002

---

## 3. Contract Tests

| ID | 场景 | 断言 |
|----|------|------|
| CT-SLASH-001 | 命令数量验证 | `cmd_count` = 24 |
| CT-SLASH-002 | 命令与 Skill 1:1 对应 | 每个 .md 文件包含正确 skill 元数据 |
| CT-SLASH-003 | proposal 命令加载 | 触发 devbooks-proposal-author |
| CT-SLASH-004 | design 命令加载 | 触发 devbooks-design-doc |
| CT-SLASH-005 | apply 命令角色解析 | --role 参数正确处理 |
| CT-SLASH-006 | review 命令加载 | 触发 devbooks-code-review |
| CT-SLASH-007 | archive 命令加载 | 触发 devbooks-spec-gardener |
| CT-SLASH-008 | quick 命令边界检查 | 边界检查逻辑生效 |
| CT-SLASH-009 | 向后兼容 | 6 个旧命令全部存在 |

---

## 4. 关联规格

- `specs/config-protocol/spec.md`：配置协议（role_isolation 配置）
- `specs/role-handoff/spec.md`：角色交接规格
- `specs/context-detection/spec.md`：上下文检测规格（新增）
- `specs/mcp/spec.md`：MCP 检测规格（更新）
