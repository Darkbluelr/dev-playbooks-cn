# DevBooks Slash Commands Guide

This guide explains when to use each Slash command, organized by the change lifecycle phases.

> **MCP Auto-Detection**: Each Skill automatically detects MCP availability on execution (2s timeout), no need to manually select "basic" or "enhanced" mode.

---

## Phase Overview

| Phase | Core Commands | Notes |
|-------|---------------|-------|
| **Proposal** | proposal → impact → challenger/judge → design → spec → c4 → plan | No coding allowed |
| **Apply** | test → code → backport (if needed) | Mandatory role isolation |
| **Review** | review → test-review | Review code and tests |
| **Archive** | backport → spec → c4 → gardener | Merge to truth source |
| **Standalone** | router / bootstrap / entropy / federation / index | Not part of a single change |

---

## Proposal (Proposal Phase)

> **Core Principle**: No implementation code allowed, only produce design documents

### 1. `/devbooks:proposal` - Create Change Proposal (Required)

**When to Use**: Starting point for every change

```
/devbooks:proposal <your requirement>
```

**Output**: `<change-root>/<change-id>/proposal.md`

**Contents**:
- Why (reason for change)
- What (what to change)
- Impact (scope of impact)
- Debate Packet (risks/alternatives/constraints)

---

### 2. `/devbooks:impact` - Impact Analysis (Required for cross-module/unclear impact)

**When to Use**:
- Change involves multiple modules
- Unsure about affected scope
- Potential compatibility breaks

```
/devbooks:impact <change-id>
```

**Output**: Updates Impact section of `proposal.md`

**MCP Enhancement**:
- CKB available: Uses `analyzeImpact`, `getCallGraph`, `findReferences`
- CKB unavailable: Falls back to Grep + Glob text search

---

### 3. `/devbooks:challenger` - Challenge Proposal (For controversial/high-risk)

**When to Use**:
- High risk, controversial
- Needs strong constraint review
- Recommend executing in new conversation (role isolation)

```
/devbooks:challenger <change-id>
```

**Output**: Challenge report (conclusion must be `Approve | Revise | Reject`)

---

### 4. `/devbooks:judge` - Judge Proposal (Required after Challenger)

**When to Use**:
- Challenger report exists, needs final judgment
- Recommend executing in new conversation (role isolation)

```
/devbooks:judge <change-id>
```

**Output**: Updates Decision Log in `proposal.md` (`Approved | Revise | Rejected`, no Pending allowed)

---

### 5. `/devbooks:debate` - Triangle Debate Workflow (For high-risk/controversial)

**When to Use**:
- Replaces separate challenger + judge calls
- Auto-orchestrates Author → Challenger → Judge flow

```
/devbooks:debate <change-id>
```

**Output**:
- Challenge report
- Judgment result
- Updated `proposal.md`

---

### 6. `/devbooks:design` - Design Document (Recommended for non-trivial changes)

**When to Use**:
- Not a bug fix or single-line change
- Needs clear constraints, acceptance criteria

```
/devbooks:design <change-id>
```

**Output**: `<change-root>/<change-id>/design.md`

**Contents**:
- What (specific design)
- Constraints (constraints and boundaries)
- AC-xxx (acceptance criteria)
- **No** implementation steps

---

### 7. `/devbooks:spec` - Spec and Contracts (When external behavior/contracts change)

**When to Use**:
- External API changes
- Data contract/Schema changes
- Need compatibility strategy

```
/devbooks:spec <change-id>
```

**Output**:
- `<change-root>/<change-id>/specs/<capability>/spec.md` (Requirements/Scenarios)
- Updates Contract section in `design.md`

---

### 8. `/devbooks:c4` - C4 Architecture Map (When boundaries/dependencies change)

**When to Use**:
- Module boundary changes
- Dependency direction changes
- Add/remove components

```
/devbooks:c4 <change-id>
```

**Proposal Phase Behavior**:
- **Does not modify** current truth `<truth-root>/architecture/c4.md`
- Outputs C4 Delta to `design.md`

---

### 9. `/devbooks:plan` - Implementation Plan (Required)

**When to Use**:
- After design.md is complete
- Final step of Proposal phase

```
/devbooks:plan <change-id>
```

**Output**: `<change-root>/<change-id>/tasks.md`

**Contents**:
- Main Path
- Temp Path (if any)
- Breakpoint Zone
- Acceptance anchors for each task

---

## Apply (Implementation Phase)

> **Core Principle**: Test Owner and Coder must be in separate conversations/instances

### 1. `/devbooks:test` - Test Owner (Required, must be new conversation)

**When to Use**:
- First step of Apply phase
- Must execute before Coder

```
/devbooks:test <change-id>
```

**Role Constraints**:
- Read-only: `proposal.md`, `design.md`, `specs/**`
- No access to: `tasks.md`

**Output**:
- `<change-root>/<change-id>/verification.md` (traceability matrix)
- `tests/**`
- Failure evidence in `evidence/`

**Requirement**: Must first produce **Red** baseline

---

### 2. `/devbooks:code` - Coder (Required, must be new conversation)

**When to Use**:
- After Test Owner completes
- Must execute in separate conversation

```
/devbooks:code <change-id>
```

**Role Constraints**:
- Strictly implement per `tasks.md`
- **Cannot** modify `tests/**`
- If tests need changes, hand back to Test Owner

**Completion Criteria**: tests/static checks/build all green

**MCP Enhancement**:
- CKB available: Outputs hotspot check report
- Top 5 hotspots: Refactor before modifying

---

### 3. `/devbooks:backport` - Design Backport (When design gaps/conflicts found)

**When to Use**:
- Design gaps found during implementation
- Decisions need to be elevated to design layer

```
/devbooks:backport <change-id>
```

**Output**: Updates `design.md`

**Follow-up Actions**:
- Re-run Planner (update tasks.md)
- Test Owner re-confirms/adds tests

---

## Review (Review Phase)

### 1. `/devbooks:review` - Code Review (Required)

**When to Use**:
- After Apply phase completes
- Before PR merge

```
/devbooks:review <change-id>
```

**Review Scope**:
- Readability
- Dependency direction
- Consistency
- Complexity
- Code smells

**Not Discussed**: Business correctness

**MCP Enhancement**:
- CKB available: Hotspot-priority review (deep review for Top 5)

---

### 2. `/devbooks:test-review` - Test Review (Optional)

**When to Use**:
- Test quality needs special attention
- Coverage/edge cases need review

```
/devbooks:test-review <change-id>
```

**Review Scope**:
- Test coverage
- Edge cases
- Consistency with `verification.md`

---

## Archive (Archive Phase)

### 1. `/devbooks:backport` - Backfill Missing Decisions

**When to Use**: Before archive, undocumented design decisions found

---

### 2. `/devbooks:spec` - Persist to Truth Source

**When to Use**: Before archive, need to update specs/contracts to `<truth-root>`

---

### 3. `/devbooks:c4` - Persist to Truth Source

**When to Use**: Before archive, update/verify `<truth-root>/architecture/c4.md`

**Archive Phase Behavior**: Updates current truth (not just Delta)

---

### 4. `/devbooks:gardener` - Spec Gardener (When spec deltas exist)

**When to Use**:
- This change produced spec deltas
- Need to merge to truth source

```
/devbooks:gardener <change-id>
```

**Operations**:
- Deduplicate/merge/categorize/delete outdated
- Only modifies `<truth-root>/**`
- Does not modify change package contents

---

## Standalone Commands (Not Part of Single Change Phase)

### `/devbooks:router` - Routing Suggestions (When unsure of next step)

**When to Use**:
- Unsure which phase you're in
- Need AI to suggest shortest closed loop

```
/devbooks:router <your requirement>
```

---

### `/devbooks:bootstrap` - Brownfield Project Initialization

**When to Use**:
- `<truth-root>` is empty
- Legacy project first adopting DevBooks

```
/devbooks:bootstrap
```

**Output**:
- Project profile
- Glossary (optional)
- Baseline specs
- Minimal verification anchors

---

### `/devbooks:entropy` - Entropy Measurement (Periodic Health Check)

**When to Use**:
- Periodic code health check
- Get quantified data before refactoring

```
/devbooks:entropy
```

**Output**: Entropy measurement report (structural/change/test/dependency entropy)

---

### `/devbooks:federation` - Cross-Repository Federation Analysis

**When to Use**:
- Change involves external API/contracts
- Multi-repo project needs downstream impact analysis

```
/devbooks:federation
```

**Prerequisite**: `.devbooks/federation.yaml` exists in project root

---

### `/devbooks:index` - Index Bootstrap

**When to Use**:
- `mcp__ckb__getStatus` shows SCIP backend unavailable
- Need to activate graph-based code understanding

```
/devbooks:index
```

**Output**: SCIP index file

---

## Typical Workflow Examples

### Small Change (bug fix)

```
1. /devbooks:proposal <bug description>
2. /devbooks:plan <change-id>
3. /devbooks:test <change-id>    # New conversation
4. /devbooks:code <change-id>    # New conversation
5. /devbooks:review <change-id>
6. /devbooks:gardener <change-id>
```

### Medium Change (new feature)

```
1. /devbooks:proposal <feature requirement>
2. /devbooks:impact <change-id>   # When cross-module
3. /devbooks:design <change-id>
4. /devbooks:spec <change-id>     # When contract changes
5. /devbooks:plan <change-id>
6. /devbooks:test <change-id>     # New conversation
7. /devbooks:code <change-id>     # New conversation
8. /devbooks:review <change-id>
9. /devbooks:gardener <change-id>
```

### Large/High-Risk Change

```
1. /devbooks:proposal <requirement>
2. /devbooks:impact <change-id>
3. /devbooks:debate <change-id>   # Triangle debate
4. /devbooks:design <change-id>
5. /devbooks:spec <change-id>
6. /devbooks:c4 <change-id>       # When architecture changes
7. /devbooks:plan <change-id>
8. /devbooks:test <change-id>     # New conversation
9. /devbooks:code <change-id>     # New conversation
10. /devbooks:review <change-id>
11. /devbooks:gardener <change-id>
```

---

## Command Summary (24 Commands)

### Core Commands (21)

| Phase | Command | Corresponding Skill |
|-------|---------|---------------------|
| Proposal | `/devbooks:proposal` | `devbooks-proposal-author` |
| | `/devbooks:impact` | `devbooks-impact-analysis` |
| | `/devbooks:challenger` | `devbooks-proposal-challenger` |
| | `/devbooks:judge` | `devbooks-proposal-judge` |
| | `/devbooks:debate` | `devbooks-proposal-debate-workflow` |
| | `/devbooks:design` | `devbooks-design-doc` |
| | `/devbooks:spec` | `devbooks-spec-contract` |
| | `/devbooks:c4` | `devbooks-c4-map` |
| | `/devbooks:plan` | `devbooks-implementation-plan` |
| Apply | `/devbooks:test` | `devbooks-test-owner` |
| | `/devbooks:code` | `devbooks-coder` |
| | `/devbooks:backport` | `devbooks-design-backport` |
| Review | `/devbooks:review` | `devbooks-code-review` |
| | `/devbooks:test-review` | `devbooks-test-reviewer` |
| Archive | `/devbooks:gardener` | `devbooks-spec-gardener` |
| | `/devbooks:delivery` | `devbooks-delivery-workflow` |
| Standalone | `/devbooks:router` | `devbooks-router` |
| | `/devbooks:bootstrap` | `devbooks-brownfield-bootstrap` |
| | `/devbooks:entropy` | `devbooks-entropy-monitor` |
| | `/devbooks:federation` | `devbooks-federation` |
| | `/devbooks:index` | `devbooks-index-bootstrap` |

### Backward Compatible Commands (3)

| Command | Equivalent To |
|---------|---------------|
| `/devbooks:coder` | `/devbooks:code` |
| `/devbooks:tester` | `/devbooks:test` |
| `/devbooks:reviewer` | `/devbooks:review` |
