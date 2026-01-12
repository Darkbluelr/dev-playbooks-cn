# verification.md - evolve-devbooks-architecture

> 推荐路径：`openspec/changes/evolve-devbooks-architecture/verification.md`
>
> 目标：把"完成定义"落到可执行锚点与证据上，并提供 `AC-xxx -> Test IDs -> Evidence` 的追溯。

---

## 元信息

- Change ID：`evolve-devbooks-architecture`
- 状态：`Draft`
- 关联：
  - Proposal：`openspec/changes/evolve-devbooks-architecture/proposal.md`
  - Design：`openspec/changes/evolve-devbooks-architecture/design.md`
  - Tasks：`openspec/changes/evolve-devbooks-architecture/tasks.md`
  - Spec deltas：`openspec/changes/evolve-devbooks-architecture/specs/**`
- 维护者：`Test Owner`
- 更新时间：`2026-01-11`
- Test Owner（独立对话）：`当前会话`
- Coder（独立对话）：`待分配`
- Red 基线证据：`openspec/changes/evolve-devbooks-architecture/evidence/red-baseline/`

---

========================
A) 测试计划指令表
========================

### 主线计划区 (Main Plan Area)

#### TP1: 目录结构验证

- [ ] TP1.1 验证 dev-playbooks/ 集中式目录结构
  - Why：确保新目录结构符合设计规范，所有必要子目录和文件到位
  - Acceptance Criteria：AC-E01
  - Test Type：`unit`（文件系统检查）
  - Non-goals：不验证文件内容正确性
  - Candidate Anchors：`test_dir_structure.bats`

#### TP2: 宪法机制验证

- [ ] TP2.1 验证 constitution.md 存在且格式正确
  - Why：宪法是核心约束，必须存在并包含必要章节
  - Acceptance Criteria：AC-E02
  - Test Type：`unit`
  - Non-goals：不验证规则是否被实际执行
  - Candidate Anchors：`test_constitution.bats`

- [ ] TP2.2 验证 constitution-check.sh 功能
  - Why：宪法检查脚本必须能检测宪法缺失或格式错误
  - Acceptance Criteria：AC-E03
  - Test Type：`unit`
  - Non-goals：不验证与其他脚本集成
  - Candidate Anchors：`test_constitution_check.bats`

#### TP3: 架构适应度验证

- [ ] TP3.1 验证 fitness-check.sh 能检测分层违规
  - Why：架构适应度函数必须能检测常见架构违规
  - Acceptance Criteria：AC-E04
  - Test Type：`unit`
  - Non-goals：不覆盖所有可能的违规类型
  - Candidate Anchors：`test_fitness_check.bats`

#### TP4: AC 追溯验证

- [ ] TP4.1 验证 ac-trace-check.sh 能检测覆盖缺失
  - Why：追溯检查必须能识别未被测试覆盖的 AC
  - Acceptance Criteria：AC-E05
  - Test Type：`unit`
  - Non-goals：不验证复杂的追溯链
  - Candidate Anchors：`test_ac_trace.bats`

#### TP5: 三层同步验证

- [ ] TP5.1 验证 spec-preview.sh 冲突预检
  - Why：冲突预检是防止并行变更冲突的关键
  - Acceptance Criteria：AC-E06
  - Test Type：`unit`
  - Non-goals：不验证复杂冲突场景
  - Candidate Anchors：`test_spec_sync.bats`

- [ ] TP5.2 验证 spec-stage.sh 暂存同步
  - Why：暂存同步是三层模型的核心
  - Acceptance Criteria：AC-E06
  - Test Type：`unit`
  - Non-goals：不验证并发场景
  - Candidate Anchors：`test_spec_sync.bats`

- [ ] TP5.3 验证 spec-promote.sh 提升到真理层
  - Why：真理层提升必须在 stage 后才能执行
  - Acceptance Criteria：AC-E06
  - Test Type：`unit`
  - Non-goals：不验证回滚功能
  - Candidate Anchors：`test_spec_sync.bats`

- [ ] TP5.4 验证 spec-rollback.sh 回滚功能
  - Why：回滚是安全网，必须可用
  - Acceptance Criteria：AC-E06
  - Test Type：`unit`
  - Non-goals：不验证复杂回滚链
  - Candidate Anchors：`test_spec_sync.bats`

#### TP6: 迁移与兼容性验证

- [ ] TP6.1 验证 openspec/ 目录已删除（迁移后）
  - Why：确保旧目录不再存在
  - Acceptance Criteria：AC-E07
  - Test Type：`unit`
  - Non-goals：迁移前不检查
  - Candidate Anchors：`test_migration.bats`

- [ ] TP6.2 验证 migrate-to-devbooks-2.sh 迁移功能
  - Why：迁移脚本必须能正确迁移目录结构
  - Acceptance Criteria：AC-E08
  - Test Type：`integration`
  - Non-goals：不验证所有边界条件
  - Candidate Anchors：`test_migration.bats`

#### TP7: 反模式库验证

- [ ] TP7.1 验证反模式库包含至少 3 个反模式
  - Why：反模式库是知识库的基础
  - Acceptance Criteria：AC-E09
  - Test Type：`unit`
  - Non-goals：不验证反模式内容质量
  - Candidate Anchors：`test_anti_patterns.bats`

#### TP8: 回滚时间验证

- [ ] TP8.1 验证完整回滚可在 15 分钟内完成
  - Why：回滚时间是 SLA 承诺
  - Acceptance Criteria：AC-E10
  - Test Type：`integration`（需要实际执行）
  - Non-goals：不验证部分回滚
  - Candidate Anchors：`MANUAL-001`（需要手动计时）

### 临时计划区 (Temporary Plan Area)

- （留空）

### 断点区 (Context Switch Breakpoint Area)

- 上次进度：初始创建
- 当前阻塞：无
- 下一步最短路径：编写 BATS 测试文件

---

========================
B) 追溯矩阵（Traceability Matrix）
========================

| AC | 描述 | Test IDs / Commands | Evidence / MANUAL-* | Status | 因果链完整性 |
|---|---|---|---|---|---|
| AC-E01 | 目录结构符合设计 | `test_dir_structure.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E02 | 宪法被所有 Skills 加载 | `test_constitution.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E03 | change-check.sh 包含宪法检查 | `test_constitution_check.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E04 | fitness-check.sh 能检测架构违规 | `test_fitness_check.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E05 | ac-trace-check.sh 能检测 AC 覆盖缺失 | `test_ac_trace.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E06 | 三层同步脚本工作正常 | `test_spec_sync.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E07 | openspec/ 目录已删除 | `test_migration.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E08 | 迁移脚本可正常工作 | `test_migration.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E09 | 反模式库至少包含 3 个反模式 | `test_anti_patterns.bats` | evidence/red-baseline/ | TODO | [ ] 完整 |
| AC-E10 | 回滚可在 15 分钟内完成 | `MANUAL-001` | evidence/rollback-drill.log | TODO | [ ] 完整 |

### 追溯矩阵完整性检查清单

- [x] **无孤儿 AC**：每个 AC 都有对应的 Test IDs 或 MANUAL-* 条目
- [x] **无孤儿测试**：每个 Test ID 都能追溯到 AC
- [ ] **无无证据 DONE**：每个 Status=DONE 的条目都有 Evidence 链接
- [ ] **Red 基线存在**：`evidence/` 目录包含初始失败证据（证明测试有效）
- [ ] **Green 证据存在**：`evidence/` 目录包含最终通过证据

---

========================
C) 执行锚点（Deterministic Anchors）
========================

### 1) 行为（Behavior）

- unit：BATS 测试文件
  - `tests/evolve-devbooks-architecture/test_dir_structure.bats`
  - `tests/evolve-devbooks-architecture/test_constitution.bats`
  - `tests/evolve-devbooks-architecture/test_constitution_check.bats`
  - `tests/evolve-devbooks-architecture/test_fitness_check.bats`
  - `tests/evolve-devbooks-architecture/test_ac_trace.bats`
  - `tests/evolve-devbooks-architecture/test_spec_sync.bats`
  - `tests/evolve-devbooks-architecture/test_anti_patterns.bats`

- integration：
  - `tests/evolve-devbooks-architecture/test_migration.bats`

- e2e：无（本次变更为工具链/脚本变更，无 E2E）

### 2) 契约（Contract）

- 配置协议契约：
  - `tests/evolve-devbooks-architecture/test_config_contract.bats`
  - 验证新旧配置格式兼容性

### 3) 结构（Structure / Fitness Functions）

- 分层/依赖方向：由 fitness-check.sh 自身验证
- 测试中包含对 fitness-check.sh 输出格式的契约测试

### 4) 静态与安全（Static/Security）

- lint/typecheck：bash -n 语法检查
- shellcheck：建议但非强制
- 报告格式：text（BATS 默认）
- 质量闸门：脚本退出码契约（0=成功, 1=检查失败, 2=用法错误）

---

========================
D) MANUAL-* 清单（人工/混合验收）
========================

- [ ] MANUAL-001 回滚时间验证
  - Pass/Fail 判据：完整回滚（RB-05）耗时 < 15 分钟
  - Evidence（截图/录像/链接/日志）：`evidence/rollback-drill.log`
  - 责任人/签字：待分配

- [ ] MANUAL-002 断点策略验证（BP-1/BP-2/BP-3）
  - Pass/Fail 判据：各断点触发时能按设计文档 §12 的处置策略执行
  - Evidence：`evidence/breakpoint-drill.log`
  - 责任人/签字：待分配

---

========================
E) 风险与降级（可选）
========================

- 风险：脚本依赖的外部工具（grep/sed/awk）版本差异可能导致行为不一致
- 降级策略：在测试中使用 POSIX 兼容语法
- 回滚策略：git revert + rollback-to-openspec.sh

========================
F) 结构质量守门记录（可选）
========================

- 冲突点：无
- 评估影响：本次变更为工具链变更，不影响业务代码内聚性
- 替代闸门：脚本退出码契约 + BATS 测试
- 决策与授权：遵循现有测试框架

========================
G) 测试分层策略
========================

## 测试分层策略

| 类型 | 数量 | 覆盖场景 | 预期执行时间 |
|------|------|----------|--------------|
| 单元测试 | 30+ | AC-E01 ~ AC-E06, AC-E09 | < 30s |
| 集成测试 | 5 | AC-E07, AC-E08 | < 60s |
| 手动测试 | 1 | AC-E10 | < 15min |

## 测试环境要求

| 测试类型 | 运行环境 | 依赖 |
|----------|----------|------|
| 单元测试 | bash + bats | 无外部依赖 |
| 集成测试 | bash + bats + 临时目录 | 需要写权限 |
| 手动测试 | 完整项目环境 | git |

## 运行命令

```bash
# 运行所有测试（Red 基线）
bats tests/evolve-devbooks-architecture/*.bats

# 运行单个测试文件
bats tests/evolve-devbooks-architecture/test_dir_structure.bats

# 运行并输出 TAP 格式（用于 CI）
bats --tap tests/evolve-devbooks-architecture/*.bats
```

========================
H) 审计与证据管理
========================

### 证据目录结构

```
openspec/changes/evolve-devbooks-architecture/evidence/
├── red-baseline/           # Red 基线证据（必须）
│   └── test-failures-2026-01-11.log
├── green-final/            # Green 最终证据（Coder 完成后）
│   └── test-results-YYYY-MM-DD.log
└── rollback-drill.log      # 回滚演练证据（MANUAL-001）
```

### 审计完整性检查清单

- [ ] **Red 基线存在**：`evidence/red-baseline/` 有失败日志
- [ ] **Green 证据存在**：`evidence/green-final/` 有通过日志
- [ ] **时间戳可追溯**：证据文件名包含时间戳
- [ ] **人工验收有签核**：MANUAL-001 有责任人签字
