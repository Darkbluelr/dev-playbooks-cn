# 闸门验证用例矩阵（T9）

> 目标：把“漏任务/忘尾部/弱连接/漂移”的典型失败方式，变成**可复现、可机判、可定位 next_action** 的验证清单；可直接复用到集成验证（T10）。

## 0) 约定：如何保证“可复现 + 可机判”

1) **建议每个用例使用独立 `change-id`**（避免相互污染）。  
2) **用例尽量只触发 1 个 Gate**：在 `proposal.md` 的 `required_gates` 里只保留目标 Gate（其他 Gate 的问题会被 `change-check.sh` 标记为 *skipped* 警告，不计入失败）。  
3) **机判口径优先使用 `evidence/gates/*.json` 的 `status/next_action` 字段**；若某脚本只输出 stdout/stderr，则将输出重定向到 `evidence/gates/*.log` 并用固定 grep 模式判定。  
4) 本仓库推荐统一参数（按需改成你的项目布局）：
   - `--project-root .`
   - `--change-root dev-playbooks/changes`
   - `--truth-root dev-playbooks/specs`

## 1) 用例矩阵（G0–G6 × 4 类事故）

> 说明：每条用例均给出四元组：**触发方式 → 预期失败点 → 预期 next_action → 证据落点**。  
> 其中“预期失败点”同时给出机判断言（`status=fail|warn` / `failure_reasons` 关键字）。

## G0（元数据/基线/状态/void）

- **漏任务：UC-G0-LEAK-BASELINE（基线工件缺失 → Bootstrap 回流）**  
  - 触发方式：运行 `skills/devbooks-delivery-workflow/scripts/change-metadata-check.sh` 时，将 `--truth-root` 指向缺少 `*_meta/*.md` 基线的目录（例如空目录）。  
  - 预期失败点：`evidence/gates/change-metadata-check.json.status=fail` 且 `failure_reasons[]` 含 `truth baseline missing; next_action=Bootstrap`。  
  - 预期 next_action：`Bootstrap`（读 `evidence/gates/change-metadata-check.json.next_action`）。  
  - 证据落点：`dev-playbooks/changes/<change-id>/evidence/gates/change-metadata-check.json`。

- **忘尾部：UC-G0-FORGET-DECISION（未裁决/未 Approved 仍尝试 strict）**  
  - 触发方式：保持 `proposal.md## Decision Log` 为 `Decision Status: Pending`（或缺失 Approved），运行 `skills/devbooks-delivery-workflow/scripts/change-check.sh --mode strict`。  
  - 预期失败点：`evidence/gates/G0-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `proposal decision status must be Approved`。  
  - 预期 next_action：`DevBooks`（读 `evidence/gates/G0-strict.report.json.next_action`）。  
  - 证据落点：`dev-playbooks/changes/<change-id>/evidence/gates/G0-strict.report.json`。

- **弱连接：UC-G0-WEAK-VOID（声明 next_action=Void 但缺 Void 工件）**  
  - 触发方式：将 `proposal.md` front matter 设为 `next_action: Void`（无需创建 `void/`），运行 `skills/devbooks-delivery-workflow/scripts/void-protocol-check.sh --mode strict`。  
  - 预期失败点：`evidence/gates/void-protocol-check.json.status=fail` 且 `failure_reasons[]` 含 `missing Void artifact:` 或 `VOID_ENABLED!=true`。  
  - 预期 next_action：`Void`（读 `evidence/gates/void-protocol-check.json.next_action`）。  
  - 证据落点：`dev-playbooks/changes/<change-id>/evidence/gates/void-protocol-check.json`。

- **漂移：UC-G0-DRIFT-CHANGEID（目录名与 proposal.change_id 不一致）**  
  - 触发方式：把 `proposal.md` front matter 的 `change_id:` 改为不同值，运行 `skills/devbooks-delivery-workflow/scripts/change-metadata-check.sh --mode strict`。  
  - 预期失败点：`evidence/gates/change-metadata-check.json.status=fail` 且 `failure_reasons[]` 含 `proposal change_id mismatch:`。  
  - 预期 next_action：`DevBooks`（读 `evidence/gates/change-metadata-check.json.next_action`）。  
  - 证据落点：`dev-playbooks/changes/<change-id>/evidence/gates/change-metadata-check.json`。

## G1（required_gates 派生与确定性校验）

- **漏任务：UC-G1-LEAK-REQUIRED-GATES（required_gates 缺失/为空）**  
  - 触发方式：删除 `proposal.md` front matter 的 `required_gates:`（或置空），运行 `skills/devbooks-delivery-workflow/scripts/required-gates-check.sh`。  
  - 预期失败点：`evidence/gates/required-gates-check.json.status=fail` 且 `failure_reasons[]` 含 `proposal.required_gates is missing or empty`。  
  - 预期 next_action：`DevBooks`（读 `evidence/gates/required-gates-check.json.next_action`）。  
  - 证据落点：`dev-playbooks/changes/<change-id>/evidence/gates/required-gates-check.json`（并生成 `required-gates-derive.json`）。

- **忘尾部：UC-G1-FORGET-RISK-UPGRADE（risk_level 升级但漏补 G5）**  
  - 触发方式：把 `proposal.md:risk_level` 改为 `medium`（或 `high`），但 `required_gates` 不包含 `G5`，运行 `required-gates-check.sh`。  
  - 预期失败点：`required-gates-check.json.status=fail` 且 `failure_reasons[]` 含 `missing derived gate: G5`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/required-gates-check.json` + `evidence/gates/required-gates-derive.json`。

- **弱连接：UC-G1-WEAK-MISS-G6（漏掉最终裁判 Gate）**  
  - 触发方式：从 `required_gates` 中移除 `G6`（保持其他不变），运行 `required-gates-check.sh`。  
  - 预期失败点：`required-gates-check.json.status=fail` 且 `failure_reasons[]` 含 `missing derived gate: G6`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/required-gates-check.json`。

- **漂移：UC-G1-DRIFT-CONTRACT-QUALITY（合同质量升级但漏补 G2）**  
  - 触发方式：把 `completion.contract.yaml:intent.deliverable_quality` 改为 `draft`（或更高），但 `required_gates` 不包含 `G2`，运行 `required-gates-check.sh`。  
  - 预期失败点：`required-gates-check.json.status=fail` 且 `failure_reasons[]` 含 `missing derived gate: G2`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/required-gates-check.json`（并可在 `required-gates-derive.json` 看到派生原因）。

## G2（Green Evidence 闭包 / 任务闭包 / 失败证据阻断）

> 运行入口统一用：`skills/devbooks-delivery-workflow/scripts/change-check.sh <change-id> --mode strict`，并在 `proposal.md.required_gates` 只保留 `G2` 以隔离其他 Gate。

- **漏任务：UC-G2-LEAK-TASKS（任务未完成）**  
  - 触发方式：保证 `evidence/green-final/` 非空（放入任意不含 FAIL 模式的文件），但 `tasks.md` 存在未勾选项。  
  - 预期失败点：`evidence/gates/G2-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `Task completion rate`（AC-002）。  
  - 预期 next_action：`DevBooks`（读 `evidence/gates/G2-strict.report.json.next_action`）。  
  - 证据落点：`evidence/gates/G2-strict.report.json` + `evidence/green-final/*`。

- **忘尾部：UC-G2-FORGET-GREEN（缺少 Green Evidence）**  
  - 触发方式：将 `tasks.md` 所有 checkbox 标为完成（或删除所有 checkbox），但 `evidence/green-final/` 为空。  
  - 预期失败点：`G2-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `Missing Green evidence`（AC-001）。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G2-strict.report.json`。

- **弱连接：UC-G2-WEAK-P0-SKIP（P0 跳过无审批证据）**  
  - 触发方式：在 `tasks.md` 添加未完成的 `- [ ] [P0] <task>`，且其前/本/后行均无 `<!-- SKIP-APPROVED:` 注释。  
  - 预期失败点：`G2-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `P0 task skip requires approval`（AC-005）。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G2-strict.report.json`（触发点在 `tasks.md`）。

- **漂移：UC-G2-DRIFT-GREEN-FAIL（Green Evidence 中出现 FAIL 模式）**  
  - 触发方式：保证任务闭包通过（tasks 全勾选），在 `evidence/green-final/` 任一文件写入 `FAIL:` / `FAILED:` / `not ok` 等失败模式行。  
  - 预期失败点：`G2-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `Test failure: Green evidence contains failure pattern`（AC-007）。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G2-strict.report.json` + 对应 `evidence/green-final/*` 文件。

## G3（Knife/Anchors：高风险或 Epic 级必须可机读）

- **漏任务：UC-G3-LEAK-ANCHORS（合同 checks 缺少确定性字段）**  
  - 触发方式：保持模板 `completion.contract.yaml` 的 `checks[]` 缺少 `runner/timeout_seconds/requires_network/success_criteria/failure_next_action`，运行 `skills/devbooks-delivery-workflow/scripts/verification-anchors-check.sh --mode strict`。  
  - 预期失败点：`evidence/gates/verification-anchors-check.json.status=fail` 且 `failure_reasons[]` 含 `missing anchor fields:`。  
  - 预期 next_action：`DevBooks`（读 `verification-anchors-check.json.next_action`）。  
  - 证据落点：`evidence/gates/verification-anchors-check.json`。

- **忘尾部：UC-G3-FORGET-KNIFE（risk=high/epic 但缺 Knife 输入）**  
  - 触发方式：把 `proposal.md:risk_level` 设为 `high`（或 `request_kind=epic`），但 `epic_id/slice_id` 为空，运行 `skills/devbooks-delivery-workflow/scripts/knife-plan-check.sh --mode strict --out evidence/gates/knife-plan-check-strict.json`。  
  - 预期失败点：`knife-plan-check-strict.json.status=fail` 且 `failure_reasons[]` 含 `missing epic_id`（或 `Knife Plan ... missing`）。  
  - 预期 next_action：`Knife`（读 `knife-plan-check-strict.json.next_action`）。  
  - 证据落点：`evidence/gates/knife-plan-check-strict.json`。

- **弱连接：UC-G3-WEAK-FREEZE-REV（进入 in_progress+ 但未冻结 Knife revision）**  
  - 触发方式：设置 `proposal.md`：`risk_level: high`，`epic_id: EPIC-AINATIVE-PROTOCOL-V1-1-COMPLETION`，`slice_id: SLICE-AINATIVE-PROTOCOL-V1-1-FULLY`，`state: in_progress`，但 `truth_refs` 缺少 `knife_plan_revision`，运行 `knife-plan-check.sh`。  
  - 预期失败点：`knife-plan-check-*.json.status=fail` 且 `failure_reasons[]` 含 `truth_refs.knife_plan_revision is required once state=`。  
  - 预期 next_action：`Knife`。  
  - 证据落点：`evidence/gates/knife-plan-check-*.json`（以及引用的 `dev-playbooks/specs/_meta/epics/**/knife-plan.yaml`）。

- **漂移：UC-G3-DRIFT-EPIC-AC（proposal.ac_ids 与 slice.ac_subset 不一致）**  
  - 触发方式：设置 `proposal.md`：`risk_level: high`、`epic_id/slice_id` 如上，但把 `ac_ids` 改成与该 slice 的 `ac_subset` 不一致，运行 `skills/devbooks-delivery-workflow/scripts/epic-alignment-check.sh --mode strict`。  
  - 预期失败点：`evidence/gates/epic-alignment-check.json.status=fail` 且 `failure_reasons[]` 含 `AC alignment mismatch:`。  
  - 预期 next_action：`DevBooks`（读 `epic-alignment-check.json.next_action`）。  
  - 证据落点：`evidence/gates/epic-alignment-check.json`。

## G4（扩展包完整性 / 结构闸门 / 文档影响）

- **漏任务：UC-G4-LEAK-PACK-MISSING（启用 Pack 但目录不存在）**  
  - 触发方式：运行 `skills/devbooks-delivery-workflow/scripts/extension-pack-integrity-check.sh --enabled-packs not-exist-pack`。  
  - 预期失败点：`evidence/gates/extension-pack-integrity-check.json.status=fail` 且 `failure_reasons[]` 含 `enabled pack missing under truth root`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/extension-pack-integrity-check.json`。

- **忘尾部：UC-G4-FORGET-DOCS-IMPACT（声明 P0 文档更新但 checklist 未完成）**  
  - 触发方式：在 `design.md` 任意位置加入 `| P0 |` 行（表示存在 P0 文档工作），并加入未勾选项 `- [ ] New workflow ...`，运行 `change-check.sh --mode strict`（`required_gates` 仅保留 `G4`）。  
  - 预期失败点：`evidence/gates/G4-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `Documentation update checklist has incomplete items`（AC-008）。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G4-strict.report.json`。

- **弱连接：UC-G4-WEAK-MAPPING-INVALID（Pack mapping 缺少可执行字段）**  
  - 触发方式：在临时 `--truth-root` 下创建一个 Pack（如 `t9-bad-pack`）并写入 mapping（缺少 `evidence_paths` 或 `check_id`），再用 `extension-pack-integrity-check.sh --enabled-packs t9-bad-pack --truth-root <tmp>` 运行。  
  - 预期失败点：`extension-pack-integrity-check.json.status=fail` 且 `failure_reasons[]` 含 `mapping entry missing required fields`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/extension-pack-integrity-check.json`。

- **漂移：UC-G4-DRIFT-PACK-ID（enabled pack_id 非法）**  
  - 触发方式：运行 `extension-pack-integrity-check.sh --enabled-packs Bad_Pack`（含大写/下划线）。  
  - 预期失败点：`extension-pack-integrity-check.json.status=fail` 且 `failure_reasons[]` 含 `invalid pack_id (expected [a-z0-9-])`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/extension-pack-integrity-check.json`。

## G5（风险证据 / 协议覆盖：risk 驱动的阻断）

- **漏任务：UC-G5-LEAK-RISK-EVIDENCE（risk=medium|high 但缺风险证据）**  
  - 触发方式：设置 `proposal.md:risk_level=medium`（或 high），不提供 `rollback-plan.md` 与 `evidence/risks/dependency-audit.log`，运行 `skills/devbooks-delivery-workflow/scripts/risk-evidence-check.sh --mode strict --out evidence/gates/risk-evidence-check-strict.json`。  
  - 预期失败点：`risk-evidence-check-*.json.status=fail` 且 `failure_reasons[]` 含 `missing rollback-plan.md` / `missing dependency audit log`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/risk-evidence-check-*.json`。

- **忘尾部：UC-G5-FORGET-P10-REPORT（触发 P10 但缺覆盖报告）**  
  - 触发方式：在 `proposal.md` 设置 `risk_flags.protocol_v1_1: true`（或 `risk_level: high`），补齐基础风险证据（回滚计划 + 依赖审计），但不生成 `evidence/gates/protocol-v1.1-coverage.report.json`，运行 `change-check.sh --mode strict`（`required_gates` 仅保留 `G5`）。  
  - 预期失败点：`evidence/gates/G5-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `missing protocol coverage report (P10)`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G5-strict.report.json`。

- **弱连接：UC-G5-WEAK-EXT-PACK-EVIDENCE（启用扩展包但缺其证据）**  
  - 触发方式：设置 `risk_level=medium|high`，并以环境变量启用 Pack：`DEVBOOKS_EXTENSIONS_ENABLED_PACKS_CSV=security-audit`；补齐回滚计划与依赖审计，但不提供 `evidence/risks/security-audit.log`，运行 `risk-evidence-check.sh`。  
  - 预期失败点：`risk-evidence-check-*.json.status=fail` 且 `failure_reasons[]` 含 `missing extension pack evidence (security-audit): .../evidence/risks/security-audit.log`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/risk-evidence-check-*.json`。

- **漂移：UC-G5-DRIFT-P10-SHA（覆盖报告与映射源 SHA 不一致）**  
  - 触发方式：触发 P10（同上），生成 `evidence/gates/protocol-v1.1-coverage.report.json`，但将其中 `design_source_sha256` 设为非 `dev-playbooks/specs/protocol-core/protocol-v1.1-coverage-mapping.yaml:design_source_sha256` 的值，运行 `change-check.sh --mode strict`。  
  - 预期失败点：`G5-strict.report.json.status=fail` 且 `failure_reasons[]` 含 `design_source_sha256 mismatch (P10)`。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G5-strict.report.json` + `evidence/gates/protocol-v1.1-coverage.report.json`。

## G6（归档裁决：范围证据包 + 弱连接 + 新鲜度 + 引用完整性）

- **漏任务：UC-G6-LEAK-SCOPE-EVIDENCE（触发范围证据包但缺必需证据）**  
  - 触发方式：将 `proposal.md` 设为 `risk_level: medium`（或 `request_kind: epic|governance`）以触发 Scope Evidence Bundle，但不生成 `evidence/gates/reference-integrity.report.json` 与 `evidence/gates/check-completion-contract.log`，运行 `skills/devbooks-delivery-workflow/scripts/archive-decider.sh --mode strict`。  
  - 预期失败点：`evidence/gates/G6-archive-decider.json.status=fail` 且 `scope_evidence_bundle_evaluation.status=fail`，`missing_artifacts[]` 包含上述路径。  
  - 预期 next_action：`DevBooks`（读 `G6-archive-decider.json.next_action`）。  
  - 证据落点：`evidence/gates/G6-archive-decider.json`。

- **漏任务：UC-G6-LEAK-RUNBOOK-STRUCTURE（触发高范围裁判但 RUNBOOK 控制面被删除）**  
  - 触发方式：触发 higher-scope（同上），但从变更包 `RUNBOOK.md` 删除 `## Cover View` 或 `## Context Capsule` 小节标题，运行 `skills/devbooks-delivery-workflow/scripts/archive-decider.sh --mode strict`（或 `change-check.sh --mode strict`）。  
  - 预期失败点：`evidence/gates/G6-archive-decider.json.status=fail` 且 `runbook_structure_evaluation.status=fail`，`missing_sections[]` 含缺失的小节标题。  
  - 预期 next_action：`DevBooks`（补齐 RUNBOOK 结构并重建派生缓存）。  
  - 证据落点：`evidence/gates/G6-archive-decider.json`。

- **忘尾部：UC-G6-FORGET-STATE-CLOSE（未完成闭包仍尝试 completed 裁判）**  
  - 触发方式：保持 `proposal.md` 的 `state` 非 `completed`（或 `Decision Status` 非 Approved / `verification.md` 仍为 Draft/Ready），运行 `skills/devbooks-delivery-workflow/scripts/check-state-consistency.sh --state completed --out evidence/gates/state-consistency-check.json`。  
  - 预期失败点：`state-consistency-check.json.status=fail` 且 `blockers[]` 包含对应阻断原因（如 `missing_decision_status` / `verification_not_done` / `traceability_has_todo`）。  
  - 预期 next_action：`DevBooks`（读 `state-consistency-check.json.next_action`）。  
  - 证据落点：`evidence/gates/state-consistency-check.json`。

- **弱连接：UC-G6-WEAK-STALE-ARTIFACT（弱连接证据不新鲜/链路断裂）**  
  - 触发方式：在 `completion.contract.yaml` 声明 `weak_link` MUST 义务（applies_to→deliverables.path），并创建其 `checks[].artifacts[]`（如 `evidence/gates/docs-consistency.report.json`，内容可为 `{\"status\":\"pass\",\"issues_count\":0}`），随后更新其覆盖的 deliverable 文件使其 mtime 晚于 artifact，运行 `archive-decider.sh --mode strict`。  
  - 预期失败点：`G6-archive-decider.json.status=fail`，且 `weak_link_evaluation.unmet_weak_link_obligations[]` 非空或 `freshness_evaluation.stale_artifacts[]` 非空。  
  - 预期 next_action：`DevBooks`。  
  - 证据落点：`evidence/gates/G6-archive-decider.json`（以及对应 `evidence/gates/*.report.json` / deliverable 文件）。

- **漂移：UC-G6-DRIFT-REFERENCE（引用不可解析/越权依赖）**  
  - 触发方式：在变更包任意 `.md/.yaml` 写入不可解析引用（如 `truth://no/such/file.md` 或 `capability://NO_SUCH_CAP`），运行 `skills/devbooks-delivery-workflow/scripts/reference-integrity-check.sh`。  
  - 预期失败点：`evidence/gates/reference-integrity.report.json.status=fail` 且 `violations_count>0`。  
  - 预期 next_action：`DevBooks`（G6 语义下默认回流到修复引用/补证据）。  
  - 证据落点：`evidence/gates/reference-integrity.report.json`。
