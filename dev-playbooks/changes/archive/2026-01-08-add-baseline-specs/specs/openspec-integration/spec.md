# openspec-integration

## 修改需求

### 需求：提供 OpenSpec 集成的安装提示与配置模板

系统必须提供 OpenSpec 集成的安装提示与配置模板，便于项目接入 DevBooks。

#### 场景：按安装提示完成接线
- **当** 按 `setup/openspec/安装提示词.md` 执行集成
- **那么** 项目会创建 `.devbooks/config.yaml` 并更新 `openspec/project.md`
- **证据**：`setup/openspec/安装提示词.md`，`setup/openspec/template.devbooks-config.yaml`

### 需求：提供可复制的 OpenSpec 集成模板

系统必须提供可复制模板，指导将规则内容追加到 `openspec/project.md` 与根 `AGENTS.md`。

#### 场景：需要手动附加规则内容
- **当** 参照模板补充 `openspec/project.md` 与根 `AGENTS.md`
- **那么** 规则内容放在 OpenSpec managed block 之外
- **证据**：`setup/openspec/OpenSpec集成模板（project.md 与 AGENTS附加块）.md`

### 需求：提供 OpenSpec 的 Codex 命令入口

系统必须提供 Codex 命令入口文档以支持 OpenSpec 的 proposal/apply/archive 流程。

#### 场景：安装 Codex prompts 后使用命令入口
- **当** 安装 `prompts/devbooks-openspec-*.md`
- **那么** 可以使用 `/devbooks-openspec-proposal`、`/devbooks-openspec-apply`、`/devbooks-openspec-archive`
- **证据**：`prompts/devbooks-openspec-proposal.md`，`prompts/devbooks-openspec-apply.md`，`prompts/devbooks-openspec-archive.md`
