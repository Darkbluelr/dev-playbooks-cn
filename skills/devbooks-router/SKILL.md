---
name: devbooks-router
description: "devbooks-router: DevBooks workflow routing and next-step recommendations. Based on user requests (proposal/design/spec/plan/test/implementation/review/archive, or DevBooks proposal/apply/archive) selects the appropriate devbooks-* Skills and provides artifact locations and shortest closed-loop. Use when user says 'what's next/route to appropriate skill/run devbooks closed-loop' etc."
tools:
  - Glob
  - Grep
  - Read
  - Bash
  - mcp__ckb__getStatus
---

# DevBooks: Workflow Router

## Prerequisite: Configuration Discovery (Protocol Agnostic)

- `<truth-root>`: Current truth directory root
- `<change-root>`: Change package directory root

Before execution, **must** search for configuration in the following order (stop when found):
1. `.devbooks/config.yaml` (if exists) -> Parse and use its mappings
2. `dev-playbooks/project.md` (if exists) -> DevBooks 2.0 protocol, use default mappings
4. `project.md` (if exists) -> template protocol, use default mappings
5. If still cannot determine -> **Stop and ask user**

**Key Constraints**:
- If configuration specifies `agents_doc` (rules document), **must read that document first** before executing any operation
- Guessing directory roots is prohibited
- Skipping rules document reading is prohibited

## Prerequisite: Graph Index Health Check (Automatic)

**Execute automatically before routing**, check CKB graph index status:

1. Call `mcp__ckb__getStatus` to check SCIP backend
2. If `backends.scip.healthy = false`:
   - Prompt user: "Detected code graph index not activated, impact analysis/call graph and other graph-based capabilities unavailable"
   - Ask whether to generate index now (approximately 1-5 minutes)
   - If user agrees, execute `devbooks-index-bootstrap` flow
   - If user declines, continue routing but mark "graph-based capabilities degraded"

3. If `backends.scip.healthy = true`:
   - Pass silently, continue routing

**Check script** (for reference):
```bash
# Detect language and generate index
if [ -f "tsconfig.json" ]; then
  scip-typescript index --output index.scip
elif [ -f "pyproject.toml" ]; then
  scip-python index . --output index.scip
elif [ -f "go.mod" ]; then
  scip-go --output index.scip
fi
```

**Degraded Mode Description**:
- Without index, `devbooks-impact-analysis` degrades to Grep text search (reduced accuracy)
- Without index, `devbooks-code-review` cannot get call graph context
- Recommend completing index generation before Apply phase

## Your Task

Map user's natural language request to:
1) Which phase currently (proposal / apply / review / archive)
2) Required artifacts for this change (proposal/design/tasks/verification) and on-demand artifacts (spec deltas/contract/c4/evidence)
3) Which `devbooks-*` Skill(s) to use next
4) Which file path each artifact should be placed in

## Output Requirements (Mandatory)

1) **First clarify 2 minimum key questions** (don't ask if answers already in context):
   - What is `<change-id>`?
   - What are `<truth-root>` / `<change-root>` final values for this project?
2) Provide "next step routing result" (3-6 items):
   - Each includes: Skill to use + artifact path + why needed
3) Only enter corresponding Skill's output mode if user explicitly says "start producing file content directly".

---

## Impact Profile Parsing (AC-003 / AC-012)

When `proposal.md` exists, Router **should automatically parse** Impact section to generate more precise execution plan.

### Impact Profile Structure

```yaml
impact_profile:
  external_api: true/false       # External API changes
  architecture_boundary: true/false  # Architecture boundary changes
  data_model: true/false         # Data model changes
  cross_repo: true/false         # Cross-repository impact
  risk_level: high/medium/low    # Risk level
  affected_modules:              # Affected modules list
    - name: <module-path>
      type: add/modify/delete
      files: <count>
```

### Parsing Flow

1. Detect if `proposal.md` exists
2. If exists, find `## Impact` section
3. Extract `impact_profile:` YAML block
4. Validate required fields: `external_api`, `risk_level`, `affected_modules`

### Routing Enhancement Based on Impact Profile

| Impact Field | Value | Auto-append Skill |
|--------------|-------|-------------------|
| `external_api: true` | - | `devbooks-spec-contract` |
| `architecture_boundary: true` | - | `devbooks-c4-map` |
| `cross_repo: true` | - | `devbooks-federation` |
| `risk_level: high` | - | `devbooks-proposal-debate-workflow` |
| `affected_modules` count > 5 | - | `devbooks-impact-analysis` (deep analysis) |

### Execution Plan Output Format

```markdown
## Execution Plan (Based on Impact Profile)

### Must Execute
1. `/devbooks:proposal` -> proposal.md (proposal exists, skip)
2. `/devbooks:design` -> design.md (required)
3. `/devbooks:plan` -> tasks.md (required)

### Recommended (Based on Impact Analysis)
4. `/devbooks:spec` -> specs/** (detected external_api: true)
5. `/devbooks:c4` -> architecture/c4.md (detected architecture_boundary: true)

### Optional
6. `/devbooks:impact` -> Deep impact analysis (affected_modules > 5)
```

### Parsing Failure Handling (AC-012)

**When no Impact Profile**:

```
Warning: Impact profile not found in proposal.md.

Missing items:
- Impact section doesn't exist
- Or impact_profile YAML block is missing

Recommended actions:
1. Run `/devbooks:impact` to generate impact analysis
2. Or use direct command `/devbooks:<skill>` directly

Direct command list:
- /devbooks:design -> Design document
- /devbooks:plan -> Implementation plan
- /devbooks:spec -> Spec definition
```

**When YAML parsing fails**:

```
Warning: Impact profile parsing failed.

Error: <specific error message>

Recommended actions:
1. Check impact_profile YAML format in proposal.md
2. Or use direct command `/devbooks:<skill>` to bypass Router
```

---

## Routing Rules (Quality-First Default)

### A) Proposal (Proposal Phase)

Trigger signals: User says "proposal/why change/scope/risk/code smell refactoring/should we do it/don't write code yet" etc.

Default routing:
- `devbooks-proposal-author` -> `(<change-root>/<change-id>/proposal.md)` (required)
- `devbooks-design-doc` -> `(<change-root>/<change-id>/design.md)` (required for non-trivial changes; only write What/Constraints + AC-xxx)
- `devbooks-implementation-plan` -> `(<change-root>/<change-id>/tasks.md)` (required; derive from design only)

On-demand additions (add only when conditions met):
- **Cross-module/unclear impact**: `devbooks-impact-analysis` (recommend writing back to proposal Impact)
- **Obvious risks/disputes/trade-offs**: `devbooks-proposal-debate-workflow` (Author/Challenger/Judge, write back Decision Log after debate)
- **External behavior/contract/data invariant changes**: `devbooks-spec-contract` -> `(<change-root>/<change-id>/specs/**)` + `design.md` Contract section
  - If need "deterministic spec delta file creation/avoid wrong paths": `change-spec-delta-scaffold.sh <change-id> <capability> ...`
- **Module boundary/dependency direction/architecture changes**: `devbooks-c4-map` -> `(<truth-root>/architecture/c4.md)`

Hard constraint reminders:
- Implementation code is prohibited in proposal phase; implementation happens in apply phase with tests/gates as completion criteria.
- If need "deterministic scaffold/avoid missing files": prefer running `devbooks-delivery-workflow` scripts
  - `change-scaffold.sh <change-id> ...`
  - `change-check.sh <change-id> --mode proposal ...`

### B) Apply (Implementation Phase: Test Owner / Coder)

Trigger signals: User says "start implementing/run tests/fix failures/follow tasks/make gates all green" etc.

Default routing (mandatory role isolation):
- Test Owner (independent conversation/independent instance): `devbooks-test-owner`
  - Artifacts: `(<change-root>/<change-id>/verification.md)` + `tests/**`
  - Run **Red** baseline first, record evidence (e.g., `(<change-root>/<change-id>/evidence/**)`)
- Coder (independent conversation/independent instance): `devbooks-coder`
  - Input: `tasks.md` + test errors + codebase
  - Modifying `tests/**` is prohibited

Apply phase deterministic checks (recommended):
- Test Owner: `change-check.sh <change-id> --mode apply --role test-owner ...`
- Test Owner (evidence recording): `change-evidence.sh <change-id> --label red-baseline -- <test-command>`
- Coder: `change-check.sh <change-id> --mode apply --role coder ...` (additionally checks git diff that `tests/**` was not modified)

LSC (Large Scale Changes) recommendations:
- First use `change-codemod-scaffold.sh <change-id> --name <codemod-name> ...` to generate codemod script skeleton, then batch changes with script and record evidence

### C) Review (Review Phase)

Trigger signals: User says "review/code smell/maintainability/dependency risk/consistency" etc.

Default routing:
- `devbooks-code-review` (output actionable suggestions; don't change business conclusions, don't change tests)

### D) Archive (Archive Phase)

Trigger signals: User says "archive/merge specs/close out/wrap up" etc.

Default routing:
- If spec deltas produced: `devbooks-spec-gardener` (prune `<truth-root>/**` before archive merge)
- If design decisions need backporting: `devbooks-design-backport` (on demand)

Pre-archive deterministic checks (recommended):
- `change-check.sh <change-id> --mode strict ...` (requires: proposal Approved, tasks all checked, trace matrix no TODO, structural gate decisions filled)

### E) Prototype (Prototype Mode)

> Source: "The Mythical Man-Month" Chapter 11 "Plan to Throw One Away" - "The first system developed is never fit for use...plan to throw one away"

Trigger signals: User says "prototype first/quick validation/spike/--prototype/throwaway prototype/Plan to Throw One Away" etc.

**Prototype mode applicable scenarios**:
- Technical solution uncertain, need quick feasibility validation
- First time building certain feature, expected to rewrite
- Need to explore actual behavior of API/library/framework

**Default routing (prototype track constraints)**:

1. Create prototype skeleton:
   - `change-scaffold.sh <change-id> --prototype ...`
   - Artifact: `(<change-root>/<change-id>/prototype/)`

2. Test Owner (independent conversation) uses `devbooks-test-owner --prototype`:
   - Artifact: `(<change-root>/<change-id>/prototype/characterization/)`
   - Generate **characterization tests** (record actual behavior) not acceptance tests
   - **No Red baseline needed** - characterization tests assert "current state"

3. Coder (independent conversation) uses `devbooks-coder --prototype`:
   - Output path: `(<change-root>/<change-id>/prototype/src/)`
   - May bypass lint/complexity thresholds
   - **Directly landing in repository `src/` is prohibited**

**Hard constraints (must follow)**:
- Prototype code and production code **physically isolated** (different directories)
- Test Owner and Coder still must be **independent conversations/independent instances** (role isolation unchanged)
- Prototype promotion to production requires **explicit trigger** `prototype-promote.sh <change-id>`

**Prerequisites for prototype promotion to production**:
1. Create production-grade `design.md` (extract What/Constraints/AC-xxx from prototype learnings)
2. Test Owner produces acceptance tests `verification.md` (replacing characterization tests)
3. Complete promotion checklist in `prototype/PROTOTYPE.md`
4. Run `prototype-promote.sh <change-id>` and pass all gates

**Prototype discard flow**:
1. Record key insights learned to proposal.md Decision Log
2. Delete `prototype/` directory

## DevBooks Command Adaptation

DevBooks uses `/devbooks:proposal`, `/devbooks:apply`, `/devbooks:archive` as entry points.
Route according to A/B/C/D above, artifact paths based on `<truth-root>/<change-root>` mappings from project signpost.

---

## Context Awareness

This Skill automatically detects context before execution and selects appropriate routing strategy.

Detection rules reference: `skills/_shared/context-detection-template.md`

### Detection Flow

1. Detect if change package exists
2. Detect existing artifacts (proposal/design/tasks/verification)
3. Infer current phase (proposal/apply/archive)
4. Select default routing based on phase

### Modes Supported by This Skill

| Mode | Trigger Condition | Behavior |
|------|-------------------|----------|
| **New change** | Change package doesn't exist or empty | Route to proposal phase, suggest creating proposal.md |
| **In progress** | Change package exists, has partial artifacts | Recommend next step based on missing artifacts |
| **Ready to archive** | Gates passed, `evidence/green-final/` exists | Route to archive phase |

### Detection Output Example

```
Detection Result:
- Change package status: exists
- Existing artifacts: proposal.md OK, design.md OK, tasks.md OK, verification.md missing
- Current phase: apply
- Recommended routing: devbooks-test-owner (establish Red baseline first)
```

---

## MCP Enhancement

This Skill supports MCP runtime enhancement, automatically detecting and enabling advanced features.

MCP enhancement rules reference: `skills/_shared/mcp-enhancement-template.md`

### Dependent MCP Services

| Service | Purpose | Timeout |
|---------|---------|---------|
| `mcp__ckb__getStatus` | Detect CKB index availability | 2s |

### Detection Flow

1. Call `mcp__ckb__getStatus` (2s timeout)
2. If CKB available -> Mark "graph-based capabilities activated" in routing suggestions
3. If timeout or failure -> Mark "graph-based capabilities degraded" in routing suggestions, suggest running /devbooks:index

### Enhanced Mode vs Basic Mode

| Feature | Enhanced Mode | Basic Mode |
|---------|---------------|------------|
| Impact analysis recommendation | Use CKB precise analysis | Use Grep text search |
| Code navigation | Symbol-level jump available | File-level search |
| Hotspot detection | CKB real-time analysis | Unavailable |

### Degradation Notice

When MCP unavailable, output the following notice:

```
Warning: CKB index not activated, graph-based capabilities (impact analysis, call graph, etc.) will be degraded.
Recommend running /devbooks:index to generate index for full functionality.
```
