# Project Context

> This document describes the project's technology stack, conventions, and domain context.
> For constitutional rules, please refer to `constitution.md`.

---

## Purpose

<!-- Describe your project purpose here -->

## Technology Stack

- **Primary Language**: <!-- e.g., TypeScript, Python, Go -->
- **Framework**: <!-- e.g., React, Django, Gin -->
- **Database**: <!-- e.g., PostgreSQL, MongoDB -->
- **Configuration Format**: YAML / JSON
- **Documentation Format**: Markdown
- **Version Control**: Git

## Project Conventions

### Code Style

<!-- Describe your code style requirements -->

### Architecture Patterns

- **Configuration Discovery**: All Skills discover configuration through `config-discovery.sh`
- **Constitution First**: Load `constitution.md` before executing any operation
- **Three-Layer Sync**: Draft -> Staged -> Truth

### Testing Strategy

- **Unit Tests**: <!-- e.g., Jest, pytest, go test -->
- **Coverage Target**: 80%
- **Red-Green Cycle**: Test Owner produces Red baseline first, Coder makes it Green

### Git Workflow

- **Main Branch**: `main` / `master`
- **Change Branch**: `change/<change-id>`
- **Commit Format**: `<type>: <subject>`
  - type: feat, fix, refactor, docs, test, chore

## Domain Context

### Core Concepts

| Term | Definition |
|------|------|
| Truth Root | Root directory of the truth source, stores final versions of specs and designs |
| Change Root | Root directory for change packages, stores all artifacts for each change |
| Spec Delta | Spec increments, describing modifications to specs from changes |
| AC-ID | Acceptance Criteria Identifier, format `AC-XXX` |
| GIP | Global Inviolable Principle |

### Role Definitions

| Role | Responsibility | Constraints |
|------|------|------|
| Design Owner | Produce What/Constraints + AC-xxx | Prohibited from writing implementation steps |
| Spec Owner | Produce spec delta | - |
| Planner | Derive tasks from design | Must not reference tests/ |
| Test Owner | Derive tests from design/specs | Must not reference tasks/ |
| Coder | Implement according to tasks | Prohibited from modifying tests/ |
| Reviewer | Code review | Cannot modify tests, cannot modify design |

## Important Constraints

1. **Role Isolation**: Test Owner and Coder must work in independent conversations
2. **Tests Are Immutable**: Coder is prohibited from modifying tests/
3. **Design First**: Code must trace back to AC-xxx
4. **Single Truth Source**: specs/ is the only authority

## External Dependencies

<!-- List project external dependencies -->

---

## Directory Root Mapping

| Path | Purpose |
|------|------|
| `dev-playbooks/` | DevBooks management directory (centralized) |
| `dev-playbooks/constitution.md` | Project Constitution |
| `dev-playbooks/project.md` | This file |
| `dev-playbooks/specs/` | Truth source |
| `dev-playbooks/changes/` | Change packages |
| `dev-playbooks/scripts/` | Project-level scripts (optional override) |

---

**Document Version**: v1.0.0
**Last Updated**: {{DATE}}
