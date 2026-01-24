<truth-root>=dev-playbooks/specs; <change-root>=dev-playbooks/changes

1) **结论（Product Manager / System Architect 视角）**：Revise Required —— MCP 规格对齐文本仍包含被 AC-105 与验证用例禁止的旧术语，阻断项未清零。
2) **阻断项（Blocking）**：
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/mcp/spec.md` 的 `REQ-MCP-005` 段落仍包含“检测/降级”字样（例如“MUST NOT 描述检测方式、超时时间、降级策略”“检测与降级细节仅在 MCP 规格与对外文档中说明”），与 AC-105 要求该段落仅保留能力类型且不含检测/降级细节不一致，`tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` 的 TEST-AC105-03 将因此失败。
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/style-cleanup/spec.md` 的 `REQ-STYLE-002` 段落仍出现“MCP 增强/依赖的 MCP 服务/增强模式 vs 基础模式”等字样，违背 AC-105 与 `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` 的 TEST-AC105-04 对该段落的过滤要求。
3) **遗漏项（Missing）**：
- 无。
4) **非阻断项（Non-blocking）**：
- `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md`、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md`、`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md` 已填充且不再是占位结构；`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/proposal.md` 的痛点→改进→AC/锚点表已闭合；`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md` 已纳入术语范围。
5) **替代方案**：
- 最小改动路径：重写 `REQ-MCP-005` 与 `REQ-STYLE-002` 段落，保留“推荐 MCP 能力类型”要求但删除“检测/降级”与旧 MCP 章节名称表述，将检测与降级细节转移到 `dev-playbooks/specs/mcp/spec.md` 的其他章节或 `dev-playbooks/docs/推荐MCP.md` 说明中。
6) **风险与证据缺口**：
- 在 `REQ-MCP-005` 与 `REQ-STYLE-002` 未清理旧术语之前，`tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` 的 TEST-AC105-03 与 TEST-AC105-04 无法通过，阻断验证链闭合。
结论：Revise Required
