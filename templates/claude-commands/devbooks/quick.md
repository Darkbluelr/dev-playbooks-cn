---
skill: multi-skill
backward-compat: true
---

# /devbooks:quick

**Backward Compatible Command**: Quick mode (small changes).

## Purpose

This command is a backward compatible command, maintaining consistency with the original `/devbooks:quick` invocation.

Suitable for small changes, skipping some workflow steps.

## New Version Alternative

Recommended to use Router for complete routing suggestions:

```
/devbooks:router
```

Router will automatically recommend the shortest path based on the change scope.

## Quick Mode Constraints

- Only for single file or minimal file changes
- No external API changes
- No architectural boundary changes
- No data model changes

## Boundary Check

If changes exceed quick mode boundaries, it will automatically suggest switching to the full workflow.

## Migration Guide

```
Old Command           New Command
/devbooks:quick  →  /devbooks:router (will auto-recommend quick path)
```
