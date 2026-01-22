# Implementation Plan: harden-devbooks-quality-gates

---
version: 1.0
status: Complete
maintainer: Planner
input_materials:
  - openspec/changes/harden-devbooks-quality-gates/design.md
  - openspec/changes/harden-devbooks-quality-gates/proposal.md
  - openspec/changes/harden-devbooks-quality-gates/specs/quality-gates/spec.md
  - openspec/changes/harden-devbooks-quality-gates/specs/role-handoff/spec.md
  - openspec/changes/harden-devbooks-quality-gates/specs/audit-tools/spec.md
last_verified: 2026-01-11
freshness_check: 1 Month
---

## Mode Selection

**Active Mode**: `Main Plan Mode`

---

## Main Plan Area

### Phase 0: Test Infrastructure Bootstrap (T0)

> **前置依赖**: 无
> **验收锚点**: AC-012

- [x] [P0] MP0.1 Create Makefile with test/lint targets
- [x] [P0] MP0.2 Create BATS test infrastructure
- [x] [P0] MP0.3 Create CI workflow configuration

---

### Phase 1: Core Quality Gates (M1 + W1)

> **前置依赖**: Phase 0
> **验收锚点**: AC-001, AC-002

- [x] [P0] MP1.1 Implement check_evidence_closure() function | Trace: AC-001
- [x] [P0] MP1.2 Implement check_task_completion_rate() function | Trace: AC-002
- [x] [P0] MP1.3 Implement check_test_failure_in_evidence() function | Trace: AC-007
- [x] [P0] MP1.4 Create migrate-to-v2-gates.sh | Trace: AC-009, AC-008
- [x] [P0] MP1.5 Add BATS tests for Phase 1 functions

---

### Phase 2: Role Handoff & Dashboard (M2 + M3 + D3)

> **前置依赖**: Phase 0
> **验收锚点**: AC-004, AC-005, AC-010
> **Note**: Can run in parallel with Phase 1 (N1 approved)

- [x] [P0] MP2.1 Create handoff-check.sh script | Trace: AC-004
- [x] [P0] MP2.2 Create handoff.md template
- [x] [P0] MP2.3 Implement check_skip_approval() function | Trace: AC-005
- [x] [P0] MP2.4 Create progress-dashboard.sh script | Trace: AC-010
- [x] [P0] MP2.5 Add BATS tests for Phase 2

---

### Phase 3: Audit & Environment Tools (M4 + M5 + W2 + W3)

> **前置依赖**: Phase 1 ∩ Phase 2
> **验收锚点**: AC-006, AC-011

- [x] [P0] MP3.1 Create env-match-check.sh script | Trace: AC-006
- [x] [P0] MP3.2 Create audit-scope.sh script | Trace: AC-011
- [x] [P0] MP3.3 Integrate env-match-check into change-check.sh
- [x] [P0] MP3.4 Add BATS tests for Phase 3

---

### Phase 4: Role Boundaries & Prototype Enhance (D1 + D2 + W4)

> **前置依赖**: Phase 3
> **验收锚点**: AC-003

- [x] [P0] MP4.1 Enhance check_role_boundaries() function | Trace: AC-003
- [x] [P1] MP4.2 Enhance prototype-promote.sh with quality gates
- [x] [P2] MP4.3 Add technical debt section to design.md template
- [x] [P0] MP4.4 Add BATS tests for Phase 4

---

## Temporary Plan Area

_Reserved for unplanned high-priority tasks. Currently empty._

**Template**:
```markdown
### TP-xxx: [Task Name]
- **Trigger**: [What caused this to be added]
- **Impact**: [Scope of impact]
- **Minimal Fix**: [Smallest change to resolve]
- **Regression Test**: [What to verify after fix]
```

---

## Plan Detail Area

### Scope & Non-goals

**In Scope**:
- change-check.sh function enhancements (4 new check functions)
- 5 new scripts: handoff-check.sh, env-match-check.sh, audit-scope.sh, progress-dashboard.sh, migrate-to-v2-gates.sh
- 1 new template: handoff.md
- Test infrastructure: Makefile, BATS tests, CI workflow

**Non-goals** (per design.md):
- Modifying existing Skills' core logic (only gate enhancements)
- Adding business features
- Refactoring existing directory structure
- MCP Server changes

### Architecture Delta

**New Components**:

| Component | Location | Responsibility |
|-----------|----------|----------------|
| handoff-check.sh | scripts/ | Role handoff verification |
| env-match-check.sh | scripts/ | Test environment declaration check |
| audit-scope.sh | scripts/ | Full-scope audit scanning |
| progress-dashboard.sh | scripts/ | Progress visualization |
| migrate-to-v2-gates.sh | scripts/ | v2 gate migration helper |
| tests/bats/ | project root | BATS test infrastructure |

**Modified Components**:

| Component | Changes |
|-----------|---------|
| change-check.sh | +4 functions: check_evidence_closure, check_task_completion_rate, check_test_failure_in_evidence, check_skip_approval, check_role_boundaries |
| prototype-promote.sh | +quality gate checks |

**Dependency Direction**:
```
devbooks-router (caller)
       │
       ▼
change-check.sh (enhanced)
       │
       ├──► handoff-check.sh (optional call)
       └──► env-match-check.sh (optional call)

audit-scope.sh ──(independent)
progress-dashboard.sh ──(independent)
```

**Forbidden Dependencies** (per design FT-001):
- audit-scope.sh → change-check.sh
- progress-dashboard.sh → change-check.sh

### Data Contracts

**Exit Code Contract** (unchanged):

| Exit Code | Meaning |
|-----------|---------|
| 0 | All checks passed |
| 1 | Check failed |
| 2 | Usage error |

**tasks.md Priority Format** (new):
```
[x] [P0] Critical task       ← 完成
[ ] [P1] Important task      ← 未完成示例
[ ] [P2] Nice-to-have task   ← 未完成示例
[ ] Task without tag         ← 视为 P2
```

**Skip Approval Format** (new):
```
[ ] [P0] Skipped task        ← 需审批
<!-- SKIP-APPROVED: <reason> -->
```

**handoff.md Required Sections**:
- "交接信息" (handoff metadata)
- "交接内容" (handoff content)
- "确认签名" (confirmation signatures with `[x]` checkboxes)

**verification.md Required Section** (archive mode):
- "测试环境声明" section (can contain "N/A")

### Milestones

| Phase | Content | Validation Anchor | Parallel? |
|-------|---------|-------------------|-----------|
| Phase 0 | Test infrastructure | AC-012 | - |
| Phase 1 | M1 + W1 + migrate script | AC-001, AC-002, AC-007 | Can parallel with Phase 2 |
| Phase 2 | M2 + M3 + D3 | AC-004, AC-005, AC-010 | Can parallel with Phase 1 |
| Phase 3 | M4 + M5 | AC-006, AC-011 | Sequential |
| Phase 4 | D1 + D2 + W4 | AC-003 | Sequential |

### Work Breakdown

**PR Split Suggestions**:

| PR | Tasks | Parallel? |
|----|-------|-----------|
| PR-0: Test Infra | MP0.1, MP0.2, MP0.3 | - |
| PR-1a: Evidence Gates | MP1.1, MP1.3, MP1.5 (partial) | Yes with PR-1b |
| PR-1b: Task Gates | MP1.2, MP1.4, MP1.5 (partial) | Yes with PR-1a |
| PR-2a: Handoff | MP2.1, MP2.2, MP2.5 (partial) | Yes with PR-1, PR-2b |
| PR-2b: P0 + Dashboard | MP2.3, MP2.4, MP2.5 (partial) | Yes with PR-1, PR-2a |
| PR-3: Env + Audit | MP3.1, MP3.2, MP3.3, MP3.4 | After PR-1, PR-2 |
| PR-4: Role Boundaries | MP4.1, MP4.2, MP4.3, MP4.4 | After PR-3 |

### Deprecation & Cleanup

No deprecations in this change. Backward compatibility maintained.

### Dependency Policy

- BATS: >= 1.5.0 (bats-core)
- shellcheck: >= 0.8.0
- POSIX compatibility required for all scripts

### Quality Gates

| Gate | Command | Required |
|------|---------|----------|
| Static Analysis | `shellcheck scripts/*.sh` | Yes (AC-008) |
| Unit Tests | `make test` | Yes (AC-012) |
| Help Docs | `for s in scripts/*.sh; do $s --help; done` | Yes (AC-009) |

### Guardrail Conflicts

**No conflicts identified**. This change enhances gates without introducing proxy metrics.

### Observability

| Metric | Observation Method | KPI Reference |
|--------|-------------------|---------------|
| False completion rate | change-check.sh --mode archive failure rate | KPI-1 (target < 5%) |
| Role handoff rate | handoff.md existence with confirmation | KPI-2 (target 0%) |
| P0 skip unapproved rate | tasks.md scan for unapproved P0 skips | KPI-3 (target 0%) |
| Audit underestimate | audit-scope.sh vs manual sampling | KPI-4 (target < 1.5x) |

### Rollout & Rollback

**Rollout Strategy**:
1. Phase 0: Internal testing with sample change packages
2. Phase 1-2: Gradual rollout with `--skip-check` escape hatch
3. Phase 3-4: Full enforcement after migration script provided

**Rollback**:
- Single script: `git checkout HEAD~1 -- scripts/<script>.sh`
- Full rollback: `git revert <commit-range>`
- Config layer: Comment out new config in `.devbooks/config.yaml`

### Risks & Edge Cases

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| New gates too strict | Medium | Medium | `--skip-check <item>` escape hatch |
| Migration cost for existing packages | High | Medium | migrate-to-v2-gates.sh script |
| BATS not installed | Low | Low | Makefile checks and installs |
| shellcheck version differences | Low | Low | Document minimum version |

**Edge Cases**:
- Empty tasks.md: Treated as 100% complete
- No priority tags: Treated as P2 (backward compatible)
- Multiple Green evidence files: Any file with FAIL pattern fails check

### Open Questions (<=3)

1. **Q1**: How many existing change packages fail new gates?
   - Validation: Run `change-check.sh --mode strict` on `openspec/changes/archive/`
   - Status: To be verified before Phase 3

2. **Q2**: Should `--skip-check` require Judge approval?
   - Design says "建议需审批", proposal Q4 pending decision
   - Default behavior: Log to skip-log.md, no enforcement

3. **Q3**: Minimum BATS version for cross-platform compatibility?
   - Current assumption: bats-core >= 1.5.0
   - Validation: Test on macOS 14 and Ubuntu 22.04

---

## Context Switch Breakpoint Area

**Last Active Task**: MP4.4 (All tasks completed)

**Checkpoint State**:
- [x] Phase 0 complete
- [x] Phase 1 complete
- [x] Phase 2 complete
- [x] Phase 3 complete
- [x] Phase 4 complete

**Context Notes**:
_Reserved for recording context when switching between main and temporary plans._

---

## Appendix: AC to Task Traceability Matrix

| AC ID | Task(s) | Test File |
|-------|---------|-----------|
| AC-001 | MP1.1, MP1.5 | change-check.bats |
| AC-002 | MP1.2, MP1.5 | change-check.bats |
| AC-003 | MP4.1, MP4.4 | change-check.bats |
| AC-004 | MP2.1, MP2.5 | handoff-check.bats |
| AC-005 | MP2.3, MP2.5 | change-check.bats |
| AC-006 | MP3.1, MP3.3, MP3.4 | env-match-check.bats |
| AC-007 | MP1.3, MP1.5 | change-check.bats |
| AC-008 | MP0.1 (lint target) | CI workflow |
| AC-009 | MP0.1, all new scripts | help-check target |
| AC-010 | MP2.4, MP2.5 | manual/bats |
| AC-011 | MP3.2, MP3.4 | manual sampling |
| AC-012 | MP0.1, MP0.2, MP0.3 | CI workflow |
