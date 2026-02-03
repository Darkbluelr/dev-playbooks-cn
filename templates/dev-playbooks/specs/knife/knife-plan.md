# Knife Plan 模板（说明文档）

> 说明：Knife Plan 必须机读；推荐使用同目录下的 `knife-plan.yaml`（本文件仅做解释与字段说明）。

## 元数据

- plan_id: <plan-id>
- epic_id: <epic-id>
- slice_id: <slice-id>
- ac_ids: [AC-001]
- acceptance_ids: [ACC-001]
- change_type: feature
- risk_level: medium
- dependencies: []
- assumptions: <assumptions>

## 验证锚点

| anchor_id | gate_id | evidence_type | success_criteria | owner |
| --- | --- | --- | --- | --- |
| ANCHOR-001 | G3 | checklist | 所有锚点字段齐全 | planner |
