# Delivery Acceptance Workflow (Design -> Plan -> Trace -> Verify)

> This document serves as the process skeleton for the "Development Playbook", targeting solo/AI agent-style development.

Directory conventions (protocol-agnostic):
- Current truth source: `<truth-root>/`
- Single change package: `<change-root>/<change-id>/` (proposal/design/tasks/specs delta/verification/evidence)
- Archive: merge delta into `<truth-root>/`, and move change package to archive area (if your context protocol provides an archive command, prefer using that)

> Goal: Make "delivery complete" have executable, traceable, and dispute-resolvable objective criteria, avoiding the false state of "tests all green but coding plan still largely incomplete".

---

## 0) Role Isolation and Test Integrity (Mandatory)

- Test Owner and Coder must have independent sessions/independent instances; parallel work is allowed but context sharing is not.
- Test Owner only produces tests/verification based on design/specs, and must first run to get a **Red** baseline; failure evidence is recorded to `<change-root>/<id>/evidence/` (recommend using `change-evidence.sh <id> -- <test-command>` to capture and persist).
- Coder only implements according to tasks and runs gates; **modifying tests/ is prohibited**. If tests need adjustment, it must be handed back to Test Owner for decision and changes.

## 0.1) Structural Quality Gates (Mandatory)

- If "proxy metric-driven" requirements appear (line count/file count/mechanical splitting/naming format), must assess impact on cohesion/coupling/testability.
- When risk signals are triggered, must "stop the line": record as a decision issue and return to Design/Proposal for handling, do not execute directly.
- Quality gate priority: complexity, coupling, dependency direction, change frequency, test quality > proxy metrics.

## 1) What Can Go in `tests/`?

The essence of `tests/` is **Executable Acceptance Anchors**: anything that can be stably judged Pass/Fail by a machine can (and should) enter the automation pipeline.

### 1.1 Recommended Content for `tests/` (Strong Constraints/Regression)

1. **Automated Tests (Behavior / Contract)**
   - Unit tests: pure logic, no IO
   - Integration tests: multi-component collaboration, but try to use fake/mocked dependencies
   - End-to-end tests (e2e): minimal critical path (offline-capable)
   - Contract tests: schema, event envelopes, API input/output shapes, backward compatibility, etc.
2. **Architecture Fitness Functions**
   - Dependency direction, layer boundaries, no circular dependencies, module responsibility boundaries, etc. (essentially "tests", just verifying structure rather than behavior)

### 1.2 Content Not Recommended Directly in `tests/` (But Can Be Automated)

3. **Static Analysis (Static Analysis / SAST / Type Check)**
   - These typically exist as "commands" like `ruff/mypy/eslint/tsc/bandit/semgrep`, better suited for separate CI steps or in `scripts/`.
   - Can also be "wrapped" to fail in `pytest` (e.g., run command and assert exit code), but be careful: this slows down tests, makes output less clear than native tools, and may conflict with IDE/CI parallelization strategies.

### 1.3 Content That Should Not Be in `tests/` (Not Machine-Decidable)

4. **Explicit Manual Acceptance Steps**
   - e.g., UI layout/usability, interaction paths, visual/copy consistency, product experience, etc.
   - These should be placed as **checklist/acceptance scripts** in the verification document of "this change package" (e.g., `<change-root>/<id>/verification.md`), and recorded in the traceability matrix as "manual anchors" with responsible person and conclusion; only sync to `docs/` when it belongs to publicly-facing user/ops documentation.

Conclusion: **Automated tests + architecture fitness functions** naturally belong in `tests/`; **static checks** are better run separately; **manual acceptance** should not be in `tests/`.

External docs vs development instructions (your preference):
- `docs/` should only contain "project-facing/user-visible documentation"
- "Development instructions/AI workflow/acceptance traceability/manual acceptance checklists" preferably go in the change package (e.g., `<change-root>/<id>/verification.md`), to avoid polluting external docs

---

## 2) MECE Classification of Acceptance Methods (All Methods for "Delivery Acceptance")

Using "who is the judge (Oracle)" as the MECE dimension, all acceptance methods can be completely covered and mutually exclusive:

### A. Machine Judge (Automated / Deterministic)

> Judgment is given by machine, stable and repeatable, final output is Pass/Fail.

- Dynamic tests: unit/contract/integration/e2e/snapshot/golden-master/property-based
- Architecture fitness functions: dependency direction, boundaries, layering, no cycles, no banned package references, etc.
- Static checks: lint, type check, SAST, dependency/license/secret scanning, schema validation, API breaking change detection
- Build and release validation: build, packaging, image build, migration script validation, config/template rendering validation
- Automated runtime validation: smoke test, health check, minimal replay, offline regression package determinism (assuming controlled environment)

### B. Human Judge + Tool Evidence (Hybrid / Evidence-Assisted)

> Tools produce objective evidence, but whether it passes still requires human judgment/sign-off.

- Performance/cost baseline: benchmark results, cost reports, capacity assessment (usually requires threshold discussion and trade-offs)
- Security review: scan result triage, threat modeling review (not as simple as "0 alerts = pass")
- Observability acceptance: dashboard/alert rule checks, SLO report review (evidence is objective, but whether standards are met requires context interpretation)
- UX visual/interaction evidence: screenshot comparison, recordings, analytics funnels (evidence exists, but satisfaction is still subjective decision)

### C. Pure Human Judge (Manual / Judgment-Based)

> Primarily relies on human judgment, difficult to fully formalize as machine criteria.

- UI/interaction acceptance, content and information architecture review, usability walkthroughs
- Product/business acceptance: requirement understanding, boundary conditions, whether exception handling "meets expectations"
- Compliance/process acceptance: permissions, audit, compliance text, legal terms, release process sign-off

Your original "four categories": automated tests / architecture fitness functions / static checks / manual acceptance steps, is a practical split of A and C; the strict MECE "judge perspective" expands it to A/B/C three categories, more comprehensive coverage and less disputable.

---

## 3) Should Tests Be Based on Design Documents or Coding Plans?

### 3.1 Default Principles (Recommended)

- **Externally perceivable requirements/constraints**: Tests should come from **Design Documents**, because design documents have lower error rates and are the authoritative source of "what".
- **Implementation Plan** is responsible for "how": task breakdown, ordering, solution selection, module selection, implementation steps. It should not become the sole judge of external behavior.

## 4) DoD (Definition of Done) for Large Projects (MECE)

Each change must at least declare which gates are covered; missing items must state reasons and remediation plans:

- A. Behavior: unit/integration/e2e (minimum set based on project type)
- B. Contract: OpenAPI/Proto/Schema/event envelope + contract tests
- C. Structure: architecture fitness functions (dependency direction/layering/no cycles/module boundaries)
- D. Static/Security: lint/typecheck/build + SAST/secret scan
- E. Evidence (as needed): screenshots/recordings/reports (UI, performance, security triage)

## 5) How to Gracefully Handle "Overturning Old Design/Old Tests" (Current Truth vs History)

- Authoritative definition: `<truth-root>/` is "current truth"; historical change packages are audit records
- New change overturns old behavior: update specs and tests in new change package, and mark `Supersedes/Breaking` in proposal; do not go back and modify historical archives to "unify the narrative"

### 3.2 When Can You Use "Coding Plan to Generate Tests"?

Only recommended when the following conditions are all met:

- The plan item is a **pure engineering implementation constraint** (e.g., "must have idempotency key", "must have migration script", "must have architecture boundary constraint"), and will not change the external semantics of the design;
- Or you are willing to **upgrade it to a specification**: extract the plan item into an ADR/design supplement, enter the design document's "acceptance criteria", then write tests.

Otherwise, "writing tests from coding plan" easily leads to: **plan is wrong -> tests follow wrong -> code is self-consistent green on wrong target (False Green)**.

Conclusion: **Design document is the acceptance truth source (Golden Truth)**; coding plan can drive "engineering constraint" tests, but either upgrade into design acceptance, or clearly mark as "internal engineering acceptance".

---

## 4) Traceability Matrix: Making "Done" Computable

The traceability matrix solves two key problems:

1. "How exactly is this plan item accepted?" (each plan item must be bound to an acceptance anchor)
2. "Why isn't it done when tests are all green?" (because there are plan items without anchors, or anchors are manual/hybrid incomplete)

### 4.1 Minimal Field Template (Can Be Copied to Any Version/Any Project)

| Design AC ID | Design Acceptance Point (Original/Summary) | Plan ID | Acceptance Method (A/B/C) | Acceptance Anchor (Test ID/Command/Checklist) | Status | Notes |
|---|---|---|---|---|---|---|
| AC-01 | ... | MP1.3 | A | T0014-I-05 / `pytest ...` | DONE | ... |

### 4.2 DoD (Definition of Done)

- **A Plan ID can only be marked DONE when its bound acceptance anchor is PASS (or manually signed off as passed).**
- Any Plan item without a bound anchor can only have status: `UNSCOPED / DEFERRED / TODO(missing anchor)`, cannot be automatically declared complete by "tests all green".

### 4.3 End-to-End Correctness Checklist

> Ensure the complete traceability chain from requirement -> design -> tests -> implementation -> archive is not broken.

**Inter-phase Transfer Checks (must verify each item)**:

| Checkpoint | Verification Question | Action on Failure |
|------------|----------------------|-------------------|
| **proposal -> design** | Does design cover all proposal goals? Are Non-goals boundaries missing? | Supplement design, return to proposal revision |
| **design -> specs** | Do all external behavior/contract changes have corresponding spec delta? | Add spec delta |
| **design -> tasks** | Do tasks cover all ACs? Are there "sourceless" tasks? | Add AC mapping, or upgrade task into design |
| **tasks -> tests** | Does each AC have corresponding tests? Are tests based on design rather than implementation? | Add tests, check test sources |
| **tests -> code** | Does code pass all tests? Is there "modifying tests to accommodate code" behavior? | Fix code, restore original test |
| **code -> archive** | Does archive include all evidence? Have specs been merged to truth source? | Add evidence, run spec gardener |

**Traceability Completeness Checks**:

- [ ] Every AC can be traced to: `AC-xxx -> Requirement/Scenario -> Test IDs -> Evidence`
- [ ] No "orphan tests" (tests exist but no corresponding AC or design source)
- [ ] No "orphan tasks" (tasks exist but no corresponding design source)
- [ ] No "DONE without evidence" (marked complete but no test pass or manual sign-off evidence)

**Final Checks Before Archive**:

```bash
# Recommend running the following checks (if script support available)
change-check.sh <change-id> --mode strict --project-root "$(pwd)" --change-root <change-root> --truth-root <truth-root>
```

- [ ] All A-type acceptance anchors (tests/static checks/build) pass
- [ ] All B/C-type acceptance anchors (manual/hybrid) have been signed off with evidence
- [ ] Traceability matrix has no `TODO(missing anchor)` status
- [ ] `evidence/` directory contains Red baseline evidence and Green pass evidence

---

## 5) Standard Process (Hardened Version)

### Step 0: Determine Delivery Scope for This Iteration (Mandatory)

- Select the Phase/milestone to deliver (MVP/Beta/Prod)
- Clarify Non-goals
- Deliverables: scope declaration in design document + version number

### Step 1: Create Design Document

- Clearly state: goals, non-goals, key decisions, acceptance criteria
- Write "external semantics/invariants" in testable language

### Step 2: Create Implementation Plan

- Break down tasks into executable Plan items (e.g., `MPx.y`)
- Each Plan item must declare:
  - Deliverables
  - Impact scope (modules/files)
  - Acceptance method (A/B/C) and candidate acceptance anchors (test IDs/commands/Checklist)

### Step 3: Establish Traceability Matrix

- Map each **design acceptance point (AC)** to: Plan item + acceptance anchor
- Address two types of gaps immediately:
  1. **Design has acceptance point but no anchor** -> add tests/add static checks/add checklist
  2. **Plan has task but no design source** -> choose: downgrade to DEFERRED, or upgrade into design (ADR) then accept

### Step 4: Write/Update Verification Anchors

- Produce A-type anchors (machine judge): based on design acceptance points, complete/update `tests/`, architecture fitness functions, static check/build validation commands (not tied to specific implementation details).
- For refactoring/migration/existing systems: prioritize adding **Snapshot/Golden Master** tests as safety net.
- Produce B/C-type anchors (non-machine): write acceptance items that cannot be stably automated into checklist, and define "evidence requirements" (screenshots/recordings/dashboard links/logs, etc.).
- Source isolation: acceptance anchors only extracted from design/specs, do not reference coding plan (avoid "testing by plan, answering by plan" self-proving loop).
- Backfill traceability matrix: complete the anchor ID/path corresponding to each design acceptance point and Plan item, ensuring subsequent objective DONE declaration.

### Step 5: Implementation

- Coding execution uses **Implementation Plan** as main thread: read "deliverables/impact scope/constraints/implementation points" per Plan item (e.g., `MPx.y`), complete specific implementation.
- Coder is prohibited from modifying tests/; if tests are unreasonable or need updating, can only feedback to Test Owner.
- Traceability matrix serves as "task filter + acceptance dashboard": prioritize advancing Plan items **already bound to acceptance anchors**; any "anchor-less" Plan item must first have anchors added/written back to design/deferred (otherwise cannot objectively declare DONE).
- Development loop: implement per coding plan -> run A-type anchors (tests/commands) for that Plan item -> fix -> until anchor PASS (then sync update Plan and matrix status).

### Step 6: Full Acceptance (Verification)

- Run all A-type anchors within this scope (full test suite + static checks + build validation)
- Static checks preferably use machine-readable output (json/xml), for mechanical fixes and traceable archiving.
- Execute B/C-type: check off each checklist item and record evidence (screenshots/recordings/reports/signatures)
- Readability/dependency/code smell review (Reviewer): use `devbooks-code-review` Skill to output review comments

### Step 7: Close-out and Consolidation

- Update traceability matrix status (DONE/BLOCKED/DEFERRED)
- Update implementation plan progress table (only based on anchor results)
- Update value stream and metrics: write this iteration's "value signal/queue points/stability metrics" evidence links back to `verification.md` (recommend putting in `evidence/`)
- If "plan errors/design omissions" discovered: correct in next version's Design Doc / ADR, not through verbal agreements
- Living document pruning (Spec Gardening):
  - Execute using `devbooks-spec-gardener` Skill
  - Deduplicate and merge: merge similar/overlapping specs, avoid additive stacking
  - Directory organization: organize by business capability into `<truth-root>/<capability>/`
  - Delete outdated: specs replaced by new features must be deleted
  - Optional automatic check: `guardrail-check.sh <change-id>` (script located at this Skill's `scripts/guardrail-check.sh`)

---

## 6) Directory Layout Example (For Reference)

- Design document: `<change-root>/<change-id>/design.md`
- Implementation plan: `<change-root>/<change-id>/tasks.md`
- Spec delta: `<change-root>/<change-id>/specs/<capability>/spec.md`
- Verification and traceability: `<change-root>/<change-id>/verification.md` (contains test plan, traceability matrix, MANUAL-* checklist and evidence requirements)
- Executable acceptance: `tests/` (contains contract/unit/integration/e2e and architecture fitness functions)
- Archive: merge delta into `<truth-root>/`, and archive change package
