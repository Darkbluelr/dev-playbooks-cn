# Proposal: multi-ai-tool-support

> **状态**: Archived（补写归档）
> **创建日期**: 2026-01-12（补写日期）
> **实际实现日期**: 2026-01-12
> **作者**: Proposal Author（补写）

---

## 1. Why（问题与目标）

### 1.1 问题陈述

DevBooks CLI 原设计与 Claude Code 深度耦合，存在以下问题：

| 问题类别 | 描述 | 影响 |
|----------|------|------|
| **平台锁定** | 仅支持 Claude Code，无法被其他 AI 工具用户采用 | 用户覆盖面受限 |
| **配置分散** | 不同 AI 工具需要手动创建各自的配置文件 | 配置繁琐、易出错 |
| **交互体验差** | 原 shell 脚本无交互式选择，需手动编辑参数 | 上手门槛高 |
| **工具碎片化** | 各 AI 工具的 instruction 文件格式不同，无统一管理 | 维护成本高 |

**市场背景**：

AI 编程助手市场快速发展，主流工具包括：
- **CLI 类**：Claude Code、Qoder、Gemini CLI、Codex CLI、OpenCode
- **IDE 类**：Cursor、Windsurf、GitHub Copilot、Continue
- **VS Code 扩展**：Antigravity

单一工具绑定策略无法满足"一套规范、多工具协同"的需求。

### 1.2 目标

**核心目标**：将 DevBooks CLI 从 Claude-specific 改造为 AI-agnostic，实现"一次配置、多工具支持"。

**成功标准**：

| 指标 | 变更前 | 变更后 |
|------|--------|--------|
| 支持的 AI 工具数量 | 1（仅 Claude Code） | 10 |
| Skills 完整支持工具数 | 1 | 2（Claude Code、Qoder） |
| 初始化交互体验 | 无（纯命令行） | 交互式多选 |
| 配置文件自动生成 | 无 | 按选择自动生成 |

---

## 2. What Changes（变更范围）

### 2.1 变更总览

本次变更将 DevBooks CLI 从单一平台支持扩展为多 AI 工具支持平台，主要包括四个方面：

#### 2.1.1 AI 工具支持矩阵

| 工具 ID | 工具名称 | 支持级别 | 配置文件 |
|---------|----------|----------|----------|
| `claude` | Claude Code | 完整 Skills | `CLAUDE.md` |
| `qoder` | Qoder CLI | 完整 Skills | `AGENTS.md` |
| `cursor` | Cursor | Rules 系统 | `.cursor/rules/devbooks.md` |
| `windsurf` | Windsurf | Rules 系统 | `.windsurf/rules/devbooks.md` |
| `gemini` | Gemini CLI | Rules 系统 | `GEMINI.md` |
| `antigravity` | Antigravity | Rules 系统 | `GEMINI.md` |
| `opencode` | OpenCode | Rules 系统 | `AGENTS.md` |
| `github-copilot` | GitHub Copilot | 自定义指令 | `.github/copilot-instructions.md` |
| `continue` | Continue | 自定义指令 | `.continue/prompts/` |
| `codex` | Codex CLI | 基础支持 | `AGENTS.md` |

#### 2.1.2 支持级别定义

| 级别 | 标识 | 说明 | 适用工具 |
|------|------|------|----------|
| **完整 Skills** | `FULL` | 独立 Skills/Agents 系统，可按需调用，有独立上下文 | Claude Code, Qoder |
| **Rules 系统** | `RULES` | 规则自动应用于匹配的文件/场景，功能接近 Skills | Cursor, Windsurf, Gemini, Antigravity, OpenCode |
| **自定义指令** | `AGENTS` | 项目级指令文件，AI 会参考但无法主动调用 | GitHub Copilot, Continue |
| **基础支持** | `BASIC` | 仅支持全局提示词，通过 AGENTS.md 模拟 | Codex |

#### 2.1.3 交互式 UI 升级

- 使用 `@inquirer/prompts` 实现多选复选框界面
- 使用 `chalk` 美化终端输出（颜色、图标）
- 使用 `ora` 实现进度 spinner
- 显示 Skills 支持级别说明，帮助用户理解各工具能力差异

#### 2.1.4 Slash 命令统一化

创建 6 个统一的 DevBooks 工作流命令：

| 命令 | 文件 | 功能 |
|------|------|------|
| `/devbooks:proposal` | `proposal.md` | 创建变更提案 |
| `/devbooks:design` | `design.md` | 创建设计文档 |
| `/devbooks:apply` | `apply.md` | 执行实现（角色：test-owner/coder/reviewer） |
| `/devbooks:archive` | `archive.md` | 归档变更包 |
| `/devbooks:quick` | `quick.md` | 快速修复流程 |
| `/devbooks:review` | `review.md` | 代码评审 |

### 2.2 非目标（显式排除）

| 排除项 | 原因 |
|--------|------|
| 修改现有 Skills 的核心逻辑 | 本次专注于工具支持扩展，不改变工作流语义 |
| 为每个工具定制 Skills | 维护成本过高，采用通用 + 适配层策略 |
| 实现工具间同步机制 | 超出范围，各工具独立运行 |

### 2.3 影响文件清单

**核心修改文件（2 个）**：

1. `package.json` - 包名改为 `devbooks`，添加 npm 依赖
2. `bin/devbooks.js` - 完整重写 CLI 实现

**新增文件（7 个）**：

1. `slash-commands/devbooks/proposal.md`
2. `slash-commands/devbooks/design.md`
3. `slash-commands/devbooks/apply.md`
4. `slash-commands/devbooks/archive.md`
5. `slash-commands/devbooks/quick.md`
6. `slash-commands/devbooks/review.md`
7. `.npmignore`（npm 发布配置）

**删除文件**：

- `templates/claude-commands/`（旧的 Claude 专用命令目录）

---

## 3. Impact（影响分析）

### 3.1 Scope 摘要

| 维度 | 数量 | 说明 |
|------|------|------|
| 直接影响文件 | 2 | package.json, bin/devbooks.js |
| 新增文件 | 7 | slash-commands/ + .npmignore |
| 删除文件 | 1 目录 | templates/claude-commands/ |
| 新增依赖 | 3 | @inquirer/prompts, chalk, ora |

### 3.2 用户影响

| 用户类型 | 变更前 | 变更后 | 迁移成本 |
|----------|--------|--------|----------|
| Claude Code 用户 | 直接可用 | 需运行 `devbooks init` 重新配置 | 低 |
| 其他 AI 工具用户 | 不支持 | 运行 `devbooks init` 选择工具 | 低 |
| 现有项目 | - | 运行 `devbooks update` 升级 | 低 |

### 3.3 对外契约影响

| 契约 | 变更类型 | 兼容性 | 说明 |
|------|----------|--------|------|
| CLI 命令 | 增强 | 向后兼容 | `devbooks init` 新增交互模式 |
| 配置文件 | 新增字段 | 向后兼容 | `.devbooks/config.yaml` 新增 `ai_tools` 字段 |
| Slash 命令位置 | 变更 | **需迁移** | 从 `.claude/commands/` 移至 `.<tool>/commands/devbooks/` |
| Skills 安装位置 | 不变 | 完全兼容 | 仍安装到 `~/.claude/skills/` |

### 3.4 依赖分析

**新增 npm 依赖**：

| 依赖 | 版本 | 用途 | 大小 |
|------|------|------|------|
| `@inquirer/prompts` | ^7.0.0 | 交互式 CLI 组件（checkbox, confirm） | ~50KB |
| `chalk` | ^5.3.0 | 终端文本样式 | ~20KB |
| `ora` | ^8.0.0 | 进度 spinner | ~30KB |

**依赖影响**：
- Node.js 最低版本要求：18+（因 ESM + 依赖要求）
- 包体积增加约 100KB（可接受）

### 3.5 风险评估

| 风险 ID | 描述 | 影响 | 概率 | 缓解措施 |
|---------|------|------|------|----------|
| R1 | 某些 AI 工具配置格式变更 | 中 | 中 | 配置模板化，易于更新 |
| R2 | 用户对支持级别理解偏差 | 低 | 中 | 在 CLI 中显示详细说明 |
| R3 | Windows 路径兼容性 | 中 | 低 | 使用 `path` 模块处理路径 |
| R4 | 非交互式环境下的使用 | 中 | 中 | 提供 `--tools` 参数跳过交互 |

---

## 4. Decision Log（决策记录）

> **注**: 本决策记录为补写，记录实现过程中的关键设计决策。

### 4.1 决策状态

**状态**: `Done`（实现已完成，提案补写）

### 4.2 关键设计决策

#### D1: Skills 支持级别分层

**问题**: 不同 AI 工具的能力差异如何处理？

**选项**:
- A: 忽略差异，统一对待
- B: 按能力分层，提供不同级别的支持

**决策**: 选择 **B**

**理由**:
1. 各 AI 工具的 Skills/Rules 能力差异客观存在
2. 分层让用户明确知道所选工具的支持程度
3. 便于后续针对性优化

---

#### D2: 配置文件命名策略

**问题**: 不同工具的指令文件如何命名？

**选项**:
- A: 统一使用 `AGENTS.md`
- B: 按工具惯例使用各自文件名
- C: 混合策略：优先遵循工具惯例

**决策**: 选择 **C**

**实现**:
- Claude Code → `CLAUDE.md`（工具惯例）
- Gemini/Antigravity → `GEMINI.md`（工具惯例）
- Qoder/OpenCode/Codex → `AGENTS.md`（通用命名）
- Cursor/Windsurf → `.xxx/rules/devbooks.md`（工具惯例）
- GitHub Copilot → `.github/copilot-instructions.md`（工具惯例）

**理由**: 遵循各工具的既有惯例，减少用户认知成本。

---

#### D3: Slash 命令目录结构

**问题**: Slash 命令放在哪里？

**选项**:
- A: 各工具独立目录，内容相同
- B: 统一源目录，安装时复制到各工具目录
- C: 符号链接共享

**决策**: 选择 **B**

**实现**:
- 源目录: `slash-commands/devbooks/`
- 安装时复制到: `.<tool>/commands/devbooks/`

**理由**:
1. 避免符号链接在 Windows 上的兼容性问题
2. 便于各工具独立定制（如果需要）
3. 源目录集中管理，易于更新

---

#### D4: 交互式 vs 命令行参数

**问题**: 初始化时如何选择工具？

**选项**:
- A: 仅命令行参数
- B: 仅交互式
- C: 交互式为主，提供命令行参数跳过

**决策**: 选择 **C**

**实现**:
- 默认启动交互式多选界面
- 提供 `--tools` 参数支持非交互式模式
- 支持 `--tools all/none/<comma-separated>`

**理由**: 兼顾易用性（交互式）和自动化需求（CI/脚本）。

---

### 4.3 补写说明

本提案为已实现功能的补写文档，旨在：

1. **追溯记录**: 补充设计决策的背景与理由
2. **文档完整性**: 符合 DevBooks 工作流的闭环要求
3. **知识沉淀**: 便于后续维护者理解设计意图

**补写日期**: 2026-01-12

**实际变更内容**: 所有代码变更已合并，详见 `bin/devbooks.js` 和 `slash-commands/devbooks/` 目录。

---

## 5. Validation（验收锚点）

> **注**: 以下为补写的验收标准，基于已实现功能。

### 5.1 验收标准（AC）

| AC ID | 验收条件 | 验证方法 | 状态 |
|-------|----------|----------|------|
| AC-001 | `devbooks init` 显示工具选择界面 | 手动执行 | PASS |
| AC-002 | 选择 Claude Code 后生成 `CLAUDE.md` | 检查文件 | PASS |
| AC-003 | 选择 Cursor 后生成 `.cursor/rules/devbooks.md` | 检查文件 | PASS |
| AC-004 | `devbooks --help` 显示支持的工具列表 | 手动执行 | PASS |
| AC-005 | `devbooks init --tools claude,cursor` 非交互式工作 | 手动执行 | PASS |
| AC-006 | `devbooks update` 更新已配置工具的文件 | 手动执行 | PASS |
| AC-007 | Slash 命令安装到正确的工具目录 | 检查目录 | PASS |
| AC-008 | `.devbooks/config.yaml` 记录选择的工具 | 检查文件 | PASS |
| AC-009 | Skills 正确安装到 `~/.claude/skills/` | 检查目录 | PASS |
| AC-010 | 支持级别说明正确显示 | 手动执行 | PASS |

---

## 附录

### A. 使用示例

**交互式初始化**:

```bash
$ devbooks init

╔══════════════════════════════════════╗
║         DevBooks 初始化向导         ║
╚══════════════════════════════════════╝

📚 Skills 支持级别说明
──────────────────────────────────────────────────

★ 完整 Skills - Claude Code, Qoder
   └ 独立的 Skills/Agents 系统，可按需调用，有独立上下文

◆ Rules 系统 - Cursor, Windsurf, Gemini, Antigravity, OpenCode
   └ 规则自动应用于匹配的文件/场景，功能接近 Skills

● 自定义指令 - GitHub Copilot, Continue
   └ 项目级指令文件，AI 会参考但无法主动调用

○ 基础支持 - Codex
   └ 仅支持全局提示词

? 选择要配置的 AI 工具（空格选择，回车确认）
❯ ◉ Claude Code ★ 完整 Skills
  ◯ Qoder CLI ★ 完整 Skills
  ◯ Cursor ◆ Rules 系统
  ...
```

**非交互式初始化**:

```bash
$ devbooks init --tools claude,cursor,github-copilot
ℹ 非交互式模式：claude, cursor, github-copilot
✓ 创建了 6 个模板文件
✓ 安装了 3 个工具的 Slash 命令
✓ 创建了 3 个指令文件

══════════════════════════════════════
✓ DevBooks 初始化完成！
══════════════════════════════════════
```

### B. 文件结构

初始化后的项目结构示例（选择 Claude + Cursor）:

```
project/
├── .devbooks/
│   └── config.yaml              # 配置文件（含 ai_tools 列表）
├── .claude/
│   └── commands/
│       └── devbooks/            # Claude Slash 命令
│           ├── proposal.md
│           ├── design.md
│           ├── apply.md
│           ├── archive.md
│           ├── quick.md
│           └── review.md
├── .cursor/
│   ├── commands/
│   │   └── devbooks/            # Cursor Slash 命令
│   │       └── ...
│   └── rules/
│       └── devbooks.md          # Cursor Rules 文件
├── dev-playbooks/
│   ├── constitution.md
│   ├── project.md
│   ├── specs/
│   └── changes/
└── CLAUDE.md                    # Claude 指令文件
```

---

**提案结束**

> **补写声明**: 本提案为已实现功能的事后补写，所有功能已完成开发并可正常使用。
