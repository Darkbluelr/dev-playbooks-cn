# 变更日志

本项目的所有重要变更都会记录在本文件中。

格式参考 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)，并遵循 [语义化版本](https://semver.org/spec/v2.0.0.html)。

## [4.0.0] - 2026-02-03

### 新增

- **完成合同（Completion Contract）**：把用户意图编译为机读合同，锁定“义务→检查→证据”链条，防止交付标准被静默弱化
- **7 道闸门（G0-G6）**：从输入就绪到归档裁决，全链路可裁判检查点，任何一道失败都会阻断
- **上游 SSOT 支持**：自动索引项目已有的需求文档，提取可裁判约束；缺失时自动创建最小 SSOT 包
- **Knife 切片协议**：大需求强制切片，每片有复杂度预算，超预算必须再切
- **Void 研究协议**：高熵问题先研究再决策，产出可追溯的决策记录（ADR）
- **证据新鲜度校验**：证据文件必须比被覆盖的交付物更新，防止用旧证据糊弄
- **弱连接义务**：文档、配置、发布说明等“代码外契约”也被编译为可裁判义务

### 修复

- **忽略规则补齐**：补齐 `.ci-index/`（本地索引数据库目录）到忽略清单，避免误提交/误发布
- **文档示例一致性**：安装后命令示例对齐为 `dev-playbooks-cn`

## [3.1.0] - 2026-01-31

> ⚠️ 重要：`3.0.0` 存在“错误发布/叙事漂移”风险（版本/变更记录与能力集不一致）。本版本用于收敛并提供可复验的发布与同步证据。建议跳过 `3.0.0`，直接使用 `3.1.0`。

### 新增

- **发布边界证据锚点**：
  - 将 `npm pack --dry-run` 作为发布边界的客观证据（packlist），用于复验“包内包含/不包含”的最终口径
  - 补齐 CLI 入口一致性自检锚点（bin 映射与入口可执行性）

### 变更

- **版本收敛**：
  - CN/EN 用户侧版本统一推进到 `3.1.0`，并对齐 Release notes 叙事（语言不同但要点一致）

### 修复

- **发布与同步闭环可裁判性**：
  - 将“发布包范围”和“跨仓同步边界”从口头约定收敛为脚本可复验证据（packlist + parity 报告）

---

## [3.0.3] - 2026-01-29

### 新增

- **协议 v1.1 覆盖与强制校验**：
  - 新增 v1.1 coverage mapping，并强制产出覆盖报告（映射 + 证据驱动；要求 `uncovered=0`）
- **闸门报告与风险证据约定**：
  - 新增 Gate Report 证据约定与风险证据落点（`evidence/gates/`、`evidence/risks/`）
- **依赖审计输出格式化**：
  - 新增格式化的依赖审计输出（最小字段 + 原始 audit JSON）

### 变更

- **强化 `change-check.sh`**：
  - 加固元数据合同、状态机、change-type 矩阵，以及 Knife/Bootstrap 的闸门校验
- **对齐文档与模板**：
  - 对齐 Gate Report、覆盖报告与依赖审计的约定（docs + templates）

---

## [3.0.2] - 2026-01-28

### 新增

- **协议层 CN↔EN 同步工具**：
  - 新增针对 `dev-playbooks/**` 的协议层同步脚本（带可审计报告与回滚锚点）：`scripts/english-sync-protocol.sh`
- **v1.1 覆盖报告生成器**：
  - 新增用于 strict/archive 闸门的 v1.1 覆盖报告生成脚本：`scripts/generate-protocol-v1.1-coverage-report.sh`

### 变更

- **加固 strict/archive 闸门**：
  - strict/archive 需要协议同步报告、parity 报告与 v1.1 覆盖报告（`skills/devbooks-delivery-workflow/scripts/change-check.sh`）
- **高风险审批加固**：
  - strict 模式下 `risk_level=high` 需要有人类审批记录（闸门强制）

---

## [3.0.1] - 2026-01-27

### 新增

- **新增 `/devbooks:delivery`（基于 `devbooks-delivery-workflow`）**：
  - 统一入口：产物化变更包骨架（RUNBOOK/inputs index + evidence + completion contract）并路由 `request_kind`
- **新增验证入口**：
  - 新增 legacy 清理、slash commands、npm 打包与总结校验等验证入口
- **新增工具脚本**：
  - `tools/devbooks-embedding.sh`、`tools/devbooks-complexity.sh`、`tools/devbooks-entropy-viz.sh`

### 变更

- **完善 strict 闸门**：
  - 完成 `change-check.sh` strict 校验：G0–G6 报告、风险/追溯/handoff 阻断，以及 registry 一致性检查
- **加固 `scripts/english-sync.sh`**：
  - 增加发布规格报告与加强 `dev-playbooks/**` deny 边界
- **统一 CLI 入口脚本**：
  - `bin/devbooks.mjs`

---

## [3.0.0] - 2026-01-26

### 新增

- **AI 原生工作流与协议升级**：
  - 补齐 Delivery 入口与 request_kind 路由规范
  - 新增变更包模板与协议合同（RUNBOOK、验证/合规/回滚、Knife Plan、合同 schema）
  - 完整化质量闸门与证据结构（G0–G6、风险与审计要求）
  - 新增依赖审计脚本与发布校验入口
  - 更新架构/文件系统视图与工作流示意图模板

### 变更

- **CLI 入口补齐**：
  - 新增 `delivery` 命令，用于入口指引（不执行 AI）
  - 帮助信息指向模板与工作流文档入口

---

## [2.6.0] - 2026-01-25

### 新增

- **MCP 增强功能**：
  - 新增 MCP 检测脚本 `scripts/detect-mcp.sh`
  - 增强所有 skill 的 MCP 集成模板
  - 新增 MCP 相关规格文档和指导

- **长期指导和参考文档**：
  - 新增 `skills/_shared/references/人类建议校准提示词.md`
  - 新增 `skills/devbooks-archiver/references/归档流程与规则.md`
  - 新增 `skills/devbooks-convergence-audit/references/` 目录
  - 新增 `skills/devbooks-delivery-workflow/references/编排禁令与阶段表.md`

- **规格文档完善**：
  - 新增 `dev-playbooks/specs/README.md` 规格索引
  - 完善 MCP、共享方法论、样式清理等规格文档

### 变更

- **文档结构优化**：
  - 更新所有 skill 的 SKILL.md 文档
  - 优化 README.md 和使用指南
  - 清理过时的文档文件

- **归档变更包**：
  - 归档 `20260124-0636-enhance-devbooks-longterm-guidance` 变更包

---

## [2.5.4] - 2026-01-23

### 修复

- **修正 ignore 规则**：
  - 移除 `.ckb/` - 这是外部工具 CKB 的缓存，不属于 DevBooks
  - 将 `dev-playbooks/changes/*/evidence/` 改为 `dev-playbooks/` - 整个工作目录都应该被 ignore

### 变更

- **更准确的 ignore 范围**：
  - `dev-playbooks/` - DevBooks 工作目录（包含所有运行时产生的内容）
  - `.devbooks/` - DevBooks 本地配置
  - `evidence/` - 测试证据目录
  - `*.tmp`, `*.bak` - 临时文件

---

## [2.5.3] - 2026-01-23

### 新增

- **智能 ignore 功能增强**：
  - 自动识别并 ignore DevBooks 工作流产生的临时文件
  - 新增 `evidence/` - 测试证据目录
  - 新增 `dev-playbooks/changes/*/evidence/` - 变更包中的证据
  - 新增 `*.tmp`, `*.bak` - 临时文件和备份文件
  - 新增 `.ckb/` - CKB 代码知识库缓存
  - 自动识别项目级 skills 目录（`.factory/`, `.cursor/` 等）

### 变更

- **更智能的 ignore 规则生成**：
  - 根据选择的 AI 工具自动添加对应的目录
  - 支持相对路径的 skills 目录自动识别
  - 同时更新 `.gitignore` 和 `.npmignore`

---

## [2.5.2] - 2026-01-23

### 修复

- **init 命令支持 Factory 和 Cursor**：
  - 将 Factory 添加为完整 Skills 支持的工具
  - 将 Cursor 从 Rules 系统升级为完整 Skills 支持
  - 现在运行 `dev-playbooks-cn init` 时可以选择 Factory 和 Cursor
  - Skills 会正确安装到 `.factory/skills/` 和 `.cursor/skills/`

- **更通用的 Skills 安装逻辑**：
  - 移除硬编码的工具 ID 检查
  - 支持所有定义了 `skillsDir` 的工具
  - 支持相对路径的 `skillsDir`（如 `.factory/skills`）

---

## [2.5.1] - 2026-01-23

### 修复

- 修复 `dev-playbooks-cn update` 命令的 changelog 显示功能
  - 添加完整的 2.5.0 版本变更记录
  - 确保用户可以看到最新版本的详细变更信息

---

## [2.5.0] - 2026-01-23

### 新增

- **Factory 原生 Skills 支持**：添加 `.factory/skills/` 目录，支持 Factory Droid
  - 使用符号链接指向现有 `skills/` 目录，保持单一数据源
  - 所有 18 个 DevBooks skills 可在 Factory 中原生使用
  - 符合 Factory Skills 标准（YAML frontmatter + Markdown）

- **Cursor 原生 Skills 支持**：添加 `.cursor/skills/` 目录，支持 Cursor Agent
  - 使用符号链接指向现有 `skills/` 目录，保持单一数据源
  - 所有 18 个 DevBooks skills 可在 Cursor 中原生使用
  - 符合 Cursor Agent Skills 标准

### 变更

- **README 优化**：
  - 移除"30秒电梯演讲"章节，简化文档结构
  - 更新"支持的 AI 工具"表格，添加 Factory 和 Cursor 原生支持
  - 明确标注各工具的 Skills 目录位置

- **package.json 更新**：
  - 添加 `.factory/` 和 `.cursor/` 到 npm 发布文件列表
  - 确保 Skills 目录随包一起发布

### Technical Details

- 使用符号链接（symlinks）而非复制文件，确保：
  - 单一数据源（Single Source of Truth）
  - 自动同步更新
  - 减少维护成本
  - 避免文件不一致

---

## [2.3.0] - 2026-01-23

### 新增

- 新增 `devbooks-docs-consistency`：文档一致性检查技能（原 `devbooks-docs-sync` 的改名与增强）
  - 支持自定义规则引擎（持续规则 + 一次性任务）
  - 增量扫描功能（基于 git diff，减少 90% token 消耗）
  - 完备性检查（5 个维度：环境依赖、安全权限、故障排查、配置说明、API 文档）
  - 文档分类（活体/历史/概念性文档）
  - 风格检查与持久化配置
- 新增共享参考文档
  - `skills/_shared/references/完备性思维框架.md`：完备性思维方法论
  - `skills/_shared/references/专家列表.md`：AI 专家角色列表
- 新增工具脚本
  - `scripts/benchmark-scan.sh`：扫描性能基准测试
  - `scripts/detect-fancy-words.sh`：浮夸词语检测

### 变更

- `devbooks-docs-sync` 改名为 `devbooks-docs-consistency`，旧名称作为别名保留（6 个月弃用期）
- 更新所有 skills 的 AI 行为规范，添加专家角色声明协议
- 优化 `devbooks-archiver`：集成文档一致性检查
- 优化 `devbooks-brownfield-bootstrap`：生成文档维护元数据
- 优化 `devbooks-proposal-author`：添加 Challenger 审视部分

### Removed

- 删除所有 skills 中的 MCP 增强章节
- 删除 `CSDN_ARTICLE.md`

---

## [2.2.1] - 2025-01-20

### 修复
- 修复 update 命令的 changelog 显示功能
  - 添加完整的版本变更记录
  - 将 CHANGELOG.md 添加到 npm 发布文件列表
- 优化 update 命令性能
  - 添加版本检查缓存（10 分钟 TTL）
  - 避免重复网络请求导致的卡顿

---

## [2.2.0] - 2025-01-20

### 新增
- 添加 Every Code (`@just-every/code`) 支持
  - 完整 Skills 系统支持
  - Skills 安装目录：`~/.code/skills/` 或 `.code/skills/`（项目级）
  - 使用 `AGENTS.md` 指令文件
- 安装脚本新增 `--code-only` 和 `--with-code` 选项
- 版本检查缓存（10 分钟 TTL）加速重复 `update` 命令

### 变更
- 更新 README 工具支持表格

---

## [2.1.1] - 2025-01-19

### 修复
- 规范用语修正

---

## [2.1.0] - 2025-01-19

### 新增

- **Version Changelog Display**: When running `dev-playbooks-cn update`, the CLI now displays a formatted changelog summary showing all changes between the current version and the latest version
  - ✅ Automatic fetch from GitHub: Retrieves CHANGELOG.md from the repository
  - 📋 Smart parsing: Extracts and displays only relevant version changes
  - 🎨 Colorized output: Highlights different types of changes (features, warnings, etc.)
  - 🔗 Graceful fallback: Shows GitHub release link if network fails
  - 📊 Content limit: Displays first 10 lines per version to avoid information overload

### Improved

- **User Experience**: Users can now make informed decisions about updates by reviewing what's new before upgrading

---

## [2.0.0] - 2026-01-19

### 新增

#### 🎯 Human-Friendly Document Templates

- **结论先行（Bottom Line Up Front）**: Every document (proposal, design, tasks, verification) now has a 30-second executive summary at the top
  - ✅ What will result: List changes in plain language
  - ❌ What won't result: Clearly state what won't change
  - 📝 One-sentence summary: Understandable even for non-technical people

- **需求对齐（Alignment Check）**: Proposal phase now includes guided questions to uncover hidden requirements
  - 👤 Role identification: Quick Starter / Platform Builder / Rapid Validator
  - 🎯 Core requirements: Explicit + hidden requirements
  - 💡 Multi-perspective recommendations: Different recommendations based on different roles

- **默认批准机制（Default Approval Mechanism）**: Reduce decision fatigue with auto-approval
  - ⏰ User silence = agreement: Auto-approve after timeout
  - 🎛️ Configurable timeout: proposal 48h / design 24h / tasks 24h / verification 12h
  - 🔒 Retain control: Users can reject or customize at any time

- **项目级文档（Project-Level Documents）**: Knowledge retention and decision tracking
  - 📋 User Profile (project-profile.md): Record role, requirements, constraints, preferences
  - 📝 Decision Log (decision-log.md): Record all important decisions for retrospection

#### New Document Templates

- `skills/_shared/references/文档模板-proposal.md` (Chinese)
- `skills/_shared/references/文档模板-design.md` (Chinese)
- `skills/_shared/references/文档模板-tasks.md` (Chinese)
- `skills/_shared/references/文档模板-verification.md` (Chinese)
- `skills/_shared/references/文档模板-project-profile.md` (Chinese)
- `skills/_shared/references/文档模板-decision-log.md` (Chinese)
- `skills/_shared/references/批准配置说明.md` (Chinese)
- `skills/_shared/references/document-template-proposal.md` (English)
- `skills/_shared/references/document-template-design.md` (English)
- `skills/_shared/references/document-template-tasks.md` (English)
- `skills/_shared/references/document-template-verification.md` (English)
- `skills/_shared/references/document-template-project-profile.md` (English)
- `skills/_shared/references/document-template-decision-log.md` (English)
- `skills/_shared/references/approval-configuration-guide.md` (English)

#### Documentation

- Updated README.md with v2.0.0 features section (both Chinese and English versions)

### 变更

- **proposal-author skill**: Updated to use new document templates
  - Now generates documents with "Bottom Line Up Front" section
  - Includes "Alignment Check" to uncover hidden requirements
  - Provides multi-perspective recommendations based on user role
  - References new template files in prompts

### Breaking Changes

⚠️ **Document Structure Changes**

- Existing proposal.md files do not conform to the new structure
- Migration may be required for existing projects
- Old format is still supported but not recommended

**Mitigation**:
- Migration script will be provided in future releases
- Backward compatibility maintained for reading old format
- New projects will use new format by default

⚠️ **Approval Mechanism Changes**

- Introduces default approval mechanism which may not fit all team workflows
- Default strategy is `auto_approve` but can be changed to `require_explicit`

**Mitigation**:
- Configurable approval strategy in `.devbooks/config.yaml`
- Can disable auto-approval for high-risk projects
- Timeout values are configurable

### Design Philosophy

This release is inspired by:
- Cognitive Load Theory: Minimize extraneous load, maximize germane load
- Dual Process Theory: Design for both System 1 (fast) and System 2 (slow) thinking
- Nudge Theory: Use default options to guide better decisions
- Inverted Pyramid Structure: Put conclusions first, details later

**Core Principles**:
- 🎯 Assume users are non-technical: Use plain language, avoid jargon
- 🤔 Uncover hidden requirements: Guide users through questions
- ⏰ Reduce decision fatigue: Default approval with configurable timeout
- 📋 Knowledge retention: Project-level documents for long-term reference

### Upgrade Guide

#### For Existing Projects

1. Update npm package:
   ```bash
   npm install -g dev-playbooks-cn@2.0.0
   # or
   npm install -g dev-playbooks@2.0.0
   ```

2. (Optional) Migrate existing documents:
   ```bash
   # Migration script will be provided in future releases
   devbooks migrate --from 1.x --to 2.0.0
   ```

3. (Optional) Configure approval mechanism:
   Create `.devbooks/config.yaml`:
   ```yaml
   approval:
     default_strategy: auto_approve
     timeout:
       proposal: 48
       design: 24
       tasks: 24
       verification: 12
   ```

4. (Optional) Create project-level documents:
   ```bash
   devbooks init-profile
   devbooks init-decision-log
   ```

#### For New Projects

New projects will automatically use the new document templates. No migration needed.

### References

- Report: "Protocol 2026: Cognitive Compatibility and Human-Computer Communication Standards in the AI-Native Era"
- Cognitive Load Theory (CLT)
- Dual Process Theory
- Nudge Theory
- Inverted Pyramid Structure

---

## [1.7.4] - 2026-01-18

### 变更
- Various bug fixes and improvements

---

## [1.7.0] - 2026-01-15

### 新增
- Initial release with 18 skills
- Support for Claude Code, Codex CLI, and other AI tools
- Quality gates and role isolation
- MCP integration support

---

[2.0.0]: https://github.com/Darkbluelr/dev-playbooks-cn/compare/v1.7.4...v2.0.0
[1.7.4]: https://github.com/Darkbluelr/dev-playbooks-cn/compare/v1.7.0...v1.7.4
[1.7.0]: https://github.com/Darkbluelr/dev-playbooks-cn/releases/tag/v1.7.0
