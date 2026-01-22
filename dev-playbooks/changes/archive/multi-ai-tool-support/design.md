# Design: multi-ai-tool-support

> **状态**: Done（补写）
> **变更 ID**: multi-ai-tool-support
> **关联提案**: [proposal.md](./proposal.md)

---

## 1. What（系统行为）

### 1.1 CLI 行为

DevBooks CLI 提供两个核心命令：

| 命令 | 行为 |
|------|------|
| `devbooks init [path] [--tools <list>]` | 初始化项目，创建 DevBooks 结构并配置所选 AI 工具 |
| `devbooks update [path]` | 读取已配置的工具列表，更新 Slash 命令、Skills、Rules 和指令文件 |

**交互模式**：
- 默认启动交互式多选界面（checkbox）
- 使用 `--tools` 参数时进入非交互式模式
- `--tools` 接受值：`all`、`none`、或逗号分隔的工具 ID

### 1.2 AI 工具支持矩阵

系统维护一个 `AI_TOOLS` 数组，定义所有支持的 AI 工具：

```typescript
interface AITool {
  id: string;                    // 工具标识符（如 'claude', 'cursor'）
  name: string;                  // 显示名称
  description: string;           // 工具描述
  skillsSupport: SkillsSupport;  // 支持级别
  slashDir?: string;             // 项目内 Slash 命令目录（相对路径）
  globalSlashDir?: string;       // 全局 Slash 命令目录（绝对路径）
  skillsDir?: string;            // Skills 安装目录（仅 FULL 级别）
  agentsDir?: string;            // Agents 目录
  rulesDir?: string;             // Rules 目录（仅 RULES 级别）
  instructionsDir?: string;      // 指令目录（如 GitHub Copilot）
  instructionFile?: string;      // 指令文件名（如 'CLAUDE.md'）
  globalDir?: string;            // 全局配置目录
  available: boolean;            // 是否可用
}
```

### 1.3 支持级别分层

```typescript
enum SKILLS_SUPPORT {
  FULL = 'full',      // 完整 Skills（Claude Code, Qoder）
  RULES = 'rules',    // Rules 系统（Cursor, Windsurf, Gemini, Antigravity, OpenCode）
  AGENTS = 'agents',  // 自定义指令（GitHub Copilot, Continue）
  BASIC = 'basic'     // 基础支持（Codex）
}
```

**各级别行为**：

| 级别 | 安装 Slash 命令 | 安装 Skills | 创建 Rules 文件 | 创建指令文件 |
|------|-----------------|-------------|-----------------|--------------|
| FULL | Yes | Yes | No | Yes |
| RULES | Yes | No | Yes | Yes（部分） |
| AGENTS | 部分 | No | No | Yes |
| BASIC | 全局 | No | No | Yes |

### 1.4 配置文件格式

`.devbooks/config.yaml` 新增 `ai_tools` 字段：

```yaml
# 已配置的 AI 工具列表
ai_tools:
  - claude
  - cursor
  - github-copilot
```

### 1.5 目录结构生成

初始化后根据选择的工具生成以下结构：

```
project/
├── .devbooks/
│   └── config.yaml              # 包含 ai_tools 列表
├── dev-playbooks/
│   ├── constitution.md
│   ├── project.md
│   ├── specs/
│   │   ├── _meta/
│   │   │   ├── project-profile.md
│   │   │   ├── glossary.md
│   │   │   └── anti-patterns/
│   │   └── architecture/
│   │       └── fitness-rules.md
│   ├── changes/
│   └── scripts/
├── .<tool>/commands/devbooks/   # 各工具的 Slash 命令（按工具）
│   ├── proposal.md
│   ├── design.md
│   ├── apply.md
│   ├── archive.md
│   ├── quick.md
│   └── review.md
├── .<tool>/rules/               # Rules 文件（仅 RULES 级别工具）
│   └── devbooks.md
└── CLAUDE.md / AGENTS.md / GEMINI.md  # 指令文件（按工具）
```

### 1.6 文件内容标记

所有生成的指令文件和 Rules 文件使用 DevBooks 标记包裹可更新内容：

```markdown
<!-- DEVBOOKS:START -->
... 可更新内容 ...
<!-- DEVBOOKS:END -->
```

---

## 2. Constraints（约束条件）

### 2.1 运行时约束

| 约束 ID | 描述 |
|---------|------|
| C-001 | Node.js 最低版本 18+（ESM + 依赖要求） |
| C-002 | 使用 ESM 模块格式（`"type": "module"`） |
| C-003 | 路径处理使用 `path` 模块，确保跨平台兼容 |

### 2.2 配置约束

| 约束 ID | 描述 |
|---------|------|
| C-010 | `ai_tools` 字段为字符串数组，每个元素对应 `AI_TOOLS` 中的 `id` |
| C-011 | 配置文件不存在时，`loadConfig()` 返回空的 `aiTools` 数组 |
| C-012 | 配置更新时保留文件其他内容，仅替换 `ai_tools` 部分 |

### 2.3 安装约束

| 约束 ID | 描述 |
|---------|------|
| C-020 | Slash 命令从 `slash-commands/devbooks/` 复制到各工具目录 |
| C-021 | Skills 仅为 `FULL` 级别工具安装（目前仅 Claude Code） |
| C-022 | Skills 安装到用户主目录下的工具配置目录（如 `~/.claude/skills/`） |
| C-023 | 符号链接在复制时跳过，避免跨平台兼容问题 |
| C-024 | 已存在的文件默认不覆盖（`update` 命令除外） |

### 2.4 指令文件命名约束

| 工具 | 指令文件 |
|------|----------|
| Claude Code | `CLAUDE.md` |
| Gemini CLI / Antigravity | `GEMINI.md` |
| Qoder / OpenCode / Codex | `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/devbooks.md` |
| Windsurf | `.windsurf/rules/devbooks.md` |

### 2.5 交互约束

| 约束 ID | 描述 |
|---------|------|
| C-030 | 交互式模式默认选中 `claude` |
| C-031 | 未选择任何工具时提示确认，用户可选择仅创建项目结构 |
| C-032 | `--tools` 参数跳过交互式界面 |

---

## 3. AC（验收标准）

### 3.1 Init 命令验收

| AC ID | 验收条件 | 验证方法 |
|-------|----------|----------|
| AC-001 | `devbooks init` 在无 `--tools` 参数时显示交互式工具选择界面 | 执行命令，观察输出 |
| AC-002 | 交互式界面显示所有 10 个 AI 工具及其支持级别 | 执行命令，核对列表 |
| AC-003 | 选择工具后，对应的 Slash 命令目录被创建 | `ls .<tool>/commands/devbooks/` |
| AC-004 | 选择 Claude Code 后，`CLAUDE.md` 被创建 | `test -f CLAUDE.md` |
| AC-005 | 选择 Cursor 后，`.cursor/rules/devbooks.md` 被创建 | `test -f .cursor/rules/devbooks.md` |
| AC-006 | 选择 GitHub Copilot 后，`.github/copilot-instructions.md` 被创建 | `test -f .github/copilot-instructions.md` |
| AC-007 | `.devbooks/config.yaml` 包含 `ai_tools` 字段，列出所选工具 | `grep ai_tools .devbooks/config.yaml` |

### 3.2 非交互式模式验收

| AC ID | 验收条件 | 验证方法 |
|-------|----------|----------|
| AC-010 | `devbooks init --tools claude` 跳过交互界面，仅配置 Claude Code | 执行命令，检查无交互提示 |
| AC-011 | `devbooks init --tools all` 配置所有可用工具 | 检查 config.yaml 包含所有工具 ID |
| AC-012 | `devbooks init --tools none` 仅创建项目结构，不配置任何工具 | 检查 config.yaml 中 `ai_tools` 为空 |
| AC-013 | `devbooks init --tools claude,cursor,github-copilot` 正确解析逗号分隔的工具列表 | 检查配置和生成的文件 |

### 3.3 Update 命令验收

| AC ID | 验收条件 | 验证方法 |
|-------|----------|----------|
| AC-020 | `devbooks update` 读取 `.devbooks/config.yaml` 中的 `ai_tools` | 执行命令，观察输出列出已配置工具 |
| AC-021 | `devbooks update` 更新已配置工具的 Slash 命令 | 修改源文件后执行，检查目标文件更新 |
| AC-022 | `devbooks update` 在未初始化的目录报错并提示运行 `init` | 在空目录执行，检查错误信息 |

### 3.4 Skills 安装验收

| AC ID | 验收条件 | 验证方法 |
|-------|----------|----------|
| AC-030 | 选择 Claude Code 后，Skills 安装到 `~/.claude/skills/devbooks-*` | `ls ~/.claude/skills/devbooks-*` |
| AC-031 | Skills 目录包含 `SKILL.md` 和必要文件 | 检查目录结构 |
| AC-032 | 选择非 FULL 级别工具时，不安装 Skills | 选择 Cursor，检查无 Skills 安装日志 |

### 3.5 Rules 文件验收

| AC ID | 验收条件 | 验证方法 |
|-------|----------|----------|
| AC-040 | Cursor 的 Rules 文件包含正确的 frontmatter（`globs`） | 检查文件内容 |
| AC-041 | Windsurf 的 Rules 文件包含正确的 frontmatter（`trigger`） | 检查文件内容 |
| AC-042 | Rules 文件内容在 DEVBOOKS 标记内 | `grep DEVBOOKS:START .cursor/rules/devbooks.md` |

### 3.6 Help 输出验收

| AC ID | 验收条件 | 验证方法 |
|-------|----------|----------|
| AC-050 | `devbooks --help` 显示支持的工具列表，按支持级别分组 | 执行命令，检查输出 |
| AC-051 | Help 输出包含工具 ID 和显示名称 | 检查输出格式 |

---

## 4. Contract（对外接口）

### 4.1 CLI 接口

```
devbooks init [path] [--tools <tools>]
devbooks update [path]
devbooks --help | -h
```

**参数**：
- `path`：可选，项目目录路径（默认当前目录）
- `--tools`：可选，非交互式指定工具（`all` | `none` | 逗号分隔的工具 ID）

**退出码**：
- `0`：成功
- `1`：错误（未初始化、未知命令等）

### 4.2 配置接口

`.devbooks/config.yaml` 新增字段：

```yaml
ai_tools:
  - <tool-id>  # 字符串数组，每项为 AI_TOOLS 中定义的 id
```

**有效 tool-id 值**：
- `claude`
- `qoder`
- `cursor`
- `windsurf`
- `gemini`
- `antigravity`
- `opencode`
- `github-copilot`
- `continue`
- `codex`

### 4.3 生成文件接口

| 工具类型 | 生成文件 | 位置 |
|----------|----------|------|
| 所有工具 | Slash 命令 | `.<tool>/commands/devbooks/*.md` 或全局 |
| FULL 级别 | Skills | `~/.claude/skills/devbooks-*` |
| RULES 级别 | Rules 文件 | `.<tool>/rules/devbooks.md` |
| 各工具 | 指令文件 | `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` 等 |

---

## 附录：工具配置详情

| ID | 名称 | 级别 | Slash 目录 | 指令文件 |
|----|------|------|-----------|----------|
| claude | Claude Code | FULL | `.claude/commands/devbooks` | `CLAUDE.md` |
| qoder | Qoder CLI | FULL | `.qoder/commands/devbooks` | `AGENTS.md` |
| cursor | Cursor | RULES | `.cursor/commands/devbooks` | `.cursor/rules/devbooks.md` |
| windsurf | Windsurf | RULES | `.windsurf/commands/devbooks` | `.windsurf/rules/devbooks.md` |
| gemini | Gemini CLI | RULES | `.gemini/commands/devbooks` | `GEMINI.md` |
| antigravity | Antigravity | RULES | `.agent/workflows/devbooks` | `GEMINI.md` |
| opencode | OpenCode | RULES | `.opencode/commands/devbooks` | `AGENTS.md` |
| github-copilot | GitHub Copilot | AGENTS | - | `.github/copilot-instructions.md` |
| continue | Continue | AGENTS | `.continue/prompts/devbooks` | - |
| codex | Codex CLI | BASIC | `~/.codex/prompts/devbooks`（全局） | `AGENTS.md` |

---

**文档结束**

> **补写声明**: 本设计文档为已实现功能的事后补写，基于 `bin/devbooks.js` 源代码提取。
