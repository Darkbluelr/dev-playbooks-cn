# role-handoff

---
capability: role-handoff
version: 1.1
status: Active
owner: devbooks-spec-gardener
last_verified: 2026-01-11
freshness_check: 3 Months
source_change: harden-devbooks-quality-gates
---

## 目的

定义 DevBooks 角色交接与环境匹配检查的行为规格，确保角色切换时信息完整传递。

## Requirements

### Requirement: REQ-RH-001 角色交接握手检查

**描述**：系统 MUST 验证角色交接有完整的握手记录。

**优先级**：P0（必须）

**验收条件**：
- `handoff-check.sh` 执行时，必须检查 `handoff.md` 存在
- 必须验证 `handoff.md` 包含必填节："交接信息"、"交接内容"、"确认签名"
- **默认行为**：必须验证"确认签名"节中**所有**签名项 `[x]` 已勾选
- **宽松模式**：`--allow-partial` 参数允许部分签名通过
- 若任一条件不满足，必须返回非零退出码

#### Scenario: SC-RH-001-01 无交接记录

- **Given**: 变更包从 Test Owner 切换到 Coder
- **When**: 执行交接检查且 `handoff.md` 不存在
- **Then**: 检查失败，输出 "缺少交接记录: handoff.md 不存在"

#### Scenario: SC-RH-001-02 交接无确认

- **Given**: `handoff.md` 存在但确认签名节无已勾选项
- **When**: 执行交接检查
- **Then**: 检查失败，输出 "交接未确认: 需要至少一方确认"

#### Scenario: SC-RH-001-03 交接已确认

- **Given**: `handoff.md` 存在且确认签名节有所有签名 `[x]` 已勾选
- **When**: 执行交接检查
- **Then**: 检查通过

#### Scenario: SC-RH-001-04 多角色链交接

- **Given**: `handoff.md` 包含多次交接记录（Test Owner → Coder → Reviewer）
- **When**: 执行交接检查
- **Then**: 验证整个交接链的完整性

---

### Requirement: REQ-RH-002 测试环境匹配验证

**描述**：系统 MUST 验证测试环境声明存在。

**优先级**：P1（重要）

**验收条件**：
- `env-match-check.sh` 执行时，必须检查 `verification.md` 存在
- 必须验证 `verification.md` 包含"测试环境声明"节
- 若节不存在或为空，必须返回非零退出码
- 允许节内容为 `N/A`（表示无特殊环境要求）

#### Scenario: SC-RH-002-01 无环境声明

- **Given**: `verification.md` 存在但无"测试环境声明"节
- **When**: 执行环境匹配检查
- **Then**: 检查失败，输出 "缺少测试环境声明"

#### Scenario: SC-RH-002-02 环境声明为 N/A

- **Given**: `verification.md` 包含"测试环境声明"节且内容为 N/A
- **When**: 执行环境匹配检查
- **Then**: 检查通过（N/A 为有效声明）

#### Scenario: SC-RH-002-03 环境声明完整

- **Given**: `verification.md` 包含详细的测试环境声明
- **When**: 执行环境匹配检查
- **Then**: 检查通过

---

## CLI 契约

### handoff-check.sh

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID |
| `--allow-partial` | 选项 | 否 | 允许部分签名通过（默认要求全部签名） |
| `--project-root` | 选项 | 否 | 项目根目录 |
| `--change-root` | 选项 | 否 | 变更包根目录 |

### env-match-check.sh

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID |
| `--project-root` | 选项 | 否 | 项目根目录 |
| `--change-root` | 选项 | 否 | 变更包根目录 |
