# Design: split-augment-add-test-reviewer

---
owner: Design Owner
created: 2026-01-10
updated: 2026-01-10
status: Ready
proposal_ref: ./proposal.md
---

> 产物落点：`openspec/changes/split-augment-add-test-reviewer/design.md`
>
> 禁止写实现步骤；只写 What/Constraints + AC-xxx。

## Problem Context

本变更解决 DevBooks 项目两个核心问题：代码理解能力与工作流框架的职责边界模糊，以及 Apply 阶段缺少专门评审测试质量的角色。详见 proposal.md §1.1。

**变化点识别**：
1. 代码理解能力位置（Variation Point）：当前耦合在 DevBooks，变化为独立 MCP Server
2. 测试评审角色（Variation Point）：当前缺失，变化为新增 test-reviewer
3. Hook 配置方式（Variation Point）：从本地脚本变为 MCP 调用

---

## 1. What（做什么）

### 1.1 拆分代码理解能力到独立项目

将 DevBooks 中的 Augment 风格代码理解能力（Embedding、Graph-RAG、调用链追踪、Bug 定位等）拆分为独立 Git 仓库 `code-intelligence-mcp`。

**拆分清单**：

| 类别 | 文件/目录 | 数量 |
|------|-----------|------|
| 工具脚本 | `tools/devbooks-embedding.sh`, `tools/graph-rag-context.sh`, `tools/call-chain-tracer.sh`, `tools/bug-locator.sh`, `tools/context-reranker.sh`, `tools/devbooks-complexity.sh`, `tools/devbooks-entropy-viz.sh`, `tools/devbooks-common.sh`, `tools/devbooks-cache-utils.sh`, `tools/devbooks-indexer.sh`, `tools/test-embedding.sh` | 11 |
| Hook 脚本 | `.claude/hooks/augment-context.sh`, `.claude/hooks/augment-context-with-embedding.sh`, `.claude/hooks/cache-manager.sh`, `setup/global-hooks/augment-context-global.sh` | 4 |
| 配置文件 | `.devbooks/embedding*.yaml`, `.devbooks/config.yaml` 中的 `embedding`/`graph_rag`/`reranker` 段 | 5 |

**新项目结构**（Shell 为主，MCP 薄壳）：

```
code-intelligence-mcp/
├── bin/
│   ├── code-intelligence-mcp    # MCP Server 入口（Node.js 薄壳）
│   └── ci-search                # 命令行入口
├── scripts/                     # 迁移的 Shell 脚本
├── hooks/                       # 迁移的 Hook 脚本
├── config/                      # 配置模板
├── src/server.ts               # MCP 薄壳
└── install.sh                   # 安装脚本
```

### 1.2 新增 test-reviewer 角色与 Skill

**角色定义**：
- 名称：`test-reviewer`
- 阶段：Apply
- 职责：评审测试质量（覆盖率/边界条件/可读性/可维护性/规格一致性）
- Skill：`devbooks-test-reviewer`

**与 reviewer 的区分**：

| 维度 | reviewer | test-reviewer |
|------|:--------:|:-------------:|
| 评审对象 | `src/`（实现代码） | `tests/`（测试代码） |
| 逻辑/风格/依赖 | ✅ | ❌ |
| 覆盖率/边界/可维护性 | ❌ | ✅ |
| 修改代码权限 | ❌ | ❌ |

### 1.3 更新文档与配置

更新 12 个文档以反映拆分后的架构：

| 文档 | 更新内容 |
|------|----------|
| `README.md` | 移除 Augment 描述，新增 MCP 依赖 |
| `使用说明书.md` | 拆分架构说明 |
| `角色使用说明.md` | 新增 test-reviewer |
| `openspec/project.md` | 新增 test-reviewer 角色定义 |
| `.devbooks/config.yaml` | 移除 embedding 段，新增 mcp_dependencies |
| `openspec/specs/_meta/project-profile.md` | 更新能力清单 |
| `openspec/specs/_meta/glossary.md` | 新增术语 |
| `docs/embedding-quickstart.md` | 重定向到新项目 |
| `docs/Augment-vs-DevBooks-技术对比.md` | 标记为历史 |
| `docs/Augment技术解析.md` | 移动或标记为历史 |
| `setup/README.md` | 更新安装流程 |
| `setup/hooks/README.md` | 重定向到新项目 |

---

## 2. Constraints（约束）

### 2.1 发布约束（人类指令，不可更改）

| 约束 | 说明 |
|------|------|
| CON-PUB-001 | DevBooks 不发布 npm 包，只通过 GitHub |
| CON-PUB-002 | code-intelligence-mcp 不发布 npm 包，只通过 GitHub |
| CON-PUB-003 | 安装方式统一为 `git clone` + `./install.sh` |

> 来源：proposal.md §2.4 人类指令

### 2.2 技术约束

| 约束 | 说明 |
|------|------|
| CON-TECH-001 | 本次只迁移 Shell 脚本，不重写为 TypeScript |
| CON-TECH-002 | MCP Server 使用 Node.js 薄壳调用 Shell 脚本 |
| CON-TECH-003 | 保留 tools/ 作为 fallback（MCP 失败时降级） |
| CON-TECH-004 | 新项目最低 Node.js 版本 18.x |
| CON-TECH-005 | Embedding 索引缺失时降级到关键词搜索（ripgrep） |

### 2.3 兼容约束

| 约束 | 说明 |
|------|------|
| CON-COMPAT-001 | Hook 三阶段废弃：Phase 1 保留副本 + deprecated 警告，Phase 2 只输出警告并重定向，Phase 3 移除 |
| CON-COMPAT-002 | 提供迁移脚本 `migrate-to-mcp.sh`，支持 dry-run |
| CON-COMPAT-003 | 迁移脚本必须跨平台兼容（macOS + Ubuntu + Debian + RHEL） |
| CON-COMPAT-004 | `.devbooks/config.yaml` 备份原配置为 `.bak` |

### 2.4 角色约束

| 约束 | 说明 |
|------|------|
| CON-ROLE-001 | test-reviewer 只看 `tests/`，不看 `src/` |
| CON-ROLE-002 | test-reviewer 不能修改任何代码 |
| CON-ROLE-003 | test-reviewer 必须检查测试与 verification.md 规格的一致性 |

### 2.5 质量约束

| 约束 | 说明 |
|------|------|
| CON-QUAL-001 | 新项目必须通过 ShellCheck（0 warnings） |
| CON-QUAL-002 | 新项目必须支持 `--help`、`--version` 参数 |
| CON-QUAL-003 | 现有 20 个 Skills 功能保持不变 |

---

## Acceptance Criteria

## 3. Acceptance Criteria（验收准则）

### 3.1 拆分验收

| AC-ID | 描述 | 验证方法 |
|-------|------|----------|
| AC-001 | `code-intelligence-mcp` 可独立运行 | `code-intelligence-mcp --version && code-intelligence-mcp search "test"` |
| AC-002 | DevBooks `tools/` 目录不再包含代码理解工具（11 个脚本已移动） | `ls tools/` 验证 |
| AC-003 | DevBooks Hook 文件标记 deprecated 警告 | 检查 `.claude/hooks/augment-context.sh` 开头 |
| AC-004 | 迁移脚本 dry-run 在 macOS/Ubuntu 无报错 | `./migrate-to-mcp.sh --dry-run` |

### 3.2 角色验收

| AC-ID | 描述 | 验证方法 |
|-------|------|----------|
| AC-005 | `devbooks-test-reviewer` Skill 可被调用 | `/devbooks-test-reviewer` 返回预期产物 |
| AC-006 | `openspec/project.md` 包含 test-reviewer 角色定义 | `grep "test-reviewer" openspec/project.md` |
| AC-007 | `角色使用说明.md` 包含 test-reviewer 说明 | `grep "test-reviewer" 角色使用说明.md` |

### 3.3 文档验收

| AC-ID | 描述 | 验证方法 |
|-------|------|----------|
| AC-008 | 12 个文档已更新 | 逐文件检查 |
| AC-009 | `README.md` 不再包含 Augment 功能描述 | `grep -v "Augment" README.md` |
| AC-010 | `docs/embedding-quickstart.md` 重定向到新项目 | 检查文件内容 |

### 3.4 兼容验收

| AC-ID | 描述 | 验证方法 |
|-------|------|----------|
| AC-011 | MCP 失败时降级到本地脚本 | 模拟 MCP 超时，验证降级 |
| AC-012 | `.devbooks/config.yaml.bak` 存在 | 迁移后检查 |

---

## Design Rationale

## 4. Design Rationale（设计决策理由）

### 4.1 为何拆分而非继续单体

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 项目结构 | 独立 Git 仓库 | 独立版本化、独立发布、可被非 DevBooks 项目使用 |
| 发布渠道 | GitHub-only | 人类指令明确禁止 npm，避免命名空间争议 |
| 语言 | 保持 Shell | 工作量小、风险低、后续可逐步重写 |

### 4.2 为何新增 test-reviewer 而非扩展 reviewer

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 角色分离 | 独立 test-reviewer | 单一职责原则，避免 reviewer 职责膨胀 |
| 评审对象 | `tests/` only | 避免与 reviewer（`src/` only）冲突 |
| 权限 | 只读 | 与其他评审角色保持一致 |

### 4.3 为何三阶段 Hook 废弃

| 阶段 | 策略 | 理由 |
|------|------|------|
| Phase 1 | 保留副本 + deprecated 警告 | 给用户迁移时间 |
| Phase 2 | 只输出警告并重定向 | 强制迁移但不破坏功能 |
| Phase 3 | 移除 | 完成迁移 |

---

## Trade-offs

**权衡取舍**：

| 权衡 | 选择 | 代价 | 收益 |
|------|------|------|------|
| 语言重写 vs 物理迁移 | 物理迁移 | Shell 脚本技术债仍存在 | 低风险、快速交付 |
| 独立仓库 vs 本地目录 | 独立仓库 | 增加维护负担 | 独立版本化、可复用 |
| 三阶段废弃 vs 立即移除 | 三阶段废弃 | 迁移周期长 | 用户平滑过渡 |
| test-reviewer 独立 vs 扩展 reviewer | 独立角色 | 增加角色数 | 职责清晰、单一原则 |

---

## 5. Contract（契约计划）

> 详见 Spec & Contract Owner 产出的规格增量。

### 5.1 API 变更

| 契约 | 变更类型 | Breaking? |
|------|----------|-----------|
| Hook 配置路径 | 路径变更（`~/.claude/settings.json`） | Yes |
| `.devbooks/config.yaml` | 移除 embedding/graph_rag/reranker 段 | Yes |
| MCP Server 工具 | 新增 code-intelligence tools | No |

### 5.2 兼容策略

- Phase 1（v2.0.x）：双轨运行（DevBooks 保留副本 + 新 MCP）
- Phase 2（v2.1.0）：DevBooks 只警告
- Phase 3（v3.0.0）：完全迁移

### 5.3 Contract Test IDs

| CT-ID | 契约 | 验证内容 |
|-------|------|----------|
| CT-MIG-001 | 迁移脚本 | dry-run 无报错 |
| CT-MIG-002 | 迁移脚本 | 配置备份存在 |
| CT-FALLBACK-001 | MCP 降级 | MCP 超时降级到本地脚本 |
| CT-FALLBACK-002 | Embedding 降级 | 索引缺失降级到关键词搜索 |
| CT-ROLE-001 | test-reviewer | 只评审 tests/ 目录 |
| CT-ROLE-002 | test-reviewer | 不修改任何代码 |

---

## 6. C4 Delta

> 由 C4 Map Maintainer 产出。proposal 阶段不修改 `openspec/specs/architecture/c4.md`（当前真理）。

### 6.1 C1 系统上下文变更

#### 新增外部系统

| 系统 | 类型 | 用途 | 必需 |
|------|------|------|------|
| code-intelligence-mcp | MCP Server | 代码理解能力（Embedding、Graph-RAG、调用链等） | 否（可降级到本地脚本） |

#### 移除的内部依赖

原 DevBooks 直接依赖的外部系统迁移到 `code-intelligence-mcp`：
- Ollama（本地 Embedding）
- OpenAI API（云端 Embedding）
- Azure OpenAI（企业 Embedding）
- Anthropic API Haiku（LLM 重排序）

**变更后依赖链**：
```
DevBooks → code-intelligence-mcp → Ollama/OpenAI/Azure/Haiku
```

### 6.2 C2 容器级变更

#### 移除容器

| 容器 | 原职责 | 迁移目标 |
|------|--------|----------|
| `tools/devbooks-embedding.sh` | Embedding 索引构建 | `code-intelligence-mcp/scripts/embedding.sh` |
| `tools/graph-rag-context.sh` | Graph-RAG 上下文引擎 | `code-intelligence-mcp/scripts/graph-rag.sh` |
| `tools/call-chain-tracer.sh` | 调用链追踪 | `code-intelligence-mcp/scripts/call-chain.sh` |
| `tools/bug-locator.sh` | Bug 定位 | `code-intelligence-mcp/scripts/bug-locator.sh` |
| `tools/context-reranker.sh` | LLM 重排序 | `code-intelligence-mcp/scripts/reranker.sh` |
| `tools/devbooks-complexity.sh` | 复杂度分析 | `code-intelligence-mcp/scripts/complexity.sh` |
| `tools/devbooks-entropy-viz.sh` | 熵度量可视化 | `code-intelligence-mcp/scripts/entropy-viz.sh` |
| `tools/devbooks-indexer.sh` | 索引管理 | `code-intelligence-mcp/scripts/indexer.sh` |
| `tools/devbooks-common.sh` | 公共函数库 | `code-intelligence-mcp/scripts/common.sh` |
| `tools/devbooks-cache-utils.sh` | 缓存工具 | `code-intelligence-mcp/scripts/cache-utils.sh` |
| `tools/test-embedding.sh` | Embedding 测试 | `code-intelligence-mcp/scripts/test-embedding.sh` |
| `setup/global-hooks/augment-context-global.sh` | 全局 Hook | `code-intelligence-mcp/hooks/` |
| `.claude/hooks/augment-context.sh` | 项目 Hook | `code-intelligence-mcp/hooks/` |

#### 修改容器

| 容器 | 变更内容 |
|------|----------|
| `tools/` | 移除 11 个代码理解工具脚本 |
| `.claude/hooks/` | Hook 添加 deprecated 警告，Phase 3 移除 |
| `setup/global-hooks/` | Hook 添加 deprecated 警告，Phase 3 移除 |

#### 新增容器

| 容器 | 职责 |
|------|------|
| `skills/devbooks-test-reviewer/` | test-reviewer 角色 Skill 实现 |

### 6.3 C3 组件级变更

#### tools/ 组件依赖图（变更后）

**Before**：
```
augment-context-global.sh (v3.0)
    │
    ├──► devbooks-embedding.sh ──┬──► Ollama
    │                             ├──► OpenAI API
    │                             └──► ripgrep
    │
    ├──► graph-rag-context.sh ──┬──► CKB MCP Server
    │         │                  └──► import 解析
    │         │
    │         └──► call-chain-tracer.sh ──► CKB MCP Server
    │
    ├──► context-reranker.sh ──► Anthropic API (Haiku)
    │
    └──► bug-locator.sh ──► call-chain-tracer.sh
```

**After**：
```
DevBooks Skills
    │
    └──► code-intelligence-mcp (MCP Server)
              │
              ├──► embedding.sh ──┬──► Ollama
              │                    ├──► OpenAI API
              │                    └──► ripgrep
              │
              ├──► graph-rag.sh ──► CKB MCP Server
              │
              └──► ... (其他工具)
```

#### skills/ 组件新增

```
skills/
├── ... (现有 20 个 Skills)
└── devbooks-test-reviewer/          # 新增
    ├── SKILL.md                     # Skill 定义
    └── scripts/                     # 评审脚本（如有）
```

### 6.4 依赖方向变更

| 变更 | Before | After | 影响 |
|------|--------|-------|------|
| DevBooks → 代码理解工具 | 直接依赖（内部调用） | 通过 MCP 协议调用 | 解耦，可独立版本化 |
| Hook → Embedding | 直接调用 tools/ | 调用 code-intelligence-mcp | 需迁移配置 |

### 6.5 建议的 Architecture Guardrails

#### 新增分层约束

| 层级 | 目录 | 职责 | 可依赖 | 禁止依赖 |
|------|------|------|--------|----------|
| external-mcp | code-intelligence-mcp | 代码理解 MCP Server | 外部 API、系统命令 | DevBooks 内部模块 |

#### 新增 Fitness Tests

| Test ID | 类型 | 描述 | 验证方式 |
|---------|------|------|----------|
| FT-008 | MCP 可用性 | code-intelligence-mcp 可通过 MCP 协议调用 | `code-intelligence-mcp --version` |
| FT-009 | 降级策略 | MCP 失败时降级到本地脚本或报错 | 模拟测试 |
| FT-010 | Hook 兼容 | deprecated Hook 输出警告 | `grep "DEPRECATED"` |
| FT-011 | 角色隔离 | test-reviewer 只读取 tests/ | Skill 实现验证 |

### 6.6 待 Archive 阶段更新的内容

> 以下内容待变更完成后，由 archive 阶段写入 `openspec/specs/architecture/c4.md`：

1. **C1 更新**：新增 `code-intelligence-mcp` 外部依赖
2. **C2 更新**：移除 `tools/` 中的 11 个代码理解工具；新增 `skills/devbooks-test-reviewer/`
3. **C3 更新**：更新 `tools/` 组件依赖图
4. **Guardrails 更新**：新增 FT-008 ~ FT-011
5. **元数据更新**：`last_verified` 日期

---

## 7. Open Questions（待澄清）

| 编号 | 问题 | 责任阶段 | 决策 |
|------|------|----------|------|
| OQ-001 | `devbooks-index-bootstrap` 和 `devbooks-entropy-monitor` 如何迁移到新 MCP？ | Apply | **已决策**：保留在 DevBooks，作为 MCP 客户端调用 code-intelligence-mcp |
| OQ-002 | Phase 2/3 绑定哪个具体版本号？ | Apply | **已决策**：Phase 2 = v2.1.0, Phase 3 = v3.0.0 |
| OQ-003 | test-reviewer 是否需要 `references/` 目录存放参考测试？ | Apply | **已决策**：暂不需要，评审基于 verification.md 规格 |

---

## 元数据

| 字段 | 值 |
|------|-----|
| 创建日期 | 2026-01-10 |
| 更新日期 | 2026-01-10 |
| 状态 | Ready |
| 关联 proposal | ./proposal.md |
| 作者 | Design Owner |

### Backport 记录

| 日期 | 来源 | 回写内容 |
|------|------|----------|
| 2026-01-10 | tasks.md §OQ 处理计划 | OQ-001~003 决策已确定 |
| 2026-01-10 | tasks.md §OQ 处理计划 | Phase 版本绑定（v2.0.x/v2.1.0/v3.0.0） |
| 2026-01-10 | verification.md CT-FALLBACK-002 | 新增 CON-TECH-005（索引缺失降级） |

---

*此设计文档由 devbooks-design-doc 产出，禁止包含实现步骤。实现计划见 tasks.md。*
