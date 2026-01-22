# audit-tools

---
capability: audit-tools
version: 1.1
status: Active
owner: devbooks-spec-gardener
last_verified: 2026-01-11
freshness_check: 3 Months
source_change: harden-devbooks-quality-gates
---

## Purpose

Define the behavior specification for DevBooks audit tools, including full scan, progress dashboard, script help documentation, and static checks.

## Requirements

### Requirement: REQ-AT-001 Full Audit Scan

**Description**: The system MUST provide a full scan tool to improve audit accuracy.

**Priority**: P1 (Important)

**Acceptance Criteria**:
- `audit-scope.sh` must scan all files in the specified directory
- Must output file count, line count, complexity metrics
- Must output hotspot file list (high modification frequency + high complexity)
- Scan result deviation must be < 1.5x (compared to manual sampling)

#### Scenario: SC-AT-001-01 Full Scan Output

- **Given**: Target directory contains 100 files
- **When**: Execute `audit-scope.sh <dir>`
- **Then**: Output includes: total file count, code line count, hotspot list

#### Scenario: SC-AT-001-02 Scan Accuracy Verification

- **Given**: Manual sampling statistics of 10 files
- **When**: Compare with `audit-scope.sh` output
- **Then**: Deviation < 1.5x

---

### Requirement: REQ-AT-002 Progress Visualization Dashboard

**Description**: The system MUST provide a change package progress visualization tool.

**Priority**: P1 (Important)

**Acceptance Criteria**:
- `progress-dashboard.sh <change-id>` must output a structured dashboard
- Dashboard must include three sections: task completion rate, role status, evidence status
- Output format must be Markdown
- JSON output must use `true/false` (not `yes/no`)

#### Scenario: SC-AT-002-01 Dashboard Output Format

- **Given**: Change package exists
- **When**: Execute `progress-dashboard.sh <change-id>`
- **Then**: Output includes "## Task Completion Rate" section, "## Role Status" section, "## Evidence Status" section

#### Scenario: SC-AT-002-02 Dashboard Data Accuracy

- **Given**: `tasks.md` has 10 tasks, 8 completed
- **When**: Execute dashboard generation
- **Then**: Task completion rate shows "80% (8/10)"

---

### Requirement: REQ-AT-003 Script Help Documentation

**Description**: The system MUST provide help documentation for all new scripts.

**Priority**: P0 (Required)

**Acceptance Criteria**:
- All new `.sh` scripts must support `--help` parameter
- Help output must include: usage, parameter description, examples
- Help output must return exit code 0

#### Scenario: SC-AT-003-01 Help Parameter Support

- **Given**: New script `handoff-check.sh`
- **When**: Execute `handoff-check.sh --help`
- **Then**: Output usage instructions with exit code 0

#### Scenario: SC-AT-003-02 All New Scripts Support Help

- **Given**: Check all new scripts
- **When**: Execute `<script> --help`
- **Then**: Each script outputs usage instructions and returns exit code 0

---

### Requirement: REQ-AT-004 Static Check Pass

**Description**: The system MUST ensure all scripts pass static checks.

**Priority**: P0 (Required)

**Acceptance Criteria**:
- All `.sh` files must pass `shellcheck`
- No error-level issues allowed
- Warning-level issues should be fixed or exempted

#### Scenario: SC-AT-004-01 shellcheck Pass

- **Given**: New script
- **When**: Execute `shellcheck <script>`
- **Then**: Exit code is 0 (no errors)

#### Scenario: SC-AT-004-02 All Scripts Pass shellcheck

- **Given**: Execute `shellcheck` on all new scripts
- **When**: Check complete
- **Then**: All return exit code 0

---

## CLI Contract

### audit-scope.sh

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `<directory>` | Positional | Yes | Scan directory |
| `--format` | Option | No | Output format (markdown/json) |

### progress-dashboard.sh

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `<change-id>` | Positional | Yes | Change package ID |
| `--project-root` | Option | No | Project root directory |
| `--change-root` | Option | No | Change package root directory |
