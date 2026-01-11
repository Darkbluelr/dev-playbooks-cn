# DevBooks 质量闸门指南

本文档说明 DevBooks 的质量闸门机制，帮助拦截"假完成"并确保变更包的真实质量。

## 概述

DevBooks 质量闸门通过 `change-check.sh` 及配套脚本，在变更包生命周期的关键节点进行自动化检查：

| 闸门 | 触发模式 | 检查内容 |
|------|----------|----------|
| Green 证据检查 | archive, strict | `evidence/green-final/` 存在且非空 |
| 任务完成率检查 | strict | tasks.md 所有任务完成或有 SKIP-APPROVED |
| 测试失败拦截 | archive, strict | Green 证据中无失败模式 |
| P0 跳过审批 | strict | P0 任务跳过必须有审批记录 |
| 环境声明检查 | archive, strict | verification.md 包含测试环境声明 |
| 角色边界检查 | apply --role | 角色不越界（如 Coder 禁改 tests/） |
| 文档影响检查 | archive, strict | design.md 声明文档影响且已兑现 |

---

## 核心脚本

### change-check.sh（核心闸门）

```bash
change-check.sh <change-id> \
  --mode <proposal|apply|review|archive|strict> \
  --role <test-owner|coder|reviewer> \
  --project-root <dir> \
  --change-root <dir> \
  --truth-root <dir>
```

**模式说明**：

| 模式 | 严格程度 | 使用场景 |
|------|----------|----------|
| `proposal` | 最宽松 | 提案阶段，只检查基本结构 |
| `apply` | 中等 | 实现阶段，检查角色边界 |
| `review` | 中等 | 评审阶段 |
| `archive` | 严格 | 归档前，强制 Green 证据 |
| `strict` | 最严格 | 完整验收，所有检查项 |

**退出码**：
- `0`：所有检查通过
- `1`：检查失败
- `2`：用法错误

### handoff-check.sh（角色交接检查）

检查 `handoff.md` 中角色交接是否有双方签名确认。

```bash
handoff-check.sh <change-id> \
  --project-root <dir> \
  --change-root <dir>
```

**检查内容**：
- handoff.md 文件存在
- 包含"确认签名"节
- 所有角色已签名（`[x]` 标记）

### env-match-check.sh（环境声明检查）

检查 `verification.md` 是否包含测试环境声明节。

```bash
env-match-check.sh <change-id> \
  --project-root <dir> \
  --change-root <dir>
```

**验证格式**：
```markdown
## 测试环境声明

- 运行环境：macOS 14 / Ubuntu 22.04
- 数据库：N/A
- 外部依赖：无
```

### audit-scope.sh（审计扫描）

全量扫描目录，输出审计报告。

```bash
audit-scope.sh <directory> --format <markdown|json>
```

### progress-dashboard.sh（进度仪表板）

生成变更包进度仪表板，包含三节：
- 任务完成率
- 角色状态
- 证据状态

```bash
progress-dashboard.sh <change-id> \
  --project-root <dir> \
  --change-root <dir>
```

### migrate-to-v2-gates.sh（迁移工具）

帮助现有变更包迁移到 v2 闸门格式。

```bash
migrate-to-v2-gates.sh <change-id> \
  --project-root <dir> \
  --change-root <dir>
```

---

## 检查项详解

### AC-001: Green 证据强制检查

**触发条件**：`--mode archive` 或 `--mode strict`

**检查逻辑**：
1. `evidence/green-final/` 目录必须存在
2. 目录中必须有至少一个文件

**失败示例**：
```
error: 缺少 Green 证据: evidence/green-final/ 不存在 (AC-001)
```

**修复方法**：
```bash
# 运行测试并保存证据
change-evidence.sh <change-id> --label green-final -- make test
```

### AC-002: 任务完成率检查

**触发条件**：`--mode strict`

**检查逻辑**：
- 遍历 tasks.md 中所有 `- [ ]` 和 `- [x]` 项
- 计算完成率，必须达到 100%
- 未完成但有 `SKIP-APPROVED` 注释的任务视为完成

**失败示例**：
```
error: 任务完成率 75% (3/4)，需要 100% (AC-002)
```

**跳过审批格式**：
```markdown
<!-- SKIP-APPROVED: 该功能延期到下一版本 -->
- [ ] [P1] 性能优化
```

### AC-003: 角色边界检查

**触发条件**：`--mode apply --role <role>`

**角色边界约束**：

| 角色 | 禁止修改 |
|------|----------|
| Coder | `tests/**`、`verification.md`、`.devbooks/` |
| Test Owner | `src/**` |
| Reviewer | 所有代码文件（`.ts`、`.js`、`.py`、`.sh` 等） |

**失败示例**：
```
error: 角色违规: Coder 禁止修改 tests/** (AC-003)
  检测到变更:
    tests/unit/foo.test.ts
    tests/integration/bar.test.ts
```

### AC-004: 角色交接握手检查

**触发条件**：调用 `handoff-check.sh`（change-check.sh 不自动调用）

**检查逻辑**：
- handoff.md 文件必须存在
- 包含"确认签名"节
- 所有角色已签名确认（`[x]` 标记）

**失败示例**：
```
error: 角色交接未确认: handoff.md 中 Coder 未签名 (AC-004)
```

**正确格式**：
```markdown
## 确认签名
- [x] Test Owner 确认交接完成
- [x] Coder 确认接收
```

### AC-005: P0 任务跳过审批

**触发条件**：`--mode strict`

**检查逻辑**：
- 查找所有 `- [ ] [P0]` 格式的未完成任务
- 每个 P0 任务跳过必须有 `<!-- SKIP-APPROVED: <reason> -->` 注释
- 注释可在任务行的前一行、同一行或后一行

**正确格式**：
```markdown
<!-- SKIP-APPROVED: 经 Judge 确认，延期到 Phase 2 -->
- [ ] [P0] 核心功能 X
```

### AC-006: 测试环境声明检查

**触发条件**：`--mode archive` 或 `--mode strict`

**检查逻辑**：
- verification.md 必须包含"测试环境声明"节
- 支持中英文标题：`## 测试环境声明` 或 `## Test Environment`

**可接受格式**：
```markdown
## 测试环境声明

- 运行环境：N/A
- 数据库：N/A
- 外部依赖：N/A
```

### AC-007: 测试失败归档拦截

**触发条件**：`--mode archive` 或 `--mode strict`

**检查逻辑**：
- 扫描 `evidence/green-final/` 中的所有文件
- 搜索失败模式：`^not ok`、`^FAIL`、`^FAILED`、`^--- FAIL:` 等
- 排除误报（如 `0 tests failed`）

**失败示例**：
```
error: 测试失败: Green 证据中包含失败模式，不能归档 (AC-007)
  文件: evidence/green-final/test-results.log
```

### AC-008: 文档影响检查

**触发条件**：`--mode archive` 或 `--mode strict`

**检查逻辑**：
1. design.md 必须包含 `## Documentation Impact` 或 `## 文档影响` 章节
2. 如果声明"无需更新文档"（勾选相应选项），检查通过
3. 如果声明了需要更新的 P0 文档，检查文档更新检查清单是否已完成
4. 在 strict 模式下，验证声明需更新的文档是否已被修改

**design.md 中的文档影响声明格式**：
```markdown
## Documentation Impact（文档影响）

### 需要更新的文档

| 文档 | 更新原因 | 优先级 |
|------|----------|--------|
| README.md | 新增功能 X 需要说明使用方法 | P0 |
| docs/使用说明书.md | 新增脚本 Y 需要补充用法 | P0 |

### 无需更新的文档

- [ ] 本次变更为内部重构，不影响用户可见功能
- [x] 本次变更仅修复 bug，不引入新功能或改变使用方式

### 文档更新检查清单

- [x] 新增脚本/命令已在使用文档中说明
- [ ] 新增配置项已在配置文档中说明
```

**失败示例**：
```
error: design.md 缺少 '## Documentation Impact/文档影响' 章节 (AC-008)
```

```
error: 文档更新检查清单有未完成项 (AC-008)
  未完成项:
    - [ ] 新增脚本/命令已在使用文档中说明
```

**触发规则**：以下变更类型强制要求更新对应文档：

| 变更类型 | 需更新文档 |
|----------|------------|
| 新增脚本（*.sh） | 使用说明、README |
| 新增 Skill | README、Skills 列表 |
| 修改工作流程 | 相关指南文档 |
| 新增配置项 | 配置文档 |
| 新增命令/CLI 参数 | 使用说明 |

---

## 使用场景

### 日常开发流程

```bash
# 1. 提案阶段
change-check.sh my-feature --mode proposal

# 2. 实现阶段（Test Owner）
change-check.sh my-feature --mode apply --role test-owner

# 3. 实现阶段（Coder）
change-check.sh my-feature --mode apply --role coder

# 4. 归档前检查
change-check.sh my-feature --mode archive

# 5. 完整验收
change-check.sh my-feature --mode strict
```

### CI 集成

```yaml
# .github/workflows/pr.yml
- name: Quality Gate Check
  run: |
    ./scripts/change-check.sh ${{ env.CHANGE_ID }} \
      --mode strict \
      --project-root . \
      --change-root openspec/changes
```

### 迁移现有变更包

```bash
# 检查现有变更包是否符合 v2 闸门
change-check.sh old-change --mode strict

# 使用迁移工具修复
migrate-to-v2-gates.sh old-change --project-root . --change-root changes
```

---

## 常见问题

### Q: 如何跳过某项检查？

目前不支持 `--skip-check` 参数。如需跳过某项检查，应：
1. 使用 `SKIP-APPROVED` 注释标记任务
2. 在 design.md 中记录决策理由

### Q: Green 证据应该包含什么？

建议包含：
- 测试运行日志（TAP/JUnit/JSON 格式）
- 静态检查结果（shellcheck、eslint 等）
- 构建日志

### Q: 如何处理角色边界误报？

如果角色边界检查产生误报，检查：
1. 是否在正确的 git 分支上
2. 是否有未提交的暂存更改
3. 文件路径是否匹配角色约束

---

## 相关文档

- `skills/devbooks-delivery-workflow/SKILL.md`：交付验收工作流说明
- `skills/devbooks-test-owner/references/9 变更验证与追溯模板.md`：验证文档模板
- `skills/devbooks-delivery-workflow/templates/handoff.md`：角色交接模板
