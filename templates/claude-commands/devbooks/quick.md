---
skill: multi-skill
backward-compat: true
---

# /devbooks:quick

**向后兼容命令**：快速模式（小变更）。

## 用途

此命令是向后兼容命令，保持与原有 `/devbooks:quick` 调用方式一致。

适用于小型变更，跳过部分流程。

## 新版本替代方案

建议使用 Router 获取完整路由建议：

```
/devbooks:router
```

Router 会根据变更规模自动推荐最短路径。

## 快速模式约束

- 仅适用于单文件或少量文件变更
- 不涉及对外 API 变更
- 不涉及架构边界变更
- 不涉及数据模型变更

## 边界检查

如果变更超出快速模式边界，会自动建议切换到完整流程。

## 迁移说明

```
旧命令           新命令
/devbooks:quick  →  /devbooks:router（会自动推荐快速路径）
```
