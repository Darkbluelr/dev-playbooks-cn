# automation-guardrails

## 修改需求

### 需求：提供 Git Hooks 安装脚本用于自动索引

系统必须提供 Git Hooks 安装脚本，用于在仓库中自动更新索引。

#### 场景：安装 Git Hooks
- **当** 运行 `bash setup/hooks/install-git-hooks.sh <project-root>`
- **那么** 安装 `post-commit`、`post-merge`、`post-checkout` hooks
- **证据**：`setup/hooks/install-git-hooks.sh`，`setup/hooks/README.md`

### 需求：提供 Claude Code Hooks 配置模板

系统必须提供 Claude Code Hooks 配置模板以实现对话前上下文注入。

#### 场景：配置 Claude Hooks
- **当** 将 `setup/hooks/claude-hooks-template.yaml` 的内容写入 `~/.claude/settings.yaml`
- **那么** Claude Code 可在对话前注入 DevBooks 上下文
- **证据**：`setup/hooks/claude-hooks-template.yaml`

### 需求：提供 CI 模板用于守门与 COD 更新

系统必须提供 CI 模板以支持架构守门与 COD 模型更新。

#### 场景：复制 CI 模板到项目
- **当** 将 `templates/ci/devbooks-guardrail.yml` 与 `templates/ci/devbooks-cod-update.yml` 复制到 `.github/workflows/`
- **那么** CI 可执行架构合规检查与 COD 模型更新
- **证据**：`templates/ci/README.md`，`templates/ci/devbooks-guardrail.yml`，`templates/ci/devbooks-cod-update.yml`
