# 设计文档：20260124-0636-enhance-devbooks-longterm-guidance

## Acceptance Criteria（验收标准）

- AC-101 (B)：`README.md`、`docs/使用指南.md`、`docs/Skill详解.md` 的 DevBooks 定位表述一致，且包含两点：1) DevBooks 为协议与工作流集合，覆盖流程/文本规范/少量自检脚本；2) DevBooks 不是 MCP 工具，MCP 为可选集成点。Pass：三份文档均包含两点且不存在相反表述；Fail：任一文档缺失或出现相反表述。验收锚点：`README.md`，`docs/使用指南.md`，`docs/Skill详解.md`。
- AC-102 (B)：`dev-playbooks/specs/shared-methodology/spec.md` 新增“长期视野/反短视”机制描述，明确包含流程、结构、文本规范、少量自检脚本四类要素，且至少引用一个现有自检脚本路径（如 `skills/devbooks-delivery-workflow/scripts/change-check.sh`）。Pass：四类要素齐全且脚本路径出现；Fail：缺任一要素或无脚本引用。验收锚点：`dev-playbooks/specs/shared-methodology/spec.md`，`skills/devbooks-delivery-workflow/scripts/change-check.sh`。
- AC-103 (B)：`dev-playbooks/specs/shared-methodology/spec.md` 包含“人类建议校准”提示词机制，具备触发条件与固定输出格式，输出字段至少包括：直觉价值、偏离最佳实践/不成熟点、推荐方案；`dev-playbooks/specs/_meta/glossary.md` 增补“人类建议校准”术语定义。Pass：机制、字段与术语完整；Fail：缺触发条件、字段或术语。验收锚点：`dev-playbooks/specs/shared-methodology/spec.md`，`dev-playbooks/specs/_meta/glossary.md`。
- AC-104 (A)：所有 `skills/**/SKILL.md` 包含“渐进披露”模板，具备三级标题“基础层（必读）/进阶层（可选）/扩展层（可选）”及必填行首关键词。Pass：`rg -n "## 渐进披露|### 基础层（必读）|### 进阶层（可选）|### 扩展层（可选）" skills/**/SKILL.md` 覆盖全部 SKILL.md，且每个文件存在 `目标：`、`输入：`、`输出：`、`边界：`、`证据：` 行；Fail：任一文件缺失标题或关键词。验收锚点：`skills/`。
- AC-105 (A/B)：所有 `skills/**/SKILL.md` 的 MCP 相关内容改为“推荐 MCP 能力类型”，不绑定具体 MCP 名称，且不含“MCP 增强/依赖的 MCP 服务/增强模式 vs 基础模式”表述；`dev-playbooks/specs/mcp/spec.md` 的 REQ-MCP-005 与 `dev-playbooks/specs/style-cleanup/spec.md` 的 REQ-STYLE-002 文本完成对齐，仅保留“推荐 MCP 能力类型”并移除检测/降级细节。Pass：`rg -n "推荐 MCP 能力类型" skills/**/SKILL.md` 覆盖全部 SKILL.md，且 `rg -n "MCP 增强|依赖的 MCP 服务|增强模式 vs 基础模式" skills/**/SKILL.md` 无结果，两个规格文件包含对齐条款；Fail：任一条件不满足。验收锚点：`skills/`，`dev-playbooks/specs/mcp/spec.md`，`dev-playbooks/specs/style-cleanup/spec.md`。
- AC-106 (B/A)：文档理由表述使用“约束：/取舍：/影响：”三段式并可扫描，规则写入 `dev-playbooks/specs/shared-methodology/spec.md`，且在 `README.md`、`docs/使用指南.md`、`docs/Skill详解.md` 中至少各出现一组完整三段式。Pass：共享方法论文档含扫描规则，且 `rg -n "^约束：|^取舍：|^影响：" README.md docs/使用指南.md docs/Skill详解.md` 在每份文档均有匹配；Fail：缺规则或任一文档缺失三段式。验收锚点：`dev-playbooks/specs/shared-methodology/spec.md`，`README.md`，`docs/使用指南.md`，`docs/Skill详解.md`。

## Problem Context

当前 DevBooks 的定位描述在多个文档中存在分散与偏差，读者容易将其理解为工具集合而非协议与工作流集合。长期视野与反短视机制在共享方法论中缺位，导致流程、结构、文本规范与自检入口缺乏统一锚点。MCP 相关描述混用具体服务名，削弱跨工具适配与术语一致性。渐进披露模板与理由三段式规则缺乏统一，影响可扫描性与一致性检查效率。

## What（要做什么）

- 澄清 DevBooks 定位：协议与工作流集合，涵盖流程、文本规范、少量自检脚本；MCP 为可选集成点。
- 建立“长期视野/反短视”机制，落在流程、结构、文本规范与自检脚本入口。
- 增加“人类建议校准”提示词机制，定义触发条件与输出格式，并要求输出最佳方案。
- 统一 Skills 渐进披露模板与层级提示语，确保可扫描与可比对。
- 将 SKILL.md 的 MCP 章节改写为“推荐 MCP 能力类型”，给出能力类型清单与命名规范。
- 文档理由表述统一采用“约束/取舍/影响”三段式。

## Design Rationale

定位澄清采用“协议与工作流集合”的表述，降低与 MCP 的概念冲突并与术语表保持一致。将 MCP 说明收敛为“推荐 MCP 能力类型”，避免绑定具体服务，提升未来替换与跨工具迁移的弹性。引入长期视野与人类建议校准机制，保证流程、结构、文本规范与自检脚本有一致入口。渐进披露模板与三段式理由规则被统一为可扫描结构，以支持一致性闸门与审阅复核。

## Constraints（约束）

- 不修改运行时代码、脚本执行逻辑与 MCP 服务实现；变更范围限于文档与规格。
- 术语遵循 `dev-playbooks/specs/_meta/glossary.md`，新增术语先进入术语表。
- REQ 冲突处理：REQ-MCP-005 与 REQ-STYLE-002 在规格增量中对齐，SKILL.md 仅保留“推荐 MCP 能力类型”，检测与降级细节集中在 MCP 规格与对外文档。
- 渐进披露模板固定标题与行首关键词，便于扫描与一致性检查。
- “人类建议校准”输出仅描述判断与推荐格式，不引入实现步骤。

## Variation Points（变体点）

- Variation Point: 长期尺度阈值覆盖（默认规则；项目可覆盖；覆盖需记录 Decision Log）
- Variation Point: 推荐 MCP 能力类型清单（基础清单固定；项目可裁剪；术语表保持一致）

## Trade-offs

统一模板与三段式规范减少了文档自由度，短期编辑成本上升。将 MCP 细节集中到规格文档降低 SKILL.md 的信息密度，读者需要在多处文档之间切换。新增提示词机制增加文档长度与维护负担，但换来可追溯与长期演进的清晰边界。

### 受影响规格（Spec Trace）

- `dev-playbooks/specs/mcp/spec.md`：REQ-MCP-005
- `dev-playbooks/specs/style-cleanup/spec.md`：REQ-STYLE-002
- `dev-playbooks/specs/shared-methodology/spec.md`：REQ-METH-003（长期视野/反短视机制）、REQ-METH-004（人类建议校准）、REQ-METH-005（约束/取舍/影响规则）
- `dev-playbooks/specs/_meta/glossary.md`：新增术语“人类建议校准”“推荐 MCP 能力类型”“长期视野/反短视”

### 约束/取舍/影响（三段式规则）

约束：理由类段落必须包含行首关键词“约束：/取舍：/影响：”，适用范围为 `README.md`、`docs/`、`dev-playbooks/specs/`、`skills/**/SKILL.md`、变更包文档。
取舍：统一表达换取可扫描与可审核性，接受局部自由度下降。
影响：文档审阅与一致性检查需要覆盖三段式规则。

## Documentation Impact（文档影响）

### 需要更新的文档

| 文档 | 更新原因 | 优先级 |
|------|----------|--------|
| `README.md` | 定位澄清与长期视野入口 | P0 |
| `docs/使用指南.md` | 定位澄清与长期视野提示 | P0 |
| `docs/Skill详解.md` | 定位澄清与渐进披露说明 | P0 |
| `dev-playbooks/docs/推荐MCP.md` | 推荐 MCP 能力类型清单与对照说明 | P0 |
| `dev-playbooks/specs/shared-methodology/spec.md` | 新增长期视野与校准机制 | P0 |
| `dev-playbooks/specs/mcp/spec.md` | REQ-MCP-005 对齐更新 | P0 |
| `dev-playbooks/specs/style-cleanup/spec.md` | REQ-STYLE-002 对齐更新 | P0 |
| `dev-playbooks/specs/_meta/glossary.md` | 新增术语定义 | P0 |
| `skills/` | SKILL.md 渐进披露与 MCP 能力类型更新 | P0 |

### 无需更新的文档

- [ ] 本次变更为内部重构，不影响用户可见功能
- [ ] 本次变更仅修复缺陷，不改变使用方式

### 文档更新检查清单

- [ ] 新增规范与提示词机制已在对外文档中说明
- [ ] 渐进披露模板已在 Skills 文档中统一
- [ ] 能力类型清单与命名规范已在推荐 MCP 文档中更新
- [ ] 术语表包含新增术语并与正文一致

## Architecture Impact（架构影响）

### 无架构变更

- [x] 本次变更不影响模块边界、依赖方向或组件结构
- 原因说明：仅文档与规格更新，不触及运行时逻辑与依赖关系
