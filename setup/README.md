# setup/（DevBooks 安装）

## DevBooks 是什么

DevBooks 是一套**变更管理工作流**，提供：

- **OpenSpec 协议**：proposal → apply → archive 三阶段变更管理
- **角色隔离**：Test Owner / Coder / Reviewer 独立执行
- **Skills 集合**：devbooks-coder、devbooks-test-owner、devbooks-router 等
- **Prompts 命令**：Codex CLI 的 OpenSpec 命令入口

## 安装

### 方式 1：OpenSpec 项目集成

告诉 AI：
```
请按照 setup/openspec/安装提示词.md 完成 DevBooks 安装
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
├── openspec/                         # OpenSpec 协议集成
│   ├── 安装提示词.md                  # 👈 唯一安装入口（AI 执行）
│   ├── OpenSpec集成模板...md          # 被安装提示词引用的模板
│   ├── template.devbooks-config.yaml  # 配置模板
│   └── prompts/                       # Codex CLI 命令入口（OpenSpec 专用）
│       ├── devbooks-openspec-proposal.md
│       ├── devbooks-openspec-apply.md
│       └── devbooks-openspec-archive.md
└── generic/                           # 协议无关模板（非 OpenSpec 项目用）
    ├── DevBooks集成模板...md
    └── 安装提示词.md
```

## 安装后效果

- ✅ OpenSpec 工作流可用（/openspec:proposal、/openspec:apply、/openspec:archive）
- ✅ DevBooks Skills 可用（devbooks-coder、devbooks-test-owner 等）
- ✅ Codex CLI Prompts 可用（devbooks-openspec-proposal 等）
- ✅ 角色隔离执行
- ✅ 变更追踪与归档
