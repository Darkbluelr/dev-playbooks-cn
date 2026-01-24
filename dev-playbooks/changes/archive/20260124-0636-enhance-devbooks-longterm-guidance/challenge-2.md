**结论（第 2 次）**：Revise Required —— <truth-root>=dev-playbooks/specs，<change-root>=dev-playbooks/changes；以 Product Manager / System Architect 视角，本次更新补充了痛点映射与 Minimal Diff，但“参考资料1 → 可验证改进”与 MCP 章节冲突对齐仍缺少可执行与可验证落点。

**阻断项（Blocking）**
- 参考资料1 的痛点映射尚未转化为可验证改进：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的“参考资料1痛点映射”仅列出“预期可验证锚点”，而 “What/Validation”未给出“长期视野/反短视”“人类建议校准”的 AC 或验证命令，无法证明新增改进与痛点闭环。
- MCP 章节冲突对齐缺少可执行替代条款：`dev-playbooks/specs/mcp/spec.md` 的 REQ-MCP-005 仍要求 SKILL.md 包含“MCP 增强”与检测方式 `mcp__ckb__getStatus()`、2s 超时、降级策略；`dev-playbooks/specs/style-cleanup/spec.md` 的 REQ-STYLE-002 要求删除“MCP 增强”章节。提案虽声明调整两条要求，但未给出替代条款的具体文本、AC Trace 迁移或场景更新，导致对齐不可验证。
- Minimal Diff 未覆盖术语表，导致术语约束不可验证：提案引入“人类建议校准”与“推荐 MCP 能力类型”（`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md`），但 `dev-playbooks/specs/_meta/glossary.md` 不含该术语，且 Minimal Diff 清单未包含术语表更新，违反“术语使用符合 glossary”的自检项。

**遗漏项（Missing）**
- 缺少“人类建议校准”提示词机制的可执行规格：提案仅说明将补充触发条件与输出，但未提供最小提示词模板、输出字段或示例，无法在 `dev-playbooks/specs/shared-methodology/spec.md` 中落地验收。
- 缺少渐进披露统一的结构模板与判定规则：提案要求“统一 Skills 渐进披露描述”，但未定义段落模板、层级提示关键词或可扫描的约束，难以验证批量改写是否达标。
- “约束-取舍-影响”改写缺少检测方法：提案只声明清理文档理由表达，但没有给出检查范围或可执行的校验规则，无法形成可验证改进。

**非阻断项（Non-blocking）**
- 6 类“推荐 MCP 能力类型”清单可作为统一基线，但需要在 `dev-playbooks/docs/推荐MCP.md` 给出固定表头与示例行，避免后续出现版本不一致或空表问题。

**替代方案**
- 先收敛到可验证的最小闭环：优先完成 `dev-playbooks/specs/mcp/spec.md` 与 `dev-playbooks/specs/style-cleanup/spec.md` 的冲突对齐条款与 AC Trace 更新，同时补齐 `dev-playbooks/specs/_meta/glossary.md` 的“人类建议校准”术语，再更新 `README.md` 与 `docs/使用指南.md` 的定位说明；批量改写全部 `skills/*/SKILL.md` 可拆分为后续变更包。

**风险与证据缺口**
- `tests/complete-devbooks-independence/test_mcp_optional.bats` 明确依赖 `skills/devbooks-router/SKILL.md` 中 “optional/fallback/graceful/without MCP” 文案模式；提案未说明渐进披露统一后将保留或替换这些关键词，存在回归风险且无验证计划。
- “推荐 MCP 能力类型”与“约束-取舍-影响”均未定义可执行验证路径，提案仅写“允许新增或调整测试点”（`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md`），但缺少具体测试设计与证据落点。

结论：Revise Required
