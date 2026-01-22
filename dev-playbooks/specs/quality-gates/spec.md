# quality-gates

---
capability: quality-gates
version: 2.1
status: Active
owner: devbooks-spec-gardener
last_verified: 2026-01-11
freshness_check: 3 Months
source_change: harden-devbooks-quality-gates
---

## Purpose

Define the behavior specification for DevBooks quality gate checks, used to intercept false completions, enforce role boundaries, and ensure tests pass before archiving.

## Requirements

### Requirement: REQ-QG-001 Green Evidence Mandatory Check

**Description**: The system MUST verify Green evidence exists in archive mode.

**Priority**: P0 (Required)

**Acceptance Criteria**:
- When `change-check.sh --mode archive` executes, must check `evidence/green-final/` directory exists
- If directory does not exist or is empty, must return non-zero exit code and output error message
- If directory exists and contains at least one file, must pass the check

#### Scenario: SC-QG-001-01 No Green Evidence at Archive

- **Given**: Change package implementation is complete
- **When**: Execute archive check and `evidence/green-final/` does not exist
- **Then**: Check fails, output "Missing Green evidence: evidence/green-final/ does not exist"

#### Scenario: SC-QG-001-02 Green Evidence Present at Archive

- **Given**: Change package implementation is complete
- **When**: Execute archive check and `evidence/green-final/` exists and contains test logs
- **Then**: Check passes, proceed to next check

---

### Requirement: REQ-QG-002 Task Completion Rate Check

**Description**: The system MUST verify 100% task completion rate in strict mode.

**Priority**: P0 (Required)

**Acceptance Criteria**:
- When `change-check.sh --mode strict` executes, must scan `tasks.md`
- If incomplete tasks exist (`[ ]` markers), must return non-zero exit code
- If all tasks completed (`[x]` or `[X]` markers), must pass the check

#### Scenario: SC-QG-002-01 Incomplete Tasks Exist

- **Given**: `tasks.md` contains 10 tasks, 2 incomplete
- **When**: Execute strict mode check
- **Then**: Check fails, output "Task completion rate 80% (8/10), requires 100%"

#### Scenario: SC-QG-002-02 All Tasks Completed

- **Given**: `tasks.md` contains 10 tasks, all marked complete
- **When**: Execute strict mode check
- **Then**: Check passes

---

### Requirement: REQ-QG-003 Coder Role Boundary Check

**Description**: The system MUST prohibit modifying test files under Coder role.

**Priority**: P1 (Important)

**Acceptance Criteria**:
- When `change-check.sh --mode apply --role coder` executes, must check if `tests/**` has modifications
- If `tests/**` has modifications, must return non-zero exit code
- If `tests/**` has no modifications, must pass the check

#### Scenario: SC-QG-003-01 Coder Modified Test File

- **Given**: Current role is Coder
- **When**: Execute apply check and `tests/example.test.ts` has modifications
- **Then**: Check fails, output "Role violation: Coder prohibited from modifying tests/**"

#### Scenario: SC-QG-003-02 Coder Only Modified Source Code

- **Given**: Current role is Coder
- **When**: Execute apply check and only `src/**` has modifications
- **Then**: Check passes

---

### Requirement: REQ-QG-004 P0 Task Skip Approval Check

**Description**: The system MUST verify P0 task skips have approval records.

**Priority**: P1 (Important)

**Acceptance Criteria**:
- In strict mode, must scan P0 tasks in `tasks.md`
- If P0 task is skipped (`[ ]` marker) but has no `<!-- SKIP-APPROVED: <reason> -->` comment, must fail
- SKIP-APPROVED detection range: line before task, same line, or line after (three-line range detection)
- If P0 task is completed or has skip approval, must pass

#### Scenario: SC-QG-004-01 P0 Task Skipped Without Approval

- **Given**: `tasks.md` contains `- [ ] [P0] Core Feature` without approval comment
- **When**: Execute strict mode check
- **Then**: Check fails, output "P0 task skip requires approval: Core Feature"

#### Scenario: SC-QG-004-02 P0 Task Skipped With Approval

- **Given**: `tasks.md` contains P0 skip task with approval comment
- **When**: Execute strict mode check
- **Then**: Check passes (approved skip)

---

### Requirement: REQ-QG-005 Test Failure Archive Interception

**Description**: The system MUST verify all tests pass in archive mode.

**Priority**: P0 (Required)

**Acceptance Criteria**:
- Check test reports in `evidence/green-final/` (`.log`, `.tap`, `.txt` files)
- If reports contain failure records, must return non-zero exit code
- Support multi-framework failure patterns: TAP (`not ok`), Jest/pytest/Go (`FAIL:`), BATS, generic (`FAILED`)
- Exclude false positives: comment lines, success statistics (e.g., `0 tests FAIL`), table separators
- If all tests pass, must pass the check

#### Scenario: SC-QG-005-01 Green Evidence Contains Failures

- **Given**: `evidence/green-final/test-results.log` contains "FAILED: test_example"
- **When**: Execute archive check
- **Then**: Check fails, output "Test failure: cannot archive"

#### Scenario: SC-QG-005-02 Green Evidence All Passed

- **Given**: `evidence/green-final/test-results.log` only contains "PASSED" records
- **When**: Execute archive check
- **Then**: Check passes

---

### Requirement: REQ-QG-006 Mode Parameter Contract

**Description**: The system MUST support extended `--mode` and `--role` parameters.

**Priority**: P0 (Required)

**Parameter Contract**:
- `--mode proposal`: Proposal phase check
- `--mode apply`: Apply phase check, supports `--role` parameter
- `--mode archive`: Archive check (includes Green evidence check)
- `--mode strict`: Strict mode (includes task completion rate, P0 skip approval check)
- `--role coder|test-owner|reviewer`: Role boundary check

#### Scenario: SC-QG-006-01 Using Role Parameter

- **Given**: change-check.sh is updated
- **When**: Execute `change-check.sh --mode apply --role coder`
- **Then**: Script recognizes `--role` parameter and executes role boundary check
