---
name: devbooks-brownfield-bootstrap
description: devbooks-brownfield-bootstrap：存量项目初始化：在当前真理目录为空时生成项目画像、术语表、SSOT、基线规格与最小验证锚点，避免"边补 specs 边改行为"。用户说"存量初始化/基线 specs/项目画像/建立 glossary/初始化 SSOT/把老项目接入上下文协议"等时使用。
recommended_experts: ["System Architect", "Technical Writer"]
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：存量项目初始化（Brownfield Bootstrap）

## 渐进披露
### 基础层（必读）
目标：明确本 Skill 的核心产出与使用范围。
输入：用户目标、现有文档、变更包上下文或项目路径。
输出：可执行产物、下一步指引或记录路径。
边界：不替代其他角色职责，不触碰 tests/。
证据：引用产出物路径或执行记录。

### 进阶层（可选）
适用：需要细化策略、边界或风险提示时补充。

### 扩展层（可选）
适用：需要与外部系统或可选工具协同时补充。

## 与 ssot-maintainer 的职责边界

| Skill | 职责 | 类比 |
|-------|------|------|
| **brownfield-bootstrap** | **创建** SSOT/Spec 骨架（从无到有） | `git init` |
| **ssot-maintainer** | **维护** SSOT（增删改已有条目） | `git commit` |

**关键区分**：
- 本 Skill 负责**初始化**：当 `ssot/` 目录不存在或为空时，生成骨架
- `ssot-maintainer` 负责**维护**：当 SSOT 已存在后，处理 delta、同步索引、刷新 ledger
- 初始化完成后，后续 SSOT 变更应使用 `ssot-maintainer`

## SSOT 与 Spec 的区别

| 维度 | SSOT | Spec |
|------|------|------|
| **抽象层次** | 需求层（What） | 设计层（How） |
| **粒度** | 项目级 | 模块级 |
| **位置** | `<devbooks-root>/ssot/` | `<truth-root>/` |
| **内容** | 系统必须做什么 | 模块如何工作 |

详见 `docs/SSOT与Spec边界说明.md`

## 推荐 MCP 能力类型
- 代码检索（code-search）
- 引用追踪（reference-tracking）
- 影响分析（impact-analysis）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根（通常是 `dev-playbooks/specs/`）
- `<change-root>`：变更包目录根（通常是 `dev-playbooks/changes/`）
- `<devbooks-root>`：DevBooks 管理目录（通常是 `dev-playbooks/`）

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **创建 DevBooks 目录结构并初始化基础配置**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

---

## 核心职责

存量项目初始化包含以下职责：

### 1. 基础配置文件初始化

在 `<devbooks-root>/`（通常是 `dev-playbooks/`）下检查并创建：

| 文件 | 用途 | 创建条件 |
|------|------|----------|
| `constitution.md` | 项目宪法（GIP 原则） | 文件不存在时 |
| `project.md` | 项目上下文（技术栈/约定） | 文件不存在时 |

**创建方式**：
- **不是简单复制模板**，而是根据代码分析结果定制内容
- `constitution.md`：基于默认 GIP 原则，可根据项目特性调整
- `project.md`：根据代码分析结果填充：
  - 技术栈（语言/框架/数据库）
  - 开发约定（代码风格/测试策略/Git 工作流）
  - 领域上下文（核心概念/角色定义）
  - 目录根映射

### 2. 项目画像与元数据

在 `<truth-root>/_meta/` 下生成：

| 产物 | 路径 | 说明 |
|------|------|------|
| 项目画像 | `_meta/project-profile.md` | 三层架构的详细技术画像 |
| 术语表 | `_meta/glossary.md` | 统一语言表（可选但推荐） |
| 文档维护元数据 | `_meta/docs-maintenance.md` | 文档风格与维护配置 |
| 领域概念 | `_meta/key-concepts.md` | 基于代码语义的概念提取（可选） |

### 3. 项目级 SSOT 初始化（核心职责）

在 `<devbooks-root>/ssot/` 下生成 SSOT 骨架：

| 产物 | 路径 | 说明 |
|------|------|------|
| SSOT 文档 | `ssot/SSOT.md` | 人类可读的需求/约束文档 |
| 需求索引 | `ssot/requirements.index.yaml` | 机读索引（稳定 ID → 锚点 → statement） |

**生成策略：骨架优先 + 渐进补全**

1. **核心契约提取**（AI 主导）
   - 扫描 API 定义（OpenAPI/GraphQL/RPC）
   - 扫描数据模型（Schema/Entity）
   - 扫描配置约束（env vars/feature flags）
   - 扫描关键业务规则（从代码注释/测试用例推断）

2. **置信度标记**
   - 每条 requirement 标记 `confidence: low|medium|high`
   - AI 生成默认为 `medium`
   - 人类确认后升级为 `high`

3. **最小可行 SSOT**
   - 初始目标：5-15 条核心需求
   - 不追求完整，追求可寻址
   - 后续通过 `ssot-maintainer` 渐进补全

**上游 SSOT 处理**：
- 若项目已存在上游 SSOT（例如独立 `SSOT docs/`）
- 本 Skill 不复制原文，而是在 `ssot/SSOT.md` 中写入指针/链接
- 并以 `requirements.index.yaml` 建立稳定 ID 与锚点索引

### 4. 架构分析产物

在 `<truth-root>/architecture/` 下生成：

| 产物 | 路径 | 数据来源 |
|------|------|----------|
| **C4 架构地图** | `architecture/c4.md` | 综合分析（可选结合结构化能力） |
| 模块依赖图 | `architecture/module-graph.md` | 结构化依赖分析（可选） |
| 技术债热点 | `architecture/hotspots.md` | 变更历史 + 复杂度分析（可选） |
| 分层约束 | `architecture/layering-constraints.md` | 代码分析（可选） |

> **设计决策**：C4 架构地图现在由 brownfield-bootstrap 在初始化时生成，后续架构变更通过 design.md 的 Architecture Impact 章节记录，由 archiver 在归档时合并。

### 5. 基线变更包（可选）

在 `<change-root>/<baseline-id>/` 下生成：

| 产物 | 说明 |
|------|------|
| `proposal.md` | 基线范围、In/Out、风险 |
| `design.md` | 现状盘点（capability inventory） |
| `specs/<cap>/spec.md` | 基线 spec deltas（ADDED 为主） |
| `verification.md` | 最小验证锚点计划 |

---

## COD 模型生成（Code Overview & Dependencies）

在初始化时可选生成项目的“代码地图”（取决于可用的结构化代码分析能力）：

### 自动生成产物

| 产物 | 路径 | 数据来源 |
|------|------|----------|
| **C4 架构地图** | `<truth-root>/architecture/c4.md` | 综合分析 |
| 模块依赖图 | `<truth-root>/architecture/module-graph.md` | 结构化依赖分析（可选） |
| 技术债热点 | `<truth-root>/architecture/hotspots.md` | 变更历史 + 复杂度分析（可选） |
| 领域概念 | `<truth-root>/_meta/key-concepts.md` | 代码语义概念提取（可选） |
| 项目画像 | `<truth-root>/_meta/project-profile.md` | 综合分析 |

### C4 架构地图生成规则

初始化时生成的 C4 地图应包含：

1. **Context 层**：系统与外部参与者（用户、外部系统）的关系
2. **Container 层**：系统内的容器（应用、数据库、服务）
3. **Component 层**：主要容器内的组件（模块、类）

**输出格式**：

```markdown
# C4 Architecture Map

## System Context

[描述系统边界与外部交互]

## Container Diagram

| Container | 技术栈 | 职责 |
|-----------|--------|------|
| <name> | <tech> | <responsibility> |

## Component Diagram

### <Container Name>

| Component | 职责 | 依赖 |
|-----------|------|------|
| <name> | <responsibility> | <dependencies> |

## Architecture Guardrails

### Layering Constraints

| 层级 | 可依赖 | 禁止依赖 |
|------|--------|----------|
| <layer> | <allowed> | <forbidden> |
```

### 热点计算公式

```
热点分数 = 变更频率 × 圈复杂度
```

- **高热点**（分数 > 阈值）：频繁修改 + 高复杂度 = Bug 密集区
- **休眠债务**（高复杂度 + 低频率）：暂时安全但需关注
- **活跃健康**（高频率 + 低复杂度）：正常维护区域

### 边界识别

自动区分：
- **用户代码**：`src/`、`lib/`、`app/` 等（可修改）
- **库代码**：`node_modules/`、`vendor/`、`.venv/` 等（不可变接口）
- **生成代码**：`dist/`、`build/`、`*.generated.*` 等（禁止手动修改）

### 执行流程

1) **检查可用能力**：确认是否具备结构化代码分析能力（如依赖关系或引用追踪）。
2) **生成 COD 产物**：基于可用的代码检索、引用追踪与变更历史分析生成模块依赖、热点与概念。
3) **生成项目画像**：整合以上数据 + 传统分析

## 参考骨架与模板

- 工作流：`references/存量项目初始化.md`
- 代码导航策略：`references/代码导航策略.md`
- **项目画像模板（三层架构）**：`templates/项目画像模板.md`
- 一次性提示词：`references/存量项目初始化提示词.md`
- 模板（按需）：`references/术语表模板.md`

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的初始化范围。

检测规则参考：`skills/_shared/上下文检测模板.md`

### 检测流程

1. 检测 `<devbooks-root>/constitution.md` 是否存在
2. 检测 `<devbooks-root>/project.md` 是否存在
3. 检测 `<truth-root>/` 是否为空或基本为空
4. 检测结构化代码分析能力是否可用
5. 检测项目规模和语言栈

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **全新初始化** | devbooks-root 不存在或为空 | 创建完整目录结构 + constitution + project + 画像 |
| **补充配置** | constitution/project 缺失 | 只补充缺失的配置文件 |
| **完整初始化** | truth-root 为空 | 生成所有基础产物（画像/基线/验证） |
| **增量初始化** | truth-root 部分存在 | 只补充缺失产物 |
| **结构化分析** | 结构化能力可用 | 使用依赖关系与引用追踪增强画像 |
| **文本分析** | 仅文本检索可用 | 使用传统分析方法 |

### 检测输出示例

```
检测结果：
- devbooks-root：存在
- constitution.md：不存在 → 将创建
- project.md：不存在 → 将创建
- truth-root：为空
- 结构化能力：可用
- 项目规模：中型（~50K LOC）
- 运行模式：补充配置 + 完整初始化 + 结构化分析
```
