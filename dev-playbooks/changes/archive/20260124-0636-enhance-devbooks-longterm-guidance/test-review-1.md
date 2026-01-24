# Test Review Report: 20260124-0636-enhance-devbooks-longterm-guidance

## 概览
- 评审日期：2026-01-24
- 评审范围：`tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats`，辅助脚本 `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_helper.bash`
- 测试文件数：3（BATS），辅助脚本 1
- 问题总数：5（Critical: 0, Major: 2, Minor: 3）

## 覆盖充分性
> 说明：覆盖状态基于测试存在性判断，与运行结果无关。

| AC-ID | 测试文件 | 覆盖状态 | 备注 |
|---|---|---|---|
| AC-101 | `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats` | ✅ 已覆盖 | 关键字存在性检查，未约束文档内一致段落/位置 |
| AC-102 | `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` | ✅ 已覆盖 | 关键字存在性检查，未验证结构化呈现 |
| AC-103 | `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` | ✅ 已覆盖 | 术语行首匹配 + 关键字存在性检查 |
| AC-104 | `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_skills_templates.bats` | ✅ 已覆盖 | 标题与关键字检查未限定在“渐进披露”区块 |
| AC-105 | `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_skills_templates.bats`；`tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` | ✅ 已覆盖 | 仅验证术语/禁用词存在性与排除 |
| AC-106 | `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats`；`tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats` | ✅ 已覆盖 | 行首规则校验，未覆盖缩进/列表形式 |

## 边界与异常路径
- 目前测试集中在“存在性/关键词”断言，缺少对结构一致性、段落范围与语义一致性的边界验证（例如同一定位段落的完整性）。
- 行首断言严格使用 `^约束：` / `^取舍：` / `^影响：`，如果文档采用缩进或列表样式，会产生漏报风险。

## 可维护性
- 多处关键词列表分散在测试内（如定位要点、长期视野要素、校准字段），后续词条变更需要多点同步，维护成本偏高。
- 对 `skills/**/SKILL.md` 的全量扫描在新增 Skill 时会带来持续维护压力，建议引入清单或分组范围以降低噪音。

## 潜在误报
- `协议/工作流/文本规范` 等泛化关键词可能在非定位段落出现，导致“文档定位一致”的误报（通过但不一致）。
- `目标：/输入：/输出：/边界：/证据：` 的行首检查未限定在“渐进披露”区块内，可能在其它章节出现而误报通过。
- `MCP 增强/依赖的 MCP 服务/增强模式 vs 基础模式` 的全量排除在“弃用说明/对照表”场景下会产生误报（判定失败）。

## 问题清单

### Major (建议修复)
1. **[M-001]** `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats:24` - 文档定位一致性仅做关键词存在性校验，缺少对同一定位段落/一致表述的约束，可能“通过但不一致”。
2. **[M-002]** `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_skills_templates.bats:25` - 渐进披露模板的关键字校验未限定在“渐进披露”区块或分层内部，存在通过但模板未落在正确结构的风险。

### Minor (可选修复)
1. **[m-001]** `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats:24` - “非 MCP 工具”与“可选 MCP 集成点”正则对空格与表达方式敏感，存在漏报风险（例如“非MCP工具”）。
2. **[m-002]** `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_docs_positioning.bats:83`、`tests/20260124-0636-enhance-devbooks-longterm-guidance/test_specs_alignment.bats:257` - 行首三段式规则过于严格，若采用缩进或列表写法会被误判为缺失。
3. **[m-003]** `tests/20260124-0636-enhance-devbooks-longterm-guidance/test_skills_templates.bats:103` - 旧 MCP 术语的全局排除在“弃用说明/对照表”场景下可能产生误报。

## 建议改进
1. 在“文档定位一致”类测试中限定同一段落锚点（例如固定小节标题或块引用），并对该段落内的关键要素做校验。
2. 对“渐进披露”模板，提取该区块文本后再校验分层标题与“目标/输入/输出/边界/证据”的结构一致性。
3. 放宽三段式规则的行首匹配（允许可选缩进或列表符），降低漏报风险。
4. 对旧 MCP 术语的排除规则增加上下文过滤（如忽略“弃用说明/对照表”标题下的内容），避免误报。

## 评审结论
**结论**：Approve

**判定依据**：
- Critical 问题数：0
- Major 问题数：2
- AC 覆盖率：6/6（100%）

---
*此报告由 devbooks-test-reviewer 生成*
