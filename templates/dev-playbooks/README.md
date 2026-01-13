# DevBooks

**面向 Claude Code / Codex CLI 的代理式 AI 开发工作流**

> 把大型变更变成可控、可追溯、可验证的闭环：Skills + 质量闸门 + 角色隔离。

[![npm](https://img.shields.io/npm/v/dev-playbooks-cn)](https://www.npmjs.com/package/dev-playbooks-cn)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)

---

## 为什么选择 DevBooks？

AI 编码助手很强大，但往往**不可预测**：

| 痛点 | 后果 |
|------|------|
| **AI 自评"已完成"** | 实际测试不过、边界条件遗漏 |
| **同一对话写测试又写代码** | 测试沦为"通过性测试"，而非验证规格 |
| **无验证闸门** | 伪完成悄悄进入生产环境 |
| **只支持 0→1 项目** | 存量代码库无从下手 |
| **命令太少** | 复杂变更不只是"spec/apply/archive" |

**DevBooks 的解决方案**：
- **基于证据的完成**：完成由测试/构建/证据定义，而非 AI 自我评估
- **强制角色隔离**：Test Owner 与 Coder 必须在独立对话中工作
- **多重质量闸门**：Green 证据检查、任务完成率、角色边界检查
- **21 个 Skills**：覆盖提案、设计、对辩、评审、熵度量、联邦分析等

---

## DevBooks 对比一览

| 维度 | DevBooks | OpenSpec | spec-kit | 无规格 |
|------|----------|----------|----------|--------|
| 规格驱动工作流 | 是 | 是 | 是 | 否 |
| 变更产物的可追溯性 | 变更包集中存档（proposal/design/spec/tasks/verification/evidence） | 主要以变更目录/文件组织为主 | 以文档+任务编排为主 | 无 |
| 角色与职责边界 | **强制隔离**（Test Owner / Coder） | 约定为主（不强制） | 约定为主（不强制） | 无 |
| 完成判据（DoD） | **证据驱动 + 闸门**（测试/构建/审计） | 人工定义/人工检查 | 人工定义/人工检查 | 常依赖主观判断 |
| 代码质量保障 | 守门 + 指标（熵度量/热点）+ Review 角色 | 依赖外部工具/人工 review | 依赖外部工具/人工 review | 不稳定 |
| 影响面分析 | CKB 图基能力（可降级 Grep） | 文本搜索/人工推导 | 文本搜索/人工推导 | 容易漏改 |
| 存量项目起步 | 自动生成基线规格/术语表/最小验证锚点 | 手动补齐 | 有限 | - |
| 自动化覆盖面 | 21 个 Skills（提案→实现→归档闭环） | 3 个核心命令 | 工具包（偏 0→1） | - |

---

## 工作原理

```
                           DevBooks 工作流

    PROPOSAL 阶段                  APPLY 阶段                     ARCHIVE 阶段
    (禁止编码)                     (角色隔离强制)                  (质量闸门)

    ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
    │  /devbooks:     │            │   对话 A        │            │  /devbooks:     │
    │   proposal      │            │  ┌───────────┐  │            │   gardener      │
    │   impact        │────────────│  │Test Owner │  │────────────│   delivery      │
    │   design        │            │  │(先跑 Red) │  │            │                 │
    │   spec          │            │  └───────────┘  │            │  质量闸门:       │
    │   plan          │            │                 │            │  ✓ Green 证据   │
    └─────────────────┘            │   对话 B        │            │  ✓ 任务完成     │
           │                       │  ┌───────────┐  │            │  ✓ 角色边界     │
           ▼                       │  │  Coder    │  │            │  ✓ 无失败       │
    ┌─────────────────┐            │  │(禁改测试!)│  │            └─────────────────┘
    │ 三角对辩        │            │  └───────────┘  │
    │ Author/Challenger│            └─────────────────┘
    │ /Judge          │
    └─────────────────┘
```

**核心约束**：Test Owner 与 Coder **必须在独立对话**中工作。这是硬性约束，不是建议。Coder 不能修改 `tests/**`，完成由测试/构建验证，而非 AI 自评。

---

## 快速开始

### 支持的 AI 工具

| 工具 | Slash 命令 | 自然语言 | 配置文件 |
|------|-----------|----------|----------|
| **Claude Code** | `/devbooks:*` | 支持 | `CLAUDE.md` |
| **Codex CLI** | `/devbooks:*` | 支持 | `AGENTS.md` |
| **Cursor** | - | 支持 | `.cursorrules` |
| **Windsurf** | - | 支持 | `.windsurfrules` |
| **Continue.dev** | - | 支持 | `.continuerules` |
| **GitHub Copilot** | - | 支持 | `.github/copilot-instructions.md` |
| **Gemini Code Assist** | - | 支持 | - |
| **Aider** | - | 支持 | `.aider.conf.yml` |
| **Cline** | - | 支持 | `.clinerules` |

> **提示**：对于不支持 Slash 命令的工具，使用自然语言指令，例如："运行 DevBooks proposal skill..."

### 安装与初始化

**npm 安装（推荐）：**

```bash
# 全局安装
npm install -g dev-playbooks-cn

# 在项目中初始化
dev-playbooks-cn init
```

**一次性使用：**

```bash
npx dev-playbooks-cn@latest init
```

**从源码安装（贡献者）：**

```bash
./scripts/install-skills.sh
```

### 安装落点

初始化后：
- Claude Code：`~/.claude/skills/devbooks-*`
- Codex CLI：`$CODEX_HOME/skills/devbooks-*`（默认 `~/.codex/skills/devbooks-*`）

### 快速集成

DevBooks 使用两个目录根：

| 目录 | 用途 | 默认值 |
|------|------|--------|
| `<truth-root>` | 当前规格（只读真理） | `dev-playbooks/specs/` |
| `<change-root>` | 变更包（工作区） | `dev-playbooks/changes/` |

详见 `docs/DevBooks集成模板（协议无关）.md` 或使用 `docs/DevBooks安装提示词.md` 让 AI 自动配置。

---

## 日常变更工作流

### 使用 Router（推荐）

```
/devbooks:router <你的需求>
```

Router 分析需求并输出执行计划，告诉你下一步用哪个命令。

### 直达命令

熟悉流程后，直接调用 Skill：

**1. Proposal 阶段（禁止编码）**

```
/devbooks:proposal 添加 OAuth2 用户认证
```

产物：`proposal.md`（必需）、`design.md`、`tasks.md`

**2. Apply 阶段（强制角色隔离）**

必须开 **2 个独立对话**：

```
# 对话 A - Test Owner
/devbooks:test add-oauth2

# 对话 B - Coder
/devbooks:code add-oauth2
```

- Test Owner：写 `verification.md` + 测试，先跑 **Red**
- Coder：按 `tasks.md` 实现，让闸门 **Green**（禁止改测试）

**3. Review 阶段**

```
/devbooks:review add-oauth2
```

**4. Archive 阶段**

```
/devbooks:gardener add-oauth2
```

---

## 命令参考

### Proposal 阶段

| 命令 | Skill | 说明 |
|------|-------|------|
| `/devbooks:router` | devbooks-router | 智能路由到合适的 Skill |
| `/devbooks:proposal` | devbooks-proposal-author | 创建变更提案 |
| `/devbooks:impact` | devbooks-impact-analysis | 跨模块影响分析 |
| `/devbooks:challenger` | devbooks-proposal-challenger | 质疑和挑战提案 |
| `/devbooks:judge` | devbooks-proposal-judge | 裁决提案 |
| `/devbooks:debate` | devbooks-proposal-debate-workflow | 三角对辩（Author/Challenger/Judge） |
| `/devbooks:design` | devbooks-design-doc | 创建设计文档 |
| `/devbooks:spec` | devbooks-spec-contract | 定义规格与契约 |
| `/devbooks:c4` | devbooks-c4-map | 生成 C4 架构地图 |
| `/devbooks:plan` | devbooks-implementation-plan | 创建实现计划 |

### Apply 阶段

| 命令 | Skill | 说明 |
|------|-------|------|
| `/devbooks:test` | devbooks-test-owner | Test Owner 角色（必须独立对话） |
| `/devbooks:code` | devbooks-coder | Coder 角色（必须独立对话） |
| `/devbooks:backport` | devbooks-design-backport | 回写发现到设计文档 |

### Review 阶段

| 命令 | Skill | 说明 |
|------|-------|------|
| `/devbooks:review` | devbooks-code-review | 代码评审（可读性/一致性） |
| `/devbooks:test-review` | devbooks-test-reviewer | 测试质量与覆盖率评审 |

### Archive 阶段

| 命令 | Skill | 说明 |
|------|-------|------|
| `/devbooks:gardener` | devbooks-spec-gardener | 规格维护与去重 |
| `/devbooks:delivery` | devbooks-delivery-workflow | 完整交付闭环 |

### 独立技能

| 命令 | Skill | 说明 |
|------|-------|------|
| `/devbooks:entropy` | devbooks-entropy-monitor | 系统熵度量 |
| `/devbooks:federation` | devbooks-federation | 跨仓库联邦分析 |
| `/devbooks:bootstrap` | devbooks-brownfield-bootstrap | 存量项目初始化 |
| `/devbooks:index` | devbooks-index-bootstrap | 生成 SCIP 索引 |

---

## DevBooks 对比

### vs. OpenSpec

[OpenSpec](https://github.com/Fission-AI/OpenSpec) 是轻量级规格驱动框架，用三个核心命令（proposal/apply/archive）对齐人与 AI，按功能文件夹分组变更。

**DevBooks 新增：**
- **角色隔离**：Test Owner 与 Coder 硬边界（必须独立对话）
- **质量闸门**：5+ 验证闸门拦截伪完成
- **21 个 Skills**：覆盖提案、对辩、评审、熵度量、联邦分析
- **基于证据的完成**：测试/构建定义"完成"，而非 AI 自评

**选择 OpenSpec**：简单规格驱动变更，需要轻量工作流。

**选择 DevBooks**：大型变更、需要角色分离和质量验证。

### vs. spec-kit

[GitHub spec-kit](https://github.com/github/spec-kit) 提供规格驱动开发工具包，有 constitution 文件、多步骤细化和结构化规划。

**DevBooks 新增：**
- **存量优先**：自动为现有代码库生成基线规格
- **角色隔离**：测试编写与实现强制分离
- **质量闸门**：运行时验证，不只是工作流引导
- **原型模式**：安全实验不污染主 src/

**选择 spec-kit**：0→1 绿地项目，使用支持的 AI 工具。

**选择 DevBooks**：存量项目或需要强制质量闸门。

### vs. Kiro.dev

[Kiro](https://kiro.dev/) 是 AWS 的代理式 IDE，用三阶段工作流（EARS 格式需求、设计、任务），但规格与实现产物分开存储。

**DevBooks 差异：**
- **变更包**：每个变更包含 proposal/design/spec/plan/verification/evidence，整个生命周期可在一个位置追溯
- **角色隔离**：Test Owner 与 Coder 强制分离
- **质量闸门**：通过闸门验证，不只是任务完成

**选择 Kiro**：想要集成 IDE 体验和 AWS 生态。

**选择 DevBooks**：想要变更包捆绑所有产物并强制角色边界。

### vs. 无规格

没有规格时，AI 从模糊提示生成代码，导致不可预测的输出、范围蔓延和"幻觉式完成"。

**DevBooks 带来：**
- 实现前商定规格
- 验证真实完成的质量闸门
- 防止自我验证的角色隔离
- 每个变更的证据链

---

## 核心原则

| 原则 | 说明 |
|------|------|
| **协议优先** | 真理/变更/归档写进项目，不只存在聊天记录里 |
| **锚点优先** | 完成由测试、静态分析、构建和证据定义 |
| **角色隔离** | Test Owner 与 Coder 必须在独立对话中工作 |
| **真理源分离** | `<truth-root>` 是只读真理；`<change-root>` 是临时工作区 |
| **结构闸门** | 优先关注复杂度/耦合/测试质量，而非代理指标 |

---

## 高级功能

<details>
<summary><strong>质量闸门</strong></summary>

DevBooks 提供质量闸门拦截"伪完成"：

| 闸门 | 触发模式 | 检查内容 |
|------|----------|----------|
| Green 证据检查 | archive, strict | `evidence/green-final/` 存在且非空 |
| 任务完成检查 | strict | tasks.md 中所有任务完成或 SKIP-APPROVED |
| 测试失败拦截 | archive, strict | Green 证据中无失败模式 |
| P0 跳过审批 | strict | P0 任务跳过必须有审批记录 |
| 角色边界检查 | apply --role | Coder 不能改 tests/，Test Owner 不能改 src/ |

核心脚本（位于 `~/.claude/skills/devbooks-delivery-workflow/scripts/`）：
- `change-check.sh --mode proposal|apply|archive|strict`
- `handoff-check.sh` - 角色交接验证
- `audit-scope.sh` - 全量审计扫描
- `progress-dashboard.sh` - 进度可视化

</details>

<details>
<summary><strong>原型模式</strong></summary>

技术方案不确定时：

1. 创建原型：`change-scaffold.sh <change-id> --prototype`
2. Test Owner 用 `--prototype`：表征测试（无需 Red 基线）
3. Coder 用 `--prototype`：输出到 `prototype/src/`（隔离主 src）
4. 提升或丢弃：`prototype-promote.sh <change-id>`

原型模式防止实验代码污染主源码树。

脚本位于 `~/.claude/skills/devbooks-delivery-workflow/scripts/`。

</details>

<details>
<summary><strong>熵度量监控</strong></summary>

DevBooks 跟踪四维系统熵：

| 指标 | 测量内容 |
|------|----------|
| 结构熵 | 模块复杂度和耦合 |
| 变更熵 | 变动和波动模式 |
| 测试熵 | 测试覆盖率和质量衰减 |
| 依赖熵 | 外部依赖健康度 |

用 `/devbooks:entropy` 生成报告，识别重构机会。

脚本（位于 `~/.claude/skills/devbooks-entropy-monitor/scripts/`）：`entropy-measure.sh`、`entropy-report.sh`

</details>

<details>
<summary><strong>存量项目初始化</strong></summary>

当 `<truth-root>` 为空时：

```
/devbooks:bootstrap
```

生成：
- 项目画像和术语表
- 从现有代码生成基线规格
- 最小验证锚点
- 模块依赖图
- 技术债热点

</details>

<details>
<summary><strong>跨仓库联邦</strong></summary>

多仓库分析：

```
/devbooks:federation
```

分析跨仓库边界的契约和依赖，支持协调变更。

</details>

<details>
<summary><strong>MCP 自动检测</strong></summary>

DevBooks Skills 支持 MCP（Model Context Protocol）优雅降级：在没有 MCP/CKB 的环境也能跑完整工作流；一旦检测到 CKB（Code Knowledge Base）可用，就自动启用图基能力，把"范围/引用/调用链"分析做得更准。

### 它有什么用？

- **影响分析更精确**：从"文件级猜测"升级到"符号级引用 + 调用图"，降低漏改风险
- **审查更有重点**：自动拉取热点文件，优先关注高风险区域（技术债/高变动）
- **大仓库更省心**：减少手动 Grep 的噪音与反复确认

### MCP 状态与行为

| MCP 状态 | 行为 |
|----------|------|
| CKB 可用 | 增强模式：符号级影响分析/引用查找/调用图/热点（`mcp__ckb__analyzeImpact`、`mcp__ckb__findReferences`、`mcp__ckb__getCallGraph`、`mcp__ckb__getHotspots`） |
| CKB 不可用 | 基础模式：Grep + Glob 文本搜索（功能完整，精度降低） |

### 自动检测

- 需要 MCP 的 Skills 会先调用 `mcp__ckb__getStatus` 探测可用性（2s 超时）
- 超时/失败 → 静默降级到基础模式，不阻塞执行
- 无需手动选择"基础/增强"模式

如需启用增强能力：按 `docs/推荐MCP.md` 配置 CKB，并运行 `/devbooks:index` 生成 `index.scip`。

</details>

<details>
<summary><strong>提案对辩工作流</strong></summary>

严格提案审查用三角对辩：

```
/devbooks:debate
```

三个角色：
1. **Author**：创建并捍卫提案
2. **Challenger**：质疑假设、发现缺口、识别风险
3. **Judge**：做最终决定、记录理由

决定结果：`Approved`、`Revise`、`Rejected`

</details>

---

## 从其他框架迁移

DevBooks 提供迁移脚本帮助从其他规格驱动开发工具迁移。

### 从 OpenSpec 迁移

如果你当前使用 [OpenSpec](https://github.com/Fission-AI/OpenSpec)，有 `openspec/` 目录：

```bash
# 使用 CLI（推荐）
dev-playbooks-cn migrate --from openspec

# 先预览变更
dev-playbooks-cn migrate --from openspec --dry-run

# 迁移后保留原目录
dev-playbooks-cn migrate --from openspec --keep-old
```

**迁移内容：**
- `openspec/specs/` → `dev-playbooks/specs/`
- `openspec/changes/` → `dev-playbooks/changes/`
- `openspec/project.md` → `dev-playbooks/project.md`
- 所有路径引用自动更新
- AI 工具命令目录自动清理（`.claude/commands/openspec/` 等）

### 从 GitHub spec-kit 迁移

如果你使用 [GitHub spec-kit](https://github.com/github/spec-kit)，有 `specs/` 和 `memory/` 目录：

```bash
# 使用 CLI（推荐）
dev-playbooks-cn migrate --from speckit

# 先预览变更
dev-playbooks-cn migrate --from speckit --dry-run

# 迁移后保留原目录
dev-playbooks-cn migrate --from speckit --keep-old
```

**映射规则：**

| Spec-Kit | DevBooks |
|----------|----------|
| `memory/constitution.md` | `dev-playbooks/specs/_meta/constitution.md` |
| `specs/[feature]/spec.md` | `changes/[feature]/design.md` |
| `specs/[feature]/plan.md` | `changes/[feature]/proposal.md` |
| `specs/[feature]/tasks.md` | `changes/[feature]/tasks.md` |
| `specs/[feature]/quickstart.md` | `changes/[feature]/verification.md` |
| `specs/[feature]/contracts/` | `changes/[feature]/specs/` |

### 迁移功能

两个迁移脚本都支持：

- **幂等执行**：可安全多次运行
- **断点续传**：中断后可从断点恢复
- **试运行模式**：预览变更再执行
- **自动备份**：原文件备份到 `.devbooks/backup/`
- **引用更新**：文档中的路径引用自动更新

### 迁移后步骤

迁移后：

1. 运行 `dev-playbooks-cn init` 设置 DevBooks Skills
2. 检查 `dev-playbooks/` 中的迁移文件
3. 更新 `verification.md` 文件的 AC 映射
4. 如需基线规格，运行 `/devbooks:bootstrap`

---

## 目录结构

```
dev-playbooks/
├── README.md              # 本文档
├── constitution.md        # 项目宪法（GIP 原则）
├── project.md             # 项目上下文（技术栈/约定）
├── specs/                 # 当前规格（只读真理）
│   ├── _meta/             # 元数据（术语表、项目画像）
│   └── architecture/      # 架构规格（fitness-rules）
├── changes/               # 变更包（工作区）
├── scripts/               # 辅助脚本
└── docs/                  # 文档
    ├── Slash 命令使用指南.md
    ├── 推荐MCP.md
    ├── DevBooks集成模板（协议无关）.md
    └── DevBooks安装提示词.md
```

---

## 文档

- [Slash 命令使用指南](docs/Slash%20命令使用指南.md)
- [MCP 配置建议](docs/推荐MCP.md)
- [集成模板（协议无关）](docs/DevBooks集成模板（协议无关）.md)
- [安装提示词](docs/DevBooks安装提示词.md)

---

## License

MIT
