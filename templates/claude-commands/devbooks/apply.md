---
skill: multi-skill-combo
skills:
  - devbooks-test-owner
  - devbooks-coder
  - devbooks-reviewer
---

# DevBooks: 应用变更（向后兼容）

使用多 Skill 组合执行实现阶段（Test Owner -> Coder -> Code Review）。

## 用法

/devbooks:apply [参数]

## 参数

$ARGUMENTS

## 说明

这是一个向后兼容命令，触发多 Skill 组合：
1. devbooks-test-owner：创建验收测试
2. devbooks-coder：实现功能代码
3. devbooks-reviewer：代码评审

建议使用更精确的直达命令：
- /devbooks:test - 验收测试
- /devbooks:code - 代码实现
- /devbooks:review - 代码评审
