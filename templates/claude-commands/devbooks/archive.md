---
skill: devbooks-spec-gardener
backward-compat: true
---

# /devbooks:archive

**Backward Compatible Command**: Execute archive phase.

## Purpose

This command is a backward compatible command, maintaining consistency with the original `/devbooks:archive` invocation.

Internally calls `devbooks-spec-gardener` Skill.

## New Version Alternative

Recommended direct command:

```
/devbooks:gardener
```

## Function

Pre-archive pruning and maintenance of <truth-root> (deduplication/merging, removing obsolete content, directory organization, consistency fixes) to prevent specs from accumulating out of control.

## Migration Guide

```
Old Command             New Command
/devbooks:archive  →  /devbooks:gardener
```
