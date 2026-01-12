# DevBooks Skills Quick Reference (Purpose / Scenarios / Prompts)

Default paths follow DevBooks project examples:
- `<truth-root>` = `dev-playbooks/specs`
- `<change-root>` = `dev-playbooks/changes`
- `<change-id>` = Change package directory name (verb-prefixed)

If you are not using DevBooks: replace `dev-playbooks/specs` / `dev-playbooks/changes` with the `<truth-root>` / `<change-root>` defined in your project's signpost file.

---

## `devbooks-router` (Router)

- Purpose: Route your natural language request to the appropriate `devbooks-*` skills and artifact destination paths.
- **Graph Index Health Check**: Automatically calls `mcp__ckb__getStatus` to check SCIP index status before routing; prompts to generate index if unavailable.
- Use Cases:
  - You are unsure which phase you are in: proposal/apply/review/archive
  - You don't know whether to write proposal / design / spec / tasks / tests first
  - You want AI to suggest the "shortest closed loop" instead of piling up steps
  - You want to use **Prototype Mode** (technical approach uncertain, need rapid validation)
- Usage Prompt (copy directly):
  ```text
  You are now Router. Please invoke `devbooks-router`.
  First read: `dev-playbooks/project.md`
  First ask me 2 questions: What is the `<change-id>`? What are the values of `<truth-root>/<change-root>` in this project?
  Then provide the Skills to use next (in order) + the file path for each artifact.

  My current request is:
  <one-sentence description of what you want to do + constraints/boundaries>
  ```
- Prototype Mode Prompt (when technical approach is uncertain):
  ```text
  You are now Router. Please invoke `devbooks-router` and enable **Prototype Mode**.
  First read: `dev-playbooks/project.md`

  I want to create a "throwaway prototype" to validate technical feasibility (Plan to Throw One Away).
  Please route via the prototype track:
  1) Create prototype skeleton: `change-scaffold.sh <change-id> --prototype ...`
  2) Test Owner produces characterization tests (no Red baseline required)
  3) Coder implements in `prototype/src/` (gates bypass allowed, cannot land in repo src/)
  4) After validation, tell me: how to promote to production (`prototype-promote.sh`) or how to discard

  My current request is:
  <one-sentence description of what you want to validate + technical questions/assumptions>
  ```

---

## `devbooks-proposal-author` (Proposal Author)

- Purpose: Produce `proposal.md` (Why/What/Impact + Debate Packet), serving as the entry point for subsequent Design/Spec/Plan (code writing prohibited in proposal phase).
- Use Cases:
  - New features / behavior changes / refactoring proposals / why changes are needed
  - Need to clarify scope, risks, rollback plan, and acceptance criteria before starting
- Usage Prompt:
  ```text
  You are now Proposal Author. Please invoke `devbooks-proposal-author`, executing the DevBooks proposal phase (implementation code prohibited).
  First read: `dev-playbooks/project.md`
  Please first generate a verb-prefixed `<change-id>`, and repeat it 3 times in your output for my confirmation.
  Then write: `dev-playbooks/changes/<change-id>/proposal.md` (must include Debate Packet).
  Additional requirement: The Impact section of the proposal must clearly state `Value Signals and Observation Metrics`, `Value Stream Bottleneck Hypothesis (Queue Points)` (write "None" if unknown).

  My requirement is:
  <one-sentence requirement + background + constraints>
  ```

---

## `devbooks-impact-analysis` (Impact Analyst)

- Purpose: Perform impact analysis before cross-module/cross-file/external contract changes, writing conclusions back to the Impact section of `proposal.md`.
- **Dual-Mode Analysis**:
  - **Graph-based Analysis** (when SCIP available): Uses `analyzeImpact`/`findReferences`/`getCallGraph` for high-precision analysis
  - **Text Search** (fallback mode): Uses `Grep`/`Glob` for keyword searching
- Use Cases:
  - You are modifying many files / uncertain about impact scope / may break compatibility
  - "Looks like just one change" but worried about missing cross-module updates
- Usage Prompt:
  ```text
  You are now Impact Analyst. Please invoke `devbooks-impact-analysis` (code writing prohibited).
  First read: `dev-playbooks/project.md`, `dev-playbooks/changes/<change-id>/proposal.md`, `dev-playbooks/specs/**`
  Please output impact analysis (Scope/Impacts/Risks/Minimal Diff/Open Questions), and write conclusions back to:
  the Impact section of `dev-playbooks/changes/<change-id>/proposal.md`.
  ```

---

## `devbooks-proposal-challenger` (Proposal Challenger)

- Purpose: Challenge `proposal.md`, outputting only a "challenge report" with mandatory conclusion (Approve/Revise/Reject), no file modifications.
- Use Cases:
  - High risk, high controversy, many trade-offs
  - Want "strong constraint review" to prevent vague proposals from passing
- Usage Prompt:
  ```text
  You are now Proposal Challenger. Please invoke `devbooks-proposal-challenger`.
  Only read: `dev-playbooks/changes/<change-id>/proposal.md` (also read `design.md` / `dev-playbooks/specs/**` if available)
  Only output a "challenge report" (conclusion must be `Approve | Revise | Reject`), do not modify any files.
  ```

---

## `devbooks-proposal-judge` (Proposal Judge)

- Purpose: Make final judgment on the proposal phase, outputting `Approved | Revise | Rejected` and writing back to the Decision Log in `proposal.md`.
- Use Cases:
  - You already have a Challenger report and need final judgment with "required changes/verification requirements"
- Usage Prompt:
  ```text
  You are now Proposal Judge. Please invoke `devbooks-proposal-judge`.
  Input: `dev-playbooks/changes/<change-id>/proposal.md` + the Challenger report I pasted
  Please provide judgment (`Approved | Revise | Rejected`), and write the judgment and "required changes/verification requirements" back to:
  the Decision Log of `dev-playbooks/changes/<change-id>/proposal.md` (Pending is prohibited).
  ```

---

## `devbooks-proposal-debate-workflow` (Proposal Debate Workflow)

- Purpose: Run "proposal-challenge-judgment" as a triangular debate workflow (Author/Challenger/Judge role isolation), ensuring clear Decision Log status.
- Use Cases:
  - You want to enforce tri-role confrontation to improve proposal quality
  - Team often "starts work before risks are clarified"
- Usage Prompt:
  ```text
  You are now Proposal Debate Orchestrator. Please invoke `devbooks-proposal-debate-workflow`.
  First read: `dev-playbooks/project.md`
  Constraint: Author/Challenger/Judge must have independent conversations/instances; if I cannot provide independent conversations, stop and explain why.
  Goal: The Decision Log status in `dev-playbooks/changes/<change-id>/proposal.md` must be Approved/Revise/Rejected (Pending is prohibited).
  Please tell me step by step according to the workflow: what instructions I need to copy-paste in each independent conversation, and what results I need to paste back to the current conversation.

  My requirement is:
  <one-sentence requirement + background + constraints>
  ```

---

## `devbooks-design-doc` (Design Owner / Design Doc)

- Purpose: Produce `design.md`, only writing What/Constraints + AC-xxx (implementation steps prohibited), serving as the golden truth for tests and plans.
- Use Cases:
  - Non-trivial changes
  - Need to clarify constraints, acceptance criteria, boundaries, and invariants
- Usage Prompt:
  ```text
  You are now Design Owner. Please invoke `devbooks-design-doc` (implementation steps prohibited).
  First read: `dev-playbooks/project.md`, `dev-playbooks/changes/<change-id>/proposal.md`
  Please write: `dev-playbooks/changes/<change-id>/design.md` (only What/Constraints + AC-xxx).
  ```

---

## `devbooks-spec-contract` (Spec & Contract Owner) [New]

> This skill merges the functionality of the original `devbooks-spec-delta` and `devbooks-contract-data`, reducing decision fatigue.

- Purpose: Define external behavior specifications and contracts (Requirements/Scenarios/API/Schema/Compatibility Strategy), and suggest or generate contract tests.
- Use Cases:
  - External behavior/contract/data invariant changes
  - OpenAPI/Proto/event envelope/schema/configuration format changes
  - Need compatibility strategy, deprecation strategy, migration and replay
- Usage Prompt:
  ```text
  You are now Spec & Contract Owner. Please invoke `devbooks-spec-contract`.
  First read: `dev-playbooks/changes/<change-id>/proposal.md`, `dev-playbooks/changes/<change-id>/design.md` (if available)
  Please output in one pass:
  - Spec delta: `dev-playbooks/changes/<change-id>/specs/<capability>/spec.md` (Requirements/Scenarios)
  - Contract plan: Write to the Contract section of `design.md` (API changes + Compatibility Strategy + Contract Test IDs)
  If there is implicit change risk, run: `implicit-change-detect.sh`
  ```

---

## `devbooks-c4-map` (C4 Map Maintainer)

- Purpose: Maintain/update the project's authoritative C4 architecture map (current truth), and output C4 Delta based on changes.
- Use Cases:
  - **Proposal Phase**: Need to document "boundary/dependency direction changes" in `design.md` (only write **C4 Delta**, don't modify current truth)
  - **Review/Archive Phase**: Changes implemented and ready to merge to current truth, update authoritative map `(<truth-root>/architecture/c4.md)`
- Usage Prompts:
  - Proposal (only write C4 Delta, don't modify current truth):
    ```text
    You are now C4 Map Maintainer. Please invoke `devbooks-c4-map`, but during the proposal phase **do not modify** `dev-playbooks/specs/architecture/c4.md` (current truth).
    First read: `dev-playbooks/specs/architecture/c4.md` (if exists) + this `dev-playbooks/changes/<change-id>/proposal.md` + `dev-playbooks/changes/<change-id>/design.md`
    Please output: a **C4 Delta** section that can be directly pasted into `dev-playbooks/changes/<change-id>/design.md` (C1/C2/C3 additions/modifications/removals + dependency direction changes + suggested Architecture Guardrails/fitness tests entries).
    ```
  - Review/Archive (update current truth authoritative map):
  ```text
  You are now C4 Map Maintainer. Please invoke `devbooks-c4-map`.
  First read: `dev-playbooks/specs/architecture/c4.md` (if exists) + this `dev-playbooks/changes/<change-id>/design.md` + related code changes (to confirm changes have actually landed)
  Please update (or create minimal skeleton with TODO marks): `dev-playbooks/specs/architecture/c4.md`.
  ```

---

## `devbooks-implementation-plan` (Planner / tasks.md)

- Purpose: Derive coding plan `tasks.md` from `design.md` (main plan/temporary plan/breakpoint zone), binding acceptance anchors (must not reference tests/).
- Use Cases:
  - Need task breakdown, parallel splitting, milestones, acceptance anchors
  - Large changes need control over each subtask's scope and verifiability
- Usage Prompt:
  ```text
  You are now Planner. Please invoke `devbooks-implementation-plan` (implementation code prohibited).
  First read: `dev-playbooks/changes/<change-id>/design.md` (and this `specs/**` if applicable); must not reference `tests/**`.
  Please write: `dev-playbooks/changes/<change-id>/tasks.md` (each task must have an acceptance anchor).
  Finally run: `devbooks validate <change-id> --strict` and fix all issues.
  ```

---

## `devbooks-test-owner` (Test Owner)

- Purpose: Transform design/specs into executable acceptance tests and traceability document `verification.md`; emphasizes independent conversation from implementation (Coder), running Red baseline first.
- Use Cases:
  - Need TDD/acceptance tests/traceability matrix (Trace Matrix)
  - Need contract tests / architecture fitness tests
- **Output Management**: When test output exceeds 50 lines, only keep key failure information, dump full logs to `evidence/`
- Usage Prompt (must be new conversation/independent instance):
  ```text
  You are now Test Owner (must be independent conversation/independent instance). Please invoke `devbooks-test-owner`, executing the DevBooks apply phase.
  Read-only input: `dev-playbooks/changes/<change-id>/proposal.md`, `design.md`, this `specs/**` (if applicable); must not reference `tasks.md`.
  Output:
    - `dev-playbooks/changes/<change-id>/verification.md` (with traceability matrix)
    - `tests/**` (per repository conventions)
    - Failure evidence dumped to `dev-playbooks/changes/<change-id>/evidence/`
  Requirement: Must first run out Red baseline; finally run `devbooks validate <change-id> --strict`.
  ```

---

## `devbooks-coder` (Coder)

- Purpose: Strictly implement features according to `tasks.md` and run gates, prohibited from modifying `tests/**`, using tests/static checks as the only completion criteria.
- Use Cases:
  - Entering implementation phase: implement tasks item by item, fix test failures, make all gates green
- **Hotspot Awareness**: Call `mcp__ckb__getHotspots` before starting tasks to check if target files are high-risk areas, and output hotspot report
  - Red Critical: Top 5 hotspot AND modifying core logic -> Refactor first before modifying, must add tests
  - Yellow High: Top 10 hotspot -> Add test coverage, focus code review attention
  - Green Normal: Non-hotspot -> Normal workflow
- **Breakpoint Continuation**: When resuming after interruption, Coder automatically identifies completed tasks in tasks.md and continues from breakpoint
- **Output Management**: When command output exceeds 50 lines, only keep first and last 10 lines + summary, dump full logs to `evidence/`
- Usage Prompt (must be new conversation/independent instance):
  ```text
  You are now Coder (must be independent conversation/independent instance). Please invoke `devbooks-coder`, executing the DevBooks apply phase.
  First read: `dev-playbooks/changes/<change-id>/tasks.md`, and Test Owner's `verification.md` (if exists).
  Strictly implement according to `tasks.md`; check off `- [x]` after completing each item.
  Prohibited from modifying `tests/**`; if tests need adjustment, hand back to Test Owner.
  Use tests/static checks/build as the only completion criteria; dump key outputs to `dev-playbooks/changes/<change-id>/evidence/` when necessary.
  ```

---

## `devbooks-code-review` (Reviewer)

- Purpose: As Reviewer role, conduct readability/consistency/dependency health/code smell review, outputting only actionable suggestions, not discussing business correctness.
- **Hotspot-Priority Review**: Call `mcp__ckb__getHotspots` before review to get project hotspots, review in risk order
  - Red Top 5 Hotspots: Must deep review (test coverage, cyclomatic complexity changes, dependency count changes)
  - Yellow Top 10 Hotspots: Priority attention
  - Green Non-hotspots: Routine review
- Use Cases:
  - Pre/post PR review for structural and maintainability gatekeeping
  - Want to discover coupling, dependency direction, complexity, code smells
- Usage Prompt:
  ```text
  You are now Reviewer. Please invoke `devbooks-code-review`.
  Please only do readability/consistency/dependency health/code smell review, do not discuss business correctness; do not modify tests/, do not modify design.
  Input: Code involved in this change + `dev-playbooks/specs/**` (if project profile/glossary/pitfall library needed).
  Output: Severe issues / Maintainability risks / Consistency suggestions / Suggested new quality gates.
  ```

---

## `devbooks-design-backport` (Design Doc Editor / Backport)

- Purpose: Write back new constraints/conflicts/gaps discovered during implementation to `design.md` (keeping design as golden truth), annotating decisions and impacts.
- Use Cases:
  - Discovered "design didn't cover/conflicts with implementation/temporary decision affects scope"
  - Need to stop and write back to design before continuing implementation
- Usage Prompt:
  ```text
  You are now Design Doc Editor. Please invoke `devbooks-design-backport`.
  Trigger: Discovered design gap/conflict/temporary decision during implementation.
  Please write back content that needs to be elevated to design layer: `dev-playbooks/changes/<change-id>/design.md` (explain reason and impact), then stop.
  You must clearly remind me: need to return to Planner to re-run tasks; Test Owner may need to add tests/re-run Red baseline.
  ```

---

## `devbooks-spec-gardener` (Spec Gardener)

- Purpose: Prune and maintain `<truth-root>` before archiving (deduplicate/merge/delete outdated/directory reorganization/consistency fixes), preventing specs accumulation from getting out of control.
- Use Cases:
  - This change produced spec deltas, preparing to archive and merge into current truth
  - Found duplicate/overlapping/outdated entries in `<truth-root>`
- Usage Prompt:
  ```text
  You are now Spec Gardener. Please invoke `devbooks-spec-gardener`.
  Input: `dev-playbooks/changes/<change-id>/specs/**` + `dev-playbooks/specs/**` + `dev-playbooks/changes/<change-id>/design.md` (if available)
  Only allowed to modify `dev-playbooks/specs/**` for merge/deduplicate/categorize/delete outdated; do not modify change package contents.
  Output in order: Change operation list (CREATE/UPDATE/MOVE/DELETE) -> Complete file content for each CREATE/UPDATE -> Merge mapping summary -> Open Questions (<=3).
  ```

---

## `devbooks-delivery-workflow` (Delivery Workflow + Scripts)

- Purpose: Run a change as a "traceable closed loop" (Design->Plan->Trace->Verify->Implement->Archive), providing deterministic scripts for scaffold/check/evidence/codemod.
- **Architecture Compliance Check**: `guardrail-check.sh` new options
  - `--check-layers`: Check layer constraint violations (lower layer referencing upper layer, common referencing browser/node, etc.)
  - `--check-cycles`: Check circular dependencies
  - `--check-hotspots`: Warn about hotspot file changes
- Use Cases:
  - You want to script repetitive steps (avoid missing files, fields, validations)
  - You want to anchor "completion" to executable verification (not verbal confirmation)
- Usage Prompt:
  ```text
  You are now about to invoke `devbooks-delivery-workflow`.
  Goal: Use this Skill's `scripts/*` to generate/validate/collect evidence as much as possible, rather than manually writing skeletons from memory.
  Constraint: Do not paste script body into context; only run scripts and summarize results; confirm with me before running each command.

  Project root: $(pwd)
  This change-id: <change-id>
  truth-root: dev-playbooks/specs
  change-root: dev-playbooks/changes

  Please suggest and execute in order (wait for my confirmation):
  1) `change-scaffold.sh <change-id> --project-root "$(pwd)" --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`
  2) `change-check.sh <change-id> --mode proposal --project-root "$(pwd)" --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`
  3) (When evidence needed) Use `change-evidence.sh` to dump test/command output to `dev-playbooks/changes/<change-id>/evidence/`
  ```

---

## `devbooks-brownfield-bootstrap` (Brownfield Bootstrapper)

- Purpose: Legacy project initialization: when `<truth-root>` is empty/missing, generate project profile, glossary, baseline specs, and minimal verification anchors, avoiding "patching specs while changing behavior".
- **COD Model Generation**: Automatically generates "code map" artifacts
  - Module dependency graph: `<truth-root>/architecture/module-graph.md` (from `mcp__ckb__getArchitecture`)
  - Technical debt hotspots: `<truth-root>/architecture/hotspots.md` (from `mcp__ckb__getHotspots`)
  - Domain concepts: `<truth-root>/_meta/key-concepts.md` (from `mcp__ckb__listKeyConcepts`)
  - Project profile template: Three-layer architecture (syntax layer/semantic layer/context layer)
- Use Cases:
  - Legacy project wants to adopt DevBooks, but has no current truth and spec baseline
  - You want to document "what it currently looks like" before starting changes
- Usage Prompt:
  ```text
  You are now Brownfield Bootstrapper. Please invoke `devbooks-brownfield-bootstrap`.
  First confirm: This project's truth-root = `dev-playbooks/specs`, change-root = `dev-playbooks/changes`.
  Constraint: Only produce documentation and baseline specs, no refactoring, no behavior changes, no implementation plans.
  Please complete in one pass according to this skill's requirements:
    - `dev-playbooks/specs/_meta/project-profile.md`
    - (Optional) `dev-playbooks/specs/_meta/glossary.md`
    - A baseline change package: `dev-playbooks/changes/<baseline-id>/*` (proposal/design/specs/verification)
  Finally tell me: how to merge the baseline into `dev-playbooks/specs/` (archiving/manual steps).
  ```

---

## `devbooks-entropy-monitor` (Entropy Monitor)

- Purpose: Periodically collect system entropy metrics (structural entropy/change entropy/test entropy/dependency entropy), generate quantitative reports, suggest refactoring when metrics exceed thresholds.
- Use Cases:
  - You want periodic health checks on code health (complexity trends, hotspot files, flaky test ratio)
  - You want quantitative data support before refactoring (not just "feels like the code is rotting")
  - You want to establish visible trends for technical debt
- Usage Prompt:
  ```text
  You are now Entropy Monitor. Please invoke `devbooks-entropy-monitor`.
  First read: `dev-playbooks/project.md` (if exists)
  Goal: Collect current system entropy metrics and generate quantitative report.

  Please execute the following steps:
  1) Run `entropy-measure.sh --project-root "$(pwd)"`, collect four-dimensional metrics (structural entropy/change entropy/test entropy/dependency entropy)
  2) Run `entropy-report.sh --output <truth-root>/_meta/entropy/entropy-report-$(date +%Y-%m-%d).md`, generate report
  3) Compare against thresholds (`thresholds.json`), list metrics exceeding thresholds
  4) If there are threshold-exceeding metrics: provide refactoring recommendations (can serve as data support for subsequent proposals)

  Project root: $(pwd)
  truth-root: dev-playbooks/specs
  ```
- Periodic Execution Recommendations:
  - Small projects (< 10K LOC): Manual weekly run
  - Medium projects (10K-100K LOC): CI scheduled daily run
  - Large projects (> 100K LOC): Trigger on PR merge

---

## `devbooks-index-bootstrap` (Index Bootstrapper) [New]

- Purpose: Automatically detect project language stack and generate SCIP index, activating graph-based code understanding capabilities (call graphs, impact analysis, symbol references, etc.).
- **Trigger Conditions**:
  - User says "initialize index/build code graph/activate graph analysis"
  - `mcp__ckb__getStatus` returns SCIP backend `healthy: false`
  - Entering new project and `index.scip` does not exist
- Use Cases:
  - Want to use graph-based analysis mode of `devbooks-impact-analysis`
  - Want hotspot awareness in `devbooks-coder`/`devbooks-code-review`
  - CKB MCP tools report "SCIP backend unavailable"
- Usage Prompt:
  ```text
  Please invoke `devbooks-index-bootstrap`.
  Goal: Detect project language stack, generate SCIP index, activate graph-based code understanding capabilities.
  Project root: $(pwd)
  ```
- Manual Index Generation (no Skill needed):
  ```bash
  # TypeScript/JavaScript
  npm install -g @anthropic-ai/scip-typescript
  scip-typescript index --output index.scip

  # Python
  pip install scip-python
  scip-python index . --output index.scip

  # Go
  go install github.com/sourcegraph/scip-go@latest
  scip-go --output index.scip
  ```

---

## `devbooks-federation` (Federation Analyst) [New]

- Purpose: Cross-repository federation analysis and contract synchronization. Detect contract changes, analyze cross-repository impact, notify downstream consumers.
- **Trigger Conditions**:
  - User says "cross-repository impact/federation analysis/contract sync/upstream-downstream dependencies/multi-repo"
  - Changes involve contract files defined in `federation.yaml`
- Use Cases:
  - Multi-repository project, need to analyze downstream impact of changes
  - External API/contract changes, need to notify consumers
  - Want to establish cross-repository impact traceability
- Prerequisites:
  - Project root contains `.devbooks/federation.yaml` (copy from `skills/devbooks-federation/templates/federation.yaml`)
- Usage Prompt:
  ```text
  Please invoke `devbooks-federation`.
  Goal: Analyze cross-repository impact of this change, detect contract changes, generate impact report.
  Project root: $(pwd)
  Changed files: <list of changed files>
  ```
- Script Support:
  ```bash
  # Check federation contract changes
  bash ~/.claude/skills/devbooks-federation/scripts/federation-check.sh --project-root "$(pwd)"
  ```
