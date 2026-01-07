# DevBooks 自动化配置指南

> 本目录包含让 DevBooks 实现"无感集成"的配置脚本和模板。

---

## 快速开始

### 1. 安装 Git Hooks（自动索引）

在你的项目根目录运行：

```bash
# 使用 DevBooks 安装脚本
bash ~/.claude/skills/devbooks-delivery-workflow/../../../setup/hooks/install-git-hooks.sh .

# 或直接从本仓库运行
bash /path/to/dev-playbooks/setup/hooks/install-git-hooks.sh /path/to/your/project
```

**效果**：每次 `git commit`、`git pull`、`git checkout` 后自动更新 SCIP 索引。

### 2. 配置 Claude Code Hooks（自动上下文）

将 `claude-hooks-template.yaml` 中的配置添加到你的 Claude Code 设置：

**方式一：全局配置**
```bash
# 编辑 ~/.claude/settings.yaml
# 将 claude-hooks-template.yaml 中的 hooks 部分复制进去
```

**方式二：项目配置**
```bash
# 在项目根目录创建 .claude/settings.yaml
mkdir -p .claude
cp /path/to/dev-playbooks/setup/hooks/claude-hooks-template.yaml .claude/settings.yaml
```

**效果**：每次对话开始时自动检测项目状态、变更包进度、索引健康。

### 3. 配置 AGENTS.md 自动路由

将集成模板中的"自动 Skill 路由规则"部分添加到你的项目：

- OpenSpec 项目：参考 `setup/openspec/OpenSpec集成模板（project.md 与 AGENTS附加块）.md`
- 其他项目：参考 `setup/template/DevBooks集成模板（协议无关）.md`

**效果**：AI 根据用户意图自动选择 Skill，无需显式点名。

---

## 文件说明

| 文件 | 用途 |
|-----|------|
| `install-git-hooks.sh` | 安装自动索引 Git Hooks |
| `claude-hooks-template.yaml` | Claude Code Hooks 配置模板 |

---

## Git Hooks 详解

### 安装的 Hooks

| Hook | 触发时机 | 行为 |
|------|---------|------|
| `post-commit` | 每次提交后 | 后台异步更新 SCIP 索引 |
| `post-merge` | 每次 pull 后 | 同上 |
| `post-checkout` | 切换分支后 | 同上 |

### 前提条件

根据项目语言安装对应的 SCIP 索引器：

```bash
# TypeScript/JavaScript
npm install -g @anthropic-ai/scip-typescript

# Python
pip install scip-python

# Go
go install github.com/sourcegraph/scip-go@latest

# Rust
cargo install scip-rust

# Java
# 需要 Gradle/Maven 插件，参见 https://sourcegraph.github.io/scip-java/
```

### 手动首次索引

Git Hooks 只在增量场景生效，首次需要手动运行：

```bash
# TypeScript/JavaScript
scip-typescript index --output index.scip

# Python
scip-python index . --output index.scip

# Go
scip-go --output index.scip
```

---

## Claude Code Hooks 详解

### 自动注入的上下文

当你在 DevBooks 管理的项目中开始对话时，会自动注入：

1. **项目类型检测**：OpenSpec / template / 其他
2. **当前变更包**：最近活动的 change-id
3. **任务进度**：tasks.md 中的完成情况（如 "6/10 完成"）
4. **索引状态**：SCIP 索引是否存在及是否过期
5. **下一步建议**：根据变更包状态推荐 Skill

### 配置示例

```yaml
# ~/.claude/settings.yaml
hooks:
  PreToolUse:
    - matcher: ".*"
      hooks:
        - type: command
          command: |
            # 检查 DevBooks 项目
            if [ -f "openspec/project.md" ]; then
              echo "[DevBooks] OpenSpec 项目"
              # ... 更多检测逻辑
            fi
```

---

## 自动路由规则

将以下规则添加到项目的 `AGENTS.md` 或 `project.md`，让 AI 自动选择 Skill：

```markdown
### 意图识别与自动路由

| 用户意图 | 自动使用 |
|---------|---------|
| "修复 Bug" | devbooks-impact-analysis → devbooks-coder |
| "重构代码" | devbooks-code-review → devbooks-coder |
| "新功能" | devbooks-router → 完整闭环 |
| "继续" | 检查 tasks.md → devbooks-coder |
```

---

## 验证配置

### 检查 Git Hooks

```bash
ls -la .git/hooks/post-commit
# 应该显示可执行文件

git commit --allow-empty -m "test hook"
# 应该看到 "[DevBooks] 更新 ... 索引..."
```

### 检查 SCIP 索引

```bash
ls -la index.scip
# 应该存在且非空

# 在 Claude Code 中测试
# 问 "检查索引状态" 或调用 mcp__ckb__getStatus
```

### 检查自动路由

在 Claude Code 中测试：
```
用户：修复这个 Bug
AI：（应该自动使用 devbooks-impact-analysis）
```

---

## 故障排除

### 索引未生成

1. 检查 SCIP 索引器是否安装：`which scip-typescript`
2. 检查 Hook 是否可执行：`ls -la .git/hooks/post-commit`
3. 手动运行 Hook 脚本查看错误：`.git/hooks/post-commit`

### Hooks 不生效

1. 确认 `~/.claude/settings.yaml` 语法正确
2. 重启 Claude Code
3. 检查 hooks 脚本权限

### 自动路由不工作

1. 确认 `AGENTS.md` 或 `project.md` 包含路由规则
2. 确认 AI 能读取到该文件（检查路径）
3. 尝试显式点名 Skill 测试是否正常工作

---

## 与 Augment Code 的对比

| 能力 | Augment | DevBooks + 本配置 |
|-----|---------|------------------|
| 持久化索引 | 自有后台服务 | Git Hooks 自动触发 |
| 增量更新 | 实时 | 每次 commit/pull/checkout |
| 无感集成 | 完全自动 | Hooks + AGENTS 规则 |
| 自动化程度 | 95% | 85% |

**差距**：
- Augment 有持续运行的后台服务，DevBooks 依赖 Git 事件触发
- Augment 的索引器支持真正的增量更新，SCIP 是全量重建

**优势**：
- DevBooks 配置透明可控，用户可以自定义
- 不依赖闭源服务，可离线使用
