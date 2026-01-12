# Proposal: harden-devbooks-quality-gates

> **状态**: Pending（修订后重新提交）
> **创建日期**: 2026-01-11
> **作者**: Proposal Author
> **修订日期**: 2026-01-11
> **裁决日期**: 2026-01-11
> **裁决人**: Proposal Judge

---

## 1. Why（问题与目标）

### 1.1 问题陈述

根据 `DEVBOOKS-GAP-ANALYSIS-REPORT.md` 的诊断，DevBooks 工作流存在以下根本性缺陷导致"修复后问题反升"：

| 问题类别 | 数量 | 核心影响 |
|----------|------|----------|
| 缺失环节 | 5 | 流程断裂、假完成（任务完成率仅 25%） |
| 薄弱环节 | 4 | 验收放水、质量下降（测试失败仍可归档） |
| 设计缺陷 | 3 | 角色断档、任务跳过（Test Owner 任务被绕过） |

**关键指标恶化**：

| 指标 | 当前值 | 问题来源 |
|------|--------|----------|
| 假完成率 | ~40% | 无 Green 证据检查 |
| 角色断档率 | ~30% | 无交接握手机制 |
| 任务跳过未审批率 | ~50% | 无任务分级与降级审批 |
| 审计低估倍数 | 2-13x | 无全量扫描工具 |

### 1.2 目标

**核心目标**：强化 DevBooks 质量闸门，使工作流具备"假完成拦截"能力。

**成功标准**：

| 指标 | 当前 | 目标 |
|------|------|------|
| 假完成率 | ~40% | < 5% |
| 角色断档率 | ~30% | 0% |
| 任务跳过未审批率 | ~50% | 0% |
| 审计低估倍数 | 2-13x | < 1.5x |

---

## 2. What Changes（范围）

### 2.1 变更范围（14 项）

#### 基础设施前置（1 项）— REV-1 新增

| ID | 名称 | 产物 | 优先级 |
|----|------|------|--------|
| T0 | 最小测试框架 | `Makefile` + `tests/bats/` + `.github/workflows/test.yml` | P0 |

> **说明**：项目画像 `project-profile.md:83` 标注"项目级统一测试入口：TBD"，需先交付测试基础设施才能验证后续 AC。

#### 缺失环节修复（5 项）

| ID | 名称 | 产物 | 优先级 |
|----|------|------|--------|
| M1 | Green 证据强制检查 | `change-check.sh` 增强 | P0 |
| M2 | 角色交接握手机制 | `handoff-check.sh` 新增 + `handoff.md` 模板 | P0 |
| M3 | 任务降级审批流程 | `tasks.md` 模板更新 + `change-check.sh` 增强 | P1 |
| M4 | 原始审计精度工具 | `audit-scope.sh` 新增 | P1 |
| M5 | 测试环境匹配验证 | `env-match-check.sh` 新增 + `verification.md` 模板更新 | P1 |

#### 薄弱环节加固（4 项）

| ID | 名称 | 产物 | 优先级 |
|----|------|------|--------|
| W1 | 验收闸门 strict 模式增强 | `change-check.sh` 增强（任务完成率、证据闭环、测试通过率） | P0 |
| W2 | 阻塞项降级审批 | `devbooks-code-review/SKILL.md` 更新 + 降级模板 | P1 |
| W3 | TODO 检查时机前移 | `change-check.sh` apply 模式增强 | P1 |
| W4 | 技术债务强制记录 | `design.md` 模板更新 + `change-check.sh` 检查 | P2 |

#### 设计缺陷修正（3 项）

| ID | 名称 | 产物 | 优先级 |
|----|------|------|--------|
| D1 | 角色隔离执行保障 | `change-check.sh` 增强（扩展 `check_no_tests_changed()`）— 见 2.4 Trade-off 分析 | P1 |
| D2 | 原型提升质量闸门 | `prototype-promote.sh` 增强 | P2 |
| D3 | 全局进度可视化 | `progress-dashboard.sh` 新增 | P1 |

> **D1 决策**：经 REV-3 trade-off 分析，选择扩展现有 `check_no_tests_changed()` 而非新增独立 Skill。
> **D3 调整**：采纳 N3 建议，从 P2 提升到 P1。

### 2.2 非目标（显式排除）

| 排除项 | 原因 |
|--------|------|
| 修改现有 Skills 的核心逻辑 | 本次只增强闸门，不改变角色职责定义 |
| 新增业务功能 | 本次专注于流程质量守护 |
| 重构现有目录结构 | 保持向后兼容 |
| 修改 MCP Server | 不涉及 MCP 层 |

### 2.3 影响文件清单（19 个）

**修改文件（8 个）**：

1. `skills/devbooks-delivery-workflow/scripts/change-check.sh`
2. `skills/devbooks-delivery-workflow/scripts/prototype-promote.sh`
3. `skills/devbooks-code-review/SKILL.md`
4. `skills/devbooks-implementation-plan/templates/tasks.md`
5. `skills/devbooks-test-owner/templates/verification.md`
6. `skills/devbooks-design-doc/templates/design.md`
7. `openspec/project.md`（增加闸门说明）
8. `.devbooks/config.yaml`（增加闸门配置项）

**新增文件（11 个）**：

1. `Makefile`（测试入口）— T0
2. `tests/bats/change-check.bats`（单元测试）— T0
3. `tests/bats/test_helper.bash`（测试辅助）— T0
4. `.github/workflows/test.yml`（CI 配置）— T0
5. `skills/devbooks-delivery-workflow/scripts/handoff-check.sh` — M2
6. `skills/devbooks-delivery-workflow/scripts/env-match-check.sh` — M5
7. `skills/devbooks-delivery-workflow/scripts/audit-scope.sh` — M4
8. `skills/devbooks-delivery-workflow/scripts/progress-dashboard.sh` — D3
9. `skills/devbooks-delivery-workflow/scripts/migrate-to-v2-gates.sh` — R2 缓解 ✅ REV-2
10. `skills/devbooks-delivery-workflow/templates/handoff.md` — M2
11. `docs/quality-gates-guide.md` — 文档

> **REV-2 说明**：`migrate-to-v2-gates.sh` 已显式纳入交付清单，交付阶段为 Phase 1。

### 2.4 D1 Trade-off 分析 — REV-3 新增

**问题**：D1"角色隔离执行保障"原计划新增完整 Skill（3 文件），但核心功能"检测 Coder 是否修改 tests/"已存在于 `change-check.sh:check_no_tests_changed()`。

**方案对比**：

| 维度 | 方案 A：新增 Skill | 方案 B：扩展 change-check.sh |
|------|-------------------|------------------------------|
| **复杂度** | 高（3 新文件 + SKILL.md + Router 集成） | 低（单函数扩展） |
| **维护成本** | 高（独立生命周期） | 低（与现有脚本统一维护） |
| **调用链** | 需 Router 新增路由规则 | 无变化，复用现有 `--role` 参数 |
| **功能重复** | 与 `check_no_tests_changed()` 重叠 | 无重复 |
| **扩展性** | 可独立演进 | 受限于 change-check.sh 框架 |

**分析结论**：

1. **功能重复问题**：`check_no_tests_changed()` 已实现核心功能（Coder 禁止修改 tests/**），新增 Skill 的边际价值有限。
2. **维护成本**：新增 Skill 需要：SKILL.md（~50 行）+ role-guard.sh（~100 行）+ role-declaration.md（~30 行）+ Router 路由规则更新，总计 ~200 行新增代码。
3. **调用链影响**：新增 Skill 需要在 `devbooks-router/SKILL.md` 中添加自动触发逻辑，增加复杂度。

**决策**：选择 **方案 B（扩展 change-check.sh）**

**实施方式**：
- 扩展 `check_no_tests_changed()` 为 `check_role_boundaries()`
- 支持更细粒度的角色边界检查（不仅限于 tests/）
- 新增 `--role` 参数的文档化约束

**降级影响**：
- 移除新增文件：`skills/devbooks-role-isolation/SKILL.md`、`scripts/role-guard.sh`、`templates/role-declaration.md`
- 新增文件数从 12 降为 11

---

## 3. Impact（影响分析）

> **分析模式**: 文本搜索（降级模式）— SCIP 索引不可用
> **分析日期**: 2026-01-11
> **分析人**: Impact Analyst

### 3.1 Transaction Scope

**`None`** — 本变更不涉及数据库或跨服务事务，仅为脚本与文档层面的增强。

### 3.2 Scope 摘要

| 维度 | 数量 | 说明 |
|------|------|------|
| 直接影响文件 | 8 | 需要修改的现有文件 |
| 间接影响文件 | 7 | 依赖变更文件的下游 |
| 新增文件 | 12 | 新增脚本/模板/Skill |
| 热点重叠 | 0 | 本次变更不涉及热点文件 |

### 3.3 直接影响文件（详细分析）

| 文件 | 影响类型 | 风险等级 | 热点? | 说明 |
|------|----------|----------|-------|------|
| `skills/devbooks-delivery-workflow/scripts/change-check.sh` | 核心增强 | 🔴 高 | - | 529 行脚本，新增 4 个检查函数 |
| `skills/devbooks-delivery-workflow/scripts/prototype-promote.sh` | 增强 | 🟡 中 | - | 新增质量闸门检查 |
| `skills/devbooks-code-review/SKILL.md` | 文档更新 | 🟢 低 | - | 增加阻塞项分级说明 |
| `skills/devbooks-implementation-plan/templates/tasks.md` | 模板更新 | 🟡 中 | - | 增加 P0/P1/P2 分级格式 |
| `skills/devbooks-test-owner/templates/verification.md` | 模板更新 | 🟡 中 | - | 新增"测试环境声明"必填节 |
| `skills/devbooks-design-doc/templates/design.md` | 模板更新 | 🟢 低 | - | 新增技术债务记录节 |
| `openspec/project.md` | 规则更新 | 🟢 低 | - | 增加闸门说明 |
| `.devbooks/config.yaml` | 配置更新 | 🟢 低 | - | 增加闸门配置项 |

### 3.4 调用链分析

**`change-check.sh` 的上游调用方（3 个）**：

```
devbooks-router/SKILL.md:100    → change-check.sh <change-id> --mode proposal
devbooks-router/SKILL.md:115    → change-check.sh <change-id> --mode apply --role test-owner
devbooks-router/SKILL.md:117    → change-check.sh <change-id> --mode apply --role coder
devbooks-router/SKILL.md:138    → change-check.sh <change-id> --mode strict
devbooks-spec-contract/SKILL.md:119 → 与 change-check.sh 集成（apply/archive/strict）
devbooks-delivery-workflow/SKILL.md:41 → 文档引用
```

**change-check.sh 内部调用的函数**：

```
check_proposal()           → 检查 proposal.md 格式与状态
check_design()             → 检查 design.md 结构
check_tasks()              → 检查 tasks.md 完成度  ← 本次增强
check_verification()       → 检查 verification.md  ← 本次增强
check_spec_deltas()        → 检查 spec delta 格式
check_no_tests_changed()   → Coder 角色约束
check_implicit_changes()   → 隐式变更检测
[NEW] check_evidence_closure()     ← 新增
[NEW] check_task_completion_rate() ← 新增
```

### 3.5 间接影响（下游依赖）

| Skills | 影响方式 | 风险等级 | 变更说明 |
|--------|----------|----------|----------|
| `devbooks-router` | 调用 change-check.sh | 🟡 中 | 闸门更严格，可能拒绝更多变更包 |
| `devbooks-coder` | 受闸门约束 | 🟢 低 | 需遵守更严格的任务完成要求 |
| `devbooks-test-owner` | 模板更新 | 🟡 中 | 需填写测试环境声明 |
| `devbooks-spec-contract` | 集成检查 | 🟢 低 | 隐式变更检测无变化 |
| `devbooks-proposal-judge` | 审批流程 | 🟢 低 | 新增任务降级审批职责 |
| `devbooks-brownfield-bootstrap` | 模板引用 | 🟢 低 | 需同步更新模板引用 |
| 现有变更包（openspec/changes/**） | 迁移影响 | 🟡 中 | 现有变更包可能不符合新闸门 |

### 3.6 对外契约影响

| 契约 | 变更类型 | 影响描述 | 兼容性 | 迁移成本 |
|------|----------|----------|--------|----------|
| `change-check.sh --mode` | 行为增强 | archive/strict 模式新增 4 项检查 | 向后兼容（更严格） | 低 |
| `change-check.sh` 退出码 | 不变 | 0=成功，1=失败，2=用法错误 | 完全兼容 | 无 |
| `tasks.md` 格式 | 新增可选字段 | 增加 `[P0]`/`[P1]`/`[P2]` 任务分级标记 | 向后兼容（不带标记视为 P2） | 低 |
| `verification.md` 格式 | 新增必填节 | 增加"测试环境声明"节 | **需迁移** | 中 |
| `design.md` 格式 | 新增可选节 | 增加"Technical Debt"节 | 向后兼容 | 低 |
| `handoff.md` | 新增文件 | 角色交接时需创建 | 纯新增，无破坏 | 低 |
| `evidence/` 目录结构 | 强制要求 | archive 时必须有 `red-baseline/` 和 `green-final/` | **需迁移** | 中 |

### 3.7 热点叠加分析

**项目热点文件（近期高频变更）**：

| 热点文件 | 变更次数 | 本次是否涉及 |
|----------|----------|--------------|
| 使用说明书.md | 6 | ❌ 不涉及 |
| setup/README.md | 5 | ❌ 不涉及 |
| skills/devbooks-impact-analysis/SKILL.md | 4 | ❌ 不涉及 |
| README.md | 4 | ❌ 不涉及 |
| .gitignore | 4 | ❌ 不涉及 |

**结论**：本次变更不涉及热点文件，变更集中在 `skills/devbooks-delivery-workflow/scripts/` 目录，风险可控。

### 3.8 测试影响

| 测试类型 | 现有覆盖 | 本次需新增 | 说明 |
|----------|----------|------------|------|
| change-check.sh 单元测试 | 无 | **必须** | 核心脚本需要测试覆盖 |
| handoff-check.sh 测试 | - | **必须** | 新增脚本需测试 |
| env-match-check.sh 测试 | - | **必须** | 新增脚本需测试 |
| audit-scope.sh 测试 | - | 建议 | 工具脚本 |
| progress-dashboard.sh 测试 | - | 建议 | 可视化脚本 |
| shellcheck 静态检查 | 无 | **必须** | 所有 .sh 文件 |
| 集成测试（完整工作流） | 无 | 建议 | 模拟完整变更包生命周期 |

### 3.9 价值信号与观测口径

| 信号 | 预期变化 | 观测方式 |
|------|----------|----------|
| 归档成功率 | 下降（假完成被拦截） | `change-check.sh --mode archive` 失败率 |
| 任务完成真实率 | 上升（闸门强制） | tasks.md 中 `[x]` 数量 / 总任务数 |
| 角色交接完成率 | 上升（握手机制） | handoff.md 存在且有确认记录 |
| 变更周期 | 可能延长（更严格的验收） | 从 proposal 到 archive 的天数 |
| Red-Green 闭环率 | 上升（强制证据） | evidence/red-baseline 与 green-final 同时存在 |

### 3.10 价值流瓶颈假设

- **假设 1**：假完成率高是因为缺乏强制 Green 证据检查 → 本次增加 `check_evidence_closure()`
- **假设 2**：角色断档是因为无交接协议 → 本次增加 `handoff-check.sh` 和 `handoff.md`
- **假设 3**：任务跳过是因为无分级与审批机制 → 本次增加 P0/P1/P2 分级和跳过审批流程

### 3.11 Minimal Diff 建议

为降低风险，建议分阶段实施：

| 阶段 | 变更内容 | 影响范围 | 风险 |
|------|----------|----------|------|
| **Phase 1** | M1 + W1（Green 证据 + 任务完成率检查） | change-check.sh | 中 |
| **Phase 2** | M2（交接握手机制） | 新增 handoff-check.sh | 低 |
| **Phase 3** | M3 + W3（任务分级 + TODO 前移） | tasks.md 模板 + change-check.sh | 中 |
| **Phase 4** | M4 + M5（审计工具 + 环境检查） | 新增脚本 | 低 |
| **Phase 5** | D1 + D2 + D3（角色隔离 + 原型提升 + 仪表板） | 新增 Skill | 低 |

### 3.12 Open Questions（影响分析层面）

| 问题 | 影响 | 建议验证方式 |
|------|------|--------------|
| 现有变更包中有多少不符合新闸门？ | 迁移成本评估 | 对 openspec/changes/ 运行 change-check.sh --mode strict |
| change-check.sh 新增检查对性能影响？ | CI 时间 | 基准测试 |
| 模板格式变更是否需要迁移脚本？ | 用户体验 | 评估手工迁移工作量 |

---

## 4. Risks & Rollback（风险与回滚）

### 4.1 风险清单

| 风险 ID | 描述 | 影响 | 概率 | 缓解措施 |
|---------|------|------|------|----------|
| R1 | 新闸门过于严格导致开发效率下降 | 中 | 中 | 提供 `--skip-check <item>` 逃生舱口（需记录原因） |
| R2 | 现有项目迁移成本 | 中 | 高 | 提供迁移脚本 `migrate-to-v2-gates.sh` |
| R3 | 角色隔离检测误报 | 低 | 中 | 提供白名单机制 |
| R4 | 脚本兼容性问题（不同 Bash 版本） | 低 | 低 | 使用 POSIX 兼容写法 + CI 多版本测试 |

### 4.2 回滚策略

| 层级 | 回滚方式 | 时间 |
|------|----------|------|
| 单脚本 | 恢复到 git 上一版本 | < 1 分钟 |
| 整体变更 | `git revert` 提交 | < 5 分钟 |
| 配置层 | 注释 `.devbooks/config.yaml` 中的新配置项 | < 1 分钟 |

---

## 5. Validation（验收锚点）

### 5.1 验收标准（AC）与成功指标追溯矩阵 — REV-4 更新

**成功标准回顾**（1.2 节）：

| 指标 ID | 指标 | 当前 | 目标 |
|---------|------|------|------|
| KPI-1 | 假完成率 | ~40% | < 5% |
| KPI-2 | 角色断档率 | ~30% | 0% |
| KPI-3 | 任务跳过未审批率 | ~50% | 0% |
| KPI-4 | 审计低估倍数 | 2-13x | < 1.5x |

**AC 与 KPI 追溯矩阵**：

| AC ID | 验收条件 | 验证方法 | 证据落点 | 关联 KPI |
|-------|----------|----------|----------|----------|
| AC-001 | 无 Green 证据时 `change-check.sh --mode archive` 报错 | `bats tests/bats/change-check.bats` | `evidence/ac-001.log` | **KPI-1** |
| AC-002 | 任务完成率 < 100% 时 `change-check.sh --mode strict` 报错 | `bats tests/bats/change-check.bats` | `evidence/ac-002.log` | **KPI-1** |
| AC-003 | Coder 修改 tests/** 时 `--role coder` 报错 | `bats tests/bats/change-check.bats` | `evidence/ac-003.log` | **KPI-2** |
| AC-004 | 角色交接无确认时 `handoff-check.sh` 报错 | `bats tests/bats/handoff-check.bats` | `evidence/ac-004.log` | **KPI-2** |
| AC-005 | P0 任务被跳过时 `change-check.sh` 报错 | `bats tests/bats/change-check.bats` | `evidence/ac-005.log` | **KPI-3** |
| AC-006 | 测试环境不匹配未声明时 `env-match-check.sh` 报错 | `bats tests/bats/env-match-check.bats` | `evidence/ac-006.log` | **KPI-1** |
| AC-007 | 测试失败但尝试归档时 `change-check.sh` 报错 | `bats tests/bats/change-check.bats` | `evidence/ac-007.log` | **KPI-1** |
| AC-008 | 所有新脚本通过 shellcheck | `make lint` | `evidence/shellcheck.log` | - |
| AC-009 | 所有新脚本有 `--help` 帮助文档 | `make help-check` | `evidence/help-check.log` | - |
| AC-010 | `progress-dashboard.sh` 生成正确的仪表板 | 执行并验证输出 | `evidence/dashboard-sample.md` | - |
| AC-011 | `audit-scope.sh` 全量扫描结果准确 | 对照手工抽样 | `evidence/ac-011.log` | **KPI-4** |
| AC-012 | 测试框架可运行 `make test` 通过 | `make test` | `evidence/phase0-baseline.log` | - |

**KPI 覆盖统计**：

| KPI | 关联 AC 数量 | AC 列表 |
|-----|-------------|---------|
| KPI-1（假完成率） | 4 | AC-001, AC-002, AC-006, AC-007 |
| KPI-2（角色断档率） | 2 | AC-003, AC-004 |
| KPI-3（任务跳过未审批率） | 1 | AC-005 |
| KPI-4（审计低估倍数） | 1 | AC-011 |
| 基础设施 | 4 | AC-008, AC-009, AC-010, AC-012 |

### 5.2 测试矩阵

| 测试类型 | 覆盖范围 | 执行命令 |
|----------|----------|----------|
| 单元测试 | 各脚本独立功能 | `tests/scripts/run-unit-tests.sh` |
| 集成测试 | 完整工作流闸门 | `tests/scripts/run-integration-tests.sh` |
| 回归测试 | 现有功能不受影响 | `tests/scripts/run-regression-tests.sh` |

---

## 6. Debate Packet（争议点与辩论问题）

### 6.1 待辩论问题

| 问题 ID | 问题描述 | 立场 A | 立场 B | 建议 |
|---------|----------|--------|--------|------|
| Q1 | 任务分级是否应强制要求？ | 强制：所有任务必须标注 P0/P1/P2 | 可选：不标注视为 P2 | 建议 B（向后兼容） |
| Q2 | 角色隔离检测是否应在 Hook 层实现？ | Hook 层：实时拦截 | Skill 层：执行时检查 | 建议 Skill 层（更灵活） |
| Q3 | 测试环境声明是否应为必填？ | 必填：所有变更都需声明 | 按需：仅涉及数据库时必填 | 建议"按需"（减少负担） |
| Q4 | 逃生舱口是否应有审批机制？ | 需审批：`--skip-check` 需 Judge 确认 | 无需审批：记录即可 | 建议"需审批"（防止滥用） |
| Q5 | 新 Skill `devbooks-role-isolation` 是否应自动触发？ | 自动：Router 自动调用 | 手动：用户显式调用 | 建议"自动"（减少遗漏） |

### 6.2 不确定点

| 不确定项 | 描述 | 验证方法 |
|----------|------|----------|
| U1 | 现有项目中有多少不符合新闸门标准 | 运行 `audit-scope.sh` 扫描 |
| U2 | 新闸门对开发周期的具体影响 | 试点 2-3 个变更包后度量 |
| U3 | 角色隔离在多人协作场景下的效果 | 收集用户反馈 |

### 6.3 已知风险需裁决

| 风险 | 描述 | 待裁决选项 |
|------|------|------------|
| R-MIGRATE | 现有项目如何迁移 | A: 强制迁移 / B: 渐进迁移 / C: 新旧并存 |
| R-ESCAPE | 逃生舱口滥用风险 | A: 限制使用次数 / B: 需审批 / C: 仅记录 |

---

## 7. Decision Log（决策日志）

### 7.1 决策状态

**状态**: `Pending`（修订后重新提交裁决）

### 7.2 需要裁决的问题清单

| 问题 | 待裁决选项 | 裁决结果 | 裁决人 | 裁决时间 |
|------|------------|----------|--------|----------|
| Q1: 任务分级是否强制 | A: 强制 / B: 可选 | - | - | - |
| Q2: 角色隔离实现层 | A: Hook / B: Skill | - | - | - |
| Q3: 测试环境声明必填性 | A: 必填 / B: 按需 | - | - | - |
| Q4: 逃生舱口审批机制 | A: 需审批 / B: 仅记录 | - | - | - |
| Q5: 角色隔离 Skill 触发方式 | A: 自动 / B: 手动 | - | - | - |
| R-MIGRATE: 迁移策略 | A: 强制 / B: 渐进 / C: 并存 | - | - | - |
| R-ESCAPE: 逃生舱口风控 | A: 限次 / B: 审批 / C: 记录 | - | - | - |

### 7.3 裁决记录

#### 裁决 #1

- **日期**: 2026-01-11
- **裁决人**: Proposal Judge
- **裁决**: `Revise`
- **触发**: Challenger 质疑报告

**理由摘要**:

1. **B1 确认（阻断）**: 项目画像 `project-profile.md:83` 标注"项目级统一测试入口：TBD"，但提案 3.8 节要求 change-check.sh 单元测试为"必须"——测试基础设施不存在导致验收锚点无法验证。
2. **B2 确认（阻断）**: 提案 4.1 节 R2 承诺"提供迁移脚本 migrate-to-v2-gates.sh"，但 2.3 节新增文件清单未包含此脚本，风险缓解承诺与交付物不一致。
3. **B3 部分确认**: D1 新增完整 Skill（3 文件）但核心功能仅为"检测 Coder 是否修改 tests/"，而 `check_no_tests_changed()` 已存在于 change-check.sh，需 trade-off 分析。
4. **N4 确认**: AC 清单 10 条与成功标准（1.2 表格 4 项指标）无直接映射，缺乏追溯矩阵。

**必须修改项**:

| 编号 | 修改要求 | 落点 |
|------|----------|------|
| REV-1 | 新增 Phase 0：交付最小测试框架（Makefile + bats + shellcheck CI） | 附录 B + 2.1/2.3 |
| REV-2 | 将 `migrate-to-v2-gates.sh` 显式纳入交付清单，明确交付阶段 | 2.3 新增文件清单 + 附录 B |
| REV-3 | 对 D1 提供 trade-off 分析：新增 Skill vs 扩展 change-check.sh，若无强理由则降级 | 2.1 D1 + 新增分析节 |
| REV-4 | 补充 AC 与成功标准的追溯矩阵 | 5.1 验收标准 |

**验证要求**:

| 验证项 | 验证方式 | 预期证据 |
|--------|----------|----------|
| Phase 0 可行性 | `make test` 或 `bats tests/` 通过 | `evidence/phase0-baseline.log` |
| 迁移脚本存在 | 文件检查 | 路径确认 |
| D1 trade-off 完整 | 包含复杂度/维护成本/调用链三维度 | proposal.md 新增节 |
| 追溯矩阵完整 | 10 条 AC 各有明确指标映射 | 5.1 表格新增列 |

**非阻断建议（Author 可选采纳）**:

- N1: Phase 1 与 Phase 2 可并行执行，在附录 B 标注
- N2: Q3"按需必填"改为"必填但可写 N/A: `<reason>`"
- N3: D3 仪表板提升到 P1（与 Phase 2 交付）
- N4: 补充"假完成率 ~40%"的抽样方法与样本量

**下一步**: 请 Proposal Author 根据 REV-1 至 REV-4 修订提案后重新提交裁决。

---

## 附录

### A. 参考文档

- `DEVBOOKS-GAP-ANALYSIS-REPORT.md`：问题诊断报告
- `openspec/specs/_meta/project-profile.md`：项目画像
- `openspec/specs/_meta/glossary.md`：术语表

### B. 变更时间线建议 — REV-1/REV-2 更新

| 阶段 | 内容 | 产物 | 依赖 | 备注 |
|------|------|------|------|------|
| **Phase 0** | T0（最小测试框架） | Makefile + tests/bats/ + CI | 无 | **REV-1 新增** |
| **Phase 1** | M1 + W1 + R2 缓解 | change-check.sh 增强 + migrate-to-v2-gates.sh | Phase 0 | **可与 Phase 2 并行（N1）** |
| **Phase 2** | M2 + M3 + D3 | handoff-check.sh + 任务分级 + 仪表板 | Phase 0 | **可与 Phase 1 并行（N1）**；D3 提升到 P1（N3） |
| **Phase 3** | M4 + M5 + W2 + W3 | audit-scope.sh + env-match-check.sh + 阻塞项 + TODO | Phase 1 ∩ Phase 2 | - |
| **Phase 4** | D1 + D2 + W4 | check_role_boundaries() + prototype-promote.sh + 技术债务 | Phase 3 | D1 降级为函数扩展（REV-3） |

> **N1 采纳**：Phase 1 与 Phase 2 无强依赖，可并行执行以缩短周期。
> **N3 采纳**：D3 仪表板从 P2 提升到 P1，与 Phase 2 一同交付。

### C. REV 修订响应清单

| 编号 | 要求 | 落点 | 状态 |
|------|------|------|------|
| REV-1 | 新增 Phase 0：交付最小测试框架 | 2.1 T0 + 2.3 新增文件 + 附录 B | ✅ 完成 |
| REV-2 | 将 `migrate-to-v2-gates.sh` 纳入交付清单 | 2.3 第 9 项 + 附录 B Phase 1 | ✅ 完成 |
| REV-3 | D1 trade-off 分析 | 2.4 新增节 + 2.1 D1 更新 | ✅ 完成 |
| REV-4 | 补充 AC 与成功标准追溯矩阵 | 5.1 表格新增"关联 KPI"列 + KPI 覆盖统计 | ✅ 完成 |

---

**提案结束**

> **修订完成**：已根据 Decision Log 7.3 中 REV-1 至 REV-4 完成修订，请重新提交裁决。
