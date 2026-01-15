# DevBooks 配置指南

> 本指南帮助你在项目中集成 DevBooks 工作流。

---

## 快速开始（让 AI 自动配置）

将以下提示词发送给 AI，它会自动完成配置：

```text
你是"DevBooks 上下文协议适配器安装员（DevBooks Context Protocol Adapter Installer）"。你的目标是在目标项目中，把 DevBooks 的协议无关约定（<truth-root>/<change-root> + 角色隔离 + DoD + Skills 索引）集成到该项目的上下文协议里。

前置条件（先检查，缺失则停止并说明原因）：
- 系统依赖已安装（必需：jq、ripgrep；推荐：scc、radon）
  检查命令：command -v jq rg scc radon
  若缺失，运行：<devbooks-root>/scripts/install-dependencies.sh
- 你能定位该项目的"标牌文件（signpost file）"（由上下文协议决定，常见：CLAUDE.md / AGENTS.md / PROJECT.md / <protocol>/project.md）。

硬约束（必须遵守）：
1) 本次安装只允许改"上下文/文档标牌"，不得修改业务代码、tests、也不得引入新依赖。
2) 若目标项目已有"上下文协议托管区块（managed block）"，自定义内容必须放在托管区块之外，避免被后续自动更新覆盖。
3) 安装必须明确写出两个目录根：
   - <truth-root>：当前真理目录根
   - <change-root>：变更包目录根

任务（按顺序执行）：
0) 检查系统依赖：
   - 运行：command -v jq rg scc radon
   - 若缺失必需依赖（jq、rg），提示用户先运行：./scripts/install-dependencies.sh
   - 若缺失推荐依赖（scc、radon），说明这是可选项，用于启用"复杂度加权热点"等能力
1) 识别上下文协议类型（至少两条分支）：
   - 若检测到 DevBooks（存在 dev-playbooks/project.md）：使用 DevBooks 默认值（<truth-root>=dev-playbooks/specs，<change-root>=dev-playbooks/changes）
   - 否则：使用手动配置部分进行集成
2) 为该项目确定目录根：
   - 若项目已有 specs/changes 等目录约定：直接沿用作为 <truth-root>/<change-root>
   - 若项目没有定义：推荐在仓库根目录使用 `specs/` 与 `changes/`
3) 将模板内容合入标牌文件（以追加方式合并）：
   - 写入：<truth-root>/<change-root>、变更包结构约定、角色隔离、DoD、devbooks-* Skills 索引
4) 验证（必须输出检查结果）：
   - 产物落点是否一致（proposal/design/tasks/verification/specs/evidence）
   - 是否包含 Test Owner/Coder 隔离与"Coder 禁止修改 tests"
   - 是否包含 DoD（MECE）
   - 是否包含 devbooks-* Skills 索引

完成后输出：
- 系统依赖检查结果（哪些已安装、哪些缺失）
- 你修改了哪些文件（列表）
- 该项目最终的 <truth-root>/<change-root> 值
- 下一步最短路径示例（用自然语言点 2-3 个关键 skills）
```

---

## 手动配置

如果你想手动配置，将以下内容添加到项目的标牌文件（`CLAUDE.md`、`AGENTS.md` 或 `PROJECT.md`）中：

### 目录根配置

```yaml
# DevBooks 目录约定
truth_root: dev-playbooks/specs/    # 当前真理目录根
change_root: dev-playbooks/changes/ # 变更包目录根
```

### 单次变更包结构

每次变更的产物按以下结构组织：

| 产物 | 路径 | 说明 |
|------|------|------|
| 提案 | `<change-root>/<change-id>/proposal.md` | Why/What/Impact |
| 设计 | `<change-root>/<change-id>/design.md` | What/Constraints + AC-xxx |
| 计划 | `<change-root>/<change-id>/tasks.md` | 可跟踪的编码任务 |
| 验证 | `<change-root>/<change-id>/verification.md` | 追溯矩阵 + MANUAL-* 清单 |
| 规格增量 | `<change-root>/<change-id>/specs/**` | 本次变更的规格 delta |
| 证据 | `<change-root>/<change-id>/evidence/**` | Red/Green 证据（按需） |

### 当前真理目录结构

```
<truth-root>/
├── _meta/
│   ├── project-profile.md    # 项目画像/约束/闸门
│   └── glossary.md           # 统一语言术语表
├── architecture/
│   └── c4.md                 # C4 架构地图
└── engineering/
    └── pitfalls.md           # 高 ROI 坑库（可选）
```

### 角色隔离（强制）

```markdown
## DevBooks 角色隔离规则

- Test Owner 与 Coder 必须在**独立对话/独立实例**中工作
- 允许并行，但不允许共享上下文造成"自证式测试"
- Coder **禁止修改** `tests/**`
- 如需调整测试，必须交回 Test Owner 决策与修改
```

### DoD（完成定义，MECE）

每次变更必须声明覆盖哪些闸门，未覆盖项必须写明原因：

| 闸门 | 类型 | 示例 |
|------|------|------|
| 行为 | unit/integration/e2e | pytest, jest |
| 契约 | OpenAPI/Proto/Schema | contract tests |
| 结构 | 分层/依赖方向/无环 | fitness tests |
| 静态/安全 | lint/typecheck/build | SAST/secret scan |
| 证据 | 截图/录像/报告 | UI、性能（按需） |

---

## Skills 索引

### 按角色

| 角色 | Skill | 产物落点 |
|------|-------|----------|
| Router | `devbooks-router` | 路由与下一步建议 |
| Proposal Author | `devbooks-proposal-author` | `proposal.md` |
| Proposal Challenger | `devbooks-proposal-challenger` | 质疑报告 |
| Proposal Judge | `devbooks-proposal-judge` | 裁决回写 |
| Impact Analyst | `devbooks-impact-analysis` | Impact 章节 |
| Design Owner | `devbooks-design-doc` | `design.md` |
| Spec & Contract | `devbooks-spec-contract` | `specs/**` |
| Planner | `devbooks-implementation-plan` | `tasks.md` |
| Test Owner | `devbooks-test-owner` | `verification.md` + `tests/` |
| Coder | `devbooks-coder` | 按 tasks 实现（禁止改 tests） |
| Reviewer | `devbooks-code-review` | 评审意见 |
| Archiver | `devbooks-archiver` | 归档修剪 + C4 合并 |
| Design Backport | `devbooks-design-backport` | 回写设计缺口 |

### 按工作流

| 工作流 | Skill | 说明 |
|--------|-------|------|
| Delivery | `devbooks-delivery-workflow` | 变更闭环 |
| Brownfield Bootstrap | `devbooks-brownfield-bootstrap` | 存量项目初始化 |

### 度量

| 功能 | Skill | 说明 |
|------|-------|------|
| Entropy Monitor | `devbooks-entropy-monitor` | 系统熵度量 |

---

## 高级选项

### 自定义目录映射

在 `.devbooks/config.yaml` 中配置：

```yaml
# 目录映射
mapping:
  truth_root: specs/           # 自定义真理目录
  change_root: changes/        # 自定义变更目录
  agents_doc: AGENTS.md        # 规则文档路径

# AI 工具配置
ai_tools:
  - claude
  - cursor
```

### CI/CD 集成

将 `templates/ci/` 中的模板复制到 `.github/workflows/`：

- `devbooks-guardrail.yml`：PR 上检查复杂度/热点/分层违规
- `devbooks-cod-update.yml`：push 后更新 COD 模型

---

## 自动 Skill 路由

AI 可以根据用户意图自动选择 Skills：

| 用户意图 | 自动路由 |
|----------|----------|
| "修 bug"、"定位问题" | `devbooks-impact-analysis` → `devbooks-coder` |
| "重构"、"优化代码" | `devbooks-code-review` → `devbooks-coder` |
| "新功能"、"实现 XX" | `devbooks-router` → 输出闭环路线 |
| "写测试"、"补测试" | `devbooks-test-owner` |
