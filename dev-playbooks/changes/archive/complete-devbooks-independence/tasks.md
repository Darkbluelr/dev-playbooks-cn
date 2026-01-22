# Implementation Plan: complete-devbooks-independence

> 产物落点：`dev-playbooks/changes/complete-devbooks-independence/tasks.md`
>
> 维护者：Planner
> 关联规范：`design.md`、`specs/slash-commands/spec.md`、`specs/npm-cli/spec.md`、`specs/config-discovery/spec.md`
> 输入材料：`proposal.md`、`design.md`
> 更新时间：2026-01-11

---

## 模式选择

**`主线计划模式`** + **`LSC 模式`**（大规模变更：56 个文件，473 处引用）

---

# 主线计划区 (Main Plan Area)

## MP1: OpenSpec 引用清理（LSC）

**目的（Why）**：完全移除代码库中的 OpenSpec 引用，实现 G-01 完全解耦目标。

**交付物（Deliverables）**：
- 56 个文件中 473 处引用清零
- 3 个目录删除（setup/openspec/、.claude/commands/openspec/、dev-playbooks/specs/openspec-integration/）

**影响范围（Files/Modules）**：见 design.md 附录 A 完整清单

**验收标准（Acceptance Criteria）**：
- AC-001: `grep -rn "openspec\|OpenSpec" . | grep -v backup | grep -v changes | wc -l` 返回 0
- AC-002: `[ ! -d "setup/openspec" ]` 返回 true
- AC-003: `[ ! -d ".claude/commands/openspec" ]` 返回 true
- AC-004: `[ ! -d "dev-playbooks/specs/openspec-integration" ]` 返回 true

**依赖（Dependencies）**：无

**风险（Risks）**：遗漏引用导致功能异常

---

### MP1.1 编写批量清理 codemod 脚本

**交付物**：`dev-playbooks/changes/complete-devbooks-independence/scripts/cleanup-openspec-refs.sh`

**接口签名**：
```bash
cleanup-openspec-refs.sh [--dry-run] [--verbose]
# 输出：修改的文件列表和行数
```

**验收**：
- 脚本支持 `--dry-run` 模式预览变更
- 脚本支持 `--verbose` 输出详细日志

**Trace**: AC-001

---

### MP1.2 删除 setup/openspec/ 目录

**交付物**：目录删除

**操作**：
```bash
rm -rf setup/openspec/
```

**验收**：AC-002 通过

---

### MP1.3 删除 .claude/commands/openspec/ 目录

**交付物**：目录删除

**操作**：
```bash
rm -rf .claude/commands/openspec/
```

**验收**：AC-003 通过

---

### MP1.4 删除 dev-playbooks/specs/openspec-integration/ 目录

**交付物**：目录删除

**操作**：
```bash
rm -rf dev-playbooks/specs/openspec-integration/
```

**验收**：AC-004 通过

---

### MP1.5 执行批量清理并验证

**交付物**：清理后的代码库

**操作**：
1. 运行 `cleanup-openspec-refs.sh`
2. 运行验证脚本确认 AC-001 通过

**验收**：AC-001 通过

---

## MP2: Slash 命令实现

**目的（Why）**：实现 DevBooks 原生 Slash 命令体系，实现 G-02 原生命令目标。

**交付物（Deliverables）**：
- `.claude/commands/devbooks/` 目录及 6 个命令定义文件

**影响范围（Files/Modules）**：`.claude/commands/`

**验收标准（Acceptance Criteria）**：
- AC-005 ~ AC-010: 各命令可正确触发对应 Skill

**依赖（Dependencies）**：MP1（避免与旧命令冲突）

**风险（Risks）**：命令格式与 Claude Code 不兼容

---

### MP2.1 创建 devbooks 命令目录

**交付物**：`.claude/commands/devbooks/` 目录

**验收**：目录存在

---

### MP2.2 创建 proposal.md 命令定义

**交付物**：`.claude/commands/devbooks/proposal.md`

**内容结构**：
- 命令描述
- 触发的 Skill: `devbooks-proposal-author`
- 前置条件检查

**验收**：AC-005 通过

**Trace**: REQ-SLASH-001

---

### MP2.3 创建 design.md 命令定义

**交付物**：`.claude/commands/devbooks/design.md`

**内容结构**：
- 命令描述
- 触发的 Skill: `devbooks-design-doc`
- 前置条件：proposal.md 存在

**验收**：AC-006 通过

**Trace**: REQ-SLASH-001

---

### MP2.4 创建 apply.md 命令定义

**交付物**：`.claude/commands/devbooks/apply.md`

**内容结构**：
- 命令描述
- `--role` 参数处理（test-owner / coder / reviewer）
- 角色隔离检查逻辑

**验收**：AC-007 通过

**Trace**: REQ-SLASH-001, REQ-SLASH-002

---

### MP2.5 创建 review.md 命令定义

**交付物**：`.claude/commands/devbooks/review.md`

**验收**：AC-008 通过

---

### MP2.6 创建 archive.md 命令定义

**交付物**：`.claude/commands/devbooks/archive.md`

**验收**：AC-009 通过

---

### MP2.7 创建 quick.md 命令定义

**交付物**：`.claude/commands/devbooks/quick.md`

**内容结构**：
- 快速模式边界检查（≤5 文件、无跨模块、无接口变更）
- 流程：proposal → apply → archive

**验收**：AC-010 通过

**Trace**: REQ-SLASH-003

---

## MP3: npm 包开发

**目的（Why）**：创建 `create-devbooks` npm 包，实现 G-03 一键安装目标。

**交付物（Deliverables）**：
- `package.json`
- `bin/create-devbooks.js`
- `templates/` 目录

**影响范围（Files/Modules）**：新增目录

**验收标准（Acceptance Criteria）**：
- AC-011 ~ AC-016: CLI 功能和发布包纯净性

**依赖（Dependencies）**：MP1（模板不含 OpenSpec 引用）

**风险（Risks）**：npm 包名冲突（已验证可用）

---

### MP3.1 创建 package.json

**交付物**：`package.json`

**关键字段**：
```json
{
  "name": "create-devbooks",
  "version": "1.0.0",
  "bin": { "create-devbooks": "./bin/create-devbooks.js" },
  "files": ["bin/", "templates/", "skills/"],
  "engines": { "node": ">=18" }
}
```

**验收**：`npm pack --dry-run` 无错误

**Trace**: REQ-CLI-005

---

### MP3.2 创建 CLI 入口脚本

**交付物**：`bin/create-devbooks.js`

**接口签名**：
```javascript
// 命令行参数
// npx create-devbooks [project-name] [options]
// --skills-only: 仅安装 Skills
// --update-skills: 更新已安装 Skills
// --template-dir: 自定义模板目录（测试用）
```

**核心功能**：
1. 参数解析
2. 目录创建
3. 模板复制
4. Skills 安装

**验收**：AC-011 通过

**Trace**: REQ-CLI-001

---

### MP3.3 创建 templates/ 目录结构

**交付物**：
```
templates/
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

**验收**：AC-012 通过

**Trace**: REQ-CLI-002

---

### MP3.4 创建 .npmignore

**交付物**：`.npmignore`

**内容**：
```
dev-playbooks/changes/
.devbooks/backup/
tests/
*.log
```

**验收**：AC-015, AC-016 通过

**Trace**: REQ-CLI-004

---

### MP3.5 实现 Skills 安装逻辑

**交付物**：`bin/create-devbooks.js` 中的 Skills 安装功能

**接口**：
```javascript
// 将 skills/devbooks-* 复制到 ~/.claude/skills/
// 返回安装的 Skills 数量（期望 21）
```

**验收**：AC-014 通过

**Trace**: REQ-CLI-003

---

### MP3.6 实现 Node.js 版本检查

**交付物**：CLI 入口的版本检查逻辑

**行为**：
- Node.js < 18 时输出错误并退出
- 错误信息明确说明版本要求

**验收**：SC-CLI-005 场景通过

**Trace**: REQ-CLI-005

---

## MP4: 配置发现更新

**目的（Why）**：移除 config-discovery.sh 中的 OpenSpec 特殊处理，实现统一配置路径。

**交付物（Deliverables）**：
- 更新后的 `scripts/config-discovery.sh`

**影响范围（Files/Modules）**：`scripts/config-discovery.sh`、21 个 Skills

**验收标准（Acceptance Criteria）**：
- AC-019: 脚本无 `openspec` 字符串
- AC-020: Skills 统一使用 .devbooks/config.yaml

**依赖（Dependencies）**：MP1

**风险（Risks）**：配置发现逻辑变更影响现有功能

---

### MP4.1 更新 config-discovery.sh

**交付物**：更新后的脚本

**变更内容**：
1. 移除 `openspec/project.md` 检测逻辑
2. 移除 `protocol: openspec` 处理
3. 保留 `truth_root`/`change_root` 别名（弃用警告）

**验收**：AC-019 通过

**Trace**: REQ-CFG-001, REQ-CFG-R01

---

### MP4.2 添加弃用警告

**交付物**：config-discovery.sh 中的弃用警告逻辑

**行为**：
- 检测到 `truth_root` 或 `change_root` 时输出警告
- 建议迁移到 `paths.specs` / `paths.changes`

**验收**：SC-CFG-003 场景通过

**Trace**: REQ-CFG-003

---

## MP5: 迁移脚本

**目的（Why）**：为现有 OpenSpec 用户提供迁移路径。

**交付物（Deliverables）**：
- `scripts/migrate-from-openspec.sh`

**影响范围（Files/Modules）**：`skills/devbooks-delivery-workflow/scripts/`

**验收标准（Acceptance Criteria）**：
- AC-021: 脚本存在且可执行
- AC-022: 迁移测试通过

**依赖（Dependencies）**：MP1, MP4

**风险（Risks）**：迁移遗漏文件

---

### MP5.1 重命名 migrate-to-devbooks-2.sh

**交付物**：`scripts/migrate-from-openspec.sh`

**操作**：
```bash
mv skills/devbooks-delivery-workflow/scripts/migrate-to-devbooks-2.sh \
   skills/devbooks-delivery-workflow/scripts/migrate-from-openspec.sh
```

**验收**：AC-021 通过

---

### MP5.2 更新迁移脚本功能

**交付物**：完善的迁移脚本

**功能**：
1. 检测 `openspec/` 目录
2. 创建 `.devbooks/config.yaml`
3. 移动 `openspec/specs/` → `dev-playbooks/specs/`
4. 移动 `openspec/changes/` → `dev-playbooks/changes/`
5. 删除 `openspec/` 目录
6. 支持 `--dry-run` 预览

**验收**：AC-022 通过

---

### MP5.3 删除 rollback-to-openspec.sh

**交付物**：脚本删除

**操作**：
```bash
rm skills/devbooks-delivery-workflow/scripts/rollback-to-openspec.sh
```

**验收**：文件不存在

---

## MP6: 验证脚本

**目的（Why）**：为所有 AC 提供自动化验证。

**交付物（Deliverables）**：
- 验证脚本集

**影响范围（Files/Modules）**：`skills/devbooks-delivery-workflow/scripts/`

**验收标准（Acceptance Criteria）**：
- 所有验证脚本可执行
- 验证脚本覆盖 AC-001 ~ AC-022

**依赖（Dependencies）**：MP1 ~ MP5

---

### MP6.1 创建 verify-openspec-free.sh

**交付物**：`skills/devbooks-delivery-workflow/scripts/verify-openspec-free.sh`

**功能**：验证 AC-001 ~ AC-004

**验收**：脚本返回 0 表示通过

---

### MP6.2 创建 verify-slash-commands.sh

**交付物**：`skills/devbooks-delivery-workflow/scripts/verify-slash-commands.sh`

**功能**：验证 AC-005 ~ AC-010

---

### MP6.3 创建 verify-npm-package.sh

**交付物**：`skills/devbooks-delivery-workflow/scripts/verify-npm-package.sh`

**功能**：验证 AC-011 ~ AC-016

---

### MP6.4 创建 verify-all.sh

**交付物**：`skills/devbooks-delivery-workflow/scripts/verify-all.sh`

**功能**：运行所有验证脚本，汇总结果

---

## MP7: 文档更新

**目的（Why）**：更新所有文档以反映 DevBooks 独立状态。

**交付物（Deliverables）**：
- 更新后的 README.md、AGENTS.md 等

**影响范围（Files/Modules）**：15 个文档文件

**验收标准（Acceptance Criteria）**：
- 文档无 OpenSpec 引用
- 文档描述与新架构一致

**依赖（Dependencies）**：MP1

---

### MP7.1 更新 README.md

**交付物**：更新后的 README.md

**变更内容**：
- 移除 OpenSpec 描述
- 添加 `npx create-devbooks` 安装说明
- 更新 Slash 命令列表

---

### MP7.2 更新 AGENTS.md

**交付物**：更新后的 AGENTS.md

**变更内容**：
- 移除 OpenSpec 引用
- 更新命令示例为 `/devbooks:*`

---

### MP7.3 更新 docs/ 下的提示词文档

**交付物**：更新后的 `docs/完全体提示词.md`、`docs/基础提示词.md`

**变更内容**：
- 移除 OpenSpec 相关内容
- 更新命令示例

---

## MP8: C4 地图归档更新

**目的（Why）**：将 C4 Delta 合并到权威 C4 地图。

**交付物（Deliverables）**：
- 更新后的 `dev-playbooks/specs/architecture/c4.md`

**影响范围（Files/Modules）**：`dev-playbooks/specs/architecture/`

**验收标准（Acceptance Criteria）**：
- C4 地图反映最新架构
- 新增 FT-006 ~ FT-009 守门规则

**依赖（Dependencies）**：MP1 ~ MP7 全部完成

---

### MP8.1 更新 C1 层

**变更内容**：
- 移除 OpenSpec 外部系统
- 新增 npm Registry
- 更新用户角色描述

---

### MP8.2 更新 C2 层

**变更内容**：
- 删除 `setup/openspec/` 容器
- 新增 `bin/`、`templates/` 容器
- 更新 `.claude/commands/` 描述

---

### MP8.3 添加 FT-006 ~ FT-009 守门规则

**交付物**：C4.md 中的新增守门规则

---

# 临时计划区 (Temporary Plan Area)

*（当前为空，用于计划外高优任务）*

---

# 计划细化区

## Scope & Non-goals

**In Scope**：
- 56 个文件清理
- 6 个 Slash 命令定义
- npm 包创建与发布
- 配置发现逻辑更新
- 迁移脚本
- 验证脚本
- 文档更新

**Non-goals**：
- OpenSpec 兼容别名
- Codex CLI 支持
- GUI

## Milestones

| 里程碑 | 包含任务包 | 验收标准 |
|--------|------------|----------|
| M1-CLEANUP | MP1 | AC-001 ~ AC-004 全部通过 |
| M2-COMMANDS | MP2 | AC-005 ~ AC-010 全部通过 |
| M3-NPM | MP3 | AC-011 ~ AC-016 全部通过 |
| M4-CONFIG | MP4 | AC-019 ~ AC-020 全部通过 |
| M5-MIGRATION | MP5 | AC-021 ~ AC-022 全部通过 |
| M6-VERIFY | MP6 | 验证脚本可运行 |
| M7-DOCS | MP7 | 文档无 OpenSpec 引用 |
| M8-ARCHIVE | MP8 | C4 地图更新完成 |

## Work Breakdown

```
MP1 ────────────────────────────────────┐
                                        ├──► MP4 ──► MP5
MP2 ────────────────────────────────────┤
                                        │
MP3 ────────────────────────────────────┤
                                        │
MP6 ◄───────────────────────────────────┤
                                        │
MP7 ────────────────────────────────────┤
                                        │
MP8 ◄───────────────────────────────────┘
```

**可并行点**：
- MP1、MP2、MP3 可并行启动（无依赖）
- MP7 可与 MP4、MP5 并行

## Quality Gates

| 闸门 | 检查命令 | 阻断条件 |
|------|----------|----------|
| FT-006 | `grep openspec` | 任何匹配 |
| FT-007 | `npm pack --dry-run` | 包含 changes/ |
| FT-008 | `ls ~/.claude/skills/devbooks-* | wc -l` | ≠ 21 |
| FT-009 | 目录存在性检查 | 不符合预期 |

## Rollout & Rollback

**灰度策略**：
1. 本地测试完成后发布 npm beta 版本
2. 内部项目验证
3. 正式发布 1.0.0

**回滚条件**：
- npm 包安装失败率 > 5%
- Slash 命令无法触发 Skill

**回滚操作**：
- `npm unpublish create-devbooks@1.0.0`
- 恢复 git 历史

## Risks & Edge Cases

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 遗漏 OpenSpec 引用 | 中 | 功能异常 | 自动化验证 + 人工复查 |
| npm 发布失败 | 低 | 阻断安装 | 提供 tarball 手动安装 |
| 迁移脚本遗漏文件 | 中 | 数据丢失 | `--dry-run` 预览 + 备份 |

## Open Questions

1. **Q: Skills 更新机制如何设计？**
   - 待定：`--update-skills` 参数行为需进一步细化

2. **Q: 是否需要在 npm 包中包含 BATS 测试？**
   - 建议：不包含，仅保留验证脚本

3. **Q: 快速模式边界是否需要动态计算？**
   - 当前设计：静态阈值（≤5 文件）
   - 待确认：是否需要更复杂的评估

---

# 断点区 (Context Switch Breakpoint Area)

*（用于未来切换主线/临时计划时记录上下文）*

| 字段 | 值 |
|------|-----|
| 当前模式 | 主线计划模式 |
| 当前任务包 | - |
| 当前子任务 | - |
| 暂停原因 | - |
| 恢复条件 | - |
| 上下文摘要 | - |

---

**文档结束**
