# intent

---
owner: Spec Gardener
last_verified: 2026-01-10
status: Active
freshness_check: 3 Months
---

## Purpose

Describe four-category intent classification capability: upgrade from binary classification (code/non-code) to four-category classification (debug/refactor/feature/docs).

---

## Requirements

### Requirement: REQ-INT-001 Four-Category Intent Classification

The system **SHALL** support four-category intent recognition, upgrading from binary classification (code/non-code) to four-category classification.

**Four Intent Categories**:
1. **debug**: Debugging, bug fixes, error troubleshooting
2. **refactor**: Refactoring, optimization, performance improvement
3. **feature**: New features, new capabilities
4. **docs**: Documentation, comments, explanations

**Acceptance Criteria**:
- New function `get_intent_type()` returns one of the four categories
- Accuracy >= 80% (based on 20 preset queries)
- Classification logic based on keyword matching (no LLM required)

#### Scenario: SC-INT-001 Debug Intent Recognition

- **GIVEN** `devbooks-common.sh` is loaded
- **WHEN** Call `get_intent_type "fix authentication bug"`
- **THEN** Return `"debug"`

**Trace**: AC-007, SPEC-INT-001 CT-INT-001

---

### Requirement: REQ-INT-002 Backward Compatibility

The system **SHALL** maintain backward compatibility; new functions should not break existing callers.

**Compatibility Requirements**:
- Original function `is_code_intent()` remains unchanged
- `is_code_intent()` internally calls `get_intent_type()` (refactored implementation)
- 6 existing callers do not need modification

**Acceptance Criteria**:
- All existing test cases still pass
- Existing caller behavior matches original version
- New functions can be used independently

#### Scenario: SC-INT-002 Backward Compatible is_code_intent

- **GIVEN** `devbooks-common.sh` is loaded
- **WHEN** Call `is_code_intent "fix bug"`
- **THEN** Return true (debug belongs to code intent)

**Trace**: AC-008, SPEC-INT-001 CT-INT-002

---

### Requirement: REQ-INT-003 Keyword Rules

The system **SHALL** perform four-category classification based on clear keyword rules, easy to understand and maintain.

**Keyword Rules**:

| Category | Keywords (regex) | Priority |
|----------|------------------|----------|
| **debug** | `debug\|fix\|bug\|error\|issue\|problem\|crash\|fail` | 1 (highest) |
| **refactor** | `refactor\|optimize\|improve\|performance\|clean\|simplify` | 2 |
| **docs** | `doc\|comment\|readme\|explain\|example\|guide` | 3 |
| **feature** | Default (does not match any of the above) | 4 (lowest) |

**Acceptance Criteria**:
- Keyword rules written in comments
- Support case-insensitive matching
- Match by priority from high to low (debug > refactor > docs > feature)

#### Scenario: SC-INT-003 Priority Matching

- **GIVEN** Input contains keywords from multiple categories "fix and refactor module"
- **WHEN** Call `get_intent_type`
- **THEN** Return `"debug"` (highest priority)

**Trace**: SPEC-INT-001 CT-INT-003

---

### Requirement: REQ-INT-004 Caller Impact Verification

The system **SHALL** verify compatibility of 6 existing callers.

**Callers**:
1. `.claude/hooks/context-inject.sh`
2. (Other scripts using `is_code_intent`)

**Acceptance Criteria**:
- Each caller passes regression testing
- Optional: Some callers use `get_intent_type()` for enhanced functionality
- No breaking changes

#### Scenario: SC-INT-004 Caller Regression Test

- **GIVEN** `context-inject.sh` Hook uses `is_code_intent`
- **WHEN** Hook executes
- **THEN** Behavior matches pre-update version

**Trace**: SPEC-INT-001 CT-INT-004

---

### Requirement: REQ-INT-005 Test Coverage

The system **SHALL** provide adequate test coverage for four-category intent classification.

**Test Requirements**:
- Intent classification test cases >= 4 (approval condition, at least 1 per category)
- Accuracy test: 20 preset queries with accuracy >= 80%
- Boundary tests: empty string, special characters, mixed keywords

#### Scenario: SC-INT-005 Accuracy Test

- **GIVEN** 20 preset queries and expected results
- **WHEN** Run accuracy test
- **THEN** Accuracy >= 80%

**Trace**: SPEC-INT-001 CT-INT-005

---

## Data-Driven Examples

### Intent Classification Reference Table

| Query Example | Expected Result | Matched Keywords |
|---------------|-----------------|------------------|
| `"fix authentication bug"` | debug | fix, bug |
| `"debug network issue"` | debug | debug, issue |
| `"refactor auth module"` | refactor | refactor |
| `"optimize query performance"` | refactor | optimize, performance |
| `"add OAuth support"` | feature | None (default) |
| `"implement rate limiting"` | feature | None (default) |
| `"update API documentation"` | docs | doc |
| `"write user guide"` | docs | guide |

### is_code_intent Mapping Rules

| Intent Type | is_code_intent Return Value | Description |
|-------------|----------------------------|-------------|
| debug | true | Code related |
| refactor | true | Code related |
| feature | true | Code related |
| docs | false | Non-code related |

### Boundary Case Handling

| Input | Expected Result | Description |
|-------|-----------------|-------------|
| `""` | feature | Empty string default |
| `"   "` | feature | Whitespace default |
| `"!@#$%^&*()"` | feature | Special characters default |
| `"FIX BUG"` | debug | Case insensitive |

### Function Interface

#### get_intent_type() (new)

```bash
# Get query intent type (four-category)
# Usage: intent=$(get_intent_type "fix authentication bug")
# Returns: debug | refactor | feature | docs
get_intent_type() {
  local query="$1"
  # Implementation in tools/devbooks-common.sh
}
```

#### is_code_intent() (refactored)

```bash
# Determine if query is code-related intent (backward compatible)
# Usage: if is_code_intent "query"; then ...; fi
# Returns: 0 (code intent) or 1 (non-code intent)
is_code_intent() {
  local intent=$(get_intent_type "$1")
  [ "$intent" != "docs" ]
}
```

---

*Spec created by boost-local-intelligence change package (2026-01-10), archived by Spec Gardener*
