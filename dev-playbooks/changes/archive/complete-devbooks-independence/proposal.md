# Proposal: complete-devbooks-independence

> 产物落点：`dev-playbooks/changes/complete-devbooks-independence/proposal.md`
>
> 状态：**Archived**（已归档 2026-01-12）
> 日期：2026-01-11
> archived_by：Spec Gardener

---

## 人类要求（Human Requirements）

**以下由人类明确要求，必须在本提案及后续所有阶段严格遵守：**

1. **完全解耦原则**：DevBooks 必须成为完全独立的上下文协议，与 OpenSpec 完全解耦。所有文档和 Skills 中不得提及 OpenSpec。
2. **纯净发布原则**：GitHub 上传的版本必须是纯净的工具库，不包含开发历史。用户下载/安装后应获得干净的模板，而非项目特定内容。
3. **一键安装原则**：用户应能通过 `npx create-devbooks` 完成安装，自动配置 slash 命令、提示词等。

---

## 1. Why（问题与目标）

### 1.1 当前痛点

| 问题 | 症状 | 根因 |
|------|------|------|
| **OpenSpec 残留未清理** | 160+ 文件包含 OpenSpec 引用；`setup/openspec/` 目录仍存在；配置中 `protocol: openspec` | 上次变更（evolve-devbooks-architecture）未完成清理 |
| **Slash 命令未独立** | 仍使用 `openspec:proposal/apply/archive`；DevBooks 无自己的阶段命令 | 历史依赖 OpenSpec CLI 设计 |
| **发布目录污染** | `dev-playbooks/changes/` 和 `dev-playbooks/specs/` 包含项目特定内容 | 用 DevBooks 开发 DevBooks，但未区分发布产物 |
| **安装流程复杂** | 需要克隆仓库、运行脚本、手动配置 | 缺少 npm 发布和 CLI 安装器 |
| **文档描述过时** | 部分文档仍称 DevBooks 为"协议无关"的工具 | 架构演进后文档未同步更新 |

### 1.2 目标定义

1. **完全独立**：移除所有 OpenSpec 引用，DevBooks 成为独立的变更管理上下文协议
2. **原生命令**：定义 DevBooks 原生的 slash 命令体系（`/devbooks:*`）
3. **npm 发布**：创建 `create-devbooks` npm 包，支持一键初始化
4. **纯净分发**：设计清晰的发布目录结构，区分工具库与项目实例
5. **MCP 可选**：slash 命令描述应支持无 MCP 时的降级体验

---

## 2. What Changes（范围）

### 2.1 变更范围

#### 2.1.1 目录结构重新设计

**发布目录结构**（GitHub/npm 上的内容）：

```
devbooks/                              # npm 包根目录
├── package.json                       # npm 包定义
├── bin/
│   └── create-devbooks.js             # CLI 入口
├── templates/
│   ├── dev-playbooks/                 # 用户项目模板（干净）
│   │   ├── constitution.md            # 宪法模板
│   │   ├── project.md                 # 项目上下文模板
│   │   ├── specs/                     # 空目录（用户填充）
│   │   │   ├── _meta/
│   │   │   │   ├── project-profile.md # 画像模板
│   │   │   │   ├── glossary.md        # 术语表模板
│   │   │   │   └── anti-patterns/     # 反模式库模板
│   │   │   └── architecture/
│   │   │       └── fitness-rules.md   # 适应度规则模板
│   │   ├── changes/                   # 空目录（变更包落点）
│   │   └── scripts/                   # 空目录（项目脚本覆盖）
│   ├── .devbooks/
│   │   └── config.yaml                # 配置模板
│   ├── CLAUDE.md                      # Claude Code 集成模板
│   └── AGENTS.md                      # 规则文档模板
├── skills/                            # Skills 定义（核心）
│   ├── devbooks-coder/
│   ├── devbooks-test-owner/
│   ├── devbooks-router/
│   └── ...
├── scripts/                           # 公共脚本
│   ├── install-skills.sh
│   ├── config-discovery.sh
│   └── ...
└── docs/                              # 文档
    ├── 完全体提示词.md
    ├── 基础提示词.md
    └── ...
```

**用户安装后的项目结构**：

```
my-project/
├── dev-playbooks/                     # DevBooks 管理目录
│   ├── constitution.md                # 项目宪法
│   ├── project.md                     # 项目上下文
│   ├── specs/                         # 真理源（用户逐步填充）
│   │   ├── _meta/
│   │   │   ├── project-profile.md
│   │   │   ├── glossary.md
│   │   │   └── anti-patterns/
│   │   └── architecture/
│   │       └── fitness-rules.md
│   ├── changes/                       # 变更包（用户工作目录）
│   └── scripts/                       # 项目级脚本覆盖
├── .devbooks/
│   └── config.yaml                    # DevBooks 配置
├── CLAUDE.md                          # Claude Code 集成
├── AGENTS.md                          # 规则文档
└── src/, tests/, ...                  # 用户项目代码
```

#### 2.1.2 Slash 命令体系设计

**DevBooks 原生阶段命令**：

| 命令 | 用途 | 触发的 Skills |
|------|------|---------------|
| `/devbooks:proposal` | 启动提案阶段 | devbooks-proposal-author → devbooks-impact-analysis → devbooks-proposal-challenger → devbooks-proposal-judge |
| `/devbooks:design` | 设计阶段 | devbooks-design-doc → devbooks-spec-contract → devbooks-c4-map → devbooks-implementation-plan |
| `/devbooks:apply` | 实现阶段 | devbooks-test-owner → devbooks-coder |
| `/devbooks:review` | 评审阶段 | devbooks-code-review → devbooks-test-reviewer |
| `/devbooks:archive` | 归档阶段 | devbooks-spec-gardener |
| `/devbooks:router` | 智能路由 | devbooks-router |

**快捷命令**（可选）：

| 命令 | 等价于 |
|------|--------|
| `/db:p` | `/devbooks:proposal` |
| `/db:d` | `/devbooks:design` |
| `/db:a` | `/devbooks:apply` |
| `/db:r` | `/devbooks:review` |
| `/db:x` | `/devbooks:archive` |

**角色子命令**（Apply 阶段）：

| 命令 | 用途 |
|------|------|
| `/devbooks:apply --role test-owner` | 仅执行 Test Owner |
| `/devbooks:apply --role coder` | 仅执行 Coder |
| `/devbooks:apply --role reviewer` | 仅执行 Reviewer |

**快速模式**（小变更可跳过 design 和 review）：

| 命令 | 用途 | 适用场景 |
|------|------|----------|
| `/devbooks:quick` | 快速变更流程 | bug fix、文档修正、小型重构 |

快速模式等价于：`proposal → apply → archive`，跳过 design 和 review 阶段。

**使用指引**：
- **完整流程**（5 阶段）：新功能、架构变更、跨模块修改
- **快速模式**（3 阶段）：bug fix、文档更新、小型代码改进
- 路由器（`/devbooks:router`）会根据变更规模自动建议使用哪种模式

#### 2.1.3 npm 包设计

**包名策略**：
- **首选**：`create-devbooks`（已验证可用，遵循 create-* 惯例）
- **备选**：`@devbooks/create`（若首选不可用时采用 scoped package）

**包名可用性验证**：2026-01-11 已确认 `create-devbooks` 在 npm 注册表中未被占用。

**安装命令**：
```bash
npx create-devbooks [project-name] [options]

# 示例
npx create-devbooks                    # 在当前目录初始化
npx create-devbooks my-app             # 创建新目录并初始化
npx create-devbooks --skills-only      # 仅安装 Skills
```

**CLI 功能**：

1. **初始化项目**：
   - 创建 `dev-playbooks/` 目录结构
   - 生成配置文件
   - 安装 Skills 到 `~/.claude/skills/`

2. **配置 slash 命令**：
   - 生成 Claude Code 的 slash 命令定义
   - 支持 MCP 检测和降级

3. **交互式配置**：
   - 询问项目类型（新项目/存量项目）
   - 询问技术栈（自动配置适应度规则）
   - 询问 MCP 安装情况（调整提示词）

#### 2.1.4 OpenSpec 清理清单

> **注意**：完整的文件清单需在 Design 阶段前生成，作为工作量评估和验收的基础。

**需要删除的目录**：
- `setup/openspec/`（整个目录）

**需要重命名/重写的文件**：
- `dev-playbooks/specs/openspec-integration/spec.md` → 删除或重写
- 包含 "openspec" 引用的文件（具体数量和清单在 Design 阶段确定）

**前置任务**（Design 阶段前必须完成）：
- P0.1：运行 `grep -r "openspec\|OpenSpec" --include="*.md" --include="*.sh" --include="*.yaml" .` 生成完整文件清单
- P0.2：将清单分类（需删除 / 需重写 / 需部分修改）
- P0.3：评估每类文件的工作量

**需要更新的配置**：
- `.devbooks/config.yaml`：移除 `protocol: openspec`
- 所有 Skills 的配置发现逻辑：移除 OpenSpec 特殊处理

**需要更新的文档**：
- `docs/完全体提示词.md`：移除 OpenSpec 引用，更新为 DevBooks 原生命令
- `docs/基础提示词.md`：同上
- `skills/Skills使用说明.md`：同上
- `README.md`：移除 OpenSpec 相关描述
- 所有 Skills 的 SKILL.md：移除 OpenSpec 引用

#### 2.1.5 MCP 可选性设计

**问题**：`完全体提示词.md` 包含 MCP 特定指令，但用户可能未安装所有 MCP。

**解决方案**：

1. **分层提示词**：
   - `基础提示词.md`：无任何 MCP 依赖
   - `完全体提示词.md`：包含所有 MCP 增强

2. **动态检测**：
   - CLI 安装时检测已安装的 MCP
   - 生成定制化的提示词文件

3. **Slash 命令描述**：
   - 每个 slash 命令包含 MCP 可用时的增强说明
   - 不可用时自动降级到基础功能

### 2.2 非目标（明确排除）

| 排除项 | 排除原因 |
|--------|----------|
| 保留 OpenSpec 兼容模式 | 目标是完全解耦，不保留兼容 |
| 多协议支持 | DevBooks 自身就是协议，不需要支持其他协议 |
| Codex CLI 支持 | 专注 Claude Code，后续可扩展 |
| 图形界面 | CLI 优先，GUI 后续迭代 |

### 2.3 新旧对比

| 维度 | 当前（OpenSpec 依赖） | 变更后（独立 DevBooks） |
|------|----------------------|------------------------|
| 阶段命令 | `/openspec:proposal/apply/archive` | `/devbooks:proposal/design/apply/review/archive` |
| 配置发现 | 先找 `openspec/project.md` | 直接找 `.devbooks/config.yaml` |
| 安装方式 | 克隆仓库 + 运行脚本 | `npx create-devbooks` |
| 发布内容 | 包含开发历史 | 纯净模板 |
| 协议定位 | "协议无关"工具 | 独立的变更管理协议 |

---

## 3. Impact（影响范围）

### 3.1 Scope（变更边界）

**In（纳入范围）**：
- 目录结构重组：创建发布目录、清理开发历史
- Slash 命令定义：新增 `/devbooks:*` 系列命令
- npm 包创建：`create-devbooks` CLI
- 文档更新：160+ 文件清理 OpenSpec 引用
- 配置更新：移除 OpenSpec 协议特殊处理
- Skills 更新：21 个 Skills 的配置发现逻辑

**Out（明确排除）**：
- OpenSpec 兼容模式
- Codex CLI 支持
- 多语言 CLI（仅 Node.js）

### 3.2 Change Type Classification

- [x] **功能扩展**：npm CLI、slash 命令体系
- [x] **子系统/模块替换**：移除 OpenSpec 依赖
- [x] **接口契约变更**：slash 命令名称变更
- [ ] 创建特定类
- [ ] 算法依赖
- [ ] 平台依赖
- [ ] 对象表示/实现依赖
- [ ] 对象职责变更

### 3.3 Impacts（受影响对象清单）

#### A. 对外契约（API/事件/Schema）

| 契约类型 | 影响程度 | 说明 |
|----------|----------|------|
| Slash 命令 | **Breaking** | `/openspec:*` → `/devbooks:*` |
| 配置格式 | Minor | 移除 `protocol` 字段，简化配置 |
| 目录结构 | Compatible | 保持 `dev-playbooks/` 不变 |

#### B. 数据与迁移

| 迁移项 | 数量 | 处置 |
|--------|------|------|
| OpenSpec 引用文件 | 160 个 | 批量替换/删除 |
| `setup/openspec/` | 1 个目录 | 删除 |
| Skills 配置发现 | 21 个 | 更新逻辑 |
| 发布目录 | 新建 | 创建 `templates/` 结构 |

#### C. 模块与依赖

**新增依赖**：
- Node.js（npm 包发布）
- 无外部运行时依赖（安装后纯 Bash + Markdown）

**移除依赖**：
- OpenSpec CLI
- OpenSpec 协议规范

#### D. 测试与验证

| 测试类型 | 需新增/更新 |
|----------|------------|
| CLI 安装测试 | 新增 `create-devbooks` 测试 |
| Slash 命令测试 | 更新命令名称 |
| Skills 集成测试 | 更新配置发现测试 |
| 文档链接验证 | 检查所有引用有效性 |

### 3.4 Transaction Scope

**`None`**

本变更为工具链/文档变更，不涉及数据库事务或跨服务调用。

### 3.5 Compatibility & Risks（兼容性与风险）

**Breaking 变化**：
1. Slash 命令名称变更：`/openspec:*` → `/devbooks:*`
2. 配置发现逻辑变更：不再特殊处理 `openspec/` 目录

**迁移路径**：
1. 现有用户：运行迁移脚本 `migrate-from-openspec.sh`
2. 新用户：直接使用 `npx create-devbooks`

**回滚路径**：
1. 恢复 `setup/openspec/` 目录
2. 回滚配置发现脚本
3. 恢复 slash 命令别名

---

## 4. Risks & Rollback（风险与回滚）

### 4.1 高风险

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| 现有用户迁移成本 | 需要更新所有 slash 命令 | 高 | 提供迁移指南和自动化脚本 |
| 文档遗漏清理 | 部分 OpenSpec 引用残留 | 中 | 自动化扫描 + 人工审查 |

### 4.2 中风险

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| npm 包命名冲突 | 包名已被占用 | 低 | 预先检查 npm 注册表 |
| MCP 检测不准 | 生成错误的提示词 | 中 | 支持手动配置覆盖 |

### 4.3 低风险

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|----------|
| CLI 兼容性 | 部分系统无 Node.js | 低 | 提供手动安装方式 |

### 4.4 回滚策略

1. **代码回滚**：`git revert`
2. **文档恢复**：从 git 历史恢复

> **注意**：不提供 `/openspec:*` 兼容别名。目标是完全解耦，现有用户需要迁移到新命令。

---

## 5. Validation（验收锚点）

### 5.1 验收标准

| AC ID | 验收条件 | 验证方式 | 证据落点 |
|-------|----------|----------|----------|
| AC-CI01 | 所有文件不包含 "openspec" 引用（backup 除外） | Grep 扫描 | `evidence/openspec-cleanup.log` |
| AC-CI02 | `setup/openspec/` 目录已删除 | 目录检查 | `evidence/dir-check.txt` |
| AC-CI03 | `/devbooks:proposal` 命令可用 | 手动测试 | `evidence/slash-cmd-test.log` |
| AC-CI04 | `/devbooks:apply` 命令可用 | 手动测试 | `evidence/slash-cmd-test.log` |
| AC-CI05 | `/devbooks:archive` 命令可用 | 手动测试 | `evidence/slash-cmd-test.log` |
| AC-CI06 | `npx create-devbooks` 可初始化项目 | 安装测试 | `evidence/npm-install-test.log` |
| AC-CI07 | 安装后目录结构符合设计 | 目录检查 | `evidence/installed-structure.txt` |
| AC-CI08 | Skills 配置发现不依赖 OpenSpec | 代码审查 | `evidence/config-discovery-review.md` |
| AC-CI09 | 21 个 Skills 的 SKILL.md 无 OpenSpec 引用 | Grep 扫描 | `evidence/skills-cleanup.log` |
| AC-CI10 | README.md 更新为 DevBooks 独立描述 | 人工审查 | `evidence/readme-review.md` |
| AC-CI11 | CI 脚本验证发布目录纯净性 | CI 运行 | `evidence/ci-purity-check.log` |
| AC-CI12 | Skills 安装到 ~/.claude/skills/ 成功 | 安装测试 | `evidence/skills-install.log` |
| AC-CI13 | 无 MCP 环境下基础功能正常 | 降级测试 | `evidence/no-mcp-test.log` |
| AC-CI14 | 迁移脚本 `migrate-from-openspec.sh` 有效 | 迁移测试 | `evidence/migration-test.log` |

### 5.2 证据落点

```
dev-playbooks/changes/complete-devbooks-independence/evidence/
├── openspec-cleanup.log
├── dir-check.txt
├── slash-cmd-test.log
├── npm-install-test.log
├── installed-structure.txt
├── config-discovery-review.md
├── skills-cleanup.log
├── readme-review.md
├── ci-purity-check.log
├── skills-install.log
├── no-mcp-test.log
└── migration-test.log
```

---

## 6. 实施路线图

### Phase 0: 前置准备（Design 阶段前）

| 任务 | 产物 | 优先级 |
|------|------|--------|
| P0.1 生成 OpenSpec 引用文件完整清单 | `evidence/openspec-files-list.txt` | P0 |
| P0.2 分类清单（删除/重写/部分修改） | 分类报告 | P0 |
| P0.3 评估工作量 | 工作量估算 | P0 |

### Phase 1: OpenSpec 清理

| 任务 | 产物 | 优先级 |
|------|------|--------|
| P1.1 删除 `setup/openspec/` 目录 | 目录删除 | P0 |
| P1.2 清理 160+ 文件中的 OpenSpec 引用 | 文件更新 | P0 |
| P1.3 更新配置发现脚本 | 脚本更新 | P0 |
| P1.4 更新 21 个 Skills | Skills 更新 | P0 |

### Phase 2: Slash 命令实现

| 任务 | 产物 | 优先级 |
|------|------|--------|
| P2.1 定义 slash 命令规范 | 规范文档 | P0 |
| P2.2 创建命令触发 Skills | Skills 更新 | P0 |
| P2.3 更新提示词文档 | 文档更新 | P1 |

### Phase 3: npm 包开发

| 任务 | 产物 | 优先级 |
|------|------|--------|
| P3.1 创建 npm 包结构 | package.json | P1 |
| P3.2 实现 CLI 入口 | bin/create-devbooks.js | P1 |
| P3.3 创建模板目录 | templates/ | P1 |
| P3.4 发布到 npm | npm 包 | P1 |

### Phase 4: 文档与收尾

| 任务 | 产物 | 优先级 |
|------|------|--------|
| P4.1 更新 README.md | 文档 | P1 |
| P4.2 编写迁移指南 | 迁移文档 | P1 |
| P4.3 清理 `.gitignore` | 配置更新 | P2 |
| P4.4 验收测试 | 证据 | P0 |

---

## 7. Debate Packet（争议点）

### 7.1 需要辩论的问题

#### DP-01：Slash 命令命名

**争议**：使用 `/devbooks:*` 还是更短的命名？

**选项**：
- A：`/devbooks:proposal/design/apply/review/archive`（完整）
- B：`/db:p/d/a/r/x`（简短）
- C：两者都支持（A 为正式，B 为别名）

**Author 立场**：选项 C，兼顾可读性和效率。

**可能的反对意见**：
- 别名增加维护成本
- 用户可能混淆

#### DP-02：npm 包命名

**争议**：npm 包应该叫什么？

**选项**：
- A：`create-devbooks`（遵循 create-* 惯例）
- B：`devbooks-cli`
- C：`@devbooks/cli`（scoped package）

**Author 立场**：选项 A，符合社区惯例（create-react-app, create-next-app）。

**可能的反对意见**：
- 包名可能已被占用
- scoped package 更专业

#### DP-03：阶段划分

**争议**：DevBooks 应该有几个阶段？

**当前设计**：5 阶段（proposal → design → apply → review → archive）

**可能的简化**：3 阶段（proposal → apply → archive），design 和 review 作为可选步骤

**Author 立场**：保持 5 阶段，但 design 和 review 可跳过。

**可能的反对意见**：
- 阶段太多，用户负担重
- 小变更不需要这么多阶段

#### DP-04：发布目录结构

**争议**：GitHub 仓库根目录应该是什么结构？

**选项**：
- A：保持当前结构，`.gitignore` 排除开发历史
- B：创建 `packages/` monorepo 结构
- C：拆分为两个仓库（devbooks-lib + devbooks-dev）

**Author 立场**：选项 A，最小改动。

**可能的反对意见**：
- `.gitignore` 容易遗漏
- monorepo 更清晰

#### DP-05：MCP 可选性实现

**争议**：如何处理 MCP 不可用的情况？

**选项**：
- A：分开维护两套提示词（基础版/完整版）
- B：单一提示词，内含条件检测逻辑
- C：CLI 安装时动态生成定制提示词

**Author 立场**：选项 C，最佳用户体验。

**可能的反对意见**：
- 动态生成增加复杂度
- 用户可能不理解生成逻辑

### 7.2 不确定点

| 不确定点 | 当前假设 | 需要验证 |
|----------|----------|----------|
| npm 包名可用性 | 假设 `create-devbooks` 未被占用 | 检查 npm 注册表 |
| Claude Code slash 命令格式 | 假设支持冒号分隔 | 验证 Claude Code 文档 |
| MCP 检测方法 | 假设可通过配置文件检测 | 验证实现可行性 |

### 7.3 开放问题

1. **Q：是否保留 OpenSpec 作为历史兼容？**
   - A：不保留。目标是完全解耦，老用户需要迁移。

2. **Q：slash 命令如何注册到 Claude Code？**
   - A：通过 Skills 机制，每个命令对应一个 Skill。

3. **Q：npm 包发布后如何更新？**
   - A：用户运行 `npx create-devbooks --update` 更新 Skills。

---

## 8. Decision Log（决策日志）

### 8.1 决策状态

**`Approved`**（Judge 二次裁决 2026-01-11）

### 8.2 争议点裁决结果

| 问题编号 | 问题 | 裁决 | 理由 |
|----------|------|------|------|
| DP-01 | Slash 命令命名 | **选 C**（完整 + 别名） | 完整命名为唯一文档化的官方命令，短命名作为未文档化的便捷方式 |
| DP-02 | npm 包命名 | **选 A**（`create-devbooks`） | 已验证可用；保留 C 为备选 |
| DP-03 | 阶段划分 | **保持 5 阶段 + 快速模式** | 增加 `/devbooks:quick` 命令支持小变更跳过 design 和 review |
| DP-04 | 发布目录结构 | **选 A + CI 防护** | 最小改动；必须增加 CI 脚本验证发布目录纯净性 |
| DP-05 | MCP 可选性 | **选 A + C 混合** | 维护两套基础模板 + CLI 动态生成定制提示词 |

### 8.3 Challenger 质疑报告摘要

**质疑日期**：2026-01-11
**结论**：`Revise`

**阻断项**：
- B-01：npm 包名可用性未验证 → **已解决**（验证结果：可用）
- B-02：Slash 命令格式兼容性 → **驳回**（当前项目已有 `openspec:*` 格式运行）
- B-03：160+ 文件清单缺失 → **接受**（降级为 Design 阶段前置任务）

**非阻断项**：
- NB-01：向后兼容过渡期（已澄清：不提供兼容）
- NB-02：MCP 检测机制技术细节（Design 阶段处理）
- NB-03：验收标准缺少自动化（已补充 AC-CI11 ~ AC-CI14）
- NB-04：迁移脚本未定义（已补充 AC-CI14）
- NB-05：Node.js 版本要求（Design 阶段处理）
- NB-06：Skills 更新机制（Design 阶段处理）

### 8.4 Judge 裁决记录

**裁决日期**：2026-01-11
**裁决结果**：`Revise`

**必须修改项**：

| 编号 | 修改要求 | 状态 |
|------|----------|------|
| REV-01 | 将"160+ 文件"改为"需在 Design 阶段前生成清单"，增加 P0 任务 | ✅ 已完成 |
| REV-02 | 明确 npm 包名策略：A 为首选，C 为备选 | ✅ 已完成 |
| REV-03 | 消除 Section 2.2 和 4.4 矛盾，删除兼容别名描述 | ✅ 已完成 |
| REV-04 | 增加"快速模式"说明 | ✅ 已完成 |
| REV-05 | 增加 CI 防护验收标准 | ✅ 已完成 |

### 8.5 Design 阶段待处理事项

| 编号 | 待处理事项 | 责任方 |
|------|------------|--------|
| D-01 | 生成并附录 OpenSpec 引用文件完整清单 | Design Author |
| D-02 | 设计 MCP 检测机制的技术方案 | Design Author |
| D-03 | 定义迁移脚本 `migrate-from-openspec.sh` 的具体行为 | Design Author |
| D-04 | 明确 Node.js 最低版本要求（建议 >= 18 LTS） | Design Author |
| D-05 | 设计 Skills 更新机制 | Design Author |
| D-06 | 为 AC-CI01 ~ AC-CI14 设计自动化验证脚本 | Design Author |
| D-07 | 确认 specs/openspec-integration/spec.md 处置方式（NB-09） | Design Author |
| D-08 | 定义"快速模式"量化边界（NB-10） | Design Author |

### 8.6 Judge 二次裁决记录

**裁决日期**：2026-01-11
**裁决结果**：**`Approved`**

**理由摘要**：
1. REV-01 ~ REV-05 共 5 项修订全部完成
2. 上一轮 3 个阻断项（B-01、B-02、B-03）已全部解决或驳回
3. 新增 NB-07 ~ NB-10 均为 Design 阶段可处理的细节，不阻断提案
4. 工作量偏差（160+ vs 415）已在 P0.1 前置任务覆盖
5. 提案结构完整，符合进入 Design 阶段的条件

**新增 Design 阶段待处理事项**：
- D-07：确认 specs/openspec-integration/spec.md 处置方式
- D-08：定义"快速模式"量化边界（影响文件数、接口变更等）

**Challenger 二轮质疑摘要**：
- 结论：Approve
- 新增非阻断项：NB-07（引用数量被低估）、NB-08（setup/openspec/ 清理确认）、NB-09（specs/ 处置方式）、NB-10（快速模式边界）
- 验证证据：OpenSpec 总引用 415 处（排除 backup/changes）；8/21 Skills SKILL.md 含引用

---

**提案结束**

**下一步**：提案已获批准，可进入 Design 阶段。使用 `devbooks-design-doc` Skill 产出 `design.md`。
