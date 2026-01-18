---
skill: quick-mode
---

# DevBooks: 快速模式（向后兼容）

触发快速模式，适用于小型变更（5 文件以内）。

## 用法

/devbooks:quick [参数]

## 参数

$ARGUMENTS

## 说明

这是一个向后兼容命令，适用于简单变更场景：
- 跳过完整的 proposal/design 流程
- 直接进入实现阶段
- 适用于 bug 修复、小功能、文档更新等

对于复杂变更（>5 文件或跨模块），建议使用 /devbooks:router 获取完整执行计划。
