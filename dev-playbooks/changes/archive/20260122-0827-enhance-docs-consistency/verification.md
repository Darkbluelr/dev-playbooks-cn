# verification.md (20260122-0827-enhance-docs-consistency)

> Recommended path: `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/verification.md`
>
> Goal: Anchor "Definition of Done" to executable anchors and evidence, and provide `AC-xxx -> Requirement/Scenario -> Test IDs -> Evidence` traceability.

---

## Metadata

- Change ID: `20260122-0827-enhance-docs-consistency`
- Status: Archived
  > Status lifecycle: Draft → Ready → Done → Archived
  > - Draft: Initial state
  > - Ready: Test plan ready (set by Test Owner)
  > - Done: All tests passed + Review approved (set by **Reviewer only**)
  > - Archived: Archived (set by Spec Gardener)
  > **Constraint: Coder is prohibited from modifying Status field**
- Archived-At: 2026-01-23T06:35:00Z
- Archived-By: devbooks-archiver
- References:
  - Proposal: `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/proposal.md`
  - Design: `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/design.md`
  - Tasks: `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/tasks.md`
  - Spec deltas:
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/docs-consistency-core/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/completeness-check/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/doc-classification/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/shared-methodology/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/skills-integration/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/style-cleanup/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/expert-roles/spec.md`
    - `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/specs/style-persistence/spec.md`
- Maintainer: Test Owner
- Last Updated: 2026-01-22
- Test Owner (independent session): codex-cli/test-owner
- Coder (independent session): <pending>
- Red baseline evidence: `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/evidence/red-baseline/`

---

## Test Environment Declaration

- Runtime: macOS 26.2.0 (aarch64)
- Shell: zsh
- Node.js: 18+ (assumed per project profile; not exercised here)
- Python: 3.x (via python3)
- BATS: installed
- Git: available
- Notes: 无需外部服务；仅本地文件与 git 状态

---

## Decision and Authorization

- Reviewer Authorization: Done（由 Reviewer 在评审通过后填写）

========================
A) Test Plan Directive Table
========================

### Main Plan Area

- [x] TP1.1 技能改名与别名机制验收
  - Why: 确保 `devbooks-docs-sync` 改名为 `devbooks-docs-consistency` 且向后兼容
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-001; REQ-CORE-001; SC-CORE-001
  - Test Type: static
  - Non-goals: 不验证具体功能实现细节; 不验证弃用期 6 个月策略
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC001-rename-alias.bats

- [x] TP1.2 规则引擎与一次性规则参数支持
  - Why: 确保持续规则与 `--once` 一次性任务可被解析并执行
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-002; REQ-CORE-002; SC-CORE-002/003/006/007
  - Test Type: unit
  - Non-goals: 不验证规则引擎性能; 不覆盖所有规则类型组合
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC002-rules-engine.bats

- [x] TP1.3 增量扫描与性能指标验证
  - Why: 确保增量扫描仅处理变更文件且性能/Token 预算符合要求
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-003; AC-012; REQ-CORE-003; SC-CORE-004/005
  - Test Type: integration
  - Non-goals: 不验证真实 token 计费; 不进行全量性能基准
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC003-scan-benchmark.bats; evidence/token-usage.log; evidence/scan-performance.log

- [x] TP1.4 完备性检查维度覆盖与报告生成
  - Why: 确保五个维度都有规则且报告落盘
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-004; REQ-COMP-001; SC-COMP-001~008
  - Test Type: unit
  - Non-goals: 不验证所有文档内容完整性; 不阻塞归档流程
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC004-completeness-report.bats; evidence/completeness-report.md

- [x] TP1.5 文档分类规则与可配置性
  - Why: 确保活体/历史/概念性文档分类可配置
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-005; REQ-CLASS-001/002; SC-CLASS-001~005
  - Test Type: unit
  - Non-goals: 不验证所有自定义路径模式
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC005-doc-classification.bats

- [x] TP1.6 共享方法论文档与引用数量验证
  - Why: 确保共享方法论文档存在且被多处引用
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-006; REQ-METH-001/002; SC-METH-001~005
  - Test Type: static
  - Non-goals: 不对内容一致性做全文 diff
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC006-shared-methodology.bats

- [x] TP1.7 Skills 集成点校验
  - Why: 确保 archiver、brownfield-bootstrap、proposal-author 与 docs-consistency 集成
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-007; REQ-INTEG-001~003; SC-INTEG-001~006
  - Test Type: static
  - Non-goals: 不执行归档流程; 不验证 bootstrap 产出内容逻辑
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC007-skills-integration.bats

- [x] TP1.8 浮夸词语清理与 MCP 增强删除
  - Why: 确保文档风格清理与 MCP 增强章节移除
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-008; AC-009; REQ-STYLE-001/002; SC-STYLE-001~008
  - Test Type: static
  - Non-goals: 不验证报告内容质量; 不改写业务描述
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC008-fancy-words.bats; TEST-AC009-no-mcp-enhancement.bats; evidence/fancy-words-removal.md

- [x] TP1.9 专家角色声明机制
  - Why: 确保 skill 元信息包含 `recommended_experts` 且专家列表与协议存在
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-010; REQ-EXPERT-001~003; SC-EXPERT-001~007
  - Test Type: static
  - Non-goals: 不验证角色内容合理性
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC010-expert-roles.bats

- [x] TP1.10 文档风格偏好持久化
  - Why: 确保 `docs-maintenance.md` 持久化并包含 style_preferences
  - Acceptance Criteria (reference AC-xxx / Requirement): AC-011; REQ-PERSIST-001/002; SC-PERSIST-001~004
  - Test Type: static
  - Non-goals: 不验证优先级运行时逻辑
  - Candidate Anchors (Test IDs / commands / evidence): TEST-AC011-style-persistence.bats

### Temporary Plan Area

- (none)

### Context Switch Breakpoint Area

- Last progress: tests/20260122-0827-enhance-docs-consistency 全量通过
- Current blocker: none
- Next shortest path: Reviewer 审查完成后进入归档

---

========================
B) Traceability Matrix
========================

| AC | Requirement/Scenario | Test IDs / Commands | Evidence / MANUAL-* | Status |
|---|---|---|---|---|
| AC-001 | REQ-CORE-001; SC-CORE-001 | TEST-AC001-rename-alias.bats | command: `test -d skills/devbooks-docs-consistency && ls -la skills/ | grep docs-sync` | Done |
| AC-002 | REQ-CORE-002; SC-CORE-002/003/006/007 | TEST-AC002-rules-engine.bats | unit: `bats tests/20260122-0827-enhance-docs-consistency/test_rules_engine.bats` | Done |
| AC-003 | REQ-CORE-003; SC-CORE-004/005 | TEST-AC003-scan-benchmark.bats | evidence/token-usage.log | Done |
| AC-004 | REQ-COMP-001; SC-COMP-001~008 | TEST-AC004-completeness-report.bats | evidence/completeness-report.md | Done |
| AC-005 | REQ-CLASS-001/002; SC-CLASS-001~005 | TEST-AC005-doc-classification.bats | unit: `bats tests/20260122-0827-enhance-docs-consistency/test_doc_classification.bats` | Done |
| AC-006 | REQ-METH-001/002; SC-METH-001~005 | TEST-AC006-shared-methodology.bats | command: `test -f skills/_shared/references/完备性思维框架.md` | Done |
| AC-007 | REQ-INTEG-001~003; SC-INTEG-001~006 | TEST-AC007-skills-integration.bats | command: `grep -q "devbooks-docs-consistency" skills/devbooks-archiver/skill.md` | Done |
| AC-008 | REQ-STYLE-001; SC-STYLE-001~003/008 | TEST-AC008-fancy-words.bats | evidence/fancy-words-removal.md | Done |
| AC-009 | REQ-STYLE-002; SC-STYLE-004~007 | TEST-AC009-no-mcp-enhancement.bats | command: `! grep -r "MCP 增强" skills/*/skill.md` | Done |
| AC-010 | REQ-EXPERT-001~003; SC-EXPERT-001~007 | TEST-AC010-expert-roles.bats | command: `grep -q "recommended_experts" skills/devbooks-proposal-author/skill.md` | Done |
| AC-011 | REQ-PERSIST-001/002; SC-PERSIST-001~004 | TEST-AC011-style-persistence.bats | command: `test -f dev-playbooks/specs/_meta/docs-maintenance.md` | Done |
| AC-012 | REQ-CORE-003; SC-CORE-004 | TEST-AC003-scan-benchmark.bats | evidence/scan-performance.log | Done |

---

========================
C) Execution Anchors (Deterministic Anchors)
========================

### 1) Behavior

- unit:
  - `bats tests/20260122-0827-enhance-docs-consistency/test_rules_engine.bats`
  - `bats tests/20260122-0827-enhance-docs-consistency/test_doc_classification.bats`
  - `bats tests/20260122-0827-enhance-docs-consistency/test_completeness_report.bats`
- integration:
  - `bats tests/20260122-0827-enhance-docs-consistency/test_scan_benchmark.bats`
- e2e:
  - none

### 2) Contract

- OpenAPI/Proto/Schema: none
- contract tests: none

### 3) Structure (Fitness Functions)

- Layering/dependency direction/no cycles: none

### 4) Static and Security

- lint/typecheck/build: none
- SAST/secret scan: none
- Report format: none

---

========================
D) MANUAL-* Checklist (Manual/Hybrid Acceptance)
========================

- [x] MANUAL-001 证明 token 消耗与扫描时长报告生成
  - Pass/Fail criteria: evidence/token-usage.log 与 evidence/scan-performance.log 存在且包含最新执行记录
  - Evidence (screenshot/video/link/log): `dev-playbooks/changes/20260122-0827-enhance-docs-consistency/evidence/token-usage.log`, `dev-playbooks/changes/20260122-0827-enhance-docs-consistency/evidence/scan-performance.log`
  - Responsible/Sign-off: Test Owner

---

========================
E) Risks and Degradation (optional)
========================

- Risks:
  - 增量扫描需要 git diff 支持,无 git 环境时只能走回退路径
  - 规则引擎测试依赖规则样例文件格式稳定
- Degradation strategy:
  - 增量扫描失败回退到全量扫描
  - 规则解析失败仅告警并继续其他规则
- Rollback strategy:
  - 回退到旧技能 `devbooks-docs-sync` 目录结构

========================
F) Structural Quality Gate Record
========================

- Decision and Authorization: Done

- Conflict points: none
- Impact assessment (cohesion/coupling/testability): docs-consistency 属于脚本型工具,新增测试不会改变耦合
- Alternative gates (complexity/coupling/dependency direction/test quality): none
- Decision and authorization: none

========================
G) Value Stream and Metrics (optional, but must explicitly fill "none")
========================

- Target Value Signal: none
- Delivery and stability metrics (optional DORA): none
- Observation window and trigger points: none
- Evidence: none
