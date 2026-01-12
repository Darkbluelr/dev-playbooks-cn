# verification.md Template (Within Change Package)

> Recommended path: `<change-root>/<change-id>/verification.md`
>
> Goal: Ground the "Definition of Done" in executable anchors and evidence, providing traceability from `AC-xxx -> Requirement/Scenario -> Test IDs -> Evidence`.

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
A) Test Plan Directive Table
========================

### Main Plan Area

- [ ] TP1.1 `<one-line goal>`
  - Why:
  - Acceptance Criteria (reference AC-xxx / Requirement):
  - Test Type: `unit | contract | integration | e2e | fitness | static`
  - Non-goals:
  - Candidate Anchors (Test IDs / commands / evidence):

### Temporary Plan Area

- (leave empty / as needed)

### Context Switch Breakpoint Area

- Previous progress:
- Current blocker:
- Next shortest path:

---

========================
B) Traceability Matrix
========================

> Recommended to use AC-xxx as primary key; if you maintain Requirements/Scenarios spec entries, list corresponding items as well.

| AC | Requirement/Scenario | Test IDs / Commands | Evidence / MANUAL-* | Status |
|---|---|---|---|---|
| AC-001 | `<capability>/Requirement...` | `TEST-...` / `pnpm test ...` | `MANUAL-001` / link | TODO |

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
- Quality gates: complexity/duplication/dependency rules (if applicable)

---

========================
D) MANUAL-* Checklist (Manual/Hybrid Acceptance)
========================

> Only include acceptance items that "cannot be stably automated"; each item must clearly specify evidence requirements.

- [ ] MANUAL-001 `<acceptance item>`
  - Pass/Fail criteria:
  - Evidence (screenshot/recording/link/log):
  - Owner/sign-off:

---

========================
E) Risks and Degradation (Optional)
========================

- Risk:
- Degradation strategy:
- Rollback strategy:

========================
F) Structural Quality Gate Record (Optional)
========================

> If this change involves "proxy metric-driven" requirements or potential structural risks, record decisions and alternative gates.

- Conflict point:
- Impact assessment (cohesion/coupling/testability):
- Alternative gates (complexity/coupling/dependency direction/test quality):
- Decision and authorization:

========================
G) Value Stream and Metrics (Optional, but must explicitly state "None")
========================

> Purpose: Ground the judgment of "faster/more stable/more valuable delivery" in observable metrics; avoid focusing only on local coding speed.

- Target value signal: `<state "None" or specify metric/dashboard/log/business event>`
- Value stream bottleneck hypothesis (where will it block): `<state "None" or specify queue points for PR review / tests / release / manual acceptance>`
- Delivery and stability metrics (optional DORA): `<state "None" or specify observability for Lead Time / Deploy Frequency / Change Failure Rate / MTTR>`
- Observation window and trigger points: `<state "None" or specify how long after go-live, which alerts/reports to watch>`
- Evidence: `<state "None" or specify link/screenshot/report path (recommended to put in evidence/)>`
