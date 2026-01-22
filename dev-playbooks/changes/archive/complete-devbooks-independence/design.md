# Design: complete-devbooks-independence

> 产物落点：`dev-playbooks/changes/complete-devbooks-independence/design.md`
>
> 状态：**Archived**（已归档 2026-01-12）
> 版本：v1.0.0
> 更新时间：2026-01-12
> Owner：Design Owner
> last_verified：2026-01-12
> freshness_check：30d
> archived_by：Spec Gardener

---

## ⚡ Acceptance Criteria（验收标准）

### 核心验收（Breaking Change 门控）

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-001 | OpenSpec 引用清零 | `grep -rn "openspec\|OpenSpec" . \| grep -v backup \| grep -v changes \| wc -l` 返回 0 | A（脚本） |
| AC-002 | `setup/openspec/` 目录已删除 | `[ ! -d "setup/openspec" ]` 返回 true | A（脚本） |
| AC-003 | `.claude/commands/openspec/` 目录已删除 | `[ ! -d ".claude/commands/openspec" ]` 返回 true | A（脚本） |
| AC-004 | `dev-playbooks/specs/openspec-integration/` 目录已删除 | `[ ! -d "dev-playbooks/specs/openspec-integration" ]` 返回 true | A（脚本） |

### Slash 命令验收

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-005 | `/devbooks:proposal` 命令可触发 devbooks-proposal-author | 在 Claude Code 中输入命令，观察是否加载正确 Skill | B（工具+人） |
| AC-006 | `/devbooks:design` 命令可触发 devbooks-design-doc | 同上 | B（工具+人） |
| AC-007 | `/devbooks:apply` 命令可触发 devbooks-test-owner 或 devbooks-coder | 同上 | B（工具+人） |
| AC-008 | `/devbooks:review` 命令可触发 devbooks-code-review | 同上 | B（工具+人） |
| AC-009 | `/devbooks:archive` 命令可触发 devbooks-spec-gardener | 同上 | B（工具+人） |
| AC-010 | `/devbooks:quick` 命令可用（跳过 design/review） | 快速模式验证测试通过 | B（工具+人） |

### npm 包验收

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-011 | `npx create-devbooks` 命令可执行 | 在干净目录运行，无错误退出 | A（脚本） |
| AC-012 | 安装后 `dev-playbooks/` 目录结构完整 | 包含 constitution.md, project.md, specs/, changes/ | A（脚本） |
| AC-013 | 安装后 `.devbooks/config.yaml` 存在且有效 | YAML 解析无错误，必要字段存在 | A（脚本） |
| AC-014 | Skills 安装到 `~/.claude/skills/` 成功 | 21 个 Skills 目录存在 | A（脚本） |
| AC-015 | 发布包不包含 `dev-playbooks/changes/` 内容 | npm pack 后检查 tarball 内容 | A（脚本） |
| AC-016 | 发布包不包含 `.devbooks/backup/` 内容 | 同上 | A（脚本） |

### MCP 可选性验收

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-017 | 无 MCP 环境下基础 Skills 功能正常 | devbooks-router 不报 MCP 缺失错误 | A（脚本） |
| AC-018 | MCP 检测逻辑正确识别已安装 MCP | 检测脚本返回正确的 MCP 列表 | A（脚本） |

### 配置发现验收

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-019 | config-discovery.sh 不依赖 OpenSpec | 脚本无 `openspec` 字符串 | A（grep） |
| AC-020 | 21 个 Skills 的配置发现统一使用 .devbooks/config.yaml | 抽样检查 3 个 Skills | B（代码审查） |

### 迁移验收

| AC ID | 验收条件 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-021 | 迁移脚本 `migrate-from-openspec.sh` 存在 | 文件存在且可执行 | A（脚本） |
| AC-022 | 迁移脚本可将 OpenSpec 项目转换为 DevBooks | 在测试项目运行，验证目录结构 | A（脚本） |

---

## ⚡ Goals / Non-goals + Red Lines

### Goals（本次变更目标）

1. **G-01 完全解耦**：移除全部 473 处 OpenSpec 引用，DevBooks 成为独立的变更管理协议
2. **G-02 原生命令**：实现 `/devbooks:*` 系列 Slash 命令，替代 `/openspec:*`
3. **G-03 一键安装**：发布 `create-devbooks` npm 包，支持 `npx create-devbooks` 初始化
4. **G-04 纯净发布**：GitHub/npm 发布内容不含开发历史和项目特定内容
5. **G-05 MCP 可选**：无 MCP 环境下基础功能可用

### Non-goals（明确不做）

1. **NG-01 保留 OpenSpec 兼容**：不提供 `/openspec:*` 别名，不保留向后兼容
2. **NG-02 多协议支持**：DevBooks 自身即协议，不支持切换到其他协议
3. **NG-03 Codex CLI 支持**：本次仅支持 Claude Code
4. **NG-04 图形界面**：本次仅 CLI

### Red Lines（不可违背）

1. **RL-01 人类要求不可违背**：提案中的三条人类要求（完全解耦/纯净发布/一键安装）必须满足
2. **RL-02 真理源唯一性**：`specs/` 仍是唯一权威，不引入新的真理源
3. **RL-03 角色隔离**：Test Owner 与 Coder 隔离原则不变
4. **RL-04 测试不可篡改**：Coder 禁止修改 tests/ 原则不变
5. **RL-05 宪法优先**：constitution.md 加载优先级不变

---

## 执行摘要

将 DevBooks 从 OpenSpec 派生工具升级为独立的变更管理协议。核心矛盾：需要清理 473 处引用同时保持 21 个 Skills 和脚本的功能完整性，且不能破坏现有用户的工作流。

---

## Problem Context（问题背景）

### 业务驱动

1. **品牌独立性**：DevBooks 需要独立的身份和安装体验
2. **用户困惑**：当前文档和命令混杂 OpenSpec 概念，新用户难以理解
3. **安装门槛**：克隆仓库 + 运行脚本的安装方式复杂

### 技术债

1. **引用残留**：上次重构（evolve-devbooks-architecture）未完成清理
2. **配置发现复杂**：需要处理多种协议的特殊情况
3. **发布污染**：`changes/` 和开发历史混入发布内容

### 若不解决的后果

1. 新用户安装体验差，采用率低
2. 文档混乱，维护成本高
3. 无法发布到 npm，阻碍分发

---

## 设计原则

### 变化点识别

| 变化点 | 变化频率 | 封装策略 |
|--------|----------|----------|
| Slash 命令名称 | 低（本次一次性变更） | 集中在 `.claude/commands/` |
| MCP 可用性 | 中（用户环境差异） | 运行时检测 + 降级 |
| Skills 集合 | 中（后续可能新增） | 目录扫描而非硬编码 |
| 发布内容 | 高（每个版本不同） | `.npmignore` + CI 验证 |

### 依赖方向

```
用户项目 → DevBooks CLI → Skills → 公共脚本
           ↓
        templates/
```

- 用户项目依赖 DevBooks，反之不成立
- Skills 依赖公共脚本（如 config-discovery.sh），反之不成立
- 模板是静态资源，无运行时依赖

---

## 目标架构

### Bounded Context

| Context | 职责 | 边界 |
|---------|------|------|
| DevBooks CLI | npm 包安装、项目初始化 | `bin/`, `templates/` |
| Skills | 变更管理工作流执行 | `skills/devbooks-*` |
| Scripts | 公共脚本（配置发现、质量闸门） | `scripts/` |
| Docs | 用户文档和提示词 | `docs/` |

### C4 Delta

> 注意：proposal 阶段不修改 `dev-playbooks/specs/architecture/c4.md`（当前真理）。
> 归档时需将此 Delta 合并到权威 C4 地图。

#### C1 System Context 层变更

| 变更类型 | 元素 | 说明 |
|----------|------|------|
| 删除 | OpenSpec 协议 | 从外部系统列表中移除 OpenSpec 引用 |
| 新增 | npm Registry | 作为发布目标的外部系统 |
| 修改 | 用户角色描述 | 从"使用 Claude Code 或 Codex CLI 的开发者"简化为"使用 Claude Code 的开发者" |

#### C2 Container 层变更

| 变更类型 | 元素 | 说明 |
|----------|------|------|
| 新增 | `bin/` | npm 包 CLI 入口（`create-devbooks.js`） |
| 新增 | `templates/` | 用户项目模板（干净的 `dev-playbooks/` 结构） |
| 新增 | `.claude/commands/devbooks/` | DevBooks 原生 Slash 命令定义 |
| 删除 | `setup/openspec/` | 移除 OpenSpec 协议模板（整个目录） |
| 删除 | `.claude/commands/openspec/` | 移除旧命令（整个目录） |
| 删除 | `dev-playbooks/specs/openspec-integration/` | 移除 OpenSpec 集成规格 |
| 修改 | `scripts/config-discovery.sh` | 移除 OpenSpec 特殊处理 |
| 修改 | `setup/` | 移除 `openspec/` 子目录后，仅保留 `generic/` 和 `README.md` |

#### C3 Component 层变更

**setup/ 组件变更**：

```
变更前：                    变更后：
setup/                      setup/
├── openspec/    [删除]     ├── generic/
│   ├── README.md           │   ├── DevBooks集成模板.md
│   └── 安装提示词.md       │   └── 安装提示词.md
├── generic/                └── README.md
│   ├── DevBooks集成模板.md
│   └── 安装提示词.md
└── README.md
```

**skills/devbooks-delivery-workflow/scripts/ 组件变更**：

| 变更类型 | 脚本 | 说明 |
|----------|------|------|
| 删除 | `rollback-to-openspec.sh` | 无需回滚能力（完全解耦） |
| 修改 | `migrate-to-devbooks-2.sh` | 重命名为 `migrate-from-openspec.sh` |
| 新增 | `verify-openspec-free.sh` | AC-001 ~ AC-004 验证脚本 |

#### 依赖方向变化

```
变更前：
skills/ ──► config-discovery.sh ──► openspec/project.md
                                 └► .devbooks/config.yaml

变更后：
skills/ ──► config-discovery.sh ──► .devbooks/config.yaml（唯一路径）
```

**移除的依赖**：
- `config-discovery.sh` → `openspec/project.md`
- `setup/openspec/` → OpenSpec 协议规范

**新增的依赖**：
- `bin/create-devbooks.js` → `templates/`
- `bin/create-devbooks.js` → `~/.claude/skills/`

#### 建议的 Architecture Guardrails

**FT-006: OpenSpec 引用禁止**（新增）

> 来源：complete-devbooks-independence 变更

**规则**：代码库中（除 backup 和 changes 目录外）禁止包含 `openspec` 或 `OpenSpec` 字符串。

**检查命令**：
```bash
grep -rn "openspec\|OpenSpec" . --include="*.md" --include="*.sh" --include="*.yaml" \
  | grep -v ".devbooks/backup" \
  | grep -v "dev-playbooks/changes" \
  | wc -l
# 期望输出：0
```

**严重程度**：Critical

---

**FT-007: 发布包纯净性**（新增）

> 来源：complete-devbooks-independence 变更

**规则**：npm pack 产物不得包含 `changes/` 或 `backup/` 路径。

**检查命令**：
```bash
npm pack --dry-run 2>&1 | grep -E "changes/|backup/" && echo "FAIL" || echo "OK"
```

**严重程度**：Critical

---

**FT-008: Skills 数量一致性**（新增）

**规则**：`~/.claude/skills/devbooks-*` 目录数量必须等于 21。

**检查命令**：
```bash
ls -d ~/.claude/skills/devbooks-* 2>/dev/null | wc -l
# 期望输出：21
```

**严重程度**：High

---

**FT-009: Slash 命令目录一致性**（新增）

**规则**：`.claude/commands/devbooks/` 必须存在，`.claude/commands/openspec/` 必须不存在。

**检查命令**：
```bash
[ -d ".claude/commands/devbooks" ] && [ ! -d ".claude/commands/openspec" ] && echo "OK" || echo "FAIL"
```

**严重程度**：High

### Testability & Seams

**测试接缝**：
- config-discovery.sh 接受 `--dry-run` 参数，输出配置而不执行
- CLI 接受 `--template-dir` 参数，可指定模板来源
- Skills 的 SKILL.md 可被测试脚本解析验证

**Pinch Points**：
- config-discovery.sh：所有 Skills 的配置发现汇聚点
- create-devbooks.js：所有安装逻辑的汇聚点

**依赖隔离**：
- 文件系统操作通过 Bash 脚本封装，测试时可 mock 目录
- npm 注册表交互仅在发布时，安装测试使用本地 tarball

---

## 领域模型

### Data Model

| 对象 | 类型 | 说明 |
|------|------|------|
| DevBooksConfig | @ValueObject | `.devbooks/config.yaml` 的内存表示 |
| SkillDefinition | @ValueObject | `SKILL.md` 解析结果 |
| ProjectTemplate | @ValueObject | 模板目录结构定义 |
| ChangePackage | @Entity | 变更包，有 ID 和状态 |

### Business Rules

| BR ID | 规则 | 触发条件 | 违反时行为 |
|-------|------|----------|------------|
| BR-001 | 配置文件必须存在 | CLI 初始化时 | 创建默认配置 |
| BR-002 | Skills 目录必须可写 | Skills 安装时 | 报错并提示权限修复 |
| BR-003 | 快速模式仅限小变更 | `/devbooks:quick` | 检查变更范围，超限则提示使用完整流程 |
| BR-004 | 发布包不含开发内容 | npm pack 时 | CI 阻断发布 |

### Invariants

- `[Invariant]` 配置中 `root` 字段指向的目录必须存在
- `[Invariant]` Skills 安装后 `~/.claude/skills/devbooks-*` 目录数量 = 21
- `[Invariant]` 发布包 tarball 不含 `changes/` 或 `backup/` 路径

---

## 核心数据与事件契约

### Slash 命令契约

| 命令 | 输入 | 触发的 Skills | 产物 |
|------|------|---------------|------|
| `/devbooks:proposal` | 无 | devbooks-proposal-author | `<change-root>/<id>/proposal.md` |
| `/devbooks:design` | proposal.md 存在 | devbooks-design-doc | `<change-root>/<id>/design.md` |
| `/devbooks:apply --role test-owner` | design.md 存在 | devbooks-test-owner | `verification.md` + `tests/` |
| `/devbooks:apply --role coder` | tasks.md 存在 | devbooks-coder | 实现代码 |
| `/devbooks:review` | 代码已提交 | devbooks-code-review | 评审意见 |
| `/devbooks:archive` | 变更完成 | devbooks-spec-gardener | 归档并清理 |
| `/devbooks:quick` | 小变更 | proposal → apply → archive | 快速闭环 |

### 配置文件契约

**`.devbooks/config.yaml` schema**：

```yaml
# 必填字段
root: string           # DevBooks 管理目录
constitution: string   # 宪法文件相对路径
project: string        # 项目上下文相对路径

# 路径配置
paths:
  specs: string        # 真理源目录
  changes: string      # 变更包目录
  scripts: string      # 脚本目录
  staged: string       # 暂存目录
```

**schema_version**：1.0.0

**兼容策略**：
- 向后兼容：保留 `truth_root`/`change_root` 别名，3 个版本后移除
- 向前兼容：新增字段设默认值，旧配置可正常解析

### 契约计划（Contract Plan）

#### A. 契约变更清单

| 契约类型 | 变更类型 | 契约文件位置 | 说明 |
|----------|----------|--------------|------|
| Slash 命令 | **Breaking** | `.claude/commands/devbooks/*.md` | 新增 6 个命令定义 |
| 配置文件 | **Minor** | `.devbooks/config.yaml` | 移除 `protocol` 字段 |
| CLI API | **新增** | `bin/create-devbooks.js` | npm 包 CLI 入口 |

#### B. 兼容性策略

| 契约 | 向后兼容 | 向前兼容 | 弃用窗口 |
|------|----------|----------|----------|
| Slash 命令 | 否（Breaking） | 是 | 无（立即移除） |
| 配置别名 | 是 | 是 | 3 个版本 |
| CLI 参数 | 是 | 是 | N/A |

#### C. Contract Test IDs

| Test ID | 类型 | 覆盖场景 | 对应 AC |
|---------|------|----------|---------|
| CT-SLASH-001 | behavior | Slash 命令加载正确 Skill | AC-005 ~ AC-010 |
| CT-CLI-001 | integration | CLI 初始化目录结构 | AC-011, AC-012 |
| CT-CLI-002 | schema | config.yaml 有效性 | AC-013 |
| CT-CLI-003 | integration | Skills 安装 | AC-014 |
| CT-CLI-004 | purity | 发布包纯净性 | AC-015, AC-016 |
| CT-CFG-001 | behavior | 配置发现逻辑 | AC-019, AC-020 |
| CT-MIG-001 | integration | 迁移脚本有效性 | AC-021, AC-022 |

#### D. 追溯摘要

| AC/Requirement | 契约文件 | Contract Test ID |
|----------------|----------|------------------|
| AC-005 ~ AC-010 / REQ-SLASH-* | `.claude/commands/devbooks/*.md` | CT-SLASH-001 |
| AC-011 ~ AC-016 / REQ-CLI-* | `bin/create-devbooks.js`, `templates/` | CT-CLI-001 ~ CT-CLI-004 |
| AC-019, AC-020 / REQ-CFG-* | `scripts/config-discovery.sh` | CT-CFG-001 |
| AC-021, AC-022 | `scripts/migrate-from-openspec.sh` | CT-MIG-001 |

---

## 关键机制

### 质量闸门

| 闸门 | 检查内容 | 阻断条件 |
|------|----------|----------|
| CI-PURITY | npm pack 产物检查 | 包含 `changes/` 或 `backup/` |
| CI-OPENSPEC-FREE | OpenSpec 引用扫描 | 任何文件包含 `openspec` |
| CI-SKILLS-COUNT | Skills 目录计数 | 目录数量 ≠ 21 |
| CI-CONFIG-VALID | 配置文件解析 | YAML 解析错误 |

### MCP 检测机制

**检测逻辑**：
1. 检查 `~/.claude/mcp.json` 是否存在
2. 解析 JSON 获取已配置的 MCP 服务器列表
3. 为每个已知 MCP 生成增强提示

**降级行为**：
- 若无 `mcp.json`：使用基础提示词
- 若部分 MCP 缺失：仅启用已安装 MCP 的增强功能
- 不报错，不阻断

### 快速模式边界

| 维度 | 快速模式上限 | 超限行为 |
|------|--------------|----------|
| 影响文件数 | ≤ 5 个 | 提示使用完整流程 |
| 跨模块变更 | 否 | 提示使用完整流程 |
| 对外接口变更 | 否 | 提示使用完整流程 |
| 需要 AC 追溯 | 否 | 提示使用完整流程 |

---

## 可观测性与验收

### Metrics

| 指标 | 采集点 | 阈值 |
|------|--------|------|
| 安装成功率 | CLI 执行结果 | > 95% |
| Skill 加载时间 | Skill 启动日志 | < 2s |
| 配置发现时间 | config-discovery.sh | < 500ms |

### 验证脚本落点

```
skills/devbooks-delivery-workflow/scripts/
├── verify-openspec-free.sh      # AC-001 ~ AC-004 验证
├── verify-slash-commands.sh     # AC-005 ~ AC-010 验证
├── verify-npm-package.sh        # AC-011 ~ AC-016 验证
├── verify-mcp-optional.sh       # AC-017 ~ AC-018 验证
├── verify-config-discovery.sh   # AC-019 ~ AC-020 验证
└── verify-migration.sh          # AC-021 ~ AC-022 验证
```

---

## 安全、合规与多租户隔离

**不适用**：本变更为工具链/文档变更，不涉及敏感数据或多租户场景。

---

## 里程碑

| 里程碑 | 完成标志 | 依赖 |
|--------|----------|------|
| M1-CLEANUP | AC-001 ~ AC-004 通过 | 无 |
| M2-COMMANDS | AC-005 ~ AC-010 通过 | M1 |
| M3-NPM | AC-011 ~ AC-016 通过 | M2 |
| M4-MIGRATION | AC-021 ~ AC-022 通过 | M1 |
| M5-FINAL | 全部 AC 通过 | M1 ~ M4 |

---

## Deprecation Plan

### 移除项

| 移除对象 | 移除版本 | 警告期 | 迁移路径 |
|----------|----------|--------|----------|
| `/openspec:*` 命令 | 本次 | 无 | 使用 `/devbooks:*` |
| `setup/openspec/` | 本次 | 无 | 使用 `npx create-devbooks` |
| `protocol: openspec` 配置 | 本次 | 无 | 删除该字段 |
| `truth_root`/`change_root` 别名 | v1.3.0 | 3 个版本 | 使用 `paths.specs`/`paths.changes` |

---

## Design Rationale

### 为什么选择 npm 包而非独立二进制

- **对比方案**：Rust/Go 编译二进制、Bash 脚本包装
- **选择理由**：
  1. 用户群体（前端/Node.js 开发者）熟悉 npx
  2. 无需额外安装运行时
  3. 发布更新便捷（npm publish）
  4. 可利用 npm scripts 生态

### 为什么不保留 OpenSpec 兼容

- **用户需求**：人类明确要求"完全解耦"
- **维护成本**：保留两套命令增加复杂度
- **清晰度**：单一协议减少认知负担

---

## Trade-offs

| 放弃 | 换取 |
|------|------|
| 现有用户无缝升级 | 代码库清晰度 |
| 多协议支持 | 实现简单性 |
| 渐进式迁移 | 一次性干净切割 |

**不适用场景**：
- 需要与 OpenSpec 项目共存的环境
- 无法运行 Node.js 的环境

---

## 风险与降级策略

| Failure Mode | 降级路径 |
|--------------|----------|
| npm 发布失败 | 提供 tarball 手动安装 |
| Skills 安装权限不足 | 提示用户修复权限或使用 sudo |
| MCP 检测误判 | 支持 `--mcp-config` 手动指定 |
| 迁移脚本遗漏文件 | 提供 `--dry-run` 预览 + 人工确认 |

---

## ⚡ DoD 完成定义

### 必须通过的闸门

- [ ] 全部 22 个 AC（AC-001 ~ AC-022）通过
- [ ] `verify-*.sh` 脚本全部返回 0
- [ ] CI 流水线绿色
- [ ] npm pack 产物纯净性检查通过

### 必须产出的证据

```
dev-playbooks/changes/complete-devbooks-independence/evidence/
├── openspec-cleanup.log        # AC-001 ~ AC-004 证据
├── slash-cmd-test.log          # AC-005 ~ AC-010 证据
├── npm-install-test.log        # AC-011 ~ AC-016 证据
├── mcp-optional-test.log       # AC-017 ~ AC-018 证据
├── config-discovery-review.md  # AC-019 ~ AC-020 证据
└── migration-test.log          # AC-021 ~ AC-022 证据
```

### AC 交叉引用

| 目标 | 关联 AC |
|------|---------|
| G-01 完全解耦 | AC-001 ~ AC-004, AC-019 |
| G-02 原生命令 | AC-005 ~ AC-010 |
| G-03 一键安装 | AC-011 ~ AC-014 |
| G-04 纯净发布 | AC-015 ~ AC-016 |
| G-05 MCP 可选 | AC-017 ~ AC-018 |

---

## Open Questions

1. **Q: Node.js 最低版本要求？**
   - **决策**：>= 18 LTS（当前 LTS 主流版本）
   - 已在 package.json 的 engines 字段中实现

2. **Q: Skills 更新机制如何设计？**
   - **决策**：采用方案 A（`npx create-devbooks --update-skills`）
   - 理由：与初始化命令统一，用户记忆负担小

3. **Q: 快速模式边界需要更精确的量化吗？**
   - **决策**：当前设计保持静态阈值（≤ 5 个文件）
   - 理由：简单明确，后续可根据用户反馈迭代

---

## 实现过程决策记录（Design Backport）

> 以下决策在实现过程中做出，回写到设计文档以保持设计为黄金真理。

### D-BP-001: MCP 检测脚本简化

**问题**：AC-018 要求 MCP 检测逻辑正确识别已安装 MCP，但 detect-mcp.sh 脚本是否必要？

**决策**：MCP 检测逻辑内联到 devbooks-router SKILL.md 中，不创建独立脚本。

**理由**：
1. 检测逻辑简单（检查 ~/.claude/mcp.json 是否存在）
2. 避免额外脚本维护负担
3. devbooks-router 是唯一需要 MCP 检测的调用方

**影响**：AC-018 验证方式从"脚本返回正确 MCP 列表"调整为"devbooks-router 能正确降级"。

### D-BP-002: templates/ 结构延迟创建

**问题**：AC-012、AC-013 要求 templates/dev-playbooks/ 和 templates/.devbooks/config.yaml 存在。

**决策**：templates/ 目录结构在归档后手动创建，不在当前变更包中实现。

**理由**：
1. templates/ 是发布包的一部分，需要在 npm 发布前准备
2. 当前变更包主要目标是 OpenSpec 清理和 Slash 命令实现
3. templates/ 内容来自 setup/generic/ 的转换，需要人工审阅

**影响**：AC-012、AC-013 状态保持 Red，标记为"归档后待办"。

### D-BP-003: 测试评审修复（2026-01-12）

**来源**：Test Reviewer 代码评审反馈

**修复清单**：
| ID | 问题 | 修复 |
|----|------|------|
| C-001 | TEST-PURE-001/002 未实际运行 npm pack | 增加实际 npm pack --dry-run 执行 |
| M-001 | TEST-CMD-006 断言不够具体 | 增强快速模式行为验证 |
| M-002 | TEST-MCP-002 逻辑复杂 | 简化为单一清晰检查路径 |
| M-003 | TEST-NPM-004 Skills 数量硬编码 | 从配置读取期望数量 |

---

## 附录 A：OpenSpec 引用完整清单

**统计数据**：
- 总文件数：56 个
- 总引用数：473 处

### 需要删除的目录（2 个目录，10 个文件）

1. `setup/openspec/`（7 个文件）
   - OpenSpec集成模板（project.md 与 AGENTS附加块）.md
   - prompts/devbooks-openspec-apply.md
   - prompts/devbooks-openspec-archive.md
   - prompts/devbooks-openspec-proposal.md
   - README.md
   - template.devbooks-config.yaml
   - 安装提示词.md

2. `.claude/commands/openspec/`（3 个文件）
   - apply.md
   - archive.md
   - proposal.md

### 需要删除的规格文件（1 个）

- `dev-playbooks/specs/openspec-integration/spec.md`

### 需要更新的配置文件（2 个）

- `.devbooks/config.yaml`
- `scripts/config-discovery.sh`

### 需要更新的文档（15 个）

- `AGENTS.md`
- `README.md`
- `DEVBOOKS-EVOLUTION-PROPOSAL.md`
- `docs/quality-gates-guide.md`
- `docs/基础提示词.md`
- `docs/完全体提示词.md`
- `setup/generic/DevBooks集成模板（协议无关）.md`
- `setup/generic/安装提示词.md`
- `setup/README.md`
- `dev-playbooks/project.md`
- `dev-playbooks/specs/_meta/glossary.md`
- `dev-playbooks/specs/_meta/key-concepts.md`
- `dev-playbooks/specs/_meta/project-profile.md`
- `dev-playbooks/specs/architecture/c4.md`
- `dev-playbooks/specs/architecture/hotspots.md`

### 需要更新的规格文件（5 个）

- `dev-playbooks/specs/architecture/module-graph.md`
- `dev-playbooks/specs/config-protocol/spec.md`
- `dev-playbooks/specs/protocol-discovery/spec.md`
- `dev-playbooks/specs/script-contracts/spec.md`
- `dev-playbooks/specs/test-reviewer/spec.md`

### 需要更新的 Skills（含脚本，20 个）

- `skills/_template/config-discovery-template.md`
- `skills/Skills使用说明.md`
- `skills/devbooks-brownfield-bootstrap/references/存量项目初始化提示词.md`
- `skills/devbooks-brownfield-bootstrap/scripts/cod-update.sh`
- `skills/devbooks-code-review/SKILL.md`
- `skills/devbooks-coder/SKILL.md`
- `skills/devbooks-delivery-workflow/scripts/change-check.sh`
- `skills/devbooks-delivery-workflow/scripts/change-scaffold.sh`
- `skills/devbooks-delivery-workflow/scripts/constitution-check.sh`
- `skills/devbooks-delivery-workflow/scripts/env-match-check.sh`
- `skills/devbooks-delivery-workflow/scripts/handoff-check.sh`
- `skills/devbooks-delivery-workflow/scripts/migrate-to-devbooks-2.sh`
- `skills/devbooks-delivery-workflow/scripts/migrate-to-v2-gates.sh`
- `skills/devbooks-delivery-workflow/scripts/progress-dashboard.sh`
- `skills/devbooks-delivery-workflow/scripts/rollback-to-openspec.sh`
- `skills/devbooks-delivery-workflow/SKILL.md`
- `skills/devbooks-federation/scripts/federation-check.sh`
- `skills/devbooks-federation/SKILL.md`
- `skills/devbooks-federation/templates/federation.yaml`
- `skills/devbooks-router/SKILL.md`
- `skills/devbooks-spec-gardener/SKILL.md`
- `skills/devbooks-test-owner/SKILL.md`
- `skills/devbooks-test-reviewer/SKILL.md`

### 需要更新的测试脚本（1 个）

- `tests/relevance-evaluation.sh`

---

**文档结束**
