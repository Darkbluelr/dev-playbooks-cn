<!-- DEVBOOKS:START -->
# /devbooks:apply

执行变更实现。

## 用法

```
/devbooks:apply <role>
```

## 可用角色

| 角色 | 职责 | 约束 |
|------|------|------|
| `test-owner` | 产出 verification.md + tests/ | 先跑出 Red 基线 |
| `coder` | 按 tasks.md 实现代码 | **禁止**修改 tests/ |
| `reviewer` | 代码审查 | 不改 tests，不改设计 |

## 角色隔离原则

**重要**: Test Owner 与 Coder 必须在独立对话/独立实例中执行。

如果在同一会话中：
1. 先以 test-owner 角色产出测试
2. 明确切换角色后，再以 coder 角色实现
3. coder 角色期间禁止修改 tests/

## 执行流程

### test-owner
1. 读取 `design.md` 中的 AC-xxx
2. 创建 `verification.md`（测试计划）
3. 编写测试代码，运行得到 Red 基线
4. 将证据保存到 `evidence/red-baseline/`

### coder
1. 读取 `tasks.md`
2. 按任务顺序实现代码
3. 让测试从 Red 变 Green
4. **禁止**修改 tests/ 目录

### reviewer
1. 审查代码质量
2. 检查是否符合设计
3. 输出评审意见

<!-- DEVBOOKS:END -->
