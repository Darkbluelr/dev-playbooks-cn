# DevBooks Integration Template (Protocol-Agnostic)

> Goal: Write DevBooks role isolation, DoD, directory conventions, and `devbooks-*` Skills index into project context (without depending on DevBooks).

---

## DevBooks Context (Protocol-Agnostic Conventions)

Add the following information to your "project signpost file" (filename determined by your context protocol; common candidates: `CLAUDE.md`, `AGENTS.md`, `PROJECT.md`, etc.):

- Directory Roots:
  - `<truth-root>`: Current truth directory root (default recommendation: `specs/`)
  - `<change-root>`: Change package directory root (default recommendation: `changes/`)

- Single Change Package File Locations (Directory Conventions):
  - `(<change-root>/<change-id>/proposal.md)`: Proposal
  - `(<change-root>/<change-id>/design.md)`: Design document
  - `(<change-root>/<change-id>/tasks.md)`: Implementation plan
  - `(<change-root>/<change-id>/verification.md)`: Verification and traceability (includes traceability matrix, MANUAL-* checklists, and evidence requirements)
  - `(<change-root>/<change-id>/specs/**)`: Spec deltas for this change
  - `(<change-root>/<change-id>/evidence/**)`: Evidence (as needed)

- Current Truth Recommended Structure (not mandatory, but recommended for consistency):
  - `(<truth-root>/_meta/project-profile.md)`: Project profile/constraints/gates/format conventions
  - `(<truth-root>/_meta/glossary.md)`: Unified language glossary (terminology)
  - `(<truth-root>/architecture/c4.md)`: C4 architecture map (current truth)
  - `(<truth-root>/engineering/pitfalls.md)`: High-ROI pitfall library (optional)

---

## Role Isolation (Mandatory)

- Test Owner and Coder must be in separate conversations/instances; parallel work is allowed but context sharing is not.
- Coder cannot modify `tests/**`; if tests need adjustment, must hand back to Test Owner for decision and changes.

---

## DoD (Definition of Done, MECE)

Each change must at least declare which gates are covered; missing items must state reason and remediation plan (recommend writing to `(<change-root>/<change-id>/verification.md)`):

- Behavior: unit/integration/e2e (minimum set based on project type)
- Contract: OpenAPI/Proto/Schema/event envelope + contract tests
- Structure: layering/dependency direction/no cycles (fitness tests)
- Static/Security: lint/typecheck/build + SAST/secret scan
- Evidence (as needed): screenshots/recordings/reports (UI, performance, security triage)

---

## DevBooks Skills Index (Protocol-Agnostic)

Recommend adding the following index to project signpost file as a guide for "when to use which Skill":

### Role-based

- Router: `devbooks-router` → For routing and output location suggestions when unsure of next step/phase (supports Prototype mode)
- Proposal Author: `devbooks-proposal-author` → `(<change-root>/<change-id>/proposal.md)`
- Proposal Challenger: `devbooks-proposal-challenger` → Challenge report (may or may not be written to change package)
- Proposal Judge: `devbooks-proposal-judge` → Judgment written back to `proposal.md`
- Impact Analyst: `devbooks-impact-analysis` → Impact analysis (recommend writing to Impact section of proposal)
- Design Owner: `devbooks-design-doc` → `(<change-root>/<change-id>/design.md)`
- Spec & Contract Owner: `devbooks-spec-contract` → `(<change-root>/<change-id>/specs/**)` + contract plan (merged original spec-delta + contract-data)
- Planner: `devbooks-implementation-plan` → `(<change-root>/<change-id>/tasks.md)`
- Test Owner: `devbooks-test-owner` → `(<change-root>/<change-id>/verification.md)` + `tests/**` [Output management: truncate >50 lines]
- Coder: `devbooks-coder` → Implementation (cannot modify tests) [Breakpoint continuation + output management]
- Reviewer: `devbooks-code-review` → Review comments
- Spec Gardener: `devbooks-spec-gardener` → Prune `(<truth-root>/**)` before archive
- C4 Map Maintainer: `devbooks-c4-map` → `(<truth-root>/architecture/c4.md)`
- Design Backport: `devbooks-design-backport` → Backport design gaps/conflicts

### Workflow-based

- Proposal Debate: `devbooks-proposal-debate-workflow` → Author/Challenger/Judge triangle debate
- Delivery Workflow: `devbooks-delivery-workflow` → Change closed loop + deterministic scripts (scaffold/check/evidence)
- Brownfield Bootstrap: `devbooks-brownfield-bootstrap` → Brownfield project initialization (when `<truth-root>` is empty)

### Metrics-based

- Entropy Monitor: `devbooks-entropy-monitor` → System entropy measurement (structural/change/test/dependency entropy) + refactoring alerts

### Index-based

- Index Bootstrap: `devbooks-index-bootstrap` → Auto-generate SCIP index, activate graph-based analysis
- Federation: `devbooks-federation` → Cross-repository federation analysis and contract sync (for multi-repo projects)

---

## CI/CD Integration (Optional)

Copy templates from `templates/ci/` to project `.github/workflows/`:

- `devbooks-guardrail.yml`: Auto-check complexity, hotspots, layer violations, circular dependencies on PR
- `devbooks-cod-update.yml`: Auto-update COD model (module graph, hotspots, concepts) after push

---

## Cross-Repository Federation (Optional)

Multi-repo projects can configure `.devbooks/federation.yaml` to define upstream/downstream dependencies:

```bash
cp skills/devbooks-federation/templates/federation.yaml .devbooks/federation.yaml
```

See `skills/devbooks-federation/SKILL.md` for details

---

## Auto Skill Routing Rules (Seamless Integration)

> These rules let AI automatically select Skills based on user intent, no explicit naming required.

### Intent Recognition and Auto-Routing

| User Intent Pattern | Auto-Selected Skills |
|---------------------|---------------------|
| "Fix bug", "locate issue", "why is it erroring" | `devbooks-impact-analysis` → `devbooks-coder` |
| "Refactor", "optimize code", "eliminate duplication" | `devbooks-code-review` → `devbooks-coder` |
| "New feature", "add XX", "implement XX" | `devbooks-router` → complete closed loop |
| "Write tests", "add tests" | `devbooks-test-owner` |
| "Continue", "next step" | Check `tasks.md` → `devbooks-coder` |
| "Review" | `devbooks-code-review` |

### Auto-Enable Graph-Based Analysis

**Pre-check**: Call `mcp__ckb__getStatus` to check index status
- Available: Auto-use `analyzeImpact`/`findReferences`/`getCallGraph`/`getHotspots`
- Unavailable: Fall back to `Grep`/`Glob` text search

### Auto Hotspot File Warning

Before executing `devbooks-coder` or `devbooks-code-review`, **must** call `mcp__ckb__getHotspots`:
- 🔴 Critical (Top 5): Output warning + suggest adding tests
- 🟡 High (Top 10): Output notice + focus review
- 🟢 Normal: Normal execution

### Auto Change Package Status Recognition

| Status | Auto Suggestion |
|--------|-----------------|
| Only `proposal.md` | → `devbooks-design-doc` |
| Has `design.md` but no `tasks.md` | → `devbooks-implementation-plan` |
| Has incomplete `tasks.md` | → `devbooks-coder` |
| All tasks complete | → `devbooks-code-review` or archive |
