# install-skills

## 修改需求

### 需求：提供安装脚本将 devbooks-* Skills 安装到 Claude Code 与 Codex CLI

系统必须提供安装脚本，将 `skills/devbooks-*` 安装到 Claude Code 与 Codex CLI 的本地目录。

#### 场景：默认安装到两个目标
- **当** 在仓库根目录执行 `./scripts/install-skills.sh`
- **那么** `skills/devbooks-*` 会被安装到 `~/.claude/skills/` 与 `$CODEX_HOME/skills/`
- **证据**：`scripts/install-skills.sh`

### 需求：安装脚本支持仅安装 Claude 或仅安装 Codex

系统必须支持通过参数控制仅安装 Claude Code 或仅安装 Codex CLI 的 Skills。

#### 场景：仅安装 Claude
- **当** 执行 `./scripts/install-skills.sh --claude-only`
- **那么** 只更新 `~/.claude/skills/` 目录
- **证据**：`scripts/install-skills.sh`

### 需求：安装脚本支持可选安装 Codex Prompts

系统必须支持可选安装 Codex Prompts 到本地 prompts 目录。

#### 场景：同时安装 prompts
- **当** 执行 `./scripts/install-skills.sh --with-codex-prompts`
- **那么** `prompts/devbooks-*.md` 被复制到 `$CODEX_HOME/prompts/`
- **证据**：`scripts/install-skills.sh`，`prompts/`

### 需求：安装脚本支持 dry-run 预览

系统必须支持 dry-run 模式以预览安装操作而不执行写入。

#### 场景：dry-run 模式
- **当** 执行 `./scripts/install-skills.sh --dry-run`
- **那么** 仅输出计划操作，不实际写入目标目录
- **证据**：`scripts/install-skills.sh`
