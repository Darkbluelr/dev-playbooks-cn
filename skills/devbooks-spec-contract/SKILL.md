---
name: devbooks-spec-contract
description: devbooks-spec-contract：定义对外行为规格与契约（Requirements/Scenarios/API/Schema/兼容策略/迁移），并建议或生成 contract tests。合并了原 spec-delta 和 contract-data 的功能。用户说"写规格/spec/契约/OpenAPI/Schema/兼容策略/contract tests"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：规格与契约（Spec & Contract）

> 本 skill 合并了原 `devbooks-spec-delta` 和 `devbooks-contract-data` 的功能，减少选择困难。

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

---

## 产物落点

| 产物类型 | 落点路径 |
|----------|----------|
| 规格 delta | `<change-root>/<change-id>/specs/<capability>/spec.md` |
| 契约计划 | `<change-root>/<change-id>/design.md`（Contract 章节）或独立 `contract-plan.md` |
| Contract Test IDs | 写入 `verification.md` 的追溯矩阵 |
| 隐式变更报告 | `<change-root>/<change-id>/evidence/implicit-changes.json` |

---

## 使用场景判断

| 场景 | 需要做什么 |
|------|-----------|
| 只有行为变化（无 API/Schema） | 只输出 spec.md（Requirements/Scenarios） |
| 有 API/Schema/事件变化 | 输出 spec.md + 契约计划 + Contract Test IDs |
| 有兼容性风险 | 额外输出兼容策略、弃用策略、迁移方案 |
| 依赖/配置/构建变更 | 运行隐式变更检测 |

---

## 执行方式

### 标准流程

1) 先阅读并遵守：`references/项目开发实用提示词.md`
2) 规格部分：按 `references/5 规格变更提示词.md` 输出 Requirements/Scenarios
3) 契约部分：按 `references/7 契约与数据定义提示词.md` 输出契约计划
4) **隐式变更检测（按需）**：`references/隐式变更检测提示词.md`

### 输出结构（一次性产出）

```markdown
## 规格 Delta（Spec）

### Requirements
- REQ-XXX-001: <需求描述>

### Scenarios
- SC-001: <场景描述>
  - Given: ...
  - When: ...
  - Then: ...

---

## 契约计划（Contract）

### API 变更
- 新增/修改端点：`POST /api/v1/orders`
- OpenAPI diff 位置：`contracts/openapi/orders.yaml`

### 兼容策略
- 向后兼容：是/否
- 弃用策略：<如有>
- 迁移方案：<如有>

### Contract Test IDs
| Test ID | 类型 | 覆盖场景 |
|---------|------|----------|
| CT-001 | schema | REQ-XXX-001 |
| CT-002 | behavior | SC-001 |
```

---

## 脚本

- 隐式变更检测：`scripts/implicit-change-detect.sh <change-id> [--base <commit>] [--project-root <dir>] [--change-root <dir>]`

---

## 隐式变更检测（扩展功能）

> 来源：《人月神话》第7章"巴比伦塔" — "小组慢慢地修改自己程序的功能，隐含地更改了约定"

隐式变更 = 没有显式声明但会改变系统行为的变更。

**检测范围**：
- 依赖变更（package.json / requirements.txt / go.mod 等）
- 配置变更（*.env / *.config.* / *.yaml 等）
- 构建变更（tsconfig.json / Dockerfile / CI 配置等）

**与 change-check.sh 集成**：
- 在 `apply` / `archive` / `strict` 模式下自动检查隐式变更报告
- 高风险隐式变更需在 `design.md` 中声明
