---
name: devbooks-spec-contract
description: "devbooks-spec-contract: Define external behavior specs and contracts (Requirements/Scenarios/API/Schema/compatibility strategy/migration), and suggest or generate contract tests. Merges functionality from original spec-delta and contract-data. Use when user says 'write spec/spec/contract/OpenAPI/Schema/compatibility strategy/contract tests' etc."
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks: Spec & Contract

> This skill merges functionality from original `devbooks-spec-delta` and `devbooks-contract-data`, reducing decision difficulty.

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

---

## Artifact Locations

| Artifact Type | Location Path |
|---------------|---------------|
| Spec delta | `<change-root>/<change-id>/specs/<capability>/spec.md` |
| Contract plan | `<change-root>/<change-id>/design.md` (Contract section) or standalone `contract-plan.md` |
| Contract Test IDs | Written to traceability matrix in `verification.md` |
| Implicit change report | `<change-root>/<change-id>/evidence/implicit-changes.json` |

---

## Use Case Determination

| Scenario | What to Do |
|----------|------------|
| Behavior change only (no API/Schema) | Only output spec.md (Requirements/Scenarios) |
| Has API/Schema/event changes | Output spec.md + contract plan + Contract Test IDs |
| Has compatibility risks | Additionally output compatibility strategy, deprecation strategy, migration plan |
| Dependency/config/build changes | Run implicit change detection |

---

## Execution Method

### Standard Flow

1) First read and follow: `_shared/references/universal-gate-protocol.md`
2) Spec part: Output Requirements/Scenarios according to `references/spec-change-prompt.md`
3) Contract part: Output contract plan according to `references/contract-data-definition-prompt.md`
4) **Implicit change detection (on demand)**: `references/implicit-change-detection-prompt.md`

### Output Structure (Single Output)

```markdown
## Spec Delta

### Requirements
- REQ-XXX-001: <requirement description>

### Scenarios
- SC-001: <scenario description>
  - Given: ...
  - When: ...
  - Then: ...

---

## Contract Plan

### API Changes
- Added/modified endpoint: `POST /api/v1/orders`
- OpenAPI diff location: `contracts/openapi/orders.yaml`

### Compatibility Strategy
- Backward compatible: Yes/No
- Deprecation strategy: <if any>
- Migration plan: <if any>

### Contract Test IDs
| Test ID | Type | Covered Scenario |
|---------|------|------------------|
| CT-001 | schema | REQ-XXX-001 |
| CT-002 | behavior | SC-001 |
```

---

## Scripts

- Implicit change detection: `scripts/implicit-change-detect.sh <change-id> [--base <commit>] [--project-root <dir>] [--change-root <dir>]`

---

## Context Awareness

This Skill automatically detects context before execution and selects appropriate operating mode.

Detection rules reference: `skills/_shared/context-detection-template.md`

### Detection Flow

1. Detect if `<change-root>/<change-id>/specs/` exists
2. If exists, determine completeness (whether has placeholders, whether REQ has Scenario)
3. Select operating mode based on detection result

### Modes Supported by This Skill

| Mode | Trigger Condition | Behavior |
|------|-------------------|----------|
| **Create from scratch** | `specs/` directory doesn't exist or empty | Create complete spec document structure including Requirements/Scenarios |
| **Patch mode** | `specs/` exists but incomplete (has `[TODO]`, REQ missing Scenario) | Add missing Requirement/Scenario, preserve existing content |
| **Sync mode** | `specs/` complete, needs sync with implementation | Check implementation-spec consistency, output diff report |

### Detection Output Example

```
Detection Result:
- Artifact existence: specs/ exists
- Completeness: incomplete (missing items: REQ-002 has no Scenario)
- Current phase: apply
- Operating mode: Patch mode
```

---

## Implicit Change Detection (Extended Feature)

> Source: "The Mythical Man-Month" Chapter 7 "Why Did the Tower of Babel Fail?" - "Groups slowly modify their own programs' functionality, implicitly changing agreements"

Implicit change = changes that are not explicitly declared but will change system behavior.

**Detection Scope**:
- Dependency changes (package.json / requirements.txt / go.mod etc.)
- Configuration changes (*.env / *.config.* / *.yaml etc.)
- Build changes (tsconfig.json / Dockerfile / CI configs etc.)

**Integration with change-check.sh**:
- Automatically check implicit change report in `apply` / `archive` / `strict` modes
- High-risk implicit changes need to be declared in `design.md`

---

## MCP Enhancement

This Skill supports MCP runtime enhancement, automatically detecting and enabling advanced features.

MCP enhancement rules reference: `skills/_shared/mcp-enhancement-template.md`

### Dependent MCP Services

| Service | Purpose | Timeout |
|---------|---------|---------|
| `mcp__ckb__findReferences` | Detect contract reference scope | 2s |
| `mcp__ckb__getStatus` | Detect CKB index availability | 2s |

### Detection Flow

1. Call `mcp__ckb__getStatus` (2s timeout)
2. If CKB available -> Use `findReferences` to detect contract symbol reference scope
3. If timeout or failure -> Degrade to Grep text search

### Enhanced Mode vs Basic Mode

| Feature | Enhanced Mode | Basic Mode |
|---------|---------------|------------|
| Reference detection | Symbol-level precise match | Grep text search |
| Contract impact scope | Call graph analysis | Direct reference statistics |
| Compatibility risk | Auto-evaluation | Manual judgment |

### Degradation Notice

When MCP unavailable, output the following notice:

```
Warning: CKB unavailable, using Grep text search for contract reference detection.
Results may be imprecise, recommend running /devbooks:index to generate index.
```
