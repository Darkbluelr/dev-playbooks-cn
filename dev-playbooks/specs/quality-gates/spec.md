# quality-gates

---
capability: quality-gates
version: 2.1
status: Active
owner: devbooks-spec-gardener
last_verified: 2026-01-11
freshness_check: 3 Months
source_change: harden-devbooks-quality-gates
---

## 目的

定义 DevBooks 质量闸门检查的行为规格，用于拦截假完成、强制角色边界、确保测试通过后才能归档。

## Requirements

### Requirement: REQ-QG-001 Green 证据强制检查

**描述**：系统 MUST 在归档模式下验证 Green 证据存在。

**优先级**：P0（必须）

**验收条件**：
- `change-check.sh --mode archive` 执行时，必须检查 `evidence/green-final/` 目录存在
- 若目录不存在或为空，必须返回非零退出码并输出错误信息
- 若目录存在且包含至少一个文件，必须通过检查

#### Scenario: SC-QG-001-01 归档时无 Green 证据

- **Given**: 变更包已完成实现
- **When**: 执行归档检查且 `evidence/green-final/` 不存在
- **Then**: 检查失败，输出 "缺少 Green 证据: evidence/green-final/ 不存在"

#### Scenario: SC-QG-001-02 归档时有 Green 证据

- **Given**: 变更包已完成实现
- **When**: 执行归档检查且 `evidence/green-final/` 存在并包含测试日志
- **Then**: 检查通过，进入下一项检查

---

### Requirement: REQ-QG-002 任务完成率检查

**描述**：系统 MUST 在严格模式下验证任务完成率为 100%。

**优先级**：P0（必须）

**验收条件**：
- `change-check.sh --mode strict` 执行时，必须扫描 `tasks.md`
- 若存在未完成任务（`[ ]` 标记），必须返回非零退出码
- 若所有任务已完成（`[x]` 或 `[X]` 标记），必须通过检查

#### Scenario: SC-QG-002-01 存在未完成任务

- **Given**: `tasks.md` 包含 10 个任务，其中 2 个未完成
- **When**: 执行严格模式检查
- **Then**: 检查失败，输出 "任务完成率 80% (8/10)，需要 100%"

#### Scenario: SC-QG-002-02 所有任务已完成

- **Given**: `tasks.md` 包含 10 个任务，全部标记完成
- **When**: 执行严格模式检查
- **Then**: 检查通过

---

### Requirement: REQ-QG-003 Coder 角色边界检查

**描述**：系统 MUST 在 Coder 角色下禁止修改测试文件。

**优先级**：P1（重要）

**验收条件**：
- `change-check.sh --mode apply --role coder` 执行时，必须检查 `tests/**` 是否有修改
- 若 `tests/**` 有修改，必须返回非零退出码
- 若 `tests/**` 无修改，必须通过检查

#### Scenario: SC-QG-003-01 Coder 修改了测试文件

- **Given**: 当前角色为 Coder
- **When**: 执行 apply 检查且 `tests/example.test.ts` 有修改
- **Then**: 检查失败，输出 "角色违规: Coder 禁止修改 tests/**"

#### Scenario: SC-QG-003-02 Coder 只修改源码

- **Given**: 当前角色为 Coder
- **When**: 执行 apply 检查且只有 `src/**` 有修改
- **Then**: 检查通过

---

### Requirement: REQ-QG-004 P0 任务跳过审批检查

**描述**：系统 MUST 验证 P0 任务跳过有审批记录。

**优先级**：P1（重要）

**验收条件**：
- 在严格模式下，必须扫描 `tasks.md` 中的 P0 任务
- 若 P0 任务被跳过（`[ ]` 标记）但无 `<!-- SKIP-APPROVED: <reason> -->` 注释，必须失败
- SKIP-APPROVED 检测范围：任务行的前一行、同一行或后一行（三行范围检测）
- 若 P0 任务已完成或有跳过审批，必须通过

#### Scenario: SC-QG-004-01 P0 任务无审批跳过

- **Given**: `tasks.md` 包含 `- [ ] [P0] 核心功能` 且无审批注释
- **When**: 执行严格模式检查
- **Then**: 检查失败，输出 "P0 任务跳过需审批: 核心功能"

#### Scenario: SC-QG-004-02 P0 任务有审批跳过

- **Given**: `tasks.md` 包含带审批注释的 P0 跳过任务
- **When**: 执行严格模式检查
- **Then**: 检查通过（已审批跳过）

---

### Requirement: REQ-QG-005 测试失败归档拦截

**描述**：系统 MUST 在归档模式下验证测试全部通过。

**优先级**：P0（必须）

**验收条件**：
- 检查 `evidence/green-final/` 中的测试报告（`.log`、`.tap`、`.txt` 文件）
- 若报告中存在失败记录，必须返回非零退出码
- 支持多框架失败模式：TAP (`not ok`)、Jest/pytest/Go (`FAIL:`)、BATS、通用 (`FAILED`)
- 排除误报：注释行、成功统计（如 `0 tests FAIL`）、表格分隔符
- 若所有测试通过，必须通过检查

#### Scenario: SC-QG-005-01 Green 证据包含失败

- **Given**: `evidence/green-final/test-results.log` 包含 "FAILED: test_example"
- **When**: 执行归档检查
- **Then**: 检查失败，输出 "测试失败: 不能归档"

#### Scenario: SC-QG-005-02 Green 证据全部通过

- **Given**: `evidence/green-final/test-results.log` 只包含 "PASSED" 记录
- **When**: 执行归档检查
- **Then**: 检查通过

---

### Requirement: REQ-QG-006 模式参数契约

**描述**：系统 MUST 支持扩展的 `--mode` 和 `--role` 参数。

**优先级**：P0（必须）

**参数契约**：
- `--mode proposal`：proposal 阶段检查
- `--mode apply`：apply 阶段检查，支持 `--role` 参数
- `--mode archive`：归档检查（含 Green 证据检查）
- `--mode strict`：严格模式（含任务完成率、P0 跳过审批检查）
- `--role coder|test-owner|reviewer`：角色边界检查

#### Scenario: SC-QG-006-01 使用角色参数

- **Given**: change-check.sh 已更新
- **When**: 执行 `change-check.sh --mode apply --role coder`
- **Then**: 脚本识别 `--role` 参数并执行角色边界检查
