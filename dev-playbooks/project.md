# Project Context

> This document describes the project's technology stack, conventions, and domain context.
> For constitutional rules, please refer to `constitution.md`.

---

## Purpose

DevBooks is a set of Development Playbooks that provides:
- Specification-driven development workflow
- AI-assisted code quality assurance
- Traceable change management

## Technology Stack

- **Scripting Language**: Bash (no external dependencies like yq)
- **Configuration Format**: YAML (simple key-value pairs)
- **Documentation Format**: Markdown
- **Version Control**: Git

## Project Conventions

### Code Style

- Shell scripts follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `shellcheck` for static analysis
- Function naming: `snake_case`
- Variable naming: `UPPER_SNAKE_CASE` (global) / `lower_snake_case` (local)

### Architecture Patterns

- **Configuration Discovery**: All Skills discover configuration through `config-discovery.sh`
- **Constitution First**: Load `constitution.md` before executing any operation
- **Three-Layer Sync**: Draft → Staged → Truth

### Testing Strategy

- **Unit Testing**: BATS framework
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
|------|------------|
| Truth Root | Source of truth root directory, storing final versions of specs and designs |
| Change Root | Change package root directory, storing all artifacts for each change |
| Spec Delta | Specification delta, describing spec modifications from changes |
| AC-ID | Acceptance Criteria identifier, format `AC-XXX` |
| GIP | Global Inviolable Principle |

### Role Definitions

| Role | Responsibility | Constraints |
|------|----------------|-------------|
| Design Owner | Produce What/Constraints + AC-xxx | No implementation steps |
| Spec Owner | Produce spec delta | - |
| Planner | Derive tasks from design | Must not reference tests/ |
| Test Owner | Derive tests from design/spec | Must not reference tasks/ |
| Coder | Implement according to tasks | Cannot modify tests/ |
| Reviewer | Code review | Cannot modify tests or design |

## Important Constraints

1. **Role Isolation**: Test Owner and Coder must be in separate conversations
2. **Test Immutability**: Coder cannot modify tests/
3. **Design First**: Code must trace back to AC-xxx
4. **Single Source of Truth**: specs/ is the only authority

## External Dependencies

- **CKB (Code Knowledge Base)**: Code intelligence analysis (optional)
- **DevBooks CLI**: Specification management tool (optional)
- **BATS**: Bash testing framework

---

## Directory Root Mapping

| Path | Purpose |
|------|---------|
| `dev-playbooks/` | DevBooks management directory (centralized) |
| `dev-playbooks/constitution.md` | Project constitution |
| `dev-playbooks/project.md` | This file |
| `dev-playbooks/specs/` | Source of truth |
| `dev-playbooks/changes/` | Change packages |
| `dev-playbooks/scripts/` | Project-level scripts (optional override) |

---

**Document Version**: v1.0.0
**Last Updated**: 2026-01-11
