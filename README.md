# DevBooks / Dev Playbooks

DevBooks 是一套面向 **Claude Code / Codex CLI** 的「代理式 AI 编程工作流」：通过 **Skills + 上下文协议适配器**，把大型项目变更做成可控、可追溯、可归档的闭环（协议化上下文、可执行验收锚点、角色隔离、影响分析等）。

## 核心原则

- **协议优先**：把"当前真理 / 变更包 / 归档"落盘在项目里（而不是只存在于聊天）。
- **锚点优先**：完成的定义来自 `tests/`、静态检查、构建与证据（而不是 AI 自评）。
- **角色隔离**：Test Owner 与 Coder 必须独立对话/独立实例；Coder 禁止修改 `tests/**`。
- **结构守门**：遇到"代理指标驱动"的要求必须停线评估，优先复杂度/耦合/依赖方向/测试质量。
- **真理源分离**：`<truth-root>` 是唯一真理源（只读参考），`<change-root>/<change-id>/` 是临时工作区（可任意试错）；归档 = 将派生数据合并回真理源。

---

## 快速开始

### 1. 安装 Skills

在本仓库根目录执行：

```bash
./scripts/install-skills.sh
```

如果你主要用 Codex CLI，并希望安装命令入口（prompts）：

```bash
./scripts/install-skills.sh --with-codex-prompts
```

安装位置：
- Claude Code：`~/.claude/skills/devbooks-*`
- Codex CLI：`$CODEX_HOME/skills/devbooks-*`（默认 `~/.codex/skills/devbooks-*`）
- Codex Prompts：`$CODEX_HOME/prompts/devbooks-*.md`（可选）

### 2. 接入你的项目

DevBooks Skills 依赖两个目录根的定义：
- `<truth-root>`：当前真理目录根（默认 `dev-playbooks/specs/`）
- `<change-root>`：变更包目录根（默认 `dev-playbooks/changes/`）

**快速接入**：
- 入口：`setup/generic/DevBooks集成模板（协议无关）.md`
- 让 AI 自动接线：`setup/generic/安装提示词.md`

---

## 日常变更闭环

### 双入口架构（v2）

DevBooks 提供两种命令入口：

1. **Router 入口**（推荐）：输入需求，获取完整执行计划
2. **直达命令**：熟悉流程后直接调用对应 Skill

### 使用 Router（推荐新手）

```
/devbooks:router <你的需求>
```

Router 会分析需求并输出执行计划，告诉你下一步用哪个命令。

### 直达命令（21 个命令与 21 个 Skills 1:1 对应）

| 阶段 | 命令 | 说明 |
|------|------|------|
| **Proposal** | `/devbooks:proposal` | 创建变更提案 |
| | `/devbooks:impact` | 影响分析 |
| | `/devbooks:challenger` | 提案质疑 |
| | `/devbooks:judge` | 提案裁决 |
| | `/devbooks:debate` | 三角对辩流程 |
| | `/devbooks:design` | 设计文档 |
| | `/devbooks:spec` | 规格与契约 |
| | `/devbooks:c4` | C4 架构地图 |
| | `/devbooks:plan` | 实现计划 |
| **Apply** | `/devbooks:test` | Test Owner（独立对话） |
| | `/devbooks:code` | Coder（独立对话） |
| | `/devbooks:backport` | 设计回写 |
| **Review** | `/devbooks:review` | 代码评审 |
| | `/devbooks:test-review` | 测试评审 |
| **Archive** | `/devbooks:gardener` | 规格园丁 |
| | `/devbooks:delivery` | 交付工作流 |
| **独立** | `/devbooks:entropy` | 熵度量 |
| | `/devbooks:federation` | 跨仓库联邦分析 |
| | `/devbooks:bootstrap` | 存量项目初始化 |
| | `/devbooks:index` | 索引引导 |

### 典型流程示例

**1. Proposal（提案阶段，禁止写代码）**

```
/devbooks:proposal <你的需求>
```

产物：`proposal.md`（必须），`design.md`（非小改动必须），`tasks.md`（必须）

**2. Apply（实现阶段，强制角色隔离）**

必须开 2 个独立对话/独立实例：
```
/devbooks:test <change-id>   # Test Owner
/devbooks:code <change-id>   # Coder
```

- Test Owner：写 `verification.md` + tests，先跑出 **Red**
- Coder：按 `tasks.md` 实现，让闸门 **Green**（禁改 tests）

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

### 角色类
- `devbooks-router`：路由到合适的 Skill
- `devbooks-proposal-author` / `devbooks-proposal-challenger` / `devbooks-proposal-judge`
- `devbooks-impact-analysis` / `devbooks-design-doc` / `devbooks-spec-contract` / `devbooks-implementation-plan`
- `devbooks-test-owner` / `devbooks-coder` / `devbooks-code-review` / `devbooks-test-reviewer` / `devbooks-spec-gardener`
- `devbooks-c4-map` / `devbooks-design-backport`

### 工作流类
- `devbooks-proposal-debate-workflow` / `devbooks-delivery-workflow`
- `devbooks-brownfield-bootstrap`：存量项目初始化
- `devbooks-index-bootstrap`：生成 SCIP 索引（需要 CKB MCP）
- `devbooks-federation`：跨仓库联邦分析

### 度量类
- `devbooks-entropy-monitor`：系统熵度量采集与报告

---

## 仓库结构

```
skills/          # devbooks-* Skills 源码
setup/           # 上下文协议适配器与集成模板
└── generic/     # 协议无关模板
scripts/         # 安装与辅助脚本
docs/            # 辅助文档
tools/           # 辅助脚本（复杂度计算、熵度量等）
```

---

## 文档索引

### MCP 自动检测与降级

DevBooks Skills 支持 MCP（Model Context Protocol）自动检测与降级：

| MCP 状态 | 行为 |
|----------|------|
| CKB 可用 | 增强模式：使用 `analyzeImpact`、`getCallGraph`、`getHotspots` 等图基工具 |
| CKB 不可用或超时（2s） | 基础模式：使用 Grep + Glob 文本搜索（功能完整，仅损失部分增强能力） |

**检测机制**：
- 每个 Skill 执行时自动调用 `mcp__ckb__getStatus()`
- 2 秒超时后输出 `[MCP 检测超时，已降级为基础模式]`
- 无需手动选择"基础提示词"或"增强提示词"

**更新 Slash 命令**：

当你更新了 MCP 配置（如新增/移除 CKB Server）后，MCP 检测是运行时自动进行的，无需手动更新 Slash 命令。

如果需要重新安装 Skills（如更新 DevBooks 版本）：

```bash
./scripts/install-skills.sh
```

### 辅助文档

- Slash 命令使用指南：`docs/slash-commands-guide.md`
- Skills 速查表：`skills/Skills使用说明.md`
- MCP 配置：`docs/推荐MCP.md`

---

## 可选：脚本化常用步骤

DevBooks 的确定性脚本位于已安装 Skill 的 `scripts/` 目录：

```bash
# Codex
DEVBOOKS_SCRIPTS="${CODEX_HOME:-$HOME/.codex}/skills/devbooks-delivery-workflow/scripts"

# Claude
DEVBOOKS_SCRIPTS="$HOME/.claude/skills/devbooks-delivery-workflow/scripts"
```

常用命令：
- 生成变更包骨架：`"$DEVBOOKS_SCRIPTS/change-scaffold.sh" <change-id> ...`
- 一键校验：`"$DEVBOOKS_SCRIPTS/change-check.sh" <change-id> --mode strict ...`
- 证据落盘：`"$DEVBOOKS_SCRIPTS/change-evidence.sh" <change-id> ...`

---

## 质量闸门（v2）

DevBooks 提供质量闸门机制，拦截"假完成"并确保变更包的真实质量：

| 闸门 | 触发模式 | 检查内容 |
|------|----------|----------|
| Green 证据检查 | archive, strict | `evidence/green-final/` 存在且非空 |
| 任务完成率检查 | strict | tasks.md 所有任务完成或有 SKIP-APPROVED |
| 测试失败拦截 | archive, strict | Green 证据中无失败模式 |
| P0 跳过审批 | strict | P0 任务跳过必须有审批记录 |
| 角色边界检查 | apply --role | Coder 禁改 tests/，Test Owner 禁改 src/ |

**核心脚本**：
- `change-check.sh`：一键校验（支持 `--mode proposal|apply|archive|strict`）
- `handoff-check.sh`：角色交接握手检查
- `env-match-check.sh`：测试环境声明检查
- `audit-scope.sh`：审计全量扫描
- `progress-dashboard.sh`：进度仪表板

详细说明参见：`docs/quality-gates-guide.md`

---

## 可选：Prototype 模式

当技术方案不确定、需要快速验证可行性时：

1. 创建原型：`change-scaffold.sh <change-id> --prototype ...`
2. Test Owner 使用 `--prototype`：产出表征测试（不需要 Red 基线）
3. Coder 使用 `--prototype`：输出到 `prototype/src/`（禁止落到仓库 src/）
4. 提升或丢弃：`prototype-promote.sh <change-id> ...`

---

## 存量项目初始化

当 `<truth-root>` 为空时，使用 `devbooks-brownfield-bootstrap`：
- 一次性产出项目画像、术语表（可选）、基线 specs 与最小验证锚点
- 自动生成模块依赖图、技术债热点、领域概念等"代码地图"产物

---

## 工具脚本

| 工具 | 用途 |
|------|------|
| `tools/devbooks-complexity.sh` | 圈复杂度计算 |
| `tools/devbooks-entropy-viz.sh` | 熵度量可视化 |

配置：`.devbooks/config.yaml`
