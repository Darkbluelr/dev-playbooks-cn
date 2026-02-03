# RUNBOOK：<change-id>

## 0) 快速开始（只做两件事）
1. 【AI】按“路线 A 或 B”执行（不要自己发明步骤）
2. 【CMD】只运行 RUNBOOK 指定的验证锚点，并把输出落盘到 `evidence/`

## 1) 本次路由结果（Delivery 入口填写）
- request_kind: <debug|change|epic|void|bootstrap|governance>
- change_type: <feature|hotfix|refactor|migration|compliance|spike-prototype|docs|protocol...>
- risk_level: <low|medium|high>
- intervention_level: <local|team|org>
- deliverable_quality: <outline|draft|complete|operational>
- need_bootstrap: <yes/no>
- need_void: <yes/no>
- need_knife: <yes/no>
- need_spec_delta: <yes/no>
- platform_targets: <0..N tool ids; only when configured/enabled>
- spec_targets: <0..N canonical paths; only when need_spec_delta=yes>

## 2) 本次输入清单
- 需求原文：<粘贴或引用>
- 参考资料索引：`inputs/index.md`

## Cover View（派生缓存，可丢弃可重建）

> NOTE：在 `risk_level=medium|high` 或 `request_kind=epic|governance` 或 `intervention_level=team|org` 的变更中，G6（`archive|strict`）会强制校验本 RUNBOOK 仍包含 `## Cover View` 与 `## Context Capsule` 两个小节标题；**不要删除**。

<!-- DEVBOOKS_DERIVED_COVER_VIEW:START -->
> 运行 `skills/devbooks-delivery-workflow/scripts/runbook-derive.sh <change-id> --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs` 自动生成（可丢弃可重建）
<!-- DEVBOOKS_DERIVED_COVER_VIEW:END -->

## Context Capsule（≤2 页；只写索引与约束，禁止贴长日志/长输出）

<!-- DEVBOOKS_DERIVED_CONTEXT_CAPSULE:START -->
> 运行 `skills/devbooks-delivery-workflow/scripts/runbook-derive.sh <change-id> --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs` 自动生成（可丢弃可重建）
<!-- DEVBOOKS_DERIVED_CONTEXT_CAPSULE:END -->

### 1) 本变更一句话目标（对齐 `completion.contract.yaml: intent.summary`）
- summary: <一句话，语义与 intent.summary 一致>

### 2) 不可变约束（3–7 条；每条附 1 个引用锚点）
- <约束 1>（source: path/to/doc.md#Heading）
- <约束 2>（source: path/to/doc.md#Heading）

### 3) 影响边界（允许/禁止；至少到目录或模块级）
- Allowed:
  - <allowed-1>
- Forbidden:
  - <forbidden-1>

### 4) 必跑验证锚点（只列 invocation_ref；不贴输出）
- <C-xxx> <invocation_ref>

### 5) 默认检索路线（必看清单：入口/配置/脚本/模板）
- Entry（入口）：<系统/项目的主要入口点与命令>
- Config（配置）：<影响行为的关键配置文件与位置>
- Scripts（脚本）：<需要阅读/运行的关键脚本与契约>
- Templates（模板）：<可能需要同步/更新的模板与生成源>
- SSOT（真理源）：<spec_targets 指向的 canonical spec 路径>

### 6) 偷懒路径黑名单（3–7 条，禁止动作）
- <blacklist-1>

## 3) 两条执行路线

### A) 自动闭环（如果你的环境支持多代理/独立会话）
【AI｜自动闭环提示词（复制即可）】
你现在是编排器。请严格按本 RUNBOOK 执行并落盘所有产物。
若需要角色隔离：
1) 若你能创建独立子代理/会话：请创建并分别执行 Test Owner 与 Coder（以及需要时的 Challenger/Judge）
2) 若你不能创建：请明确告诉我“需要我手动开新对话/新实例”，并暂停等待我确认
禁止：在同一上下文里先写 tests 再写实现，或先写提案再自己裁决。

### B) 手动闭环（无多代理/不能自动分身时）
**你需要准备的窗口（MUST）**：
- 窗口 1：Delivery/主对话（只负责汇总与校验）
- 窗口 2：Test Owner（只写 `tests/**` + `verification.md` + `evidence/**`）
- 窗口 3：Coder（只改实现；禁止修改 `tests/**`）
（若需提案对辩/裁决：建议额外开窗口分别扮演 Author/Challenger/Judge）

## 4) 产物清单与 Done 判据
- 必需文件：`proposal.md`、`design.md`、`tasks.md`、`verification.md`
- 证据目录：
  - `evidence/red-baseline/`
  - `evidence/green-final/`
  - `evidence/gates/`
    - 提示：归档前应产出 `evidence/gates/G6-archive-decider.json`（仅提示，不接线）
  - `evidence/risks/`
- Done 判据：以 `change-check.sh --mode strict` + Green Evidence 为准（不得口头自证完成）

## 5) 回退与止损
- DoR 不满足 → 回到 Bootstrap
- 执行期反复失败/外部信息缺口 → 回到 Void
- 预算超限/切片不收敛 → 回到 Knife
