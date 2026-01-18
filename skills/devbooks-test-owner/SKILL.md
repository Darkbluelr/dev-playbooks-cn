---
name: devbooks-test-owner
description: devbooks-test-owner：以 Test Owner 角色把设计/规格转成可执行验收测试与追溯文档（verification.md），强调与实现（Coder）独立对话、先跑出 Red 基线。用户说"写测试/验收测试/追溯矩阵/verification.md/Red-Green/contract tests/fitness tests"，或在 DevBooks apply 阶段以 test owner 执行时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：测试负责人（Test Owner）

## 快速开始

我的职责：
1. **阶段 1（Red 基线）**：编写测试 → 产出失败证据
2. **阶段 2（Green 验证）**：审计证据 → 勾选 AC 矩阵

## 工作流位置

```
proposal → design → [TEST-OWNER] → [CODER] → [TEST-OWNER] → code-review → archive
                         ↓              ↓           ↓
                    Red 基线      实现+快轨     证据审计+打勾
                   (增量测试)    (@smoke)     (不重跑@full)
```

## 双阶段职责

| 阶段 | 触发时机 | 核心职责 | 测试运行方式 | 产出 |
|------|----------|----------|--------------|------|
| **阶段 1：Red 基线** | design.md 完成后 | 编写测试、产出失败证据 | 只跑**增量测试**（新写的/P0） | verification.md (Status=Ready)、Red 基线 |
| **阶段 2：Green 验证** | Coder 完成 + @full 通过后 | **审计证据**、勾选 AC 覆盖矩阵 | 默认不重跑，可选抽样 | AC 矩阵打勾、Status=Verified |

### AI 时代优化

| 旧设计 | 新设计 | 原因 |
|--------|--------|------|
| Test Owner 和 Coder 必须单独会话 | 同一会话，用 `[TEST-OWNER]` / `[CODER]` 模式标签切换 | 减少上下文重建成本 |
| 阶段2 重跑完整测试 | 阶段2 默认**审计证据**，可选抽样重跑 | 避免慢测试多次运行 |
| 测试无分层要求 | 强制测试分层：`@smoke`/`@critical`/`@full` | 快速反馈循环 |

---

## 前置：配置发现

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根

## 产物落点

- 测试计划与追溯：`<change-root>/<change-id>/verification.md`
- 测试代码：按仓库惯例（例如 `tests/**`）
- Red 基线证据：`<change-root>/<change-id>/evidence/red-baseline/`
- Green 证据：`<change-root>/<change-id>/evidence/green-final/`

---

## 📚 参考文档

### 必读（立即阅读）

1. **AI行为规范**：`~/.claude/skills/_shared/references/AI行为规范.md`
   - 可验证性守门、结构质量守门、完整性守门
   - 所有 skills 的基础规则

2. **绝对禁令与规则**：`references/绝对禁令与规则.md`
   - 禁止空壳测试、禁止演示模式、禁止测试与 AC 脱钩
   - AC 覆盖矩阵复选框权限
   - 测试隔离与稳定性要求

3. **测试代码提示词**：`references/测试代码提示词.md`
   - 完整的测试编写指南
   - 严格按此提示词执行

### 阶段 1 必读（编写测试时）

4. **测试驱动方法论**：`references/测试驱动.md`
   - TDD 完整方法论
   - Red-Green-Refactor 循环
   - 何时阅读：需要理解 TDD 原则时

5. **测试分层策略**：`references/测试分层策略.md`
   - 单元/集成/E2E 测试分层
   - 测试金字塔原则
   - 何时阅读：规划测试类型分布时

6. **测试分层与运行策略**：`references/测试分层与运行策略.md`
   - @smoke/@critical/@full 标签详解
   - 各阶段测试运行策略
   - 异步与同步的边界
   - 何时阅读：需要理解测试运行策略时

7. **解依赖技术速查表**：`references/解依赖技术速查表.md`
   - Mock/Stub/Fake 技术
   - 依赖注入模式
   - 何时阅读：需要隔离外部依赖时

8. **异步系统测试策略**：`references/异步系统测试策略.md`
   - 异步代码测试技巧
   - 事件驱动系统测试
   - 何时阅读：测试异步功能时

9. **ication 模板与结构**：`references/verification模板与结构.md`
   - verification.md 完整模板
   - Status 字段权限
   - AC 覆盖矩阵结构
   - 何时阅读：创建 verification.md 时

10. **变更验证与追溯模板**：`references/变更验证与追溯模板.md`
    - 追溯矩阵模板
    - 边界条件检查清单
    - 何时阅读：需要完整模板参考时

### 阶段 2 必读（证据审计时）

11. **阶段 2 证据审计清单**：`references/阶段2证据审计清单.md`
    - 完整的证据审计步骤
    - 何时抽样重跑
    - 如何勾选 AC 矩阵
    - 何时阅读：进入阶段 2 时立即阅读

---

## 核心流程

### 阶段 1：Red 基线（编写测试）

1. **读取设计文档**：
   ```bash
   # 读取 design.md 和 AC
   cat <change-root>/<change-id>/design.md
   ```

2. **创建 verification.md**：
   - 使用 `references/verification模板与结构.md- 建立 AC 覆盖矩阵
   - 设置 Status = `Draft`

3. **编写测试**：
   - 严格遵守 `references/绝对禁令与规则.md`
   - 参考 `references/测试代码提示词.md`
   - 每个 AC 至少一个测试

4. **运行测试产出 Red 基线**：
   ```bash
   # 只跑新写的测试（增量）
   npm test -- --grep "AC-001|AC-002"

   # 保存失败证据
   npm test 2>&1 | tee <change-root>/<change-id>/evidence/red-baseline/test-$(date +%Y%m%d-%H%M%S).log
   ```

5. **更新 verification.md**：
   - 设置 Status = `Ready`
   - 记录 Red 基线证据路径

6. **检查偏离**：
   - 如发现设计缺口，记录到 `deviation-log.md`
   - 参考 `~/.claude/skills/_shared/references/偏离检测与路由协议.md`

### 阶段 2：Green 验证（审计证据）

**完整步骤详见**：`references/阶段2证据审计清单.md`

简要流程：
1. 检查 `@full` 测试已通过
2. 审计 `evidence/green-final/` 目录
3. 验证 commit hash 一致性
4. 审计测试日志
5. 验证 AC 覆盖
6. 可选抽样重跑
7. 勾选 AC 矩阵
8. 设置 Status = `Verified`

---

## 输出管理

防止大量输出污染 context：

| 场景 | 处理方式 |
|------|----------|
| 测试输出 > 50 行 | 只保留首尾各 10 行 + 失败摘要 |
| Red 基线日志 | 落盘到 `evidence/red-baseline/`，对话中只引用路径 |
| Green 证据日志 | 落盘到 `evidence/green-final/`，对话中只引用路径 |
| 大量测试用例列表 | 用表格摘要，不要逐条贴出 |

---

## 上下文感知

本 Skill 在执行前自动检测上下文，确保角色隔离和前置条件满足。

检测规则参考：`~/.claude/skills/_shared/上下文检测模板.md`

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **首次编写** | `verification.md` 不存在 | 创建完整验收测试套件 |
| **补充测试** | `verification.md` 存在但有 `[TODO]` | 补充缺失的测试用例 |
| **Red 基线验证** | 测试存在，需要确认 Red 状态 | 运行测试并记录失败日志 |
| **证据审计** | 用户说"验证/打勾"且 @full 通过 | 审计证据并勾选 AC 矩阵 |

---

## 完成状态与下一步路由

### 阶段 1 完成状态

| 状态码 | 状态 | 判定条件 | 下一步 |
|:------:|------|----------|--------|
| ✅ | PHASE1_COMPLETED | Red 基线产出，无偏离 | 切换到 `[CODER]` 模式 |
| ⚠️ | PHASE1_COMPLETED_WITH_DEVIATION | Red 基线产出，deviation-log 有未回写记录 | `devbooks-design-backport` |
| ❌ | BLOCKED | 需要外部输入/决策 | 记录断点，等待用户 |
| 💥 | FAILED | 测试框架问题等 | 修复后重试 |

### 阶段 2 完成状态

| 状态码 | 状态 | 判定条件 | 下一步 |
|:------:|------|----------|--------|
| ✅ | PHASE2_VERIFIED | 证据审计通过，AC 矩阵已打勾 | `devbooks-reviewer` |
| ⏳ | PHASE2_WAITING | @full 测试仍在运行 | 等待 CI 完成 |
| ❌ | PHASE2_FAILED | @full 测试未通过 | 通知 Coder 修复 |
| 🔄 | PHASE2_HANDOFF | 发现测试本身有问题 | 修复测试后重新验证 |

### 路由输出模板（必须使用）

```markdown
## 完成状态

**阶段**：阶段 1（Red 基线）/ 阶段 2（Green 验证）

**状态**：✅ PHASE1_COMPLETED / ✅ PHASE2_VERIFIED / ...

**Red 基线**：已产出 / 未完成（仅阶段 1）

**@full 测试**：已通过 / 运行中 / 失败（仅阶段 2）

**证据审计**：已完成 / 待审计（仅阶段 2）

**AC 矩阵**：已打勾 N/M / 未打勾（仅阶段 2）

**偏离记录**：有 N 条待回写 / 无

## 下一步

**推荐**：切换到 `[CODER]` 模式 / `devbooks-xxx skill`

**原因**：[具体原因]
```

---

## 偏离检测与落盘

**参考**：`~/.claude/skills/_shared/references/偏离检测与路由协议.md`

在编写测试过程中，**必须立即**将以下情况写入 `deviation-log.md`：

| 情况 | 类型 | 示例 |
|------|------|------|
| 发现 design.md 未覆盖的边界情况 | DESIGN_GAP | 并发写入场景 |
| 发现需要额外的约束 | CONSTRAINT_CHANGE | 需要添加参数校验 |
| 发现接口需要调整 | API_CHANGE | 需要增加返回字段 |
| 发现配置项需要变更 | CONSTRAINT_CHANGE | 需要新的配置参数 |

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`~/.claude/skills/_shared/MCP增强模板.md`
