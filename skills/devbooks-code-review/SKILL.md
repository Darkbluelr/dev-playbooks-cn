---
name: devbooks-code-review
description: devbooks-code-review：以 Reviewer 角色做可读性/一致性/依赖健康/坏味道审查，只输出审查意见与可执行建议，不讨论业务正确性。用户说"帮我做代码评审/review 可维护性/坏味道/依赖风险/一致性建议"，或在 OpenSpec apply 阶段以 reviewer 执行时使用。
tools:
  - Glob
  - Grep
  - Read
  - Bash
  - mcp__ckb__getStatus
  - mcp__ckb__getHotspots
  - mcp__ckb__getCallGraph
  - mcp__ckb__analyzeImpact
---

# DevBooks：代码评审（Reviewer）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `openspec/project.md`（如存在）→ OpenSpec 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 热点优先审查（Hotspot-First Review）

**借鉴 Augment Code 的热点计算**：优先审查高风险区域的变更。

### 审查前置步骤

1) 调用 `mcp__ckb__getHotspots(limit=20)` 获取项目热点
2) 对比变更文件列表与热点，**按风险排序审查**：
   - 🔴 热点 Top 5：必须深度审查
   - 🟡 热点 Top 10：重点关注
   - 🟢 非热点：常规审查

### 热点文件额外审查项

对于热点文件，**必须额外检查**：

| 检查项 | 原因 | 操作 |
|--------|------|------|
| 测试覆盖率 | 热点文件 Bug 概率高 | 要求增加测试 |
| 圈复杂度变化 | 是否在增加复杂度 | 建议拆分函数 |
| 依赖数量变化 | 是否在增加耦合 | 检查依赖方向 |
| 变更范围 | 是否一次改太多 | 建议拆分 PR |

### 输出格式

在评审开头输出热点摘要：

```markdown
## 热点审查摘要

本次变更涉及 **3/8 个热点文件**，需重点关注：

| 文件 | 热点排名 | 变更行数 | 审查优先级 |
|------|----------|----------|------------|
| src/order/process.ts | #2 | +45/-12 | 🔴 必须深度审查 |
| src/auth/login.ts | #7 | +8/-3 | 🟡 重点关注 |
```

## 审查维度（借鉴 VS Code ESLint 规则）

### 1. 可读性审查
- 命名一致性（PascalCase/camelCase）
- 函数长度和复杂度
- 注释质量和必要性
- 代码格式化

### 2. 依赖健康审查
- 分层约束遵守（参见 devbooks-c4-map）
- 循环依赖检测
- 内部模块封装（禁止深度导入 *Internal 文件）
- 依赖方向正确性

### 3. 资源管理审查（借鉴 VS Code DisposableStore）

**必须检查的资源泄漏模式**：

| 检查项 | 违规模式 | 正确模式 |
|--------|----------|----------|
| 订阅未取消 | `event.on(...)` 无对应 `off()` | 注册到 DisposableStore |
| 定时器未清理 | `setInterval()` 无 `clearInterval()` | 在 dispose() 中清理 |
| 监听器未移除 | `addEventListener()` 无 `removeEventListener()` | 使用 AbortController |
| 流未关闭 | `createReadStream()` 无 `close()` | 使用 try-finally 或 using |
| 连接未释放 | `connect()` 无 `disconnect()` | 使用连接池或 dispose 模式 |

**DisposableStore 模式检查**：

```typescript
// 违规：可变的 disposable 字段
private disposable = new DisposableStore(); // 应该是 readonly

// 违规：dispose() 未调用 super.dispose()
dispose() {
  this.cleanup(); // 缺少 super.dispose()
}

// 正确模式
private readonly _disposables = new DisposableStore();

override dispose() {
  this._disposables.dispose();
  super.dispose();
}
```

**资源管理检查清单**：
- [ ] DisposableStore 字段是否声明为 `readonly` 或 `const`？
- [ ] dispose() 方法是否调用了 `super.dispose()`？
- [ ] 订阅/监听器是否注册到 DisposableStore？
- [ ] 测试是否包含 `ensureNoDisposablesAreLeakedInTestSuite()`？

### 4. 类型安全审查

- [ ] 是否存在 `as any` 类型断言？
- [ ] 是否存在 `{} as T` 危险断言？
- [ ] 是否使用了 `unknown` 而非 `any`？
- [ ] 泛型约束是否足够严格？

### 5. 坏味道检测

参见：`references/坏味道速查表.md`

### 6. 测试质量审查

- [ ] 是否存在 `test.only` / `describe.only`？
- [ ] 测试是否有清理逻辑（afterEach）？
- [ ] 测试是否独立（不依赖执行顺序）？
- [ ] mock 是否正确重置？

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 阅读资源管理指南：`references/资源管理审查清单.md`。
3) 严格按完整提示词输出评审意见：`references/12 代码评审提示词.md`。
