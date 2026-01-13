---
skill: multi-role
backward-compat: true
---

# /devbooks:apply

**向后兼容命令**：执行 Apply 阶段（Test Owner 或 Coder）。

## 用途

此命令是向后兼容命令，保持与原有 `/devbooks:apply` 调用方式一致。

## 新版本替代方案

建议使用以下直达命令：

| 角色 | 新命令 | 说明 |
|------|--------|------|
| Test Owner | `/devbooks:test` | 测试负责人，产出 verification.md |
| Coder | `/devbooks:code` | 实现负责人，按 tasks.md 实现 |

## 参数

- `--role test-owner`：以 Test Owner 角色执行
- `--role coder`：以 Coder 角色执行

## 角色隔离

Test Owner 和 Coder 必须在独立会话中执行。

## 迁移说明

```
旧命令                    新命令
/devbooks:apply --role test-owner  →  /devbooks:test
/devbooks:apply --role coder       →  /devbooks:code
```
