<truth-root>=dev-playbooks/specs; <change-root>=dev-playbooks/changes
# Code Review：20260124-0636-enhance-devbooks-longterm-guidance

专家视角：System Architect / Security Expert

范围：`README.md`、`docs/使用指南.md`、`docs/Skill详解.md`、`dev-playbooks/docs/推荐MCP.md`、`skills/**/SKILL.md`、`dev-playbooks/specs/shared-methodology/spec.md`、`dev-playbooks/specs/mcp/spec.md`、`dev-playbooks/specs/style-cleanup/spec.md`、`dev-playbooks/specs/_meta/glossary.md`

## 严重问题（必须修复）
- SKILL.md 仍保留 `## MCP 说明` 章节，违反 `dev-playbooks/specs/mcp/spec.md:61` 的“仅保留推荐 MCP 能力类型小节”要求，也与 `dev-playbooks/specs/style-cleanup/spec.md:36` 的清理约束冲突。受影响文件：`skills/devbooks-docs-consistency/SKILL.md:138`、`skills/devbooks-entropy-monitor/SKILL.md:154`、`skills/devbooks-implementation-plan/SKILL.md:157`、`skills/devbooks-delivery-workflow/SKILL.md:227`、`skills/devbooks-design-doc/SKILL.md:255`、`skills/devbooks-brownfield-bootstrap/SKILL.md:235`、`skills/devbooks-archiver/SKILL.md:426`、`skills/devbooks-impact-analysis/SKILL.md:133`、`skills/devbooks-reviewer/SKILL.md:210`、`skills/devbooks-router/SKILL.md:344`、`skills/devbooks-proposal-judge/SKILL.md:74`、`skills/devbooks-proposal-author/SKILL.md:185`、`skills/devbooks-test-owner/SKILL.md:283`、`skills/devbooks-test-reviewer/SKILL.md:248`、`skills/devbooks-proposal-challenger/SKILL.md:82`、`skills/devbooks-spec-contract/SKILL.md:192`。建议：移除所有 MCP 说明段落，仅保留“推荐 MCP 能力类型”。验证：`rg -n "## MCP 说明" skills/**/SKILL.md`。
- SKILL.md 中仍出现具体 MCP 服务与模式细节（CKB、索引健康、增强/基础模式、mcp__ckb__*），与 `dev-playbooks/specs/mcp/spec.md:61`、`dev-playbooks/specs/style-cleanup/spec.md:36`、`dev-playbooks/specs/_meta/glossary.md:23` 的“能力类型清单不绑定具体服务”口径不一致。示例位置：`skills/devbooks-brownfield-bootstrap/SKILL.md:66`、`skills/devbooks-impact-analysis/SKILL.md:111`、`skills/devbooks-router/SKILL.md:47`、`skills/devbooks-reviewer/SKILL.md:146`。建议：将服务/模式细节迁移到 `dev-playbooks/docs/推荐MCP.md` 或 MCP 规格，只在 SKILL.md 保留能力类型清单。验证：`rg -n "CKB|mcp__ckb|增强模式|基础模式|图索引|MCP 检测" skills/**/SKILL.md`。
- Test Owner 渐进披露边界与角色职责冲突：`skills/devbooks-test-owner/SKILL.md:292` 写明“ 不触碰 tests/”，与 Test Owner 需要编写验收测试的职责相矛盾，易误导执行。建议：将边界改为“仅触碰 tests/ 与 verification.md，不改实现代码”等角色匹配表述。验证：`rg -n "不触碰 tests/" skills/devbooks-test-owner/SKILL.md`。
- 交付闸门未满足，无法给出通过结论：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md:50` 仍有未完成项，且 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/` 未见 `green-final/` 证据目录。建议：补齐 MP1.9 的自检与证据，再进入评审通过流程。验证：`rg -n "^- \[ \]" dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md`，`ls dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/`。

## 可维护性风险（建议修复）
- 技能清单与实际目录不一致：`docs/Skill详解.md:3` 标注“19 个 Skills”，且 `docs/Skill详解.md:661` 出现 `design-backport`，但 `skills/` 目录未包含该 Skill。建议：同步技能数量与清单。验证：`ls skills`，`rg -n "design-backport" docs/Skill详解.md`。
- 相关文档链接失效：`docs/使用指南.md:540`、`docs/使用指南.md:541` 与 `docs/Skill详解.md:678`、`docs/Skill详解.md:679` 指向 `./DevBooks配置指南.md`、`./推荐MCP.md`，但文件位于 `dev-playbooks/docs/`。建议：修正相对路径或将文档移动到 `docs/`。验证：`ls docs`。
- `dev-playbooks/docs/推荐MCP.md` 新增“能力类型与命名规范”但目录未更新，结构不一致：`dev-playbooks/docs/推荐MCP.md:10` 与 `dev-playbooks/docs/推荐MCP.md:38`。建议：补齐目录项。验证：`rg -n "目录|MCP 能力类型" dev-playbooks/docs/推荐MCP.md`。
- 设计要求 `docs/Skill详解.md` 增补“渐进披露说明”，但当前文档未出现该关键词：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md:50`。建议：在 Skill 详解补一段解释“基础/进阶/扩展”模板与用途。验证：`rg -n "渐进披露" docs/Skill详解.md`。
- MCP 能力类型清单口径不清：`dev-playbooks/docs/推荐MCP.md:42` 包含“文档检索”，而 SKILL.md 清单仅含三类（如 `skills/devbooks-reviewer/SKILL.md:228`）。建议：明确哪些 Skill 需要“文档检索”，或在推荐文档中说明“视需求裁剪”。验证：`rg -n "推荐 MCP 能力类型" skills/**/SKILL.md`。
- 渐进披露模板在所有 SKILL.md 中重复，信息高度同质，可能放大上下文负担（Prompt 膨胀）。建议：改为引用统一模板文件或压缩为 2-3 行关键提示。示例位置：`skills/devbooks-coder/SKILL.md:268`。验证：`rg -n "## 渐进披露" skills/**/SKILL.md`。

## 风格与一致性建议（可选）
- 术语标题未对齐：`dev-playbooks/docs/推荐MCP.md:38` 使用“能力类型与命名规范”，而术语表定义为“推荐 MCP 能力类型”（`dev-playbooks/specs/_meta/glossary.md:23`）。建议：统一标题用语。验证：`rg -n "MCP 能力类型" dev-playbooks/docs/推荐MCP.md`。
- “定位与文本规范”新增后未进入目录，导航一致性下降：`docs/使用指南.md:40`、`docs/使用指南.md:52` 与 `docs/Skill详解.md:18`、`docs/Skill详解.md:7`。建议：补充目录项。验证：`rg -n "定位与文本规范|目录" docs/使用指南.md docs/Skill详解.md`。
- “不要写为了…所以…”约束检查：在本次范围内未发现该句式（已扫描 `README.md`、`docs/`、`skills/**/SKILL.md` 与相关 specs）。验证：`rg -n "为了.*所以" README.md docs/ dev-playbooks/specs skills/**/SKILL.md`。

## 建议新增质量闸门（如需）
- 增加静态检查，防止 MCP 运行细节回流到 SKILL.md：`rg -n "## MCP 说明|CKB|mcp__ckb|增强模式|基础模式|MCP 检测|图索引" skills/**/SKILL.md`。

## 产出物完整性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| tasks.md 完成度 | ❌ | 8/9 已完成，`MP1.9` 未完成（`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/tasks.md:50`） |
| 测试全绿（非 Skip） | ❌ | 未运行测试，未取得通过/跳过/失败数据 |
| Green 证据存在 | ❌ | `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/` 下缺失 `green-final/` |
| 无失败模式在证据中 | ❌ | 无 Green 证据，无法核验 |

## 评审结论

🔄 REQUEST CHANGES（Revise Required）
