# automation-guardrails

---
owner: devbooks-spec-gardener
last_verified: 2026-01-10
status: Draft
freshness_check: 3 Months
---

## Purpose

Describe the current capabilities and acceptance scenarios for automation guardrail related scripts and templates.

## Requirements

### Requirement: Provide CI Templates for Guardrails and COD Updates

The system MUST provide CI templates to support architecture guardrails and COD model updates.

#### Scenario: Copy CI Templates to Project
- **When** Copy `templates/ci/devbooks-guardrail.yml` and `templates/ci/devbooks-cod-update.yml` to `.github/workflows/`
- **Then** CI can execute architecture compliance checks and COD model updates
- **Evidence**: `templates/ci/README.md`, `templates/ci/devbooks-guardrail.yml`, `templates/ci/devbooks-cod-update.yml`
