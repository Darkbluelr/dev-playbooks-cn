# audit-tools

---
capability: audit-tools
version: 1.1
status: Active
owner: devbooks-spec-gardener
last_verified: 2026-01-11
freshness_check: 3 Months
source_change: harden-devbooks-quality-gates
---

## 目的

定义 DevBooks 审计工具的行为规格，包括全量扫描、进度仪表板、脚本帮助文档和静态检查。

## Requirements

### Requirement: REQ-AT-001 全量审计扫描

**描述**：系统 MUST 提供全量扫描工具以提升审计精度。

**优先级**：P1（重要）

**验收条件**：
- `audit-scope.sh` 必须扫描指定目录下的所有文件
- 必须输出文件数量、行数、复杂度指标
- 必须输出热点文件清单（高频修改 + 高复杂度）
- 扫描结果偏差必须 < 1.5x（与手工抽样对比）

#### Scenario: SC-AT-001-01 全量扫描输出

- **Given**: 目标目录包含 100 个文件
- **When**: 执行 `audit-scope.sh <dir>`
- **Then**: 输出包含：文件总数、代码行数、热点清单

#### Scenario: SC-AT-001-02 扫描精度验证

- **Given**: 手工抽样 10 个文件的统计结果
- **When**: 对比 `audit-scope.sh` 的输出
- **Then**: 偏差 < 1.5x

---

### Requirement: REQ-AT-002 进度可视化仪表板

**描述**：系统 MUST 提供变更包进度可视化工具。

**优先级**：P1（重要）

**验收条件**：
- `progress-dashboard.sh <change-id>` 必须输出结构化仪表板
- 仪表板必须包含三节：任务完成率、角色状态、证据状态
- 输出格式必须为 Markdown
- JSON 输出必须使用 `true/false`（非 `yes/no`）

#### Scenario: SC-AT-002-01 仪表板输出格式

- **Given**: 变更包存在
- **When**: 执行 `progress-dashboard.sh <change-id>`
- **Then**: 输出包含 "## 任务完成率" 节、"## 角色状态" 节、"## 证据状态" 节

#### Scenario: SC-AT-002-02 仪表板数据准确

- **Given**: `tasks.md` 有 10 个任务，完成 8 个
- **When**: 执行仪表板生成
- **Then**: 任务完成率显示 "80% (8/10)"

---

### Requirement: REQ-AT-003 脚本帮助文档

**描述**：系统 MUST 为所有新增脚本提供帮助文档。

**优先级**：P0（必须）

**验收条件**：
- 所有新增 `.sh` 脚本必须支持 `--help` 参数
- 帮助输出必须包含：用法、参数说明、示例
- 帮助输出必须返回退出码 0

#### Scenario: SC-AT-003-01 帮助参数支持

- **Given**: 新增脚本 `handoff-check.sh`
- **When**: 执行 `handoff-check.sh --help`
- **Then**: 输出用法说明，退出码为 0

#### Scenario: SC-AT-003-02 所有新增脚本均支持帮助

- **Given**: 检查所有新增脚本
- **When**: 执行 `<script> --help`
- **Then**: 每个脚本都输出用法说明并返回退出码 0

---

### Requirement: REQ-AT-004 静态检查通过

**描述**：系统 MUST 确保所有脚本通过静态检查。

**优先级**：P0（必须）

**验收条件**：
- 所有 `.sh` 文件必须通过 `shellcheck` 检查
- 不允许有 error 级别的问题
- warning 级别问题应修复或标注豁免

#### Scenario: SC-AT-004-01 shellcheck 检查通过

- **Given**: 新增脚本
- **When**: 执行 `shellcheck <script>`
- **Then**: 退出码为 0（无错误）

#### Scenario: SC-AT-004-02 所有脚本均通过 shellcheck

- **Given**: 对所有新增脚本执行 `shellcheck`
- **When**: 检查完成
- **Then**: 全部返回退出码 0

---

## CLI 契约

### audit-scope.sh

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<directory>` | 位置参数 | 是 | 扫描目录 |
| `--format` | 选项 | 否 | 输出格式（markdown/json） |

### progress-dashboard.sh

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID |
| `--project-root` | 选项 | 否 | 项目根目录 |
| `--change-root` | 选项 | 否 | 变更包根目录 |
