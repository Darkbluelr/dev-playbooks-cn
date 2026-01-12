# MCP Enhancement Template

> This template is referenced by each SKILL.md to define the standard section format for MCP runtime detection and graceful degradation strategies.

---

## Core Principles

1. **2s timeout**: All MCP calls must return within 2s, otherwise considered unavailable
2. **Graceful degradation**: When MCP is unavailable, Skill continues executing basic functionality without blocking
3. **Silent detection**: Detection process is transparent to users, only outputs notification on degradation

---

## Standard Section Format

Each SKILL.md's "MCP Enhancement" section should include the following:

```markdown
## MCP Enhancement

This Skill supports MCP runtime enhancement, automatically detecting and enabling advanced features.

### Dependent MCP Services

| Service | Purpose | Timeout |
|---------|---------|---------|
| `mcp__ckb__getStatus` | Detect CKB index availability | 2s |
| `mcp__ckb__getHotspots` | Get hotspot files | 2s |

### Detection Flow

1. Call `mcp__ckb__getStatus` (2s timeout)
2. If successful -> Enable enhanced mode
3. If timeout or failure -> Degrade to basic mode

### Enhanced Mode vs Basic Mode

| Feature | Enhanced Mode | Basic Mode |
|---------|---------------|------------|
| Hotspot detection | CKB real-time analysis | Git history statistics |
| Impact analysis | Symbol-level references | File-level grep |
| Call graph | Precise call chain | Unavailable |

### Degradation Notice

When MCP is unavailable, output the following notice:

```
Warning: CKB unavailable (timeout or not configured), using basic mode.
To enable enhanced features, run /devbooks:index to generate index.
```
```

---

## Classification by Skill

### Skills Without MCP Dependency

The following Skills do not depend on MCP and do not need MCP enhancement section:

- devbooks-design-doc (pure document generation)
- devbooks-implementation-plan (pure plan generation)
- devbooks-proposal-author (pure document generation)
- devbooks-proposal-challenger (pure review)
- devbooks-proposal-judge (pure judgment)
- devbooks-proposal-debate-workflow (workflow orchestration)
- devbooks-design-backport (document backport)
- devbooks-spec-gardener (file organization)
- devbooks-test-reviewer (test review)

For these Skills, the MCP enhancement section should state:

```markdown
## MCP Enhancement

This Skill does not depend on MCP services, no runtime detection needed.
```

### Skills With MCP Dependency

The following Skills depend on MCP and need complete MCP enhancement section:

| Skill | MCP Dependency | Enhanced Feature |
|-------|----------------|------------------|
| devbooks-coder | mcp__ckb__getHotspots | Hotspot file warning |
| devbooks-code-review | mcp__ckb__getHotspots | Hotspot file highlighting |
| devbooks-impact-analysis | mcp__ckb__analyzeImpact, findReferences | Precise impact analysis |
| devbooks-brownfield-bootstrap | mcp__ckb__* | COD model generation |
| devbooks-index-bootstrap | mcp__ckb__getStatus | Index status detection |
| devbooks-federation | mcp__ckb__*, mcp__github__* | Cross-repository analysis |
| devbooks-router | mcp__ckb__getStatus | Index availability detection |
| devbooks-c4-map | mcp__ckb__getArchitecture | Module dependency graph |
| devbooks-spec-contract | mcp__ckb__findReferences | Reference detection |
| devbooks-entropy-monitor | mcp__ckb__getHotspots | Hotspot trend analysis |
| devbooks-delivery-workflow | mcp__ckb__getStatus | Index detection |
| devbooks-test-owner | mcp__ckb__analyzeImpact | Test coverage analysis |

---

## Detection Code Example

### Bash Detection Script

```bash
#!/bin/bash
# mcp-detect.sh - MCP availability detection

TIMEOUT=2

# Detect CKB
check_ckb() {
  # Simulate MCP call (actually executed by Claude Code)
  # If no response within 2s, return degraded status
  echo "Warning: CKB detection needs to be executed in Claude Code environment"
}

# Output detection result
detect_mcp() {
  local ckb_status="unknown"

  # Check if index.scip file exists (file-level detection)
  if [ -f "index.scip" ]; then
    ckb_status="available (file-based)"
  else
    ckb_status="unavailable"
  fi

  echo "MCP Detection Result:"
  echo "- CKB Index: $ckb_status"
}

detect_mcp
```

---

## Notes

1. **Do not add non-existent MCP tools in SKILL.md frontmatter**
2. **Timeout detection should be done at the start of Skill execution, do not detect multiple times**
3. **After degradation, do not repeat notices, only output once on first detection**
4. **Enhanced features are optional, basic features must be fully functional**
