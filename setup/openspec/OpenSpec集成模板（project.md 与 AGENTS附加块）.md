# OpenSpec 集成模板（把 DevBooks `devbooks-*` Skills 接入项目上下文）

> 目标：不 fork OpenSpec、不改会被 `openspec update` 覆盖的文件；只通过 `openspec/project.md` + 根 `AGENTS.md`（managed block 之外）注入你的工作方式。
>
> 映射关系（OpenSpec）：
> - `<truth-root>` → `openspec/specs/`
> - `<change-root>` → `openspec/changes/`

---

## 1) `openspec/project.md` 推荐追加内容（可复制）

### Directory Roots（目录根）

- `openspec/specs/`（当前真理源）
- `openspec/changes/`（变更包）

### Project Profile（项目画像入口，强烈建议）

- 项目画像（技术栈/命令/约定/闸门）：`openspec/specs/_meta/project-profile.md`
- 统一语言表（术语）：`openspec/specs/_meta/glossary.md`
- 架构地图（C4）：`openspec/specs/architecture/c4.md`

### Truth Sources（真理源优先级）

1. `openspec/specs/`：当前系统真理（最高优先级）
2. `openspec/changes/<change-id>/`：本次变更包（proposal/design/tasks/verification/spec deltas）
3. 代码与测试：以仓库事实为准（测试/构建输出是确定性锚点）
4. 聊天记录：非权威，必要时需回写到上述文件

### Agent Roles（角色隔离）

- Design Owner：只写 What/Constraints + AC-xxx（禁止写实现步骤）
- Spec Owner：只写规格 delta（Requirements/Scenarios）
- Planner：只从设计推导 tasks（不得参考 tests/）
- Test Owner：只从设计/规格推导测试（不得参考 tasks/）；**必须独立对话/独立实例**
- Proposal Author：只写 `proposal.md`（含 Debate Packet）
- Proposal Challenger：只出质疑报告（必须给结论）
- Proposal Judge：只出裁决报告（必须明确 Approved/Revise/Rejected）
- Coder：按 tasks 实现并跑闸门（不得反向改写设计意图）；**必须独立对话/独立实例；禁止修改 tests/**，如需调整测试只能交还 Test Owner
- Reviewer：只做可读性/依赖/风格审查；不改 tests/，不改设计
- Impact Analyst：跨模块改动先做影响分析再写代码

### Test Integrity（测试完整性与红绿循环）

- 允许并行，但**测试与实现必须是独立对话**；禁止在同一会话内既写 tests 又写实现。
- Test Owner 先产出 tests/verification，并运行以确认 **Red** 基线；记录失败证据到 `openspec/changes/<id>/evidence/`（若无证据目录可新建）。
- Coder 仅以 `openspec/changes/<id>/tasks.md` + 测试报错 + 代码库为输入，目标是让测试 **Green**；严禁修改 tests。

### Structural Quality Guardrails（结构质量守门）

- 若出现“代理指标驱动”的要求（行数/文件数/机械拆分/命名格式），必须评估其对内聚/耦合/可测试性的影响。
- 触发风险信号时必须停线：记录为决策问题并回到 proposal/design 处理，不得直接执行。
- 质量闸门优先级：复杂度、耦合度、依赖方向、变更频率、测试质量 > 代理指标。

### Definition of Done（DoD，MECE）

每次变更至少声明覆盖到哪些闸门；缺失项必须写原因与补救计划（建议写入 `openspec/changes/<id>/verification.md`）：
- 行为（Behavior）：unit/integration/e2e（按项目类型最小集）
- 契约（Contract）：OpenAPI/Proto/Schema/事件 envelope + contract tests
- 结构（Structure）：架构适配函数（依赖方向/分层/禁止循环）
- 静态与安全（Static/Security）：lint/typecheck/build + SAST/secret scan
- 证据（Evidence，按需）：截图/录像/报告

### DevBooks Skills（开发作战手册 Skills）

本项目使用 DevBooks 的 `devbooks-*` Skills（全局安装后在所有项目可用）：

**角色类：**
- Router（下一步路由）：`devbooks-router` → 给出阶段判断 + 下一步该用哪个 Skill + 产物落点（支持 Prototype 模式）
- Design（设计文档）：`devbooks-design-doc` → `openspec/changes/<id>/design.md`
- Spec delta（规格 delta）：`devbooks-spec-delta` → `openspec/changes/<id>/specs/<capability>/spec.md`
- Plan（编码计划）：`devbooks-implementation-plan` → `openspec/changes/<id>/tasks.md`
- Test（测试与追溯）：`devbooks-test-owner` → `openspec/changes/<id>/verification.md` + `tests/**`
- Proposal Author（提案撰写）：`devbooks-proposal-author` → `openspec/changes/<id>/proposal.md`
- Proposal Challenger（提案质疑）：`devbooks-proposal-challenger` → 质疑报告（不写入变更包）
- Proposal Judge（提案裁决）：`devbooks-proposal-judge` → 裁决报告（写回 `proposal.md`）
- Coder（实现）：`devbooks-coder` → 实现与验证（不改 tests）
- Reviewer（代码评审）：`devbooks-code-review` → Review Notes（不写入变更包）
- Garden（规格园丁）：`devbooks-spec-gardener` → 归档前修剪 `openspec/specs/`
- Impact（影响分析）：`devbooks-impact-analysis` → 写入 `openspec/changes/<id>/proposal.md` 的 Impact 部分
- Contracts（契约与数据）：`devbooks-contract-data` → `contracts/**` + contract tests
- C4 map（架构地图）：`devbooks-c4-map` → `openspec/specs/architecture/c4.md`
- Backport（回写设计）：`devbooks-design-backport` → 回写 `openspec/changes/<id>/design.md`

**工作流类：**
- Workflow（交付验收骨架）：`devbooks-delivery-workflow` → 变更闭环 + 确定性脚本
- Proposal Debate（提案对辩工作流）：`devbooks-proposal-debate-workflow` → Author/Challenger/Judge 三角对辩
- Brownfield Bootstrap（存量初始化）：`devbooks-brownfield-bootstrap` → 当 `openspec/specs/` 为空时生成项目画像与基线

**度量类：**
- Entropy Monitor（熵度量）：`devbooks-entropy-monitor` → 系统熵度量（结构熵/变更熵/测试熵/依赖熵）+ 重构预警 → `openspec/specs/_meta/entropy/`

### OpenSpec 三阶段与 DevBooks 角色映射

> OpenSpec 有 proposal/apply/archive 三阶段命令。DevBooks 为每个阶段提供角色隔离与质量闸门。

#### 阶段一：Proposal（禁止写实现代码）

**命令**：`/openspec:proposal <描述>` 或 `/devbooks-openspec-proposal`

**可用角色与 Skills**：
| 角色 | Skill | 产物 |
|------|-------|------|
| Router | `devbooks-router` | 阶段判断 + 下一步建议 |
| Proposal Author | `devbooks-proposal-author` | `proposal.md`（Why/What/Impact + Debate Packet）|
| Proposal Challenger | `devbooks-proposal-challenger` | 质疑报告（风险/遗漏/不一致）|
| Proposal Judge | `devbooks-proposal-judge` | 裁决报告（Approved/Revise/Rejected → 写回 proposal.md）|
| Design Owner | `devbooks-design-doc` | `design.md`（What/Constraints + AC-xxx）|
| Spec Owner | `devbooks-spec-delta` | `specs/<capability>/spec.md`（Requirements/Scenarios）|
| Planner | `devbooks-implementation-plan` | `tasks.md`（编码计划，不得参考 tests/）|
| Impact Analyst | `devbooks-impact-analysis` | 影响分析（写入 proposal.md 的 Impact 部分）|

**典型流程**：
```
/openspec:proposal <描述>
  → devbooks-router（判断阶段）
  → devbooks-proposal-author（撰写提案）
  → devbooks-proposal-challenger（质疑）
  → devbooks-proposal-judge（裁决）
  → devbooks-design-doc（设计文档）
  → devbooks-spec-delta（规格增量，如有对外变更）
  → devbooks-implementation-plan（编码计划）
  → openspec validate <id> --strict
```

**特殊口令**：
- **"存量初始化"**：当 `openspec/specs/` 为空时，先使用 `devbooks-brownfield-bootstrap` 生成项目画像与基线
- **"--prototype"**：技术方案不确定时，使用 `devbooks-router` 的 Prototype 模式，产物隔离到 `prototype/` 目录

---

#### 阶段二：Apply（角色隔离，必须指定角色）

**命令**：`/openspec:apply <role> <change-id>` 或 `/devbooks-openspec-apply <role> <change-id>`

**关键约束**：
- **必须指定角色**：test-owner / coder / reviewer
- **未指定角色时**：显示菜单等待用户选择，**禁止自动执行**
- **角色隔离**：Test Owner 与 Coder 必须独立对话/独立实例

**可用角色与 Skills**：
| 角色 | Skill | 产物 | 约束 |
|------|-------|------|------|
| Test Owner | `devbooks-test-owner` | `verification.md` + `tests/**` | 先跑 Red 基线，记录证据到 `evidence/` |
| Coder | `devbooks-coder` | 实现代码 | **禁止修改 tests/**，以测试为唯一完成判据 |
| Reviewer | `devbooks-code-review` | 评审意见 | 只做可读性/依赖/风格审查，不改代码 |

**典型流程**：
```
# 步骤 1：Test Owner（独立对话）
/openspec:apply test-owner <id>
  → devbooks-test-owner
  → 产出 verification.md + tests/
  → 跑 Red 基线，记录失败证据

# 步骤 2：Coder（独立对话）
/openspec:apply coder <id>
  → devbooks-coder
  → 按 tasks.md 实现
  → 让测试 Green（禁止改 tests）

# 步骤 3：Reviewer
/openspec:apply reviewer <id>
  → devbooks-code-review
  → 输出评审意见
```

---

#### 阶段三：Archive（规格合并与归档）

**命令**：`/openspec:archive <change-id>` 或 `/devbooks-openspec-archive`

**可用角色与 Skills**：
| 角色 | Skill | 产物 |
|------|-------|------|
| Spec Gardener | `devbooks-spec-gardener` | 修剪后的 `openspec/specs/`（去重/合并/删除过时）|
| Design Backport | `devbooks-design-backport` | 回写 `design.md`（实现中发现的新约束/冲突）|

**典型流程**：
```
/openspec:archive <id>
  → devbooks-spec-gardener（归档前修剪）
  → devbooks-design-backport（如有设计回写需求）
  → openspec archive <id>
  → 验证 specs 更新是否符合预期
```

---

### 其他快捷口令

- **Prototype 模式**（技术方案不确定时）：
  - 在 proposal 阶段输入口令 **"--prototype"** 或说"先做原型/spike/快速验证"
  - 产物目录：`openspec/changes/<change-id>/prototype/`
  - 约束：原型代码与生产代码物理隔离；Test Owner 产出表征测试（不需要 Red 基线）
  - 提升到生产：`prototype-promote.sh <change-id> ...`

- **定期熵度量**（代码健康体检）：
  - 使用 `devbooks-entropy-monitor` Skill
  - 产出 `openspec/specs/_meta/entropy/entropy-report-YYYY-MM-DD.md`
  - 建议频率：小型项目每周、中型项目每日、大型项目每次合并

### C4（架构地图）

- 权威 C4 地图：`openspec/specs/architecture/c4.md`
- 每次变更的设计文档只写 C4 Delta（本次新增/修改/移除哪些元素）

---

## 2) 根 `AGENTS.md` 的“附加块”模板（放在 OpenSpec managed block 之后）

> OpenSpec 会用 `<!-- OPENSPEC:START -->...<!-- OPENSPEC:END -->` 管理一段内容；你的自定义规则请放在 `<!-- OPENSPEC:END -->` 之后，避免被覆盖。

建议追加：

- **配置发现**：在回答任何问题或写任何代码前，按以下顺序查找配置：
  1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
  2. `openspec/project.md`（如存在）→ OpenSpec 协议
  3. `project.md`（如存在）→ template 协议
- 找到配置后，先阅读 `agents_doc`（规则文档），再执行任何操作。
- 在回答任何问题或写任何代码前，先阅读 `openspec/project.md`。
- 进一步阅读项目画像与约定：`openspec/specs/_meta/project-profile.md`（技术栈/命令/约定/闸门）。
- 若存在统一语言表：先阅读 `openspec/specs/_meta/glossary.md` 并遵循术语约束。
- Test Owner 与 Coder 必须独立对话/独立实例；Coder 禁止修改 tests/，如需调整测试必须交还 Test Owner。
- 若出现“代理指标驱动”的要求（行数/文件数/机械拆分/命名格式），必须停线评估并回到 proposal/design 处理。
- 当你看到用户请求“存量初始化/基线建立”或检测到 `openspec/specs/` 为空：先使用 `devbooks-brownfield-bootstrap` Skill 生成基线与项目画像，再进入正常 proposal/apply/archive。
- 对架构/跨模块/对外契约变更：先使用 `devbooks-impact-analysis` Skill 做影响分析，再进入 proposal。
- 任何新功能/破坏性变更/架构改动：必须先创建 `openspec/changes/<id>/`（proposal/design/tasks/spec deltas/verification），审核通过后才可实现。
- `docs/` 仅用于对外说明；开发使用说明、验收追溯、MANUAL-* 清单优先写入本次变更包的 `verification.md`。
