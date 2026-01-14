---
name: devbooks-test-owner
description: devbooks-test-owner：以 Test Owner 角色把设计/规格转成可执行验收测试与追溯文档（verification.md），强调与实现（Coder）独立对话、先跑出 Red 基线。用户说"写测试/验收测试/追溯矩阵/verification.md/Red-Green/contract tests/fitness tests"，或在 DevBooks apply 阶段以 test owner 执行时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：测试负责人（Test Owner）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
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
# DevBooks 2.0 默认路径
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

## 下一步推荐

**参考**：`skills/_shared/workflow-next-steps.md`

完成 test-owner（产出 Red 基线）后，下一步是：

| 条件 | 下一个 Skill | 原因 |
|------|--------------|------|
| Red 基线已产出 | `devbooks-coder` | Coder 实现以让闸门变绿 |

**关键**：
- Coder **必须在单独的会话/实例中工作**
- Test Owner 和 Coder 不能共享同一会话上下文
- 工作流顺序是：
```
test-owner (会话A) → coder (会话B) → code-review
```

### 输出模板

完成 test-owner（Red 基线）后，输出：

```markdown
## 推荐的下一步

**下一步：`devbooks-coder`**（必须在单独的会话中）

原因：Red 基线已产出。下一步是让 Coder 按 tasks.md 实现，使所有闸门变绿。Coder 必须在单独会话中工作以确保角色隔离。

### 如何调用（在单独的会话中）
```
运行 devbooks-coder skill 处理变更 <change-id>
```

**重要**：Coder 不能修改 `tests/**`。如需修改测试，请交回 Test Owner。
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`
