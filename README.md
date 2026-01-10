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

DevBooks Skills 本身不依赖 OpenSpec；它们只依赖两个目录根的定义：
- `<truth-root>`：当前真理目录根（默认建议 `specs/`）
- `<change-root>`：变更包目录根（默认建议 `changes/`）

**OpenSpec 项目**：
- 入口：`setup/openspec/README.md`
- 让 AI 自动接线：`setup/openspec/安装提示词.md`
- OpenSpec 映射：`<truth-root>` → `openspec/specs/`，`<change-root>` → `openspec/changes/`

**其他项目**：
- 入口：`setup/template/DevBooks集成模板（协议无关）.md`
- 让 AI 自动接线：`setup/template/安装提示词.md`

---

## 日常变更闭环

### 质量优先闭环（兼容 OpenSpec）

**1. Proposal（提案阶段，禁止写代码）**

```
/devbooks-openspec-proposal <你的需求>
```

产物：`proposal.md`（必须），`design.md`（非小改动必须），`tasks.md`（必须）

**2. Apply（实现阶段，强制角色隔离）**

必须开 2 个独立对话/独立实例：
```
/devbooks-openspec-apply test-owner <change-id>  # Test Owner
/devbooks-openspec-apply coder <change-id>       # Coder
```

- Test Owner：写 `verification.md` + tests，先跑出 **Red**
- Coder：按 `tasks.md` 实现，让闸门 **Green**（禁改 tests）

**3. Review（评审阶段）**

```
/devbooks-openspec-apply reviewer <change-id>
```

**4. Archive（归档阶段）**

```
/devbooks-openspec-archive <change-id>
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
├── openspec/    # OpenSpec 协议集成
│   └── prompts/ # Codex CLI 命令入口（OpenSpec 专用）
└── generic/     # 协议无关模板
scripts/         # 安装与辅助脚本
docs/            # 提示词文档
tools/           # 辅助脚本（复杂度计算、熵度量等）
templates/       # CI/CD、GitHub、联邦配置模板
mcp/             # MCP 配置文档
```

---

## 文档索引

### 提示词文档

| 文档 | 说明 |
|------|------|
| `角色推荐提示词.md` | 提示词索引（按 MCP 安装情况选择） |
| `docs/基础提示词.md` | 基础版提示词（无 MCP） |
| `docs/MCP增强提示词.md` | MCP 增强提示词片段 |
| `docs/完全体提示词.md` | 完全体提示词（所有 MCP） |

### 其他文档

- Skills 速查表：`Skills使用说明.md`
- MCP 配置：`mcp/mcp-servers.md`、`mcp/mcp_claude.md`、`mcp/mcp_codex.md`

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
