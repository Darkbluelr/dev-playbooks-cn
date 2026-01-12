# setup/（DevBooks 安装）

## DevBooks 是什么

DevBooks 是一套**变更管理工作流**，提供：

- **DevBooks 协议**：proposal → apply → archive 三阶段变更管理
- **角色隔离**：Test Owner / Coder / Reviewer 独立执行
- **Skills 集合**：devbooks-coder、devbooks-test-owner、devbooks-router 等
- **Prompts 命令**：Codex CLI 的 DevBooks 命令入口

## 安装

### 方式 1：DevBooks 项目集成

告诉 AI：
```
请按照 setup/dev-playbooks/安装提示词.md 完成 DevBooks 安装
```

### 方式 2：安装 Skills + Prompts

```bash
./scripts/install-skills.sh --with-codex-prompts
```

这会安装：
- DevBooks Skills（到 `~/.claude/skills/` 和 `~/.codex/skills/`）
- Codex Prompts（到 `~/.codex/prompts/`，需要 `--with-codex-prompts`）

### 方式 3：安装系统依赖

```bash
./scripts/install-dependencies.sh
```

## 目录结构

```
setup/
├── dev-playbooks/                         # DevBooks 协议集成
│   ├── 安装提示词.md                  # 👈 唯一安装入口（AI 执行）
│   ├── DevBooks集成模板...md          # 被安装提示词引用的模板
│   ├── template.devbooks-config.yaml  # 配置模板
│   └── prompts/                       # Codex CLI 命令入口（DevBooks 专用）
│       ├── devbooks-proposal.md
│       ├── devbooks-apply.md
│       └── devbooks-archive.md
└── generic/                           # 协议无关模板（非 DevBooks 项目用）
    ├── DevBooks集成模板...md
    └── 安装提示词.md
```

## 安装后效果

- ✅ DevBooks 工作流可用（/devbooks:proposal、/devbooks:apply、/devbooks:archive）
- ✅ DevBooks Skills 可用（devbooks-coder、devbooks-test-owner 等）
- ✅ Codex CLI Prompts 可用（devbooks-proposal 等）
- ✅ 角色隔离执行
- ✅ 变更追踪与归档
