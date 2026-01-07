---
name: devbooks-contract-data
description: devbooks-contract-data：定义对外契约与数据（API/事件/schema_version/idempotency_key/兼容策略/迁移与回放），并建议或生成 contract tests。支持隐式变更检测（依赖/配置/构建变更）。用户说"定义契约/OpenAPI/事件协议/Schema/幂等键/兼容策略/数据迁移/隐式变更检测"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：契约与数据（Contract & Data）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `openspec/project.md`（如存在）→ OpenSpec 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/7 契约与数据定义提示词.md`。
3) **隐式变更检测（按需）**：`references/隐式变更检测提示词.md`。

## 脚本

- 隐式变更检测：`scripts/implicit-change-detect.sh <change-id> [--base <commit>] [--project-root <dir>] [--change-root <dir>]`

## 隐式变更检测（扩展功能）

> 来源：《人月神话》第7章"巴比伦塔" — "小组慢慢地修改自己程序的功能，隐含地更改了约定"

隐式变更 = 没有显式声明但会改变系统行为的变更。

**检测范围**：
- 依赖变更（package.json / requirements.txt / go.mod 等）
- 配置变更（*.env / *.config.* / *.yaml 等）
- 构建变更（tsconfig.json / Dockerfile / CI 配置等）

**产物落点**：
- `<change-root>/<change-id>/evidence/implicit-changes.json`

**与 change-check.sh 集成**：
- 在 `apply` / `archive` / `strict` 模式下自动检查隐式变更报告
- 高风险隐式变更需在 `design.md` 中声明
