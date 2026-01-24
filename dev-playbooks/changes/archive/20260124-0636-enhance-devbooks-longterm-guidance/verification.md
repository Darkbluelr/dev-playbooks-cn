# 验证计划：20260124-0636-enhance-devbooks-longterm-guidance

========================
A) 测试计划指令表
========================

### 主线计划区 (Main Plan Area)

- [x] TP1.1 保障文档定位一致与三段式规则可扫描
  - Why：确保对外叙述一致且可被静态检查覆盖
  - Acceptance Criteria：AC-101，AC-106
  - Test Type：static
  - Non-goals：不验证脚本运行时行为
  - Candidate Anchors：TEST-AC101-01，TEST-AC106-01，`bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats`

- [x] TP1.2 统一 SKILL 渐进披露模板与 MCP 能力表述
  - Why：确保技能说明可扫描、可对齐
  - Acceptance Criteria：AC-104，AC-105
  - Test Type：static
  - Non-goals：不验证 MCP 实际可用性
  - Candidate Anchors：TEST-AC104-01，TEST-AC105-01，TEST-AC105-02，TEST-AC105-03，TEST-AC105-04

- [x] TP1.3 验证共享方法论与术语表的新增机制
  - Why：确保长期视野与人类建议校准机制落盘
  - Acceptance Criteria：AC-102，AC-103，AC-106
  - Test Type：static
  - Non-goals：不评估内容质量，仅检查要素存在
  - Candidate Anchors：TEST-AC102-01，TEST-AC103-01，TEST-AC103-02，TEST-AC106-02

### 临时计划区 (Temporary Plan Area)

- 无

### 断点区 (Context Switch Breakpoint Area)

- 上次进度：新增 BATS 测试并建立 Red 基线
- 当前阻塞：无
- 下一步最短路径：交由 Coder 实现文档与规格改动

---

## 元信息

- Change ID：`20260124-0636-enhance-devbooks-longterm-guidance`
- Status: Archived
  - 状态流转：Draft → Ready → Implementation Done → Verified → Done → Archived
  - 约束：Coder 禁止修改 Status 字段
- 关联：
  - Proposal：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md`
  - Design：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md`
  - Tasks：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md`
  - Spec deltas：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/**`
- 维护者：Test Owner
- 更新时间：2026-01-24
- Test Owner（独立对话）：Codex Test Owner
- Coder（独立对话）：未指定
- Red 基线证据：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/red-baseline/test-20260124-084406.log`

---

## 测试策略

### 测试类型分布

| 测试类型 | 数量 | 用途 | 预期耗时 |
|---|---:|---|---|
| 静态/文档检查 | 11 | 文档、规格、术语与技能一致性 | < 10s |

### 测试环境

| 测试类型 | 环境 | 依赖 |
|---|---|---|
| 静态/文档检查 | 本地仓库 | bash, rg, bats |

## 测试分层策略

| 类型 | 数量 | 覆盖场景 | 预期执行时间 |
|---|---:|---|---|
| 静态 | 11 | AC-101 ~ AC-106 | < 10s |

---

## AC 覆盖矩阵

| AC-ID | 描述 | 测试类型 | Test ID | 优先级 | 状态 |
|---|---|---|---|---|---|
| AC-101 | 文档定位一致 | 静态 | TEST-AC101-01 | P0 | [x] |
| AC-102 | 长期视野/反短视机制 | 静态 | TEST-AC102-01 | P0 | [x] |
| AC-103 | 人类建议校准机制与术语 | 静态 | TEST-AC103-01，TEST-AC103-02 | P0 | [x] |
| AC-104 | 渐进披露模板一致 | 静态 | TEST-AC104-01 | P0 | [x] |
| AC-105 | MCP 能力类型与规格对齐 | 静态 | TEST-AC105-01，TEST-AC105-02，TEST-AC105-03，TEST-AC105-04 | P0 | [x] |
| AC-106 | 三段式规则 | 静态 | TEST-AC106-01，TEST-AC106-02 | P0 | [x] |

---

========================
B) 追溯矩阵（Traceability Matrix）
========================

| AC | Requirement/Scenario | Test IDs / Commands | Evidence / MANUAL-* | 状态 | 因果链完整性 |
|---|---|---|---|---|---|
| AC-101 | 文档定位一致（README + 使用指南 + Skill 详解） | TEST-AC101-01 / `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats` | `evidence/green-final/bats-2026-01-24-165458.log`；`evidence/red-baseline/test-20260124-084406.log` | 已验证 | [x] 完整 |
| AC-102 | REQ-METH-003 长期视野/反短视机制 | TEST-AC102-01 / `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats` | `evidence/green-final/bats-2026-01-24-165458.log`；`evidence/red-baseline/test-20260124-084406.log` | 已验证 | [x] 完整 |
| AC-103 | REQ-METH-004 人类建议校准 + 术语表 | TEST-AC103-01，TEST-AC103-02 / `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats` | `evidence/green-final/bats-2026-01-24-165458.log`；`evidence/red-baseline/test-20260124-084406.log` | 已验证 | [x] 完整 |
| AC-104 | Skills 渐进披露模板规则 | TEST-AC104-01 / `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats` | `evidence/green-final/bats-2026-01-24-165458.log`；`evidence/red-baseline/test-20260124-084406.log` | 已验证 | [x] 完整 |
| AC-105 | REQ-MCP-005/REQ-STYLE-002 对齐 + Skills MCP 能力类型 | TEST-AC105-01，TEST-AC105-02，TEST-AC105-03，TEST-AC105-04 / `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats` | `evidence/green-final/bats-2026-01-24-165458.log`；`evidence/red-baseline/test-20260124-084406.log` | 已验证 | [x] 完整 |
| AC-106 | REQ-METH-005 三段式规则 + 文档三段式 | TEST-AC106-01，TEST-AC106-02 / `bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats` | `evidence/green-final/bats-2026-01-24-165458.log`；`evidence/red-baseline/test-20260124-084406.log` | 已验证 | [x] 完整 |

---

========================
C) 执行锚点（Deterministic Anchors）
========================

### 验证命令清单

```bash
# 运行全部验收测试（推荐）
bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats

# 文档定位与三段式规则核查（可选）
rg -n "非 MCP 工具|不是 MCP 工具|MCP.*可选.*集成点|可选.*MCP.*集成点" README.md docs/使用指南.md docs/Skill详解.md
rg -n "^约束：|^取舍：|^影响：" README.md docs/使用指南.md docs/Skill详解.md

# SKILL.md MCP 能力类型核查（可选）
rg -n "推荐 MCP 能力类型" skills/**/SKILL.md
rg -n "MCP 增强|依赖的 MCP 服务|增强模式 vs 基础模式" skills/**/SKILL.md
```

---

========================
D) MANUAL-* 清单（人工/混合验收）
========================

- 无（本次无人工验收项）

---

========================
E) 风险与降级（可选）
========================

- 风险：无
- 降级策略：无
- 回滚策略：无

========================
F) 结构质量守门记录
========================

- 冲突点：无
- 评估影响（内聚/耦合/可测试性）：无
- 替代闸门（复杂度/耦合/依赖方向/测试质量）：无
- 决策与授权：无

========================
G) 价值流与度量
========================

- 目标价值信号：无
- 价值流瓶颈假设：无
- 交付与稳定性指标：无
- 观测窗口与触发点：无
- Evidence：无
