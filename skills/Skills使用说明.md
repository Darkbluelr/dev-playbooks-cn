# DevBooks Skills 速查表（作用 / 场景 / 话术）

默认按 DevBooks 项目示例写路径：
- `<truth-root>` = `dev-playbooks/specs`
- `<change-root>` = `dev-playbooks/changes`
- `<change-id>` = 本次变更包目录名（动词开头）

如果你不是 DevBooks：把 `dev-playbooks/specs` / `dev-playbooks/changes` 替换成你项目“指路牌文件”里定义的 `<truth-root>` / `<change-root>`。

---

## `devbooks-router`（Router）

- 作用：把你的自然语言请求路由成下一步该用哪些 `devbooks-*` skills + 每个产物落点路径。
- **图索引健康检查**：路由前自动调用 `mcp__ckb__getStatus` 检查 SCIP 索引状态，若不可用会提示生成索引。
- 使用场景：
  - 你不确定当前属于 proposal/apply/review/archive 哪个阶段
  - 你不知道该先写 proposal / design / spec / tasks / tests 哪个
  - 你想让 AI 给出"最短闭环"而不是堆步骤
  - 你想使用 **Prototype 模式**（技术方案不确定，需要快速验证）
- 使用话术（可直接复制）：
  ```text
  你现在是 Router。请点名使用 `devbooks-router`。
  先读：`dev-playbooks/project.md`
  先问我 2 个问题：`<change-id>` 是什么？`<truth-root>/<change-root>` 在本项目的取值是什么？
  然后给出下一步要用的 Skills（按顺序）+ 每个产物应落到的文件路径。

  我的当前诉求是：
  <一句话描述你要做什么 + 约束/边界>
  ```
- Prototype 模式话术（技术方案不确定时）：
  ```text
  你现在是 Router。请点名使用 `devbooks-router`，并启用 **Prototype 模式**。
  先读：`dev-playbooks/project.md`

  我想做一个"扔掉式原型"来验证技术可行性（Plan to Throw One Away）。
  请按原型轨道路由：
  1) 创建原型骨架：`change-scaffold.sh <change-id> --prototype ...`
  2) Test Owner 产出表征测试（不需要 Red 基线）
  3) Coder 在 `prototype/src/` 实现（允许绕过闸门，禁止落到仓库 src/）
  4) 验证完成后告诉我：如何提升到生产（`prototype-promote.sh`）或如何丢弃

  我的当前诉求是：
  <一句话描述你要验证什么 + 技术疑问/假设>
  ```

---

## `devbooks-proposal-author`（Proposal Author）

- 作用：产出 `proposal.md`（Why/What/Impact + Debate Packet），作为后续 Design/Spec/Plan 的入口（proposal 阶段禁止写代码）。
- 使用场景：
  - 新功能 / 行为变更 / 重构提案 / 为什么要改
  - 需要把范围、风险、回滚、验收口径说清楚再动手
- 使用话术：
  ```text
  你现在是 Proposal Author。请点名使用 `devbooks-proposal-author`，按 DevBooks proposal 阶段执行（禁止写实现代码）。
  先读：`dev-playbooks/project.md`
  请你先生成一个动词开头的 `<change-id>`，并在输出里重复 3 次让我确认。
  然后写：`dev-playbooks/changes/<change-id>/proposal.md`（必须包含 Debate Packet）。
  额外要求：proposal 的 Impact 里必须写清 `价值信号与观测口径`、`价值流瓶颈假设（排队点）`（不会写就填“无”）。

  我的需求是：
  <一句话需求 + 背景 + 约束>
  ```

---

## `devbooks-impact-analysis`（Impact Analyst）

- 作用：跨模块/跨文件/对外契约变更前做影响分析，把结论写回 `proposal.md` 的 Impact 部分。
- **双模式分析**：
  - **图基分析**（SCIP 可用时）：使用 `analyzeImpact`/`findReferences`/`getCallGraph` 进行高精度分析
  - **文本搜索**（降级模式）：使用 `Grep`/`Glob` 进行关键字搜索
- 使用场景：
  - 你要改很多文件 / 不确定受影响面 / 可能破坏兼容
  - “看起来只是改一处”，但担心跨模块漏改
- 使用话术：
  ```text
  你现在是 Impact Analyst。请点名使用 `devbooks-impact-analysis`（禁止写代码）。
  先读：`dev-playbooks/project.md`、`dev-playbooks/changes/<change-id>/proposal.md`、`dev-playbooks/specs/**`
  请输出影响分析（Scope/Impacts/Risks/Minimal Diff/Open Questions），并把结论回填到：
  `dev-playbooks/changes/<change-id>/proposal.md` 的 Impact 部分。
  ```

---

## `devbooks-proposal-challenger`（Proposal Challenger）

- 作用：对 `proposal.md` 发起质疑，只输出“质疑报告”并必须给结论（Approve/Revise/Reject），不改文件。
- 使用场景：
  - 风险高、争议大、取舍多
  - 想要“强约束审查”，避免提案含糊通过
- 使用话术：
  ```text
  你现在是 Proposal Challenger。请点名使用 `devbooks-proposal-challenger`。
  只读取：`dev-playbooks/changes/<change-id>/proposal.md`（如有再读 `design.md` / `dev-playbooks/specs/**`）
  只输出“质疑报告”（结论必须 `Approve | Revise | Reject`），不要修改任何文件。
  ```

---

## `devbooks-proposal-judge`（Proposal Judge）

- 作用：对 proposal 阶段做裁决，给出 `Approved | Revise | Rejected` 并写回 `proposal.md` 的 Decision Log。
- 使用场景：
  - 你已经有 Challenger 报告，需要最终裁决与“必须修改项/验证要求”
- 使用话术：
  ```text
  你现在是 Proposal Judge。请点名使用 `devbooks-proposal-judge`。
  输入：`dev-playbooks/changes/<change-id>/proposal.md` + 我粘贴的 Challenger 报告
  请给出裁决（`Approved | Revise | Rejected`），并把裁决与“必须修改项/验证要求”写回：
  `dev-playbooks/changes/<change-id>/proposal.md` 的 Decision Log（禁止 Pending）。
  ```

---

## `devbooks-proposal-debate-workflow`（Proposal Debate Workflow）

- 作用：把“提案-质疑-裁决”跑成一套三角对辩流程（Author/Challenger/Judge 角色隔离），并确保 Decision Log 状态明确。
- 使用场景：
  - 你想强制三角色对抗来提高提案质量
  - 团队里经常“风险没说清就开工”
- 使用话术：
  ```text
  你现在是 Proposal Debate Orchestrator。请点名使用 `devbooks-proposal-debate-workflow`。
  先读：`dev-playbooks/project.md`
  约束：Author/Challenger/Judge 必须独立对话/独立实例；如果我无法提供独立对话，你就停止并说明原因。
  目标：最终 `dev-playbooks/changes/<change-id>/proposal.md` 的 Decision Log 状态必须为 Approved/Revise/Rejected（禁止 Pending）。
  请你按工作流逐步告诉我：每一个独立对话里我要复制粘贴的指令是什么，以及每一步需要我把什么结果贴回当前对话。

  我的需求是：
  <一句话需求 + 背景 + 约束>
  ```

---

## `devbooks-design-doc`（Design Owner / Design Doc）

- 作用：产出 `design.md`，只写 What/Constraints + AC-xxx（禁止写实现步骤），作为测试与计划的黄金真理。
- 使用场景：
  - 非小改动
  - 需要明确约束、验收口径、边界与不变量
- 使用话术：
  ```text
  你现在是 Design Owner。请点名使用 `devbooks-design-doc`（禁止写实现步骤）。
  先读：`dev-playbooks/project.md`、`dev-playbooks/changes/<change-id>/proposal.md`
  请写：`dev-playbooks/changes/<change-id>/design.md`（只写 What/Constraints + AC-xxx）。
  ```

---

## `devbooks-spec-contract`（Spec & Contract Owner）【新】

> 本 skill 合并了原 `devbooks-spec-delta` 和 `devbooks-contract-data` 的功能，减少选择困难。

- 作用：定义对外行为规格与契约（Requirements/Scenarios/API/Schema/兼容策略），并建议或生成 contract tests。
- 使用场景：
  - 对外行为/契约/数据不变量变化
  - OpenAPI/Proto/事件 envelope/schema/配置格式 变更
  - 需要补兼容策略、弃用策略、迁移与回放
- 使用话术：
  ```text
  你现在是 Spec & Contract Owner。请点名使用 `devbooks-spec-contract`。
  先读：`dev-playbooks/changes/<change-id>/proposal.md`、`dev-playbooks/changes/<change-id>/design.md`（如有）
  请一次性输出：
  - 规格 delta：`dev-playbooks/changes/<change-id>/specs/<capability>/spec.md`（Requirements/Scenarios）
  - 契约计划：写入 `design.md` 的 Contract 章节（API 变更 + 兼容策略 + Contract Test IDs）
  如有隐式变更风险，运行：`implicit-change-detect.sh`
  ```

---

## `devbooks-c4-map`（C4 Map Maintainer）

- 作用：维护/更新项目的权威 C4 架构地图（当前真理），并按变更输出 C4 Delta。
- 使用场景：
  - **Proposal 阶段**：需要在 `design.md` 里写清“边界/依赖方向变化”（只写 **C4 Delta**，不改当前真理）
  - **Review/Archive 阶段**：变更已实现并准备合并当前真理，更新权威地图 `(<truth-root>/architecture/c4.md)`
- 使用话术：
  - Proposal（只写 C4 Delta，不改当前真理）：
    ```text
    你现在是 C4 Map Maintainer。请点名使用 `devbooks-c4-map`，但在 proposal 阶段**不要修改** `dev-playbooks/specs/architecture/c4.md`（当前真理）。
    先读：`dev-playbooks/specs/architecture/c4.md`（如存在）+ 本次 `dev-playbooks/changes/<change-id>/proposal.md` + `dev-playbooks/changes/<change-id>/design.md`
    请输出：一段可直接粘贴进 `dev-playbooks/changes/<change-id>/design.md` 的 **C4 Delta** 小节（C1/C2/C3 新增/修改/移除 + 依赖方向变化 + 建议的 Architecture Guardrails/fitness tests 条目）。
    ```
  - Review/Archive（更新当前真理的权威地图）：
  ```text
  你现在是 C4 Map Maintainer。请点名使用 `devbooks-c4-map`。
  先读：`dev-playbooks/specs/architecture/c4.md`（如存在）+ 本次 `dev-playbooks/changes/<change-id>/design.md` + 相关代码改动（用于确认变更已真实落地）
  请更新（或创建最小骨架并标 TODO）：`dev-playbooks/specs/architecture/c4.md`。
  ```

---

## `devbooks-implementation-plan`（Planner / tasks.md）

- 作用：从 `design.md` 推导编码计划 `tasks.md`（主线计划/临时计划/断点区），并绑定验收锚点（不得参考 tests/）。
- 使用场景：
  - 需要拆任务、并行拆分、里程碑、验收锚点
  - 大改动需要控制每个子任务改动量与可验收性
- 使用话术：
  ```text
  你现在是 Planner。请点名使用 `devbooks-implementation-plan`（禁止写实现代码）。
  先读：`dev-playbooks/changes/<change-id>/design.md`（以及本次 `specs/**` 如有）；不得参考 `tests/**`。
  请写：`dev-playbooks/changes/<change-id>/tasks.md`（每个任务都必须有验收锚点）。
  最后运行：`devbooks validate <change-id> --strict` 并修复所有问题。
  ```

---

## `devbooks-test-owner`（Test Owner）

- 作用：把设计/规格转成可执行验收测试与追溯文档 `verification.md`；强调与实现（Coder）独立对话、先跑出 Red 基线。
- 使用场景：
  - 需要 TDD/验收测试/追溯矩阵（Trace Matrix）
  - 需要 contract tests / 架构适配测试（fitness tests）
- **输出管理**：测试输出超过 50 行时，只保留关键失败信息，完整日志落盘到 `evidence/`
- 使用话术（必须新对话/独立实例）：
  ```text
  你现在是 Test Owner（必须独立对话/独立实例）。请点名使用 `devbooks-test-owner`，按 DevBooks apply 阶段执行。
  只读输入：`dev-playbooks/changes/<change-id>/proposal.md`、`design.md`、本次 `specs/**`（如有）；不得参考 `tasks.md`。
  产出：
    - `dev-playbooks/changes/<change-id>/verification.md`（含追溯矩阵）
    - `tests/**`（按仓库惯例）
    - 失败证据落盘到 `dev-playbooks/changes/<change-id>/evidence/`
  要求：必须先跑出 Red 基线；最后运行 `devbooks validate <change-id> --strict`。
  ```

---

## `devbooks-coder`（Coder）

- 作用：严格按 `tasks.md` 实现功能并跑闸门，禁止修改 `tests/**`，以测试/静态检查为唯一完成判据。
- 使用场景：
  - 进入实现阶段：按计划逐项实现、修复测试失败、让闸门全绿
- **热点感知**：开始任务前调用 `mcp__ckb__getHotspots` 检查目标文件是否为高风险区域，并输出热点报告
  - 🔴 Critical：热点 Top 5 且修改核心逻辑 → 先重构再修改，必须增加测试
  - 🟡 High：热点 Top 10 → 增加测试覆盖，代码审查重点关注
  - 🟢 Normal：非热点 → 正常流程
- **断点续做**：中断后继续时，Coder 会自动识别 tasks.md 中已完成的任务，从断点继续
- **输出管理**：命令输出超过 50 行时，只保留首尾各 10 行 + 摘要，完整日志落盘到 `evidence/`
- 使用话术（必须新对话/独立实例）：
  ```text
  你现在是 Coder（必须独立对话/独立实例）。请点名使用 `devbooks-coder`，按 DevBooks apply 阶段执行。
  先读：`dev-playbooks/changes/<change-id>/tasks.md`、以及 Test Owner 的 `verification.md`（如已存在）。
  严格按 `tasks.md` 实现；每完成一项再勾选 `- [x]`。
  禁止修改 `tests/**`；如需调整测试只能交还 Test Owner。
  以 tests/静态检查/build 为唯一完成判据；必要时把关键输出落盘到 `dev-playbooks/changes/<change-id>/evidence/`。
  ```

---

## `devbooks-code-review`（Reviewer）

- 作用：以 Reviewer 角色做可读性/一致性/依赖健康/坏味道审查，只输出可执行建议，不讨论业务正确性。
- **热点优先审查**：审查前调用 `mcp__ckb__getHotspots` 获取项目热点，按风险排序审查
  - 🔴 热点 Top 5：必须深度审查（测试覆盖、圈复杂度变化、依赖数量变化）
  - 🟡 热点 Top 10：重点关注
  - 🟢 非热点：常规审查
- 使用场景：
  - PR 评审前/后做结构与可维护性把关
  - 想发现耦合、依赖方向、复杂度、坏味道
- 使用话术：
  ```text
  你现在是 Reviewer。请点名使用 `devbooks-code-review`。
  请只做可读性/一致性/依赖健康度/坏味道审查，不讨论业务正确性；不改 tests/，不改设计。
  输入：本次变更涉及的代码 + `dev-playbooks/specs/**`（如需要项目画像/术语表/坑库）。
  输出：严重问题 / 可维护性风险 / 一致性建议 / 需要新增的质量闸门建议。
  ```

---

## `devbooks-design-backport`（Design Doc Editor / Backport）

- 作用：把实现中发现的新约束/冲突/缺口回写到 `design.md`（保持设计为黄金真理），并标注决策与影响。
- 使用场景：
  - 发现“设计没覆盖/与实现冲突/临时决策影响范围”
  - 需要停线回写设计再继续实现
- 使用话术：
  ```text
  你现在是 Design Doc Editor。请点名使用 `devbooks-design-backport`。
  触发：实现中发现设计缺口/冲突/临时决策。
  请把需要上升到设计层的内容回写：`dev-playbooks/changes/<change-id>/design.md`（说明原因与影响），然后停止。
  你必须明确提示我：需要回到 Planner 重跑 tasks；Test Owner 可能需要补测试/重跑 Red 基线。
  ```

---

## `devbooks-spec-gardener`（Spec Gardener）

- 作用：归档前修剪与维护 `<truth-root>`（去重合并/删除过时/目录整理/一致性修复），避免 specs 堆叠失控。
- 使用场景：
  - 本次产生了 spec deltas，准备归档合并进当前真理
  - 发现 `<truth-root>` 里重复/重叠/过时条目
- 使用话术：
  ```text
  你现在是 Spec Gardener。请点名使用 `devbooks-spec-gardener`。
  输入：`dev-playbooks/changes/<change-id>/specs/**` + `dev-playbooks/specs/**` + `dev-playbooks/changes/<change-id>/design.md`（如有）
  只允许修改 `dev-playbooks/specs/**` 做合并/去重/归类/删除过时；不要修改 change 包内容。
  输出按顺序：变更操作清单（CREATE/UPDATE/MOVE/DELETE）→ 每个 CREATE/UPDATE 的完整文件内容 → 合并映射摘要 → Open Questions（<=3）。
  ```

---

## `devbooks-delivery-workflow`（Delivery Workflow + Scripts）

- 作用：把一次变更跑成"可追溯闭环"（Design→Plan→Trace→Verify→Implement→Archive），并提供确定性脚本 scaffold/check/evidence/codemod。
- **架构合规检查**：`guardrail-check.sh` 新增选项
  - `--check-layers`：检查分层约束违规（下层引用上层、common 引用 browser/node 等）
  - `--check-cycles`：检查循环依赖
  - `--check-hotspots`：警告热点文件变更
- 使用场景：
  - 你想把重复步骤脚本化（避免漏文件、漏字段、漏校验）
  - 你想把“完成”锚定到可执行校验（而不是口头确认）
- 使用话术：
  ```text
  你现在要点名使用 `devbooks-delivery-workflow`。
  目标：尽量用该 Skill 的 `scripts/*` 生成/校验/采集证据，而不是凭记忆手写骨架。
  约束：不要把脚本正文贴进上下文；只运行脚本并汇总结果；每个命令运行前先向我确认。

  项目根目录：$(pwd)
  本次 change-id：<change-id>
  truth-root：dev-playbooks/specs
  change-root：dev-playbooks/changes

  请你依次建议并执行（等我确认）：
  1) `change-scaffold.sh <change-id> --project-root \"$(pwd)\" --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`
  2) `change-check.sh <change-id> --mode proposal --project-root \"$(pwd)\" --change-root dev-playbooks/changes --truth-root dev-playbooks/specs`
  3) （需要证据时）用 `change-evidence.sh` 把测试/命令输出落盘到 `dev-playbooks/changes/<change-id>/evidence/`
  ```

---

## `devbooks-brownfield-bootstrap`（Brownfield Bootstrapper）

- 作用：存量项目初始化：当 `<truth-root>` 为空/缺失时生成项目画像、术语表、基线规格与最小验证锚点，避免"边补 specs 边改行为"。
- **COD 模型生成**：自动生成"代码地图"产物
  - 模块依赖图：`<truth-root>/architecture/module-graph.md`（来自 `mcp__ckb__getArchitecture`）
  - 技术债热点：`<truth-root>/architecture/hotspots.md`（来自 `mcp__ckb__getHotspots`）
  - 领域概念：`<truth-root>/_meta/key-concepts.md`（来自 `mcp__ckb__listKeyConcepts`）
  - 项目画像模板：三层架构（语法层/语义层/上下文层）
- 使用场景:
  - 老项目想接入 DevBooks/DevBooks，但没有当前真理与规格基线
  - 你想先把“现在是什么样”写清楚，再开始改动
- 使用话术：
  ```text
  你现在是 Brownfield Bootstrapper。请点名使用 `devbooks-brownfield-bootstrap`。
  先确认：本项目 truth-root = `dev-playbooks/specs`，change-root = `dev-playbooks/changes`。
  约束：只产出文档与基线规格，不做重构、不改业务行为、不输出实现计划。
  请按该 skill 的要求一次性补齐：
    - `dev-playbooks/specs/_meta/project-profile.md`
    - （可选）`dev-playbooks/specs/_meta/glossary.md`
    - 一个 baseline change package：`dev-playbooks/changes/<baseline-id>/*`（proposal/design/specs/verification）
  最后告诉我：如何把 baseline 合并进 `dev-playbooks/specs/`（归档/人工步骤）。
  ```

---

## `devbooks-entropy-monitor`（Entropy Monitor）

- 作用：定期采集系统熵度量（结构熵/变更熵/测试熵/依赖熵），生成量化报告，当指标超阈值时建议重构。
- 使用场景：
  - 你想定期体检代码健康度（复杂度趋势、热点文件、Flaky 测试占比）
  - 你想在重构前获取量化数据支撑（而不是"感觉代码烂了"）
  - 你想建立技术债务的可视化趋势
- 使用话术：
  ```text
  你现在是 Entropy Monitor。请点名使用 `devbooks-entropy-monitor`。
  先读：`dev-playbooks/project.md`（如存在）
  目标：采集当前系统的熵度量，并生成量化报告。

  请按以下步骤执行：
  1) 运行 `entropy-measure.sh --project-root "$(pwd)"`，采集四维度指标（结构熵/变更熵/测试熵/依赖熵）
  2) 运行 `entropy-report.sh --output <truth-root>/_meta/entropy/entropy-report-$(date +%Y-%m-%d).md`，生成报告
  3) 对比阈值（`thresholds.json`），列出超阈值的指标
  4) 如果有超阈值指标：给出重构建议（可作为后续 proposal 的数据支撑）

  项目根目录：$(pwd)
  truth-root：dev-playbooks/specs
  ```
- 定期执行建议：
  - 小型项目（< 10K LOC）：每周手动运行
  - 中型项目（10K-100K LOC）：CI 定时每日运行
  - 大型项目（> 100K LOC）：PR 合并时触发

---

## `devbooks-index-bootstrap`（Index Bootstrapper）【新】

- 作用：自动检测项目语言栈并生成 SCIP 索引，激活图基代码理解能力（调用图、影响分析、符号引用等）。
- **触发条件**：
  - 用户说"初始化索引/建立代码图谱/激活图分析"
  - `mcp__ckb__getStatus` 返回 SCIP 后端 `healthy: false`
  - 进入新项目且 `index.scip` 不存在
- 使用场景：
  - 想使用 `devbooks-impact-analysis` 的图基分析模式
  - 想在 `devbooks-coder`/`devbooks-code-review` 中获得热点感知
  - CKB MCP 工具报错"SCIP 后端不可用"
- 使用话术：
  ```text
  请点名使用 `devbooks-index-bootstrap`。
  目标：检测项目语言栈，生成 SCIP 索引，激活图基代码理解能力。
  项目根目录：$(pwd)
  ```
- 手动生成索引（无需 Skill）：
  ```bash
  # TypeScript/JavaScript
  npm install -g @anthropic-ai/scip-typescript
  scip-typescript index --output index.scip

  # Python
  pip install scip-python
  scip-python index . --output index.scip

  # Go
  go install github.com/sourcegraph/scip-go@latest
  scip-go --output index.scip
  ```

---

## `devbooks-federation`（Federation Analyst）【新】

- 作用：跨仓库联邦分析与契约同步。检测契约变更、分析跨仓库影响、通知下游消费者。
- **触发条件**：
  - 用户说"跨仓库影响/联邦分析/契约同步/上下游依赖/多仓库"
  - 变更涉及 `federation.yaml` 中定义的契约文件
- 使用场景：
  - 多仓库项目，需要分析变更对下游的影响
  - 对外 API/契约变更，需要通知消费者
  - 想建立跨仓库的影响追溯
- 前置条件：
  - 项目根目录存在 `.devbooks/federation.yaml`（从 `skills/devbooks-federation/templates/federation.yaml` 复制）
- 使用话术：
  ```text
  请点名使用 `devbooks-federation`。
  目标：分析本次变更的跨仓库影响，检测契约变更，生成影响报告。
  项目根目录：$(pwd)
  变更文件：<变更的文件列表>
  ```
- 脚本支持：
  ```bash
  # 检查联邦契约变更
  bash ~/.claude/skills/devbooks-federation/scripts/federation-check.sh --project-root "$(pwd)"
  ```

