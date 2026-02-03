#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-scaffold.sh <change-id> [--project-root <dir>] [--change-root <dir>] [--truth-root <dir>] [--force] [--prototype]

Creates a DevBooks change package skeleton under:
  <change-root>/<change-id>/

Defaults (can be overridden by flags or env):
  DEVBOOKS_PROJECT_ROOT: pwd
  DEVBOOKS_CHANGE_ROOT:  changes
  DEVBOOKS_TRUTH_ROOT:   specs

Options:
  --prototype   Create prototype track skeleton (prototype/src + prototype/characterization).
                Use this for "Plan to Throw One Away" exploratory work.
                Prototype code is physically isolated from production code.

Notes:
- Use --change-root and --truth-root to customize paths for your project layout.
- It writes markdown templates for proposal/design/tasks/verification and creates specs/ + evidence/ directories.
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_id="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
force=false
prototype=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --change-root)
      change_root="${2:-}"
      shift 2
      ;;
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    --prototype)
      prototype=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

# Validate change-id format: YYYYMMDD-HHMM-<verb-prefixed-description>
# 格式：日期时间-动词开头的语义描述
# 示例：20240116-1030-add-oauth2-support
validate_change_id_format() {
  local id="$1"

  # Pattern: 8 digits (date) + hyphen + 4 digits (time) + hyphen + verb-prefixed-description
  # 日期：YYYYMMDD，时间：HHMM
  if [[ ! "$id" =~ ^[0-9]{8}-[0-9]{4}-.+ ]]; then
    return 1
  fi

  # Extract datetime part for validation
  local date_part="${id:0:8}"
  local time_part="${id:9:4}"
  local desc_part="${id:14}"

  # Validate date (basic check: year 2020-2099, month 01-12, day 01-31)
  local year="${date_part:0:4}"
  local month="${date_part:4:2}"
  local day="${date_part:6:2}"

  # Remove leading zeros for numeric comparison
  year=$((10#$year))
  month=$((10#$month))
  day=$((10#$day))

  if [[ "$year" -lt 2020 || "$year" -gt 2099 ]]; then
    return 1
  fi
  if [[ "$month" -lt 1 || "$month" -gt 12 ]]; then
    return 1
  fi
  if [[ "$day" -lt 1 || "$day" -gt 31 ]]; then
    return 1
  fi

  # Validate time (hour 00-23, minute 00-59)
  local hour="${time_part:0:2}"
  local minute="${time_part:2:2}"

  hour=$((10#$hour))
  minute=$((10#$minute))

  if [[ "$hour" -lt 0 || "$hour" -gt 23 ]]; then
    return 1
  fi
  if [[ "$minute" -lt 0 || "$minute" -gt 59 ]]; then
    return 1
  fi

  # Validate description starts with a verb (common verbs)
  # 常用动词：add, fix, update, refactor, remove, improve, migrate, implement, ...
  local verb_pattern="^(feat|add|fix|update|refactor|remove|improve|migrate|implement|enable|disable|change|create|delete|modify|optimize|resolve|setup|init|configure|introduce|extract|merge|split|move|rename|deprecate|upgrade|downgrade|revert|sync|integrate|unify|standardize|simplify|extend|reduce|enhance|support|handle|validate|test|document|cleanup|prepare|finalize|complete|release|publish|deploy|hotfix|patch|bump)-"

  if [[ ! "$desc_part" =~ $verb_pattern ]]; then
    return 1
  fi

  return 0
}

if ! validate_change_id_format "$change_id"; then
  echo "error: change-id 格式无效: '$change_id'" >&2
  echo "" >&2
  echo "期望格式: YYYYMMDD-HHMM-<动词开头的语义描述>" >&2
  echo "示例: 20240116-1030-add-oauth2-support" >&2
  echo "" >&2
  echo "规则:" >&2
  echo "  - 日期: YYYYMMDD (如 20240116)" >&2
  echo "  - 时间: HHMM (如 1030 表示 10:30)" >&2
  echo "  - 描述: 必须以动词开头 (add/fix/update/refactor/...)" >&2
  echo "" >&2
  echo "常用动词: add, fix, update, refactor, remove, improve, migrate, implement" >&2
  exit 2
fi

if [[ -z "$project_root" || -z "$change_root" || -z "$truth_root" ]]; then
  usage
  exit 2
fi

change_root="${change_root%/}"
truth_root="${truth_root%/}"
project_root="${project_root%/}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# change-scaffold.sh 可以在任意 --project-root 下创建变更包，因此模板应相对脚本所在仓库定位。
repo_root="$(cd "${script_dir}/../../.." && pwd)"
templates_dir="${repo_root}/templates/dev-playbooks/changes"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

mkdir -p "${change_dir}/specs" "${change_dir}/evidence" "${change_dir}/inputs"

# P1: evidence 目录结构（必需）
mkdir -p \
  "${change_dir}/evidence/red-baseline" \
  "${change_dir}/evidence/green-final" \
  "${change_dir}/evidence/gates" \
  "${change_dir}/evidence/risks"

write_file() {
  local path="$1"
  shift || true

  if [[ -f "$path" && "$force" != true ]]; then
    echo "skip: $path"
    cat >/dev/null
    return 0
  fi

  mkdir -p "$(dirname "$path")"
  cat >"$path"
  echo "wrote: $path"
}

escape_sed_repl() {
  printf '%s' "$1" | sed -e 's/[\\/&|]/\\&/g'
}

esc_change_id="$(escape_sed_repl "$change_id")"
esc_change_root="$(escape_sed_repl "$change_root")"
esc_truth_root="$(escape_sed_repl "$truth_root")"

render_template() {
  sed \
    -e "s|__CHANGE_ID__|${esc_change_id}|g" \
    -e "s|__CHANGE_ROOT__|${esc_change_root}|g" \
    -e "s|__TRUTH_ROOT__|${esc_truth_root}|g"
}

render_productized_template() {
  # 支持 templates/dev-playbooks/changes 的两种占位符：
  # - <change-id> (Markdown)
  # - CHANGE_ID (YAML)
  sed \
    -e "s|<change-id>|${esc_change_id}|g" \
    -e "s|CHANGE_ID|${esc_change_id}|g"
}

write_from_repo_template() {
  local rel="$1"
  local out="$2"

  if [[ -f "$out" && "$force" != true ]]; then
    echo "skip: $out"
    return 0
  fi

  local src="${templates_dir}/${rel}"
  if [[ ! -f "$src" ]]; then
    return 1
  fi

  mkdir -p "$(dirname "$out")"
  render_productized_template <"$src" >"$out"
  echo "wrote: $out"
  return 0
}

# P1: Delivery 入口产物化（RUNBOOK/inputs/index/completion.contract）
# 说明：优先使用仓库模板；若缺失则继续使用旧模板生成最小可用文件。
write_from_repo_template "RUNBOOK.md" "${change_dir}/RUNBOOK.md" || true
if [[ ! -f "${change_dir}/RUNBOOK.md" ]]; then
  cat <<'EOF' | render_productized_template | write_file "${change_dir}/RUNBOOK.md"
# RUNBOOK：<change-id>

## 0) 快速开始
1. 先填写 `proposal.md` 的元数据（至少 risk_level / request_kind / intervention_level）。
2. 运行严格校验：`skills/devbooks-delivery-workflow/scripts/change-check.sh <change-id> --mode strict`

## Cover View（派生缓存，可丢弃可重建）

> NOTE：在 `risk_level=medium|high` 或 `request_kind=epic|governance` 或 `intervention_level=team|org` 的变更中，G6（`archive|strict`）会强制校验本 RUNBOOK 仍包含 `## Cover View` 与 `## Context Capsule` 两个小节标题；不要删除。

<!-- DEVBOOKS_DERIVED_COVER_VIEW:START -->
> 运行 `skills/devbooks-delivery-workflow/scripts/runbook-derive.sh <change-id> ...` 自动生成（可丢弃可重建）
<!-- DEVBOOKS_DERIVED_COVER_VIEW:END -->

## Context Capsule（≤2 页；只写索引与约束，禁止贴长日志/长输出）

<!-- DEVBOOKS_DERIVED_CONTEXT_CAPSULE:START -->
> 运行 `skills/devbooks-delivery-workflow/scripts/runbook-derive.sh <change-id> ...` 自动生成（可丢弃可重建）
<!-- DEVBOOKS_DERIVED_CONTEXT_CAPSULE:END -->

### 1) 本变更一句话目标（对齐 `completion.contract.yaml: intent.summary`）
- summary: <一句话，语义与 intent.summary 一致>

### 2) 必跑验证锚点（只列 invocation_ref；不贴输出）
- <C-xxx> <invocation_ref>

## 输入索引

- `inputs/index.md`
EOF
fi

write_from_repo_template "inputs/index.md" "${change_dir}/inputs/index.md" || true
if [[ ! -f "${change_dir}/inputs/index.md" ]]; then
  cat <<'EOF' | render_productized_template | write_file "${change_dir}/inputs/index.md"
# Input Index: <change-id>

> Goal: record references + metadata only; do not copy long documents; used for audit and traceability.

## Provided Inputs (Index)

- Request text:
- Docs/links:
- File paths:
EOF
fi

write_from_repo_template "completion.contract.yaml" "${change_dir}/completion.contract.yaml" || true
if [[ ! -f "${change_dir}/completion.contract.yaml" ]]; then
  cat <<'EOF' | render_productized_template | write_file "${change_dir}/completion.contract.yaml"
schema_version: 1.0.0
change_id: CHANGE_ID
intent:
  summary: "用一句话描述本变更的目标"
  deliverable_quality: outline
deliverables:
  - id: D-001
    kind: other
    path: path/to/deliverable
    quality: inherit
obligations:
  - id: O-001
    describes: "可验证的义务描述（可判定 Pass/Fail）"
    applies_to:
      - D-001
    severity: must
checks:
  - id: C-001
    type: custom
    invocation_ref: "描述如何执行该检查（例如脚本路径/命令/配置键/运行手册）"
    covers:
      - O-001
    artifacts:
      - evidence/gates/C-001.log
decision_locks:
  forbid_weakening_without_decision: true
EOF
fi

write_from_repo_template "state.audit.yaml" "${change_dir}/state.audit.yaml" || true
if [[ ! -f "${change_dir}/state.audit.yaml" ]]; then
  cat <<'EOF' | render_productized_template | write_file "${change_dir}/state.audit.yaml"
schema_version: 1.0.0
change_id: CHANGE_ID
state_transitions:
  - from_state: null
    to_state: pending
    reason: "scaffolded"
    evidence_refs: []
EOF
fi

write_from_repo_template "proposal.md" "${change_dir}/proposal.md" || true
if [[ ! -f "${change_dir}/proposal.md" ]]; then
  cat <<'EOF' | render_productized_template | write_file "${change_dir}/proposal.md"
---
schema_version: 1.0.0
change_id: <change-id>
request_kind: change
change_type: docs
risk_level: low
intervention_level: local
state: pending
state_reason: ""
next_action: DevBooks
epic_id: ""
slice_id: ""
ac_ids: []
truth_refs: {}
risk_flags: {}
required_gates:
  - G0
  - G1
  - G2
  - G4
  - G6
completion_contract: completion.contract.yaml
deliverable_quality: outline
approvals:
  security: ""
  compliance: ""
  devops: ""
escape_hatch: null
---

# Proposal: <change-id>

> Output location: `dev-playbooks/changes/<change-id>/proposal.md`
>
> Note: Proposal phase prohibits implementation code; only define Why/What/Impact/Risks/Validation + debate points.

## Why

- Problem:
- Goal:

## What Changes

- In scope:
- Out of scope (Non-goals):
- Impact scope (modules/capabilities/external contracts/data invariants):

## Impact

- External contracts (API/Schema/Event):
- Data and migration:
- Affected modules and dependencies:
- Testing and quality gates:
- Value Signal and Observation: none
- Value Stream Bottleneck Hypothesis: none

## Risks

- Risks:
- Degradation strategy:
- Rollback strategy:

## Validation

- Candidate acceptance anchors (tests/static checks/build/manual evidence):
- Evidence location: `dev-playbooks/changes/<change-id>/evidence/` (recommend using `change-evidence.sh <change-id> -- <command>` to collect)

## Debate Packet

- Debate points/questions requiring decision (<=7 items):

## Decision Log

- Decision Status: Pending
- Decision summary:
- Questions requiring decision:
EOF
fi

 cat <<'EOF' | render_template | write_file "${change_dir}/design.md"
# Design: __CHANGE_ID__

> Output location: `__CHANGE_ROOT__/__CHANGE_ID__/design.md`
>
> Only write What/Constraints + AC-xxx; prohibit implementation steps and function body code.

## Background and Current State

- Current behavior (observable facts):
- Main constraints (performance/security/compatibility/dependency direction):

## Problem Context

- What is broken today (observable symptoms)?
- Why this matters (impact on workflow/quality/velocity)?
- Constraints that cannot be violated:

## Goals / Non-goals

- Goals:
- Non-goals:

## Design Principles and Red Lines

- Principles:
- Red Lines (unbreakable):

## Target Architecture (optional)

- Boundaries and dependency direction:
- Extension points:

## Data and Contracts (as needed)

- Artifacts / Events / Schema:
- Compatibility strategy (versioning/migration/replay):

## Design Rationale

- Why this design (compared to alternatives)?
- Key decisions and justifications:

## Trade-offs

- Trade-offs accepted:
- Trade-offs rejected:

## Variation Points (Future Change Hotspots)

- Where do we expect change?
- What is intentionally left as an extension point?

## Documentation Impact

- Docs that must be updated:
- Docs explicitly confirmed as not needing updates:

## Observability and Acceptance (as needed)

- Metrics/KPI/SLO:

## Acceptance Criteria

- AC-001 (A/B/C): <observable Pass/Fail criteria> (candidate anchors: tests/commands/evidence)
EOF

cat <<'EOF' | render_template | write_file "${change_dir}/tasks.md"
# Tasks: __CHANGE_ID__

> Output location: `__CHANGE_ROOT__/__CHANGE_ID__/tasks.md`
>
> Only derive tasks from `__CHANGE_ROOT__/__CHANGE_ID__/design.md`; do not reverse-engineer plan from tests/.

========================
Main Plan Area
========================

- [ ] MP1.1 <one-line goal>
  - Why:
  - Acceptance Criteria (reference AC-xxx):
  - Candidate Anchors (tests/commands/evidence):
  - Dependencies:
  - Risks:

========================
Temporary Plan Area
========================

- (leave empty/as needed)

========================
Context Switch Breakpoint Area
========================

- Last progress:
- Current blocker:
- Next shortest path:
EOF

cat <<'EOF' | render_template | write_file "${change_dir}/verification.md"
# verification.md (__CHANGE_ID__)

> Recommended path: `__CHANGE_ROOT__/__CHANGE_ID__/verification.md`
>
> Goal: Anchor "Definition of Done" to executable anchors and evidence, and provide `AC-xxx -> Requirement/Scenario -> Test IDs -> Evidence` traceability.

---

## Metadata

- Change ID: `__CHANGE_ID__`
- Status: Draft
  > Status lifecycle: Draft → Ready → Done → Archived
  > - Draft: Initial state
  > - Ready: Test plan ready (set by Test Owner)
  > - Done: All tests passed + Review approved (set by **Reviewer only**)
  > - Archived: Archived (set by Spec Gardener)
  > **Constraint: Coder is prohibited from modifying Status field**
- References:
  - Proposal: `__CHANGE_ROOT__/__CHANGE_ID__/proposal.md`
  - Design: `__CHANGE_ROOT__/__CHANGE_ID__/design.md`
  - Tasks: `__CHANGE_ROOT__/__CHANGE_ID__/tasks.md`
  - Spec deltas: `__CHANGE_ROOT__/__CHANGE_ID__/specs/**`
- Maintainer: <you>
- Last Updated: YYYY-MM-DD
- Test Owner (independent session): <session/agent>
- Coder (independent session): <session/agent>
- Red baseline evidence: `__CHANGE_ROOT__/__CHANGE_ID__/evidence/`

---

========================
A) Test Plan Directive Table
========================

### Main Plan Area

- [ ] TP1.1 <one-line goal>
  - Why:
  - Acceptance Criteria (reference AC-xxx / Requirement):
  - Test Type: unit | contract | integration | e2e | fitness | static
  - Non-goals:
  - Candidate Anchors (Test IDs / commands / evidence):

### Temporary Plan Area

- (leave empty/as needed)

### Context Switch Breakpoint Area

- Last progress:
- Current blocker:
- Next shortest path:

---

========================
B) Traceability Matrix
========================

| AC | Requirement/Scenario | Test IDs / Commands | Evidence / MANUAL-* | Status |
|---|---|---|---|---|
| AC-001 | <capability>/Requirement... | TEST-... / pnpm test ... | MANUAL-001 / link | TODO |

---

========================
C) Execution Anchors (Deterministic Anchors)
========================

### 1) Behavior

- unit:
- integration:
- e2e:

### 2) Contract

- OpenAPI/Proto/Schema:
- contract tests:

### 3) Structure (Fitness Functions)

- Layering/dependency direction/no cycles:

### 4) Static and Security

- lint/typecheck/build:
- SAST/secret scan:
- Report format: json|xml (prefer machine-readable)

---

========================
D) MANUAL-* Checklist (Manual/Hybrid Acceptance)
========================

- [ ] MANUAL-001 <acceptance item>
  - Pass/Fail criteria:
  - Evidence (screenshot/video/link/log):
  - Responsible/Sign-off:

---

========================
E) Risks and Degradation (optional)
========================

- Risks:
- Degradation strategy:
- Rollback strategy:

========================
F) Structural Quality Gate Record
========================

- Conflict points:
- Impact assessment (cohesion/coupling/testability):
- Alternative gates (complexity/coupling/dependency direction/test quality):
- Decision and Authorization: <fill "none" or specify authorizer/conclusion>

========================
G) Value Stream and Metrics (optional, but must explicitly fill "none")
========================

- Target Value Signal: <fill "none" or specify metrics/dashboard/logs/business events>
- Delivery and stability metrics (optional DORA): <fill "none" or specify Lead Time / Deploy Frequency / Change Failure Rate / MTTR observation approach>
- Observation window and trigger points: <fill "none" or specify post-launch duration, what alerts/reports to observe>
- Evidence: <fill "none" or specify link/screenshot/report path (recommend storing in evidence/)>
EOF

specs_readme_path="${change_dir}/specs/README.md"
if [[ ! -f "$specs_readme_path" || "$force" == true ]]; then
  printf '%s\n' "# specs/" "" "Create a subdirectory for each capability in this directory, and write \`spec.md\` inside:" "" "- \`${change_root}/${change_id}/specs/<capability>/spec.md\`" "" | write_file "$specs_readme_path"
fi

# Prototype mode: create prototype track skeleton
if [[ "$prototype" == true ]]; then
  mkdir -p "${change_dir}/prototype/src" "${change_dir}/prototype/characterization"

  cat <<'EOF' | render_template | write_file "${change_dir}/prototype/PROTOTYPE.md"
# Prototype Declaration: __CHANGE_ID__

> This directory contains prototype code, **DO NOT merge directly into production codebase**.
>
> Source: "The Mythical Man-Month" Chapter 11 "Plan to Throw One Away" - "The first system built is not usable...plan to throw it away"

## Directory Structure

```
prototype/
├── PROTOTYPE.md          # This file: prototype declaration and status
├── src/                  # Prototype implementation code (technical debt allowed)
└── characterization/     # Characterization tests (record actual behavior, not acceptance tests)
```

## Status

- [ ] Prototype complete
- [ ] Characterization tests ready (behavior snapshot recorded)
- [ ] Decided: promote / discard / iterate

## Constraints (must follow)

1. **Physical isolation**: Prototype code can only be in `prototype/src/`, cannot directly land in repo `src/`
2. **Role isolation unchanged**: Test Owner and Coder must still use independent sessions/instances
3. **Characterization tests first**: Test Owner produces "characterization tests" (record actual behavior), not acceptance tests
4. **Promotion requires explicit trigger**: Run `prototype-promote.sh __CHANGE_ID__` and complete checklist

## Promotion Checklist (must complete before promotion)

- [ ] Create production-level `design.md` (extract What/Constraints/AC-xxx from prototype learnings)
- [ ] Test Owner produces acceptance tests `verification.md` (replace characterization tests)
- [ ] Run `prototype-promote.sh __CHANGE_ID__` and pass all gates
- [ ] Archive prototype code to `tests/archived-characterization/__CHANGE_ID__/`

## Discard Checklist (when discarding)

- [ ] Record key insights learned to `proposal.md` Decision Log
- [ ] Delete `prototype/` directory

## Learning Record

> What was learned during prototyping? These insights will help production-level implementation.

- Technical discoveries:
- Risk clarifications:
- Design constraint updates:
EOF

  echo "ok: created prototype track at ${change_dir}/prototype/"
fi

# Delivery hook: Platform Sync (optional)
# If the project provides scripts/platform-sync.sh and platform_targets[] is configured,
# run it to keep platform artifacts in sync and write an auditable summary into RUNBOOK.md.
platform_sync_script="${project_root}/scripts/platform-sync.sh"
if [[ -x "$platform_sync_script" ]]; then
  echo "info: platform sync (if enabled)..."
  "$platform_sync_script" "$change_id" --project-root "$project_root" --change-root "$change_root" >/dev/null 2>&1 || {
    echo "error: platform-sync failed (see ${change_dir}/evidence/gates/platform-sync.json)" >&2
    exit 1
  }
fi

echo "ok: scaffolded ${change_dir}"
