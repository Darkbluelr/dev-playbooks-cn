# Red Baseline Summary

## Test Execution Date
2026-01-09

## Test Results Overview

| Test File | Total | Passed | Failed | Skipped |
|-----------|-------|--------|--------|---------|
| test_embedding.bats | 10 | 0 | 10 | 0 |
| test_graph_rag.bats | 11 | 1 | 10 | 0 |
| test_entropy_viz.bats | 13 | 0 | 0 | 13 |
| test_intent.bats | 16 | 2 | 14 | 0 |
| test_backward_compat.bats | 16 | 6 | 10 | 0 |
| **TOTAL** | **66** | **9** | **44** | **13** |

## Key Findings

### Features Not Implemented (Red Baseline Established)

1. **Embedding Provider (AC-001/002/003)**
   - `devbooks-embedding.sh` tool missing
   - Ollama auto-detection not implemented
   - Three-level fallback not implemented

2. **CKB Graph Traversal (AC-004/005)**
   - `graph-rag-context.sh` exists but CKB integration missing
   - `call-chain-tracer.sh` tool missing
   - Multi-hop graph traversal not implemented

3. **Entropy Visualization (AC-006)**
   - `devbooks-entropy-viz.sh` tool missing
   - All 13 tests skipped (tool not found)

4. **Intent Classification (AC-007)**
   - `get_intent_type()` function not implemented
   - Four-classification not available
   - `is_code_intent()` exists for basic code/non-code detection

5. **Backward Compatibility (AC-008)**
   - `load_config()` not implemented
   - `get_config_value()` not implemented
   - `get_hotspot_files()` function missing
   - Hook interface mostly compatible

### Partially Working Features

- `is_code_intent()` - Basic detection works
- Hook interface - Accepts arguments, pipe-friendly
- Skill directory structure - Compatible

## Evidence Files

- Individual test logs in this directory
- Full test run log: `full-test-run-*.log`

## Next Steps

Red baseline established. Tests ready for Green phase after implementation.
