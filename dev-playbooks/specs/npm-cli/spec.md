# Spec: DevBooks npm CLI

---
owner: Spec Owner
last_verified: 2026-01-12
status: Active
freshness_check: 3 Months
source_change: complete-devbooks-independence
---

## 1. Requirements

### REQ-CLI-001: 一键初始化命令

系统 SHALL 提供 `npx create-devbooks` 命令，支持一键初始化 DevBooks 项目。

**命令格式**：
```bash
npx create-devbooks [project-name] [options]
```

**选项**：
- 无参数：在当前目录初始化
- `project-name`：创建新目录并初始化
- `--skills-only`：仅安装 Skills 到 `~/.claude/skills/`
- `--update-skills`：更新已安装的 Skills

**验收条件**：
- CLI 入口脚本存在（`bin/create-devbooks.js`）
- 命令可无错误执行

---

### REQ-CLI-002: 项目目录结构生成

初始化命令 SHALL 生成以下目录结构：

```
<project>/
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
├── .devbooks/
│   └── config.yaml
├── CLAUDE.md
└── AGENTS.md
```

**验收条件**：
- 目录结构符合定义
- 模板文件内容有效

---

### REQ-CLI-003: Skills 安装

初始化命令 SHALL 将 21 个 DevBooks Skills 安装到 `~/.claude/skills/` 目录。

**Skills 列表**：
1. devbooks-brownfield-bootstrap
2. devbooks-c4-map
3. devbooks-code-review
4. devbooks-coder
5. devbooks-delivery-workflow
6. devbooks-design-backport
7. devbooks-design-doc
8. devbooks-entropy-monitor
9. devbooks-federation
10. devbooks-impact-analysis
11. devbooks-implementation-plan
12. devbooks-index-bootstrap
13. devbooks-proposal-author
14. devbooks-proposal-challenger
15. devbooks-proposal-debate-workflow
16. devbooks-proposal-judge
17. devbooks-router
18. devbooks-spec-contract
19. devbooks-spec-gardener
20. devbooks-test-owner
21. devbooks-test-reviewer

**验收条件**：
- 21 个 Skills 目录存在于 `~/.claude/skills/`
- 每个 Skill 包含 SKILL.md

---

### REQ-CLI-004: 发布包纯净性

npm 发布包 SHALL NOT 包含以下内容：
- `dev-playbooks/changes/` 目录
- `.devbooks/backup/` 目录
- 项目特定的开发历史

**验收条件**：
- `npm pack --dry-run` 输出不含禁止路径
- `.npmignore` 配置正确

---

### REQ-CLI-005: Node.js 版本要求

CLI 工具 SHALL 要求 Node.js >= 18 LTS。

系统 SHOULD 在版本不满足时输出明确的错误提示。

**验收条件**：
- `package.json` 的 `engines.node` 设为 `>=18`
- 版本检查逻辑存在

---

## 2. Scenarios

### SC-CLI-001: 在空目录初始化项目

- **GIVEN** 用户在一个空目录中
- **WHEN** 用户执行 `npx create-devbooks`
- **THEN** 系统创建 `dev-playbooks/` 目录结构
- **AND** 系统创建 `.devbooks/config.yaml` 配置文件
- **AND** 系统安装 21 个 Skills 到 `~/.claude/skills/`

---

### SC-CLI-002: 在现有项目中初始化

- **GIVEN** 用户在一个已有代码的项目目录中
- **WHEN** 用户执行 `npx create-devbooks`
- **THEN** 系统检测到非空目录
- **AND** 系统提示确认是否继续
- **AND** 用户确认后创建 DevBooks 目录结构（不覆盖现有文件）

---

### SC-CLI-003: 仅更新 Skills

- **GIVEN** 用户已安装 DevBooks 但需要更新 Skills
- **WHEN** 用户执行 `npx create-devbooks --update-skills`
- **THEN** 系统仅更新 `~/.claude/skills/devbooks-*` 目录
- **AND** 不修改项目目录中的任何文件

---

### SC-CLI-004: npm pack 验证

- **GIVEN** 维护者准备发布 npm 包
- **WHEN** 执行 `npm pack`
- **THEN** 生成的 tarball 不包含 `changes/` 路径
- **AND** 生成的 tarball 不包含 `backup/` 路径

---

### SC-CLI-005: Node.js 版本不满足

- **GIVEN** 用户的 Node.js 版本 < 18
- **WHEN** 用户执行 `npx create-devbooks`
- **THEN** 系统输出错误信息
- **AND** 错误信息明确说明需要 Node.js >= 18

---

## 3. Contract Tests

| ID | 场景 | 断言 |
|----|------|------|
| CT-CLI-001 | CLI 入口存在 | `bin/create-devbooks.js` 可执行 |
| CT-CLI-002 | 目录结构生成 | 所有必需目录存在 |
| CT-CLI-003 | 配置文件生成 | `.devbooks/config.yaml` 有效 |
| CT-CLI-004 | Skills 安装 | 21 个 Skills 目录存在 |
| CT-CLI-005 | 纯净性 - changes | tarball 无 changes/ |
| CT-CLI-006 | 纯净性 - backup | tarball 无 backup/ |

---

## 4. 关联规格

- `specs/config-protocol/spec.md`：配置文件格式
- `specs/slash-commands/spec.md`：Slash 命令体系
