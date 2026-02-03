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
acceptance_ids: []
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

> 产物路径：`dev-playbooks/changes/<change-id>/proposal.md`
>
> 注意：Proposal 阶段禁止写实现细节；只定义 Why/What/Impact/Risks/Validation，并记录 Debate/Judge。

## Why（为什么）

- 问题：
- 目标：

## What Changes（改动内容）

- 变更范围（In scope）：
- 不在范围（Non-goals）：
- 影响范围（模块/能力/对外契约/数据不变式）：

## Impact（影响）

- 对外契约（API/Schema/Event）：
- 数据与迁移：
- 受影响模块与依赖：
- 测试与质量闸门：
- 价值信号与观测口径：无
- 价值流瓶颈假设：无

## Risks（风险）

- 风险：
- 降级策略：
- 回滚策略：

## Validation（验证）

- 候选验收锚点（tests/静态检查/build/人工证据等）：
- 证据落点：`dev-playbooks/changes/<change-id>/evidence/`

## Debate Packet（对辩材料包）

- 需要裁决的对辩点/问题（<= 7 项）：

## Decision Log（裁决记录）

- 决策状态：Pending
- 裁决摘要：
- 待裁决问题：
