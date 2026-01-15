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

## 工作流位置感知（Workflow Position Awareness）

> **核心原则**：Test Owner 在整体工作流中承担**双阶段职责**，确保与 Coder 的角色隔离。

### 我在整体工作流中的位置

```
proposal → design → [Test Owner 阶段1] → coder → [Test Owner 阶段2] → code-review → archive
                         ↓                           ↓
                    Red 基线产出              Green 验证 + 打勾
```

### Test Owner 的双阶段职责

| 阶段 | 触发时机 | 核心职责 | 产出 |
|------|----------|----------|------|
| **阶段 1：Red 基线** | design.md 完成后 | 编写测试、产出失败证据 | verification.md (Status=Ready)、Red 基线 |
| **阶段 2：Green 验证** | Coder 完成后 | 验证测试通过、勾选 AC 覆盖矩阵 | AC 矩阵打勾、Status 保持 Ready（等 Reviewer 设 Done） |

### 阶段 2 详细职责（关键！）

当用户说"Coder 完成了，请验证"或类似请求时，Test Owner 进入**阶段 2**：

1. **运行全部测试**：执行 `npm test` 或项目测试命令
2. **验证 Green 状态**：确认所有测试通过
3. **勾选 AC 覆盖矩阵**：在 verification.md 的 AC 覆盖矩阵中将 `[ ]` 改为 `[x]`
4. **收集 Green 证据**：保存到 `evidence/green-final/`
5. **输出验证报告**：总结测试结果和覆盖情况

### AC 覆盖矩阵复选框权限（重要！）

| 复选框位置 | 谁可以勾选 | 勾选时机 |
|------------|-----------|----------|
| AC 覆盖矩阵中的 `[ ]` | **Test Owner** | 阶段 2 验证 Green 状态后 |
| Status 字段 `Done` | Reviewer | Code Review 通过后 |

**禁止**：Coder 不能勾选 AC 覆盖矩阵，不能修改 verification.md。

---

## 前置：配置发现（协议无关）

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
- 禁止跳过规则文档阅读

## 产物落点

- 测试计划与追溯：`<change-root>/<change-id>/verification.md`
- 测试代码：按仓库惯例（例如 `tests/**`）
- Red 基线证据：`<change-root>/<change-id>/evidence/red-baseline/`

---

## verification.md 增强模板（必填结构）

Test Owner 必须产出结构化的 `verification.md`，同时作为测试计划和追溯文档。

### Status 字段权限

| 状态 | 含义 | 谁可以设置 |
|------|------|-----------|
| `Draft` | 初始状态 | 自动生成 |
| `Ready` | 测试计划就绪 | **Test Owner** |
| `Done` | Review 通过 | Reviewer（禁止 Test Owner/Coder） |
| `Archived` | 已归档 | Spec Gardener |

**约束**：Test Owner 完成测试计划后，应将 Status 设为 `Ready`。

```markdown
# 验证计划：<change-id>

## 测试策略

### 测试类型分布
| 测试类型 | 数量 | 用途 | 预期耗时 |
|----------|------|------|----------|
| 单元测试 | X | 核心逻辑、边界条件 | < 5s |
| 集成测试 | Y | API 契约、数据流 | < 30s |
| E2E 测试 | Z | 关键用户路径 | < 60s |
| 契约测试 | W | 外部 API 兼容性 | < 10s |

### 测试环境
| 测试类型 | 环境 | 依赖 |
|----------|------|------|
| 单元 | Node.js | 无（全部 mock） |
| 集成 | Node.js + 测试数据库 | Docker |
| E2E | 浏览器（Playwright） | 完整应用 |

---

## AC 覆盖矩阵

| AC-ID | 描述 | 测试类型 | Test ID | 优先级 | 状态 |
|-------|------|----------|---------|--------|------|
| AC-001 | 用户登录返回 JWT | 单元 | T-001 | P0 | [ ] |
| AC-002 | 密码错误返回 401 | 单元 | T-002 | P0 | [ ] |
| AC-003 | Token 24小时后过期 | 集成 | T-003 | P1 | [ ] |

**覆盖摘要**：
- AC 总数：X
- 已有测试覆盖：Y
- 覆盖率：Y/X = Z%

---

## 边界条件检查清单

### 输入验证
- [ ] 空输入 / null 值
- [ ] 超过最大长度
- [ ] 无效格式（邮箱、手机号等）
- [ ] SQL 注入 / XSS 尝试

### 状态边界
- [ ] 第一项（index 0）
- [ ] 最后一项（index n-1）
- [ ] 空集合
- [ ] 单元素集合
- [ ] 最大容量

### 并发与时序
- [ ] 并发访问同一资源
- [ ] 请求超时处理
- [ ] 竞态条件场景
- [ ] 失败后重试

### 错误处理
- [ ] 网络故障
- [ ] 数据库连接丢失
- [ ] 外部 API 不可用
- [ ] 无效响应格式

---

## 测试优先级

| 优先级 | 定义 | Red 基线要求 |
|--------|------|--------------|
| P0 | 阻塞发布，核心功能 | 必须在 Red 基线中失败 |
| P1 | 重要，应该覆盖 | 应该在 Red 基线中失败 |
| P2 | 锦上添花，可以后补 | Red 基线中可选 |

### P0 测试（必须在 Red 基线中）
1. T-001: <测试描述>
2. T-002: <测试描述>

### P1 测试（应该在 Red 基线中）
1. T-003: <测试描述>

---

## 手动验证检查清单

### MANUAL-001: <手动检查描述>
- [ ] 步骤 1
- [ ] 步骤 2
- [ ] 预期结果

---

## 追溯矩阵

| 需求 | 设计 (AC) | 测试 | 证据 |
|------|-----------|------|------|
| REQ-001 | AC-001, AC-002 | T-001, T-002 | evidence/red-baseline/*.log |
```

---

## 证据路径强制约定

**Red 基线证据必须保存到变更包目录**：
```
<change-root>/<change-id>/evidence/red-baseline/
```

**禁止的路径**：
- ❌ `./evidence/`（项目根目录）
- ❌ `evidence/`（相对于当前工作目录）

**正确的路径示例**：
```bash
# Dev-Playbooks 默认路径
dev-playbooks/changes/<change-id>/evidence/red-baseline/test-$(date +%Y%m%d-%H%M%S).log

# 使用脚本
devbooks change-evidence <change-id> --label red-baseline -- npm test
```

---

## 输出管理约束（Observation Masking）

防止大量输出污染 context：

| 场景 | 处理方式 |
|------|----------|
| 测试输出 > 50 行 | 只保留首尾各 10 行 + 失败摘要 |
| Red 基线日志 | 落盘到 `evidence/red-baseline/`，对话中只引用路径 |
| Green 证据日志 | 落盘到 `evidence/green-final/`，对话中只引用路径 |
| 大量测试用例列表 | 用表格摘要，不要逐条贴出 |

**示例**：
```
❌ 错误：贴入 500 行测试输出
✅ 正确：Red 基线已建立，3 个测试失败，详见 evidence/red-baseline/test-2024-01-05.log
        失败摘要：
        - FAIL test_pagination_invalid_page (expected 400, got 500)
        - FAIL test_pagination_boundary (assertion error)
        - FAIL test_sorting_desc (timeout)
```

---

## 测试分层强制约定（借鉴 VS Code）

### 测试类型与命名约定

| 测试类型 | 文件命名 | 目录位置 | 预期执行时间 |
|----------|----------|----------|--------------|
| 单元测试 | `*.test.ts` / `*.test.js` | `src/**/test/` 或 `tests/unit/` | < 5s/文件 |
| 集成测试 | `*.integrationTest.ts` | `tests/integration/` | < 30s/文件 |
| E2E 测试 | `*.e2e.ts` / `*.spec.ts` | `tests/e2e/` | < 60s/文件 |
| 契约测试 | `*.contract.ts` | `tests/contract/` | < 10s/文件 |
| 烟雾测试 | `*.smoke.ts` | `tests/smoke/` | 可变 |

### 测试金字塔比例建议

```
        /\
       /E2E\        ≈ 10%（关键用户路径）
      /─────\
     /Integration\  ≈ 20%（模块边界）
    /─────────────\
   /  Unit Tests   \ ≈ 70%（业务逻辑）
  /─────────────────\
```

### verification.md 必须包含的测试分层信息

```markdown
## 测试分层策略

| 类型 | 数量 | 覆盖场景 | 预期执行时间 |
|------|------|----------|--------------|
| 单元测试 | X | AC-001, AC-002 | < Ys |
| 集成测试 | Y | AC-003 | < Zs |
| E2E 测试 | Z | 关键路径 | < Ws |

## 测试环境要求

| 测试类型 | 运行环境 | 依赖 |
|----------|----------|------|
| 单元测试 | Node.js | 无外部依赖 |
| 集成测试 | Node.js + 测试数据库 | Docker |
| E2E 测试 | Browser (Playwright) | 完整应用 |
```

### 测试隔离要求

- [ ] 每个测试必须独立运行，不依赖其他测试的执行顺序
- [ ] 集成测试必须有 `beforeEach`/`afterEach` 清理
- [ ] 禁止使用共享的可变状态
- [ ] 测试结束后必须清理创建的文件/数据

### 测试稳定性要求

- [ ] 禁止提交 `test.only` / `it.only` / `describe.only`
- [ ] Flaky 测试必须标记并限期修复（不超过 1 周）
- [ ] 测试超时必须合理设置（单元测试 < 5s，集成测试 < 30s）
- [ ] 禁止依赖外部网络（mock 所有外部调用）

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 阅读方法论参考：`references/测试驱动.md`（需要时再读）。
3) 阅读测试分层指南：`references/测试分层策略.md`。
4) 严格按完整提示词执行：`references/测试代码提示词.md`。
5) 模板（按需）：`references/变更验证与追溯模板.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，确保角色隔离和前置条件满足。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `design.md` 是否存在
2. 检测当前会话是否已执行过 Coder 角色
3. 检测 `verification.md` 是否已存在
4. 检测 `tests/` 目录状态

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **首次编写** | `verification.md` 不存在 | 创建完整验收测试套件 |
| **补充测试** | `verification.md` 存在但有 `[TODO]` | 补充缺失的测试用例 |
| **Red 基线验证** | 测试存在，需要确认 Red 状态 | 运行测试并记录失败日志 |

### 前置检查

- [ ] `design.md` 存在
- [ ] 当前会话未执行过 Coder
- [ ] 有 AC-xxx 可供追溯

### 检测输出示例

```
检测结果：
- 产物存在性：design.md ✓, verification.md ✗
- 角色隔离：✓（当前会话未执行 Coder）
- AC 数量：14 个
- 运行模式：首次编写
```

---

## 偏离检测与落盘协议

**参考**：`skills/_shared/references/偏离检测与路由协议.md`

### 实时落盘要求

在编写测试过程中，**必须立即**将以下情况写入 `deviation-log.md`：

| 情况 | 类型 | 示例 |
|------|------|------|
| 发现 design.md 未覆盖的边界情况 | DESIGN_GAP | 并发写入场景 |
| 发现需要额外的约束 | CONSTRAINT_CHANGE | 需要添加参数校验 |
| 发现接口需要调整 | API_CHANGE | 需要增加返回字段 |
| 发现配置项需要变更 | CONSTRAINT_CHANGE | 需要新的配置参数 |

### deviation-log.md 格式

```markdown
# 偏离日志

## 待回写记录

| 时间 | 类型 | 描述 | 涉及文件 | 已回写 |
|------|------|------|----------|:------:|
| 2024-01-15 09:30 | DESIGN_GAP | 发现并发场景未覆盖 | tests/concurrent.test.ts | ❌ |
```

### Compact 保护

**重要**：deviation-log.md 是持久化文件，不受 compact 影响。即使对话被压缩，偏离信息仍然保留。

---

## 完成状态与下一步路由

### 阶段感知（关键！）

Test Owner 有两个阶段，完成状态因阶段而异：

| 当前阶段 | 如何判断 | 完成后下一步 |
|----------|----------|--------------|
| **阶段 1** | verification.md 不存在或 Red 基线未产出 | → Coder |
| **阶段 2** | 用户说"验证/打勾"且 Coder 已完成 | → Code Review |

### 阶段 1 完成状态分类（MECE）

| 状态码 | 状态 | 判定条件 | 下一步 |
|:------:|------|----------|--------|
| ✅ | PHASE1_COMPLETED | Red 基线产出，无偏离 | `devbooks-coder`（单独会话） |
| ⚠️ | PHASE1_COMPLETED_WITH_DEVIATION | Red 基线产出，deviation-log 有未回写记录 | `devbooks-design-backport` |
| ❌ | BLOCKED | 需要外部输入/决策 | 记录断点，等待用户 |
| 💥 | FAILED | 测试框架问题等 | 修复后重试 |

### 阶段 2 完成状态分类（MECE）

| 状态码 | 状态 | 判定条件 | 下一步 |
|:------:|------|----------|--------|
| ✅ | PHASE2_VERIFIED | 测试全绿，AC 矩阵已打勾 | `devbooks-code-review` |
| ❌ | PHASE2_FAILED | 测试未通过 | 通知 Coder 修复，或 HANDOFF |
| 🔄 | PHASE2_HANDOFF | 发现测试本身有问题 | 修复测试后重新验证 |

### 阶段判定流程

```
1. 检查当前处于哪个阶段：
   - verification.md 不存在 → 阶段 1
   - verification.md 存在但 AC 矩阵全是 [ ] → 阶段 1 或 阶段 2（看用户请求）
   - 用户明确说"验证/打勾/Coder 完成了" → 阶段 2

2. 阶段 1 状态判定：
   a. 检查 deviation-log.md 是否有 "| ❌" 记录
      → 有：PHASE1_COMPLETED_WITH_DEVIATION
   b. 检查 Red 基线是否产出
      → 否：BLOCKED 或 FAILED
   c. 以上都通过 → PHASE1_COMPLETED

3. 阶段 2 状态判定：
   a. 运行测试，检查是否全绿
      → 否：PHASE2_FAILED
   b. 检查测试本身是否有问题
      → 是：PHASE2_HANDOFF
   c. 全绿且无问题 → PHASE2_VERIFIED
```

### 路由输出模板（必须使用）

完成 test-owner 后，**必须**输出以下格式：

```markdown
## 完成状态

**阶段**：阶段 1（Red 基线）/ 阶段 2（Green 验证）

**状态**：✅ PHASE1_COMPLETED / ✅ PHASE2_VERIFIED / ⚠️ ... / ❌ ... / 💥 ...

**Red 基线**：已产出 / 未完成（仅阶段 1）

**Green 验证**：全绿 / 有失败（仅阶段 2）

**AC 矩阵**：已打勾 N/M / 未打勾（仅阶段 2）

**偏离记录**：有 N 条待回写 / 无

## 下一步

**推荐**：`devbooks-xxx skill`

**原因**：[具体原因]

### 如何调用
运行 devbooks-xxx skill 处理变更 <change-id>
```

### 具体路由规则

| 我的状态 | 下一步 | 原因 |
|----------|--------|------|
| PHASE1_COMPLETED | `devbooks-coder`（单独会话） | Red 基线已产出，Coder 实现以变绿 |
| PHASE1_COMPLETED_WITH_DEVIATION | `devbooks-design-backport` | 先回写设计，再交给 Coder |
| PHASE2_VERIFIED | `devbooks-code-review` | 测试全绿，可以进入代码评审 |
| PHASE2_FAILED | 通知 Coder | 测试未通过，需要 Coder 修复 |
| PHASE2_HANDOFF | 修复测试 | 测试本身有问题，Test Owner 修复 |
| BLOCKED | 等待用户 | 记录断点区 |
| FAILED | 修复后重试 | 分析失败原因 |

**关键约束**：
- **角色隔离**：Coder 必须在**单独的会话/实例**中工作
- Test Owner 和 Coder 不能共享同一会话上下文
- 如有偏离，必须先 design-backport 再交给 Coder
- **阶段 2 的 AC 矩阵打勾只能由 Test Owner 执行**

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`
