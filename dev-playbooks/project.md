# 项目上下文 (Project Context)

> 本文档描述项目的技术栈、约定和领域上下文。
> 宪法性规则请参阅 `constitution.md`。

---

## 目的

DevBooks 是一套开发作战手册（Development Playbooks），提供：
- 规范驱动的开发工作流
- AI 辅助的代码质量保障
- 可追溯的变更管理

## 技术栈

- **脚本语言**：Bash（无外部依赖，如 yq）
- **配置格式**：YAML（简单键值对）
- **文档格式**：Markdown
- **版本控制**：Git

## 项目约定

### 代码风格

- Shell 脚本遵循 [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- 使用 `shellcheck` 进行静态检查
- 函数命名：`snake_case`
- 变量命名：`UPPER_SNAKE_CASE`（全局）/ `lower_snake_case`（局部）

### 架构模式

- **配置发现**：所有 Skills 通过 `config-discovery.sh` 发现配置
- **宪法优先**：执行任何操作前加载 `constitution.md`
- **三层同步**：Draft → Staged → Truth

### 测试策略

- **单元测试**：BATS 框架
- **覆盖率目标**：80%
- **Red-Green 循环**：Test Owner 先产出 Red 基线，Coder 让其 Green

### Git 工作流

- **主分支**：`main` / `master`
- **变更分支**：`change/<change-id>`
- **提交格式**：`<type>: <subject>`
  - type: feat, fix, refactor, docs, test, chore

## 领域上下文

### 核心概念

| 术语 | 定义 |
|------|------|
| Truth Root | 真理源根目录，存放规格和设计的最终版本 |
| Change Root | 变更包根目录，存放每次变更的所有产物 |
| Spec Delta | 规格增量，描述变更对规格的修改 |
| AC-ID | 验收标准标识符，格式 `AC-XXX` |
| GIP | 全局不可违背原则（Global Inviolable Principle） |

### 角色定义

| 角色 | 职责 | 约束 |
|------|------|------|
| Design Owner | 产出 What/Constraints + AC-xxx | 禁止写实现步骤 |
| Spec Owner | 产出规格 delta | - |
| Planner | 从设计推导 tasks | 不得参考 tests/ |
| Test Owner | 从设计/规格推导测试 | 不得参考 tasks/ |
| Coder | 按 tasks 实现 | 禁止修改 tests/ |
| Reviewer | 代码审查 | 不改 tests，不改设计 |

## 重要约束

1. **角色隔离**：Test Owner 与 Coder 必须独立对话
2. **测试不可篡改**：Coder 禁止修改 tests/
3. **设计优先**：代码必须追溯到 AC-xxx
4. **真理源唯一**：specs/ 是唯一权威

## 外部依赖

- **CKB（Code Knowledge Base）**：代码智能分析（可选）
- **DevBooks CLI**：规格管理工具（可选）
- **BATS**：Bash 测试框架

---

## 目录根映射

| 路径 | 用途 |
|------|------|
| `dev-playbooks/` | DevBooks 管理目录（集中式） |
| `dev-playbooks/constitution.md` | 项目宪法 |
| `dev-playbooks/project.md` | 本文件 |
| `dev-playbooks/specs/` | 真理源 |
| `dev-playbooks/changes/` | 变更包 |
| `dev-playbooks/scripts/` | 项目级脚本（可选覆盖） |

---

**文档版本**：v1.0.0
**最后更新**：2026-01-11
