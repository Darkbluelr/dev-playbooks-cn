# verification.md Template (Within Change Package)

> Recommended path: `<change-root>/<change-id>/verification.md`
>
> Goal: Anchor the "Definition of Done" to executable anchors and evidence, and provide traceability from `AC-xxx -> Requirement/Scenario -> Test IDs -> Evidence`.

---

## Metadata

- Change ID: `<change-id>`
- Status: `Draft | Ready | Done | Archived`
- Related:
  - Proposal: `<change-root>/<change-id>/proposal.md`
  - Design: `<change-root>/<change-id>/design.md`
  - Tasks: `<change-root>/<change-id>/tasks.md`
  - Spec deltas: `<change-root>/<change-id>/specs/**`
- Maintainer: `<you>`
- Updated: `YYYY-MM-DD`
- Test Owner (independent session): `<session/agent>`
- Coder (independent session): `<session/agent>`
- Red baseline evidence: `<change-root>/<change-id>/evidence/`

---

========================
A) Test Plan Instruction Table
========================

### Main Plan Area

- [ ] TP1.1 `<one-line goal>`
  - Why:
  - Acceptance Criteria (reference AC-xxx / Requirement):
  - Test Type: `unit | contract | integration | e2e | fitness | static`
  - Non-goals:
  - Candidate Anchors (Test IDs / commands / evidence):

### Temporary Plan Area

- (Leave empty / as needed)

### Context Switch Breakpoint Area

- Last progress:
- Current blockers:
- Next shortest path:

---

========================
B) Traceability Matrix
========================

> Recommended to use AC-xxx as primary key; if you maintain Requirements/Scenarios spec entries, list corresponding items as well.
>
> **Traceability completeness requirement**: Each AC must be traceable to the complete chain `AC -> Requirement/Scenario -> Test IDs -> Evidence`.

| AC | Requirement/Scenario | Test IDs / Commands | Evidence / MANUAL-* | Status | Causal Chain Complete |
|---|---|---|---|---|---|
| AC-001 | `<capability>/Requirement...` | `TEST-...` / `pnpm test ...` | `MANUAL-001` / link | TODO | [ ] Complete |

### Traceability Matrix Completeness Checklist

- [ ] **No orphan ACs**: Each AC has corresponding Test IDs or MANUAL-* entries
- [ ] **No orphan tests**: Each Test ID can be traced back to an AC or Requirement
- [ ] **No evidence-less DONE**: Each Status=DONE entry has an Evidence link
- [ ] **Red baseline exists**: `evidence/` directory contains initial failure evidence (proving test validity)
- [ ] **Green evidence exists**: `evidence/` directory contains final passing evidence

### Traceability Chain Example

```
AC-001 (design.md)
  |-- Requirement: REQ-ORDER-001 (specs/order-query/spec.md)
  |   |-- Scenario: SC-001 "Return 400 when pagination params are invalid"
  |-- Test IDs:
  |   |-- TEST-001-a: unit test (tests/unit/order_test.py::test_invalid_page)
  |   |-- TEST-001-b: contract test (tests/contract/order_api_test.py::test_400)
  |-- Evidence:
      |-- Red: evidence/red-baseline-2024-01-05.log
      |-- Green: evidence/green-final-2024-01-06.log
```

---

========================
C) Deterministic Anchors
========================

### 1) Behavior

- unit:
- integration:
- e2e:

### 2) Contract

- OpenAPI/Proto/Schema:
- contract tests:

### 3) Structure / Fitness Functions

- Layering/dependency direction/no cycles:

### 4) Static/Security

- lint/typecheck/build:
- SAST/secret scan:
- Report format: `json|xml` (prefer machine-readable)
- Quality gates: complexity/duplication/dependency rules (if any)

---

========================
D) MANUAL-* Checklist (Manual/Hybrid Acceptance)
========================

> Only include acceptance items that "cannot be reliably automated"; each must specify evidence requirements.

- [ ] MANUAL-001 `<acceptance item>`
  - Pass/Fail criteria:
  - Evidence (screenshot/video/link/log):
  - Responsible person/signature:

---

========================
E) Risks and Degradation (Optional)
========================

- Risks:
- Degradation strategy:
- Rollback strategy:

========================
F) Structural Quality Gate Record (Optional)
========================

> If this change involves "proxy-metric-driven" requirements or potential structural risks, record decisions and alternative gates.

- Conflict point:
- Impact assessment (cohesion/coupling/testability):
- Alternative gates (complexity/coupling/dependency direction/test quality):
- Decision and authorization:

========================
G) Value Stream and Metrics (Optional, but must explicitly fill "None")
========================

> Purpose: Anchor "faster/more stable/more valuable delivery" judgments to observable metrics; avoid looking only at local coding speed.

- Target value signal: `<fill "None" or specify metric/dashboard/log/business event>`
- Value stream bottleneck hypothesis (where it will block): `<fill "None" or specify PR review / tests / release / manual acceptance queue points>`
- Delivery and stability metrics (optional DORA): `<fill "None" or specify Lead Time / Deploy Frequency / Change Failure Rate / MTTR observation metrics>`
- Observation window and trigger points: `<fill "None" or specify how long after go-live, which alerts/reports to watch>`
- Evidence: `<fill "None" or specify link/screenshot/report path (recommend storing in evidence/)>`

========================
H) Audit and Evidence Management (Recommended)
========================

> Purpose: Ensure change process is traceable and auditable, meeting compliance requirements.

### Evidence Directory Structure

```
<change-root>/<change-id>/evidence/
|-- red-baseline/           # Red baseline evidence (required)
|   |-- test-failures-<timestamp>.log
|   |-- test-failures-<timestamp>.json
|-- green-final/            # Green final evidence (required)
|   |-- test-results-<timestamp>.log
|   |-- test-results-<timestamp>.json
|-- performance/            # Performance test evidence (if any)
|   |-- benchmark-<timestamp>.json
|-- manual-acceptance/      # Manual acceptance evidence (if any)
|   |-- MANUAL-001-screenshot.png
|   |-- MANUAL-001-signoff.md
|-- audit-log.md           # Audit log (recommended)
```

### Audit Log Template (audit-log.md)

```markdown
# Change Audit Log

## Metadata
- Change ID: <change-id>
- Created: YYYY-MM-DD HH:MM
- Test Owner: <name/session>
- Coder: <name/session>

## Key Event Record

| Time | Event | Actor | Evidence Link |
|------|-------|-------|---------------|
| YYYY-MM-DD HH:MM | Red baseline established | Test Owner | evidence/red-baseline/xxx.log |
| YYYY-MM-DD HH:MM | First Green | Coder | evidence/green-final/xxx.log |
| YYYY-MM-DD HH:MM | Manual acceptance sign-off | Reviewer | evidence/manual-acceptance/xxx.md |

## Change Decision Record

| Time | Decision | Reason | Impact Scope |
|------|----------|--------|--------------|
| YYYY-MM-DD | Adjust AC-002 acceptance criteria | Found missing boundary condition | tests/unit/xxx_test.py |
```

### Evidence Collection Commands (Recommended Script)

```bash
# Collect Red baseline
change-evidence.sh <change-id> --label red-baseline --project-root "$(pwd)" --change-root <change-root> -- <test-command>

# Collect Green final result
change-evidence.sh <change-id> --label green-final --project-root "$(pwd)" --change-root <change-root> -- <test-command>

# Collect performance test result
change-evidence.sh <change-id> --label performance --project-root "$(pwd)" --change-root <change-root> -- <benchmark-command>
```

### Audit Completeness Checklist

- [ ] **Red baseline exists**: `evidence/red-baseline/` has failure logs
- [ ] **Green evidence exists**: `evidence/green-final/` has passing logs
- [ ] **Timestamps are traceable**: Evidence filenames include timestamps
- [ ] **Audit log is complete**: `audit-log.md` records key events
- [ ] **Manual acceptance has sign-off**: MANUAL-* entries have responsible person signatures
