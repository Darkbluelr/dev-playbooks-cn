# DevBooks / Dev Playbooks

DevBooks 是面向 **Claude Code / Codex CLI** 的“代理式 AI 开发工作流（agentic workflow）”：通过 **Skills + 上下文协议适配器（Context Protocol Adapters）**，把大型变更变成可控、可追溯、可归档的闭环（协议化上下文、可执行验收锚点、角色隔离、影响分析等）。

## 快速开始

### 1) 安装 DevBooks CLI（npm，推荐）

全局安装：

```bash
npm install -g devbooks
```

一次性使用（无需全局安装）：

```bash
npx devbooks@latest init
```

### 2) 在你的项目中初始化

如果你用了上面的 `npx devbooks@latest init`，可以跳过这一步。

在项目根目录执行：

```bash
devbooks init
```

后续需要更新现有配置时：

```bash
devbooks update
```

安装落点（`devbooks init` 或安装脚本之后）：
- Claude Code：`~/.claude/skills/devbooks-*`
- Codex CLI：`$CODEX_HOME/skills/devbooks-*`（默认 `~/.codex/skills/devbooks-*`）
- Codex Prompts：`$CODEX_HOME/prompts/devbooks-*.md`（可选）

### 3) 从源码安装（贡献者/本地调试）

在本仓库根目录执行：

```bash
./scripts/install-skills.sh
```

如果你主要使用 Codex CLI，并希望同时安装命令入口（prompts）：

```bash
./scripts/install-skills.sh --with-codex-prompts
```

### 4) 集成到你的项目

DevBooks Skills 依赖两个目录根定义：
- `<truth-root>`：当前真理目录根（默认 `dev-playbooks/specs/`）
- `<change-root>`：变更包目录根（默认 `dev-playbooks/changes/`）

**快速集成**：
- 模板入口：`setup/generic/devbooks-integration-template.md`
- 让 AI 自动接线：`setup/generic/installation-prompt.md`

## 核心原则

- **协议优先**：把“当前真理 / 变更包 / 归档证据”写进项目里（而不是只存在聊天记录里）。
- **锚点优先**：完成定义来自 `tests/`、静态检查、构建产物与证据（而不是 AI 自评“已完成”）。
- **角色隔离**：Test Owner 与 Coder 必须分开对话/实例；Coder 不能修改 `tests/**`。
- **结构闸门**：遇到“代理指标驱动”（行数/文件数/机械拆分/命名格式）时先停下评估，优先关注复杂度/耦合/依赖方向/测试质量。
- **真理源分离**：`<truth-root>` 是只读“唯一真理”；`<change-root>/<change-id>/` 是临时工作区（可自由试验）；归档 = 把有效的派生结果合回真理源。

---

## 日常变更工作流

### 双入口架构（v2）

DevBooks 提供两种入口：

1. **Router 入口（推荐）**：输入需求，输出完整执行路线
2. **直达命令**：熟悉流程后，直接调用对应 Skill

### 使用 Router（新手推荐）

```
/devbooks:router <你的需求>
```

Router 会分析需求并输出执行计划，告诉你下一步应该用哪个命令。

### 直达命令（21 个命令与 21 个 Skills 1:1 映射）

| 阶段 | 命令 | 说明 |
|------|------|------|
| **Proposal** | `/devbooks:proposal` | 创建变更提案 |
| | `/devbooks:impact` | 影响分析 |
| | `/devbooks:challenger` | 质疑提案 |
| | `/devbooks:judge` | 裁决提案 |
| | `/devbooks:debate` | 三角对辩工作流 |
| | `/devbooks:design` | 设计文档 |
| | `/devbooks:spec` | 规格与契约 |
| | `/devbooks:c4` | C4 架构地图 |
| | `/devbooks:plan` | 实现计划 |
| **Apply** | `/devbooks:test` | Test Owner（必须单独对话） |
| | `/devbooks:code` | Coder（必须单独对话） |
| | `/devbooks:backport` | 设计回写 |
| **Review** | `/devbooks:review` | 代码评审 |
| | `/devbooks:test-review` | 测试评审 |
| **Archive** | `/devbooks:gardener` | 规格园丁 |
| | `/devbooks:delivery` | 交付闭环 |
| **Standalone** | `/devbooks:entropy` | 熵度量 |
| | `/devbooks:federation` | 跨仓库联邦分析 |
| | `/devbooks:bootstrap` | 存量项目初始化 |
| | `/devbooks:index` | 索引引导（Index bootstrap） |

### 典型工作流示例

**1. Proposal（提案阶段：禁止编码）**

```
/devbooks:proposal <你的需求>
```

产物：`proposal.md`（必需），`design.md`（非 trivial 变更必需），`tasks.md`（必需）

**2. Apply（实现阶段：强制角色隔离）**

必须开 2 个独立对话/实例：

```
/devbooks:test <change-id>   # Test Owner
/devbooks:code <change-id>   # Coder
```

- Test Owner：编写 `verification.md` + 测试，先跑出 **Red** 基线
- Coder：按 `tasks.md` 实现，让闸门 **Green**（禁止修改 tests）

**3. Review（评审阶段）**

```
/devbooks:review <change-id>
```

**4. Archive（归档阶段）**

```
/devbooks:gardener <change-id>
```

---

## Skills 索引

### 角色类（Role-based）
- `devbooks-router`：路由到合适的 Skill
- `devbooks-proposal-author` / `devbooks-proposal-challenger` / `devbooks-proposal-judge`
- `devbooks-impact-analysis` / `devbooks-design-doc` / `devbooks-spec-contract` / `devbooks-implementation-plan`
- `devbooks-test-owner` / `devbooks-coder` / `devbooks-code-review` / `devbooks-test-reviewer` / `devbooks-spec-gardener`
- `devbooks-c4-map` / `devbooks-design-backport`

### 工作流类（Workflow-based）
- `devbooks-proposal-debate-workflow` / `devbooks-delivery-workflow`
- `devbooks-brownfield-bootstrap`：存量项目初始化
- `devbooks-index-bootstrap`：生成 SCIP 索引（需要 CKB MCP）
- `devbooks-federation`：跨仓库联邦分析

### 指标类（Metrics-based）
- `devbooks-entropy-monitor`：系统熵度量与报告

---

## 仓库结构

```
skills/          # devbooks-* Skills 源码
setup/           # 上下文协议适配与集成模板
└── generic/     # 协议无关模板
scripts/         # 安装与工具脚本
docs/            # 文档
tools/           # 工具脚本（复杂度、熵度量等）
bin/             # CLI 入口
```

---

## 文档索引

### MCP 自动检测与降级

DevBooks Skills 支持 MCP（Model Context Protocol）自动检测与优雅降级：

| MCP 状态 | 行为 |
|----------|------|
| CKB 可用 | 增强模式：使用 `analyzeImpact`、`getCallGraph`、`getHotspots` 等图能力 |
| CKB 不可用或超时（2s） | 基础模式：使用 Grep + Glob 文本搜索（功能完整，但少部分增强能力不可用） |

**检测机制**：
- 每个 Skill 执行时会自动调用 `mcp__ckb__getStatus()`
- 超过 2 秒超时后输出：`[MCP detection timeout, degraded to basic mode]`
- 无需手动选择“基础提示词/增强提示词”

**Slash Commands 更新**：

当你更新 MCP 配置（例如添加/移除 CKB Server）后，MCP 检测在运行时自动生效，无需手动更新 Slash Commands。

如果你需要重新安装 Skills（例如升级 DevBooks 版本）：

```bash
./scripts/install-skills.sh
```

### 其它文档

- Slash Commands 指南：`docs/slash-commands-guide.md`
- Skills 快速索引：`skills/skills-usage-guide.md`
- MCP 配置建议：`docs/recommended-mcp.md`

---

## 可选：脚本化常用步骤

DevBooks 的确定性脚本位于已安装 Skill 的 `scripts/` 目录中：

```bash
# Codex
DEVBOOKS_SCRIPTS="${CODEX_HOME:-$HOME/.codex}/skills/devbooks-delivery-workflow/scripts"

# Claude
DEVBOOKS_SCRIPTS="$HOME/.claude/skills/devbooks-delivery-workflow/scripts"
```

常用命令：
- 生成变更包骨架：`"$DEVBOOKS_SCRIPTS/change-scaffold.sh" <change-id> ...`
- 一键校验：`"$DEVBOOKS_SCRIPTS/change-check.sh" <change-id> --mode strict ...`
- 证据采集：`"$DEVBOOKS_SCRIPTS/change-evidence.sh" <change-id> ...`

---

## 质量闸门（v2）

DevBooks 提供质量闸门机制，用于拦截“伪完成”，确保变更包质量真实可验证：

| 闸门 | 触发模式 | 检查内容 |
|------|----------|----------|
| Green Evidence Check | archive, strict | `evidence/green-final/` 存在且非空 |
| Task Completion Rate Check | strict | tasks.md 中任务都已完成或有 SKIP-APPROVED |
| Test Failure Interception | archive, strict | Green evidence 中不存在失败模式 |
| P0 Skip Approval | strict | P0 任务跳过必须有审批记录 |
| Role Boundary Check | apply --role | Coder 不能改 tests/，Test Owner 不能改 src/ |

**核心脚本**：
- `change-check.sh`：一键校验（支持 `--mode proposal|apply|archive|strict`）
- `handoff-check.sh`：角色交接握手检查
- `env-match-check.sh`：测试环境声明检查
- `audit-scope.sh`：全量审计扫描
- `progress-dashboard.sh`：进度看板

详细说明：`dev-playbooks/specs/quality-gates/spec.md`

---

## 可选：原型模式（Prototype Mode）

当技术路径不确定、需要快速验证可行性时：

1. 创建原型：`change-scaffold.sh <change-id> --prototype ...`
2. Test Owner 使用 `--prototype`：产出表征测试（可不要求 Red 基线）
3. Coder 使用 `--prototype`：输出到 `prototype/src/`（禁止落入仓库 src/）
4. 提升或丢弃：`prototype-promote.sh <change-id> ...`

---

## 存量项目初始化（Brownfield）

当 `<truth-root>` 为空时，使用 `devbooks-brownfield-bootstrap`：
- 一次性产出：项目画像、术语表（可选）、基线 specs、最小验证锚点
- 自动生成：模块依赖图、技术债热点、领域概念等“代码地图”产物

---

## 工具脚本

| 工具 | 作用 |
|------|------|
| `tools/devbooks-complexity.sh` | 圈复杂度计算 |
| `tools/devbooks-entropy-viz.sh` | 熵度量可视化 |

配置文件：`.devbooks/config.yaml`

---

## License

MIT
