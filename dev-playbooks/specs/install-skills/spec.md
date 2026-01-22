# install-skills

---
owner: devbooks-spec-gardener
last_verified: 2026-01-08
status: Draft
freshness_check: 3 Months
---

## Purpose

Describe the current capabilities and acceptance scenarios for Skills installation and Prompts installation scripts.

## Requirements

### Requirement: Provide Installation Script to Install devbooks-* Skills to Claude Code and Codex CLI

The system MUST provide an installation script to install `skills/devbooks-*` to the local directories of Claude Code and Codex CLI.

#### Scenario: Default Installation to Both Targets
- **When** Execute `./scripts/install-skills.sh` in the repository root
- **Then** `skills/devbooks-*` will be installed to `~/.claude/skills/` and `$CODEX_HOME/skills/`
- **Evidence**: `scripts/install-skills.sh`

### Requirement: Installation Script Supports Claude-Only or Codex-Only Installation

The system MUST support installing Skills to Claude Code only or Codex CLI only through parameters.

#### Scenario: Claude-Only Installation
- **When** Execute `./scripts/install-skills.sh --claude-only`
- **Then** Only update `~/.claude/skills/` directory
- **Evidence**: `scripts/install-skills.sh`

### Requirement: Installation Script Supports Optional Codex Prompts Installation

The system MUST support optionally installing Codex Prompts to the local prompts directory.

#### Scenario: Install Prompts Simultaneously
- **When** Execute `./scripts/install-skills.sh --with-codex-prompts`
- **Then** `prompts/devbooks-*.md` is copied to `$CODEX_HOME/prompts/`
- **Evidence**: `scripts/install-skills.sh`, `prompts/`

### Requirement: Installation Script Supports Dry-Run Preview

The system MUST support dry-run mode to preview installation operations without actually writing.

#### Scenario: Dry-Run Mode
- **When** Execute `./scripts/install-skills.sh --dry-run`
- **Then** Only output planned operations without actually writing to target directories
- **Evidence**: `scripts/install-skills.sh`
