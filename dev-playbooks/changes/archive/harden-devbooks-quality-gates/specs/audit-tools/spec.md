# audit-tools

---
capability: audit-tools
version: 1.1
status: Complete
owner: Spec Owner
last_verified: 2026-01-11
freshness_check: 1 Month
archive_ready: true
---

## ADDED Requirements

### Requirement: REQ-AT-001 全量审计扫描

**描述**：系统 MUST 提供全量扫描工具以提升审计精度。

**优先级**：P1（重要）

**验收条件**：
- `audit-scope.sh` 必须扫描指定目录下的所有文件
- 必须输出文件数量、行数、复杂度指标
- 必须输出热点文件清单（高频修改 + 高复杂度）
- 扫描结果偏差必须 < 1.5x（与手工抽样对比）

**追溯**: AC-011

#### Scenario: SC-AT-001-01 全量扫描输出

- **Given**: 目标目录包含 100 个文件
- **When**: 执行 `audit-scope.sh <dir>`
- **Then**: 输出包含：文件总数、代码行数、热点清单
- **证据**: `skills/devbooks-delivery-workflow/scripts/audit-scope.sh`

#### Scenario: SC-AT-001-02 扫描精度验证

- **Given**: 手工抽样 10 个文件的统计结果
- **When**: 对比 `audit-scope.sh` 的输出
- **Then**: 偏差 < 1.5x
- **证据**: `evidence/ac-011.log`

---

### Requirement: REQ-AT-002 进度可视化仪表板

**描述**：系统 MUST 提供变更包进度可视化工具。

**优先级**：P1（重要）

**验收条件**：
- `progress-dashboard.sh <change-id>` 必须输出结构化仪表板
- 仪表板必须包含三节：任务完成率、角色状态、证据状态
- 输出格式必须为 Markdown

**追溯**: AC-010

#### Scenario: SC-AT-002-01 仪表板输出格式

- **Given**: 变更包 `harden-devbooks-quality-gates` 存在
- **When**: 执行 `progress-dashboard.sh harden-devbooks-quality-gates`
- **Then**: 输出包含 "## 任务完成率" 节、"## 角色状态" 节、"## 证据状态" 节
- **证据**: `skills/devbooks-delivery-workflow/scripts/progress-dashboard.sh`

#### Scenario: SC-AT-002-02 仪表板数据准确

- **Given**: `tasks.md` 有 10 个任务，完成 8 个
- **When**: 执行仪表板生成
- **Then**: 任务完成率显示 "80% (8/10)"
- **证据**: `evidence/dashboard-sample.md`

---

### Requirement: REQ-AT-003 脚本帮助文档

**描述**：系统 MUST 为所有新增脚本提供帮助文档。

**优先级**：P0（必须）

**验收条件**：
- 所有新增 `.sh` 脚本必须支持 `--help` 参数
- 帮助输出必须包含：用法、参数说明、示例
- 帮助输出必须返回退出码 0

**追溯**: AC-009

#### Scenario: SC-AT-003-01 帮助参数支持

- **Given**: 新增脚本 `handoff-check.sh`
- **When**: 执行 `handoff-check.sh --help`
- **Then**: 输出用法说明，退出码为 0
- **证据**: `skills/devbooks-delivery-workflow/scripts/handoff-check.sh`

#### Scenario: SC-AT-003-02 所有新增脚本均支持帮助

- **Given**: 检查所有新增脚本
- **When**: 执行 `<script> --help`
- **Then**: 每个脚本都输出用法说明并返回退出码 0
- **证据**: `evidence/help-check.log`

---

### Requirement: REQ-AT-004 静态检查通过

**描述**：系统 MUST 确保所有脚本通过静态检查。

**优先级**：P0（必须）

**验收条件**：
- 所有 `.sh` 文件必须通过 `shellcheck` 检查
- 不允许有 error 级别的问题
- warning 级别问题应修复或标注豁免

**追溯**: AC-008

#### Scenario: SC-AT-004-01 shellcheck 检查通过

- **Given**: 新增脚本 `handoff-check.sh`
- **When**: 执行 `shellcheck handoff-check.sh`
- **Then**: 退出码为 0（无错误）
- **证据**: `evidence/shellcheck.log`

#### Scenario: SC-AT-004-02 所有脚本均通过 shellcheck

- **Given**: 对所有新增脚本执行 `shellcheck`
- **When**: 检查完成
- **Then**: 全部返回退出码 0
- **证据**: `evidence/shellcheck.log`

---

## 追溯摘要

| AC ID | Requirement | Scenario |
|-------|-------------|----------|
| AC-011 | REQ-AT-001 | SC-AT-001-01, SC-AT-001-02 |
| AC-010 | REQ-AT-002 | SC-AT-002-01, SC-AT-002-02 |
| AC-009 | REQ-AT-003 | SC-AT-003-01, SC-AT-003-02 |
| AC-008 | REQ-AT-004 | SC-AT-004-01, SC-AT-004-02 |
