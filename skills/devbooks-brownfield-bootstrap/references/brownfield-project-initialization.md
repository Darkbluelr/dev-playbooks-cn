# Brownfield Project: Initialization (Project Profile + Baseline Specs) Workflow

Applicable scenario: You are introducing the "Specification-based Context Protocol" in an existing project, but `<truth-root>/` is empty or nearly empty.

Goal: Complete a one-time setup of "project profile and conventions + current state specification baseline" so that subsequent changes can run stably as if "developed according to the protocol from the beginning."

Core Principles:
- **Don't write the entire system at once**: First cover the "external surface" (API/CLI/events/config/Schema), then gradually add the internals.
- **Evidence first**: Every specification must point to code/tests/logs/runtime behavior; if uncertain, write `TBD` + verification plan.
- **Solidify current state first, then discuss refactoring**: The baseline phase should avoid introducing behavioral changes; prevent "writing specs while changing behavior" which causes truth source drift.

---

## Step 0: Define Baseline Scope (Mandatory)

Choose one of three options (pick only one to avoid losing control):
- A) **External Contract Priority**: API/events/Schema/configuration formats (most recommended)
- B) **Critical Path Priority**: 1-3 core business paths like login/payment/ordering/build-deploy
- C) **Module Boundary Priority**: Dependency direction/layering/no circular dependencies (with C4 + fitness tests)

Output (write to `<change-root>/<baseline-id>/proposal.md`):
- In / Out
- Risks and known unknowns (<=5 items)
- "What this baseline doesn't do" (Non-goals)

---

## Step 0.5: One-time Generation (Recommended Approach)

Use a single prompt to complete "project profile + baseline specs + verification draft":
- See `references/brownfield-initialization-prompt.md` in this Skill

This prompt will produce:
- `<truth-root>/_meta/project-profile.md` (tech stack/commands/conventions/gates/contract entry points)
- `<truth-root>/_meta/glossary.md` (optional: unified language table)
- `<change-root>/<baseline-id>/...` (proposal/design/specs delta/verification)

---

## Step 1: Capability Inventory

Cluster the existing system into 3-8 capabilities using MECE (examples):
- `auth`, `billing`, `search`, `sync`, `config`, `observability`

For each capability, provide at least:
- External entry points (API/CLI/events/topics)
- Core data/Schema
- Dependency direction (who it calls/who calls it)

Output location (recommended):
- `<change-root>/<baseline-id>/design.md` (optional but strongly recommended to have a "current state summary" page)

---

## Step 2: Write Baseline Spec Deltas (ADDED Only)

In `<change-root>/<baseline-id>/specs/<capability>/spec.md`, write **current state specifications**:
- Prefer using only "new/ADDED" type sections (specific headings should follow the format conventions in `<truth-root>/_meta/project-profile.md`)
- Each Requirement must have at least 1 Scenario
- Requirements/Scenarios must be "observable" (input/output/error semantics/invariants)

Notes:
- If uncertain: write `TBD` and add verification action to the plan section of `verification.md` (don't guess).
- If obvious bugs are found: don't fix them during baseline phase; create a separate change for the fix (avoid mixing behavioral changes into the baseline).

---

## Step 3: Add Minimal Verification Anchors (Recommended)

The goal is not "full test coverage" but leaving handholds for future evolution:
- External contracts: prioritize contract tests (schema shape / backward compatibility)
- Critical paths: minimal smoke/integration
- Structural red lines: fitness tests (layering/no circular dependencies/no boundary violations)
- If refactoring/migration is planned: prioritize adding Snapshot/Golden Master as behavioral fingerprints

Output location:
- `<change-root>/<baseline-id>/verification.md` (plan + traceability matrix + MANUAL-*)
- `tests/**` (following repository conventions)
- `contracts/**` (if you maintain a contract library)

---

## Step 4: Merge into Current Truth Source (<truth-root>/)

Merge the baseline change's `<truth-root>/**` into `<truth-root>/**`:
- If your context protocol provides an archive/merge command: use the command to complete the merge
- Otherwise: manual merge is acceptable, but maintain the "change package -> current truth" one-way merge semantics

---

## Definition of Done (DoD)

- `<truth-root>/` contains at least 1-3 core capabilities' spec.md files
- Each spec has at least 3-10 Requirements (current state level is sufficient)
- At least 1 type of anchor is in place (contract or smoke or fitness, choose one)
- Non-covered parts clearly document Non-goals + future completion plan
