---
skill: devbooks-router
---

# DevBooks: 快速模式（向后兼容）

快速入口，适用于小型变更（5 文件以内），由 Router 输出最短闭环路径。

## 用法

/devbooks:quick [参数]

## 参数

$ARGUMENTS

## 说明

这是一个向后兼容命令，适用于简单变更场景：
- 由 Router 判断是否可走轻量路径
- 适用于 bug 修复、小功能、文档更新等

对于复杂变更（>5 文件或跨模块），建议使用 /devbooks:router 获取完整执行计划。
