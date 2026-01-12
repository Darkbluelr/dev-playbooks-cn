# Context Detection Template

> This template provides standardized context detection rules for all SKILL.md files.
>
> Artifact path: `skills/_shared/context-detection-template.md`

---

## Overview

Context detection is used to automatically identify the current working state, helping Skills select the correct operating mode. Detection is based on file existence and does not depend on external services.

---

## Detection Rules

### 1. Artifact Existence Detection

Detect whether key artifacts exist in the change package directory.

```bash
# Detection script example
detect_artifacts() {
  local change_root="$1"
  local change_id="$2"
  local change_dir="${change_root}/${change_id}"

  # Detect key artifacts
  local has_proposal=false
  local has_design=false
  local has_tasks=false
  local has_verification=false
  local has_specs=false

  [[ -f "${change_dir}/proposal.md" ]] && has_proposal=true
  [[ -f "${change_dir}/design.md" ]] && has_design=true
  [[ -f "${change_dir}/tasks.md" ]] && has_tasks=true
  [[ -f "${change_dir}/verification.md" ]] && has_verification=true
  [[ -d "${change_dir}/specs" ]] && has_specs=true

  echo "proposal:${has_proposal}"
  echo "design:${has_design}"
  echo "tasks:${has_tasks}"
  echo "verification:${has_verification}"
  echo "specs:${has_specs}"
}
```

### 2. Completeness Check Rules

Validate specs/ completeness by Requirement blocks.

**Completeness criteria**:
1. Each REQ must have at least one Scenario
2. Each Scenario must have Given/When/Then
3. No placeholders exist (`[TODO]`, `[TBD]`)
4. All ACs have corresponding Requirements

```bash
# Completeness check script example
# [m-001 fix] Output format consistent with tests/lib/completeness-check.sh
check_spec_completeness() {
  local spec_file="$1"

  # If file is empty or doesn't exist, consider complete
  if [[ ! -f "$spec_file" ]] || [[ ! -s "$spec_file" ]]; then
    echo "complete:no Req to validate"
    return 0
  fi

  # Check for placeholders
  if grep -qE '\[TODO\]|\[TBD\]' "$spec_file"; then
    echo "incomplete:placeholders exist"
    return 1
  fi

  # Check Requirement blocks
  local req_count=$(grep -c '^## REQ-' "$spec_file" || echo 0)
  local scenario_count=$(grep -c '^### Scenario' "$spec_file" || echo 0)

  if [[ $req_count -gt 0 && $scenario_count -eq 0 ]]; then
    echo "incomplete:REQ missing Scenario"
    return 1
  fi

  # Check Given/When/Then
  local gwt_count=$(grep -cE '^\s*-\s*(Given|When|Then)' "$spec_file" || echo 0)
  if [[ $scenario_count -gt 0 && $gwt_count -lt $((scenario_count * 3)) ]]; then
    echo "incomplete:Scenario missing complete Given/When/Then"
    return 1
  fi

  echo "complete:all validations passed"
  return 0
}
```

### 3. Current Phase Detection

Infer current phase based on existing artifacts.

| Phase | Determination Criteria |
|-------|------------------------|
| **proposal** | `proposal.md` doesn't exist, or exists but not yet judged |
| **apply** | `proposal.md` exists and judged, `design.md` exists, implementing |
| **archive** | All gates passed, ready to archive or already archived |

```bash
# Phase detection script example
detect_phase() {
  local change_dir="$1"

  # Check artifact existence
  local has_proposal=false
  local has_design=false
  local has_evidence=false

  [[ -f "${change_dir}/proposal.md" ]] && has_proposal=true
  [[ -f "${change_dir}/design.md" ]] && has_design=true
  [[ -d "${change_dir}/evidence/green-final" ]] && has_evidence=true

  # Infer phase
  if ! $has_proposal; then
    echo "proposal"
  elif $has_evidence; then
    echo "archive"
  else
    echo "apply"
  fi
}
```

### 4. Operating Mode Detection

Select Skill operating mode based on context.

| Mode | Condition | Description |
|------|-----------|-------------|
| **Create from scratch** | Target artifact doesn't exist | Create new artifact |
| **Patch mode** | Artifact exists but incomplete | Fill in missing parts |
| **Sync mode** | Artifact complete, needs sync with implementation | Check consistency and update |

```bash
# Mode detection script example
detect_mode() {
  local artifact_path="$1"
  local artifact_type="$2"  # spec | design | c4

  if [[ ! -e "$artifact_path" ]]; then
    echo "create"  # Create from scratch
    return
  fi

  # Check completeness
  case "$artifact_type" in
    spec)
      local completeness=$(check_spec_completeness "$artifact_path")
      # [m-001 fix] Use format check consistent with implementation
      if [[ "$completeness" == complete:* ]]; then
        echo "sync"  # Sync mode
      else
        echo "patch"  # Patch mode
      fi
      ;;
    design)
      if grep -qE '\[TODO\]|\[TBD\]' "$artifact_path"; then
        echo "patch"
      else
        echo "sync"
      fi
      ;;
    c4)
      if [[ -f "$artifact_path" ]]; then
        echo "update"
      else
        echo "create"
      fi
      ;;
  esac
}
```

---

## 7 Boundary Scenario Test Cases

| ID | Scenario | Input State | Expected Output | Description |
|----|----------|-------------|-----------------|-------------|
| **CD-001** | Empty change package | `change-dir/` is empty | phase=proposal, mode=create | Initial state for new change |
| **CD-002** | Only proposal | `proposal.md` exists, others empty | phase=proposal, awaiting judgment | Proposal written but not approved |
| **CD-003** | proposal + design | Both files exist | phase=apply | Design complete, entering implementation |
| **CD-004** | Incomplete specs | `specs/` exists but has `[TODO]` | mode=patch | Specs need completion |
| **CD-005** | Complete specs | `specs/` exists with no placeholders | mode=sync | Check consistency with implementation |
| **CD-006** | Gates passed | `evidence/green-final/` exists | phase=archive | Ready to archive |
| **CD-007** | c4.md doesn't exist | `specs/architecture/c4.md` doesn't exist | mode=create | Architecture diagram needs creation |

### Test Case Verification Script

```bash
#!/bin/bash
# context-detection-test.sh
# Run context detection boundary scenario tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

echo "=== Context Detection Boundary Scenario Tests ==="

# CD-001: Empty change package
echo -n "CD-001 Empty change package... "
mkdir -p "$TEST_DIR/CD-001"
phase=$(detect_phase "$TEST_DIR/CD-001")
[[ "$phase" == "proposal" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-002: Only proposal
echo -n "CD-002 Only proposal... "
mkdir -p "$TEST_DIR/CD-002"
touch "$TEST_DIR/CD-002/proposal.md"
phase=$(detect_phase "$TEST_DIR/CD-002")
[[ "$phase" == "proposal" || "$phase" == "apply" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-003: proposal + design
echo -n "CD-003 proposal + design... "
mkdir -p "$TEST_DIR/CD-003"
touch "$TEST_DIR/CD-003/proposal.md"
touch "$TEST_DIR/CD-003/design.md"
phase=$(detect_phase "$TEST_DIR/CD-003")
[[ "$phase" == "apply" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-004: Incomplete specs
echo -n "CD-004 Incomplete specs... "
mkdir -p "$TEST_DIR/CD-004/specs"
echo "[TODO] To be completed" > "$TEST_DIR/CD-004/specs/spec.md"
mode=$(detect_mode "$TEST_DIR/CD-004/specs/spec.md" "spec")
[[ "$mode" == "patch" ]] && echo "PASS" || echo "FAIL (got: $mode)"

# CD-005: Complete specs
echo -n "CD-005 Complete specs... "
mkdir -p "$TEST_DIR/CD-005/specs"
cat > "$TEST_DIR/CD-005/specs/spec.md" << 'EOF'
## REQ-001 Sample Requirement
### Scenario: Normal flow
- Given precondition
- When action executed
- Then expected result
EOF
mode=$(detect_mode "$TEST_DIR/CD-005/specs/spec.md" "spec")
[[ "$mode" == "sync" ]] && echo "PASS" || echo "FAIL (got: $mode)"

# CD-006: Gates passed
echo -n "CD-006 Gates passed... "
mkdir -p "$TEST_DIR/CD-006/evidence/green-final"
touch "$TEST_DIR/CD-006/proposal.md"
phase=$(detect_phase "$TEST_DIR/CD-006")
[[ "$phase" == "archive" ]] && echo "PASS" || echo "FAIL (got: $phase)"

# CD-007: c4.md doesn't exist
echo -n "CD-007 c4.md doesn't exist... "
mkdir -p "$TEST_DIR/CD-007/specs/architecture"
mode=$(detect_mode "$TEST_DIR/CD-007/specs/architecture/c4.md" "c4")
[[ "$mode" == "create" ]] && echo "PASS" || echo "FAIL (got: $mode)"

echo "=== Tests Complete ==="
```

---

## Skill Reference Method

Reference this template in SKILL.md:

```markdown
## Context Awareness

This Skill automatically detects context before execution and selects the appropriate operating mode.

Detection rules reference: `skills/_shared/context-detection-template.md`

### Detection Flow

1. Detect artifact existence
2. Check completeness
3. Infer current phase
4. Select operating mode

### Modes Supported by This Skill

| Mode | Trigger Condition | Behavior |
|------|-------------------|----------|
| Create from scratch | <condition> | <behavior> |
| Patch mode | <condition> | <behavior> |
| Sync mode | <condition> | <behavior> |
```

---

## Detection Output Format

Standardized detection result output:

```
Detection Result:
- Artifact existence: <exists/doesn't exist>
- Completeness: <complete/incomplete (missing items: ...)>
- Current phase: <proposal/apply/archive>
- Operating mode: <create from scratch/patch/sync>
```

---

**Document Version**: v1.0.0
**Last Updated**: 2026-01-12
