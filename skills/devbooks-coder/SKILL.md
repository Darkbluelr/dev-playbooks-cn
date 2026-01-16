---
name: devbooks-coder
description: devbooks-coder：以 Coder 角色严格按 tasks.md 实现功能并跑闸门，禁止修改 tests/，以测试/静态检查为唯一完成判据。用户说"按计划实现/修复测试失败/让闸门全绿/实现任务项/不改测试"，或在 DevBooks apply 阶段以 coder 执行时使用。
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：实现负责人（Coder）

## 工作流位置感知（Workflow Position Awareness）

> **核心原则**：Coder 在 Test Owner 阶段 1 之后执行，通过**模式标签**（而非会话隔离）实现思维清晰。

### 我在整体工作流中的位置

```
proposal → design → [TEST-OWNER] → [CODER] → [TEST-OWNER] → code-review → archive
                                      ↓              ↓
                               实现+快轨测试    证据审计+打勾
                              (@smoke/@critical)  (不重跑@full)
```

### AI 时代个人开发优化

> **重要变更**：本协议针对 AI 编程 + 个人开发场景优化，**去掉了"单独会话"的硬性要求**。

| 旧设计 | 新设计 | 原因 |
|--------|--------|------|
| Test Owner 和 Coder 必须单独会话 | 同一会话，用 `[TEST-OWNER]` / `[CODER]` 模式标签切换 | 减少上下文重建成本 |
| Coder 跑完整测试等待结果 | Coder 跑快轨（`@smoke`/`@critical`），`@full` 异步触发 | 快速迭代 |
| 完成后直接交给 Test Owner | 完成后状态为 `Implementation Done`，等 @full 通过 | 异步不阻塞，归档同步 |

### Coder 的职责边界

| 允许 | 禁止 |
|------|------|
| 修改 `src/**` 代码 | ❌ 修改 `tests/**` |
| 勾选 `tasks.md` 任务项 | ❌ 修改 `verification.md` |
| 记录偏离到 `deviation-log.md` | ❌ 勾选 AC 覆盖矩阵 |
| 运行快轨测试（`@smoke`/`@critical`） | ❌ 设置 verification.md Status 为 Verified/Done |
| 触发 `@full` 测试（CI/后台） | ❌ 等待 @full 完成（可以开始下一个变更） |

### Coder 完成后的流程

1. **快轨测试绿**：`@smoke` + `@critical` 通过
2. **触发 @full**：提交代码，CI 开始异步运行 @full 测试
3. **状态变更**：设置变更状态为 `Implementation Done`
4. **可以开始下一个变更**（不阻塞）
5. **等待 @full 结果**：
   - @full 通过 → Test Owner 进入阶段 2 审计证据
   - @full 失败 → Coder 修复

**关键提醒**：
- Coder 完成后，状态是 `Implementation Done`，**不是直接进入 Code Review**
- 开发迭代是异步的（可以开始下一个变更），但归档是同步的（必须等 @full 通过）

---

## 测试分层与运行策略（关键！）

> **核心原则**：Coder 只运行快轨测试，@full 测试异步触发，不阻塞开发迭代。

### 测试分层标签

| 标签 | 用途 | Coder 何时运行 | 预期耗时 |
|------|------|----------------|----------|
| `@smoke` | 快速反馈，核心路径 | 每次代码修改后 | 秒级 |
| `@critical` | 关键功能验证 | 准备提交前 | 分钟级 |
| `@full` | 完整验收测试 | **不运行**，触发 CI 异步执行 | 可以慢 |

### Coder 的测试运行策略

```bash
# 开发过程中：频繁运行 @smoke
npm test -- --grep "@smoke"

# 准备提交前：运行 @critical
npm test -- --grep "@smoke|@critical"

# 提交后：CI 自动运行 @full（Coder 不等待）
git push  # 触发 CI
# → Coder 可以开始下一个任务
```

### 异步与同步的边界

| 动作 | 阻塞/异步 | 说明 |
|------|-----------|------|
| `@smoke` 测试 | 同步 | 每次修改后立即运行 |
| `@critical` 测试 | 同步 | 提交前必须通过 |
| `@full` 测试 | **异步** | CI 后台运行，不阻塞 Coder |
| 开始下一个变更 | **不阻塞** | Coder 可以立即开始 |
| 归档 | **阻塞** | 必须等 @full 通过 |

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

## 断点续做协议（Plan Persistence）

每次开始前**必须**执行以下步骤：

1. **读取进度**：打开 `<change-root>/<change-id>/tasks.md`，识别已勾选 `- [x]` 的任务
2. **定位续做点**：找到"最后一个 `[x]`"后的第一个 `- [ ]`
3. **输出确认**：明确告知用户当前进度，例如：
   ```
   检测到 T1-T6 已完成（6/10），从 T7 继续。
   ```
4. **检查断点区**：如果 tasks.md 有"断点区"记录，优先恢复断点状态
5. **异常处理**：如果发现"未勾选但代码已存在"的任务，提示用户确认

### 断点区格式（tasks.md 末尾）

```markdown
### 断点区 (Context Switch Breakpoint Area)
- 上次进度：T6 完成，T7 开始但未完成
- 当前阻塞：<阻塞原因>
- 下一步最短路径：<建议动作>
```

---

## 实时进度更新协议（Real-time Progress Update）

> **核心原则**：完成一个任务，立即勾选一个。不要等到全部完成再批量勾选。

**必须遵守**：

### 单任务完成后立即勾选

每完成 tasks.md 中的一个任务项后，**立即**将其从 `- [ ]` 改为 `- [x]`：

```markdown
# 任务完成前
- [ ] MP1.1 实现缓存管理器基础结构

# 任务完成后，立即更新
- [x] MP1.1 实现缓存管理器基础结构
```

### 为什么必须实时勾选

1. **断点恢复**：中断后可以准确知道从哪里继续
2. **进度可视**：用户和 AI 都能清楚看到当前进度
3. **避免遗忘**：批量勾选容易遗漏已完成项
4. **证据链完整**：每个勾选代表一个完成的里程碑

### 勾选时机

| 时机 | 操作 |
|------|------|
| 代码编写完成 | 暂不勾选 |
| 编译通过 | 暂不勾选 |
| 相关测试通过 | **立即勾选** |
| 多个任务一起完成 | 逐个勾选，不要批量 |

### 禁止行为

- ❌ 禁止等所有任务完成后再批量勾选
- ❌ 禁止"代码写完就算完成"而不勾选
- ❌ 禁止勾选后又改回未勾选状态（除非回滚代码）

---

## 输出管理约束（Observation Masking）

防止大量输出污染 context：

| 场景 | 处理方式 |
|------|----------|
| 命令输出 > 50 行 | 只保留首尾各 10 行 + 中间摘要 |
| 测试输出 | 提取关键失败信息，不要全量贴入对话 |
| 日志输出 | 落盘到 `<change-root>/<change-id>/evidence/`，对话中只引用路径 |
| 大文件内容 | 引用路径，不要内联 |

**示例**：
```
❌ 错误：贴入 2000 行测试日志
✅ 正确：测试失败 3 个，详见 <change-root>/<change-id>/evidence/green-final/test-output.log
        关键错误：FAIL src/order.test.ts:45 - Expected 400, got 500
```

---

## 证据路径强制约定

**Green 证据必须保存到变更包目录**：
```
<change-root>/<change-id>/evidence/green-final/
```

**禁止的路径**：
- ❌ `./evidence/`（项目根目录）
- ❌ `evidence/`（相对于当前工作目录）

**正确的路径示例**：
```bash
# Dev-Playbooks 默认路径
dev-playbooks/changes/<change-id>/evidence/green-final/test-$(date +%Y%m%d-%H%M%S).log

# 使用脚本
devbooks change-evidence <change-id> --label green-final -- npm test
```

---

## 关键约束

### 角色边界约束
- **禁止修改 `tests/**`**（需要改测试必须交还 Test Owner）
- **禁止修改 `verification.md`**（由 Test Owner 维护）
- **禁止修改 `verification.md` 的 Status 字段**（只有 Reviewer 可以设为 Done）
- **禁止修改 `.devbooks/`、`build/`、工程配置文件**（除非 proposal.md 明确声明）

### 代码质量约束

#### 禁止提交的模式

| 模式 | 检测命令 | 原因 |
|------|----------|------|
| `test.only` | `rg '\.only\s*\(' src/` | 会跳过其他测试 |
| `console.log` | `rg 'console\.log' src/` | 调试代码残留 |
| `debugger` | `rg 'debugger' src/` | 调试断点残留 |
| `// TODO` 无 issue | `rg 'TODO(?!.*#\d+)' src/` | 无法追踪的待办 |
| `any` 类型 | `rg ': any[^a-z]' src/` | 类型安全漏洞 |
| `@ts-ignore` | `rg '@ts-ignore' src/` | 隐藏类型错误 |

#### 提交前必须检查

```bash
# 1. 编译检查（强制）
npm run compile || exit 1

# 2. Lint 检查（强制）
npm run lint || exit 1

# 3. 测试检查（强制）
npm test || exit 1

# 4. test.only 检查（强制）
if rg -l '\.only\s*\(' tests/ src/**/test/; then
  echo "error: found .only() in tests" >&2
  exit 1
fi

# 5. 调试代码检查（强制）
if rg -l 'console\.(log|debug)|debugger' src/ --type ts; then
  echo "error: found debug statements" >&2
  exit 1
fi
```

### 验证前置约束

**核心要求**：每次修改代码后，必须运行验证命令并确认通过。

- [ ] 修改代码后立即运行 `npm run compile`
- [ ] 编译通过后运行 `npm run lint`
- [ ] Lint 通过后运行 `npm test`
- [ ] 禁止在验证失败时声明"任务完成"
- [ ] 验证命令输出必须记录到证据文件

### 资源清理约束

- [ ] 临时文件必须在任务结束时删除
- [ ] 后台进程必须在任务结束时终止
- [ ] 无论成功失败，都必须执行清理

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 阅读低风险改动技术：`references/低风险改动技术.md`（需要时再读）。
3) 严格按完整提示词执行：`references/代码实现提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，确保前置条件满足。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `tasks.md` 是否存在
2. 检测 `verification.md` 是否存在（Test Owner 已完成）
3. 检测当前会话是否已执行过 Test Owner 角色
4. 识别 tasks.md 中的进度（已完成/待做）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **首次实现** | tasks.md 全部为 `[ ]` | 从 MP1.1 开始 |
| **断点续做** | tasks.md 有部分 `[x]` | 从最后 `[x]` 后的第一个 `[ ]` 继续 |
| **闸门修复** | 测试失败需要修复 | 优先处理失败项 |

### 前置检查

- [ ] `tasks.md` 存在
- [ ] `verification.md` 存在
- [ ] 当前会话未执行过 Test Owner
- [ ] `tests/**` 有测试文件

### 检测输出示例

```
检测结果：
- 产物存在性：tasks.md ✓, verification.md ✓
- 角色隔离：✓（当前会话未执行 Test Owner）
- 进度：6/10 已完成
- 运行模式：断点续做，从 MP1.7 继续
```

---

## 偏离检测与落盘协议

**参考**：`skills/_shared/references/偏离检测与路由协议.md`

### 实时落盘要求

在实现过程中，**必须立即**将以下情况写入 `deviation-log.md`：

| 情况 | 类型 | 示例 |
|------|------|------|
| 添加了 tasks.md 中没有的功能 | NEW_FEATURE | 新增 warmup() 方法 |
| 修改了 design.md 中的约束 | CONSTRAINT_CHANGE | 超时改为 60s |
| 发现设计未覆盖的边界情况 | DESIGN_GAP | 并发场景 |
| 公共接口与设计不一致 | API_CHANGE | 参数增加 |

### deviation-log.md 格式

```markdown
# 偏离日志

## 待回写记录

| 时间 | 类型 | 描述 | 涉及文件 | 已回写 |
|------|------|------|----------|:------:|
| 2024-01-15 10:30 | NEW_FEATURE | 添加缓存预热功能 | src/cache.ts | ❌ |
```

### Compact 保护

**重要**：deviation-log.md 是持久化文件，不受 compact 影响。即使对话被压缩，偏离信息仍然保留。

---

## 完成状态与下一步路由

### 完成状态分类（MECE）

| 状态码 | 状态 | 判定条件 | 下一步 |
|:------:|------|----------|--------|
| ✅ | IMPLEMENTATION_DONE | 快轨测试绿，@full 已触发，无偏离 | 切换到 `[TEST-OWNER]` 等待 @full |
| ⚠️ | IMPLEMENTATION_DONE_WITH_DEVIATION | 快轨绿，deviation-log 有未回写记录 | `devbooks-design-backport` |
| 🔄 | HANDOFF | 发现测试问题需要修改 | 切换到 `[TEST-OWNER]` 模式修复测试 |
| ❌ | BLOCKED | 需要外部输入/决策 | 记录断点，等待用户 |
| 💥 | FAILED | 快轨测试未通过 | 修复后重试 |

### 状态判定流程

```
1. 检查 deviation-log.md 是否有 "| ❌" 记录
   → 有：IMPLEMENTATION_DONE_WITH_DEVIATION

2. 检查是否需要修改 tests/
   → 是：HANDOFF to [TEST-OWNER] 模式

3. 检查快轨测试（@smoke + @critical）是否全部通过
   → 否：FAILED

4. 检查 tasks.md 是否全部完成
   → 否：BLOCKED 或继续实现

5. 以上都通过，触发 @full
   → IMPLEMENTATION_DONE
```

### 路由输出模板（必须使用）

完成 coder 后，**必须**输出以下格式：

```markdown
## 完成状态

**状态**：✅ IMPLEMENTATION_DONE / ⚠️ ... / 🔄 HANDOFF / ❌ BLOCKED / 💥 FAILED

**任务进度**：X/Y 已完成

**快轨测试**：@smoke ✅ / @critical ✅

**@full 测试**：已触发（CI 异步运行中）

**偏离记录**：有 N 条待回写 / 无

## 下一步

**推荐**：切换到 `[TEST-OWNER]` 模式等待 @full / `devbooks-xxx skill`

**原因**：[具体原因]

**注意**：可以开始下一个变更，不需要等待 @full 完成
```

### 具体路由规则

| 我的状态 | 下一步 | 原因 |
|----------|--------|------|
| IMPLEMENTATION_DONE | 切换到 `[TEST-OWNER]` 模式（等 @full） | 快轨绿，等 @full 通过后审计证据 |
| IMPLEMENTATION_DONE_WITH_DEVIATION | `devbooks-design-backport` | 先回写设计 |
| HANDOFF (测试问题) | 切换到 `[TEST-OWNER]` 模式 | Coder 不能修改测试 |
| BLOCKED | 等待用户 | 记录断点区 |
| FAILED | 修复后重试 | 分析失败原因 |

**关键约束**：
- Coder **永远不能修改** `tests/**`
- 如发现测试问题，必须切换到 `[TEST-OWNER]` 模式处理
- 如有偏离，必须先 design-backport 再继续
- **Coder 完成后状态是 `Implementation Done`，必须等 @full 通过后才能进入 Test Owner 阶段 2**
- **模式切换替代会话隔离**：使用 `[TEST-OWNER]` / `[CODER]` 标签切换模式

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getHotspots` | 检测热点文件，输出预警 | 2s |
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若 CKB 可用 → 调用 `mcp__ckb__getHotspots` 获取热点文件
3. 若超时或失败 → 降级到基础模式（无热点预警）

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 热点文件预警 | CKB 实时分析 | 不可用 |
| 风险文件识别 | 自动高亮高热点变更 | 手动识别 |
| 代码导航 | 符号级跳转 | 文件级搜索 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 不可用，跳过热点检测。
如需启用热点预警，请手动生成 SCIP 索引。
```

