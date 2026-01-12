# Project Constitution

> This document defines the project's inviolable principles (Global Inviolable Principles).
> All AI assistants and developers must adhere to these principles before executing any operation.

---

## Part Zero: Mandatory Directives

**Before executing any Skill or operation, you must:**

1. Read and understand this constitution document
2. Confirm the operation does not violate any GIP principles
3. Stop immediately and report if there is a conflict

---

## Global Inviolable Principles (GIP)

### GIP-01: Role Isolation Principle

**Rule**: Test Owner and Coder must execute in independent conversations/independent instances.

**Rationale**:
- Prevent cognitive contamination between tests and implementation
- Ensure the integrity of the Red-Green cycle
- Avoid the anti-pattern of "writing tests and modifying tests yourself"

**Violation Consequence**: Change package cannot be archived.

---

### GIP-02: Tests Are Immutable Principle

**Rule**: The Coder role is prohibited from modifying any files under the `tests/**` directory.

**Rationale**:
- Tests are the executable form of specifications
- Modifying tests is equivalent to modifying specs, requiring design-level decisions
- Ensure independence of acceptance criteria

**Exception**: If tests need modification, must hand back to Test Owner.

---

### GIP-03: Design First Principle

**Rule**: Code implementation must trace back to AC-xxx in design documents.

**Rationale**:
- Ensure all code changes have a clear business purpose
- Support full traceability: Design -> Tasks -> Tests -> Code
- Prevent "ghost features" and unauthorized changes

**Verification Method**: `ac-trace-check.sh` checks coverage.

---

### GIP-04: Single Truth Source Principle

**Rule**: `specs/` is the only source of truth for system behavior.

**Rationale**:
- Avoid inconsistencies caused by specs scattered in multiple places
- Ensure all roles reference the same source
- Support incremental synchronization and conflict detection

**Operational Constraints**:
- Spec deltas in change packages must go through stage -> promote process
- Direct modification of `specs/` directory is prohibited

---

## Escape Hatches

> The following situations may temporarily bypass the above principles, but must be documented and traceable.

### EH-01: Emergency Fix

**Applicable Scenario**: Production environment has serious failures requiring emergency fixes.

**Process**:
1. Document emergency fix reason in `evidence/`
2. Mark with `[EMERGENCY]` prefix
3. Complete the full change package afterwards

### EH-02: Prototype Validation

**Applicable Scenario**: Technical approach is uncertain, needs quick validation.

**Constraints**:
- Code must be placed in `prototype/` directory
- Prohibited from directly merging into production code
- Promote through formal process after validation is complete

### EH-03: Manual Adjudication

**Applicable Scenario**: Rule conflicts or edge cases require human judgment.

**Process**:
1. Document decision points in `proposal.md`
2. Signed confirmation by project owner
3. Update Decision Log

---

## Constitution Amendment Process

1. Any modifications to this constitution must go through a formal change proposal
2. Change proposals need to go through Challenger questioning and Judge adjudication
3. Constitution changes have P0 priority, requiring confirmation from all core members

---

**Constitution Version**: v1.0.0
**Last Updated**: {{DATE}}
