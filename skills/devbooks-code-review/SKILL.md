---
name: devbooks-code-review
description: devbooks-code-review：以 Reviewer 角色做可读性/一致性/依赖健康/坏味道审查，只输出审查意见与可执行建议，不讨论业务正确性。用户说"帮我做代码评审/review 可维护性/坏味道/依赖风险/一致性建议"，或在 DevBooks apply 阶段以 reviewer 执行时使用。
tools:
  - Glob
  - Grep
  - Read
  - Bash
---

# DevBooks：代码评审（Reviewer）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
4. `project.md`（如存在）→ template 协议，使用默认映射
5. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 审查维度

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

### 3. 资源管理审查

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

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 阅读资源管理指南：`references/资源管理审查清单.md`。
3) 严格按完整提示词输出评审意见：`references/代码评审提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的审查范围。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测变更包是否存在
2. 检测是否有代码变更（git diff）
3. 检测热点文件（通过 CKB getHotspots）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **变更包审查** | 提供 change-id | 审查该变更包相关的代码变更 |
| **文件审查** | 提供具体文件路径 | 审查指定文件 |
| **热点优先审查** | 检测到热点文件变更 | 优先审查高风险热点 |

### 检测输出示例

```
检测结果：
- 变更包状态：存在
- 代码变更：12 个文件
- 热点文件：3 个（需重点关注）
- 运行模式：变更包审查 + 热点优先
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getHotspots` | 检测热点文件，优先审查 | 2s |
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若 CKB 可用 → 调用 `mcp__ckb__getHotspots` 获取热点文件
3. 对热点文件进行优先审查
4. 若超时或失败 → 降级到基础模式

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 热点优先审查 | 自动识别高风险文件 | 按变更顺序审查 |
| 依赖方向检查 | 基于模块图分析 | 基于文件路径推断 |
| 循环依赖检测 | CKB 精确检测 | Grep 启发式检测 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 不可用，无法进行热点优先审查。
按变更文件顺序进行审查。
```

