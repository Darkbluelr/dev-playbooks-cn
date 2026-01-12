---
name: devbooks-test-owner
description: "devbooks-test-owner: As Test Owner role, converts design/specs into executable acceptance tests and traceability documentation (verification.md), emphasizing independent conversation from implementation (Coder) and establishing Red baseline first. Use when user says 'write tests/acceptance tests/traceability matrix/verification.md/Red-Green/contract tests/fitness tests', or during DevBooks apply phase as test owner."
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks: Test Owner

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

## Artifact Locations

- Test plan and traceability: `<change-root>/<change-id>/verification.md`
- Test code: According to repository conventions (e.g., `tests/**`)

---

## Output Management Constraints (Observation Masking)

Prevent large outputs from polluting context:

| Scenario | Handling Method |
|----------|-----------------|
| Test output > 50 lines | Keep only first and last 10 lines + failure summary |
| Red baseline logs | Save to `evidence/red-baseline/`, only reference path in conversation |
| Green evidence logs | Save to `evidence/green-final/`, only reference path in conversation |
| Large test case lists | Use table summary, don't paste item by item |

**Example**:
```
Bad: Paste 500 lines of test output
Good: Red baseline established, 3 tests failed, see evidence/red-baseline/test-2024-01-05.log
      Failure summary:
      - FAIL test_pagination_invalid_page (expected 400, got 500)
      - FAIL test_pagination_boundary (assertion error)
      - FAIL test_sorting_desc (timeout)
```

---

## Test Layering Mandatory Convention (Borrowing from VS Code)

### Test Types and Naming Convention

| Test Type | File Naming | Directory Location | Expected Execution Time |
|-----------|-------------|-------------------|------------------------|
| Unit tests | `*.test.ts` / `*.test.js` | `src/**/test/` or `tests/unit/` | < 5s/file |
| Integration tests | `*.integrationTest.ts` | `tests/integration/` | < 30s/file |
| E2E tests | `*.e2e.ts` / `*.spec.ts` | `tests/e2e/` | < 60s/file |
| Contract tests | `*.contract.ts` | `tests/contract/` | < 10s/file |
| Smoke tests | `*.smoke.ts` | `tests/smoke/` | Variable |

### Test Pyramid Ratio Recommendation

```
        /\
       /E2E\        ~10% (critical user paths)
      /-----\
     /Integration\  ~20% (module boundaries)
    /-------------\
   /  Unit Tests   \ ~70% (business logic)
  /-----------------\
```

### verification.md Must Include Test Layering Information

```markdown
## Test Layering Strategy

| Type | Count | Covered Scenarios | Expected Execution Time |
|------|-------|-------------------|------------------------|
| Unit tests | X | AC-001, AC-002 | < Ys |
| Integration tests | Y | AC-003 | < Zs |
| E2E tests | Z | Critical paths | < Ws |

## Test Environment Requirements

| Test Type | Runtime Environment | Dependencies |
|-----------|---------------------|--------------|
| Unit tests | Node.js | No external dependencies |
| Integration tests | Node.js + Test DB | Docker |
| E2E tests | Browser (Playwright) | Full application |
```

### Test Isolation Requirements

- [ ] Each test must run independently, not depending on other tests' execution order
- [ ] Integration tests must have `beforeEach`/`afterEach` cleanup
- [ ] Using shared mutable state is prohibited
- [ ] Tests must clean up created files/data after completion

### Test Stability Requirements

- [ ] Committing `test.only` / `it.only` / `describe.only` is prohibited
- [ ] Flaky tests must be marked and fixed within deadline (no more than 1 week)
- [ ] Test timeouts must be reasonably set (unit tests < 5s, integration tests < 30s)
- [ ] Depending on external network is prohibited (mock all external calls)

## Execution Method

1) First read and follow: `_shared/references/universal-gate-protocol.md` (verifiability + structural quality gates).
2) Read methodology reference: `references/test-driven.md` (read when needed).
3) Read test layering guide: `references/test-layering-strategy.md`.
4) Execute strictly according to full prompt: `references/test-code-prompt.md`.
5) Template (on demand): `references/9-change-verification-traceability-template.md`.

---

## Context Awareness

This Skill automatically detects context before execution, ensuring role isolation and prerequisites are met.

Detection rules reference: `skills/_shared/context-detection-template.md`

### Detection Flow

1. Detect if `design.md` exists
2. Detect if current session has executed Coder role
3. Detect if `verification.md` already exists
4. Detect `tests/` directory status

### Modes Supported by This Skill

| Mode | Trigger Condition | Behavior |
|------|-------------------|----------|
| **First write** | `verification.md` doesn't exist | Create complete acceptance test suite |
| **Add tests** | `verification.md` exists but has `[TODO]` | Add missing test cases |
| **Red baseline verification** | Tests exist, need to confirm Red status | Run tests and record failure logs |

### Prerequisite Checks

- [ ] `design.md` exists
- [ ] Current session has not executed Coder
- [ ] Has AC-xxx for traceability

### Detection Output Example

```
Detection Result:
- Artifact existence: design.md OK, verification.md missing
- Role isolation: OK (current session has not executed Coder)
- AC count: 14
- Operating mode: First write
```

---

## MCP Enhancement

This Skill does not depend on MCP services, no runtime detection needed.

MCP enhancement rules reference: `skills/_shared/mcp-enhancement-template.md`
