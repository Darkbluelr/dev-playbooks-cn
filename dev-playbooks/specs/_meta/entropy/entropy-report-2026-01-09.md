# System Entropy Report

> Generated: 2026-01-09T12:00:00Z
> Project Path: /Users/ozbombor/Projects/dev-playbooks
> Analysis Period: 30 days

---

## Overview

| Dimension | Health Status | Key Metrics | Description |
|-----------|---------------|-------------|-------------|
| Structural Entropy | :red_circle: | File Lines P95: **750** | Exceeds threshold (>500) |
| Change Entropy | :green_circle: | Hotspot File Ratio: **0/156 = 0%** | Healthy (<10%) |
| Test Entropy | :red_circle: | Test/Code Ratio: **403/10112 = 0.04** | Severely Insufficient (<0.5) |
| Dependency Entropy | :green_circle: | Outdated Dependency Ratio: **0%** | Healthy |

**Healthy Dimensions**: 2/4 | **Alerts**: 2

---

## A) Structural Entropy

> Source: Static Code Analysis

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| File Lines P95 | **750** | < 500 | :red_circle: Exceeds threshold |
| File Lines Average | ~200 | - | :white_circle: |
| Cyclomatic Complexity Average | N/A | < 10 | :white_circle: Not collected |
| Cyclomatic Complexity P95 | N/A | < 20 | :white_circle: Not collected |

### Large Files (>300 lines)

| File | Lines | Recommendation |
|------|-------|----------------|
| `mcp/devbooks-mcp-server/src/index.ts` | 750 | :red_circle: Split into multiple modules |
| `tools/devbooks-embedding.sh` | 692 | :yellow_circle: Consider splitting |
| `mcp/devbooks-mcp-server/dist/index.js` | 654 | :white_circle: Build artifact, ignore |
| `setup/global-hooks/augment-context-global.sh` | 541 | :yellow_circle: Consider splitting |
| `skills/devbooks-delivery-workflow/scripts/change-check.sh` | 528 | :yellow_circle: Consider splitting |
| `skills/devbooks-delivery-workflow/scripts/guardrail-check.sh` | 518 | :yellow_circle: Consider splitting |

**Recommendation**: Prioritize splitting `mcp/devbooks-mcp-server/src/index.ts` (750 lines), can be split by functional modules into:
- `handlers/` - Various request handlers
- `tools/` - Utility functions
- `types.ts` - Type definitions

---

## B) Change Entropy

> Source: Git History Analysis (past 30 days)

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| Hotspot File Count | 0 / 156 | - | :green_circle: |
| Hotspot File Ratio | **0%** | < 10% | :green_circle: Healthy |
| Highest Modification Frequency | 5 times | - | :white_circle: |

### Frequently Modified Files (within 30 days)

| File | Modification Count | Risk Level |
|------|--------------------|------------|
| `User Manual.md` | 5 | :white_circle: Documentation |
| `setup/README.md` | 4 | :white_circle: Documentation |
| `setup/template/DevBooks Integration Template...md` | 4 | :white_circle: Documentation |
| `skills/devbooks-spec-delta/SKILL.md` | 3 | :white_circle: Configuration |
| `.claude/hooks/augment-context.sh` | 3 | :yellow_circle: Script |

**Hotspot Definition**: Files modified more than 5 times within the analysis period

**Conclusion**: No hotspot files (modifications >5), change entropy is healthy.

---

## C) Test Entropy

> Source: Test File Statistics

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| Test Code Lines | **403** | - | :white_circle: |
| Production Code Lines | **10,112** | - | :white_circle: |
| Test/Code Ratio | **0.04** | > 0.5 | :red_circle: Severely insufficient |
| Flaky Test Ratio | N/A | < 0.01 | :white_circle: Not collected |
| Code Coverage | N/A | > 0.7 | :white_circle: Not collected |

### Test File List

| File | Lines | Type |
|------|-------|------|
| `tests/enhance-code-intelligence/test_performance.bats` | 172 | BATS |
| `tests/enhance-code-intelligence/test_hotspot.bats` | 133 | BATS |
| `tests/enhance-code-intelligence/test_index_detection.bats` | 98 | BATS |
| **Total** | **403** | - |

**Recommendation**: Test/code ratio is only 4%, far below the healthy threshold of 50%. Priority for adding tests:
1. :red_circle: `mcp/devbooks-mcp-server/` - 0% coverage, needs unit tests
2. :red_circle: `skills/*/scripts/` - Shell scripts need BATS tests
3. :yellow_circle: `tools/devbooks-embedding.sh` - Needs integration tests

---

## D) Dependency Entropy

> Source: Dependency Analysis

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| npm Dependencies | 0 | - | :white_circle: |
| Outdated Dependencies | 0 | - | :green_circle: |
| Outdated Dependency Ratio | 0% | < 20% | :green_circle: Healthy |
| Security Vulnerabilities | 0 | = 0 | :green_circle: |

**Note**: Project is primarily Shell scripts with no external npm dependencies. MCP Server uses a separate package.json.

---

## Alert Details

- **[WARNING]** structural: file_lines_p95 (750) exceeds threshold (500)
- **[WARNING]** test: test_code_ratio (0.04) below threshold (0.5)

---

## Trend Analysis

> First collection, no historical trend data available yet

---

## Recommended Actions

### High Priority (P0)

1. **Add Tests** - Test/code ratio is only 4%, recommendations:
   - Add unit tests for `mcp/devbooks-mcp-server/src/index.ts`
   - Add BATS test coverage for `setup/global-hooks/augment-context-global.sh`
   - Target: Increase test/code ratio to 30%+

### Medium Priority (P1)

2. **Split Large Files** - `mcp/devbooks-mcp-server/src/index.ts` (750 lines):
   - Recommend creating a refactoring proposal: `/devbooks-proposal-author`
   - Split by responsibility into handlers/tools/types modules

3. **Shell Script Modularization** - 5 scripts exceed 500 lines:
   - Extract common functions to `lib/common.sh`
   - Split main logic into independent functions

### Low Priority (P2)

4. **Continuous Monitoring** - Recommend running entropy measurement weekly to track trends

---

## Quantitative Summary

| Dimension | Score | Grade |
|-----------|-------|-------|
| Structural Entropy | 60/100 | C |
| Change Entropy | 95/100 | A |
| Test Entropy | 20/100 | F |
| Dependency Entropy | 100/100 | A |
| **Overall** | **68.75/100** | **D** |

> Overall score calculation: (60+95+20+100)/4 = 68.75

---

*Report generated by DevBooks Entropy Monitor*
*Reference: "The Mythical Man-Month" Chapter 16 "No Silver Bullet" - Controlling complexity is the key to software development*
