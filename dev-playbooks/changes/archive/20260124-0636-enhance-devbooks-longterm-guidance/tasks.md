truth-root=dev-playbooks/specs; change-root=dev-playbooks/changes
# 编码计划：20260124-0636-enhance-devbooks-longterm-guidance

## 主线计划区

- [x] MP1.1 更新用户面向文档定位与三段式理由
  - 关联 AC：AC-101，AC-106
  - 步骤：
    1. 在 `README.md` 添加 DevBooks 定位与 MCP 可选集成说明，并补充“约束/取舍/影响三段式”理由段落。
    2. 在 `docs/使用指南.md` 同步定位与三段式理由段落。
    3. 在 `docs/Skill详解.md` 同步定位与三段式理由段落。
- [x] MP1.2 更新共享方法论规格增量
  - 关联 AC：AC-102，AC-103，AC-106
  - 步骤：
    1. 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/shared-methodology/spec.md` 增补长期视野/反短视机制，覆盖流程、结构、文本规范与自检脚本引用。
    2. 增补“人类建议校准”提示词机制条款，包含触发条件与固定输出字段。
    3. 增补“约束/取舍/影响三段式”规则条款。
- [x] MP1.3 更新术语表规格增量
  - 关联 AC：AC-103
  - 步骤：
    1. 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/_meta/glossary.md` 新增“人类建议校准”术语定义。
    2. 在同一文件新增“推荐 MCP 能力类型”“长期视野/反短视”术语定义。
- [x] MP1.4 对齐 MCP 与 style-cleanup 规格增量
  - 关联 AC：AC-105
  - 步骤：
    1. 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/mcp/spec.md` 更新 REQ-MCP-005 条款，聚焦“推荐 MCP 能力类型”口径。
    2. 在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/specs/style-cleanup/spec.md` 更新 REQ-STYLE-002 条款，删除增强/依赖/模式对比相关表述。
- [x] MP1.5 更新推荐 MCP 对照表与能力类型说明
  - 关联 AC：AC-105
  - 步骤：
    1. 在 `dev-playbooks/docs/推荐MCP.md` 增补能力类型清单与命名规范。
    2. 在同一文档补充“能力类型 → 常见实现”对照表。
- [x] MP1.6 统一 Skills 渐进披露模板
  - 关联 AC：AC-104
  - 步骤：
    1. 在所有 `skills/**/SKILL.md` 增加“渐进披露”章节。
    2. 按统一层级补充“基础层/进阶层/扩展层”标题与对应提示语。
    3. 在基础层填写“目标/输入/输出/边界/证据”行首字段。
- [x] MP1.7 改写 Skills MCP 章节为推荐 MCP 能力类型
  - 关联 AC：AC-105
  - 步骤：
    1. 将所有 `skills/**/SKILL.md` MCP 章节改为“推荐 MCP 能力类型”小节。
    2. 删除“增强/依赖/模式对比”相关表述，保留能力类型清单与命名规范提示。
- [x] MP1.8 规格增量执行 stage/promote 同步
  - 关联 AC：AC-102，AC-103，AC-105，AC-106
  - 步骤：
    1. 运行 `./skills/devbooks-delivery-workflow/scripts/spec-stage.sh 20260124-0636-enhance-devbooks-longterm-guidance --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`。
    2. 确认 `dev-playbooks/specs/_staged/20260124-0636-enhance-devbooks-longterm-guidance` 已生成并包含本次规格增量。
    3. 运行 `./skills/devbooks-delivery-workflow/scripts/spec-promote.sh 20260124-0636-enhance-devbooks-longterm-guidance --project-root . --truth-root dev-playbooks/specs`。
- [x] MP1.9 执行 DevBooks 自检并记录证据
  - 关联 AC：AC-101，AC-104，AC-105，AC-106
  - 步骤：
    1. 运行 `./skills/devbooks-delivery-workflow/scripts/change-check.sh 20260124-0636-enhance-devbooks-longterm-guidance --mode apply --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`。
    2. 运行 `./skills/devbooks-delivery-workflow/scripts/guardrail-check.sh --project-root .`。
    3. 将输出记录在 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/`。

## 临时计划区

- 暂无。

## 断点区

- 最近进展：主线任务已标记完成，等待归档前的严格闸门检查。
- 当前阻塞：无。
- 下一条最短路径：运行严格 change-check 并整理归档证据。
