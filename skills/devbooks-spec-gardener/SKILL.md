---
name: devbooks-spec-gardener
description: "devbooks-spec-gardener: Pre-archive pruning and maintenance of <truth-root> (deduplicate/merge/delete obsolete/directory organization/consistency fixes), preventing specs accumulation from getting out of control. Use when user says 'spec gardener/specs dedup merge/pre-archive cleanup/clean obsolete specs', or during DevBooks archive/pre-archive wrap-up."
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks: Spec Gardener

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

## Execution Method

1) First read and follow: `_shared/references/universal-gate-protocol.md` (verifiability + structural quality gates).
2) Execute strictly according to full prompt: `references/spec-gardener-prompt.md`.

---

## Context Awareness

This Skill automatically detects context before execution and selects appropriate maintenance mode.

Detection rules reference: `skills/_shared/context-detection-template.md`

### Detection Flow

1. Detect `<truth-root>/` directory status
2. If change-id provided, check change package archive conditions
3. Detect duplicate/obsolete specs

### Modes Supported by This Skill

| Mode | Trigger Condition | Behavior |
|------|-------------------|----------|
| **Archive mode** | change-id provided and gates passed | Merge change package artifacts into truth-root |
| **Maintenance mode** | No change-id | Execute dedup, cleanup, organization operations |
| **Check mode** | With --dry-run parameter | Only output suggestions, no actual modifications |

### Detection Output Example

```
Detection Result:
- truth-root: exists, contains 12 spec files
- Change package: exists, all gates green
- Operating mode: Archive mode
```

---

## MCP Enhancement

This Skill does not depend on MCP services, no runtime detection needed.

MCP enhancement rules reference: `skills/_shared/mcp-enhancement-template.md`
