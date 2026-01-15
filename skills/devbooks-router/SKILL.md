---
name: devbooks-router
description: devbooks-router：DevBooks 工作流入口引导：帮助用户确定从哪个 skill 开始，检测项目当前状态，给出最短闭环路径。用户说"下一步怎么做/从哪开始/按 devbooks 跑闭环/项目状态"等时使用。注意：skill 完成后的路由由各 skill 自己负责，无需调用 router。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Bash
---

# DevBooks：工作流入口引导（Router）

## 定位说明

> **重要**：Router 的职责是**入口引导**，而非每步路由。

| 场景 | 是否使用 Router |
|------|:---------------:|
| "我该从哪开始？" | ✅ 使用 |
| "项目当前状态？" | ✅ 使用 |
| "coder 完成后下一步？" | ❌ 不使用（coder 自己输出） |
| "这个 skill 完成后呢？" | ❌ 不使用（各 skill 自己输出） |

**原则**：每个 skill 完成时会输出自己的下一步推荐，遵循 `_shared/references/偏离检测与路由协议.md`。

---

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 前置：图索引健康检查（自动）

**在路由前自动执行**，检查 CKB 图索引状态：

1. 调用 `mcp__ckb__getStatus` 检查 SCIP 后端
2. 如果 `backends.scip.healthy = false`：
   - 提示用户：「检测到代码图索引未激活，影响分析/调用图等图基能力不可用」
   - 提供手动生成索引的命令（见下方脚本）
   - 继续路由但标注「图基能力降级」

3. 如果 `backends.scip.healthy = true`：
   - 静默通过，继续路由

**检查脚本**（供参考）：
```bash
# 检测语言并生成索引
if [ -f "tsconfig.json" ]; then
  scip-typescript index --output index.scip
elif [ -f "pyproject.toml" ]; then
  scip-python index . --output index.scip
elif [ -f "go.mod" ]; then
  scip-go --output index.scip
fi
```

**降级模式说明**：
- 无索引时，`devbooks-impact-analysis` 退化为 Grep 文本搜索（准确度下降）
- 无索引时，`devbooks-code-review` 无法获取调用图上下文
- 建议在 Apply 阶段前完成索引生成

## 你要做的事

把用户的自然语言请求映射成：
1) 现在处于哪个阶段（proposal / apply / review / archive）
2) 本次变更的“必产物”（proposal/design/tasks/verification）与“按需产物”（spec deltas/contract/c4/evidence）
3) 下一步该用哪个（或哪些）`devbooks-*` Skills
4) 每个产物应落到哪个文件路径

## 输出要求（强制）

1) **先问清楚 2 个最小关键问题**（若上下文里已有答案则不问）：
   - `<change-id>` 是什么？
   - `<truth-root>` / `<change-root>` 在该项目最终取值是什么？
2) 给出“下一步路由结果”（3–6 条即可）：
   - 每条包含：要用的 Skill + 产物路径 + 为什么需要
3) 如果用户明确要你"直接开始产出文件内容"，再进入对应 Skill 的输出模式。

---

## Impact 画像解析（AC-003 / AC-012）

当 `proposal.md` 存在时，Router **应自动解析** Impact 章节以生成更精确的执行计划。

### Impact Profile 结构

```yaml
impact_profile:
  external_api: true/false       # 对外 API 变更
  architecture_boundary: true/false  # 架构边界变更
  data_model: true/false         # 数据模型变更
  cross_repo: true/false         # 跨仓库影响
  risk_level: high/medium/low    # 风险等级
  affected_modules:              # 受影响模块列表
    - name: <module-path>
      type: add/modify/delete
      files: <count>
```

### 解析流程

1. 检测 `proposal.md` 是否存在
2. 若存在，查找 `## Impact` 章节
3. 提取 `impact_profile:` YAML 块
4. 验证必填字段：`external_api`、`risk_level`、`affected_modules`

### 基于 Impact 画像的路由增强

| Impact 字段 | 值 | 自动追加 Skill |
|-------------|-----|---------------|
| `external_api: true` | - | `devbooks-spec-contract` |
| `architecture_boundary: true` | - | `devbooks-design-doc`（确保 Architecture Impact 章节完整） |
| `cross_repo: true` | - | 手动分析跨仓库影响 |
| `risk_level: high` | - | `devbooks-proposal-challenger` + `devbooks-proposal-judge` |
| `affected_modules` 数量 > 5 | - | `devbooks-impact-analysis`（深度分析） |

### 执行计划输出格式

```markdown
## 执行计划（基于 Impact 画像）

### 必须执行
1. `devbooks-proposal-author skill` → proposal.md（提案已存在，跳过）
2. `devbooks-design-doc skill` → design.md（必须）
3. `devbooks-implementation-plan skill` → tasks.md（必须）

### 建议执行（基于 Impact 分析）
4. `devbooks-spec-contract skill` → specs/**（检测到 external_api: true）
5. `devbooks-design-doc skill` → design.md Architecture Impact 章节（检测到 architecture_boundary: true）

### 可选执行
6. `devbooks-impact-analysis skill` → 深度影响分析（affected_modules > 5）
```

### 解析失败处理（AC-012）

**无 Impact 画像时**：

```
⚠️ proposal.md 中未找到 Impact 画像。

缺失项：
- Impact 章节不存在
- 或 impact_profile YAML 块缺失

建议动作：
1. 运行 `devbooks-impact-analysis skill` 生成影响分析
2. 或直接使用相应 skill

skill 列表：
- devbooks-design-doc skill → 设计文档
- devbooks-implementation-plan skill → 编码计划
- devbooks-spec-contract skill → 规格定义
```

**YAML 解析失败时**：

```
⚠️ Impact 画像解析失败。

错误：<具体错误信息>

建议动作：
1. 检查 proposal.md 中 impact_profile YAML 格式
2. 或直接使用相应 skill 绕过 Router
```

---

## 路由规则（质量优先默认）

### A) Proposal（提案阶段）

触发信号：用户说“提案/为什么要改/范围/风险/坏味道重构/要不要做/先别写代码”等。

默认路由：
- `devbooks-proposal-author` → `(<change-root>/<change-id>/proposal.md)`（必须）
- `devbooks-design-doc` → `(<change-root>/<change-id>/design.md)`（非小改动必须；只写 What/Constraints + AC-xxx）
- `devbooks-implementation-plan` → `(<change-root>/<change-id>/tasks.md)`（必须；只从设计推导）

按需追加（满足条件才加）：
- **跨模块/影响不清晰**：`devbooks-impact-analysis`（建议写回 proposal Impact）
- **风险/争议/取舍明显**：`devbooks-proposal-challenger` + `devbooks-proposal-judge`（独立对话，对辩后写回 Decision Log）
- **对外行为/契约/数据不变量变化**：`devbooks-spec-contract` → `(<change-root>/<change-id>/specs/**)` + `design.md` Contract 章节
  - 若需要"确定性创建 spec delta 文件/避免路径写错"：`change-spec-delta-scaffold.sh <change-id> <capability> ...`
- **模块边界/依赖方向/架构形态变化**：确保 `devbooks-design-doc` 输出完整的 Architecture Impact 章节 → 归档时由 `devbooks-archiver` 合并到 `(<truth-root>/architecture/c4.md)`

硬约束提醒：
- proposal 阶段禁止写实现代码；实现发生在 apply 阶段并以测试/闸门为完成判据。
- 若需要“确定性落盘骨架/避免漏文件”：优先运行 `devbooks-delivery-workflow` 的脚本
  - `change-scaffold.sh <change-id> ...`
  - `change-check.sh <change-id> --mode proposal ...`

### B) Apply（实现阶段：Test Owner / Coder）

触发信号：用户说“开始实现/跑测试/修复失败/按 tasks 做/让闸门全绿”等。

默认路由（强制角色隔离）：
- Test Owner（独立对话/独立实例）：`devbooks-test-owner`
  - 产物：`(<change-root>/<change-id>/verification.md)` + `tests/**`
  - 先跑出 **Red** 基线，并记录证据（如 `(<change-root>/<change-id>/evidence/**)`）
- Coder（独立对话/独立实例）：`devbooks-coder`
  - 输入：`tasks.md` + 测试报错 + 代码库
  - 禁止修改 `tests/**`

apply 阶段的确定性检查（推荐）：
- Test Owner：`change-check.sh <change-id> --mode apply --role test-owner ...`
- Test Owner（证据落盘）：`change-evidence.sh <change-id> --label red-baseline -- <test-command>`
- Coder：`change-check.sh <change-id> --mode apply --role coder ...`（会额外检查 git diff 下 `tests/**` 未被修改）

LSC（大规模同质化修改）建议：
- 先用 `change-codemod-scaffold.sh <change-id> --name <codemod-name> ...` 生成 codemod 脚本骨架，再用脚本批量变更并记录 evidence

### C) Review（评审阶段）

触发信号：用户说"review/坏味道/可维护性/依赖风险/一致性"等。

默认路由：
- `devbooks-code-review`（输出可执行建议；不改业务结论、不改 tests）
- `devbooks-test-reviewer`（评审测试质量、覆盖率、边界条件）

### D) Docs Sync（文档同步）

触发信号：用户说"更新文档/同步文档/README 更新/API 文档"等。

默认路由：
- `devbooks-docs-sync`（维护用户文档与代码一致性）
  - 增量模式：在变更包上下文中，只更新本次 change 相关的文档
  - 全局模式：带 --global 参数，扫描全部文档并生成差异报告

**触发条件**（非每次 change 都需要）：
- 新增/修改/删除公共 API
- 变更用户可见行为
- 修改配置项
- 变更 CLI 命令

### E) Archive（归档阶段）

触发信号：用户说"归档/合并 specs/关账/收尾"等。

默认路由：
- 若本次产生了 spec delta：`devbooks-archiver`（先修剪 `<truth-root>/**` 再归档合并）
- 若需要回写设计决策：`devbooks-design-backport`（按需）
- 若影响用户文档：`devbooks-docs-sync`（确保文档与代码一致）

归档前的确定性检查（推荐）：
- `change-check.sh <change-id> --mode strict ...`（要求：proposal 已 Approved、tasks 全勾选、trace matrix 无 TODO、结构守门决策已填写）

### F) Prototype（原型模式）

> 来源：《人月神话》第11章"未雨绸缪" — "第一个开发的系统并不合用...为舍弃而计划"

触发信号：用户说"先做原型/快速验证/spike/--prototype/扔掉式原型/Plan to Throw One Away"等。

**原型模式适用场景**：
- 技术方案不确定，需要快速验证可行性
- 第一次做某类功能，预期会重写
- 需要探索 API/库/框架的实际行为

**默认路由（原型轨道约束）**：

1. 创建原型骨架：
   - `change-scaffold.sh <change-id> --prototype ...`
   - 产物：`(<change-root>/<change-id>/prototype/)`

2. Test Owner（独立对话）使用 `devbooks-test-owner --prototype`：
   - 产物：`(<change-root>/<change-id>/prototype/characterization/)`
   - 生成**表征测试**（记录实际行为）而非验收测试
   - **不需要 Red 基线**——表征测试断言的是"现状"

3. Coder（独立对话）使用 `devbooks-coder --prototype`：
   - 输出路径：`(<change-root>/<change-id>/prototype/src/)`
   - 允许绕过 lint/复杂度阈值
   - **禁止直接落到仓库 `src/`**

**硬约束（必须遵守）**：
- 原型代码与生产代码**物理隔离**（不同目录）
- Test Owner 与 Coder 仍必须**独立对话/独立实例**（角色隔离不变）
- 原型提升到生产需要**显式触发** `prototype-promote.sh <change-id>`

**原型提升到生产的前置条件**：
1. 创建生产级 `design.md`（从原型学习中提炼 What/Constraints/AC-xxx）
2. Test Owner 产出验收测试 `verification.md`（替代表征测试）
3. 完成 `prototype/PROTOTYPE.md` 中的提升检查清单
4. 运行 `prototype-promote.sh <change-id>` 并通过所有闸门

**原型丢弃流程**：
1. 记录学习到的关键洞察到 `proposal.md` 的 Decision Log
2. 删除 `prototype/` 目录

## DevBooks Skill 适配

DevBooks 使用 `devbooks-proposal-author skill`、`devbooks-test-owner/coder skill`、`devbooks-archiver skill` 作为入口。
按上述 A/B/C/D 路由即可，产物路径以项目指路牌里 `<truth-root>/<change-root>` 的映射为准。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的路由策略。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测变更包是否存在
2. 检测已有产物（proposal/design/tasks/verification）
3. 推断当前阶段（proposal/apply/archive）
4. 根据阶段选择默认路由

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **新变更** | 变更包不存在或为空 | 路由到 proposal 阶段，建议创建 proposal.md |
| **进行中** | 变更包存在，有部分产物 | 根据缺失产物推荐下一步 |
| **待归档** | 闸门通过，`evidence/green-final/` 存在 | 路由到 archive 阶段 |

### 检测输出示例

```
检测结果：
- 变更包状态：存在
- 已有产物：proposal.md ✓, design.md ✓, tasks.md ✓, verification.md ✗
- 当前阶段：apply
- 建议路由：devbooks-test-owner（先建立 Red 基线）
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若 CKB 可用 → 在路由建议中标注"图基能力已激活"
3. 若超时或失败 → 在路由建议中标注"图基能力降级"，建议手动生成 SCIP 索引

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 影响分析推荐 | 使用 CKB 精确分析 | 使用 Grep 文本搜索 |
| 代码导航 | 符号级跳转可用 | 文件级搜索 |
| 热点检测 | CKB 实时分析 | 不可用 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 索引未激活，图基能力（影响分析、调用图等）将降级。
建议手动生成 SCIP 索引以启用完整功能。
```
