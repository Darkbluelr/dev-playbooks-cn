---
skill: devbooks-spec-gardener
backward-compat: true
---

# /devbooks:archive

**向后兼容命令**：执行归档阶段。

## 用途

此命令是向后兼容命令，保持与原有 `/devbooks:archive` 调用方式一致。

内部调用 `devbooks-spec-gardener` Skill。

## 新版本替代方案

建议使用直达命令：

```
/devbooks:gardener
```

## 功能

归档前修剪与维护 <truth-root>（去重合并/删除过时/目录整理/一致性修复），避免 specs 堆叠失控。

## 迁移说明

```
旧命令             新命令
/devbooks:archive  →  /devbooks:gardener
```
