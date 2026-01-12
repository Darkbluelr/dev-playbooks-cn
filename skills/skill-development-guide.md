# DevBooks Skill Development Guide

This document defines the design principles and constraints that must be followed when developing new Skills.

---

## 1) Core Design Principles

### 1.1 Single Responsibility Principle (UNIX Philosophy)

- **Each Skill does one thing**: A Skill is responsible for one clear responsibility, do not mix multiple responsibilities
- **Pass information through the file system**: Skills exchange data through files in the `<change-root>/<change-id>/` directory, not through shared memory or session state
- **Artifacts must be plain text**: All artifacts use Markdown/JSON format for version control and human review

### 1.2 Idempotency Design Principle (Mandatory)

**Idempotency Definition**: Repeated execution of the same operation produces the same result without side effect accumulation.

| Skill Type | Idempotency Requirement | Example |
|------------|------------------------|---------|
| **Validation/Check** | Must be idempotent (no file modifications) | `change-check.sh`, `guardrail-check.sh`, `devbooks-code-review` |
| **Generation** | Must clearly define "overwrite/incremental" behavior | `change-scaffold.sh`, `devbooks-design-doc`, `devbooks-proposal-author` |
| **Modification** | Must be safely re-runnable | `devbooks-spec-gardener`, `devbooks-design-backport` |

**Validation/Check Skills Must Comply**:
- [ ] Do not modify any files (read-only operations)
- [ ] Do not modify databases, caches, or external state
- [ ] Multiple runs produce identical output (given same input)
- [ ] No partial state left on failure

**Generation Skills Must Comply**:
- [ ] Clearly declare "overwrite mode" or "incremental mode"
- [ ] Overwrite mode: Repeated runs produce same result
- [ ] Incremental mode: Repeated runs do not produce duplicate content (must detect existing content)
- [ ] Rollback to pre-run state on failure (or clearly state inability to rollback)

**Modification Skills Must Comply**:
- [ ] Backup original files before modification (or recoverable via git)
- [ ] Multiple runs do not produce cumulative side effects
- [ ] Provide "dry-run" mode to preview changes

### 1.3 Mandatory Validation-First Principle (Inspired by VS Code)

**Core Requirement**: Generation/modification Skills **must run validation** after outputting files; proceed to next step is prohibited if validation fails.

| Skill Type | Validation Requirement | Failure Handling |
|------------|----------------------|------------------|
| Code generation | Compile check (TypeScript/ESLint) | Must fix before proceeding |
| Test generation | Run tests (expected Red or Green) | Record result in verification.md |
| Config generation | Format validation (JSON/YAML schema) | Must fix before proceeding |
| Doc generation | Link check, format check | Warn but can proceed |

**Mandatory Validation Checklist**:

```markdown
## Validation-First Check (Generation/Modification Skills Must Execute)

- [ ] Run relevant validation commands immediately after file output
- [ ] Validation command output must be recorded to evidence file
- [ ] Declaring "task complete" is prohibited when validation fails
- [ ] Must attempt fix or clearly report failure reason when validation fails
- [ ] "Assuming success" is prohibited—must actually view command output
```

**Example: Validation Flow After Code Generation**

```bash
# 1. Generate code
write_code_to_file "$output_file"

# 2. Validate immediately (mandatory)
if ! npm run compile 2>&1 | tee "$evidence_dir/compile.log"; then
  echo "error: compilation failed, cannot proceed" >&2
  exit 1
fi

# 3. Run lint check
if ! npm run lint 2>&1 | tee "$evidence_dir/lint.log"; then
  echo "error: lint failed, cannot proceed" >&2
  exit 1
fi

# 4. Only proceed after validation passes
echo "ok: verification passed"
```

### 1.4 Task Output Monitoring Principle

**Requirement**: When running long tasks, must actively view output to avoid "assuming success" hallucinations.

- [ ] Background tasks must have timeout mechanism
- [ ] Must check task exit code
- [ ] Must read and analyze task output
- [ ] Declaring success based solely on "command finished executing" is prohibited

### 1.5 Truth Source Separation Principle

- **Read-only truth source**: Skills can only read `<truth-root>/`, cannot directly modify (except archiving Skills like `spec-gardener`)
- **Write to workspace**: Skills write to `<change-root>/<change-id>/`
- **Archive means merge**: Archiving operation merges workspace content back to truth source

### 1.6 Resource Cleanup Principle (Inspired by VS Code)

**Requirement**: Clean up temporary resources regardless of success or failure.

- [ ] Temporary files must be deleted on exit
- [ ] Background processes must be terminated on exit
- [ ] Database connections must be closed on exit
- [ ] Use `trap` to ensure cleanup on abnormal exit

```bash
# Example: Using trap to ensure cleanup
cleanup() {
  rm -rf "$TEMP_DIR"
  kill "$BG_PID" 2>/dev/null || true
}
trap cleanup EXIT
```

---

## 2) Skill Directory Structure

```
skills/
└── devbooks-<skill-name>/
    ├── SKILL.md           # Skill definition (required)
    ├── references/        # Reference documentation (optional)
    │   ├── *.md           # Prompts, templates, checklists, etc.
    │   └── ...
    └── scripts/           # Executable scripts (optional)
        ├── *.sh           # Shell scripts
        └── ...
```

### 2.1 SKILL.md Template

```markdown
---
name: devbooks-<skill-name>
description: One-sentence description of the Skill's responsibility and trigger scenarios
---

# DevBooks: <Skill Name>

## Prerequisites: Directory Roots (Protocol-Agnostic)

- `<truth-root>`: Current truth directory root
- `<change-root>`: Change package directory root

## Responsibility

<Describe what this Skill does>

## Idempotency Declaration

- Type: Validation / Generation / Modification
- Idempotent: Yes / No (explain reason)
- Re-run behavior: <Describe behavior of multiple runs>

## Reference Documentation

- `references/<doc-name>.md`

## Scripts (if any)

- `scripts/<script-name>.sh`
```

---

## 3) Script Development Standards

### 3.1 Required Parameters

All scripts must support the following standard parameters:

```bash
--project-root <path>    # Project root directory (required)
--change-root <path>     # Change package directory root (required)
--truth-root <path>      # Truth source directory root (required)
--dry-run                # Preview mode, no actual modifications (recommended)
--help                   # Display help information (required)
```

### 3.2 Exit Code Standards

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Parameter error |
| 3 | Precondition not met |
| 4 | Validation failed (for check scripts) |

### 3.3 Output Standards

- Normal output to stdout
- Error messages to stderr
- Support `--json` for machine-readable output (recommended)
- Do not use ANSI color codes (unless TTY detected)

---

## 4) Quality Checklist

New Skills must pass the following checks before submission:

- [ ] **Single Responsibility**: Skill does one thing
- [ ] **Idempotency Declaration**: SKILL.md clearly declares idempotency behavior
- [ ] **Truth Source Separation**: Does not directly modify `<truth-root>/` (unless archiving Skill)
- [ ] **Complete Parameters**: Scripts support standard parameters (`--project-root`, `--change-root`, `--truth-root`)
- [ ] **Help Information**: `--help` outputs clear usage instructions
- [ ] **Correct Exit Codes**: Uses standard exit codes
- [ ] **No Side Effects**: Validation Skills do not modify files
- [ ] **Testable**: Provides test cases or verification method

---

## 5) Example: Idempotency Implementation for Validation Skill

```bash
#!/usr/bin/env bash
# change-check.sh - Validation script example

set -euo pipefail

# Validation script: read-only operations, do not modify any files
readonly MODE="readonly"

check_change() {
    local change_id="$1"
    local change_path="$CHANGE_ROOT/$change_id"

    # Read-only operation: check if files exist
    [[ -f "$change_path/proposal.md" ]] || return 4
    [[ -f "$change_path/design.md" ]] || return 4
    [[ -f "$change_path/tasks.md" ]] || return 4

    # Read-only operation: validate content format
    grep -q "^## Acceptance Criteria" "$change_path/design.md" || return 4

    return 0
}

# Multiple runs produce same output, no side effects
check_change "$1"
```
