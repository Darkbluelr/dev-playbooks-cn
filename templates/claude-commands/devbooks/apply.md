---
skill: multi-role
backward-compat: true
---

# /devbooks:apply

**Backward Compatible Command**: Execute Apply phase (Test Owner or Coder).

## Purpose

This command is a backward compatible command, maintaining consistency with the original `/devbooks:apply` invocation.

## New Version Alternative

Recommended direct commands:

| Role | New Command | Description |
|------|--------|------|
| Test Owner | `/devbooks:test` | Test owner, produces verification.md |
| Coder | `/devbooks:code` | Implementation owner, implements per tasks.md |

## Parameters

- `--role test-owner`: Execute as Test Owner role
- `--role coder`: Execute as Coder role

## Role Isolation

Test Owner and Coder must be executed in separate sessions.

## Migration Guide

```
Old Command                    New Command
/devbooks:apply --role test-owner  →  /devbooks:test
/devbooks:apply --role coder       →  /devbooks:code
```
