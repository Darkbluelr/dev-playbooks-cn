# 文档一致性工具优化

**配置信息**：
- `truth-root` = `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/specs`
- `change-root` = `/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes`
- `change-id` = `20260122-0827-enhance-docs-consistency`

---

## 结论先行

**本提案会导致**：
- 文档同步工具改名为 `devbooks-docs-consistency`
- 支持自定义规则（如"删除所有 augment 引用"）
- 增量扫描机制，减少 token 消耗
- 文档维护元数据（`docs-maintenance.md`），包含文档风格偏好
- 完备性检查（环境依赖、安全权限、故障排查等）
- 共享方法论文档（完备性思维框架）
- 去除项目中所有 skill 和文档的浮夸词语
- 删除 MCP 增强相关功能
- 所有 skill 使用时必须声明扮演的专家角色

**本提案不会导致**：
- 不破坏现有文档结构
- 不强制配置（零配置可用）
- 不修改历史文档（CHANGELOG.md 等）

**一句话总结**：优化文档一致性检查工具，支持自定义规则和增量扫描，同时简化项目描述语言。

---

## 需求对齐

### 核心需求

**基础功能**：
- [x] 文档与代码保持一致
- [x] 自动检测文档问题
- [x] 增量扫描

**扩展功能**：
- [x] 自定义规则
- [x] 完备性检查
- [x] 文档分类（活体/历史）
- [x] 文档风格偏好持久化（如是否使用 emoji、是否使用浮夸词语）
- [x] 与其他 skills 集成
- [x] 去除浮夸词语
- [x] 删除 MCP 增强功能
- [x] Skill 专家角色声明

### 关键决策

#### 决策 1：一次性任务 vs 持续规则

- [x] 一次性任务：用命令行参数 `--once "remove:@augment"`
- [ ] 持续规则：写入配置文件

**选择理由**：一次性任务更简单，不污染配置文件。

#### 决策 2：全量扫描 vs 增量扫描

- [x] 增量扫描：利用 devbooks 演进历史
- [ ] 全量扫描：每次扫描所有代码

**选择理由**：增量扫描节省 token，提升效率。

#### 决策 3：完备性检查深度

- [x] 完备检查：覆盖多个维度
- [ ] 基础检查：只检查核心内容

**选择理由**：完备检查确保文档无遗漏。

---

## 批准流程

- [x] 同意推荐方案，直接开始
- [ ] 自定义方案
- [ ] 需要更多信息

---

### Challenger 额外审视部分

**用户自定义审视点**：
```
[用户可在此填写]
```

**AI 推荐审视点**：
1. **禁止拆分变更包**：本提案功能相互依赖，必须整体实现
2. **避免过度设计**：检查是否引入不必要的复杂度
3. **性能影响**：增量扫描是否真的节省 token
4. **向后兼容性**：改名后如何迁移
5. **文档完整性**：元数据文件是否增加维护负担
6. **规则引擎复杂度**：配置是否过于复杂

**Challenger 约束**：
- 禁止提议拆分变更包
- 必须评估整体方案可行性
- 必须指出过度设计
- 必须评估用户负担

---

## 详细提案

### Why（为什么要改）

#### 问题描述

当前 `devbooks-docs-sync` skill 存在以下问题：

1. **命名不准确**："sync"不能准确反映一致性审计职责
2. **缺少自定义规则**：无法添加项目特定规范
3. **全量扫描浪费 token**：每次扫描整个代码库
4. **检查维度不完备**：只检查 API 和配置，缺少环境依赖等
5. **缺少文档分类**：没有区分活体文档和历史文档
6. **缺少方法论支持**：没有完备性思维框架
7. **描述语言浮夸**：项目中存在大量花里胡哨的词语
8. **MCP 增强功能越界**：应该由 MCP 自身处理

#### 影响

- 效率问题：全量扫描浪费 token
- 质量问题：检查维度不完备
- 可维护性问题：缺少自定义规则
- 用户体验问题：命名不准确，描述浮夸
- 边界问题：MCP 增强功能越界

---

### What（要改什么）

#### 目标

1. 改名：`devbooks-docs-sync` → `devbooks-docs-consistency`
2. 自定义规则支持（持续规则 + 一次性任务）
3. 增量扫描机制
4. 完备性检查（环境依赖、安全权限、故障排查等）
5. 文档分类管理（活体/历史/概念性）
6. 文档风格偏好持久化（emoji、浮夸词语等）
7. 共享方法论文档
8. 去除浮夸词语
9. 删除 MCP 增强功能
10. Skill 专家角色声明机制
11. 与其他 skills 集成

#### 范围

**In scope**：
1. `skills/devbooks-docs-sync/` → `skills/devbooks-docs-consistency/`
2. 新增：`skills/devbooks-docs-consistency/references/docs-rules-schema.yaml`
3. 新增：`skills/_shared/references/完备性思维框架.md`
4. 修改：`skills/devbooks-archiver/skill.md`
5. 修改：`skills/devbooks-brownfield-bootstrap/skill.md`
6. 修改：`skills/devbooks-proposal-author/skill.md`
7. 修改：`skills/devbooks-design-backport/skill.md`
8. 修改：`skills/devbooks-impact-analysis/skill.md`
9. 新增：`dev-playbooks/specs/_meta/docs-maintenance.md`（包含文档风格偏好）
10. **新增**：去除所有 skill 描述中的浮夸词语
11. **删除**：所有 skill 中的 MCP 增强章节
12. **新增**：所有 skill 添加专家角色声明机制

**Out of scope**：
- 不修改现有用户文档
- 不修改历史文档
- 不修改测试代码
- 不修改其他 skills 核心逻辑
- **明确排除**：用户项目中的 `dev-playbooks/` 目录（通过 `devbooks init` 创建的模板文件）不在 docs-consistency 维护范围内，理由：
  - 这些文件是 DevBooks 工具自身维护的模板
  - 面向开发者使用，不面向最终用户
  - DevBooks 开发过程中会自行维护这些文件
  - 用户项目的文档一致性由用户自己负责

**Impact scope**：
- 模块：devbooks-docs-sync（核心）、devbooks-archiver、devbooks-brownfield-bootstrap、devbooks-proposal-author、devbooks-design-backport、devbooks-impact-analysis、所有 skills（去除浮夸词语）
- 能力：文档一致性审计、自定义规则、增量扫描、完备性检查
- 外部契约：skill 调用接口（改名）
- 数据不变性：只新增元数据文件

---

### Impact（影响分析）

**配置信息**：
- `truth-root` = `dev-playbooks/specs`
- `change-root` = `dev-playbooks/changes`

#### 变更边界（Scope）

**In scope**：
1. **核心变更**：
   - `skills/devbooks-docs-sync/` → `skills/devbooks-docs-consistency/`（改名 + 功能增强）
   - 新增规则引擎、增量扫描、完备性检查、文档分类、风格偏好持久化

2. **集成变更**（5 个 skills）：
   - `skills/devbooks-archiver/SKILL.md`：归档前调用 docs-consistency 检查
   - `skills/devbooks-brownfield-bootstrap/SKILL.md`：初始化时生成 `docs-maintenance.md`
   - `skills/devbooks-proposal-author/SKILL.md`：proposal 模板新增 Challenger 审视章节
   - `skills/devbooks-design-backport/SKILL.md`：回写设计时同步文档
   - `skills/devbooks-impact-analysis/SKILL.md`：影响分析包含文档影响

3. **全局清理**（19 个 skills + 多个 references）：
   - 去除浮夸词语（"最强大脑"、"智能"、"高效"等）
   - 删除 MCP 增强章节（23 个文件）
   - 新增专家角色声明机制

4. **共享资源**：
   - 移动 `如何构建完备的系统.md` → `skills/_shared/references/完备性思维框架.md`
   - 新增 `dev-playbooks/specs/_meta/docs-maintenance.md`（文档维护元数据）
   - 新增 `skills/_shared/references/专家列表.md`

**Out of scope**：
- 不修改用户项目的 `dev-playbooks/` 目录（通过 `devbooks init` 创建的模板）
- 不修改历史文档（CHANGELOG.md）
- 不修改测试代码
- 不修改其他 skills 的核心逻辑

#### 变更类型分类（Change Type Classification）

- [x] **功能扩展**：新增自定义规则、增量扫描、完备性检查、文档分类等功能
- [x] **接口契约变更**：skill 名称改变（`devbooks-docs-sync` → `devbooks-docs-consistency`）
- [x] **对象职责变更**：从"文档同步"扩展为"文档一致性审计"
- [ ] **创建特定类**：不涉及
- [ ] **算法依赖**：不涉及
- [ ] **平台依赖**：不涉及
- [ ] **对象表示/实现依赖**：不涉及
- [ ] **子系统/模块替换**：不涉及

#### 受影响对象清单（Impacts）

##### A. 对外契约（API/事件/Schema）

| 契约类型 | 变更内容 | 影响范围 | 兼容性 |
|----------|----------|----------|--------|
| Skill 调用接口 | 名称改变：`devbooks-docs-sync` → `devbooks-docs-consistency` | 所有调用方（archiver、router 等） | 提供别名，保留 6 个月 |
| 配置文件格式 | 新增 `docs-maintenance.md` 元数据文件 | 新项目自动生成，存量项目首次运行时生成 | 向后兼容（零配置可用） |
| 命令行参数 | 新增 `--once` 参数支持一次性规则 | 可选参数，不影响现有用法 | 向后兼容 |

##### B. 数据与迁移（DB/回放/幂等）

| 数据类型 | 变更内容 | 迁移策略 |
|----------|----------|----------|
| 元数据文件 | 新增 `dev-playbooks/specs/_meta/docs-maintenance.md` | 首次运行时自动生成，无需手动迁移 |
| 共享文档 | 移动 `如何构建完备的系统.md` → `skills/_shared/references/完备性思维框架.md` | 保留原文件 6 个月，添加重定向说明 |
| 专家列表 | 新增 `skills/_shared/references/专家列表.md` | 新文件，无迁移需求 |

##### C. 模块与依赖（边界/调用方向/循环风险）

**直接依赖关系**（5 个 skills 直接调用 docs-consistency）：

```
devbooks-archiver → devbooks-docs-consistency（归档前检查）
devbooks-brownfield-bootstrap → devbooks-docs-consistency（初始化生成元数据）
devbooks-design-backport → devbooks-docs-consistency（回写设计同步文档）
devbooks-impact-analysis → devbooks-docs-consistency（影响分析包含文档）
devbooks-proposal-author → 完备性思维框架（提案撰写参考）
```

**间接影响**（通过 router 路由）：

```
devbooks-router → devbooks-docs-consistency（路由表更新）
```

**循环依赖风险**：无（docs-consistency 不依赖其他 skills）

##### D. 测试与验证（需要新增/更新哪些锚点）

| 测试类型 | 测试内容 | 验收标准 |
|----------|----------|----------|
| 单元测试 | 规则引擎解析与执行 | 覆盖率 > 80% |
| 单元测试 | 增量扫描逻辑 | 正确识别变更文件 |
| 单元测试 | 完备性检查算法 | 覆盖所有检查维度 |
| 集成测试 | 与 archiver 集成 | 归档前检查生效 |
| 集成测试 | 与 brownfield-bootstrap 集成 | 初始化生成元数据 |
| 集成测试 | 文档风格偏好持久化 | 风格检查生效 |
| 性能测试 | 增量扫描 token 消耗 | < 全量扫描 20% |
| 端到端测试 | 完整工作流 | 所有功能正常 |

##### E. Bounded Context 边界

**本次变更不跨越 Bounded Context**：
- 所有变更都在 DevBooks 工具内部
- 不涉及外部系统集成
- 不需要引入 ACL

**模块边界清晰**：
- `devbooks-docs-consistency`：文档一致性审计
- `devbooks-archiver`：归档流程编排
- `devbooks-brownfield-bootstrap`：项目初始化
- 各模块职责单一，边界清晰

##### F. 受影响的 Spec 真理

**本次变更不影响 `truth-root/specs/` 下的规格文件**：
- DevBooks 工具本身没有规格文件
- 新增的 `docs-maintenance.md` 是元数据文件，不是规格文件
- 不破坏现有规格

#### Pinch Point 识别与最小测试集

**Pinch Points**：

1. **[PP-1] `devbooks-docs-consistency` 主入口**
   - 汇聚点：所有调用方（archiver、brownfield-bootstrap、design-backport、impact-analysis）都通过此入口
   - 调用路径：4 条
   - 测试策略：在此处写 1 个集成测试，覆盖所有调用场景

2. **[PP-2] 规则引擎核心**
   - 汇聚点：自定义规则、完备性检查、风格偏好检查都通过规则引擎
   - 调用路径：3 条
   - 测试策略：在此处写 1 个单元测试，覆盖所有规则类型

3. **[PP-3] 增量扫描逻辑**
   - 汇聚点：所有文档扫描都通过增量扫描逻辑
   - 调用路径：2 条（增量模式、全量模式）
   - 测试策略：在此处写 1 个单元测试，覆盖两种模式

**最小测试集**：
- 在 PP-1 写 1 个集成测试 → 覆盖 4 条调用路径
- 在 PP-2 写 1 个单元测试 → 覆盖 3 种规则类型
- 在 PP-3 写 1 个单元测试 → 覆盖 2 种扫描模式
- **预计测试数量**：3 个核心测试（而非为每条路径写 9 个）

**ROI 原则**：测试数量 = Pinch Point 数量（3 个），而非调用路径数量（9 个）

#### 受影响的模块

| 模块 | 影响类型 | 影响程度 | 说明 |
|------|----------|----------|------|
| devbooks-docs-sync | 改名 + 功能增强 | 高 | 核心变更 |
| devbooks-archiver | 集成调用 | 中 | 归档前检查 |
| devbooks-brownfield-bootstrap | 集成调用 | 中 | 初始化生成元数据 |
| devbooks-proposal-author | 新增字段 | 低 | Challenger 审视部分 |
| devbooks-design-backport | 集成调用 | 低 | 回写设计同步文档 |
| devbooks-impact-analysis | 集成调用 | 低 | 影响分析包含文档 |
| 所有 skills（19 个） | 描述修改 | 中 | 去除浮夸词语 |
| 所有 skills（19 个） | 删除章节 | 低 | 删除 MCP 增强 |
| 所有 skills（19 个） | 新增机制 | 中 | 专家角色声明 |
| 所有 references（28 个） | 描述修改 | 中 | 去除浮夸词语 |

#### 兼容性与风险（Compatibility & Risks）

##### Breaking 变化

| 变化类型 | 影响 | 缓解措施 |
|----------|------|----------|
| Skill 名称改变 | 调用方需要更新 | 提供别名 `devbooks-docs-sync`，保留 6 个月 |
| 配置文件新增 | 存量项目需要生成元数据 | 首次运行时自动生成，零配置可用 |

##### 迁移/回滚路径

**迁移路径**：
1. **阶段 1**（0-1 个月）：
   - 发布新版本，同时保留旧名称别名
   - 文档更新，说明改名原因
   - 用户可继续使用旧名称

2. **阶段 2**（1-3 个月）：
   - 在调用旧名称时输出 deprecation 警告
   - 引导用户迁移到新名称

3. **阶段 3**（3-6 个月）：
   - 增加警告频率
   - 在文档中标记旧名称为 deprecated

4. **阶段 4**（6 个月后）：
   - 移除别名
   - 只保留新名称

**回滚路径**：
- 如果新功能出现严重问题，可以回退到旧版本
- 元数据文件可以安全删除（不影响核心功能）
- 集成调用可以通过配置开关禁用

##### 风险评估

| 风险 | 概率 | 影响 | 缓解措施 | 残余风险 |
|------|------|------|----------|----------|
| 改名后用户无法找到工具 | 中 | 中 | 提供别名 + 文档说明 | 低 |
| 增量扫描遗漏新增代码 | 低 | 高 | 提供全量扫描回退 + 充分测试 | 低 |
| 元数据维护成为负担 | 中 | 中 | 自动维护 + 零配置默认 | 低 |
| 规则引擎过于复杂 | 中 | 中 | 零配置默认行为 + 渐进式配置 | 低 |
| 完备性检查过于严格 | 低 | 低 | 提供检查级别配置 | 极低 |
| 去除词语影响理解 | 低 | 低 | 保留核心描述 + 代码审查 | 极低 |
| 集成测试覆盖不足 | 中 | 高 | Pinch Point 测试策略 + 端到端测试 | 低 |

#### 最小改动面策略（Minimal Diff Strategy）

##### 优先改动点（变化收口点）

1. **核心收口点**：`skills/devbooks-docs-consistency/SKILL.md`
   - 所有新功能都在此模块实现
   - 其他模块只做集成调用，不修改核心逻辑

2. **集成收口点**：5 个 skills 的集成调用
   - 只在必要的地方添加调用
   - 不修改这些 skills 的核心逻辑

3. **清理收口点**：批量文本替换
   - 使用脚本批量去除浮夸词语
   - 使用脚本批量删除 MCP 增强章节
   - 人工审查确保不误删

##### 明确禁止的改动类型

| 禁止类型 | 说明 | 违反后果 |
|----------|------|----------|
| 修改其他 skills 核心逻辑 | 只做集成调用，不改变原有行为 | 增加风险，难以回滚 |
| 修改测试代码 | 测试由 Test Owner 维护 | 违反 GIP-02 |
| 修改用户项目模板 | `dev-playbooks/` 模板由工具维护 | 超出范围 |
| 修改历史文档 | CHANGELOG.md 等历史记录不可变 | 破坏可追溯性 |
| 引入新的外部依赖 | 保持零依赖原则 | 增加复杂度 |

##### 改动面控制指标

| 指标 | 目标值 | 实际值（待实现后填写） |
|------|--------|------------------------|
| 修改的 skills 数量 | ≤ 6 个（1 个核心 + 5 个集成） | - |
| 新增的文件数量 | ≤ 5 个 | - |
| 删除的文件数量 | 1 个（移动） | - |
| 修改的行数（核心逻辑） | ≤ 500 行 | - |
| 修改的行数（描述清理） | 不限（批量替换） | - |

#### 需要补齐的资料（Open Questions）

1. **规则引擎配置格式**
   - 问题：YAML 格式的具体结构是什么？
   - 影响：实现阶段需要明确
   - 建议：在 design.md 中补充完整的 schema 定义

2. **完备性检查维度优先级**
   - 问题：哪些维度是必须检查的？哪些是可选的？
   - 影响：影响检查严格程度
   - 建议：在 design.md 中定义检查级别（strict/normal/loose）

3. **专家角色列表完整性**
   - 问题：需要包含哪些专家？如何分类？
   - 影响：影响专家角色声明机制的可用性
   - 建议：在 design.md 中补充完整的专家列表和分类标准

---

### Risks & Rollback

#### 风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 改名后用户无法找到工具 | 中 | 中 | 提供别名 |
| 增量扫描遗漏新增代码 | 低 | 高 | 提供全量扫描回退 |
| 元数据维护成为负担 | 中 | 中 | 自动维护 |
| 规则引擎过于复杂 | 中 | 中 | 零配置默认行为 |
| 完备性检查过于严格 | 低 | 低 | 提供检查级别配置 |
| 去除词语影响理解 | 低 | 低 | 保留核心描述 |

#### Degradation strategy

- 增量扫描失败：回退到全量扫描
- 规则引擎失败：跳过自定义规则
- 完备性检查失败：只执行核心检查

#### Rollback strategy

- 改名回滚：恢复旧名称
- 功能回滚：删除新增代码
- 元数据回滚：删除 `docs-maintenance.md`
- 集成回滚：移除集成调用
- 描述回滚：恢复原描述

---

### Validation

#### Candidate acceptance anchors

1. **功能验收**：
   - [ ] 改名完成，别名生效
   - [ ] 自定义规则支持
   - [ ] 增量扫描工作正常
   - [ ] 完备性检查覆盖所有维度
   - [ ] 文档分类正确
   - [ ] 共享方法论文档可引用
   - [ ] 与其他 skills 集成成功
   - [ ] 浮夸词语已去除
   - [ ] MCP 增强功能已删除
   - [ ] 专家角色声明机制已实现
   - [ ] 文档风格偏好已持久化

2. **性能验收**：
   - [ ] 增量扫描 token 消耗 < 全量扫描 20%
   - [ ] 扫描速度 < 10 秒

3. **质量验收**：
   - [ ] 所有单元测试通过
   - [ ] 所有集成测试通过
   - [ ] 代码审查通过
   - [ ] 文档完整性检查通过

#### Evidence location

- 证据目录：`/Users/ozbombor/Projects/dev-playbooks-cn/dev-playbooks/changes/20260122-0827-enhance-docs-consistency/evidence/`
- 收集方式：`change-evidence.sh 20260122-0827-enhance-docs-consistency -- <command>`

---


## Debate Packet

## Why

- 本提案的动机与问题背景详见上文“### Why（为什么要改）”。

## What Changes

- 变更范围与内容详见上文“### What（要改什么）”。

## Impact

- 影响分析详见上文“### Impact（影响分析）”。

## Risks

- 风险与回滚详见上文“### Risks & Rollback”。

## Validation

- 验收与证据锚点详见上文“### Validation”。

### Debate points/questions requiring decision

1. **改名策略**：
   - 问题：是否提供别名？
   - 选项 A：提供别名，保留 6 个月
   - 选项 B：直接改名
   - 推荐：选项 A

2. **规则引擎复杂度**：
   - 问题：配置是否过于复杂？
   - 选项 A：完整规则引擎
   - 选项 B：简单规则
   - 推荐：选项 A（提供零配置默认）

3. **增量扫描触发时机**：
   - 问题：何时增量，何时全量？
   - 选项 A：默认增量，手动全量
   - 选项 B：自动判断
   - 推荐：选项 B

4. **元数据维护方式**：
   - 问题：是否需要用户手动编辑？
   - 选项 A：完全自动
   - 选项 B：自动为主，可手动调整
   - 推荐：选项 B

5. **完备性检查严格程度**：
   - 问题：是否阻塞归档？
   - 选项 A：阻塞归档
   - 选项 B：只警告
   - 推荐：选项 B

6. **共享方法论文档位置**：
   - 问题：放在哪里？
   - 选项 A：`skills/_shared/references/完备性思维框架.md`
   - 选项 B：保持原位置
   - 推荐：选项 A

7. **Challenger 审视部分实现**：
   - 问题：如何实现？
   - 选项 A：proposal 模板新增章节
   - 选项 B：在 Debate Packet 中
   - 推荐：选项 A

8. **浮夸词语去除范围**：
   - 问题：去除哪些词语？
   - 选项 A：去除所有修饰词（"最强大脑"、"智能"、"高效"等）
   - 选项 B：只去除明显浮夸的词
   - 推荐：选项 A（回归本质描述）

9. **MCP 增强功能处理**：
   - 问题：如何处理 MCP 增强？
   - 选项 A：完全删除
   - 选项 B：保留但简化
   - 推荐：选项 A（保持边界）

---


- Value Signal and Observation: 文档一致性检查的覆盖率提升、扫描耗时下降、token 消耗下降（以 evidence/token-usage.log 与 evidence/scan-performance.log 为观测锚点）
- Value Stream Bottleneck Hypothesis: 当前瓶颈在全量扫描与规则缺失导致的返工；通过增量扫描与规则引擎降低返工与扫描成本

## Decision Log
- Decision Status: Approved

- **Decision Status**: `Approved`
- **Decision summary**: 提案通过，进入设计阶段。需在 design.md 中补充 AC、算法、配置格式等内容。详见 `judge-decision.md`
- **Questions requiring decision**: 见 Debate Packet（推荐方案已在裁决报告中说明）
- **Judge decision**: 见 `judge-decision.md`

---

## 附录：共享方法论文档

### 完备性思维框架位置

**原文件**：`/Users/ozbombor/Projects/dev-playbooks-cn/如何构建完备的系统.md`

**新位置**：`skills/_shared/references/完备性思维框架.md`

**说明**：
- 通用方法论文档
- 包含认知系统架构师角色、OmniMind 推理框架、完备性工具集、互斥性工具集
- 多个 skills 可复用

### 哪些 Skills 可能用到

| Skill | 使用场景 | 说明 |
|-------|----------|------|
| devbooks-docs-consistency | 完备性检查 | 使用完备性工具集检查文档覆盖率 |
| devbooks-proposal-author | 提案撰写 | 使用 OmniMind 框架系统性思考 |
| devbooks-proposal-challenger | 提案质疑 | 使用批判性思维工具发现遗漏 |
| devbooks-design-doc | 设计文档 | 使用多维度分析确保设计完备 |
| devbooks-spec-contract | 规格定义 | 使用 MECE 原则确保规格完整 |
| devbooks-impact-analysis | 影响分析 | 使用系统思维分析影响范围 |
| devbooks-brownfield-bootstrap | 存量初始化 | 使用完备性工具集建立基线 |

### 集成方式

在需要使用完备性思维框架的 skill 中，添加引用：

```markdown
## 方法论支持

本 Skill 使用 `skills/_shared/references/完备性思维框架.md` 中的方法论：
- 完备性工具集：系统思维、TRIZ、MECE、多维度分析
- 互斥性工具集：MECE、正交设计、模块化设计
- OmniMind 推理框架：解构、探索、验证、综合

详见：`~/.claude/skills/_shared/references/完备性思维框架.md`
```

---

## 附录：浮夸词语清理规范

### 需要去除的词语类型

1. **过度修饰词**：
   - "最强大脑"、"智能"、"高效"、"强大"、"优雅"、"完美"
   - "卓越"、"杰出"、"出色"、"精妙"、"精彩"

2. **夸张表达**：
   - "革命性"、"颠覆性"、"突破性"、"创新性"
   - "无与伦比"、"前所未有"、"史无前例"

3. **情感化词语**：
   - "令人惊叹"、"令人兴奋"、"令人激动"
   - "美妙"、"绝妙"、"神奇"

### 替换原则

- "智能的文档一致性审计系统" → "文档一致性检查工具"
- "最强大脑" → "专家"或直接去除
- "高效的增量扫描" → "增量扫描"
- "强大的规则引擎" → "规则引擎"

### 保留的描述

- 技术术语：保留
- 功能描述：保留
- 约束说明：保留
- 数据指标：保留

---

## 附录：MCP 增强功能删除说明

### 删除理由

**设计哲学**：把 MCP 相关需求交还给 MCP 自身，保持边界。

**具体原因**：
1. MCP 增强功能属于 MCP 的职责范围
2. DevBooks skills 不应该处理 MCP 的可用性检测
3. 降级提示应该由 MCP 自身提供
4. 保持 skills 的职责单一

### 需要删除的内容

在所有 skills 中删除以下章节：
1. "MCP 增强"章节
2. "依赖的 MCP 服务"说明
3. "增强模式 vs 基础模式"对比
4. "降级提示"相关内容
5. MCP 可用性检测代码

### 替代方案

- 如果 skill 需要使用 MCP 工具，直接调用即可
- 如果 MCP 不可用，由 MCP 自身返回错误
- Skill 不需要处理 MCP 的降级逻辑

---

## 附录：文档风格偏好持久化

### 设计目标

解决问题：去除浮夸词语、emoji 等风格调整后，如何确保后续文档编写时不会再次引入？

### 实现方案

在 `docs-maintenance.md` 中添加 `style_preferences` 字段：

```yaml
# 文档维护元数据
version: 1.0
last_full_scan: 2026-01-22

# 文档风格偏好
style_preferences:
  # 是否使用 emoji
  use_emoji: false
  reason: "保持文档专业性，回归本质描述"

  # 是否使用浮夸词语
  use_fancy_words: false
  forbidden_words:
    - "最强大脑"
    - "智能"
    - "高效"
    - "强大"
    - "优雅"
    - "完美"
    - "革命性"
    - "颠覆性"
  reason: "回归本质描述，避免过度修饰"

  # 标题风格
  heading_style: "simple"  # simple | decorated
  reason: "使用简洁的标题，不使用装饰性符号"

  # 代码块风格
  code_block_style: "standard"  # standard | enhanced
  reason: "使用标准代码块，不添加额外装饰"

# 重点维护的文档
critical_docs:
  - path: "README.md"
    reason: "项目入口"
    triggers:
      - "public_api_change"
      - "config_change"
    last_reviewed: 2026-01-20

# 规则引擎维护的文档
automated_docs:
  - path: "docs/configuration.md"
    rule: "sync_env_vars"

# 已知的文档-代码映射
known_mappings:
  env_vars:
    - DATABASE_URL: "docs/configuration.md#database"
    - API_KEY: "docs/configuration.md#authentication"
```

### 使用方式

#### 1. 初始化时生成

在 `devbooks-brownfield-bootstrap` 首次运行时：
- 扫描现有文档风格
- 生成默认的 `style_preferences`
- 用户可手动调整

#### 2. 文档编写时检查

在 `devbooks-docs-consistency` 运行时：
- 读取 `style_preferences`
- 检查新文档是否符合风格偏好
- 如果违反，给出警告或自动修复

#### 3. 持续维护

- 风格偏好随项目演进更新
- 可以通过命令行参数临时覆盖
- 可以在配置文件中永久修改

### 优势

1. **持久化**：风格偏好记录在版本控制中，团队共享
2. **可追溯**：每个偏好都有 `reason` 字段，说明为什么这样设置
3. **灵活性**：可以随时调整，不需要修改代码
4. **自动化**：文档编写时自动检查，减少人工审查负担
5. **渐进式**：可以先设置宽松规则，逐步收紧

### 与自定义规则的关系

- **风格偏好**：长期的、项目级的文档风格约定
- **自定义规则**：临时的、一次性的文档清理任务

两者互补，不冲突。

---

## 附录：Skill 专家角色声明机制

### 设计目标

确保 AI 使用 skill 时：
1. 选择一个真实存在且匹配任务的专家
2. 显式声明自己扮演这个专家
3. 然后开始任务

### 实现方案

#### 1. 在每个 skill.md 中定义推荐专家列表

```markdown
---
name: devbooks-proposal-author
description: 撰写变更提案
recommended_experts:
  - name: "Martin Fowler"
    expertise: "软件架构、重构"
    suitable_for: "架构变更、重构提案"
  - name: "Kent Beck"
    expertise: "测试驱动开发、极限编程"
    suitable_for: "测试相关提案"
  - name: "Eric Evans"
    expertise: "领域驱动设计"
    suitable_for: "领域模型变更提案"
---

# DevBooks：提案撰写（Proposal Author）

## 专家角色声明（必须）

在执行本 Skill 前，AI 必须：
1. 从上述 `recommended_experts` 中选择一个与任务最匹配的专家
2. 显式声明：`我将扮演 [专家名称]，专长是 [专长领域]`
3. 然后开始执行任务

**示例**：
```
我将扮演 Martin Fowler，专长是软件架构和重构。现在开始撰写提案。
```

## 前置：配置发现
...
```

#### 2. 在 AI 行为规范中添加约束

在 `skills/_shared/references/AI行为规范.md` 中添加：

```markdown
## 6. Skill 专家角色声明协议

**硬规则**：
1. 使用任何 skill 前，必须从 skill.md 的 `recommended_experts` 中选择一个专家
2. 必须显式声明：`我将扮演 [专家名称]，专长是 [专长领域]`
3. 选择的专家必须与任务匹配
4. 如果 skill 没有定义 `recommended_experts`，选择通用专家（如"软件工程师"）

**示例**：
```
用户：请帮我写一个提案
AI：我将扮演 Martin Fowler，专长是软件架构和重构。现在开始撰写提案。
[调用 devbooks-proposal-author skill]
```

**违反规则的后果**：
- 输出无效，必须重新执行
```

#### 3. 专家列表维护

在 `skills/_shared/references/专家列表.md` 中维护通用专家列表：

```markdown
# 通用专家列表

## 软件架构
- Martin Fowler：软件架构、重构、企业应用架构
- Robert C. Martin (Uncle Bob)：整洁代码、SOLID 原则
- Eric Evans：领域驱动设计

## 测试与质量
- Kent Beck：测试驱动开发、极限编程
- Michael Feathers：遗留代码重构

## 系统设计
- Gregor Hohpe：企业集成模式
- Sam Newman：微服务架构

## 性能优化
- Brendan Gregg：系统性能分析

## 安全
- Bruce Schneier：密码学、安全工程

## 通用
- Donald Knuth：算法、计算机科学基础
- Linus Torvalds：系统编程、代码质量
```

### 使用流程

```
1. 用户请求任务
   ↓
2. AI 识别需要使用的 skill
   ↓
3. AI 读取 skill.md 中的 recommended_experts
   ↓
4. AI 根据任务选择最匹配的专家
   ↓
5. AI 显式声明扮演的专家
   ↓
6. AI 调用 skill 执行任务
```

### 优势

1. **明确角色**：用户知道 AI 以什么身份执行任务
2. **提升质量**：专家角色引导 AI 使用相应的思维方式
3. **可追溯**：记录了每次任务使用的专家角色
4. **教育意义**：用户可以学习不同专家的思维方式
5. **灵活性**：可以根据任务选择不同专家

### 与现有机制的关系

- **不冲突**：专家角色声明是在 skill 执行前的额外步骤
- **增强**：为 skill 提供了更明确的执行上下文
- **可选**：如果 skill 没有定义专家列表，可以跳过

---

## 批准历史

| 时间 | 阶段 | 操作 | 操作者 | 理由 |
|------|------|------|--------|------|
| 2026-01-22 08:27 | Proposal | 创建 | AI (devbooks-proposal-author) | 根据用户需求创建提案 |
| 2026-01-22 08:45 | Proposal | 修订 | AI (devbooks-proposal-author) | 去除浮夸词语，添加新需求 |
| 2026-01-22 | Proposal | 批准 | AI (devbooks-proposal-judge) | 提案通过，进入设计阶段 |

---

**下一步**：
- 运行 `devbooks-design-doc` skill 处理变更 `20260122-0827-enhance-docs-consistency`
- 在设计阶段补充 AC、算法、配置格式等内容（详见 `judge-decision.md`）
