---
skill: devbooks-archiver
---

# DevBooks: 归档变更包

使用 devbooks-archiver 完成变更包的归档闭环。

## 用法

/devbooks:archive [参数]

## 参数

$ARGUMENTS

## 说明

这是一个归档闭环命令，负责完整的归档收尾：
- 自动回写设计文档
- 规格合并到真理源
- 文档同步检查
- 变更包归档移动

如需单独做文档一致性检查，可用 /devbooks:gardener（devbooks-docs-consistency）。
