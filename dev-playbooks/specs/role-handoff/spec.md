# role-handoff

---
capability: role-handoff
version: 1.1
status: Active
owner: devbooks-spec-gardener
last_verified: 2026-01-11
freshness_check: 3 Months
source_change: harden-devbooks-quality-gates
---

## Purpose

Define the behavior specification for DevBooks role handoff and environment matching checks, ensuring complete information transfer during role switches.

## Requirements

### Requirement: REQ-RH-001 Role Handoff Handshake Check

**Description**: The system MUST verify role handoff has complete handshake records.

**Priority**: P0 (Required)

**Acceptance Criteria**:
- When `handoff-check.sh` executes, must check `handoff.md` exists
- Must verify `handoff.md` contains required sections: "Handoff Information", "Handoff Content", "Confirmation Signatures"
- **Default behavior**: Must verify **all** signature items `[x]` are checked in "Confirmation Signatures" section
- **Lenient mode**: `--allow-partial` parameter allows partial signatures to pass
- If any condition is not met, must return non-zero exit code

#### Scenario: SC-RH-001-01 No Handoff Record

- **Given**: Change package switches from Test Owner to Coder
- **When**: Execute handoff check and `handoff.md` does not exist
- **Then**: Check fails, output "Missing handoff record: handoff.md does not exist"

#### Scenario: SC-RH-001-02 Handoff Without Confirmation

- **Given**: `handoff.md` exists but confirmation signatures section has no checked items
- **When**: Execute handoff check
- **Then**: Check fails, output "Handoff not confirmed: requires at least one party confirmation"

#### Scenario: SC-RH-001-03 Handoff Confirmed

- **Given**: `handoff.md` exists and all signatures `[x]` are checked in confirmation signatures section
- **When**: Execute handoff check
- **Then**: Check passes

#### Scenario: SC-RH-001-04 Multi-Role Chain Handoff

- **Given**: `handoff.md` contains multiple handoff records (Test Owner -> Coder -> Reviewer)
- **When**: Execute handoff check
- **Then**: Verify integrity of entire handoff chain

---

### Requirement: REQ-RH-002 Test Environment Matching Verification

**Description**: The system MUST verify test environment declaration exists.

**Priority**: P1 (Important)

**Acceptance Criteria**:
- When `env-match-check.sh` executes, must check `verification.md` exists
- Must verify `verification.md` contains "Test Environment Declaration" section
- If section does not exist or is empty, must return non-zero exit code
- Allow section content to be `N/A` (indicating no special environment requirements)

#### Scenario: SC-RH-002-01 No Environment Declaration

- **Given**: `verification.md` exists but has no "Test Environment Declaration" section
- **When**: Execute environment matching check
- **Then**: Check fails, output "Missing test environment declaration"

#### Scenario: SC-RH-002-02 Environment Declaration is N/A

- **Given**: `verification.md` contains "Test Environment Declaration" section with content N/A
- **When**: Execute environment matching check
- **Then**: Check passes (N/A is a valid declaration)

#### Scenario: SC-RH-002-03 Complete Environment Declaration

- **Given**: `verification.md` contains detailed test environment declaration
- **When**: Execute environment matching check
- **Then**: Check passes

---

## CLI Contract

### handoff-check.sh

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `<change-id>` | Positional | Yes | Change package ID |
| `--allow-partial` | Option | No | Allow partial signatures to pass (default requires all signatures) |
| `--project-root` | Option | No | Project root directory |
| `--change-root` | Option | No | Change package root directory |

### env-match-check.sh

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `<change-id>` | Positional | Yes | Change package ID |
| `--project-root` | Option | No | Project root directory |
| `--change-root` | Option | No | Change package root directory |
