# Implementation Plan: redesign-slash-command-routing

---
maintainer: Planner
input_materials:
  - `dev-playbooks/changes/redesign-slash-command-routing/design.md`
  - `dev-playbooks/changes/redesign-slash-command-routing/proposal.md`
related_specs:
  - `dev-playbooks/changes/redesign-slash-command-routing/specs/slash-commands/spec.md`
  - `dev-playbooks/changes/redesign-slash-command-routing/specs/context-detection/spec.md`
  - `dev-playbooks/changes/redesign-slash-command-routing/specs/mcp-detection/spec.md`
  - `dev-playbooks/changes/redesign-slash-command-routing/specs/router/spec.md`
status: Draft
created: 2026-01-12
last_verified: 2026-01-12
---

## 模式选择

**当前模式**：`主线计划模式`

---

## 主线计划区 (Main Plan Area)

### MP1: 命令模板创建

**目的 (Why)**：实现 21 个 Slash 命令与 21 个 Skills 的 1:1 对应关系。

**交付物 (Deliverables)**：
- 15 个新命令模板文件（保留原有 6 个）

**影响范围 (Files/Modules)**：
- `templates/claude-commands/devbooks/`（新增 15 个 .md 文件）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP1.1 | 创建 `router.md` | 文件存在且包含 `skill: devbooks-router` | - |
| MP1.2 | 创建 `impact.md` | 文件存在且包含 `skill: devbooks-impact-analysis` | - |
| MP1.3 | 创建 `challenger.md` | 文件存在且包含 `skill: devbooks-proposal-challenger` | - |
| MP1.4 | 创建 `judge.md` | 文件存在且包含 `skill: devbooks-proposal-judge` | - |
| MP1.5 | 创建 `debate.md` | 文件存在且包含 `skill: devbooks-proposal-debate-workflow` | - |
| MP1.6 | 创建 `spec.md` | 文件存在且包含 `skill: devbooks-spec-contract` | - |
| MP1.7 | 创建 `c4.md` | 文件存在且包含 `skill: devbooks-c4-map` | - |
| MP1.8 | 创建 `plan.md` | 文件存在且包含 `skill: devbooks-implementation-plan` | - |
| MP1.9 | 创建 `test.md` | 文件存在且包含 `skill: devbooks-test-owner` | - |
| MP1.10 | 创建 `code.md` | 文件存在且包含 `skill: devbooks-coder` | - |
| MP1.11 | 创建 `test-review.md` | 文件存在且包含 `skill: devbooks-test-reviewer` | - |
| MP1.12 | 创建 `backport.md` | 文件存在且包含 `skill: devbooks-design-backport` | - |
| MP1.13 | 创建 `gardener.md` | 文件存在且包含 `skill: devbooks-spec-gardener` | - |
| MP1.14 | 创建 `entropy.md` | 文件存在且包含 `skill: devbooks-entropy-monitor` | - |
| MP1.15 | 创建 `federation.md` | 文件存在且包含 `skill: devbooks-federation` | - |
| MP1.16 | 创建 `bootstrap.md` | 文件存在且包含 `skill: devbooks-brownfield-bootstrap` | - |
| MP1.17 | 创建 `index.md` | 文件存在且包含 `skill: devbooks-index-bootstrap` | - |
| MP1.18 | 创建 `delivery.md` | 文件存在且包含 `skill: devbooks-delivery-workflow` | - |

**验收标准 (Acceptance Criteria)**：
- AC-001：`ls templates/claude-commands/devbooks/*.md | wc -l` 输出 21
- AC-002：每个命令文件的 `skill:` 字段与对应 SKILL.md 的 `name:` 字段匹配

**依赖 (Dependencies)**：无

**风险 (Risks)**：
- 命令模板内容不完整 → 参考现有 proposal.md 模板结构

---

### MP2: 上下文检测模板创建

**目的 (Why)**：提供标准化的上下文检测规则，供所有 SKILL.md 引用。

**交付物 (Deliverables)**：
- `skills/_shared/context-detection-template.md`

**影响范围 (Files/Modules)**：
- `skills/_shared/`（新建目录和文件）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP2.1 | 创建 `skills/_shared/` 目录 | 目录存在 | - |
| MP2.2 | 创建 `context-detection-template.md` | 文件存在 | MP2.1 |
| MP2.3 | 编写产物存在性检测规则 | 包含三种模式（从零/补漏/同步） | MP2.2 |
| MP2.4 | 编写完整性判断规则 | 包含按 Req 分组校验算法 | MP2.2 |
| MP2.5 | 编写 7 个边界场景测试用例 | 包含测试表格 | MP2.4 |
| MP2.6 | 编写当前阶段检测规则 | 包含 proposal/apply/archive 三阶段 | MP2.2 |

**验收标准 (Acceptance Criteria)**：
- AC-011：文件存在且包含完整性判断规则（含 7 个边界场景）

**依赖 (Dependencies)**：无

**风险 (Risks)**：
- 完整性判断规则过于复杂 → 提供 bash 脚本示例

---

### MP3: SKILL.md 上下文感知章节

**目的 (Why)**：为每个 SKILL.md 添加上下文感知能力，自动检测产物存在性和当前阶段。

**交付物 (Deliverables)**：
- 21 个 SKILL.md 更新（新增上下文感知章节）

**影响范围 (Files/Modules)**：
- `skills/devbooks-*/SKILL.md`（21 个文件）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP3.1 | 设计上下文感知章节模板 | 模板包含检测规则引用 | MP2 |
| MP3.2 | 更新 `devbooks-spec-contract/SKILL.md` | 包含三种模式检测 | MP3.1 |
| MP3.3 | 更新 `devbooks-c4-map/SKILL.md` | 包含两种模式检测 | MP3.1 |
| MP3.4 | 批量更新其他 19 个 SKILL.md | 包含上下文感知章节 | MP3.1 |

**验收标准 (Acceptance Criteria)**：
- AC-004：`devbooks-spec-contract` 能自动检测模式
- AC-005：`devbooks-c4-map` 能自动检测模式

**依赖 (Dependencies)**：MP2（上下文检测模板）

**风险 (Risks)**：
- 批量修改可能引入不一致 → 使用标准模板 + 逐个校验

---

### MP4: SKILL.md MCP 增强章节

**目的 (Why)**：为每个 SKILL.md 添加 MCP 检测能力，自动选择增强或基础模式。

**交付物 (Deliverables)**：
- 21 个 SKILL.md 更新（新增 MCP 增强章节）

**影响范围 (Files/Modules)**：
- `skills/devbooks-*/SKILL.md`（21 个文件）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP4.1 | 设计 MCP 增强章节模板 | 模板包含检测方式、超时、降级策略 | - |
| MP4.2 | 更新 `devbooks-coder/SKILL.md` | 包含 MCP 增强章节（热点检测） | MP4.1 |
| MP4.3 | 更新 `devbooks-code-review/SKILL.md` | 包含 MCP 增强章节（热点检测） | MP4.1 |
| MP4.4 | 更新 `devbooks-impact-analysis/SKILL.md` | 包含 MCP 增强章节 | MP4.1 |
| MP4.5 | 批量更新其他 18 个 SKILL.md | 包含 MCP 增强章节 | MP4.1 |

**验收标准 (Acceptance Criteria)**：
- AC-006：执行任意 Skill 时，日志显示 MCP 检测尝试
- AC-007：模拟 MCP 不可用，2s 后 Skill 继续执行且输出降级提示

**依赖 (Dependencies)**：无

**风险 (Risks)**：
- MCP 检测实现依赖运行时环境 → 提供模拟测试方法

---

### MP5: Router 增强

**目的 (Why)**：增强 Router 能力，使其能读取 Impact 画像并生成执行计划。

**交付物 (Deliverables)**：
- 更新 `skills/devbooks-router/SKILL.md`

**影响范围 (Files/Modules)**：
- `skills/devbooks-router/SKILL.md`
- `skills/devbooks-router/references/`（如需）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP5.1 | 设计 Impact 画像解析规则 | 定义 YAML 结构解析逻辑 | - |
| MP5.2 | 设计执行计划输出格式 | 定义 Markdown 模板 | - |
| MP5.3 | 实现推导规则 | 根据 Impact 字段推荐 Skill | MP5.1 |
| MP5.4 | 实现失败处理 | 无 Impact 时输出错误 + 降级方案 | MP5.1 |
| MP5.5 | 更新双入口模式文档 | 说明 Router 主入口 vs 直达命令 | - |

**验收标准 (Acceptance Criteria)**：
- AC-003：给定 5 个历史变更的 proposal.md，Router 成功解析 ≥ 4 个
- AC-012：模拟无 Impact 画像时，输出明确错误 + 建议直达命令

**依赖 (Dependencies)**：无

**风险 (Risks)**：
- 历史 proposal.md 格式不统一 → 提供兼容性解析

---

### MP6: 验证脚本与 C4 文档更新

**目的 (Why)**：更新验证脚本和架构文档，确保闸门检查覆盖新命令。

**交付物 (Deliverables)**：
- 更新 `verify-slash-commands.sh`
- 更新 `dev-playbooks/specs/architecture/c4.md`

**影响范围 (Files/Modules)**：
- `skills/devbooks-delivery-workflow/scripts/verify-slash-commands.sh`
- `dev-playbooks/specs/architecture/c4.md`

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP6.1 | 更新 `verify-slash-commands.sh` 新增 AC-011~AC-028 | 脚本包含 18 个新验证项 | MP1 |
| MP6.2 | 更新 C4 组件表 | 列出全部 21 个命令 | MP1 |
| MP6.3 | 更新 FT-009 规则 | 检查条件改为 `cmd_count -eq 21` | MP6.2 |

**验收标准 (Acceptance Criteria)**：
- AC-009：FT-009 规则检查条件为 `cmd_count -eq 21`
- AC-010：`verify-slash-commands.sh` 包含 AC-011 ~ AC-028 验证项

**依赖 (Dependencies)**：MP1（命令模板创建）

**风险 (Risks)**：
- 遗漏新命令验证项 → 使用命令清单逐项核对

---

### MP7: 兼容性验证

**目的 (Why)**：确保现有 6 个命令的调用方式保持兼容。

**交付物 (Deliverables)**：
- 兼容性测试报告（`evidence/compatibility-test.md`）

**影响范围 (Files/Modules)**：
- `templates/claude-commands/devbooks/proposal.md`（保持不变）
- `templates/claude-commands/devbooks/design.md`（保持不变）
- `templates/claude-commands/devbooks/apply.md`（保持不变）
- `templates/claude-commands/devbooks/review.md`（保持不变）
- `templates/claude-commands/devbooks/archive.md`（保持不变）
- `templates/claude-commands/devbooks/quick.md`（保持不变）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP7.1 | 验证 `/devbooks:proposal` 正常工作 | 触发 devbooks-proposal-author | MP1 |
| MP7.2 | 验证 `/devbooks:design` 正常工作 | 触发 devbooks-design-doc | MP1 |
| MP7.3 | 验证 `/devbooks:apply` 正常工作 | 触发相应 Skill | MP1 |
| MP7.4 | 验证 `/devbooks:review` 正常工作 | 触发 devbooks-code-review | MP1 |
| MP7.5 | 验证 `/devbooks:archive` 正常工作 | 触发 devbooks-spec-gardener | MP1 |
| MP7.6 | 验证 `/devbooks:quick` 正常工作 | 触发多 Skill 组合 | MP1 |

**验收标准 (Acceptance Criteria)**：
- AC-008：原有 6 个命令正常工作

**依赖 (Dependencies)**：MP1

**风险 (Risks)**：
- 无（现有文件保持不变）

---

### MP8: 文档更新

**目的 (Why)**：同步更新用户文档，反映命令列表变化。

**交付物 (Deliverables)**：
- 更新 `README.md`
- 更新 `docs/完全体提示词.md`
- 更新 `dev-playbooks/project-profile.md`（如存在）

**影响范围 (Files/Modules)**：
- `README.md`
- `docs/完全体提示词.md`
- `dev-playbooks/project-profile.md`

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP8.1 | 更新 README 命令列表 | 列出全部 21 个命令 | MP1 |
| MP8.2 | 更新完全体提示词文档 | 更新角色入口说明 | MP1 |
| MP8.3 | 更新 project-profile.md | 命令数量字段显示 21 | MP1 |

**验收标准 (Acceptance Criteria)**：
- AC-014：`project-profile.md` 同步更新命令数量

**依赖 (Dependencies)**：MP1

**风险 (Risks)**：
- 遗漏文档更新 → 使用 design.md 的文档影响清单逐项核对

---

### MP9: 回滚验证

**目的 (Why)**：验证回滚方案可执行，确保变更可逆。

**交付物 (Deliverables)**：
- `evidence/rollback-dry-run.log`

**影响范围 (Files/Modules)**：
- 无实际修改（dry-run 模式）

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP9.1 | dry-run 恢复 FT-009 规则 | 无报错 | MP6 |
| MP9.2 | dry-run 删除新增命令模板 | 无报错 | MP1 |
| MP9.3 | dry-run 恢复验证脚本 | 无报错 | MP6 |
| MP9.4 | 记录 dry-run 输出到 `evidence/rollback-dry-run.log` | 文件存在 | MP9.1-9.3 |

**验收标准 (Acceptance Criteria)**：
- AC-013：dry-run 执行回滚命令无报错

**依赖 (Dependencies)**：MP1, MP6

**风险 (Risks)**：
- 回滚命令不完整 → 按 proposal.md 回滚步骤逐项执行

---

### MP10: 证据收集

**目的 (Why)**：收集所有验证证据，满足 DoD 要求。

**交付物 (Deliverables)**：
- `evidence/router-parse-stats.md`
- `evidence/context-detection-test.log`
- `evidence/mcp-latency.log`

**影响范围 (Files/Modules)**：
- `dev-playbooks/changes/redesign-slash-command-routing/evidence/`

**子任务**：

| ID | 任务 | 验收标准 | 依赖 |
|----|------|----------|------|
| MP10.1 | 执行 Router 解析测试（5 个历史变更） | 成功率 ≥ 80% | MP5 |
| MP10.2 | 执行上下文检测边界场景测试（7 个） | 误判率 ≤ 20% | MP2 |
| MP10.3 | 测量 MCP 检测 P95 延迟 | ≤ 2s | MP4 |
| MP10.4 | 汇总证据到 evidence/ 目录 | 4 个文件齐全 | MP10.1-10.3 |

**验收标准 (Acceptance Criteria)**：
- DoD：`evidence/` 目录包含 4 个文件

**依赖 (Dependencies)**：MP2, MP4, MP5, MP9

**风险 (Risks)**：
- 测试数据不足 → 使用本次变更包作为测试用例之一

---

## 临时计划区 (Temporary Plan Area)

> 当前无临时计划。如需添加计划外高优任务，请在此处说明触发原因、影响面、最小修复范围。

---

## 断点区 (Context Switch Breakpoint Area)

> 用于记录主线/临时计划切换时的上下文。

| 字段 | 值 |
|------|-----|
| 当前模式 | 主线计划模式 |
| 最后完成任务 | MP3（21 个 SKILL.md 上下文感知章节已完成） |
| 下一个任务 | MP4.1（设计 MCP 增强章节模板） |
| 阻塞项 | 无 |
| 备注 | MP1 已创建 18 个新命令模板（实际 24 个命令，含 6 个兼容命令），MP2 已创建上下文检测模板 |

---

## 计划细化区

### Scope & Non-goals

**Scope**：
- 新增 15 个命令模板文件
- 更新 21 个 SKILL.md（上下文感知 + MCP 增强章节）
- 更新验证脚本和 C4 文档
- 更新用户文档

**Non-goals**：
- 不改变 Skill 核心职责
- 不改变变更包目录结构
- 不实现动态生成命令

### Architecture Delta

**新增**：
- `skills/_shared/context-detection-template.md`

**修改**：
- `templates/claude-commands/devbooks/`：6 → 21 个文件
- `dev-playbooks/specs/architecture/c4.md`：FT-009 规则

**依赖方向**：
```
命令模板 → SKILL.md → _shared/context-detection-template.md
```

### Milestones

| 阶段 | 任务包 | 验收标准 |
|------|--------|----------|
| M1 | MP1 | AC-001, AC-002 |
| M2 | MP2, MP3 | AC-004, AC-005, AC-011 |
| M3 | MP4 | AC-006, AC-007 |
| M4 | MP5 | AC-003, AC-012 |
| M5 | MP6, MP8 | AC-009, AC-010, AC-014 |
| M6 | MP7 | AC-008 |
| M7 | MP9, MP10 | AC-013, DoD |

### Work Breakdown

**可并行点**：
- MP1（命令模板）与 MP2（上下文模板）可并行
- MP3（上下文章节）与 MP4（MCP 章节）可并行（均依赖模板设计）
- MP5（Router）独立，可与其他任务并行

**依赖关系**：
```
MP1 ─┬─► MP6
     │
     └─► MP7

MP2 ──► MP3

MP4 独立

MP5 独立

MP1 + MP6 ──► MP9

MP2 + MP4 + MP5 + MP9 ──► MP10
```

### Quality Gates

| 闸门 | 检查命令 |
|------|----------|
| 命令完整性 | `ls templates/claude-commands/devbooks/*.md \| wc -l` = 21 |
| FT-009 | `fitness-check.sh` 无失败 |
| 验证脚本 | `verify-slash-commands.sh` 无失败 |

### Rollout & Rollback

**灰度策略**：不适用（一次性发布）

**回滚条件**：
- FT-009 验证失败且无法快速修复
- 新命令导致 CLI 安装流程中断
- Router 解析失败率 > 50%

**回滚步骤**：见 proposal.md 回滚方案

### Risks & Edge Cases

| 风险 | 缓解措施 |
|------|----------|
| FT-009 断言失败 | 必须同步修改 c4.md |
| 命令模板内容不完整 | 参考现有模板结构 |
| 上下文检测规则复杂 | 提供标准模板 + 边界测试 |
| MCP 检测阻塞 | 2s 超时强制降级 |

### Open Questions

1. **Q**: 上下文检测的性能影响如何？
   - **假设**：检测基于文件存在性，预期 <100ms
   - **验证**：MP10.2 中测量实际延迟

2. **Q**: 是否需要为每个命令添加 `--dry-run` 模式？
   - **假设**：当前只为 Router 添加
   - **验证**：用户反馈后按需迭代

3. **Q**: 历史 proposal.md 格式是否统一？
   - **假设**：可能存在格式差异
   - **验证**：MP10.1 中测试兼容性

---

**文档版本**：v1.0.0
**最后更新**：2026-01-12
