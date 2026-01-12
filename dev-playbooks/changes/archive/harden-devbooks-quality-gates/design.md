# Design: harden-devbooks-quality-gates

---
version: 1.1
status: Complete
created: 2026-01-11
owner: Design Owner
last_verified: 2026-01-11
freshness_check: 1 Month
scope: DevBooks 质量闸门强化
backport_date: 2026-01-11
backport_items: BF-01, BF-02, BF-03, BF-04, BF-05
---

## Acceptance Criteria（验收标准）

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 | 关联 KPI |
|-------|----------|----------------|----------|----------|
| AC-001 | Green 证据强制检查 | `change-check.sh --mode archive` 在 `evidence/green-final/` 不存在时返回非零退出码 | A | KPI-1 |
| AC-002 | 任务完成率检查 | `change-check.sh --mode strict` 在 tasks.md 中存在未完成 `[ ]` 项时返回非零退出码 | A | KPI-1 |
| AC-003 | Coder 角色边界检查 | `change-check.sh --mode apply --role coder` 在 tests/** 有修改时返回非零退出码 | A | KPI-2 |
| AC-004 | 角色交接握手检查 | `handoff-check.sh` 在 handoff.md 无确认签名时返回非零退出码 | A | KPI-2 |
| AC-005 | P0 任务跳过检查 | `change-check.sh --mode strict` 在 P0 任务被标记跳过且无审批记录时返回非零退出码 | A | KPI-3 |
| AC-006 | 测试环境匹配检查 | `env-match-check.sh` 在 verification.md 无环境声明节时返回非零退出码 | A | KPI-1 |
| AC-007 | 测试失败归档拦截 | `change-check.sh --mode archive` 在 evidence/green-final/ 中存在失败记录时返回非零退出码 | A | KPI-1 |
| AC-008 | 新脚本静态检查 | `shellcheck` 对所有新增 .sh 文件返回零退出码 | A | - |
| AC-009 | 帮助文档完整性 | 所有新增脚本支持 `--help` 参数并输出用法说明 | A | - |
| AC-010 | 仪表板输出验证 | `progress-dashboard.sh <change-id>` 输出包含"任务完成率"、"角色状态"、"证据状态"三节 | A | - |
| AC-011 | 审计全量扫描精度 | `audit-scope.sh` 扫描结果与手工抽样（10 个文件）的偏差 < 1.5x | B | KPI-4 |
| AC-012 | 测试框架可运行 | `make test` 返回零退出码 | A | - |

**验收方式说明**：A = 机器裁判（自动化测试）；B = 工具证据 + 人签核；C = 纯人工验收

---

## Goals / Non-goals / Red Lines

### Goals（本次变更目标）

1. **拦截假完成**：强制要求 Green 证据存在才能归档
2. **保障角色隔离**：通过检查机制确保 Coder 不修改 tests/
3. **规范任务降级**：P0 任务跳过必须有审批记录
4. **提升审计精度**：提供全量扫描工具，降低审计低估倍数

### Non-goals（显式排除）

1. 不修改现有 Skills 的核心逻辑（只增强闸门检查）
2. 不新增业务功能
3. 不重构现有目录结构
4. 不涉及 MCP Server 层

### Red Lines（不可破约束）

1. **向后兼容**：现有合规的变更包必须仍能通过闸门
2. **逃生舱口**：必须保留 `--skip-check <item>` 机制，但需记录原因
3. **POSIX 兼容**：所有脚本使用 POSIX 兼容写法，不依赖 Bash 4+ 特性
4. **测试基础设施先行**：Phase 0 必须在其他阶段前完成
5. **ripgrep 依赖**：所有脚本依赖 `rg`（ripgrep）进行模式搜索（实现中澄清）

---

## 执行摘要

DevBooks 工作流存在"假完成"问题（约 40%），核心原因是缺乏 Green 证据强制检查和角色边界约束。本设计通过在 `change-check.sh` 中新增 4 个检查函数、引入角色交接握手机制、提供全量审计工具来强化质量闸门，目标是将假完成率降至 < 5%。

---

## Problem Context（问题背景）

### 为什么要解决这个问题？

根据 `DEVBOOKS-GAP-ANALYSIS-REPORT.md` 诊断：

| 问题类别 | 数量 | 核心影响 |
|----------|------|----------|
| 缺失环节 | 5 | 流程断裂、假完成（任务完成率仅 25%） |
| 薄弱环节 | 4 | 验收放水、质量下降（测试失败仍可归档） |
| 设计缺陷 | 3 | 角色断档、任务跳过（Test Owner 任务被绕过） |

### 当前系统的摩擦点

1. **无 Green 证据检查**：归档时不验证测试是否真正通过
2. **无角色交接握手**：角色切换时信息丢失
3. **任务跳过无审批**：P0 任务被静默跳过
4. **审计低估严重**：人工抽样与实际偏差达 2-13x

### 不解决的后果

- 假完成累积导致技术债务失控
- 角色隔离形同虚设
- 质量退化被掩盖，问题发现延迟

---

## 价值链映射

```
Goal: 假完成率 < 5%
    │
    ├── 阻碍：无 Green 证据强制检查
    │   └── 杠杆：在 archive 模式新增 check_evidence_closure()
    │
    ├── 阻碍：角色边界可被绕过
    │   └── 杠杆：扩展 check_no_tests_changed() 为 check_role_boundaries()
    │
    └── 阻碍：任务跳过无审计
        └── 杠杆：在 tasks.md 引入 P0/P1/P2 分级 + 跳过审批机制
```

---

## 设计原则

### 核心原则

1. **增量增强**：在现有脚本基础上扩展，不引入新的调用链
2. **证据驱动**：所有检查都要求可观察的证据（文件存在/内容匹配）
3. **逃生舱口**：严格但不死板，提供有记录的跳过机制

### 变化点识别（Variation Points）

| 变化点 | 封装方式 | 说明 |
|--------|----------|------|
| 检查项列表 | 函数级封装 | 每个检查项为独立函数，便于增删 |
| 严格程度 | 模式参数 | `--mode proposal/apply/archive/strict` |
| 角色约束 | 角色参数 | `--role test-owner/coder/reviewer` |
| 跳过机制 | 白名单参数 | `--skip-check <item>` |

---

## 目标架构

### Bounded Context（边界上下文）

本次变更限定在 `skills/devbooks-delivery-workflow/` 边界内：

```
skills/devbooks-delivery-workflow/
├── scripts/
│   ├── change-check.sh      ← 核心增强（4 个新函数）
│   ├── handoff-check.sh     ← 新增
│   ├── env-match-check.sh   ← 新增
│   ├── audit-scope.sh       ← 新增
│   ├── progress-dashboard.sh ← 新增
│   └── migrate-to-v2-gates.sh ← 新增
└── templates/
    └── handoff.md           ← 新增
```

### 依赖方向约束

```
devbooks-router (调用方)
       │
       ▼
change-check.sh (本次增强)
       │
       ├──► handoff-check.sh (新增，被调用)
       ├──► env-match-check.sh (新增，被调用)
       └──► audit-scope.sh (新增，独立工具)
```

**禁止反向依赖**：新增脚本不应依赖 change-check.sh；handoff-check.sh 等为独立可调用的工具脚本。

### C4 Delta（架构增量）

> 本节描述本次变更对 `openspec/specs/architecture/c4.md` 的增量影响。归档时需合并到权威 C4 地图。

#### C1 系统上下文（无变化）

本次变更不影响系统边界、外部系统或主要用户。

#### C2 容器级变化

| 操作 | 容器 | 说明 | 影响 |
|------|------|------|------|
| 新增 | `tests/bats/` | BATS 测试目录（Phase 0） | 新增测试基础设施容器 |
| 修改 | `skills/devbooks-delivery-workflow/scripts/` | 新增 5 个脚本 | 脚本数量从 5 增至 10 |

**C2 更新内容**（归档时合并到 c4.md）：

```markdown
| 容器 | 作用 | 证据 |
|---|---|---|
| `tests/` | BATS 测试文件 | `tests/` |
```

#### C3 组件级变化

**skills/devbooks-delivery-workflow/scripts/ 组件变化**：

| 操作 | 组件 | 职责 | 调用关系 |
|------|------|------|----------|
| 增强 | `change-check.sh` | 核心闸门检查（+4 函数） | 被 devbooks-router 调用 |
| 新增 | `handoff-check.sh` | 角色交接握手检查 | 可被 change-check.sh 调用 |
| 新增 | `env-match-check.sh` | 测试环境匹配检查 | 可被 change-check.sh 调用 |
| 新增 | `audit-scope.sh` | 全量审计扫描 | 独立工具，不被其他脚本调用 |
| 新增 | `progress-dashboard.sh` | 进度可视化仪表板 | 独立工具，不被其他脚本调用 |
| 新增 | `migrate-to-v2-gates.sh` | v2 闸门迁移工具 | 一次性迁移工具 |

**C3 更新内容**（归档时合并到 c4.md）：

```markdown
### skills/devbooks-delivery-workflow/scripts/ 组件

| 脚本 | 职责 | 调用方 |
|------|------|--------|
| `change-check.sh` | 变更包质量闸门检查 | devbooks-router |
| `change-scaffold.sh` | 变更包脚手架 | devbooks-router |
| `prototype-promote.sh` | 原型提升 | 手动调用 |
| `handoff-check.sh` | 角色交接检查 | change-check.sh / 手动 |
| `env-match-check.sh` | 环境匹配检查 | change-check.sh / 手动 |
| `audit-scope.sh` | 审计全量扫描 | 手动调用 |
| `progress-dashboard.sh` | 进度仪表板 | 手动调用 |
| `migrate-to-v2-gates.sh` | v2 迁移工具 | 一次性迁移 |
```

#### 依赖方向变化

**新增依赖**：

```
change-check.sh
       │
       ├──► handoff-check.sh (可选调用)
       └──► env-match-check.sh (可选调用)
```

**依赖方向约束（保持不变）**：

- `devbooks-router` → `change-check.sh`（允许）
- `change-check.sh` → `handoff-check.sh`（允许，可选）
- `handoff-check.sh` → `change-check.sh`（**禁止**，反向依赖）
- `audit-scope.sh` → `change-check.sh`（**禁止**，独立工具）

#### Architecture Guardrails（建议新增）

本次变更建议在 `openspec/specs/architecture/c4.md` 的 `## Architecture Guardrails` 章节新增以下条目：

**Fitness Test FT-001: 脚本依赖方向检查**

```markdown
### FT-001: 脚本依赖方向

**规则**：独立工具脚本（audit-scope.sh、progress-dashboard.sh）不应依赖 change-check.sh

**检查命令**：
```bash
# 检查 audit-scope.sh 是否引用 change-check.sh
rg "change-check" skills/devbooks-delivery-workflow/scripts/audit-scope.sh && echo "FAIL" || echo "OK"
```

**严重程度**：High
```

**Fitness Test FT-002: 闸门脚本退出码契约**

```markdown
### FT-002: 闸门脚本退出码

**规则**：所有闸门检查脚本必须遵守退出码契约（0=成功，1=失败，2=用法错误）

**检查方式**：BATS 测试覆盖

**严重程度**：Critical
```

**Fitness Test FT-003: 新脚本帮助文档**

```markdown
### FT-003: 脚本帮助文档

**规则**：所有 scripts/ 下的 .sh 文件必须支持 --help 参数

**检查命令**：
```bash
for script in skills/devbooks-delivery-workflow/scripts/*.sh; do
  $script --help >/dev/null 2>&1 || echo "FAIL: $script"
done
```

**严重程度**：Medium
```

#### C4 归档任务

归档时需执行以下更新：

| 任务 | 目标文件 | 内容 |
|------|----------|------|
| T-C4-01 | `openspec/specs/architecture/c4.md` | 更新 C2 容器表，新增 `tests/` 行 |
| T-C4-02 | `openspec/specs/architecture/c4.md` | 更新 C3 组件表，新增 scripts/ 组件清单 |
| T-C4-03 | `openspec/specs/architecture/c4.md` | 新增 Architecture Guardrails 章节（FT-001/002/003） |

---

## 核心数据与契约

### change-check.sh 退出码契约

| 退出码 | 含义 | 兼容性 |
|--------|------|--------|
| 0 | 所有检查通过 | 保持不变 |
| 1 | 检查失败 | 保持不变 |
| 2 | 用法错误 | 保持不变 |

### 模板格式契约

**tasks.md 任务分级标记**：

```markdown
- [x] [P0] 核心功能实现
- [ ] [P1] 性能优化
- [ ] [P2] 文档补充
```

- 未标记分级的任务视为 P2（向后兼容）
- P0 任务跳过需在任务行的前一行、同一行或后一行添加 `<!-- SKIP-APPROVED: <reason> -->`（实现中扩展为三行范围检测）

**verification.md 环境声明节**：

```markdown
## 测试环境声明

- 运行环境：macOS 14 / Ubuntu 22.04
- 数据库：N/A
- 外部依赖：无
```

- 必填节（archive 模式强制检查）
- 可写 `N/A` 表示无特殊环境要求

**handoff.md 格式**：

```markdown
# 角色交接记录

## 交接信息
- 交出角色：Test Owner
- 接收角色：Coder
- 交接时间：2026-01-11

## 交接内容
- verification.md 已产出
- Red 基线已记录到 evidence/red-baseline/

## 确认签名
- [ ] Test Owner 确认交接完成
- [ ] Coder 确认接收
```

---

## Contract（契约计划）

### CLI 接口契约

**change-check.sh 参数契约（v2）**：

| 参数 | 类型 | 必填 | 说明 | 兼容性 |
|------|------|------|------|--------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID | 保持不变 |
| `--mode` | 选项 | 是 | proposal/apply/archive/strict | 保持不变 |
| `--role` | 选项 | 否（apply 模式下建议） | test-owner/coder/reviewer | **新增** |
| `--skip-check` | 选项 | 否 | 跳过指定检查项 | **新增** |
| `--project-root` | 选项 | 否 | 项目根目录 | 保持不变 |
| `--change-root` | 选项 | 否 | 变更包根目录 | 保持不变 |

**handoff-check.sh 参数契约（v1.1）**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID |
| `--allow-partial` | 选项 | 否 | 允许部分签名通过（默认要求全部签名） |
| `--project-root` | 选项 | 否 | 项目根目录 |
| `--change-root` | 选项 | 否 | 变更包根目录 |

**handoff-check.sh 签名策略**（实现中澄清）：

- **默认行为**：要求 handoff.md 中所有 `- [ ]` 签名项都已勾选 `- [x]`
- **宽松模式**：`--allow-partial` 允许部分签名通过（适用于多角色链中间状态）
- **多角色链**：支持多次交接的完整链路验证

**env-match-check.sh 参数契约（v1）**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID |
| `--project-root` | 选项 | 否 | 项目根目录 |
| `--change-root` | 选项 | 否 | 变更包根目录 |

**audit-scope.sh 参数契约（v1）**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<directory>` | 位置参数 | 是 | 扫描目录 |
| `--format` | 选项 | 否 | 输出格式（markdown/json） |

**progress-dashboard.sh 参数契约（v1）**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `<change-id>` | 位置参数 | 是 | 变更包 ID |
| `--project-root` | 选项 | 否 | 项目根目录 |
| `--change-root` | 选项 | 否 | 变更包根目录 |

### 兼容策略

| 契约 | 变更类型 | 向后兼容 | 迁移说明 |
|------|----------|----------|----------|
| `change-check.sh --mode` | 行为增强 | 是（更严格） | 现有脚本无需修改 |
| `change-check.sh --role` | 新增参数 | 是（可选） | 不传递时使用默认行为 |
| `change-check.sh --skip-check` | 新增参数 | 是（可选） | 不传递时执行全部检查 |
| `tasks.md [P0]` 格式 | 新增可选标记 | 是 | 无标记视为 P2 |
| `verification.md` 环境声明节 | 新增必填节 | **否** | 需补充节（可写 N/A） |
| `handoff.md` | 新增文件 | 是（纯新增） | 角色交接时创建 |
| `evidence/` 目录结构 | 强制要求 | **否** | archive 前需创建 |

### 弃用策略

本次变更无弃用项。

### Contract Test IDs

| Test ID | 类型 | 覆盖场景 | 关联 AC |
|---------|------|----------|---------|
| CT-001 | behavior | change-check.sh --mode archive 无 Green 证据时失败 | AC-001 |
| CT-002 | behavior | change-check.sh --mode strict 任务未完成时失败 | AC-002 |
| CT-003 | behavior | change-check.sh --role coder tests/ 有修改时失败 | AC-003 |
| CT-004 | behavior | handoff-check.sh 无确认签名时失败 | AC-004 |
| CT-005 | behavior | change-check.sh P0 跳过无审批时失败 | AC-005 |
| CT-006 | behavior | env-match-check.sh 无环境声明时失败 | AC-006 |
| CT-007 | behavior | change-check.sh 测试失败时拒绝归档 | AC-007 |
| CT-008 | lint | shellcheck 对所有新增脚本通过 | AC-008 |
| CT-009 | behavior | 所有新增脚本支持 --help | AC-009 |
| CT-010 | output | progress-dashboard.sh 输出包含三节 | AC-010 |
| CT-011 | precision | audit-scope.sh 精度 < 1.5x | AC-011 |
| CT-012 | behavior | make test 可运行 | AC-012 |

---

## 关键机制

### 检查函数清单（change-check.sh 新增）

| 函数 | 触发模式 | 职责 |
|------|----------|------|
| `check_evidence_closure()` | archive, strict | 验证 evidence/red-baseline/ 和 evidence/green-final/ 存在 |
| `check_task_completion_rate()` | strict | 验证 tasks.md 中所有任务已完成 |
| `check_role_boundaries()` | apply --role | 验证角色未越界（扩展自 check_no_tests_changed） |
| `check_skip_approval()` | strict | 验证 P0 任务跳过有审批记录 |
| `check_test_failure_in_evidence()` | archive | 验证 Green 证据中无测试失败记录 |

### 测试失败检测契约（实现中澄清）

> 本节为实现过程中发现并回写的设计约束，用于 AC-007 验收。

**支持的测试框架失败模式**：

| 框架 | 失败模式 | 示例 |
|------|----------|------|
| TAP | `^not ok` | `not ok 1 - test description` |
| Jest/pytest/Go | `^FAIL[: ]` | `FAIL: TestSomething` |
| BATS | `not ok` | TAP 格式输出 |
| 通用 | `FAILED` | 各种框架的失败标记 |

**误报排除规则**：

- 排除注释行（`#` 开头）
- 排除成功统计（如 `0 tests FAIL`、`0 failed`）
- 排除表格分隔符中的 `FAIL` 字样

**检测范围**：扫描 `evidence/green-final/` 下所有 `.log`、`.tap`、`.txt` 文件。

### verification.md 可选章节策略（实现中澄清）

> 为向后兼容，部分章节从强制改为建议。

| 章节 | 模式 | 行为 |
|------|------|------|
| `## 测试环境声明` | archive | **必填**，缺失时报错 |
| `## G) 价值流与度量` | archive | **可选**，缺失时仅警告 |
| `## F) ...` | guardrail | **可选**，缺失时跳过检查 |

### 逃生舱口机制

```bash
change-check.sh <change-id> --mode strict --skip-check evidence_closure
```

- 使用 `--skip-check` 时必须在 `openspec/changes/<change-id>/skip-log.md` 记录原因
- Judge 审批时需确认跳过理由合理

---

## 可观测性与验收

### KPI 指标

| 指标 ID | 指标 | 当前 | 目标 | 观测方式 |
|---------|------|------|------|----------|
| KPI-1 | 假完成率 | ~40% | < 5% | `change-check.sh --mode archive` 失败率 |
| KPI-2 | 角色断档率 | ~30% | 0% | handoff.md 存在且有确认签名 |
| KPI-3 | 任务跳过未审批率 | ~50% | 0% | tasks.md 中 P0 跳过无 SKIP-APPROVED 注释 |
| KPI-4 | 审计低估倍数 | 2-13x | < 1.5x | audit-scope.sh 输出与手工抽样对比 |

---

## 风险与降级策略

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 新闸门过严导致效率下降 | 中 | 中 | 提供 `--skip-check` 逃生舱口（需记录） |
| 现有项目迁移成本 | 高 | 中 | 提供 `migrate-to-v2-gates.sh` 迁移脚本 |
| 脚本兼容性问题 | 低 | 低 | 使用 POSIX 兼容写法 + CI 多版本测试 |

### 降级路径

1. **单项降级**：`--skip-check <item>` 跳过特定检查
2. **模式降级**：使用 `--mode apply` 代替 `--mode strict`
3. **完全回滚**：`git revert` 到上一版本

---

## 里程碑（设计层面）

| 阶段 | 内容 | 前置依赖 | 验收锚点 |
|------|------|----------|----------|
| Phase 0 | 最小测试框架（Makefile + bats + CI） | 无 | AC-012 |
| Phase 1 | M1 + W1 + 迁移脚本 | Phase 0 | AC-001, AC-002 |
| Phase 2 | M2 + M3 + D3 | Phase 0 | AC-004, AC-005, AC-010 |
| Phase 3 | M4 + M5 + W2 + W3 | Phase 1, Phase 2 | AC-006, AC-011 |
| Phase 4 | D1 + D2 + W4 | Phase 3 | AC-003, AC-007 |

---

## Design Rationale（设计决策理由）

### D1：扩展 change-check.sh vs 新增 Skill

**决策**：选择扩展 `change-check.sh`

| 维度 | 新增 Skill | 扩展 change-check.sh（选中） |
|------|------------|------------------------------|
| 复杂度 | 高（3 新文件 + Router 集成） | 低（单函数扩展） |
| 维护成本 | 高（独立生命周期） | 低（统一维护） |
| 功能重复 | 与 check_no_tests_changed() 重叠 | 无重复 |

**理由**：`check_no_tests_changed()` 已实现核心功能，新增 Skill 的边际价值有限。

### Phase 0 前置

**决策**：测试框架必须在其他阶段前交付

**理由**：项目画像标注"项目级统一测试入口：TBD"，无测试基础设施则验收锚点无法验证。

---

## Trade-offs（权衡取舍）

| 取舍 | 放弃什么 | 获得什么 |
|------|----------|----------|
| 增量增强而非重写 | 不能彻底优化架构 | 最小侵入性、低风险 |
| 强制证据检查 | 开发效率可能下降 | 假完成被拦截 |
| P0 跳过需审批 | 灵活性降低 | 关键任务不被遗漏 |

---

## DoD 完成定义（Definition of Done）

本设计在以下条件全部满足时视为"完成"：

### 必须通过的闸门

1. `make test` 返回零退出码（AC-012）
2. `make lint`（shellcheck）对所有新增脚本返回零退出码（AC-008）
3. 所有 AC-001 至 AC-011 验收通过

### 必须产出的证据

| 证据 | 落点 | 关联 AC |
|------|------|---------|
| Phase 0 基线日志 | `evidence/phase0-baseline.log` | AC-012 |
| Green 证据检查日志 | `evidence/ac-001.log` | AC-001 |
| 任务完成率检查日志 | `evidence/ac-002.log` | AC-002 |
| 角色边界检查日志 | `evidence/ac-003.log` | AC-003 |
| 交接握手检查日志 | `evidence/ac-004.log` | AC-004 |
| P0 跳过检查日志 | `evidence/ac-005.log` | AC-005 |
| 环境匹配检查日志 | `evidence/ac-006.log` | AC-006 |
| 归档拦截检查日志 | `evidence/ac-007.log` | AC-007 |
| shellcheck 日志 | `evidence/shellcheck.log` | AC-008 |
| 帮助文档检查日志 | `evidence/help-check.log` | AC-009 |
| 仪表板样例 | `evidence/dashboard-sample.md` | AC-010 |
| 审计精度验证日志 | `evidence/ac-011.log` | AC-011 |

---

## Open Questions（<=3）

1. **Q1**：现有变更包中有多少不符合新闸门？需要运行 `change-check.sh --mode strict` 对 `openspec/changes/` 进行扫描评估迁移成本。

2. **Q2**：`verification.md` 环境声明节是否允许写 `N/A`？建议允许（降低负担），但需明确写法规范。

3. **Q3**：逃生舱口 `--skip-check` 是否需要 Judge 审批？Proposal 中 Q4 待裁决。

---

**设计文档结束**
